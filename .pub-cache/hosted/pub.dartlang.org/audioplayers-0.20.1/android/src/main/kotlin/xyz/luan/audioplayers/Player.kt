package xyz.luan.audioplayers

import android.media.MediaDataSource

abstract class Player {
    abstract val playerId: String

    abstract fun getDuration(): Int?
    abstract fun getCurrentPosition(): Int?
    abstract fun isActuallyPlaying(): Boolean

    abstract fun play()
    abstract fun stop()
    abstract fun release()
    abstract fun pause()

    abstract fun configAttributes(respectSilence: Boolean, stayAwake: Boolean, duckAudio: Boolean)
    abstract fun setUrl(url: String, isLocal: Boolean)
    abstract fun setDataSource(mediaDataSource: MediaDataSource?)
    abstract fun setVolume(volume: Double)
    abstract fun setRate(rate: Double)
    abstract fun setReleaseMode(releaseMode: ReleaseMode)
    abstract fun setPlayingRoute(playingRoute: String)

    /**
     * Seek operations cannot be called until after the player is ready.
     */
    abstract fun seek(position: Int)

    companion object {
        @JvmStatic
        protected fun objectEquals(o1: Any?, o2: Any?): Boolean {
            return o1 == null && o2 == null || o1 != null && o1 == o2
        }
    }
}