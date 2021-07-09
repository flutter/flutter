// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// This composites HTML views into the [ui.Scene].
class HtmlViewEmbedder {
  /// The [HtmlViewEmbedder] singleton.
  static HtmlViewEmbedder instance = HtmlViewEmbedder._();

  HtmlViewEmbedder._();

  /// The maximum number of overlay surfaces that can be live at once.
  static const int maximumOverlaySurfaces = const int.fromEnvironment(
    'FLUTTER_WEB_MAXIMUM_OVERLAYS',
    defaultValue: 8,
  );

  /// The picture recorder shared by all platform views which paint to the
  /// backup surface.
  CkPictureRecorder? _backupPictureRecorder;

  /// The set of platform views using the backup surface.
  final Set<int> _viewsUsingBackupSurface = <int>{};

  /// A picture recorder associated with a view id.
  ///
  /// When we composite in the platform view, we need to create a new canvas
  /// for further paint commands to paint to, since the composited view will
  /// be on top of the current canvas, and we want further paint commands to
  /// be on top of the platform view.
  final Map<int, CkPictureRecorder> _pictureRecorders =
      <int, CkPictureRecorder>{};

  /// The most recent composition parameters for a given view id.
  ///
  /// If we receive a request to composite a view, but the composition
  /// parameters haven't changed, we can avoid having to recompute the
  /// element stack that correctly composites the view into the scene.
  final Map<int, EmbeddedViewParams> _currentCompositionParams =
      <int, EmbeddedViewParams>{};

  /// The clip chain for a view Id.
  ///
  /// This contains:
  /// * The root view in the stack of mutator elements for the view id.
  /// * The slot view in the stack (what shows the actual platform view contents).
  /// * The number of clipping elements used last time the view was composited.
  final Map<int, ViewClipChain> _viewClipChains = <int, ViewClipChain>{};

  /// Surfaces used to draw on top of platform views, keyed by platform view ID.
  ///
  /// These surfaces are cached in the [OverlayCache] and reused.
  final Map<int, Surface> _overlays = <int, Surface>{};

  /// The views that need to be recomposited into the scene on the next frame.
  final Set<int> _viewsToRecomposite = <int>{};

  /// The list of view ids that should be composited, in order.
  List<int> _compositionOrder = <int>[];

  /// The most recent composition order.
  List<int> _activeCompositionOrder = <int>[];

  /// The size of the frame, in physical pixels.
  ui.Size _frameSize = ui.window.physicalSize;

  void set frameSize(ui.Size size) {
    _frameSize = size;
  }

  List<CkCanvas> getCurrentCanvases() {
    final Set<CkCanvas> canvases = <CkCanvas>{};
    for (int i = 0; i < _compositionOrder.length; i++) {
      final int viewId = _compositionOrder[i];
      canvases.add(_pictureRecorders[viewId]!.recordingCanvas!);
    }
    return canvases.toList();
  }

  void prerollCompositeEmbeddedView(int viewId, EmbeddedViewParams params) {
    _ensureOverlayInitialized(viewId);
    if (_viewsUsingBackupSurface.contains(viewId)) {
      if (_backupPictureRecorder == null) {
        // Only initialize the picture recorder for the backup surface once.
        final pictureRecorder = CkPictureRecorder();
        pictureRecorder.beginRecording(ui.Offset.zero & _frameSize);
        pictureRecorder.recordingCanvas!.clear(ui.Color(0x00000000));
        _backupPictureRecorder = pictureRecorder;
      }
      _pictureRecorders[viewId] = _backupPictureRecorder!;
    } else {
      final pictureRecorder = CkPictureRecorder();
      pictureRecorder.beginRecording(ui.Offset.zero & _frameSize);
      pictureRecorder.recordingCanvas!.clear(ui.Color(0x00000000));
      _pictureRecorders[viewId] = pictureRecorder;
    }
    _compositionOrder.add(viewId);

    // Do nothing if the params didn't change.
    if (_currentCompositionParams[viewId] == params) {
      return;
    }
    _currentCompositionParams[viewId] = params;
    _viewsToRecomposite.add(viewId);
  }

