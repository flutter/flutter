// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;

/** TODO(mattcarroll): fill in javadoc for LifecycleChannel. */
public class LifecycleChannel {
  private static final String TAG = "LifecycleChannel";

  @NonNull public final BasicMessageChannel<String> channel;

  public LifecycleChannel(@NonNull DartExecutor dartExecutor) {
    this.channel =
        new BasicMessageChannel<>(dartExecutor, "flutter/lifecycle", StringCodec.INSTANCE);
  }

  public void appIsInactive() {
    Log.v(TAG, "Sending AppLifecycleState.inactive message.");
    channel.send("AppLifecycleState.inactive");
  }

  public void appIsResumed() {
    Log.v(TAG, "Sending AppLifecycleState.resumed message.");
    channel.send("AppLifecycleState.resumed");
  }

  public void appIsPaused() {
    Log.v(TAG, "Sending AppLifecycleState.paused message.");
    channel.send("AppLifecycleState.paused");
  }

  public void appIsDetached() {
    Log.v(TAG, "Sending AppLifecycleState.detached message.");
    channel.send("AppLifecycleState.detached");
  }
}
