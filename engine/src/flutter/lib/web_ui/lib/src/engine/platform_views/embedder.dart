// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// This composites HTML views into the [ui.Scene].
class PlatformViewEmbedder {
  PlatformViewEmbedder(this.sceneHost, this.rasterizer);

  final DomElement sceneHost;
  final ViewRasterizer rasterizer;

  /// The context for the current frame.
  EmbedderFrameContext _context = EmbedderFrameContext();

  /// The context for the current frame. Should only be used in tests.
  @visibleForTesting
  EmbedderFrameContext get debugContext => _context;

  /// The most recent composition parameters for a given view id.
  ///
  /// If we receive a request to composite a view, but the composition
  /// parameters haven't changed, we can avoid having to recompute the
  /// element stack that correctly composites the view into the scene.
  final Map<int, EmbeddedViewParams> _currentCompositionParams = <int, EmbeddedViewParams>{};

  /// The clip chain for a view Id.
  ///
  /// This contains:
  /// * The root view in the stack of mutator elements for the view id.
  /// * The slot view in the stack (what shows the actual platform view contents).
  /// * The number of clipping elements used last time the view was composited.
  final Map<int, ViewClipChain> _viewClipChains = <int, ViewClipChain>{};

  /// The maximum number of canvases to create. Too many canvases can cause a
  /// performance burden.
  static int get maximumCanvases => configuration.canvasKitMaximumSurfaces;

  /// The views that need to be recomposited into the scene on the next frame.
  final Set<int> _viewsToRecomposite = <int>{};

  /// The list of view ids that should be composited, in order.
  final List<int> _compositionOrder = <int>[];

  /// The most recent composition order.
  final List<int> _activeCompositionOrder = <int>[];

  /// The most recent composition.
  Composition _activeComposition = Composition();

  /// Returns the most recent composition. Only used in tests.
  Composition get debugActiveComposition => _activeComposition;

  /// If [debugOverlayOptimizationBounds] is true, this canvas will draw
  /// semitransparent rectangles showing the computed bounds of the platform
  /// views and pictures in the scene.
  DisplayCanvas? debugBoundsCanvas;

  /// The size of the frame, in physical pixels.
  late BitmapSize _frameSize;

  set frameSize(BitmapSize size) {
    _frameSize = size;
  }

  /// Returns a list of canvases for the optimized composition. These are used in
  /// the paint step.
  Iterable<LayerCanvas> getOptimizedCanvases() {
    return _context.optimizedCanvases!;
  }

  void prerollCompositeEmbeddedView(int viewId, EmbeddedViewParams params) {
    // Do nothing if the params didn't change.
    if (_currentCompositionParams[viewId] == params) {
      // If the view was prerolled but not composited, then it needs to be
      // recomposited.
      if (!_activeCompositionOrder.contains(viewId)) {
        _viewsToRecomposite.add(viewId);
      }
      return;
    }
    _currentCompositionParams[viewId] = params;
    _viewsToRecomposite.add(viewId);
  }

  /// Adds the picture recorder associated with [picture] to the unoptimized
  /// scene.
  void addPictureToUnoptimizedScene(PictureLayer picture) {
    _context.sceneElements.add(PictureSceneElement(picture));
  }

  /// Prepares to composite [viewId].
  void compositeEmbeddedView(int viewId) {
    // Ensure platform view with `viewId` is injected into the `rasterizer.view`.
    rasterizer.view.dom.injectPlatformView(viewId);

    _compositionOrder.add(viewId);
    _context.sceneElements.add(PlatformViewSceneElement(viewId));

    if (_viewsToRecomposite.contains(viewId)) {
      _compositeWithParams(viewId, _currentCompositionParams[viewId]!);
      _viewsToRecomposite.remove(viewId);
    }
  }