  CkCanvas? compositeEmbeddedView(int viewId) {
    // Do nothing if this view doesn't need to be composited.
    if (!_viewsToRecomposite.contains(viewId)) {
      return _pictureRecorders[viewId]!.recordingCanvas;
    }
    _compositeWithParams(viewId, _currentCompositionParams[viewId]!);
    _viewsToRecomposite.remove(viewId);
    return _pictureRecorders[viewId]!.recordingCanvas;
  }

  void _compositeWithParams(int viewId, EmbeddedViewParams params) {
    // If we haven't seen this viewId yet, cache it for clips/transforms.
    ViewClipChain clipChain = _viewClipChains.putIfAbsent(viewId, () {
      return ViewClipChain(view: createPlatformViewSlot(viewId));
    });

    html.Element slot = clipChain.slot;

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
      html.Element oldPlatformViewRoot = clipChain.root;
      html.Element newPlatformViewRoot = _reconstructClipViewsChain(
        currentClippingCount,
        slot,
        oldPlatformViewRoot,
      );
      // Store the updated root element, and clip count
      clipChain.updateClipChain(
        root: newPlatformViewRoot,
        clipCount: currentClippingCount,
      );
    }

    // Apply mutators to the slot
    _applyMutators(params.mutators, slot, viewId);
  }

  int _countClips(MutatorsStack mutators) {
    int clipCount = 0;
    for (final Mutator mutator in mutators) {
      if (mutator.isClipType) {
        clipCount++;
      }
    }
    return clipCount;
  }

  html.Element _reconstructClipViewsChain(
    int numClips,
    html.Element platformView,
    html.Element headClipView,
  ) {
    int indexInFlutterView = -1;
    if (headClipView.parent != null) {
      indexInFlutterView = skiaSceneHost!.children.indexOf(headClipView);
      headClipView.remove();
    }
    html.Element head = platformView;
    int clipIndex = 0;
    // Re-use as much existing clip views as needed.
    while (head != headClipView && clipIndex < numClips) {
      head = head.parent!;
      clipIndex++;
    }
    // If there weren't enough existing clip views, add more.
    while (clipIndex < numClips) {
      html.Element clippingView = html.Element.tag('flt-clip');
      clippingView.append(head);
      head = clippingView;
      clipIndex++;
    }
    head.remove();

    // If the chain was previously attached, attach it to the same position.
    if (indexInFlutterView > -1) {
      skiaSceneHost!.children.insert(indexInFlutterView, head);
    }
    return head;
  }

  /// Clean up the old SVG clip definitions, as this platform view is about to
  /// be recomposited.
  void _cleanUpClipDefs(int viewId) {
    if (_svgClipDefs.containsKey(viewId)) {
      final html.Element clipDefs =
          _svgPathDefs!.querySelector('#sk_path_defs')!;
      final List<html.Element> nodesToRemove = <html.Element>[];
      final Set<String> oldDefs = _svgClipDefs[viewId]!;
      for (html.Element child in clipDefs.children) {
        if (oldDefs.contains(child.id)) {
          nodesToRemove.add(child);
        }
      }
      for (html.Element node in nodesToRemove) {
        node.remove();
      }
      _svgClipDefs[viewId]!.clear();
    }
  }

  void _applyMutators(
      MutatorsStack mutators, html.Element embeddedView, int viewId) {
    html.Element head = embeddedView;
    Matrix4 headTransform = Matrix4.identity();
    double embeddedOpacity = 1.0;
    _resetAnchor(head);
    _cleanUpClipDefs(viewId);

    for (final Mutator mutator in mutators) {
      switch (mutator.type) {
        case MutatorType.transform:
          headTransform = mutator.matrix!.multiplied(headTransform);
          head.style.transform =
              float64ListToCssTransform(headTransform.storage);
          break;
        case MutatorType.clipRect:
        case MutatorType.clipRRect:
        case MutatorType.clipPath:
          html.Element clipView = head.parent!;
          clipView.style.clip = '';
          clipView.style.clipPath = '';
          headTransform = Matrix4.identity();
          clipView.style.transform = '';
          if (mutator.rect != null) {
            final ui.Rect rect = mutator.rect!;
            clipView.style.clip = 'rect(${rect.top}px, ${rect.right}px, '
                '${rect.bottom}px, ${rect.left}px)';
          } else if (mutator.rrect != null) {
            final CkPath path = CkPath();
            path.addRRect(mutator.rrect!);
            _ensureSvgPathDefs();
            html.Element pathDefs =
                _svgPathDefs!.querySelector('#sk_path_defs')!;
            _clipPathCount += 1;
            final String clipId = 'svgClip$_clipPathCount';
            html.Node newClipPath = html.DocumentFragment.svg(
              '<clipPath id="$clipId">'
              '<path d="${path.toSvgString()}">'
              '</path></clipPath>',
              treeSanitizer: NullTreeSanitizer(),
            );
            pathDefs.append(newClipPath);
            // Store the id of the node instead of [newClipPath] directly. For
            // some reason, calling `newClipPath.remove()` doesn't remove it
            // from the DOM.
            _svgClipDefs.putIfAbsent(viewId, () => <String>{}).add(clipId);
            clipView.style.clipPath = 'url(#$clipId)';
          } else if (mutator.path != null) {
            final CkPath path = mutator.path as CkPath;
            _ensureSvgPathDefs();
            html.Element pathDefs =
                _svgPathDefs!.querySelector('#sk_path_defs')!;
            _clipPathCount += 1;
            final String clipId = 'svgClip$_clipPathCount';
            html.Node newClipPath = html.DocumentFragment.svg(
              '<clipPath id="$clipId">'
              '<path d="${path.toSvgString()}">'
              '</path></clipPath>',
              treeSanitizer: NullTreeSanitizer(),
            );
            pathDefs.append(newClipPath);
            // Store the id of the node instead of [newClipPath] directly. For
            // some reason, calling `newClipPath.remove()` doesn't remove it
            // from the DOM.
            _svgClipDefs.putIfAbsent(viewId, () => <String>{}).add(clipId);
            clipView.style.clipPath = 'url(#$clipId)';
          }
          _resetAnchor(clipView);
          head = clipView;
          break;
        case MutatorType.opacity:
          embeddedOpacity *= mutator.alphaFloat;
          break;
      }
    }

    embeddedView.style.opacity = embeddedOpacity.toString();

    // Reverse scale based on screen scale.
    //
    // HTML elements use logical (CSS) pixels, but we have been using physical
    // pixels, so scale down the head element to match the logical resolution.
    final double scale = window.devicePixelRatio;
    final double inverseScale = 1 / scale;
    final Matrix4 scaleMatrix =
        Matrix4.diagonal3Values(inverseScale, inverseScale, 1);
    headTransform = scaleMatrix.multiplied(headTransform);
    head.style.transform = float64ListToCssTransform(headTransform.storage);
  }

  /// Sets the transform origin to the top-left corner of the element.
  ///
  /// By default, the transform origin is the center of the element, but
  /// Flutter assumes the transform origin is the top-left point.
  void _resetAnchor(html.Element element) {
    element.style.transformOrigin = '0 0 0';
    element.style.position = 'absolute';
  }

  int _clipPathCount = 0;

  html.Element? _svgPathDefs;

  /// The nodes containing the SVG clip definitions needed to clip this view.
  Map<int, Set<String>> _svgClipDefs = <int, Set<String>>{};

  /// Ensures we add a container of SVG path defs to the DOM so they can
  /// be referred to in clip-path: url(#blah).
  void _ensureSvgPathDefs() {
    if (_svgPathDefs != null) {
      return;
    }
    _svgPathDefs = html.Element.html(
      '$kSvgResourceHeader<defs id="sk_path_defs"></defs></svg>',
      treeSanitizer: NullTreeSanitizer(),
    );
    skiaSceneHost!.append(_svgPathDefs!);
  }

  void submitFrame() {
    bool _didPaintBackupSurface = false;
    for (int i = 0; i < _compositionOrder.length; i++) {
      int viewId = _compositionOrder[i];
      if (_viewsUsingBackupSurface.contains(viewId)) {
        // Only draw the picture to the backup surface once.
        if (!_didPaintBackupSurface) {
          SurfaceFrame backupFrame =
              SurfaceFactory.instance.backupSurface.acquireFrame(_frameSize);
          backupFrame.skiaCanvas
              .drawPicture(_backupPictureRecorder!.endRecording());
          _backupPictureRecorder = null;
          backupFrame.submit();
          _didPaintBackupSurface = true;
        }
      } else {
        final SurfaceFrame frame = _overlays[viewId]!.acquireFrame(_frameSize);
        final CkCanvas canvas = frame.skiaCanvas;
        canvas.drawPicture(
          _pictureRecorders[viewId]!.endRecording(),
        );
        frame.submit();
      }
    }
    _pictureRecorders.clear();
    if (listEquals(_compositionOrder, _activeCompositionOrder)) {
      _compositionOrder.clear();
      return;
    }

    final Set<int> unusedViews = Set<int>.from(_activeCompositionOrder);
    _activeCompositionOrder.clear();

    List<int>? debugInvalidViewIds;
    for (int i = 0; i < _compositionOrder.length; i++) {
      int viewId = _compositionOrder[i];

      if (assertionsEnabled) {
        if (!platformViewManager.knowsViewId(viewId)) {
          debugInvalidViewIds ??= <int>[];
          debugInvalidViewIds.add(viewId);
          continue;
        }
      }

      unusedViews.remove(viewId);
      html.Element platformViewRoot = _viewClipChains[viewId]!.root;
      html.Element overlay = _overlays[viewId]!.htmlElement;
      platformViewRoot.remove();
      skiaSceneHost!.append(platformViewRoot);
      overlay.remove();
      skiaSceneHost!.append(overlay);
      _activeCompositionOrder.add(viewId);
    }

    _compositionOrder.clear();

    disposeViews(unusedViews);

    if (assertionsEnabled) {
      if (debugInvalidViewIds != null && debugInvalidViewIds.isNotEmpty) {
        throw AssertionError(
          'Cannot render platform views: ${debugInvalidViewIds.join(', ')}. '
          'These views have not been created, or they have been deleted.',
        );
      }
    }
  }

  void disposeViews(Set<int> viewsToDispose) {
    for (final int viewId in viewsToDispose) {
      // Remove viewId from the _viewClipChains Map, and then from the DOM.
      ViewClipChain? clipChain = _viewClipChains.remove(viewId);
      clipChain?.root.remove();
      // More cleanup
      _releaseOverlay(viewId);
      _currentCompositionParams.remove(viewId);
      _viewsToRecomposite.remove(viewId);
      _cleanUpClipDefs(viewId);
      _svgClipDefs.remove(viewId);
    }
  }

  void _releaseOverlay(int viewId) {
    if (_overlays[viewId] != null) {
      Surface overlay = _overlays[viewId]!;
      if (overlay == SurfaceFactory.instance.backupSurface) {
        assert(_viewsUsingBackupSurface.contains(viewId));
        _viewsUsingBackupSurface.remove(viewId);
        _overlays.remove(viewId);
        // If no views use the backup surface, then we can release it. This
        // happens when the number of live platform views drops below the
        // maximum overlay surfaces, so the backup surface is no longer needed.
        if (_viewsUsingBackupSurface.isEmpty) {
          SurfaceFactory.instance.releaseSurface(overlay);
        }
      } else {
        SurfaceFactory.instance.releaseSurface(overlay);
        _overlays.remove(viewId);
      }
    }
  }

  void _ensureOverlayInitialized(int viewId) {
    // If there's an active overlay for the view ID, continue using it.
    Surface? overlay = _overlays[viewId];
    if (overlay != null && !_viewsUsingBackupSurface.contains(viewId)) {
      overlay.createOrUpdateSurfaces(_frameSize);
      return;
    }

    // If this view was using the backup surface, try to release the backup
    // surface and see if a non-backup surface became available.
    if (_viewsUsingBackupSurface.contains(viewId)) {
      _releaseOverlay(viewId);
    }

    // Try reusing a cached overlay created for another platform view.
    overlay = SurfaceFactory.instance.getSurface();
    if (overlay == SurfaceFactory.instance.backupSurface) {
      _viewsUsingBackupSurface.add(viewId);
    }
    overlay.createOrUpdateSurfaces(_frameSize);
    _overlays[viewId] = overlay;
  }

  /// Deletes SVG clip paths, useful for tests.
  void debugCleanupSvgClipPaths() {
    _svgPathDefs?.children.single.children.forEach((element) {
      element.remove();
    });
    _svgClipDefs.clear();
  }

  /// Clears the state of this view embedder. Used in tests.
  void debugClear() {
    final Set<int> allViews = platformViewManager.debugClear();
    disposeViews(allViews);
    _backupPictureRecorder?.endRecording();
    _backupPictureRecorder = null;
    _viewsUsingBackupSurface.clear();
    _pictureRecorders.clear();
    _currentCompositionParams.clear();
    debugCleanupSvgClipPaths();
    _currentCompositionParams.clear();
    _viewClipChains.clear();
    _overlays.clear();
    _viewsToRecomposite.clear();
    _activeCompositionOrder.clear();
    _compositionOrder.clear();
  }
}

