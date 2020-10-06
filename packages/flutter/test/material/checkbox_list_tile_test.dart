// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';

Widget wrap({ Widget child }) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(child: child),
    ),
  );
}

void main() {
  testWidgets('CheckboxListTile control test', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    await tester.pumpWidget(wrap(
      child: CheckboxListTile(
        value: true,
        onChanged: (bool value) { log.add(value); },
        title: const Text('Hello'),
      ),
    ));
    await tester.tap(find.text('Hello'));
    log.add('-');
    await tester.tap(find.byType(Checkbox));
    expect(log, equals(<dynamic>[false, '-', false]));
  });

  testWidgets('CheckboxListTile checkColor test', (WidgetTester tester) async {
    Widget buildFrame(Color color) {
      return wrap(
        child: CheckboxListTile(
          value: true,
          checkColor: color,
          onChanged: (bool value) {},
        ),
      );
    }

    RenderBox getCheckboxListTileRenderer() {
      return tester.renderObject<RenderBox>(find.byType(CheckboxListTile));
    }

    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..path(color: const Color(0xFFFFFFFF))); // paints's color is 0xFFFFFFFF (default color)

    await tester.pumpWidget(buildFrame(const Color(0xFF000000)));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..path(color: const Color(0xFF000000))); // paints's color is 0xFF000000 (params)
  });

  testWidgets('CheckboxListTile activeColor test', (WidgetTester tester) async {
    Widget buildFrame(Color themeColor, Color activeColor) {
      return wrap(
        child: Theme(
          data: ThemeData(toggleableActiveColor: themeColor),
          child: CheckboxListTile(
            value: true,
            activeColor: activeColor,
            onChanged: (bool value) {},
          ),
        ),
      );
    }
    RenderBox getCheckboxListTileRenderer() {
      return tester.renderObject<RenderBox>(find.byType(CheckboxListTile));
    }

    await tester.pumpWidget(buildFrame(const Color(0xFF000000), null));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..rrect(color: const Color(0xFF000000))); // paints's color is 0xFF000000 (theme)

    await tester.pumpWidget(buildFrame(const Color(0xFF000000), const Color(0xFFFFFFFF)));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..rrect(color: const Color(0xFFFFFFFF))); // paints's color is 0xFFFFFFFF (params)
  });

  testWidgets('CheckboxListTile can autofocus unless disabled.', (WidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      wrap(
        child: CheckboxListTile(
          value: true,
          onChanged: (_) {},
          title: Text('Hello', key: childKey),
          autofocus: true,
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext, nullOk: true).hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrap(
        child: CheckboxListTile(
          value: true,
          onChanged: null,
          title: Text('Hello', key: childKey),
          autofocus: true,
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext, nullOk: true).hasPrimaryFocus, isFalse);
  });

  testWidgets('CheckboxListTile contentPadding test', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: const Center(
          child: CheckboxListTile(
            value: false,
            onChanged: null,
            title: Text('Title'),
            contentPadding: EdgeInsets.fromLTRB(10, 18, 4, 2),
          ),
        ),
      )
    );

    final Rect paddingRect = tester.getRect(find.byType(Padding));
    final Rect checkboxRect = tester.getRect(find.byType(Checkbox));
    final Rect titleRect = tester.getRect(find.text('Title'));

    final Rect tallerWidget = checkboxRect.height > titleRect.height ? checkboxRect : titleRect;

    // Check the offsets of CheckBox and title after padding is applied.
    expect(paddingRect.right, checkboxRect.right + 4);
    expect(paddingRect.left, titleRect.left - 10);

    // Calculate the remaining height from the default ListTile height.
    final double remainingHeight = 56 - tallerWidget.height;
    expect(paddingRect.top, tallerWidget.top - remainingHeight / 2 - 18);
    expect(paddingRect.bottom, tallerWidget.bottom + remainingHeight / 2 + 2);
  });

  testWidgets('CheckboxListTile tristate test', (WidgetTester tester) async {
    bool _value = false;
    bool _tristate = false;

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return wrap(
              child: CheckboxListTile(
                title: const Text('Title'),
                tristate: _tristate,
                value: _value,
                onChanged: (bool value) {
                  setState(() {
                    _value = value;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);

    // Tap the checkbox when tristate is disabled.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, false);

    // Tap the listTile when tristate is disabled.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, false);

    // Enable tristate
    _tristate = true;
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);

    // Tap the checkbox when tristate is enabled.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, null);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, false);

    // Tap the listTile when tristate is enabled.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, null);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, false);
  });
}
