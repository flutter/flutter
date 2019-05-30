// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// When `true` prints statistics about what happened to the surface tree when
/// it was composited.
///
/// Also paints an on-screen overlay with the numbers visualized as a timeline.
const _debugExplainSurfaceStats = false;

/// When `true` shows an overlay that contains stats about canvas reuse.
///
/// The overlay also includes a button to reset the stats.
const _debugShowCanvasReuseStats = false;

/// When `true` renders the outlines of clip layers on the screen instead of
/// clipping the contents.
///
/// This is useful when visually debugging clipping behavior.
bool debugShowClipLayers = false;

/// The threshold for the canvas pixel count to screen pixel count ratio, beyond
/// which in debug mode a warning is issued to the console.
///
/// As we improve canvas utilization we should decrease this number. It is
/// unlikely that we will hit 1.0, but something around 3.0 should be
/// reasonable.
const _kScreenPixelRatioWarningThreshold = 6.0;

int _debugFrameNumber = 0;

/// Performs any outstanding painting work enqueued by [PersistedPicture]s.
void commitScene(PersistedScene scene) {
  assert(() {
    _debugFrameNumber++;
    return true;
  }());
  if (_paintQueue.isNotEmpty) {
    if (_paintQueue.length > 1) {
      // Sort paint requests in decreasing canvas size order. Paint requests
      // attempt to reuse canvases. For efficiency we want the biggest pictures
      // to find canvases before the smaller ones claim them.
      _paintQueue.sort((_PaintRequest a, _PaintRequest b) {
        final double aSize = a.canvasSize.height * a.canvasSize.width;
        final double bSize = b.canvasSize.height * b.canvasSize.width;
        return bSize.compareTo(aSize);
      });
    }

    for (_PaintRequest request in _paintQueue) {
      request.paintCallback();
    }
    _paintQueue = <_PaintRequest>[];
  }

  // Reset reuse strategy back to matching. Retain requests are one-time. In
  // order to retain the same layer again the framework must call addRetained
  // again. If addRetained is not called the engine will recycle the surfaces.
  // Calling addRetained on a layer whose surface has been recycled will
  // rebuild the surfaces as if it was a brand new layer.
  if (_retainedSurfaces.isNotEmpty) {
    for (int i = 0; i < _retainedSurfaces.length; i++) {
      _retainedSurfaces[i].reuseStrategy = PersistedSurfaceReuseStrategy.match;
    }
    _retainedSurfaces = <PersistedSurface>[];
  }
  if (_debugExplainSurfaceStats) {
    _debugPrintSurfaceStats(scene, _debugFrameNumber);
    _debugRepaintSurfaceStatsOverlay(scene);
  }
  assert(() {
    final validationErrors = <String>[];
    scene.debugValidate(validationErrors);
    if (validationErrors.isNotEmpty) {
      print('ENGINE LAYER TREE INCONSISTENT:\n'
          '${validationErrors.map((e) => '  - $e\n').join()}');
    }
    return true;
  }());
  if (_debugExplainSurfaceStats) {
    _surfaceStats = <PersistedSurface, _DebugSurfaceStats>{};
  }
}

/// Discards information about previously rendered frames, including DOM
/// elements and cached canvases.
///
/// After calling this function new canvases will be created for the
/// subsequent scene. This is useful when tests need predictable canvas
/// sizes. If the cache is not cleared, then canvases allocated in one test
/// may be reused in another test.
void debugForgetFrameScene() {
  _clipIdCounter = 0;
  _recycledCanvases.clear();
}

/// Surfaces that were retained this frame.
///
/// Surfaces should be added to this list directly. Instead, if a surface needs
/// to be retained call [_retainSurface].
List<PersistedSurface> get debugRetainedSurfaces => _retainedSurfaces;
List<PersistedSurface> _retainedSurfaces = <PersistedSurface>[];

/// Marks the subtree of surfaces rooted at [surface] as retained.
void _retainSurface(PersistedSurface surface) {
  _retainedSurfaces.add(surface);
  surface.retain();
}

/// Maps every surface currently active on the screen to debug statistics.
Map<PersistedSurface, _DebugSurfaceStats> _surfaceStats =
    <PersistedSurface, _DebugSurfaceStats>{};

