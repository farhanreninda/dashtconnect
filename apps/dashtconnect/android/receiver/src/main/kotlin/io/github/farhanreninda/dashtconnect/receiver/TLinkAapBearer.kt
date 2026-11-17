package io.github.farhanreninda.dashtconnect.receiver

import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

/**
 * The "VNC Automotive AAP bearer" that T-Link wraps around RFB on the USB accessory link.
 *
 * Handshake: the phone sends a 44-byte V2 hello (magic, device id, zeros) and the 9-byte "DEV"
 * marker, once a second until the head unit answers with either "HOST" (v1: raw RFB afterwards)
 * or a 44-byte reply that echoes the device id (v2). In v2 every USB transfer carries a 44-byte
 * header in each direction, the phone sends a header-only keepalive every second, and the link
 * is dropped when the head unit stays silent for 5 seconds.
 */
class TLinkAapBearer(
    private val rawIn: InputStream,
    private val rawOut: OutputStream,
    private val log: (String) -> Unit,
    private val deviceId: ByteArray = uuidBytes(UUID.randomUUID()),
) {
    private val chunks = LinkedBlockingQueue<ByteArray>()
    @Volatile private var closed = false
    @Volatile private var txHeader: ByteArray? = null
    private var rxHeader: ByteArray? = null
    private var keepalive: Thread? = null
    var version = 0
        private set

    /** Runs the handshake; afterwards [input] and [output] carry plain RFB bytes. */
    fun establish(timeoutMs: Long = 30_000) {
        val giveUp = System.currentTimeMillis() + timeoutMs
        var readerStarted = false
        while (System.currentTimeMillis() < giveUp) {
            writeTransfer(hello(withHost = null), first = !readerStarted)
            writeTransfer(DEVICE_HANDSHAKE, first = false)
            if (!readerStarted) { startReader(); readerStarted = true }
            val reply = readHandshake(System.currentTimeMillis() + ATTEMPT_MS)
            if (reply.size == HOST_HANDSHAKE.size && reply.contentEquals(HOST_HANDSHAKE)) {
                version = 1
                log("tlink aap v1 (raw RFB)")
                return
            }
            if (reply.size == HELLO_SIZE && reply.copyOfRange(28, 44).contentEquals(deviceId)) {
                val hostId = reply.copyOfRange(12, 28)
                version = 2
                txHeader = hello(withHost = hostId)
                rxHeader = MAGIC + hostId + deviceId
                startKeepalive()
                log("tlink aap v2 established")
                return
            }
            if (reply.isNotEmpty()) log("tlink aap unexpected reply ${TLinkRfbServer.hex(reply)}")
        }
        throw IOException("Head unit did not answer the AAP handshake")
    }

    val input: InputStream = object : InputStream() {
        private var current = ByteArray(0)
        private var pos = 0

        override fun read(): Int {
            val one = ByteArray(1)
            return if (read(one, 0, 1) < 0) -1 else one[0].toInt() and 0xff
        }

        override fun read(b: ByteArray, off: Int, len: Int): Int {
            if (len == 0) return 0
            while (pos >= current.size) {
                if (closed) return -1
                // Only v2 has keepalives, so silence means a dead link there; v1 may idle freely.
                val chunk = if (version == 2) {
                    chunks.poll(RECEIVE_TIMEOUT_MS, TimeUnit.MILLISECONDS)
                        ?: throw IOException("Head unit silent for ${RECEIVE_TIMEOUT_MS / 1000} s")
                } else chunks.take()
                if (chunk === END) return -1
                current = strip(chunk)
                pos = 0
            }
            val n = minOf(len, current.size - pos)
            System.arraycopy(current, pos, b, off, n)
            pos += n
            return n
        }

        override fun available(): Int = current.size - pos
    }

    val output: OutputStream = object : OutputStream() {
        override fun write(b: Int) = write(byteArrayOf(b.toByte()), 0, 1)

        override fun write(b: ByteArray, off: Int, len: Int) {
            var at = off
            val end = off + len
            while (at < end) {
                val size = payloadSize(end - at, txHeader?.size ?: 0)
                writePacket(b, at, size)
                at += size
            }
        }
    }

    fun close() {
        if (closed) return
        closed = true
        keepalive?.interrupt()
        if (version == 2) runCatching { synchronized(rawOut) { rawOut.write(hello(withHost = null)); rawOut.flush() } }
        chunks.offer(END)
    }

    private fun strip(chunk: ByteArray): ByteArray {
        val header = rxHeader ?: return chunk
        if (chunk.size < header.size || !chunk.copyOfRange(0, header.size).contentEquals(header)) {
            throw IOException("Packet with no AAP header: ${TLinkRfbServer.hex(chunk.copyOfRange(0, minOf(chunk.size, 48)))}")
        }
        return chunk.copyOfRange(header.size, chunk.size)
    }

    private fun writePacket(b: ByteArray, off: Int, len: Int) {
        val header = txHeader
        val packet = if (header == null) b.copyOfRange(off, off + len) else header + b.copyOfRange(off, off + len)
        synchronized(rawOut) { rawOut.write(packet); rawOut.flush() }
    }

    /** The first write after attaching can fail while the head unit opens its side; T-Link retries 21 times. */
    private fun writeTransfer(bytes: ByteArray, first: Boolean) {
        var attempt = 0
        while (true) {
            try {
                synchronized(rawOut) { rawOut.write(bytes); rawOut.flush() }
                return
            } catch (e: IOException) {
                if (!first || ++attempt >= FIRST_WRITE_ATTEMPTS) throw e
                Thread.sleep(50)
            }
        }
    }

    private fun startReader() {
        Thread({
            val buffer = ByteArray(READ_SIZE)
            try {
                while (!closed) {
                    val n = rawIn.read(buffer, 0, READ_SIZE)
                    if (n < 0) break
                    if (n > 0) chunks.offer(buffer.copyOf(n))
                }
            } catch (e: IOException) {
                if (!closed) log("tlink aap read ended: ${e.message}")
            } finally {
                chunks.offer(END)
            }
        }, "tlink-aap-reader").apply { isDaemon = true }.start()
    }

    /** Collects up to 44 bytes of the head unit's answer until [deadline]. */
    private fun readHandshake(deadline: Long): ByteArray {
        var reply = ByteArray(0)
        while (reply.size < HELLO_SIZE) {
            val wait = deadline - System.currentTimeMillis()
            if (wait <= 0) break
            val chunk = chunks.poll(wait, TimeUnit.MILLISECONDS) ?: break
            if (chunk === END) throw IOException("USB link closed during AAP handshake")
            reply += chunk
            if (reply.size == HOST_HANDSHAKE.size && reply.contentEquals(HOST_HANDSHAKE)) break
        }
        return reply
    }

    private fun startKeepalive() {
        keepalive = Thread({
            try {
                while (!closed) {
                    Thread.sleep(KEEPALIVE_MS)
                    runCatching { writePacket(ByteArray(0), 0, 0) }
                }
            } catch (_: InterruptedException) {
            }
        }, "tlink-aap-keepalive").apply { isDaemon = true; start() }
    }

    private fun hello(withHost: ByteArray?) = MAGIC + deviceId + (withHost ?: ByteArray(16))

    companion object {
        /** "v02" magic that starts every V2 hello and packet header. */
        val MAGIC = byteArrayOf(-1, -1, 0, 0, 10, 10, 0x76, 0x30, 0x32, 0, 0, 0)
        val DEVICE_HANDSHAKE = byteArrayOf(-1, -1, 0, 0, 10, 10, 0x44, 0x45, 0x56) // "DEV"
        val HOST_HANDSHAKE = byteArrayOf(-1, -1, 0, 0, 10, 10, 0x48, 0x4f, 0x53, 0x54) // "HOST"
        const val HELLO_SIZE = 44
        private const val READ_SIZE = 512
        private const val MAX_TRANSFER = 15871
        private const val ATTEMPT_MS = 1_000L
        private const val KEEPALIVE_MS = 1_000L
        // T-Link drops the link after 5 s of silence; 15 s keeps the same safety without cutting a slow head unit.
        private const val RECEIVE_TIMEOUT_MS = 15_000L
        private const val FIRST_WRITE_ATTEMPTS = 21
        private val END = ByteArray(0)

        /** Payload bytes for the next packet: never let header + payload be a multiple of 512, like T-Link. */
        fun payloadSize(remaining: Int, headerSize: Int): Int {
            var size = minOf(remaining, MAX_TRANSFER - headerSize)
            if (size > 0 && (headerSize + size) % 512 == 0) size -= 1
            return size
        }

        fun uuidBytes(id: UUID): ByteArray =
            ByteBuffer.allocate(16).putLong(id.mostSignificantBits).putLong(id.leastSignificantBits).array()
    }
}
