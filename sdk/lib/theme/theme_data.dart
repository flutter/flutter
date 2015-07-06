// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'typography.dart' as typography;
import 'colors.dart' as colors;

enum ThemeBrightness { dark, light }

class ThemeData {

  ThemeData({
    ThemeBrightness brightness,
    Map<int, Color> primarySwatch,
    Color accentColor,
    Color floatingActionButtonColor,
    typography.TextTheme text,
    typography.TextTheme toolbarText })
    : this.brightness = brightness,
      this.primarySwatch = primarySwatch,
      canvasColor = brightness == ThemeBrightness.dark ? colors.Grey[850] : colors.Grey[50],
      cardColor = brightness == ThemeBrightness.dark ? colors.Grey[800] : colors.White,
      text = brightness == ThemeBrightness.dark ? typography.white : typography.black {
    assert(brightness != null);

    if (primarySwatch == null) {
      _primaryColor = brightness == ThemeBrightness.dark ? colors.Grey[900] : colors.Grey[100];
    } else {
      _primaryColor = primarySwatch[500];
    }

    if (accentColor == null) {
      _accentColor = primarySwatch == null ? colors.Blue[500] : primarySwatch[500];
    } else {
      _accentColor = accentColor;
    }

    if (floatingActionButtonColor == null) {
      _floatingActionButtonColor = accentColor == null ? colors.PinkAccent[200] : accentColor;
    } else {
      _floatingActionButtonColor = floatingActionButtonColor;
    }

    if (toolbarText == null) {
      if (colors.DarkColors.contains(primarySwatch) || _primaryColor == colors.Grey[900])
        _toolbarText = typography.white;
      else
        _toolbarText = typography.black;
    } else {
      _toolbarText = toolbarText;
    }
  }

  factory ThemeData.light() => new ThemeData(primarySwatch: colors.Blue, brightness: ThemeBrightness.light);
  factory ThemeData.dark() => new ThemeData(brightness: ThemeBrightness.dark);
  factory ThemeData.fallback() => new ThemeData.light();

  final ThemeBrightness brightness;
  final Map<int, Color> primarySwatch;
  final Color canvasColor;
  final Color cardColor;
  final typography.TextTheme text;

  Color _primaryColor;
  Color get primaryColor => _primaryColor;

  Color _accentColor;
  Color get accentColor => _accentColor;

  Color _floatingActionButtonColor;
  Color get floatingActionButtonColor => _floatingActionButtonColor;

  typography.TextTheme _toolbarText;
  typography.TextTheme get toolbarText => _toolbarText;
}
