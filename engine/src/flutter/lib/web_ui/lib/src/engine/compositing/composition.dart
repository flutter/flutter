// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/ui.dart' as ui;

import '../../engine.dart' show OcclusionMap, PlatformViewManager;
import '../compositing/rasterizer.dart';
import '../layer/layer.dart';
import '../platform_views/embedder.dart';
import '../vector_math.dart';

/// If `true`, draws the computed bounds for platform views and pictures to
/// help debug issues with the overlay optimization.
bool debugOverlayOptimizationBounds = false;

/// A [Composition] is a concrete description of how a Flutter scene will be
/// rendered in a web browser.
///
/// A [Composition] is a sequence containing two types of entities:
///   * Canvases: which contain rasterized Pictures, and
///   * Platform views: being HTML content that is to be composited along with
///     the Flutter content.
class Composition {
  final List<CompositionEntity> entities = <CompositionEntity>[];

  void add(CompositionEntity entity) {
    entities.add(entity);
  }

  /// Returns [true] if this is equivalent to [other] for use in a composition.
  bool equalsForCompositing(Composition other) {
    if (other.entities.length != entities.length) {
      return false;
    }
    for (var i = 0; i < entities.length; i++) {
      if (!entities[i].equalsForCompositing(other.entities[i])) {
        return false;
      }
    }
    return true;
  }

  /// A list of just the canvases in the composition.
  List<CompositionCanvas> get canvases => entities.whereType<CompositionCanvas>().toList();

  @override
  String toString() => entities.toString();
}

/// An element of a [Composition]. Either a canvas or a platform view.
sealed class CompositionEntity {
  /// Returns [true] if this entity is equal to [other] for use in a
  /// composition.
  ///
  /// For example, all [CompositionCanvas] objects are equal to each other
  /// for purposes of rendering since any canvas in that place in the
  /// composition will be equivalent. Platform views are only equal if they are
  /// for the same view id.
  bool equalsForCompositing(CompositionEntity other);
}

class CompositionCanvas extends CompositionEntity {
  CompositionCanvas();

  final OcclusionMap _occlusionMap = OcclusionMap();

  /// The [pictures] which should be rendered in this canvas.
  final List<PictureLayer> pictures = <PictureLayer>[];

  /// The [DisplayCanvas] that will be used to display [pictures].
  ///
  /// This is set by the view embedder.
  DisplayCanvas? displayCanvas;

  /// Adds the [picture] to the pictures that should be rendered in this canvas.
  void add(PictureLayer picture) {
    pictures.add(picture);
    _occlusionMap.addRect(picture.sceneBounds!);
  }

  bool overlaps(ui.Rect rect) {
    return _occlusionMap.overlaps(rect);
  }

  @override
  bool equalsForCompositing(CompositionEntity other) {
    return other is CompositionCanvas;
  }

  @override
  String toString() {
    return '$CompositionCanvas(${pictures.length} pictures)';
  }
}

/// A platform view to be composited.
class CompositionPlatformView extends CompositionEntity {
  CompositionPlatformView(this.viewId);

  /// The [viewId] of the platform view to render.
  final int viewId;

  @override
  bool equalsForCompositing(CompositionEntity other) {
    return other is CompositionPlatformView && other.viewId == viewId;
  }

  @override
  String toString() {
    return '$CompositionPlatformView($viewId)';
  }

  /// The bounds that were computed for this platform view when creating the
  /// optimized composition. This is only set in debug mode.
  ui.Rect? debugComputedBounds;
}