  void _compositeWithParams(int platformViewId, EmbeddedViewParams params) {
    // If we haven't seen this viewId yet, cache it for clips/transforms.
    final ViewClipChain clipChain = _viewClipChains.putIfAbsent(platformViewId, () {
      return ViewClipChain(view: createPlatformViewSlot(platformViewId));
    });

    final DomElement slot = clipChain.slot;

    // See `apply()` in the PersistedPlatformView class for the HTML version
    // of this code.
    slot.style
      ..width = '${params.size.width}px'
      ..height = '${params.size.height}px'
      ..position = 'absolute';

    // Recompute the position in the DOM of the `slot` element...
    final int currentClippingCount = _countClips(params.mutators);
    final int previousClippingCount = clipChain.clipCount;
    if (currentClippingCount != previousClippingCount) {
      final DomElement oldPlatformViewRoot = clipChain.root;
      final DomElement newPlatformViewRoot = _reconstructClipViewsChain(
        currentClippingCount,
        slot,
        oldPlatformViewRoot,
      );
      // Store the updated root element, and clip count
      clipChain.updateClipChain(root: newPlatformViewRoot, clipCount: currentClippingCount);
    }

    // Apply mutators to the slot
    _applyMutators(params, slot, platformViewId);
  }

  int _countClips(MutatorsStack mutators) {
    var clipCount = 0;
    for (final mutator in mutators) {
      if (mutator.isClipType) {
        clipCount++;
      }
    }
    return clipCount;
  }

  DomElement _reconstructClipViewsChain(
    int numClips,
    DomElement platformView,
    DomElement headClipView,
  ) {
    DomNode? headClipViewNextSibling;
    var headClipViewWasAttached = false;
    if (headClipView.parentNode != null) {
      headClipViewWasAttached = true;
      headClipViewNextSibling = headClipView.nextSibling;
      headClipView.remove();
    }
    var head = platformView;
    var clipIndex = 0;
    // Re-use as much existing clip views as needed.
    while (head != headClipView && clipIndex < numClips) {
      head = head.parent!;
      clipIndex++;
    }
    // If there weren't enough existing clip views, add more.
    while (clipIndex < numClips) {
      final DomElement clippingView = createDomElement('flt-clip');
      clippingView.append(head);
      head = clippingView;
      clipIndex++;
    }
    head.remove();

    // If the chain was previously attached, attach it to the same position.
    if (headClipViewWasAttached) {
      sceneHost.insertBefore(head, headClipViewNextSibling);
    }
    return head;
  }

  void _applyMutators(EmbeddedViewParams params, DomElement embeddedView, int viewId) {
    final MutatorsStack mutators = params.mutators;
    var head = embeddedView;
    var headTransform = params.offset == ui.Offset.zero
        ? Matrix4.identity()
        : Matrix4.translationValues(params.offset.dx, params.offset.dy, 0);
    var embeddedOpacity = 1.0;
    _resetAnchor(head);

    for (final mutator in mutators) {
      switch (mutator.type) {
        case MutatorType.transform:
          headTransform = mutator.matrix!.multiplied(headTransform);
          head.style.transform = float64ListToCssTransform(headTransform.storage);
        case MutatorType.clipRect:
        case MutatorType.clipRRect:
        case MutatorType.clipPath:
          final DomElement clipView = head.parent!;
          clipView.style.clip = '';
          clipView.style.clipPath = '';
          headTransform = Matrix4.identity();
          clipView.style.transform = '';
          // We need to set width and height for the clipView to cover the
          // bounds of the path since Safari seem to incorrectly intersect
          // the element bounding rect with the clip path.
          clipView.style.width = '100%';
          clipView.style.height = '100%';
          if (mutator.rect != null) {
            final ui.Rect rect = mutator.rect!;
            clipView.style.clipPath =
                'rect(${rect.top}px ${rect.right}px '
                '${rect.bottom}px ${rect.left}px)';
          } else if (mutator.rrect != null) {
            final ui.RRect rrect = mutator.rrect!;
            if (rrect.blRadius == rrect.brRadius &&
                rrect.blRadius == rrect.tlRadius &&
                rrect.blRadius == rrect.trRadius &&
                rrect.blRadiusX == rrect.blRadiusY) {
              clipView.style.clipPath =
                  'rect(${rrect.top}px ${rrect.right}px '
                  '${rrect.bottom}px ${rrect.left}px '
                  'round ${rrect.blRadiusX}px)';
            } else {
              final path = ui.Path() as LayerPath;
              path.addRRect(mutator.rrect!);
              clipView.style.clipPath = 'path("${path.toSvgString()}")';
            }
          } else if (mutator.path != null) {
            final path = (mutator.path! as LazyPath).builtPath as LayerPath;
            clipView.style.clipPath = 'path("${path.toSvgString()}")';
          }
          _resetAnchor(clipView);
          head = clipView;
        case MutatorType.opacity:
          embeddedOpacity *= mutator.alphaFloat;
      }
    }

    embeddedView.style.opacity = embeddedOpacity.toString();

    // Reverse scale based on screen scale.
    //
    // HTML elements use logical (CSS) pixels, but we have been using physical
    // pixels, so scale down the head element to match the logical resolution.
    final double scale = EngineFlutterDisplay.instance.devicePixelRatio;
    final double inverseScale = 1 / scale;
    final scaleMatrix = Matrix4.diagonal3Values(inverseScale, inverseScale, 1);
    headTransform = scaleMatrix.multiplied(headTransform);
    head.style.transform = float64ListToCssTransform(headTransform.storage);
  }

