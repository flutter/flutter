// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;

public class PlatformViewsActivity extends TestActivity {
  public static final String TEXT_VIEW_PV = "scenarios/textPlatformView";
  public static final String SURFACE_VIEW_PV = "scenarios/surfacePlatformV";
  public static final String TEXTURE_VIEW_PV = "scenarios/texturePlatformV";

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    flutterEngine
        .getPlatformViewsController()
        .getRegistry()
        .registerViewFactory(TEXT_VIEW_PV, new TextPlatformViewFactory());

    flutterEngine
        .getPlatformViewsController()
        .getRegistry()
        .registerViewFactory(SURFACE_VIEW_PV, new SurfacePlatformViewFactory());

    flutterEngine
        .getPlatformViewsController()
        .getRegistry()
        .registerViewFactory(TEXTURE_VIEW_PV, new TexturePlatformViewFactory());
  }
}
