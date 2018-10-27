// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Theme data control test', () {
    final ThemeData dark = ThemeData.dark();

    expect(dark, hasOneLineDescription);
    expect(dark, equals(dark.copyWith()));
    expect(dark.hashCode, equals(dark.copyWith().hashCode));

    final ThemeData light = ThemeData.light();
    final ThemeData dawn = ThemeData.lerp(dark, light, 0.25);

    expect(dawn.brightness, Brightness.dark);
    expect(dawn.primaryColor, Color.lerp(dark.primaryColor, light.primaryColor, 0.25));
  });

  test('Defaults to the default typography for the platform', () {
    for (TargetPlatform platform in TargetPlatform.values) {
      final ThemeData theme = ThemeData(platform: platform);
      final Typography typography = Typography(platform: platform);
      expect(theme.textTheme, typography.black.apply(decoration: TextDecoration.none),
          reason: 'Not using default typography for $platform');
    }
  });

  test('Default text theme contrasts with brightness', () {
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.textTheme.title.color, typography.black.title.color);
    expect(darkTheme.textTheme.title.color, typography.white.title.color);
  });

  test('Default primary text theme contrasts with primary brightness', () {
    final ThemeData lightTheme = ThemeData(primaryColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(primaryColorBrightness: Brightness.dark);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.primaryTextTheme.title.color, typography.white.title.color);
  });

  test('Default accent text theme contrasts with accent brightness', () {
    final ThemeData lightTheme = ThemeData(accentColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(accentColorBrightness: Brightness.dark);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.accentTextTheme.title.color, typography.white.title.color);
  });

  test('Default slider indicator style gets a default body2 if accentTextTheme.body2 is null', () {
    const TextTheme noBody2TextTheme = TextTheme(body2: null);
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light, accentTextTheme: noBody2TextTheme);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark, accentTextTheme: noBody2TextTheme);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.sliderTheme.valueIndicatorTextStyle, equals(typography.white.body2));
    expect(darkTheme.sliderTheme.valueIndicatorTextStyle, equals(typography.black.body2));
  });

  test('Default chip label style gets a default body2 if textTheme.body2 is null', () {
    const TextTheme noBody2TextTheme = TextTheme(body2: null);
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light, textTheme: noBody2TextTheme);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark, textTheme: noBody2TextTheme);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.chipTheme.labelStyle.color, equals(typography.black.body2.color.withAlpha(0xde)));
    expect(darkTheme.chipTheme.labelStyle.color, equals(typography.white.body2.color.withAlpha(0xde)));
  });

  test('Default icon theme contrasts with brightness', () {
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.textTheme.title.color, typography.black.title.color);
    expect(darkTheme.textTheme.title.color, typography.white.title.color);
  });

  test('Default primary icon theme contrasts with primary brightness', () {
    final ThemeData lightTheme = ThemeData(primaryColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(primaryColorBrightness: Brightness.dark);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.primaryTextTheme.title.color, typography.white.title.color);
  });

  test('Default accent icon theme contrasts with accent brightness', () {
    final ThemeData lightTheme = ThemeData(accentColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(accentColorBrightness: Brightness.dark);
    final Typography typography = Typography(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.title.color, typography.black.title.color);
    expect(darkTheme.accentTextTheme.title.color, typography.white.title.color);
  });

  test('Defaults to MaterialTapTargetBehavior.expanded', () {
    final ThemeData themeData = ThemeData();

    expect(themeData.materialTapTargetSize, MaterialTapTargetSize.padded);
  });

  test('Can control fontFamily', () {
    final ThemeData themeData = ThemeData(fontFamily: 'Ahem');

    expect(themeData.textTheme.body2.fontFamily, equals('Ahem'));
    expect(themeData.primaryTextTheme.title.fontFamily, equals('Ahem'));
    expect(themeData.accentTextTheme.display4.fontFamily, equals('Ahem'));
  });

  test('Can estimate brightness - directly', () {
    expect(ThemeData.estimateBrightnessForColor(Colors.white), equals(Brightness.light));
    expect(ThemeData.estimateBrightnessForColor(Colors.black), equals(Brightness.dark));
    expect(ThemeData.estimateBrightnessForColor(Colors.blue), equals(Brightness.dark));
    expect(ThemeData.estimateBrightnessForColor(Colors.yellow), equals(Brightness.light));
    expect(ThemeData.estimateBrightnessForColor(Colors.deepOrange), equals(Brightness.dark));
    expect(ThemeData.estimateBrightnessForColor(Colors.orange), equals(Brightness.light));
    expect(ThemeData.estimateBrightnessForColor(Colors.lime), equals(Brightness.light));
    expect(ThemeData.estimateBrightnessForColor(Colors.grey), equals(Brightness.light));
    expect(ThemeData.estimateBrightnessForColor(Colors.teal), equals(Brightness.dark));
    expect(ThemeData.estimateBrightnessForColor(Colors.indigo), equals(Brightness.dark));
  });

  test('Can estimate brightness - indirectly', () {
    expect(ThemeData(primaryColor: Colors.white).primaryColorBrightness, equals(Brightness.light));
    expect(ThemeData(primaryColor: Colors.black).primaryColorBrightness, equals(Brightness.dark));
    expect(ThemeData(primaryColor: Colors.blue).primaryColorBrightness, equals(Brightness.dark));
    expect(ThemeData(primaryColor: Colors.yellow).primaryColorBrightness, equals(Brightness.light));
    expect(ThemeData(primaryColor: Colors.deepOrange).primaryColorBrightness, equals(Brightness.dark));
    expect(ThemeData(primaryColor: Colors.orange).primaryColorBrightness, equals(Brightness.light));
    expect(ThemeData(primaryColor: Colors.lime).primaryColorBrightness, equals(Brightness.light));
    expect(ThemeData(primaryColor: Colors.grey).primaryColorBrightness, equals(Brightness.light));
    expect(ThemeData(primaryColor: Colors.teal).primaryColorBrightness, equals(Brightness.dark));
    expect(ThemeData(primaryColor: Colors.indigo).primaryColorBrightness, equals(Brightness.dark));
  });

  test('cursorColor', () {
    expect(ThemeData(cursorColor: Colors.red).cursorColor, Colors.red);
  });
}
