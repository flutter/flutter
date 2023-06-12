package com.github.florent37.assets_audio_player

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Handler
import android.os.Message
import com.github.florent37.assets_audio_player.headset.HeadsetStrategy
import com.github.florent37.assets_audio_player.notification.AudioMetas
import com.github.florent37.assets_audio_player.notification.NotificationManager
import com.github.florent37.assets_audio_player.notification.NotificationService
import com.github.florent37.assets_audio_player.notification.NotificationSettings
import com.github.florent37.assets_audio_player.playerimplem.*
import com.github.florent37.assets_audio_player.stopwhencall.AudioFocusStrategy
import com.github.florent37.assets_audio_player.stopwhencall.StopWhenCall
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlin.math.max
import kotlin.math.min

/**
 * Does not depend on Flutter, feel free to use it in all your projects
 */
class Player(
        val id: String,
        private val context: Context,
        private val stopWhenCall: StopWhenCall,
        private val notificationManager: NotificationManager,
        private val flutterAssets: FlutterPlugin.FlutterAssets
) {

    companion object {
        const val VOLUME_WHEN_REDUCED = 0.3

        const val AUDIO_TYPE_NETWORK = "network"
        const val AUDIO_TYPE_LIVESTREAM = "liveStream"
        const val AUDIO_TYPE_FILE = "file"
        const val AUDIO_TYPE_ASSET = "asset"
    }

    private val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    // To handle position updates.
    private val handler = Handler()

    private var mediaPlayer: PlayerImplem? = null

    //region outputs
    var onVolumeChanged: ((Double) -> Unit)? = null
    var onPlaySpeedChanged: ((Double) -> Unit)? = null
    var onPitchChanged: ((Double) -> Unit)? = null
    var onForwardRewind: ((Double) -> Unit)? = null
    var onReadyToPlay: ((DurationMS) -> Unit)? = null
    var onSessionIdFound: ((Int) -> Unit)? = null
    var onPositionMSChanged: ((Long) -> Unit)? = null
    var onFinished: (() -> Unit)? = null
    var onPlaying: ((Boolean) -> Unit)? = null
    var onBuffering: ((Boolean) -> Unit)? = null
    var onError: ((AssetAudioPlayerThrowable) -> Unit)? = null
    var onNext: (() -> Unit)? = null
    var onPrev: (() -> Unit)? = null
    var onStop: (() -> Unit)? = null
    var onNotificationPlayOrPause: (() -> Unit)? = null
    var onNotificationStop: (() -> Unit)? = null
    //endregion

    private var respectSilentMode: Boolean = false
    private var headsetStrategy: HeadsetStrategy = HeadsetStrategy.none
    private var audioFocusStrategy: AudioFocusStrategy = AudioFocusStrategy.None
    private var volume: Double = 1.0
    private var playSpeed: Double = 1.0
    private var pitch: Double = 1.0

    private var isEnabledToPlayPause: Boolean = true
    private var isEnabledToChangeVolume: Boolean = true

    val isPlaying: Boolean
        get() = mediaPlayer != null && mediaPlayer!!.isPlaying

    private var lastRingerMode: Int? = null //see https://developer.android.com/reference/android/media/AudioManager.html?hl=fr#getRingerMode()

    private var displayNotification = false

    private var _playingPath : String? = null
    private var _durationMs : DurationMS = 0
    private var _positionMs : DurationMS = 0
    private var _lastOpenedPath : String? = null
    private var audioMetas: AudioMetas? = null
    private var notificationSettings: NotificationSettings? = null

    private var _lastPositionMs: Long? = null
    private val updatePosition = object : Runnable {
        override fun run() {
            mediaPlayer?.let { mediaPlayer ->
                try {
                    if (!mediaPlayer.isPlaying) {
                        handler.removeCallbacks(this)
                    }

                    val positionMs : Long = mediaPlayer.currentPositionMs

                    if(_lastPositionMs != positionMs) {
                        // Send position (milliseconds) to the application.
                        onPositionMSChanged?.invoke(positionMs)
                        _lastPositionMs = positionMs
                    }

                    if (respectSilentMode) {
                        val ringerMode = am.ringerMode
                        if (lastRingerMode != ringerMode) { //if changed
                            lastRingerMode = ringerMode
                            setVolume(volume) //re-apply volume if changed
                        }
                    }

                    _positionMs = if(_durationMs != 0L) {
                        min(positionMs, _durationMs)
                    } else {
                        positionMs
                    }
                    updateNotifPosition()

                    // Update every 300ms.
                    handler.postDelayed(this, 300)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    fun next() {
        this.onNext?.invoke()
    }

    fun prev() {
        this.onPrev?.invoke()
    }

    fun onAudioUpdated(path: String, audioMetas: AudioMetas) {
        if(_playingPath == path || (_playingPath == null && _lastOpenedPath == path)){
            this.audioMetas = audioMetas
            updateNotif()
        }
    }

    fun open(assetAudioPath: String?,
             assetAudioPackage: String?,
             audioType: String,
             autoStart: Boolean,
             volume: Double,
             seek: Int?,
             respectSilentMode: Boolean,
             displayNotification: Boolean,
             notificationSettings: NotificationSettings,
             audioMetas: AudioMetas,
             playSpeed: Double,
             pitch: Double,
             headsetStrategy: HeadsetStrategy,
             audioFocusStrategy: AudioFocusStrategy,
             networkHeaders: Map<*, *>?,
             result: MethodChannel.Result,
             context: Context,
             drmConfiguration: Map<*, *>?
    ) {
        try {
            stop(pingListener = false)
        } catch (t: Throwable){
            print(t)
        }

        this.displayNotification = displayNotification
        this.audioMetas = audioMetas
        this.notificationSettings = notificationSettings
        this.respectSilentMode = respectSilentMode
        this.headsetStrategy = headsetStrategy
        this.audioFocusStrategy = audioFocusStrategy

        _lastOpenedPath = assetAudioPath
      
        GlobalScope.launch(Dispatchers.Main) {
            try {
                val playerWithDuration = PlayerFinder.findWorkingPlayer(
                        PlayerFinderConfiguration(
                        assetAudioPath = assetAudioPath,
                        flutterAssets = flutterAssets,
                        assetAudioPackage = assetAudioPackage,
                        audioType = audioType,
                        networkHeaders = networkHeaders,
                        context = context,
                        onFinished = {
                            stopWhenCall.stop()
                            onFinished?.invoke()
                        },
                        onPlaying = onPlaying,
                        onBuffering = onBuffering,
                        onError= onError,
                        drmConfiguration = drmConfiguration
                        )
                )

                val durationMs = playerWithDuration.duration
                mediaPlayer = playerWithDuration.player

                //here one open succeed
                onReadyToPlay?.invoke(durationMs)
                mediaPlayer?.getSessionId(listener = {
                    onSessionIdFound?.invoke(it)
                })

                _playingPath = assetAudioPath
                _durationMs = durationMs

                setVolume(volume)
                setPlaySpeed(playSpeed)
                setPitch(pitch)

                seek?.let {
                    this@Player.seek(milliseconds = seek * 1L)
                }

                if (autoStart) {
                    play() //display notif inside
                } else {
                    updateNotif() //if pause, we need to display the notif
                }
                result.success(null)
            } catch (error: Throwable) {
                error.printStackTrace()
                if(error is PlayerFinder.NoPlayerFoundException && error.why != null){
                    result.error("OPEN", error.why.message, mapOf(
                            "type" to error.why.type,
                            "message" to error.why.message
                    ))
                } else {
                    result.error("OPEN", error.message, null)
                }
            }
        }
    }

    fun stop(pingListener: Boolean = true, removeNotification: Boolean = true) {
        mediaPlayer?.apply {
            // Reset duration and position.
            // handler.removeCallbacks(updatePosition);
            // channel.invokeMethod("player.duration", 0);
            onPositionMSChanged?.invoke(0)

            mediaPlayer?.stop()
            mediaPlayer?.release()
            onPlaying?.invoke(false)
            handler.removeCallbacks(updatePosition)
        }
        if (forwardHandler != null) {
            forwardHandler!!.stop()
            forwardHandler = null
        }
        mediaPlayer = null
        onForwardRewind?.invoke(0.0)
        if (pingListener) { //action from user
            onStop?.invoke()
            updateNotif(removeNotificationOnStop= removeNotification)
        }
    }


    fun toggle() {
        if (isPlaying) {
            pause()
        } else {
            play()
        }
    }

    private fun stopForward() {
        forwardHandler?.takeIf { h -> h.isActive }?.let { h ->
            h.stop()
            setPlaySpeed(this.playSpeed)
        }
        onForwardRewind?.invoke(0.0)
    }

    private fun updateNotifPosition() {
        this.audioMetas
                ?.takeIf { this.displayNotification }
                ?.takeIf { notificationSettings?.seekBarEnabled ?: true }
                ?.let { audioMetas ->
                    NotificationService.updatePosition(
                            context = context,
                            isPlaying = isPlaying,
                            speed = this.playSpeed.toFloat(),
                            currentPositionMs = _positionMs
                    )
        }
    }

    fun forceNotificationForGroup(
            audioMetas: AudioMetas,
            isPlaying: Boolean,
            display: Boolean,
            notificationSettings: NotificationSettings
    ) {
        notificationManager.showNotification(
                playerId = id,
                audioMetas = audioMetas,
                isPlaying = isPlaying,
                notificationSettings = notificationSettings,
                stop = !display,
                durationMs = 0
        )
    }

    fun showNotification(show: Boolean){
        val oldValue = this.displayNotification
        this.displayNotification = show
        if(oldValue) { //if was showing a notification
            notificationManager.stopNotification()
            //hide it
        } else {
            updateNotif()
        }
    }
    
    private fun updateNotif(removeNotificationOnStop: Boolean = true) {
        this.audioMetas?.takeIf { this.displayNotification }?.let { audioMetas ->
            this.notificationSettings?.let { notificationSettings ->
                updateNotifPosition()
                notificationManager.showNotification(
                        playerId = id,
                        audioMetas = audioMetas,
                        isPlaying = this.isPlaying,
                        notificationSettings = notificationSettings,
                        stop = removeNotificationOnStop && mediaPlayer == null,
                        durationMs = this._durationMs
                )
            }
        }
    }

    fun play() {
        if(audioFocusStrategy is AudioFocusStrategy.None){
            this.isEnabledToPlayPause = true //this one must be called before play/pause()
            this.isEnabledToChangeVolume = true //this one must be called before play/pause()
            playerPlay()
        } else {
            val audioState = this.stopWhenCall.requestAudioFocus(audioFocusStrategy)
            if (audioState == StopWhenCall.AudioState.AUTHORIZED_TO_PLAY) {
                this.isEnabledToPlayPause = true //this one must be called before play/pause()
                this.isEnabledToChangeVolume = true //this one must be called before play/pause()
                playerPlay()
            } //else will wait until focus is enabled
        }
    }

    private fun playerPlay() { //the play
        if (isEnabledToPlayPause) { //can be disabled while recieving phone call
            mediaPlayer?.let { player ->
                stopForward()
                player.play()
                _lastPositionMs = null
                handler.post(updatePosition)
                onPlaying?.invoke(true)
                updateNotif()
            }
        } else {
            this.stopWhenCall.requestAudioFocus(audioFocusStrategy)
        }
    }

    fun pause() {
        if (isEnabledToPlayPause) {
            mediaPlayer?.let {
                it.pause()
                handler.removeCallbacks(updatePosition)

                stopForward()
                onPlaying?.invoke(false)
                updateNotif()
            }
        }
    }

    fun loopSingleAudio(loop: Boolean){
        mediaPlayer?.loopSingleAudio = loop
    }

    fun seek(milliseconds: Long) {
        mediaPlayer?.apply {
            val to = max(milliseconds, 0L)
            seekTo(to)
            onPositionMSChanged?.invoke(currentPositionMs)
        }
    }

    fun seekBy(milliseconds: Long) {
        mediaPlayer?.let {
            val to = it.currentPositionMs + milliseconds;
            seek(to)
        }
    }

    fun setVolume(volume: Double) {
        if (isEnabledToChangeVolume) {
            this.volume = volume
            mediaPlayer?.let {
                var v = volume
                if (this.respectSilentMode) {
                    v = when (am.ringerMode) {
                        AudioManager.RINGER_MODE_SILENT, AudioManager.RINGER_MODE_VIBRATE -> 0.toDouble()
                        else -> volume //AudioManager.RINGER_MODE_NORMAL
                    }
                }

                it.setVolume(v.toFloat())

                onVolumeChanged?.invoke(this.volume) //only notify the setted volume, not the silent mode one
            }
        }
    }

    private var forwardHandler: ForwardHandler? = null;

    fun setPlaySpeed(playSpeed: Double) {
        if (playSpeed >= 0) { //android only take positive play speed
            if (forwardHandler != null) {
                forwardHandler!!.stop()
                forwardHandler = null
            }
            this.playSpeed = playSpeed
            mediaPlayer?.let {
                it.setPlaySpeed(playSpeed.toFloat())
                onPlaySpeedChanged?.invoke(this.playSpeed)
            }
        }
    }

    fun setPitch(pitch: Double) {
        if (pitch >= 0) { //android only take positive pitch
            if (forwardHandler != null) {
                forwardHandler!!.stop()
                forwardHandler = null
            }
            this.pitch = pitch
            mediaPlayer?.let {
                it.setPitch(pitch.toFloat())
                onPitchChanged?.invoke(this.pitch)
            }
        }
    }

    fun forwardRewind(speed: Double) {
        if (forwardHandler == null) {
            forwardHandler = ForwardHandler()
        }

        mediaPlayer?.pause()
        //handler.removeCallbacks(updatePosition)
        //onPlaying?.invoke(false)

        onForwardRewind?.invoke(speed)
        forwardHandler!!.start(this, speed)
    }

    private var volumeBeforePhoneStateChanged: Double? = null
    private var wasPlayingBeforeEnablePlayChange: Boolean? = null
    fun updateEnableToPlay(audioState: StopWhenCall.AudioState) {
        (audioFocusStrategy as? AudioFocusStrategy.Request)?.let { audioFocusStrategy ->
            when (audioState) {
                StopWhenCall.AudioState.AUTHORIZED_TO_PLAY -> {
                    this.isEnabledToPlayPause = true //this one must be called before play/pause()
                    this.isEnabledToChangeVolume = true //this one must be called before play/pause()
                    if(audioFocusStrategy.resumeAfterInterruption) {
                        wasPlayingBeforeEnablePlayChange?.let {
                            //phone call ended
                            if (it) {
                                playerPlay()
                            } else {
                                pause()
                            }
                        }
                    }
                    volumeBeforePhoneStateChanged?.let {
                        setVolume(it)
                    }
                    wasPlayingBeforeEnablePlayChange = null
                    volumeBeforePhoneStateChanged = null
                }
                StopWhenCall.AudioState.REDUCE_VOLUME -> {
                    volumeBeforePhoneStateChanged = this.volume
                    setVolume(VOLUME_WHEN_REDUCED)
                    this.isEnabledToChangeVolume = false //this one must be called after setVolume()
                }
                StopWhenCall.AudioState.FORBIDDEN -> {
                    wasPlayingBeforeEnablePlayChange = this.isPlaying
                    pause()
                    this.isEnabledToPlayPause = false //this one must be called after pause()
                }
            }
        }
    }

    fun askPlayOrPause() {
        this.onNotificationPlayOrPause?.invoke()
    }

    fun askStop() {
        this.onNotificationStop?.invoke()
    }

    fun onHeadsetPlugged(plugged: Boolean) {
        if(plugged){
            when(this.headsetStrategy){
                HeadsetStrategy.pauseOnUnplug -> { /* do nothing */}
                HeadsetStrategy.pauseOnUnplugPlayOnPlug -> {
                    if(!isPlaying) {
                        this.onNotificationPlayOrPause?.invoke()
                    }
                }
                else -> { /* do nothing */ }
            }
        } else {
            when(this.headsetStrategy){
                HeadsetStrategy.pauseOnUnplug, HeadsetStrategy.pauseOnUnplugPlayOnPlug  -> {
                    if(isPlaying) {
                        this.onNotificationPlayOrPause?.invoke()
                    }
                }
                else -> { /* do nothing */ }
            }
        }
    }
}

class ForwardHandler : Handler() {

    companion object {
        const val MESSAGE_FORWARD = 1
        const val DELAY = 300L
    }

    private var player: com.github.florent37.assets_audio_player.Player? = null
    private var speed: Double = 1.0

    val isActive: Boolean
        get() = hasMessages(MESSAGE_FORWARD)

    fun start(player: com.github.florent37.assets_audio_player.Player, speed: Double) {
        this.player = player
        this.speed = speed
        removeMessages(MESSAGE_FORWARD)
        sendEmptyMessage(MESSAGE_FORWARD)
    }

    fun stop() {
        removeMessages(MESSAGE_FORWARD)
        this.player = null
    }

    override fun handleMessage(msg: Message) {
        super.handleMessage(msg)
        if (msg.what == MESSAGE_FORWARD) {
            this.player?.let {
                it.seekBy((DELAY * speed).toLong())
                sendEmptyMessageDelayed(MESSAGE_FORWARD, DELAY)
            }
        }
    }
}