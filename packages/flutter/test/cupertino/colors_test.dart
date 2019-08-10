// Copyright 2018 The Chromium Authors. All rights reserved.
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
    final Color resolved = CupertinoDynamicColor.resolve(color, context);
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

final CupertinoDynamicColor dynamicColor = CupertinoDynamicColor(
  color: color0,
  darkColor: color1,
  elevatedColor: color2,
  highContrastColor: color3,
  darkElevatedColor: color4,
  darkHighContrastColor: color5,
  highContrastElevatedColor: color6,
  darkHighContrastElevatedColor: color7,
);

final Color notSoDynamicColor1 = CupertinoDynamicColor(
  color: color0,
  darkColor: color0,
  darkHighContrastColor: color0,
  darkElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
  highContrastColor: color0,
  highContrastElevatedColor: color0,
  elevatedColor: color0,
);

final Color vibrancyDependentColor1 = CupertinoDynamicColor(
  color: color1,
  elevatedColor: color1,
  highContrastColor: color1,
  highContrastElevatedColor: color1,
  darkColor: color0,
  darkHighContrastColor: color0,
  darkElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

final Color contrastDependentColor1 = CupertinoDynamicColor(
  color: color1,
  darkColor: color1,
  elevatedColor: color1,
  darkElevatedColor: color1,
  highContrastColor: color0,
  darkHighContrastColor: color0,
  highContrastElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

final Color elevationDependentColor1 = CupertinoDynamicColor(
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
    expect(dynamicColor, CupertinoDynamicColor(
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

    expect(vibrancyDependentColor1, isNot(CupertinoDynamicColor(
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

  test('withVibrancy constructor works', () {
    expect(vibrancyDependentColor1, CupertinoDynamicColor.withVibrancy(
      color: color1,
      darkColor: color0,
    ));
  });

  test('withVibrancyAndContrast constructor works', () {
    expect(contrastDependentColor1, CupertinoDynamicColor.withVibrancyAndContrast(
      color: color1,
      darkColor: color1,
      highContrastColor: color0,
      darkHighContrastColor: color0,
    ));
  });

  testWidgets('Dynamic colors that are not actually dynamic should not claim dependencies',
    (WidgetTester tester) async {
      await tester.pumpWidget(DependentWidget(color: notSoDynamicColor1));

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
  });

  testWidgets(
    'Dynamic colors that are only dependent on vibrancy should not claim unnecessary dependencies, '
    'and its resolved color should change when its dependency changes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: DependentWidget(color: vibrancyDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color1));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color0)));

      // Changing color vibrancy works.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: DependentWidget(color: vibrancyDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color1)));

      // CupertinoTheme should take percedence over MediaQuery.
      await tester.pumpWidget(
        CupertinoTheme(
          data: const CupertinoThemeData(brightness: Brightness.light),
          child: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark),
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
        MediaQuery(
          data: const MediaQueryData(highContrastContent: false),
          child: DependentWidget(color: contrastDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color1));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color0)));

      // Changing accessibility contrast works.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrastContent: true),
          child: DependentWidget(color: contrastDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color1)));

      // Asserts when the required dependency is missing.
      await tester.pumpWidget(DependentWidget(color: contrastDependentColor1));
      expect(tester.takeException()?.toString(), contains('does not contain a MediaQuery'));
  });

  testWidgets(
    'Dynamic colors that are only dependent on elevation level should not claim unnecessary dependencies, '
    'and its resolved color should change when its dependency changes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: elevationDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color1));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color0)));

      // Changing UI elevation works.
      await tester.pumpWidget(
        CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: elevationDependentColor1),
        ),
      );

      expect(tester.takeException(), null);
      expect(find.byType(DependentWidget), paints..rect(color: color0));
      expect(find.byType(DependentWidget), isNot(paints..rect(color: color1)));

      // Asserts when the required dependency is missing.
      await tester.pumpWidget(DependentWidget(color: elevationDependentColor1));
      expect(tester.takeException()?.toString(), contains('does not contain a CupertinoUserInterfaceLevel'));
  });

  testWidgets('Dynamic color with all 3 depedencies works', (WidgetTester tester) async {
    final Color dynamicRainbowColor1 = CupertinoDynamicColor(
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
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light, highContrastContent: false),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color0));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark, highContrastContent: false),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color1));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light, highContrastContent: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color2));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark, highContrastContent: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.base,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color3));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark, highContrastContent: false),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color4));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light, highContrastContent: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color5));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark, highContrastContent: true),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: DependentWidget(color: dynamicRainbowColor1),
        ),
      ),
    );
    expect(find.byType(DependentWidget), paints..rect(color: color6));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light, highContrastContent: false),
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

    testWidgets('exists in CupertinoApp', (WidgetTester tester) async {
      await tester.pumpWidget(CupertinoApp(home: Builder(builder: systemColorGetter)));
      expect(colors.systemBackground, CupertinoSystemColors.fallbackValues.systemBackground);
    });

    testWidgets('resolves against its own BuildContext', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.elevated,
            child: Builder(
              builder: (BuildContext context) {
                return CupertinoSystemColors.fromBuildContext(
                  child: Builder(builder: systemColorGetter),
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      // In widget tests the OS colors should fallback to `fallbackValues`.
      expect(colors.systemBackground, isNot(CupertinoSystemColors.fallbackValues.systemBackground));
      expect(colors.systemBackground.value, CupertinoSystemColors.fallbackValues.systemBackground.darkElevatedColor.value);

      colors = null;
      // Changing dependencies works.
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (BuildContext context) {
              return CupertinoUserInterfaceLevel(
                data: CupertinoUserInterfaceLevelData.elevated,
                child: CupertinoSystemColors.fromBuildContext(
                  child: Builder(builder: systemColorGetter),
                  context: context,
                ),
              );
            }
          ),
        ),
      );

      expect(colors.systemBackground.value, CupertinoSystemColors.fallbackValues.systemBackground.elevatedColor.value);
    });
  });

  testWidgets('CupertinoDynamicColor used in a CupertinoTheme', (WidgetTester tester) async {
    CupertinoDynamicColor color;
    await tester.pumpWidget(
      CupertinoApp(
        theme: CupertinoThemeData(
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
        theme: CupertinoThemeData(
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
        theme: CupertinoThemeData(primaryColor: dynamicColor),
        home: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light, highContrastContent: false),
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
        theme: CupertinoThemeData(primaryColor: dynamicColor),
        home: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark, highContrastContent: true),
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
            cupertinoOverrideTheme: CupertinoThemeData(
              brightness: Brightness.dark,
              primaryColor: dynamicColor,
            ),
          ),
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.light, highContrastContent: false),
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
            cupertinoOverrideTheme: CupertinoThemeData(
              brightness: Brightness.dark,
              primaryColor: dynamicColor,
            ),
          ),
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark, highContrastContent: true),
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
          theme: ThemeData(colorScheme: ColorScheme.dark(primary: dynamicColor)),
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark, highContrastContent: true),
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
}
