package xyz.luan.audioplayers.player

import android.content.Context
import android.media.AudioManager
import android.media.MediaPlayer
import xyz.luan.audioplayers.AudioContextAndroid
import xyz.luan.audioplayers.AudioplayersPlugin
import xyz.luan.audioplayers.PlayerMode
import xyz.luan.audioplayers.PlayerMode.LOW_LATENCY
import xyz.luan.audioplayers.PlayerMode.MEDIA_PLAYER
import xyz.luan.audioplayers.ReleaseMode
import xyz.luan.audioplayers.source.Source

// For some reason this cannot be accessed from MediaPlayer.MEDIA_ERROR_SYSTEM
private const val MEDIA_ERROR_SYSTEM = -2147483648

class WrappedPlayer internal constructor(
    private val ref: AudioplayersPlugin,
    val playerId: String,
    var context: AudioContextAndroid,
) {
    private var player: Player? = null

    var source: Source? = null
        set(value) {
            if (field != value) {
                field = value
                if (value != null) {
                    val player = getOrCreatePlayer()
                    player.setSource(value)
                    player.configAndPrepare()
                } else {
                    released = true
                    prepared = false
                    playing = false
                    player?.release()
                }
            }
        }

    var volume = 1.0f
        set(value) {
            if (field != value) {
                field = value
                if (!released) {
                    player?.setVolume(value)
                }
            }
        }

    var rate = 1.0f
        set(value) {
            if (field != value) {
                field = value
                player?.setRate(value)
            }
        }

    var releaseMode = ReleaseMode.RELEASE
        set(value) {
            if (field != value) {
                field = value
                if (!released) {
                    player?.setLooping(isLooping)
                }
            }
        }

    val isLooping: Boolean
        get() = releaseMode == ReleaseMode.LOOP

    var playerMode: PlayerMode = MEDIA_PLAYER
        set(value) {
            if (field != value) {
                field = value

                // if the player exists, we need to re-create it from scratch;
                // this will probably cause music to pause for a second
                player?.let {
                    shouldSeekTo = maybeGetCurrentPosition()
                    prepared = false
                    it.release()
                }
                initPlayer()
            }
        }

    var released = true
    var prepared = false
    var playing = false
    var shouldSeekTo = -1

    private val focusManager = FocusManager(this)

    private fun maybeGetCurrentPosition(): Int {
        // for Sound Pool, we can't get current position, so we just start over
        return runCatching { player?.getCurrentPosition().takeUnless { it == 0 } }.getOrNull() ?: -1
    }

    private fun getOrCreatePlayer(): Player {
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

    fun updateAudioContext(audioContext: AudioContextAndroid) {
        if (context == audioContext) {
            return
        }
        if (context.audioFocus != null && audioContext.audioFocus == null) {
            focusManager.handleStop()
        }
        this.context = audioContext.copy()
        player?.updateContext(context)
    }

    // Getters

    /**
     * Returns the duration of the media in milliseconds, if available.
     */
    fun getDuration(): Int? {
        return if (prepared) player?.getDuration() else null
    }

    /**
     * Returns the current position of the playback in milliseconds, if available.
     */
    fun getCurrentPosition(): Int? {
        return if (prepared) player?.getCurrentPosition() else null
    }

    fun isActuallyPlaying(): Boolean {
        return playing && prepared && player?.isActuallyPlaying() == true
    }

    val applicationContext: Context
        get() = ref.getApplicationContext()

    val audioManager: AudioManager
        get() = applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    /**
     * Playback handling methods
     */
    fun play() {
        focusManager.maybeRequestAudioFocus(andThen = ::actuallyPlay)
    }

    private fun actuallyPlay() {
        if (!playing && !released) {
            val currentPlayer = player
            playing = true
            if (currentPlayer == null) {
                initPlayer()
            } else if (prepared) {
                currentPlayer.start()
                ref.handleIsPlaying()
            }
        }
    }

    fun stop() {
        focusManager.handleStop()
        if (released) {
            return
        }
        if (releaseMode != ReleaseMode.RELEASE) {
            pause()
            if(prepared) {
                if (player?.isLiveStream() == true) {
                    player?.stop()
                    prepared = false
                    player?.prepare()
                } else {
                    // MediaPlayer does not allow to call player.seekTo after calling player.stop
                    seek(0)
                }
            }
        } else {
            release()
        }
    }

    fun release() {
        focusManager.handleStop()
        if (released) {
            return
        }
        if (playing) {
            player?.stop()
        }

        // Setting source to null will reset released, prepared and playing
        // and also calls player.release()
        source = null
        player = null
    }

    fun pause() {
        if (playing) {
            playing = false
            if (prepared) {
                player?.pause()
            }
        }
    }

    // seek operations cannot be called until after
    // the player is ready.
    fun seek(position: Int) {
        shouldSeekTo = if (prepared && player?.isLiveStream() != true) {
            player?.seekTo(position)
            -1
        } else {
            position
        }
    }

    /**
     * Player callbacks
     */
    fun onPrepared() {
        prepared = true
        ref.handleDuration(this)
        if (playing) {
            player?.start()
            ref.handleIsPlaying()
        }
        if (shouldSeekTo >= 0 && player?.isLiveStream() != true) {
            player?.seekTo(shouldSeekTo)
        }
    }

    fun onCompletion() {
        if (releaseMode != ReleaseMode.LOOP) {
            stop()
        }
        ref.handleComplete(this)
    }

    fun onError(what: Int, extra: Int): Boolean {
        val whatMsg = if (what == MediaPlayer.MEDIA_ERROR_SERVER_DIED) {
            "MEDIA_ERROR_SERVER_DIED"
        } else {
            "MEDIA_ERROR_UNKNOWN {what:$what}"
        }
        val extraMsg = when (extra) {
            MEDIA_ERROR_SYSTEM -> "MEDIA_ERROR_SYSTEM"
            MediaPlayer.MEDIA_ERROR_IO -> "MEDIA_ERROR_IO"
            MediaPlayer.MEDIA_ERROR_MALFORMED -> "MEDIA_ERROR_MALFORMED"
            MediaPlayer.MEDIA_ERROR_UNSUPPORTED -> "MEDIA_ERROR_UNSUPPORTED"
            MediaPlayer.MEDIA_ERROR_TIMED_OUT -> "MEDIA_ERROR_TIMED_OUT"
            else -> "MEDIA_ERROR_UNKNOWN {extra:$extra}"
        }
        ref.handleError(this, "MediaPlayer error with what:$whatMsg extra:$extraMsg")
        return false
    }

    fun onBuffering(percent: Int) {
        // TODO(luan) expose this as a stream
    }

    fun onSeekComplete() {
        ref.handleSeekComplete(this)
    }

    /**
     * Internal logic. Private methods
     */

    /**
     * Create new player
     */
    private fun createPlayer(): Player {
        return when (playerMode) {
            MEDIA_PLAYER -> MediaPlayerPlayer(this)
            LOW_LATENCY -> SoundPoolPlayer(this)
        }
    }

    /**
     * Create new player, assign and configure source
     */
    private fun initPlayer() {
        val player = createPlayer()
        // Need to set player before calling prepare, as onPrepared may is called before player is assigned
        this.player = player
        source?.let {
            player.setSource(it)
            player.configAndPrepare()
        }
    }

    private fun Player.configAndPrepare() {
        setRate(rate)
        setVolume(volume)
        setLooping(isLooping)
        prepare()
    }
}
