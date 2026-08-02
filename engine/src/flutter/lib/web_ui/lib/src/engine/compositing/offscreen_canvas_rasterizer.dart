// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A [Rasterizer] that uses a single GL context in an OffscreenCanvas to do
/// all the rendering. It transfers bitmaps created in the OffscreenCanvas to
/// one or many on-screen <canvas> elements to actually display the scene.
class OffscreenCanvasRasterizer extends Rasterizer {
  OffscreenCanvasRasterizer(
    OffscreenSurface Function(OffscreenCanvasProvider) offscreenSurfaceCreateFn,
  ) : _surfaceProvider = OffscreenSurfaceProvider(
        OffscreenCanvasProvider(),
        offscreenSurfaceCreateFn,
      );

  final OffscreenSurfaceProvider _surfaceProvider;

  @override
  @visibleForTesting
  SurfaceProvider get surfaceProvider => _surfaceProvider;

  /// This is an SkSurface backed by an OffScreenCanvas. This single Surface is
  /// used to render to many RenderCanvases to produce the rendered scene.
  late final OffscreenSurface offscreenSurface = _surfaceProvider.createSurface();

  /// A lock to ensure that only one view is using the [offscreenSurface] at a
  /// time.
  ///
  /// Since the [offscreenSurface] is shared across all views, we must ensure
  /// that we only render one view at a time.
  Future<void> _lock = Future<void>.value();

  Future<T> synchronized<T>(Future<T> Function() computation) async {
    final Future<void> oldLock = _lock;
    final Completer<void> completer = Completer<void>();
    _lock = completer.future;
    await oldLock;
    try {
      return await computation();
    } finally {
      completer.complete();
    }
  }

  @override
  OffscreenCanvasViewRasterizer createViewRasterizer(EngineFlutterView view) {
    return _viewRasterizers.putIfAbsent(view, () => OffscreenCanvasViewRasterizer(view, this));
  }

  final Map<EngineFlutterView, OffscreenCanvasViewRasterizer> _viewRasterizers =
      <EngineFlutterView, OffscreenCanvasViewRasterizer>{};

  @override
  void setResourceCacheMaxBytes(int bytes) {
    _surfaceProvider.setSkiaResourceCacheMaxBytes(bytes);
  }

  @override
  void dispose() {
    _surfaceProvider.dispose();
    for (final OffscreenCanvasViewRasterizer viewRasterizer in _viewRasterizers.values) {
      viewRasterizer.dispose();
    }
  }

  @override
  Surface createPictureToImageSurface() {
    return _surfaceProvider.createSurface();
  }
}

class OffscreenCanvasViewRasterizer extends ViewRasterizer {
  OffscreenCanvasViewRasterizer(super.view, this.rasterizer);

  final OffscreenCanvasRasterizer rasterizer;

  @override
  final DisplayCanvasFactory<RenderCanvas> displayFactory = DisplayCanvasFactory<RenderCanvas>(
    createCanvas: () => RenderCanvas(),
  );

  @override
  Future<void> draw(LayerTree layerTree, FrameTimingRecorder? recorder) {
    return rasterizer.synchronized(() => super.draw(layerTree, recorder));
  }

  @override
  Future<void> prepareToDraw() async {
    await rasterizer.offscreenSurface.setMinimumSize(currentFrameSize);
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    if (displayCanvases.length != pictures.length) {
      throw ArgumentError('Called rasterize() with a different number of canvases and pictures.');
    }
    recorder?.recordRasterStart();
    if (browserSupportsCreateImageBitmap) {
      final List<DomImageBitmap> bitmaps = await rasterizer.offscreenSurface
          .rasterizeToImageBitmaps(pictures, size: currentFrameSize);
      for (var i = 0; i < displayCanvases.length; i++) {
        (displayCanvases[i] as RenderCanvas).render(bitmaps[i]);
      }
    } else {
      for (var i = 0; i < displayCanvases.length; i++) {
        await rasterizer.offscreenSurface.rasterizeToCanvas(pictures[i]);
        (displayCanvases[i] as RenderCanvas).renderWithNoBitmapSupport(
          rasterizer.offscreenSurface.canvasImageSource,
          currentFrameSize.height,
          currentFrameSize,
        );
      }
    }
    recorder?.recordRasterFinish();
  }
}
