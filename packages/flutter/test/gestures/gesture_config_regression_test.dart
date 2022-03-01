// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class TestResult {
  bool dragStarted = false;
  bool dragUpdate = false;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.testResult}) : super(key: key);

  final TestResult testResult;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

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

void main() {
  testWidgets('Scroll Views get the same ScrollConfiguration as GestureDetectors', (WidgetTester tester) async {
    tester.binding.window.viewConfigurationTestValue = const ui.ViewConfiguration(
      gestureSettings: ui.GestureSettings(physicalTouchSlop: 4),
    );
    final TestResult result = TestResult();

    await tester.pumpWidget(MaterialApp(
      title: 'Scroll Bug',
      home: MyHomePage(testResult: result),
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
