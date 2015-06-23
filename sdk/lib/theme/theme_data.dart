// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'typography.dart' as typography;
import 'colors.dart' as colors;

enum ThemeBrightness { dark, light }

class ThemeData {

  ThemeData.light({
    this.primary,
    this.accent,
    bool darkToolbar: false })
    : brightness = ThemeBrightness.light,
      toolbarText = darkToolbar ? typography.white : typography.black,
      text = typography.black;

  ThemeData.dark({ this.primary, this.accent })
    : brightness = ThemeBrightness.dark,
      toolbarText = typography.white,
      text = typography.white;

  ThemeData.fallback()
    : brightness = ThemeBrightness.light,
      primary = colors.Indigo,
      accent = colors.PinkAccent,
      toolbarText = typography.white,
      text = typography.black;

  final ThemeBrightness brightness;
  final Map<int, Color> primary;
  final Map<int, Color> accent;
  final typography.TextTheme text;
  final typography.TextTheme toolbarText;
}
