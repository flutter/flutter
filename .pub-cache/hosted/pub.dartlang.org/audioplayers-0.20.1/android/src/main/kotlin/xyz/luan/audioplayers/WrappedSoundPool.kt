package xyz.luan.audioplayers

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaDataSource
import android.media.SoundPool
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.URI
import java.net.URL
import java.util.*
import android.os.Build

class WrappedSoundPool internal constructor(override val playerId: String) : Player() {
    companion object {
        private val soundPool = createSoundPool()

        /** For the onLoadComplete listener, track which sound id is associated with which player. An entry only exists until
         * it has been loaded.
         */
        private val soundIdToPlayer = Collections.synchronizedMap(mutableMapOf<Int, WrappedSoundPool>())

        /** This is to keep track of the players which share the same sound id, referenced by url. When a player release()s, it
         * is removed from the associated player list. The last player to be removed actually unloads() the sound id and then
         * the url is removed from this map.
         */
        private val urlToPlayers = Collections.synchronizedMap(mutableMapOf<String, MutableList<WrappedSoundPool>>())

        private fun createSoundPool(): SoundPool {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val attrs = AudioAttributes.Builder().setLegacyStreamType(AudioManager.USE_DEFAULT_STREAM_TYPE)
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .build()
                // make a new SoundPool, allowing up to 100 streams
                SoundPool.Builder()
                        .setAudioAttributes(attrs)
                        .setMaxStreams(100)
                        .build()
            } else {
                // make a new SoundPool, allowing up to 100 streams
                @Suppress("DEPRECATION")
                SoundPool(100, AudioManager.STREAM_MUSIC, 0)
            }
        }

        init {
            soundPool.setOnLoadCompleteListener { _, sampleId, _ ->
                Logger.info("Loaded $sampleId")
                val loadingPlayer = soundIdToPlayer[sampleId]
                if (loadingPlayer != null) {
                    soundIdToPlayer.remove(loadingPlayer.soundId)
                    // Now mark all players using this sound as not loading and start them if necessary
                    synchronized(urlToPlayers) {
                        val urlPlayers = urlToPlayers[loadingPlayer.url] ?: listOf<WrappedSoundPool>()
                        for (player in urlPlayers) {
                            Logger.info("Marking $player as loaded")
                            player.loading = false
                            if (player.playing) {
                                Logger.info("Delayed start of $player")
                                player.start()
                            }
                        }
                    }
                }
            }
        }
    }

    private var url: String? = null
    private var volume = 1.0f
    private var rate = 1.0f
    private var soundId: Int? = null
    private var streamId: Int? = null
    private var playing = false
    private var paused = false
    private var looping = false
    private var loading = false

    override fun play() {
        if (!loading) {
            start()
        }
        playing = true
        paused = false
    }

    override fun stop() {
        if (playing) {
            streamId?.let { soundPool.stop(it) }
            playing = false
        }
        paused = false
    }

    override fun release() {
        stop()
        val soundId = this.soundId ?: return
        val url = this.url ?: return

        synchronized(urlToPlayers) {
            val playersForSoundId = urlToPlayers[url] ?: return
            if (playersForSoundId.singleOrNull() === this) {
                urlToPlayers.remove(url)
                soundPool.unload(soundId)
                soundIdToPlayer.remove(soundId)
                this.soundId = null
                Logger.info("unloaded soundId $soundId")
            } else {
                // This is not the last player using the soundId, just remove it from the list.
                playersForSoundId.remove(this)
            }

        }
    }

    override fun pause() {
        if (playing) {
            streamId?.let { soundPool.pause(it) }
        }
        playing = false
        paused = true
    }

    override fun setDataSource(mediaDataSource: MediaDataSource?) {
        throw unsupportedOperation("setDataSource")
    }

    override fun setUrl(url: String, isLocal: Boolean) {
        if (this.url != null && this.url == url) {
            return
        }
        if (soundId != null) {
            release()
        }
        synchronized(urlToPlayers) {
            this.url = url
            val urlPlayers = urlToPlayers.getOrPut(url) { mutableListOf() }
            val originalPlayer = urlPlayers.firstOrNull()

            if (originalPlayer != null) {
                // Sound has already been loaded - reuse the soundId.
                loading = originalPlayer.loading
                soundId = originalPlayer.soundId
                Logger.info("Reusing soundId $soundId for $url is loading=$loading $this")
            } else {
                // First one for this URL - load it.
                val start = System.currentTimeMillis()

                loading = true
                soundId = soundPool.load(getAudioPath(url, isLocal), 1)
                soundIdToPlayer[soundId] = this

                Logger.info("time to call load() for $url: ${System.currentTimeMillis() - start} player=$this")
            }
            urlPlayers.add(this)
        }
    }

    override fun setVolume(volume: Double) {
        this.volume = volume.toFloat()
        if (playing) {
            streamId?.let { soundPool.setVolume(it, this.volume, this.volume) }
        }
    }

    override fun setRate(rate: Double) {
        this.rate = rate.toFloat()
        if (streamId != null) {
            streamId?.let { soundPool.setRate(it, this.rate) }
        }
    }

    override fun configAttributes(
            respectSilence: Boolean,
            stayAwake: Boolean,
            duckAudio: Boolean
    ) = Unit

    override fun setReleaseMode(releaseMode: ReleaseMode) {
        looping = releaseMode === ReleaseMode.LOOP
        if (playing) {
            streamId?.let { soundPool.setLoop(it, loopModeInteger()) }
        }
    }

    override fun getDuration() = throw unsupportedOperation("getDuration")

    override fun getCurrentPosition() = throw unsupportedOperation("getDuration")

    override fun isActuallyPlaying(): Boolean = false

    override fun setPlayingRoute(playingRoute: String) {
        throw unsupportedOperation("setPlayingRoute")
    }

    override fun seek(position: Int) {
        throw unsupportedOperation("seek")
    }

    private fun start() {
        setRate(rate.toDouble())
        if (paused) {
            streamId?.let { soundPool.resume(it) }
            paused = false
        } else {
            val soundId = this.soundId ?: return
            streamId = soundPool.play(
                    soundId,
                    volume,
                    volume,
                    0,
                    loopModeInteger(),
                    1.0f
            )
        }
    }

    /** Integer representation of the loop mode used by Android */
    private fun loopModeInteger(): Int = if (looping) -1 else 0

    private fun getAudioPath(url: String?, isLocal: Boolean): String? {
        if (isLocal) {
            return url?.removePrefix("file://")
        }

        return loadTempFileFromNetwork(url).absolutePath
    }

    private fun loadTempFileFromNetwork(url: String?): File {
        val bytes = downloadUrl(URI.create(url).toURL())
        val tempFile = File.createTempFile("sound", "")
        FileOutputStream(tempFile).use {
            it.write(bytes)
            tempFile.deleteOnExit()
        }
        return tempFile
    }

    private fun downloadUrl(url: URL): ByteArray {
        val outputStream = ByteArrayOutputStream()
        url.openStream().use { stream ->
            val chunk = ByteArray(4096)
            while (true) {
                val bytesRead = stream.read(chunk).takeIf { it > 0 } ?: break
                outputStream.write(chunk, 0, bytesRead)
            }
        }
        return outputStream.toByteArray()
    }

    private fun unsupportedOperation(message: String): UnsupportedOperationException {
        return UnsupportedOperationException("LOW_LATENCY mode does not support: $message")
    }
}
