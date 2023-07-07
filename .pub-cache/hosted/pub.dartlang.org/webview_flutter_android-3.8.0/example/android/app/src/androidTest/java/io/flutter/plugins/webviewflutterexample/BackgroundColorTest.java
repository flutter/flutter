// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutterexample;

import static androidx.test.espresso.flutter.EspressoFlutter.onFlutterWidget;
import static androidx.test.espresso.flutter.action.FlutterActions.click;
import static androidx.test.espresso.flutter.matcher.FlutterMatchers.withText;
import static androidx.test.espresso.flutter.matcher.FlutterMatchers.withValueKey;
import static org.junit.Assert.assertEquals;

import android.graphics.Bitmap;
import android.graphics.Color;
import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.rule.ActivityTestRule;
import androidx.test.runner.screenshot.ScreenCapture;
import androidx.test.runner.screenshot.Screenshot;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class BackgroundColorTest {
  @Rule
  public ActivityTestRule<DriverExtensionActivity> myActivityTestRule =
      new ActivityTestRule<>(DriverExtensionActivity.class, true, false);

  @Before
  public void setUp() {
    ActivityScenario.launch(DriverExtensionActivity.class);
  }

  @Ignore("Doesn't run in Firebase Test Lab: https://github.com/flutter/flutter/issues/94748")
  @Test
  public void backgroundColor() {
    onFlutterWidget(withValueKey("ShowPopupMenu")).perform(click());
    onFlutterWidget(withValueKey("ShowTransparentBackgroundExample")).perform(click());
    onFlutterWidget(withText("Transparent background test"));

    final ScreenCapture screenCapture = Screenshot.capture();
    final Bitmap screenBitmap = screenCapture.getBitmap();

    final int centerLeftColor =
        screenBitmap.getPixel(10, (int) Math.floor(screenBitmap.getHeight() / 2.0));
    final int centerColor =
        screenBitmap.getPixel(
            (int) Math.floor(screenBitmap.getWidth() / 2.0),
            (int) Math.floor(screenBitmap.getHeight() / 2.0));

    // Flutter Colors.green color : 0xFF4CAF50
    // https://github.com/flutter/flutter/blob/f4abaa0735eba4dfd8f33f73363911d63931fe03/packages/flutter/lib/src/material/colors.dart#L1208
    // The background color of the webview is : rgba(0, 0, 0, 0.5)
    // The expected color is : rgba(38, 87, 40, 1) -> 0xFF265728
    assertEquals(0xFF265728, centerLeftColor);
    assertEquals(Color.RED, centerColor);
  }
}
