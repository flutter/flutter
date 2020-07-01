// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import static org.junit.Assert.fail;

import android.content.Context;
import androidx.test.InstrumentationRegistry;
import androidx.test.internal.runner.junit4.statement.UiThreadStatement;
import androidx.test.runner.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import java.util.Arrays;
import java.util.Locale;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class EngineLaunchE2ETest {
  @Test
  public void smokeTestEngineLaunch() throws Throwable {
    Context applicationContext = InstrumentationRegistry.getTargetContext();
    // Specifically, create the engine without running FlutterMain first.
    final AtomicReference<FlutterEngine> engine = new AtomicReference<>();

    // Run the production under test on the UI thread instead of annotating the whole test
    // as @UiThreadTest because having the message handler and the CompletableFuture both being
    // on the same thread will create deadlocks.
    UiThreadStatement.runOnUiThread(() -> engine.set(new FlutterEngine(applicationContext)));
    CompletableFuture<Boolean> statusReceived = new CompletableFuture<>();

    // Resolve locale to `en_US`.
    // This is required, so `window.locale` in populated in dart.
    // TODO: Fix race condition between sending this over the channel and starting the entrypoint.
    // https://github.com/flutter/flutter/issues/55999
    UiThreadStatement.runOnUiThread(
        () -> engine.get().getLocalizationChannel().sendLocales(Arrays.asList(Locale.US)));

    // The default Dart main entrypoint sends back a platform message on the "waiting_for_status"
    // channel. That will be our launch success assertion condition.
    engine
        .get()
        .getDartExecutor()
        .setMessageHandler(
            "waiting_for_status",
            (byteBuffer, binaryReply) -> statusReceived.complete(Boolean.TRUE));

    // Launching the entrypoint will run the Dart code that sends the "waiting_for_status" platform
    // message.
    UiThreadStatement.runOnUiThread(
        () ->
            engine
                .get()
                .getDartExecutor()
                .executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault()));

    try {
      Boolean result = statusReceived.get(10, TimeUnit.SECONDS);
      if (!result) {
        fail("expected message on waiting_for_status not received");
      }
    } catch (ExecutionException e) {
      fail(e.getMessage());
    } catch (InterruptedException e) {
      fail(e.getMessage());
    } catch (TimeoutException e) {
      fail("timed out waiting for engine started signal");
    }
    // If it gets to here, statusReceived is true.
  }
}
