// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  group('Path Metrics', () {
    setUpAll(() async {
      await ui.webOnlyInitializePlatform();
    });

    test('Using CanvasKit', () {
      expect(experimentalUseSkia, true);
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
  }, skip: isIosSafari); // TODO: https://github.com/flutter/flutter/issues/60040
}
