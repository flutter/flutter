// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;

/** TODO(mattcarroll): fill in javadoc for NavigationChannel. */
public class NavigationChannel {
  private static final String TAG = "NavigationChannel";

  @NonNull public final MethodChannel channel;

  public NavigationChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new MethodChannel(dartExecutor, "flutter/navigation", JSONMethodCodec.INSTANCE);
  }

  public void setInitialRoute(@NonNull String initialRoute) {
    Log.v(TAG, "Sending message to set initial route to '" + initialRoute + "'");
    channel.invokeMethod("setInitialRoute", initialRoute);
  }

  public void pushRoute(@NonNull String route) {
    Log.v(TAG, "Sending message to push route '" + route + "'");
    channel.invokeMethod("pushRoute", route);
  }

  public void popRoute() {
    Log.v(TAG, "Sending message to pop route.");
    channel.invokeMethod("popRoute", null);
  }

  public void setMethodCallHandler(@Nullable MethodChannel.MethodCallHandler handler) {
    channel.setMethodCallHandler(handler);
  }
}
