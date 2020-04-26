// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.splash_screen_load_rotate;

import android.content.Context;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.SplashScreen;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.view.FlutterMain;

public class MainActivity extends FlutterActivity {
  private static FlutterEngine flutterEngine;

  /**
   * We explicitly provide a {@code FlutterEngine} so that every rotation does not create a
   * new FlutterEngine. Creating a new FlutterEngine on every orientation would cause the
   * splash experience to restart upon every orientation change, which is not what we're
   * interested in verifying in this example app.
   */
  @Override
  public FlutterEngine provideFlutterEngine(Context context) {
    if (flutterEngine == null) {
      flutterEngine = new FlutterEngine(context);

      flutterEngine.getDartExecutor().executeDartEntrypoint(new DartExecutor.DartEntrypoint(
          getAssets(),
          FlutterMain.findAppBundlePath(context),
          "main"
      ));
    }
    return flutterEngine;
  }

  @Override
  public SplashScreen provideSplashScreen() {
    return new SplashScreenThatNeverEnds();
  }
}
