package io.github.farhanreninda.dashtconnect.receiver

import android.content.Context
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * On-device CarPlay session log that the owner can share after a drive, where adb is unavailable.
 * Two files of [maxBytes] each are kept. Callers must not pass SSIDs, passphrases or addresses.
 */
class ReceiverSessionLog(private val directory: File, private val maxBytes: Long = 512 * 1024) {
    private val current = File(directory, "carplay.log")
    private val previous = File(directory, "carplay.1.log")
    private val time = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)

    @Synchronized
    fun write(line: String) {
        runCatching {
            directory.mkdirs()
            if (current.length() > maxBytes) {
                previous.delete()
                current.renameTo(previous)
            }
            current.appendText("${time.format(Date())} ${line.take(MAX_LINE)}\n")
        }
    }

    /** Older file first; null when nothing has been recorded yet. */
    @Synchronized
    fun exportTo(target: File): File? {
        val parts = listOf(previous, current).filter { it.isFile && it.length() > 0 }
        if (parts.isEmpty()) return null
        target.parentFile?.mkdirs()
        target.writeText(parts.joinToString("") { it.readText() })
        return target
    }

    companion object {
        private const val MAX_LINE = 1_000
        fun forContext(context: Context) = ReceiverSessionLog(File(context.filesDir, "diagnostics"))
    }
}
