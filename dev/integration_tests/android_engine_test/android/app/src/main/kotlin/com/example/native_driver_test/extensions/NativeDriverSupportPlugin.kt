// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_engine_test.extensions

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Build
import android.os.SystemClock
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import io.flutter.Log
import io.flutter.embedding.android.FlutterImageView
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.mutatorsstack.FlutterMutatorView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.renderer.FlutterRenderer
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformOverlayView

class NativeDriverSupportPlugin :
    ActivityAware,
    FlutterPlugin,
    MethodCallHandler {
    private val tag = "NativeDriverSupportPlugin"
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var flutterEngine: FlutterEngine? = null
    private var flutterRenderer: FlutterRenderer? = null
    private var isFlutterUiDisplayed = false
    private val pendingDisplayResults = mutableListOf<MethodChannel.Result>()

    private val displayListener =
        object : FlutterUiDisplayListener {
            override fun onFlutterUiDisplayed() {
                isFlutterUiDisplayed = true
                val pending = pendingDisplayResults.toList()
                pendingDisplayResults.clear()
                for (result in pending) {
                    result.success(null)
                }
            }

            override fun onFlutterUiNoLongerDisplayed() {
                isFlutterUiDisplayed = false
            }
        }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "native_driver")
        channel.setMethodCallHandler(this)
        flutterEngine = binding.flutterEngine
        flutterRenderer = binding.flutterEngine.renderer
        flutterRenderer?.addIsDisplayingFlutterUiListener(displayListener)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        flutterRenderer?.removeIsDisplayingFlutterUiListener(displayListener)
        flutterRenderer = null
        flutterEngine = null
        isFlutterUiDisplayed = false
        for (result in pendingDisplayResults) {
            result.error("DETACHED", "Engine detached before frame was displayed", null)
        }
        pendingDisplayResults.clear()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (call.method == "wait_for_first_frame_displayed") {
            if (isFlutterUiDisplayed || (flutterRenderer?.isDisplayingFlutterUi == true)) {
                isFlutterUiDisplayed = true
                result.success(null)
            } else {
                pendingDisplayResults.add(result)
            }
            return
        }

        val activity = this.activity
        if (activity == null) {
            Log.w(tag, "Received method channel, but no current activity")
            return
        }
        when (call.method) {
            "sdk_version" -> {
                val versionMap = mapOf("version" to Build.VERSION.SDK_INT)
                result.success(versionMap)
            }
            "is_emulator" -> {
                val isEmulator =
                    when {
                        Build.MODEL.contains("gphone") -> true
                        else -> false
                    }
                result.success(mapOf("emulator" to isEmulator))
            }
            "ping" -> {
                result.success(null)
            }
            "get_system_ui_visibility" -> {
                @Suppress("DEPRECATION")
                val flags = activity.window.decorView.systemUiVisibility
                result.success(mapOf("system_ui_visibility" to flags))
            }
            "tap_view" -> {
                // Decode the selector.
                val kind = call.argument<String>("kind")
                lateinit var selector: NativeSelector
                when (kind) {
                    "byNativeAccessibilityLabel" -> {
                        selector = NativeSelector.ByContentDescription(call.argument("label")!!)
                    }
                    "byNativeIntegerId" -> {
                        val stringId = call.argument<String>("id")!!
                        selector = NativeSelector.ByViewId(stringId.toInt())
                    }
                    else -> {
                        result.error("INVALID_SELECTOR", "Not supported", kind)
                        return
                    }
                }

                // Fail if not found.
                val found = selector.find(activity.window.decorView.rootView)
                if (found == null) {
                    result.error("VIEW_NOT_FOUND", "No view was found", call.arguments())
                    return
                }

                // Send tap event.
                val x = found.x + found.width / 2
                val y = found.y + found.height / 2
                val downTime = SystemClock.uptimeMillis()

                val pressDown = MotionEvent.obtain(downTime, downTime, MotionEvent.ACTION_DOWN, x, y, 0)
                found.dispatchTouchEvent(pressDown)
                pressDown.recycle()

                val pressUp = MotionEvent.obtain(downTime, downTime, MotionEvent.ACTION_UP, x, y, 0)
                found.dispatchTouchEvent(pressUp)
                pressUp.recycle()
                result.success(null)
            }
            "resize_flutter_view" -> {
                val flutterView = findFlutterView(activity.window.decorView)
                if (flutterView == null) {
                    result.error("FLUTTER_VIEW_NOT_FOUND", "Could not locate FlutterView", null)
                    return
                }
                val requestedHeight = call.argument<Int>("height")
                val targetHeight =
                    if (requestedHeight == null || requestedHeight <= 0) {
                        ViewGroup.LayoutParams.MATCH_PARENT
                    } else {
                        requestedHeight
                    }
                val params =
                    flutterView.layoutParams
                        ?: ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            targetHeight
                        )
                val alreadyMatches =
                    params.height == targetHeight &&
                        (targetHeight <= 0 || flutterView.height == targetHeight)
                if (alreadyMatches) {
                    result.success(
                        mapOf("width" to flutterView.width, "height" to flutterView.height)
                    )
                    return
                }
                params.height = targetHeight
                flutterView.layoutParams = params
                var completed = false
                val listener =
                    object : View.OnLayoutChangeListener {
                        override fun onLayoutChange(
                            v: View,
                            left: Int,
                            top: Int,
                            right: Int,
                            bottom: Int,
                            oldLeft: Int,
                            oldTop: Int,
                            oldRight: Int,
                            oldBottom: Int
                        ) {
                            if (completed) {
                                return
                            }
                            completed = true
                            v.removeOnLayoutChangeListener(this)
                            result.success(mapOf("width" to v.width, "height" to v.height))
                        }
                    }
                flutterView.addOnLayoutChangeListener(listener)
                flutterView.requestLayout()
            }
            "get_hybrid_composition_state" -> {
                val flutterView = findFlutterView(activity.window.decorView)
                if (flutterView == null) {
                    result.error("FLUTTER_VIEW_NOT_FOUND", "Could not locate FlutterView", null)
                    return
                }
                var flutterSurfaceViewCount = 0
                var surfaceAvailable = false
                var flutterImageViewCount = 0
                var overlayViewCount = 0
                var mutatorViewCount = 0
                var visibleMutatorViewCount = 0
                for (i in 0 until flutterView.childCount) {
                    when (val child = flutterView.getChildAt(i)) {
                        is FlutterSurfaceView -> {
                            flutterSurfaceViewCount++
                            if (child.holder.surface?.isValid == true) {
                                surfaceAvailable = true
                            }
                        }
                        is PlatformOverlayView -> {
                            overlayViewCount++
                        }
                        is FlutterImageView -> {
                            flutterImageViewCount++
                        }
                        is FlutterMutatorView -> {
                            mutatorViewCount++
                            if (child.visibility == View.VISIBLE) {
                                visibleMutatorViewCount++
                            }
                        }
                    }
                }
                val engine = flutterEngine
                val overlayLayerViewsCount =
                    if (engine != null) getOverlayLayerViewsSize(engine) else -1
                result.success(
                    mapOf(
                        "overlayLayerViewsCount" to overlayLayerViewsCount,
                        "isDisplayingFlutterUi" to (flutterRenderer?.isDisplayingFlutterUi == true),
                        "flutterSurfaceViewCount" to flutterSurfaceViewCount,
                        "surfaceAvailable" to surfaceAvailable,
                        "flutterImageViewCount" to flutterImageViewCount,
                        "overlayViewCount" to overlayViewCount,
                        "mutatorViewCount" to mutatorViewCount,
                        "visibleMutatorViewCount" to visibleMutatorViewCount,
                        "flutterViewWidth" to flutterView.width,
                        "flutterViewHeight" to flutterView.height
                    )
                )
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    @SuppressLint("VisibleForTesting")
    private fun getOverlayLayerViewsSize(engine: FlutterEngine): Int = engine.platformViewsController.overlayLayerViews.size()

    private fun findFlutterView(root: View): FlutterView? {
        if (root is FlutterView) {
            return root
        }
        if (root is ViewGroup) {
            for (i in 0 until root.childCount) {
                val match = findFlutterView(root.getChildAt(i))
                if (match != null) {
                    return match
                }
            }
        }
        return null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
