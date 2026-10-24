package io.github.farhanreninda.dashtconnect

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.github.farhanreninda.dashtconnect.platform.DeviceChannel
import io.github.farhanreninda.dashtconnect.receiver.ReceiverChannel

class MainActivity : FlutterActivity() {
    private var deviceChannel: DeviceChannel? = null
    private var receiverChannel: ReceiverChannel? = null

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
}
