// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.demo.gallery;

import android.os.ConditionVariable;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.FlutterView;

/** Instrumentation for testing using Android Espresso framework. */
public class FlutterGalleryInstrumentation implements MethodCallHandler {

  private final ConditionVariable testFinished = new ConditionVariable();
  private volatile boolean testSuccessful;

  FlutterGalleryInstrumentation(FlutterView view) {
    new MethodChannel(view, "io.flutter.demo.gallery/TestLifecycleListener")
        .setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
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
