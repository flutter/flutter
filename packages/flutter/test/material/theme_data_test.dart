// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Theme data control test', () {
    final ThemeData dark = new ThemeData.dark();

    expect(dark, hasOneLineDescription);
    expect(dark, equals(dark.copyWith()));
    expect(dark.hashCode, equals(dark.copyWith().hashCode));

    final ThemeData light = new ThemeData.light();
    final ThemeData dawn = ThemeData.lerp(dark, light, 0.25);

    expect(dawn.brightness, Brightness.dark);
    expect(dawn.primaryColor, Color.lerp(dark.primaryColor, light.primaryColor, 0.25));
  });

  test('Defaults to the default typography for the platform', () {
    for (TargetPlatform platform in TargetPlatform.values) {
      final ThemeData theme = new ThemeData(platform: platform);
      final Typography typography = new Typography(platform: platform);
      expect(theme.textTheme, typography.black, reason: 'Not using default typography for $platform');
    }
  });

  test('Default text theme contrasts with brightness', () {
    final ThemeData lightTheme = new ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = new ThemeData(brightness: Brightness.dark);
    final Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.textTheme.title.color, typography.black.title.color);
    expect(darkTheme.textTheme.title.color, typography.white.title.color);
  });

  test('Default primary text theme contrasts with primary brightness', () {
    final ThemeData lightTheme = new ThemeData(primaryColorBrightness: Brightness.light);
    final ThemeData darkTheme = new ThemeData(primaryColorBrightness: Brightness.dark);
    final Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.primaryTextTheme.title.color, typography.white.title.color);
  });

  test('Default accent text theme contrasts with accent brightness', () {
    final ThemeData lightTheme = new ThemeData(accentColorBrightness: Brightness.light);
    final ThemeData darkTheme = new ThemeData(accentColorBrightness: Brightness.dark);
    final Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.accentTextTheme.title.color, typography.white.title.color);
  });

  test('Default icon theme contrasts with brightness', () {
    final ThemeData lightTheme = new ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = new ThemeData(brightness: Brightness.dark);
    final Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.textTheme.title.color, typography.black.title.color);
    expect(darkTheme.textTheme.title.color, typography.white.title.color);
  });

  test('Default primary icon theme contrasts with primary brightness', () {
    final ThemeData lightTheme = new ThemeData(primaryColorBrightness: Brightness.light);
    final ThemeData darkTheme = new ThemeData(primaryColorBrightness: Brightness.dark);
    final Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.primaryTextTheme.title.color, typography.white.title.color);
  });

  test('Default accent icon theme contrasts with accent brightness', () {
    final ThemeData lightTheme = new ThemeData(accentColorBrightness: Brightness.light);
    final ThemeData darkTheme = new ThemeData(accentColorBrightness: Brightness.dark);
    final Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.accentTextTheme.title.color, typography.white.title.color);
  });

  test('Can control fontFamily', () {
    final ThemeData themeData = new ThemeData(fontFamily: 'Ahem');

    expect(themeData.textTheme.body2.fontFamily, equals('Ahem'));
    expect(themeData.primaryTextTheme.title.fontFamily, equals('Ahem'));
    expect(themeData.accentTextTheme.display4.fontFamily, equals('Ahem'));
  });

  test('Can estimate brightness', () {
    expect(new ThemeData(primaryColor: Colors.white).primaryColorBrightness, equals(Brightness.light));
    expect(new ThemeData(primaryColor: Colors.black).primaryColorBrightness, equals(Brightness.dark));
    expect(new ThemeData(primaryColor: Colors.blue).primaryColorBrightness, equals(Brightness.dark));
    expect(new ThemeData(primaryColor: Colors.yellow).primaryColorBrightness, equals(Brightness.light));
    expect(new ThemeData(primaryColor: Colors.deepOrange).primaryColorBrightness, equals(Brightness.dark));
    expect(new ThemeData(primaryColor: Colors.orange).primaryColorBrightness, equals(Brightness.light));
    expect(new ThemeData(primaryColor: Colors.lime).primaryColorBrightness, equals(Brightness.light));
    expect(new ThemeData(primaryColor: Colors.grey).primaryColorBrightness, equals(Brightness.light));
    expect(new ThemeData(primaryColor: Colors.teal).primaryColorBrightness, equals(Brightness.dark));
    expect(new ThemeData(primaryColor: Colors.indigo).primaryColorBrightness, equals(Brightness.dark));
  });
}
