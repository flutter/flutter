// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@immutable
class MyThemeExtensionA extends ThemeExtension<MyThemeExtensionA> {
  const MyThemeExtensionA({
    required this.color1,
    required this.color2,
  });

  final Color? color1;
  final Color? color2;

  @override
  MyThemeExtensionA copyWith({Color? color1, Color? color2}) {
    return MyThemeExtensionA(
      color1: color1 ?? this.color1,
      color2: color2 ?? this.color2,
    );
  }

  @override
  MyThemeExtensionA lerp(ThemeExtension<MyThemeExtensionA>? other, double t) {
    if (other is! MyThemeExtensionA) {
      return this;
    }
    return MyThemeExtensionA(
      color1: Color.lerp(color1, other.color1, t),
      color2: Color.lerp(color2, other.color2, t),
    );
  }
}

@immutable
class MyThemeExtensionB extends ThemeExtension<MyThemeExtensionB> {
  const MyThemeExtensionB({
    required this.textStyle,
  });

  final TextStyle? textStyle;

  @override
  MyThemeExtensionB copyWith({Color? color, TextStyle? textStyle}) {
    return MyThemeExtensionB(
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  MyThemeExtensionB lerp(ThemeExtension<MyThemeExtensionB>? other, double t) {
    if (other is! MyThemeExtensionB) {
      return this;
    }
    return MyThemeExtensionB(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
    );
  }
}

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
      expect(
        theme.textTheme,
        typography.black.apply(decoration: TextDecoration.none),
        reason: 'Not using default typography for $platform',
      );
    }
  });

  test('Default text theme contrasts with brightness', () {
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.textTheme.headline6!.color, typography.black.headline6!.color);
    expect(darkTheme.textTheme.headline6!.color, typography.white.headline6!.color);
  });

  test('Default primary text theme contrasts with primary brightness', () {
    final ThemeData lightTheme = ThemeData(primaryColor: Colors.white);
    final ThemeData darkTheme = ThemeData(primaryColor: Colors.black);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.headline6!.color, typography.black.headline6!.color);
    expect(darkTheme.primaryTextTheme.headline6!.color, typography.white.headline6!.color);
  });

  test('Default icon theme contrasts with brightness', () {
    final ThemeData lightTheme = ThemeData(brightness: Brightness.light);
    final ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.textTheme.headline6!.color, typography.black.headline6!.color);
    expect(darkTheme.textTheme.headline6!.color, typography.white.headline6!.color);
  });

  test('Default primary icon theme contrasts with primary brightness', () {
    final ThemeData lightTheme = ThemeData(primaryColor: Colors.white);
    final ThemeData darkTheme = ThemeData(primaryColor: Colors.black);
    final Typography typography = Typography.material2018(platform: lightTheme.platform);

    expect(lightTheme.primaryTextTheme.headline6!.color, typography.black.headline6!.color);
    expect(darkTheme.primaryTextTheme.headline6!.color, typography.white.headline6!.color);
  });

  testWidgets('Defaults to MaterialTapTargetBehavior.padded on mobile platforms and MaterialTapTargetBehavior.shrinkWrap on desktop', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData(platform: defaultTargetPlatform);
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        expect(themeData.materialTapTargetSize, MaterialTapTargetSize.padded);
        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        expect(themeData.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
        break;
    }
  }, variant: TargetPlatformVariant.all());

  test('Can control fontFamily default', () {
    final ThemeData themeData = ThemeData(
      fontFamily: 'Ahem',
      textTheme: const TextTheme(
        headline6: TextStyle(fontFamily: 'Roboto'),
      ),
    );

    expect(themeData.textTheme.bodyText1!.fontFamily, equals('Ahem'));
    expect(themeData.primaryTextTheme.headline3!.fontFamily, equals('Ahem'));

    // Shouldn't override the specified style's family
    expect(themeData.textTheme.headline6!.fontFamily, equals('Roboto'));
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
    expect(const TextSelectionThemeData(cursorColor: Colors.red).cursorColor, Colors.red);
  });

  test('If colorSchemeSeed is used colorScheme, primaryColor and primarySwatch should not be.', () {
    expect(() => ThemeData(colorSchemeSeed: Colors.blue, colorScheme: const ColorScheme.light()), throwsAssertionError);
    expect(() => ThemeData(colorSchemeSeed: Colors.blue, primaryColor: Colors.green), throwsAssertionError);
    expect(() => ThemeData(colorSchemeSeed: Colors.blue, primarySwatch: Colors.green), throwsAssertionError);
  });

  test('ThemeData can generate a light colorScheme from colorSchemeSeed', () {
    final ThemeData theme = ThemeData(colorSchemeSeed: Colors.blue);

    expect(theme.colorScheme.primary, const Color(0xff0061a6));
    expect(theme.colorScheme.onPrimary, const Color(0xffffffff));
    expect(theme.colorScheme.primaryContainer, const Color(0xffd0e4ff));
    expect(theme.colorScheme.onPrimaryContainer, const Color(0xff001d36));
    expect(theme.colorScheme.secondary, const Color(0xff535f70));
    expect(theme.colorScheme.onSecondary, const Color(0xffffffff));
    expect(theme.colorScheme.secondaryContainer, const Color(0xffd6e3f7));
    expect(theme.colorScheme.onSecondaryContainer, const Color(0xff101c2b));
    expect(theme.colorScheme.tertiary, const Color(0xff6b5778));
    expect(theme.colorScheme.onTertiary, const Color(0xffffffff));
    expect(theme.colorScheme.tertiaryContainer, const Color(0xfff3daff));
    expect(theme.colorScheme.onTertiaryContainer, const Color(0xff251432));
    expect(theme.colorScheme.error, const Color(0xffba1b1b));
    expect(theme.colorScheme.onError, const Color(0xffffffff));
    expect(theme.colorScheme.errorContainer, const Color(0xffffdad4));
    expect(theme.colorScheme.onErrorContainer, const Color(0xff410001));
    expect(theme.colorScheme.outline, const Color(0xff73777f));
    expect(theme.colorScheme.background, const Color(0xfffdfcff));
    expect(theme.colorScheme.onBackground, const Color(0xff1b1b1b));
    expect(theme.colorScheme.surface, const Color(0xfffdfcff));
    expect(theme.colorScheme.onSurface, const Color(0xff1b1b1b));
    expect(theme.colorScheme.surfaceVariant, const Color(0xffdfe2eb));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xff42474e));
    expect(theme.colorScheme.inverseSurface, const Color(0xff2f3033));
    expect(theme.colorScheme.onInverseSurface, const Color(0xfff1f0f4));
    expect(theme.colorScheme.inversePrimary, const Color(0xff9ccaff));
    expect(theme.colorScheme.shadow, const Color(0xff000000));
    expect(theme.colorScheme.brightness, Brightness.light);

    expect(theme.primaryColor, theme.colorScheme.primary);
    expect(theme.primaryColorBrightness, Brightness.dark);
    expect(theme.canvasColor, theme.colorScheme.background);
    expect(theme.accentColor, theme.colorScheme.secondary);
    expect(theme.accentColorBrightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.background);
    expect(theme.bottomAppBarColor, theme.colorScheme.surface);
    expect(theme.cardColor, theme.colorScheme.surface);
    expect(theme.dividerColor, theme.colorScheme.outline);
    expect(theme.backgroundColor, theme.colorScheme.background);
    expect(theme.dialogBackgroundColor, theme.colorScheme.background);
    expect(theme.indicatorColor, theme.colorScheme.onPrimary);
    expect(theme.errorColor, theme.colorScheme.error);
    expect(theme.applyElevationOverlayColor, false);
  });

  test('ThemeData can generate a dark colorScheme from colorSchemeSeed', () {
    final ThemeData theme = ThemeData(
      colorSchemeSeed: Colors.blue,
      brightness: Brightness.dark,
    );

    expect(theme.colorScheme.primary, const Color(0xff9ccaff));
    expect(theme.colorScheme.onPrimary, const Color(0xff00325a));
    expect(theme.colorScheme.primaryContainer, const Color(0xff00497f));
    expect(theme.colorScheme.onPrimaryContainer, const Color(0xffd0e4ff));
    expect(theme.colorScheme.secondary, const Color(0xffbbc8db));
    expect(theme.colorScheme.onSecondary, const Color(0xff253140));
    expect(theme.colorScheme.secondaryContainer, const Color(0xff3c4858));
    expect(theme.colorScheme.onSecondaryContainer, const Color(0xffd6e3f7));
    expect(theme.colorScheme.tertiary, const Color(0xffd6bee4));
    expect(theme.colorScheme.onTertiary, const Color(0xff3b2948));
    expect(theme.colorScheme.tertiaryContainer, const Color(0xff523f5f));
    expect(theme.colorScheme.onTertiaryContainer, const Color(0xfff3daff));
    expect(theme.colorScheme.error, const Color(0xffffb4a9));
    expect(theme.colorScheme.onError, const Color(0xff680003));
    expect(theme.colorScheme.errorContainer, const Color(0xff930006));
    expect(theme.colorScheme.onErrorContainer, const Color(0xffffb4a9));
    expect(theme.colorScheme.outline, const Color(0xff8d9199));
    expect(theme.colorScheme.background, const Color(0xff1b1b1b));
    expect(theme.colorScheme.onBackground, const Color(0xffe2e2e6));
    expect(theme.colorScheme.surface, const Color(0xff1b1b1b));
    expect(theme.colorScheme.onSurface, const Color(0xffe2e2e6));
    expect(theme.colorScheme.surfaceVariant, const Color(0xff42474e));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xffc3c7d0));
    expect(theme.colorScheme.inverseSurface, const Color(0xffe2e2e6));
    expect(theme.colorScheme.onInverseSurface, const Color(0xff2f3033));
    expect(theme.colorScheme.inversePrimary, const Color(0xff0061a6));
    expect(theme.colorScheme.shadow, const Color(0xff000000));
    expect(theme.colorScheme.brightness, Brightness.dark);

    expect(theme.primaryColor, theme.colorScheme.surface);
    expect(theme.primaryColorBrightness, Brightness.dark);
    expect(theme.canvasColor, theme.colorScheme.background);
    expect(theme.accentColor, theme.colorScheme.secondary);
    expect(theme.accentColorBrightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.background);
    expect(theme.bottomAppBarColor, theme.colorScheme.surface);
    expect(theme.cardColor, theme.colorScheme.surface);
    expect(theme.dividerColor, theme.colorScheme.outline);
    expect(theme.backgroundColor, theme.colorScheme.background);
    expect(theme.dialogBackgroundColor, theme.colorScheme.background);
    expect(theme.indicatorColor, theme.colorScheme.onSurface);
    expect(theme.errorColor, theme.colorScheme.error);
    expect(theme.applyElevationOverlayColor, true);
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

  testWidgets('splashFactory is InkSparkle only for Android non-web when useMaterial3 is true', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);

    // Basic check that this theme is in fact using material 3.
    expect(theme.useMaterial3, true);

    switch (debugDefaultTargetPlatformOverride!) {
      case TargetPlatform.android:
        if (kIsWeb) {
          expect(theme.splashFactory, equals(InkRipple.splashFactory));
        } else {
          expect(theme.splashFactory, equals(InkSparkle.splashFactory));
        }
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        expect(theme.splashFactory, equals(InkRipple.splashFactory));
     }
  }, variant: TargetPlatformVariant.all());

  testWidgets('splashFactory is InkSplash for every platform scenario, including Android non-web, when useMaterial3 is false', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: false);

    switch (debugDefaultTargetPlatformOverride!) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        expect(theme.splashFactory, equals(InkSplash.splashFactory));
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets('VisualDensity.adaptivePlatformDensity returns adaptive values', (WidgetTester tester) async {
    switch (debugDefaultTargetPlatformOverride!) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        expect(VisualDensity.adaptivePlatformDensity, equals(VisualDensity.standard));
        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        expect(VisualDensity.adaptivePlatformDensity, equals(VisualDensity.compact));
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets('VisualDensity in ThemeData defaults to "compact" on desktop and "standard" on mobile', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    switch (debugDefaultTargetPlatformOverride!) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        expect(themeData.visualDensity, equals(VisualDensity.standard));
        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        expect(themeData.visualDensity, equals(VisualDensity.compact));
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets('Ensure Visual Density effective constraints are clamped', (WidgetTester tester) async {
    const BoxConstraints square = BoxConstraints.tightFor(width: 35, height: 35);
    BoxConstraints expanded = const VisualDensity(horizontal: 4.0, vertical: 4.0).effectiveConstraints(square);
    expect(expanded.minWidth, equals(35));
    expect(expanded.minHeight, equals(35));
    expect(expanded.maxWidth, equals(35));
    expect(expanded.maxHeight, equals(35));

    BoxConstraints contracted = const VisualDensity(horizontal: -4.0, vertical: -4.0).effectiveConstraints(square);
    expect(contracted.minWidth, equals(19));
    expect(contracted.minHeight, equals(19));
    expect(expanded.maxWidth, equals(35));
    expect(expanded.maxHeight, equals(35));

    const BoxConstraints small = BoxConstraints.tightFor(width: 4, height: 4);
    expanded = const VisualDensity(horizontal: 4.0, vertical: 4.0).effectiveConstraints(small);
    expect(expanded.minWidth, equals(4));
    expect(expanded.minHeight, equals(4));
    expect(expanded.maxWidth, equals(4));
    expect(expanded.maxHeight, equals(4));

    contracted = const VisualDensity(horizontal: -4.0, vertical: -4.0).effectiveConstraints(small);
    expect(contracted.minWidth, equals(0));
    expect(contracted.minHeight, equals(0));
    expect(expanded.maxWidth, equals(4));
    expect(expanded.maxHeight, equals(4));
  });

  testWidgets('Ensure Visual Density effective constraints expand and contract', (WidgetTester tester) async {
    const BoxConstraints square = BoxConstraints();
    final BoxConstraints expanded = const VisualDensity(horizontal: 4.0, vertical: 4.0).effectiveConstraints(square);
    expect(expanded.minWidth, equals(16));
    expect(expanded.minHeight, equals(16));
    expect(expanded.maxWidth, equals(double.infinity));
    expect(expanded.maxHeight, equals(double.infinity));

    final BoxConstraints contracted = const VisualDensity(horizontal: -4.0, vertical: -4.0).effectiveConstraints(square);
    expect(contracted.minWidth, equals(0));
    expect(contracted.minHeight, equals(0));
    expect(expanded.maxWidth, equals(double.infinity));
    expect(expanded.maxHeight, equals(double.infinity));
  });

  group('Theme extensions', () {
    const Key containerKey = Key('container');

    testWidgets('can be obtained', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>{
              MyThemeExtensionA(
                color1: Colors.black,
                color2: Colors.amber,
              ),
              MyThemeExtensionB(
                textStyle: TextStyle(fontSize: 50),
              )
            },
          ),
          home: Container(key: containerKey),
        ),
      );

      final ThemeData theme = Theme.of(
        tester.element(find.byKey(containerKey)),
      );

      expect(theme.extension<MyThemeExtensionA>()!.color1, Colors.black);
      expect(theme.extension<MyThemeExtensionA>()!.color2, Colors.amber);
      expect(theme.extension<MyThemeExtensionB>()!.textStyle, const TextStyle(fontSize: 50));
    });

    testWidgets('can use copyWith', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>{
              const MyThemeExtensionA(
                color1: Colors.black,
                color2: Colors.amber,
              ).copyWith(color1: Colors.blue),
            },
          ),
          home: Container(key: containerKey),
        ),
      );

      final ThemeData theme = Theme.of(
        tester.element(find.byKey(containerKey)),
      );

      expect(theme.extension<MyThemeExtensionA>()!.color1, Colors.blue);
      expect(theme.extension<MyThemeExtensionA>()!.color2, Colors.amber);
    });

    testWidgets('can lerp', (WidgetTester tester) async {
      const MyThemeExtensionA extensionA1 = MyThemeExtensionA(
        color1: Colors.black,
        color2: Colors.amber,
      );
      const MyThemeExtensionA extensionA2 = MyThemeExtensionA(
        color1: Colors.white,
        color2: Colors.blue,
      );
      const MyThemeExtensionB extensionB1 = MyThemeExtensionB(
        textStyle: TextStyle(fontSize: 50),
      );
      const MyThemeExtensionB extensionB2 = MyThemeExtensionB(
        textStyle: TextStyle(fontSize: 100),
      );

      // Both ThemeDatas include both extensions
      ThemeData lerped = ThemeData.lerp(
        ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            extensionA1,
            extensionB1,
          ],
        ),
        ThemeData(
          extensions: const <ThemeExtension<dynamic>>{
            extensionA2,
            extensionB2,
          },
        ),
        0.5,
      );

      expect(lerped.extension<MyThemeExtensionA>()!.color1, const Color(0xff7f7f7f));
      expect(lerped.extension<MyThemeExtensionA>()!.color2, const Color(0xff90ab7d));
      expect(lerped.extension<MyThemeExtensionB>()!.textStyle, const TextStyle(fontSize: 75));

      // Missing from 2nd ThemeData
      lerped = ThemeData.lerp(
        ThemeData(
          extensions: const <ThemeExtension<dynamic>>{
            extensionA1,
            extensionB1,
          },
        ),
        ThemeData(
          extensions: const <ThemeExtension<dynamic>>{
            extensionB2,
          },
        ),
        0.5,
      );
      expect(lerped.extension<MyThemeExtensionA>()!.color1, Colors.black); // Not lerped
      expect(lerped.extension<MyThemeExtensionA>()!.color2, Colors.amber); // Not lerped
      expect(lerped.extension<MyThemeExtensionB>()!.textStyle, const TextStyle(fontSize: 75));

      // Missing from 1st ThemeData
      lerped = ThemeData.lerp(
        ThemeData(
          extensions: const <ThemeExtension<dynamic>>{
            extensionA1,
          },
        ),
        ThemeData(
          extensions: const <ThemeExtension<dynamic>>{
            extensionA2,
            extensionB2,
          },
        ),
        0.5,
      );
      expect(lerped.extension<MyThemeExtensionA>()!.color1, const Color(0xff7f7f7f));
      expect(lerped.extension<MyThemeExtensionA>()!.color2, const Color(0xff90ab7d));
      expect(lerped.extension<MyThemeExtensionB>()!.textStyle, const TextStyle(fontSize: 100)); // Not lerped
    });
  });

  test('copyWith, ==, hashCode basics', () {
    expect(ThemeData(), ThemeData().copyWith());
    expect(ThemeData().hashCode, ThemeData().copyWith().hashCode);
  });

  test('== and hashCode include focusColor and hoverColor', () {
    // regression test for https://github.com/flutter/flutter/issues/91587

    // Focus color and hover color are used in the default button theme, so
    // use an empty one to ensure that just focus and hover colors are tested.
    const ButtonThemeData buttonTheme = ButtonThemeData();

    final ThemeData focusColorBlack = ThemeData(focusColor: Colors.black, buttonTheme: buttonTheme);
    final ThemeData focusColorWhite = ThemeData(focusColor: Colors.white, buttonTheme: buttonTheme);
    expect(focusColorBlack != focusColorWhite, true);
    expect(focusColorBlack.hashCode != focusColorWhite.hashCode, true);

    final ThemeData hoverColorBlack = ThemeData(hoverColor: Colors.black, buttonTheme: buttonTheme);
    final ThemeData hoverColorWhite = ThemeData(hoverColor: Colors.white, buttonTheme: buttonTheme);
    expect(hoverColorBlack != hoverColorWhite, true);
    expect(hoverColorBlack.hashCode != hoverColorWhite.hashCode, true);
  });

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
      visualDensity: VisualDensity.standard,
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
      useMaterial3: false,
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
      expansionTileTheme: const ExpansionTileThemeData(backgroundColor: Colors.black),
      cardTheme: const CardTheme(color: Colors.black),
      chipTheme: chipTheme,
      platform: TargetPlatform.iOS,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      applyElevationOverlayColor: false,
      pageTransitionsTheme: pageTransitionTheme,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      scrollbarTheme: const ScrollbarThemeData(radius: Radius.circular(10.0)),
      bottomAppBarTheme: const BottomAppBarTheme(color: Colors.black),
      colorScheme: const ColorScheme.light(),
      dialogTheme: const DialogTheme(backgroundColor: Colors.black),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.black),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.black),
      navigationRailTheme: const NavigationRailThemeData(backgroundColor: Colors.black),
      typography: Typography.material2018(),
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
      checkboxTheme: const CheckboxThemeData(),
      radioTheme: const RadioThemeData(),
      switchTheme: const SwitchThemeData(),
      progressIndicatorTheme: const ProgressIndicatorThemeData(),
      drawerTheme: const DrawerThemeData(),
      listTileTheme: const ListTileThemeData(),
      fixTextFieldOutlineLabel: false,
      useTextSelectionTheme: false,
      androidOverscrollIndicator: null,
      extensions: const <Object, ThemeExtension<dynamic>>{},
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
      visualDensity: VisualDensity.standard,
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
      useMaterial3: true,
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
      expansionTileTheme: const ExpansionTileThemeData(backgroundColor: Colors.black),
      cardTheme: const CardTheme(color: Colors.white),
      chipTheme: otherChipTheme,
      platform: TargetPlatform.android,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      applyElevationOverlayColor: true,
      pageTransitionsTheme: const PageTransitionsTheme(),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
      scrollbarTheme: const ScrollbarThemeData(radius: Radius.circular(10.0)),
      bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white),
      colorScheme: const ColorScheme.light(),
      dialogTheme: const DialogTheme(backgroundColor: Colors.white),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.white),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white),
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
      checkboxTheme: const CheckboxThemeData(),
      radioTheme: const RadioThemeData(),
      switchTheme: const SwitchThemeData(),
      progressIndicatorTheme: const ProgressIndicatorThemeData(),
      drawerTheme: const DrawerThemeData(),
      listTileTheme: const ListTileThemeData(),
      fixTextFieldOutlineLabel: true,
      useTextSelectionTheme: true,
      androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
      extensions: const <Object, ThemeExtension<dynamic>>{
        MyThemeExtensionB: MyThemeExtensionB(textStyle: TextStyle()),
      },
    );

    final ThemeData themeDataCopy = theme.copyWith(
      primaryColor: otherTheme.primaryColor,
      primaryColorBrightness: otherTheme.primaryColorBrightness,
      primaryColorLight: otherTheme.primaryColorLight,
      primaryColorDark: otherTheme.primaryColorDark,
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
      useMaterial3: otherTheme.useMaterial3,
      selectedRowColor: otherTheme.selectedRowColor,
      unselectedWidgetColor: otherTheme.unselectedWidgetColor,
      disabledColor: otherTheme.disabledColor,
      buttonTheme: otherTheme.buttonTheme,
      toggleButtonsTheme: otherTheme.toggleButtonsTheme,
      buttonColor: otherTheme.buttonColor,
      secondaryHeaderColor: otherTheme.secondaryHeaderColor,
      textSelectionColor: otherTheme.textSelectionTheme.selectionColor,
      cursorColor: otherTheme.textSelectionTheme.cursorColor,
      textSelectionHandleColor: otherTheme.textSelectionTheme.selectionHandleColor,
      backgroundColor: otherTheme.backgroundColor,
      dialogBackgroundColor: otherTheme.dialogBackgroundColor,
      indicatorColor: otherTheme.indicatorColor,
      hintColor: otherTheme.hintColor,
      errorColor: otherTheme.errorColor,
      toggleableActiveColor: otherTheme.toggleableActiveColor,
      textTheme: otherTheme.textTheme,
      primaryTextTheme: otherTheme.primaryTextTheme,
      inputDecorationTheme: otherTheme.inputDecorationTheme,
      iconTheme: otherTheme.iconTheme,
      primaryIconTheme: otherTheme.primaryIconTheme,
      sliderTheme: otherTheme.sliderTheme,
      tabBarTheme: otherTheme.tabBarTheme,
      tooltipTheme: otherTheme.tooltipTheme,
      expansionTileTheme: otherTheme.expansionTileTheme,
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
      navigationBarTheme: otherTheme.navigationBarTheme,
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
      dataTableTheme: otherTheme.dataTableTheme,
      checkboxTheme: otherTheme.checkboxTheme,
      radioTheme: otherTheme.radioTheme,
      switchTheme: otherTheme.switchTheme,
      progressIndicatorTheme: otherTheme.progressIndicatorTheme,
      drawerTheme: otherTheme.drawerTheme,
      listTileTheme: otherTheme.listTileTheme,
      fixTextFieldOutlineLabel: otherTheme.fixTextFieldOutlineLabel,
      extensions: otherTheme.extensions.values,
    );

    expect(themeDataCopy.brightness, equals(otherTheme.brightness));
    expect(themeDataCopy.primaryColor, equals(otherTheme.primaryColor));
    expect(themeDataCopy.primaryColorBrightness, equals(otherTheme.primaryColorBrightness));
    expect(themeDataCopy.primaryColorLight, equals(otherTheme.primaryColorLight));
    expect(themeDataCopy.primaryColorDark, equals(otherTheme.primaryColorDark));
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
    expect(themeDataCopy.useMaterial3, equals(otherTheme.useMaterial3));
    expect(themeDataCopy.selectedRowColor, equals(otherTheme.selectedRowColor));
    expect(themeDataCopy.unselectedWidgetColor, equals(otherTheme.unselectedWidgetColor));
    expect(themeDataCopy.disabledColor, equals(otherTheme.disabledColor));
    expect(themeDataCopy.buttonTheme, equals(otherTheme.buttonTheme));
    expect(themeDataCopy.toggleButtonsTheme, equals(otherTheme.toggleButtonsTheme));
    expect(themeDataCopy.buttonColor, equals(otherTheme.buttonColor));
    expect(themeDataCopy.secondaryHeaderColor, equals(otherTheme.secondaryHeaderColor));
    expect(themeDataCopy.textSelectionTheme.selectionColor, equals(otherTheme.textSelectionTheme.selectionColor));
    expect(themeDataCopy.textSelectionTheme.cursorColor, equals(otherTheme.textSelectionTheme.cursorColor));
    expect(themeDataCopy.textSelectionTheme.selectionColor, equals(otherTheme.textSelectionTheme.selectionColor));
    expect(themeDataCopy.textSelectionTheme.cursorColor, equals(otherTheme.textSelectionTheme.cursorColor));
    expect(themeDataCopy.textSelectionTheme.selectionHandleColor, equals(otherTheme.textSelectionTheme.selectionHandleColor));
    expect(themeDataCopy.backgroundColor, equals(otherTheme.backgroundColor));
    expect(themeDataCopy.dialogBackgroundColor, equals(otherTheme.dialogBackgroundColor));
    expect(themeDataCopy.indicatorColor, equals(otherTheme.indicatorColor));
    expect(themeDataCopy.hintColor, equals(otherTheme.hintColor));
    expect(themeDataCopy.errorColor, equals(otherTheme.errorColor));
    expect(themeDataCopy.textTheme, equals(otherTheme.textTheme));
    expect(themeDataCopy.primaryTextTheme, equals(otherTheme.primaryTextTheme));
    expect(themeDataCopy.sliderTheme, equals(otherTheme.sliderTheme));
    expect(themeDataCopy.tabBarTheme, equals(otherTheme.tabBarTheme));
    expect(themeDataCopy.tooltipTheme, equals(otherTheme.tooltipTheme));
    expect(themeDataCopy.expansionTileTheme, equals(otherTheme.expansionTileTheme));
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
    expect(themeDataCopy.navigationBarTheme, equals(otherTheme.navigationBarTheme));
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
    expect(themeDataCopy.dataTableTheme, equals(otherTheme.dataTableTheme));
    expect(themeDataCopy.checkboxTheme, equals(otherTheme.checkboxTheme));
    expect(themeDataCopy.radioTheme, equals(otherTheme.radioTheme));
    expect(themeDataCopy.switchTheme, equals(otherTheme.switchTheme));
    expect(themeDataCopy.progressIndicatorTheme, equals(otherTheme.progressIndicatorTheme));
    expect(themeDataCopy.drawerTheme, equals(otherTheme.drawerTheme));
    expect(themeDataCopy.listTileTheme, equals(otherTheme.listTileTheme));
    expect(themeDataCopy.fixTextFieldOutlineLabel, equals(otherTheme.fixTextFieldOutlineLabel));
    expect(themeDataCopy.extensions, equals(otherTheme.extensions));
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

  test('ThemeData diagnostics include all properties', () {
    // List of properties must match the properties in ThemeData.hashCode()
    final Set<String> expectedPropertyNames = <String>{
      // GENERAL CONFIGURATION
      'applyElevationOverlayColor',
      'cupertinoOverrideTheme',
      'extensions',
      'inputDecorationTheme',
      'materialTapTargetSize',
      'pageTransitionsTheme',
      'platform',
      'scrollbarTheme',
      'splashFactory',
      'visualDensity',
      'useMaterial3',
      // COLOR
      'colorScheme',
      'primaryColor',
      'primaryColorLight',
      'primaryColorDark',
      'focusColor',
      'hoverColor',
      'shadowColor',
      'canvasColor',
      'scaffoldBackgroundColor',
      'bottomAppBarColor',
      'cardColor',
      'dividerColor',
      'highlightColor',
      'splashColor',
      'selectedRowColor',
      'unselectedWidgetColor',
      'disabledColor',
      'secondaryHeaderColor',
      'backgroundColor',
      'dialogBackgroundColor',
      'indicatorColor',
      'hintColor',
      'errorColor',
      'toggleableActiveColor',
      // TYPOGRAPHY & ICONOGRAPHY
      'typography',
      'textTheme',
      'primaryTextTheme',
      'iconTheme',
      'primaryIconTheme',
      // COMPONENT THEMES
      'appBarTheme',
      'bannerTheme',
      'bottomAppBarTheme',
      'bottomNavigationBarTheme',
      'bottomSheetTheme',
      'buttonBarTheme',
      'buttonTheme',
      'cardTheme',
      'checkboxTheme',
      'chipTheme',
      'dataTableTheme',
      'dialogTheme',
      'dividerTheme',
      'drawerTheme',
      'elevatedButtonTheme',
      'floatingActionButtonTheme',
      'listTileTheme',
      'navigationBarTheme',
      'navigationRailTheme',
      'outlinedButtonTheme',
      'popupMenuTheme',
      'progressIndicatorTheme',
      'radioTheme',
      'sliderTheme',
      'snackBarTheme',
      'switchTheme',
      'tabBarTheme',
      'textButtonTheme',
      'textSelectionTheme',
      'timePickerTheme',
      'toggleButtonsTheme',
      'tooltipTheme',
      'expansionTileTheme',
      // DEPRECATED (newest deprecations at the bottom)
      'useTextSelectionTheme',
      'textSelectionColor',
      'cursorColor',
      'textSelectionHandleColor',
      'accentColor',
      'accentColorBrightness',
      'accentTextTheme',
      'accentIconTheme',
      'buttonColor',
      'fixTextFieldOutlineLabel',
      'primaryColorBrightness',
      'androidOverscrollIndicator',
    };

    final DiagnosticPropertiesBuilder properties = DiagnosticPropertiesBuilder();
    ThemeData.light().debugFillProperties(properties);
    final List<String> propertyNameList = properties.properties
      .map((final DiagnosticsNode node) => node.name)
      .whereType<String>()
      .toList();
    final Set<String> propertyNames = propertyNameList.toSet();

    // Ensure there are no duplicates.
    expect(propertyNameList.length, propertyNames.length);

    // Ensure they are all there.
    expect(propertyNames, expectedPropertyNames);
  });
}
