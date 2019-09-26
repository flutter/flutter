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

  testWidgets('ThemeData.from a light color scheme sets appropriate values', (WidgetTester tester) async {
    const ColorScheme lightColors = ColorScheme.light();
    final ThemeData theme = ThemeData.from(colorScheme: lightColors);

    expect(theme.brightness, equals(Brightness.light));
    expect(theme.primaryColor, equals(lightColors.primary));
    expect(theme.accentColor, equals(lightColors.secondary));
    expect(theme.cardColor, equals(lightColors.surface));
    expect(theme.backgroundColor, equals(lightColors.background));
    expect(theme.canvasColor, equals(lightColors.background));
    expect(theme.scaffoldBackgroundColor, equals(lightColors.background));
    expect(theme.dialogBackgroundColor, equals(lightColors.background));
    expect(theme.errorColor, equals(lightColors.error));
    expect(theme.applyElevationOverlayColor, isFalse);
  });

  testWidgets('ThemeData.from a dark color scheme sets appropriate values', (WidgetTester tester) async {
    const ColorScheme darkColors = ColorScheme.dark();
    final ThemeData theme = ThemeData.from(colorScheme: darkColors);

    expect(theme.brightness, equals(Brightness.dark));
    // in dark theme's the color used for main components is surface instead of primary
    expect(theme.primaryColor, equals(darkColors.surface));
    expect(theme.accentColor, equals(darkColors.secondary));
    expect(theme.cardColor, equals(darkColors.surface));
    expect(theme.backgroundColor, equals(darkColors.background));
    expect(theme.canvasColor, equals(darkColors.background));
    expect(theme.scaffoldBackgroundColor, equals(darkColors.background));
    expect(theme.dialogBackgroundColor, equals(darkColors.background));
    expect(theme.errorColor, equals(darkColors.error));
    expect(theme.applyElevationOverlayColor, isTrue);
  });

  testWidgets('ThemeData.copyWith correctly creates new ThemeData with all copied arguments', (WidgetTester tester) async {
    final ThemeData theme = ThemeData.light();
    final ThemeData darkTheme = ThemeData.dark();

    final ThemeData themeDataCopy = theme.copyWith(
      brightness: darkTheme.brightness,
      primaryColor: darkTheme.primaryColor,
      primaryColorBrightness: darkTheme.primaryColorBrightness,
      primaryColorLight: darkTheme.primaryColorLight,
      primaryColorDark: darkTheme.primaryColorDark,
      accentColor: darkTheme.accentColor,
      accentColorBrightness: darkTheme.accentColorBrightness,
      canvasColor: darkTheme.canvasColor,
      scaffoldBackgroundColor: darkTheme.scaffoldBackgroundColor,
      bottomAppBarColor: darkTheme.bottomAppBarColor,
      cardColor: darkTheme.cardColor,
      dividerColor: darkTheme.dividerColor,
      focusColor: darkTheme.focusColor,
      hoverColor: darkTheme.hoverColor,
      highlightColor: darkTheme.highlightColor,
      splashColor: darkTheme.splashColor,
      splashFactory: darkTheme.splashFactory,
      selectedRowColor: darkTheme.selectedRowColor,
      unselectedWidgetColor: darkTheme.unselectedWidgetColor,
      disabledColor: darkTheme.disabledColor,
      buttonTheme: darkTheme.buttonTheme,
      toggleButtonsTheme: darkTheme.toggleButtonsTheme,
      buttonColor: darkTheme.buttonColor,
      secondaryHeaderColor: darkTheme.secondaryHeaderColor,
      textSelectionColor: darkTheme.textSelectionColor,
      cursorColor: darkTheme.cursorColor,
      textSelectionHandleColor: darkTheme.textSelectionHandleColor,
      backgroundColor: darkTheme.backgroundColor,
      dialogBackgroundColor: darkTheme.dialogBackgroundColor,
      indicatorColor: darkTheme.indicatorColor,
      hintColor: darkTheme.hintColor,
      errorColor : darkTheme.errorColor ,
      toggleableActiveColor : darkTheme.toggleableActiveColor ,
      textTheme : darkTheme.textTheme ,
      primaryTextTheme : darkTheme.primaryTextTheme ,
      accentTextTheme : darkTheme.accentTextTheme ,
      inputDecorationTheme : darkTheme.inputDecorationTheme ,
      iconTheme : darkTheme.iconTheme ,
      primaryIconTheme : darkTheme.primaryIconTheme ,
      accentIconTheme : darkTheme.accentIconTheme ,
      sliderTheme : darkTheme.sliderTheme ,
      tabBarTheme : darkTheme.tabBarTheme ,
      tooltipTheme : darkTheme.tooltipTheme ,
      cardTheme : darkTheme.cardTheme ,
      chipTheme : darkTheme.chipTheme ,
      platform : darkTheme.platform ,
      materialTapTargetSize : darkTheme.materialTapTargetSize ,
      applyElevationOverlayColor : darkTheme.applyElevationOverlayColor ,
      pageTransitionsTheme : darkTheme.pageTransitionsTheme ,
      appBarTheme : darkTheme.appBarTheme ,
      bottomAppBarTheme : darkTheme.bottomAppBarTheme ,
      colorScheme : darkTheme.colorScheme ,
      dialogTheme : darkTheme.dialogTheme ,
      floatingActionButtonTheme : darkTheme.floatingActionButtonTheme ,
      typography : darkTheme.typography ,
      cupertinoOverrideTheme : darkTheme.cupertinoOverrideTheme ,
      snackBarTheme : darkTheme.snackBarTheme ,
      bottomSheetTheme : darkTheme.bottomSheetTheme ,
      bannerTheme : darkTheme.bannerTheme ,
      dividerTheme : darkTheme.dividerTheme ,
      buttonBarTheme : darkTheme.buttonBarTheme ,
    );

    expect(themeDataCopy.brightness, equals(darkTheme.brightness));
    expect(themeDataCopy.primaryColor, equals(darkTheme.primaryColor));
    expect(themeDataCopy.primaryColorBrightness, equals(darkTheme.primaryColorBrightness));
    expect(themeDataCopy.primaryColorLight, equals(darkTheme.primaryColorLight));
    expect(themeDataCopy.primaryColorDark, equals(darkTheme.primaryColorDark));
    expect(themeDataCopy.accentColor, equals(darkTheme.accentColor));
    expect(themeDataCopy.accentColorBrightness, equals(darkTheme.accentColorBrightness));
    expect(themeDataCopy.canvasColor, equals(darkTheme.canvasColor));
    expect(themeDataCopy.scaffoldBackgroundColor, equals(darkTheme.scaffoldBackgroundColor));
    expect(themeDataCopy.bottomAppBarColor, equals(darkTheme.bottomAppBarColor));
    expect(themeDataCopy.canvasColor, equals(darkTheme.canvasColor));
    expect(themeDataCopy.scaffoldBackgroundColor, equals(darkTheme.scaffoldBackgroundColor));
    expect(themeDataCopy.bottomAppBarColor, equals(darkTheme.bottomAppBarColor));
    expect(themeDataCopy.cardColor, equals(darkTheme.cardColor));
    expect(themeDataCopy.dividerColor, equals(darkTheme.dividerColor));
    expect(themeDataCopy.focusColor, equals(darkTheme.focusColor));
    expect(themeDataCopy.focusColor, equals(darkTheme.focusColor));
    expect(themeDataCopy.hoverColor, equals(darkTheme.hoverColor));
    expect(themeDataCopy.highlightColor, equals(darkTheme.highlightColor));
    expect(themeDataCopy.splashColor, equals(darkTheme.splashColor));
    expect(themeDataCopy.splashFactory, equals(darkTheme.splashFactory));
    expect(themeDataCopy.selectedRowColor, equals(darkTheme.selectedRowColor));
    expect(themeDataCopy.unselectedWidgetColor, equals(darkTheme.unselectedWidgetColor));
    expect(themeDataCopy.disabledColor, equals(darkTheme.disabledColor));
    expect(themeDataCopy.buttonTheme, equals(darkTheme.buttonTheme));
    expect(themeDataCopy.toggleButtonsTheme, equals(darkTheme.toggleButtonsTheme));
    expect(themeDataCopy.buttonColor, equals(darkTheme.buttonColor));
    expect(themeDataCopy.secondaryHeaderColor, equals(darkTheme.secondaryHeaderColor));
    expect(themeDataCopy.textSelectionColor, equals(darkTheme.textSelectionColor));
    expect(themeDataCopy.cursorColor, equals(darkTheme.cursorColor));
    expect(themeDataCopy.textSelectionColor, equals(darkTheme.textSelectionColor));
    expect(themeDataCopy.cursorColor, equals(darkTheme.cursorColor));
    expect(themeDataCopy.textSelectionHandleColor, equals(darkTheme.textSelectionHandleColor));
    expect(themeDataCopy.backgroundColor, equals(darkTheme.backgroundColor));
    expect(themeDataCopy.dialogBackgroundColor, equals(darkTheme.dialogBackgroundColor));
    expect(themeDataCopy.indicatorColor, equals(darkTheme.indicatorColor));
    expect(themeDataCopy.hintColor, equals(darkTheme.hintColor));
    expect(themeDataCopy.errorColor, equals(darkTheme.errorColor));
    expect(themeDataCopy.toggleableActiveColor, equals(darkTheme.accentColor));
    expect(themeDataCopy.textTheme, equals(darkTheme.textTheme));
    expect(themeDataCopy.primaryTextTheme, equals(darkTheme.primaryTextTheme));
    expect(themeDataCopy.accentTextTheme, equals(darkTheme.accentTextTheme));
    expect(themeDataCopy.sliderTheme, equals(darkTheme.sliderTheme));
    expect(themeDataCopy.tabBarTheme, equals(darkTheme.tabBarTheme));
    expect(themeDataCopy.tooltipTheme, equals(darkTheme.tooltipTheme));
    expect(themeDataCopy.cardTheme, equals(darkTheme.cardTheme));
    expect(themeDataCopy.chipTheme, equals(darkTheme.chipTheme));
    expect(themeDataCopy.platform, equals(darkTheme.platform));
    expect(themeDataCopy.materialTapTargetSize, equals(darkTheme.materialTapTargetSize));
    expect(themeDataCopy.applyElevationOverlayColor, equals(darkTheme.applyElevationOverlayColor));
    expect(themeDataCopy.pageTransitionsTheme, equals(darkTheme.pageTransitionsTheme));
    expect(themeDataCopy.appBarTheme, equals(darkTheme.appBarTheme));
    expect(themeDataCopy.bottomAppBarTheme, equals(darkTheme.bottomAppBarTheme));
    expect(themeDataCopy.colorScheme, equals(darkTheme.colorScheme));
    expect(themeDataCopy.dialogTheme, equals(darkTheme.dialogTheme));
    expect(themeDataCopy.floatingActionButtonTheme, equals(darkTheme.floatingActionButtonTheme));
    expect(themeDataCopy.typography, equals(darkTheme.typography));
    expect(themeDataCopy.cupertinoOverrideTheme, equals(darkTheme.cupertinoOverrideTheme));
    expect(themeDataCopy.snackBarTheme, equals(darkTheme.snackBarTheme));
    expect(themeDataCopy.bottomSheetTheme, equals(darkTheme.bottomSheetTheme));
    expect(themeDataCopy.popupMenuTheme, equals(darkTheme.popupMenuTheme));
    expect(themeDataCopy.bannerTheme, equals(darkTheme.bannerTheme));
    expect(themeDataCopy.dividerTheme, equals(darkTheme.dividerTheme));
    expect(themeDataCopy.buttonBarTheme, equals(darkTheme.buttonBarTheme));
  });

}
