package xyz.luan.audioplayers.player

import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import androidx.annotation.RequiresApi
import xyz.luan.audioplayers.AudioContextAndroid

class FocusManager(
    private val player: WrappedPlayer,
) {
    private var audioFocusChangeListener: AudioManager.OnAudioFocusChangeListener? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private val context: AudioContextAndroid
        get() = player.context

    private val audioManager: AudioManager
        get() = player.audioManager

    fun maybeRequestAudioFocus(andThen: () -> Unit) {
        if (context.audioFocus == null) {
            andThen()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            newRequestAudioFocus(andThen)
        } else {
            @Suppress("DEPRECATION")
            oldRequestAudioFocus(andThen)
        }
    }

    fun handleStop() {
        if (context.audioFocus != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                audioManager.abandonAudioFocus(audioFocusChangeListener)
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun newRequestAudioFocus(andThen: () -> Unit) {
        val audioFocus = context.audioFocus ?: return andThen()

        val audioFocusRequest = AudioFocusRequest.Builder(audioFocus)
            .setAudioAttributes(context.buildAttributes())
            .setOnAudioFocusChangeListener { handleFocusResult(it, andThen) }
            .build()
        this.audioFocusRequest = audioFocusRequest

        val result = audioManager.requestAudioFocus(audioFocusRequest)
        handleFocusResult(result, andThen)
    }

    @Deprecated("Use requestAudioFocus instead")
    private fun oldRequestAudioFocus(andThen: () -> Unit) {
        val audioFocus = context.audioFocus ?: return andThen()
        audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { handleFocusResult(it, andThen) }
        @Suppress("DEPRECATION")
        val result = audioManager.requestAudioFocus(
            audioFocusChangeListener,
            AudioManager.STREAM_MUSIC,
            audioFocus,
        )
        handleFocusResult(result, andThen)
    }

    private fun handleFocusResult(result: Int, andThen: () -> Unit) {
        if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            andThen()
        }
    }
}