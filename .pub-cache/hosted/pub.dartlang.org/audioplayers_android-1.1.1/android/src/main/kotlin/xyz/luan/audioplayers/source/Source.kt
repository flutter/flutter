package xyz.luan.audioplayers.source

import android.media.MediaPlayer
import xyz.luan.audioplayers.player.SoundPoolPlayer

// TODO(luan) replace this indirection with a sealed interface once we have that option!
interface Source {
    fun setForMediaPlayer(mediaPlayer: MediaPlayer)
    fun setForSoundPool(soundPoolPlayer: SoundPoolPlayer)
}