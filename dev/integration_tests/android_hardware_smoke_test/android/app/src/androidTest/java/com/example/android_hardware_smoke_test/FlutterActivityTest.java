// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.android_hardware_smoke_test;

import static junit.framework.TestCase.assertEquals;

import android.util.Log;
import androidx.lifecycle.Lifecycle;
import androidx.test.ext.junit.rules.ActivityScenarioRule;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Assert;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterActivityTest
{
  private static final String TAG = "FlutterActivityTest";

  /**
   * This timeout represents the time it takes for the flutter app to render one frame and reply
   * after a test sends a message over the channel.
   */
  private static final int MESSAGE_CHANNEL_RESPONSE_TIMEOUT_MS = 1000;

  /**
   * The timeout for each test. This should be strictly larger than MESSAGE_CHANNEL_RESPONSE_TIMEOUT_MS.
    */
  private static final int TEST_TIMEOUT_MS = 3000;

  @Rule
  public ActivityScenarioRule<MainActivity> rule =
      new ActivityScenarioRule<>(MainActivity.class);

  private void templateTest(String testName) {
    Log.d(TAG, "Starting "+testName);
    CompletableFuture<String> future = new CompletableFuture<>();

    rule.getScenario().onActivity(activity -> {
      // Confirm screen is not locked by checking activity has lifecycle state RESUMED.
      // If the screen were locked, flutter would never return a reply over the message channel.
      Assert.assertEquals(Lifecycle.State.RESUMED, activity.getLifecycle().getCurrentState());

      // Send a message to the flutter app telling it which test state to enter.
      // Place the reply into the future.
      Log.d(TAG, "Sending '"+testName+"' on message channel");
      try {
        JSONObject message = new JSONObject();
        message.put("testName", testName);
        message.put("performAppSideGoldenCompare", true);
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


    String reply = null;
    try {
      reply = future.get(MESSAGE_CHANNEL_RESPONSE_TIMEOUT_MS, TimeUnit.MILLISECONDS);
    } catch (ExecutionException e) {
      Log.e(TAG, testName+" Failed to receive result on message channel, ExecutionException " + e.getMessage());
      throw new RuntimeException(e);
    } catch (InterruptedException e) {
      Log.e(TAG, testName+"  Failed to receive result on message channel, InterruptedException " + e.getMessage());
      throw new RuntimeException(e);
    } catch (TimeoutException e) {
      Log.e(TAG, testName+" Failed to receive result on message channel, TimeoutException " + e.getMessage());
      throw new RuntimeException(e);
    }

    Log.d(TAG, "Received "+reply+" on message channel");
    assertEquals("Rendered "+testName, reply);
  }

  @Test(timeout = TEST_TIMEOUT_MS)
  public void blueRectangleTest() {
    templateTest("blueRectangleTest");
  }

  @Test(timeout = TEST_TIMEOUT_MS)
  public void trianglePathTest() {
    templateTest("trianglePathTest");
  }


}
