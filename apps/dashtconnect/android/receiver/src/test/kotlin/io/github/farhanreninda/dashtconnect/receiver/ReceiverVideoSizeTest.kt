package io.github.farhanreninda.dashtconnect.receiver

import org.junit.Assert.assertEquals
import org.junit.Test

class ReceiverVideoSizeTest {
    @Test fun matchesLandscapeAspectWithoutIncreasingDecoderWidth() {
        assertEquals(ReceiverVideoSize(1280, 576), ReceiverVideoSize.forDisplay(1600, 720))
        assertEquals(ReceiverVideoSize(1280, 576), ReceiverVideoSize.forDisplay(720, 1600))
        assertEquals(ReceiverVideoSize(1280, 720), ReceiverVideoSize.forDisplay(1920, 1080))
        assertEquals(0, ReceiverVideoSize.forDisplay(2340, 1080).height % 2)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsEmptyDisplay() { ReceiverVideoSize.forDisplay(0, 720) }
}
