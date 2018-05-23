// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('FlatButton implements debugFillDescription', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = new DiagnosticPropertiesBuilder();
    new FlatButton(
        onPressed: () {},
        textColor: const Color(0xFF00FF00),
        disabledTextColor: const Color(0xFFFF0000),
        color: const Color(0xFF000000),
        highlightColor: const Color(0xFF1565C0),
        splashColor: const Color(0xFF9E9E9E),
        child: const Text('Hello'),
    ).debugFillProperties(builder);
    final List<String> description = builder.properties
        .where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode n) => n.toString()).toList();
    expect(description, <String>[
      'textColor: Color(0xff00ff00)',
      'disabledTextColor: Color(0xffff0000)',
      'color: Color(0xff000000)',
      'highlightColor: Color(0xff1565c0)',
      'splashColor: Color(0xff9e9e9e)',
    ]);
  });

  testWidgets('FlatButton adapts to CupertinoButton on iOS', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      new Material(
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Theme(
            data: new ThemeData(
              adaptiveWidgetTheme: AdaptiveWidgetThemeData.bundled,
              platform: TargetPlatform.iOS,
            ),
            child: new FlatButton(
              onPressed: () => tapped = true,
              child: const Text('an apple'),
            ),
          ),
        ),
      ),
    );

    expect(find.widgetWithText(CupertinoButton, 'an apple'), findsOneWidget);
    expect(tapped, false);

    await tester.tap(find.text('an apple'));

    expect(tapped, true);
  });

  testWidgets('do not adapt on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Theme(
            data: new ThemeData(
              adaptiveWidgetTheme: AdaptiveWidgetThemeData.bundled,
              platform: TargetPlatform.android,
            ),
            child: new FlatButton(
              onPressed: () {},
              child: const Text('not an apple'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoButton), findsNothing);
  });
}