  /// Sets the transform origin to the top-left corner of the element.
  ///
  /// By default, the transform origin is the center of the element, but
  /// Flutter assumes the transform origin is the top-left point.
  void _resetAnchor(DomElement element) {
    element.style.transformOrigin = '0 0 0';
    element.style.position = 'absolute';
  }

  /// Optimizes the scene to use the fewest possible canvases. This sets up
  /// the final paint pass to paint the pictures into the optimized canvases.
  void optimizeComposition() {
    Composition composition = createOptimizedComposition(
      _context.sceneElements,
      _currentCompositionParams,
    );
    composition = _modifyCompositionForMaxCanvases(composition);
    _context.optimizedComposition = composition;
    // Create new picture recorders for the optimized canvases and record
    // which pictures go in which canvas.
    final optimizedCanvasRecorders = <LayerPictureRecorder>[];
    final optimizedCanvases = <LayerCanvas>[];
    final pictureToOptimizedCanvasMap = <PictureLayer, LayerCanvas>{};
    for (final CompositionCanvas canvas in composition.canvases) {
      final pictureRecorder = ui.PictureRecorder() as LayerPictureRecorder;
      optimizedCanvasRecorders.add(pictureRecorder);
      final layerCanvas =
          ui.Canvas(pictureRecorder, ui.Offset.zero & _frameSize.toSize()) as LayerCanvas;
      optimizedCanvases.add(layerCanvas);
      for (final PictureLayer picture in canvas.pictures) {
        pictureToOptimizedCanvasMap[picture] = layerCanvas;
      }
    }
    _context.optimizedCanvasRecorders = optimizedCanvasRecorders;
    _context.optimizedCanvases = optimizedCanvases;
    _context.pictureToOptimizedCanvasMap = pictureToOptimizedCanvasMap;
  }

  /// Returns the canvas that this picture layer should draw into in the
  /// optimized scene.
  LayerCanvas getOptimizedCanvasFor(PictureLayer picture) {
    assert(_context.optimizedComposition != null);
    return _context.pictureToOptimizedCanvasMap![picture]!;
  }

