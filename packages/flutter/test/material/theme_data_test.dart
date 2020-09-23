// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
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
    for (final TargetPlatform platform in TargetPlatform.values) {
      final ThemeData theme = ThemeData(platform: platform);
      final Typography typography = Typography.material2018(platform: platform);
      expect(theme.textTheme, typography.black.apply(decoration: TextDecoration.none),
          reason: 'Not using default typography for $platform');
    }
  });

  test('Default text theme contrasts with brightness', () {
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.textTheme.headline6.color, typography.black.headline6.color);
    expect(darkTheme.textTheme.headline6.color, typography.white.headline6.color);
  });

  test('Default primary text theme contrasts with primary brightness', () {
    final ThemeData lightTheme = ThemeData(primaryColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(primaryColorBrightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.headline6.color, typography.black.headline6.color);
    expect(darkTheme.primaryTextTheme.headline6.color, typography.white.headline6.color);
  });

  test('Default accent text theme contrasts with accent brightness', () {
    final ThemeData lightTheme = ThemeData(accentColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(accentColorBrightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.headline6.color, typography.black.headline6.color);
    expect(darkTheme.accentTextTheme.headline6.color, typography.white.headline6.color);
  });

  test('Default chip label style gets a default bodyText1 if textTheme.bodyText1 is null', () {
    const TextTheme noBodyText1TextTheme = TextTheme(bodyText1: null);
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light, textTheme: noBodyText1TextTheme);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark, textTheme: noBodyText1TextTheme);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.chipTheme.labelStyle.color, equals(typography.black.bodyText1.color.withAlpha(0xde)));
    expect(darkTheme.chipTheme.labelStyle.color, equals(typography.white.bodyText1.color.withAlpha(0xde)));
  });

  test('Default icon theme contrasts with brightness', () {
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.textTheme.headline6.color, typography.black.headline6.color);
    expect(darkTheme.textTheme.headline6.color, typography.white.headline6.color);
  });

  test('Default primary icon theme contrasts with primary brightness', () {
    final ThemeData lightTheme = ThemeData(primaryColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(primaryColorBrightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.headline6.color, typography.black.headline6.color);
    expect(darkTheme.primaryTextTheme.headline6.color, typography.white.headline6.color);
  });

  test('Default accent icon theme contrasts with accent brightness', () {
    final ThemeData lightTheme = ThemeData(accentColorBrightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(accentColorBrightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.accentTextTheme.headline6.color, typography.black.headline6.color);
    expect(darkTheme.accentTextTheme.headline6.color, typography.white.headline6.color);
  });

  test('Defaults to MaterialTapTargetBehavior.expanded', () {
    final ThemeData themeData = ThemeData();

    expect(themeData.materialTapTargetSize, MaterialTapTargetSize.padded);
  });

  test('Can control fontFamily default', () {
    final ThemeData themeData = ThemeData(
      fontFamily: 'Ahem',
      textTheme: const TextTheme(
        headline6: TextStyle(fontFamily: 'Roboto'),
      ),
    );

    expect(themeData.textTheme.bodyText1.fontFamily, equals('Ahem'));
    expect(themeData.primaryTextTheme.headline3.fontFamily, equals('Ahem'));
    expect(themeData.accentTextTheme.headline1.fontFamily, equals('Ahem'));

    // Shouldn't override the specified style's family
    expect(themeData.textTheme.headline6.fontFamily, equals('Roboto'));
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

  testWidgets('VisualDensity.adaptivePlatformDensity returns adaptive values', (WidgetTester tester) async {
    switch (debugDefaultTargetPlatformOverride) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        expect(VisualDensity.adaptivePlatformDensity, equals(const VisualDensity()));
        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        expect(VisualDensity.adaptivePlatformDensity, equals(VisualDensity.compact));
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets('ThemeData.copyWith correctly creates new ThemeData with all copied arguments', (WidgetTester tester) async {

    final SliderThemeData sliderTheme = SliderThemeData.fromPrimaryColors(
      primaryColor: Colors.black,
      primaryColorDark: Colors.black,
      primaryColorLight: Colors.black,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    );

    final ChipThemeData chipTheme = ChipThemeData.fromDefaults(
      primaryColor: Colors.black,
      secondaryColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black),
    );

    const PageTransitionsTheme pageTransitionTheme = PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    );

    final ThemeData theme = ThemeData.raw(
      visualDensity: const VisualDensity(),
      primaryColor: Colors.black,
      primaryColorBrightness: Brightness.dark,
      primaryColorLight: Colors.black,
      primaryColorDark: Colors.black,
      accentColor: Colors.black,
      accentColorBrightness: Brightness.dark,
      canvasColor: Colors.black,
      shadowColor: Colors.black,
      scaffoldBackgroundColor: Colors.black,
      bottomAppBarColor: Colors.black,
      cardColor: Colors.black,
      dividerColor: Colors.black,
      focusColor: Colors.black,
      hoverColor: Colors.black,
      highlightColor: Colors.black,
      splashColor: Colors.black,
      splashFactory: InkRipple.splashFactory,
      selectedRowColor: Colors.black,
      unselectedWidgetColor: Colors.black,
      disabledColor: Colors.black,
      buttonTheme: const ButtonThemeData(colorScheme: ColorScheme.dark()),
      toggleButtonsTheme: const ToggleButtonsThemeData(textStyle: TextStyle(color: Colors.black)),
      buttonColor: Colors.black,
      secondaryHeaderColor: Colors.black,
      textSelectionColor: Colors.black,
      cursorColor: Colors.black,
      textSelectionHandleColor: Colors.black,
      backgroundColor: Colors.black,
      dialogBackgroundColor: Colors.black,
      indicatorColor: Colors.black,
      hintColor: Colors.black,
      errorColor: Colors.black,
      toggleableActiveColor: Colors.black,
      textTheme: ThemeData.dark().textTheme,
      primaryTextTheme: ThemeData.dark().textTheme,
      accentTextTheme: ThemeData.dark().textTheme,
      inputDecorationTheme: ThemeData.dark().inputDecorationTheme.copyWith(border: const OutlineInputBorder()),
      iconTheme: ThemeData.dark().iconTheme,
      primaryIconTheme: ThemeData.dark().iconTheme,
      accentIconTheme: ThemeData.dark().iconTheme,
      sliderTheme: sliderTheme,
      tabBarTheme: const TabBarTheme(labelColor: Colors.black),
      tooltipTheme: const TooltipThemeData(height: 100),
      cardTheme: const CardTheme(color: Colors.black),
      chipTheme: chipTheme,
      platform: TargetPlatform.iOS,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      applyElevationOverlayColor: false,
      pageTransitionsTheme: pageTransitionTheme,
      appBarTheme: const AppBarTheme(color: Colors.black),
      bottomAppBarTheme: const BottomAppBarTheme(color: Colors.black),
      colorScheme: const ColorScheme.light(),
      dialogTheme: const DialogTheme(backgroundColor: Colors.black),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.black),
      navigationRailTheme: const NavigationRailThemeData(backgroundColor: Colors.black),
      typography: Typography.material2018(platform: TargetPlatform.android),
      cupertinoOverrideTheme: null,
      snackBarTheme: const SnackBarThemeData(backgroundColor: Colors.black),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.black),
      popupMenuTheme: const PopupMenuThemeData(color: Colors.black),
      bannerTheme: const MaterialBannerThemeData(backgroundColor: Colors.black),
      dividerTheme: const DividerThemeData(color: Colors.black),
      buttonBarTheme: const ButtonBarThemeData(alignment: MainAxisAlignment.start),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(type: BottomNavigationBarType.fixed),
      timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.black),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(primary: Colors.red)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(primary: Colors.green)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(primary: Colors.blue)),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black),
      dataTableTheme: const DataTableThemeData(),
      fixTextFieldOutlineLabel: false,
      useTextSelectionTheme: false,
    );

    final SliderThemeData otherSliderTheme = SliderThemeData.fromPrimaryColors(
      primaryColor: Colors.white,
      primaryColorDark: Colors.white,
      primaryColorLight: Colors.white,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    );

    final ChipThemeData otherChipTheme = ChipThemeData.fromDefaults(
      primaryColor: Colors.white,
      secondaryColor: Colors.black,
      labelStyle: const TextStyle(color: Colors.white),
    );

    final ThemeData otherTheme = ThemeData.raw(
      visualDensity: const VisualDensity(),
      primaryColor: Colors.white,
      primaryColorBrightness: Brightness.light,
      primaryColorLight: Colors.white,
      primaryColorDark: Colors.white,
      accentColor: Colors.white,
      accentColorBrightness: Brightness.light,
      canvasColor: Colors.white,
      shadowColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      bottomAppBarColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.white,
      focusColor: Colors.white,
      hoverColor: Colors.white,
      highlightColor: Colors.white,
      splashColor: Colors.white,
      splashFactory: InkRipple.splashFactory,
      selectedRowColor: Colors.white,
      unselectedWidgetColor: Colors.white,
      disabledColor: Colors.white,
      buttonTheme: const ButtonThemeData(colorScheme: ColorScheme.light()),
      toggleButtonsTheme: const ToggleButtonsThemeData(textStyle: TextStyle(color: Colors.white)),
      buttonColor: Colors.white,
      secondaryHeaderColor: Colors.white,
      textSelectionColor: Colors.white,
      cursorColor: Colors.white,
      textSelectionHandleColor: Colors.white,
      backgroundColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      indicatorColor: Colors.white,
      hintColor: Colors.white,
      errorColor: Colors.white,
      toggleableActiveColor: Colors.white,
      textTheme: ThemeData.light().textTheme,
      primaryTextTheme: ThemeData.light().textTheme,
      accentTextTheme: ThemeData.light().textTheme,
      inputDecorationTheme: ThemeData.light().inputDecorationTheme.copyWith(border: InputBorder.none),
      iconTheme: ThemeData.light().iconTheme,
      primaryIconTheme: ThemeData.light().iconTheme,
      accentIconTheme: ThemeData.light().iconTheme,
      sliderTheme: otherSliderTheme,
      tabBarTheme: const TabBarTheme(labelColor: Colors.white),
      tooltipTheme: const TooltipThemeData(height: 100),
      cardTheme: const CardTheme(color: Colors.white),
      chipTheme: otherChipTheme,
      platform: TargetPlatform.android,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      applyElevationOverlayColor: true,
      pageTransitionsTheme: const PageTransitionsTheme(),
      appBarTheme: const AppBarTheme(color: Colors.white),
      bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white),
      colorScheme: const ColorScheme.light(),
      dialogTheme: const DialogTheme(backgroundColor: Colors.white),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.white),
      navigationRailTheme: const NavigationRailThemeData(backgroundColor: Colors.white),
      typography: Typography.material2018(platform: TargetPlatform.iOS),
      cupertinoOverrideTheme: ThemeData.light().cupertinoOverrideTheme,
      snackBarTheme: const SnackBarThemeData(backgroundColor: Colors.white),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
      popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
      bannerTheme: const MaterialBannerThemeData(backgroundColor: Colors.white),
      dividerTheme: const DividerThemeData(color: Colors.white),
      buttonBarTheme: const ButtonBarThemeData(alignment: MainAxisAlignment.end),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(type: BottomNavigationBarType.shifting),
      timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
      textButtonTheme: const TextButtonThemeData(),
      elevatedButtonTheme: const ElevatedButtonThemeData(),
      outlinedButtonTheme: const OutlinedButtonThemeData(),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
      dataTableTheme: const DataTableThemeData(),
      fixTextFieldOutlineLabel: true,
      useTextSelectionTheme: true,
    );

    final ThemeData themeDataCopy = theme.copyWith(
      primaryColor: otherTheme.primaryColor,
      primaryColorBrightness: otherTheme.primaryColorBrightness,
      primaryColorLight: otherTheme.primaryColorLight,
      primaryColorDark: otherTheme.primaryColorDark,
      accentColor: otherTheme.accentColor,
      accentColorBrightness: otherTheme.accentColorBrightness,
      canvasColor: otherTheme.canvasColor,
      shadowColor: otherTheme.shadowColor,
      scaffoldBackgroundColor: otherTheme.scaffoldBackgroundColor,
      bottomAppBarColor: otherTheme.bottomAppBarColor,
      cardColor: otherTheme.cardColor,
      dividerColor: otherTheme.dividerColor,
      focusColor: otherTheme.focusColor,
      hoverColor: otherTheme.hoverColor,
      highlightColor: otherTheme.highlightColor,
      splashColor: otherTheme.splashColor,
      splashFactory: otherTheme.splashFactory,
      selectedRowColor: otherTheme.selectedRowColor,
      unselectedWidgetColor: otherTheme.unselectedWidgetColor,
      disabledColor: otherTheme.disabledColor,
      buttonTheme: otherTheme.buttonTheme,
      toggleButtonsTheme: otherTheme.toggleButtonsTheme,
      buttonColor: otherTheme.buttonColor,
      secondaryHeaderColor: otherTheme.secondaryHeaderColor,
      textSelectionColor: otherTheme.textSelectionColor,
      cursorColor: otherTheme.cursorColor,
      textSelectionHandleColor: otherTheme.textSelectionHandleColor,
      backgroundColor: otherTheme.backgroundColor,
      dialogBackgroundColor: otherTheme.dialogBackgroundColor,
      indicatorColor: otherTheme.indicatorColor,
      hintColor: otherTheme.hintColor,
      errorColor: otherTheme.errorColor,
      toggleableActiveColor: otherTheme.toggleableActiveColor,
      textTheme: otherTheme.textTheme,
      primaryTextTheme: otherTheme.primaryTextTheme,
      accentTextTheme: otherTheme.accentTextTheme,
      inputDecorationTheme: otherTheme.inputDecorationTheme,
      iconTheme: otherTheme.iconTheme,
      primaryIconTheme: otherTheme.primaryIconTheme,
      accentIconTheme: otherTheme.accentIconTheme,
      sliderTheme: otherTheme.sliderTheme,
      tabBarTheme: otherTheme.tabBarTheme,
      tooltipTheme: otherTheme.tooltipTheme,
      cardTheme: otherTheme.cardTheme,
      chipTheme: otherTheme.chipTheme,
      platform: otherTheme.platform,
      materialTapTargetSize: otherTheme.materialTapTargetSize,
      applyElevationOverlayColor: otherTheme.applyElevationOverlayColor,
      pageTransitionsTheme: otherTheme.pageTransitionsTheme,
      appBarTheme: otherTheme.appBarTheme,
      bottomAppBarTheme: otherTheme.bottomAppBarTheme,
      colorScheme: otherTheme.colorScheme,
      dialogTheme: otherTheme.dialogTheme,
      floatingActionButtonTheme: otherTheme.floatingActionButtonTheme,
      navigationRailTheme: otherTheme.navigationRailTheme,
      typography: otherTheme.typography,
      cupertinoOverrideTheme: otherTheme.cupertinoOverrideTheme,
      snackBarTheme: otherTheme.snackBarTheme,
      bottomSheetTheme: otherTheme.bottomSheetTheme,
      popupMenuTheme: otherTheme.popupMenuTheme,
      bannerTheme: otherTheme.bannerTheme,
      dividerTheme: otherTheme.dividerTheme,
      buttonBarTheme: otherTheme.buttonBarTheme,
      bottomNavigationBarTheme: otherTheme.bottomNavigationBarTheme,
      timePickerTheme: otherTheme.timePickerTheme,
      textButtonTheme: otherTheme.textButtonTheme,
      elevatedButtonTheme: otherTheme.elevatedButtonTheme,
      outlinedButtonTheme: otherTheme.outlinedButtonTheme,
      textSelectionTheme: otherTheme.textSelectionTheme,
      fixTextFieldOutlineLabel: otherTheme.fixTextFieldOutlineLabel,
      useTextSelectionTheme: otherTheme.useTextSelectionTheme,
    );

    expect(themeDataCopy.brightness, equals(otherTheme.brightness));
    expect(themeDataCopy.primaryColor, equals(otherTheme.primaryColor));
    expect(themeDataCopy.primaryColorBrightness, equals(otherTheme.primaryColorBrightness));
    expect(themeDataCopy.primaryColorLight, equals(otherTheme.primaryColorLight));
    expect(themeDataCopy.primaryColorDark, equals(otherTheme.primaryColorDark));
    expect(themeDataCopy.accentColor, equals(otherTheme.accentColor));
    expect(themeDataCopy.accentColorBrightness, equals(otherTheme.accentColorBrightness));
    expect(themeDataCopy.canvasColor, equals(otherTheme.canvasColor));
    expect(themeDataCopy.shadowColor, equals(otherTheme.shadowColor));
    expect(themeDataCopy.scaffoldBackgroundColor, equals(otherTheme.scaffoldBackgroundColor));
    expect(themeDataCopy.bottomAppBarColor, equals(otherTheme.bottomAppBarColor));
    expect(themeDataCopy.cardColor, equals(otherTheme.cardColor));
    expect(themeDataCopy.dividerColor, equals(otherTheme.dividerColor));
    expect(themeDataCopy.focusColor, equals(otherTheme.focusColor));
    expect(themeDataCopy.focusColor, equals(otherTheme.focusColor));
    expect(themeDataCopy.hoverColor, equals(otherTheme.hoverColor));
    expect(themeDataCopy.highlightColor, equals(otherTheme.highlightColor));
    expect(themeDataCopy.splashColor, equals(otherTheme.splashColor));
    expect(themeDataCopy.splashFactory, equals(otherTheme.splashFactory));
    expect(themeDataCopy.selectedRowColor, equals(otherTheme.selectedRowColor));
    expect(themeDataCopy.unselectedWidgetColor, equals(otherTheme.unselectedWidgetColor));
    expect(themeDataCopy.disabledColor, equals(otherTheme.disabledColor));
    expect(themeDataCopy.buttonTheme, equals(otherTheme.buttonTheme));
    expect(themeDataCopy.toggleButtonsTheme, equals(otherTheme.toggleButtonsTheme));
    expect(themeDataCopy.buttonColor, equals(otherTheme.buttonColor));
    expect(themeDataCopy.secondaryHeaderColor, equals(otherTheme.secondaryHeaderColor));
    expect(themeDataCopy.textSelectionColor, equals(otherTheme.textSelectionColor));
    expect(themeDataCopy.cursorColor, equals(otherTheme.cursorColor));
    expect(themeDataCopy.textSelectionColor, equals(otherTheme.textSelectionColor));
    expect(themeDataCopy.cursorColor, equals(otherTheme.cursorColor));
    expect(themeDataCopy.textSelectionHandleColor, equals(otherTheme.textSelectionHandleColor));
    expect(themeDataCopy.backgroundColor, equals(otherTheme.backgroundColor));
    expect(themeDataCopy.dialogBackgroundColor, equals(otherTheme.dialogBackgroundColor));
    expect(themeDataCopy.indicatorColor, equals(otherTheme.indicatorColor));
    expect(themeDataCopy.hintColor, equals(otherTheme.hintColor));
    expect(themeDataCopy.errorColor, equals(otherTheme.errorColor));
    expect(themeDataCopy.toggleableActiveColor, equals(otherTheme.accentColor));
    expect(themeDataCopy.textTheme, equals(otherTheme.textTheme));
    expect(themeDataCopy.primaryTextTheme, equals(otherTheme.primaryTextTheme));
    expect(themeDataCopy.accentTextTheme, equals(otherTheme.accentTextTheme));
    expect(themeDataCopy.sliderTheme, equals(otherTheme.sliderTheme));
    expect(themeDataCopy.tabBarTheme, equals(otherTheme.tabBarTheme));
    expect(themeDataCopy.tooltipTheme, equals(otherTheme.tooltipTheme));
    expect(themeDataCopy.cardTheme, equals(otherTheme.cardTheme));
    expect(themeDataCopy.chipTheme, equals(otherTheme.chipTheme));
    expect(themeDataCopy.platform, equals(otherTheme.platform));
    expect(themeDataCopy.materialTapTargetSize, equals(otherTheme.materialTapTargetSize));
    expect(themeDataCopy.applyElevationOverlayColor, equals(otherTheme.applyElevationOverlayColor));
    expect(themeDataCopy.pageTransitionsTheme, equals(otherTheme.pageTransitionsTheme));
    expect(themeDataCopy.appBarTheme, equals(otherTheme.appBarTheme));
    expect(themeDataCopy.bottomAppBarTheme, equals(otherTheme.bottomAppBarTheme));
    expect(themeDataCopy.colorScheme, equals(otherTheme.colorScheme));
    expect(themeDataCopy.dialogTheme, equals(otherTheme.dialogTheme));
    expect(themeDataCopy.floatingActionButtonTheme, equals(otherTheme.floatingActionButtonTheme));
    expect(themeDataCopy.navigationRailTheme, equals(otherTheme.navigationRailTheme));
    expect(themeDataCopy.typography, equals(otherTheme.typography));
    expect(themeDataCopy.cupertinoOverrideTheme, equals(otherTheme.cupertinoOverrideTheme));
    expect(themeDataCopy.snackBarTheme, equals(otherTheme.snackBarTheme));
    expect(themeDataCopy.bottomSheetTheme, equals(otherTheme.bottomSheetTheme));
    expect(themeDataCopy.popupMenuTheme, equals(otherTheme.popupMenuTheme));
    expect(themeDataCopy.bannerTheme, equals(otherTheme.bannerTheme));
    expect(themeDataCopy.dividerTheme, equals(otherTheme.dividerTheme));
    expect(themeDataCopy.buttonBarTheme, equals(otherTheme.buttonBarTheme));
    expect(themeDataCopy.bottomNavigationBarTheme, equals(otherTheme.bottomNavigationBarTheme));
    expect(themeDataCopy.timePickerTheme, equals(otherTheme.timePickerTheme));
    expect(themeDataCopy.textButtonTheme, equals(otherTheme.textButtonTheme));
    expect(themeDataCopy.elevatedButtonTheme, equals(otherTheme.elevatedButtonTheme));
    expect(themeDataCopy.outlinedButtonTheme, equals(otherTheme.outlinedButtonTheme));
    expect(themeDataCopy.textSelectionTheme, equals(otherTheme.textSelectionTheme));
    expect(themeDataCopy.fixTextFieldOutlineLabel, equals(otherTheme.fixTextFieldOutlineLabel));
    expect(themeDataCopy.useTextSelectionTheme, equals(otherTheme.useTextSelectionTheme));
  });

  testWidgets('ThemeData.toString has less than 200 characters output', (WidgetTester tester) async {
    // This test makes sure that the ThemeData debug output doesn't get too
    // verbose, which has been a problem in the past.

    const ColorScheme darkColors = ColorScheme.dark();
    final ThemeData darkTheme = ThemeData.from(colorScheme: darkColors);

    expect(darkTheme.toString().length, lessThan(200));

    const ColorScheme lightColors = ColorScheme.light();
    final ThemeData lightTheme = ThemeData.from(colorScheme: lightColors);

    expect(lightTheme.toString().length, lessThan(200));
  });

  testWidgets('ThemeData brightness parameter overrides ColorScheme brightness', (WidgetTester tester) async {
    const ColorScheme lightColors = ColorScheme.light();
    expect(() => ThemeData(colorScheme: lightColors, brightness: Brightness.dark), throwsAssertionError);
  });

  testWidgets('ThemeData.copyWith brightness parameter overrides ColorScheme brightness', (WidgetTester tester) async {
    const ColorScheme lightColors = ColorScheme.light();
    final ThemeData theme = ThemeData.from(colorScheme: lightColors).copyWith(brightness: Brightness.dark);

    // The brightness parameter only overrides ColorScheme.brightness.
    expect(theme.brightness, equals(Brightness.dark));
    expect(theme.colorScheme.brightness, equals(Brightness.dark));
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
}
