package xyz.luan.audioplayers

import LogLevel
import android.content.Context
import android.os.Handler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.lang.ref.WeakReference

class AudioplayersPlugin : MethodCallHandler, FlutterPlugin {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private val mediaPlayers = mutableMapOf<String, Player>()
    private val handler = Handler()
    private var positionUpdates: Runnable? = null

    private var seekFinish = false

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "xyz.luan/audioplayers")
        context = binding.applicationContext
        seekFinish = false
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {}
    override fun onMethodCall(call: MethodCall, response: MethodChannel.Result) {
        try {
            handleMethodCall(call, response)
        } catch (e: Exception) {
            Logger.error("Unexpected error!", e)
            response.error("Unexpected error!", e.message, e)
        }
    }

    private fun handleMethodCall(call: MethodCall, response: MethodChannel.Result) {
        when (call.method) {
            "changeLogLevel" -> {
                val value = call.enumArgument<LogLevel>("value")
                    ?: throw error("value is required")
                Logger.logLevel = value
                response.success(1)
                return
            }
        }
        val playerId = call.argument<String>("playerId") ?: return
        val mode = call.argument<String>("mode")
        val player = getPlayer(playerId, mode)
        when (call.method) {
            "play" -> {
                configureAttributesAndVolume(call, player)

                val url = call.argument<String>("url")!!
                val isLocal = call.argument<Boolean>("isLocal") ?: false
                player.setUrl(url, isLocal)

                val position = call.argument<Int>("position")
                if (position != null && mode != "PlayerMode.LOW_LATENCY") {
                    player.seek(position)
                }
                player.play()
            }
            "playBytes" -> {
                configureAttributesAndVolume(call, player)

                val bytes = call.argument<ByteArray>("bytes") ?: throw error("bytes are required")
                player.setDataSource(ByteDataSource(bytes))

                val position = call.argument<Int>("position")
                if (position != null && mode != "PlayerMode.LOW_LATENCY") {
                    player.seek(position)
                }
                player.play()
            }
            "resume" -> player.play()
            "pause" -> player.pause()
            "stop" -> player.stop()
            "release" -> player.release()
            "seek" -> {
                val position = call.argument<Int>("position") ?: throw error("position is required")
                player.seek(position)
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume") ?: throw error("volume is required")
                player.setVolume(volume)
            }
            "setUrl" -> {
                val url = call.argument<String>("url") !!
                val isLocal = call.argument<Boolean>("isLocal") ?: false
                player.setUrl(url, isLocal)
            }
            "setPlaybackRate" -> {
                val rate = call.argument<Double>("playbackRate") ?: throw error("playbackRate is required")
                player.setRate(rate)
            }
            "getDuration" -> {
                response.success(player.getDuration() ?: 0)
                return
            }
            "getCurrentPosition" -> {
                response.success(player.getCurrentPosition() ?: 0)
                return
            }
            "setReleaseMode" -> {
                val releaseMode = call.enumArgument<ReleaseMode>("releaseMode")
                    ?: throw error("releaseMode is required")
                player.setReleaseMode(releaseMode)
            }
            "earpieceOrSpeakersToggle" -> {
                val playingRoute = call.argument<String>("playingRoute") ?: throw error("playingRoute is required")
                player.setPlayingRoute(playingRoute)
            }
            else -> {
                response.notImplemented()
                return
            }
        }
        response.success(1)
    }

    private fun configureAttributesAndVolume(
        call: MethodCall,
        player: Player
    ) {
        val respectSilence = call.argument<Boolean>("respectSilence") ?: false
        val stayAwake = call.argument<Boolean>("stayAwake") ?: false
        val duckAudio = call.argument<Boolean>("duckAudio") ?: false
        player.configAttributes(respectSilence, stayAwake, duckAudio)

        val volume = call.argument<Double>("volume") ?: 1.0
        player.setVolume(volume)
    }

    private fun getPlayer(playerId: String, mode: String?): Player {
        return mediaPlayers.getOrPut(playerId) {
            if (mode.equals("PlayerMode.MEDIA_PLAYER", ignoreCase = true)) {
                WrappedMediaPlayer(this, playerId)
            } else {
                WrappedSoundPool(playerId)
            }
        }
    }

    fun getApplicationContext(): Context {
        return context.applicationContext
    }

    fun handleIsPlaying() {
        startPositionUpdates()
    }

    fun handleDuration(player: Player) {
        channel.invokeMethod("audio.onDuration", buildArguments(player.playerId, player.getDuration() ?: 0))
    }

    fun handleCompletion(player: Player) {
        channel.invokeMethod("audio.onComplete", buildArguments(player.playerId, true))
    }

    fun handleError(player: Player, message: String) {
        channel.invokeMethod("audio.onError", buildArguments(player.playerId, message))
    }

    fun handleSeekComplete() {
        seekFinish = true
    }

    private fun startPositionUpdates() {
        if (positionUpdates != null) {
            return
        }
        positionUpdates = UpdateCallback(mediaPlayers, channel, handler, this).also {
            handler.post(it)
        }
    }

    private fun stopPositionUpdates() {
        positionUpdates = null
        handler.removeCallbacksAndMessages(null)
    }

    private class UpdateCallback(
            mediaPlayers: Map<String, Player>,
            channel: MethodChannel,
            handler: Handler,
            audioplayersPlugin: AudioplayersPlugin
    ) : Runnable {
        private val mediaPlayers = WeakReference(mediaPlayers)
        private val channel = WeakReference(channel)
        private val handler = WeakReference(handler)
        private val audioplayersPlugin = WeakReference(audioplayersPlugin)

        override fun run() {
            val mediaPlayers = mediaPlayers.get()
            val channel = channel.get()
            val handler = handler.get()
            val audioplayersPlugin = audioplayersPlugin.get()
            if (mediaPlayers == null || channel == null || handler == null || audioplayersPlugin == null) {
                audioplayersPlugin?.stopPositionUpdates()
                return
            }
            var nonePlaying = true
            for (player in mediaPlayers.values) {
                if (!player.isActuallyPlaying()) {
                    continue
                }
                try {
                    nonePlaying = false
                    val key = player.playerId
                    val duration = player.getDuration()
                    val time = player.getCurrentPosition()
                    channel.invokeMethod("audio.onDuration", buildArguments(key, duration ?: 0))
                    channel.invokeMethod("audio.onCurrentPosition", buildArguments(key, time ?: 0))
                    if (audioplayersPlugin.seekFinish) {
                        channel.invokeMethod("audio.onSeekComplete", buildArguments(player.playerId, true))
                        audioplayersPlugin.seekFinish = false
                    }
                } catch (e: UnsupportedOperationException) {
                }
            }
            if (nonePlaying) {
                audioplayersPlugin.stopPositionUpdates()
            } else {
                handler.postDelayed(this, 200)
            }
        }

    }

    companion object {
        private fun buildArguments(playerId: String, value: Any): Map<String, Any> {
            return mapOf(
                    "playerId" to playerId,
                    "value" to value
            )
        }

        private fun error(message: String): Exception {
            return IllegalArgumentException(message)
        }
    }
}

private inline fun <reified T: Enum<T>> MethodCall.enumArgument(name: String): T? {
    val enumName = argument<String>(name) ?: return null
    return enumValueOf<T>(enumName.split('.').last())
}
