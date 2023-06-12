package xyz.luan.audioplayers


import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import xyz.luan.audioplayers.player.WrappedPlayer
import xyz.luan.audioplayers.source.BytesSource
import xyz.luan.audioplayers.source.UrlSource
import java.lang.ref.WeakReference
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentMap

typealias FlutterHandler = (call: MethodCall, response: MethodChannel.Result) -> Unit

class AudioplayersPlugin : FlutterPlugin, IUpdateCallback {
    private val mainScope = CoroutineScope(Dispatchers.Main)

    private lateinit var channel: MethodChannel
    private lateinit var globalChannel: MethodChannel
    private lateinit var context: Context

    private val players = ConcurrentHashMap<String, WrappedPlayer>()
    private val handler = Handler(Looper.getMainLooper())
    private var updateRunnable: Runnable? = null

    private var defaultAudioContext = AudioContextAndroid()

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "xyz.luan/audioplayers")
        channel.setMethodCallHandler { call, response -> safeCall(call, response, ::handler) }
        globalChannel = MethodChannel(binding.binaryMessenger, "xyz.luan/audioplayers.global")
        globalChannel.setMethodCallHandler { call, response -> safeCall(call, response, ::globalHandler) }
        updateRunnable = UpdateRunnable(players, channel, handler, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        stopUpdates()
        updateRunnable = null
        players.values.forEach { it.release() }
        players.clear()
        mainScope.cancel()
    }

    private fun safeCall(
        call: MethodCall,
        response: MethodChannel.Result,
        handler: FlutterHandler,
    ) {
        mainScope.launch(Dispatchers.IO) {
            try {
                handler(call, response)
            } catch (e: Exception) {
                Logger.error("Unexpected error!", e)
                response.error("Unexpected error!", e.message, e)
            }
        }
    }

    private fun globalHandler(call: MethodCall, response: MethodChannel.Result) {
        when (call.method) {
            "changeLogLevel" -> {
                val value = call.enumArgument<LogLevel>("value") ?: error("value is required")
                Logger.logLevel = value
            }
            "setGlobalAudioContext" -> {
                defaultAudioContext = call.audioContext()
            }
        }

        response.success(1)
    }

    private fun handler(call: MethodCall, response: MethodChannel.Result) {
        val playerId = call.argument<String>("playerId") ?: return
        val player = getPlayer(playerId)
        when (call.method) {
            "setSourceUrl" -> {
                val url = call.argument<String>("url") ?: error("url is required")
                val isLocal = call.argument<Boolean>("isLocal") ?: false
                player.source = UrlSource(url, isLocal)
            }
            "setSourceBytes" -> {
                val bytes = call.argument<ByteArray>("bytes") ?: error("bytes are required")
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    error("Operation not supported on Android <= M")
                }
                player.source = BytesSource(bytes)
            }
            "resume" -> player.play()
            "pause" -> player.pause()
            "stop" -> player.stop()
            "release" -> player.release()
            "seek" -> {
                val position = call.argument<Int>("position") ?: error("position is required")
                player.seek(position)
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume") ?: error("volume is required")
                player.volume = volume.toFloat()
            }
            "setBalance" -> {
                Logger.error("setBalance is not currently implemented on Android")
                response.notImplemented()
                return
            }
            "setPlaybackRate" -> {
                val rate = call.argument<Double>("playbackRate") ?: error("playbackRate is required")
                player.rate = rate.toFloat()
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
                    ?: error("releaseMode is required")
                player.releaseMode = releaseMode
            }
            "setPlayerMode" -> {
                val playerMode = call.enumArgument<PlayerMode>("playerMode")
                    ?: error("playerMode is required")
                player.playerMode = playerMode
            }
            "setAudioContext" -> {
                val audioContext = call.audioContext()
                player.updateAudioContext(audioContext)
            }
            else -> {
                response.notImplemented()
                return
            }
        }
        response.success(1)
    }

    private fun getPlayer(playerId: String): WrappedPlayer {
        return players.getOrPut(playerId) {
            WrappedPlayer(this, playerId, defaultAudioContext.copy())
        }
    }

    fun getApplicationContext(): Context {
        return context.applicationContext
    }

    fun handleIsPlaying() {
        startUpdates()
    }

    fun handleDuration(player: WrappedPlayer) {
        channel.invokeMethod("audio.onDuration", buildArguments(player.playerId, player.getDuration() ?: 0))
    }

    fun handleComplete(player: WrappedPlayer) {
        channel.invokeMethod("audio.onComplete", buildArguments(player.playerId))
    }

    fun handleError(player: WrappedPlayer, message: String) {
        channel.invokeMethod("audio.onError", buildArguments(player.playerId, message))
    }

    fun handleSeekComplete(player: WrappedPlayer) {
        channel.invokeMethod("audio.onSeekComplete", buildArguments(player.playerId))
        channel.invokeMethod(
            "audio.onCurrentPosition",
            buildArguments(player.playerId, player.getCurrentPosition() ?: 0)
        )
    }

    override fun startUpdates() {
        updateRunnable?.let { handler.post(it) }
    }

    override fun stopUpdates() {
        handler.removeCallbacksAndMessages(null)
    }

    private class UpdateRunnable(
        mediaPlayers: ConcurrentMap<String, WrappedPlayer>,
        channel: MethodChannel,
        handler: Handler,
        updateCallback: IUpdateCallback,
    ) : Runnable {
        private val mediaPlayers = WeakReference(mediaPlayers)
        private val channel = WeakReference(channel)
        private val handler = WeakReference(handler)
        private val updateCallback = WeakReference(updateCallback)

        override fun run() {
            val mediaPlayers = mediaPlayers.get()
            val channel = channel.get()
            val handler = handler.get()
            val updateCallback = updateCallback.get()
            if (mediaPlayers == null || channel == null || handler == null || updateCallback == null) {
                updateCallback?.stopUpdates()
                return
            }
            var isAnyPlaying = false
            for (player in mediaPlayers.values) {
                if (!player.isActuallyPlaying()) {
                    continue
                }
                isAnyPlaying = true
                val key = player.playerId
                val duration = player.getDuration()
                val time = player.getCurrentPosition()
                channel.invokeMethod("audio.onDuration", buildArguments(key, duration ?: 0))
                channel.invokeMethod("audio.onCurrentPosition", buildArguments(key, time ?: 0))
            }
            if (isAnyPlaying) {
                handler.postDelayed(this, 200)
            } else {
                updateCallback.stopUpdates()
            }
        }

    }

    companion object {
        private fun buildArguments(playerId: String, value: Any? = null): Map<String, Any> {
            return listOfNotNull(
                "playerId" to playerId,
                value?.let { "value" to it },
            ).toMap()
        }
    }
}

private interface IUpdateCallback {
    fun stopUpdates()
    fun startUpdates()
}

private inline fun <reified T : Enum<T>> MethodCall.enumArgument(name: String): T? {
    val enumName = argument<String>(name) ?: return null
    return enumValueOf<T>(enumName.split('.').last().toConstantCase())
}

fun String.toConstantCase(): String {
    return replace(Regex("(.)(\\p{Upper})"), "$1_$2")
        .replace(Regex("(.) (.)"), "$1_$2")
        .uppercase()
}

private fun MethodCall.audioContext(): AudioContextAndroid {
    return AudioContextAndroid(
        isSpeakerphoneOn = argument<Boolean>("isSpeakerphoneOn") ?: error("isSpeakerphoneOn is required"),
        stayAwake = argument<Boolean>("stayAwake") ?: error("stayAwake is required"),
        contentType = argument<Int>("contentType") ?: error("contentType is required"),
        usageType = argument<Int>("usageType") ?: error("usageType is required"),
        audioFocus = argument<Int>("audioFocus"),
    )
}
