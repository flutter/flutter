// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

/// Describes how a sliver's clip reacts to the area overlapped by other slivers.
///
/// Slivers may overlap, for example when a pinned [SliverAppBar] is stacked
/// on top of other content. This enum defines whether the content underneath
/// that overlap should be clipped out, and if so, how the shape of the clip
/// handles the dynamic boundary of the overlapping region.
///
/// See also:
///  * [SliverClipRRect.clipOverlap], which uses this behavior.
enum ClipOverlapBehavior {
  /// The clip ignores any overlap.
  ///
  /// Content covered by overlapping slivers will not be clipped out by this
  /// mechanism and may render underneath them if they are semi-transparent.
  none,

  /// The clip strictly follows the straight edge of the overlapping sliver.
  ///
  /// The clip rectangle is truncated along the axis of the scroll view so that
  /// it never intrudes into the overlap area.
  ///
  /// If the clip is shaped with rounded corners (like in [SliverClipRRect]),
  /// those corners will appear cut off (squared off) if they intersect the
  /// overlapping boundary.
  followEdge,

  /// The entire shape of the clip shifts inwards to preserve its form.
  ///
  /// Instead of simply slicing off the overlapped portion, the clip
  /// area is shrunk while preserving features like rounded corners. As the
  /// item scrolls underneath the overlap, the corners will visibly slide down
  /// so they are never hidden or prematurely sheared by the overlap boundary.
  preserveShape,
}

/// A sliver that clips its child using a rectangle.
///
/// By default, it clips the child to its bounds. It can also clip based on a
/// custom [clipper].
///
/// This widget is particularly useful when used in a [CustomScrollView] with
/// pinned slivers (like [SliverAppBar] with [SliverAppBar.pinned] set to true).
/// When [clipOverlap] is true (the default), it automatically clips the portion
/// of the child that is overlapped by the pinned sliver, preventing the child
/// from being visible underneath a semi-transparent or translucent pinned header.
///
/// {@tool snippet}
///
/// This example shows a [CustomScrollView] with a pinned [SliverAppBar] and a
/// [SliverClipRect] wrapping a list. As the list scrolls up, the items are
/// clipped so they don't appear behind the semi-transparent app bar.
///
/// ```dart
/// CustomScrollView(
///   slivers: <Widget>[
///     SliverAppBar(
///       pinned: true,
///       expandedHeight: 200.0,
///       backgroundColor: Colors.blue.withAlpha(128), // Semi-transparent
///       flexibleSpace: const FlexibleSpaceBar(
///         title: Text('SliverClipRect'),
///       ),
///     ),
///     SliverClipRect(
///       sliver: SliverList(
///         delegate: SliverChildBuilderDelegate(
///           (BuildContext context, int index) {
///             return Container(
///               height: 100.0,
///               color: index.isEven ? Colors.grey[200] : Colors.grey[300],
///               child: Center(child: Text('Item $index')),
///             );
///           },
///           childCount: 20,
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SliverClipRRect], which clips a sliver with a rounded rectangle.
///  * [ClipRect], which clips a box widget.
///  * [CustomClipper], for creating custom clips.
class SliverClipRect extends SingleChildRenderObjectWidget {
  /// Creates a sliver that clips its child.
  const SliverClipRect({
    super.key,
    required Widget sliver,
    this.clipper,
    this.clipBehavior = Clip.hardEdge,
    this.clipOverlap = true,
  }) : super(child: sliver);

  /// If non-null, determines which clip rectangle to use.
  final CustomClipper<Rect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  final Clip clipBehavior;

  /// Whether to automatically clip the portion of the child that is overlapped
  /// by preceding pinned slivers.
  ///
  /// If true, the clip rect will be adjusted to exclude the area defined by
  /// [SliverConstraints.overlap]. This is useful to ensure content passing
  /// underneath a semi-transparent pinned header is not visible.
  ///
  /// Defaults to true.
  final bool clipOverlap;

  @override
  RenderSliverClipRect createRenderObject(BuildContext context) {
    return RenderSliverClipRect(
      clipper: clipper,
      clipBehavior: clipBehavior,
      clipOverlap: clipOverlap,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverClipRect renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior
      ..clipOverlap = clipOverlap ? ClipOverlapBehavior.followEdge : ClipOverlapBehavior.none;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper, defaultValue: null),
    );
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.hardEdge));
    properties.add(DiagnosticsProperty<bool>('clipOverlap', clipOverlap, defaultValue: true));
  }
}

