// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A [Rasterizer] creates [ViewRasterizer]s which are able to draw Flutter
/// content into [FlutterView]s.
abstract class Rasterizer {
  /// Creates a [ViewRasterizer] for a given [view].
  ViewRasterizer createViewRasterizer(EngineFlutterView view);

  /// Creates a [Surface] which is to be used for [Picture.toImage] calls.
  Surface createPictureToImageSurface();

  /// Sets the maximum size of the resource cache to [bytes].
  void setResourceCacheMaxBytes(int bytes);

  /// Disposes this rasterizer and all [ViewRasterizer]s that it created.
  void dispose();

  /// Provides the surfaces used by this rasterizer.
  SurfaceProvider get surfaceProvider;
}

/// Owns the view rasterizers that share a [SurfaceProvider].
abstract class SurfaceRasterizer<V extends ViewRasterizer> extends Rasterizer {
  SurfaceRasterizer() {
    assert(() {
      registerHotRestartListener(dispose);
      return true;
    }());
  }

  final Map<EngineFlutterView, V> _views = <EngineFlutterView, V>{};

  /// Includes disposed views whose frames are still using their canvases.
  int _liveFactories = 0;
  bool _disposed = false;

  /// Builds the rasterizer for a newly registered view.
  @protected
  V buildViewRasterizer(EngineFlutterView view);

  @override
  V createViewRasterizer(EngineFlutterView view) {
    assert(!_disposed);
    return _views.putIfAbsent(view, () {
      final V rasterizer = buildViewRasterizer(view);
      rasterizer._owner = this;
      _liveFactories++;
      return rasterizer;
    });
  }

  void _releaseFactory(ViewRasterizer rasterizer) {
    try {
      rasterizer.displayFactory.dispose();
    } finally {
      _liveFactories--;
      if (_disposed && _liveFactories == 0) {
        surfaceProvider.dispose();
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_liveFactories == 0) {
      surfaceProvider.dispose();
      return;
    }
    for (final V rasterizer in _views.values.toList()) {
      rasterizer.dispose();
    }
  }

  @override
  Surface createPictureToImageSurface() => surfaceProvider.createSurface();

  @override
  void setResourceCacheMaxBytes(int bytes) => surfaceProvider.setSkiaResourceCacheMaxBytes(bytes);
}

/// Composites Flutter content into a [FlutterView]. Manages the creation of
/// [DisplayCanvas] objects to render the content into.
abstract class ViewRasterizer {
  ViewRasterizer(this.view) {
    view.dom.setScene(sceneElement);
  }

  /// The view this rasterizer renders into.
  final EngineFlutterView view;

  /// The queue of render requests for this view.
  final RenderQueue queue = RenderQueue();

  SurfaceRasterizer<ViewRasterizer>? _owner;

  /// Whether [PlatformViewEmbedder.submitFrame] is still using the display canvases. Their factory
  /// and the shared surface provider must outlive that work, even on failure.
  bool _submittingFrame = false;

  /// Whether this rasterizer has been disposed.
  bool get isDisposed => _isDisposed;

  /// The size of the current frame being rasterized.
  BitmapSize currentFrameSize = BitmapSize.zero;

  /// The context which is persisted between frames.
  final CompositorContext context = CompositorContext();

  /// The platform view embedder.
  late final PlatformViewEmbedder viewEmbedder = PlatformViewEmbedder(sceneElement, this);

  /// A factory for creating overlays.
  DisplayCanvasFactory<DisplayCanvas> get displayFactory;

  /// The DOM element which this rasterizer should raster into.
  final DomElement sceneElement = domDocument.createElement('flt-scene');

  /// The last layer tree that was rendered. Only non-null if in debug mode.
  LayerTree? _lastRenderedLayerTree;

