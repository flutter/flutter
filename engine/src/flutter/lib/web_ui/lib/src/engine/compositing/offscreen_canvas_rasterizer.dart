// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  Future<void> prepareToDraw() async {
    await rasterizer.offscreenSurface.setSize(currentFrameSize);
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
          .rasterizeToImageBitmaps(pictures);
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
