// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CkPath', () {
    setUpAll(() async {
      debugResetBrowserSupportsFinalizationRegistry();
      await ui.webOnlyInitializePlatform();
    });

    tearDown(() {
      debugResetBrowserSupportsFinalizationRegistry();
    });

    test('Using CanvasKit', () {
      expect(useCanvasKit, true);
    });

    test(CkPathMetrics, () {
      final ui.Path path = ui.Path();
      expect(path, isA<CkPath>());
      expect(path.computeMetrics().length, 0);

      path.addRect(ui.Rect.fromLTRB(0, 0, 10, 10));
      final ui.PathMetric metric = path.computeMetrics().single;
      expect(metric.contourIndex, 0);
      expect(metric.extractPath(0, 0.5).computeMetrics().length, 1);

      final ui.Tangent tangent1 = metric.getTangentForOffset(5);
      expect(tangent1.position, ui.Offset(5, 0));
      expect(tangent1.vector, ui.Offset(1, 0));

      final ui.Tangent tangent2 = metric.getTangentForOffset(15);
      expect(tangent2.position, ui.Offset(10, 5));
      expect(tangent2.vector, ui.Offset(0, 1));

      expect(metric.isClosed, true);

      path.addOval(ui.Rect.fromLTRB(10, 10, 100, 100));
      expect(path.computeMetrics().length, 2);

      // Path metrics can be iterated over multiple times.
      final ui.PathMetrics metrics = path.computeMetrics();
      expect(metrics.toList().length, 2);
      expect(metrics.toList().length, 2);
      expect(metrics.toList().length, 2);

      // Can simultaneously iterate over multiple metrics from the same path.
      final ui.PathMetrics metrics1 = path.computeMetrics();
      final ui.PathMetrics metrics2 = path.computeMetrics();
      final Iterator<ui.PathMetric> iter1 = metrics1.iterator;
      final Iterator<ui.PathMetric> iter2 = metrics2.iterator;
      expect(iter1.moveNext(), true);
      expect(iter2.moveNext(), true);
      expect(iter1.current, isNotNull);
      expect(iter2.current, isNotNull);
      expect(iter1.moveNext(), true);
      expect(iter2.moveNext(), true);
      expect(iter1.current, isNotNull);
      expect(iter2.current, isNotNull);
      expect(iter1.moveNext(), false);
      expect(iter2.moveNext(), false);
      expect(() => iter1.current, throwsRangeError);
      expect(() => iter2.current, throwsRangeError);
    });

    test('CkPath.reset', () {
      final ui.Path path = ui.Path();
      expect(path, isA<CkPath>());
      path.addRect(const ui.Rect.fromLTRB(0, 0, 10, 10));
      expect(path.contains(const ui.Offset(5, 5)), isTrue);

      expect(path.fillType, ui.PathFillType.nonZero);
      path.fillType = ui.PathFillType.evenOdd;
      expect(path.fillType, ui.PathFillType.evenOdd);

      path.reset();
      expect(path.fillType, ui.PathFillType.nonZero);
      expect(path.contains(const ui.Offset(5, 5)), isFalse);
    });

    test('CkPath resurrection', () {
      const ui.Rect rect = ui.Rect.fromLTRB(0, 0, 10, 10);
      final CkPath path = CkPath();
      path.addRect(rect);
      path.delete();

      final SkPath resurrectedCopy = path.resurrect();
      expect(fromSkRect(resurrectedCopy.getBounds()), rect);
    });

    test('Resurrect CkContourMeasure in the middle of iteration', () {
      browserSupportsFinalizationRegistry = false;
      final ui.Path path = ui.Path();
      expect(path, isA<CkPath>());
      path.addRect(ui.Rect.fromLTRB(0, 0, 10, 10));
      path.addRect(ui.Rect.fromLTRB(20, 20, 30, 30));
      path.addRect(ui.Rect.fromLTRB(40, 40, 50, 50));

      final ui.PathMetrics metrics = path.computeMetrics();
      final CkContourMeasureIter iterator = metrics.iterator;

      expect(iterator.moveNext(), true);
      expect(iterator.current.contourIndex, 0);
      expect(iterator.moveNext(), true);
      expect(iterator.current.contourIndex, 1);

      // Delete iterator in the middle of iteration
      iterator.delete();
      iterator.rawSkiaObject = null;

      // Check that the iterator can continue from the last position.
      expect(iterator.moveNext(), true);
      expect(iterator.current.contourIndex, 2);
      expect(iterator.moveNext(), false);
    });

    test('Resurrect CkContourMeasure', () {
      browserSupportsFinalizationRegistry = false;
      final ui.Path path = ui.Path();
      expect(path, isA<CkPath>());
      path.addRect(ui.Rect.fromLTRB(0, 0, 10, 10));
      path.addRect(ui.Rect.fromLTRB(20, 20, 30, 30));
      path.addRect(ui.Rect.fromLTRB(40, 40, 50, 50));

      final ui.PathMetrics metrics = path.computeMetrics();
      final CkContourMeasureIter iterator = metrics.iterator;

      expect(iterator.moveNext(), true);
      final CkContourMeasure measure0 = iterator.current;
      expect(measure0.contourIndex, 0);
      expect(measure0.extractPath(0, 15).getBounds(), ui.Rect.fromLTRB(0, 0, 10, 5));

      expect(iterator.moveNext(), true);
      final CkContourMeasure measure1 = iterator.current;
      expect(measure1.contourIndex, 1);
      expect(measure1.extractPath(0, 15).getBounds(), ui.Rect.fromLTRB(20, 20, 30, 25));

      // Delete iterator and the measure in the middle of iteration
      iterator.delete();
      iterator.rawSkiaObject = null;
      measure0.delete();
      measure0.rawSkiaObject = null;
      measure1.delete();
      measure1.rawSkiaObject = null;

      // Check that the measure is still value after resurrection.
      expect(measure0.contourIndex, 0);
      expect(measure0.extractPath(0, 15).getBounds(), ui.Rect.fromLTRB(0, 0, 10, 5));
      expect(measure1.contourIndex, 1);
      expect(measure1.extractPath(0, 15).getBounds(), ui.Rect.fromLTRB(20, 20, 30, 25));
    });
  },
      skip:
          isIosSafari); // TODO: https://github.com/flutter/flutter/issues/60040
}
