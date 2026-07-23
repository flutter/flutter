// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show clampDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Describes how a sliver's clip reacts to the area overlapped by other slivers.
///
/// This enum defines whether the content underneath that overlap should be
/// clipped out, and if so, how the shape of the clip handles the dynamic
/// boundary of the overlapping region.
///
/// See also:
///
/// * [SliverClipRect.clipOverlap] and [SliverClipRRect.clipOverlap], which
///   use this behavior.
enum ClipOverlapBehavior {
  /// The clip ignores any overlap.
  ///
  /// Content covered by overlapping slivers will not be clipped out by this
  /// mechanism and may render underneath them if they are semi-transparent.
  none,

  /// The clip follows the edge of the overlapping sliver.
  ///
  /// The clip rectangle is truncated along the axis of the scroll view so that
  /// it never intrudes into the overlap area.
  followEdge,

  /// The entire shape of the clip shifts inwards to preserve its form.
  ///
  /// Instead of slicing off the overlapped portion, the clip area is shrunk
  /// while preserving features like rounded corners. As the item scrolls
  /// underneath the overlap, the corners will visibly slide down so they are
  /// never hidden or prematurely sheared by the overlap boundary.
  preserveShape,
}

/// A sliver render object that clips its child using a rectangle.
///
/// By default, [RenderSliverClipRect] uses its own bounds as the base
/// rectangle for the clip, but the size and location of the clip can be
/// customized using a custom [clipper].
class RenderSliverClipRect extends _RenderSliverCustomClip<Rect> {
  /// Creates a rectangular clip.
  ///
  /// If [clipper] is null, the clip will match the layout size and position of
  /// the child.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  RenderSliverClipRect({
    super.clipper,
    super.clipBehavior = .antiAlias,
    super.clipOverlap = .followEdge,
  });

  @override
  Rect buildClip() {
    final Rect maxPaintRect = getMaxPaintRect();
    Rect newClip = clipper?.getClip(maxPaintRect.size).shift(maxPaintRect.topLeft) ?? maxPaintRect;

    final double clipExtent = switch (constraints.axis) {
      Axis.horizontal => newClip.width,
      Axis.vertical => newClip.height,
    };

    Rect copyNewClipWith({double? left, double? top, double? right, double? bottom}) =>
        Rect.fromLTRB(
          left ?? newClip.left,
          top ?? newClip.top,
          right ?? newClip.right,
          bottom ?? newClip.bottom,
        );

    if (clipOverlap != ClipOverlapBehavior.none) {
      final double clipOrigin = getClipOriginForOverlap(clipExtent);
      newClip = switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.down => copyNewClipWith(top: math.max(newClip.top, clipOrigin)),
        AxisDirection.up => copyNewClipWith(
          bottom: math.min(newClip.bottom, geometry!.paintExtent - clipOrigin),
        ),
        AxisDirection.right => copyNewClipWith(left: math.max(newClip.left, clipOrigin)),
        AxisDirection.left => copyNewClipWith(
          right: math.min(newClip.right, geometry!.paintExtent - clipOrigin),
        ),
      };
    }
    return newClip;
  }

  @override
  bool clipContains(Offset offset, Rect clip) => clip.contains(offset);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !child!.geometry!.visible) {
      layer = null;
      return;
    }

    final Rect? clipRect = getClip();
    if (clipRect != null) {
      if (!clipRect.isEmpty) {
        layer = context.pushClipRect(
          needsCompositing,
          offset,
          clipRect,
          super.paint,
          clipBehavior: clipBehavior,
          oldLayer: layer as ClipRectLayer?,
        );
      } else {
        layer = null;
      }
    } else {
      layer = null;
      context.paintChild(child!, offset);
    }
  }
}

