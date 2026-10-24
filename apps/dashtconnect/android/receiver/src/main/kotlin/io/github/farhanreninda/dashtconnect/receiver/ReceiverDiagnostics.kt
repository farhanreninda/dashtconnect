package io.github.farhanreninda.dashtconnect.receiver

private val protocolMessage = Regex("^iap2 (rx|tx)=0x[0-9a-fA-F]{4}")

internal fun receiverProtocolDiagnostic(message: String): String? =
    protocolMessage.find(message)?.value ?: message.takeIf {
        it == "iap2 identification accepted" || it == "iap2 authentication accepted"
    }
