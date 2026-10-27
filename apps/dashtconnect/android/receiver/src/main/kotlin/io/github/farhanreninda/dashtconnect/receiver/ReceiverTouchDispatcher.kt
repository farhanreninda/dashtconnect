package io.github.farhanreninda.dashtconnect.receiver

import java.io.Closeable
import java.util.concurrent.Executor

internal class ReceiverTouchDispatcher(
    private val executor: Executor,
    private val send: (List<ReceiverTouch>) -> Unit,
) : Closeable {
    private data class Packet(val points: List<ReceiverTouch>, val transition: Boolean)
    private val pending = ArrayDeque<Packet>()
    private var pointerIds = emptyList<Int>()
    private var draining = false
    private var closed = false

    @Synchronized fun submit(points: List<ReceiverTouch>) {
        if (closed) return
        val snapshot = points.take(10)
        val ids = snapshot.map { it.id }
        val transition = ids != pointerIds
        pointerIds = ids
        // Coalesce movement, but keep every finger-down/up boundary in order.
        if (!transition && pending.lastOrNull()?.transition == false) pending.removeLast()
        // A stalled connection must release the old gesture instead of replaying an input backlog.
        if (pending.size >= 64) {
            pending.clear()
            pending.addLast(Packet(emptyList(), true))
        }
        pending.addLast(Packet(snapshot, transition))
        if (!draining) {
            draining = true
            executor.execute(::drain)
        }
    }

    private fun drain() {
        while (true) {
            val packet = synchronized(this) {
                if (closed || pending.isEmpty()) {
                    draining = false
                    return
                }
                pending.removeFirst()
            }
            runCatching { send(packet.points) }
        }
    }

    @Synchronized override fun close() {
        closed = true
        pending.clear()
    }
}
