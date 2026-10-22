// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('overlapping surfaces receive their own render and context-loss callbacks', () async {
    final provider = OffscreenCanvasProvider();
    final first = SkwasmOffscreenSurface(provider);
    final second = SkwasmOffscreenSurface(provider);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFF00FF00), ui.BlendMode.src);
    final ui.Picture picture = recorder.endRecording();
    try {
      await Future.wait<void>(<Future<void>>[first.initialized, second.initialized]);
      Future<void> render(SkwasmOffscreenSurface surface, BitmapSize size) async {
        final List<DomImageBitmap> bitmaps = await surface.rasterizeToImageBitmaps(
          size,
          <ui.Picture>[picture],
        );
        try {
          expect(bitmaps.single.width, size.width);
          expect(bitmaps.single.height, size.height);
        } finally {
          for (final bitmap in bitmaps) {
            bitmap.close();
          }
        }
      }

      await Future.wait<void>(<Future<void>>[
        render(first, const BitmapSize(16, 12)),
        render(second, const BitmapSize(32, 24)),
      ]);
      await Future.wait<void>(<Future<void>>[
        first.triggerContextLoss(),
        second.triggerContextLoss(),
      ]);
      await Future.wait<void>(<Future<void>>[
        first.handledContextLossEvent,
        second.handledContextLossEvent,
      ]);
      await Future.wait<void>(<Future<void>>[
        render(first, const BitmapSize(24, 16)),
        render(second, const BitmapSize(12, 8)),
      ]);
    } finally {
      picture.dispose();
      first.dispose();
      second.dispose();
      provider.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('rendering can complete without exporting an image bitmap', () async {
    final provider = OffscreenCanvasProvider();
    final surface = SkwasmOffscreenSurface(provider);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFF00FF00), ui.BlendMode.src);
    final picture = recorder.endRecording() as SkwasmPicture;
    try {
      await surface.initialized;
      final int callbackId = withStackScope((StackScope scope) {
        final Pointer<PictureHandle> pictures = scope.allocPointerArray(1).cast<PictureHandle>();
        pictures[0] = picture.handle;
        return surfaceRenderPictures(surface.handle, pictures, 1, 16, 12, false);
      });
      final result =
          (await SkwasmCallbackHandler.instance.registerCallback(callbackId)) as RasterResult;
      expect(result.imageBitmaps.toDart, isEmpty);
      final List<DomImageBitmap> bitmaps = await surface.rasterizeToImageBitmaps(
        const BitmapSize(32, 24),
        <ui.Picture>[picture],
      );
      expect(bitmaps.single.width, 32);
      expect(bitmaps.single.height, 24);
      bitmaps.single.close();
    } finally {
      picture.dispose();
      surface.dispose();
      provider.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 10)));
}
