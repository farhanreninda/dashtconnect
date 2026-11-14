package io.github.farhanreninda.dashtconnect

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.github.farhanreninda.dashtconnect.platform.DeviceChannel
import io.github.farhanreninda.dashtconnect.receiver.ReceiverChannel
import io.github.farhanreninda.dashtconnect.androidauto.AndroidAutoChannel

class MainActivity : FlutterActivity() {
    private var deviceChannel: DeviceChannel? = null
    private var receiverChannel: ReceiverChannel? = null
    private var androidAutoChannel: AndroidAutoChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        androidAutoChannel?.dispose()
        androidAutoChannel = AndroidAutoChannel(this, flutterEngine.dartExecutor.binaryMessenger)
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
        androidAutoChannel?.resume()
    }

    override fun onPause() {
        deviceChannel?.pause()
        androidAutoChannel?.pause()
        receiverChannel?.pause()
        super.onPause()
    }

    override fun onDestroy() {
        deviceChannel?.dispose()
        androidAutoChannel?.dispose()
        androidAutoChannel = null
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
        receiverChannel?.activityResult(requestCode)
    }
}