/// A sliver render object that clips its child.
class RenderSliverClipRect extends _RenderSliverCustomClip<Rect> {
  /// Creates a sliver render object for clipping.
  RenderSliverClipRect({super.clipper, super.clipBehavior = Clip.hardEdge, bool clipOverlap = true})
    : super(clipOverlap: clipOverlap ? ClipOverlapBehavior.followEdge : ClipOverlapBehavior.none);

  @override
  Rect buildClip() {
    final Rect maxPaintRect = getMaxPaintRect();
    Rect newClip = clipper?.getClip(maxPaintRect.size) ?? maxPaintRect;

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

    if (clipOverlap != ClipOverlapBehavior.none && constraints.overlap > 0) {
      final double clipOrigin = getClipOriginForOverlap(clipExtent);
      newClip = switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.down => copyNewClipWith(top: clipOrigin),
        AxisDirection.up => copyNewClipWith(bottom: geometry!.paintExtent - clipOrigin),
        AxisDirection.right => copyNewClipWith(left: clipOrigin),
        AxisDirection.left => copyNewClipWith(right: geometry!.paintExtent - clipOrigin),
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
      context.paintChild(child!, offset);
    }
  }
}

/// A sliver that clips its child using a rounded rectangle.
///
/// By default, it clips the child to its bounds with the given [borderRadius].
/// It can also clip based on a custom [clipper].
///
/// This widget is particularly useful when used in a [CustomScrollView] with
/// pinned slivers (like [SliverAppBar] with [SliverAppBar.pinned] set to true).
/// The [clipOverlap] parameter controls how the clip reacts to the area that
/// overlaps with a preceding pinned sliver:
///
///  * [ClipOverlapBehavior.followEdge] (default): the clip rectangle is
///    truncated at the overlap boundary. Rounded corners that fall within the
///    overlapped region are squared off.
///  * [ClipOverlapBehavior.preserveShape]: the entire rounded rectangle shifts
///    inward so that corners are never hidden by the overlap. This produces a
///    smoother visual when items scroll underneath a pinned header.
///  * [ClipOverlapBehavior.none]: the overlap is ignored and no additional
///    clipping is applied.
///
/// {@tool snippet}
///
/// This example shows a [CustomScrollView] with a pinned [SliverAppBar] and a
/// [SliverClipRRect] wrapping a list. As items scroll behind the translucent
/// app bar, they are clipped with rounded corners that stay visible thanks to
/// [ClipOverlapBehavior.preserveShape].
///
/// ```dart
/// CustomScrollView(
///   slivers: <Widget>[
///     SliverAppBar(
///       pinned: true,
///       expandedHeight: 200.0,
///       backgroundColor: Colors.blue.withAlpha(128), // Semi-transparent
///       flexibleSpace: const FlexibleSpaceBar(
///         title: Text('SliverClipRRect'),
///       ),
///     ),
///     SliverClipRRect(
///       borderRadius: BorderRadius.circular(16.0),
///       sliver: SliverList(
///         delegate: SliverChildBuilderDelegate(
///           (BuildContext context, int index) {
///             return Container(
///               height: 100.0,
///               color: index.isEven ? Colors.grey[200] : Colors.grey[300],
///               child: Center(child: Text('Item $index')),
///             );
///           },
///           childCount: 20,
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SliverClipRect], which clips a sliver with a rectangle.
///  * [ClipRRect], which clips a box widget with a rounded rectangle.
///  * [ClipOverlapBehavior], which describes the available overlap-clipping
///    strategies.
///  * [CustomClipper], for creating custom clips.
class SliverClipRRect extends SingleChildRenderObjectWidget {
  /// Creates a sliver that clips its child using a rounded rectangle.
  const SliverClipRRect({
    super.key,
    required Widget sliver,
    this.borderRadius = BorderRadius.zero,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    this.clipOverlap = ClipOverlapBehavior.followEdge,
  }) : super(child: sliver);

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  final BorderRadiusGeometry borderRadius;

  /// If non-null, determines which clip to use instead of the default
  /// rounded rectangle derived from [borderRadius].
  ///
  /// When a clipper is provided, [borderRadius] is ignored.
  final CustomClipper<RRect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  final Clip clipBehavior;

