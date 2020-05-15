// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenariosui;

import android.content.Intent;
import androidx.test.filters.LargeTest;
import androidx.test.rule.ActivityTestRule;
import androidx.test.runner.AndroidJUnit4;
import dev.flutter.scenarios.TextPlatformViewActivity;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
@LargeTest
public class PlatformViewUiTests {
  Intent intent;

  @Rule
  public ActivityTestRule<TextPlatformViewActivity> activityRule =
      new ActivityTestRule<>(
          TextPlatformViewActivity.class, /*initialTouchMode=*/ false, /*launchActivity=*/ false);

  @Before
  public void setUp() {
    intent = new Intent(Intent.ACTION_MAIN);
    // Render a native android view.
    intent.putExtra("use_android_view", true);
  }

  @Test
  public void testPlatformView() throws Exception {
    intent.putExtra("scenario", "platform_view");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewMultiple() throws Exception {
    intent.putExtra("scenario", "platform_view_multiple");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewMultipleBackgroundForeground() throws Exception {
    intent.putExtra("scenario", "platform_view_multiple_background_foreground");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewCliprect() throws Exception {
    intent.putExtra("scenario", "platform_view_cliprect");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewCliprrect() throws Exception {
    intent.putExtra("scenario", "platform_view_cliprrect");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewClippath() throws Exception {
    intent.putExtra("scenario", "platform_view_clippath");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewTransform() throws Exception {
    intent.putExtra("scenario", "platform_view_transform");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewOpacity() throws Exception {
    intent.putExtra("scenario", "platform_view_opacity");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewRotate() throws Exception {
    intent.putExtra("scenario", "platform_view_rotate");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewMultipleWithoutOverlays() throws Exception {
    intent.putExtra("scenario", "platform_view_multiple_without_overlays");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }

  @Test
  public void testPlatformViewTwoIntersectingOverlays() throws Exception {
    intent.putExtra("scenario", "platform_view_two_intersecting_overlays");
    ScreenshotUtil.capture(activityRule.launchActivity(intent));
  }
}
