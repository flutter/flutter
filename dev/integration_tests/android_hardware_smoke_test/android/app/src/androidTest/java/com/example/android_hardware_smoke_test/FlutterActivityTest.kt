// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

import android.graphics.Bitmap
import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.io.ByteArrayOutputStream
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

@RunWith(Parameterized::class)
class FlutterActivityTest(
    private val scenario: TestScenario
) {
    companion object {
        private const val TAG = "FlutterActivityTest"
        private const val SCREENSHOT_CAPTURE_DELAY_MS = 200L
        private const val DIAGNOSTIC_WARNING_DELAY_SEC = 5L
        private const val TEST_TIMEOUT_SEC = 60L

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): Collection<TestScenario> = TestScenario.values().toList()
    }

    @get:Rule val rule = ActivityScenarioRule(MainActivity::class.java)

    /**
     * Common test body for executing a test on the device by sending a command to the Flutter
     * application.
     *
     * Sends a [RenderRequest] over the Pigeon API containing the target scenario and comparison instruction.
     * The test awaits a completed frame render reply up to 60 seconds, logging warning diagnostics
     * if the operation is exceptionally slow.
     *
     * @param scenario The target rendering scenario to execute and compare.
     */
    private fun templateTest(scenario: TestScenario) {
        val testName =
            scenario.name
                .lowercase()
                .split("_")
                .mapIndexed { index, part ->
                    if (index == 0) part else part.replaceFirstChar { it.uppercase() }
                }.joinToString("") + "Test"
        val future = CompletableFuture<String>()

        rule.scenario.onActivity { activity ->
            try {
                // Confirm screen is not locked by checking activity has lifecycle state RESUMED
                assertEquals(Lifecycle.State.RESUMED, activity.lifecycle.currentState)

                val mainActivity = activity as MainActivity
                val api = SmokeTestFlutterApi(mainActivity.engine!!.dartExecutor.binaryMessenger)
                val isPlatformView = testName.startsWith("platformView")
                val request =
                    RenderRequest(
                        scenario = scenario,
                        performAppSideGoldenCompare = !isPlatformView,
                        captureScreenshot = true
                    )

                api.renderTest(request) { result ->
                    result.fold(
                        onSuccess = { reply ->
                            try {
                                if (reply.message == "Skipped") {
                                    val reason = reply.reason ?: "Unsupported"
                                    future.complete("Skipped: $reason")
                                } else if (isPlatformView && reply.message.startsWith("Rendered platformView")) {
                                    val x = reply.x?.toInt() ?: throw IllegalStateException("Expected non-null x coordinate")
                                    val y = reply.y?.toInt() ?: throw IllegalStateException("Expected non-null y coordinate")
                                    val width = reply.width?.toInt() ?: throw IllegalStateException("Expected non-null width")
                                    val height = reply.height?.toInt() ?: throw IllegalStateException("Expected non-null height")

                                    captureAndSendScreenshot(x, y, width, height, scenario, testName, api, future)
                                } else {
                                    future.complete(reply.message)
                                }
                            } catch (e: Exception) {
                                future.completeExceptionally(e)
                            }
                        },
                        onFailure = { error ->
                            future.completeExceptionally(error)
                        }
                    )
                }
            } catch (e: Throwable) {
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
            Log.e(TAG, "$testName Failed to receive result over Pigeon API: ${e.message}")
            throw RuntimeException(e)
        } finally {
            executor.shutdown()
        }

        if (reply.startsWith("Skipped")) {
            Log.w(TAG, "$testName: Skipped - $reply")
            org.junit.Assume.assumeTrue(reply, false)
            return
        }

        if (testName.startsWith("platformView")) {
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
        scenario: TestScenario,
        testName: String,
        api: SmokeTestFlutterApi,
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

                val request = CompareGoldenRequest(scenario, croppedBytes)

                rule.scenario.onActivity { _ ->
                    api.compareGolden(request) { result ->
                        result.fold(
                            onSuccess = { reply ->
                                future.complete(reply.message)
                            },
                            onFailure = { error ->
                                future.completeExceptionally(error)
                            }
                        )
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
    fun runScenario() {
        templateTest(scenario)
    }
}
