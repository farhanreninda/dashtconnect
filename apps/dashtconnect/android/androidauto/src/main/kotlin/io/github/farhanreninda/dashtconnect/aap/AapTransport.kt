package io.github.farhanreninda.dashtconnect.aap

import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import android.util.Log
import java.io.IOException
import java.net.Socket
import java.nio.Buffer
import java.nio.ByteBuffer
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLEngine
import javax.net.ssl.SSLEngineResult.HandshakeStatus
import javax.net.ssl.SSLEngineResult.Status
import javax.net.ssl.SSLException
import javax.net.ssl.X509TrustManager

internal class AapMessage(val channel: Int, val type: Int, val body: ByteArray) {
    /** Body starts after the two-byte type. */
    val offset get() = 2
}

/** AAP framing over TCP with the TLS session the phone requires; the head unit is the TLS client. */
internal class AapTransport(private val socket: Socket, identity: HeadUnitIdentity) : AapLink {
    private val input = DataInputStream(BufferedInputStream(socket.getInputStream(), 1 shl 16))
    private val output = BufferedOutputStream(socket.getOutputStream(), 1 shl 15)
    private val engine: SSLEngine = SSLContext.getInstance("TLS").apply {
        init(arrayOf(identity.keyManager()), arrayOf(TrustPhone), null)
    }.createSSLEngine().apply { useClientMode = true }
    private val writeLock = Any()
    private val reassembler = Reassembler()
    private var netIn: ByteBuffer = ByteBuffer.allocate(engine.session.packetBufferSize * 2)
    private var appIn: ByteBuffer = ByteBuffer.allocate(engine.session.applicationBufferSize)

    /** Version exchange, TLS handshake and auth-complete, all on channel 0 in the clear. */
    fun handshake() {
        Log.i(TAG, "sent version request")
        writeFrame(0, Flags.PLAIN_CONTROL, plain(AapSession.VERSION_REQUEST, byteArrayOf(0, 1, 0, 2)))
        val version = readPlainControl(AapSession.VERSION_RESPONSE)
        Log.i(TAG, "version response ${version.size} bytes")
        if (version.size >= 8 && version[6] == 0xFF.toByte() && version[7] == 0xFF.toByte()) {
            throw IOException("Versi protokol Android Auto tidak cocok")
        }
        engine.beginHandshake()
        Log.i(TAG, "tls handshake start")
        while (true) {
            when (engine.handshakeStatus) {
                HandshakeStatus.NEED_WRAP -> {
                    val out = ByteBuffer.allocate(engine.session.packetBufferSize)
                    val result = engine.wrap(ByteBuffer.allocate(0), out)
                    if (result.status == Status.CLOSED) throw SSLException("TLS ditutup saat handshake")
                    if (out.position() > 0) writeFrame(0, Flags.PLAIN_CONTROL, plain(AapSession.SSL_HANDSHAKE, out.array().copyOf(out.position())))
                }
                HandshakeStatus.NEED_UNWRAP -> {
                    (netIn as Buffer).flip()
                    val result = engine.unwrap(netIn, appIn)
                    netIn.compact()
                    (appIn as Buffer).clear()
                    if (result.status == Status.CLOSED) throw SSLException("Android Auto menutup TLS")
                    if (result.status == Status.BUFFER_UNDERFLOW || result.bytesConsumed() == 0 && netIn.position() == 0) {
                        val record = readPlainControl(AapSession.SSL_HANDSHAKE)
                        appendNet(record, 2, record.size - 2)
                    }
                }
                HandshakeStatus.NEED_TASK -> while (true) { (engine.delegatedTask ?: break).run() }
                else -> break
            }
        }
        Log.i(TAG, "tls handshake done, sending auth complete")
        writeFrame(0, Flags.PLAIN_CONTROL, plain(AapSession.AUTH_COMPLETE, Proto().int(1, 0).build()))
    }

    /** Blocks for the next complete message. */
    fun read(): AapMessage {
        while (true) {
            val (channel, flags, payload) = readFrame()
            Log.i(TAG, "rx frame ch=$channel flags=0x${flags.toString(16)} len=${payload.size}")
            val plain = if (flags and Flags.ENCRYPTED != 0) decrypt(payload) else payload
            val message = reassembler.add(channel, flags, plain) ?: continue
            if (message.size < 2) continue
            Log.i(TAG, "rx msg ch=$channel type=0x${u16(message, 0).toString(16)}")
            return AapMessage(channel, u16(message, 0), message)
        }
    }

