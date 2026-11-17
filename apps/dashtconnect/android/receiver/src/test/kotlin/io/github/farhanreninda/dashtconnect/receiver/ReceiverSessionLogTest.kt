package io.github.farhanreninda.dashtconnect.receiver

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.nio.file.Files

class ReceiverSessionLogTest {
    @Test fun rotatesAndExportsOldestFirstWithinTwoFiles() {
        val dir = Files.createTempDirectory("dtc-log").toFile()
        val log = ReceiverSessionLog(dir, maxBytes = 80)
        val target = dir.resolve("export.txt")
        assertNull(log.exportTo(target))
        repeat(6) { log.write("event-$it ".padEnd(40, 'x')) }
        val text = requireNotNull(log.exportTo(target)).readText()
        val events = Regex("event-(\\d)").findAll(text).map { it.groupValues[1].toInt() }.toList()
        assertEquals(events.sorted(), events)
        assertTrue("latest kept", 5 in events)
        assertTrue("oldest rotated out", 0 !in events)
        dir.deleteRecursively()
    }
}