  Future<void> submitFrame(FrameTimingRecorder? recorder) async {
    final Composition composition = _context.optimizedComposition!;
    _updateDomForNewComposition(composition);
    if (composition.equalsForCompositing(_activeComposition)) {
      // Copy the display canvases to the new composition.
      for (var i = 0; i < composition.canvases.length; i++) {
        composition.canvases[i].displayCanvas = _activeComposition.canvases[i].displayCanvas;
        _activeComposition.canvases[i].displayCanvas = null;
      }
    }
    _activeComposition = composition;

    final List<DisplayCanvas> displayCanvases = composition.canvases
        .map((CompositionCanvas canvas) => canvas.displayCanvas!)
        .toList();
    final List<ui.Picture> picturesToRasterize = _context.optimizedCanvasRecorders!
        .map((ui.PictureRecorder recorder) => recorder.endRecording())
        .toList();
    await rasterizer.rasterize(displayCanvases, picturesToRasterize, recorder);
    for (final picture in picturesToRasterize) {
      picture.dispose();
    }

    for (final LayerPictureRecorder recorder in _context.measuringPictureRecorders.values) {
      if (recorder.isRecording) {
        recorder.endRecording();
      }
    }

    // Draw the computed bounds for pictures and platform views if overlay
    // optimization debugging is enabled.
    if (debugOverlayOptimizationBounds) {
      debugBoundsCanvas ??= rasterizer.displayFactory.getCanvas();
      final boundsRecorder = ui.PictureRecorder();
      final boundsCanvas = ui.Canvas(boundsRecorder, ui.Offset.zero & _frameSize.toSize());
      final platformViewBoundsPaint = ui.Paint()..color = const ui.Color.fromARGB(100, 0, 255, 0);
      final pictureBoundsPaint = ui.Paint()..color = const ui.Color.fromARGB(100, 0, 0, 255);
      for (final CompositionEntity entity in _activeComposition.entities) {
        if (entity is CompositionPlatformView) {
          if (entity.debugComputedBounds != null) {
            boundsCanvas.drawRect(entity.debugComputedBounds!, platformViewBoundsPaint);
          }
        } else if (entity is CompositionCanvas) {
          for (final PictureLayer picture in entity.pictures) {
            boundsCanvas.drawRect(picture.sceneBounds!, pictureBoundsPaint);
          }
        }
      }
      await rasterizer.rasterize(
        <DisplayCanvas>[debugBoundsCanvas!],
        <ui.Picture>[boundsRecorder.endRecording()],
        null,
      );
      sceneHost.append(debugBoundsCanvas!.hostElement);
    }

    // Reset the context.
    _context = EmbedderFrameContext();
    if (listEquals(_compositionOrder, _activeCompositionOrder)) {
      _compositionOrder.clear();
      return;
    }

    final unusedViews = Set<int>.from(_activeCompositionOrder);
    _activeCompositionOrder.clear();

    List<int>? debugInvalidViewIds;

    for (var i = 0; i < _compositionOrder.length; i++) {
      final int viewId = _compositionOrder[i];

      var isViewInvalid = false;
      assert(() {
        isViewInvalid = !PlatformViewManager.instance.knowsViewId(viewId);
        if (isViewInvalid) {
          debugInvalidViewIds ??= <int>[];
          debugInvalidViewIds!.add(viewId);
        }
        return true;
      }());
      if (isViewInvalid) {
        continue;
      }

      _activeCompositionOrder.add(viewId);
      unusedViews.remove(viewId);
    }

    _compositionOrder.clear();

    unusedViews.forEach(disposeView);

    assert(
      debugInvalidViewIds == null || debugInvalidViewIds!.isEmpty,
      'Cannot render platform views: ${debugInvalidViewIds!.join(', ')}. '
      'These views have not been created, or they have been deleted.',
    );
  }

  void disposeView(int viewId) {
    final ViewClipChain? clipChain = _viewClipChains.remove(viewId);
    clipChain?.root.remove();
    // More cleanup
    _currentCompositionParams.remove(viewId);
    _viewsToRecomposite.remove(viewId);
  }

  /// Modify the given composition by removing canvases until the number of
  /// canvases is less than or equal to the maximum number of canvases.
  Composition _modifyCompositionForMaxCanvases(Composition composition) {
    final result = Composition();
    final int numCanvases = composition.canvases.length;
    if (numCanvases <= maximumCanvases) {
      return composition;
    }
    int numCanvasesToDelete = numCanvases - maximumCanvases;
    final picturesForLastCanvas = <PictureLayer>[];
    final modifiedEntities = List<CompositionEntity>.from(composition.entities);
    var sawLastCanvas = false;
    for (int i = composition.entities.length - 1; i >= 0; i--) {
      final CompositionEntity entity = modifiedEntities[i];
      if (entity is CompositionCanvas) {
        if (!sawLastCanvas) {
          sawLastCanvas = true;
          continue;
        }
        modifiedEntities.removeAt(i);
        picturesForLastCanvas.insertAll(0, entity.pictures);
        numCanvasesToDelete--;
        if (numCanvasesToDelete == 0) {
          break;
        }
      }
    }

    // Add all the pictures from the deleted canvases to the second-to-last
    // canvas (or the last canvas if there is only one).
    sawLastCanvas = (maximumCanvases == 1);
    for (int i = modifiedEntities.length - 1; i > 0; i--) {
      final CompositionEntity entity = modifiedEntities[i];
      if (entity is CompositionCanvas) {
        if (sawLastCanvas) {
          entity.pictures.addAll(picturesForLastCanvas);
          break;
        }
        sawLastCanvas = true;
      }
    }

    result.entities.addAll(modifiedEntities);
    return result;
  }

