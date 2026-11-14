package io.github.farhanreninda.dashtconnect.aap

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AapSessionTest {
    private class Sent(val channel: Int, val type: Int, val body: ByteArray)

    private val sent = ArrayList<Sent>()
    private val frames = ArrayList<ByteArray>()
    private val configs = ArrayList<ByteArray>()
    private val session = AapSession(
        { channel, type, body -> sent.add(Sent(channel, type, body)) },
        VideoSpec.forScreen(2400, 1080),
        object : VideoSink {
            override fun codecConfig(data: ByteArray, offset: Int, length: Int) { configs.add(data.copyOfRange(offset, offset + length)) }
            override fun frame(data: ByteArray, offset: Int, length: Int) { frames.add(data.copyOfRange(offset, offset + length)) }
        },
        "1.0",
    )

    @Test fun protoEncodesVarintsStringsAndNegativeEnums() {
        assertArrayEquals(byteArrayOf(0x08, 0x96.toByte(), 0x01), Proto().int(1, 150).build())
        assertArrayEquals(byteArrayOf(0x12, 2, 'h'.code.toByte(), 'i'.code.toByte()), Proto().string(2, "hi").build())
        assertEquals(11, Proto().int(1, -1).build().size)
        assertEquals(mapOf(1 to 150L, 3 to 7L), readVarints(Proto().int(1, 150).string(2, "x").int(3, 7).build()))
    }

    @Test fun videoSpecMatchesScreenAspect() {
        assertEquals(VideoSpec(0, 144), VideoSpec.forScreen(2400, 1080))
        assertEquals(VideoSpec(0, 144), VideoSpec.forScreen(1080, 2400))
        assertEquals(VideoSpec(320, 0), VideoSpec.forScreen(1024, 768))
    }

    @Test fun reassemblerJoinsFragmentsPerChannel() {
        val r = Reassembler()
        assertNull(r.add(2, Flags.ENCRYPTED or Flags.FIRST, byteArrayOf(1, 2)))
        assertArrayEquals(byteArrayOf(9), r.add(0, Flags.ENCRYPTED or Flags.FIRST or Flags.LAST, byteArrayOf(9)))
        assertNull(r.add(2, Flags.ENCRYPTED, byteArrayOf(3)))
        assertArrayEquals(byteArrayOf(1, 2, 3, 4), r.add(2, Flags.ENCRYPTED or Flags.LAST, byteArrayOf(4)))
        assertNull(r.add(2, Flags.ENCRYPTED or Flags.LAST, byteArrayOf(5)))
    }

    @Test fun answersDiscoveryWithVideoInputAndSensors() {
        session.handle(0, AapSession.SERVICE_DISCOVERY_REQUEST, ByteArray(0))
        val reply = sent.single()
        assertEquals(AapSession.SERVICE_DISCOVERY_RESPONSE, reply.type)
        val text = String(reply.body, Charsets.ISO_8859_1)
        assertTrue(text.contains("DashTConnect"))
        assertEquals(AapSession.DRIVER_POSITION_RIGHT.toLong(), readVarints(reply.body)[6])
    }

    @Test fun opensChannelsAndEchoesPing() {
        session.handle(3, AapSession.CHANNEL_OPEN_REQUEST, Proto().int(1, 0).int(2, 3).build())
        session.handle(0, AapSession.PING_REQUEST, Proto().int(1, 1234).build())
        assertEquals(3, sent[0].channel)
        assertEquals(AapSession.CHANNEL_OPEN_RESPONSE, sent[0].type)
        assertEquals(mapOf(1 to 0L), readVarints(sent[0].body))
        assertEquals(AapSession.PING_RESPONSE, sent[1].type)
        assertEquals(1234L, readVarints(sent[1].body)[1])
        assertTrue(session.inputOpen)
    }

    @Test fun drivingStatusIsUnrestrictedAfterSensorStart() {
        session.handle(1, AapSession.SENSOR_START_REQUEST, Proto().int(1, AapSession.SENSOR_DRIVING_STATUS).int(2, 0).build())
        assertEquals(listOf(AapSession.SENSOR_START_RESPONSE, AapSession.SENSOR_EVENT), sent.map { it.type })
        assertArrayEquals(Proto().message(13) { int(1, 0) }.build(), sent[1].body)
    }

    @Test fun videoSetupStartAndFramesAreAcked() {
        session.handle(2, AapSession.MEDIA_SETUP, Proto().int(1, 3).build())
        session.handle(2, AapSession.MEDIA_START, Proto().int(1, 7).int(2, 0).build())
        session.handle(2, AapSession.MEDIA_CODEC_CONFIG, byteArrayOf(0, 0, 0, 1, 0x67))
        session.handle(2, AapSession.MEDIA_DATA, byteArrayOf(0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 1, 0x65))
        assertEquals(
            listOf(AapSession.MEDIA_CONFIG, AapSession.VIDEO_FOCUS_NOTIFICATION, AapSession.MEDIA_ACK, AapSession.MEDIA_ACK),
            sent.map { it.type },
        )
        assertEquals(mapOf(1 to 2L, 2 to 1L, 3 to 0L), readVarints(sent[0].body))
        assertEquals(mapOf(1 to 7L, 2 to 1L), readVarints(sent[3].body))
        assertArrayEquals(byteArrayOf(0, 0, 0, 1, 0x67), configs.single())
        assertArrayEquals(byteArrayOf(0, 0, 0, 1, 0x65), frames.single())
    }

    @Test fun touchIsDroppedUntilInputChannelOpens() {
        session.touch(0, 0, listOf(AapSession.Pointer(0, 10, 20)), 1)
        assertTrue(sent.isEmpty())
        session.handle(3, AapSession.CHANNEL_OPEN_REQUEST, ByteArray(0))
        session.touch(0, 0, listOf(AapSession.Pointer(0, 10, 20)), 1)
        assertEquals(AapSession.INPUT_EVENT, sent.last().type)
        assertEquals(3, sent.last().channel)
    }

    @Test fun byeByeEndsSession() {
        session.handle(0, AapSession.BYEBYE_REQUEST, Proto().int(1, 1).build())
        assertEquals(AapSession.BYEBYE_RESPONSE, sent.single().type)
        assertTrue(session.ended)
    }
}
