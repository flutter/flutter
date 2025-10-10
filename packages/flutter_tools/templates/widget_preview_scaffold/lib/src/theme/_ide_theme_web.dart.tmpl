// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE: originally from package:devtools_app_shared

import 'dart:ui';

import 'package:web/web.dart';

import '../utils/url/url.dart';
import 'ide_theme.dart';

/// Load any IDE-supplied theming.
IdeTheme getIdeTheme() {
  final queryParams = IdeThemeQueryParams(loadQueryParams());

  final overrides = IdeTheme(
    backgroundColor: queryParams.backgroundColor,
    foregroundColor: queryParams.foregroundColor,
    isDarkMode: queryParams.darkMode,
  );

  // If the environment has provided a background color, set it immediately
  // to avoid a white page until the first Flutter frame is rendered.
  if (overrides.backgroundColor != null) {
    document.body!.style.backgroundColor = toCssHexColor(
      overrides.backgroundColor!,
    );
  }

  return overrides;
}

/// Converts a dart:ui Color into #RRGGBBAA format for use in CSS.
String toCssHexColor(Color color) {
  // In CSS Hex, Alpha comes last, but in Flutter's `value` field, alpha is
  // in the high bytes, so just using `value.toRadixString(16)` will put alpha
  // in the wrong position.
  String hex(double channelValue) =>
      (channelValue * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${hex(color.r)}${hex(color.g)}${hex(color.b)}${hex(color.a)}';
}
