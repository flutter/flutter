// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import android.graphics.Bitmap;
import androidx.annotation.Nullable;

public class GetBitmapActivity extends TestActivity {

  @Nullable private volatile Bitmap bitmap;

  @Nullable
  public Bitmap getBitmap() {
    waitUntilFlutterRendered();
    return bitmap;
  }

  @Nullable
  protected void notifyFlutterRendered() {
    bitmap = getFlutterEngine().getRenderer().getBitmap();
    super.notifyFlutterRendered();
  }
}