    override fun send(channel: Int, type: Int, body: ByteArray) {
        Log.i(TAG, "tx msg ch=$channel type=0x${type.toString(16)} body=${body.size}")
        var flags = Flags.ENCRYPTED or Flags.FIRST or Flags.LAST
        if (channel != AapSession.CONTROL && AapSession.isControlType(type)) flags = flags or Flags.CONTROL
        synchronized(writeLock) {
            val source = ByteBuffer.wrap(plain(type, body))
            var out = ByteBuffer.allocate(engine.session.packetBufferSize)
            while (source.hasRemaining()) {
                val result = engine.wrap(source, out)
                when (result.status) {
                    Status.BUFFER_OVERFLOW -> out = ByteBuffer.allocate(out.capacity() * 2).put(out.flipped())
                    Status.CLOSED -> throw SSLException("TLS sudah ditutup")
                    else -> Unit
                }
            }
            writeFrame(channel, flags, out.array().copyOf(out.position()))
        }
    }

    fun close() = runCatching { socket.close() }

    private fun decrypt(payload: ByteArray): ByteArray {
        appendNet(payload, 0, payload.size)
        val plain = ByteArrayOutputStream()
        (netIn as Buffer).flip()
        try {
            while (netIn.hasRemaining()) {
                val result = engine.unwrap(netIn, appIn)
                when (result.status) {
                    Status.BUFFER_OVERFLOW -> { appIn = ByteBuffer.allocate(appIn.capacity() * 2).put(appIn.flipped()); continue }
                    Status.BUFFER_UNDERFLOW -> break
                    Status.CLOSED -> throw SSLException("Android Auto menutup TLS")
                    Status.OK -> Unit
                }
                plain.write(appIn.array(), 0, appIn.position())
                (appIn as Buffer).clear()
                if (result.bytesConsumed() == 0) break
            }
        } finally {
            netIn.compact()
        }
        return plain.toByteArray()
    }

    private fun appendNet(data: ByteArray, offset: Int, length: Int) {
        if (netIn.remaining() < length) {
            netIn = ByteBuffer.allocate(netIn.position() + length + engine.session.packetBufferSize).put(netIn.flipped())
        }
        netIn.put(data, offset, length)
    }

    private fun readPlainControl(expected: Int): ByteArray {
        while (true) {
            val (channel, flags, payload) = readFrame()
            if (channel != 0 || flags and Flags.ENCRYPTED != 0 || payload.size < 2) continue
            if (u16(payload, 0) == expected) return payload
        }
    }

    private fun readFrame(): Triple<Int, Int, ByteArray> {
        val channel = input.readUnsignedByte()
        val flags = input.readUnsignedByte()
        val length = input.readUnsignedShort()
        // A first fragment of a split message also carries the 4-byte total length.
        if (flags and Flags.FIRST != 0 && flags and Flags.LAST == 0) input.readInt()
        val payload = ByteArray(length)
        input.readFully(payload)
        return Triple(channel, flags, payload)
    }

    private fun writeFrame(channel: Int, flags: Int, payload: ByteArray) {
        require(payload.size <= 0xFFFF) { "Frame AAP terlalu besar" }
        synchronized(output) {
            output.write(byteArrayOf(channel.toByte(), flags.toByte(), (payload.size shr 8).toByte(), payload.size.toByte()))
            output.write(payload)
            output.flush()
        }
    }

    private fun plain(type: Int, body: ByteArray) =
        byteArrayOf((type shr 8).toByte(), type.toByte()) + body

    private fun u16(data: ByteArray, at: Int) =
        ((data[at].toInt() and 0xFF) shl 8) or (data[at + 1].toInt() and 0xFF)

    private companion object { const val TAG = "DashTAA" }

    // Buffer-typed calls: ByteBuffer's covariant flip()/clear() are missing on older Android.
    private fun ByteBuffer.flipped(): ByteBuffer = apply { (this as Buffer).flip() }

    /** The peer is Android Auto on this same phone over loopback; its certificate is not pinned. */
    private object TrustPhone : X509TrustManager {
        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
        override fun getAcceptedIssuers() = emptyArray<X509Certificate>()
    }
}
