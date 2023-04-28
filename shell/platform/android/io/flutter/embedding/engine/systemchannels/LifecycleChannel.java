// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;

/**
 * A {@link BasicMessageChannel} that communicates lifecycle events to the framework.
 *
 * <p>The activity listens to the Android lifecycle events, in addition to the focus events for
 * windows, and this channel combines that information to decide if the application is the inactive,
 * resumed, paused, or detached state.
 */
public class LifecycleChannel {
  private static final String TAG = "LifecycleChannel";
  private static final String CHANNEL_NAME = "flutter/lifecycle";

  // These should stay in sync with the AppLifecycleState enum in the framework.
  private static final String RESUMED = "AppLifecycleState.resumed";
  private static final String INACTIVE = "AppLifecycleState.inactive";
  private static final String PAUSED = "AppLifecycleState.paused";
  private static final String DETACHED = "AppLifecycleState.detached";

  private String lastAndroidState = "";
  private String lastFlutterState = "";
  private boolean lastFocus = false;

  @NonNull private final BasicMessageChannel<String> channel;

  public LifecycleChannel(@NonNull DartExecutor dartExecutor) {
    this(new BasicMessageChannel<String>(dartExecutor, CHANNEL_NAME, StringCodec.INSTANCE));
  }

  @VisibleForTesting
  public LifecycleChannel(@NonNull BasicMessageChannel<String> channel) {
    this.channel = channel;
  }

  // Here's the state table this implements:
  //
  // | Android State | Window focused | Flutter state |
  // |---------------|----------------|---------------|
  // | Resumed       |     true       |    resumed    |
  // | Resumed       |     false      |    inactive   |
  // | Paused        |     true       |    inactive   |
  // | Paused        |     false      |    inactive   |
  // | Stopped       |     true       |    paused     |
  // | Stopped       |     false      |    paused     |
  // | Detached      |     true       |    detached   |
  // | Detached      |     false      |    detached   |
  private void sendState(String state, boolean hasFocus) {
    if (lastAndroidState == state && hasFocus == lastFocus) {
      // No inputs changed, so Flutter state could not have changed.
      return;
    }
    String newState;
    if (state == RESUMED) {
      // Focus is only taken into account when the Android state is "Resumed".
      // In all other states, focus is ignored, because we can't know what order
      // Android lifecycle notifications and window focus notifications events
      // will arrive in, and those states don't send input events anyhow.
      newState = hasFocus ? RESUMED : INACTIVE;
    } else {
      newState = state;
    }
    // Keep the last reported values for future updates.
    lastAndroidState = state;
    lastFocus = hasFocus;
    if (newState == lastFlutterState) {
      // No change in the resulting Flutter state, so don't report anything.
      return;
    }
    Log.v(TAG, "Sending " + newState + " message.");
    channel.send(newState);
    lastFlutterState = newState;
  }

  // Called if at least one window in the app has focus.
  public void aWindowIsFocused() {
    sendState(lastAndroidState, true);
  }

  // Called if no windows in the app have focus.
  public void noWindowsAreFocused() {
    sendState(lastAndroidState, false);
  }

  public void appIsResumed() {
    sendState(RESUMED, lastFocus);
  }

  public void appIsInactive() {
    sendState(INACTIVE, lastFocus);
  }

  public void appIsPaused() {
    sendState(PAUSED, lastFocus);
  }

  public void appIsDetached() {
    sendState(DETACHED, lastFocus);
  }
}
