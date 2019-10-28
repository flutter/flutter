// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Default $MaterialButton meets a11y contrast guidelines', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MaterialButton(
              child: const Text('MaterialButton'),
              onPressed: () { },
            ),
          ),
        ),
      ),
    );

    // Default, not disabled.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Highlighted (pressed).
    final Offset center = tester.getCenter(find.byType(MaterialButton));
    await tester.startGesture(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  },
    semanticsEnabled: true,
    skip: isBrowser,
  );
  testWidgets('$MaterialButton gets focus when autofocus is set.', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'MaterialButton');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MaterialButton(
            focusNode: focusNode,
            onPressed: () {},
            child: Container(width: 100, height: 100, color: const Color(0xffff0000)),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MaterialButton(
            autofocus: true,
            focusNode: focusNode,
            onPressed: () {},
            child: Container(width: 100, height: 100, color: const Color(0xffff0000)),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets('MaterialButton onPressed and onLongPress callbacks are correctly called when non-null', (WidgetTester tester) async {

    bool wasPressed;
    Finder materialButton;

    Widget buildFrame({ VoidCallback onPressed, VoidCallback onLongPress }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(child: const Text('button'), onPressed: onPressed, onLongPress: onLongPress),
      );
    }

    // onPressed not null, onLongPress null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: () { wasPressed = true; }, onLongPress: null),
    );
    materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, true);
    await tester.tap(materialButton);
    await tester.pumpAndSettle();
    expect(wasPressed, true);

    // onPressed null, onLongPress not null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: () { wasPressed = true; }),
    );
    materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, true);
    await tester.longPress(materialButton);
    await tester.pumpAndSettle();
    expect(wasPressed, true);

    // onPressed null, onLongPress null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: null),
    );
    materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, false);
    await tester.tap(materialButton);
    await tester.longPress(materialButton);
    await tester.pumpAndSettle();
    expect(wasPressed, false);
  });

  testWidgets('MaterialButton onPressed and onLongPress callbacks are distinctly recognized', (WidgetTester tester) async {
    bool didPressButton = false;
    bool didLongPressButton = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          onPressed: () {
            didPressButton = true;
          },
          onLongPress: () {
            didLongPressButton = true;
          },
          child: const Text('button'),
        ),
      ),
    );

    final Finder materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, true);

    expect(didPressButton, isFalse);
    await tester.tap(materialButton);
    expect(didPressButton, isTrue);

    expect(didLongPressButton, isFalse);
    await tester.longPress(materialButton);
    expect(didLongPressButton, isTrue);
  });
}
