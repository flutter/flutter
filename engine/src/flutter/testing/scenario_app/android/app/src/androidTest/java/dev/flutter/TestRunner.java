// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter;

import android.os.Bundle;
import androidx.test.runner.AndroidJUnitRunner;
import dev.flutter.scenariosui.ScreenshotUtil;

public class TestRunner extends AndroidJUnitRunner {
  @Override
  public void onCreate(Bundle arguments) {
    ScreenshotUtil.onCreate(this, arguments);
    super.onCreate(arguments);
  }

  @Override
  public void finish(int resultCode, Bundle results) {
    ScreenshotUtil.onDestroy();
    super.finish(resultCode, results);
  }
}
