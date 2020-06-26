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

  /**
   * Computes the {@link Locale} in supportedLocales that best matches the user's preferred locales.
   *
   * <p>FlutterEngine must be non-null when this method is invoked.
   */
  @SuppressWarnings("deprecation")
  public Locale resolveNativeLocale(List<Locale> supportedLocales) {
    if (supportedLocales == null || supportedLocales.isEmpty()) {
      return null;
    }

    // Android improved the localization resolution algorithms after API 24 (7.0, Nougat).
    // See https://developer.android.com/guide/topics/resources/multilingual-support
    //
    // LanguageRange and Locale.lookup was added in API 26 and is the preferred way to
    // select a locale. Pre-API 26, we implement a manual locale resolution.
    if (Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
      // Modern locale resolution using LanguageRange
      // https://developer.android.com/guide/topics/resources/multilingual-support#postN
      List<Locale.LanguageRange> languageRanges = new ArrayList<>();
      LocaleList localeList = context.getResources().getConfiguration().getLocales();
      int localeCount = localeList.size();
      for (int index = 0; index < localeCount; ++index) {
        Locale locale = localeList.get(index);
        String localeString = locale.toString();
        // This string replacement converts the locale string into the ranges format.
        languageRanges.add(new Locale.LanguageRange(localeString.replace("_", "-")));
        languageRanges.add(new Locale.LanguageRange(locale.getLanguage()));
        languageRanges.add(new Locale.LanguageRange(locale.getLanguage() + "-*"));
      }
      Locale platformResolvedLocale = Locale.lookup(languageRanges, supportedLocales);
      if (platformResolvedLocale != null) {
        return platformResolvedLocale;
      }
      return supportedLocales.get(0);
    } else if (Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
      // Modern locale resolution without languageRange
      // https://developer.android.com/guide/topics/resources/multilingual-support#postN
      LocaleList localeList = context.getResources().getConfiguration().getLocales();
      for (int index = 0; index < localeList.size(); ++index) {
        Locale preferredLocale = localeList.get(index);
        // Look for exact match.
        for (Locale locale : supportedLocales) {
          if (preferredLocale.equals(locale)) {
            return locale;
          }
        }
        // Look for exact language only match.
        for (Locale locale : supportedLocales) {
          if (preferredLocale.getLanguage().equals(locale.toLanguageTag())) {
            return locale;
          }
        }
        // Look for any locale with matching language.
        for (Locale locale : supportedLocales) {
          if (preferredLocale.getLanguage().equals(locale.getLanguage())) {
            return locale;
          }
        }
      }
      return supportedLocales.get(0);
    }

    // Legacy locale resolution
    // https://developer.android.com/guide/topics/resources/multilingual-support#preN
    Locale preferredLocale = context.getResources().getConfiguration().locale;
    if (preferredLocale != null) {
      // Look for exact match.
      for (Locale locale : supportedLocales) {
        if (preferredLocale.equals(locale)) {
          return locale;
        }
      }
      // Look for exact language only match.
      for (Locale locale : supportedLocales) {
        if (preferredLocale.getLanguage().equals(locale.toString())) {
          return locale;
        }
      }
    }
    return supportedLocales.get(0);
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