List<Map<PersistedSurface, _DebugSurfaceStats>> _surfaceStatsTimeline =
    <Map<PersistedSurface, _DebugSurfaceStats>>[];

/// Returns debug statistics for the given [surface].
_DebugSurfaceStats _surfaceStatsFor(PersistedSurface surface) {
  if (!_debugExplainSurfaceStats) {
    throw new Exception(
        '_surfaceStatsFor is only available when _debugExplainSurfaceStats is set to true.');
  }
  return _surfaceStats.putIfAbsent(surface, () => _DebugSurfaceStats(surface));
}

/// Compositor information collected for one frame useful for assessing the
/// efficiency of constructing the frame.
///
/// This information is only available in debug mode.
///
/// For stats pertaining to a single surface the numeric counter fields are
/// typically either 0 or 1. For aggregated stats, the numbers can be >1.
class _DebugSurfaceStats {
  _DebugSurfaceStats(this.surface);

  /// The surface these stats are for, or `null` if these are aggregated stats.
  final PersistedSurface surface;

  /// How many times a surface was retained from a previously rendered frame.
  int retainSurfaceCount = 0;

  /// How many times a surface reused an HTML element from a previously rendered
  /// surface.
  int reuseElementCount = 0;

  /// If a surface is a [PersistedPicture], how many times it painted.
  int paintCount = 0;

  /// If a surface is a [PersistedPicture], how many pixels it painted.
  int paintPixelCount = 0;

  /// If a surface is a [PersistedPicture], how many times it reused a
  /// previously allocated `<canvas>` element when it painted.
  int reuseCanvasCount = 0;

  /// If a surface is a [PersistedPicture], how many times it allocated a new
  /// bitmap canvas.
  int allocateBitmapCanvasCount = 0;

  /// If a surface is a [PersistedPicture], how many pixels it allocated for
  /// the bitmap.
  ///
  /// For aggregated stats, this is the total sum of all pixels across all
  /// canvases.
  int allocatedBitmapSizeInPixels = 0;

  /// The number of HTML DOM nodes a surface allocated.
  ///
  /// For aggregated stats, this is the total sum of all DOM nodes across all
  /// surfaces.
  int allocatedDomNodeCount = 0;

  /// Adds all counters of [oneSurfaceStats] into this object.
  void aggregate(_DebugSurfaceStats oneSurfaceStats) {
    retainSurfaceCount += oneSurfaceStats.retainSurfaceCount;
    reuseElementCount += oneSurfaceStats.reuseElementCount;
    paintCount += oneSurfaceStats.paintCount;
    paintPixelCount += oneSurfaceStats.paintPixelCount;
    reuseCanvasCount += oneSurfaceStats.reuseCanvasCount;
    allocateBitmapCanvasCount += oneSurfaceStats.allocateBitmapCanvasCount;
    allocatedBitmapSizeInPixels += oneSurfaceStats.allocatedBitmapSizeInPixels;
    allocatedDomNodeCount += oneSurfaceStats.allocatedDomNodeCount;
  }
}

html.CanvasRenderingContext2D _debugSurfaceStatsOverlayCtx;

