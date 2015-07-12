// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/theme/colors.dart' as colors;

enum ThemeBrightness { dark, light }

class ThemeData {

  ThemeData({
    ThemeBrightness brightness,
    Map<int, Color> primarySwatch,
    Color accentColor,
    this.accentColorBrightness: ThemeBrightness.dark,
    typography.TextTheme text })
    : this.brightness = brightness,
      this.primarySwatch = primarySwatch,
      primaryColorBrightness = primarySwatch == null ? brightness : ThemeBrightness.dark,
      canvasColor = brightness == ThemeBrightness.dark ? colors.Grey[850] : colors.Grey[50],
      cardColor = brightness == ThemeBrightness.dark ? colors.Grey[800] : colors.White,
      dividerColor = brightness == ThemeBrightness.dark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      text = brightness == ThemeBrightness.dark ? typography.white : typography.black {
    assert(brightness != null);

    if (primarySwatch == null) {
      if (brightness == ThemeBrightness.dark) {
        _primaryColor = colors.Grey[900];
      } else {
        _primaryColor = colors.Grey[100];
      }
    } else {
      _primaryColor = primarySwatch[500];
    }

    if (accentColor == null) {
      _accentColor = primarySwatch == null ? colors.Blue[500] : primarySwatch[500];
    } else {
      _accentColor = accentColor;
    }
  }

  factory ThemeData.light() => new ThemeData(primarySwatch: colors.Blue, brightness: ThemeBrightness.light);
  factory ThemeData.dark() => new ThemeData(brightness: ThemeBrightness.dark);
  factory ThemeData.fallback() => new ThemeData.light();

  final ThemeBrightness brightness;
  final Map<int, Color> primarySwatch;
  final Color canvasColor;
  final Color cardColor;
  final Color dividerColor;
  final typography.TextTheme text;

  Color _primaryColor;
  Color get primaryColor => _primaryColor;

  final ThemeBrightness primaryColorBrightness;

  Color _accentColor;
  Color get accentColor => _accentColor;

  final ThemeBrightness accentColorBrightness;
}
