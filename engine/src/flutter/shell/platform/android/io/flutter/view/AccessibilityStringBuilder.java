// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.text.SpannableString;
import android.text.style.LocaleSpan;
import android.text.style.TtsSpan;
import android.text.style.URLSpan;
import java.util.List;
import java.util.Locale;

/**
 * Builds a string with accessibility related string spans.
 *
 * <p>Use {@code addLocale} to set the locale and/or {@code addUrl} to set the url for the entire
 * string. Uses {@code addAttributes} to add any additional {@code StringAttribute} to the string
 */
public class AccessibilityStringBuilder {
  // When adding a new StringAttributeType, the classes in these file must be
  // updated as well.
  //  * engine/src/flutter/lib/ui/semantics.dart
  //  * engine/src/flutter/lib/web_ui/lib/semantics.dart
  //  * engine/src/flutter/lib/ui/semantics/string_attribute.h

  public enum StringAttributeType {
    SPELLOUT,
    LOCALE,
  }

  public static class StringAttribute {
    int start;
    int end;
    StringAttributeType type;
  }

  public static class SpellOutStringAttribute extends StringAttribute {}

  public static class LocaleStringAttribute extends StringAttribute {
    String locale;
  }

  private static class UrlStringAttribute extends StringAttribute {
    String url;
  }

  AccessibilityStringBuilder() {}

  private String string;
  private List<StringAttribute> attributes;
  private String locale;
  private String url;

  AccessibilityStringBuilder addString(String string) {
    this.string = string;
    return this;
  }

  AccessibilityStringBuilder addAttributes(List<StringAttribute> attributes) {
    this.attributes = attributes;
    return this;
  }

  AccessibilityStringBuilder addLocale(String locale) {
    this.locale = locale;
    return this;
  }

  AccessibilityStringBuilder addUrl(String url) {
    this.url = url;
    return this;
  }

  CharSequence build() {
    if (string == null) {
      return null;
    }
    final SpannableString spannableString = new SpannableString(string);
    if (attributes != null) {
      for (StringAttribute attribute : attributes) {
        switch (attribute.type) {
          case SPELLOUT:
            {
              final TtsSpan ttsSpan = new TtsSpan.Builder<>(TtsSpan.TYPE_VERBATIM).build();
              spannableString.setSpan(ttsSpan, attribute.start, attribute.end, 0);
              break;
            }
          case LOCALE:
            {
              LocaleStringAttribute localeAttribute = (LocaleStringAttribute) attribute;
              Locale locale = Locale.forLanguageTag(localeAttribute.locale);
              final LocaleSpan localeSpan = new LocaleSpan(locale);
              spannableString.setSpan(localeSpan, attribute.start, attribute.end, 0);
              break;
            }
        }
      }
    }
    if (url != null && !url.isEmpty()) {
      final URLSpan urlSpan = new URLSpan(url);
      spannableString.setSpan(urlSpan, 0, string.length(), 0);
    }

    if (locale != null && !locale.isEmpty()) {
      Locale localeObject = Locale.forLanguageTag(locale);
      final LocaleSpan localeSpan = new LocaleSpan(localeObject);
      spannableString.setSpan(localeSpan, 0, string.length(), 0);
    }

    return spannableString;
  }
}
