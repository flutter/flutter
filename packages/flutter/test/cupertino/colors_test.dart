// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/src/cupertino/interface_level.dart';
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

final Color notSoDynamicColor1 = CupertinoDynamicColor(defaultColor: color0);
final Color notSoDynamicColor2 = CupertinoDynamicColor(defaultColor: color0, darkColor: color0);
final Color notSoDynamicColor3 = CupertinoDynamicColor(defaultColor: color0, highContrastColor: color0);
final Color notSoDynamicColor4 = CupertinoDynamicColor(defaultColor: color0, elevatedColor: color0);
final Color notSoDynamicColor5 = CupertinoDynamicColor(
  normalColor: color0,
  darkColor: color0,
  darkHighContrastColor: color0,
  darkElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
  highContrastColor: color0,
  highContrastElevatedColor: color0,
  elevatedColor: color0,
);

final Color vibrancyDependentColor1 = CupertinoDynamicColor(
  defaultColor: color1,
  darkColor: color0,
  darkHighContrastColor: color0,
  darkElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

final Color contrastDependentColor1 = CupertinoDynamicColor(
  defaultColor: color1,
  highContrastColor: color0,
  darkHighContrastColor: color0,
  highContrastElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

final Color elevationDependentColor1 = CupertinoDynamicColor(
  defaultColor: color1,
  elevatedColor: color0,
  darkElevatedColor: color0,
  highContrastElevatedColor: color0,
  darkHighContrastElevatedColor: color0,
);

void main() {
  test('== works as expected', () {
    expect(notSoDynamicColor1, notSoDynamicColor2);
    expect(notSoDynamicColor1, notSoDynamicColor3);
    expect(notSoDynamicColor1, notSoDynamicColor4);
    expect(notSoDynamicColor1, notSoDynamicColor5);

    expect(notSoDynamicColor2, notSoDynamicColor5);


    expect(notSoDynamicColor1, isNot(vibrancyDependentColor1));
    expect(notSoDynamicColor5, isNot(vibrancyDependentColor1));

    expect(notSoDynamicColor1, isNot(contrastDependentColor1));
    expect(notSoDynamicColor5, isNot(contrastDependentColor1));

    expect(vibrancyDependentColor1, isNot(CupertinoDynamicColor(
      defaultColor: color0,
      darkColor: color0,
      darkHighContrastColor: color0,
      darkElevatedColor: color0,
      darkHighContrastElevatedColor: color0,
    )));
  });

  test('withVibrancy constructor works', () {
    expect(vibrancyDependentColor1, CupertinoDynamicColor.withVibrancy(
      defaultColor: color1,
      normalColor: color1,
      darkColor: color0,
    ));
  });

  test('withVibrancyAndContrast constructor works', () {
    expect(contrastDependentColor1, CupertinoDynamicColor.withVibrancyAndContrast(
      defaultColor: color1,
      highContrastColor: color0,
      darkHighContrastColor: color0,
    ));
  });

  testWidgets('Dynamic colors that are not actually dynamic should not claim dependencies',
    (WidgetTester tester) async {
      for (Color color in <Color>[notSoDynamicColor1, notSoDynamicColor2, notSoDynamicColor3, notSoDynamicColor4, notSoDynamicColor5]) {
        await tester.pumpWidget(DependentWidget(color: color));

        expect(tester.takeException(), null);
        expect(find.byType(DependentWidget), paints..rect(color: color0));
      }
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
      normalColor: color0,
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
    CupertinoSystemColorData colors;
    setUp(() { colors = null; });

    Widget systemColorGetter(BuildContext context) {
      colors = CupertinoSystemColor.of(context);
      return const Placeholder();
    }

    testWidgets('exists in CupertinoApp', (WidgetTester tester) async {
      await tester.pumpWidget(CupertinoApp(home: Builder(builder: systemColorGetter)));
      expect(colors.systemBackground, CupertinoSystemColor.fallbackValues.systemBackground);
    });

    testWidgets('resolves against its own BuildContext', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.elevated,
            child: Builder(
              builder: (BuildContext context) {
                return CupertinoSystemColors.fromCurrentContext(
                  child: Builder(builder: systemColorGetter),
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      // In widget tests the OS colors should fallback to `fallbackValues`.
      expect(colors.systemBackground, isNot(CupertinoSystemColor.fallbackValues.systemBackground));
      expect(colors.systemBackground.defaultColor, CupertinoSystemColor.fallbackValues.systemBackground.darkElevatedColor);

      colors = null;
      // Changing dependencies works.
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (BuildContext context) {
              return CupertinoUserInterfaceLevel(
                data: CupertinoUserInterfaceLevelData.elevated,
                child: CupertinoSystemColors.fromCurrentContext(
                  child: Builder(builder: systemColorGetter),
                  context: context,
                ),
              );
            }
          ),
        ),
      );

      expect(colors.systemBackground.defaultColor, CupertinoSystemColor.fallbackValues.systemBackground.elevatedColor);
    });
  });

  testWidgets('CupertinoDynamicColor used in a CupertinoTheme', (WidgetTester tester) async {
    final CupertinoDynamicColor dynamicColor = CupertinoDynamicColor(
      normalColor: const Color(0xFF000000),
      darkColor: const Color(0xFF000001),
      elevatedColor: const Color(0xFF000002),
      highContrastColor: const Color(0xFF000003),
      darkElevatedColor: const Color(0xFF000004),
      darkHighContrastColor: const Color(0xFF000005),
      highContrastElevatedColor: const Color(0xFF000006),
      darkHighContrastElevatedColor: const Color(0xFF000007),
    );

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

    expect(color.value, dynamicColor.normalColor.value);

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

    expect(color.value, dynamicColor.normalColor.value);

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

    expect(color.defaultColor, dynamicColor.darkHighContrastElevatedColor);
  });
}
