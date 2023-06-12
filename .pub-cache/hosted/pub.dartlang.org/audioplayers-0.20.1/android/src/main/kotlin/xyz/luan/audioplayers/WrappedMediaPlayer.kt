package xyz.luan.audioplayers

import android.content.Context
import android.media.*
import android.os.Build
import android.os.PowerManager

class WrappedMediaPlayer internal constructor(
        private val ref: AudioplayersPlugin,
        override val playerId: String
) : Player(), MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener, AudioManager.OnAudioFocusChangeListener, MediaPlayer.OnSeekCompleteListener, MediaPlayer.OnErrorListener {
    private val audioFocusChangeListener: AudioManager.OnAudioFocusChangeListener? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private var player: MediaPlayer? = null
    private var url: String? = null
    private var dataSource: MediaDataSource? = null
    private var volume = 1.0
    private var rate = 1.0f
    private var respectSilence = false
    private var stayAwake = false
    private var duckAudio = false
    private var releaseMode: ReleaseMode = ReleaseMode.RELEASE
    private var playingRoute: String = "speakers"
    private var released = true
    private var prepared = false
    private var playing = false
    private var shouldSeekTo = -1

    /**
     * Setter methods
     */
    override fun setUrl(url: String, isLocal: Boolean) {
        if (this.url != url) {
            this.url = url
            val player = getOrCreatePlayer()
            player.setDataSource(url)
            preparePlayer(player)
        }

        if (Build.VERSION.SDK_INT >= 23) {
            // Dispose of any old data buffer array, if we are now playing from another source.
            dataSource = null
        }
    }

    override fun setDataSource(mediaDataSource: MediaDataSource?) {
        if (Build.VERSION.SDK_INT >= 23) {
            if (!objectEquals(dataSource, mediaDataSource)) {
                dataSource = mediaDataSource
                val player = getOrCreatePlayer()
                player.setDataSource(mediaDataSource)
                preparePlayer(player)
            }
        } else {
            throw RuntimeException("setDataSource is only available on API >= 23");
        }
    }

    private fun preparePlayer(player: MediaPlayer) {
        player.setVolume(volume.toFloat(), volume.toFloat())
        player.isLooping = releaseMode === ReleaseMode.LOOP
        player.prepareAsync()
    }

    private fun getOrCreatePlayer(): MediaPlayer {
        val currentPlayer = player
        return if (released || currentPlayer == null) {
            createPlayer().also {
                player = it
                released = false
            }
        } else if (prepared) {
            currentPlayer.also {
                it.reset()
                prepared = false
            }
        } else {
            currentPlayer
        }
    }

    override fun setVolume(volume: Double) {
        if (this.volume != volume) {
            this.volume = volume
            if (!released) {
                player?.setVolume(volume.toFloat(), volume.toFloat())
            }
        }
    }

    override fun setPlayingRoute(playingRoute: String) {
        if (this.playingRoute != playingRoute) {
            val wasPlaying = playing
            if (wasPlaying) {
                pause()
            }
            this.playingRoute = playingRoute
            val position = player?.currentPosition ?: 0
            released = false
            player = createPlayer().also {
                it.setDataSource(url)
                it.prepare()

                seek(position)
                if (wasPlaying) {
                    playing = true
                    it.start()
                }
            }
        }
    }

    override fun setRate(rate: Double) {
        this.rate = rate.toFloat()

        val player = this.player ?: return
        if (Build.VERSION.SDK_INT >= 23) {
            player.playbackParams = player.playbackParams.setSpeed(this.rate)
        }
    }

    override fun configAttributes(respectSilence: Boolean, stayAwake: Boolean, duckAudio: Boolean) {
        if (this.respectSilence != respectSilence) {
            this.respectSilence = respectSilence
            if (!released) {
                player?.let { setAttributes(it) }
            }
        }
        if (this.duckAudio != duckAudio) {
            this.duckAudio = duckAudio
            if (!released) {
                player?.let { setAttributes(it) }
            }
        }
        if (this.stayAwake != stayAwake) {
            this.stayAwake = stayAwake
            if (!released && this.stayAwake) {
                player?.setWakeMode(ref.getApplicationContext(), PowerManager.PARTIAL_WAKE_LOCK)
            }
        }
    }

    override fun onAudioFocusChange(focusChange: Int) {
        if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
            actuallyPlay()
        }
    }

    override fun setReleaseMode(releaseMode: ReleaseMode) {
        if (this.releaseMode !== releaseMode) {
            this.releaseMode = releaseMode
            if (!released) {
                player?.isLooping = releaseMode === ReleaseMode.LOOP
            }
        }
    }

    /**
     * Getter methods
     */
    override fun getDuration(): Int? {
        return player?.duration
    }

    override fun getCurrentPosition(): Int? {
        return player?.currentPosition
    }

    override fun isActuallyPlaying(): Boolean {
        return playing && prepared
    }

    private val audioManager: AudioManager
        get() = ref.getApplicationContext().getSystemService(Context.AUDIO_SERVICE) as AudioManager

    /**
     * Playback handling methods
     */
    override fun play() {
        if (duckAudio) {
            val audioManager = audioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                        .setAudioAttributes(
                                AudioAttributes.Builder()
                                        .setUsage(if (respectSilence) AudioAttributes.USAGE_NOTIFICATION_RINGTONE else AudioAttributes.USAGE_MEDIA)
                                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                        .build()
                        )
                        .setOnAudioFocusChangeListener { actuallyPlay() }.build()
                this.audioFocusRequest = audioFocusRequest
                audioManager.requestAudioFocus(audioFocusRequest)
            } else {
                // Request audio focus for playback
                @Suppress("DEPRECATION")
                val result = audioManager.requestAudioFocus(audioFocusChangeListener,  // Use the music stream.
                        AudioManager.STREAM_MUSIC,  // Request permanent focus.
                        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                    actuallyPlay()
                }
            }
        } else {
            actuallyPlay()
        }
    }

    private fun actuallyPlay() {
        if (!playing) {
            val currentPlayer = player
            playing = true
            if (released || currentPlayer == null) {
                released = false
                player = createPlayer().also {
                    if (Build.VERSION.SDK_INT >= 23 && dataSource != null) {
                        it.setDataSource(dataSource)
                    } else {
                        it.setDataSource(url)
                    }
                    it.prepareAsync()
                }
            } else if (prepared) {
                currentPlayer.start()
                ref.handleIsPlaying()
            }
        }
    }

    override fun stop() {
        if (duckAudio) {
            val audioManager = audioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                audioManager.abandonAudioFocus(audioFocusChangeListener)
            }
        }
        if (released) {
            return
        }
        if (releaseMode !== ReleaseMode.RELEASE) {
            if (playing) {
                playing = false
                player?.pause()
                player?.seekTo(0)
            }
        } else {
            release()
        }
    }

    override fun release() {
        if (released) {
            return
        }
        if (playing) {
            player?.stop()
        }
        player?.reset()
        player?.release()
        player = null
        prepared = false
        released = true
        playing = false
    }

    override fun pause() {
        if (playing) {
            playing = false
            player?.pause()
        }
    }

    // seek operations cannot be called until after
    // the player is ready.
    override fun seek(position: Int) {
        if (prepared) {
            player?.seekTo(position)
        } else {
            shouldSeekTo = position
        }
    }

    /**
     * MediaPlayer callbacks
     */
    override fun onPrepared(mediaPlayer: MediaPlayer) {
        prepared = true
        ref.handleDuration(this)
        if (playing) {
            player?.start()
            ref.handleIsPlaying()
        }
        if (shouldSeekTo >= 0) {
            player?.seekTo(shouldSeekTo)
            shouldSeekTo = -1
        }
    }

    override fun onCompletion(mediaPlayer: MediaPlayer) {
        if (releaseMode !== ReleaseMode.LOOP) {
            stop()
        }
        ref.handleCompletion(this)
    }

    override fun onError(mp: MediaPlayer, what: Int, extra: Int): Boolean {
        var whatMsg: String
        whatMsg = if (what == MediaPlayer.MEDIA_ERROR_SERVER_DIED) {
            "MEDIA_ERROR_SERVER_DIED"
        } else {
            "MEDIA_ERROR_UNKNOWN {what:$what}"
        }
        val extraMsg: String
        when (extra) {
            -2147483648 -> extraMsg = "MEDIA_ERROR_SYSTEM"
            MediaPlayer.MEDIA_ERROR_IO -> extraMsg = "MEDIA_ERROR_IO"
            MediaPlayer.MEDIA_ERROR_MALFORMED -> extraMsg = "MEDIA_ERROR_MALFORMED"
            MediaPlayer.MEDIA_ERROR_UNSUPPORTED -> extraMsg = "MEDIA_ERROR_UNSUPPORTED"
            MediaPlayer.MEDIA_ERROR_TIMED_OUT -> extraMsg = "MEDIA_ERROR_TIMED_OUT"
            else -> {
                whatMsg = "MEDIA_ERROR_UNKNOWN {extra:$extra}"
                extraMsg = whatMsg
            }
        }
        ref.handleError(this, "MediaPlayer error with what:$whatMsg extra:$extraMsg")
        return false
    }

    override fun onSeekComplete(mediaPlayer: MediaPlayer) {
        ref.handleSeekComplete()
    }

    /**
     * Internal logic. Private methods
     */
    private fun createPlayer(): MediaPlayer {
        val player = MediaPlayer()
        player.setOnPreparedListener(this)
        player.setOnCompletionListener(this)
        player.setOnSeekCompleteListener(this)
        player.setOnErrorListener(this)

        setAttributes(player)
        player.setVolume(volume.toFloat(), volume.toFloat())
        player.isLooping = releaseMode === ReleaseMode.LOOP
        return player
    }

    private fun setAttributes(player: MediaPlayer) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usage = when {
                // Works with bluetooth headphones
                // automatically switch to earpiece when disconnect bluetooth headphones
                playingRoute != "speakers" -> AudioAttributes.USAGE_VOICE_COMMUNICATION
                respectSilence -> AudioAttributes.USAGE_NOTIFICATION_RINGTONE
                else -> AudioAttributes.USAGE_MEDIA
            }
            player.setAudioAttributes(
                    AudioAttributes.Builder()
                            .setUsage(usage)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
            )
            if (usage == AudioAttributes.USAGE_VOICE_COMMUNICATION) {
                audioManager.isSpeakerphoneOn = false
            }
        } else {
            // This method is deprecated but must be used on older devices
            if (playingRoute == "speakers") {
                player.setAudioStreamType(if (respectSilence) AudioManager.STREAM_RING else AudioManager.STREAM_MUSIC)
            } else {
                player.setAudioStreamType(AudioManager.STREAM_VOICE_CALL)
            }
        }
    }

}
