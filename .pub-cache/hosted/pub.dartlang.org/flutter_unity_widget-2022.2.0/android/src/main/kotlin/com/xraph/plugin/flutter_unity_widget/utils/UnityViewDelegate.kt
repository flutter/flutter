package com.xraph.plugin.flutter_unity_widget.utils

import android.os.Bundle

import com.unity3d.player.UnityPlayer

interface IUnityViewDelegate {
    val unityPlayer: UnityPlayer

    // val view:IObjectWrapper

    @Throws(Exception::class)
    fun onCreate(bundle: Bundle)

    @Throws(Exception::class)
    fun onResume()

    @Throws(Exception::class)
    fun onPause()

    @Throws(Exception::class)
    fun onDestroy()

    @Throws(Exception::class)
    fun onLowMemory()

    @Throws(Exception::class)
    fun onSaveInstanceState(bundle: Bundle)

    @Throws(Exception::class)
    fun onStart()

    @Throws(Exception::class)
    fun onStop()
}