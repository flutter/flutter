// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.android_hardware_smoke_test

import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
class FlutterActivityTest {
    companion object {
        private const val TAG = "FlutterActivityTest"
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
                val message =
                    JSONObject().apply {
                        put("testName", testName)
                        put("performAppSideGoldenCompare", true)
                    }

                Log.d(TAG, "Sending '$message' on message channel")

                activity.messageChannel?.send(message) { reply ->
                    try {
                        val replyJson = reply as JSONObject
                        future.complete(replyJson.getString("message"))
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
                        "Rendering '$testName' is taking longer than expected (exceeded 5 seconds)..."
                    )
                }
            },
            5,
            TimeUnit.SECONDS
        )

        val reply: String
        try {
            // Wait with a very generous 60-second timeout to catch true deadlocks/crashes
            reply = future.get(60, TimeUnit.SECONDS)
        } catch (e: Exception) {
            Log.e(TAG, "$testName Failed to receive result on message channel: ${e.message}")
            throw RuntimeException(e)
        } finally {
            executor.shutdown()
        }

        Log.d(TAG, "Received $reply on message channel")
        assertEquals("Rendered $testName", reply)
    }

    @Test
    fun blueRectangleTest() {
        templateTest("blueRectangleTest")
    }

    @Test
    fun trianglePathTest() {
        templateTest("trianglePathTest")
    }

    @Test
    fun textTest() {
        templateTest("textTest")
    }
}
