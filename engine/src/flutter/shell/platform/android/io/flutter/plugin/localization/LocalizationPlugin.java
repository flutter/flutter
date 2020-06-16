// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.localization;

import android.content.Context;
import android.content.res.Configuration;
import android.os.Build;
import android.os.LocaleList;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.systemchannels.LocalizationChannel;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** Android implementation of the localization plugin. */
public class LocalizationPlugin {
  @NonNull private final LocalizationChannel localizationChannel;
  @NonNull private final Context context;

  public LocalizationPlugin(
      @NonNull Context context, @NonNull LocalizationChannel localizationChannel) {

    this.context = context;
    this.localizationChannel = localizationChannel;
  }

  public Locale resolveNativeLocale(List<Locale> supportedLocales) {
    Locale platformResolvedLocale = null;
    if (Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
      List<Locale.LanguageRange> languageRanges = new ArrayList<>();
      LocaleList localeList = context.getResources().getConfiguration().getLocales();
      int localeCount = localeList.size();
      for (int index = 0; index < localeCount; ++index) {
        Locale locale = localeList.get(index);
        String localeString = locale.toString();
        // This string replacement converts the locale string into the ranges format.
        languageRanges.add(new Locale.LanguageRange(localeString.replace("_", "-")));
      }

      // TODO(garyq): This should be modified to achieve Android's full
      // locale resolution:
      // https://developer.android.com/guide/topics/resources/multilingual-support
      platformResolvedLocale = Locale.lookup(languageRanges, supportedLocales);
    }
    return platformResolvedLocale;
  }

  /**
   * Send the current {@link Locale} configuration to Flutter.
   *
   * <p>FlutterEngine must be non-null when this method is invoked.
   */
  @SuppressWarnings("deprecation")
  public void sendLocalesToFlutter(@NonNull Configuration config) {
    List<Locale> locales = new ArrayList<>();
    if (Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
      LocaleList localeList = config.getLocales();
      int localeCount = localeList.size();
      for (int index = 0; index < localeCount; ++index) {
        Locale locale = localeList.get(index);
        locales.add(locale);
      }
    } else {
      locales.add(config.locale);
    }

    localizationChannel.sendLocales(locales);
  }
}
