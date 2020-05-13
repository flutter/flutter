// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import android.os.StrictMode;
import io.flutter.app.FlutterApplication;

public class ScenarioApplication extends FlutterApplication {
  @Override
  public void onCreate() {
    StrictMode.setThreadPolicy(
        new StrictMode.ThreadPolicy.Builder()
            .detectDiskReads()
            .detectDiskWrites()
            .penaltyDeath()
            .build());
    super.onCreate();
  }
}
