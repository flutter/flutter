// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetFileDescriptor;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Window;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryCodec;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

public abstract class TestActivity extends TestableFlutterActivity {
  static final String TAG = "Scenarios";

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    hideSystemBars(getWindow());

    final Intent launchIntent = getIntent();
    if ("com.google.intent.action.TEST_LOOP".equals(launchIntent.getAction())) {
      if (Build.VERSION.SDK_INT > 22) {
        requestPermissions(new String[] {Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
      }
      final Uri logFileUri = launchIntent.getData();
      new Handler()
          .postDelayed(
              new Runnable() {
                @Override
                public void run() {
                  writeTimelineData(logFileUri);
                  testFlutterLoaderCallbackWhenInitializedTwice();
                }
              },
              20000);
    } else {
      testFlutterLoaderCallbackWhenInitializedTwice();
    }
  }

  @Override
  @NonNull
  public FlutterShellArgs getFlutterShellArgs() {
    FlutterShellArgs args = FlutterShellArgs.fromIntent(getIntent());
    args.add(FlutterShellArgs.ARG_TRACE_STARTUP);
    args.add(FlutterShellArgs.ARG_ENABLE_DART_PROFILING);
    args.add(FlutterShellArgs.ARG_VERBOSE_LOGGING);
    return args;
  }

  @Override
  public void onFlutterUiDisplayed() {
    final Intent launchIntent = getIntent();
    MethodChannel channel =
        new MethodChannel(getFlutterEngine().getDartExecutor(), "driver", JSONMethodCodec.INSTANCE);
    Map<String, Object> test = new HashMap<>(2);
    if (launchIntent.hasExtra("scenario_name")) {
      test.put("name", launchIntent.getStringExtra("scenario_name"));
    } else {
      test.put("name", "animated_color_square");
    }
    test.put("use_android_view", launchIntent.getBooleanExtra("use_android_view", false));
    test.put(
        "expect_android_view_fallback",
        launchIntent.getBooleanExtra("expect_android_view_fallback", false));
    test.put("view_type", launchIntent.getStringExtra("view_type"));
    getScenarioParams(test);
    channel.invokeMethod("set_scenario", test);
  }

  /**
   * Populates test-specific parameters that are sent to the Dart test scenario.
   *
   * @param args The map of test arguments
   */
  protected void getScenarioParams(@NonNull Map<String, Object> args) {}

  protected void writeTimelineData(@Nullable Uri logFile) {
    if (logFile == null) {
      throw new IllegalArgumentException();
    }
    if (getFlutterEngine() == null) {
      Log.e(TAG, "Could not write timeline data - no engine.");
      return;
    }
    final BasicMessageChannel<ByteBuffer> channel =
        new BasicMessageChannel<>(
            getFlutterEngine().getDartExecutor(), "write_timeline", BinaryCodec.INSTANCE);
    channel.send(
        null,
        (ByteBuffer reply) -> {
          AssetFileDescriptor afd = null;
          try {
            afd = getContentResolver().openAssetFileDescriptor(logFile, "w");
            final FileDescriptor fd = afd.getFileDescriptor();
            final FileOutputStream outputStream = new FileOutputStream(fd);
            outputStream.write(reply.array());
            outputStream.close();
          } catch (IOException ex) {
            Log.e(TAG, "Could not write timeline file", ex);
          } finally {
            try {
              if (afd != null) {
                afd.close();
              }
            } catch (IOException e) {
              Log.w(TAG, "Could not close", e);
            }
          }
          finish();
        });
  }

  /**
   * This method verifies that {@link
   * io.flutter.embedding.engine.loader.FlutterLoader#ensureInitializationCompleteAsync(Context,
   * String[], Handler, Runnable)} invokes its callback when called after initialization.
   */
  protected void testFlutterLoaderCallbackWhenInitializedTwice() {
    FlutterLoader flutterLoader = new FlutterLoader();

    // Flutter is probably already loaded in this app based on
    // code that ran before this method. Nonetheless, invoke the
    // blocking initialization here to ensure it's initialized.
    flutterLoader.startInitialization(getApplicationContext());
    flutterLoader.ensureInitializationComplete(getApplication(), new String[] {});

    // Now that Flutter is loaded, invoke ensureInitializationCompleteAsync with
    // a callback and verify that the callback is invoked.
    Handler mainHandler = new Handler(Looper.getMainLooper());

    final AtomicBoolean didInvokeCallback = new AtomicBoolean(false);

    flutterLoader.ensureInitializationCompleteAsync(
        getApplication(),
        new String[] {},
        mainHandler,
        new Runnable() {
          @Override
          public void run() {
            didInvokeCallback.set(true);
          }
        });

    mainHandler.post(
        new Runnable() {
          @Override
          public void run() {
            if (!didInvokeCallback.get()) {
              throw new RuntimeException(
                  "Failed test: FlutterLoader#ensureInitializationCompleteAsync() did not invoke its callback.");
            }
          }
        });
  }

  private static void hideSystemBars(Window window) {
    final WindowInsetsControllerCompat insetController =
        WindowCompat.getInsetsController(window, window.getDecorView());
    insetController.setSystemBarsBehavior(
        WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
    insetController.hide(WindowInsetsCompat.Type.systemBars());
  }
}
