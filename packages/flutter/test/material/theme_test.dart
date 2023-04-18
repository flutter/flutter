// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const TextTheme defaultGeometryTheme = Typography.englishLike2014;

  test('ThemeDataTween control test', () {
    final ThemeData light = ThemeData.light();
    final ThemeData dark = ThemeData.dark();
    final ThemeDataTween tween = ThemeDataTween(begin: light, end: dark);
    expect(tween.lerp(0.25), equals(ThemeData.lerp(light, dark, 0.25)));
  });

  testWidgets('PopupMenu inherits app theme', (final WidgetTester tester) async {
    final Key popupMenuButtonKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              PopupMenuButton<String>(
                key: popupMenuButtonKey,
                itemBuilder: (final BuildContext context) {
                  return <PopupMenuItem<String>>[
                    const PopupMenuItem<String>(child: Text('menuItem')),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    expect(Theme.of(tester.element(find.text('menuItem'))).brightness, equals(Brightness.dark));
  });

  testWidgets('Theme overrides selection style', (final WidgetTester tester) async {
    final Key key = UniqueKey();
    const Color defaultSelectionColor = Color(0x11111111);
    const Color defaultCursorColor = Color(0x22222222);
    const Color themeSelectionColor = Color(0x33333333);
    const Color themeCursorColor = Color(0x44444444);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: DefaultSelectionStyle(
            selectionColor: defaultSelectionColor,
            cursorColor: defaultCursorColor,
            child: Theme(
              data: ThemeData(
                textSelectionTheme: const TextSelectionThemeData(
                  selectionColor: themeSelectionColor,
                  cursorColor: themeCursorColor,
                ),
              ),
              child: TextField(
                key: key,
              ),
            )
          ),
        ),
      ),
    );
    // Finds RenderEditable.
    final RenderObject root = tester.renderObject(find.byType(EditableText));
    late RenderEditable renderEditable;
    void recursiveFinder(final RenderObject child) {
      if (child is RenderEditable) {
        renderEditable = child;
        return;
      }
      child.visitChildren(recursiveFinder);
    }
    root.visitChildren(recursiveFinder);

    // Focus text field so it has a selection color. The selection color is null
    // on an unfocused text field.
    await tester.tap(find.byKey(key));
    await tester.pump();

    expect(renderEditable.selectionColor, themeSelectionColor);
    expect(tester.widget<EditableText>(find.byType(EditableText)).cursorColor, themeCursorColor);
  });

  testWidgets('Fallback theme', (final WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      Builder(
        builder: (final BuildContext context) {
          capturedContext = context;
          return Container();
        },
      ),
    );

    expect(Theme.of(capturedContext), equals(ThemeData.localize(ThemeData.fallback(), defaultGeometryTheme)));
  });

  testWidgets('ThemeData.localize memoizes the result', (final WidgetTester tester) async {
    final ThemeData light = ThemeData.light();
    final ThemeData dark = ThemeData.dark();

    // Same input, same output.
    expect(
      ThemeData.localize(light, defaultGeometryTheme),
      same(ThemeData.localize(light, defaultGeometryTheme)),
    );

    // Different text geometry, different output.
    expect(
      ThemeData.localize(light, defaultGeometryTheme),
      isNot(same(ThemeData.localize(light, Typography.tall2014))),
    );

    // Different base theme, different output.
    expect(
      ThemeData.localize(light, defaultGeometryTheme),
      isNot(same(ThemeData.localize(dark, defaultGeometryTheme))),
    );
  });

  testWidgets('ThemeData with null typography uses proper defaults', (final WidgetTester tester) async {
    expect(ThemeData().typography, Typography.material2014());
    final ThemeData m3Theme = ThemeData(useMaterial3: true);
    expect(m3Theme.typography, Typography.material2021(colorScheme: m3Theme.colorScheme));
  });

  testWidgets('PopupMenu inherits shadowed app theme', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5572
    final Key popupMenuButtonKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                PopupMenuButton<String>(
                  key: popupMenuButtonKey,
                  itemBuilder: (final BuildContext context) {
                    return <PopupMenuItem<String>>[
                      const PopupMenuItem<String>(child: Text('menuItem')),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    expect(Theme.of(tester.element(find.text('menuItem'))).brightness, equals(Brightness.light));
  });

  testWidgets('DropdownMenu inherits shadowed app theme', (final WidgetTester tester) async {
    final Key dropdownMenuButtonKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                DropdownButton<String>(
                  key: dropdownMenuButtonKey,
                  onChanged: (final String? newValue) { },
                  value: 'menuItem',
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'menuItem',
                      child: Text('menuItem'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(dropdownMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    for (final Element item in tester.elementList(find.text('menuItem'))) {
      expect(Theme.of(item).brightness, equals(Brightness.light));
    }
  });

  testWidgets('ModalBottomSheet inherits shadowed app theme', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (final BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (final BuildContext context) => const Text('bottomSheet'),
                      );
                    },
                    child: const Text('SHOW'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation
    expect(Theme.of(tester.element(find.text('bottomSheet'))).brightness, equals(Brightness.light));
  });

  testWidgets('Dialog inherits shadowed app theme', (final WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Scaffold(
            key: scaffoldKey,
            body: Center(
              child: Builder(
                builder: (final BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (final BuildContext context) => const Text('dialog'),
                      );
                    },
                    child: const Text('SHOW'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('dialog'))).brightness, equals(Brightness.light));
  });

  testWidgets("Scaffold inherits theme's scaffoldBackgroundColor", (final WidgetTester tester) async {
    const Color green = Color(0xFF00FF00);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: green),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (final BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (final BuildContext context) {
                        return const Scaffold(
                          body: SizedBox(
                            width: 200.0,
                            height: 200.0,
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('SHOW'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(const Duration(seconds: 1));

    final List<Material> materials = tester.widgetList<Material>(find.byType(Material)).toList();
    expect(materials.length, equals(2));
    expect(materials[0].color, green); // app scaffold
    expect(materials[1].color, green); // dialog scaffold
  });

  testWidgets('IconThemes are applied', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(iconTheme: const IconThemeData(color: Colors.green, size: 10.0)),
        home: const Icon(Icons.computer),
      ),
    );

    RenderParagraph glyphText = tester.renderObject(find.byType(RichText));

    expect(glyphText.text.style!.color, Colors.green);
    expect(glyphText.text.style!.fontSize, 10.0);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(iconTheme: const IconThemeData(color: Colors.orange, size: 20.0)),
        home: const Icon(Icons.computer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // Halfway through the theme transition

    glyphText = tester.renderObject(find.byType(RichText));

    expect(glyphText.text.style!.color, Color.lerp(Colors.green, Colors.orange, 0.5));
    expect(glyphText.text.style!.fontSize, 15.0);

    await tester.pump(const Duration(milliseconds: 100)); // Finish the transition
    glyphText = tester.renderObject(find.byType(RichText));

    expect(glyphText.text.style!.color, Colors.orange);
    expect(glyphText.text.style!.fontSize, 20.0);
  });

  testWidgets(
    'Same ThemeData reapplied does not trigger descendants rebuilds',
    (final WidgetTester tester) async {
      testBuildCalled = 0;
      ThemeData themeData = ThemeData(primaryColor: const Color(0xFF000000));

      Widget buildTheme() {
        return Theme(
          data: themeData,
          child: const Test(),
        );
      }

      await tester.pumpWidget(buildTheme());
      expect(testBuildCalled, 1);

      // Pump the same widgets again.
      await tester.pumpWidget(buildTheme());
      // No repeated build calls to the child since it's the same theme data.
      expect(testBuildCalled, 1);

      // New instance of theme data but still the same content.
      themeData = ThemeData(primaryColor: const Color(0xFF000000));
      await tester.pumpWidget(buildTheme());
      // Still no repeated calls.
      expect(testBuildCalled, 1);

      // Different now.
      themeData = ThemeData(primaryColor: const Color(0xFF222222));
      await tester.pumpWidget(buildTheme());
      // Should call build again.
      expect(testBuildCalled, 2);
    },
  );

  testWidgets('Text geometry set in Theme has higher precedence than that of Localizations', (final WidgetTester tester) async {
    const double kMagicFontSize = 4321.0;
    final ThemeData fallback = ThemeData.fallback();
    final ThemeData customTheme = fallback.copyWith(
      primaryTextTheme: fallback.primaryTextTheme.copyWith(
        bodyMedium: fallback.primaryTextTheme.bodyMedium!.copyWith(
          fontSize: kMagicFontSize,
        ),
      ),
    );
    expect(customTheme.primaryTextTheme.bodyMedium!.fontSize, kMagicFontSize);

    late double actualFontSize;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: customTheme,
        child: Builder(builder: (final BuildContext context) {
          final ThemeData theme = Theme.of(context);
          actualFontSize = theme.primaryTextTheme.bodyMedium!.fontSize!;
          return Text(
            'A',
            style: theme.primaryTextTheme.bodyMedium,
          );
        }),
      ),
    ));

    expect(actualFontSize, kMagicFontSize);
  });

  testWidgets('Default Theme provides all basic TextStyle properties', (final WidgetTester tester) async {
    late ThemeData theme;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (final BuildContext context) {
          theme = Theme.of(context);
          return const Text('A');
        },
      ),
    ));

    List<TextStyle> extractStyles(final TextTheme textTheme) {
      return <TextStyle>[
        textTheme.displayLarge!,
        textTheme.displayMedium!,
        textTheme.displaySmall!,
        textTheme.headlineLarge!,
        textTheme.headlineMedium!,
        textTheme.headlineSmall!,
        textTheme.titleLarge!,
        textTheme.titleMedium!,
        textTheme.bodyLarge!,
        textTheme.bodyMedium!,
        textTheme.bodySmall!,
        textTheme.labelLarge!,
        textTheme.labelMedium!,
      ];
    }

    for (final TextTheme textTheme in <TextTheme>[theme.textTheme, theme.primaryTextTheme]) {
      for (final TextStyle style in extractStyles(textTheme).map<TextStyle>((final TextStyle style) => _TextStyleProxy(style))) {
        expect(style.inherit, false);
        expect(style.color, isNotNull);
        expect(style.fontFamily, isNotNull);
        expect(style.fontSize, isNotNull);
        expect(style.fontWeight, isNotNull);
        expect(style.fontStyle, null);
        expect(style.letterSpacing, null);
        expect(style.wordSpacing, null);
        expect(style.textBaseline, isNotNull);
        expect(style.height, null);
        expect(style.decoration, TextDecoration.none);
        expect(style.decorationColor, null);
        expect(style.decorationStyle, null);
        expect(style.debugLabel, isNotNull);
        expect(style.locale, null);
        expect(style.background, null);
      }
    }

    expect(theme.textTheme.displayLarge!.debugLabel, '(englishLike displayLarge 2014).merge(blackMountainView displayLarge)');
  });

  group('Cupertino theme', () {
    late int buildCount;
    CupertinoThemeData? actualTheme;
    IconThemeData? actualIconTheme;
    BuildContext? context;

    final Widget singletonThemeSubtree = Builder(
      builder: (final BuildContext localContext) {
        buildCount++;
        actualTheme = CupertinoTheme.of(localContext);
        actualIconTheme = IconTheme.of(localContext);
        context = localContext;
        return const Placeholder();
      },
    );

    Future<CupertinoThemeData> testTheme(final WidgetTester tester, final ThemeData theme) async {
      await tester.pumpWidget(Theme(data: theme, child: singletonThemeSubtree));
      return actualTheme!;
    }

    setUp(() {
      buildCount = 0;
      actualTheme = null;
      actualIconTheme = null;
      context = null;
    });

    testWidgets('Default theme has defaults', (final WidgetTester tester) async {
      final CupertinoThemeData theme = await testTheme(tester, ThemeData.light());

      expect(theme.brightness, Brightness.light);
      expect(theme.primaryColor, Colors.blue);
      expect(theme.scaffoldBackgroundColor, Colors.grey[50]);
      expect(theme.primaryContrastingColor, Colors.white);
      expect(theme.textTheme.textStyle.fontFamily, '.SF Pro Text');
      expect(theme.textTheme.textStyle.fontSize, 17.0);
    });

    testWidgets('Dark theme has defaults', (final WidgetTester tester) async {
      final CupertinoThemeData theme = await testTheme(tester, ThemeData.dark());

      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, Colors.blue);
      expect(theme.primaryContrastingColor, Colors.white);
      expect(theme.scaffoldBackgroundColor, Colors.grey[850]);
      expect(theme.textTheme.textStyle.fontFamily, '.SF Pro Text');
      expect(theme.textTheme.textStyle.fontSize, 17.0);
    });

    testWidgets('MaterialTheme overrides the brightness', (final WidgetTester tester) async {
      await testTheme(tester, ThemeData.dark());
      expect(CupertinoTheme.brightnessOf(context!), Brightness.dark);

      await testTheme(tester, ThemeData.light());
      expect(CupertinoTheme.brightnessOf(context!), Brightness.light);

      // Overridable by cupertinoOverrideTheme.
      await testTheme(tester, ThemeData(
        brightness: Brightness.light,
        cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.dark),
      ));
      expect(CupertinoTheme.brightnessOf(context!), Brightness.dark);

      await testTheme(tester, ThemeData(
        brightness: Brightness.dark,
        cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.light),
      ));
      expect(CupertinoTheme.brightnessOf(context!), Brightness.light);
    });

    testWidgets('Can override material theme', (final WidgetTester tester) async {
      final CupertinoThemeData theme = await testTheme(tester, ThemeData(
        cupertinoOverrideTheme: const CupertinoThemeData(
          scaffoldBackgroundColor: CupertinoColors.lightBackgroundGray,
        ),
      ));

      expect(theme.brightness, Brightness.light);
      // We took the scaffold background override but the rest are still cascaded
      // to the material theme.
      expect(theme.primaryColor, Colors.blue);
      expect(theme.primaryContrastingColor, Colors.white);
      expect(theme.scaffoldBackgroundColor, CupertinoColors.lightBackgroundGray);
      expect(theme.textTheme.textStyle.fontFamily, '.SF Pro Text');
      expect(theme.textTheme.textStyle.fontSize, 17.0);
    });

    testWidgets('Can override properties that are independent of material', (final WidgetTester tester) async {
      final CupertinoThemeData theme = await testTheme(tester, ThemeData(
        cupertinoOverrideTheme: const CupertinoThemeData(
          // The bar colors ignore all things material except brightness.
          barBackgroundColor: CupertinoColors.black,
        ),
      ));

      expect(theme.primaryColor, Colors.blue);
      // MaterialBasedCupertinoThemeData should also function like a normal CupertinoThemeData.
      expect(theme.barBackgroundColor, CupertinoColors.black);
    });

    testWidgets('Changing material theme triggers rebuilds', (final WidgetTester tester) async {
      CupertinoThemeData theme = await testTheme(tester, ThemeData(
        primarySwatch: Colors.red,
      ));

      expect(buildCount, 1);
      expect(theme.primaryColor, Colors.red);

      theme = await testTheme(tester, ThemeData(
        primarySwatch: Colors.orange,
      ));

      expect(buildCount, 2);
      expect(theme.primaryColor, Colors.orange);
    });

    testWidgets(
      "CupertinoThemeData does not override material theme's icon theme",
      (final WidgetTester tester) async {
        const Color materialIconColor = Colors.blue;
        const Color cupertinoIconColor = Colors.black;

        await testTheme(tester, ThemeData(
            iconTheme: const IconThemeData(color: materialIconColor),
            cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: cupertinoIconColor),
        ));

        expect(buildCount, 1);
        expect(actualIconTheme!.color, materialIconColor);
      },
    );

    testWidgets(
      'Changing cupertino theme override triggers rebuilds',
      (final WidgetTester tester) async {
        CupertinoThemeData theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.purple,
          cupertinoOverrideTheme: const CupertinoThemeData(
            primaryColor: CupertinoColors.activeOrange,
          ),
        ));

        expect(buildCount, 1);
        expect(theme.primaryColor, CupertinoColors.activeOrange);

        theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.purple,
          cupertinoOverrideTheme: const CupertinoThemeData(
            primaryColor: CupertinoColors.activeGreen,
          ),
        ));

        expect(buildCount, 2);
        expect(theme.primaryColor, CupertinoColors.activeGreen);
      },
    );

    testWidgets(
      'Cupertino theme override blocks derivative changes',
      (final WidgetTester tester) async {
        CupertinoThemeData theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.purple,
          cupertinoOverrideTheme: const CupertinoThemeData(
            primaryColor: CupertinoColors.activeOrange,
          ),
        ));

        expect(buildCount, 1);
        expect(theme.primaryColor, CupertinoColors.activeOrange);

        // Change the upstream material primary color.
        theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.blue,
          cupertinoOverrideTheme: const CupertinoThemeData(
            // But the primary material color is preempted by the override.
            primaryColor: CupertinoColors.systemRed,
          ),
        ));

        expect(buildCount, 2);
        expect(theme.primaryColor, CupertinoColors.systemRed);
      },
    );

    testWidgets(
      'Cupertino overrides do not block derivatives triggering rebuilds when derivatives are not overridden',
      (final WidgetTester tester) async {
        CupertinoThemeData theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.purple,
          cupertinoOverrideTheme: const CupertinoThemeData(
            primaryContrastingColor: CupertinoColors.destructiveRed,
          ),
        ));

        expect(buildCount, 1);
        expect(theme.textTheme.actionTextStyle.color, Colors.purple);
        expect(theme.primaryContrastingColor, CupertinoColors.destructiveRed);

        theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.green,
          cupertinoOverrideTheme: const CupertinoThemeData(
            primaryContrastingColor: CupertinoColors.destructiveRed,
          ),
        ));

        expect(buildCount, 2);
        expect(theme.textTheme.actionTextStyle.color, Colors.green);
        expect(theme.primaryContrastingColor, CupertinoColors.destructiveRed);
      },
    );

    testWidgets(
      'copyWith only copies the overrides, not the material or cupertino derivatives',
      (final WidgetTester tester) async {
        final CupertinoThemeData originalTheme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.purple,
          cupertinoOverrideTheme: const CupertinoThemeData(
            primaryContrastingColor: CupertinoColors.activeOrange,
          ),
        ));

        final CupertinoThemeData copiedTheme = originalTheme.copyWith(
          barBackgroundColor: CupertinoColors.destructiveRed,
        );

        final CupertinoThemeData theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.blue,
          cupertinoOverrideTheme: copiedTheme,
        ));

        expect(theme.primaryColor, Colors.blue);
        expect(theme.primaryContrastingColor, CupertinoColors.activeOrange);
        expect(theme.barBackgroundColor, CupertinoColors.destructiveRed);
      },
    );

    testWidgets(
      "Material themes with no cupertino overrides can also be copyWith'ed",
      (final WidgetTester tester) async {
        final CupertinoThemeData originalTheme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.purple,
        ));

        final CupertinoThemeData copiedTheme = originalTheme.copyWith(
          primaryContrastingColor: CupertinoColors.destructiveRed,
        );

        final CupertinoThemeData theme = await testTheme(tester, ThemeData(
          primarySwatch: Colors.blue,
          cupertinoOverrideTheme: copiedTheme,
        ));

        expect(theme.primaryColor, Colors.blue);
        expect(theme.primaryContrastingColor, CupertinoColors.destructiveRed);
      },
    );
  });
}

