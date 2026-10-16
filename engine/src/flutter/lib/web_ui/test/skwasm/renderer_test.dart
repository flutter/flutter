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
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('SkwasmRenderer rasterizer', () {
    late SkwasmRenderer testRenderer;

    setUp(() {
      debugOverrideJsConfiguration(null);
      testRenderer = SkwasmRenderer()..debugResetRasterizer();
    });

    tearDown(() {
      testRenderer.rasterizer.dispose();
      ui_web.browser.debugBrowserEngineOverride = null;
      ui_web.browser.debugOperatingSystemOverride = null;
      debugOverrideJsConfiguration(null);
    });

    for (final ui_web.BrowserEngine engine in ui_web.BrowserEngine.values) {
      test('selects the desktop default for $engine and the loaded thread mode', () {
        ui_web.browser.debugBrowserEngineOverride = engine;
        final bool expectHybrid = switch (engine) {
          ui_web.BrowserEngine.blink => !testRenderer.isMultiThreaded,
          ui_web.BrowserEngine.webkit || ui_web.BrowserEngine.firefox => true,
        };
        for (final os in <ui_web.OperatingSystem>[
          ui_web.OperatingSystem.macOs,
          ui_web.OperatingSystem.linux,
          ui_web.OperatingSystem.windows,
        ]) {
          ui_web.browser.debugOperatingSystemOverride = os;
          testRenderer.rasterizer.dispose();
          testRenderer.debugResetRasterizer();
          expect(
            testRenderer.rasterizer,
            expectHybrid && browserSupportsTransferControlToOffscreen
                ? isA<HybridCanvasRasterizer>()
                : isA<OffscreenCanvasRasterizer>(),
            reason: '$os, multi-threaded: ${testRenderer.isMultiThreaded}',
          );
        }
      });

      test('keeps mobile and unknown platforms opt-in for $engine', () {
        ui_web.browser.debugBrowserEngineOverride = engine;
        for (final os in <ui_web.OperatingSystem>[
          ui_web.OperatingSystem.iOs,
          ui_web.OperatingSystem.android,
          ui_web.OperatingSystem.unknown,
        ]) {
          ui_web.browser.debugOperatingSystemOverride = os;
          testRenderer.rasterizer.dispose();
          testRenderer.debugResetRasterizer();
          expect(testRenderer.rasterizer, isA<OffscreenCanvasRasterizer>(), reason: '$os');
        }
      });
    }

    for (final enabled in <bool>[true, false]) {
      test('explicit hybrid $enabled overrides automatic selection', () {
        debugOverrideJsConfiguration(
          <String, Object?>{'skwasmUseHybridRasterizer': enabled}.jsify()
              as JsFlutterConfiguration?,
        );
        for (final ui_web.BrowserEngine engine in ui_web.BrowserEngine.values) {
          ui_web.browser.debugBrowserEngineOverride = engine;
          for (final ui_web.OperatingSystem os in ui_web.OperatingSystem.values) {
            ui_web.browser.debugOperatingSystemOverride = os;
            testRenderer.rasterizer.dispose();
            testRenderer.debugResetRasterizer();
            expect(
              testRenderer.rasterizer,
              enabled && browserSupportsTransferControlToOffscreen
                  ? isA<HybridCanvasRasterizer>()
                  : isA<OffscreenCanvasRasterizer>(),
              reason: '$engine on $os',
            );
          }
        }
      });
    }

    test('uses an offscreen picture surface for PNG image export', () async {
      debugOverrideJsConfiguration(
        <String, Object?>{'skwasmUseHybridRasterizer': true}.jsify() as JsFlutterConfiguration?,
      );

      final globalRenderer = renderer as SkwasmRenderer;
      globalRenderer.debugResetRasterizer();

      if (globalRenderer.rasterizer is! HybridCanvasRasterizer) {
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
      for (final mode in <String>['bitmap', 'hybrid']) {
        debugOverrideJsConfiguration(
          <String, Object?>{'skwasmUseHybridRasterizer': mode == 'hybrid'}.jsify()
              as JsFlutterConfiguration?,
        );
        globalRenderer.debugResetRasterizer();

        if (mode == 'bitmap') {
          expect(globalRenderer.rasterizer, isA<OffscreenCanvasRasterizer>());
        } else if (browserSupportsTransferControlToOffscreen) {
          expect(globalRenderer.rasterizer, isA<HybridCanvasRasterizer>());
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
