// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.graphics.Bitmap
import android.util.Base64
import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.flutter.embedding.engine.FlutterEngineCache
import org.json.JSONObject
import org.junit.AfterClass
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.ByteArrayOutputStream
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
class FlutterActivityTest {
    companion object {
        private const val TAG = "FlutterActivityTest"
        private const val SCREENSHOT_CAPTURE_DELAY_MS = 200L
        private const val DIAGNOSTIC_WARNING_DELAY_SEC = 5L
        private const val TEST_TIMEOUT_SEC = 60L

        @JvmStatic
        @AfterClass
        fun tearDownClass() {
            InstrumentationRegistry.getInstrumentation().runOnMainSync {
                val engine = FlutterEngineCache.getInstance().get("smoke_test_engine")
                engine?.destroy()
                FlutterEngineCache.getInstance().remove("smoke_test_engine")
            }
        }
    }

    @get:Rule val rule = ActivityScenarioRule(MainActivity::class.java)

    /**
     * Common test body for executing a test on the device by sending a command to the Flutter
     * application.
     *
     * Sends a JSON message over the [BasicMessageChannel] containing the [testName] and an
     * on-device comparison request instruction. The test awaits a completed frame render reply up
     * to 60 seconds, logging warning diagnostics if the operation is exceptionally slow.
     *
     * @param testName The descriptive identifier of the test case to render and compare.
     */
    private fun templateTest(testName: String) {
        Log.d(TAG, "Starting $testName")
        val future = CompletableFuture<String>()

        rule.scenario.onActivity { activity ->
            // Confirm screen is not locked by checking activity has lifecycle state RESUMED
            assertEquals(Lifecycle.State.RESUMED, activity.lifecycle.currentState)

            try {
                val isPlatformView = testName.startsWith(Constants.PLATFORM_VIEW_PREFIX)
                val message =
                    JSONObject().apply {
                        put(Constants.KEY_TEST_NAME, testName)
                        put(Constants.KEY_PERFORM_APP_SIDE_GOLDEN_COMPARE, !isPlatformView)
                    }

                Log.d(TAG, "Sending '$message' on message channel")

                activity.messageChannel?.send(message) { reply ->
                    try {
                        val replyJson =
                            reply as? JSONObject
                                ?: throw IllegalStateException("Expected JSONObject reply from Dart, but received: $reply")
                        val replyMessage = replyJson.getString(Constants.KEY_MESSAGE)

                        if (replyMessage == "Skipped") {
                            val reason = replyJson.optString(Constants.KEY_REASON, "Unsupported")
                            future.complete("Skipped: $reason")
                        } else if (isPlatformView && replyMessage.startsWith("Rendered ${Constants.PLATFORM_VIEW_PREFIX}")) {
                            val x = replyJson.getInt(Constants.KEY_X)
                            val y = replyJson.getInt(Constants.KEY_Y)
                            val width = replyJson.getInt(Constants.KEY_WIDTH)
                            val height = replyJson.getInt(Constants.KEY_HEIGHT)

                            captureAndSendScreenshot(x, y, width, height, testName, future)
                        } else {
                            future.complete(replyMessage)
                        }
                    } catch (e: Exception) {
                        future.completeExceptionally(e)
                    }
                }
            } catch (e: Exception) {
                future.completeExceptionally(e)
            }
        }

        // Schedule a diagnostic warning log if the rendering is exceptionally slow
        val executor = Executors.newSingleThreadScheduledExecutor()
        executor.schedule(
            {
                if (!future.isDone) {
                    Log.w(
                        TAG,
                        "Rendering '$testName' is taking longer than expected (exceeded $DIAGNOSTIC_WARNING_DELAY_SEC seconds)..."
                    )
                }
            },
            DIAGNOSTIC_WARNING_DELAY_SEC,
            TimeUnit.SECONDS
        )

        val reply: String
        try {
            // Wait with a very generous timeout to catch true deadlocks/crashes
            reply = future.get(TEST_TIMEOUT_SEC, TimeUnit.SECONDS)
        } catch (e: Exception) {
            Log.e(TAG, "$testName Failed to receive result on message channel: ${e.message}")
            throw RuntimeException(e)
        } finally {
            executor.shutdown()
        }

        Log.d(TAG, "Received $reply on message channel")
        if (reply.startsWith("Skipped")) {
            Log.w(TAG, "$testName: Skipped - $reply")
            org.junit.Assume.assumeTrue(reply, false)
            return
        }

        if (testName.startsWith(Constants.PLATFORM_VIEW_PREFIX)) {
            assertEquals("Comparison Success", reply)
        } else {
            assertEquals("Rendered $testName", reply)
        }
    }

