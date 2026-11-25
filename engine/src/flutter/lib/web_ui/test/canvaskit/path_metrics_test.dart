// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

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
      expect(metric.length, 40);

      // Extract the top-right corner: (15, 10) -> (20, 10) -> (20, 15).
      final ui.Path extracted = metric.extractPath(5, 15);
      expect(segments, isEmpty, reason: 'EnginePath.extracted is lazy until materialized.');

      final ui.Rect bounds = extracted.getBounds();
      expect(segments, isNotEmpty);

      expect(bounds, const ui.Rect.fromLTRB(15, 10, 20, 15));
      expect(extracted.fillType, ui.PathFillType.evenOdd);
      final List<ui.PathMetric> extractedMetrics = extracted.computeMetrics().toList();
      expect(extractedMetrics, hasLength(1));
      expect(extractedMetrics.single.length, 10);
      expect(extractedMetrics.single.isClosed, isFalse);

      for (final segment in segments) {
        expect(
          _isDeleted(segment),
          isTrue,
          reason: 'Temporary SkPath returned by ContourMeasure.getSegment must be deleted.',
        );
      }
    });

    test('repeated extractPath calls over varied ranges delete every temporary SkPath', () {
      final List<JSObject> segments = _spyOnGetSegment();

      final path = ui.Path()
        ..moveTo(0, 0)
        ..lineTo(600, 0)
        ..lineTo(600, 400);
      final ui.PathMetric metric = path.computeMetrics().single;
      expect(metric.length, 1000);

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
        expect(
          _isDeleted(segments[i]),
          isTrue,
          reason: 'Segment $i returned by ContourMeasure.getSegment was not deleted.',
        );
      }
    });

    test('extractPath handles boundary, degenerate, and unmoved ranges without leaking SkPath', () {
      final List<JSObject> segments = _spyOnGetSegment();

      final path = ui.Path()
        ..moveTo(10, 20)
        ..lineTo(110, 20);
      final ui.PathMetric metric = path.computeMetrics().single;
      expect(metric.length, 100);

      final cases = <(double, double, bool, ui.Rect)>[
        (40, 40, true, const ui.Rect.fromLTRB(50, 20, 50, 20)),
        (70, 30, true, ui.Rect.zero),
        (double.nan, 50, true, ui.Rect.zero),
        (-25, 150, true, const ui.Rect.fromLTRB(10, 20, 110, 20)),
        (120, 140, true, ui.Rect.zero),
        (25, 75, false, const ui.Rect.fromLTRB(0, 0, 85, 20)),
      ];

      for (final (double start, double end, bool startWithMoveTo, ui.Rect expectedBounds)
          in cases) {
        final ui.Path extracted = metric.extractPath(start, end, startWithMoveTo: startWithMoveTo);
        expect(extracted.getBounds(), expectedBounds);
      }

      expect(segments, hasLength(cases.length));
      for (var i = 0; i < segments.length; i++) {
        expect(_isDeleted(segments[i]), isTrue, reason: 'Case $i leaked temporary SkPath.');
      }
    });

    test('extractPath deletes temporary SkPath when SkPathBuilder throws', () {
      final List<JSObject> segments = _spyOnGetSegment();
      final canvasKit = globalContext['flutterCanvasKit']! as JSObject;
      final JSAny originalPathBuilder = canvasKit['PathBuilder']!;
      addTearDown(() {
        canvasKit['PathBuilder'] = originalPathBuilder;
      });

      final path = ui.Path()..lineTo(20, 0);
      final ui.Path extracted = path.computeMetrics().single.extractPath(2, 12);
      expect(segments, isEmpty);

      canvasKit['PathBuilder'] = ((JSAny? _) {
        throw StateError('Simulated PathBuilder failure');
      }).toJS;
      try {
        expect(extracted.getBounds, throwsA(anything));
      } finally {
        canvasKit['PathBuilder'] = originalPathBuilder;
      }

      expect(segments, hasLength(1));
      expect(_isDeleted(segments.single), isTrue);
    });

    test('extractPath segments survive Path.combine and Canvas rasterization', () async {
      final List<JSObject> segments = _spyOnGetSegment();

      final multiContour = ui.Path()
        ..addRect(const ui.Rect.fromLTRB(0, 0, 20, 20))
        ..addRect(const ui.Rect.fromLTRB(10, 0, 30, 20));
      final List<ui.PathMetric> metrics = multiContour.computeMetrics().toList();
      expect(metrics, hasLength(2));

      final ui.Path leftSegment = metrics[0].extractPath(0, metrics[0].length);
      final ui.Path rightSegment = metrics[1].extractPath(0, metrics[1].length);
      final ui.Path overlap = ui.Path.combine(
        ui.PathOperation.intersect,
        leftSegment,
        rightSegment,
      );
      expect(segments, isEmpty);
      expect(overlap.getBounds(), const ui.Rect.fromLTRB(10, 0, 20, 20));
      expect(segments, hasLength(2));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      // Draw `leftSegment` twice to materialize it once and verify cached `CkPath` reuse.
      canvas.drawPath(leftSegment, ui.Paint()..color = const ui.Color(0xFF00FF00));
      canvas.drawPath(leftSegment, ui.Paint()..color = const ui.Color(0xFF0000FF));
      canvas.drawPath(overlap, ui.Paint()..color = const ui.Color(0xFFFF0000));

      final ui.Picture picture = recorder.endRecording();
      addTearDown(picture.dispose);
      final ui.Image image = picture.toImageSync(30, 20);
      addTearDown(image.dispose);
      final ByteData bytes = (await image.toByteData())!;

      // RGBA big-endian: (5, 10) is leftSegment-only (blue), (15, 10) is
      // overlap (red), and (25, 10) is empty.
      expect(bytes.getUint32((10 * 30 + 5) * 4), 0x0000FFFF);
      expect(bytes.getUint32((10 * 30 + 15) * 4), 0xFF0000FF);
      expect(bytes.getUint32((10 * 30 + 25) * 4), 0x00000000);

      expect(segments, hasLength(3));
      for (var i = 0; i < segments.length; i++) {
        expect(_isDeleted(segments[i]), isTrue, reason: 'Segment $i leaked.');
      }
    });
  });
}
