package io.github.farhanreninda.dashtconnect.receiver

import java.util.concurrent.CancellationException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.*
import org.junit.Test

class ReceiverResourcesTest {
    @Test fun closesInReverseOrderOnlyOnce() {
        val resources = ReceiverResources()
        val closed = mutableListOf<Int>()
        resources.add { closed.add(1) }
        resources.add { closed.add(2) }
        resources.takeForClose().forEach { it() }
        resources.takeForClose().forEach { it() }
        assertEquals(listOf(2, 1), closed)
    }

    @Test fun acquisitionRacingWithShutdownIsAlwaysReleased() {
        repeat(50) {
            val resources = ReceiverResources()
            val released = AtomicInteger()
            val ready = CountDownLatch(1)
            val thread = Thread {
                ready.await()
                try { resources.own(AutoCloseable { released.incrementAndGet() }) }
                catch (_: CancellationException) { }
            }.apply { start() }
            ready.countDown()
            resources.takeForClose().forEach { it() }
            thread.join(2000)
            assertFalse(thread.isAlive)
            assertEquals(1, released.get())
        }
    }

    @Test fun rejectsNonFiniteOrOutOfBoundsTouchInput() {
        assertThrows(IllegalArgumentException::class.java) { ReceiverTouch(1, Double.NaN, 0.2) }
        assertThrows(IllegalArgumentException::class.java) { ReceiverTouch(1, 1.1, 0.2) }
        assertThrows(IllegalArgumentException::class.java) { ReceiverTouch(32, 0.1, 0.2) }
        assertEquals(1.0, ReceiverTouch(0, 0.0, 1.0).y, 0.0)
    }
}
