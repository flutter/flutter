// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

// TODO(yjbanov): this is currently very naive. We probably want to cache
//                fewer large canvases than small canvases. We could also
//                improve cache hit count if we did not require exact canvas
//                size match, but instead could choose a canvas that's big
//                enough. The optimal heuristic will need to be figured out.
//                For example, we probably don't want to pick a full-screen
//                canvas to draw a 10x10 picture. Let's revisit this after
//                Harry's layer merging refactor.
/// The maximum number canvases cached.
const _kCanvasCacheSize = 30;

/// Canvases available for reuse, capped at [_kCanvasCacheSize].
final List<BitmapCanvas> _recycledCanvases = <BitmapCanvas>[];

/// A request to repaint a canvas.
///
/// Paint requests are prioritized such that the larger pictures go first. This
/// makes canvas allocation more efficient by letting large pictures claim
/// larger recycled canvases. Otherwise, small pictures would claim the large
/// canvases forcing us to allocate new large canvases.
class _PaintRequest {
  _PaintRequest({
    this.canvasSize,
    this.paintCallback,
  })  : assert(canvasSize != null),
        assert(paintCallback != null);

  final ui.Size canvasSize;
  final ui.VoidCallback paintCallback;
}

/// Repaint requests produced by [PersistedPicture]s that actually paint on the
/// canvas. Painting is delayed until the layer tree is updated to maximize
/// the number of reusable canvases.
List<_PaintRequest> _paintQueue = <_PaintRequest>[];

void _recycleCanvas(EngineCanvas canvas) {
  if (canvas is BitmapCanvas && canvas.isReusable()) {
    _recycledCanvases.add(canvas);
    if (_recycledCanvases.length > _kCanvasCacheSize) {
      final BitmapCanvas removedCanvas = _recycledCanvases.removeAt(0);
      removedCanvas.dispose();
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.disposedCount++;
      }
    }
    if (_debugShowCanvasReuseStats) {
      DebugCanvasReuseOverlay.instance.inRecycleCount =
          _recycledCanvases.length;
    }
  }
}

/// Signature of a function that instantiates a [PersistedPicture].
typedef PersistedPictureFactory = PersistedPicture Function(
    Object webOnlyPaintedBy,
    double dx,
    double dy,
    ui.Picture picture,
    int hints);

/// Function used by the [SceneBuilder] to instantiate a picture layer.
PersistedPictureFactory persistedPictureFactory = standardPictureFactory;

/// Instantiates an implementation of a picture layer that uses DOM, CSS, and
/// 2D canvas for painting.
PersistedStandardPicture standardPictureFactory(Object webOnlyPaintedBy,
    double dx, double dy, ui.Picture picture, int hints) {
  return PersistedStandardPicture(webOnlyPaintedBy, dx, dy, picture, hints);
}

/// Instantiates an implementation of a picture layer that uses CSS Paint API
/// (part of Houdini) for painting.
PersistedHoudiniPicture houdiniPictureFactory(Object webOnlyPaintedBy,
    double dx, double dy, ui.Picture picture, int hints) {
  return PersistedHoudiniPicture(webOnlyPaintedBy, dx, dy, picture, hints);
}

class PersistedHoudiniPicture extends PersistedPicture {
  PersistedHoudiniPicture(
      Object paintedBy, double dx, double dy, ui.Picture picture, int hints)
      : super(paintedBy, dx, dy, picture, hints) {
    if (!_cssPainterRegistered) {
      _registerCssPainter();
    }
  }

  static bool _cssPainterRegistered = false;

  static void _registerCssPainter() {
    _cssPainterRegistered = true;
    final dynamic css = js_util.getProperty(html.window, 'CSS');
    final dynamic paintWorklet = js_util.getProperty(css, 'paintWorklet');
    if (paintWorklet == null) {
      html.window.console.warn(
          'WARNING: CSS.paintWorklet not available. Paint worklets are only '
          'supported on sites served from https:// or http://localhost.');
      return;
    }
    js_util.callMethod(
      paintWorklet,
      'addModule',
      <dynamic>[
        '/packages/flutter_web/assets/houdini_painter.js',
      ],
    );
  }

  /// Houdini does not paint to bitmap.
  @override
  int get bitmapPixelCount => 0;

  @override
  void applyPaint(EngineCanvas oldCanvas) {
    _recycleCanvas(oldCanvas);
    final HoudiniCanvas canvas = HoudiniCanvas(_localCullRect);
    _canvas = canvas;
    domRenderer.clearDom(rootElement);
    rootElement.append(_canvas.rootElement);
    picture.recordingCanvas.apply(_canvas);
    canvas.commit();
  }
}

