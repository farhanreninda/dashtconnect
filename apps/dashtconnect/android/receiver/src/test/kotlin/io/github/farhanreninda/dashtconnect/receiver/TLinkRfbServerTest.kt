package io.github.farhanreninda.dashtconnect.receiver

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.util.zip.Inflater

class TLinkRfbServerTest {
    private val frame = RfbFrame(2, 1, byteArrayOf(10, 20, 30, -1, 40, 50, 60, -1), seq = 1)

    private fun session(
        width: Int = 2,
        frames: () -> RfbFrame = { frame },
        client: DataOutputStream.() -> Unit,
    ): Pair<DataInputStream, List<String>> {
        val request = ByteArrayOutputStream().also { DataOutputStream(it).client() }
        val response = ByteArrayOutputStream()
        val logs = mutableListOf<String>()
        TLinkRfbServer(ByteArrayInputStream(request.toByteArray()), response, width, 1, frames, { logs += it }).run()
        return DataInputStream(response.toByteArray().inputStream()) to logs
    }

    private fun DataInputStream.expectHandshake() {
        assertEquals("RFB 003.008\n", String(ByteArray(12).also { readFully(it) }))
        assertEquals(1, readUnsignedByte()); assertEquals(1, readUnsignedByte()) // one type: None
        assertEquals(0, readInt()) // security OK
        skipBytes(4) // width, height
        skipBytes(16)
        assertEquals("DashTConnect", String(ByteArray(readInt()).also { readFully(it) }))
    }

    @Test
    fun servesRawFrameAfterHandshake() {
        val (server, logs) = session {
            write("RFB 003.008\n".toByteArray()); writeByte(1); writeByte(1)
            writeByte(2); writeByte(0); writeShort(2); writeInt(0); writeInt(-223)
            writeByte(3); writeByte(0); writeShort(0); writeShort(0); writeShort(2); writeShort(1)
        }
        server.expectHandshake()
        assertEquals(0, server.readUnsignedByte()); server.skipBytes(1)
        assertEquals(1, server.readUnsignedShort())
        server.skipBytes(8)
        assertEquals(0, server.readInt()) // Raw
        assertArrayEquals(frame.rgba, ByteArray(8).also { server.readFully(it) })
        assertTrue(logs.any { it == "tlink encodings [0, -223], using Raw" })
    }

    @Test
    fun convertsToClientRgb565() {
        val (server, _) = session {
            write("RFB 003.008\n".toByteArray()); writeByte(1); writeByte(1)
            writeByte(0); write(ByteArray(3))
            write(TLinkRfbServer.PixelFormat(16, 16, false, true, 31, 63, 31, 11, 5, 0).toBytes())
            writeByte(3); writeByte(0); writeShort(0); writeShort(0); writeShort(2); writeShort(1)
        }
        server.expectHandshake()
        server.skipBytes(4 + 12)
        // r=10*31/255=1, g=20*63/255=4, b=30*31/255=3 -> 0x0883 little-endian
        assertArrayEquals(byteArrayOf(0x83.toByte(), 0x08), ByteArray(2).also { server.readFully(it) })
    }

    @Test
    fun logsNonRfbReplyAndStops() {
        val (_, logs) = session { write("hello-tlink!".toByteArray()) }
        assertTrue(logs.any { it.startsWith("tlink not RFB") })
    }

    private fun DataOutputStream.hello() { write("RFB 003.008\n".toByteArray()); writeByte(1); writeByte(1) }
    private fun DataOutputStream.encodings(vararg list: Int) { writeByte(2); writeByte(0); writeShort(list.size); list.forEach { writeInt(it) } }
    private fun DataOutputStream.request(incremental: Boolean, width: Int) {
        writeByte(3); writeByte(if (incremental) 1 else 0); writeShort(0); writeShort(0); writeShort(width); writeShort(1)
    }

    @Test
    fun zrleTilesInflateToCompactPixels() {
        val inflater = Inflater()
        val (server, _) = session {
            hello(); encodings(16, 0); request(false, 2)
        }
        server.expectHandshake()
        server.skipBytes(2); assertEquals(1, server.readUnsignedShort())
        server.skipBytes(8)
        assertEquals(16, server.readInt())
        inflater.setInput(ByteArray(server.readInt()).also { server.readFully(it) })
        val tile = ByteArray(7).also { assertEquals(7, inflater.inflate(it)) }
        // subencoding 0 (raw), then R,G,B per pixel: the unused fourth byte is dropped
        assertArrayEquals(byteArrayOf(0, 10, 20, 30, 40, 50, 60), tile)
    }

    @Test
    fun incrementalUpdateSendsOnlyChangedTiles() {
        val first = ByteArray(130 * 4) { 0 }
        val second = first.copyOf().also { it[100 * 4] = 9 } // pixel 100 sits in the second 64px tile
        var calls = 0
        val (server, _) = session(width = 130, frames = {
            RfbFrame(130, 1, if (calls++ == 0) first else second, seq = calls.toLong())
        }) {
            hello(); request(false, 130); request(true, 130)
        }
        server.expectHandshake()
        server.skipBytes(2); assertEquals(3, server.readUnsignedShort())
        repeat(3) { server.skipBytes(4); val w = server.readUnsignedShort(); server.skipBytes(6 + w * 4) }
        server.skipBytes(2); assertEquals(1, server.readUnsignedShort())
        assertEquals(64, server.readUnsignedShort()) // x of the only changed tile
    }
}
