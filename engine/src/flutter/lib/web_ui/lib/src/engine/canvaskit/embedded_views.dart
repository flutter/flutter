// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:svg' as svg;

import 'package:ui/ui.dart' as ui;

import '../../engine.dart' show platformViewManager;
import '../configuration.dart';
import '../html/path_to_svg_clip.dart';
import '../platform_views/slots.dart';
import '../util.dart';
import '../vector_math.dart';
import '../window.dart';
import 'canvas.dart';
import 'initialization.dart';
import 'path.dart';
import 'picture_recorder.dart';
import 'surface.dart';
import 'surface_factory.dart';

/// This composites HTML views into the [ui.Scene].
class HtmlViewEmbedder {
  /// The [HtmlViewEmbedder] singleton.
  static HtmlViewEmbedder instance = HtmlViewEmbedder._();

  HtmlViewEmbedder._();

  /// If `true`, overlay canvases are disabled.
  ///
  /// This causes all drawing to go to a single canvas, with all of the platform
  /// views rendered over top. This may result in incorrect rendering with
  /// platform views.
  static bool get disableOverlays =>
      debugDisableOverlays || configuration.canvasKitMaximumSurfaces <= 1;

  /// Force the view embedder to disable overlays.
  ///
  /// This should never be used outside of tests.
  static bool debugDisableOverlays = false;

  /// The set of platform views using the backup surface.
  final Set<int> _viewsUsingBackupSurface = <int>{};

  /// Picture recorders which were created during the preroll phase.
  ///
  /// These picture recorders will be "claimed" in the paint phase by platform
  /// views being composited into the scene.
  final List<CkPictureRecorder> _pictureRecordersCreatedDuringPreroll =
      <CkPictureRecorder>[];

  /// The picture recorder shared by all platform views which paint to the
  /// backup surface.
  CkPictureRecorder? _backupPictureRecorder;

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

  /// The number of platform views in this frame which are visible.
  ///
  /// These platform views will require overlays.
  int _visibleViewCount = 0;

  /// The most recent composition order.
  List<int> _activeCompositionOrder = <int>[];

  /// The size of the frame, in physical pixels.
  ui.Size _frameSize = ui.window.physicalSize;

  set frameSize(ui.Size size) {
    _frameSize = size;
  }

  /// Returns a list of canvases which will be overlaid on top of the "base"
  /// canvas after a platform view is composited into the scene.
  ///
  /// The engine asks for the overlay canvases immediately before the paint
  /// phase, after the preroll phase. In the preroll phase we must be
  /// conservative and assume that every platform view which is prerolled is
  /// also composited, and therefore requires an overlay canvas. However, not
  /// every platform view which is prerolled ends up being composited (it may be
  /// clipped out and not actually drawn). This means that we may end up
  /// overallocating canvases. This isn't a problem in practice, however, as
  /// unused recording canvases are simply deleted at the end of the frame.
  List<CkCanvas> getOverlayCanvases() {
    if (disableOverlays) {
      return const <CkCanvas>[];
    }
    final List<CkCanvas> overlayCanvases = _pictureRecordersCreatedDuringPreroll
        .map((CkPictureRecorder r) => r.recordingCanvas!)
        .toList();
    if (_backupPictureRecorder != null) {
      overlayCanvases.add(_backupPictureRecorder!.recordingCanvas!);
    }
    return overlayCanvases;
  }

