package io.github.farhanreninda.dashtconnect.aap

import android.content.res.AssetManager
import android.util.Base64
import java.io.FileNotFoundException
import java.net.Socket
import java.security.KeyFactory
import java.security.Principal
import java.security.PrivateKey
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec
import javax.net.ssl.SSLEngine
import javax.net.ssl.X509ExtendedKeyManager

/** Client certificate the phone requires from a head unit. Supplied locally, never from Git. */
internal class HeadUnitIdentity(val certificate: X509Certificate, val key: PrivateKey) {

    /** Always offers this certificate: the phone's CA list does not name its issuer. */
    fun keyManager() = object : X509ExtendedKeyManager() {
        override fun chooseEngineClientAlias(keyType: Array<out String>?, issuers: Array<out Principal>?, engine: SSLEngine?) = ALIAS
        override fun chooseClientAlias(keyType: Array<out String>?, issuers: Array<out Principal>?, socket: Socket?) = ALIAS
        override fun getCertificateChain(alias: String?) = arrayOf(certificate)
        override fun getPrivateKey(alias: String?) = key
        override fun getClientAliases(keyType: String?, issuers: Array<out Principal>?) = arrayOf(ALIAS)
        override fun getServerAliases(keyType: String?, issuers: Array<out Principal>?) = null
        override fun chooseServerAlias(keyType: String?, issuers: Array<out Principal>?, socket: Socket?) = null
    }

    companion object {
        private const val ALIAS = "headunit"
        const val CERTIFICATE = "androidauto/headunit.crt"
        const val KEY = "androidauto/headunit.key"

        fun available(assets: AssetManager) = runCatching { load(assets) }.getOrNull() != null

        /** Null when the identity files are not bundled; throws when they are present but unusable. */
        fun load(assets: AssetManager): HeadUnitIdentity? {
            val certificate = try {
                assets.open(CERTIFICATE).use { CertificateFactory.getInstance("X.509").generateCertificate(it) as X509Certificate }
            } catch (_: FileNotFoundException) { return null }
            val pem = try { assets.open(KEY).use { it.reader().readText() } }
                catch (_: FileNotFoundException) { return null }
            val der = Base64.decode(pem.replace(Regex("-----[^-]+-----|\\s"), ""), Base64.DEFAULT)
            val spec = PKCS8EncodedKeySpec(der)
            val key = runCatching { KeyFactory.getInstance("RSA").generatePrivate(spec) }
                .getOrElse { KeyFactory.getInstance("EC").generatePrivate(spec) }
            return HeadUnitIdentity(certificate, key)
        }
    }
}
