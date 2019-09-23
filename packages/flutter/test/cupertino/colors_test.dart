// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';

class DependentWidget extends StatelessWidget {
  const DependentWidget({
    Key key,
    this.color
  }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color resolved = CupertinoDynamicColor.resolve(color, context, nullOk: false);
    return DecoratedBox(
      decoration: BoxDecoration(color: resolved),
      child: const SizedBox.expand(),
    );
  }
}

const Color color0 = Color(0xFF000000);
const Color color1 = Color(0xFF000001);
const Color color2 = Color(0xFF000002);
const Color color3 = Color(0xFF000003);
const Color color4 = Color(0xFF000004);
const Color color5 = Color(0xFF000005);
const Color color6 = Color(0xFF000006);
const Color color7 = Color(0xFF000007);

// A color that depends on color vibrancy, accessibility contrast, as well as user
// interface elevation.
const CupertinoDynamicColor dynamicColor = CupertinoDynamicColor(
  color: color0,
  darkColor: color1,
  elevatedColor: color2,
  highContrastColor: color3,
  darkElevatedColor: color4,
  darkHighContrastColor: color5,
  highContrastElevatedColor: color6,
  darkHighContrastElevatedColor: color7,
);

// A color that uses [color0] in every circumstance.
const Color notSoDynamicColor1 = CupertinoDynamicColor(
  color: color0,
  darkColor: color0,
  darkHighContrastColor: color0,
  darkElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
  highContrastColor: color0,
  highContrastElevatedColor: color0,
  elevatedColor: color0,
);

