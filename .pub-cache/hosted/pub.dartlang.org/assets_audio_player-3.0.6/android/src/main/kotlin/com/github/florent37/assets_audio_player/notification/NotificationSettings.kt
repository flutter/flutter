package com.github.florent37.assets_audio_player.notification

import java.io.Serializable

class NotificationSettings(
        val nextEnabled: Boolean,
        val playPauseEnabled: Boolean,
        val prevEnabled: Boolean,
        val seekBarEnabled: Boolean,

        //android only
        val stopEnabled: Boolean,
        val previousIcon: String?,
        val stopIcon: String?,
        val playIcon: String?,
        val nextIcon: String?,
        val pauseIcon: String?
) : Serializable {
    fun numberEnabled() : Int {
        var number = 0
        if(playPauseEnabled) number++
        if(prevEnabled) number++
        if(nextEnabled) number++
        if(stopEnabled) number++
        return number
    }
}

fun fetchNotificationSettings(from: Map<*, *>) : NotificationSettings {
    return NotificationSettings(
            nextEnabled= from["notif.settings.nextEnabled"] as? Boolean ?: true,
            stopEnabled= from["notif.settings.stopEnabled"] as? Boolean ?: true,
            playPauseEnabled = from["notif.settings.playPauseEnabled"] as? Boolean ?: true,
            prevEnabled = from["notif.settings.prevEnabled"] as? Boolean ?: true,
            seekBarEnabled = from["notif.settings.seekBarEnabled"] as? Boolean ?: true,
            previousIcon = from["notif.settings.previousIcon"] as? String,
            nextIcon = from["notif.settings.nextIcon"] as? String,
            pauseIcon = from["notif.settings.pauseIcon"] as? String,
            playIcon = from["notif.settings.playIcon"] as? String,
            stopIcon = from["notif.settings.stopIcon"] as? String
    )
}