/// A sliver render object that clips its child using a rounded rectangle.
///
/// By default, [RenderSliverClipRRect] uses its own bounds as the base
/// rectangle for the clip, but the size and location of the clip can be
/// customized using a custom [clipper].
class RenderSliverClipRRect extends _RenderSliverCustomClip<RRect> {
  /// Creates a sliver render object for clipping with a rounded rectangle.
  ///
  /// The [borderRadius] defaults to [BorderRadius.zero], i.e. a rectangle with
  /// right-angled corners.
  ///
  /// If [clipper] is non-null, then [borderRadius] is ignored.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  RenderSliverClipRRect({
    BorderRadiusGeometry borderRadius = .zero,
    super.clipper,
    super.clipBehavior = .antiAlias,
    super.clipOverlap = .followEdge,
    TextDirection? textDirection,
  }) : _borderRadius = borderRadius,
       _textDirection = textDirection;

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  BorderRadiusGeometry get borderRadius => _borderRadius;
  BorderRadiusGeometry _borderRadius;
  set borderRadius(BorderRadiusGeometry value) {
    if (_borderRadius == value) {
      return;
    }
    _borderRadius = value;
    _markNeedsClip();
  }

  /// The text direction with which to resolve [borderRadius].
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedsClip();
  }

  @override
  RRect buildClip() {
    final Rect maxPaintRect = getMaxPaintRect();

    RRect newClip =
        clipper?.getClip(maxPaintRect.size).shift(maxPaintRect.topLeft) ??
        borderRadius.resolve(textDirection).toRRect(maxPaintRect);

    if (clipOverlap != ClipOverlapBehavior.none) {
      final double insideClipExtent = switch ((constraints.axis, clipOverlap)) {
        (Axis.horizontal, ClipOverlapBehavior.preserveShape) => newClip.middleRect.width,
        (Axis.vertical, ClipOverlapBehavior.preserveShape) => newClip.middleRect.height,
        (Axis.horizontal, _) => newClip.width,
        (Axis.vertical, _) => newClip.height,
      };
      final double clipOrigin = getClipOriginForOverlap(insideClipExtent);

      RRect copyNewClipWith({double? left, double? top, double? right, double? bottom}) =>
          RRect.fromLTRBAndCorners(
            left ?? newClip.left,
            top ?? newClip.top,
            right ?? newClip.right,
            bottom ?? newClip.bottom,
            topLeft: newClip.tlRadius,
            topRight: newClip.trRadius,
            bottomLeft: newClip.blRadius,
            bottomRight: newClip.brRadius,
          );

      newClip = switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.down => copyNewClipWith(top: math.max(newClip.top, clipOrigin)),
        AxisDirection.up => copyNewClipWith(
          bottom: math.min(newClip.bottom, geometry!.paintExtent - clipOrigin),
        ),
        AxisDirection.right => copyNewClipWith(left: math.max(newClip.left, clipOrigin)),
        AxisDirection.left => copyNewClipWith(
          right: math.min(newClip.right, geometry!.paintExtent - clipOrigin),
        ),
      };
    }

    return newClip;
  }

  @override
  bool clipContains(Offset offset, RRect clip) => clip.contains(offset);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !child!.geometry!.visible) {
      layer = null;
      return;
    }

    final RRect? clip = getClip();
    if (clip != null) {
      if (!clip.isEmpty) {
        layer = context.pushClipRRect(
          needsCompositing,
          offset,
          clip.outerRect,
          clip,
          super.paint,
          clipBehavior: clipBehavior,
          oldLayer: layer as ClipRRectLayer?,
        );
      } else {
        layer = null;
      }
    } else {
      layer = null;
      context.paintChild(child!, offset);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BorderRadiusGeometry>('borderRadius', borderRadius, defaultValue: null),
    );
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

abstract class _RenderSliverCustomClip<T> extends RenderProxySliver {
  _RenderSliverCustomClip({
    RenderSliver? sliver,
    CustomClipper<T>? clipper,
    Clip clipBehavior = .antiAlias,
    ClipOverlapBehavior clipOverlap = .followEdge,
  }) : _clipper = clipper,
       _clipBehavior = clipBehavior,
       _clipOverlap = clipOverlap,
       super(sliver);

