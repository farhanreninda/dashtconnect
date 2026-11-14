package io.github.farhanreninda.dashtconnect.androidauto

import android.content.ActivityNotFoundException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.usb.UsbManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.github.farhanreninda.dashtconnect.BuildConfig
import io.github.farhanreninda.dashtconnect.aap.AndroidAutoProjection
import io.github.farhanreninda.dashtconnect.aap.AndroidAutoProjectionActivity

class AndroidAutoChannel(private val activity: FlutterActivity, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, "dashtconnect/android_auto")
    private val events = EventChannel(messenger, "dashtconnect/android_auto_events")
    private var sink: EventChannel.EventSink? = null
    private var foreground = false
    private var observing = false
    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) { emit() }
    }
    private val onSession: () -> Unit = { activity.runOnUiThread { emit() } }
    private val identity by lazy { AndroidAutoProjection.identityAvailable(activity) }

    init {
        methods.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "refresh" -> {
                        stopObserving()
                        startObserving()
                        result.success(snapshot())
                    }
                    "start" -> {
                        activity.startActivity(Intent(activity, AndroidAutoProjectionActivity::class.java)
                            .putExtra(AndroidAutoProjectionActivity.EXTRA_VERSION, BuildConfig.VERSION_NAME))
                        result.success(null)
                    }
                    "stop" -> {
                        AndroidAutoProjection.stop()
                        result.success(null)
                    }
                    "openSettings" -> {
                        val preferences = Intent(Intent.ACTION_APPLICATION_PREFERENCES).setPackage(PACKAGE)
                        val intent = if (preferences.resolveActivity(activity.packageManager) != null) preferences
                            else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$PACKAGE"))
                        activity.startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (_: ActivityNotFoundException) {
                result.error("settings_unavailable", "Pengaturan Android Auto tidak tersedia.", null)
            } catch (_: Exception) {
                result.error("android_auto", "Status Android Auto belum dapat diperiksa.", null)
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                sink = events
                startObserving()
                emit()
            }
            override fun onCancel(arguments: Any?) {
                stopObserving()
                sink = null
            }
        })
    }

    fun resume() {
        foreground = true
        startObserving()
    }

    fun pause() {
        foreground = false
        stopObserving()
    }

    private fun startObserving() {
        if (observing || !foreground || sink == null) return
        val filter = IntentFilter().apply {
            addAction(UsbManager.ACTION_USB_ACCESSORY_ATTACHED)
            addAction(UsbManager.ACTION_USB_ACCESSORY_DETACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        ContextCompat.registerReceiver(activity, usbReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
        AndroidAutoProjection.addListener(onSession)
        observing = true
        emit()
    }

    private fun stopObserving() {
        if (!observing) return
        activity.unregisterReceiver(usbReceiver)
        AndroidAutoProjection.removeListener(onSession)
        observing = false
    }

    private fun emit() {
        try { sink?.success(snapshot()) }
        catch (_: Exception) { sink?.error("android_auto", "Status Android Auto belum dapat diperiksa.", null) }
    }

    @Suppress("DEPRECATION")
    private fun snapshot(): Map<String, Any> {
        val app = try { activity.packageManager.getPackageInfo(PACKAGE, 0) }
            catch (_: PackageManager.NameNotFoundException) { null }
        val usb = activity.getSystemService(UsbManager::class.java)
        return mapOf(
            "sdk" to Build.VERSION.SDK_INT,
            "installed" to (app != null),
            "enabled" to (app?.applicationInfo?.enabled == true),
            "version" to (app?.versionName ?: ""),
            "usbAccessory" to (!usb?.accessoryList.isNullOrEmpty()),
            "usbHostDevice" to (!usb?.deviceList.isNullOrEmpty()),
            "identity" to identity,
            "session" to AndroidAutoProjection.state.name.lowercase(),
            "sessionDetail" to AndroidAutoProjection.detail,
        )
    }

    fun dispose() {
        stopObserving()
        sink = null
        events.setStreamHandler(null)
        methods.setMethodCallHandler(null)
    }

    private companion object { const val PACKAGE = "com.google.android.projection.gearhead" }
}
