package io.github.farhanreninda.dashtconnect.receiver

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Base64
import com.shilapi.xcertplay.airplay.AirPlayIdentity
import com.shilapi.xcertplay.airplay.PairingStore
import com.shilapi.xcertplay.mfi.LocalMfiAuthenticationClient
import java.io.File

internal fun receiverHardwareAddress(value: String?): String? = value?.uppercase()?.takeIf {
    Regex("[0-9A-F]{2}(:[0-9A-F]{2}){5}").matches(it) &&
        it !in setOf("02:00:00:00:00:00", "00:00:00:00:00:00", "FF:FF:FF:FF:FF:FF")
}

object ReceiverIdentity {
    fun authenticationAvailable(context: Context): Boolean =
        listOf("identity.pk8", "certificate.p7b").all { name ->
            val file = File(context.filesDir, "offline-mfi/$name")
            file.isFile || runCatching {
                context.assets.open("offline-mfi/$name").use { it.read() >= 0 }
            }.getOrDefault(false)
        }

    internal fun authentication(context: Context): LocalMfiAuthenticationClient {
        val directory = File(context.filesDir, "offline-mfi")
        if (listOf("identity.pk8", "certificate.p7b").all { File(directory, it).isFile }) {
            return LocalMfiAuthenticationClient.load(directory)
        }
        val staging = File(context.cacheDir, "receiver-auth-" + java.util.UUID.randomUUID())
        check(staging.mkdirs() || staging.isDirectory)
        try {
            for (name in listOf("identity.pk8", "certificate.p7b")) {
                val bytes = context.assets.open("offline-mfi/$name").use { stream ->
                    val output = java.io.ByteArrayOutputStream()
                    val buffer = ByteArray(1024)
                    while (true) {
                        val count = stream.read(buffer)
                        if (count < 0) break
                        require(output.size() + count <= 16 * 1024) { "Accessory identity too large" }
                        output.write(buffer, 0, count)
                    }
                    val data = output.toByteArray()
                    require(data.size in 1..16 * 1024) { "Invalid accessory identity size" }
                    data
                }
                try { File(staging, name).writeBytes(bytes) } finally { bytes.fill(0) }
            }
            return LocalMfiAuthenticationClient.load(staging)
        } finally {
            listOf("identity.pk8", "certificate.p7b").forEach { File(staging, it).delete() }
            staging.delete()
        }
    }

    internal fun identity(context: Context): AirPlayIdentity {
        val preferences = context.getSharedPreferences("receiver_identity", Context.MODE_PRIVATE)
        return synchronized(this) {
            val privateKey = preferences.getString("private", null)
            val publicKey = preferences.getString("public", null)
            val pairingId = preferences.getString("pairingId", null)
            if (privateKey != null && publicKey != null && pairingId != null) {
                AirPlayIdentity(decode(privateKey), decode(publicKey), pairingId).also {
                    require(it.privateKey.size == 32 && it.publicKey.size == 32)
                }
            } else {
                AirPlayIdentity.generate().also {
                    check(preferences.edit()
                        .putString("private", encode(it.privateKey))
                        .putString("public", encode(it.publicKey))
                        .putString("pairingId", it.pairingId).commit())
                }
            }
        }
    }

    internal fun pairings(context: Context): PairingStore {
        val preferences = context.getSharedPreferences("receiver_pairings", Context.MODE_PRIVATE)
        return PairingStore { id, key ->
            require(id.length in 1..512 && key.size == 32)
            require(preferences.contains(id) || preferences.all.size < 32) { "Pairing storage full" }
            check(preferences.edit().putString(id, encode(key)).commit())
        }.also { store ->
            preferences.all.forEach { (id, value) ->
                if (value is String) store.save(id, decode(value))
            }
        }
    }

    private fun encode(bytes: ByteArray) = Base64.encodeToString(bytes, Base64.NO_WRAP)
    private fun decode(text: String) = Base64.decode(text, Base64.NO_WRAP)
}

object ReceiverNetworkStatus {
    fun hasInternetNetwork(context: Context): Boolean {
        val connectivity = context.getSystemService(ConnectivityManager::class.java)
        return connectivity.allNetworks.any { network ->
            connectivity.getNetworkCapabilities(network)
                ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        }
    }

}