void _debugRepaintSurfaceStatsOverlay(PersistedScene scene) {
  final int overlayWidth = html.window.innerWidth;
  final rowHeight = 30;
  final rowCount = 4;
  final int overlayHeight = rowHeight * rowCount;
  final int strokeWidth = 2;

  _surfaceStatsTimeline.add(_surfaceStats);

  while (_surfaceStatsTimeline.length > (overlayWidth / strokeWidth)) {
    _surfaceStatsTimeline.removeAt(0);
  }

  if (_debugSurfaceStatsOverlayCtx == null) {
    final html.CanvasElement _debugSurfaceStatsOverlay = html.CanvasElement(
      width: overlayWidth,
      height: overlayHeight,
    );
    _debugSurfaceStatsOverlay.style
      ..position = 'fixed'
      ..left = '0'
      ..top = '0'
      ..zIndex = '1000'
      ..opacity = '0.8';
    _debugSurfaceStatsOverlayCtx = _debugSurfaceStatsOverlay.context2D;
    html.document.body.append(_debugSurfaceStatsOverlay);
  }

  _debugSurfaceStatsOverlayCtx
    ..fillStyle = 'black'
    ..beginPath()
    ..rect(0, 0, overlayWidth, overlayHeight)
    ..fill();

  final double physicalScreenWidth =
      html.window.innerWidth * html.window.devicePixelRatio;
  final double physicalScreenHeight =
      html.window.innerHeight * html.window.devicePixelRatio;
  final double physicsScreenPixelCount =
      physicalScreenWidth * physicalScreenHeight;

  final int totalDomNodeCount = scene.rootElement.querySelectorAll('*').length;

  for (int i = 0; i < _surfaceStatsTimeline.length; i++) {
    final _DebugSurfaceStats totals = _DebugSurfaceStats(null);
    int pixelCount = 0;
    _surfaceStatsTimeline[i]
        .values
        .forEach((_DebugSurfaceStats oneSurfaceStats) {
      totals.aggregate(oneSurfaceStats);
      if (oneSurfaceStats.surface is PersistedPicture) {
        final PersistedPicture picture = oneSurfaceStats.surface;
        pixelCount += picture.bitmapPixelCount;
      }
    });

    final double repaintRate = totals.paintPixelCount / pixelCount;
    final double domAllocationRate =
        totals.allocatedDomNodeCount / totalDomNodeCount;
    final double bitmapAllocationRate =
        totals.allocatedBitmapSizeInPixels / physicsScreenPixelCount;
    final double surfaceRetainRate =
        totals.retainSurfaceCount / _surfaceStatsTimeline[i].length;

    // Repaints
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'red'
      ..beginPath()
      ..moveTo(strokeWidth * i, rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (1 - repaintRate))
      ..stroke();

    // DOM allocations
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'red'
      ..beginPath()
      ..moveTo(strokeWidth * i, 2 * rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (2 - domAllocationRate))
      ..stroke();

    // Bitmap allocations
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'red'
      ..beginPath()
      ..moveTo(strokeWidth * i, 3 * rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (3 - bitmapAllocationRate))
      ..stroke();

    // Surface retentions
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'green'
      ..beginPath()
      ..moveTo(strokeWidth * i, 4 * rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (4 - surfaceRetainRate))
      ..stroke();
  }

  _debugSurfaceStatsOverlayCtx
    ..font = 'normal normal 14px sans-serif'
    ..fillStyle = 'white'
    ..fillText('Repaint rate', 5, rowHeight - 5)
    ..fillText('DOM alloc rate', 5, 2 * rowHeight - 5)
    ..fillText('Bitmap alloc rate', 5, 3 * rowHeight - 5)
    ..fillText('Retain rate', 5, 4 * rowHeight - 5);

  for (int i = 1; i <= rowCount; i++) {
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = 1
      ..strokeStyle = 'blue'
      ..beginPath()
      ..moveTo(0, overlayHeight - rowHeight * i)
      ..lineTo(overlayWidth, overlayHeight - rowHeight * i)
      ..stroke();
  }
}

