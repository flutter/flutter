// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('OffscreenSurface', () {
    setUpUnitTests();

    test(
      'creates new context when WebGL context is lost',
      () async {
        final Rasterizer rasterizer = renderer.rasterizer;
        final surfaceProvider = rasterizer.surfaceProvider as OffscreenSurfaceProvider;
        final OffscreenSurface surface = surfaceProvider.createSurface();
        await surface.initialized;

        final int initialGlContext = surface.glContext;

        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;
        await surface.initialized;

        // A new context is created.
        expect(surface.glContext, isNot(initialGlContext));
      },
      skip: isFirefox || isSafari || !browserSupportsOffscreenCanvas,
    );

    test(
      'can still render after context is lost',
      () async {
        final Rasterizer rasterizer = renderer.rasterizer;
        final surfaceProvider = rasterizer.surfaceProvider as OffscreenSurfaceProvider;
        final OffscreenSurface surface = surfaceProvider.createSurface();
        await surface.initialized;

        await surface.setSize(const BitmapSize(10, 10));

        // Draw a red square.
        final ui.Picture redPicture = drawPicture((ui.Canvas canvas) {
          canvas.drawRect(
            const ui.Rect.fromLTWH(0, 0, 10, 10),
            ui.Paint()..color = const ui.Color(0xFFFF0000),
          );
        });
        List<DomImageBitmap> bitmaps = await surface.rasterizeToImageBitmaps(<ui.Picture>[
          redPicture,
        ]);
        expect(bitmaps, hasLength(1));
        await expectBitmapColor(bitmaps.single, const ui.Color(0xFFFF0000));

        // Lose the context.
        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;
        await surface.initialized;

        // Draw a blue square.
        final ui.Picture bluePicture = drawPicture((ui.Canvas canvas) {
          canvas.drawRect(
            const ui.Rect.fromLTWH(0, 0, 10, 10),
            ui.Paint()..color = const ui.Color(0xFF0000FF),
          );
        });
        bitmaps = await surface.rasterizeToImageBitmaps(<ui.Picture>[bluePicture]);
        expect(bitmaps, hasLength(1));
        await expectBitmapColor(bitmaps.single, const ui.Color(0xFF0000FF));
      },
      skip: isFirefox || isSafari || !browserSupportsOffscreenCanvas,
    );

    test(
      'can recover from multiple context losses',
      () async {
        final Rasterizer rasterizer = renderer.rasterizer;
        final surfaceProvider = rasterizer.surfaceProvider as OffscreenSurfaceProvider;
        final OffscreenSurface surface = surfaceProvider.createSurface();
        await surface.initialized;

        final int initialGlContext = surface.glContext;

        // First loss
        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;
        await surface.initialized;
        final int contextAfterFirstLoss = surface.glContext;
        expect(contextAfterFirstLoss, isNot(initialGlContext));

        // Second loss
        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;
        await surface.initialized;
        final int contextAfterSecondLoss = surface.glContext;
        expect(contextAfterSecondLoss, isNot(contextAfterFirstLoss));
      },
      skip: isFirefox || isSafari || !browserSupportsOffscreenCanvas,
    );
  });
}

ui.Picture drawPicture(void Function(ui.Canvas) drawCommands) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  drawCommands(canvas);
  return recorder.endRecording();
}

Future<void> expectBitmapColor(DomImageBitmap bitmap, ui.Color color) async {
  final DomHTMLCanvasElement canvas = createDomCanvasElement(
    width: bitmap.width,
    height: bitmap.height,
  );
  final DomCanvasRenderingContext2D ctx = canvas.context2D;
  ctx.drawImage(bitmap, 0, 0);
  final DomImageData imageData = ctx.getImageData(0, 0, 1, 1);
  final Uint8ClampedList pixels = imageData.data;
  expect(pixels[0], color.red);
  expect(pixels[1], color.green);
  expect(pixels[2], color.blue);
  expect(pixels[3], color.alpha);
}
