// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';

const int _kNumOfRenderObjects = 100;
const int _kNumWarmUp = 1000;
const int _kTestIterations = 100000;

// Measures the time it takes to compute paint transforms between render objects.
Future<void> main() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");
  final Stopwatch watch = Stopwatch();
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  final Widget widget = Directionality(
    textDirection: TextDirection.ltr,
    child: Transform.scale(
      scaleX: 2.0,
      scaleY: 3.0,
      child: const _WidgetWithManyRenderObjects(
        numOfRenderObjects: _kNumOfRenderObjects,
        child: SizedBox(),
      ),
    ),
  );

  final Widget manyHeadedWidget = Directionality(
    textDirection: TextDirection.ltr,
    child: Transform.scale(
      scaleX: 2.0,
      scaleY: 3.0,
      child: const _ManyHeadedWidget(
        numOfLevels: _kNumOfRenderObjects,
        child: SizedBox(),
      ),
    ),
  );

  await benchmarkWidgets((WidgetTester tester) async {
    await tester.pumpWidget(widget);
    final RenderObject fromRenderObject = tester.renderObject(find.byType(SizedBox));
    final RenderObject toRenderObject = tester.renderObject(find.byType(Transform));

    for (int i = 0; i < _kNumWarmUp; i += 1) {
      fromRenderObject.getTransformTo(toRenderObject);
    }
    watch.start();
    for (int i = 0; i < _kTestIterations; i += 1) {
      fromRenderObject.getTransformTo(toRenderObject);
    }
    watch.stop();
  });

  printer.addResult(
    description: 'RenderObject.getTransformTo() for $_kNumOfRenderObjects render objects',
    value: watch.elapsedMicroseconds.toDouble() / _kTestIterations,
    unit: 'μs per iteration',
    name: 'Simple_RenderObject_getTransformTo_iteration',
  );

  watch.reset();
  await benchmarkWidgets((WidgetTester tester) async {
    await tester.pumpWidget(widget);
    final RenderObject fromRenderObject = tester.renderObject(find.byType(SizedBox));

    for (int i = 0; i < _kNumWarmUp; i += 1) {
      fromRenderObject.getTransformTo(null);
    }
    watch.start();
    for (int i = 0; i < _kTestIterations; i += 1) {
      fromRenderObject.getTransformTo(null);
    }
    watch.stop();
  });

  printer.addResult(
    description: 'RenderObject.getTransformTo(null) for $_kNumOfRenderObjects render objects',
    value: watch.elapsedMicroseconds.toDouble() / _kTestIterations,
    unit: 'μs per iteration',
    name: 'Simple_RenderObject_getTransformTo_null_iteration',
  );

  watch.reset();
  await benchmarkWidgets((WidgetTester tester) async {
    await tester.pumpWidget(manyHeadedWidget);
    final RenderObject fromRenderObject = tester.renderObjectList(find.byType(SizedBox)).first;
    final RenderObject toRenderObject = tester.renderObjectList(find.byType(SizedBox)).last;

    for (int i = 0; i < _kNumWarmUp; i += 1) {
      fromRenderObject.computeTransformToRenderObject(toRenderObject);
    }
    watch.start();
    for (int i = 0; i < _kTestIterations; i += 1) {
      fromRenderObject.computeTransformToRenderObject(toRenderObject);
    }
    watch.stop();
  });

  printer.addResult(
    description: 'RenderObject.computeTransformToRenderObject for $_kNumOfRenderObjects levels',
    value: watch.elapsedMicroseconds.toDouble() / _kTestIterations,
    unit: 'μs per iteration',
    name: 'Simple_RenderObject_computeTransformToRenderObject_iteration',
  );

  printer.printToStdout();
}

final class _WidgetWithManyRenderObjects extends StatelessWidget {
  const _WidgetWithManyRenderObjects({
    required this.numOfRenderObjects,
    required this.child,
  });

  final int numOfRenderObjects;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets padding = EdgeInsets.all(8);
    return numOfRenderObjects > 1
      ? Padding(padding: padding, child: _WidgetWithManyRenderObjects(numOfRenderObjects: numOfRenderObjects - 1, child: child))
      : child;
  }
}

final class _ManyHeadedWidget extends StatelessWidget {
  const _ManyHeadedWidget({
    required this.numOfLevels,
    required this.child,
  });

  final int numOfLevels;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets padding = EdgeInsets.all(1);
    return numOfLevels > 1
      ? Column(
        children: <Widget>[
          Padding(
            padding: padding,
            child: _WidgetWithManyRenderObjects(numOfRenderObjects: numOfLevels - 1, child: child),
          ),
          Padding(
            padding: padding,
            child: _WidgetWithManyRenderObjects(numOfRenderObjects: numOfLevels - 1, child: child),
          ),
          Padding(
            padding: padding,
            child: _WidgetWithManyRenderObjects(numOfRenderObjects: numOfLevels - 1, child: child),
          ),
        ],
      )
      : child;
  }
}
