package com.github.florent37.assets_audio_player.playerimplem

import android.content.Context
import android.net.Uri
import android.os.Build
import android.util.Log
import com.github.florent37.assets_audio_player.AssetAudioPlayerThrowable
import com.github.florent37.assets_audio_player.AssetsAudioPlayerPlugin
import com.github.florent37.assets_audio_player.Player
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.C.AUDIO_SESSION_ID_UNSET
import com.google.android.exoplayer2.Player.REPEAT_MODE_ALL
import com.google.android.exoplayer2.Player.REPEAT_MODE_OFF
import com.google.android.exoplayer2.drm.*
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory
import com.google.android.exoplayer2.extractor.ts.AdtsExtractor
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.dash.DashMediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource
import com.google.android.exoplayer2.upstream.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class IncompatibleException(val audioType: String, val type: PlayerImplemTesterExoPlayer.Type) : Throwable()

class PlayerImplemTesterExoPlayer(private val type: Type) : PlayerImplemTester {


    enum class Type {
        Default,
        HLS,
        DASH,
        SmoothStreaming
    }


    override suspend fun open(configuration: PlayerFinderConfiguration): PlayerFinder.PlayerWithDuration {
        if (AssetsAudioPlayerPlugin.displayLogs) {
            Log.d("PlayerImplem", "trying to open with exoplayer($type)")
        }
        //some type are only for web
        if (configuration.audioType != Player.AUDIO_TYPE_LIVESTREAM && configuration.audioType != Player.AUDIO_TYPE_LIVESTREAM) {
            if (type == Type.HLS || type == Type.DASH || type == Type.SmoothStreaming) {
                throw IncompatibleException(configuration.audioType, type)
            }
        }

        val mediaPlayer = PlayerImplemExoPlayer(
                onFinished = {
                    configuration.onFinished?.invoke()
                    //stop(pingListener = false)
                },
                onBuffering = {
                    configuration.onBuffering?.invoke(it)
                },
                onError = { t ->
                    configuration.onError?.invoke(t)
                },
                type = this.type
        )

        try {
            val durationMS = mediaPlayer.open(
                    context = configuration.context,
                    assetAudioPath = configuration.assetAudioPath,
                    audioType = configuration.audioType,
                    assetAudioPackage = configuration.assetAudioPackage,
                    networkHeaders = configuration.networkHeaders,
                    flutterAssets = configuration.flutterAssets,
                    drmConfiguration = configuration.drmConfiguration
            )
            return PlayerFinder.PlayerWithDuration(
                    player = mediaPlayer,
                    duration = durationMS
            )
        } catch (t: Throwable) {
            if (AssetsAudioPlayerPlugin.displayLogs) {
                Log.d("PlayerImplem", "failed to open with exoplayer($type)")
            }
            mediaPlayer.release()
            throw  t
        }
    }
}