// A color that uses [color1] for light mode, and [color0] for dark mode.
const Color vibrancyDependentColor1 = CupertinoDynamicColor(
  color: color1,
  elevatedColor: color1,
  highContrastColor: color1,
  highContrastElevatedColor: color1,
  darkColor: color0,
  darkHighContrastColor: color0,
  darkElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

// A color that uses [color1] for normal contrast mode, and [color0] for high
// contrast mode.
const Color contrastDependentColor1 = CupertinoDynamicColor(
  color: color1,
  darkColor: color1,
  elevatedColor: color1,
  darkElevatedColor: color1,
  highContrastColor: color0,
  darkHighContrastColor: color0,
  highContrastElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

// A color that uses [color1] for base interface elevation, and [color0] for elevated
// interface elevation.
const Color elevationDependentColor1 = CupertinoDynamicColor(
  color: color1,
  darkColor: color1,
  highContrastColor: color1,
  darkHighContrastColor: color1,
  elevatedColor: color0,
  darkElevatedColor: color0,
  highContrastElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

void main() {
  test('== works as expected', () {
    expect(dynamicColor, const CupertinoDynamicColor(
        color: color0,
        darkColor: color1,
        elevatedColor: color2,
        highContrastColor: color3,
        darkElevatedColor: color4,
        darkHighContrastColor: color5,
        highContrastElevatedColor: color6,
        darkHighContrastElevatedColor: color7,
      )
    );

    expect(notSoDynamicColor1, isNot(vibrancyDependentColor1));

    expect(notSoDynamicColor1, isNot(contrastDependentColor1));

    expect(vibrancyDependentColor1, isNot(const CupertinoDynamicColor(
      color: color0,
      elevatedColor: color0,
      highContrastColor: color0,
      highContrastElevatedColor: color0,
      darkColor: color0,
      darkHighContrastColor: color0,
      darkElevatedColor: color0,
      darkHighContrastElevatedColor: color0,
    )));
  });

  test('CupertinoDynamicColor.toString() works', () {
    expect(
      dynamicColor.toString(),
      'CupertinoDynamicColor(*color = Color(0xff000000)*, '
      'darkColor = Color(0xff000001), '
      'highContrastColor = Color(0xff000003), '
      'darkHighContrastColor = Color(0xff000005), '
      'elevatedColor = Color(0xff000002), '
      'darkElevatedColor = Color(0xff000004), '
      'highContrastElevatedColor = Color(0xff000006), '
      'darkHighContrastElevatedColor = Color(0xff000007))'
    );
    expect(notSoDynamicColor1.toString(), 'CupertinoDynamicColor(*color = Color(0xff000000)*)');
    expect(vibrancyDependentColor1.toString(), 'CupertinoDynamicColor(*color = Color(0xff000001)*, darkColor = Color(0xff000000))');
    expect(contrastDependentColor1.toString(), 'CupertinoDynamicColor(*color = Color(0xff000001)*, highContrastColor = Color(0xff000000))');
    expect(elevationDependentColor1.toString(), 'CupertinoDynamicColor(*color = Color(0xff000001)*, elevatedColor = Color(0xff000000))');

    expect(
      const CupertinoDynamicColor.withBrightnessAndContrast(
        color: color0,
        darkColor: color1,
        highContrastColor: color2,
        darkHighContrastColor: color3,
      ).toString(),
      'CupertinoDynamicColor(*color = Color(0xff000000)*, '
      'darkColor = Color(0xff000001), '
      'highContrastColor = Color(0xff000002), '
      'darkHighContrastColor = Color(0xff000003))',
    );
  });

  test('can resolve null color', () {
    expect(CupertinoDynamicColor.resolve(null, null), isNull);
  });

  test('withVibrancy constructor creates colors that may depend on vibrancy', () {
    expect(vibrancyDependentColor1, const CupertinoDynamicColor.withBrightness(
      color: color1,
      darkColor: color0,
    ));
  });

  test('withVibrancyAndContrast constructor creates colors that may depend on contrast and vibrancy', () {
    expect(contrastDependentColor1, const CupertinoDynamicColor.withBrightnessAndContrast(
      color: color1,
      darkColor: color1,
      highContrastColor: color0,
      darkHighContrastColor: color0,
    ));

    expect(
      const CupertinoDynamicColor(
        color: color0,
        darkColor: color1,
        highContrastColor: color2,
        darkHighContrastColor: color3,
        elevatedColor: color0,
        darkElevatedColor: color1,
        highContrastElevatedColor: color2,
        darkHighContrastElevatedColor: color3,
      ),
      const CupertinoDynamicColor.withBrightnessAndContrast(
        color: color0,
        darkColor: color1,
        highContrastColor: color2,
        darkHighContrastColor: color3,
      ),
    );
  });

  testWidgets('Dynamic colors that are not actually dynamic should not claim dependencies',
    (WidgetTester tester) async {
      await tester.pumpWidget(const DependentWidget(color: notSoDynamicColor1));

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
  });

  testWidgets(
    'Dynamic colors that are only dependent on vibrancy should not claim unnecessary dependencies, '
    'and its resolved color should change when its dependency changes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(platformBrightness: Brightness.light),
          child: DependentWidget(color: vibrancyDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color1));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color0)));

      // Changing color vibrancy works.
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(platformBrightness: Brightness.dark),
          child: DependentWidget(color: vibrancyDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color1)));

      // CupertinoTheme should take percedence over MediaQuery.
      await tester.pumpWidget(
        const CupertinoTheme(
          data: CupertinoThemeData(brightness: Brightness.light),
          child: MediaQuery(
            data: MediaQueryData(platformBrightness: Brightness.dark),
            child: DependentWidget(color: vibrancyDependentColor1),
          ),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color1));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color0)));
  });

  testWidgets(
    'Dynamic colors that are only dependent on accessibility contrast should not claim unnecessary dependencies, '
    'and its resolved color should change when its dependency changes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(highContrast: false),
          child: DependentWidget(color: contrastDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color1));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color0)));

      // Changing accessibility contrast works.
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: DependentWidget(color: contrastDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color1)));

      // Asserts when the required dependency is missing.
      await tester.pumpWidget(const DependentWidget(color: contrastDependentColor1));
      expect(tester.takeException()?.toString(), contains('does not contain a MediaQuery'));
  });

  testWidgets(
    'Dynamic colors that are only dependent on elevation level should not claim unnecessary dependencies, '
    'and its resolved color should change when its dependency changes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: elevationDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color1));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color0)));

      // Changing UI elevation works.
      await tester.pumpWidget(
        const CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: elevationDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color1)));

      // Asserts when the required dependency is missing.
      await tester.pumpWidget(const DependentWidget(color: elevationDependentColor1));
      expect(tester.takeException()?.toString(), contains('does not contain a CupertinoUserInterfaceLevel'));
  });

  testWidgets('Dynamic color with all 3 depedencies works', (WidgetTester tester) async {
    const Color dynamicRainbowColor1 = CupertinoDynamicColor(
      color: color0,
      darkColor: color1,
      highContrastColor: color2,
      darkHighContrastColor: color3,
      darkElevatedColor: color4,
      highContrastElevatedColor: color5,
      darkHighContrastElevatedColor: color6,
      elevatedColor: color7,
    );

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.light, highContrast: false),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color0));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.dark, highContrast: false),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color1));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.light, highContrast: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color2));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.dark, highContrast: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color3));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.dark, highContrast: false),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color4));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.light, highContrast: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color5));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.dark, highContrast: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color6));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.light, highContrast: false),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color7));
  });

  group('CupertinoSystemColors widget', () {
    CupertinoSystemColorsData colors;
    setUp(() { colors = null; });

    Widget systemColorGetter(BuildContext context) {
      colors = CupertinoSystemColors.of(context);
      return const Placeholder();
    }

    const CupertinoDynamicColor kSystemBackground = CupertinoDynamicColor(
      color: Color.fromARGB(255, 255, 255, 255),
      darkColor: Color.fromARGB(255, 0, 0, 0),
      highContrastColor: Color.fromARGB(255, 255, 255, 255),
      darkHighContrastColor: Color.fromARGB(255, 0, 0, 0),
      elevatedColor: Color.fromARGB(255, 255, 255, 255),
      darkElevatedColor: Color.fromARGB(255, 28, 28, 30),
      highContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
      darkHighContrastElevatedColor: Color.fromARGB(255, 36, 36, 38),
    );

    testWidgets('exists in CupertinoApp', (WidgetTester tester) async {
      await tester.pumpWidget(CupertinoApp(home: Builder(builder: systemColorGetter)));
      expect(colors.systemBackground, kSystemBackground);
    });

    testWidgets('resolves against its own BuildContext', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.elevated,
            child: Builder(
              builder: (BuildContext context) {
                return CupertinoSystemColors(
                  child: Builder(builder: systemColorGetter),
                  data: CupertinoSystemColors.of(context).resolveColors(context),
                );
              },
            ),
          ),
        ),
      );

      // In widget tests the OS colors should fallback to `fallbackValues`.
      expect(colors.systemBackground, isNot(kSystemBackground));
      expect(colors.systemBackground.value, kSystemBackground.darkElevatedColor.value);

      colors = null;
      // Changing dependencies works.
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (BuildContext context) {
              return CupertinoUserInterfaceLevel(
                data: CupertinoUserInterfaceLevelData.elevated,
                child: CupertinoSystemColors(
                  child: Builder(builder: systemColorGetter),
                  data: CupertinoSystemColors.of(context).resolveColors(context),
                ),
              );
            },
          ),
        ),
      );

      expect(colors.systemBackground.value, kSystemBackground.elevatedColor.value);
    });
  });

  testWidgets('CupertinoDynamicColor used in a CupertinoTheme', (WidgetTester tester) async {
    CupertinoDynamicColor color;
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: dynamicColor,
        ),
        home: Builder(
          builder: (BuildContext context) {
            color = CupertinoTheme.of(context).primaryColor;
            return const Placeholder();
          }
        ),
      ),
    );

    expect(color.value, dynamicColor.darkColor.value);

    // Changing dependencies works.
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: dynamicColor,
        ),
        home: Builder(
          builder: (BuildContext context) {
            color = CupertinoTheme.of(context).primaryColor;
            return const Placeholder();
          }
        ),
      ),
    );

    expect(color.value, dynamicColor.color.value);

    // Having a dependency below the CupertinoTheme widget works.
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(primaryColor: dynamicColor),
        home: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light, highContrast: false),
          child: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.base,
            child: Builder(
              builder: (BuildContext context) {
                color = CupertinoTheme.of(context).primaryColor;
                return const Placeholder();
              }
            ),
          ),
        ),
      ),
    );

    expect(color.value, dynamicColor.color.value);

    // Changing dependencies works.
    await tester.pumpWidget(
      CupertinoApp(
        // No brightness is explicitly specified here so it should defer to MediaQuery.
        theme: const CupertinoThemeData(primaryColor: dynamicColor),
        home: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark, highContrast: true),
          child: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.elevated,
            child: Builder(
              builder: (BuildContext context) {
                color = CupertinoTheme.of(context).primaryColor;
                return const Placeholder();
              }
            ),
          ),
        ),
      ),
    );

    expect(color.value, dynamicColor.darkHighContrastElevatedColor.value);
  });

  group('MaterialApp:', () {
    Color color;
    setUp(() { color = null; });

    testWidgets('dynamic color works in cupertino override theme', (WidgetTester tester) async {
      final CupertinoDynamicColor Function() typedColor = () => color;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            cupertinoOverrideTheme: const CupertinoThemeData(
              brightness: Brightness.dark,
              primaryColor: dynamicColor,
            ),
          ),
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.light, highContrast: false),
            child: CupertinoUserInterfaceLevel(
              data: CupertinoUserInterfaceLevelData.base,
              child: Builder(
                builder: (BuildContext context) {
                  color = CupertinoTheme.of(context).primaryColor;
                  return const Placeholder();
                }
              ),
            ),
          ),
        ),
      );

      // Explicit brightness is respected.
      expect(typedColor().value, dynamicColor.darkColor.value);
      color = null;

      // Changing dependencies works.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            cupertinoOverrideTheme: const CupertinoThemeData(
              brightness: Brightness.dark,
              primaryColor: dynamicColor,
            ),
          ),
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark, highContrast: true),
            child: CupertinoUserInterfaceLevel(
              data: CupertinoUserInterfaceLevelData.elevated,
              child: Builder(
                builder: (BuildContext context) {
                  color = CupertinoTheme.of(context).primaryColor;
                  return const Placeholder();
                }
              ),
            ),
          ),
        ),
      );

      expect(typedColor().value, dynamicColor.darkHighContrastElevatedColor.value);
    });

    testWidgets('dynamic color does not work in a material theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          // This will create a MaterialBasedCupertinoThemeData with primaryColor set to `dynamicColor`.
          theme: ThemeData(colorScheme: const ColorScheme.dark(primary: dynamicColor)),
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark, highContrast: true),
            child: CupertinoUserInterfaceLevel(
              data: CupertinoUserInterfaceLevelData.elevated,
              child: Builder(
                builder: (BuildContext context) {
                  color = CupertinoTheme.of(context).primaryColor;
                  return const Placeholder();
                }
              ),
            ),
          ),
        ),
      );

      // The color is not resolved.
      expect(color, dynamicColor);
      expect(color, isNot(dynamicColor.darkHighContrastElevatedColor));
    });
  });

  group('CupertinoSystemColors', () {
    const Color dynamicColor0 = CupertinoDynamicColor.withBrightness(
      color: Color(0x00000000),
      darkColor: Color(0x00000000)
    );
    const Color dynamicColor1 = CupertinoDynamicColor.withBrightness(
      color: Color(0x00000001),
      darkColor: Color(0x00000000)
    );

    const CupertinoSystemColorsData system0 = CupertinoSystemColorsData(
      label: dynamicColor0,
      secondaryLabel: dynamicColor0,
      tertiaryLabel: dynamicColor0,
      quaternaryLabel: dynamicColor0,
      systemFill: dynamicColor0,
      secondarySystemFill: dynamicColor0,
      tertiarySystemFill: dynamicColor0,
      quaternarySystemFill: dynamicColor0,
      placeholderText: dynamicColor0,
      systemBackground: dynamicColor0,
      secondarySystemBackground: dynamicColor0,
      tertiarySystemBackground: dynamicColor0,
      systemGroupedBackground: dynamicColor0,
      secondarySystemGroupedBackground: dynamicColor0,
      tertiarySystemGroupedBackground: dynamicColor0,
      separator: dynamicColor0,
      opaqueSeparator: dynamicColor0,
      link: dynamicColor0,
      systemBlue: dynamicColor0,
      systemGreen: dynamicColor0,
      systemIndigo: dynamicColor0,
      systemOrange: dynamicColor0,
      systemPink: dynamicColor0,
      systemPurple: dynamicColor0,
      systemRed: dynamicColor0,
      systemTeal: dynamicColor0,
      systemYellow: dynamicColor0,
      systemGray: dynamicColor0,
      systemGray2: dynamicColor0,
      systemGray3: dynamicColor0,
      systemGray4: dynamicColor0,
      systemGray5: dynamicColor0,
      systemGray6: dynamicColor0,
    );

    test('CupertinoSystemColorsData.== and CupertinoSystemColorsData.copyWith', () {
      expect(system0, system0);
      expect(system0, system0.copyWith());
      expect(system0, system0.copyWith(link: dynamicColor0));
      final CupertinoSystemColorsData withDifferentLink = system0.copyWith(link: dynamicColor1);
      expect(withDifferentLink.link, dynamicColor1);
      expect(system0, isNot(withDifferentLink));
    });

    test('CupertinoSystemColorsData.hashCode', () {
      expect(system0.hashCode, system0.hashCode);
      expect(system0.hashCode, system0.copyWith().hashCode);
      expect(system0.hashCode, system0.copyWith(link: dynamicColor0).hashCode);
      expect(system0.hashCode, isNot(system0.copyWith(link: dynamicColor1).hashCode));
    });

    test('CupertinoSystemColorsData.debugFillProperties', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      system0.debugFillProperties(builder);

      expect(
        builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList(),
        <String>[
          'label: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'secondaryLabel: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'tertiaryLabel: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'quaternaryLabel: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemFill: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'secondarySystemFill: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'tertiarySystemFill: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'quaternarySystemFill: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'placeholderText: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemBackground: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'secondarySystemBackground: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'tertiarySystemBackground: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGroupedBackground: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'secondarySystemGroupedBackground: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'tertiarySystemGroupedBackground: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'separator: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'opaqueSeparator: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'link: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemBlue: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGreen: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemIndigo: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemOrange: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemPink: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemPurple: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemRed: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemTeal: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemYellow: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGray: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGray2: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGray3: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGray4: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGray5: CupertinoDynamicColor(*color = Color(0x00000000)*)',
          'systemGray6: CupertinoDynamicColor(*color = Color(0x00000000)*)',
        ],
      );
    });
  });
}
