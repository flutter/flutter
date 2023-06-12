package xyz.luan.audioplayers

import android.annotation.SuppressLint
import android.media.AudioAttributes
import android.media.AudioAttributes.*
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import androidx.annotation.RequiresApi

data class AudioContextAndroid(
    val isSpeakerphoneOn: Boolean,
    val stayAwake: Boolean,
    val contentType: Int,
    val usageType: Int,
    val audioFocus: Int?,
) {
    @SuppressLint("InlinedApi") // we are just using numerical constants
    constructor() : this(
        isSpeakerphoneOn = false,
        stayAwake = false,
        contentType = CONTENT_TYPE_MUSIC,
        usageType = USAGE_MEDIA,
        audioFocus = null,
    )

    fun setAttributesOnPlayer(player: MediaPlayer) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            player.setAudioAttributes(buildAttributes())
        } else {
            @Suppress("DEPRECATION")
            player.setAudioStreamType(getStreamType())
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun buildAttributes(): AudioAttributes {
        return Builder()
            .setUsage(usageType)
            .setContentType(contentType)
            .build()
    }

    @Deprecated("This is used for Android older than LOLLIPOP", replaceWith = ReplaceWith("buildAttributes"))
    private fun getStreamType(): Int {
        return when (usageType) {
            USAGE_VOICE_COMMUNICATION -> AudioManager.STREAM_VOICE_CALL
            USAGE_NOTIFICATION_RINGTONE -> AudioManager.STREAM_RING
            else -> AudioManager.STREAM_MUSIC
        }
    }
}