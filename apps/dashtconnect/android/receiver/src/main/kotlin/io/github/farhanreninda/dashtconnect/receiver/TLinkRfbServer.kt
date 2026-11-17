package io.github.farhanreninda.dashtconnect.receiver

import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.io.InputStream
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.util.zip.Deflater

/** Tightly packed RGBA pixels; [seq] grows with every new capture. */
class RfbFrame(val width: Int, val height: Int, val rgba: ByteArray, val seq: Long)

/**
 * Minimal RFB server that plays the T-Link phone role toward a JVCKenwood head unit over AOA.
 * Offers security type None. Frames go out as 64x64 tiles, only the tiles that changed since the
 * last update, compressed with ZRLE when the head unit offers it and Raw otherwise. Everything the
 * head unit sends is logged so a rejection (for example a RealVNC licence check) shows up in the
 * shared diagnostics log.
 */
class TLinkRfbServer(
    input: InputStream,
    output: OutputStream,
    private val width: Int,
    private val height: Int,
    private val latestFrame: () -> RfbFrame?,
    private val log: (String) -> Unit,
    private val onFirstFrame: () -> Unit = {},
) {
    private val inp = DataInputStream(input)
    private val out = DataOutputStream(output.buffered(256 * 1024))
    private var clientFormat = SERVER_FORMAT
    private var sentSeq = -1L
    private var framesSent = 0
    private var pointerEvents = 0
    private var keyEvents = 0
    private var zrle = false
    private var lastSent: ByteArray? = null
    private val deflater = Deflater(Deflater.BEST_SPEED)
    private val deflateBuffer = ByteArray(64 * 1024)

    fun run() {
        try {
            if (!handshake()) return
            messageLoop()
        } catch (e: EOFException) {
            log("tlink closed by head unit")
        } catch (e: Exception) {
            log("tlink stopped: ${e.javaClass.simpleName} ${e.message}")
        } finally {
            deflater.end()
            log("tlink summary frames=$framesSent pointer=$pointerEvents key=$keyEvents")
        }
    }

    private fun handshake(): Boolean {
        out.write("RFB 003.008\n".toByteArray()); out.flush()
        val version = ByteArray(12).also { inp.readFully(it) }
        val text = String(version, Charsets.US_ASCII)
        log("tlink client version ${hex(version)} '${text.trim()}'")
        if (!text.startsWith("RFB ")) {
            log("tlink not RFB, next bytes ${hex(readAvailable())}")
            return false
        }
        val minor = text.substring(8, 11).toIntOrNull() ?: 8
        if (text.startsWith("RFB 003") && minor < 7) {
            out.writeInt(SECURITY_NONE); out.flush()
        } else {
            out.writeByte(1); out.writeByte(SECURITY_NONE); out.flush()
            val chosen = inp.readUnsignedByte()
            log("tlink security chosen $chosen")
            if (chosen != SECURITY_NONE) {
                log("tlink unsupported security, next bytes ${hex(readAvailable())}")
                return false
            }
            if (minor >= 8 || !text.startsWith("RFB 003")) { out.writeInt(0); out.flush() }
        }
        log("tlink client init shared=${inp.readUnsignedByte()}")
        out.writeShort(width); out.writeShort(height)
        out.write(SERVER_FORMAT.toBytes())
        val name = "DashTConnect".toByteArray()
        out.writeInt(name.size); out.write(name); out.flush()
        log("tlink server init ${width}x$height sent")
        return true
    }

    private fun messageLoop() {
        while (true) {
            when (val type = inp.readUnsignedByte()) {
                0 -> {
                    inp.skipBytes(3)
                    clientFormat = PixelFormat.read(inp)
                    lastSent = null // tiles were encoded in the old format; resend everything
                    log("tlink set pixel format $clientFormat")
                }
                2 -> {
                    inp.skipBytes(1)
                    val encodings = List(inp.readUnsignedShort()) { inp.readInt() }
                    zrle = ENCODING_ZRLE in encodings
                    log("tlink encodings $encodings, using ${if (zrle) "ZRLE" else "Raw"}")
                }
                3 -> {
                    val incremental = inp.readUnsignedByte() != 0
                    inp.skipBytes(8) // requested region; the whole screen is always sent
                    sendFrame(incremental)
                }
                4 -> { inp.skipBytes(7); if (keyEvents++ < 5) log("tlink key event") }
                5 -> {
                    val mask = inp.readUnsignedByte(); val x = inp.readUnsignedShort(); val y = inp.readUnsignedShort()
                    if (pointerEvents++ < 5) log("tlink pointer mask=$mask x=$x y=$y")
                }
                6 -> { inp.skipBytes(3); inp.skipBytes(inp.readInt()) }
                else -> {
                    log("tlink unknown message $type, next bytes ${hex(readAvailable())}")
                    return
                }
            }
        }
    }

    private fun sendFrame(incremental: Boolean) {
        var frame = latestFrame()
        // An incremental request only needs an answer once the screen has changed.
        val deadline = System.currentTimeMillis() + if (incremental) WAIT_FOR_CHANGE_MS else 0
        while (incremental && (frame == null || frame.seq == sentSeq) && System.currentTimeMillis() < deadline) {
            Thread.sleep(5)
            frame = latestFrame()
        }
        if (frame == null || frame.width != width || frame.height != height) {
            out.writeByte(0); out.writeByte(0); out.writeShort(0); out.flush()
            return
        }
        if (incremental && frame.seq == sentSeq) {
            out.writeByte(0); out.writeByte(0); out.writeShort(0); out.flush()
            return
        }
        val previous = if (incremental) lastSent else null
        val tiles = ArrayList<IntArray>()
        for (ty in 0 until height step TILE) for (tx in 0 until width step TILE) {
            val tile = intArrayOf(tx, ty, minOf(TILE, width - tx), minOf(TILE, height - ty))
            if (previous == null || tileChanged(previous, frame.rgba, tile)) tiles += tile
        }
        val pixels = clientFormat.fromRgba(frame.rgba)
        out.writeByte(0); out.writeByte(0); out.writeShort(tiles.size)
        for (tile in tiles) writeTile(pixels, tile)
        out.flush()
        lastSent = frame.rgba
        sentSeq = frame.seq
        if (framesSent++ == 0) {
            log("tlink first frame sent")
            onFirstFrame()
        }
    }

    private fun tileChanged(old: ByteArray, new: ByteArray, tile: IntArray): Boolean {
        val (x, y, w, h) = tile
        for (row in y until y + h) {
            val start = (row * width + x) * 4
            for (i in start until start + w * 4) if (old[i] != new[i]) return true
        }
        return false
    }

    private fun writeTile(pixels: ByteArray, tile: IntArray) {
        val (x, y, w, h) = tile
        out.writeShort(x); out.writeShort(y); out.writeShort(w); out.writeShort(h)
        val bpp = clientFormat.bpp / 8
        if (!zrle) {
            out.writeInt(ENCODING_RAW)
            for (row in y until y + h) out.write(pixels, (row * width + x) * bpp, w * bpp)
            return
        }
        // One ZRLE tile per rectangle: solid colour when uniform, otherwise raw CPIXELs.
        val (skip, size) = clientFormat.cpixel()
        val first = (y * width + x) * bpp
        var solid = true
        check@ for (row in y until y + h) for (col in x until x + w) {
            val at = (row * width + col) * bpp
            for (b in 0 until bpp) if (pixels[at + b] != pixels[first + b]) { solid = false; break@check }
        }
        val tileBytes = ByteArrayOutputStream(1 + w * h * size)
        if (solid) {
            tileBytes.write(1); tileBytes.write(pixels, first + skip, size)
        } else {
            tileBytes.write(0)
            for (row in y until y + h) for (col in x until x + w) tileBytes.write(pixels, (row * width + col) * bpp + skip, size)
        }
        deflater.setInput(tileBytes.toByteArray())
        val zipped = ByteArrayOutputStream()
        do {
            val n = deflater.deflate(deflateBuffer, 0, deflateBuffer.size, Deflater.SYNC_FLUSH)
            zipped.write(deflateBuffer, 0, n)
        } while (n == deflateBuffer.size)
        out.writeInt(ENCODING_ZRLE)
        out.writeInt(zipped.size())
        zipped.writeTo(out)
    }

    private fun readAvailable(): ByteArray {
        val n = minOf(inp.available(), 64)
        return ByteArray(n).also { inp.readFully(it) }
    }

    data class PixelFormat(
        val bpp: Int, val depth: Int, val bigEndian: Boolean, val trueColor: Boolean,
        val redMax: Int, val greenMax: Int, val blueMax: Int,
        val redShift: Int, val greenShift: Int, val blueShift: Int,
    ) {
        fun toBytes(): ByteArray = byteArrayOf(
            bpp.toByte(), depth.toByte(), (if (bigEndian) 1 else 0).toByte(), (if (trueColor) 1 else 0).toByte(),
            (redMax shr 8).toByte(), redMax.toByte(), (greenMax shr 8).toByte(), greenMax.toByte(),
            (blueMax shr 8).toByte(), blueMax.toByte(),
            redShift.toByte(), greenShift.toByte(), blueShift.toByte(), 0, 0, 0,
        )

        /**
         * ZRLE compact pixel: (offset into each pixel, byte count). A 32-bit pixel whose colour fits
         * in three bytes drops the unused byte, as RFB 3.8 section 7.7.6 requires.
         */
        fun cpixel(): Pair<Int, Int> {
            if (bpp != 32 || !trueColor || depth > 24) return 0 to bpp / 8
            val mask = (redMax shl redShift) or (greenMax shl greenShift) or (blueMax shl blueShift)
            return when {
                mask and 0xff000000.toInt() == 0 -> (if (bigEndian) 1 else 0) to 3
                mask and 0xff == 0 -> (if (bigEndian) 0 else 1) to 3
                else -> 0 to 4
            }
        }

        fun fromRgba(rgba: ByteArray): ByteArray {
            if (this == SERVER_FORMAT) return rgba
            val bytes = bpp / 8
            val pixels = rgba.size / 4
            val result = ByteArray(pixels * bytes)
            for (p in 0 until pixels) {
                val r = (rgba[p * 4].toInt() and 0xff) * redMax / 255
                val g = (rgba[p * 4 + 1].toInt() and 0xff) * greenMax / 255
                val b = (rgba[p * 4 + 2].toInt() and 0xff) * blueMax / 255
                val v = (r shl redShift) or (g shl greenShift) or (b shl blueShift)
                for (i in 0 until bytes) {
                    val shift = if (bigEndian) (bytes - 1 - i) * 8 else i * 8
                    result[p * bytes + i] = (v shr shift).toByte()
                }
            }
            return result
        }

        companion object {
            fun read(inp: DataInputStream): PixelFormat {
                val f = PixelFormat(
                    inp.readUnsignedByte(), inp.readUnsignedByte(), inp.readUnsignedByte() != 0, inp.readUnsignedByte() != 0,
                    inp.readUnsignedShort(), inp.readUnsignedShort(), inp.readUnsignedShort(),
                    inp.readUnsignedByte(), inp.readUnsignedByte(), inp.readUnsignedByte(),
                )
                inp.skipBytes(3)
                return f
            }
        }
    }

    companion object {
        private const val SECURITY_NONE = 1
        private const val ENCODING_RAW = 0
        private const val ENCODING_ZRLE = 16
        private const val TILE = 64
        private const val WAIT_FOR_CHANGE_MS = 100L

        /** Little-endian R,G,B,X in memory, identical to Android RGBA_8888 so frames need no conversion. */
        val SERVER_FORMAT = PixelFormat(32, 24, false, true, 255, 255, 255, 0, 8, 16)

        fun hex(bytes: ByteArray) = bytes.joinToString(" ") { "%02x".format(it) }
    }
}
