// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.os.Build;
import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** Sends the platform's locales to Dart. */
public class LocalizationChannel {
  private static final String TAG = "LocalizationChannel";

  @NonNull public final MethodChannel channel;

  public LocalizationChannel(@NonNull DartExecutor dartExecutor) {
    this.channel =
        new MethodChannel(dartExecutor, "flutter/localization", JSONMethodCodec.INSTANCE);
  }

  /** Send the given {@code locales} to Dart. */
  public void sendLocales(@NonNull List<Locale> locales, Locale platformResolvedLocale) {
    Log.v(TAG, "Sending Locales to Flutter.");
    // Send platformResolvedLocale first as it may be used in the callback
    // triggered by the user supported locales being updated/set.
    if (platformResolvedLocale != null) {
      List<String> platformResolvedLocaleData = new ArrayList<>();
      platformResolvedLocaleData.add(platformResolvedLocale.getLanguage());
      platformResolvedLocaleData.add(platformResolvedLocale.getCountry());
      platformResolvedLocaleData.add(
          Build.VERSION.SDK_INT >= 21 ? platformResolvedLocale.getScript() : "");
      platformResolvedLocaleData.add(platformResolvedLocale.getVariant());
      channel.invokeMethod("setPlatformResolvedLocale", platformResolvedLocaleData);
    }

    // Send the user's preferred locales.
    List<String> data = new ArrayList<>();
    for (Locale locale : locales) {
      Log.v(
          TAG,
          "Locale (Language: "
              + locale.getLanguage()
              + ", Country: "
              + locale.getCountry()
              + ", Variant: "
              + locale.getVariant()
              + ")");
      data.add(locale.getLanguage());
      data.add(locale.getCountry());
      // locale.getScript() was added in API 21.
      data.add(Build.VERSION.SDK_INT >= 21 ? locale.getScript() : "");
      data.add(locale.getVariant());
    }
    channel.invokeMethod("setLocale", data);
  }
}
