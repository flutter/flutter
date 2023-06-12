package com.github.florent37.assets_audio_player.headset

enum class HeadsetStrategy {
    none,
    pauseOnUnplug,
    pauseOnUnplugPlayOnPlug;

    companion object  {
        fun from(s: String?) : HeadsetStrategy {
            return when(s){
                "pauseOnUnplug" -> pauseOnUnplug
                "pauseOnUnplugPlayOnPlug" -> pauseOnUnplugPlayOnPlug
                else -> none
            }
        }
    }
}