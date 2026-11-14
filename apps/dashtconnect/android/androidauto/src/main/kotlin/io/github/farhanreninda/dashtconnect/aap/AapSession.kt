package io.github.farhanreninda.dashtconnect.aap

internal fun interface AapLink {
    fun send(channel: Int, type: Int, body: ByteArray)
}

internal interface VideoSink {
    fun codecConfig(data: ByteArray, offset: Int, length: Int)
    fun frame(data: ByteArray, offset: Int, length: Int)
}

/**
 * Canvas announced to the phone. The phone draws its UI inside width - marginWidth by
 * height - marginHeight, so the margins make the content match the screen's aspect ratio.
 */
data class VideoSpec(val marginWidth: Int, val marginHeight: Int, val density: Int = 160) {
    val width get() = WIDTH
    val height get() = HEIGHT

    companion object {
        const val WIDTH = 1280
        const val HEIGHT = 720

        fun forScreen(screenWidth: Int, screenHeight: Int): VideoSpec {
            val w = maxOf(screenWidth, screenHeight).toLong()
            val h = minOf(screenWidth, screenHeight).toLong()
            require(w > 0 && h > 0)
            return if (w * HEIGHT >= h * WIDTH) VideoSpec(0, HEIGHT - (WIDTH * h / w).toInt())
                else VideoSpec(WIDTH - (HEIGHT * w / h).toInt(), 0)
        }
    }
}

