// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.flutter;

import android.app.Activity;
import android.view.View;
import androidx.annotation.Keep;

@Keep
public abstract class SensitiveContent {
  // Hide constructor
  private SensitiveContent() {}

  public static void setContentSensitivity(Activity activity, int sensitivityLevel, int viewId) {
    View flutterView = activity.getWindow().getDecorView();
    flutterView.setContentSensitivity(sensitivityLevel);
  }
}
