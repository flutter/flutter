// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'typography.dart' as typography;
import 'colors.dart' as colors;

class ThemeData {

  ThemeData.light({
    this.primary,
    this.accent,
    bool darkToolbar: false })
    : toolbarText = darkToolbar ? typography.white : typography.black,
      text = typography.black,
      backgroundColor = colors.Grey[50],
      dialogColor = colors.White;

  ThemeData.dark({ this.primary, this.accent })
    : toolbarText = typography.white,
      text = typography.white,
      backgroundColor = colors.Grey[850],
      dialogColor = colors.Grey[800];

  ThemeData.fallback()
    : primary = colors.Indigo,
      accent = colors.PinkAccent,
      toolbarText = typography.white,
      text = typography.black,
      backgroundColor = colors.Grey[50],
      dialogColor = colors.White;

  final Map<int, Color> primary;
  final Map<int, Color> accent;
  final typography.TextTheme text;
  final typography.TextTheme toolbarText;
  final Color backgroundColor;
  final Color dialogColor;
}
