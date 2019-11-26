// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

Widget _buildBoilerplate({
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
  Widget child,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: MediaQueryData(padding: padding),
      child: child,
    ),
  );
}

void main() {
  testWidgets('Scrollbar doesn\'t show when tapping list', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildBoilerplate(
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
      ),
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
      _buildBoilerplate(child: Container(
        height: 200.0,
        width: 300.0,
        child: Scrollbar(
          child: ListView(
            children: <Widget>[
              Container(height: 40.0, child: const Text('0')),
            ],
          ),
        ),
      )),
    );

    final CustomPaint custom = tester.widget(find.descendant(
      of: find.byType(Scrollbar),
      matching: find.byType(CustomPaint),
    ).first);
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
      axisDirection: AxisDirection.down,
    );
    scrollPainter.update(metrics, AxisDirection.down);

    final List<Invocation> invocations = <Invocation>[];
    final TestCanvas canvas = TestCanvas(invocations);
    scrollPainter.paint(canvas, const Size(10.0, 100.0));

    // Scrollbar is not supposed to draw anything if there isn't enough content.
    expect(invocations.isEmpty, isTrue);
  });

  testWidgets('Adaptive scrollbar', (WidgetTester tester) async {
    Widget viewWithScroll(TargetPlatform platform) {
      return _buildBoilerplate(
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
    expect(find.byType(CupertinoScrollbar), paints..rrect());
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(viewWithScroll(TargetPlatform.macOS));
    await gesture.down(
      tester.getCenter(find.byType(SingleChildScrollView)),
    );
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Scrollbar), paints..rrect());
    expect(find.byType(CupertinoScrollbar), paints..rrect());
  });

  testWidgets('Scrollbar passes controller to CupertinoScrollbar', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll(TargetPlatform platform) {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(
            platform: platform
          ),
          child: Scrollbar(
            controller: controller,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll(debugDefaultTargetPlatformOverride));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SingleChildScrollView))
    );
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CupertinoScrollbar), paints..rrect());
    final CupertinoScrollbar scrollbar = find.byType(CupertinoScrollbar).evaluate().first.widget as CupertinoScrollbar;
    expect(scrollbar.controller, isNotNull);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

}
