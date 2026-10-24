package io.github.farhanreninda.dashtconnect.platform

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger

class DeviceChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private var dimRequested = false
    private val channel = MethodChannel(messenger, "dashtconnect/device")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "storagePath" -> result.success(activity.filesDir.absolutePath)
                "deviceInfo" -> result.success(deviceInfo())
                "openSettings" -> {
                    val section = (call.arguments as? Map<*, *>)?.get("section") as? String
                    val action = when (section) {
                        "wifi" -> Settings.ACTION_WIFI_SETTINGS
                        "bluetooth" -> Settings.ACTION_BLUETOOTH_SETTINGS
                        else -> null
                    }
                    if (action == null) {
                        result.error("invalid_argument", "Bagian pengaturan tidak didukung.", null)
                    } else {
                        launchActivity(
                            Intent(action), result, "settings_unavailable",
                            "Pengaturan tidak dapat dibuka pada perangkat ini.",
                        )
                    }
                }
                "setDimmed" -> {
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled == null) {
                        result.error("invalid_argument", "enabled harus berupa boolean", null)
                    } else {
                        dimRequested = enabled
                        applyBrightness(enabled)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        applyBrightness(false)
    }

    private fun launchActivity(
        intent: Intent,
        result: MethodChannel.Result,
        errorCode: String,
        errorMessage: String,
    ) {
        try {
            activity.startActivity(intent)
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error(errorCode, errorMessage, null)
        } catch (_: SecurityException) {
            result.error(errorCode, errorMessage, null)
        }
    }

    private fun applyBrightness(dimmed: Boolean) {
        activity.window.attributes = activity.window.attributes.apply {
            screenBrightness = if (dimmed) 0.03f else
                WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
        }
        if (dimmed) activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    fun resume() {
        applyBrightness(dimRequested)
    }

    fun pause() {
        applyBrightness(false)
    }

    private fun deviceInfo(): Map<String, String> {
        val connectivity = activity.getSystemService(ConnectivityManager::class.java)
        val capabilities = connectivity.getNetworkCapabilities(connectivity.activeNetwork)
        val battery = activity.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temperature = battery?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
        val charging = battery?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        return linkedMapOf(
            "Model Android" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "Versi Android" to "${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "Arsitektur" to Build.SUPPORTED_ABIS.joinToString(),
            "Hardware Android" to Build.HARDWARE,
            "Fitur USB host" to yesNo(activity.packageManager.hasSystemFeature(PackageManager.FEATURE_USB_HOST)),
            "Fitur Wi-Fi Direct" to yesNo(activity.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT)),
            "Jaringan aktif" to when {
                capabilities == null -> "Tidak ada jaringan default"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "VPN"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi-Fi"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Seluler"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
                else -> "Transport lain"
            },
            "Internet tervalidasi Android" to if (capabilities?.hasCapability(
                NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true) "Ya" else "Tidak tervalidasi",
            "Suhu baterai" to if (temperature == null || temperature == Int.MIN_VALUE)
                "Tidak tersedia" else "${temperature / 10.0} °C",
            "Daya eksternal" to if (charging == null) "Tidak tersedia" else yesNo(charging != 0),
        )
    }

    private fun yesNo(value: Boolean) = if (value) "Tersedia" else "Tidak tersedia"
}
