package com.shilapi.xcertplay.network

import org.junit.Assert.*
import org.junit.Test

class P2pNetworkNameTest {
    @Test fun usesBrandWithinAndroidNamingAndByteLimits() {
        assertEquals("DIRECT-Ab-SAMSUNG CARPLAY", P2pNetworkName.forBrand("samsung", "Ab"))
        assertEquals("DIRECT-7x-XIAOMI CARPLAY", P2pNetworkName.forBrand("Xiaomi", "7x"))
        for (brand in listOf("", "厂商", "a".repeat(80), "ACME\nPhone")) {
            val name = P2pNetworkName.forBrand(brand, "Ab")
            assertTrue(name.toByteArray(Charsets.UTF_8).size <= 32)
            assertTrue(name.matches(Regex("DIRECT-[A-Za-z0-9]{2}-[A-Z0-9 ]+ CARPLAY")))
            assertTrue(P2pOwnership.canReclaim(true, name, name, "DIRECT-owned-"))
            assertFalse(P2pOwnership.canReclaim(true, name, null, "DIRECT-owned-"))
        }
    }
}