class PersistedStandardPicture extends PersistedPicture {
  PersistedStandardPicture(
      Object paintedBy, double dx, double dy, ui.Picture picture, int hints)
      : super(paintedBy, dx, dy, picture, hints);

  @override
  int get bitmapPixelCount {
    if (_canvas is! BitmapCanvas) {
      return 0;
    }

    final BitmapCanvas bitmapCanvas = _canvas;
    return bitmapCanvas.bitmapPixelCount;
  }

  @override
  void applyPaint(EngineCanvas oldCanvas) {
    if (picture.recordingCanvas.hasArbitraryPaint) {
      _applyBitmapPaint(oldCanvas);
    } else {
      _applyDomPaint(oldCanvas);
    }
  }

  void _applyDomPaint(EngineCanvas oldCanvas) {
    _recycleCanvas(oldCanvas);
    _canvas = DomCanvas();
    domRenderer.clearDom(rootElement);
    rootElement.append(_canvas.rootElement);
    picture.recordingCanvas.apply(_canvas);
  }

  bool _doesCanvasFitBounds(BitmapCanvas canvas, ui.Rect newBounds) {
    final ui.Rect canvasBounds = canvas.bounds;
    return canvasBounds.width >= newBounds.width &&
        canvasBounds.height >= newBounds.height;
  }

  void _applyBitmapPaint(EngineCanvas oldCanvas) {
    if (oldCanvas is BitmapCanvas &&
        _doesCanvasFitBounds(oldCanvas, _localCullRect) &&
        oldCanvas.isReusable()) {
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.keptCount++;
      }
      oldCanvas.bounds = _localCullRect;
      _canvas = oldCanvas;
      _canvas.clear();
      picture.recordingCanvas.apply(_canvas);
    } else {
      // We can't use the old canvas because the size has changed, so we put
      // it in a cache for later reuse.
      _recycleCanvas(oldCanvas);
      // We cannot paint immediately because not all canvases that we may be
      // able to reuse have been released yet. So instead we enqueue this
      // picture to be painted after the update cycle is done syncing the layer
      // tree then reuse canvases that were freed up.
      _paintQueue.add(_PaintRequest(
        canvasSize: _localCullRect.size,
        paintCallback: () {
          _canvas = _findOrCreateCanvas(_localCullRect);
          if (_debugExplainSurfaceStats) {
            _surfaceStatsFor(this).paintPixelCount +=
                (_canvas as BitmapCanvas).bitmapPixelCount;
          }
          domRenderer.clearDom(rootElement);
          rootElement.append(_canvas.rootElement);
          _canvas.clear();
          picture.recordingCanvas.apply(_canvas);
        },
      ));
    }
  }

  /// Attempts to reuse a canvas from the [_recycledCanvases]. Allocates a new
  /// one if unable to reuse.
  ///
  /// The best recycled canvas is one that:
  ///
  /// - Fits the requested [canvasSize]. This is a hard requirement. Otherwise
  ///   we risk clipping the picture.
  /// - Is the smallest among all possible reusable canvases. This makes canvas
  ///   reuse more efficient.
  /// - Contains no more than twice the number of requested pixels. This makes
  ///   sure we do not use too much memory for small canvases.
  BitmapCanvas _findOrCreateCanvas(ui.Rect bounds) {
    ui.Size canvasSize = bounds.size;
    BitmapCanvas bestRecycledCanvas;
    double lastPixelCount = double.infinity;

    for (int i = 0; i < _recycledCanvases.length; i++) {
      BitmapCanvas candidate = _recycledCanvases[i];
      if (!candidate.isReusable()) {
        continue;
      }

      ui.Size candidateSize = candidate.size;
      double candidatePixelCount = candidateSize.width * candidateSize.height;

      final bool fits = _doesCanvasFitBounds(candidate, bounds);
      final bool isSmaller = candidatePixelCount < lastPixelCount;
      if (fits && isSmaller) {
        bestRecycledCanvas = candidate;
        lastPixelCount = candidatePixelCount;
        final bool fitsExactly = candidateSize.width == canvasSize.width &&
            candidateSize.height == canvasSize.height;
        if (fitsExactly) {
          // No need to keep looking any more.
          break;
        }
      }
    }

    if (bestRecycledCanvas != null) {
      if (_debugExplainSurfaceStats) {
        _surfaceStatsFor(this).reuseCanvasCount++;
      }
      _recycledCanvases.remove(bestRecycledCanvas);
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.inRecycleCount =
            _recycledCanvases.length;
      }
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.reusedCount++;
      }
      bestRecycledCanvas.bounds = bounds;
      return bestRecycledCanvas;
    }

    if (_debugShowCanvasReuseStats) {
      DebugCanvasReuseOverlay.instance.createdCount++;
    }
    final BitmapCanvas canvas = BitmapCanvas(bounds);
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this)
        ..allocateBitmapCanvasCount += 1
        ..allocatedBitmapSizeInPixels =
            canvas.widthInBitmapPixels * canvas.heightInBitmapPixels;
    }
    return canvas;
  }
}

