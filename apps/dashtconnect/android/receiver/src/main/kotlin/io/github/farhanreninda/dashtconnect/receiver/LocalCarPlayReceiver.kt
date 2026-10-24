package io.github.farhanreninda.dashtconnect.receiver

import android.Manifest
import android.content.pm.PackageManager
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.provider.Settings
import android.view.Surface
import com.shilapi.xcertplay.airplay.*
import com.shilapi.xcertplay.iap2.session.Iap2Session
import com.shilapi.xcertplay.media.AndroidMediaSink
import com.shilapi.xcertplay.media.MediaAudioBuffer
import com.shilapi.xcertplay.mfi.Iap2MfiAuthenticationClient
import com.shilapi.xcertplay.network.CarPlayBonjour
import com.shilapi.xcertplay.network.diagnosticSummary
import com.shilapi.xcertplay.network.WifiP2pGroupManager
import com.shilapi.xcertplay.network.WifiP2pChannels
import com.shilapi.xcertplay.transport.*
import java.io.Closeable
import java.io.IOException
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

data class ReceiverTouch(val id: Int, val x: Double, val y: Double) {
    init {
        require(id in 0..31 && x.isFinite() && y.isFinite())
        require(x in 0.0..1.0 && y in 0.0..1.0)
    }
}

class LocalCarPlayReceiver(
    context: Context,
    private val surface: Surface,
    private val phone: BluetoothDevice,
    private val onStatus: (String) -> Unit,
    private val onConnected: () -> Unit,
    private val onFailure: (String) -> Unit,
    private val onWifi: (String, String) -> Unit = { _, _ -> },
    private val provisionedBluetoothAddress: String? = null,
    private val videoSize: ReceiverVideoSize = ReceiverVideoSize(1280, 720),
) : Closeable {
    private val app = context.applicationContext
    private val resources = ReceiverResources()
    private val closed = AtomicBoolean(false)
    private val started = AtomicBoolean(false)
    private val sessions = ConcurrentHashMap.newKeySet<AirPlaySession>()
    private val sessionsLock = Any()
    private val active = AtomicReference<AirPlaySession?>()
    private val runtimeReady = AtomicBoolean(false)
    private val rendered = AtomicBoolean(false)
    private val reported = AtomicBoolean(false)
    private val pendingTouches = AtomicReference<List<ReceiverTouch>?>(null)
    private val worker = Executors.newSingleThreadExecutor()
    private val tunnelWorker = Executors.newSingleThreadExecutor()
    private val timers = Executors.newSingleThreadScheduledExecutor()
    private val touchWorker = Executors.newSingleThreadScheduledExecutor()

    fun start() {
        check(started.compareAndSet(false, true))
        worker.execute {
            try { connect() }
            catch (error: Exception) {
                if (!closed.get()) {
                    android.util.Log.w("DashTReceiver", "Startup failure ${error.javaClass.simpleName} at ${error.stackTrace.firstOrNull()}")
                    fail(error.message ?: "RECEIVER_START_FAILED")
                }
            }
        }
    }

    fun touch(points: List<ReceiverTouch>) {
        if (!closed.get() && reported.get()) pendingTouches.set(points.take(10))
    }

    private fun status(message: String) { if (!closed.get() && !reported.get()) onStatus(message) }

    private fun protocolProgress(message: String) {
        receiverProtocolDiagnostic(message)?.let { android.util.Log.i("DashTReceiver", it) }
    }

    private fun connect() {
        ReceiverOfflinePolicy.requireOffline(app)
        check(app.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            "Izinkan mikrofon untuk audio CarPlay terlebih dahulu."
        }
        status("Menyiapkan autentikasi lokal…")
        val authentication = ReceiverIdentity.authentication(app)
        val identity = ReceiverIdentity.identity(app)
        val pairings = ReceiverIdentity.pairings(app)
        val adapter = app.getSystemService(BluetoothManager::class.java)?.adapter
            ?: throw IOException("BLUETOOTH_UNAVAILABLE")
        if (!adapter.isEnabled) throw IOException("BLUETOOTH_DISABLED")
        watchInternet()

        status("Menyiapkan Wi-Fi lokal…")
        val hotspot = resources.own(WifiP2pGroupManager(app,
            preferredChannel = WifiP2pChannels.AUTO_2_4_GHZ, deviceBrand = Build.MANUFACTURER))
        val network = hotspot.start(25_000)
        android.util.Log.i("DashTReceiver", "Wi-Fi local frequencyMHz=${network.frequencyMHz}")
        ReceiverOfflinePolicy.requireOffline(app)
        val address = network.hostAddresses.filterIsInstance<Inet4Address>().firstOrNull()
            ?: network.hostAddress ?: throw IOException("LOCAL_ADDRESS_UNAVAILABLE")
        val fallbackId = identity.publicKey.take(6).mapIndexed { i, value ->
            if (i == 0) ((value.toInt() and 0xfc) or 2).toByte() else value
        }.joinToString(":") { "%02X".format(it.toInt() and 255) }
        @Suppress("HardwareIds", "MissingPermission")
        val btMac = listOfNotNull(
            runCatching { adapter.address }.getOrNull(),
            runCatching { Settings.Secure.getString(app.contentResolver, "bluetooth_address") }.getOrNull(),
            provisionedBluetoothAddress,
        ).firstNotNullOfOrNull(::receiverHardwareAddress)
            ?: fallbackId
        val server = resources.own(ServerSocket().apply {
            reuseAddress = true
            bind(InetSocketAddress(address, 0))
        })
        val config = AirPlayConfig(
            deviceName = "DashTConnect", deviceId = receiverHardwareAddress(network.bssid) ?: fallbackId,
            btMac = btMac, sourceVersion = "950.7.1", port = server.localPort,
            main = AirPlayDisplayConfig(videoSize.width, videoSize.height, fps = 30),
            rightHandDrive = true, microphone = true,
            mainBufferedAudio = true,
            manufacturer = "DashTConnect", model = Build.MODEL, oemLabel = "DashTConnect",
        )
        android.util.Log.i("DashTReceiver", "Audio output offered buffered=true microphone=true hardwareBluetoothAvailable=${btMac != fallbackId}")
        val sink = AndroidMediaSink(
            surface = surface, videoWidth = videoSize.width, videoHeight = videoSize.height,
            context = app, audioFocusEnabled = true, mainVideoFrameRate = 30,
            // Receive gaps reached 620 ms on this link; keep music buffered across those gaps.
            mediaBufferMillis = MediaAudioBuffer.MOST_STABLE_MILLIS,
            callSpeakerphone = { true },
        )
        resources.add { sink.close() }
        val media = CarPlayMediaEngine(sink, microphoneEnabled = true)
        val identification = Iap2IdentificationConfig(
            name = "DashTConnect", modelIdentifier = Build.MODEL,
            manufacturer = "DashTConnect", serialNumber = "DTC-" + identity.pairingId,
            firmwareVersion = "0.4.0", hardwareVersion = "1.0",
            carPlayUsbInterfaceNumber = 0,
            externalAccessoryProtocol = "io.github.farhanreninda.dashtconnect",
        )
        val wireless = Iap2WirelessIdentification(btMac, network.ssid)
        val endpoint = Iap2WirelessCarPlayEndpoint(
            ssid = network.ssid, passphrase = network.passphrase,
            channel = network.channel, security = network.security,
            ipAddresses = listOf(address.hostAddress!!.substringBefore('%')),
            airPlayPort = server.localPort, deviceIdentifier = config.deviceId,
            publicKey = identity.publicKeyHex, sourceVersion = config.sourceVersion,
            accessPointBssid = network.accessPointBssid,
        )
        media.setIapTunnelHandler { stream ->
            if (closed.get()) false else {
                try {
                    val channel = resources.own(Iap2Session.openTunnel(stream))
                    tunnelWorker.execute {
                        try {
                            Iap2WirelessControlClient(channel, Iap2MfiAuthenticationClient(authentication)).run(
                                identification = identification.forWirelessLink(Iap2WirelessLinkRole.RUNTIME_TUNNEL, wireless),
                                endpoint = endpoint,
                                timeoutMillis = Iap2WirelessControlClient.NO_TIMEOUT_MILLIS,
                                onReady = { runtimeReady.set(true); confirmConnection(hotspot::onCarPlayConfirmed) },
                                onProgress = ::protocolProgress,
                            )
                            if (!closed.get()) fail("IPHONE_SESSION_ENDED")
                        } catch (error: Exception) { if (!closed.get()) fail(error.message ?: "IAP_TUNNEL_FAILED") }
                    }
                    true
                } catch (_: Exception) { false }
            }
        }
        val listener = object : AirPlaySessionListener {
            override fun onSessionActive(session: AirPlaySession) {
                active.set(session)
                status("Sesi iPhone diterima; menunggu gambar…")
            }
            override fun onVideoFrameRendered(session: AirPlaySession) {
                if (active.get() === session) {
                    rendered.set(true)
                    confirmConnection(hotspot::onCarPlayConfirmed)
                }
            }
            override fun onSessionEnded(session: AirPlaySession) {
                sessions.remove(session)
                if (active.compareAndSet(session, null) && !closed.get()) fail("IPHONE_SESSION_ENDED")
            }
            override fun onTransportError(message: String) { fail("IPHONE_TRANSPORT_FAILED") }
        }
        resources.add {
            val remaining = synchronized(sessionsLock) { sessions.toList().also { sessions.clear() } }
            remaining.forEach { runCatching { it.close() } }
        }
        Thread({
            try {
                while (!closed.get()) {
                    val socket = server.accept()
                    socket.tcpNoDelay = true
                    socket.keepAlive = true
                    val session = synchronized(sessionsLock) {
                        if (closed.get() || sessions.size >= 4) null else {
                            AirPlaySession(socket, config, identity, pairings, authentication, listener, media)
                                .also { sessions.add(it) }
                        }
                    }
                    if (session == null) { socket.close(); continue }
                    session.start()
                }
            } catch (_: IOException) { if (!closed.get()) fail("LOCAL_LISTENER_FAILED") }
        }, "dtc-local-receiver").apply { isDaemon = true; start() }
        val bonjour = resources.own(CarPlayBonjour(app, config, identity,
            advertisedHost = address.hostAddress, useInterfaceMdns = true,
            onEvent = { android.util.Log.i("DashTReceiver", it.diagnosticSummary()) }))
        bonjour.start()
        touchWorker.scheduleAtFixedRate({
            pendingTouches.getAndSet(null)?.let { points ->
                runCatching { active.get()?.sendTouch(points.map { AirPlayContact(it.id, it.x, it.y, true) }) }
            }
        }, 0, 16, TimeUnit.MILLISECONDS)

        status("Menghubungkan Bluetooth iPhone…")
        @Suppress("MissingPermission")
        val bluetoothSocket = resources.own(phone.createRfcommSocketToServiceRecord(UUID.fromString(IAP2_UUID)))
        val connected = AtomicBoolean(false)
        val connectTimeout = timers.schedule({ if (!connected.get()) runCatching { bluetoothSocket.close() } }, 20, TimeUnit.SECONDS)
        bluetoothSocket.connect()
        connected.set(true)
        connectTimeout.cancel(false)
        val stream = resources.own(BluetoothRfcommDuplexStream(bluetoothSocket))
        val channel = resources.own(Iap2Session.openWireless(stream))
        status("Memasangkan dan mengautentikasi iPhone…")
        val result = Iap2WirelessControlClient(channel, Iap2MfiAuthenticationClient(authentication)).run(
            identification = identification.forWirelessLink(Iap2WirelessLinkRole.BLUETOOTH_BOOTSTRAP, wireless),
            endpoint = endpoint, timeoutMillis = 180_000,
            beforeStartSession = { hotspot.validateReady(); ReceiverOfflinePolicy.requireOffline(app) },
            onStartSessionSent = {
                status("Menunggu iPhone berpindah ke Wi-Fi lokal…")
                onWifi(network.ssid, network.passphrase)
                timers.schedule({
                    if (!reported.get() && !closed.get()) {
                        android.util.Log.i("DashTReceiver", bonjour.diagnosticSnapshot())
                        fail("IPHONE_VIDEO_TIMEOUT")
                    }
                }, 180, TimeUnit.SECONDS)
            },
            keepAliveAfterDeadline = { reported.get() && !closed.get() },
            onProgress = ::protocolProgress,
        )
        if (!closed.get() && result.carPlayStartSessionsSent == 0 && !runtimeReady.get()) {
            throw IOException("IPHONE_BOOTSTRAP_ENDED")
        }
    }

    private fun confirmConnection(confirmHotspot: () -> Unit) {
        if (!closed.get() && runtimeReady.get() && rendered.get() && reported.compareAndSet(false, true)) {
            runCatching(confirmHotspot)
            onConnected()
        }
    }

    private fun watchInternet() {
        val connectivity = app.getSystemService(ConnectivityManager::class.java)
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) { check() }
            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) { check() }
            private fun check() {
                if (!closed.get() && ReceiverOfflinePolicy.hasInternetNetwork(app)) fail("ANDROID_INTERNET_ENABLED")
            }
        }
        connectivity.registerNetworkCallback(NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build(), callback)
        resources.add { connectivity.unregisterNetworkCallback(callback) }
        ReceiverOfflinePolicy.requireOffline(app)
    }

    private fun fail(reason: String) {
        if (!closed.compareAndSet(false, true)) return
        onFailure(reason)
        release()
    }

    override fun close() {
        if (closed.compareAndSet(false, true)) release()
    }

    private fun release() {
        worker.shutdownNow()
        tunnelWorker.shutdownNow()
        timers.shutdownNow()
        touchWorker.shutdownNow()
        val releases = resources.takeForClose()
        Thread({ releases.forEach { runCatching(it) } }, "dtc-receiver-close")
            .apply { isDaemon = true; start() }
    }

    companion object {
        private const val IAP2_UUID = "00000000-deca-fade-deca-deafdecacafe"
    }
}
