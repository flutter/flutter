package com.xraph.plugin.flutter_unity_widget

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Choreographer
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.unity3d.player.IUnityPlayerLifecycleEvents
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView


@SuppressLint("NewApi")
class FlutterUnityWidgetController(
        private val id: Int,
        private val context: Context?,
        binaryMessenger: BinaryMessenger,
        lifecycleProvider: LifecycleProvider
) :     PlatformView,
        DefaultLifecycleObserver,
        FlutterUnityWidgetOptionsSink,
        MethodCallHandler,
        UnityEventListener,
        IUnityPlayerLifecycleEvents {

    //#region Members
    private val LOG_TAG = "FlutterUnityController"
    private var lifecycleProvider: LifecycleProvider = lifecycleProvider
    private var options: FlutterUnityWidgetOptions = FlutterUnityWidgetOptions()

    private val methodChannel: MethodChannel

    private var methodChannelResult: MethodChannel.Result? = null
    private var view: FrameLayout
    private var disposed: Boolean = false
    private var attached: Boolean = false
    private var loadedCallbackPending: Boolean = false

    init {
        UnityPlayerUtils.controllers.add(this)

        var tempContext = UnityPlayerUtils.activity as Context
        if (context != null) tempContext = context
        // set layout view
        view = FrameLayout(tempContext)
        view.setBackgroundColor(Color.WHITE)

        // setup method channel
        methodChannel = MethodChannel(binaryMessenger, "plugin.xraph.com/unity_view_$id")
        methodChannel.setMethodCallHandler(this)

        // Set unity listener
        UnityPlayerUtils.addUnityEventListener(this)

        if(UnityPlayerUtils.unityPlayer == null) {
            createPlayer()
            refocusUnity()
        } else if(!UnityPlayerUtils.unityLoaded) {
            createPlayer()
            attachToView()
        } else {
            // attach unity to controller
            attachToView()
        }
    }

    //#endregion

    //#region Flutter Overrides
    override fun getView(): View {
//        if(UnityPlayerUtils.unityPlayer == null)
//            return UnityPlayerUtils.unityPlayer!!

        return view
    }

    override fun dispose() {
        Log.d(LOG_TAG, "this controller disposed")
        UnityPlayerUtils.removeUnityEventListener(this)
        if (disposed) {
            return
        }

        detachView()
        destroyUnityViewIfNecessary()

        val lifecycle = lifecycleProvider.getLifecycle()
        lifecycle.removeObserver(this)

        disposed = true
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        when (methodCall.method) {
            "unity#waitForUnity" -> {
                if (UnityPlayerUtils.unityPlayer != null) {
                    result.success(null)
                    return
                }
                result.success(null)
                methodChannelResult = result
            }
            "unity#createPlayer" -> {
                invalidateFrameIfNeeded()
                this.createPlayer()
                refocusUnity()
                result.success(null)
            }
            "unity#isReady" -> {
                result.success(UnityPlayerUtils.unityPlayer != null)
            }
            "unity#isLoaded" -> {
                result.success(UnityPlayerUtils.unityLoaded)
            }
            "unity#isPaused" -> {
                result.success(UnityPlayerUtils.unityPaused)
            }
            "unity#postMessage" -> {
                invalidateFrameIfNeeded()
                val gameObject: String = methodCall.argument<String>("gameObject").toString()
                val methodName: String = methodCall.argument<String>("methodName").toString()
                val message: String = methodCall.argument<String>("message").toString()
                UnityPlayerUtils.postMessage(gameObject, methodName, message)
                result.success(true)
            }
            "unity#pausePlayer" -> {
                invalidateFrameIfNeeded()
                UnityPlayerUtils.pause()
                result.success(true)
            }
            "unity#openInNativeProcess" -> {
                openNativeUnity()
                result.success(true)
            }
            "unity#resumePlayer" -> {
                invalidateFrameIfNeeded()
                UnityPlayerUtils.resume()
                result.success(true)
            }
            "unity#unloadPlayer" -> {
                invalidateFrameIfNeeded()
                UnityPlayerUtils.unload()
                result.success(true)
            }
            "unity#dispose" -> {
                // destroyUnityViewIfNecessary()
                // if ()
                // dispose()
                result.success(null)
            }
            "unity#silentQuitPlayer" -> {
                UnityPlayerUtils.quitPlayer()
                result.success(true)
            }
            "unity#quitPlayer" -> {
                if (UnityPlayerUtils.unityPlayer != null) {
                    UnityPlayerUtils.unityPlayer!!.destroy()
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
    //#endregion

    //#region Options Override
    override fun setFullscreenEnabled(fullscreenEnabled: Boolean) {
        options.fullscreenEnabled = fullscreenEnabled
    }

    override fun setHideStatusBar(hideStatusBar: Boolean) {
        options.hideStatus = hideStatusBar
    }

    override fun setRunImmediately(runImmediately: Boolean) {
        options.runImmediately = runImmediately
    }

    override fun setUnloadOnDispose(unloadOnDispose: Boolean) {
        options.unloadOnDispose = unloadOnDispose
    }
    //#endregion

    //#region Unity Events
    override fun onMessage(message: String) {
        Handler(Looper.getMainLooper()).post {
            methodChannel.invokeMethod("events#onUnityMessage", message)
        }
    }

    override fun onSceneLoaded(name: String, buildIndex: Int, isLoaded: Boolean, isValid: Boolean) {
        Handler(Looper.getMainLooper()).post {
            val payload: MutableMap<String, Any> = HashMap()
            payload["name"] = name
            payload["buildIndex"] = buildIndex
            payload["isLoaded"] = isLoaded
            payload["isValid"] = isValid
            methodChannel.invokeMethod("events#onUnitySceneLoaded", payload)
        }
    }

    override fun onUnityPlayerUnloaded() {
        Log.d(LOG_TAG, "onUnityPlayerUnloaded")
        UnityPlayerUtils.unityLoaded = false
        Handler(Looper.getMainLooper()).post {
            methodChannel.invokeMethod("events#onUnityUnloaded", true)
        }
    }

    override fun onUnityPlayerQuitted() {
        if (disposed) return
    }

    //#endregion

    //#region Lifecycle Overrides
    override fun onCreate(owner: LifecycleOwner) {
        Log.d(LOG_TAG, "onCreate")
        owner.lifecycle.addObserver(this)
    }

    override fun onResume(owner: LifecycleOwner) {
        Log.d(LOG_TAG, "onResume")
        reattachToView()
        if(UnityPlayerUtils.viewStaggered && UnityPlayerUtils.unityLoaded) {
            this.createPlayer()
            refocusUnity()
            UnityPlayerUtils.viewStaggered = false
        }
    }

    override fun onPause(owner: LifecycleOwner) {
        Log.d(LOG_TAG, "onPause")
        UnityPlayerUtils.viewStaggered = true
        UnityPlayerUtils.pause()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        Log.d(LOG_TAG, "onDestroy")
        if (disposed) {
            return
        }

        owner.lifecycle.removeObserver(this)
    }

    //#endregion

    //#region Member Methods
    fun bootstrap() {
        this.lifecycleProvider.getLifecycle().addObserver(this)
    }

    private fun openNativeUnity() {
        val activity = getActivity(null)
        if (activity != null) {
            val intent = Intent(getActivity(null)!!.applicationContext, OverrideUnityActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            intent.putExtra("fullscreen", options.fullscreenEnabled)
            intent.putExtra("flutterActivity", activity.javaClass)
            activity.startActivityForResult(intent, 1)
        }
    }

    private fun destroyUnityViewIfNecessary() {
        if (options.unloadOnDispose) {
            UnityPlayerUtils.unload()
        }
    }

    private fun createPlayer() {
        try {
            if (UnityPlayerUtils.activity != null) {
                UnityPlayerUtils.createUnityPlayer( this, object : OnCreateUnityViewCallback {
                    override fun onReady() {
                        // attach unity to controller
                        attachToView()

                        if (methodChannelResult != null) {
                            methodChannelResult!!.success(true)
                            methodChannelResult = null
                        }
                    }
                })
            }
        } catch (e: Exception) {
            if (methodChannelResult != null) {
                methodChannelResult!!.error("FLUTTER_UNITY_WIDGET", e.message, e)
                methodChannelResult!!.success(false)
                methodChannelResult = null
            }
        }
    }

    private fun getActivity(context: Context?): Activity? {
        if (UnityPlayerUtils.activity != null) {
            return UnityPlayerUtils.activity
        }

        if (context == null) {
            return UnityPlayerUtils.activity
        } else if (context is ContextWrapper) {
            return if (context is Activity) {
                context
            } else {
                getActivity(context.baseContext)
            }
        }
        return UnityPlayerUtils.activity
    }

    private fun detachView() {
        UnityPlayerUtils.controllers.remove(this)
        methodChannel.setMethodCallHandler(null)
        UnityPlayerUtils.removePlayer(this)
    }


    private fun attachToView() {
        if (UnityPlayerUtils.unityPlayer == null) return
        Log.d(LOG_TAG, "Attaching unity to view")

        if (UnityPlayerUtils.unityPlayer!!.parent != null) {
            (UnityPlayerUtils.unityPlayer!!.parent as ViewGroup).removeView(UnityPlayerUtils.unityPlayer)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            UnityPlayerUtils.unityPlayer!!.z = -1f
        }

        // add unity to view
        UnityPlayerUtils.addUnityViewToGroup(view)
        UnityPlayerUtils.focus()
        attached = true
    }

    // DO NOT CHANGE THIS FUNCTION
    private fun refocusUnity() {
        UnityPlayerUtils.resume()
        UnityPlayerUtils.pause()
        UnityPlayerUtils.resume()
    }

    fun reattachToView() {
        if (UnityPlayerUtils.unityPlayer!!.parent != view) {
            this.attachToView()
            Handler(Looper.getMainLooper()).post {
                methodChannel.invokeMethod("events#onViewReattached", null)
            }
        }
        view.requestLayout()
    }

    /// Reference solution to Google Maps implementation
    /// https://github.com/flutter/plugins/blob/b0bfab678f83bebd49e9f9d0a83fe9b40774e853/packages/google_maps_flutter/google_maps_flutter/android/src/main/java/io/flutter/plugins/googlemaps/GoogleMapController.java#L154
    private fun invalidateFrameIfNeeded() {
        if (UnityPlayerUtils.unityPlayer == null || loadedCallbackPending) {
            return
        }

        loadedCallbackPending = false
        postFrameCallback {
            postFrameCallback {
                view.invalidate()
            }
        }
    }

    private fun postFrameCallback(f: Runnable) {
        Choreographer.getInstance()
                .postFrameCallback { f.run() }
    }
    //#endregion
}