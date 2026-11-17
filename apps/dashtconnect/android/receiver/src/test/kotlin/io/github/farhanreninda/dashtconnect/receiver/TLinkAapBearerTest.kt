package io.github.farhanreninda.dashtconnect.receiver

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

class TLinkAapBearerTest {
    /** Keeps USB transfer boundaries: each write is one transfer, each read returns one transfer. */
    private class Usb {
        val toPhone = LinkedBlockingQueue<ByteArray>()
        val fromPhone = LinkedBlockingQueue<ByteArray>()
        val phoneIn = object : InputStream() {
            override fun read() = throw UnsupportedOperationException()
            override fun read(b: ByteArray, off: Int, len: Int): Int {
                val t = toPhone.take()
                if (t.isEmpty()) return -1
                System.arraycopy(t, 0, b, off, t.size)
                return t.size
            }
        }
        val phoneOut = object : OutputStream() {
            override fun write(b: Int) = write(byteArrayOf(b.toByte()))
            override fun write(b: ByteArray, off: Int, len: Int) { fromPhone.put(b.copyOfRange(off, off + len)) }
        }
        fun next(): ByteArray = fromPhone.poll(3, TimeUnit.SECONDS) ?: error("phone sent nothing")
    }

    private val device = ByteArray(16) { (it + 1).toByte() }
    private val host = ByteArray(16) { (0xA0 + it).toByte() }

    @Test
    fun v2HandshakeThenFramedTrafficBothWays() {
        val usb = Usb()
        val bearer = TLinkAapBearer(usb.phoneIn, usb.phoneOut, {}, device)
        val established = Thread { bearer.establish(5_000) }.apply { start() }

        assertArrayEquals(TLinkAapBearer.MAGIC + device + ByteArray(16), usb.next())
        assertArrayEquals(TLinkAapBearer.DEVICE_HANDSHAKE, usb.next())
        usb.toPhone.put(TLinkAapBearer.MAGIC + host + device)
        established.join(3_000)
        assertEquals(2, bearer.version)

        bearer.output.write("RFB 003.008\n".toByteArray())
        assertArrayEquals(TLinkAapBearer.MAGIC + device + host + "RFB 003.008\n".toByteArray(), usb.next())

        val rx = TLinkAapBearer.MAGIC + host + device
        usb.toPhone.put(rx) // header-only keepalive from the head unit is skipped
        usb.toPhone.put(rx + "RFB 003.008\n".toByteArray())
        val got = ByteArray(12)
        var n = 0
        while (n < 12) n += bearer.input.read(got, n, 12 - n)
        assertEquals("RFB 003.008\n", String(got))
        bearer.close()
    }

    @Test
    fun hostReplyStartsRawV1() {
        val usb = Usb()
        val bearer = TLinkAapBearer(usb.phoneIn, usb.phoneOut, {}, device)
        val established = Thread { bearer.establish(5_000) }.apply { start() }
        usb.next(); usb.next()
        usb.toPhone.put(TLinkAapBearer.HOST_HANDSHAKE)
        established.join(3_000)
        assertEquals(1, bearer.version)
        bearer.output.write(byteArrayOf(1, 2, 3))
        assertArrayEquals(byteArrayOf(1, 2, 3), usb.next())
    }

    @Test
    fun packetLengthNeverAMultipleOf512() {
        assertEquals(467, TLinkAapBearer.payloadSize(468, 44)) // 44 + 468 = 512 would be one
        assertEquals(1000, TLinkAapBearer.payloadSize(1000, 44))
        assertEquals(15827, TLinkAapBearer.payloadSize(100_000, 44))
        assertEquals(0, TLinkAapBearer.payloadSize(0, 44))
    }
}
