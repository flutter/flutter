// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.demo.gallery;

import android.os.ConditionVariable;
import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** Instrumentation for testing using Android Espresso framework. */
public class FlutterGalleryInstrumentation implements MethodCallHandler {
  private final ConditionVariable testFinished = new ConditionVariable();
  private volatile boolean testSuccessful;

  FlutterGalleryInstrumentation(@NonNull BinaryMessenger messenger) {
    new MethodChannel(messenger, "io.flutter.demo.gallery/TestLifecycleListener")
        .setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    testSuccessful = call.method.equals("success");
    testFinished.open();
    result.success(null);
  }

  public boolean isTestSuccessful() {
    return testSuccessful;
  }

  public void waitForTestToFinish() throws Exception {
    testFinished.block();
  }
}
