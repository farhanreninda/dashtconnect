package io.github.farhanreninda.dashtconnect.aap

import android.content.Context
import android.os.SystemClock
import android.util.Log
import android.view.Surface
import java.io.IOException
import java.net.ConnectException
import java.net.InetSocketAddress
import java.net.Socket
import java.net.SocketTimeoutException
import java.util.concurrent.CopyOnWriteArraySet
import java.util.concurrent.Executors
import javax.net.ssl.SSLException

/** One Android Auto session against the phone's own head unit server on 127.0.0.1:5277. */
object AndroidAutoProjection {
    enum class State { IDLE, CONNECTING, WAITING_VIDEO, PROJECTING, FAILED, ENDED }

    @Volatile var state = State.IDLE
        private set
    @Volatile var detail = ""
        private set

    private val listeners = CopyOnWriteArraySet<() -> Unit>()
    private val writer = Executors.newSingleThreadExecutor { Thread(it, "aa-input") }
    private val lock = Any()
    private var socket: Socket? = null
    private var transport: AapTransport? = null
    private var session: AapSession? = null
    private var decoder: H264Decoder? = null
    private var codecConfig: ByteArray? = null
    @Volatile private var generation = 0

    fun addListener(listener: () -> Unit) = listeners.add(listener)
    fun removeListener(listener: () -> Unit) = listeners.remove(listener)

    val active get() = state == State.CONNECTING || state == State.WAITING_VIDEO || state == State.PROJECTING

    fun identityAvailable(context: Context) = HeadUnitIdentity.available(context.assets)

    internal fun start(context: Context, spec: VideoSpec, softwareVersion: String) {
        val id = synchronized(lock) {
            if (active) return
            ++generation
        }
        val assets = context.applicationContext.assets
        set(State.CONNECTING, "")
        Thread({ run(id, assets, spec, softwareVersion) }, "aa-session").start()
    }

    fun stop() {
        val (open, s) = synchronized(lock) {
            generation++
            socket to session
        }
        writer.execute {
            runCatching { s?.byeBye() }
            runCatching { open?.close() }
        }
        if (active) set(State.ENDED, "")
    }

    internal fun attach(surface: Surface) {
        synchronized(lock) {
            decoder?.release()
            val id = generation
            decoder = H264Decoder(surface, onFirstFrame = { if (id == generation) set(State.PROJECTING, "") }) {
                if (id == generation) set(State.FAILED, "Decoder video berhenti: ${it.message ?: it.javaClass.simpleName}")
            }
            codecConfig?.let { decoder?.submit(it, 0, it.size, config = true) }
            val s = session
            if (s != null) writer.execute { runCatching { s.requestKeyframe() } }
        }
    }

    internal fun detach() {
        synchronized(lock) {
            decoder?.release()
            decoder = null
        }
    }

    internal fun touch(action: Int, actionIndex: Int, pointers: List<AapSession.Pointer>) {
        val s = synchronized(lock) { session } ?: return
        val now = SystemClock.elapsedRealtimeNanos()
        writer.execute { runCatching { s.touch(action, actionIndex, pointers, now) } }
    }

    private fun run(id: Int, assets: android.content.res.AssetManager, spec: VideoSpec, softwareVersion: String) {
        val socket = Socket()
        try {
            val identity = try { HeadUnitIdentity.load(assets) } catch (e: Exception) {
                return fail(id, "Identitas head unit tidak dapat dibaca: ${e.message ?: e.javaClass.simpleName}")
            } ?: return fail(id, "Identitas head unit Android Auto belum dipasang pada build ini.")
            synchronized(lock) {
                if (id != generation) return
                this.socket = socket
            }
            try {
                socket.tcpNoDelay = true
                socket.connect(InetSocketAddress("127.0.0.1", PORT), 3000)
            } catch (_: ConnectException) {
                return fail(id, "Head unit server Android Auto belum berjalan. Buka Android Auto, masuk Setelan developer lewat menu titik tiga, pilih Start head unit server, lalu coba lagi.")
            }
            val transport = AapTransport(socket, identity)
            // The head unit server serves one connection at a time; a stale one leaves it accepting but silent.
            socket.soTimeout = HANDSHAKE_TIMEOUT_MS
            try { transport.handshake() } catch (e: SSLException) {
                Log.w(TAG, "handshake", e)
                return fail(id, "Android Auto menolak handshake TLS: ${e.message ?: "tanpa keterangan"}")
            } catch (_: SocketTimeoutException) {
                return fail(id, "Head unit server tidak menjawab. Di Android Auto pilih Stop head unit server, lalu Start head unit server lagi, kemudian coba ulang.")
            }
            socket.soTimeout = 0
            val session = AapSession(transport, spec, Sink(id), softwareVersion)
            synchronized(lock) {
                if (id != generation) return
                this.transport = transport
                this.session = session
            }
            set(State.WAITING_VIDEO, "")
            while (!session.ended) {
                val message = transport.read()
                synchronized(lock) { if (id != generation) return }
                session.handle(message.channel, message.type, message.body, message.offset)
            }
            if (id == generation) set(State.ENDED, "Android Auto mengakhiri sesi.")
        } catch (e: IOException) {
            Log.w(TAG, "session", e)
            fail(id, "Koneksi Android Auto terputus: ${e.message ?: e.javaClass.simpleName}")
        } catch (e: RuntimeException) {
            Log.w(TAG, "session", e)
            fail(id, "Pesan Android Auto tidak dapat diproses: ${e.message ?: e.javaClass.simpleName}")
        } finally {
            runCatching { socket.close() }
            synchronized(lock) {
                if (this.socket === socket) {
                    this.socket = null
                    transport = null
                    session = null
                    codecConfig = null
                }
            }
        }
    }

    private fun fail(id: Int, message: String) {
        if (synchronized(lock) { id == generation }) set(State.FAILED, message)
    }

    private fun set(state: State, detail: String) {
        this.state = state
        this.detail = detail
        Log.i(TAG, "$state $detail")
        listeners.forEach { it() }
    }

    private class Sink(private val id: Int) : VideoSink {
        override fun codecConfig(data: ByteArray, offset: Int, length: Int) {
            synchronized(lock) {
                if (id != generation) return
                codecConfig = data.copyOfRange(offset, offset + length)
                decoder?.submit(data, offset, length, config = true)
            }
        }

        override fun frame(data: ByteArray, offset: Int, length: Int) {
            synchronized(lock) { if (id == generation) decoder?.submit(data, offset, length, config = false) }
        }
    }

    private const val PORT = 5277
    private const val TAG = "DashTAA"
    private const val HANDSHAKE_TIMEOUT_MS = 6000
}
