// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

int buildCount = 0;
CupertinoThemeData? actualTheme;
IconThemeData? actualIconTheme;

final Widget singletonThemeSubtree = Builder(
  builder: (BuildContext context) {
    buildCount++;
    actualTheme = CupertinoTheme.of(context);
    actualIconTheme = IconTheme.of(context);
    return const Placeholder();
  },
);

Future<CupertinoThemeData> testTheme(WidgetTester tester, CupertinoThemeData theme) async {
  await tester.pumpWidget(
    CupertinoTheme(
      data: theme,
      child: singletonThemeSubtree,
    ),
  );
  return actualTheme!;
}

Future<IconThemeData> testIconTheme(WidgetTester tester, CupertinoThemeData theme) async {
  await tester.pumpWidget(
    CupertinoTheme(
      data: theme,
      child: singletonThemeSubtree,
    ),
  );
  return actualIconTheme!;
}

void main() {
  setUp(() {
    buildCount = 0;
    actualTheme = null;
    actualIconTheme = null;
  });

  testWidgets('Default theme has defaults', (WidgetTester tester) async {
    final CupertinoThemeData theme = await testTheme(tester, CupertinoThemeData());

    expect(theme.brightness, isNull);
    expect(theme.primaryColor, CupertinoColors.activeBlue);
    expect(theme.textTheme.textStyle.fontSize, 17.0);
    expect(theme.applyThemeToAll, false);
  });

  testWidgets('Theme attributes cascade', (WidgetTester tester) async {
    final CupertinoThemeData theme = await testTheme(tester, CupertinoThemeData(
      primaryColor: CupertinoColors.systemRed,
    ));

    expect(theme.textTheme.actionTextStyle.color, isSameColorAs(CupertinoColors.systemRed.color));
  });

  testWidgets('Dependent attribute can be overridden from cascaded value', (WidgetTester tester) async {
    final CupertinoThemeData theme = await testTheme(tester, CupertinoThemeData(
      brightness: Brightness.dark,
      textTheme: const CupertinoTextThemeData(
        textStyle: TextStyle(color: CupertinoColors.black),
      ),
    ));

    // The brightness still cascaded down to the background color.
    expect(theme.scaffoldBackgroundColor, isSameColorAs(CupertinoColors.black));
    // But not to the font color which we overrode.
    expect(theme.textTheme.textStyle.color, isSameColorAs(CupertinoColors.black));
  });

  testWidgets(
    'Reading themes creates dependencies',
    (WidgetTester tester) async {
      // Reading the theme creates a dependency.
      CupertinoThemeData theme = await testTheme(tester, CupertinoThemeData(
        // Default brightness is light,
        barBackgroundColor: const Color(0x11223344),
        textTheme: const CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Skeuomorphic'),
        ),
      ));

      expect(buildCount, 1);
      expect(theme.textTheme.textStyle.fontFamily, 'Skeuomorphic');

      // Changing another property also triggers a rebuild.
      theme = await testTheme(tester, CupertinoThemeData(
        brightness: Brightness.light,
        barBackgroundColor: const Color(0x11223344),
        textTheme: const CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Skeuomorphic'),
        ),
      ));

      expect(buildCount, 2);
      // Re-reading the same value doesn't change anything.
      expect(theme.textTheme.textStyle.fontFamily, 'Skeuomorphic');

      theme = await testTheme(tester, CupertinoThemeData(
        brightness: Brightness.light,
        barBackgroundColor: const Color(0x11223344),
        textTheme: const CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Flat'),
        ),
      ));

      expect(buildCount, 3);
      expect(theme.textTheme.textStyle.fontFamily, 'Flat');
    },
  );

  testWidgets(
    'copyWith works',
    (WidgetTester tester) async {
      final CupertinoThemeData originalTheme = CupertinoThemeData(
        brightness: Brightness.dark,
        applyThemeToAll: true,
      );

      final CupertinoThemeData theme = await testTheme(tester, originalTheme.copyWith(
        primaryColor: CupertinoColors.systemGreen,
        applyThemeToAll: false,
      ));

      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, isSameColorAs(CupertinoColors.systemGreen.darkColor));
      // Now check calculated derivatives.
      expect(theme.textTheme.actionTextStyle.color, isSameColorAs(CupertinoColors.systemGreen.darkColor));
      expect(theme.scaffoldBackgroundColor, isSameColorAs(CupertinoColors.black));

      expect(theme.applyThemeToAll, false);
    },
  );

  testWidgets("Theme has default IconThemeData, which is derived from the theme's primary color", (WidgetTester tester) async {
    const CupertinoDynamicColor primaryColor = CupertinoColors.systemRed;
    final CupertinoThemeData themeData = CupertinoThemeData(primaryColor: primaryColor);

    final IconThemeData resultingIconTheme = await testIconTheme(tester, themeData);

    expect(resultingIconTheme.color, isSameColorAs(primaryColor));

    // Works in dark mode if primaryColor is a CupertinoDynamicColor.
    final Color darkColor = (await testIconTheme(
      tester,
      themeData.copyWith(brightness: Brightness.dark),
    )).color!;

    expect(darkColor, isSameColorAs(primaryColor.darkColor));
  });

  testWidgets('IconTheme.of creates a dependency on iconTheme', (WidgetTester tester) async {
    IconThemeData iconTheme = await testIconTheme(tester, CupertinoThemeData(primaryColor: CupertinoColors.destructiveRed));

    expect(buildCount, 1);
    expect(iconTheme.color, CupertinoColors.destructiveRed);

    iconTheme = await testIconTheme(tester, CupertinoThemeData(primaryColor: CupertinoColors.activeOrange));
    expect(buildCount, 2);
    expect(iconTheme.color, CupertinoColors.activeOrange);
  });

  testWidgets('CupertinoTheme diagnostics', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    CupertinoThemeData().debugFillProperties(builder);

    final Set<String> description = builder.properties
      .map((DiagnosticsNode node) => node.name.toString())
      .toSet();

    expect(
      setEquals(
        description,
        <String>{
          'brightness',
          'extensions',
          'primaryColor',
          'primaryContrastingColor',
          'barBackgroundColor',
          'scaffoldBackgroundColor',
          'applyThemeToAll',
          'textStyle',
          'actionTextStyle',
          'tabLabelTextStyle',
          'navTitleTextStyle',
          'navLargeTitleTextStyle',
          'navActionTextStyle',
          'pickerTextStyle',
          'dateTimePickerTextStyle',
        },
      ),
      isTrue,
    );
  });

  testWidgets('CupertinoTheme.toStringDeep uses single-line style', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/47651.
    expect(
      CupertinoTheme(
        data: CupertinoThemeData(primaryColor: const Color(0x00000000)),
        child: const SizedBox(),
      ).toStringDeep().trimRight(),
      isNot(contains('\n')),
    );
  });

  testWidgets('CupertinoThemeData equality', (WidgetTester tester) async {
    final CupertinoThemeData a = CupertinoThemeData(brightness: Brightness.dark);
    final CupertinoThemeData b = a.copyWith();
    final CupertinoThemeData c = a.copyWith(brightness: Brightness.light);
    expect(a, equals(b));
    expect(b, equals(a));
    expect(a, isNot(equals(c)));
    expect(c, isNot(equals(a)));
    expect(b, isNot(equals(c)));
    expect(c, isNot(equals(b)));
  });

  late Brightness currentBrightness;
  void colorMatches(Color? componentColor, CupertinoDynamicColor expectedDynamicColor) {
    switch (currentBrightness) {
      case Brightness.light:
        expect(componentColor, isSameColorAs(expectedDynamicColor.color));
      case Brightness.dark:
        expect(componentColor, isSameColorAs(expectedDynamicColor.darkColor));
    }
  }

  void dynamicColorsTestGroup() {
    testWidgets('CupertinoTheme.of resolves colors', (WidgetTester tester) async {
      final CupertinoThemeData data = CupertinoThemeData(brightness: currentBrightness, primaryColor: CupertinoColors.systemRed);
      final CupertinoThemeData theme = await testTheme(tester, data);

      expect(data.primaryColor, isSameColorAs(CupertinoColors.systemRed));
      colorMatches(theme.primaryColor, CupertinoColors.systemRed);
    });

    testWidgets('CupertinoTheme.of resolves default values', (WidgetTester tester) async {
      const CupertinoDynamicColor primaryColor = CupertinoColors.systemRed;
      final CupertinoThemeData data = CupertinoThemeData(brightness: currentBrightness, primaryColor: primaryColor);

      const CupertinoDynamicColor barBackgroundColor = CupertinoDynamicColor.withBrightness(
        color: Color(0xF0F9F9F9),
        darkColor: Color(0xF01D1D1D),
      );

      final CupertinoThemeData theme = await testTheme(tester, data);

      colorMatches(theme.primaryContrastingColor, CupertinoColors.systemBackground);
      colorMatches(theme.barBackgroundColor, barBackgroundColor);
      colorMatches(theme.scaffoldBackgroundColor, CupertinoColors.systemBackground);
      colorMatches(theme.textTheme.textStyle.color, CupertinoColors.label);
      colorMatches(theme.textTheme.actionTextStyle.color, primaryColor);
      colorMatches(theme.textTheme.tabLabelTextStyle.color, CupertinoColors.inactiveGray);
      colorMatches(theme.textTheme.navTitleTextStyle.color, CupertinoColors.label);
      colorMatches(theme.textTheme.navLargeTitleTextStyle.color, CupertinoColors.label);
      colorMatches(theme.textTheme.navActionTextStyle.color, primaryColor);
      colorMatches(theme.textTheme.pickerTextStyle.color, CupertinoColors.label);
      colorMatches(theme.textTheme.dateTimePickerTextStyle.color, CupertinoColors.label);
    });
  }

  currentBrightness = Brightness.light;
  group('light colors', dynamicColorsTestGroup);

  currentBrightness = Brightness.dark;
  group('dark colors', dynamicColorsTestGroup);

  group('Theme extensions', () {
    const Key containerKey = Key('container');

    testWidgets('can be obtained', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: CupertinoThemeData(
            extensions: const <CupertinoThemeExtension<dynamic>>{
              MyThemeExtensionA(
                color1: CupertinoColors.black,
                color2: CupertinoColors.white,
              ),
              MyThemeExtensionB(
                textTheme: CupertinoTextThemeData(
                  textStyle: TextStyle(fontSize: 50),
                ),
              ),
            },
          ),
          home: Container(key: containerKey),
        ),
      );

      final CupertinoThemeData theme = CupertinoTheme.of(
        tester.element(find.byKey(containerKey)),
      );

      expect(theme.extension<MyThemeExtensionA>()!.color1, CupertinoColors.black);
      expect(theme.extension<MyThemeExtensionA>()!.color2, CupertinoColors.white);
      expect(theme.extension<MyThemeExtensionB>()!.textTheme, const CupertinoTextThemeData(textStyle: TextStyle(fontSize: 50)));
    });

    testWidgets('can use copyWith', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: CupertinoThemeData(
            extensions: <CupertinoThemeExtension<dynamic>>{
              const MyThemeExtensionA(
                color1: CupertinoColors.black,
                color2: CupertinoColors.white,
              ).copyWith(color1: CupertinoColors.link),
            },
          ),
          home: Container(key: containerKey),
        ),
      );

      final CupertinoThemeData theme = CupertinoTheme.of(
        tester.element(find.byKey(containerKey)),
      );

      expect(theme.extension<MyThemeExtensionA>()!.color1, CupertinoColors.link);
      expect(theme.extension<MyThemeExtensionA>()!.color2, CupertinoColors.white);
    });

    testWidgets('can resolve', (WidgetTester tester) async {
      const MyThemeExtensionA extensionA = MyThemeExtensionA(
        color1: CupertinoColors.systemRed,
        color2: CupertinoColors.systemPurple,
      );

      final CupertinoThemeData dataA = CupertinoThemeData(brightness: Brightness.dark, extensions: const <CupertinoThemeExtension<dynamic>>{extensionA});
      final CupertinoThemeData themeA = await testTheme(tester, dataA);

      expect(dataA.extension<MyThemeExtensionA>()!.color1, isSameColorAs(CupertinoColors.systemRed));
      colorMatches(themeA.extension<MyThemeExtensionA>()!.color1, CupertinoColors.systemRed);
      expect(dataA.extension<MyThemeExtensionA>()!.color2, isSameColorAs(CupertinoColors.systemPurple));
      colorMatches(themeA.extension<MyThemeExtensionA>()!.color2, CupertinoColors.systemPurple);

      const MyThemeExtensionB extensionB = MyThemeExtensionB(
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(color: CupertinoColors.systemRed),
        ),
      );

      final CupertinoThemeData dataB = CupertinoThemeData(brightness: Brightness.dark, extensions: const <CupertinoThemeExtension<dynamic>>{extensionB});
      final CupertinoThemeData themeB = await testTheme(tester, dataB);

      expect(dataB.extension<MyThemeExtensionB>()!.textTheme?.textStyle.color, isSameColorAs(CupertinoColors.systemRed));
      colorMatches(themeB.extension<MyThemeExtensionB>()!.textTheme?.textStyle.color, CupertinoColors.systemRed);
    });

    testWidgets('should return null on extension not found', (WidgetTester tester) async {
      final CupertinoThemeData theme = CupertinoThemeData(
        extensions: const <CupertinoThemeExtension<dynamic>>{},
      );

      expect(theme.extension<MyThemeExtensionA>(), isNull);
    });
  });
}

@immutable
class MyThemeExtensionA extends CupertinoThemeExtension<MyThemeExtensionA> {
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
  CupertinoThemeExtension<MyThemeExtensionA> resolveFrom(BuildContext context) {
    return MyThemeExtensionA(
      color1: CupertinoDynamicColor.maybeResolve(color1, context),
      color2: CupertinoDynamicColor.maybeResolve(color2, context),
    );
  }
}

@immutable
class MyThemeExtensionB extends CupertinoThemeExtension<MyThemeExtensionB> {
  const MyThemeExtensionB({
    required this.textTheme,
  });

  final CupertinoTextThemeData? textTheme;

  @override
  MyThemeExtensionB copyWith({Color? color, CupertinoTextThemeData? textTheme}) {
    return MyThemeExtensionB(
      textTheme: textTheme ?? this.textTheme,
    );
  }

  @override
  CupertinoThemeExtension<MyThemeExtensionB> resolveFrom(BuildContext context) {
    return MyThemeExtensionB(
      textTheme: textTheme?.resolveFrom(context),
    );
  }
}
