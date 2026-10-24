package io.github.farhanreninda.dashtconnect.receiver

data class ReceiverVideoSize(val width: Int, val height: Int) {
    init {
        require(width in 640..1920 && height in 360..1280 && width % 2 == 0 && height % 2 == 0)
    }

    companion object {
        fun forDisplay(width: Int, height: Int): ReceiverVideoSize {
            require(width > 0 && height > 0)
            val landscapeWidth = maxOf(width, height)
            val landscapeHeight = minOf(width, height)
            val videoHeight = (1280.0 * landscapeHeight / landscapeWidth).toInt() / 2 * 2
            return ReceiverVideoSize(1280, videoHeight.coerceIn(360, 1280))
        }
    }
}
