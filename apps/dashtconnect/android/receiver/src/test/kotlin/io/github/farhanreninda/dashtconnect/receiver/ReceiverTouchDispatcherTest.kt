package io.github.farhanreninda.dashtconnect.receiver

import java.util.concurrent.Executor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ReceiverTouchDispatcherTest {
    private val tasks = ArrayDeque<Runnable>()
    private val sent = mutableListOf<List<ReceiverTouch>>()
    private val dispatcher = ReceiverTouchDispatcher(Executor { tasks.addLast(it) }) { sent.add(it) }
    private fun point(x: Double, id: Int = 0) = ReceiverTouch(id, x, 0.5)
    private fun drain() { while (tasks.isNotEmpty()) tasks.removeFirst().run() }

    @Test fun rapidTapKeepsDownAndUpWithoutWaitingForATimer() {
        dispatcher.submit(listOf(point(0.2)))
        assertEquals(1, tasks.size)
        dispatcher.submit(emptyList())
        drain()
        assertEquals(listOf(listOf(point(0.2)), emptyList()), sent)
    }

    @Test fun movementBacklogKeepsLatestPositionAndPointerTransitions() {
        dispatcher.submit(listOf(point(0.1)))
        repeat(1000) { dispatcher.submit(listOf(point(it / 1000.0))) }
        dispatcher.submit(listOf(point(0.9), point(0.4, 1)))
        dispatcher.submit(listOf(point(0.9)))
        dispatcher.submit(emptyList())
        drain()
        assertEquals(listOf(1, 1, 2, 1, 0), sent.map { it.size })
        assertEquals(0.999, sent[1][0].x, 0.0)
    }

    @Test fun blockedSenderBacklogIsBoundedAndReleasesPreviousGesture() {
        repeat(1000) {
            dispatcher.submit(listOf(point(0.5)))
            dispatcher.submit(emptyList())
        }
        drain()
        assertTrue(sent.size <= 64)
        assertTrue(sent.first().isEmpty())
        assertTrue(sent.last().isEmpty())
    }

    @Test fun shutdownDropsQueuedInputAndDoesNotScheduleAgain() {
        dispatcher.submit(listOf(point(0.5)))
        dispatcher.close()
        drain()
        dispatcher.submit(emptyList())
        assertTrue(sent.isEmpty())
        assertTrue(tasks.isEmpty())
    }
}
