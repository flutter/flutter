// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('SkwasmRenderer rasterizer', () {
    late SkwasmRenderer testRenderer;

    setUp(() {
      testRenderer = SkwasmRenderer();
      debugOverrideJsConfiguration(null);
    });

    test('defaults to OffscreenCanvasRasterizer', () {
      testRenderer.debugResetRasterizer();

      expect(testRenderer.rasterizer, isA<OffscreenCanvasRasterizer>());
    });

    test('can be configured to use MultiSurfaceRasterizer when the canvas can stay on the raster thread', () {
      debugOverrideJsConfiguration(
        <String, Object?>{'skwasmForceMultiSurfaceRasterizer': true}.jsify()
            as JsFlutterConfiguration?,
      );

      testRenderer.debugResetRasterizer();

      if (browserSupportsTransferControlToOffscreen || !testRenderer.isMultiThreaded) {
        expect(testRenderer.rasterizer, isA<MultiSurfaceRasterizer>());
      } else {
        expect(testRenderer.rasterizer, isA<OffscreenCanvasRasterizer>());
      }
    });

    test('uses an offscreen picture surface for PNG image export', () async {
      debugOverrideJsConfiguration(
        <String, Object?>{'skwasmForceMultiSurfaceRasterizer': true}.jsify()
            as JsFlutterConfiguration?,
      );

      final globalRenderer = renderer as SkwasmRenderer;
      globalRenderer.debugResetRasterizer();

      if (globalRenderer.rasterizer is! MultiSurfaceRasterizer) {
        return;
      }
      expect(globalRenderer.pictureToImageSurface, isA<OffscreenSurface>());

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFF00FF00), ui.BlendMode.src);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(2, 2);
      try {
        final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(data, isNotNull);
        expect(data!.lengthInBytes, greaterThan(0));
      } finally {
        image.dispose();
        picture.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('picture to image preserves rendered pixels', () async {
      final globalRenderer = renderer as SkwasmRenderer;
      for (final forceMultiSurface in <bool>[false, true]) {
        debugOverrideJsConfiguration(
          <String, Object?>{'skwasmForceMultiSurfaceRasterizer': forceMultiSurface}.jsify()
              as JsFlutterConfiguration?,
        );
        globalRenderer.debugResetRasterizer();

        if (!forceMultiSurface) {
          expect(globalRenderer.rasterizer, isA<OffscreenCanvasRasterizer>());
        } else if (browserSupportsTransferControlToOffscreen || !globalRenderer.isMultiThreaded) {
          expect(globalRenderer.rasterizer, isA<MultiSurfaceRasterizer>());
        }

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 2, 2));
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 1, 1),
          ui.Paint()..color = const ui.Color(0xFFFF0000),
        );
        canvas.drawRect(
          const ui.Rect.fromLTWH(1, 0, 1, 1),
          ui.Paint()..color = const ui.Color(0xFF00FF00),
        );
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 1, 1, 1),
          ui.Paint()..color = const ui.Color(0xFF0000FF),
        );
        canvas.drawRect(
          const ui.Rect.fromLTWH(1, 1, 1, 1),
          ui.Paint()..color = const ui.Color(0xFFFFFFFF),
        );
        final ui.Picture picture = recorder.endRecording();
        final ui.Image image = await picture.toImage(2, 2);
        try {
          final ByteData? data = await image.toByteData();
          expect(data, isNotNull);
          expect(data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), <int>[
            0xFF,
            0x00,
            0x00,
            0xFF,
            0x00,
            0xFF,
            0x00,
            0xFF,
            0x00,
            0x00,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
          ]);
          final ByteData? pngData = await image.toByteData(format: ui.ImageByteFormat.png);
          expect(pngData, isNotNull);
          final Uint8List pngBytes = pngData!.buffer.asUint8List(
            pngData.offsetInBytes,
            pngData.lengthInBytes,
          );
          expect(pngBytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);

          final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
          final ui.FrameInfo decodedFrame = await codec.getNextFrame();
          try {
            final ByteData? decodedData = await decodedFrame.image.toByteData();
            expect(decodedData, isNotNull);
            expect(
              decodedData!.buffer.asUint8List(decodedData.offsetInBytes, decodedData.lengthInBytes),
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            );
          } finally {
            decodedFrame.image.dispose();
            codec.dispose();
          }
        } finally {
          image.dispose();
          picture.dispose();
        }
      }
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
