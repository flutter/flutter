package com.github.florent37.assets_audio_player.notification

import java.io.Serializable

sealed class NotificationAction : Serializable {
    
    companion object {
        const val ACTION_STOP = "stop"
        const val ACTION_NEXT = "next"
        const val ACTION_PREV = "prev"
        const val ACTION_TOGGLE = "toggle"
        const val ACTION_SELECT = "select"
    }
    
    class Show(
            val isPlaying: Boolean,
            val audioMetas: AudioMetas,
            val playerId: String,
            val notificationSettings: NotificationSettings,
            val durationMs: Long
    ) : NotificationAction() {
        fun copyWith(isPlaying: Boolean? = null,
                     audioMetas: AudioMetas? = null,
                     playerId: String? = null,
                     notificationSettings: NotificationSettings? = null,
                     durationMs: Long? = null
        ) : Show{
            return Show(
                    isPlaying= isPlaying ?: this.isPlaying,
                    audioMetas = audioMetas ?: this.audioMetas,
                    playerId = playerId ?: this.playerId,
                    notificationSettings = notificationSettings ?: this.notificationSettings,
                    durationMs = durationMs ?: this.durationMs
            )
        }
    }

    class Hide() : NotificationAction()
}
