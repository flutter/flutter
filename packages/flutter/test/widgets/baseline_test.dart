// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Baseline - control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Ahem',
            fontSize: 100.0,
          ),
          child: Text('X', textDirection: TextDirection.ltr),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('X')).size, const Size(100.0, 100.0));
  });

  testWidgets('Baseline - position test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: Baseline(
          baseline: 180.0,
          baselineType: TextBaseline.alphabetic,
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'Ahem',
              fontSize: 100.0,
            ),
            child: Text('X', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('X')).size, const Size(100.0, 100.0));
    expect(
      tester.renderObject<RenderBox>(find.byType(Baseline)).size,
      within<Size>(from: const Size(100.0, 200.0), distance: 0.001),
    );
  });

  testWidgets('Chip caches baseline', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Baseline(
            baseline: 100.0,
            baselineType: TextBaseline.alphabetic,
            child: Chip(
              label: BaselineDetector(() {
                calls += 1;
              }),
            ),
          ),
        ),
      ),
    );
    expect(calls, 1);
    await tester.pump();
    expect(calls, 1);
    tester.renderObject<RenderBaselineDetector>(find.byType(BaselineDetector)).dirty();
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('ListTile caches baseline', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Baseline(
            baseline: 100.0,
            baselineType: TextBaseline.alphabetic,
            child: ListTile(
              title: BaselineDetector(() {
                calls += 1;
              }),
            ),
          ),
        ),
      ),
    );
    expect(calls, 1);
    await tester.pump();
    expect(calls, 1);
    tester.renderObject<RenderBaselineDetector>(find.byType(BaselineDetector)).dirty();
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets("LayoutBuilder returns child's baseline", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Baseline(
            baseline: 180.0,
            baselineType: TextBaseline.alphabetic,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return BaselineDetector(() {});
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(BaselineDetector)).top, 160.0);
  });
}

class BaselineDetector extends LeafRenderObjectWidget {
  const BaselineDetector(this.callback, { super.key });

  final VoidCallback callback;

  @override
  RenderBaselineDetector createRenderObject(BuildContext context) => RenderBaselineDetector(callback);

  @override
  void updateRenderObject(BuildContext context, RenderBaselineDetector renderObject) {
    renderObject.callback = callback;
  }
}

class RenderBaselineDetector extends RenderBox {
  RenderBaselineDetector(this.callback);

  VoidCallback callback;

  @override
  bool get sizedByParent => true;

  @override
  double computeMinIntrinsicWidth(double height) => 0.0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0.0;

  @override
  double computeMinIntrinsicHeight(double width) => 0.0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0.0;

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (callback != null) {
      callback();
    }
    return 20.0;
  }

  void dirty() {
    markNeedsLayout();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.smallest;
  }

  @override
  void paint(PaintingContext context, Offset offset) { }
}
