// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/ui.dart' as ui;

import '../../engine.dart' show PictureLayer, PlatformViewManager;
import '../compositing/composition.dart';
import '../platform_views/embedder.dart';
import '../vector_math.dart';

/// If `true`, draws the computed bounds for platform views and pictures to
/// help debug issues with the overlay optimization.
bool debugOverlayOptimizationBounds = false;

// Computes the bounds of the platform view from its associated parameters.
@visibleForTesting
ui.Rect computePlatformViewBounds(EmbeddedViewParams params) {
  ui.Rect currentClipBounds = ui.Rect.largest;

  Matrix4 currentTransform = Matrix4.identity();
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
  final ui.Rect rawBounds = ui.Rect.fromLTWH(
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
  final Map<int, ui.Rect> cachedComputedRects = <int, ui.Rect>{};

  final Composition result = Composition();

  // The first picture is added to the composition in a new canvas.
  CompositionCanvas tentativeCanvas = CompositionCanvas();

  for (final SceneElement sceneElement in sceneElements) {
    if (sceneElement is PlatformViewSceneElement) {
      final int viewId = sceneElement.viewId;
      final CompositionPlatformView platformView = CompositionPlatformView(viewId);
      if (PlatformViewManager.instance.isVisible(viewId)) {
        final ui.Rect platformViewBounds = cachedComputedRects[viewId] = computePlatformViewBounds(
          paramsForViews[viewId]!,
        );

        if (debugOverlayOptimizationBounds) {
          platformView.debugComputedBounds = platformViewBounds;
        }

        // If the platform view intersects with any pictures in the tentative canvas
        // then add the tentative canvas to the composition.
        for (final PictureLayer picture in tentativeCanvas.pictures) {
          if (!picture.sceneBounds!.intersect(platformViewBounds).isEmpty) {
            result.add(tentativeCanvas);
            tentativeCanvas = CompositionCanvas();
            break;
          }
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
      bool addedToTentativeCanvas = false;
      for (final PictureLayer canvasPicture in tentativeCanvas.pictures) {
        if (!canvasPicture.sceneBounds!.intersect(picture.sceneBounds!).isEmpty) {
          tentativeCanvas.add(picture);
          addedToTentativeCanvas = true;
          break;
        }
      }
      if (addedToTentativeCanvas) {
        continue;
      }

      CompositionCanvas? lastCanvasSeen;
      bool addedPictureToComposition = false;
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
          for (final PictureLayer canvasPicture in entity.pictures) {
            if (!canvasPicture.sceneBounds!.intersect(picture.sceneBounds!).isEmpty) {
              lastCanvasSeen.add(picture);
              addedPictureToComposition = true;
              break;
            }
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
