package com.shilapi.xcertplay.network

import java.util.Locale

internal object P2pNetworkName {
    fun forBrand(brand: String, token: String): String {
        require(token.matches(Regex("[A-Za-z0-9]{2}")))
        val label = brand.uppercase(Locale.ROOT).replace(Regex("[^A-Z0-9]+"), " ")
            .trim().take(14).trim().ifEmpty { "ANDROID" }
        return "DIRECT-$token-$label CARPLAY"
    }
}