  void _updateDomForNewComposition(Composition composition) {
    if (composition.equalsForCompositing(_activeComposition)) {
      // The composition has not changed, so no DOM manipulation is needed.
      return;
    }
    final List<int> indexMap = _getIndexMapFromPreviousComposition(_activeComposition, composition);
    final List<int> existingIndexMap = indexMap.where((int index) => index != -1).toList();

    final List<int> staticElements = longestIncreasingSubsequence(existingIndexMap);
    // Convert longest increasing subsequence from subsequence of indices of
    // `existingIndexMap` to a subsequence of indices in previous composition.
    for (var i = 0; i < staticElements.length; i++) {
      staticElements[i] = existingIndexMap[staticElements[i]];
    }

    // Remove elements which are in the active composition, but not in the new
    // composition.
    for (var i = 0; i < _activeComposition.entities.length; i++) {
      if (indexMap.contains(i)) {
        continue;
      }
      final CompositionEntity entity = _activeComposition.entities[i];
      if (entity is CompositionPlatformView) {
        disposeView(entity.viewId);
      } else if (entity is CompositionCanvas) {
        assert(
          entity.displayCanvas != null,
          'CompositionCanvas in previous composition was '
          'not assigned a DisplayCanvas',
        );
        rasterizer.releaseOverlay(entity.displayCanvas!);
        entity.displayCanvas = null;
      }
    }

    // Updates [canvas] (located in [index] in the next composition) to have a
    // display canvas, either taken from the associated canvas in the previous
    // composition, or newly created.
    void updateCompositionCanvasWithDisplay(CompositionCanvas canvas, int index) {
      // Does [nextEntity] correspond with a canvas in the previous composition?
      // If so, then the canvas in the previous composition had an associated
      //display canvas. Use this display canvas for [nextEntity].
      if (indexMap[index] != -1) {
        final CompositionEntity previousEntity = _activeComposition.entities[indexMap[index]];
        assert(previousEntity is CompositionCanvas && previousEntity.displayCanvas != null);
        canvas.displayCanvas = (previousEntity as CompositionCanvas).displayCanvas;
        previousEntity.displayCanvas = null;
      } else {
        // There is no corresponding canvas in the previous composition. So this
        // canvas needs a display canvas.
        canvas.displayCanvas = rasterizer.getOverlay();
      }
    }

    // At this point, the DOM contains the static elements and the elements from
    // the previous composition which need to move. We iterate over the static
    // elements and insert the elements which come before them into the DOM.
    var staticElementIndex = 0;
    var nextCompositionIndex = 0;
    while (staticElementIndex < staticElements.length) {
      final int staticElementIndexInActiveComposition = staticElements[staticElementIndex];
      final DomElement staticDomElement = _getElement(
        _activeComposition.entities[staticElementIndexInActiveComposition],
      );
      // Go through next composition elements until we reach the static element.
      while (indexMap[nextCompositionIndex] != staticElementIndexInActiveComposition) {
        final CompositionEntity nextEntity = composition.entities[nextCompositionIndex];
        if (nextEntity is CompositionCanvas) {
          updateCompositionCanvasWithDisplay(nextEntity, nextCompositionIndex);
        }
        sceneHost.insertBefore(_getElement(nextEntity), staticDomElement);
        nextCompositionIndex++;
      }
      if (composition.entities[nextCompositionIndex] is CompositionCanvas) {
        updateCompositionCanvasWithDisplay(
          composition.entities[nextCompositionIndex] as CompositionCanvas,
          nextCompositionIndex,
        );
      }
      // Also increment the next composition index because this is the static
      // element.
      nextCompositionIndex++;
      staticElementIndex++;
    }

    // Add the leftover entities.
    while (nextCompositionIndex < composition.entities.length) {
      final CompositionEntity nextEntity = composition.entities[nextCompositionIndex];
      if (nextEntity is CompositionCanvas) {
        updateCompositionCanvasWithDisplay(nextEntity, nextCompositionIndex);
      }
      sceneHost.append(_getElement(nextEntity));
      nextCompositionIndex++;
    }
  }

  DomElement _getElement(CompositionEntity entity) {
    return switch (entity) {
      CompositionCanvas() => entity.displayCanvas!.hostElement,
      CompositionPlatformView() => _viewClipChains[entity.viewId]!.root,
    };
  }

