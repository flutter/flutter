// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE: these tests are originally from package:devtools_app_shared.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/theme/ide_theme.dart';
import 'package:widget_preview_scaffold/src/theme/theme.dart';

void main() {
  group('Theme', () {
    ThemeData theme;

    test('can be used without override', () {
      theme = themeFor(
        isDarkTheme: true,
        ideTheme: IdeTheme(),
        theme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      );
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(darkColorScheme.surface));

      theme = themeFor(
        isDarkTheme: false,
        ideTheme: IdeTheme(),
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      );
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(lightColorScheme.surface));
    });

    test('can be inferred from override background color', () {
      theme = themeFor(
        isDarkTheme: false, // Will be overridden by white BG
        ideTheme: IdeTheme(backgroundColor: Colors.white70),
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      );
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(Colors.white70));

      theme = themeFor(
        isDarkTheme: true, // Will be overridden by black BG
        ideTheme: IdeTheme(backgroundColor: Colors.black),
        theme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      );
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(Colors.black));
    });

    test('will not be inferred for colors that are not dark/light enough', () {
      theme = themeFor(
        isDarkTheme: false, // Will not be overridden - not dark enough
        ideTheme: IdeTheme(backgroundColor: Colors.orange),
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      );
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(lightColorScheme.surface));

      theme = themeFor(
        isDarkTheme: true, // Will not be overridden - not light enough
        ideTheme: IdeTheme(backgroundColor: Colors.orange),
        theme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      );
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(darkColorScheme.surface));
    });
  });
}