/// Prints debug statistics for the current frame to the console.
void _debugPrintSurfaceStats(PersistedScene scene, int frameNumber) {
  int pictureCount = 0;
  int paintCount = 0;

  int bitmapCanvasCount = 0;
  int bitmapReuseCount = 0;
  int bitmapAllocationCount = 0;
  int bitmapPaintCount = 0;
  int bitmapPixelsAllocated = 0;

  int domCanvasCount = 0;
  int domPaintCount = 0;

  int surfaceRetainCount = 0;
  int elementReuseCount = 0;

  int totalAllocatedDomNodeCount = 0;

  void countReusesRecursively(PersistedSurface surface) {
    _DebugSurfaceStats stats = _surfaceStatsFor(surface);
    assert(stats != null);

    surfaceRetainCount += stats.retainSurfaceCount;
    elementReuseCount += stats.reuseElementCount;
    totalAllocatedDomNodeCount += stats.allocatedDomNodeCount;

    if (surface is PersistedStandardPicture) {
      pictureCount += 1;
      paintCount += stats.paintCount;

      if (surface._canvas is DomCanvas) {
        domCanvasCount++;
        domPaintCount += stats.paintCount;
      }

      if (surface._canvas is BitmapCanvas) {
        bitmapCanvasCount++;
        bitmapPaintCount += stats.paintCount;
      }

      bitmapReuseCount += stats.reuseCanvasCount;
      bitmapAllocationCount += stats.allocateBitmapCanvasCount;
      bitmapPixelsAllocated += stats.allocatedBitmapSizeInPixels;
    }

    surface.visitChildren(countReusesRecursively);
  }

  scene.visitChildren(countReusesRecursively);

  final StringBuffer buf = StringBuffer();
  buf
    ..writeln(
        '---------------------- FRAME #${frameNumber} -------------------------')
    ..writeln('Surfaces retained: $surfaceRetainCount')
    ..writeln('Elements reused: $elementReuseCount')
    ..writeln('Elements allocated: $totalAllocatedDomNodeCount')
    ..writeln('Pictures: $pictureCount')
    ..writeln('  Painted: $paintCount')
    ..writeln('  Skipped painting: ${pictureCount - paintCount}')
    ..writeln('DOM canvases:')
    ..writeln('  Painted: $domPaintCount')
    ..writeln('  Skipped painting: ${domCanvasCount - domPaintCount}')
    ..writeln('Bitmap canvases: ${bitmapCanvasCount}')
    ..writeln('  Painted: $bitmapPaintCount')
    ..writeln('  Skipped painting: ${bitmapCanvasCount - bitmapPaintCount}')
    ..writeln('  Reused: $bitmapReuseCount')
    ..writeln('  Allocated: $bitmapAllocationCount')
    ..writeln('  Allocated pixels: $bitmapPixelsAllocated')
    ..writeln('  Available for reuse: ${_recycledCanvases.length}');

  // A microtask will fire after the DOM is flushed, letting us probe into
  // actual <canvas> tags.
  scheduleMicrotask(() {
    final canvasElements = html.document.querySelectorAll('canvas');
    final StringBuffer canvasInfo = StringBuffer();
    final int pixelCount = canvasElements
        .cast<html.CanvasElement>()
        .map<int>((html.CanvasElement e) {
      final int pixels = e.width * e.height;
      canvasInfo.writeln('    - ${e.width} x ${e.height} = ${pixels} pixels');
      return pixels;
    }).fold(0, (int total, int pixels) => total + pixels);
    final double physicalScreenWidth =
        html.window.innerWidth * html.window.devicePixelRatio;
    final double physicalScreenHeight =
        html.window.innerHeight * html.window.devicePixelRatio;
    final double physicsScreenPixelCount =
        physicalScreenWidth * physicalScreenHeight;
    final double screenPixelRatio = pixelCount / physicsScreenPixelCount;
    final String screenDescription =
        '1 screen is ${physicalScreenWidth} x ${physicalScreenHeight} = ${physicsScreenPixelCount} pixels';
    final String canvasPixelDescription =
        '${pixelCount} (${screenPixelRatio.toStringAsFixed(2)} x screens';
    buf
      ..writeln('  Elements: ${canvasElements.length}')
      ..writeln(canvasInfo)
      ..writeln('  Pixels: $canvasPixelDescription; $screenDescription)')
      ..writeln('-----------------------------------------------------------');
    bool screenPixelRatioTooHigh =
        screenPixelRatio > _kScreenPixelRatioWarningThreshold;
    if (screenPixelRatioTooHigh) {
      print(
          'WARNING: pixel/screen ratio too high (${screenPixelRatio.toStringAsFixed(2)}x)');
    }
    print(buf);
  });
}

/// Signature of a function that receives a [PersistedSurface].
///
/// This is used to traverse surfaces using [PersistedSurface.visitChildren].
typedef PersistedSurfaceVisitor = void Function(PersistedSurface);

/// Controls the algorithm used to reuse a previously rendered surface.
enum PersistedSurfaceReuseStrategy {
  /// This strategy matches a surface to a previously rendered surface using
  /// its type and descendants.
  match,

  /// This strategy reuses the surface as is.
  ///
  /// This strategy relies on Flutter's retained-mode layer system (see
  /// [EngineLayer]).
  retain,
}

/// A node in the tree built by [SceneBuilder] that contains information used to
/// compute the fewest amount of mutations necessary to update the browser DOM.
abstract class PersistedSurface implements ui.EngineLayer {
  /// Creates a persisted surface.
  ///
  /// [paintedBy] points to the object that painted this surface.
  PersistedSurface(this.paintedBy);

  /// The strategy that should be used when attempting to reuse the resources
  /// owned by this surface.
  PersistedSurfaceReuseStrategy reuseStrategy =
      PersistedSurfaceReuseStrategy.match;