int testBuildCalled = 0;
class Test extends StatelessWidget {
  const Test({ super.key });

  @override
  Widget build(final BuildContext context) {
    testBuildCalled += 1;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

/// This class exists only to make sure that we test all the properties of the
/// [TextStyle] class. If a property is added/removed/renamed, the analyzer will
/// complain that this class has incorrect overrides.
// ignore: avoid_implementing_value_types
class _TextStyleProxy implements TextStyle {
  _TextStyleProxy(this._delegate);

  final TextStyle _delegate;

  // Do make sure that all the properties correctly forward to the _delegate.
  @override
  Color? get color => _delegate.color;
  @override
  Color? get backgroundColor => _delegate.backgroundColor;
  @override
  String? get debugLabel => _delegate.debugLabel;
  @override
  TextDecoration? get decoration => _delegate.decoration;
  @override
  Color? get decorationColor => _delegate.decorationColor;
  @override
  TextDecorationStyle? get decorationStyle => _delegate.decorationStyle;
  @override
  double? get decorationThickness => _delegate.decorationThickness;
  @override
  String? get fontFamily => _delegate.fontFamily;
  @override
  List<String>? get fontFamilyFallback => _delegate.fontFamilyFallback;
  @override
  double? get fontSize => _delegate.fontSize;
  @override
  FontStyle? get fontStyle => _delegate.fontStyle;
  @override
  FontWeight? get fontWeight => _delegate.fontWeight;
  @override
  double? get height => _delegate.height;
  @override
  TextLeadingDistribution? get leadingDistribution => _delegate.leadingDistribution;
  @override
  Locale? get locale => _delegate.locale;
  @override
  ui.Paint? get foreground => _delegate.foreground;
  @override
  ui.Paint? get background => _delegate.background;
  @override
  bool get inherit => _delegate.inherit;
  @override
  double? get letterSpacing => _delegate.letterSpacing;
  @override
  TextBaseline? get textBaseline => _delegate.textBaseline;
  @override
  double? get wordSpacing => _delegate.wordSpacing;
  @override
  List<Shadow>? get shadows => _delegate.shadows;
  @override
  List<ui.FontFeature>? get fontFeatures => _delegate.fontFeatures;
  @override
  List<ui.FontVariation>? get fontVariations => _delegate.fontVariations;
  @override
  TextOverflow? get overflow => _delegate.overflow;

  @override
  String toString({ final DiagnosticLevel minLevel = DiagnosticLevel.info }) =>
      super.toString();

  @override
  DiagnosticsNode toDiagnosticsNode({ final String? name, final DiagnosticsTreeStyle? style }) {
    throw UnimplementedError();
  }

  @override
  String toStringShort() {
    throw UnimplementedError();
  }

  @override
  TextStyle apply({
    final Color? color,
    final Color? backgroundColor,
    final TextDecoration? decoration,
    final Color? decorationColor,
    final TextDecorationStyle? decorationStyle,
    final double decorationThicknessFactor = 1.0,
    final double decorationThicknessDelta = 0.0,
    final String? fontFamily,
    final List<String>? fontFamilyFallback,
    final double fontSizeFactor = 1.0,
    final double fontSizeDelta = 0.0,
    final int fontWeightDelta = 0,
    final FontStyle? fontStyle,
    final double letterSpacingFactor = 1.0,
    final double letterSpacingDelta = 0.0,
    final double wordSpacingFactor = 1.0,
    final double wordSpacingDelta = 0.0,
    final double heightFactor = 1.0,
    final double heightDelta = 0.0,
    final TextLeadingDistribution? leadingDistribution,
    final TextBaseline? textBaseline,
    final Locale? locale,
    final List<ui.Shadow>? shadows,
    final List<ui.FontFeature>? fontFeatures,
    final List<ui.FontVariation>? fontVariations,
    final TextOverflow? overflow,
    final String? package,
  }) {
    throw UnimplementedError();
  }

  @override
  RenderComparison compareTo(final TextStyle other) {
    throw UnimplementedError();
  }

  @override
  TextStyle copyWith({
    final bool? inherit,
    final Color? color,
    final Color? backgroundColor,
    final String? fontFamily,
    final List<String>? fontFamilyFallback,
    final double? fontSize,
    final FontWeight? fontWeight,
    final FontStyle? fontStyle,
    final double? letterSpacing,
    final double? wordSpacing,
    final TextBaseline? textBaseline,
    final double? height,
    final TextLeadingDistribution? leadingDistribution,
    final Locale? locale,
    final ui.Paint? foreground,
    final ui.Paint? background,
    final List<Shadow>? shadows,
    final List<ui.FontFeature>? fontFeatures,
    final List<ui.FontVariation>? fontVariations,
    final TextDecoration? decoration,
    final Color? decorationColor,
    final TextDecorationStyle? decorationStyle,
    final double? decorationThickness,
    final String? debugLabel,
    final TextOverflow? overflow,
    final String? package,
  }) {
    throw UnimplementedError();
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties, { final String prefix = '' }) {
    throw UnimplementedError();
  }

  @override
  ui.ParagraphStyle getParagraphStyle({
    final TextAlign? textAlign,
    final TextDirection? textDirection,
    final double textScaleFactor = 1.0,
    final String? ellipsis,
    final int? maxLines,
    final ui.TextHeightBehavior? textHeightBehavior,
    final Locale? locale,
    final String? fontFamily,
    final double? fontSize,
    final FontWeight? fontWeight,
    final FontStyle? fontStyle,
    final double? height,
    final StrutStyle? strutStyle,
  }) {
    throw UnimplementedError();
  }

  @override
  ui.TextStyle getTextStyle({ final double textScaleFactor = 1.0 }) {
    throw UnimplementedError();
  }

  @override
  TextStyle merge(final TextStyle? other) {
    throw UnimplementedError();
  }
}