  /// Draws the [layerTree] at [frameSize] (in physical pixels) to the screen
  /// for the view associated with this rasterizer.
  Future<void> draw(LayerTree layerTree, ui.Size frameSize, FrameTimingRecorder? recorder) async {
    // The [frameSize] may be slightly imprecise if the `devicePixelRatio` isn't
    // an integer. For example, if you zoom to 110% in Chrome on a Macbook, the
    // `devicePixelRatio` is `2.200000047683716`, so when the physical size is
    // computed by multiplying the logical size by the device pixel ratio, the
    // result is slightly imprecise as well. Nevertheless, the number should
    // be close to an integer, so round the frame size to be more precise.
    final BitmapSize bitmapSize = frameSize.isEmpty
        ? BitmapSize.zero
        : BitmapSize.fromSize(frameSize);
    if (_isDisposed || bitmapSize.isEmpty) {
      // The view was disposed or the available drawing area is empty (or
      // rounds to 0 physical pixels). Skip drawing.
      // Record all the draw steps as happening instantly so we don't crash
      // when submitting frame timings.
      recorder?.recordRasterStart();
      recorder?.recordRasterFinish();
      return;
    }

    currentFrameSize = bitmapSize;
    viewEmbedder.frameSize = currentFrameSize;
    final Frame compositorFrame = context.acquireFrame(viewEmbedder);

    // Raster time includes the engine's preroll, measure, composition
    // optimization, and paint passes, as well as rasterizing the pictures.
    recorder?.recordRasterStart();
    compositorFrame.raster(layerTree, currentFrameSize);
    _lastRenderedLayerTree = layerTree;

    final Stopwatch? presentationTimer = Profiler.isBenchmarkMode ? (Stopwatch()..start()) : null;
    await prepareToDraw();
    if (_isDisposed) {
      // The view was disposed while preparing to draw. Don't submit the frame,
      // which would allocate new display canvases for the disposed view.
      recorder?.recordRasterFinish();
      return;
    }
    _submittingFrame = true;
    try {
      await viewEmbedder.submitFrame(recorder);
    } finally {
      _submittingFrame = false;
      if (_isDisposed) {
        _owner?._releaseFactory(this);
      }
    }
    if (presentationTimer != null) {
      presentationTimer.stop();
      Profiler.instance.benchmark(
        kProfilePresentationDuration,
        presentationTimer.elapsedMicroseconds.toDouble(),
      );
    }
  }

  /// Do some initialization to prepare to draw a frame.
  Future<void> prepareToDraw();

  /// Rasterizes the given [pictures] into the [displayCanvases].
  ///
  /// Throws an [ArgumentError] if [displayCanvases] and [pictures] are not
  /// the same length.
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  );

  /// Get a [DisplayCanvas] to use as an overlay.
  DisplayCanvas getOverlay() {
    return displayFactory.getCanvas();
  }

  /// Release the given [overlay] so it may be reused.
  void releaseOverlay(DisplayCanvas overlay) {
    displayFactory.releaseCanvas(overlay);
  }

  /// Release all overlays.
  void releaseOverlays() {
    displayFactory.releaseCanvases();
  }

  /// Remove all overlays that have been created from the DOM.
  void removeOverlaysFromDom() {
    displayFactory.removeCanvasesFromDom();
  }

  bool _isDisposed = false;

  /// Disposes this rasterizer.
  ///
  /// After this is called, [draw] does nothing.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _owner?._views.remove(view);
    viewEmbedder.dispose();
    if (!_submittingFrame) {
      _owner?._releaseFactory(this);
    }
  }

  /// Clears the state. Used in tests.
  void debugClear() {
    viewEmbedder.debugClear();
  }

  /// Returns helpful debug information.
  Map<String, dynamic>? dumpDebugInfo() {
    if (kDebugMode) {
      if (_lastRenderedLayerTree != null) {
        return _lastRenderedLayerTree!.dumpDebugInfo();
      }
    }
    return null;
  }
}

/// A [DisplayCanvas] is an abstraction for a canvas element which displays
/// Skia-drawn pictures to the screen. They are also sometimes called "overlays"
/// because they can be overlaid on top of platform views, which are HTML
/// content that isn't rendered by Skia.
///
/// [DisplayCanvas]es are drawn into with [ViewRasterizer.rasterize].
abstract class DisplayCanvas {
  /// The DOM element which, when appended to the scene host, will display the
  /// Skia-rendered content to the screen.
  DomElement get hostElement;

  /// Whether or not this overlay canvas is attached to the DOM.
  bool get isConnected;

  /// Initialize the overlay.
  void initialize();

  /// Marks whether this canvas is used as an overlay between platform views.
  void setIsOverlay(bool isOverlay) {}

  /// Disposes this overlay.
  void dispose();
}

/// Encapsulates a request to render a [ui.Scene] at a given physical [size].
/// Contains the scene to render and a [Completer] which completes when the
/// scene has been rendered.
typedef RenderRequest = ({
  ui.Scene scene,
  ui.Size size,
  Completer<void> completer,
  FrameTimingRecorder? recorder,
});

/// A per-view queue of render requests. Only contains the current render
/// request and the next render request. If a new render request is made before
/// the current request is complete, then the next render request is replaced
/// with the most recently requested render and the other one is dropped.
class RenderQueue {
  RenderQueue();

  RenderRequest? current;
  RenderRequest? next;
}
