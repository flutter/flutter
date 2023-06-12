package com.github.florent37.assets_audio_player.notification

import android.app.Notification
import android.app.NotificationChannel
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.os.Build
import android.os.IBinder
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.support.v4.media.session.PlaybackStateCompat.ACTION_SEEK_TO
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.media.session.MediaButtonReceiver
import com.github.florent37.assets_audio_player.R
import com.google.android.exoplayer2.C
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlin.math.abs
import android.app.PendingIntent.FLAG_UPDATE_CURRENT
import android.app.PendingIntent.FLAG_IMMUTABLE

class NotificationService : Service() {

    companion object {
        const val NOTIFICATION_ID = 1
        const val CHANNEL_ID = "assets_audio_player"
        const val MEDIA_SESSION_TAG = "assets_audio_player"

        const val EXTRA_PLAYER_ID = "playerId"
        const val EXTRA_NOTIFICATION_ACTION = "notificationAction"
        const val TRACK_ID = "trackID";

        const val manifestIcon = "assets.audio.player.notification.icon"
        const val manifestIconPlay = "assets.audio.player.notification.icon.play"
        const val manifestIconPause = "assets.audio.player.notification.icon.pause"
        const val manifestIconPrev = "assets.audio.player.notification.icon.prev"
        const val manifestIconNext = "assets.audio.player.notification.icon.next"
        const val manifestIconStop = "assets.audio.player.notification.icon.stop"

        private var stateCompat : PlaybackStateCompat? = null

        fun timeDiffer(old: PlaybackStateCompat?, new: PlaybackStateCompat, minDifferenceMS: Long) : Boolean {
            if(old == null){
                return true
            }

            val currentPos = old.position
            return abs(new.position - currentPos) > minDifferenceMS
        }

        fun updatePosition(context: Context, isPlaying: Boolean, currentPositionMs: Long, speed: Float) {
            MediaButtonsReceiver.getMediaSessionCompat(context).let { mediaSession ->
                val state = if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED
                val newState = PlaybackStateCompat.Builder()
                        .setActions(ACTION_SEEK_TO)
                        .setState(state, currentPositionMs, if (isPlaying) speed else 0f)
                        .build()

                if(
                        //pause -> play, play-> pause
                        stateCompat?.state != newState.state ||
                        //speed changed
                        stateCompat?.playbackSpeed != speed ||
                        //seek
                        timeDiffer(stateCompat, newState, 2000)
                ){
                    stateCompat = newState
                    mediaSession.setPlaybackState(stateCompat)
                }

            }
        }


        private fun MediaMetadataCompat.Builder.putStringIfNotNull(key: String, value: String?) : MediaMetadataCompat.Builder {
            return if(value != null)
                this.putString(key, value)
            else
                this
        }

        fun updateNotifMetaData(context: Context, display: Boolean,
                                durationMs: Long,
                                title: String? = null,
                                artist: String? = null,
                                album: String? = null
        ) {
            val mediaSession = MediaButtonsReceiver.getMediaSessionCompat(context)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val builder = MediaMetadataCompat.Builder()
                        //for samsung devices https://github.com/florent37/Flutter-AssetsAudioPlayer/issues/205
                        .putStringIfNotNull(MediaMetadata.METADATA_KEY_TITLE, title)
                        .putStringIfNotNull(MediaMetadata.METADATA_KEY_ARTIST, artist)
                        .putStringIfNotNull(MediaMetadata.METADATA_KEY_ALBUM, album)

                if (!display || durationMs == 0L /* livestream */) {
                    builder.putLong(MediaMetadata.METADATA_KEY_DURATION, C.TIME_UNSET)
                } else {
                    builder.putLong(MediaMetadata.METADATA_KEY_DURATION, durationMs)
                }

                mediaSession.setMetadata(builder.build())
            }
        }
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        if (intent.action == Intent.ACTION_MEDIA_BUTTON) {
            MediaButtonsReceiver.getMediaSessionCompat(applicationContext).let {
                MediaButtonReceiver.handleIntent(it, intent)
            }
        }
        when (val notificationAction = intent.getSerializableExtra(EXTRA_NOTIFICATION_ACTION)) {
            is NotificationAction.Show -> {
                displayNotification(notificationAction)
            }
            is NotificationAction.Hide -> {
                hideNotif()
            }
        }
        return START_NOT_STICKY
    }

    private fun createReturnIntent(forAction: String, forPlayer: String, audioMetas: AudioMetas): Intent {
        return Intent(this, NotificationActionReceiver::class.java)
                .setAction(forAction)
                .putExtra(EXTRA_PLAYER_ID, forPlayer)
                .putExtra(TRACK_ID, audioMetas.trackID)
    }

    private fun displayNotification(action: NotificationAction.Show) {
        GlobalScope.launch(Dispatchers.Main) {
            val image = ImageDownloader.loadBitmap(context = applicationContext, imageMetas = action.audioMetas.image)
            if(image != null){
                displayNotification(action, image) //display without image for now
                return@launch
            }
            val imageOnLoadError = ImageDownloader.loadBitmap(context = applicationContext, imageMetas = action.audioMetas.imageOnLoadError)
            if(imageOnLoadError != null){
                displayNotification(action, imageOnLoadError) //display without image for now
                return@launch
            }

            val imageFromManifest = ImageDownloader.loadHolderBitmapFromManifest(context = applicationContext)
            if(imageFromManifest != null){
                displayNotification(action, imageFromManifest) //display without image for now
                return@launch
            }

            displayNotification(action, null) //display without image
        }
    }

    private fun getSmallIcon(context: Context): Int {
        return getCustomIconOrDefault(context, manifestIcon, null, R.drawable.exo_icon_circular_play)
    }

    private fun getPlayIcon(context: Context, resourceName: String?): Int {
        return getCustomIconOrDefault(context, manifestIconPlay, resourceName, R.drawable.exo_icon_play)
    }

    private fun getPauseIcon(context: Context, resourceName: String?): Int {
        return getCustomIconOrDefault(context, manifestIconPause, resourceName, R.drawable.exo_icon_pause)
    }

    private fun getNextIcon(context: Context, resourceName: String?): Int {
        return getCustomIconOrDefault(context, manifestIconNext, resourceName, R.drawable.exo_icon_next)
    }

    private fun getPrevIcon(context: Context, resourceName: String?): Int {
        return getCustomIconOrDefault(context, manifestIconPrev, resourceName, R.drawable.exo_icon_previous)
    }

    private fun getStopIcon(context: Context, resourceName: String?): Int {
        return getCustomIconOrDefault(context, manifestIconStop, resourceName, R.drawable.exo_icon_stop)
    }

    private fun getCustomIconOrDefault(context: Context, manifestName: String, resourceName: String?, defaultIcon: Int): Int {
        try {
            // by resource name
            val customIconFromName = getResourceID(resourceName)
            if (customIconFromName != null) {
                return customIconFromName
            }

            //by manifest
            val appInfos = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
            val customIconFromManifest = appInfos.metaData.get(manifestName) as? Int
            if (customIconFromManifest != null) {
                return customIconFromManifest
            }
        } catch (t: Throwable) {
            //print(t)
        }

        //if customIconFromName is null or customIconFromManifest is null
        return defaultIcon
    }

    private fun getResourceID(iconName: String?): Int? {
        return iconName?.let { name ->
            resources.getIdentifier(name, "drawable", applicationContext.packageName)
        }
    }

    private fun displayNotification(action: NotificationAction.Show, bitmap: Bitmap?) {
        createNotificationChannel()
        val mediaSession = MediaButtonsReceiver.getMediaSessionCompat(applicationContext)

        val notificationSettings = action.notificationSettings

        updateNotifMetaData(
                context = applicationContext,
                display = notificationSettings.seekBarEnabled,
                title = action.audioMetas.title,
                artist = action.audioMetas.artist,
                album = action.audioMetas.album,
                durationMs = action.durationMs
        )

        val toggleIntent = createReturnIntent(forAction = NotificationAction.ACTION_TOGGLE, forPlayer = action.playerId, audioMetas = action.audioMetas)
                .putExtra(EXTRA_NOTIFICATION_ACTION, action.copyWith(
                        isPlaying = !action.isPlaying
                ))
        val pendingToggleIntent = PendingIntent.getBroadcast(this, 0, toggleIntent, FLAG_IMMUTABLE or FLAG_UPDATE_CURRENT)
        MediaButtonReceiver.handleIntent(mediaSession, toggleIntent)

        val context = this

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                //prev
                .apply {
                    if (notificationSettings.prevEnabled) {
                        addAction(getPrevIcon(context, action.notificationSettings.previousIcon), "prev",
                                PendingIntent.getBroadcast(context, 0, createReturnIntent(forAction = NotificationAction.ACTION_PREV, forPlayer = action.playerId, audioMetas = action.audioMetas), FLAG_IMMUTABLE or FLAG_UPDATE_CURRENT)
                        )
                    }
                }
                //play/pause
                .apply {
                    if (notificationSettings.playPauseEnabled) {
                        addAction(
                                if (action.isPlaying) getPauseIcon(context, action.notificationSettings.pauseIcon) else getPlayIcon(context, action.notificationSettings.playIcon),
                                if (action.isPlaying) "pause" else "play",
                                pendingToggleIntent
                        )
                    }
                }
                //next
                .apply {
                    if (notificationSettings.nextEnabled) {
                        addAction(getNextIcon(context, action.notificationSettings.nextIcon), "next", PendingIntent.getBroadcast(context, 0,
                                createReturnIntent(forAction = NotificationAction.ACTION_NEXT, forPlayer = action.playerId, audioMetas = action.audioMetas), FLAG_IMMUTABLE or FLAG_UPDATE_CURRENT)
                        )
                    }
                }
                //stop
                .apply {
                    if (notificationSettings.stopEnabled) {
                        addAction(getStopIcon(context, action.notificationSettings.stopIcon), "stop", PendingIntent.getBroadcast(context, 0,
                                createReturnIntent(forAction = NotificationAction.ACTION_STOP, forPlayer = action.playerId, audioMetas = action.audioMetas), FLAG_IMMUTABLE or FLAG_UPDATE_CURRENT)
                        )
                    }
                }
                .setStyle(androidx.media.app.NotificationCompat.MediaStyle()
                        .also {
                            when (notificationSettings.numberEnabled()) {
                                1 -> it.setShowActionsInCompactView(0)
                                2 -> it.setShowActionsInCompactView(0, 1)
                                3 -> it.setShowActionsInCompactView(0, 1, 2)
                                4 -> it.setShowActionsInCompactView(0, 1, 2, 3)
                                else -> it.setShowActionsInCompactView()
                            }
                        }
                        .setShowCancelButton(true)
                        .setMediaSession(mediaSession.sessionToken)
                )
                .setSmallIcon(getSmallIcon(context))
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setContentTitle(action.audioMetas.title)
                .setContentText(action.audioMetas.artist)
                .setOnlyAlertOnce(true)
                .also {
                    if (!action.audioMetas.album.isNullOrEmpty()) {
                        it.setSubText(action.audioMetas.album)
                    }
                }
                .setContentIntent(PendingIntent.getBroadcast(this, 0,
                        createReturnIntent(forAction = NotificationAction.ACTION_SELECT, forPlayer = action.playerId, audioMetas = action.audioMetas), FLAG_IMMUTABLE or PendingIntent.FLAG_CANCEL_CURRENT))
                .also {
                    if (bitmap != null) {
                        it.setLargeIcon(bitmap)
                    }
                }
                .setShowWhen(false)
                .build()
        startForeground(NOTIFICATION_ID, notification)

        //fix for https://github.com/florent37/Flutter-AssetsAudioPlayer/issues/139
        if (!action.isPlaying && Build.VERSION.SDK_INT >= 24) {
           stopForeground(2)
        }

    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                    CHANNEL_ID,
                    "Foreground Service Channel",
                    android.app.NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "assets_audio_player"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            NotificationManagerCompat.from(applicationContext).createNotificationChannel(
                    serviceChannel
            )
        }
    }

    private fun hideNotif() {
        NotificationManagerCompat.from(applicationContext).cancel(NOTIFICATION_ID)
        stopForeground(true)
        stopSelf()
    }

    override fun onTaskRemoved(rootIntent: Intent) {
        hideNotif()
    }

    override fun onCreate() {
        super.onCreate()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
    }

}
