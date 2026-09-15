// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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
  test('multiple surfaces can complete overlapping callbacks', () async {
    final canvasProvider = OnscreenCanvasProvider();
    final first = SkwasmSurface.onscreen(
      canvasProvider,
      useTransferredCanvas: skwasmIsMultiThreaded(),
    );
    final second = SkwasmSurface.onscreen(
      canvasProvider,
      useTransferredCanvas: skwasmIsMultiThreaded(),
    );
    ui.Picture? picture;
    try {
      await Future.wait<void>(<Future<void>>[first.initialized, second.initialized])
          .timeout(const Duration(seconds: 10));
      await Future.wait<void>(<Future<void>>[
        first.setSize(const BitmapSize(64, 64)),
        second.setSize(const BitmapSize(64, 64)),
      ]).timeout(const Duration(seconds: 10));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFF00FF00), ui.BlendMode.src);
      picture = recorder.endRecording();
      await Future.wait<void>(<Future<void>>[
        first.rasterizeToCanvas(picture),
        second.rasterizeToCanvas(picture),
      ]).timeout(const Duration(seconds: 10));
    } finally {
      picture?.dispose();
      first.dispose();
      second.dispose();
      canvasProvider.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('onscreen surface positions overlays without moving the base canvas', () async {
    final canvasProvider = OnscreenCanvasProvider();
    final surface = SkwasmSurface.onscreen(
      canvasProvider,
      useTransferredCanvas: skwasmIsMultiThreaded(),
    );
    try {
      await surface.initialized.timeout(const Duration(seconds: 10));
      final canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      expect(canvas.style.position, isNot('absolute'));

      surface.setIsOverlay(true);
      expect(canvas.style.position, 'absolute');

      surface.setIsOverlay(false);
      expect(canvas.style.position, isNot('absolute'));
    } finally {
      surface.dispose();
      canvasProvider.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('onscreen surface recreates context and keeps pixels after loss', () async {
    final canvasProvider = OnscreenCanvasProvider();
    final surface = SkwasmSurface.onscreen(
      canvasProvider,
      useTransferredCanvas: skwasmIsMultiThreaded(),
    );
    domDocument.body!.append(surface.hostElement);
    ui.Picture? picture;
    try {
      await surface.initialized.timeout(const Duration(seconds: 10));
      await surface.setSize(const BitmapSize(2, 2)).timeout(const Duration(seconds: 10));
      final int initialGlContext = surface.glContext;
      surface.setIsOverlay(true);
      var canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      expect(canvas.style.position, 'absolute');

      picture = _solidPicture(const ui.Color(0xFFFF0000));
      await surface.rasterizeToCanvas(picture).timeout(const Duration(seconds: 10));
      expect(await _readOnscreenPixel(surface, waitForFrame: skwasmIsMultiThreaded()), <int>[
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
      ]);

      await surface.triggerContextLoss().timeout(const Duration(seconds: 10));
      await surface.handledContextLossEvent.timeout(const Duration(seconds: 10));
      await surface.initialized.timeout(const Duration(seconds: 10));
      expect(surface.glContext, isNot(initialGlContext));
      canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      expect(canvas.style.position, 'absolute');
      surface.setIsOverlay(false);
      expect(canvas.style.position, isNot('absolute'));

      picture.dispose();
      picture = _solidPicture(const ui.Color(0xFF0000FF));
      await surface.rasterizeToCanvas(picture).timeout(const Duration(seconds: 10));
      expect(await _readOnscreenPixel(surface, waitForFrame: skwasmIsMultiThreaded()), <int>[
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
      ]);
    } finally {
      picture?.dispose();
      surface.dispose();
      surface.hostElement.remove();
      canvasProvider.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}

ui.Picture _solidPicture(ui.Color color) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 2, 2));
  canvas.drawColor(color, ui.BlendMode.src);
  return recorder.endRecording();
}

Future<List<int>> _readOnscreenPixel(SkwasmSurface surface, {required bool waitForFrame}) async {
  if (waitForFrame) {
    await _settleOnscreenFrame();
  }
  final DomHTMLCanvasElement canvas = createDomCanvasElement(width: 2, height: 2);
  final DomCanvasRenderingContext2D context = canvas.context2D;
  context.drawImage(surface.canvasImageSource, 0, 0);
  final Uint8ClampedList data = context.getImageData(0, 0, 2, 2).data;
  canvas.width = 0;
  canvas.height = 0;
  return data.toList();
}

Future<void> _settleOnscreenFrame() async {
  for (var i = 0; i < 2; i += 1) {
    final completer = Completer<void>();
    domWindow.requestAnimationFrame((_) => completer.complete());
    await completer.future;
  }
}
