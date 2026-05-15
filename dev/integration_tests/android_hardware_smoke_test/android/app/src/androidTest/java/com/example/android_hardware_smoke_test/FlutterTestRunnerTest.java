// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.android_hardware_smoke_test;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

@RunWith(FlutterTestRunner.class)
public class FlutterTestRunnerTest
{
  @Rule
  public ActivityTestRule<MainActivity> rule =
    new ActivityTestRule<>(MainActivity.class, true, false);
}
