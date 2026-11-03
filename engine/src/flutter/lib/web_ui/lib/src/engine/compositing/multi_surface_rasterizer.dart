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

  /// Removes the [view] rasterizer from the registry.
  void _removeViewRasterizer(EngineFlutterView view) {
    _viewRasterizers.remove(view);
  }

  @override
  void dispose() {
    for (final viewRasterizer in List<MultiSurfaceViewRasterizer>.of(_viewRasterizers.values)) {
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

/// A [ViewRasterizer] for a single [EngineFlutterView] managed by a
/// [MultiSurfaceRasterizer], rendering directly onto one or more onscreen
/// [Surface]s.
class MultiSurfaceViewRasterizer extends ViewRasterizer {
  MultiSurfaceViewRasterizer(super.view, this.rasterizer, this.surfaceProvider);

  /// The owning [MultiSurfaceRasterizer] that tracks this view rasterizer.
  final MultiSurfaceRasterizer rasterizer;

  /// The [OnscreenSurfaceProvider] used to allocate display surfaces for [view].
  final OnscreenSurfaceProvider surfaceProvider;

  bool _disposed = false;

  // Shadows `ViewRasterizer._lastRenderedLayerTree`, which is private to
  // another library, because [draw] is overridden below.
  LayerTree? _lastRenderedLayerTree;

  @override
  late final DisplayCanvasFactory<OnscreenSurface> displayFactory =
      DisplayCanvasFactory<OnscreenSurface>(createCanvas: surfaceProvider.createSurface);

  // Mirrors `ViewRasterizer.draw`, but bails out if the view is disposed
  // before the frame starts or while `prepareToDraw` is awaited, so a removed
  // view never resurrects surfaces (and WebGL contexts) for a stale frame.
  // See https://github.com/flutter/flutter/issues/195025.
  @override
  Future<void> draw(LayerTree layerTree, FrameTimingRecorder? recorder) async {
    final ui.Size frameSize = view.physicalSize;
    if (_disposed || frameSize.isEmpty) {
      // Nothing to draw. Record all the draw steps as happening instantly so
      // we don't crash when submitting frame timings.
      recorder?.recordRasterStart();
      recorder?.recordRasterFinish();
      return;
    }

    // Round the frame size, which may be slightly imprecise when the
    // `devicePixelRatio` isn't an integer.
    final bitmapSize = BitmapSize.fromSize(frameSize);

    currentFrameSize = bitmapSize;
    viewEmbedder.frameSize = currentFrameSize;
    final Frame compositorFrame = context.acquireFrame(viewEmbedder);

    recorder?.recordRasterStart();
    compositorFrame.raster(layerTree, currentFrameSize);
    _lastRenderedLayerTree = layerTree;

    await prepareToDraw();
    if (_disposed) {
      recorder?.recordRasterFinish();
      return;
    }
    await viewEmbedder.submitFrame(recorder);
  }

  @override
  Future<void> prepareToDraw() async {
    if (_disposed) {
      return;
    }
    await displayFactory.baseCanvas.setSize(currentFrameSize);
  }

  /// Rasterizes the given [picture] directly to the given [canvas].
  Future<void> rasterizeToCanvas(OnscreenSurface canvas, ui.Picture picture) async {
    if (_disposed) {
      return;
    }
    await canvas.setSize(currentFrameSize);
    if (_disposed) {
      return;
    }
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
    if (_disposed) {
      recorder?.recordRasterFinish();
      return;
    }
    final rasterizeFutures = <Future<void>>[];
    for (var i = 0; i < displayCanvases.length; i++) {
      rasterizeFutures.add(rasterizeToCanvas(displayCanvases[i] as OnscreenSurface, pictures[i]));
    }
    await Future.wait<void>(rasterizeFutures);
    recorder?.recordRasterFinish();
  }

  @override
  Map<String, dynamic>? dumpDebugInfo() {
    if (kDebugMode) {
      return _lastRenderedLayerTree?.dumpDebugInfo();
    }
    return null;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _lastRenderedLayerTree = null;
    // Complete any render queued for this view so callers awaiting
    // `renderScene` for a removed view don't hang.
    queue.next?.completer.complete();
    queue.next = null;
    rasterizer._removeViewRasterizer(view);
    displayFactory.dispose();
    super.dispose();
  }
}
