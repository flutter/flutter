// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

/// Intercepts `flutterCanvasKit.ContourMeasure.prototype.getSegment` to record
/// every WASM-heap `SkPath` returned during the current test, restoring the
/// original prototype method in [addTearDown].
List<JSObject> _spyOnGetSegment() {
  final canvasKit = globalContext['flutterCanvasKit']! as JSObject;
  final contourMeasure = canvasKit['ContourMeasure']! as JSObject;
  final prototype = contourMeasure['prototype']! as JSObject;
  final originalGetSegment = prototype['getSegment']! as JSFunction;
  final segments = <JSObject>[];

  JSObject wrappedGetSegment(
    JSObject self,
    JSNumber start,
    JSNumber end,
    JSBoolean startWithMoveTo,
  ) {
    final segment =
        originalGetSegment.callAsFunction(self, start, end, startWithMoveTo)! as JSObject;
    segments.add(segment);
    return segment;
  }

  prototype['getSegment'] = wrappedGetSegment.toJSCaptureThis;
  addTearDown(() {
    prototype['getSegment'] = originalGetSegment;
  });
  return segments;
}

/// Returns whether Emscripten's `isDeleted()` reports [skObject] as freed.
bool _isDeleted(JSObject skObject) {
  return skObject.callMethod<JSBoolean>('isDeleted'.toJS).toDart;
}

void testMain() {
  group('CkContourMeasure', () {
    setUpCanvasKitTest();

    test('extractPath deletes temporary SkPath and preserves extracted segment', () {
      final List<JSObject> segments = _spyOnGetSegment();

      final path = ui.Path()
        ..fillType = ui.PathFillType.evenOdd
        ..addRect(const ui.Rect.fromLTRB(10, 10, 20, 20));
      final ui.PathMetric metric = path.computeMetrics().single;

      // Extract the top-right corner: (15, 10) -> (20, 10) -> (20, 15).
      final ui.Path extracted = metric.extractPath(5, 15);
      expect(segments, isEmpty, reason: 'EnginePath.extracted is lazy until materialized.');

      final ui.Rect bounds = extracted.getBounds();
      expect(segments, hasLength(1));
      expect(_isDeleted(segments.single), isTrue);

      expect(bounds, const ui.Rect.fromLTRB(15, 10, 20, 15));
      expect(extracted.fillType, ui.PathFillType.evenOdd);
      final ui.PathMetric extractedMetric = extracted.computeMetrics().single;
      expect(extractedMetric.length, 10);
      expect(extractedMetric.isClosed, isFalse);
    });

    test('repeated extractPath calls over varied ranges delete every temporary SkPath', () {
      final List<JSObject> segments = _spyOnGetSegment();

      final path = ui.Path()
        ..moveTo(0, 0)
        ..lineTo(600, 0)
        ..lineTo(600, 400);
      final ui.PathMetric metric = path.computeMetrics().single;

      const dashCount = 100;
      for (var i = 0; i < dashCount; i++) {
        final double start = i * 10.0;
        final double end = start + 4.0 + (i % 5);
        final ui.Path dash = metric.extractPath(start, end);
        final ui.Rect dashBounds = dash.getBounds();
        expect(dashBounds.width + dashBounds.height, closeTo(end - start, 1e-3));
      }

      expect(segments, hasLength(dashCount));
      for (var i = 0; i < segments.length; i++) {
        expect(_isDeleted(segments[i]), isTrue, reason: 'Segment $i was not deleted.');
      }
    });
  });
}
