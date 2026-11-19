// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Isolated `FlutterActivity` that renders the animated teardown stress scenario and immediately
 * calls `finish()` so `FlutterEngine.destroy()` runs while frames are in flight.
 *
 * Runs in `:engine_teardown` so that if [FlutterEngine.destroy] deadlocks the main thread inside
 * the graphics driver, the instrumentation runner in the primary process stays responsive and can
 * fail the test promptly.
 */
class EngineTeardownActivity : FlutterActivity() {
    companion object {
        private const val TAG = "EngineTeardownActivity"
        internal const val ACTION_RENDERED =
            "com.example.android_hardware_smoke_test.ENGINE_TEARDOWN_RENDERED"
        internal const val ACTION_DESTROYING =
            "com.example.android_hardware_smoke_test.ENGINE_TEARDOWN_DESTROYING"
        internal const val ACTION_DESTROYED =
            "com.example.android_hardware_smoke_test.ENGINE_TEARDOWN_DESTROYED"
        internal const val EXTRA_CYCLE = "cycle"
        internal const val EXTRA_ERROR = "error"
    }

    private var messageChannel: BasicMessageChannel<Any>? = null
    private var methodChannel: MethodChannel? = null
    private var testDispatched = false
    private var renderedSent = false
    private var cycle = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.setFormat(PixelFormat.RGBA_8888)
        cycle = intent.getIntExtra(EXTRA_CYCLE, 0)
        super.onCreate(savedInstanceState)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        messageChannel =
            BasicMessageChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                MainActivity.CHANNEL_NAME,
                JSONMessageCodec.INSTANCE
            )
        methodChannel =
            MainActivity.createNativeSupportChannel(
                flutterEngine,
                MainActivity.readImpellerBackend(this)
            )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        messageChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        if (testDispatched) {
            return
        }
        testDispatched = true

        val message =
            JSONObject().apply {
                put("testName", "engineTeardownTest")
                put("captureScreenshot", false)
                put("performAppSideGoldenCompare", false)
            }

        Log.i(TAG, "Cycle $cycle: dispatching engineTeardownTest")
        messageChannel?.send(message) { reply ->
            val replyMessage = (reply as? JSONObject)?.optString("message", "")
            val error =
                if (replyMessage == "Rendered engineTeardownTest") {
                    null
                } else {
                    "Unexpected reply: $reply"
                }
            renderedSent = true
            sendBroadcast(
                Intent(ACTION_RENDERED).apply {
                    setPackage(packageName)
                    addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                    putExtra(EXTRA_CYCLE, cycle)
                    if (error != null) {
                        putExtra(EXTRA_ERROR, error)
                    }
                }
            )
            finish()
        }
    }

    override fun onDestroy() {
        val shouldNotifyTeardown = renderedSent && !isChangingConfigurations
        if (shouldNotifyTeardown) {
            sendBroadcast(
                Intent(ACTION_DESTROYING).apply {
                    setPackage(packageName)
                    addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                    putExtra(EXTRA_CYCLE, cycle)
                }
            )
        }
        Log.i(TAG, "Cycle $cycle: calling super.onDestroy() (destroying FlutterEngine)")
        super.onDestroy()
        Log.i(TAG, "Cycle $cycle: super.onDestroy() returned")
        if (shouldNotifyTeardown) {
            sendBroadcast(
                Intent(ACTION_DESTROYED).apply {
                    setPackage(packageName)
                    addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                    putExtra(EXTRA_CYCLE, cycle)
                }
            )
        }
    }
}
