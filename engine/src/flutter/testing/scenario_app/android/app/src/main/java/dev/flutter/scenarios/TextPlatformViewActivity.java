// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import io.flutter.embedding.engine.FlutterEngine;

public class TextPlatformViewActivity extends TestActivity {
  static final String TAG = "Scenarios";

  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    flutterEngine
        .getPlatformViewsController()
        .getRegistry()
        .registerViewFactory("scenarios/textPlatformView", new TextPlatformViewFactory());
  }
}
