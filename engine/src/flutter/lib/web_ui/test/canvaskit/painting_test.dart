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

    test('the SkPaint counter sees a backend paint until it is disposed', () {
      final counter = _SkPaintCounter.install();
      addTearDown(() => counter.uninstall());

      final BackendPaint paint = EnginePaint().createBackendPaint();
      expect(
        counter.created,
        1,
        reason: 'createBackendPaint constructs exactly one SkPaint through flutterCanvasKit.Paint.',
      );
      expect(
        counter.live,
        1,
        reason: 'The SkPaint stays alive until its backend paint is disposed.',
      );

      paint.dispose();
      expect(counter.live, 0, reason: 'dispose deletes the SkPaint.');

      paint.dispose();
      expect(
        counter.live,
        0,
        reason: 'A second dispose must not call delete on the SkPaint again.',
      );
      expect(counter.created, 1, reason: 'dispose never constructs an SkPaint.');
    });

    test('drawing with every paint consumer deletes every SkPaint it creates', () async {
      final counter = _SkPaintCounter.install();
      addTearDown(() => counter.uninstall());

      final PaintConsumers consumers = await PaintConsumers.create();
      // One SkPaint to draw the image, plus a foreground and a background
      // SkPaint for each of the three paragraphs.
      const consumerSetupPaintCount = 7;
      expect(
        counter.created,
        consumerSetupPaintCount,
        reason:
            'Drawing the image creates one SkPaint and each paragraph creates one for its '
            'foreground and one for its background.',
      );
      expect(
        counter.live,
        0,
        reason: 'The image draw and the paragraph builders delete their SkPaints when done.',
      );

      final int createdBeforeRecording = counter.created;
      final ui.Picture picture = consumers.record();
      expect(
        counter.created - createdBeforeRecording,
        PaintConsumers.canvasPaintDrawCount,
        reason: 'Each canvas draw call that takes a Paint creates exactly one SkPaint.',
      );
      expect(
        counter.live,
        0,
        reason: 'Each canvas draw call deletes its SkPaint before returning.',
      );

      final ui.Image rendered = await picture.toImage(20, 20);
      expect(counter.live, 0, reason: 'Rendering a picture deletes any SkPaint it creates.');

      rendered.dispose();
      picture.dispose();
      consumers.dispose();
      expect(
        counter.live,
        0,
        reason: 'Pictures, images, paragraphs and vertices never own an SkPaint.',
      );
    });
  });
}
