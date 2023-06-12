package com.github.florent37.assets_audio_player.notification

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Drawable
import android.net.Uri
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.loader.FlutterLoader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

object ImageDownloader {

    suspend fun loadBitmap(context: Context, imageMetas: ImageMetas?) : Bitmap? {
        if (imageMetas?.imageType != null && imageMetas.imagePath != null) {
            try {
                return getBitmap(context = context,
                        fileType = imageMetas.imageType,
                        filePath = imageMetas.imagePath,
                        filePackage = imageMetas.imagePackage
                )
            } catch (t: Throwable) {
                print(t)
            }
        }
        return null
    }


    const val manifestNotificationPlaceHolder = "assets.audio.player.notification.place.holder"

    suspend fun loadHolderBitmapFromManifest(context: Context) : Bitmap? {
        try {
            val appInfos = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
            val manifestPlaceHolderResource = appInfos.metaData.get(manifestNotificationPlaceHolder) as? Int
            if(manifestPlaceHolderResource == null){
                throw Exception("no $manifestPlaceHolderResource on AndroidManifest.xml")
            }

            return BitmapFactory.decodeResource(context.resources, manifestPlaceHolderResource)
        } catch (t : Throwable) {
            print(t)
        }
        return null
    }

    suspend fun getBitmap(context: Context, fileType: String, filePath: String, filePackage: String?): Bitmap = withContext(Dispatchers.IO) {
        suspendCoroutine<Bitmap> { continuation ->
            try {
                when (fileType) {
                    "asset" -> {
                        val loader: FlutterLoader = FlutterInjector.instance().flutterLoader()
                        val path = "file:///android_asset/${if(filePackage == null){
                            loader.getLookupKeyForAsset(filePath)
                        } else {
                            loader.getLookupKeyForAsset(filePath, filePackage)
                        }}"
                        //Log.d("ImageDownloader", "path $path")
                        val uri = Uri.parse(path)
                        //Log.d("ImageDownloader", "uri $uri")
                        Glide.with(context)
                                .asBitmap()
                                .timeout(5000)
                                .load(uri)
                                .into(object : CustomTarget<Bitmap>() {
                                    override fun onLoadFailed(errorDrawable: Drawable?) {
                                        continuation.resumeWithException(Exception("failed to download $filePath"))
                                    }

                                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                                        continuation.resume(resource)
                                    }

                                    override fun onLoadCleared(placeholder: Drawable?) {

                                    }
                                })

                        //val istr = context.assets.open("flutter_assets/$filePath")
                        //val bitmap = BitmapFactory.decodeStream(istr)
                        //continuation.resume(bitmap)
                    }
                    "network" -> {
                        Glide.with(context)
                                .asBitmap()
                                .timeout(5000)
                                .load(filePath)
                                .into(object : CustomTarget<Bitmap>() {
                                    override fun onLoadFailed(errorDrawable: Drawable?) {
                                        try {
                                            val appInfos = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
                                            val manifestPlaceHolderResource = appInfos.metaData.get(manifestNotificationPlaceHolder) as? Int
                                            if(manifestPlaceHolderResource == null){
                                                continuation.resumeWithException(Exception("failed to download $filePath"))
                                            }else{
                                                val placeHolder = BitmapFactory.decodeResource(context.resources,manifestPlaceHolderResource)
                                                continuation.resume(placeHolder)
                                            }
                                        } catch (t : Throwable) {
                                            continuation.resumeWithException(Exception("failed to download $filePath"))
                                        }
                                    }

                                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                                        continuation.resume(resource)
                                    }

                                    override fun onLoadCleared(placeholder: Drawable?) {

                                    }
                                })
                    }
                    else -> {
                        //val options = BitmapFactory.Options().apply {
                        //    inPreferredConfig = Bitmap.Config.ARGB_8888
                        //}
                        //val bitmap = BitmapFactory.decodeFile(filePath, options)
                        //continuation.resume(bitmap)

                        Glide.with(context)
                                .asBitmap()
                                .timeout(5000)
                                .load(File(filePath).path)
                                .into(object : CustomTarget<Bitmap>() {
                                    override fun onLoadFailed(errorDrawable: Drawable?) {
                                        try {
                                            val appInfos = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
                                            val manifestPlaceHolderResource = appInfos.metaData.get(manifestNotificationPlaceHolder) as? Int
                                            if(manifestPlaceHolderResource == null){
                                                continuation.resumeWithException(Exception("failed to download $filePath"))
                                            }else{
                                                val placeHolder = BitmapFactory.decodeResource(context.resources,manifestPlaceHolderResource)
                                                continuation.resume(placeHolder)
                                            }
                                        } catch (t : Throwable) {
                                            continuation.resumeWithException(Exception("failed to download $filePath"))
                                        }
                                    }

                                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                                        continuation.resume(resource)
                                    }

                                    override fun onLoadCleared(placeholder: Drawable?) {

                                    }
                                })
                    }
                }
            } catch (t: Throwable) {
                // handle exception
                t.printStackTrace()
                continuation.resumeWithException(t)
            }
        }
    }
}