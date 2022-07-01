// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenariosui;

import android.content.Intent;
import android.graphics.Rect;
import android.os.Build.VERSION_CODES;
import androidx.annotation.NonNull;
import androidx.test.filters.LargeTest;
import androidx.test.filters.SdkSuppress;
import androidx.test.rule.ActivityTestRule;
import androidx.test.runner.AndroidJUnit4;
import dev.flutter.scenarios.ExternalTextureFlutterActivity;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
@LargeTest
@Ignore("Test had flakes in Skia Gold image matching.")
public class ExternalTextureTests {
  private static final int SURFACE_WIDTH = 192;
  private static final int SURFACE_HEIGHT = 256;

  Intent intent;

  @Rule @NonNull
  public ActivityTestRule<ExternalTextureFlutterActivity> activityRule =
      new ActivityTestRule<>(
          ExternalTextureFlutterActivity.class,
          /*initialTouchMode=*/ false,
          /*launchActivity=*/ false);

  @Before
  public void setUp() {
    intent = new Intent(Intent.ACTION_MAIN);
  }

  @Test
  public void testCanvasSurface() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "canvas");
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent), "ExternalTextureTests_testCanvasSurface");
  }

  @Test
  @SdkSuppress(minSdkVersion = VERSION_CODES.LOLLIPOP)
  public void testMediaSurface() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "media");
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent), "ExternalTextureTests_testMediaSurface");
  }

  @Test
  @SdkSuppress(minSdkVersion = VERSION_CODES.LOLLIPOP)
  public void testRotatedMediaSurface_90() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "media");
    intent.putExtra("rotation", 90);
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent), "ExternalTextureTests_testRotatedMediaSurface_90");
  }

  @Test
  @SdkSuppress(minSdkVersion = VERSION_CODES.LOLLIPOP)
  public void testRotatedMediaSurface_180() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "media");
    intent.putExtra("rotation", 180);
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent), "ExternalTextureTests_testRotatedMediaSurface_180");
  }

  @Test
  @SdkSuppress(minSdkVersion = VERSION_CODES.LOLLIPOP)
  public void testRotatedMediaSurface_270() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "media");
    intent.putExtra("rotation", 270);
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent), "ExternalTextureTests_testRotatedMediaSurface_270");
  }

  @Test
  @SdkSuppress(minSdkVersion = VERSION_CODES.M)
  public void testCroppedMediaSurface_bottomLeft() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "image");
    intent.putExtra("crop", new Rect(0, 0, SURFACE_WIDTH / 2, SURFACE_HEIGHT / 2));
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent),
        "ExternalTextureTests_testCroppedMediaSurface_bottomLeft");
  }

  @Test
  @SdkSuppress(minSdkVersion = VERSION_CODES.M)
  public void testCroppedMediaSurface_topRight() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "image");
    intent.putExtra(
        "crop", new Rect(SURFACE_WIDTH / 2, SURFACE_HEIGHT / 2, SURFACE_WIDTH, SURFACE_HEIGHT));
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent),
        "ExternalTextureTests_testCroppedMediaSurface_topRight");
  }

  @Test
  @SdkSuppress(minSdkVersion = VERSION_CODES.M)
  public void testCroppedRotatedMediaSurface_bottomLeft_90() throws Exception {
    intent.putExtra("scenario_name", "display_texture");
    intent.putExtra("surface_renderer", "image");
    intent.putExtra("crop", new Rect(0, 0, SURFACE_WIDTH / 2, SURFACE_HEIGHT / 2));
    intent.putExtra("rotation", 90);
    ScreenshotUtil.capture(
        activityRule.launchActivity(intent),
        "ExternalTextureTests_testCroppedRotatedMediaSurface_bottomLeft_90");
  }
}
