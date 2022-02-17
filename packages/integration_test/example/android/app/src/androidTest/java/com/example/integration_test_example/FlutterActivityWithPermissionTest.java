// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.integration_test_example;

import android.Manifest.permission;
import androidx.test.rule.ActivityTestRule;
import androidx.test.rule.GrantPermissionRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import io.flutter.embedding.android.FlutterActivity;
import org.junit.Rule;
import org.junit.runner.RunWith;

/**
 * Demonstrates how an integration test on Android can be run with permissions already granted. This
 * is helpful if developers want to test native App behavior that depends on certain system service
 * results which are guarded with permissions.
 */
@RunWith(FlutterTestRunner.class)
public class FlutterActivityWithPermissionTest {

  @Rule
  public GrantPermissionRule permissionRule =
      GrantPermissionRule.grant(permission.ACCESS_COARSE_LOCATION);

  @Rule
  public ActivityTestRule<FlutterActivity> rule =
      new ActivityTestRule<>(FlutterActivity.class, true, false);
}
