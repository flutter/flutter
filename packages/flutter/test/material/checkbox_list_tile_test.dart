// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
}
