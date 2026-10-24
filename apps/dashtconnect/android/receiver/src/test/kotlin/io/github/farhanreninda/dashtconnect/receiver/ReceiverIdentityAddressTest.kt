package io.github.farhanreninda.dashtconnect.receiver

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ReceiverIdentityAddressTest {
    @Test fun rejectsMaskedAndInvalidAddressesBeforeAdvertisingThem() {
        for (value in listOf(null, "", "invalid", "02:00:00:00:00:00", "00:00:00:00:00:00", "ff:ff:ff:ff:ff:ff")) {
            assertNull(receiverHardwareAddress(value))
        }
        assertEquals("AA:BB:CC:DD:EE:01", receiverHardwareAddress("aa:bb:cc:dd:ee:01"))
    }
}
