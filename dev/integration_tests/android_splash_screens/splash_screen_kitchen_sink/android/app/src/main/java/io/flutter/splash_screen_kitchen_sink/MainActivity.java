// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.splash_screen_kitchen_sink;

import android.content.Context;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import androidx.annotation.Nullable;
import java.util.ArrayList;
import java.util.List;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.SplashScreen;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;
import io.flutter.view.FlutterMain;

public class MainActivity extends FlutterActivity {
  private static final String TAG = "MainActivity";

  private static FlutterEngine flutterEngine;

  static {
    // Explicitly activates Debug logging for the Flutter Android embedding.
    io.flutter.Log.setLogLevel(Log.DEBUG);
  }

  // Sends a JSON-serialized log of test events from Android to Flutter.
  private BasicMessageChannel<String> testChannel;
  // Log of splash events that is updated, serialized, and sent to Flutter.
  private SplashTestLog splashTestLog;

  /**
   * We explicitly provide a {@code FlutterEngine} so that every rotation does not create a
   * new FlutterEngine. Creating a new FlutterEngine on every orientation would cause the
   * splash experience to restart upon every orientation change, which is not what we're
   * interested in verifying in this example app.
   */
  @Override
  public FlutterEngine provideFlutterEngine(Context context) {
    if (flutterEngine == null) {
      flutterEngine = new FlutterEngine(context);

      flutterEngine.getDartExecutor().executeDartEntrypoint(new DartExecutor.DartEntrypoint(
          getAssets(),
          FlutterMain.findAppBundlePath(context),
          "main"
      ));

      // Setup the channel that sends splash test log updates from Android to Flutter.
      testChannel = new BasicMessageChannel<>(
          flutterEngine.getDartExecutor(),
          "testChannel",
          StringCodec.INSTANCE
      );

      // Initialize the splash test log that accumulates events.
      splashTestLog = new SplashTestLog();

      // Send initial splash test log.
      updateLogAndSendToFlutter();

      // List for any layout change, look for splash test updates, and if
      // there are any, add them to the log and send them to Flutter.
      getWindow().getDecorView().getRootView().getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
        @Override
        public void onGlobalLayout() {
          updateLogAndSendToFlutter();
        }
      });
    }
    return flutterEngine;
  }

  private void updateLogAndSendToFlutter() {
    // Look for the existence of a FlutterView and the existence of a
    // splash screen View on top of it.
    View flutterView = findViewByType(FlutterView.class);
    boolean isSplashAvailable = false;
    if (flutterView != null) {
      ViewGroup flutterViewParent = (ViewGroup) flutterView.getParent();
      isSplashAvailable = flutterViewParent.getChildCount() > 1;
    }

    // Update the splash test log.
    splashTestLog.update(flutterView != null, isSplashAvailable);

    // Send the latest version of the splash test log to Flutter.
    testChannel.send(splashTestLog.serialize());
  }

  /**
   * Finds an Android {@code View} in this {@code Activity}'s {@code View} hierarchy
   * that matches the given {@code viewType}.
   *
   * This method searches the {@code View} hierarchy breadth-first.
   */
  private View findViewByType(Class<? extends View> viewType) {
    View selectedView = getWindow().getDecorView().getRootView();//findViewById(0x01020002);
    List<View> viewQueue = new ArrayList<>();

    while (selectedView != null && !selectedView.getClass().equals(viewType)) {
      if (selectedView instanceof ViewGroup) {
        ViewGroup selectedViewGroup = (ViewGroup) selectedView;
        for (int i = 0; i < selectedViewGroup.getChildCount(); ++i) {
          viewQueue.add(selectedViewGroup.getChildAt(i));
        }
      }

      if (!viewQueue.isEmpty()) {
        selectedView = viewQueue.remove(0);
      } else {
        selectedView = null;
      }
    }

    return selectedView;
  }

  @Override
  @Nullable
  public SplashScreen provideSplashScreen() {
    return new FlutterZoomSplashScreen();
  }

  /**
   * Log of splash UI changes that is used to verify the correctness of
   * splash behavior.
   */
  private static class SplashTestLog {
    private List<TestState> eventLog = new ArrayList<>();

    SplashTestLog() {
      eventLog.add(TestState.WAITING_FOR_LAYOUT);
    }

    void update(boolean isFlutterViewAvailable, boolean isSplashAvailable) {
      TestState newTestState = TestState.WAITING_FOR_LAYOUT;
      if (isFlutterViewAvailable) {
        newTestState = isSplashAvailable ? TestState.SPLASH_SHOWING : TestState.SPLASH_NOT_SHOWING;
      }

      if (newTestState != eventLog.get(eventLog.size() - 1)) {
        eventLog.add(newTestState);
      }
    }

    String serialize() {
      return "{\"events\":[" + serializeEvents() + "]}";
    }

    private String serializeEvents() {
      StringBuilder stringBuilder = new StringBuilder();
      for (int i = 0; i < eventLog.size(); ++i) {
        stringBuilder.append(serializeEvent(eventLog.get(i)));
        if (i < (eventLog.size() - 1)) {
          stringBuilder.append(",");
        }
      }
      return stringBuilder.toString();
    }

    private String serializeEvent(TestState event) {
      switch (event) {
        case WAITING_FOR_LAYOUT:
          return "\"waiting_for_layout\"";
        case SPLASH_SHOWING:
          return "\"splash_showing\"";
        case SPLASH_NOT_SHOWING:
          return "\"splash_not_showing\"";
        default:
          throw new IllegalStateException("Received non-existent TestState.");
      }
    }
  }

  /**
   * States of splash display in this test project.
   */
  private enum TestState {
    WAITING_FOR_LAYOUT,
    SPLASH_SHOWING,
    SPLASH_NOT_SHOWING;
  }
}
