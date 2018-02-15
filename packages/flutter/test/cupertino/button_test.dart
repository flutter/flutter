// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlag;

import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

const TextStyle testStyle = const TextStyle(
  fontFamily: 'Ahem',
  fontSize: 10.0,
);

void main() {
  testWidgets('Default layout minimum size', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(child: const CupertinoButton(
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
    const double minSize = 60.0;
    await tester.pumpWidget(
      boilerplate(child: const CupertinoButton(
        child: const Text('X', style: testStyle),
        onPressed: null,
        minSize: minSize,
      ))
    );
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size,
      // 1 10px character + 16px * 2 is smaller than defined 60.0px minimum
      const Size.square(minSize),
    );
  });

  testWidgets('Size grows with text', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(child: const CupertinoButton(
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
    await tester.pumpWidget(boilerplate(child: const CupertinoButton(
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
    await tester.pumpWidget(boilerplate(child: const CupertinoButton(
      child: const Text('X', style: testStyle),
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
          return boilerplate(
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
    await tester.pumpWidget(boilerplate(child: const CupertinoButton(
      child: const Text('Tap me'),
      onPressed: null,
    )));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
    await tester.tap(find.byType(CupertinoButton));
    // Still doesn't animate.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('pressedOpacity defaults to 0.1', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(child: new CupertinoButton(
      child: const Text('Tap me'),
      onPressed: () { },
    )));

    // Keep a "down" gesture on the button
    final Offset center = tester.getCenter(find.byType(CupertinoButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Check opacity
    final FadeTransition opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoButton),
      matching: find.byType(FadeTransition),
    ));
    expect(opacity.opacity.value, 0.1);
  });

  testWidgets('pressedOpacity parameter', (WidgetTester tester) async {
    const double pressedOpacity = 0.5;
    await tester.pumpWidget(boilerplate(child: new CupertinoButton(
      pressedOpacity: pressedOpacity,
      child: const Text('Tap me'),
      onPressed: () { },
    )));

    // Keep a "down" gesture on the button
    final Offset center = tester.getCenter(find.byType(CupertinoButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Check opacity
    final FadeTransition opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoButton),
      matching: find.byType(FadeTransition),
    ));
    expect(opacity.opacity.value, pressedOpacity);
  });

  testWidgets('Cupertino button is semantically a button', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      boilerplate(
          child: new Center(
            child: new CupertinoButton(
              onPressed: () { },
              child: const Text('ABC')
            ),
          ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            actions: SemanticsAction.tap.index,
            label: 'ABC',
            flags: SemanticsFlag.isButton.index,
          )
        ],
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });
}

Widget boilerplate({ Widget child }) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: new Center(child: child),
  );
}
