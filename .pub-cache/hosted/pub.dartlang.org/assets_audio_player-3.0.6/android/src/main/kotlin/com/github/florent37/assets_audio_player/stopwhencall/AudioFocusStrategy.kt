package com.github.florent37.assets_audio_player.stopwhencall

sealed class AudioFocusStrategy {
    
    object None : AudioFocusStrategy()

    class Request(
            val resumeAfterInterruption: Boolean,
            val resumeOthersPlayersAfterDone: Boolean
    ) : AudioFocusStrategy()

    companion object  {
        fun from(params: Map<*, *>?): AudioFocusStrategy {
            if(params == null){
                return  AudioFocusStrategy.None
            }
            return try {
                val request = params["request"]
                if (request == false) {
                    AudioFocusStrategy.None
                }
                else {
                    AudioFocusStrategy.Request(
                            resumeAfterInterruption = params["resumeAfterInterruption"] as Boolean,
                            resumeOthersPlayersAfterDone = params["resumeOthersPlayersAfterDone"] as Boolean
                    )
                }
            } catch (t: Throwable){
                AudioFocusStrategy.None
            }
        }
    }

}
