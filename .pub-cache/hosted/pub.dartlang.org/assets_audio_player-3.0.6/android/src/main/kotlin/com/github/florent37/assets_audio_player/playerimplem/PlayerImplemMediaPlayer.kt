package com.github.florent37.assets_audio_player.playerimplem

import android.content.Context
import android.media.MediaPlayer
import android.media.MediaPlayer.*
import android.net.Uri
import android.util.Log
import com.github.florent37.assets_audio_player.AssetAudioPlayerThrowable
import com.github.florent37.assets_audio_player.AssetsAudioPlayerPlugin
import com.github.florent37.assets_audio_player.Player
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class PlayerImplemTesterMediaPlayer : PlayerImplemTester {

    private var mediaPlayer :PlayerImplemMediaPlayer? = null


    private fun mapError(t: Throwable): AssetAudioPlayerThrowable {
        return AssetAudioPlayerThrowable.PlayerError(t)
    }


    override suspend fun open(configuration: PlayerFinderConfiguration): PlayerFinder.PlayerWithDuration {
        if(AssetsAudioPlayerPlugin.displayLogs) {
            Log.d("PlayerImplem", "trying to open with native mediaplayer")
        }
        val mediaPlayer = PlayerImplemMediaPlayer(
                onFinished = {
                    configuration.onFinished?.invoke()
                    //stop(pingListener = false)
                },
                onBuffering = {
                    configuration.onBuffering?.invoke(it)
                },
                onError = { t ->
                    configuration.onError?.invoke(mapError(t))
                }
        )
        try {
            val durationMS = mediaPlayer?.open(
                    context = configuration.context,
                    assetAudioPath = configuration.assetAudioPath,
                    audioType = configuration.audioType,
                    assetAudioPackage = configuration.assetAudioPackage,
                    networkHeaders = configuration.networkHeaders,
                    flutterAssets = configuration.flutterAssets,
                    drmConfiguration = configuration.drmConfiguration
            )
            return PlayerFinder.PlayerWithDuration(
                    player = mediaPlayer!!,
                    duration = durationMS!!
            )
        } catch (t: Throwable) {
            if(AssetsAudioPlayerPlugin.displayLogs) {
                Log.d("PlayerImplem", "failed to open with native mediaplayer")
            }

            mediaPlayer?.release()
            throw  t
        }
    }
}

class PlayerImplemMediaPlayer(
        onFinished: (() -> Unit),
        onBuffering: ((Boolean) -> Unit),
        onError: ((Throwable) -> Unit)
) : PlayerImplem(
        onFinished = onFinished,
        onBuffering = onBuffering,
        onError = onError
) {
    private var mediaPlayer: MediaPlayer? = null

    override val isPlaying: Boolean
        get() = try {
            mediaPlayer?.isPlaying ?: false
        } catch (t: Throwable) {
            false
        }
    override val currentPositionMs: Long
        get() = try {
            mediaPlayer?.currentPosition?.toLong() ?: 0
        } catch (t: Throwable) {
            0
        }

    override var loopSingleAudio: Boolean
        get() = mediaPlayer?.isLooping ?: false
        set(value) {
            mediaPlayer?.isLooping = value
        }

    override fun stop() {
        mediaPlayer?.stop()
    }

    override fun play() {
        mediaPlayer?.start()
    }

    override fun pause() {
        mediaPlayer?.pause()
    }

    override suspend fun open(
            context: Context,
            flutterAssets: FlutterPlugin.FlutterAssets,
            assetAudioPath: String?,
            audioType: String,
            networkHeaders: Map<*, *>?,
            assetAudioPackage: String?,
            drmConfiguration: Map<*, *>?
    ): DurationMS = withContext(Dispatchers.IO) {
        suspendCoroutine<DurationMS> { continuation ->
            var onThisMediaReady = false

            this@PlayerImplemMediaPlayer.mediaPlayer = MediaPlayer()

            when (audioType) {
                Player.AUDIO_TYPE_NETWORK, Player.AUDIO_TYPE_LIVESTREAM -> {
                    mediaPlayer?.reset()
                    networkHeaders?.toMapString()?.let {
                        mediaPlayer?.setDataSource(context, Uri.parse(assetAudioPath), it)
                    } ?: run {
                        //without headers
                        mediaPlayer?.setDataSource(assetAudioPath)
                    }
                }
                Player.AUDIO_TYPE_FILE -> {
                    mediaPlayer?.reset();
                    mediaPlayer?.setDataSource(context, Uri.parse("file:///$assetAudioPath"))
                }
                else -> { //asset
                    context.assets.openFd("flutter_assets/$assetAudioPath").also {
                        mediaPlayer?.reset();
                        mediaPlayer?.setDataSource(it.fileDescriptor, it.startOffset, it.declaredLength)
                    }.close()
                }
            }

            mediaPlayer?.setOnErrorListener { _, what, extra: Int ->
                // what
                //    MEDIA_ERROR_UNKNOWN
                //    MEDIA_ERROR_SERVER_DIED
                // extra
                //    MEDIA_ERROR_IO
                //    MEDIA_ERROR_MALFORMED
                //    MEDIA_ERROR_UNSUPPORTED
                //    MEDIA_ERROR_TIMED_OUT
                //    MEDIA_ERROR_SYSTEM - low-level system error.
                val error = if (what == MEDIA_ERROR_SERVER_DIED || extra == MEDIA_ERROR_IO || extra == MEDIA_ERROR_TIMED_OUT) {
                    AssetAudioPlayerThrowable.NetworkError(Throwable(extra.toString()))
                } else {
                    AssetAudioPlayerThrowable.PlayerError(Throwable(extra.toString()))
                }

                if (!onThisMediaReady) {
                    continuation.resumeWithException(error)
                } else {
                    onError(error)
                }

                true
            }
            mediaPlayer?.setOnCompletionListener {
                this@PlayerImplemMediaPlayer.onFinished.invoke()
            }

            try {
                mediaPlayer?.setOnPreparedListener {
                    //retrieve duration in seconds
                    val duration = mediaPlayer?.duration ?: 0
                    val totalDurationMs = duration.toLong()

                    continuation.resume(totalDurationMs)

                    onThisMediaReady = true
                }
                mediaPlayer?.prepare()
            } catch (error: Throwable) {
                if (!onThisMediaReady) {
                    continuation.resumeWithException(error)
                } else {
                    onError(AssetAudioPlayerThrowable.PlayerError(error))
                }
            }
        }
    }

    override fun release() {
        mediaPlayer?.release()
    }

    override fun seekTo(to: Long) {
        mediaPlayer?.seekTo(to.toInt())
    }

    override fun setVolume(volume: Float) {
        mediaPlayer?.setVolume(volume, volume)
    }

    override fun setPlaySpeed(playSpeed: Float) {
        //not possible
    }

    override fun setPitch(pitch: Float) {
        //not possible
    }

    override fun getSessionId(listener: (Int) -> Unit) {
        mediaPlayer?.audioSessionId?.takeIf { it != 0 }?.let(listener)
    }
}

fun Map<*, *>.toMapString(): Map<String, String> {
    val result = mutableMapOf<String, String>()
    this.forEach {
        it.key?.let { key ->
            it.value?.let { value ->
                result[key.toString()] = value.toString()
            }
        }
    }
    return result
}