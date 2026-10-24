package io.github.farhanreninda.dashtconnect.receiver

import java.util.concurrent.CancellationException

internal class ReceiverResources {
    private val lock = Any()
    private var closed = false
    private val releases = ArrayList<() -> Unit>()

    fun <T : AutoCloseable> own(resource: T): T {
        add { resource.close() }
        return resource
    }

    fun add(release: () -> Unit) {
        val rejected = synchronized(lock) {
            if (closed) true else { releases.add(release); false }
        }
        if (rejected) {
            runCatching(release)
            throw CancellationException("Receiver stopped")
        }
    }

    fun takeForClose(): List<() -> Unit> = synchronized(lock) {
        if (closed) emptyList() else {
            closed = true
            releases.reversed().also { releases.clear() }
        }
    }
}
