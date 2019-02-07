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
 * TODO(mattcarroll): fill in javadoc for PlatformChannel.
 */
public class PlatformChannel {

  public final MethodChannel channel;

  public PlatformChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new MethodChannel(dartExecutor, "flutter/platform", JSONMethodCodec.INSTANCE);
  }

  public void setMethodCallHandler(@Nullable MethodChannel.MethodCallHandler handler) {
    channel.setMethodCallHandler(handler);
  }

}