  void prerollCompositeEmbeddedView(int viewId, EmbeddedViewParams params) {
    if (!disableOverlays && platformViewManager.isVisible(viewId)) {
      // We must decide in the preroll phase if a platform view will use the
      // backup overlay, so that draw commands after the platform view will
      // correctly paint to the backup surface.
      bool needBackupSurface = false;
      if (_pictureRecordersCreatedDuringPreroll.length >=
          SurfaceFactory.instance.maximumOverlays) {
        needBackupSurface = true;
      }
      if (needBackupSurface) {
        if (_backupPictureRecorder == null) {
          // Only initialize the picture recorder for the backup surface once.
          final CkPictureRecorder pictureRecorder = CkPictureRecorder();
          pictureRecorder.beginRecording(ui.Offset.zero & _frameSize);
          pictureRecorder.recordingCanvas!.clear(const ui.Color(0x00000000));
          _backupPictureRecorder = pictureRecorder;
        }
      } else {
        final CkPictureRecorder pictureRecorder = CkPictureRecorder();
        pictureRecorder.beginRecording(ui.Offset.zero & _frameSize);
        pictureRecorder.recordingCanvas!.clear(const ui.Color(0x00000000));
        _pictureRecordersCreatedDuringPreroll.add(pictureRecorder);
      }
    }

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

  /// Prepares to composite [viewId].
  ///
  /// If this returns a [CkCanvas], then that canvas should be the new leaf
  /// node. Otherwise, keep the same leaf node.
  CkCanvas? compositeEmbeddedView(int viewId) {
    final int overlayIndex = _visibleViewCount;
    _compositionOrder.add(viewId);
    if (platformViewManager.isVisible(viewId)) {
      _visibleViewCount++;
    }
    final bool needOverlay =
        !disableOverlays && platformViewManager.isVisible(viewId);
    if (needOverlay) {
      if (overlayIndex < _pictureRecordersCreatedDuringPreroll.length) {
        _pictureRecorders[viewId] =
            _pictureRecordersCreatedDuringPreroll[overlayIndex];
      } else {
        _viewsUsingBackupSurface.add(viewId);
        _pictureRecorders[viewId] = _backupPictureRecorder!;
      }
    }

    // Do nothing if this view doesn't need to be composited.
    if (!_viewsToRecomposite.contains(viewId)) {
      if (needOverlay) {
        return _pictureRecorders[viewId]!.recordingCanvas;
      } else {
        return null;
      }
    }
    _compositeWithParams(viewId, _currentCompositionParams[viewId]!);
    _viewsToRecomposite.remove(viewId);
    if (needOverlay) {
      return _pictureRecorders[viewId]!.recordingCanvas;
    } else {
      return null;
    }
  }

  void _compositeWithParams(int viewId, EmbeddedViewParams params) {
    // If we haven't seen this viewId yet, cache it for clips/transforms.
    final ViewClipChain clipChain = _viewClipChains.putIfAbsent(viewId, () {
      return ViewClipChain(view: createPlatformViewSlot(viewId));
    });

    final html.Element slot = clipChain.slot;

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
      final html.Element oldPlatformViewRoot = clipChain.root;
      final html.Element newPlatformViewRoot = _reconstructClipViewsChain(
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
      final html.Element clippingView = html.Element.tag('flt-clip');
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
      for (final html.Element child in clipDefs.children) {
        if (oldDefs.contains(child.id)) {
          nodesToRemove.add(child);
        }
      }
      for (final html.Element node in nodesToRemove) {
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
          final html.Element clipView = head.parent!;
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
            final html.Element pathDefs =
                _svgPathDefs!.querySelector('#sk_path_defs')!;
            _clipPathCount += 1;
            final String clipId = 'svgClip$_clipPathCount';
            final svg.ClipPathElement newClipPath = svg.ClipPathElement();
            newClipPath.id = clipId;
            newClipPath.append(
                svg.PathElement()
                  ..setAttribute('d', path.toSvgString()!));

            pathDefs.append(newClipPath);
            // Store the id of the node instead of [newClipPath] directly. For
            // some reason, calling `newClipPath.remove()` doesn't remove it
            // from the DOM.
            _svgClipDefs.putIfAbsent(viewId, () => <String>{}).add(clipId);
            clipView.style.clipPath = 'url(#$clipId)';
          } else if (mutator.path != null) {
            final CkPath path = mutator.path! as CkPath;
            _ensureSvgPathDefs();
            final html.Element pathDefs =
                _svgPathDefs!.querySelector('#sk_path_defs')!;
            _clipPathCount += 1;
            final String clipId = 'svgClip$_clipPathCount';
            final svg.ClipPathElement newClipPath = svg.ClipPathElement();
            newClipPath.id = clipId;
            newClipPath.append(
                svg.PathElement()
                  ..setAttribute('d', path.toSvgString()!));
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
    _svgPathDefs = kSvgResourceHeader.clone(false) as svg.SvgSvgElement;
    _svgPathDefs!.append(svg.DefsElement()..id = 'sk_path_defs');
    skiaSceneHost!.append(_svgPathDefs!);
  }

  void submitFrame() {
    final ViewListDiffResult? diffResult = (_activeCompositionOrder.isEmpty ||
            _compositionOrder.isEmpty ||
            disableOverlays)
        ? null
        : diffViewList(
            _activeCompositionOrder
                .where((int viewId) => platformViewManager.isVisible(viewId))
                .toList(),
            _compositionOrder
                .where((int viewId) => platformViewManager.isVisible(viewId))
                .toList());
    final Map<int, int>? insertBeforeMap = _updateOverlays(diffResult);

    bool _didPaintBackupSurface = false;
    if (!disableOverlays) {
      for (int i = 0; i < _compositionOrder.length; i++) {
        final int viewId = _compositionOrder[i];
        if (platformViewManager.isInvisible(viewId)) {
          continue;
        }
        if (_viewsUsingBackupSurface.contains(viewId)) {
          // Only draw the picture to the backup surface once.
          if (!_didPaintBackupSurface) {
            final SurfaceFrame backupFrame =
                SurfaceFactory.instance.backupSurface.acquireFrame(_frameSize);
            backupFrame.skiaCanvas
                .drawPicture(_backupPictureRecorder!.endRecording());
            _backupPictureRecorder = null;
            backupFrame.submit();
            _didPaintBackupSurface = true;
          }
        } else {
          final SurfaceFrame frame =
              _overlays[viewId]!.acquireFrame(_frameSize);
          final CkCanvas canvas = frame.skiaCanvas;
          canvas.drawPicture(
            _pictureRecorders[viewId]!.endRecording(),
          );
          frame.submit();
        }
      }
    }
    _pictureRecordersCreatedDuringPreroll.clear();
    _pictureRecorders.clear();
    _viewsUsingBackupSurface.clear();
    if (listEquals(_compositionOrder, _activeCompositionOrder)) {
      _compositionOrder.clear();
      _visibleViewCount = 0;
      return;
    }

    final Set<int> unusedViews = Set<int>.from(_activeCompositionOrder);
    _activeCompositionOrder.clear();

    List<int>? debugInvalidViewIds;

    if (diffResult != null) {
      disposeViews(diffResult.viewsToRemove.toSet());
      _activeCompositionOrder.addAll(_compositionOrder);
      unusedViews.removeAll(_compositionOrder);

      html.Element? elementToInsertBefore;
      if (diffResult.addToBeginning) {
        elementToInsertBefore =
            _viewClipChains[diffResult.viewToInsertBefore!]!.root;
      }

      for (final int viewId in diffResult.viewsToAdd) {
        if (assertionsEnabled) {
          if (!platformViewManager.knowsViewId(viewId)) {
            debugInvalidViewIds ??= <int>[];
            debugInvalidViewIds.add(viewId);
            continue;
          }
        }
        if (diffResult.addToBeginning) {
          final html.Element platformViewRoot = _viewClipChains[viewId]!.root;
          skiaSceneHost!.insertBefore(platformViewRoot, elementToInsertBefore);
          final Surface? overlay = _overlays[viewId];
          if (overlay != null) {
            skiaSceneHost!
                .insertBefore(overlay.htmlElement, elementToInsertBefore);
          }
        } else {
          final html.Element platformViewRoot = _viewClipChains[viewId]!.root;
          skiaSceneHost!.append(platformViewRoot);
          final Surface? overlay = _overlays[viewId];
          if (overlay != null) {
            skiaSceneHost!.append(overlay.htmlElement);
          }
        }
      }
      insertBeforeMap?.forEach((int viewId, int viewIdToInsertBefore) {
        final html.Element overlay = _overlays[viewId]!.htmlElement;
        if (viewIdToInsertBefore != -1) {
          final html.Element nextSibling =
              _viewClipChains[viewIdToInsertBefore]!.root;
          skiaSceneHost!.insertBefore(overlay, nextSibling);
        } else {
          skiaSceneHost!.append(overlay);
        }
      });
      if (_didPaintBackupSurface) {
        skiaSceneHost!
            .append(SurfaceFactory.instance.backupSurface.htmlElement);
      }
    } else {
      SurfaceFactory.instance.removeSurfacesFromDom();
      for (int i = 0; i < _compositionOrder.length; i++) {
        final int viewId = _compositionOrder[i];

        if (assertionsEnabled) {
          if (!platformViewManager.knowsViewId(viewId)) {
            debugInvalidViewIds ??= <int>[];
            debugInvalidViewIds.add(viewId);
            continue;
          }
        }

        final html.Element platformViewRoot = _viewClipChains[viewId]!.root;
        final Surface? overlay = _overlays[viewId];
        skiaSceneHost!.append(platformViewRoot);
        if (overlay != null) {
          skiaSceneHost!.append(overlay.htmlElement);
        }
        _activeCompositionOrder.add(viewId);
        unusedViews.remove(viewId);
      }
      if (_didPaintBackupSurface) {
        skiaSceneHost!
            .append(SurfaceFactory.instance.backupSurface.htmlElement);
      }
    }

    _compositionOrder.clear();
    _visibleViewCount = 0;

    disposeViews(unusedViews);

    _pictureRecorders.clear();

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
      final ViewClipChain? clipChain = _viewClipChains.remove(viewId);
      clipChain?.root.remove();
      // More cleanup
      _currentCompositionParams.remove(viewId);
      _viewsToRecomposite.remove(viewId);
      _cleanUpClipDefs(viewId);
      _svgClipDefs.remove(viewId);
    }
  }

  void _releaseOverlay(int viewId) {
    if (_overlays[viewId] != null) {
      final Surface overlay = _overlays[viewId]!;
      SurfaceFactory.instance.releaseSurface(overlay);
      _overlays.remove(viewId);
    }
  }

  // Called right before compositing the scene.
  //
  // [_compositionOrder] and [_activeComposition] order should contain the
  // composition order of the current and previous frame, respectively.
  //
  // TODO(hterkelsen): Test this more thoroughly.
  Map<int, int>? _updateOverlays(ViewListDiffResult? diffResult) {
    if (_viewsUsingBackupSurface.isEmpty) {
      SurfaceFactory.instance
          .releaseSurface(SurfaceFactory.instance.backupSurface);
    }
    if (diffResult != null &&
        diffResult.viewsToAdd.isEmpty &&
        diffResult.viewsToRemove.isEmpty) {
      return null;
    }
    if (diffResult == null) {
      // Everything is going to be explicitly recomposited anyway. Release all
      // the surfaces and assign an overlay to the first N surfaces where
      // N = [SurfaceFactory.instance.maximumOverlays] and assign the rest
      // to the backup surface.
      SurfaceFactory.instance.releaseSurfaces();
      _overlays.clear();
      final List<int> viewsNeedingOverlays = _compositionOrder
          .where((int viewId) => platformViewManager.isVisible(viewId))
          .toList();
      final int numOverlays = math.min(
        SurfaceFactory.instance.maximumOverlays,
        viewsNeedingOverlays.length,
      );
      for (int i = 0; i < numOverlays; i++) {
        final int viewId = viewsNeedingOverlays[i];
        assert(!_viewsUsingBackupSurface.contains(viewId));
        _initializeOverlay(viewId);
      }
      _assertOverlaysInitialized();
      return null;
    } else {
      // We want to preserve the overlays in the "unchanged" section of the
      // diff result as much as possible. If `addToBeginning` is `false`, then
      // release the overlays for the views which were deleted from the
      // beginning of the composition order and try to reuse those overlays in
      // either the unchanged segment or the newly added views. If
      // `addToBeginning` is `true` then release the overlays for the deleted
      // views and from the unchanged segment and assign the newly added views
      // to them.
      diffResult.viewsToRemove.forEach(_releaseOverlay);
      final int availableOverlays =
          SurfaceFactory.instance.numAvailableOverlays;
      if (diffResult.addToBeginning) {
        // If we have enough overlays for the newly added views, then just use
        // them. Otherwise, we will need to release overlays from the unchanged
        // segment of view ids.
        if (diffResult.viewsToAdd.length > availableOverlays) {
          int viewsToDispose = math.min(SurfaceFactory.instance.maximumOverlays,
              diffResult.viewsToAdd.length - availableOverlays);
          // The first `maximumSurfaces` views in the previous composition order
          // had an overlay.
          int index = SurfaceFactory.instance.maximumOverlays -
              diffResult.viewsToAdd.length;
          while (viewsToDispose > 0) {
            // The first [maxOverlays - viewsAdded] active views should have
            // overlays. The rest should be removed.
            _releaseOverlay(_activeCompositionOrder[index++]);
            viewsToDispose--;
          }
        }

        // Now assign an overlay to the newly added views.
        final int overlaysToAssign = math.min(diffResult.viewsToAdd.length,
            SurfaceFactory.instance.numAvailableOverlays);
        for (int i = 0; i < overlaysToAssign; i++) {
          _initializeOverlay(diffResult.viewsToAdd[i]);
        }
        _assertOverlaysInitialized();
        return null;
      } else {
        // Use the overlays we just released for any platform views at the
        // beginning of the list which previously used the backup surface.
        int overlaysToAssign =
            math.min(_compositionOrder.length, availableOverlays);
        int index = 0;
        final int lastOriginalIndex =
            _activeCompositionOrder.length - diffResult.viewsToRemove.length;
        final Map<int, int> insertBeforeMap = <int, int>{};
        while (overlaysToAssign > 0 && index < _compositionOrder.length) {
          final bool activeView = index < lastOriginalIndex;
          final int viewId = _compositionOrder[index];
          if (!_overlays.containsKey(viewId) &&
              platformViewManager.isVisible(viewId)) {
            _initializeOverlay(viewId);
            overlaysToAssign--;
            if (activeView) {
              if (index + 1 < _compositionOrder.length) {
                insertBeforeMap[viewId] = _compositionOrder[index + 1];
              } else {
                insertBeforeMap[viewId] = -1;
              }
            }
          }
          index++;
        }
        _assertOverlaysInitialized();
        return insertBeforeMap;
      }
    }
  }

  void _assertOverlaysInitialized() {
    if (assertionsEnabled) {
      for (int i = 0; i < _compositionOrder.length; i++) {
        final int viewId = _compositionOrder[i];
        assert(_viewsUsingBackupSurface.contains(viewId) ||
            platformViewManager.isInvisible(viewId) ||
            _overlays[viewId] != null);
      }
    }
  }

  void _initializeOverlay(int viewId) {
    assert(!_overlays.containsKey(viewId) &&
        !_viewsUsingBackupSurface.contains(viewId));

    // Try reusing a cached overlay created for another platform view.
    final Surface overlay = SurfaceFactory.instance.getOverlay()!;
    overlay.createOrUpdateSurface(_frameSize);
    _overlays[viewId] = overlay;
  }

  /// Deletes SVG clip paths, useful for tests.
  void debugCleanupSvgClipPaths() {
    _svgPathDefs?.children.single.children.forEach(removeElement);
    _svgClipDefs.clear();
  }

  static void removeElement(html.Element element) {
    element.remove();
  }

  /// Clears the state of this view embedder. Used in tests.
  void debugClear() {
    final Set<int> allViews = platformViewManager.debugClear();
    disposeViews(allViews);
    _backupPictureRecorder?.endRecording();
    _backupPictureRecorder = null;
    _viewsUsingBackupSurface.clear();
    _pictureRecordersCreatedDuringPreroll.clear();
    _pictureRecorders.clear();
    _currentCompositionParams.clear();
    debugCleanupSvgClipPaths();
    _currentCompositionParams.clear();
    _viewClipChains.clear();
    _overlays.clear();
    _viewsToRecomposite.clear();
    _activeCompositionOrder.clear();
    _compositionOrder.clear();
    _visibleViewCount = 0;
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
      : _root = view,
        _slot = view;

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

  @override
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

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is MutatorsStack &&
        listEquals<Mutator>(other._mutators, _mutators);
  }

  @override
  int get hashCode => ui.hashList(_mutators);

  @override
  Iterator<Mutator> get iterator => _mutators.reversed.iterator;
}

/// The results of diffing the current composition order with the active
/// composition order.
class ViewListDiffResult {
  /// Views which should be removed from the scene.
  final List<int> viewsToRemove;

  /// Views to add to the scene.
  final List<int> viewsToAdd;

  /// If `true`, [viewsToAdd] should be added at the beginning of the scene.
  /// Otherwise, they should be added at the end of the scene.
  final bool addToBeginning;

  /// If [addToBeginning] is `true`, then this is the id of the platform view
  /// to insert [viewsToAdd] before.
  ///
  /// `null` if [addToBeginning] is `false`.
  final int? viewToInsertBefore;

  const ViewListDiffResult(
      this.viewsToRemove, this.viewsToAdd, this.addToBeginning,
      {this.viewToInsertBefore});
}

/// Diff the composition order with the active composition order. It is
/// common for the composition order and active composition order to differ
/// only slightly.
///
/// Consider a scrolling list of platform views; from frame
/// to frame the composition order will change in one of two ways, depending
/// on which direction the list is scrolling. One or more views will be added
/// to the beginning of the list, and one or more views will be removed from
/// the end of the list, with the order of the unchanged middle views
/// remaining the same.
// TODO(hterkelsen): Refactor to use [longestIncreasingSubsequence] and logic
// similar to `Surface._insertChildDomNodes` to efficiently handle more cases,
// https://github.com/flutter/flutter/issues/89611.
ViewListDiffResult? diffViewList(List<int> active, List<int> next) {
  if (active.isEmpty || next.isEmpty) {
    return null;
  }
  // If the [active] and [next] lists are in the expected form described above,
  // then either the first or last element of [next] will be in [active].
  int index = active.indexOf(next.first);
  if (index != -1) {
    // Verify that the active composition order is contained, in order, in the
    // next composition order.
    for (int i = 0; i + index < active.length; i++) {
      if (active[i + index] != next[i]) {
        return null;
      }
      if (i == next.length - 1) {
        if (index == 0) {
          return ViewListDiffResult(active.sublist(i + 1), const <int>[], true,
              viewToInsertBefore: next.first);
        } else {
          return ViewListDiffResult(
              active.sublist(0, index), const <int>[], false);
        }
      }
    }
    return ViewListDiffResult(
      active.sublist(0, index),
      next.sublist(active.length - index),
      false,
    );
  }

  index = active.lastIndexOf(next.last);
  if (index != -1) {
    for (int i = 0; index - i >= 0; i++) {
      if (next.length <= i || active[index - i] != next[next.length - 1 - i]) {
        return null;
      }
    }
    return ViewListDiffResult(
      active.sublist(index + 1),
      next.sublist(0, next.length - index - 1),
      true,
      viewToInsertBefore: active.first,
    );
  }

  return null;
}
