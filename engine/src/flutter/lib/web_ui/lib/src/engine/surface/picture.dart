// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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
const int _kCanvasCacheSize = 30;

/// Canvases available for reuse, capped at [_kCanvasCacheSize].
final List<BitmapCanvas> _recycledCanvases = <BitmapCanvas>[];

/// Reduces recycled canvas list by 50% to reduce bitmap canvas memory use.
void _reduceCanvasMemoryUsage() {
  final int canvasCount = _recycledCanvases.length;
  for (int i = 0; i < canvasCount; i++) {
    _recycledCanvases[i].dispose();
  }
  _recycledCanvases.clear();
}

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
  if (canvas is BitmapCanvas) {
    if (canvas.isReusable()) {
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
    } else {
      canvas.dispose();
    }
  }
}


/// Signature of a function that instantiates a [PersistedPicture].
typedef PersistedPictureFactory = PersistedPicture Function(
  double dx,
  double dy,
  ui.Picture picture,
  int hints,
);

/// Function used by the [SceneBuilder] to instantiate a picture layer.
PersistedPictureFactory persistedPictureFactory = standardPictureFactory;

/// Instantiates an implementation of a picture layer that uses DOM, CSS, and
/// 2D canvas for painting.
PersistedStandardPicture standardPictureFactory(
    double dx, double dy, ui.Picture picture, int hints) {
  return PersistedStandardPicture(dx, dy, picture, hints);
}

/// Instantiates an implementation of a picture layer that uses CSS Paint API
/// (part of Houdini) for painting.
PersistedHoudiniPicture houdiniPictureFactory(
    double dx, double dy, ui.Picture picture, int hints) {
  return PersistedHoudiniPicture(dx, dy, picture, hints);
}

class PersistedHoudiniPicture extends PersistedPicture {
  PersistedHoudiniPicture(double dx, double dy, ui.Picture picture, int hints)
      : super(dx, dy, picture, hints) {
    if (!_cssPainterRegistered) {
      _registerCssPainter();
    }
  }

  static bool _cssPainterRegistered = false;

  @override
  double matchForUpdate(PersistedPicture existingSurface) {
    // Houdini is display list-based so all pictures are cheap to repaint.
    // However, if the picture hasn't changed at all then it's completely
    // free.
    return existingSurface.picture == picture ? 0.0 : 1.0;
  }

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
        '/packages/flutter_web_ui/assets/houdini_painter.js',
      ],
    );
  }

  /// Houdini does not paint to bitmap.
  @override
  int get bitmapPixelCount => 0;

  @override
  void applyPaint(EngineCanvas oldCanvas) {
    _recycleCanvas(oldCanvas);
    final HoudiniCanvas canvas = HoudiniCanvas(_optimalLocalCullRect);
    _canvas = canvas;
    domRenderer.clearDom(rootElement);
    rootElement.append(_canvas.rootElement);
    picture.recordingCanvas.apply(_canvas, _optimalLocalCullRect);
    canvas.commit();
  }
}

class PersistedStandardPicture extends PersistedPicture {
  PersistedStandardPicture(double dx, double dy, ui.Picture picture, int hints)
      : super(dx, dy, picture, hints);