class PlayerImplemExoPlayer(
        onFinished: (() -> Unit),
        onBuffering: ((Boolean) -> Unit),
        onError: ((AssetAudioPlayerThrowable) -> Unit),
        val type: PlayerImplemTesterExoPlayer.Type
) : PlayerImplem(
        onFinished = onFinished,
        onBuffering = onBuffering,
        onError = onError
) {

    private var mediaPlayer: ExoPlayer? = null

    override var loopSingleAudio: Boolean
        get() = mediaPlayer?.repeatMode == REPEAT_MODE_ALL
        set(value) {
            mediaPlayer?.repeatMode = if (value) REPEAT_MODE_ALL else REPEAT_MODE_OFF
        }

    override val isPlaying: Boolean
        get() = mediaPlayer?.isPlaying ?: false
    override val currentPositionMs: Long
        get() = mediaPlayer?.currentPosition ?: 0

    override fun stop() {
        mediaPlayer?.stop()
    }

    override fun play() {
        mediaPlayer?.playWhenReady = true
    }

    override fun pause() {
        mediaPlayer?.playWhenReady = false
    }

    private fun getDataSource(context: Context,
                              flutterAssets: FlutterPlugin.FlutterAssets,
                              assetAudioPath: String?,
                              audioType: String,
                              networkHeaders: Map<*, *>?,
                              assetAudioPackage: String?,
                              drmConfiguration: Map<*, *>?
    ): MediaSource {
        try {
            mediaPlayer?.stop()
            when (audioType) {
                Player.AUDIO_TYPE_NETWORK, Player.AUDIO_TYPE_LIVESTREAM -> {
                    val uri = Uri.parse(assetAudioPath)
                    val mediaItem: MediaItem = MediaItem.fromUri(uri)
                    val userAgent = "assets_audio_player"

                    val factory = DataSource.Factory {
                        val allowCrossProtocol = true
                        val dataSource = DefaultHttpDataSource.Factory().setUserAgent(userAgent).setAllowCrossProtocolRedirects(allowCrossProtocol).createDataSource()
                        networkHeaders?.forEach {
                            it.key?.let { key ->
                                it.value?.let { value ->
                                    dataSource.setRequestProperty(key.toString(), value.toString())
                                }
                            }
                        }
                        dataSource
                    }

                    return when (type) {
                        PlayerImplemTesterExoPlayer.Type.HLS -> HlsMediaSource.Factory(factory).setAllowChunklessPreparation(true)
                        PlayerImplemTesterExoPlayer.Type.DASH -> DashMediaSource.Factory(factory)
                        PlayerImplemTesterExoPlayer.Type.SmoothStreaming -> SsMediaSource.Factory(factory)
                        else -> ProgressiveMediaSource.Factory(factory, DefaultExtractorsFactory().setAdtsExtractorFlags(AdtsExtractor.FLAG_ENABLE_CONSTANT_BITRATE_SEEKING))
                    }.createMediaSource(mediaItem)
                }
                Player.AUDIO_TYPE_FILE -> {
                    val uri = Uri.parse(assetAudioPath)
                    var mediaItem: MediaItem = MediaItem.fromUri(uri)
                    val factory = ProgressiveMediaSource
                            .Factory(DefaultDataSource.Factory(context), DefaultExtractorsFactory())


                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                        val key = drmConfiguration?.get("clearKey")?.toString()

                        if (key != null) {
                            val mediaItemDrmConfiguration: MediaItem.DrmConfiguration = MediaItem.DrmConfiguration.Builder(C.CLEARKEY_UUID).setKeySetId(key.toByteArray()).build()
                            mediaItem = mediaItem.buildUpon().setDrmConfiguration(mediaItemDrmConfiguration).build()
                            factory.setDrmSessionManagerProvider(DefaultDrmSessionManagerProvider())
                        }

                    }

                    return factory.createMediaSource(mediaItem)
                }
                else -> { //asset$
                    val p = assetAudioPath!!.replace(" ", "%20")
                    val path = if (assetAudioPackage.isNullOrBlank()) {
                        flutterAssets.getAssetFilePathByName(p)
                    } else {
                        flutterAssets.getAssetFilePathByName(p, assetAudioPackage)
                    }
                    val assetDataSource = AssetDataSource(context)
                    assetDataSource.open(DataSpec(Uri.fromFile(File(path))))

                    val factory = DataSource.Factory { assetDataSource }
                    return ProgressiveMediaSource
                            .Factory(factory, DefaultExtractorsFactory())
                            .createMediaSource(MediaItem.fromUri(assetDataSource.uri!!))
                }
            }
        } catch (e: Exception) {
            throw e
        }
    }

    private fun ExoPlayer.Builder.incrementBufferSize(audioType: String): ExoPlayer.Builder {
        if (audioType == Player.AUDIO_TYPE_NETWORK || audioType == Player.AUDIO_TYPE_LIVESTREAM) {
            /* Instantiate a DefaultLoadControl.Builder. */
            val loadControlBuilder = DefaultLoadControl.Builder()

/*How many milliseconds of media data to buffer at any time. */
            val loadControlBufferMs = DefaultLoadControl.DEFAULT_MAX_BUFFER_MS /* This is 50000 milliseconds in ExoPlayer 2.9.6 */

/* Configure the DefaultLoadControl to use the same value for */
            loadControlBuilder.setBufferDurationsMs(
                    loadControlBufferMs,
                    loadControlBufferMs,
                    DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_MS,
                    DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS)

            return this.setLoadControl(loadControlBuilder.build())
        }
        return this
    }

    fun mapError(t: Throwable): AssetAudioPlayerThrowable {
        return when {
            t is ExoPlaybackException -> {
                (t.cause as? HttpDataSource.InvalidResponseCodeException)?.takeIf { it.responseCode >= 400 }?.let {
                    AssetAudioPlayerThrowable.UnreachableException(t)
                } ?: let {
                    AssetAudioPlayerThrowable.NetworkError(t)
                }
            }
            t.message?.contains("unable to connect", true) == true -> {
                AssetAudioPlayerThrowable.NetworkError(t)
            }
            else -> {
                AssetAudioPlayerThrowable.PlayerError(t)
            }
        }
    }

    override suspend fun open(
            context: Context,
            flutterAssets: FlutterPlugin.FlutterAssets,
            assetAudioPath: String?,
            audioType: String,
            networkHeaders: Map<*, *>?,
            assetAudioPackage: String?,
            drmConfiguration: Map<*, *>?
    ) = suspendCoroutine<DurationMS> { continuation ->
        var onThisMediaReady = false

        try {
            mediaPlayer = ExoPlayer.Builder(context)
                    .incrementBufferSize(audioType)
                    .build()

            val mediaSource = getDataSource(
                    context = context,
                    flutterAssets = flutterAssets,
                    assetAudioPath = assetAudioPath,
                    audioType = audioType,
                    networkHeaders = networkHeaders,
                    assetAudioPackage = assetAudioPackage,
                    drmConfiguration = drmConfiguration
            )

            var lastState: Int? = null

            this.mediaPlayer?.addListener(object : com.google.android.exoplayer2.Player.Listener {

                override fun onPlayerError(error: PlaybackException) {
                    val errorMapped = mapError(error)
                    if (!onThisMediaReady) {
                        continuation.resumeWithException(errorMapped)
                    } else {
                        onError(errorMapped)
                    }
                }

                override fun onPlaybackStateChanged(playbackState: Int) {
                    if (lastState != playbackState) {
                        when (playbackState) {
                            ExoPlayer.STATE_ENDED -> {
                                pause()
                                onFinished.invoke()
                                onBuffering.invoke(false)
                            }
                            ExoPlayer.STATE_BUFFERING -> {
                                onBuffering.invoke(true)
                            }
                            ExoPlayer.STATE_READY -> {
                                onBuffering.invoke(false)
                                if (!onThisMediaReady) {
                                    onThisMediaReady = true
                                    //retrieve duration in seconds
                                    if (audioType == Player.AUDIO_TYPE_LIVESTREAM) {
                                        continuation.resume(0) //no duration for livestream
                                    } else {
                                        val duration = mediaPlayer?.duration ?: 0

                                        continuation.resume(duration)
                                    }
                                }
                            }
                            else -> {
                            }
                        }
                    }
                    lastState = playbackState
                }
            })

            mediaPlayer?.setMediaSource(mediaSource)
            mediaPlayer?.prepare()
        } catch (error: Throwable) {
            if (!onThisMediaReady) {
                continuation.resumeWithException(error)
            } else {
                onBuffering.invoke(false)
                onError(mapError(error))
            }
        }
    }

    override fun release() {
        mediaPlayer?.release()
    }

    override fun seekTo(to: Long) {
        mediaPlayer?.seekTo(to)
    }

    override fun setVolume(volume: Float) {
        mediaPlayer?.volume = volume
    }

    override fun setPlaySpeed(playSpeed: Float) {
        val params: PlaybackParameters? = mediaPlayer?.playbackParameters
        if (params != null) {
            mediaPlayer?.playbackParameters = PlaybackParameters(playSpeed, params.pitch)
        }
    }

    override fun setPitch(pitch: Float) {
        val params: PlaybackParameters? = mediaPlayer?.playbackParameters
        if (params != null) {
            mediaPlayer?.playbackParameters = PlaybackParameters(params.speed, pitch)
        }
    }

    override fun getSessionId(listener: (Int) -> Unit) {
        val id = mediaPlayer?.audioSessionId?.takeIf { it != AUDIO_SESSION_ID_UNSET }
        if (id != null) {
            listener(id)
        } else {
            val listener = object : com.google.android.exoplayer2.Player.Listener {
                override fun onAudioSessionIdChanged(audioSessionId: Int) {
                    listener(audioSessionId)
                    mediaPlayer?.removeListener(this)
                }
            }
            mediaPlayer?.addListener(listener)
        }
        //return
    }
}