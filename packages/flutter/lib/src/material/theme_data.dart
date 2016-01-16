// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, hashValues, hashList, lerpDouble;

import 'colors.dart';
import 'icon_theme_data.dart';
import 'typography.dart';

enum ThemeBrightness { dark, light }

// Deriving these values is black magic. The spec claims that pressed buttons
// have a highlight of 0x66999999, but that's clearly wrong. The videos in the
// spec show that buttons have a composited highlight of #E1E1E1 on a background
// of #FAFAFA. Assuming that the highlight really has an opacity of 0x66, we can
// solve for the actual color of the highlight:
const Color _kLightThemeHighlightColor = const Color(0x66BCBCBC);

// The same video shows the splash compositing to #D7D7D7 on a background of
// #E1E1E1. Again, assuming the splash has an opacity of 0x66, we can solve for
// the actual color of the splash:
const Color _kLightThemeSplashColor = const Color(0x66C8C8C8);

// Unfortunately, a similar video isn't available for the dark theme, which
// means we assume the values in the spec are actually correct.
const Color _kDarkThemeHighlightColor = const Color(0x40CCCCCC);
const Color _kDarkThemeSplashColor = const Color(0x40CCCCCC);

class ThemeData {

  ThemeData.raw({
    this.brightness,
    this.primarySwatch,
    this.primaryColor,
    this.primaryColorBrightness,
    this.canvasColor,
    this.cardColor,
    this.dividerColor,
    this.highlightColor,
    this.splashColor,
    this.unselectedColor,
    this.disabledColor,
    this.accentColor,
    this.accentColorBrightness,
    this.indicatorColor,
    this.hintColor,
    this.hintOpacity,
    this.text,
    this.primaryTextTheme,
    this.primaryIconTheme
  }) {
    assert(brightness != null);
    // primarySwatch can be null; TODO(ianh): see https://github.com/flutter/flutter/issues/1277
    assert(primaryColor != null);
    assert(primaryColorBrightness != null);
    assert(canvasColor != null);
    assert(cardColor != null);
    assert(dividerColor != null);
    assert(highlightColor != null);
    assert(splashColor != null);
    assert(unselectedColor != null);
    assert(disabledColor != null);
    assert(accentColor != null);
    assert(accentColorBrightness != null);
    assert(indicatorColor != null);
    assert(hintColor != null);
    assert(hintOpacity != null);
    assert(text != null);
    assert(primaryTextTheme != null);
    assert(primaryIconTheme != null);
  }

