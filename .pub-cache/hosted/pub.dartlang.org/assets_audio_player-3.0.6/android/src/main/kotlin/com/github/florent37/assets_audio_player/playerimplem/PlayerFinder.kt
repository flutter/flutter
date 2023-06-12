package com.github.florent37.assets_audio_player.playerimplem

import android.content.Context
import com.github.florent37.assets_audio_player.AssetAudioPlayerThrowable
import io.flutter.embedding.engine.plugins.FlutterPlugin

interface PlayerImplemTester {
    @Throws(Exception::class)
    suspend fun open(configuration: PlayerFinderConfiguration): PlayerFinder.PlayerWithDuration
}

class PlayerFinderConfiguration(
        val assetAudioPath: String?,
        val flutterAssets: FlutterPlugin.FlutterAssets,
        val assetAudioPackage: String?,
        val audioType: String,
        val networkHeaders: Map<*, *>?,
        val context: Context,
        val onFinished: (() -> Unit)?,
        val onPlaying: ((Boolean) -> Unit)?,
        val onBuffering: ((Boolean) -> Unit)?,
        val onError: ((AssetAudioPlayerThrowable) -> Unit)?,
        val drmConfiguration: Map<*,*>?
)

object PlayerFinder {

    class PlayerWithDuration(val player: PlayerImplem, val duration: DurationMS)
    class NoPlayerFoundException(val why: AssetAudioPlayerThrowable? = null) : Throwable()

    private val HLSExoPlayerTester = PlayerImplemTesterExoPlayer(PlayerImplemTesterExoPlayer.Type.HLS)
    private val DefaultExoPlayerTester = PlayerImplemTesterExoPlayer(PlayerImplemTesterExoPlayer.Type.Default)
    private val DASHExoPlayerTester = PlayerImplemTesterExoPlayer(PlayerImplemTesterExoPlayer.Type.DASH)
    private val SmoothStreamingExoPlayerTester = PlayerImplemTesterExoPlayer(PlayerImplemTesterExoPlayer.Type.SmoothStreaming)
    private val MediaPlayerTester = PlayerImplemTesterMediaPlayer()


    private val playerImpls = listOf<PlayerImplemTester>(
            DefaultExoPlayerTester,
            HLSExoPlayerTester,
            DASHExoPlayerTester,
            SmoothStreamingExoPlayerTester,
            MediaPlayerTester
    )

    private fun sortPlayerImpls(path: String?, originList: List<PlayerImplemTester>) : List<PlayerImplemTester> {
        val editedList = originList.toMutableList()

        path?.let {
            //add others suggestions
            if (path.endsWith(".m3u8")) {
                editedList.moveToFirst(HLSExoPlayerTester)
            }
        }

        return editedList
    }

    fun <T> MutableList<T>.moveToFirst(element: T) = this.apply {
        remove(element)
        add(0, element) //move to first
    }

    @Throws(NoPlayerFoundException::class)
    private suspend fun _findWorkingPlayer(
            remainingImpls: List<PlayerImplemTester>,
            configuration: PlayerFinderConfiguration
    ): PlayerWithDuration {
        if (remainingImpls.isEmpty()) {
            throw NoPlayerFoundException()
        }
        try {
            //try the first
            val implemTester = remainingImpls.first()
            val playerwithDuration = implemTester.open(
                    configuration = configuration
            )
            //if we're here : no exception, we can return it
            return playerwithDuration
        } catch (unrachable : AssetAudioPlayerThrowable.UnreachableException) {
            //not usefull to test all players if the first is UnreachableException
            throw NoPlayerFoundException(why= unrachable)
        } catch (t: Throwable) {
            //else, remove it from list and test the next
            val implsToTest = remainingImpls.toMutableList().apply {
                removeAt(0)
            }
            return _findWorkingPlayer(
                    remainingImpls = implsToTest,
                    configuration= configuration
            )
        }
    }

    @Throws(NoPlayerFoundException::class)
    suspend fun findWorkingPlayer(configuration: PlayerFinderConfiguration): PlayerWithDuration {
        return _findWorkingPlayer(
                remainingImpls= sortPlayerImpls(
                        path= configuration.assetAudioPath,
                        originList=playerImpls
                ),
                configuration= configuration
        )
    }
}
