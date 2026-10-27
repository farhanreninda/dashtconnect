package io.github.farhanreninda.dashtconnect.receiver

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.View
import android.widget.FrameLayout
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.MotionEvent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ReceiverChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val main = Handler(Looper.getMainLooper())
    private val methods = MethodChannel(messenger, "dashtconnect/receiver")
    private val events = EventChannel(messenger, "dashtconnect/receiver_events")
    private var sink: EventChannel.EventSink? = null
    private val views = HashMap<Int, ReceiverView>()
    private var pendingPermissions: MethodChannel.Result? = null
    private var pendingSetup: MethodChannel.Result? = null
    private var setupStep = 0
    private val connectionPreferences = activity.getSharedPreferences("receiver_connection", Context.MODE_PRIVATE)
    private var disposed = false

    val viewFactory = object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: android.content.Context, viewId: Int, args: Any?): PlatformView {
            return ReceiverView(context, viewId).also { views[viewId] = it }
        }
    }

    init {
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) { sink = eventSink }
            override fun onCancel(arguments: Any?) { sink = null }
        })
        methods.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "preparation" -> result.success(preparation())
                    "prepareConnection" -> {
                        if (pendingSetup != null || pendingPermissions != null) {
                            result.error("busy", "Persiapan koneksi masih diproses.", null)
                        } else {
                            pendingSetup = result
                            setupStep = 0
                            continueSetup()
                        }
                    }
                    "requestPermissions" -> {
                        val missing = missingPermissions()
                        if (missing.isEmpty()) result.success(preparation())
                        else if (pendingPermissions != null || pendingSetup != null) result.error("busy", "Permintaan izin masih diproses.", null)
                        else {
                            pendingPermissions = result
                            activity.requestPermissions(missing.toTypedArray(), PERMISSIONS_REQUEST)
                        }
                    }
                    "start" -> {
                        val viewId = call.argument<Number>("viewId")?.toInt()
                        val address = call.argument<String>("phoneId")
                        val view = views[viewId] ?: error("Layar receiver belum siap.")
                        require(!address.isNullOrBlank()) { "Pilih iPhone terlebih dahulu." }
                        view.start(address)
                        result.success(null)
                    }
                    "stop" -> {
                        val viewId = call.argument<Number>("viewId")?.toInt()
                        views[viewId]?.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("receiver", error.message ?: "Receiver belum dapat dijalankan.", null)
            }
        }
    }

    @Suppress("MissingPermission", "DEPRECATION")
    private fun continueSetup() {
        if (pendingSetup == null) return
        try {
            if (setupStep == 0) {
                setupStep = 1
                val missing = missingPermissions()
                if (missing.isNotEmpty()) {
                    activity.requestPermissions(missing.toTypedArray(), PERMISSIONS_REQUEST)
                    return
                }
            }
            if (missingPermissions().isNotEmpty() || !ReceiverIdentity.authenticationAvailable(activity)) {
                finishSetup()
                return
            }
            val adapter = activity.getSystemService(BluetoothManager::class.java)?.adapter
            if (setupStep == 1) {
                setupStep = 2
                if (adapter != null && !adapter.isEnabled) {
                    activity.startActivityForResult(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE), SETUP_REQUEST)
                    return
                }
            }
            if (adapter?.isEnabled != true) { finishSetup(); return }
            val wifi = activity.getSystemService(WifiManager::class.java)
            if (setupStep == 2) {
                setupStep = 3
                if (wifi?.isWifiEnabled != true) {
                    val action = if (Build.VERSION.SDK_INT >= 29) Settings.Panel.ACTION_WIFI else Settings.ACTION_WIFI_SETTINGS
                    activity.startActivityForResult(Intent(action), SETUP_REQUEST)
                    return
                }
            }
            if (wifi?.isWifiEnabled != true) { finishSetup(); return }
            if (setupStep == 3) {
                setupStep = 4
                if ((preparation()["phones"] as List<*>).isEmpty()) {
                    activity.startActivityForResult(Intent(Settings.ACTION_BLUETOOTH_SETTINGS), SETUP_REQUEST)
                    return
                }
            }
            finishSetup()
        } catch (_: Exception) {
            val result = pendingSetup
            pendingSetup = null
            result?.error("setup", "Persiapan otomatis belum berhasil. Periksa Wi-Fi dan Bluetooth.", null)
        }
    }

    private fun finishSetup() {
        val value = preparation()
        val result = pendingSetup
        pendingSetup = null
        result?.success(value)
    }

    fun activityResult(requestCode: Int): Boolean {
        if (requestCode != SETUP_REQUEST) return false
        continueSetup()
        return true
    }

    private fun missingPermissions(): List<String> {
        val required = buildList {
            add(Manifest.permission.RECORD_AUDIO)
            if (Build.VERSION.SDK_INT >= 31) add(Manifest.permission.BLUETOOTH_CONNECT)
            if (Build.VERSION.SDK_INT >= 33) add(Manifest.permission.NEARBY_WIFI_DEVICES)
            else add(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        return required.filter { activity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }
    }

    @Suppress("MissingPermission")
    private fun preparation(): Map<String, Any?> {
        val adapter = activity.getSystemService(BluetoothManager::class.java)?.adapter
        val allowed = Build.VERSION.SDK_INT < 31 || activity.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        val bonded = if (allowed) adapter?.bondedDevices.orEmpty() else emptySet()
        val lastPhone = connectionPreferences.getString("last_phone", null)
        val phones = bonded.filter {
            it.bluetoothClass?.majorDeviceClass == BluetoothClass.Device.Major.PHONE || it.address == lastPhone
        }
        return mapOf(
            "authenticationAvailable" to ReceiverIdentity.authenticationAvailable(activity),
            "internetAvailable" to ReceiverNetworkStatus.hasInternetNetwork(activity),
            "bluetoothEnabled" to (allowed && adapter?.isEnabled == true),
            "wifiEnabled" to (activity.getSystemService(WifiManager::class.java)?.isWifiEnabled == true),
            "preferredPhoneId" to lastPhone?.takeIf { id -> phones.any { it.address == id } },
            "missingPermissions" to missingPermissions(),
            "phones" to phones.sortedBy { it.name.orEmpty() }.map {
                mapOf("id" to it.address, "name" to (it.name ?: "iPhone"))
            },
        )
    }

    fun permissionsResult(requestCode: Int): Boolean {
        if (requestCode != PERMISSIONS_REQUEST) return false
        if (pendingSetup != null) {
            continueSetup()
            return true
        }
        val result = pendingPermissions
        pendingPermissions = null
        try {
            result?.success(preparation())
        } catch (_: Exception) {
            result?.error("permissions", "Izin belum dapat dibaca. Periksa pengaturan aplikasi.", null)
        }
        return true
    }

    fun pause() { views.values.toList().forEach { it.stop() } }

    fun dispose() {
        disposed = true
        views.values.toList().forEach { it.dispose() }
        pendingPermissions?.error("closed", "Aplikasi ditutup.", null)
        pendingPermissions = null
        pendingSetup?.error("closed", "Aplikasi ditutup.", null)
        pendingSetup = null
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
    }

    private fun emit(viewId: Int, phase: String, message: String = "", wifi: Map<String, String>? = null) {
        main.post {
            if (!disposed && views.containsKey(viewId)) sink?.success(mapOf(
                "viewId" to viewId, "phase" to phase, "message" to message,
                "wifi" to wifi,
            ))
        }
    }

    private inner class ReceiverView(context: android.content.Context, private val id: Int) : PlatformView {
        private val videoSize = if (Build.VERSION.SDK_INT >= 30) {
            activity.windowManager.currentWindowMetrics.bounds.let { ReceiverVideoSize.forDisplay(it.width(), it.height()) }
        } else {
            @Suppress("DEPRECATION")
            val metrics = android.util.DisplayMetrics().also { activity.windowManager.defaultDisplay.getRealMetrics(it) }
            ReceiverVideoSize.forDisplay(metrics.widthPixels, metrics.heightPixels)
        }
        private val previousCutoutMode = if (Build.VERSION.SDK_INT >= 28) activity.window.attributes.layoutInDisplayCutoutMode else 0
        private val container = FrameLayout(context).apply { setBackgroundColor(android.graphics.Color.BLACK) }
        private val surface = SurfaceView(context)
        private var surfaceReady = false
        private var receiver: LocalCarPlayReceiver? = null
        @Volatile private var attempt = 0

        init {
            if (Build.VERSION.SDK_INT >= 28) {
                activity.window.attributes = activity.window.attributes.apply {
                    layoutInDisplayCutoutMode = android.view.WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }
            container.addView(surface)
            container.addOnLayoutChangeListener { _, left, top, right, bottom, _, _, _, _ ->
                val width = right - left
                val height = bottom - top
                if (width > 0 && height > 0) {
                    val scale = minOf(width / videoSize.width.toDouble(), height / videoSize.height.toDouble())
                    val fittedWidth = (videoSize.width * scale).toInt()
                    val fittedHeight = (videoSize.height * scale).toInt()
                    if (surface.layoutParams.width != fittedWidth || surface.layoutParams.height != fittedHeight) {
                        surface.layoutParams = FrameLayout.LayoutParams(fittedWidth, fittedHeight, android.view.Gravity.CENTER)
                    }
                }
            }
            surface.holder.addCallback(object : SurfaceHolder.Callback {
                override fun surfaceCreated(holder: SurfaceHolder) { surfaceReady = true; emit(id, "surface_ready") }
                override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit
                override fun surfaceDestroyed(holder: SurfaceHolder) {
                    surfaceReady = false
                    stop()
                    emit(id, "surface_lost")
                }
            })
            surface.setOnTouchListener { _, event ->
                val contacts = if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) emptyList()
                else (0 until event.pointerCount).filter {
                    !(event.actionMasked == MotionEvent.ACTION_POINTER_UP && it == event.actionIndex)
                }.take(10).map {
                    ReceiverTouch(event.getPointerId(it),
                        (event.getX(it) / surface.width.coerceAtLeast(1)).toDouble().coerceIn(0.0, 1.0),
                        (event.getY(it) / surface.height.coerceAtLeast(1)).toDouble().coerceIn(0.0, 1.0))
                }
                receiver?.touch(contacts)
                true
            }
        }

        @Suppress("MissingPermission")
        fun start(phoneId: String) {
            check(surfaceReady) { "Layar receiver belum siap. Coba lagi." }
            check(missingPermissions().isEmpty()) { "Izinkan akses perangkat sekitar dan mikrofon terlebih dahulu." }
            check(ReceiverIdentity.authenticationAvailable(activity)) { "Autentikasi aksesori belum disiapkan pada build ini." }
            check(activity.getSystemService(WifiManager::class.java)?.isWifiEnabled == true) { "Aktifkan Wi-Fi Android." }
            val adapter = activity.getSystemService(BluetoothManager::class.java)?.adapter
            check(adapter?.isEnabled == true) { "Aktifkan Bluetooth Android." }
            val phone = adapter.bondedDevices.firstOrNull { it.address == phoneId }
                ?: error("Pasangkan iPhone melalui pengaturan Bluetooth, lalu perbarui daftar.")
            stop()
            surface.keepScreenOn = true
            val current = ++attempt
            receiver = LocalCarPlayReceiver(activity, surface.holder.surface, phone,
                onStatus = { if (current == attempt) emit(id, "connecting", it) },
                onConnected = { if (current == attempt) {
                    connectionPreferences.edit().putString("last_phone", phone.address).apply()
                    emit(id, "connected", "CarPlay diterima dari iPhone")
                } },
                onFailure = { reason -> if (current == attempt) emit(id, "error", failureMessage(reason)) },
                provisionedBluetoothAddress = io.github.farhanreninda.dashtconnect.BuildConfig.RECEIVER_BLUETOOTH_ADDRESS,
                videoSize = videoSize,
                onWifi = { ssid, passphrase -> if (current == attempt) emit(id, "connecting",
                    "Menunggu iPhone berpindah ke Wi-Fi lokal…", mapOf("ssid" to ssid, "passphrase" to passphrase)) },
            ).also { it.start() }
        }

        fun stop() {
            surface.keepScreenOn = false
            attempt++
            val previous = receiver
            receiver = null
            previous?.close()
            if (previous != null) emit(id, "stopped", "Receiver dihentikan")
        }

        override fun getView(): View = container
        override fun dispose() {
            stop()
            views.remove(id)
            if (Build.VERSION.SDK_INT >= 28) {
                activity.window.attributes = activity.window.attributes.apply { layoutInDisplayCutoutMode = previousCutoutMode }
            }
        }
    }

    private fun failureMessage(reason: String): String = when {
        reason == "BLUETOOTH_DISABLED" -> "Bluetooth Android belum aktif."
        reason.startsWith("Turn on Wi-Fi") -> "Wi-Fi Android belum aktif. Nyalakan Wi-Fi, lalu coba lagi."
        reason == "IPHONE_VIDEO_TIMEOUT" -> "iPhone belum mengirim gambar. Periksa permintaan CarPlay di iPhone, lalu coba lagi."
        reason == "IPHONE_SESSION_ENDED" -> "Sesi iPhone terputus. Anda dapat mencoba menghubungkan ulang."
        reason.contains("authentication", ignoreCase = true) || reason.contains("certificate", ignoreCase = true) -> "Autentikasi aksesori belum diterima. Periksa identitas receiver dan permintaan di iPhone."
        else -> "Koneksi iPhone belum berhasil. Periksa Bluetooth, Wi-Fi lokal, dan permintaan CarPlay di iPhone, lalu coba lagi."
    }

    private companion object {
        const val PERMISSIONS_REQUEST = 7330
        const val SETUP_REQUEST = 7331
    }
}
