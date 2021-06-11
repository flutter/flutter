// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.plugins.integration_test;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import androidx.test.platform.app.InstrumentationRegistry;
import java.io.ByteArrayOutputStream;

/** FlutterDeviceScreenshot */
class FlutterDeviceScreenshot {

  /**
   * Captures a screenshot of the device, then it crops the image by the given components.
   *
   * @param x The x component of the crop window.
   * @param y The y component of the crop window.
   * @param width The width component of the crop window.
   * @param height The height component of the crop window.
   * @return byte array containing the cropped image in PNG format.
   */
  static byte[] capture(int x, int y, int width, int height) {
    final Bitmap bitmap =
        InstrumentationRegistry.getInstrumentation().getUiAutomation().takeScreenshot();

    final ByteArrayOutputStream output = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, /* irrelevant for PNG */ 100, output);
    return output.toByteArray();
  }
}
