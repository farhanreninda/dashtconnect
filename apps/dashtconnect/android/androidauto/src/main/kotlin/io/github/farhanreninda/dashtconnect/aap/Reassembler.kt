package io.github.farhanreninda.dashtconnect.aap

import java.io.ByteArrayOutputStream

internal object Flags {
    const val FIRST = 0x01
    const val LAST = 0x02
    const val CONTROL = 0x04
    const val ENCRYPTED = 0x08
    const val PLAIN_CONTROL = FIRST or LAST
}

/** Joins fragmented plaintext per channel into whole messages (type + body). */
internal class Reassembler(private val limit: Int = 8 shl 20) {
    private val partial = HashMap<Int, ByteArrayOutputStream>()

    fun add(channel: Int, flags: Int, plain: ByteArray): ByteArray? {
        val first = flags and Flags.FIRST != 0
        val last = flags and Flags.LAST != 0
        if (first && last) {
            partial.remove(channel)
            return plain
        }
        val buffer = if (first) ByteArrayOutputStream().also { partial[channel] = it }
            else partial[channel] ?: return null
        buffer.write(plain)
        if (buffer.size() > limit) {
            partial.remove(channel)
            throw IllegalStateException("Pesan AAP melebihi batas")
        }
        if (!last) return null
        partial.remove(channel)
        return buffer.toByteArray()
    }
}