/// Represents a Clip Chain (for a view).
///
/// Objects of this class contain:
/// * The root view in the stack of mutator elements for the view id.
/// * The slot view in the stack (the actual contents of the platform view).
/// * The number of clipping elements used last time the view was composited.
class ViewClipChain {
  html.Element _root;
  html.Element _slot;
  int _clipCount = -1;

  ViewClipChain({required html.Element view})
      : this._root = view,
        this._slot = view;

  html.Element get root => _root;
  html.Element get slot => _slot;
  int get clipCount => _clipCount;

  void updateClipChain({required html.Element root, required int clipCount}) {
    _root = root;
    _clipCount = clipCount;
  }
}

/// The parameters passed to the view embedder.
class EmbeddedViewParams {
  EmbeddedViewParams(this.offset, this.size, MutatorsStack mutators)
      : mutators = MutatorsStack._copy(mutators);

  final ui.Offset offset;
  final ui.Size size;
  final MutatorsStack mutators;

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EmbeddedViewParams &&
        other.offset == offset &&
        other.size == size &&
        other.mutators == mutators;
  }

  int get hashCode => ui.hashValues(offset, size, mutators);
}

enum MutatorType {
  clipRect,
  clipRRect,
  clipPath,
  transform,
  opacity,
}

/// Stores mutation information like clipping or transform.
class Mutator {
  const Mutator._(
    this.type,
    this.rect,
    this.rrect,
    this.path,
    this.matrix,
    this.alpha,
  );