  /// If non-null, determines which clip to use on the child.
  CustomClipper<T>? get clipper => _clipper;
  CustomClipper<T>? _clipper;
  set clipper(CustomClipper<T>? newClipper) {
    if (_clipper == newClipper) {
      return;
    }
    final CustomClipper<T>? oldClipper = _clipper;
    _clipper = newClipper;
    assert(newClipper != null || oldClipper != null);
    if (newClipper == null ||
        oldClipper == null ||
        newClipper.runtimeType != oldClipper.runtimeType ||
        newClipper.shouldReclip(oldClipper)) {
      _markNeedsClip();
    }
    if (attached) {
      oldClipper?.removeListener(_markNeedsClip);
      newClipper?.addListener(_markNeedsClip);
    }
  }

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior == value) {
      return;
    }
    _clipBehavior = value;
    _markNeedsClip();
  }

  /// Whether to clip starting from the overlap area.
  ClipOverlapBehavior get clipOverlap => _clipOverlap;
  ClipOverlapBehavior _clipOverlap;
  set clipOverlap(ClipOverlapBehavior value) {
    if (_clipOverlap == value) {
      return;
    }
    _clipOverlap = value;
    _markNeedsClip();
  }

  T? _clip;

  /// Builds the clip to apply to the child. This method is called lazily from
  /// [getClip] and the result is cached until the next time the render object is marked as needing paint.
  @protected
  T buildClip();

  /// Returns the clip to apply to the child, or null if no clipping is necessary.
  T? getClip() {
    if (clipBehavior == Clip.none) {
      _clip = null;
    } else {
      _clip ??= buildClip();
    }

    return _clip;
  }

  /// Returns whether the given offset is contained within the clip. This is used for hit testing and should be
  /// implemented by subclasses to match the shape of the clip.
  bool clipContains(Offset offset, T clip);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clipper?.addListener(_markNeedsClip);
  }

  @override
  void detach() {
    _clipper?.removeListener(_markNeedsClip);
    super.detach();
  }

  void _markNeedsClip() {
    _clip = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    super.performLayout();

    _clip = null;
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (clipBehavior != .none &&
        clipOverlap == .followEdge &&
        mainAxisPosition < constraints.overlap) {
      return false;
    }

    if (clipBehavior != .none) {
      final Offset hitOffset = switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.down => Offset(crossAxisPosition, mainAxisPosition),
        AxisDirection.right => Offset(mainAxisPosition, crossAxisPosition),
        AxisDirection.up => Offset(crossAxisPosition, geometry!.paintExtent - mainAxisPosition),
        AxisDirection.left => Offset(geometry!.paintExtent - mainAxisPosition, crossAxisPosition),
      };

      final T? clip = getClip();
      if (clip != null && !clipContains(hitOffset, clip)) {
        return false;
      }
    }

    return super.hitTest(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    final Rect maxPaintRect = getMaxPaintRect();
    return switch (clipBehavior) {
      .none => null,
      .hardEdge || .antiAlias || .antiAliasWithSaveLayer =>
        _clipper?.getApproximateClipRect(maxPaintRect.size).shift(maxPaintRect.topLeft) ??
            Offset.zero & paintBounds.size,
    };
  }

  /// Computes the main-axis offset at which the clip's leading edge should
  /// start so it reacts to the region overlapped by other slivers (such as a
  /// pinned header).
  ///
  /// The [insideClipExtent] is the part of the clip allowed to slide under the
  /// overlap before its edge moves: the full extent for
  /// [ClipOverlapBehavior.followEdge], or the middle rect for
  /// [ClipOverlapBehavior.preserveShape]. The result is clamped between the
  /// already-scrolled content and the current overlap.
  @protected
  double getClipOriginForOverlap(double insideClipExtent) {
    final double effectiveOverlap = math.max(0.0, constraints.overlap);
    final double flexibleClipExtent = math.max(
      0.0,
      insideClipExtent - geometry!.maxScrollObstructionExtent,
    );
    // To handle leading side of the viewport.
    final double minClipOrigin = -math.min(flexibleClipExtent, constraints.scrollOffset);

    // When flexibleClipExtent is scrolled, we can push up the clip.
    return ui.clampDouble(
      flexibleClipExtent - constraints.scrollOffset,
      minClipOrigin,
      effectiveOverlap,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<T>>('clipper', clipper, defaultValue: null));
    properties.add(DiagnosticsProperty<T?>('clip', _clip));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.antiAlias));
    properties.add(
      EnumProperty<ClipOverlapBehavior>(
        'clipOverlap',
        clipOverlap,
        defaultValue: ClipOverlapBehavior.followEdge,
      ),
    );
  }
}
