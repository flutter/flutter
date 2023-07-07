package com.xraph.plugin.flutter_unity_widget

interface UnityEventListener {
    fun onMessage(message: String)

    fun onSceneLoaded(name: String, buildIndex: Int, isLoaded: Boolean, isValid: Boolean)
}