  factory ThemeData({
    ThemeBrightness brightness: ThemeBrightness.light,
    Map<int, Color> primarySwatch,
    Color primaryColor,
    ThemeBrightness primaryColorBrightness,
    Color canvasColor,
    Color cardColor,
    Color dividerColor,
    Color highlightColor,
    Color splashColor,
    Color unselectedColor,
    Color disabledColor,
    Color accentColor,
    ThemeBrightness accentColorBrightness: ThemeBrightness.dark,
    Color indicatorColor,
    Color hintColor,
    double hintOpacity,
    TextTheme text,
    TextTheme primaryTextTheme,
    IconThemeData primaryIconTheme
  }) {
    // brightness default is in the arguments list
    bool isDark = brightness == ThemeBrightness.dark;
    primaryColor ??= primarySwatch == null ? isDark ? Colors.grey[900] : Colors.grey[100] : primarySwatch[500];
    primaryColorBrightness ??= primarySwatch == null ? brightness : ThemeBrightness.dark /* swatch[500] is always dark */;
    canvasColor ??= isDark ? Colors.grey[850] : Colors.grey[50];
    cardColor ??= isDark ? Colors.grey[800] : Colors.white;
    dividerColor ??= isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);
    highlightColor ??= isDark ? _kDarkThemeHighlightColor : _kLightThemeHighlightColor;
    splashColor ??= isDark ? _kDarkThemeSplashColor : _kLightThemeSplashColor;
    unselectedColor ??= isDark ? Colors.white70 : Colors.black54;
    disabledColor ??= isDark ? Colors.white30 : Colors.black26;
    accentColor ??= primarySwatch == null ? Colors.blue[500] : primarySwatch[500];
    // accentColorBrightness default is in the arguments list
    indicatorColor ??= accentColor == primaryColor ? Colors.white : accentColor;
    hintColor ??= isDark ? const Color(0x42FFFFFF) : const Color(0x4C000000);
    hintOpacity ??= hintColor != null ? hintColor.alpha / 0xFF : isDark ? 0.26 : 0.30;
    text ??= isDark ? Typography.white : Typography.black;
    primaryTextTheme ??= primaryColorBrightness == ThemeBrightness.dark ? Typography.white : Typography.black;
    primaryIconTheme ??= primaryColorBrightness == ThemeBrightness.dark ? const IconThemeData(color: IconThemeColor.white) : const IconThemeData(color: IconThemeColor.black);
    return new ThemeData.raw(
      brightness: brightness,
      primarySwatch: primarySwatch,
      primaryColor: primaryColor,
      primaryColorBrightness: primaryColorBrightness,
      canvasColor: canvasColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      unselectedColor: unselectedColor,
      disabledColor: disabledColor,
      accentColor: accentColor,
      accentColorBrightness: accentColorBrightness,
      indicatorColor: indicatorColor,
      hintColor: hintColor,
      hintOpacity: hintOpacity,
      text: text,
      primaryTextTheme: primaryTextTheme,
      primaryIconTheme: primaryIconTheme
    );
  }

  factory ThemeData.light() => new ThemeData(primarySwatch: Colors.blue, brightness: ThemeBrightness.light);
  factory ThemeData.dark() => new ThemeData(brightness: ThemeBrightness.dark);
  factory ThemeData.fallback() => new ThemeData.light();

  /// The brightness of the overall theme of the application. Used by widgets
  /// like buttons to determine what color to pick when not using the primary or
  /// accent color.
  ///
  /// When the ThemeBrightness is dark, the canvas, card, and primary colors are
  /// all dark. When the ThemeBrightness is light, the canvas and card colors
  /// are bright, and the primary color's darkness varies as described by
  /// primaryColorBrightness. The primaryColor does not contrast well with the
  /// card and canvas colors when the brightness is dark; when the brightness is
  /// dark, use Colors.white or the accentColor for a contrasting color.
  final ThemeBrightness brightness;

  final Map<int, Color> primarySwatch;

  /// The background colour for major parts of the app (toolbars, tab bars, etc)
  final Color primaryColor;

  /// The brightness of the primaryColor. Used to determine the colour of text and
  /// icons placed on top of the primary color (e.g. toolbar text).
  final ThemeBrightness primaryColorBrightness;

  final Color canvasColor;
  final Color cardColor;
  final Color dividerColor;
  final Color highlightColor;
  final Color splashColor;
  final Color unselectedColor;
  final Color disabledColor;

  /// The foreground color for widgets (knobs, text, etc)
  final Color accentColor;

  /// The brightness of the accentColor. Used to determine the colour of text
  /// and icons placed on top of the accent color (e.g. the icons on a floating
  /// action button).
  final ThemeBrightness accentColorBrightness;

  /// The color of the selected tab indicator in a tab strip.
  final Color indicatorColor;

  // Some users want the pre-multiplied color, others just want the opacity.
  final Color hintColor;
  final double hintOpacity;

  /// Text with a color that contrasts with the card and canvas colors.
  final TextTheme text;

  /// A text theme that contrasts with the primary color.
  final TextTheme primaryTextTheme;

  final IconThemeData primaryIconTheme;

  static ThemeData lerp(ThemeData begin, ThemeData end, double t) {
    Map<int, Color> primarySwatch;
    if (begin.primarySwatch != null && end.primarySwatch != null) {
      primarySwatch = <int, Color>{};
      for (int index in begin.primarySwatch.keys) {
        if (!end.primarySwatch.containsKey(index))
          continue;
        primarySwatch[index] = Color.lerp(begin.primarySwatch[index], end.primarySwatch[index], t);
      }
    }
    return new ThemeData.raw(
      brightness: t < 0.5 ? begin.brightness : end.brightness,
      primarySwatch: primarySwatch,
      primaryColor: Color.lerp(begin.primaryColor, end.primaryColor, t),
      primaryColorBrightness: t < 0.5 ? begin.primaryColorBrightness : end.primaryColorBrightness,
      canvasColor: Color.lerp(begin.canvasColor, end.canvasColor, t),
      cardColor: Color.lerp(begin.cardColor, end.cardColor, t),
      dividerColor: Color.lerp(begin.dividerColor, end.dividerColor, t),
      highlightColor: Color.lerp(begin.highlightColor, end.highlightColor, t),
      splashColor: Color.lerp(begin.splashColor, end.splashColor, t),
      unselectedColor: Color.lerp(begin.unselectedColor, end.unselectedColor, t),
      disabledColor: Color.lerp(begin.disabledColor, end.disabledColor, t),
      accentColor: Color.lerp(begin.accentColor, end.accentColor, t),
      accentColorBrightness: t < 0.5 ? begin.accentColorBrightness : end.accentColorBrightness,
      indicatorColor: Color.lerp(begin.indicatorColor, end.indicatorColor, t),
      hintColor: Color.lerp(begin.hintColor, end.hintColor, t),
      hintOpacity: lerpDouble(begin.hintOpacity, end.hintOpacity, t),
      text: TextTheme.lerp(begin.text, end.text, t),
      primaryTextTheme: TextTheme.lerp(begin.primaryTextTheme, end.primaryTextTheme, t),
      primaryIconTheme: IconThemeData.lerp(begin.primaryIconTheme, end.primaryIconTheme, t)
    );
  }

  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    ThemeData otherData = other;
    return (otherData.brightness == brightness) &&
           (otherData.primarySwatch == primarySwatch) &&
           (otherData.primaryColor == primaryColor) &&
           (otherData.primaryColorBrightness == primaryColorBrightness) &&
           (otherData.canvasColor == canvasColor) &&
           (otherData.cardColor == cardColor) &&
           (otherData.dividerColor == dividerColor) &&
           (otherData.highlightColor == highlightColor) &&
           (otherData.splashColor == splashColor) &&
           (otherData.unselectedColor == unselectedColor) &&
           (otherData.disabledColor == disabledColor) &&
           (otherData.accentColor == accentColor) &&
           (otherData.accentColorBrightness == accentColorBrightness) &&
           (otherData.indicatorColor == indicatorColor) &&
           (otherData.hintColor == hintColor) &&
           (otherData.hintOpacity == hintOpacity) &&
           (otherData.text == text) &&
           (otherData.primaryTextTheme == primaryTextTheme) &&
           (otherData.primaryIconTheme == primaryIconTheme);
  }
  int get hashCode {
    return hashValues(
      brightness,
      hashList(primarySwatch.keys),
      hashList(primarySwatch.values),
      primaryColor,
      primaryColorBrightness,
      canvasColor,
      cardColor,
      dividerColor,
      highlightColor,
      splashColor,
      unselectedColor,
      disabledColor,
      accentColor,
      accentColorBrightness,
      indicatorColor,
      hintColor,
      hintOpacity,
      text,
      primaryTextTheme,
      primaryIconTheme
    );
  }

  String toString() => '$primaryColor $brightness etc...';
}
