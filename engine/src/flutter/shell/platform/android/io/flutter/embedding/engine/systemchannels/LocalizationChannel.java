// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;

/**
 * Sends the platform's locales to Dart.
 */
public class LocalizationChannel {

  @NonNull
  public final MethodChannel channel;

  public LocalizationChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new MethodChannel(dartExecutor, "flutter/localization", JSONMethodCodec.INSTANCE);
  }

  /**
   * Send the given {@code locales} to Dart.
   */
  public void sendLocales(List<Locale> locales) {
    List<String> data = new ArrayList<>();
    for (Locale locale : locales) {
      data.add(locale.getLanguage());
      data.add(locale.getCountry());
      data.add(locale.getScript());
      data.add(locale.getVariant());
    }
    channel.invokeMethod("setLocale", data);
  }

}
