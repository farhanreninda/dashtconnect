package io.github.farhanreninda.dashtconnect.receiver

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.hardware.usb.UsbAccessory
import android.hardware.usb.UsbManager
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import java.io.FileInputStream
import java.io.FileOutputStream

/**
 * Replaces the T-Link app: captures the phone screen and serves it to the head unit over the
 * AOA link. Touch needs no code here because the head unit registers itself as a USB HID
 * touchscreen while in accessory mode.
 */
class TLinkMirrorService : Service() {
    private var projection: MediaProjection? = null
    private var display: VirtualDisplay? = null
    private var reader: ImageReader? = null
    private var captureThread: HandlerThread? = null
    @Volatile private var latest: RfbFrame? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val log = ReceiverSessionLog.forContext(this)
        startInForeground()
        val accessory = intent?.parcelable<UsbAccessory>(UsbManager.EXTRA_ACCESSORY)
        val data = intent?.parcelable<Intent>(EXTRA_PROJECTION_DATA)
        if (active || accessory == null || data == null) {
            if (!active) stopSelf()
            return START_NOT_STICKY
        }
        active = true
        streaming = false
        problem = null
        log.write("tlink accessory ${accessory.manufacturer}/${accessory.model} v${accessory.version}")
        val manager = getSystemService(MediaProjectionManager::class.java)
        val mp = manager.getMediaProjection(intent.getIntExtra(EXTRA_RESULT_CODE, 0), data) ?: run {
            log.write("tlink screen capture refused")
            problem = "Izin rekam layar belum diberikan. Coba hubungkan lagi."
            stopSelf(); return START_NOT_STICKY
        }
        projection = mp
        startCapture(mp)
        Thread({ serve(accessory, log) }, "tlink-rfb").start()
        return START_NOT_STICKY
    }

    private fun startCapture(mp: MediaProjection) {
        val thread = HandlerThread("tlink-capture").also { it.start() }
        val handler = Handler(thread.looper)
        captureThread = thread
        mp.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() { stopSelf() }
        }, handler)
        val imageReader = ImageReader.newInstance(WIDTH, HEIGHT, PixelFormat.RGBA_8888, 2)
        var seq = 0L
        imageReader.setOnImageAvailableListener({ r ->
            val image = r.acquireLatestImage() ?: return@setOnImageAvailableListener
            image.use {
                val plane = it.planes[0]
                val buffer = plane.buffer
                val row = WIDTH * 4
                val pixels = ByteArray(row * HEIGHT)
                for (y in 0 until HEIGHT) {
                    buffer.position(y * plane.rowStride)
                    buffer.get(pixels, y * row, row)
                }
                latest = RfbFrame(WIDTH, HEIGHT, pixels, seq++)
            }
        }, handler)
        reader = imageReader
        display = mp.createVirtualDisplay(
            "dashtconnect-tlink", WIDTH, HEIGHT, resources.displayMetrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, imageReader.surface, null, handler,
        )
    }

    private fun serve(accessory: UsbAccessory, log: ReceiverSessionLog) {
        val fd = getSystemService(UsbManager::class.java)?.openAccessory(accessory)
        if (fd == null) {
            log.write("tlink open accessory failed")
            problem = "Koneksi USB head unit belum bisa dibuka. Tutup T-Link, cabut lalu colok ulang kabel."
        } else {
            fd.use {
                val wire = TLinkWireLog(log::write)
                val bearer = TLinkAapBearer(wire.input(FileInputStream(it.fileDescriptor)), wire.output(FileOutputStream(it.fileDescriptor)), log::write)
                try {
                    bearer.establish()
                    TLinkRfbServer(
                        bearer.input, bearer.output,
                        WIDTH, HEIGHT, { latest }, log::write, onFirstFrame = { streaming = true },
                    ).run()
                } catch (e: Exception) {
                    log.write("tlink aap failed: ${e.javaClass.simpleName} ${e.message}")
                } finally {
                    bearer.close()
                }
            }
            problem = if (streaming) "Tampilan ke head unit terputus. Colok ulang kabel lalu hubungkan lagi."
            else "Head unit belum menerima tampilan DashTConnect. Bagikan log diagnostik dari Pengaturan."
        }
        stopSelf()
    }

    private fun startInForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL, "Layar mobil", NotificationManager.IMPORTANCE_LOW))
        }
        val notification = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this))
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("DashTConnect tampil di head unit")
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        active = false
        streaming = false
        display?.release()
        reader?.close()
        projection?.stop()
        captureThread?.quitSafely()
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    private inline fun <reified T : android.os.Parcelable> Intent.parcelable(key: String): T? =
        if (Build.VERSION.SDK_INT >= 33) getParcelableExtra(key, T::class.java) else getParcelableExtra(key)

    companion object {
        // shortcut: fixed 800x480 because RFB lets the server pick the size; read the head unit's real panel size from the log and adjust.
        const val WIDTH = 800
        const val HEIGHT = 480
        /** True while a head unit session is being served. */
        @Volatile var active = false
            private set
        /** True once the head unit has received the first frame of the current session. */
        @Volatile var streaming = false
            private set
        /** Why the last session ended or never started, for the head unit step in the app. */
        @Volatile var problem: String? = null
            private set
        private const val CHANNEL = "tlink"
        private const val NOTIFICATION_ID = 7301
        private const val EXTRA_RESULT_CODE = "resultCode"
        private const val EXTRA_PROJECTION_DATA = "projectionData"

        fun start(context: Context, accessory: UsbAccessory, resultCode: Int, data: Intent) {
            val intent = Intent(context, TLinkMirrorService::class.java)
                .putExtra(UsbManager.EXTRA_ACCESSORY, accessory)
                .putExtra(EXTRA_RESULT_CODE, resultCode)
                .putExtra(EXTRA_PROJECTION_DATA, data)
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
        }
    }
}
