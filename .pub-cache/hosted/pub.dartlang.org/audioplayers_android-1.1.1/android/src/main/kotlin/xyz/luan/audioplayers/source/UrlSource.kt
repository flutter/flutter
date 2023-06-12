package xyz.luan.audioplayers.source

import android.media.MediaPlayer
import xyz.luan.audioplayers.player.SoundPoolPlayer
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.URI
import java.net.URL

data class UrlSource(
    val url: String,
    val isLocal: Boolean,
): Source {
    override fun setForMediaPlayer(mediaPlayer: MediaPlayer) {
        mediaPlayer.setDataSource(url)
    }

    override fun setForSoundPool(soundPoolPlayer: SoundPoolPlayer) {
        soundPoolPlayer.setUrlSource(this)
    }

    fun getAudioPathForSoundPool(): String? {
        if (isLocal) {
            return url.removePrefix("file://")
        }

        return loadTempFileFromNetwork().absolutePath
    }

    private fun loadTempFileFromNetwork(): File {
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
}