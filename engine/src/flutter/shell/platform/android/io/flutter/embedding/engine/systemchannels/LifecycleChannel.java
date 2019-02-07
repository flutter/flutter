// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;

/**
 * TODO(mattcarroll): fill in javadoc for LifecycleChannel.
 */
public class LifecycleChannel {

  @NonNull
  public final BasicMessageChannel<String> channel;

  public LifecycleChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new BasicMessageChannel<>(dartExecutor, "flutter/lifecycle", StringCodec.INSTANCE);
  }

  public void appIsInactive() {
    channel.send("AppLifecycleState.inactive");
  }

  public void appIsResumed() {
    channel.send("AppLifecycleState.resumed");
  }

  public void appIsPaused() {
    channel.send("AppLifecycleState.paused");
  }

}
