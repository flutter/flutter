package com.github.florent37.assets_audio_player.notification

import java.io.Serializable

data class ImageMetas(
        val imageType: String?,
        val imagePackage: String?,
        val imagePath: String?
) : Serializable

data class AudioMetas(
        val title: String?,
        val artist: String?,
        val album: String?,
        val image: ImageMetas?,
        val imageOnLoadError: ImageMetas?,
        val trackID: String?
) : Serializable

fun fetchImageMetas(from: Map<*, *>, suffix: String= "") : ImageMetas {
    return ImageMetas(
            imagePath = from["song.image$suffix"] as? String,
            imageType = from["song.imageType$suffix"] as? String,
            imagePackage = from["song.imagePackage$suffix"] as? String
    )
}

fun fetchAudioMetas(from: Map<*, *>) : AudioMetas {
    return AudioMetas(
            title = from["song.title"] as? String,
            artist = from["song.artist"] as? String,
            album = from["song.album"] as? String,
            image = fetchImageMetas(from),
            imageOnLoadError = fetchImageMetas(from, suffix = ".onLoadFail"),
            trackID = from["song.trackID"] as? String
    )
}