// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;

/**
 * TODO(mattcarroll): fill in javadoc for NavigationChannel.
 */
public class NavigationChannel {

  @NonNull
  public final MethodChannel channel;

  public NavigationChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new MethodChannel(dartExecutor, "flutter/navigation", JSONMethodCodec.INSTANCE);
  }

  public void setInitialRoute(String initialRoute) {
    channel.invokeMethod("setInitialRoute", initialRoute);
  }

  public void pushRoute(String route) {
    channel.invokeMethod("pushRoute", route);
  }

  public void popRoute() {
    channel.invokeMethod("popRoute", null);
  }

  public void setMethodCallHandler(@Nullable MethodChannel.MethodCallHandler handler) {
    channel.setMethodCallHandler(handler);
  }

}
