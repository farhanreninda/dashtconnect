package com.shilapi.xcertplay.media

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ReceiverMediaTimingTest {
    @Test fun musicReserveCoversObservedReceiveGapWithoutIncreasingVoiceBuffer() {
        val music = MediaAudioBuffer.plan(true, 48000, 2, 4096, MediaAudioBuffer.MOST_STABLE_MILLIS)
        val missingBytes = 48000 * 2 * 2 * 620 / 1000
        assertTrue(music.startBytes > missingBytes)
        assertTrue(music.trackBufferBytes > music.startBytes)
        val voice = MediaAudioBuffer.plan(false, 48000, 1, 4096, MediaAudioBuffer.MOST_STABLE_MILLIS)
        assertEquals(MediaAudioBuffer.plan(false, 48000, 1, 4096, 300), voice)
        assertTrue(voice.startBytes * 1000L / (48000 * 2) < 100)
    }

    @Test fun frameTimestampsRemainEvenWhenFramesArriveInABurst() {
        val pacer = FramePacer()
        val interval = 33_333_333L
        val base = 2_000_000_000L
        repeat(30) { i -> pacer.localTime((i + 1) * interval, base + (i + 1) * interval) }
        val arrival = base + 33 * interval
        val frames = (31..33).map { i -> pacer.localTime(i * interval, arrival) }
        assertEquals(interval, frames[1] - frames[0])
        assertEquals(interval, frames[2] - frames[1])
        val delay = PacingDelay(140_000_000L)
        repeat(1000) { delay.onFrame(5_000_000_000L) }
        assertEquals(200_000_000L, delay.nanos)
    }
}
