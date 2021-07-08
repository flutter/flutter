// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.plugins.integration_test;

import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Instrumentation;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.view.Choreographer;
import android.view.PixelCopy;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.test.platform.app.InstrumentationRegistry;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.lang.StringBuilder;

/** FlutterDeviceScreenshot */
@TargetApi(19)
class FlutterDeviceScreenshot {
  /**
   * Whether the app is run with instrumentation.
   *
   * @return true if the app is running with instrumentation.
   */
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
   * <p>It also converts {@link FlutterView} to an image view, since {@link FlutterSurfaceView}
   * pixels are opaque when rendering the view to a canvas.
   *
   * @param activity This is {@link FlutterActivity}.
   * @param methodChannel The method channel to call into Dart.
   * @param result The result of the method call that came from Dart.
   */
  static void captureView(
      @NonNull Activity activity, @NonNull MethodChannel methodChannel, @NonNull Result result) {
    final FlutterView flutterView = getFlutterView(activity);
    flutterView.convertToImageView();
    methodChannel.invokeMethod("scheduleFrame", null);

    final HandlerThread screenshotBackgroundThread = new HandlerThread("screenshot");
    screenshotBackgroundThread.start();

    final Handler backgroundHandler = new Handler(screenshotBackgroundThread.getLooper());
    final Handler mainHandler = new Handler(Looper.getMainLooper());

    takeScreenshot(backgroundHandler, mainHandler, flutterView, result);
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

  private static FlutterView getFlutterView(Activity activity) {
    final ViewGroup root = (ViewGroup) activity.findViewById(android.R.id.content);
    return (FlutterView) (((ViewGroup) root.getChildAt(0)).getChildAt(0));
  }

  private static void waitForAndroidFrame(Runnable r) {
    Choreographer.getInstance()
        .postFrameCallback(
            new Choreographer.FrameCallback() {
              @Override
              public void doFrame(long frameTimeNanos) {
                r.run();
              }
            });
  }

  private static void takeScreenshot(
      @NonNull Handler backgroundHandler,
      @NonNull Handler mainHandler,
      @NonNull FlutterView view,
      @NonNull Result result) {
    final boolean acquired = view.acquireLatestImageViewFrame();
    // The next frame may already have already been comitted.
    // The next frame is guaranteed to have the Flutter image.
    waitForAndroidFrame(
        () -> {
          waitForAndroidFrame(
              () -> {
                if (acquired) {
                  FlutterDeviceScreenshot.convertViewToBitmap(view, result, backgroundHandler);
                } else {
                  takeScreenshot(backgroundHandler, mainHandler, view, result);
                }
              });
        });
  }

  private static void convertViewToBitmap(
      FlutterView flutterView, @NonNull Result result, @NonNull Handler backgroundHandler) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      final Bitmap bitmap =
          Bitmap.createBitmap(
              flutterView.getWidth(), flutterView.getHeight(), Bitmap.Config.RGB_565);
      final Canvas canvas = new Canvas(bitmap);
      flutterView.draw(canvas);

      final ByteArrayOutputStream output = new ByteArrayOutputStream();
      bitmap.compress(Bitmap.CompressFormat.PNG, /*quality=*/ 100, output);
      result.success(output.toByteArray());
    }

    final Bitmap bitmap =
        Bitmap.createBitmap(
            flutterView.getWidth(), flutterView.getHeight(), Bitmap.Config.ARGB_8888);

    final int[] flutterViewLocation = new int[2];
    flutterView.getLocationInWindow(flutterViewLocation);
    final int flutterViewLeft = flutterViewLocation[0];
    final int flutterViewTop = flutterViewLocation[1];

    final Rect flutterViewRect =
        new Rect(
            flutterViewLeft,
            flutterViewTop,
            flutterViewLeft + flutterView.getWidth(),
            flutterViewTop + flutterView.getHeight());

    final Activity flutterActivity = (Activity) flutterView.getContext();
    PixelCopy.request(
        flutterActivity.getWindow(),
        flutterViewRect,
        bitmap,
        (int copyResult) -> {
          final Handler mainHandler = new Handler(Looper.getMainLooper());
          if (copyResult == PixelCopy.SUCCESS) {
            final ByteArrayOutputStream output = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, /*quality=*/ 100, output);
            mainHandler.post(
                () -> {
                  result.success(output.toByteArray());
                });
          } else {
            mainHandler.post(
                () -> {
                  result.error("Could not copy the pixels", "result was " + copyResult, null);
                });
          }
        },
        backgroundHandler);
  }
}
