package com.github.florent37.assets_audio_player.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.github.florent37.assets_audio_player.AssetsAudioPlayerPlugin

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val playerId = intent.getStringExtra(NotificationService.EXTRA_PLAYER_ID) ?: return
        val trackID = if (intent.getStringExtra(NotificationService.TRACK_ID) == null) "" else intent.getStringExtra(NotificationService.TRACK_ID)
        val player = AssetsAudioPlayerPlugin.instance?.assetsAudioPlayer?.getPlayer(playerId) ?: return
        when (intent.action) {
             NotificationAction.ACTION_PREV -> player.prev()
             NotificationAction.ACTION_STOP -> {
                 player.askStop()
                 //NotificationManager(context).hideNotification()
             }
             NotificationAction.ACTION_NEXT -> player.next()
             NotificationAction.ACTION_TOGGLE -> {
                //val notificationAction = intent.getSerializableExtra(NotificationService.EXTRA_NOTIFICATION_ACTION) as NotificationAction.Show
                player.askPlayOrPause() //send it to flutter

                //update notif
                //NotificationManager(context).showNotification(playerId= playerId, audioMetas = notificationAction.audioMetas, isPlaying = player.)
            }
            NotificationAction.ACTION_SELECT -> {
                var intent = context.packageManager.getLaunchIntentForPackage(context.packageName)!!;  
                 intent.apply {
                     putExtra(NotificationService.EXTRA_PLAYER_ID, playerId)
                     putExtra(NotificationService.TRACK_ID, trackID)
                 }
                 context.startActivity(intent)
            }
        }
    }
}