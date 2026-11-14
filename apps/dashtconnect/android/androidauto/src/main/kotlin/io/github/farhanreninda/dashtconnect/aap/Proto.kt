package io.github.farhanreninda.dashtconnect.aap

import java.io.ByteArrayOutputStream

/** Minimal proto2 encoder for the few messages a head unit sends. */
internal class Proto {
    private val out = ByteArrayOutputStream()

    private fun varint(value: Long) {
        var v = value
        while (v and 0x7FL.inv() != 0L) {
            out.write(((v and 0x7F) or 0x80).toInt())
            v = v ushr 7
        }
        out.write(v.toInt())
    }

    // Negative int32/enum values sign-extend to ten bytes, as proto2 requires.
    fun int(field: Int, value: Long) = apply { varint((field shl 3).toLong()); varint(value) }
    fun int(field: Int, value: Int) = int(field, value.toLong())
    fun bool(field: Int, value: Boolean) = int(field, if (value) 1 else 0)
    fun bytes(field: Int, value: ByteArray) = apply {
        varint(((field shl 3) or 2).toLong())
        varint(value.size.toLong())
        out.write(value)
    }
    fun string(field: Int, value: String) = bytes(field, value.toByteArray())
    fun message(field: Int, block: Proto.() -> Unit) = bytes(field, Proto().apply(block).build())
    fun build(): ByteArray = out.toByteArray()
}

/** Top-level varint fields of a message; other wire types are skipped. Last value wins. */
internal fun readVarints(data: ByteArray, offset: Int = 0, end: Int = data.size): Map<Int, Long> {
    val fields = HashMap<Int, Long>()
    var i = offset
    fun next(): Long {
        var shift = 0
        var result = 0L
        while (true) {
            require(i < end && shift < 64) { "Varint AAP rusak" }
            val b = data[i++].toInt()
            result = result or ((b and 0x7F).toLong() shl shift)
            if (b and 0x80 == 0) return result
            shift += 7
        }
    }
    while (i < end) {
        val key = next()
        val field = (key ushr 3).toInt()
        when ((key and 7).toInt()) {
            0 -> fields[field] = next()
            1 -> i += 8
            2 -> { val length = next().toInt(); i += length }
            5 -> i += 4
            else -> throw IllegalArgumentException("Wire type AAP tidak dikenal")
        }
        require(i in 0..end) { "Panjang field AAP melewati pesan" }
    }
    return fields
}