    private fun captureAndSendScreenshot(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        testName: String,
        future: CompletableFuture<String>
    ) {
        // Capture the screenshot on a background thread with a short delay. We must NOT sleep or capture
        // on the Main UI Thread to avoid blocking frame rendering or causing an ANR.
        val screenshotExecutor = Executors.newSingleThreadScheduledExecutor()
        screenshotExecutor.schedule({
            try {
                // Capture the true screen output using UiAutomation from this privileged instrumentation runner process.
                val instrumentation = InstrumentationRegistry.getInstrumentation()
                val screenshot =
                    instrumentation.uiAutomation.takeScreenshot()
                        ?: throw IllegalStateException("UiAutomation.takeScreenshot() returned null")

                if (x < 0 ||
                    y < 0 ||
                    width <= 0 ||
                    height <= 0 ||
                    x + width > screenshot.width ||
                    y + height > screenshot.height
                ) {
                    throw IllegalArgumentException(
                        "Crop bounds out of range: x=$x, y=$y, width=$width, height=$height, screenshot.width=${screenshot.width}, screenshot.height=${screenshot.height}"
                    )
                }

                // Crop the full-screen screenshot to the exact widget bounds.
                val cropped = Bitmap.createBitmap(screenshot, x, y, width, height)
                if (cropped != screenshot) {
                    screenshot.recycle()
                }

                val stream = ByteArrayOutputStream()
                try {
                    cropped.compress(Bitmap.CompressFormat.PNG, 100, stream)
                } finally {
                    cropped.recycle()
                }
                val croppedBytes = stream.toByteArray()
                val base64Image = Base64.encodeToString(croppedBytes, Base64.NO_WRAP)

                val compareMsg =
                    JSONObject().apply {
                        put(Constants.KEY_COMMAND, Constants.COMMAND_COMPARE_GOLDEN)
                        put(Constants.KEY_TEST_NAME, testName)
                        put(Constants.KEY_IMAGE_BYTES, base64Image)
                    }

                Log.d(TAG, "Sending compare_golden request to Dart app")
                // Send the cropped PNG bytes back to Dart so all golden comparisons are resolved via Dart's matchesGoldenFile.
                rule.scenario.onActivity { mainActivity ->
                    mainActivity.messageChannel?.send(compareMsg) { compareReply ->
                        try {
                            val compareReplyJson =
                                compareReply as? JSONObject
                                    ?: throw IllegalStateException(
                                        "Expected JSONObject reply from compare_golden request, but received: $compareReply"
                                    )
                            future.complete(compareReplyJson.getString(Constants.KEY_MESSAGE))
                        } catch (e: Exception) {
                            future.completeExceptionally(e)
                        }
                    }
                }
            } catch (e: Exception) {
                future.completeExceptionally(e)
            } finally {
                screenshotExecutor.shutdown()
            }
        }, SCREENSHOT_CAPTURE_DELAY_MS, TimeUnit.MILLISECONDS)
    }

    @Test
    fun blueRectangleTest() {
        templateTest(Constants.BLUE_RECTANGLE_TEST)
    }

    @Test
    fun trianglePathTest() {
        templateTest(Constants.TRIANGLE_PATH_TEST)
    }

    @Test
    fun textTest() {
        templateTest(Constants.TEXT_TEST)
    }

    @Test
    fun imageTest() {
        templateTest(Constants.IMAGE_TEST)
    }

    @Test
    fun advancedBlendTest() {
        templateTest(Constants.ADVANCED_BLEND_TEST)
    }

    @Test
    fun backdropFilterBlurTest() {
        templateTest(Constants.BACKDROP_FILTER_BLUR_TEST)
    }

    @Test
    fun platformViewTextureLayerTest() {
        templateTest(Constants.PLATFORM_VIEW_TEXTURE_LAYER_TEST)
    }

    @Test
    fun platformViewHybridCompositionTest() {
        templateTest(Constants.PLATFORM_VIEW_HYBRID_COMPOSITION_TEST)
    }

    @Test
    fun platformViewHybridCompositionPlusPlusTest() {
        templateTest(Constants.PLATFORM_VIEW_HYBRID_COMPOSITION_PLUS_PLUS_TEST)
    }
}
