// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../ui/utils.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

/// Counts the SkPaints constructed through `flutterCanvasKit.Paint` while
/// installed, and how many of them have not been deleted.
extension type _SkPaintCounter._(JSObject _) implements JSObject {
  factory _SkPaintCounter.install() {
    final JSFunction install = (globalContext['Function']! as JSFunction)
        .callAsConstructor<JSFunction>(
          'canvasKit'.toJS,
          '''
          const OriginalPaint = canvasKit.Paint;
          const counter = {
            created: 0,
            live: 0,
            uninstall() {
              canvasKit.Paint = OriginalPaint;
            },
          };
          canvasKit.Paint = function() {
            const paint = new OriginalPaint();
            counter.created++;
            counter.live++;
            const originalDelete = paint.delete;
            paint.delete = function() {
              counter.live--;
              return originalDelete.call(this);
            };
            return paint;
          };
          return counter;
          '''
              .toJS,
        );
    return install.callAsFunction(null, globalContext['flutterCanvasKit'])! as _SkPaintCounter;
  }

  external int get created;
  external int get live;
  external void uninstall();
}

void testMain() {
  group('CkPaint', () {
    setUpCanvasKitTest();

    test('createBackendPaint builds an SkPaint that dispose deletes once', () {
      final paint =
          (EnginePaint()..color = const ui.Color(0xFF00FF00)).createBackendPaint() as CkPaint;
      final JSObject skPaint = paint.skiaObject;
      expect(skPaint.callMethod<JSFloat32Array>('getColor'.toJS).toDart, <double>[0, 1, 0, 1]);
      expect(skPaint.callMethod<JSBoolean>('isDeleted'.toJS).toDart, isFalse);

      paint.dispose();
      expect(skPaint.callMethod<JSBoolean>('isDeleted'.toJS).toDart, isTrue);

      // Disposing again must not delete the SkPaint a second time.
      expect(paint.dispose, returnsNormally);
    });

    test('drawing with every paint consumer deletes every SkPaint it creates', () async {
      final counter = _SkPaintCounter.install();
      addTearDown(() => counter.uninstall());

      final PaintConsumers consumers = await PaintConsumers.create();
      final ui.Picture picture = consumers.record();
      // Each paint consumer creates at least one SkPaint.
      expect(counter.created, greaterThanOrEqualTo(11));
      expect(counter.live, 0, reason: 'after recording');

      final ui.Image rendered = await picture.toImage(20, 20);
      expect(counter.live, 0, reason: 'after rendering');

      rendered.dispose();
      picture.dispose();
      consumers.dispose();
      expect(counter.live, 0, reason: 'after disposing');
    });
  });
}
