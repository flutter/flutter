// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.android_verified_input;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.dart.DartExecutor;

public class MainActivity extends FlutterActivity {
  public static MethodChannel mMethodChannel;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    DartExecutor executor = flutterEngine.getDartExecutor();

    // Configuring AdView to call adservices APIs
    flutterEngine
        .getPlatformViewsController()
        .getRegistry()
        .registerViewFactory("verified-input-view", new VerifiedInputViewFactory());

    mMethodChannel = new MethodChannel(executor, "verified_input_test");
  }
}