  final MutatorType type;
  final ui.Rect? rect;
  final ui.RRect? rrect;
  final ui.Path? path;
  final Matrix4? matrix;
  final int? alpha;

  const Mutator.clipRect(ui.Rect rect)
      : this._(MutatorType.clipRect, rect, null, null, null, null);
  const Mutator.clipRRect(ui.RRect rrect)
      : this._(MutatorType.clipRRect, null, rrect, null, null, null);
  const Mutator.clipPath(ui.Path path)
      : this._(MutatorType.clipPath, null, null, path, null, null);
  const Mutator.transform(Matrix4 matrix)
      : this._(MutatorType.transform, null, null, null, matrix, null);
  const Mutator.opacity(int alpha)
      : this._(MutatorType.opacity, null, null, null, null, alpha);

  bool get isClipType =>
      type == MutatorType.clipRect ||
      type == MutatorType.clipRRect ||
      type == MutatorType.clipPath;

  double get alphaFloat => alpha! / 255.0;

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

    switch (type) {
      case MutatorType.clipRect:
        return rect == typedOther.rect;
      case MutatorType.clipRRect:
        return rrect == typedOther.rrect;
      case MutatorType.clipPath:
        return path == typedOther.path;
      case MutatorType.transform:
        return matrix == typedOther.matrix;
      case MutatorType.opacity:
        return alpha == typedOther.alpha;
      default:
        return false;
    }
  }

  int get hashCode => ui.hashValues(type, rect, rrect, path, matrix, alpha);
}

/// A stack of mutators that can be applied to an embedded view.
class MutatorsStack extends Iterable<Mutator> {
  MutatorsStack() : _mutators = <Mutator>[];

  MutatorsStack._copy(MutatorsStack original)
      : _mutators = List<Mutator>.from(original._mutators);

  final List<Mutator> _mutators;

  void pushClipRect(ui.Rect rect) {
    _mutators.add(Mutator.clipRect(rect));
  }

  void pushClipRRect(ui.RRect rrect) {
    _mutators.add(Mutator.clipRRect(rrect));
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

  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is MutatorsStack &&
        listEquals<Mutator>(other._mutators, _mutators);
  }

  int get hashCode => ui.hashList(_mutators);

  @override
  Iterator<Mutator> get iterator => _mutators.reversed.iterator;
}
