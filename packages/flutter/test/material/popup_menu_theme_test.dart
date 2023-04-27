// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

PopupMenuThemeData _popupMenuThemeM2() {
  return PopupMenuThemeData(
    color: Colors.orange,
    shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    elevation: 12.0,
    textStyle: const TextStyle(color: Color(0xffffffff), textBaseline: TextBaseline.alphabetic),
    mouseCursor: MaterialStateProperty.resolveWith<MouseCursor?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return SystemMouseCursors.contextMenu;
      }
      return SystemMouseCursors.alias;
    }),
  );
}

PopupMenuThemeData _popupMenuThemeM3() {
  return PopupMenuThemeData(
    color: Colors.orange,
    shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    elevation: 12.0,
    shadowColor: const Color(0xff00ff00),
    surfaceTintColor: const Color(0xff00ff00),
    labelTextStyle: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return const TextStyle(color: Color(0xfff99ff0), fontSize: 12.0);
      }
      return const TextStyle(color: Color(0xfff12099), fontSize: 17.0);
    }),
    mouseCursor: MaterialStateProperty.resolveWith<MouseCursor?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return SystemMouseCursors.contextMenu;
      }
      return SystemMouseCursors.alias;
    }),
  );
}

void main() {
  test('PopupMenuThemeData copyWith, ==, hashCode basics', () {
    expect(const PopupMenuThemeData(), const PopupMenuThemeData().copyWith());
    expect(const PopupMenuThemeData().hashCode, const PopupMenuThemeData().copyWith().hashCode);
  });

  test('PopupMenuThemeData lerp special cases', () {
    expect(PopupMenuThemeData.lerp(null, null, 0), null);
    const PopupMenuThemeData data = PopupMenuThemeData();
    expect(identical(PopupMenuThemeData.lerp(data, data, 0.5), data), true);
  });

  test('PopupMenuThemeData null fields by default', () {
    const PopupMenuThemeData popupMenuTheme = PopupMenuThemeData();
    expect(popupMenuTheme.color, null);
    expect(popupMenuTheme.shape, null);
    expect(popupMenuTheme.elevation, null);
    expect(popupMenuTheme.shadowColor, null);
    expect(popupMenuTheme.surfaceTintColor, null);
    expect(popupMenuTheme.textStyle, null);
    expect(popupMenuTheme.labelTextStyle, null);
    expect(popupMenuTheme.enableFeedback, null);
    expect(popupMenuTheme.mouseCursor, null);
  });

  testWidgets('Default PopupMenuThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const PopupMenuThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('PopupMenuThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
     PopupMenuThemeData(
      color: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0))),
      elevation: 2.0,
      shadowColor: const Color(0xff00ff00),
      surfaceTintColor: const Color(0xff00ff00),
      textStyle: const TextStyle(color: Color(0xffffffff)),
      labelTextStyle: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return const TextStyle(color: Color(0xfff99ff0), fontSize: 12.0);
        }
        return const TextStyle(color: Color(0xfff12099), fontSize: 17.0);
      }),
      mouseCursor: MaterialStateMouseCursor.clickable,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'color: Color(0xffffffff)',
      'shape: RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(2.0))',
      'elevation: 2.0',
      'shadowColor: Color(0xff00ff00)',
      'surfaceTintColor: Color(0xff00ff00)',
      'text style: TextStyle(inherit: true, color: Color(0xffffffff))',
      "labelTextStyle: Instance of '_MaterialStatePropertyWith<TextStyle?>'",
      'mouseCursor: MaterialStateMouseCursor(clickable)',
    ]);
  });

  testWidgets('Passing no PopupMenuThemeData returns defaults', (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key enabledPopupItemKey = UniqueKey();
    final Key disabledPopupItemKey = UniqueKey();
    final ThemeData theme = ThemeData(useMaterial3: true);

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            Padding(
              // The padding makes sure the menu has enough space around it to
              // get properly aligned when displayed (`_kMenuScreenPadding`).
              padding: const EdgeInsets.all(8.0),
              child: PopupMenuButton<void>(
                key: popupButtonKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      key: enabledPopupItemKey,
                      child: const Text('Enabled PopupMenuItem'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<void>(
                      key: disabledPopupItemKey,
                      enabled: false,
                      child: const Text('Disabled PopupMenuItem'),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    /// The last Material widget under popupButtonApp is the [PopupMenuButton]
    /// specified above, so by finding the last descendent of popupButtonApp
    /// that is of type Material, this code retrieves the built
    /// [PopupMenuButton].
    final Material button = tester.widget<Material>(
      find.descendant(
        of: find.byKey(popupButtonApp),
        matching: find.byType(Material),
      ).last,
    );
    expect(button.color, theme.colorScheme.surface);
    expect(button.shadowColor, theme.colorScheme.shadow);
    expect(button.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(button.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(button.elevation, 3.0);

    /// The last DefaultTextStyle widget under popupItemKey is the
    /// [PopupMenuItem] specified above, so by finding the last descendent of
    /// popupItemKey that is of type DefaultTextStyle, this code retrieves the
    /// built [PopupMenuItem].
    final DefaultTextStyle enabledText = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byKey(enabledPopupItemKey),
        matching: find.byType(DefaultTextStyle),
      ).last,
    );
    expect(enabledText.style.fontFamily, 'Roboto');
    expect(enabledText.style.color, theme.colorScheme.onSurface);
    /// Test disabled text color
    final DefaultTextStyle disabledText = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byKey(disabledPopupItemKey),
        matching: find.byType(DefaultTextStyle),
      ).last,
    );
    expect(disabledText.style.color, theme.colorScheme.onSurface.withOpacity(0.38));

    final Offset topLeftButton = tester.getTopLeft(find.byType(PopupMenuButton<void>));
    final Offset topLeftMenu = tester.getTopLeft(find.byWidget(button));
    expect(topLeftMenu, topLeftButton);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byKey(disabledPopupItemKey)));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );
    await gesture.down(tester.getCenter(find.byKey(enabledPopupItemKey)));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
  });

  testWidgets('Popup menu uses values from PopupMenuThemeData', (WidgetTester tester) async {
    final PopupMenuThemeData popupMenuTheme = _popupMenuThemeM3();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key enabledPopupItemKey = UniqueKey();
    final Key disabledPopupItemKey = UniqueKey();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, popupMenuTheme: popupMenuTheme),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              // The padding is used in the positioning of the menu when the
              // position is `PopupMenuPosition.under`. Setting it to zero makes
              // it easier to test.
              padding: EdgeInsets.zero,
              key: popupButtonKey,
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<Object>>[
                  PopupMenuItem<Object>(
                    key: disabledPopupItemKey,
                    enabled: false,
                    child: const Text('disabled'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<Object>(
                    key: enabledPopupItemKey,
                    onTap: () { },
                    child: const Text('enabled'),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    /// The last Material widget under popupButtonApp is the [PopupMenuButton]
    /// specified above, so by finding the last descendent of popupButtonApp
    /// that is of type Material, this code retrieves the built
    /// [PopupMenuButton].
    final Material button = tester.widget<Material>(
      find.descendant(
        of: find.byKey(popupButtonApp),
        matching: find.byType(Material),
      ).last,
    );
    expect(button.color, Colors.orange);
    expect(button.surfaceTintColor, const Color(0xff00ff00));
    expect(button.shadowColor, const Color(0xff00ff00));
    expect(button.shape, const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))));
    expect(button.elevation, 12.0);

    final DefaultTextStyle enabledText = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byKey(enabledPopupItemKey),
        matching: find.byType(DefaultTextStyle),
      ).last,
    );
    expect(
      enabledText.style,
      popupMenuTheme.labelTextStyle?.resolve(enabled),
    );
    /// Test disabled text color
    final DefaultTextStyle disabledText = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byKey(disabledPopupItemKey),
        matching: find.byType(DefaultTextStyle),
      ).last,
    );
    expect(
      disabledText.style,
      popupMenuTheme.labelTextStyle?.resolve(disabled),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byKey(disabledPopupItemKey)));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      popupMenuTheme.mouseCursor?.resolve(disabled),
    );
    await gesture.down(tester.getCenter(find.byKey(enabledPopupItemKey)));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      popupMenuTheme.mouseCursor?.resolve(enabled),
    );
  });

  testWidgets('Popup menu widget properties take priority over theme', (WidgetTester tester) async {
    final PopupMenuThemeData popupMenuTheme = _popupMenuThemeM3();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

    const Color color = Colors.purple;
    const Color surfaceTintColor = Colors.amber;
    const Color shadowColor = Colors.green;
    const ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
    );
    const double elevation = 7.0;
    const TextStyle textStyle = TextStyle(color: Color(0xffffffef), fontSize: 19.0);
    const MouseCursor cursor =  SystemMouseCursors.forbidden;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, popupMenuTheme: popupMenuTheme),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              key: popupButtonKey,
              elevation: elevation,
              shadowColor: shadowColor,
              surfaceTintColor: surfaceTintColor,
              color: color,
              shape: shape,
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<void>>[
                  PopupMenuItem<void>(
                    key: popupItemKey,
                    labelTextStyle: MaterialStateProperty.all<TextStyle>(textStyle),
                    mouseCursor: cursor,
                    child: const Text('Example'),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    /// The last Material widget under popupButtonApp is the [PopupMenuButton]
    /// specified above, so by finding the last descendent of popupButtonApp
    /// that is of type Material, this code retrieves the built
    /// [PopupMenuButton].
    final Material button = tester.widget<Material>(
      find.descendant(
        of: find.byKey(popupButtonApp),
        matching: find.byType(Material),
      ).last,
    );
    expect(button.color, color);
    expect(button.shape, shape);
    expect(button.elevation, elevation);
    expect(button.shadowColor, shadowColor);
    expect(button.surfaceTintColor, surfaceTintColor);

    /// The last DefaultTextStyle widget under popupItemKey is the
    /// [PopupMenuItem] specified above, so by finding the last descendent of
    /// popupItemKey that is of type DefaultTextStyle, this code retrieves the
    /// built [PopupMenuItem].
    final DefaultTextStyle text = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byKey(popupItemKey),
        matching: find.byType(DefaultTextStyle),
      ).last,
    );
    expect(text.style, textStyle);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byKey(popupItemKey)));
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), cursor);
  });

  group('Material 2', () {
    // Tests that are only relevant for Material 2. Once ThemeData.useMaterial3
    // is turned on by default, these tests can be removed.

    testWidgets('Passing no PopupMenuThemeData returns defaults', (WidgetTester tester) async {
     final Key popupButtonKey = UniqueKey();
      final Key popupButtonApp = UniqueKey();
      final Key enabledPopupItemKey = UniqueKey();
      final Key disabledPopupItemKey = UniqueKey();
      final ThemeData theme = ThemeData();

      await tester.pumpWidget(MaterialApp(
        theme: theme,
        key: popupButtonApp,
        home: Material(
          child: Column(
            children: <Widget>[
              Padding(
              // The padding makes sure the menu has enough space around it to
              // get properly aligned when displayed (`_kMenuScreenPadding`).
              padding: const EdgeInsets.all(8.0),
                child: PopupMenuButton<void>(
                  key: popupButtonKey,
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<void>>[
                      PopupMenuItem<void>(
                        key: enabledPopupItemKey,
                        child: const Text('Enabled PopupMenuItem'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<void>(
                        key: disabledPopupItemKey,
                        enabled: false,
                        child: const Text('Disabled PopupMenuItem'),
                      ),
                    ];
                  },
                ),
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.byKey(popupButtonKey));
      await tester.pumpAndSettle();

      /// The last Material widget under popupButtonApp is the [PopupMenuButton]
      /// specified above, so by finding the last descendent of popupButtonApp
      /// that is of type Material, this code retrieves the built
      /// [PopupMenuButton].
      final Material button = tester.widget<Material>(
        find.descendant(
          of: find.byKey(popupButtonApp),
          matching: find.byType(Material),
        ).last,
      );
      expect(button.color, null);
      expect(button.shape, null);
      expect(button.elevation, 8.0);

      /// The last DefaultTextStyle widget under popupItemKey is the
      /// [PopupMenuItem] specified above, so by finding the last descendent of
      /// popupItemKey that is of type DefaultTextStyle, this code retrieves the
      /// built [PopupMenuItem].
      final DefaultTextStyle enabledText = tester.widget<DefaultTextStyle>(
        find.descendant(
          of: find.byKey(enabledPopupItemKey),
          matching: find.byType(DefaultTextStyle),
        ).last,
      );
      expect(enabledText.style.fontFamily, 'Roboto');
      expect(enabledText.style.color, const Color(0xdd000000));
      /// Test disabled text color
      final DefaultTextStyle disabledText = tester.widget<DefaultTextStyle>(
        find.descendant(
          of: find.byKey(disabledPopupItemKey),
          matching: find.byType(DefaultTextStyle),
        ).last,
      );
      expect(disabledText.style.color, theme.disabledColor);

      final Offset topLeftButton = tester.getTopLeft(find.byType(PopupMenuButton<void>));
      final Offset topLeftMenu = tester.getTopLeft(find.byWidget(button));
      expect(topLeftMenu, topLeftButton);

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byKey(disabledPopupItemKey)));
      await tester.pumpAndSettle();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic,
      );
      await gesture.down(tester.getCenter(find.byKey(enabledPopupItemKey)));
      await tester.pumpAndSettle();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
    });

    testWidgets('Popup menu uses values from PopupMenuThemeData', (WidgetTester tester) async {
      final PopupMenuThemeData popupMenuTheme = _popupMenuThemeM2();
      final Key popupButtonKey = UniqueKey();
      final Key popupButtonApp = UniqueKey();
      final Key enabledPopupItemKey = UniqueKey();
      final Key disabledPopupItemKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(popupMenuTheme: popupMenuTheme),
        key: popupButtonApp,
        home: Material(
          child: Column(
            children: <Widget>[
              PopupMenuButton<void>(
                // The padding is used in the positioning of the menu when the
                // position is `PopupMenuPosition.under`. Setting it to zero makes
                // it easier to test.
                padding: EdgeInsets.zero,
                key: popupButtonKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<Object>>[
                    PopupMenuItem<Object>(
                      key: disabledPopupItemKey,
                      enabled: false,
                      child: const Text('disabled'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<Object>(
                      key: enabledPopupItemKey,
                      onTap: () { },
                      child: const Text('enabled'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.byKey(popupButtonKey));
      await tester.pumpAndSettle();

      /// The last Material widget under popupButtonApp is the [PopupMenuButton]
      /// specified above, so by finding the last descendent of popupButtonApp
      /// that is of type Material, this code retrieves the built
      /// [PopupMenuButton].
      final Material button = tester.widget<Material>(
        find.descendant(
          of: find.byKey(popupButtonApp),
          matching: find.byType(Material),
        ).last,
      );
      expect(button.color, popupMenuTheme.color);
      expect(button.shape, popupMenuTheme.shape);
      expect(button.elevation, popupMenuTheme.elevation);

      /// The last DefaultTextStyle widget under popupItemKey is the
      /// [PopupMenuItem] specified above, so by finding the last descendent of
      /// popupItemKey that is of type DefaultTextStyle, this code retrieves the
      /// built [PopupMenuItem].
      final DefaultTextStyle text = tester.widget<DefaultTextStyle>(
        find.descendant(
          of: find.byKey(enabledPopupItemKey),
          matching: find.byType(DefaultTextStyle),
        ).last,
      );
      expect(text.style, popupMenuTheme.textStyle);

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byKey(disabledPopupItemKey)));
      await tester.pumpAndSettle();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        popupMenuTheme.mouseCursor?.resolve(disabled),
      );
      await gesture.down(tester.getCenter(find.byKey(enabledPopupItemKey)));
      await tester.pumpAndSettle();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        popupMenuTheme.mouseCursor?.resolve(enabled),
      );
    });

    testWidgets('Popup menu widget properties take priority over theme', (WidgetTester tester) async {
      final PopupMenuThemeData popupMenuTheme = _popupMenuThemeM2();
      final Key popupButtonKey = UniqueKey();
      final Key popupButtonApp = UniqueKey();
      final Key popupItemKey = UniqueKey();

      const Color color = Colors.purple;
      const Color surfaceTintColor = Colors.amber;
      const Color shadowColor = Colors.green;
      const ShapeBorder shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(9.0)),
      );
      const double elevation = 7.0;
      const TextStyle textStyle = TextStyle(color: Color(0xffffffef), fontSize: 19.0);
      const MouseCursor cursor =  SystemMouseCursors.forbidden;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true, popupMenuTheme: popupMenuTheme),
        key: popupButtonApp,
        home: Material(
          child: Column(
            children: <Widget>[
              PopupMenuButton<void>(
                key: popupButtonKey,
                elevation: elevation,
                shadowColor: shadowColor,
                surfaceTintColor: surfaceTintColor,
                color: color,
                shape: shape,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      key: popupItemKey,
                      labelTextStyle: MaterialStateProperty.all<TextStyle>(textStyle),
                      mouseCursor: cursor,
                      child: const Text('Example'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.byKey(popupButtonKey));
      await tester.pumpAndSettle();

      /// The last Material widget under popupButtonApp is the [PopupMenuButton]
      /// specified above, so by finding the last descendent of popupButtonApp
      /// that is of type Material, this code retrieves the built
      /// [PopupMenuButton].
      final Material button = tester.widget<Material>(
        find.descendant(
          of: find.byKey(popupButtonApp),
          matching: find.byType(Material),
        ).last,
      );
      expect(button.color, color);
      expect(button.shape, shape);
      expect(button.elevation, elevation);
      expect(button.shadowColor, shadowColor);
      expect(button.surfaceTintColor, surfaceTintColor);

      /// The last DefaultTextStyle widget under popupItemKey is the
      /// [PopupMenuItem] specified above, so by finding the last descendent of
      /// popupItemKey that is of type DefaultTextStyle, this code retrieves the
      /// built [PopupMenuItem].
      final DefaultTextStyle text = tester.widget<DefaultTextStyle>(
        find.descendant(
          of: find.byKey(popupItemKey),
          matching: find.byType(DefaultTextStyle),
        ).last,
      );
      expect(text.style, textStyle);

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byKey(popupItemKey)));
      await tester.pumpAndSettle();
      expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), cursor);
    });
  });
}

Set<MaterialState> enabled = <MaterialState>{};
Set<MaterialState> disabled = <MaterialState>{MaterialState.disabled};