/** Head-unit side of an AAP session after TLS: answers the phone and routes video and input. */
internal class AapSession(
    private val link: AapLink,
    private val spec: VideoSpec,
    private val video: VideoSink,
    private val softwareVersion: String,
) {
    @Volatile var ended = false
        private set
    @Volatile var inputOpen = false
        private set
    private val mediaSessions = HashMap<Int, Int>()

    fun handle(channel: Int, type: Int, body: ByteArray, offset: Int = 0) {
        when {
            channel == CONTROL -> control(type, body, offset)
            type == CHANNEL_OPEN_REQUEST -> {
                link.send(channel, CHANNEL_OPEN_RESPONSE, Proto().int(1, 0).build())
                if (channel == INPUT) inputOpen = true
            }
            channel == SENSOR -> sensor(type, body, offset)
            channel == VIDEO -> video(type, body, offset)
            channel in AUDIO_CHANNELS -> audio(channel, type, body, offset)
            channel == INPUT && type == INPUT_BINDING_REQUEST ->
                link.send(INPUT, INPUT_BINDING_RESPONSE, Proto().int(1, 0).build())
        }
    }

    /** Asks the phone for a fresh keyframe, used after the decoder surface is recreated. */
    fun requestKeyframe() = link.send(VIDEO, VIDEO_FOCUS_NOTIFICATION, projectedFocus())

    fun touch(action: Int, actionIndex: Int, pointers: List<Pointer>, timestampNs: Long) {
        if (!inputOpen) return
        val report = Proto()
            .int(1, timestampNs)
            .message(3) {
                for (p in pointers) message(1) { int(1, p.x); int(2, p.y); int(3, p.id) }
                int(2, actionIndex)
                int(3, action)
            }
        link.send(INPUT, INPUT_EVENT, report.build())
    }

    fun byeBye() = link.send(CONTROL, BYEBYE_REQUEST, Proto().int(1, 1).build())

    private fun control(type: Int, body: ByteArray, offset: Int) {
        when (type) {
            SERVICE_DISCOVERY_REQUEST -> link.send(CONTROL, SERVICE_DISCOVERY_RESPONSE, discovery())
            PING_REQUEST -> {
                val timestamp = readVarints(body, offset)[1] ?: 0L
                link.send(CONTROL, PING_RESPONSE, Proto().int(1, timestamp).build())
            }
            NAV_FOCUS_REQUEST -> link.send(CONTROL, NAV_FOCUS_NOTIFICATION, Proto().int(1, 2).build())
            AUDIO_FOCUS_REQUEST -> {
                val state = when (readVarints(body, offset)[1]?.toInt()) {
                    1 -> 1
                    2, 3 -> 2
                    else -> 3
                }
                link.send(CONTROL, AUDIO_FOCUS_NOTIFICATION, Proto().int(1, state).build())
            }
            BYEBYE_REQUEST -> {
                link.send(CONTROL, BYEBYE_RESPONSE, ByteArray(0))
                ended = true
            }
            BYEBYE_RESPONSE -> ended = true
        }
    }

    private fun sensor(type: Int, body: ByteArray, offset: Int) {
        if (type != SENSOR_START_REQUEST) return
        val sensor = readVarints(body, offset)[1]?.toInt()
        link.send(SENSOR, SENSOR_START_RESPONSE, Proto().int(1, 0).build())
        when (sensor) {
            SENSOR_DRIVING_STATUS ->
                link.send(SENSOR, SENSOR_EVENT, Proto().message(13) { int(1, 0) }.build())
            SENSOR_NIGHT ->
                link.send(SENSOR, SENSOR_EVENT, Proto().message(10) { bool(1, false) }.build())
        }
    }

    private fun video(type: Int, body: ByteArray, offset: Int) {
        when (type) {
            MEDIA_SETUP -> {
                link.send(VIDEO, MEDIA_CONFIG, Proto().int(1, 2).int(2, 1).int(3, 0).build())
                requestKeyframe()
            }
            MEDIA_START -> mediaSessions[VIDEO] = readVarints(body, offset)[1]?.toInt() ?: 0
            VIDEO_FOCUS_REQUEST -> requestKeyframe()
            MEDIA_CODEC_CONFIG -> {
                video.codecConfig(body, offset, body.size - offset)
                ack(VIDEO)
            }
            MEDIA_DATA -> {
                // Data carries an 8-byte timestamp before the H.264 access unit.
                if (body.size - offset > 8) video.frame(body, offset + 8, body.size - offset - 8)
                ack(VIDEO)
            }
        }
    }

    // Audio is acknowledged but not played yet; the phone still needs the channel to behave.
    private fun audio(channel: Int, type: Int, body: ByteArray, offset: Int) {
        when (type) {
            MEDIA_SETUP -> link.send(channel, MEDIA_CONFIG, Proto().int(1, 2).int(2, 1).int(3, 0).build())
            MEDIA_START -> mediaSessions[channel] = readVarints(body, offset)[1]?.toInt() ?: 0
            MEDIA_CODEC_CONFIG, MEDIA_DATA -> ack(channel)
        }
    }

    private fun ack(channel: Int) =
        link.send(channel, MEDIA_ACK, Proto().int(1, mediaSessions[channel] ?: 0).int(2, 1).build())

    private fun projectedFocus() = Proto().int(1, 1).bool(2, false).build()

    private fun discovery(): ByteArray = Proto()
        .message(1) {
            int(1, SENSOR)
            message(2) {
                message(1) { int(1, SENSOR_DRIVING_STATUS) }
                message(1) { int(1, SENSOR_NIGHT) }
            }
        }
        .message(1) {
            int(1, VIDEO)
            message(3) {
                int(1, CODEC_H264_BP)
                int(2, 0)
                message(4) {
                    int(1, RESOLUTION_1280x720)
                    int(2, FRAME_RATE_30)
                    int(3, spec.marginWidth)
                    int(4, spec.marginHeight)
                    int(5, spec.density)
                    int(10, CODEC_H264_BP)
                }
                bool(5, true)
            }
        }
        .message(1) {
            int(1, INPUT)
            message(4) { message(2) { int(1, spec.width); int(2, spec.height) } }
        }
        // This phone's GAL rejects the SPEECH stream (type 1), so only MEDIA and SYSTEM are offered.
        .message(1) { audioSink(AUDIO_MEDIA, STREAM_MEDIA, 48000, 2) }
        .message(1) { audioSink(AUDIO_SYSTEM, STREAM_SYSTEM, 16000, 1) }
        .string(2, "DashTConnect")
        .string(3, "T-Link")
        .string(4, "2026")
        .string(5, "dashtconnect")
        .int(6, DRIVER_POSITION_RIGHT)
        .string(7, "DashTConnect")
        .string(8, "Receiver")
        .string(9, softwareVersion)
        .string(10, softwareVersion)
        .bool(11, false)
        .string(14, "DashTConnect")
        .build()

    /** One audio sink service: channel id, AudioStreamType, and its single PCM config. */
    private fun Proto.audioSink(channel: Int, stream: Int, sampleRate: Int, channels: Int) {
        int(1, channel)
        message(3) {
            int(1, CODEC_AUDIO_PCM)
            int(2, stream)
            message(3) {
                int(1, sampleRate)
                int(2, 16)
                int(3, channels)
            }
        }
    }

    data class Pointer(val id: Int, val x: Int, val y: Int)

    companion object {
        const val CONTROL = 0
        const val SENSOR = 1
        const val VIDEO = 2
        const val INPUT = 3
        const val AUDIO_SPEECH = 4
        const val AUDIO_SYSTEM = 5
        const val AUDIO_MEDIA = 6
        val AUDIO_CHANNELS = setOf(AUDIO_SPEECH, AUDIO_SYSTEM, AUDIO_MEDIA)

        const val CODEC_AUDIO_PCM = 1
        const val STREAM_SPEECH = 1
        const val STREAM_SYSTEM = 2
        const val STREAM_MEDIA = 3

        const val VERSION_REQUEST = 1
        const val VERSION_RESPONSE = 2
        const val SSL_HANDSHAKE = 3
        const val AUTH_COMPLETE = 4
        const val SERVICE_DISCOVERY_REQUEST = 5
        const val SERVICE_DISCOVERY_RESPONSE = 6
        const val CHANNEL_OPEN_REQUEST = 7
        const val CHANNEL_OPEN_RESPONSE = 8
        const val PING_REQUEST = 11
        const val PING_RESPONSE = 12
        const val NAV_FOCUS_REQUEST = 13
        const val NAV_FOCUS_NOTIFICATION = 14
        const val BYEBYE_REQUEST = 15
        const val BYEBYE_RESPONSE = 16
        const val AUDIO_FOCUS_REQUEST = 18
        const val AUDIO_FOCUS_NOTIFICATION = 19

        const val MEDIA_DATA = 0
        const val MEDIA_CODEC_CONFIG = 1
        const val MEDIA_SETUP = 0x8000
        const val MEDIA_START = 0x8001
        const val MEDIA_CONFIG = 0x8003
        const val MEDIA_ACK = 0x8004
        const val VIDEO_FOCUS_REQUEST = 0x8007
        const val VIDEO_FOCUS_NOTIFICATION = 0x8008

        const val SENSOR_START_REQUEST = 0x8001
        const val SENSOR_START_RESPONSE = 0x8002
        const val SENSOR_EVENT = 0x8003
        const val SENSOR_NIGHT = 10
        const val SENSOR_DRIVING_STATUS = 13

        const val INPUT_EVENT = 0x8001
        const val INPUT_BINDING_REQUEST = 0x8002
        const val INPUT_BINDING_RESPONSE = 0x8003

        const val CODEC_H264_BP = 3
        const val RESOLUTION_1280x720 = 2
        const val FRAME_RATE_30 = 2
        // Toyota Raize Indonesia: setir kanan.
        const val DRIVER_POSITION_RIGHT = 1

        fun isControlType(type: Int) = type in 1..26
    }
}