// Computes the bounds of the platform view from its associated parameters.
@visibleForTesting
ui.Rect computePlatformViewBounds(EmbeddedViewParams params) {
  ui.Rect currentClipBounds = ui.Rect.largest;

  var currentTransform = Matrix4.identity();
  for (final Mutator mutator in params.mutators.reversed) {
    switch (mutator.type) {
      case MutatorType.clipRect:
        final ui.Rect transformedClipBounds = transformRectWithMatrix(
          currentTransform,
          mutator.rect!,
        );
        currentClipBounds = currentClipBounds.intersect(transformedClipBounds);
      case MutatorType.clipRRect:
        final ui.Rect transformedClipBounds = transformRectWithMatrix(
          currentTransform,
          mutator.rrect!.outerRect,
        );
        currentClipBounds = currentClipBounds.intersect(transformedClipBounds);
      case MutatorType.clipPath:
        final ui.Rect transformedClipBounds = transformRectWithMatrix(
          currentTransform,
          mutator.path!.getBounds(),
        );
        currentClipBounds.intersect(transformedClipBounds);
      case MutatorType.transform:
        currentTransform = currentTransform.multiplied(mutator.matrix!);
      case MutatorType.opacity:
        // Doesn't effect bounds.
        continue;
    }
  }

  // The width and height are in physical pixels already, so apply the inverse
  // scale since the transform already applied the scaling.
  final rawBounds = ui.Rect.fromLTWH(
    params.offset.dx,
    params.offset.dy,
    params.size.width,
    params.size.height,
  );
  final ui.Rect transformedBounds = transformRectWithMatrix(currentTransform, rawBounds);
  return transformedBounds.intersect(currentClipBounds);
}

/// Returns the optimized [Composition] for a sequence of [pictures] and
/// [platformViews].
///
/// [paramsForViews] is required to compute the bounds of the platform views.
Composition createOptimizedComposition(
  Iterable<SceneElement> sceneElements,
  Map<int, EmbeddedViewParams> paramsForViews,
) {
  final cachedComputedRects = <int, ui.Rect>{};

  final result = Composition();

  // The first picture is added to the composition in a new canvas.
  var tentativeCanvas = CompositionCanvas();

  for (final sceneElement in sceneElements) {
    if (sceneElement is PlatformViewSceneElement) {
      final int viewId = sceneElement.viewId;
      final platformView = CompositionPlatformView(viewId);
      if (PlatformViewManager.instance.isVisible(viewId)) {
        final ui.Rect platformViewBounds = cachedComputedRects[viewId] = computePlatformViewBounds(
          paramsForViews[viewId]!,
        );

        if (debugOverlayOptimizationBounds) {
          platformView.debugComputedBounds = platformViewBounds;
        }

        // If the platform view intersects with any pictures in the tentative canvas
        // then add the tentative canvas to the composition.
        if (tentativeCanvas.overlaps(platformViewBounds)) {
          result.add(tentativeCanvas);
          tentativeCanvas = CompositionCanvas();
        }
      }
      result.add(platformView);
    } else if (sceneElement is PictureSceneElement) {
      final PictureLayer picture = sceneElement.picture;
      if (picture.isCulled) {
        continue;
      }

      // Find the first canvas which comes after the last entity (picture
      // or platform view) that the next picture intersects with, and add the
      // picture to that canvas, or create a new canvas.

      // First check if the picture intersects with any pictures in the
      // tentative canvas, as this will be the last canvas in the composition
      // when it is eventually added.
      if (tentativeCanvas.overlaps(picture.sceneBounds!)) {
        tentativeCanvas.add(picture);
        continue;
      }

      CompositionCanvas? lastCanvasSeen;
      var addedPictureToComposition = false;
      for (final CompositionEntity entity in result.entities.reversed) {
        if (entity is CompositionPlatformView) {
          if (PlatformViewManager.instance.isVisible(entity.viewId)) {
            final ui.Rect platformViewBounds = cachedComputedRects[entity.viewId]!;
            if (!platformViewBounds.intersect(picture.sceneBounds!).isEmpty) {
              // The next picture intersects with a platform view already in the
              // result. Add this picture to the first canvas which comes
              // after this platform view or create one if none exists.
              if (lastCanvasSeen != null) {
                lastCanvasSeen.add(picture);
              } else {
                tentativeCanvas.add(picture);
              }
              addedPictureToComposition = true;
              break;
            }
          }
        } else if (entity is CompositionCanvas) {
          lastCanvasSeen = entity;
          // Check if we intersect with any pictures in this canvas.
          if (entity.overlaps(picture.sceneBounds!)) {
            entity.add(picture);
            addedPictureToComposition = true;
          }
        }
      }
      if (!addedPictureToComposition) {
        if (lastCanvasSeen != null) {
          // Add it to the last canvas seen in the composition, if any.
          lastCanvasSeen.add(picture);
        } else {
          tentativeCanvas.add(picture);
        }
      }
    }
  }

  if (tentativeCanvas.pictures.isNotEmpty) {
    result.add(tentativeCanvas);
  }

  return result;
}