  @override
  double matchForUpdate(PersistedStandardPicture existingSurface) {
    if (existingSurface.picture == picture) {
      // Picture is the same, return perfect score.
      return 0.0;
    }

    if (!existingSurface.picture.recordingCanvas.didDraw) {
      // The previous surface didn't draw anything and therefore has no
      // resources to reuse.
      return 1.0;
    }

    final bool didRequireBitmap =
        existingSurface.picture.recordingCanvas.hasArbitraryPaint;
    final bool requiresBitmap = picture.recordingCanvas.hasArbitraryPaint;
    if (didRequireBitmap != requiresBitmap) {
      // Switching canvas types is always expensive.
      return 1.0;
    } else if (!requiresBitmap) {
      // Currently DomCanvas is always expensive to repaint, as we always throw
      // out all the DOM we rendered before. This may change in the future, at
      // which point we may return other values here.
      return 1.0;
    } else {
      final BitmapCanvas oldCanvas = existingSurface._canvas;
      if (!oldCanvas.doesFitBounds(_exactLocalCullRect)) {
        // The canvas needs to be resized before painting.
        return 1.0;
      } else {
        final int newPixelCount = BitmapCanvas._widthToPhysical(_exactLocalCullRect.width)
             * BitmapCanvas._heightToPhysical(_exactLocalCullRect.height);
        final int oldPixelCount =
            oldCanvas._widthInBitmapPixels * oldCanvas._heightInBitmapPixels;

        if (oldPixelCount == 0) {
          return 1.0;
        }

        final double pixelCountRatio = newPixelCount / oldPixelCount;
        assert(0 <= pixelCountRatio && pixelCountRatio <= 1.0,
            'Invalid pixel count ratio $pixelCountRatio');
        return 1.0 - pixelCountRatio;
      }
    }
  }

  @override
  Matrix4 get localTransformInverse => null;

  @override
  int get bitmapPixelCount {
    if (_canvas is! BitmapCanvas) {
      return 0;
    }

    final BitmapCanvas bitmapCanvas = _canvas;
    return bitmapCanvas.bitmapPixelCount;
  }

  FrameReference<bool> _didApplyPaint = FrameReference<bool>(false);

  @override
  void applyPaint(EngineCanvas oldCanvas) {
    if (picture.recordingCanvas.hasArbitraryPaint) {
      _applyBitmapPaint(oldCanvas);
    } else {
      _applyDomPaint(oldCanvas);
    }
    _didApplyPaint.value = true;
  }

  void _applyDomPaint(EngineCanvas oldCanvas) {
    _recycleCanvas(oldCanvas);
    _canvas = DomCanvas();
    domRenderer.clearDom(rootElement);
    rootElement.append(_canvas.rootElement);
    picture.recordingCanvas.apply(_canvas, _optimalLocalCullRect);
  }

