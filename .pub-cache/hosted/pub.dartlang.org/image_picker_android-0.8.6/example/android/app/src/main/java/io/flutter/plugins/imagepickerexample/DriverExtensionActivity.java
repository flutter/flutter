// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepickerexample;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;

public class DriverExtensionActivity extends FlutterActivity {
  @NonNull
  @Override
  public String getDartEntrypointFunctionName() {
    return "appMain";
  }
}
