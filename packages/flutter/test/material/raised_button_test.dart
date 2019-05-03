// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('RaisedButton implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    RaisedButton(
      onPressed: () { },
      textColor: const Color(0xFF00FF00),
      disabledTextColor: const Color(0xFFFF0000),
      color: const Color(0xFF000000),
      highlightColor: const Color(0xFF1565C0),
      splashColor: const Color(0xFF9E9E9E),
      child: const Text('Hello'),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      'textColor: Color(0xff00ff00)',
      'disabledTextColor: Color(0xffff0000)',
      'color: Color(0xff000000)',
      'highlightColor: Color(0xff1565c0)',
      'splashColor: Color(0xff9e9e9e)',
    ]);
  });

  testWidgets('Default RaisedButton meets a11y contrast guidelines', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RaisedButton(
              child: const Text('RaisedButton'),
              onPressed: () { },
            ),
          ),
        ),
      ),
    );

    // Default, not disabled.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Highlighted (pressed).
    final Offset center = tester.getCenter(find.byType(RaisedButton));
    await tester.startGesture(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  },
    semanticsEnabled: true,
  );


}