  void _applyBitmapPaint(EngineCanvas oldCanvas) {
    if (oldCanvas is BitmapCanvas &&
        oldCanvas.doesFitBounds(_optimalLocalCullRect) &&
        oldCanvas.isReusable()) {
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.keptCount++;
      }
      oldCanvas.bounds = _optimalLocalCullRect;
      _canvas = oldCanvas;
      _canvas.clear();
      picture.recordingCanvas.apply(_canvas, _optimalLocalCullRect);
    } else {
      // We can't use the old canvas because the size has changed, so we put
      // it in a cache for later reuse.
      _recycleCanvas(oldCanvas);
      // We cannot paint immediately because not all canvases that we may be
      // able to reuse have been released yet. So instead we enqueue this
      // picture to be painted after the update cycle is done syncing the layer
      // tree then reuse canvases that were freed up.
      _paintQueue.add(_PaintRequest(
        canvasSize: _optimalLocalCullRect.size,
        paintCallback: () {
          _canvas = _findOrCreateCanvas(_optimalLocalCullRect);
          if (_debugExplainSurfaceStats) {
            final BitmapCanvas bitmapCanvas = _canvas;
            _surfaceStatsFor(this).paintPixelCount +=
                bitmapCanvas.bitmapPixelCount;
          }
          domRenderer.clearDom(rootElement);
          rootElement.append(_canvas.rootElement);
          _canvas.clear();
          picture.recordingCanvas.apply(_canvas, _optimalLocalCullRect);
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
    final ui.Size canvasSize = bounds.size;
    BitmapCanvas bestRecycledCanvas;
    double lastPixelCount = double.infinity;
    for (int i = 0; i < _recycledCanvases.length; i++) {
      final BitmapCanvas candidate = _recycledCanvases[i];
      if (!candidate.isReusable()) {
        continue;
      }

      final ui.Size candidateSize = candidate.size;
      final double candidatePixelCount =
          candidateSize.width * candidateSize.height;

      final bool fits = candidate.doesFitBounds(bounds);
      final bool isSmaller = candidatePixelCount < lastPixelCount;
      if (fits && isSmaller) {
        // [isTooSmall] is used to make sure that a small picture doesn't
        // reuse and hold onto memory of a large canvas.
        final double requestedPixelCount = bounds.width * bounds.height;
        final bool isTooSmall = isSmaller &&
            requestedPixelCount > 1 &&
            (candidatePixelCount / requestedPixelCount) > 4;
        if (!isTooSmall) {
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
            canvas._widthInBitmapPixels * canvas._heightInBitmapPixels;
    }
    return canvas;
  }
}

/// A surface that uses a combination of `<canvas>`, `<div>` and `<p>` elements
/// to draw shapes and text.
abstract class PersistedPicture extends PersistedLeafSurface {
  PersistedPicture(this.dx, this.dy, this.picture, this.hints)
      : localPaintBounds = picture.recordingCanvas.pictureBounds;

  EngineCanvas _canvas;

  /// Returns the canvas used by this picture layer.
  ///
  /// Useful for tests.
  EngineCanvas get debugCanvas => _canvas;

  final double dx;
  final double dy;
  final EnginePicture picture;
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
    _computeExactCullRects();
  }

  /// The rectangle that contains all visible pixels drawn by [picture] inside
  /// the current layer hierarchy in local coordinates.
  ///
  /// This value is a conservative estimate, i.e. it must be big enough to
  /// contain everything that's visible, but it may be bigger than necessary.
  /// Therefore it should not be used for clipping. It is meant to be used for
  /// optimizing canvas allocation.
  ui.Rect get optimalLocalCullRect => _optimalLocalCullRect;
  ui.Rect _optimalLocalCullRect;

  /// Same as [optimalLocalCullRect] but in screen coordinate system.
  ui.Rect get debugExactGlobalCullRect => _exactGlobalCullRect;
  ui.Rect _exactGlobalCullRect;

  ui.Rect _exactLocalCullRect;

  /// Computes the canvas paint bounds based on the estimated paint bounds and
  /// the scaling produced by transformations.
  ///
  /// Return `true` if the local cull rect changed, indicating that a repaint
  /// may be required. Returns `false` otherwise. Global cull rect changes do
  /// not necessarily incur repaints. For example, if the layer sub-tree was
  /// translated from one frame to another we may not need to repaint, just
  /// translate the canvas.
  void _computeExactCullRects() {
    assert(transform != null);
    assert(localPaintBounds != null);

    if (parent._projectedClip == null) {
      // Compute and cache chain of clipping bounds on parent of picture since
      // parent may include multiple pictures so it can be reused by all
      // child pictures.
      ui.Rect bounds;
      PersistedSurface parentSurface = parent;
      final Matrix4 clipTransform = Matrix4.identity();
      while (parentSurface != null) {
        final ui.Rect localClipBounds = parentSurface._localClipBounds;
        if (localClipBounds != null) {
          if (bounds == null) {
            bounds = transformRect(clipTransform, localClipBounds);
          } else {
            bounds =
                bounds.intersect(transformRect(clipTransform, localClipBounds));
          }
        }
        final Matrix4 localInverse = parentSurface.localTransformInverse;
        if (localInverse != null && !localInverse.isIdentity()) {
          clipTransform.multiply(localInverse);
        }
        parentSurface = parentSurface.parent;
      }
      if (bounds != null && (bounds.width <= 0 || bounds.height <= 0)) {
        bounds = ui.Rect.zero;
      }
      // Cache projected clip on parent.
      parent._projectedClip = bounds;
    }
    // Intersect localPaintBounds with parent projected clip to calculate
    // and cache [_exactLocalCullRect].
    if (parent._projectedClip == null) {
      _exactLocalCullRect = localPaintBounds;
    } else {
      _exactLocalCullRect = localPaintBounds.intersect(parent._projectedClip);
    }
    if (_exactLocalCullRect.width <= 0 || _exactLocalCullRect.height <= 0) {
      _exactLocalCullRect = ui.Rect.zero;
      _exactGlobalCullRect = ui.Rect.zero;
    } else {
      assert(() {
        _exactGlobalCullRect = transformRect(transform, _exactLocalCullRect);
        return true;
      }());
    }
  }

  bool _computeOptimalCullRect(PersistedPicture oldSurface) {
    assert(_exactLocalCullRect != null);

    if (oldSurface == null || !oldSurface.picture.recordingCanvas.didDraw) {
      // First useful paint.
      _optimalLocalCullRect = _exactLocalCullRect;
      return true;
    }

    assert(oldSurface._optimalLocalCullRect != null);

    final bool surfaceBeingRetained = identical(oldSurface, this);
    final ui.Rect oldOptimalLocalCullRect = surfaceBeingRetained
        ? _optimalLocalCullRect
        : oldSurface._optimalLocalCullRect;

    if (_exactLocalCullRect == ui.Rect.zero) {
      // The clip collapsed into a zero-sized rectangle. If it was already zero,
      // no need to signal cull rect change.
      _optimalLocalCullRect = ui.Rect.zero;
      return oldOptimalLocalCullRect != ui.Rect.zero;
    }

    if (rectContainsOther(oldOptimalLocalCullRect, _exactLocalCullRect)) {
      // The cull rect we computed in the past contains the newly computed cull
      // rect. This can happen, for example, when the picture is being shrunk by
      // a clip when it is scrolled out of the screen. In this case we do not
      // repaint the picture. We just let it be shrunk by the outer clip.
      _optimalLocalCullRect = oldOptimalLocalCullRect;
      return false;
    }

    // The new cull rect contains area not covered by a previous rect. Perhaps
    // the clip is growing, moving around the picture, or both. In this case
    // a part of the picture may not have been painted. We will need to
    // request a new canvas and paint the picture on it. However, this is also
    // a strong signal that the clip will continue growing as typically
    // Flutter uses animated transitions. So instead of allocating the canvas
    // the size of the currently visible area, we try to allocate a canvas of
    // a bigger size. This will prevent any further repaints as future frames
    // will hit the above case where the new cull rect is fully contained
    // within the cull rect we compute now.

    // Compute the delta, by which each of the side of the clip rect has "moved"
    // since the last time we updated the cull rect.
    final double leftwardDelta = oldOptimalLocalCullRect.left - _exactLocalCullRect.left;
    final double upwardDelta = oldOptimalLocalCullRect.top - _exactLocalCullRect.top;
    final double rightwardDelta = _exactLocalCullRect.right - oldOptimalLocalCullRect.right;
    final double bottomwardDelta = _exactLocalCullRect.bottom - oldOptimalLocalCullRect.bottom;

    // Compute the new optimal rect to paint into.
    final ui.Rect newLocalCullRect = ui.Rect.fromLTRB(
      _exactLocalCullRect.left - _predictTrend(leftwardDelta, _exactLocalCullRect.width),
      _exactLocalCullRect.top - _predictTrend(upwardDelta, _exactLocalCullRect.height),
      _exactLocalCullRect.right + _predictTrend(rightwardDelta, _exactLocalCullRect.width),
      _exactLocalCullRect.bottom + _predictTrend(bottomwardDelta, _exactLocalCullRect.height),
    ).intersect(localPaintBounds);

    final bool localCullRectChanged = _optimalLocalCullRect != newLocalCullRect;
    _optimalLocalCullRect = newLocalCullRect;
    return localCullRectChanged;
  }

  /// Predicts the delta a particular side of a clip rect will move given the
  /// [delta] it moved by last, and the respective [extent] (width or height)
  /// of the clip.
  static double _predictTrend(double delta, double extent) {
    if (delta <= 0.0) {
      // Shrinking. Give it 10% of the extent in case the trend is reversed.
      return extent * 0.1;
    } else {
      // Growing. Predict 10 more frames of similar deltas. Give it at least
      // 50% of the extent (protect from extremely slow growth trend such as
      // slow scrolling). Give no more than the full extent (protects from
      // fast scrolling that could lead to overallocation).
      return math.min(
        math.max(extent * 0.5, delta * 10.0),
        extent,
      );
    }
  }

  /// Number of bitmap pixel painted by this picture.
  ///
  /// If the implementation does not paint onto a bitmap canvas, it should
  /// return zero.
  int get bitmapPixelCount;

  void _applyPaint(PersistedPicture oldSurface) {
    final EngineCanvas oldCanvas = oldSurface?._canvas;
    if (!picture.recordingCanvas.didDraw) {
      _recycleCanvas(oldCanvas);
      domRenderer.clearDom(rootElement);
      return;
    }

    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).paintCount++;
    }

    assert(_optimalLocalCullRect != null);
    applyPaint(oldCanvas);
  }

  /// Concrete implementations implement this method to do actual painting.
  void applyPaint(EngineCanvas oldCanvas);

  void _applyTranslate() {
    rootElement.style.transform = 'translate(${dx}px, ${dy}px)';
  }

  @override
  void apply() {
    _applyTranslate();
    _applyPaint(null);
  }

  @override
  void build() {
    _computeOptimalCullRect(null);
    super.build();
  }

  @override
  void update(PersistedPicture oldSurface) {
    super.update(oldSurface);

    if (dx != oldSurface.dx || dy != oldSurface.dy) {
      _applyTranslate();
    }

    final bool cullRectChangeRequiresRepaint =
        _computeOptimalCullRect(oldSurface);
    if (identical(picture, oldSurface.picture)) {
      // The picture is the same. Attempt to avoid repaint.
      if (cullRectChangeRequiresRepaint) {
        // Cull rect changed such that a repaint is still necessary.
        _applyPaint(oldSurface);
      } else {
        // Cull rect did not change, or changed such in a way that does not
        // require a repaint (e.g. it shrunk).
        _canvas = oldSurface._canvas;
      }
    } else {
      // We have a new picture. Repaint.
      _applyPaint(oldSurface);
    }
  }

  @override
  void retain() {
    super.retain();
    final bool cullRectChangeRequiresRepaint = _computeOptimalCullRect(this);
    if (cullRectChangeRequiresRepaint) {
      _applyPaint(this);
    }
  }

  @override
  void discard() {
    _recycleCanvas(_canvas);
    super.discard();
  }

  @override
  void debugPrintChildren(StringBuffer buffer, int indent) {
    super.debugPrintChildren(buffer, indent);
    if (rootElement != null && rootElement.firstChild != null) {
      final html.Element firstChild = rootElement.firstChild;
      final String canvasTag = firstChild.tagName.toLowerCase();
      final int canvasHash = rootElement.firstChild.hashCode;
      buffer.writeln('${'  ' * (indent + 1)}<$canvasTag @$canvasHash />');
    } else if (rootElement != null) {
      buffer.writeln(
          '${'  ' * (indent + 1)}<${rootElement.tagName.toLowerCase()} @$hashCode />');
    } else {
      buffer.writeln('${'  ' * (indent + 1)}<recycled-canvas />');
    }
  }

  @override
  void debugValidate(List<String> validationErrors) {
    super.debugValidate(validationErrors);

    if (picture.recordingCanvas.didDraw) {
      if (debugCanvas == null) {
        validationErrors
            .add('$runtimeType has non-trivial picture but it has null canvas');
      }
      if (_optimalLocalCullRect == null) {
        validationErrors.add('$runtimeType has null _optimalLocalCullRect');
      }
      if (_exactGlobalCullRect == null) {
        validationErrors.add('$runtimeType has null _exactGlobalCullRect');
      }
      if (_exactLocalCullRect == null) {
        validationErrors.add('$runtimeType has null _exactLocalCullRect');
      }
    }
  }
}
