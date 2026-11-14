package io.github.farhanreninda.dashtconnect.aap

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout

/**
 * Full-screen landscape surface for the projected Android Auto UI. T-Link mirrors this screen
 * to the head unit, and touches coming back through T-Link land here.
 */
class AndroidAutoProjectionActivity : Activity() {
    private lateinit var surface: SurfaceView
    private lateinit var spec: VideoSpec
    private val onState: () -> Unit = {
        runOnUiThread {
            val state = AndroidAutoProjection.state
            if (state == AndroidAutoProjection.State.FAILED || state == AndroidAutoProjection.State.ENDED) finish()
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val root = FrameLayout(this).apply { setBackgroundColor(0xFF000000.toInt()) }
        surface = SurfaceView(this)
        root.addView(surface)
        setContentView(root)
        hideSystemBars()

        val metrics = resources.displayMetrics
        spec = VideoSpec.forScreen(metrics.widthPixels, metrics.heightPixels)
        root.addOnLayoutChangeListener { _, l, t, r, b, _, _, _, _ -> place(r - l, b - t) }
        root.setOnTouchListener { _, event -> touch(event); true }
        surface.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) = AndroidAutoProjection.attach(holder.surface)
            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit
            override fun surfaceDestroyed(holder: SurfaceHolder) = AndroidAutoProjection.detach()
        })
        AndroidAutoProjection.addListener(onState)
        AndroidAutoProjection.start(this, spec, intent.getStringExtra(EXTRA_VERSION) ?: "1")
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    override fun onDestroy() {
        AndroidAutoProjection.removeListener(onState)
        if (isFinishing) AndroidAutoProjection.stop()
        super.onDestroy()
    }

    /** Scales the full video canvas so its content area (canvas minus margins) fills the screen. */
    private fun place(width: Int, height: Int) {
        if (width == 0 || height == 0) return
        val scale = scale(width)
        val params = FrameLayout.LayoutParams((VideoSpec.WIDTH * scale).toInt(), (VideoSpec.HEIGHT * scale).toInt())
        params.leftMargin = -(spec.marginWidth / 2f * scale).toInt()
        params.topMargin = -(spec.marginHeight / 2f * scale).toInt()
        if (surface.layoutParams?.width != params.width || (surface.layoutParams as? FrameLayout.LayoutParams)?.topMargin != params.topMargin) {
            surface.layoutParams = params
        }
    }

    private fun scale(screenWidth: Int) = screenWidth.toFloat() / (VideoSpec.WIDTH - spec.marginWidth)

    private fun touch(event: MotionEvent) {
        val action = event.actionMasked
        if (action !in SUPPORTED_ACTIONS) return
        val scale = scale(window.decorView.width.takeIf { it > 0 } ?: return)
        val pointers = (0 until event.pointerCount).map {
            AapSession.Pointer(
                id = event.getPointerId(it),
                x = (event.getX(it) / scale + spec.marginWidth / 2f).toInt().coerceIn(0, VideoSpec.WIDTH - 1),
                y = (event.getY(it) / scale + spec.marginHeight / 2f).toInt().coerceIn(0, VideoSpec.HEIGHT - 1),
            )
        }
        AndroidAutoProjection.touch(action, event.actionIndex, pointers)
    }

    @Suppress("DEPRECATION")
    private fun hideSystemBars() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.apply {
                hide(WindowInsets.Type.systemBars())
                systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
    }

    companion object {
        const val EXTRA_VERSION = "version"
        // MotionEvent's masked action codes match AAP's TouchEvent.PointerAction values.
        private val SUPPORTED_ACTIONS = setOf(
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_UP, MotionEvent.ACTION_MOVE,
            MotionEvent.ACTION_CANCEL, MotionEvent.ACTION_POINTER_DOWN, MotionEvent.ACTION_POINTER_UP,
        )
    }
}