  /// Returns a [List] of ints mapping elements from the [next] composition to
  /// elements of the [previous] composition. If there is no matching element in
  /// the previous composition, then the index map for that element is `-1`.
  List<int> _getIndexMapFromPreviousComposition(Composition previous, Composition next) {
    assert(
      !previous.equalsForCompositing(next),
      'Should not be in this method if the Compositions are equal',
    );
    final result = <int>[];
    var index = 0;

    final int maxUnchangedLength = math.min(previous.entities.length, next.entities.length);

    // A canvas in the previous composition can only be used once in the next
    // composition. So if it is matched with one in the next composition, mark
    // it here so it is only matched once.
    final alreadyClaimedCanvases = <int>{};

    // Add the unchanged elements from the beginning of the list.
    while (index < maxUnchangedLength &&
        previous.entities[index].equalsForCompositing(next.entities[index])) {
      result.add(index);
      if (previous.entities[index] is CompositionCanvas) {
        alreadyClaimedCanvases.add(index);
      }
      index += 1;
    }

    while (index < next.entities.length) {
      var foundForIndex = false;
      for (var oldIndex = 0; oldIndex < previous.entities.length; oldIndex += 1) {
        if (previous.entities[oldIndex].equalsForCompositing(next.entities[index]) &&
            !alreadyClaimedCanvases.contains(oldIndex)) {
          result.add(oldIndex);
          if (previous.entities[oldIndex] is CompositionCanvas) {
            alreadyClaimedCanvases.add(oldIndex);
          }
          foundForIndex = true;
          break;
        }
      }
      if (!foundForIndex) {
        result.add(-1);
      }
      index += 1;
    }

    assert(result.length == next.entities.length);
    return result;
  }

  static void removeElement(DomElement element) {
    element.remove();
  }

  /// Disposes the state of this view embedder.
  void dispose() {
    _viewClipChains.keys.toList().forEach(disposeView);
    _context = EmbedderFrameContext();
    _currentCompositionParams.clear();
    _viewClipChains.clear();
    _viewsToRecomposite.clear();
    _activeCompositionOrder.clear();
    _compositionOrder.clear();
    for (final CompositionCanvas canvas in _activeComposition.canvases) {
      canvas.displayCanvas?.dispose();
      canvas.displayCanvas?.hostElement.remove();
    }
    _activeComposition = Composition();
    debugBoundsCanvas?.dispose();
    debugBoundsCanvas?.hostElement.remove();
    debugBoundsCanvas = null;
  }

  /// Clears the state. Used in tests.
  void debugClear() {
    dispose();
    rasterizer.removeOverlaysFromDom();
  }
}

/// Represents a Clip Chain (for a view).
///
/// Objects of this class contain:
/// * The root view in the stack of mutator elements for the view id.
/// * The slot view in the stack (the actual contents of the platform view).
/// * The number of clipping elements used last time the view was composited.
class ViewClipChain {
  ViewClipChain({required DomElement view}) : _root = view, _slot = view;

  DomElement _root;
  final DomElement _slot;
  int _clipCount = -1;

  DomElement get root => _root;
  DomElement get slot => _slot;
  int get clipCount => _clipCount;

  void updateClipChain({required DomElement root, required int clipCount}) {
    _root = root;
    _clipCount = clipCount;
  }
}

/// The parameters passed to the platform view embedder.
class EmbeddedViewParams {
  EmbeddedViewParams(this.offset, this.size, MutatorsStack mutators)
    : mutators = MutatorsStack._copy(mutators);

  final ui.Offset offset;
  final ui.Size size;
  final MutatorsStack mutators;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EmbeddedViewParams &&
        other.offset == offset &&
        other.size == size &&
        other.mutators == mutators;
  }

  @override
  int get hashCode => Object.hash(offset, size, mutators);
}

enum MutatorType { clipRect, clipRRect, clipPath, transform, opacity }

/// Stores mutation information like clipping or transform.
class Mutator {
  const Mutator.clipRect(ui.Rect rect) : this._(MutatorType.clipRect, rect, null, null, null, null);
  const Mutator.clipRRect(ui.RRect rrect)
    : this._(MutatorType.clipRRect, null, rrect, null, null, null);
  const Mutator.clipPath(ui.Path path) : this._(MutatorType.clipPath, null, null, path, null, null);
  const Mutator.transform(Matrix4 matrix)
    : this._(MutatorType.transform, null, null, null, matrix, null);
  const Mutator.opacity(int alpha) : this._(MutatorType.opacity, null, null, null, null, alpha);

