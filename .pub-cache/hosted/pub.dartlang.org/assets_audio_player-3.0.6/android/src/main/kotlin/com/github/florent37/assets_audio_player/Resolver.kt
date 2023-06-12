package com.github.florent37.assets_audio_player

import android.content.Context
import android.net.Uri
import android.provider.MediaStore

class UriResolver(private val context: Context) {

    companion object {
        const val PREFIX_CONTENT = "content://media"
    }

    private fun contentPath(uri: Uri, columnName: String): String? {
        return context.contentResolver?.query(
                uri,
                arrayOf(
                        columnName
                ),
                null,
                null,
                null)
                ?.use { cursor ->
                    cursor.takeIf { it.count == 1 }?.let {
                        it.moveToFirst()
                        it.getString(cursor.getColumnIndex(columnName))
                    }
                }
    }

    fun audioPath(uri: String?): String? {
        if(uri != null) {
            try {
                if (uri.startsWith(PREFIX_CONTENT)) {
                    val uriParsed = Uri.parse(uri)
                    return contentPath(uriParsed, MediaStore.Audio.Media.DATA) ?: uri
                }
            } catch (t: Throwable) {
                //print(t)
            }
        }
        return uri
    }

    fun imagePath(uri: String?): String? {
        if(uri != null) {
            try {
                if (uri.startsWith(PREFIX_CONTENT)) {
                    val uriParsed = Uri.parse(uri)
                    return contentPath(uriParsed, MediaStore.Images.Media.DATA) ?: uri
                }
            } catch (t: Throwable) {
                //print(t)
            }
        }
        return uri
    }
}