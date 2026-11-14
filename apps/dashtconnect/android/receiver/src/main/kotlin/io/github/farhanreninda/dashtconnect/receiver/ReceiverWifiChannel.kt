package io.github.farhanreninda.dashtconnect.receiver

import com.shilapi.xcertplay.network.WifiP2pChannels

private val nonDfsFiveGhz = listOf(5180, 5200, 5220, 5240, 5745, 5765, 5785, 5805, 5825)

/**
 * Radios without dual-band concurrency (SM-A047F reports mIsDbs=false) hop between the station
 * channel and the CarPlay group, which stalled music and dropped sessions. Share the station's
 * 5 GHz channel; a 2.4 GHz station is already aligned by the 2.4 GHz band plan.
 */
internal fun receiverP2pChannel(stationMHz: Int): Int =
    if (stationMHz in nonDfsFiveGhz) (stationMHz - 5000) / 5 else WifiP2pChannels.AUTO_2_4_GHZ
