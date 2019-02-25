// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class TestCanvas implements Canvas {
  TestCanvas([this.invocations]);

  final List<Invocation> invocations;

  @override
  void noSuchMethod(Invocation invocation) {
    invocations?.add(invocation);
  }
}

void main() {
  testWidgets('Scrollbar doesn\'t show when tapping list', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFFF00))
          ),
          height: 200.0,
          width: 300.0,
          child: Scrollbar(
            child: ListView(
              children: <Widget>[
                Container(height: 40.0, child: const Text('0')),
                Container(height: 40.0, child: const Text('1')),
                Container(height: 40.0, child: const Text('2')),
                Container(height: 40.0, child: const Text('3')),
                Container(height: 40.0, child: const Text('4')),
                Container(height: 40.0, child: const Text('5')),
                Container(height: 40.0, child: const Text('6')),
                Container(height: 40.0, child: const Text('7')),
              ],
            ),
          ),
        ),
      ),
    ));

    SchedulerBinding.instance.debugAssertNoTransientCallbacks('Building a list with a scrollbar triggered an animation.');
    await tester.tap(find.byType(ListView));
    SchedulerBinding.instance.debugAssertNoTransientCallbacks('Tapping a block with a scrollbar triggered an animation.');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.byType(ListView), const Offset(0.0, -10.0));
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('ScrollbarPainter does not divide by zero', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 200.0,
        width: 300.0,
        child: Scrollbar(
          child: ListView(
            children: <Widget>[
              Container(height: 40.0, child: const Text('0')),
            ],
          ),
        ),
      ),
    ));

    final CustomPaint custom = tester.widget(find.descendant(
      of: find.byType(Scrollbar),
      matching: find.byType(CustomPaint)).first
    );
    final dynamic scrollPainter = custom.foregroundPainter;
    // Dragging makes the scrollbar first appear.
    await tester.drag(find.text('0'), const Offset(0.0, -10.0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    final ScrollMetrics metrics = FixedScrollMetrics(
      minScrollExtent: 0.0,
      maxScrollExtent: 0.0,
      pixels: 0.0,
      viewportDimension: 100.0,
      axisDirection: AxisDirection.down
    );
    scrollPainter.update(metrics, AxisDirection.down);

    final List<Invocation> invocations = <Invocation>[];
    final TestCanvas canvas = TestCanvas(invocations);
    scrollPainter.paint(canvas, const Size(10.0, 100.0));
    final Rect thumbRect = invocations.single.positionalArguments[0];
    expect(thumbRect.isFinite, isTrue);
  });

  testWidgets('Adaptive scrollbar', (WidgetTester tester) async {
    Widget viewWithScroll(TargetPlatform platform) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            platform: platform
          ),
          child: const Scrollbar(
            child: SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll(TargetPlatform.android));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Scrollbar), paints..rect());

    await tester.pumpWidget(viewWithScroll(TargetPlatform.iOS));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SingleChildScrollView))
    );
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Scrollbar), paints..rrect());
  });
}
