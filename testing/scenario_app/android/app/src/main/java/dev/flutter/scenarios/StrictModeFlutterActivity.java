// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import android.os.Bundle;
import android.os.StrictMode;
import io.flutter.embedding.android.FlutterActivity;

// TODO: Trigger this activity.
// https://github.com/flutter/flutter/issues/60635
public class StrictModeFlutterActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    StrictMode.setThreadPolicy(
        new StrictMode.ThreadPolicy.Builder()
            .detectDiskReads()
            .detectDiskWrites()
            .penaltyDeath()
            .build());
    super.onCreate(savedInstanceState);
  }
}
