// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:meta/meta.dart';

import '../../engine.dart';

/// Caches canvases used to overlay platform views.
class RenderCanvasFactory {
  RenderCanvasFactory() {
    assert(() {
      registerHotRestartListener(debugClear);
      return true;
    }());
  }

  /// The lazy-initialized singleton surface factory.
  ///
  /// [debugClear] causes this singleton to be reinitialized.
  static RenderCanvasFactory get instance =>
      _instance ??= RenderCanvasFactory();

  /// Returns the raw (potentially uninitialized) value of the singleton.
  ///
  /// Useful in tests for checking the lifecycle of this class.
  static RenderCanvasFactory? get debugUninitializedInstance => _instance;

  // Override the current instance with a new one.
  //
  // This should only be used in tests.
  static void debugSetInstance(RenderCanvasFactory newInstance) {
    _instance = newInstance;
  }

  static RenderCanvasFactory? _instance;

  /// The base canvas to paint on. This is the default canvas which will be
  /// painted to. If there are no platform views, then this canvas will render
  /// the entire scene.
  final RenderCanvas baseCanvas = RenderCanvas();

  /// A surface used specifically for `Picture.toImage` when software rendering
  /// is supported.
  late final Surface pictureToImageSurface = Surface();

  /// Canvases created by this factory which are currently in use.
  final List<RenderCanvas> _liveCanvases = <RenderCanvas>[];

  /// Canvases created by this factory which are no longer in use. These can be
  /// reused.
  final List<RenderCanvas> _cache = <RenderCanvas>[];

  /// The number of canvases which have been created by this factory.
  int get _canvasCount => _liveCanvases.length + _cache.length + 1;

  /// The number of surfaces created by this factory. Used for testing.
  @visibleForTesting
  int get debugSurfaceCount => _canvasCount;

  /// Returns the number of cached surfaces.
  ///
  /// Useful in tests.
  int get debugCacheSize => _cache.length;

  /// Gets an overlay canvas from the cache or creates a new one if there are
  /// none in the cache.
  RenderCanvas getCanvas() {
    if (_cache.isNotEmpty) {
      final RenderCanvas canvas = _cache.removeLast();
      _liveCanvases.add(canvas);
      return canvas;
    } else {
      final RenderCanvas canvas = RenderCanvas();
      _liveCanvases.add(canvas);
      return canvas;
    }
  }

  /// Releases all surfaces so they can be reused in the next frame.
  ///
  /// If a released surface is in the DOM, it is not removed. This allows the
  /// engine to release the surfaces at the end of the frame so they are ready
  /// to be used in the next frame, but still used for painting in the current
  /// frame.
  void releaseCanvases() {
    _cache.addAll(_liveCanvases);
    _liveCanvases.clear();
  }

  /// Removes all surfaces except the base surface from the DOM.
  ///
  /// This is called at the beginning of the frame to prepare for painting into
  /// the new surfaces.
  void removeSurfacesFromDom() {
    _cache.forEach(_removeFromDom);
  }

  // Removes [canvas] from the DOM.
  void _removeFromDom(RenderCanvas canvas) {
    canvas.htmlElement.remove();
  }

  /// Signals that a canvas is no longer being used. It can be reused.
  void releaseCanvas(RenderCanvas canvas) {
    assert(canvas != baseCanvas, 'Attempting to release the base canvas');
    assert(
        _liveCanvases.contains(canvas),
        'Attempting to release a Canvas which '
        'was not created by this factory');
    canvas.htmlElement.remove();
    _liveCanvases.remove(canvas);
    _cache.add(canvas);
  }

  /// Returns [true] if [canvas] is currently being used to paint content.
  ///
  /// The base canvas always counts as live.
  ///
  /// If a canvas is not live, then it must be in the cache and ready to be
  /// reused.
  bool isLive(RenderCanvas canvas) {
    if (canvas == baseCanvas || _liveCanvases.contains(canvas)) {
      return true;
    }
    assert(_cache.contains(canvas));
    return false;
  }

  /// Dispose all canvases created by this factory. Used in tests.
  void debugClear() {
    for (final RenderCanvas canvas in _cache) {
      canvas.dispose();
    }
    for (final RenderCanvas canvas in _liveCanvases) {
      canvas.dispose();
    }
    baseCanvas.dispose();
    _liveCanvases.clear();
    _cache.clear();
    _instance = null;
  }
}