/// A surface that uses a combination of `<canvas>`, `<div>` and `<p>` elements
/// to draw shapes and text.
abstract class PersistedPicture extends PersistedLeafSurface {
  PersistedPicture(Object paintedBy, this.dx, this.dy, this.picture, this.hints)
      : localPaintBounds = picture.recordingCanvas.computePaintBounds(),
        super(paintedBy);

  EngineCanvas _canvas;

  final double dx;
  final double dy;
  final ui.Picture picture;
  final ui.Rect localPaintBounds;
  final int hints;

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-picture');
  }

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;
    if (dx != 0.0 || dy != 0.0) {
      _transform = _transform.clone();
      _transform.translate(dx, dy);
    }
    _globalClip = parent._globalClip;
  }

  /// The rectangle that contains all visible pixels drawn by [picture] inside
  /// the current layer hierarchy in local coordinates.
  ///
  /// This value is a conservative estimate, i.e. it must be big enough to
  /// contain everything that's visible, but it may be bigger than necessary.
  /// Therefore it should not be used for clipping. It is meant to be used for
  /// optimizing canvas allocation.
  ui.Rect get localCullRect => _localCullRect;
  ui.Rect _localCullRect;

  /// Same as [localCullRect] but in screen coordinate system.
  ui.Rect get debugGlobalCullRect => _globalCullRect;
  ui.Rect _globalCullRect;

  /// Computes the canvas paint bounds based on the estimated paint bounds and
  /// the scaling produced by transformations.
  ///
  /// Return `true` if the local cull rect changed, indicating that a repaint
  /// may be required. Returns `false` otherwise. Global cull rect changes do
  /// not necessarily incur repaints. For example, if the layer sub-tree was
  /// translated from one frame to another we may not need to repaint, just
  /// translate the canvas.
  bool _recomputeCullRect() {
    assert(transform != null);
    assert(localPaintBounds != null);
    final ui.Rect globalPaintBounds = localClipRectToGlobalClip(
        localClip: localPaintBounds, transform: transform);

    // The exact cull rect required in screen coordinates.
    ui.Rect tightGlobalCullRect = globalPaintBounds.intersect(_globalClip);

    // The exact cull rect required in local coordinates.
    ui.Rect tightLocalCullRect;
    if (tightGlobalCullRect.width <= 0 || tightGlobalCullRect.height <= 0) {
      tightGlobalCullRect = ui.Rect.zero;
      tightLocalCullRect = ui.Rect.zero;
    } else {
      final Matrix4 invertedTransform =
          Matrix4.fromFloat64List(Float64List(16));

      // TODO(yjbanov): When we move to our own vector math library, rewrite
      //                this to check for the case of simple transform before
      //                inverting. Inversion of simple transforms can be made
      //                much cheaper.
      final double det = invertedTransform.copyInverse(transform);
      if (det == 0) {
        // Determinant is zero, which means the transform is not invertible.
        tightGlobalCullRect = ui.Rect.zero;
        tightLocalCullRect = ui.Rect.zero;
      } else {
        tightLocalCullRect = localClipRectToGlobalClip(
            localClip: tightGlobalCullRect, transform: invertedTransform);
      }
    }

    assert(tightLocalCullRect != null);

    if (_localCullRect == null) {
      // This is the first time we are painting this picture. Use the minimal
      // cull rect size because we don't know what the framework's intention is
      // w.r.t. to the clip. Let's start with the smallest canvas possible to
      // save memory. Subsequent repaints will provide more info later.
      _localCullRect = tightLocalCullRect;
      _globalCullRect = tightGlobalCullRect;
      return true;
    } else if (tightLocalCullRect == ui.Rect.zero) {
      // The clip collapsed into a zero-sized rectangle.
      final bool wasZero = _localCullRect == ui.Rect.zero;
      _localCullRect = ui.Rect.zero;
      _globalCullRect = ui.Rect.zero;

      // If it was already zero, no need to signal cull rect change.
      return !wasZero;
    } else if (rectContainsOther(_localCullRect, tightLocalCullRect)) {
      // The cull rect we computed in the past contains the newly computed cull
      // rect. This can happen, for example, when the picture is being shrunk by
      // a clip when it is scrolled out of the screen. In this case we do not
      // repaint the picture. We just let it be shrunk by the outer clip.
      return false;
    } else {
      // The new cull rect contains area not covered by a previous rect. Perhaps
      // the clip is growing, moving around the picture, or both. In this case
      // a part of the picture may not been painted. We will need to
      // request a new canvas and paint the picture on it. However, this is also
      // a strong signal that the clip will continue growing as typically
      // Flutter uses animated transitions. So instead of allocating the canvas
      // the size of the currently visible area, we try to allocate a canvas of
      // a bigger size. This will prevent any further repaints as future frames
      // will hit the above case where the new cull rect is fully contained
      // within the cull rect we compute now.

      // If any of the borders moved.
      const double kPredictedGrowthFactor = 3.0;
      final double leftwardTrend = kPredictedGrowthFactor *
          math.max(_localCullRect.left - tightLocalCullRect.left, 0);
      final double upwardTrend = kPredictedGrowthFactor *
          math.max(_localCullRect.top - tightLocalCullRect.top, 0);
      final double rightwardTrend = kPredictedGrowthFactor *
          math.max(tightLocalCullRect.right - _localCullRect.right, 0);
      final double bottomwardTrend = kPredictedGrowthFactor *
          math.max(tightLocalCullRect.bottom - _localCullRect.bottom, 0);

      ui.Rect newLocalCullRect = ui.Rect.fromLTRB(
        _localCullRect.left - leftwardTrend,
        _localCullRect.top - upwardTrend,
        _localCullRect.right + rightwardTrend,
        _localCullRect.bottom + bottomwardTrend,
      ).intersect(localPaintBounds);

      final bool localCullRectChanged = _localCullRect != newLocalCullRect;
      _localCullRect = newLocalCullRect;
      _globalCullRect = tightGlobalCullRect;
      return localCullRectChanged;
    }
  }

  /// Number of bitmap pixel painted by this picture.
  ///
  /// If the implementation does not paint onto a bitmap canvas, it should
  /// return zero.
  int get bitmapPixelCount;

  void _applyPaint(EngineCanvas oldCanvas) {
    if (!picture.recordingCanvas.didDraw) {
      _recycleCanvas(oldCanvas);
      domRenderer.clearDom(rootElement);
      return;
    }

    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).paintCount++;
    }

    applyPaint(oldCanvas);
  }

  /// Concrete implementations implement this method to do actual painting.
  void applyPaint(EngineCanvas oldCanvas);

  void _applyTranslate() {
    rootElement.style.transform = 'translate(${dx}px, ${dy}px)';
  }

  @override
  void apply() {
    _recomputeCullRect();
    _applyTranslate();
    _applyPaint(null);
  }

  @override
  void update(PersistedPicture oldSurface) {
    super.update(oldSurface);

    if (dx != oldSurface.dx || dy != oldSurface.dy) {
      _applyTranslate();
    }

    // We need to inherit the previous cull rects to allow [_recomputeCullRect]
    // to be smarter.
    _localCullRect = oldSurface._localCullRect;
    _globalCullRect = oldSurface._globalCullRect;
    if (identical(picture, oldSurface.picture)) {
      // The picture is the same. Attempt to avoid repaint.
      if (_recomputeCullRect()) {
        // Cull rect changed such that a repaint is still necessary.
        _applyPaint(oldSurface._canvas);
      } else {
        // Cull rect did not change, or changed such in a way that does not
        // require a repaint (e.g. it shrunk).
        _canvas = oldSurface._canvas;
      }
    } else {
      // We have a new picture. Repaint.
      _recomputeCullRect();
      _applyPaint(oldSurface._canvas);
    }
  }

  @override
  void retain() {
    super.retain();
    if (_recomputeCullRect()) {
      _applyPaint(_canvas);
    }
  }

  @override
  void recycle() {
    _recycleCanvas(_canvas);
    super.recycle();
  }

  @override
  void debugPrintChildren(StringBuffer buffer, int indent) {
    super.debugPrintChildren(buffer, indent);
    if (rootElement != null && rootElement.firstChild != null) {
      final canvasTag =
          (rootElement.firstChild as html.Element).tagName.toLowerCase();
      final canvasHash = rootElement.firstChild.hashCode;
      buffer.writeln('${'  ' * (indent + 1)}<$canvasTag @$canvasHash />');
    } else if (rootElement != null) {
      buffer.writeln(
          '${'  ' * (indent + 1)}<${rootElement.tagName.toLowerCase()} @$hashCode />');
    } else {
      buffer.writeln('${'  ' * (indent + 1)}<canvas recycled />');
    }
  }
}
