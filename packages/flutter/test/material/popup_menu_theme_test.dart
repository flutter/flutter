// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

PopupMenuThemeData _popupMenuTheme() {
  return const PopupMenuThemeData(
    color: Colors.orange,
    shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    elevation: 12.0,
    textStyle: TextStyle(color: Color(0xffffffff), textBaseline: TextBaseline.alphabetic),
    position: PopupMenuPosition.under,
  );
}

void main() {
  test('PopupMenuThemeData copyWith, ==, hashCode basics', () {
    expect(const PopupMenuThemeData(), const PopupMenuThemeData().copyWith());
    expect(const PopupMenuThemeData().hashCode, const PopupMenuThemeData().copyWith().hashCode);
  });

  test('PopupMenuThemeData null fields by default', () {
    const PopupMenuThemeData popupMenuTheme = PopupMenuThemeData();
    expect(popupMenuTheme.color, null);
    expect(popupMenuTheme.shape, null);
    expect(popupMenuTheme.elevation, null);
    expect(popupMenuTheme.textStyle, null);
    expect(popupMenuTheme.mouseCursor, null);
    expect(popupMenuTheme.position, null);
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
    const PopupMenuThemeData(
      color: Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0))),
      elevation: 2.0,
      textStyle: TextStyle(color: Color(0xffffffff)),
      mouseCursor: MaterialStateMouseCursor.clickable,
      position: PopupMenuPosition.over,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'color: Color(0xffffffff)',
      'shape: RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(2.0))',
      'elevation: 2.0',
      'text style: TextStyle(inherit: true, color: Color(0xffffffff))',
      'mouseCursor: MaterialStateMouseCursor(clickable)',
      'position: over'
    ]);
  });

  testWidgets('Passing no PopupMenuThemeData returns defaults', (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            Padding(
              // The padding makes sure the menu as enough space to around to
              // get properly aligned when displayed (`_kMenuScreenPadding`).
              padding: const EdgeInsets.all(8.0),
              child: PopupMenuButton<void>(
                key: popupButtonKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      key: popupItemKey,
                      child: const Text('Example'),
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
    final DefaultTextStyle text = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byKey(popupItemKey),
        matching: find.byType(DefaultTextStyle),
      ).last,
    );
    expect(text.style.fontFamily, 'Roboto');
    expect(text.style.color, const Color(0xdd000000));
    expect(text.style.color, const Color(0xdd000000));

    final Offset topLeftButton = tester.getTopLeft(find.byType(PopupMenuButton<void>));
    final Offset topLeftMenu = tester.getTopLeft(find.byWidget(button));
    expect(topLeftMenu, topLeftButton);
  });

  testWidgets('Popup menu uses values from PopupMenuThemeData', (WidgetTester tester) async {
    final PopupMenuThemeData popupMenuTheme = _popupMenuTheme();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

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
                    key: popupItemKey,
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
    expect(button.color, popupMenuTheme.color);
    expect(button.shape, popupMenuTheme.shape);
    expect(button.elevation, popupMenuTheme.elevation);

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
    expect(text.style, popupMenuTheme.textStyle);

    final Offset bottomLeftButton = tester.getBottomLeft(find.byType(PopupMenuButton<void>));
    final Offset topLeftMenu = tester.getTopLeft(find.byWidget(button));
    expect(topLeftMenu, bottomLeftButton);
  });

  testWidgets('Popup menu widget properties take priority over theme', (WidgetTester tester) async {
    final PopupMenuThemeData popupMenuTheme = _popupMenuTheme();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

    const Color color = Colors.purple;
    const ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
    );
    const double elevation = 7.0;
    const TextStyle textStyle = TextStyle(color: Color(0x00000000), textBaseline: TextBaseline.alphabetic);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(popupMenuTheme: popupMenuTheme),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            Padding(
              // The padding makes sure the menu as enough space to around to
              // get properly aligned when displayed (`_kMenuScreenPadding`).
              padding: const EdgeInsets.all(8.0),
              child: PopupMenuButton<void>(
                key: popupButtonKey,
                elevation: elevation,
                color: color,
                shape: shape,
                position: PopupMenuPosition.over,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      key: popupItemKey,
                      textStyle: textStyle,
                      child: const Text('Example'),
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
    expect(button.color, color);
    expect(button.shape, shape);
    expect(button.elevation, elevation);

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

    final Offset topLeftButton = tester.getTopLeft(find.byType(PopupMenuButton<void>));
    final Offset topLeftMenu = tester.getTopLeft(find.byWidget(button));
    expect(topLeftMenu, topLeftButton);
  });

  testWidgets('ThemeData.popupMenuTheme properties are utilized', (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key enabledPopupItemKey = UniqueKey();
    final Key disabledPopupItemKey = UniqueKey();

    await tester.pumpWidget(MaterialApp(
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuTheme(
              data: PopupMenuThemeData(
                color: Colors.pink,
                shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                elevation: 6.0,
                textStyle: const TextStyle(color: Color(0xfffff000), textBaseline: TextBaseline.alphabetic),
                mouseCursor: MaterialStateProperty.resolveWith<MouseCursor?>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return SystemMouseCursors.contextMenu;
                  }
                  return SystemMouseCursors.alias;
                }),
              ),
              child: PopupMenuButton<void>(
                key: popupButtonKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      key: disabledPopupItemKey,
                      enabled: false,
                      child: const Text('disabled'),
                    ),
                    PopupMenuItem<void>(
                      key: enabledPopupItemKey,
                      onTap: () { },
                      child: const Text('enabled'),
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
    expect(button.color, Colors.pink);
    expect(button.shape, const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))));
    expect(button.elevation, 6.0);

    final DefaultTextStyle text = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byKey(enabledPopupItemKey),
        matching: find.byType(DefaultTextStyle),
      ),
    );
    expect(text.style.color, const Color(0xfffff000));

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byKey(disabledPopupItemKey)));
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.contextMenu);
    await gesture.down(tester.getCenter(find.byKey(enabledPopupItemKey)));
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.alias);
  });
}
