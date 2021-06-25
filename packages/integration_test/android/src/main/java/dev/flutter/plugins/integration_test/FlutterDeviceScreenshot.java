// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.plugins.integration_test;

import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Instrumentation;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.Rect;
import android.graphics.Canvas;
import androidx.annotation.NonNull;
import androidx.test.platform.app.InstrumentationRegistry;
import java.io.ByteArrayOutputStream;
import io.flutter.util.PathUtils;
import java.io.FileOutputStream;
import java.io.File;
import android.content.Context;
import java.io.IOException;
import java.lang.IllegalStateException;
import android.view.View;
import android.view.PixelCopy;
import android.view.ViewGroup;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterImageView;

import android.os.Looper;
import android.os.Handler;
import com.google.common.util.concurrent.SettableFuture;
import java.util.concurrent.Future;
import android.view.Choreographer;

/** FlutterDeviceScreenshot */
@TargetApi(19)
class FlutterDeviceScreenshot {
  static FlutterView getFlutterView(Activity activity) {
    final ViewGroup root = (ViewGroup)activity.findViewById(android.R.id.content);
    return (FlutterView)(((ViewGroup)root.getChildAt(0)).getChildAt(0));
  }

  static boolean hasInstrumentation() {
    try {
      return InstrumentationRegistry.getInstrumentation() != null;
    } catch (IllegalStateException exception) {
      return false;
    }
  }

  /**
   * Captures a screenshot by drawing the view to a Canvas.
   *
   * <p> It also converts {@link FlutterView} to an image view, since {@link FlutterSurfaceView}
   * pixels are opaque when rendering the view to a canvas.
   *
   * @param activity activity the flutter activity. Usually {@link FlutterActivity}.
   * @return byte array containing the screenshot.
   */
  static Future<byte[]> captureView(@NonNull Activity activity) {
    SettableFuture<byte[]> result = SettableFuture.create();

    final FlutterView flutterView = getFlutterView(activity);

    final int[] location = new int[2];
    flutterView.getLocationInWindow(location);
    final Bitmap bitmap = Bitmap.createBitmap(flutterView.getWidth(), flutterView.getHeight(), Bitmap.Config.ARGB_8888);
    PixelCopy.request(
        activity.getWindow(),
        new Rect(location[0], location[1], location[0] + flutterView.getWidth(), location[1] + flutterView.getHeight()),
        bitmap,
        (int copyResult) -> {
          if (copyResult == PixelCopy.SUCCESS) {
            final ByteArrayOutputStream output = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, /* irrelevant for PNG */ 100, output);
            result.set(output.toByteArray());
          }
        },
        new Handler(Looper.getMainLooper()));

    return result;
  }

  /**
   * Captures a screenshot using ui automation.
   *
   * @return byte array containing the screenshot.
   */
  static byte[] captureWithUiAutomation() throws IOException {
    final Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
    final Bitmap originalBitmap = instrumentation.getUiAutomation().takeScreenshot();
    final ByteArrayOutputStream output = new ByteArrayOutputStream();

    originalBitmap.compress(Bitmap.CompressFormat.PNG, /* irrelevant for PNG */ 100, output);
    return output.toByteArray();
  }
}
