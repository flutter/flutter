package com.github.florent37.assets_audio_player.notification

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS
import android.support.v4.media.session.PlaybackStateCompat
import android.view.KeyEvent

class MediaButtonsReceiver(context: Context, private val onAction: (MediaButtonAction) -> Unit, private val onNotifSeek: (Long) -> Unit) {

    companion object {
        var instance: MediaButtonsReceiver? = null


        private var mediaSessionCompat : MediaSessionCompat? = null
        fun getMediaSessionCompat(context: Context) : MediaSessionCompat {
            if(mediaSessionCompat == null) {
                mediaSessionCompat = MediaSessionCompat(context, "MediaButtonsReceiver", null, null).apply {
                    setFlags(FLAG_HANDLES_MEDIA_BUTTONS)
                    isActive = true
                }
            }
            return mediaSessionCompat!!
        }
    }

    enum class MediaButtonAction {
        play, 
        pause, 
        playOrPause, 
        next, 
        prev, 
        stop
    }

    init {
        instance = this
    }

    private val mediaSessionCallback = object : MediaSessionCompat.Callback() {
        override fun onMediaButtonEvent(mediaButtonEvent: Intent?): Boolean {
            onIntentReceive(mediaButtonEvent)
            return super.onMediaButtonEvent(mediaButtonEvent)
        }

        override fun onSeekTo(pos: Long) {
            super.onSeekTo(pos)
            seekPlayerTo(pos)
        }
    }

    init {
        getMediaSessionCompat(context).setCallback(mediaSessionCallback)
    }

    private fun getAdjustedKeyCode(keyEvent: KeyEvent): Int {
        val keyCode = keyEvent.keyCode
        return if (keyCode == KeyEvent.KEYCODE_MEDIA_PLAY || keyCode == KeyEvent.KEYCODE_MEDIA_PAUSE) {
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
        } else keyCode
    }

    private fun mapAction(keyCode: Int): MediaButtonAction? {
        return when (keyCode) {
            KeyEvent.KEYCODE_MEDIA_PLAY -> MediaButtonAction.play
            KeyEvent.KEYCODE_MEDIA_PAUSE -> MediaButtonAction.pause
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> MediaButtonAction.playOrPause
            KeyEvent.KEYCODE_MEDIA_STOP -> MediaButtonAction.stop
            KeyEvent.KEYCODE_MEDIA_NEXT -> MediaButtonAction.next
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> MediaButtonAction.prev
            else -> null
        }
    }

    fun onIntentReceive(intent: Intent?) {
        if (intent == null) {
            return
        }
        if (intent.action != Intent.ACTION_MEDIA_BUTTON) {
            return
        }
        (intent.extras?.get(Intent.EXTRA_KEY_EVENT) as? KeyEvent)
                ?.takeIf { it.action == KeyEvent.ACTION_DOWN }
                ?.let { getAdjustedKeyCode(it) }
                ?.let { mapAction(it) }
                ?.let { action ->
                    handleMediaButton(action)
                }

    }

    private fun seekPlayerTo(pos: Long) {
        this.onNotifSeek(pos)
    }

    private fun handleMediaButton(action: MediaButtonAction) {
        this.onAction(action)
    }
}