  /// The root element that renders this surface to the DOM.
  ///
  /// This element can be reused across frames. See also, [childContainer],
  /// which is the element used to manage child nodes.
  html.Element rootElement;

  /// The element that contains child surface elements.
  ///
  /// By default this is the same as the [rootElement]. However, specialized
  /// surface implementations may choose to override this and provide a
  /// different element for nesting children.
  html.Element get childContainer => rootElement;

  /// This surface's immediate parent.
  PersistedContainerSurface parent;

  /// The render object that painted this surface.
  ///
  /// Used to find a surface in the previous frame whose [element] can be
  /// reused.
  final Object paintedBy;

  /// Render objects that painted something in the subtree rooted at this node.
  ///
  /// Used to find a surface in the previous frame whose [element] can be
  /// reused.
  // TODO(yjbanov): consider benchmarking and potentially using a list that
  //                compiles to JSArray. We may never have duplicates here by
  //                construction. The only other use-case for Set is to perform
  //                an order-agnostic comparison.
  Set<Object> _descendants;

  /// Visits immediate children.
  ///
  /// Does not recurse.
  void visitChildren(PersistedSurfaceVisitor visitor);

  /// Creates a new element and sets the necessary HTML and CSS attributes.
  ///
  /// This is called when we failed to locate an existing DOM element to reuse,
  /// such as on the very first frame.
  @protected
  @mustCallSuper
  void build() {
    assert(rootElement == null);
    assert(reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    recomputeTransformAndClip();
    rootElement = createElement();
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).allocatedDomNodeCount++;
    }
    apply();
  }

  /// Instructs this surface to adopt HTML DOM elements of another surface.
  ///
  /// This is done for efficiency. Instead of creating new DOM elements on every
  /// frame, we reuse old ones as much as possible. This method should only be
  /// called when [isTotalMatchFor] returns true for the [oldSurface]. Otherwise
  /// adopting the [oldSurface]'s elements could lead to correctness issues.
  @protected
  @mustCallSuper
  void adoptElements(covariant PersistedSurface oldSurface) {
    assert(oldSurface.rootElement != null);
    rootElement = oldSurface.rootElement;
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).reuseElementCount++;
    }
  }

  /// Updates the attributes of this surface's element.
  ///
  /// Attempts to reuse [oldSurface]'s DOM element, if possible. Otherwise,
  /// creates a new element by calling [build].
  @protected
  @mustCallSuper
  void update(covariant PersistedSurface oldSurface) {
    assert(oldSurface != null);
    assert(!identical(oldSurface, this));
    assert(reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    assert(oldSurface.reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    assert(isTotalMatchFor(oldSurface) || isFuzzyMatchFor(oldSurface));

    recomputeTransformAndClip();
    adoptElements(oldSurface);

    // We took ownership of the old element.
    oldSurface.rootElement = null;
    assert(rootElement != null);
  }

  /// Reuses a [PersistedSurface] rendered in the previous frame.
  ///
  /// This is different from [update], which reuses another surface's elements,
  /// i.e. it was not requested to be retained by the framework.
  ///
  /// This is also different from [build], which constructs a brand new surface
  /// sub-tree.
  @protected
  @mustCallSuper
  void retain() {
    assert(rootElement != null);
    recomputeTransformAndClip();
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).retainSurfaceCount++;
    }
  }

  /// Removes the [element] of this surface from the tree.
  ///
  /// This method may be overridden by concrete implementations, for example, to
  /// recycle the resources owned by this surface.
  @protected
  @mustCallSuper
  void recycle() {
    assert(reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    rootElement.remove();
    rootElement = null;
  }

  @protected
  @mustCallSuper
  void debugValidate(List<String> validationErrors) {
    if (rootElement == null) {
      validationErrors.add('$runtimeType has null element.');
    }
    if (reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
      validationErrors.add('$runtimeType is still scheduled to be retained at '
          'the end of the frame.');
    }
  }

  /// A total match between two surfaces is when they are of the same type, were
  /// painted by the same render object, contain the same set of descendants,
  /// and do not have pending retain requests.
  ///
  /// If this method returns true it is safe to call [update] and pass `other`
  /// to it.
  bool isTotalMatchFor(PersistedSurface other) {
    assert(other != null);
    if (reuseStrategy == PersistedSurfaceReuseStrategy.retain ||
        other.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
      // If any of the nodes are being retained, do not match it. It is reused
      // directly.
      return false;
    }
    return other.runtimeType == runtimeType &&
        (other.paintedBy != null && paintedBy != null) &&
        identical(other.paintedBy, paintedBy) &&
        _hasExactDescendants(other);
  }

  /// Whether `other` surface matches this surface by type and neither have
  /// pending request to be retained.
  ///
  /// If this method returns true it is safe to call [update] and pass `other`
  /// to it.
  bool isFuzzyMatchFor(PersistedSurface other) {
    assert(other != null);
    if (reuseStrategy == PersistedSurfaceReuseStrategy.retain ||
        other.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
      // If any of the nodes are being retained, do not match it. It is reused
      // directly.
      return false;
    }
    return other.runtimeType == runtimeType;
  }

  bool _hasExactDescendants(PersistedSurface other) {
    if ((_descendants == null || _descendants.isEmpty) &&
        (other._descendants == null || other._descendants.isEmpty)) {
      return true;
    } else if (_descendants == null || other._descendants == null) {
      return false;
    }

    if (_descendants.length != other._descendants.length) {
      return false;
    }

    return _descendants.containsAll(other._descendants);
  }

  /// Creates a DOM element for this surface.
  html.Element createElement();

  /// Creates a DOM element for this surface preconfigured with common
  /// attributes, such as absolute positioning and debug information.
  html.Element defaultCreateElement(String tagName) {
    final element = html.Element.tag(tagName);
    element.style.position = 'absolute';
    if (assertionsEnabled) {
      element.setAttribute(
        'created-by',
        '${this.paintedBy.runtimeType}',
      );
    }
    return element;
  }

  /// Sets the HTML and CSS properties appropriate for this surface's
  /// implementation.
  ///
  /// For example, [PersistedTransform] sets the "transform" CSS attribute.
  void apply();

  /// The effective transform at this surface level.
  ///
  /// This value is computed by concatenating transforms of all ancestor
  /// transforms as well as this layer's transform (if any).
  ///
  /// The value is update by [recomputeTransformAndClip].
  Matrix4 get transform => _transform;
  Matrix4 _transform;

  /// The intersection at this surface level.
  ///
  /// This value is the intersection of clips in the ancestor chain, including
  /// the clip added by this layer (if any).
  ///
  /// The value is update by [recomputeTransformAndClip].
  ui.Rect get globalClip => _globalClip;
  ui.Rect _globalClip;

  /// Recomputes [transform] and [globalClip] fields.
  ///
  /// The default implementation inherits the values from the parent. Concrete
  /// surface implementations may override this with their custom transform and
  /// clip behaviors.
  ///
  /// This method is called by the [update] method. If a surface overrides this
  /// method it must make sure that all the parameters necessary for the
  /// computation are updated prior to calling `super.update`.
  @protected
  void recomputeTransformAndClip() {
    _transform = parent._transform;
    _globalClip = parent._globalClip;
  }

  /// Prints this surface into a [buffer] in a human-readable format.
  void debugPrint(StringBuffer buffer, int indent) {
    if (rootElement != null) {
      buffer.write('${'  ' * indent}<${rootElement.tagName.toLowerCase()} ');
    } else {
      buffer.write('${'  ' * indent}<$runtimeType recycled ');
    }
    debugPrintAttributes(buffer);
    buffer.writeln('>');
    debugPrintChildren(buffer, indent);
    if (rootElement != null) {
      buffer.writeln('${'  ' * indent}</${rootElement.tagName.toLowerCase()}>');
    } else {
      buffer.writeln('${'  ' * indent}</$runtimeType>');
    }
  }

  @protected
  @mustCallSuper
  void debugPrintAttributes(StringBuffer buffer) {
    if (rootElement != null) {
      buffer.write('@${rootElement.hashCode} ');
    }
    if (paintedBy != null) {
      buffer.write('painted-by="${paintedBy.runtimeType}"');
    }
  }

  @protected
  @mustCallSuper
  void debugPrintChildren(StringBuffer buffer, int indent) {}

  @override
  String toString() {
    if (assertionsEnabled) {
      final log = StringBuffer();
      debugPrint(log, 0);
      return log.toString();
    } else {
      return super.toString();
    }
  }
}

