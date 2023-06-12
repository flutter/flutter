package com.github.florent37.assets_audio_player.notification

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.media.session.MediaButtonReceiver
import androidx.annotation.Keep;

@Keep
class CustomMediaButtonReceiver : MediaButtonReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        try {
            super.onReceive(context, intent)
        } catch (e: Exception) {
            Log.e(javaClass.name, e.message ?: "unknown error")
        }
    }
}
