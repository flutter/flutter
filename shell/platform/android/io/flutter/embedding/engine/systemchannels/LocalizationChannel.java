// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;

import java.util.Arrays;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;

/**
 * TODO(mattcarroll): fill in javadoc for LocalizationChannel.
 */
public class LocalizationChannel {

  @NonNull
  public final MethodChannel channel;

  public LocalizationChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new MethodChannel(dartExecutor, "flutter/localization", JSONMethodCodec.INSTANCE);
  }

  public void setLocale(String language, String country) {
    channel.invokeMethod("setLocale", Arrays.asList(language, country));
  }

  public void setMethodCallHandler(MethodChannel.MethodCallHandler handler) {
    channel.setMethodCallHandler(handler);
  }

}
