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
  });
}