/// A surface that doesn't have child surfaces.
abstract class PersistedLeafSurface extends PersistedSurface {
  PersistedLeafSurface(Object paintedBy) : super(paintedBy);

  @override
  void visitChildren(PersistedSurfaceVisitor visitor) {
    // Does not have children.
  }
}

/// A surface that has a flat list of child surfaces.
abstract class PersistedContainerSurface extends PersistedSurface {
  PersistedContainerSurface(Object paintedBy) : super(paintedBy);

  final List<PersistedSurface> _children = <PersistedSurface>[];

  @override
  void visitChildren(PersistedSurfaceVisitor visitor) {
    _children.forEach(visitor);
  }

  void appendChild(PersistedSurface child) {
    _children.add(child);
    child.parent = this;

    // Add the child to the list of descendants in all ancestors within the
    // current render object.
    //
    // We only reuse a DOM node when it is painted by the same RenderObject,
    // therefore we need to mark this surface and ancestors within the current
    // render object as having this child as a descendant. This allows us to
    // detect when children move within their list of siblings and reuse their
    // elements.
    if (paintedBy != null &&
        child.paintedBy != null &&
        !identical(child.paintedBy, paintedBy)) {
      PersistedSurface container = this;
      while (container != null &&
          container.paintedBy != null &&
          identical(container.paintedBy, paintedBy)) {
        container._descendants ??= Set<Object>();
        container._descendants.add(child.paintedBy);
        container = container.parent;
      }
    }
  }

