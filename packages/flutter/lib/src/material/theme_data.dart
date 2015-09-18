// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'package:sky/src/material/typography.dart';
import 'package:sky/src/material/colors.dart';

enum ThemeBrightness { dark, light }

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
      // TODO(eseidel): Where are highlight and selected colors documented?
      // I flipped highlight/selected to match the News app (which is clearly not quite Material)
      // Gmail has an interesting behavior of showing selected darker until
      // you click on a different drawer item when the first one loses its
      // selected color and becomes lighter, the ink then fills to make the new
      // click dark to match the previous (resting) selected state.  States
      // revert when you cancel the tap.
      highlightColor = const Color(0x33999999),
      selectedColor = const Color(0x66999999),
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

  final ThemeBrightness brightness;
  final Map<int, Color> primarySwatch;
  final Color canvasColor;
  final Color cardColor;
  final Color dividerColor;
  final Color hintColor;
  final Color highlightColor;
  final Color selectedColor;
  final double hintOpacity;
  final TextTheme text;

  Color _primaryColor;
  Color get primaryColor => _primaryColor;

  final ThemeBrightness primaryColorBrightness;

  Color _accentColor;
  Color get accentColor => _accentColor;

  final ThemeBrightness accentColorBrightness;
}
