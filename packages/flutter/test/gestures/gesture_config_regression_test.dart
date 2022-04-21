// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestResult {
  bool dragStarted = false;
  bool dragUpdate = false;
}

class NestedScrollableCase extends StatefulWidget {
  const NestedScrollableCase({super.key, required this.testResult});

  final TestResult testResult;

  @override
  State<NestedScrollableCase> createState() => _NestedScrollableCaseState();
}

class _NestedScrollableCaseState extends State<NestedScrollableCase> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFixedExtentList(
            itemExtent: 50.0,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragDown: (DragDownDetails details) {
                      widget.testResult.dragStarted = true;
                    },
                    onVerticalDragUpdate: (DragUpdateDetails details){
                      widget.testResult.dragUpdate = true;
                    },
                    onVerticalDragEnd: (_) {},
                    child: Text('List Item $index', key: ValueKey<int>(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NestedDragableCase extends StatefulWidget {
  const NestedDragableCase({super.key, required this.testResult});

  final TestResult testResult;

  @override
  State<NestedDragableCase> createState() => _NestedDragableCaseState();
}

class _NestedDragableCaseState extends State<NestedDragableCase> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFixedExtentList(
            itemExtent: 50.0,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  alignment: Alignment.center,
                  child: Draggable<Object>(
                    key: ValueKey<int>(index),
                    feedback: const Text('Dragging'),
                    child: Text('List Item $index'),
                    onDragStarted: () {
                      widget.testResult.dragStarted = true;
                    },
                    onDragUpdate: (DragUpdateDetails details){
                      widget.testResult.dragUpdate = true;
                    },
                    onDragEnd: (_) {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('Scroll Views get the same ScrollConfiguration as GestureDetectors', (WidgetTester tester) async {
    tester.binding.window.viewConfigurationTestValue = const ui.ViewConfiguration(
      gestureSettings: ui.GestureSettings(physicalTouchSlop: 4),
    );
    final TestResult result = TestResult();

    await tester.pumpWidget(MaterialApp(
      title: 'Scroll Bug',
      home: NestedScrollableCase(testResult: result),
    ));

    // By dragging the scroll view more than the configured touch slop above but less than
    // the framework default value, we demonstrate that this causes gesture detectors
    // that do not receive the same gesture settings to fire at different times than would
    // be expected.
    final Offset start = tester.getCenter(find.byKey(const ValueKey<int>(1)));
    await tester.timedDragFrom(start, const Offset(0, 5), const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

   expect(result.dragStarted, true);
   expect(result.dragUpdate, true);
  });

  testWidgets('Scroll Views get the same ScrollConfiguration as Draggables', (WidgetTester tester) async {
    tester.binding.window.viewConfigurationTestValue = const ui.ViewConfiguration(
      gestureSettings: ui.GestureSettings(physicalTouchSlop: 4),
    );
    final TestResult result = TestResult();

    await tester.pumpWidget(MaterialApp(
      title: 'Scroll Bug',
      home: NestedDragableCase(testResult: result),
    ));

    // By dragging the scroll view more than the configured touch slop above but less than
    // the framework default value, we demonstrate that this causes gesture detectors
    // that do not receive the same gesture settings to fire at different times than would
    // be expected.
    final Offset start = tester.getCenter(find.byKey(const ValueKey<int>(1)));
    await tester.timedDragFrom(start, const Offset(0, 5), const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

   expect(result.dragStarted, true);
   expect(result.dragUpdate, true);
  });
}
