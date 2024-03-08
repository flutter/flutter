// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/ui.dart' as ui;

import '../../engine.dart' show PlatformViewManager;
import '../vector_math.dart';
import 'embedded_views.dart';
import 'picture.dart';
import 'rasterizer.dart';

/// If `true`, draws the computed bounds for platform views and pictures to
/// help debug issues with the overlay optimization.
bool debugOverlayOptimizationBounds = false;

/// A [Rendering] is a concrete description of how a Flutter scene will be
/// rendered in a web browser.
///
/// A [Rendering] is a sequence containing two types of entities:
///   * Render canvases: which contain rasterized CkPictures, and
///   * Platform views: being HTML content that is to be composited along with
///     the Flutter content.
class Rendering {
  final List<RenderingEntity> entities = <RenderingEntity>[];

  void add(RenderingEntity entity) {
    entities.add(entity);
  }

  /// Returns [true] if this is equibalent to [other] for use in rendering.
  bool equalsForRendering(Rendering other) {
    if (other.entities.length != entities.length) {
      return false;
    }
    for (int i = 0; i < entities.length; i++) {
      if (!entities[i].equalsForRendering(other.entities[i])) {
        return false;
      }
    }
    return true;
  }

  /// A list of just the canvases in the rendering.
  List<RenderingRenderCanvas> get canvases =>
      entities.whereType<RenderingRenderCanvas>().toList();

  @override
  String toString() => entities.toString();
}

/// An element of a [Rendering]. Either a render canvas or a platform view.
sealed class RenderingEntity {
  /// Returns [true] if this entity is equal to [other] for use in a rendering.
  ///
  /// For example, all [RenderingRenderCanvas] objects are equal to each other
  /// for purposes of rendering since any canvas in that place in the rendering
  /// will be equivalent. Platform views are only equal if they are for the same
  /// view id.
  bool equalsForRendering(RenderingEntity other);
}

class RenderingRenderCanvas extends RenderingEntity {
  RenderingRenderCanvas();

  /// The [pictures] which should be rendered in this canvas.
  final List<CkPicture> pictures = <CkPicture>[];

  /// The [DisplayCanvas] that will be used to display [pictures].
  ///
  /// This is set by the view embedder.
  DisplayCanvas? displayCanvas;

  /// Adds the [picture] to the pictures that should be rendered in this canvas.
  void add(CkPicture picture) {
    pictures.add(picture);
  }

  @override
  bool equalsForRendering(RenderingEntity other) {
    return other is RenderingRenderCanvas;
  }

  @override
  String toString() {
    return '$RenderingRenderCanvas(${pictures.length} pictures)';
  }
}

/// A platform view to be rendered.
class RenderingPlatformView extends RenderingEntity {
  RenderingPlatformView(this.viewId);

  /// The [viewId] of the platform view to render.
  final int viewId;

  @override
  bool equalsForRendering(RenderingEntity other) {
    return other is RenderingPlatformView && other.viewId == viewId;
  }

  @override
  String toString() {
    return '$RenderingPlatformView($viewId)';
  }

  /// The bounds that were computed for this platform view when creating the
  /// optimized rendering. This is only set in debug mode.
  ui.Rect? debugComputedBounds;
}

// Computes the bounds of the platform view from its associated parameters.
@visibleForTesting
ui.Rect computePlatformViewBounds(EmbeddedViewParams params) {
  ui.Rect currentClipBounds = ui.Rect.largest;

  Matrix4 currentTransform = Matrix4.identity();
  for (final Mutator mutator in params.mutators.reversed) {
    switch (mutator.type) {
      case MutatorType.clipRect:
        final ui.Rect transformedClipBounds =
            transformRectWithMatrix(currentTransform, mutator.rect!);
        currentClipBounds = currentClipBounds.intersect(transformedClipBounds);
      case MutatorType.clipRRect:
        final ui.Rect transformedClipBounds =
            transformRectWithMatrix(currentTransform, mutator.rrect!.outerRect);
        currentClipBounds = currentClipBounds.intersect(transformedClipBounds);
      case MutatorType.clipPath:
        final ui.Rect transformedClipBounds = transformRectWithMatrix(
            currentTransform, mutator.path!.getBounds());
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
  final ui.Rect transformedBounds =
      transformRectWithMatrix(currentTransform, rawBounds);
  return transformedBounds.intersect(currentClipBounds);
}

/// Returns the optimized [Rendering] for a sequence of [pictures] and
/// [platformViews].
///
/// [paramsForViews] is required to compute the bounds of the platform views.
Rendering createOptimizedRendering(
  List<CkPicture> pictures,
  List<int> platformViews,
  Map<int, EmbeddedViewParams> paramsForViews,
) {
  assert(pictures.length == platformViews.length + 1);

  final Rendering result = Rendering();

  // The first render canvas is required due to the pseudo-platform view "V_0"
  // which is defined as a platform view that comes before all Flutter drawing
  // commands and intersects with everything.
  RenderingRenderCanvas currentRenderCanvas = RenderingRenderCanvas();

  // This line essentially unwinds the first iteration of the following loop.
  // Since "V_0" intersects with all subsequent pictures, then the first picture
  // it intersects with is "P_0", so we create a new render canvas and add "P_0"
  // to it.
  if (!pictures[0].cullRect.isEmpty) {
    currentRenderCanvas.add(pictures[0]);
  }
  for (int i = 0; i < platformViews.length; i++) {
    final RenderingPlatformView platformView =
        RenderingPlatformView(platformViews[i]);
    if (PlatformViewManager.instance.isVisible(platformViews[i])) {
      final ui.Rect platformViewBounds =
          computePlatformViewBounds(paramsForViews[platformViews[i]]!);
      if (debugOverlayOptimizationBounds) {
        platformView.debugComputedBounds = platformViewBounds;
      }
      bool intersectsWithCurrentPictures = false;
      for (final CkPicture picture in currentRenderCanvas.pictures) {
        if (picture.cullRect.overlaps(platformViewBounds)) {
          intersectsWithCurrentPictures = true;
          break;
        }
      }
      if (intersectsWithCurrentPictures) {
        result.add(currentRenderCanvas);
        currentRenderCanvas = RenderingRenderCanvas();
      }
    }
    result.add(platformView);
    if (!pictures[i + 1].cullRect.isEmpty) {
      currentRenderCanvas.add(pictures[i + 1]);
    }
  }
  if (currentRenderCanvas.pictures.isNotEmpty) {
    result.add(currentRenderCanvas);
  }
  return result;
}
