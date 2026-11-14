package io.github.farhanreninda.dashtconnect.receiver

import com.shilapi.xcertplay.network.WifiP2pChannels
import org.junit.Assert.assertEquals
import org.junit.Test

class ReceiverWifiChannelTest {
    @Test fun sharesNonDfsFiveGhzStationChannel() {
        assertEquals(149, receiverP2pChannel(5745))
        assertEquals(36, receiverP2pChannel(5180))
        assertEquals(165, receiverP2pChannel(5825))
    }

    @Test fun otherwiseStaysOnTwoGhzBand() {
        for (mhz in listOf(-1, 2437, 5260, 5500)) assertEquals(WifiP2pChannels.AUTO_2_4_GHZ, receiverP2pChannel(mhz))
    }
}