  const Mutator._(this.type, this.rect, this.rrect, this.path, this.matrix, this.alpha);

  final MutatorType type;
  final ui.Rect? rect;
  final ui.RRect? rrect;
  final ui.Path? path;
  final Matrix4? matrix;
  final int? alpha;

  bool get isClipType =>
      type == MutatorType.clipRect || type == MutatorType.clipRRect || type == MutatorType.clipPath;

  double get alphaFloat => alpha! / 255.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutator) {
      return false;
    }

    final Mutator typedOther = other;
    if (type != typedOther.type) {
      return false;
    }

    return switch (type) {
      MutatorType.clipRect => rect == typedOther.rect,
      MutatorType.clipRRect => rrect == typedOther.rrect,
      MutatorType.clipPath => path == typedOther.path,
      MutatorType.transform => matrix == typedOther.matrix,
      MutatorType.opacity => alpha == typedOther.alpha,
    };
  }

  @override
  int get hashCode => Object.hash(type, rect, rrect, path, matrix, alpha);
}

/// A stack of mutators that can be applied to an embedded view.
class MutatorsStack extends Iterable<Mutator> {
  MutatorsStack() : _mutators = <Mutator>[];

  MutatorsStack._copy(MutatorsStack original) : _mutators = List<Mutator>.from(original._mutators);

  final List<Mutator> _mutators;

  void pushClipRect(ui.Rect rect) {
    _mutators.add(Mutator.clipRect(rect));
  }

  void pushClipRRect(ui.RRect rrect) {
    _mutators.add(Mutator.clipRRect(rrect));
  }

  void pushClipRSuperellipse(ui.RSuperellipse rsuperellipse) {
    // RSuperellipse ops in PlatformView are approximated by RRect because they
    // are expensive.
    pushClipRRect(rsuperellipse.toApproximateRRect());
  }

  void pushClipPath(ui.Path path) {
    _mutators.add(Mutator.clipPath(path));
  }

  void pushTransform(Matrix4 matrix) {
    _mutators.add(Mutator.transform(matrix));
  }

  void pushOpacity(int alpha) {
    _mutators.add(Mutator.opacity(alpha));
  }

  void pop() {
    _mutators.removeLast();
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is MutatorsStack && listEquals<Mutator>(other._mutators, _mutators);
  }

  @override
  int get hashCode => Object.hashAll(_mutators);

  @override
  Iterator<Mutator> get iterator => _mutators.reversed.iterator;

  /// Iterate over the mutators in reverse.
  Iterable<Mutator> get reversed => _mutators;
}

sealed class SceneElement {}

class PictureSceneElement extends SceneElement {
  PictureSceneElement(this.picture);

  final PictureLayer picture;
}

class PlatformViewSceneElement extends SceneElement {
  PlatformViewSceneElement(this.viewId);

  final int viewId;
}

/// The state for the current frame.
class EmbedderFrameContext {
  /// Picture recorders which were created to measure the final bounds of the
  /// picture in the scene.
  final Map<PictureLayer, LayerPictureRecorder> measuringPictureRecorders =
      <PictureLayer, LayerPictureRecorder>{};

  /// List of picture recorders and platform view ids in the order they were
  /// painted.
  final List<SceneElement> sceneElements = <SceneElement>[];

  /// The optimized composition for this frame. This is set by calling
  /// [optimizeComposition].
  Composition? optimizedComposition;

  /// The picture recorders for the optimized composition. This is set by
  /// calling [optimizeComposition].
  List<LayerPictureRecorder>? optimizedCanvasRecorders;

  /// The Canvases which will be drawn into in the optimized composition. This
  /// is set by calling [optimizeComposition].
  List<LayerCanvas>? optimizedCanvases;

  /// A map from the original PictureLayer to the Canvas it should be drawn
  /// into in the optimized composition. This is set by calling
  /// [optimizeComposition].
  Map<PictureLayer, LayerCanvas>? pictureToOptimizedCanvasMap;
}
