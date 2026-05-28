// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.android_hardware_smoke_test;

import static org.junit.Assert.assertEquals;

import android.util.Log;
import androidx.lifecycle.Lifecycle;
import androidx.test.ext.junit.rules.ActivityScenarioRule;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Assert;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterActivityTest {
  private static final String TAG = "FlutterActivityTest";

  @Rule
  public ActivityScenarioRule<MainActivity> rule =
      new ActivityScenarioRule<>(MainActivity.class);

  private void templateTest(String testName) {
    Log.d(TAG, "Starting " + testName);
    CompletableFuture<String> future = new CompletableFuture<>();

    rule.getScenario().onActivity(activity -> {
      // Confirm screen is not locked by checking activity has lifecycle state RESUMED.
      // If the screen were locked, flutter would never return a reply over the message channel.
      Assert.assertEquals(Lifecycle.State.RESUMED, activity.getLifecycle().getCurrentState());

      // Send a message to the flutter app telling it which test state to enter.
      // Place the reply into the future.
      try {
        JSONObject message = new JSONObject();
        message.put("testName", testName);
        message.put("performAppSideGoldenCompare", true);

        Log.d(TAG, "Sending '" + message.toString() + "' on message channel");

        activity.messageChannel.send(message, reply -> {
          try {
            JSONObject replyJson = (JSONObject) reply;
            future.complete(replyJson.getString("message"));
          } catch (Exception e) {
            future.completeExceptionally(e);
          }
        });
      } catch (JSONException e) {
        future.completeExceptionally(e);
      }
    });

    // Schedule a diagnostic warning log if the rendering is exceptionally slow
    ScheduledExecutorService executor = Executors.newSingleThreadScheduledExecutor();
    java.util.concurrent.ScheduledFuture<?> warningTask = executor.schedule(() -> {
      if (!future.isDone()) {
        Log.w(TAG, "Rendering '" + testName + "' is taking longer than expected (exceeded 5 seconds)...");
      }
    }, 5, TimeUnit.SECONDS);

    String reply = null;
    try {
      // Wait with a very generous 60-second timeout to catch true deadlocks/crashes
      reply = future.get(60, TimeUnit.SECONDS);
    } catch (Exception e) {
      Log.e(TAG, testName + " Failed to receive result on message channel: " + e.getMessage());
      throw new RuntimeException(e);
    } finally {
      warningTask.cancel(true);
      executor.shutdown();
    }

    Log.d(TAG, "Received " + reply + " on message channel");
    assertEquals("Rendered " + testName, reply);
  }

  @Test
  public void blueRectangleTest() {
    templateTest("blueRectangleTest");
  }

  @Test
  public void trianglePathTest() {
    templateTest("trianglePathTest");
  }


}
