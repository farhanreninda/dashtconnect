package io.github.farhanreninda.dashtconnect.receiver

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ReceiverDiagnosticsTest {
    @Test fun protocolLogRetainsStageWithoutPayload() {
        assertEquals("iap2 rx=0x4e0e", receiverProtocolDiagnostic(
            "iap2 rx=0x4e0e device-transport-identifier bluetooth=private; ssid=private password=private"))
        assertEquals("iap2 authentication accepted", receiverProtocolDiagnostic("iap2 authentication accepted"))
        assertNull(receiverProtocolDiagnostic("ssid=private password=private"))
        assertNull(receiverProtocolDiagnostic("iap2 authentication accepted private-payload"))
    }
}
