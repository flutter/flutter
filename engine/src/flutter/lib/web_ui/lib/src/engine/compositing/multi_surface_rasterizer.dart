// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A [Rasterizer] which uses one or many on-screen WebGL contexts to display
/// the scene. This way of rendering is prone to bugs because there is a limit
/// to how many WebGL contexts can be live at one time as well as bugs in
/// sharing GL resources between the contexts. However, using
/// [createImageBitmap] is currently very slow on Firefox and Safari browsers,
/// so directly rendering to several [Surface]s is how we can achieve 60 fps on
/// these browsers.
class MultiSurfaceRasterizer extends Rasterizer {
  MultiSurfaceRasterizer(OnscreenSurface Function(OnscreenCanvasProvider) onscreenSurfaceCreateFn)
    : _surfaceProvider = OnscreenSurfaceProvider(OnscreenCanvasProvider(), onscreenSurfaceCreateFn);

  final OnscreenSurfaceProvider _surfaceProvider;

  @override
  @visibleForTesting
  SurfaceProvider get surfaceProvider => _surfaceProvider;

  @override
  MultiSurfaceViewRasterizer createViewRasterizer(EngineFlutterView view) {
    return _viewRasterizers.putIfAbsent(
      view,
      () => MultiSurfaceViewRasterizer(view, this, _surfaceProvider),
    );
  }

  final Map<EngineFlutterView, MultiSurfaceViewRasterizer> _viewRasterizers =
      <EngineFlutterView, MultiSurfaceViewRasterizer>{};

  @override
  void dispose() {
    for (final MultiSurfaceViewRasterizer viewRasterizer in _viewRasterizers.values) {
      viewRasterizer.dispose();
    }
    _viewRasterizers.clear();
    _surfaceProvider.dispose();
  }

  @override
  void setResourceCacheMaxBytes(int bytes) {
    _surfaceProvider.setSkiaResourceCacheMaxBytes(bytes);
  }

  @override
  Surface createPictureToImageSurface() {
    return _surfaceProvider.createSurface();
  }
}

class MultiSurfaceViewRasterizer extends ViewRasterizer {
  MultiSurfaceViewRasterizer(super.view, this.rasterizer, this.surfaceProvider);

  final MultiSurfaceRasterizer rasterizer;
  final OnscreenSurfaceProvider surfaceProvider;

  @override
  late final DisplayCanvasFactory<OnscreenSurface> displayFactory =
      DisplayCanvasFactory<OnscreenSurface>(createCanvas: surfaceProvider.createSurface);

  @override
  Future<void> prepareToDraw() async {
    await displayFactory.baseCanvas.setSize(currentFrameSize);
  }

  /// Rasterizes the given [picture] directly to the given [canvas].
  Future<void> rasterizeToCanvas(OnscreenSurface canvas, ui.Picture picture) async {
    await canvas.setSize(currentFrameSize);
    return canvas.rasterizeToCanvas(picture);
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
    final rasterizeFutures = <Future<void>>[];
    for (var i = 0; i < displayCanvases.length; i++) {
      rasterizeFutures.add(rasterizeToCanvas(displayCanvases[i] as OnscreenSurface, pictures[i]));
    }
    await Future.wait<void>(rasterizeFutures);
    recorder?.recordRasterFinish();
  }
}
