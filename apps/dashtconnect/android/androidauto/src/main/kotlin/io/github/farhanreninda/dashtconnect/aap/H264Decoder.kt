package io.github.farhanreninda.dashtconnect.aap

import android.media.MediaCodec
import android.media.MediaFormat
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface

/** Hardware H.264 decode straight onto the projection surface. */
internal class H264Decoder(surface: Surface, private val onFirstFrame: () -> Unit, private val onError: (Exception) -> Unit) {
    private val lock = Any()
    private val freeInputs = ArrayDeque<Int>()
    private val pending = ArrayDeque<Pair<ByteArray, Int>>()
    private val thread = HandlerThread("aa-video").apply { start() }
    private val codec = MediaCodec.createDecoderByType(MIME)
    private var released = false
    private var rendered = false

    init {
        codec.setCallback(object : MediaCodec.Callback() {
            override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
                synchronized(lock) { freeInputs.addLast(index); feed() }
            }
            override fun onOutputBufferAvailable(codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo) {
                synchronized(lock) { if (released) return }
                codec.releaseOutputBuffer(index, true)
                if (!rendered) { rendered = true; onFirstFrame() }
            }
            override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) = onError(e)
            override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) = Unit
        }, Handler(thread.looper))
        val format = MediaFormat.createVideoFormat(MIME, VideoSpec.WIDTH, VideoSpec.HEIGHT)
        // Without these the decoder may hold several frames back, which shows as lag on every transition.
        format.setInteger(MediaFormat.KEY_PRIORITY, 0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) format.setInteger(MediaFormat.KEY_LOW_LATENCY, 1)
        codec.configure(format, surface, null, 0)
        codec.start()
    }

    fun submit(data: ByteArray, offset: Int, length: Int, config: Boolean) {
        val flags = if (config) MediaCodec.BUFFER_FLAG_CODEC_CONFIG else 0
        synchronized(lock) {
            if (released) return
            // shortcut: no cap; if a slow decoder makes this grow on device, drop to a keyframe request.
            pending.addLast(data.copyOfRange(offset, offset + length) to flags)
            feed()
        }
    }

    private fun feed() {
        while (freeInputs.isNotEmpty() && pending.isNotEmpty()) {
            val index = freeInputs.removeFirst()
            val (bytes, flags) = pending.removeFirst()
            try {
                val buffer = codec.getInputBuffer(index) ?: continue
                buffer.clear()
                buffer.put(bytes, 0, minOf(bytes.size, buffer.remaining()))
                codec.queueInputBuffer(index, 0, buffer.position(), System.nanoTime() / 1000, flags)
            } catch (e: IllegalStateException) {
                onError(e)
                return
            }
        }
    }

    fun release() {
        synchronized(lock) {
            if (released) return
            released = true
            pending.clear()
        }
        runCatching { codec.stop() }
        runCatching { codec.release() }
        thread.quitSafely()
    }

    private companion object { const val MIME = "video/avc" }
}
