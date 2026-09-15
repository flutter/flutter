// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
}
