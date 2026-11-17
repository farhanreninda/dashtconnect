package io.github.farhanreninda.dashtconnect.receiver

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbAccessory
import android.hardware.usb.UsbManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel

/**
 * Head unit step before CarPlay: finds the T-Link USB accessory, asks for USB access and screen
 * capture, then hands the session to [TLinkMirrorService].
 */
class HeadUnitLink(private val activity: Activity) {
    private val usb = activity.getSystemService(UsbManager::class.java)
    private var pending: MethodChannel.Result? = null
    private var pendingAccessory: UsbAccessory? = null
    private var permissionReceiver: BroadcastReceiver? = null

    fun status(): Map<String, Any?> = mapOf(
        "link" to when {
            TLinkMirrorService.streaming -> "streaming"
            TLinkMirrorService.active -> "waiting"
            attached() != null -> "detected"
            else -> "absent"
        },
        "problem" to TLinkMirrorService.problem,
    )

    fun connect(result: MethodChannel.Result) {
        if (pending != null) return result.error("busy", "Koneksi head unit masih diproses.", null)
        if (TLinkMirrorService.active) return result.success(status())
        val accessory = attached() ?: return result.success(status())
        pending = result
        if (usb?.hasPermission(accessory) == true) return requestCapture(accessory)
        val action = "${activity.packageName}.TLINK_USB_PERMISSION"
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                unregisterPermissionReceiver()
                if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) requestCapture(accessory)
                else finish(error = "Akses USB ke head unit ditolak. Tekan Hubungkan lalu pilih Izinkan.")
            }
        }
        permissionReceiver = receiver
        ContextCompat.registerReceiver(activity, receiver, IntentFilter(action), ContextCompat.RECEIVER_NOT_EXPORTED)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
        usb?.requestPermission(accessory, PendingIntent.getBroadcast(activity, 0, Intent(action).setPackage(activity.packageName), flags))
    }

    fun activityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != CAPTURE_REQUEST) return false
        val accessory = pendingAccessory
        pendingAccessory = null
        if (resultCode == Activity.RESULT_OK && data != null && accessory != null) {
            TLinkMirrorService.start(activity, accessory, resultCode, data)
            // The service flips to active asynchronously; report the state it is about to enter.
            finish(mapOf("link" to "waiting", "problem" to null))
        } else {
            finish(error = "Izin rekam layar belum diberikan. Tekan Hubungkan lalu pilih Seluruh layar.")
        }
        return true
    }

    fun dispose() {
        unregisterPermissionReceiver()
        finish(error = "Aplikasi ditutup.")
    }

    private fun requestCapture(accessory: UsbAccessory) {
        pendingAccessory = accessory
        val manager = activity.getSystemService(MediaProjectionManager::class.java)
        @Suppress("DEPRECATION")
        activity.startActivityForResult(manager.createScreenCaptureIntent(), CAPTURE_REQUEST)
    }

    private fun finish(value: Map<String, Any?>? = null, error: String? = null) {
        val result = pending ?: return
        pending = null
        if (error != null) result.error("head_unit", error, null) else result.success(value)
    }

    private fun unregisterPermissionReceiver() {
        permissionReceiver?.let { runCatching { activity.unregisterReceiver(it) } }
        permissionReceiver = null
    }

    private fun attached(): UsbAccessory? =
        usb?.accessoryList?.firstOrNull { it.manufacturer == "com.jvckenwood" && it.model == "tlink" }

    companion object {
        const val CAPTURE_REQUEST = 7301
    }
}
