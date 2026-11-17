package io.github.farhanreninda.dashtconnect.receiver

import java.io.FilterInputStream
import java.io.FilterOutputStream
import java.io.InputStream
import java.io.OutputStream

/**
 * Logs the first [limit] bytes crossing the USB link in each direction as hex, so a head unit
 * that rejects the phone leaves its exact bytes in the diagnostics log.
 */
class TLinkWireLog(private val log: (String) -> Unit, private val limit: Int = 4096) {
    private var inLogged = 0
    private var outLogged = 0

    fun input(stream: InputStream): InputStream = object : FilterInputStream(stream) {
        override fun read(): Int = super.read().also { if (it >= 0) received(byteArrayOf(it.toByte()), 0, 1) }
        override fun read(b: ByteArray, off: Int, len: Int): Int =
            super.read(b, off, len).also { if (it > 0) received(b, off, it) }
    }

    fun output(stream: OutputStream): OutputStream = object : FilterOutputStream(stream) {
        override fun write(b: ByteArray, off: Int, len: Int) {
            sent(b, off, len)
            out.write(b, off, len)
        }
        override fun write(b: Int) = write(byteArrayOf(b.toByte()), 0, 1)
    }

    @Synchronized private fun received(b: ByteArray, off: Int, len: Int) {
        if (inLogged >= limit) return
        val n = minOf(len, limit - inLogged)
        inLogged += n
        log("tlink rx $len: ${TLinkRfbServer.hex(b.copyOfRange(off, off + n))}")
    }

    @Synchronized private fun sent(b: ByteArray, off: Int, len: Int) {
        if (outLogged >= limit) return
        val n = minOf(len, limit - outLogged)
        outLogged += n
        log("tlink tx $len: ${TLinkRfbServer.hex(b.copyOfRange(off, off + n))}")
    }
}