  @override
  void build() {
    super.build();
    // Memoize length for efficiency.
    final len = _children.length;
    // Memoize container element for efficiency. [childContainer] is polymorphic
    final html.Element containerElement = childContainer;
    for (int i = 0; i < len; i++) {
      final PersistedSurface child = _children[i];
      if (child.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
        assert(child.rootElement != null);
        _retainSurface(child);
      } else {
        child.build();
      }
      containerElement.append(child.rootElement);
    }
  }

  void _updateChild(PersistedSurface newChild, PersistedSurface oldChild) {
    assert(newChild.rootElement == null);
    assert(oldChild.isTotalMatchFor(newChild) ||
        oldChild.isFuzzyMatchFor(newChild));
    final html.Element oldElement = oldChild.rootElement;
    assert(oldElement != null);
    newChild.update(oldChild);
    // When the new surface reuses an existing element it takes ownership of it
    // so we null it out in the old surface. This prevents the element from
    // being reused more than once, which would be a serious bug.
    assert(oldChild.rootElement == null);
    assert(identical(newChild.rootElement, oldElement));
  }

  @override
  void update(PersistedContainerSurface oldContainer) {
    assert(isTotalMatchFor(oldContainer) || isFuzzyMatchFor(oldContainer));
    super.update(oldContainer);

    // A simple algorithms that attempts to reuse DOM elements from the previous
    // frame:
    //
    // - Scans both the old list and the new list in reverse, updating matching
    //   child surfaces. The reason for iterating in reverse is so that we can
    //   move the child in a single call to `insertBefore`. Otherwise, we'd have
    //   to do a more complicated dance of finding the next sibling and special
    //   casing `append`.
    // - If non-match is found, performs a search (also in reverse) to locate a
    //   reusable element, then moves it towards the back.
    // - If no reusable element is found, creates a new one.

    int bottomInNew = _children.length - 1;
    int bottomInOld = oldContainer._children.length - 1;

    // Memoize container element for efficiency. [childContainer] is polymorphic
    final html.Element containerElement = childContainer;

    PersistedSurface nextSibling;

    // Inserts the DOM node of the child before the DOM node of the next sibling
    // if it has moved as a result of the update. Does nothing if the new child
    // is already in the right location in the DOM tree.
    void insertDomNodeIfMoved(PersistedSurface newChild) {
      assert(newChild.rootElement != null);
      assert(newChild.parent == this);
      final bool reparented = newChild.rootElement.parent != containerElement;
      // Do not check for sibling if reparented. It's obvious that we moved.
      final bool moved = reparented ||
          newChild.rootElement.nextElementSibling != nextSibling?.rootElement;
      if (moved) {
        if (nextSibling == null) {
          // We're at the end of the list.
          containerElement.append(newChild.rootElement);
        } else {
          // We're in the middle of the list.
          containerElement.insertBefore(
              newChild.rootElement, nextSibling.rootElement);
        }
      }
    }

    while (bottomInNew >= 0 && bottomInOld >= 0) {
      final PersistedSurface newChild = _children[bottomInNew];
      if (newChild.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
        insertDomNodeIfMoved(newChild);
        _retainSurface(newChild);
      } else {
        final PersistedSurface oldChild = oldContainer._children[bottomInOld];
        bool onlyChildren =
            _children.length == 1 && oldContainer._children.length == 1;
        if (onlyChildren && oldChild.isFuzzyMatchFor(newChild) ||
            oldChild.isTotalMatchFor(newChild)) {
          _updateChild(newChild, oldChild);
          bottomInOld--;
        } else {
          // Scan back for a matching old child, if any.
          int searchPointer = bottomInOld - 1;
          PersistedSurface match;

          // Searching by scanning the array backwards may seem inefficient, but
          // in practice we'll have single-digit child lists. It is better to scan
          // and not perform any allocations than utilize fancier data structures
          // (e.g. maps).
          while (searchPointer >= 0) {
            final candidate = oldContainer._children[searchPointer];
            final isNotYetReused = candidate.rootElement != null;
            if (isNotYetReused && candidate.isTotalMatchFor(newChild)) {
              match = candidate;
              break;
            }
            searchPointer--;
          }

          // If we found a match, reuse the element. Otherwise, create a new one.
          if (match != null) {
            _updateChild(newChild, match);
          } else {
            newChild.build();
          }

          insertDomNodeIfMoved(newChild);
        }
      }
      assert(newChild.rootElement != null);
      bottomInNew--;
      nextSibling = newChild;
    }

    while (bottomInNew >= 0) {
      // We scanned the old container and attempted to reuse as much as possible
      // but there are still elements in the new list that need to be updated.
      // Since there are no more old elements to reuse, we build new ones.
      assert(bottomInOld == -1);
      final newChild = _children[bottomInNew];

      if (newChild.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
        _retainSurface(newChild);
      } else {
        newChild.build();
      }

      insertDomNodeIfMoved(newChild);

      bottomInNew--;
      assert(newChild.rootElement != null);
      nextSibling = newChild;
    }

    // Remove elements that were not reused this frame.
    final len = oldContainer._children.length;
    for (int i = 0; i < len; i++) {
      PersistedSurface oldChild = oldContainer._children[i];

      // Only recycle nodes that still have DOM nodes and they have not been
      // retained.
      if (oldChild.rootElement != null &&
          oldChild.reuseStrategy != PersistedSurfaceReuseStrategy.retain) {
        oldChild.recycle();
      }
    }

    // At the end of this all children should have an element each, and it
    // should be attached to this container's element.
    assert(() {
      for (int i = 0; i < oldContainer._children.length; i++) {
        if (oldContainer._children[i].reuseStrategy !=
            PersistedSurfaceReuseStrategy.retain) {
          assert(oldContainer._children[i].rootElement == null);
          assert(oldContainer._children[i].childContainer == null);
        }
      }
      for (int i = 0; i < _children.length; i++) {
        assert(_children[i].rootElement != null);
        assert(_children[i].rootElement.parent == containerElement);
      }
      return true;
    }());
  }

  @override
  void retain() {
    super.retain();
    final int len = _children.length;
    for (int i = 0; i < len; i++) {
      _children[i].retain();
    }
  }

  @override
  void recycle() {
    for (int i = 0; i < _children.length; i++) {
      final PersistedSurface child = _children[i];
      if (child.reuseStrategy != PersistedSurfaceReuseStrategy.retain) {
        child.recycle();
      }
    }
    super.recycle();
  }

  @protected
  @mustCallSuper
  void debugValidate(List<String> validationErrors) {
    super.debugValidate(validationErrors);
    for (int i = 0; i < _children.length; i++) {
      _children[i].debugValidate(validationErrors);
    }
  }

  @override
  void debugPrintChildren(StringBuffer buffer, int indent) {
    super.debugPrintChildren(buffer, indent);
    for (int i = 0; i < _children.length; i++) {
      _children[i].debugPrint(buffer, indent + 1);
    }
  }
}
