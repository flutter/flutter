// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

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

  ThemeData({
    ThemeBrightness brightness: ThemeBrightness.light,
    Map<int, Color> primarySwatch,
    Color accentColor,
    this.accentColorBrightness: ThemeBrightness.dark,
    TextTheme text
  }): this.brightness = brightness,
      this.primarySwatch = primarySwatch,
      primaryColorBrightness = primarySwatch == null ? brightness : ThemeBrightness.dark,
      canvasColor = brightness == ThemeBrightness.dark ? Colors.grey[850] : Colors.grey[50],
      cardColor = brightness == ThemeBrightness.dark ? Colors.grey[800] : Colors.white,
      dividerColor = brightness == ThemeBrightness.dark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      // Some users want the pre-multiplied color, others just want the opacity.
      hintColor = brightness == ThemeBrightness.dark ? const Color(0x42FFFFFF) : const Color(0x4C000000),
      hintOpacity = brightness == ThemeBrightness.dark ? 0.26 : 0.30,
      highlightColor = brightness == ThemeBrightness.dark ? _kDarkThemeHighlightColor : _kLightThemeHighlightColor,
      splashColor = brightness == ThemeBrightness.dark ? _kDarkThemeSplashColor : _kLightThemeSplashColor,
      text = brightness == ThemeBrightness.dark ? Typography.white : Typography.black {
    assert(brightness != null);

    if (primarySwatch == null) {
      if (brightness == ThemeBrightness.dark) {
        _primaryColor = Colors.grey[900];
      } else {
        _primaryColor = Colors.grey[100];
      }
    } else {
      _primaryColor = primarySwatch[500];
    }

    if (accentColor == null) {
      _accentColor = primarySwatch == null ? Colors.blue[500] : primarySwatch[500];
    } else {
      _accentColor = accentColor;
    }
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
  /// card and canvas colors when the brightness is dask; when the birghtness is
  /// dark, use Colors.white or the accentColor for a contrasting color.
  final ThemeBrightness brightness;

  final Map<int, Color> primarySwatch;
  final Color canvasColor;
  final Color cardColor;
  final Color dividerColor;
  final Color hintColor;
  final Color highlightColor;
  final Color splashColor;
  final double hintOpacity;

  /// Text with a color that contrasts with the card and canvas colors.
  final TextTheme text;

  /// The background colour for major parts of the app (toolbars, tab bars, etc)
  Color get primaryColor => _primaryColor;
  Color _primaryColor;

  /// The brightness of the primaryColor. Used to determine the colour of text and
  /// icons placed on top of the primary color (e.g. toolbar text).
  final ThemeBrightness primaryColorBrightness;

  /// A text theme that contrasts with the primary color.
  TextTheme get primaryTextTheme {
    if (primaryColorBrightness == ThemeBrightness.dark)
      return Typography.white;
    return Typography.black;
  }

  IconThemeData get primaryIconTheme {
    if (primaryColorBrightness == ThemeBrightness.dark)
      return const IconThemeData(color: IconThemeColor.white);
    return const IconThemeData(color: IconThemeColor.black);
  }

  Color get unselectedColor {
    if (brightness == ThemeBrightness.dark)
      return Colors.white70;
    return Colors.black54;
  }

  Color get disabledColor {
    if (brightness == ThemeBrightness.dark)
      return Colors.white30;
    return Colors.black26;
  }

  /// The foreground color for widgets (knobs, text, etc)
  Color get accentColor => _accentColor;
  Color _accentColor;

  /// The brightness of the accentColor. Used to determine the colour of text
  /// and icons placed on top of the accent color (e.g. the icons on a floating
  /// action button).
  final ThemeBrightness accentColorBrightness;

  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    ThemeData otherData = other;
    return (otherData.brightness == brightness) &&
           (otherData.primarySwatch == primarySwatch) &&
           (otherData.canvasColor == canvasColor) &&
           (otherData.cardColor == cardColor) &&
           (otherData.dividerColor == dividerColor) &&
           (otherData.hintColor == hintColor) &&
           (otherData.highlightColor == highlightColor) &&
           (otherData.hintOpacity == hintOpacity) &&
           (otherData.text == text) &&
           (otherData.primaryColorBrightness == primaryColorBrightness) &&
           (otherData.accentColorBrightness == accentColorBrightness);
  }
  int get hashCode {
    int value = 373;
    value = 37 * value + brightness.hashCode;
    value = 37 * value + primarySwatch.hashCode;
    value = 37 * value + canvasColor.hashCode;
    value = 37 * value + cardColor.hashCode;
    value = 37 * value + dividerColor.hashCode;
    value = 37 * value + hintColor.hashCode;
    value = 37 * value + highlightColor.hashCode;
    value = 37 * value + hintOpacity.hashCode;
    value = 37 * value + text.hashCode;
    value = 37 * value + primaryColorBrightness.hashCode;
    value = 37 * value + accentColorBrightness.hashCode;
    return value;
  }

  String toString() => '$primaryColor $brightness etc...';
}
