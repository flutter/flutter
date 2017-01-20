// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Theme data control test', () {
    ThemeData dark = new ThemeData.dark();

    expect(dark, hasOneLineDescription);
    expect(dark, equals(dark.copyWith()));
    expect(dark.hashCode, equals(dark.copyWith().hashCode));

    ThemeData light = new ThemeData.light();
    ThemeData dawn = ThemeData.lerp(dark, light, 0.25);

    expect(dawn.brightness, Brightness.dark);
    expect(dawn.primaryColor, Color.lerp(dark.primaryColor, light.primaryColor, 0.25));
  });

  test('Defaults to the default typography for the platform', () {
    for (TargetPlatform platform in TargetPlatform.values) {
      ThemeData theme = new ThemeData(platform: platform);
      Typography typography = new Typography(platform: platform);
      expect(theme.textTheme, typography.black, reason: 'Not using default typography for $platform');
    }
  });

  test('Default text theme contrasts with brightness', () {
    ThemeData lightTheme = new ThemeData(brightness: Brightness.light);
    ThemeData darkTheme = new ThemeData(brightness: Brightness.dark);
    Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.textTheme.title.color, typography.black.title.color);
    expect(darkTheme.textTheme.title.color, typography.white.title.color);
  });

  test('Default primary text theme contrasts with primary brightness', () {
    ThemeData lightTheme = new ThemeData(primaryColorBrightness: Brightness.light);
    ThemeData darkTheme = new ThemeData(primaryColorBrightness: Brightness.dark);
    Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.primaryTextTheme.title.color, typography.white.title.color);
  });

  test('Default accent text theme contrasts with accent brightness', () {
    ThemeData lightTheme = new ThemeData(accentColorBrightness: Brightness.light);
    ThemeData darkTheme = new ThemeData(accentColorBrightness: Brightness.dark);
    Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.accentTextTheme.title.color, typography.white.title.color);
  });

  test('Default icon theme contrasts with brightness', () {
    ThemeData lightTheme = new ThemeData(brightness: Brightness.light);
    ThemeData darkTheme = new ThemeData(brightness: Brightness.dark);
    Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.textTheme.title.color, typography.black.title.color);
    expect(darkTheme.textTheme.title.color, typography.white.title.color);
  });

  test('Default primary icon theme contrasts with primary brightness', () {
    ThemeData lightTheme = new ThemeData(primaryColorBrightness: Brightness.light);
    ThemeData darkTheme = new ThemeData(primaryColorBrightness: Brightness.dark);
    Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.primaryTextTheme.title.color, typography.white.title.color);
  });

  test('Default accent icon theme contrasts with accent brightness', () {
    ThemeData lightTheme = new ThemeData(accentColorBrightness: Brightness.light);
    ThemeData darkTheme = new ThemeData(accentColorBrightness: Brightness.dark);
    Typography typography = new Typography(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.accentTextTheme.title.color, typography.white.title.color);
  });
}
