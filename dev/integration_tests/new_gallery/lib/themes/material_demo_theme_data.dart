// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MaterialDemoThemeData {
  static final ThemeData themeData = ThemeData(
    colorScheme: _colorScheme.copyWith(background: Colors.white),
    canvasColor: _colorScheme.background,
    highlightColor: Colors.transparent,
    indicatorColor: _colorScheme.onPrimary,
    scaffoldBackgroundColor: _colorScheme.background,
    secondaryHeaderColor: _colorScheme.background,
    typography: Typography.material2018(platform: defaultTargetPlatform),
    visualDensity: VisualDensity.standard,
    // Component themes
    appBarTheme: AppBarTheme(
      color: _colorScheme.primary,
      iconTheme: IconThemeData(color: _colorScheme.onPrimary),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(color: _colorScheme.primary),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        return states.contains(WidgetState.selected) ? _colorScheme.primary : null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        return states.contains(WidgetState.selected) ? _colorScheme.primary : null;
      }),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        return states.contains(WidgetState.selected) ? _colorScheme.primary : null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        return states.contains(WidgetState.selected) ? _colorScheme.primary.withAlpha(0x80) : null;
      }),
    ),
  );

  static const ColorScheme _colorScheme = ColorScheme(
    primary: Color(0xFF6200EE),
    primaryContainer: Color(0xFF6200EE),
    secondary: Color(0xFFFF5722),
    secondaryContainer: Color(0xFFFF5722),
    background: Colors.white,
    surface: Color(0xFFF2F2F2),
    onBackground: Colors.black,
    onSurface: Colors.black,
    error: Colors.red,
    onError: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    brightness: Brightness.light,
  );
}
