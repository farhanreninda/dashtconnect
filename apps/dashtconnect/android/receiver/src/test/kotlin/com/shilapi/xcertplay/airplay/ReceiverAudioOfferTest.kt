package com.shilapi.xcertplay.airplay

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReceiverAudioOfferTest {
    private val config = AirPlayConfig(
        deviceName = "test", deviceId = "02:00:00:00:00:01", btMac = "02:00:00:00:00:02",
        sourceVersion = "950.7.1", main = AirPlayDisplayConfig(1280, 720),
        mainBufferedAudio = true, microphone = false,
    )

    @Test fun bufferedAudioOffersAacWithoutInventingMicrophoneSupport() {
        val info = AirPlayInfoPlist.build(config)
        val formats = (info["audioFormats"] as List<*>).filterIsInstance<Map<*, *>>()
        val buffered = formats.single { it["type"] == 103 }
        assertEquals("media", buffered["audioType"])
        assertEquals(0x800000, buffered["audioOutputFormats"])
        assertFalse(buffered.containsKey("audioInputFormats"))
        assertTrue(info.containsKey("mainBufferedInfo"))
    }

    @Test fun bufferedAudioNegotiationRequiresThePhoneProposalAndEnabledOutput() {
        assertTrue(setupEnabledFeatures(config, listOf("mainBuffered")).contains("mainBuffered"))
        assertFalse(setupEnabledFeatures(config, emptyList<Any>()).contains("mainBuffered"))
        val disabled = config.copy(disableAudioOutput = true)
        assertFalse(setupEnabledFeatures(disabled, listOf("mainBuffered")).contains("mainBuffered"))
        val info = AirPlayInfoPlist.build(disabled)
        assertFalse(info.containsKey("mainBufferedInfo"))
        assertFalse(info.containsKey("audioFormats"))
    }

    @Test fun microphoneOffersInputForVoiceAndAppAudioButNotMusic() {
        val info = AirPlayInfoPlist.build(config.copy(microphone = true))
        val formats = (info["audioFormats"] as List<*>).filterIsInstance<Map<*, *>>()
        for (audioType in listOf("default", "telephony", "speechRecognition")) {
            val input = formats.single { it["type"] == 100 && it["audioType"] == audioType }
            assertTrue((input["audioInputFormats"] as Int) > 0)
        }
        assertTrue(formats.filter { it["audioType"] == "media" }
            .none { it.containsKey("audioInputFormats") })
    }
}
