package io.github.farhanreninda.dashtconnect

import android.content.Intent
import android.hardware.usb.UsbAccessory
import android.hardware.usb.UsbManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.github.farhanreninda.dashtconnect.platform.DeviceChannel
import io.github.farhanreninda.dashtconnect.receiver.ReceiverChannel
import io.github.farhanreninda.dashtconnect.receiver.TLinkMirrorService

class MainActivity : FlutterActivity() {
    private var deviceChannel: DeviceChannel? = null
    private var receiverChannel: ReceiverChannel? = null
    private var pendingAccessory: UsbAccessory? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) handleAccessory(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleAccessory(intent)
    }

    /** Head unit plugged in: ask for screen capture, then serve it in place of the T-Link app. */
    private fun handleAccessory(intent: Intent?) {
        if (intent?.action != UsbManager.ACTION_USB_ACCESSORY_ATTACHED) return
        @Suppress("DEPRECATION")
        pendingAccessory = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(UsbManager.EXTRA_ACCESSORY, UsbAccessory::class.java)
        } else {
            intent.getParcelableExtra(UsbManager.EXTRA_ACCESSORY)
        } ?: return
        val manager = getSystemService(MediaProjectionManager::class.java)
        @Suppress("DEPRECATION")
        startActivityForResult(manager.createScreenCaptureIntent(), TLINK_CAPTURE_REQUEST)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deviceChannel?.dispose()
        deviceChannel = DeviceChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        receiverChannel?.dispose()
        receiverChannel = ReceiverChannel(this, flutterEngine.dartExecutor.binaryMessenger).also {
            flutterEngine.platformViewsController.registry.registerViewFactory("dashtconnect/receiver_surface", it.viewFactory)
        }
    }

    override fun onResume() {
        super.onResume()
        deviceChannel?.resume()
    }

    override fun onPause() {
        deviceChannel?.pause()
        receiverChannel?.pause()
        super.onPause()
    }

    override fun onDestroy() {
        deviceChannel?.dispose()
        receiverChannel?.dispose()
        deviceChannel = null
        receiverChannel = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        receiverChannel?.permissionsResult(requestCode)
    }

    @Deprecated("Activity result bridge for receiver system panels")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == TLINK_CAPTURE_REQUEST) {
            val accessory = pendingAccessory
            pendingAccessory = null
            if (resultCode == RESULT_OK && data != null && accessory != null) {
                TLinkMirrorService.start(this, accessory, resultCode, data)
            }
            return
        }
        receiverChannel?.activityResult(requestCode)
    }

    private companion object {
        const val TLINK_CAPTURE_REQUEST = 7301
    }
}
