// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.pumpWidget(
      new Center(
        child: new Container(
          decoration: new BoxDecoration(
            border: new Border.all(color: const Color(0xFFFFFF00))
          ),
          height: 200.0,
          width: 300.0,
          child: new Scrollbar(
            child: new ListView(
              children: <Widget>[
                new Container(height: 40.0, child: const Text('0')),
                new Container(height: 40.0, child: const Text('1')),
                new Container(height: 40.0, child: const Text('2')),
                new Container(height: 40.0, child: const Text('3')),
                new Container(height: 40.0, child: const Text('4')),
                new Container(height: 40.0, child: const Text('5')),
                new Container(height: 40.0, child: const Text('6')),
                new Container(height: 40.0, child: const Text('7')),
              ]
            )
          )
        )
      )
    );

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
    await tester.pumpWidget(
      new Container(
        height: 200.0,
        width: 300.0,
        child: new Scrollbar(
          child: new ListView(
            children: <Widget>[
              new Container(height: 40.0, child: const Text('0')),
            ]
          )
        )
      )
    );

    final CustomPaint custom = tester.widget(find.descendant(of: find.byType(Scrollbar), matching: find.byType(CustomPaint)).first);
    final dynamic scrollPainter = custom.foregroundPainter;
    final ScrollMetrics metrics = new FixedScrollMetrics(
      minScrollExtent: 0.0,
      maxScrollExtent: 0.0,
      pixels: 0.0,
      viewportDimension: 100.0,
      axisDirection: AxisDirection.down
    );
    scrollPainter.update(metrics, AxisDirection.down);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    final List<Invocation> invocations = <Invocation>[];
    final TestCanvas canvas = new TestCanvas(invocations);
    scrollPainter.paint(canvas, const Size(10.0, 100.0));
    final Rect thumbRect = invocations.single.positionalArguments[0];
    expect(thumbRect.isFinite, isTrue);
  });
}