  /// How the clip reacts to the area overlapped by preceding pinned slivers.
  ///
  /// When set to [ClipOverlapBehavior.followEdge] (the default), the clip
  /// rectangle is truncated at the overlap boundary defined by
  /// [SliverConstraints.overlap]. Rounded corners that intersect this boundary
  /// will appear squared off.
  ///
  /// When set to [ClipOverlapBehavior.preserveShape], the entire rounded
  /// rectangle is shifted inward so that corners remain fully visible,
  /// producing a smoother visual effect as items scroll under a pinned header.
  ///
  /// When set to [ClipOverlapBehavior.none], no overlap clipping is applied
  /// and content may render underneath translucent pinned slivers.
  ///
  /// See [ClipOverlapBehavior] for details on each mode.
  final ClipOverlapBehavior clipOverlap;

  @override
  RenderSliverClipRRect createRenderObject(BuildContext context) {
    return RenderSliverClipRRect(
      borderRadius: borderRadius,
      clipper: clipper,
      clipBehavior: clipBehavior,
      clipOverlap: clipOverlap,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverClipRRect renderObject) {
    renderObject
      ..borderRadius = borderRadius
      ..clipper = clipper
      ..clipBehavior = clipBehavior
      ..clipOverlap = clipOverlap
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BorderRadiusGeometry>('borderRadius', borderRadius, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<CustomClipper<RRect>>('clipper', clipper, defaultValue: null),
    );
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

/// A sliver render object that clips its child using a rounded rectangle.
///
/// By default, [RenderSliverClipRRect] uses its own bounds as the base
/// rectangle for the clip, but the size and location of the clip can be
/// customized using a custom [clipper].
class RenderSliverClipRRect extends _RenderSliverCustomClip<RRect> {
  /// Creates a sliver render object for clipping with a rounded rectangle.
  RenderSliverClipRRect({
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
    super.clipper,
    super.clipBehavior = Clip.antiAlias,
    super.clipOverlap = ClipOverlapBehavior.followEdge,
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
    markNeedsPaint();
  }

  /// The text direction with which to resolve [borderRadius].
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
  }

  @override
  RRect buildClip() {
    final Rect maxPaintRect = getMaxPaintRect();

    RRect newClip =
        clipper?.getClip(maxPaintRect.size) ??
        borderRadius.resolve(textDirection).toRRect(maxPaintRect);

    if (clipOverlap != ClipOverlapBehavior.none && constraints.overlap > 0) {
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
        AxisDirection.down => copyNewClipWith(top: clipOrigin),
        AxisDirection.up => copyNewClipWith(bottom: geometry!.paintExtent - clipOrigin),
        AxisDirection.right => copyNewClipWith(left: clipOrigin),
        AxisDirection.left => copyNewClipWith(right: geometry!.paintExtent - clipOrigin),
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
    Clip clipBehavior = Clip.antiAlias,
    ClipOverlapBehavior clipOverlap = ClipOverlapBehavior.followEdge,
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

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  /// Whether to clip starting from the overlap area.
  ClipOverlapBehavior get clipOverlap => _clipOverlap;
  ClipOverlapBehavior _clipOverlap;
  set clipOverlap(ClipOverlapBehavior value) {
    if (_clipOverlap != value) {
      _clipOverlap = value;
      markNeedsPaint();
    }
  }

  T? _clip;
  @protected
  T buildClip();

  @visibleForTesting
  T? getClip() {
    if (clipBehavior == Clip.none) {
      _clip = null;
    } else {
      _clip ??= buildClip();
    }

    return _clip;
  }

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
    if (clipOverlap != ClipOverlapBehavior.none && mainAxisPosition < constraints.overlap) {
      return false;
    }

    if (clipBehavior != Clip.none) {
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
    return switch (clipBehavior) {
      Clip.none => null,
      Clip.hardEdge || Clip.antiAlias || Clip.antiAliasWithSaveLayer =>
        _clipper?.getApproximateClipRect(paintBounds.size) ?? Offset.zero & paintBounds.size,
    };
  }

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
    return clampDouble(
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
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.hardEdge));
    properties.add(
      EnumProperty<ClipOverlapBehavior>(
        'clipOverlap',
        clipOverlap,
        defaultValue: ClipOverlapBehavior.followEdge,
      ),
    );
  }
}
