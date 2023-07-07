// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.pathprovider;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugins.DartIntegrationTest;
import org.junit.Rule;
import org.junit.runner.RunWith;

@DartIntegrationTest
@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule
  public ActivityTestRule<FlutterActivity> rule = new ActivityTestRule<>(FlutterActivity.class);
}
