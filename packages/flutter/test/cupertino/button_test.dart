// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

const TextStyle testStyle = const TextStyle(
  fontFamily: 'Ahem',
  fontSize: 10.0,
);

void main() {
  testWidgets('Default layout minimum size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(child: const CupertinoButton(
        child: const Text('X', style: testStyle),
        onPressed: null,
      ))
    );
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size,
      // 1 10px character + 16px * 2 is smaller than the default 44px minimum.
      const Size.square(44.0),
    );
  });

  testWidgets('Minimum size parameter', (WidgetTester tester) async {
    final double minSize = 60.0;
    await tester.pumpWidget(
      new Center(child: new CupertinoButton(
        child: const Text('X', style: testStyle),
        onPressed: null,
        minSize: minSize,
      ))
    );
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size,
      // 1 10px character + 16px * 2 is smaller than defined 60.0px minimum
      new Size.square(minSize),
    );
  });

  testWidgets('Size grows with text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(child: const CupertinoButton(
        child: const Text('XXXX', style: testStyle),
        onPressed: null,
      ))
    );
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size.width,
      // 4 10px character + 16px * 2 = 72.
      72.0,
    );
  });

  testWidgets('Button with background is wider', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: const CupertinoButton(
      child: const Text('X', style: testStyle),
      onPressed: null,
      color: const Color(0xFFFFFFFF),
    )));
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size.width,
      // 1 10px character + 64 * 2 = 138 for buttons with background.
      138.0,
    );
  });

  testWidgets('Custom padding', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: const CupertinoButton(
      child: const Text(' ', style: testStyle),
      onPressed: null,
      padding: const EdgeInsets.all(100.0),
    )));
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size,
      const Size.square(210.0),
    );
  });

  testWidgets('Button takes taps', (WidgetTester tester) async {
    bool value = false;
    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Center(
            child: new CupertinoButton(
              child: const Text('Tap me'),
              onPressed: () {
                setState(() {
                  value = true;
                });
              },
            ),
          );
        },
      ),
    );

    expect(value, isFalse);
    // No animating by default.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
    await tester.tap(find.byType(CupertinoButton));
    expect(value, isTrue);
    // Animates.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));
  });

  testWidgets('Disabled button doesn\'t animate', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: const CupertinoButton(
      child: const Text('Tap me'),
      onPressed: null,
    )));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
    await tester.tap(find.byType(CupertinoButton));
    // Still doesn't animate.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('pressedOpacity defaults to 0.1', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(child: new CupertinoButton(
      child: const Text('Tap me'),
      onPressed: () { },
    )));

    // Keep a "down" gesture on the button
    final Offset center = tester.getCenter(find.byType(CupertinoButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Check opacity
    final Opacity opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoButton),
      matching: find.byType(Opacity),
    ));
    expect(opacity.opacity, 0.1);
  });

  testWidgets('pressedOpacity parameter', (WidgetTester tester) async {
    final double pressedOpacity = 0.5;
    await tester.pumpWidget(new Center(child: new CupertinoButton(
      pressedOpacity: pressedOpacity,
      child: const Text('Tap me'),
      onPressed: () { },
    )));

    // Keep a "down" gesture on the button
    final Offset center = tester.getCenter(find.byType(CupertinoButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Check opacity
    final Opacity opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoButton),
      matching: find.byType(Opacity),
    ));
    expect(opacity.opacity, pressedOpacity);
  });
}
