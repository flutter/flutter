// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'binding.dart';
import 'debug.dart';
import 'object.dart';
import 'viewport_offset.dart';

// CORE TYPES FOR SLIVERS
// The RenderSliver base class and its helper types.

/// The direction in which a sliver's contents are ordered, relative to the
/// scroll offset axis.
///
/// For example, a vertical alphabetical list that is going [AxisDirection.down]
/// with a [GrowthDirection.forward] would have the A at the top and the Z at
/// the bottom, with the A adjacent to the origin, as would such a list going
/// [AxisDirection.up] with a [GrowthDirection.reverse]. On the other hand, a
/// vertical alphabetical list that is going [AxisDirection.down] with a
/// [GrowthDirection.reverse] would have the Z at the top (at scroll offset
/// zero) and the A below it.
enum GrowthDirection {
  /// This sliver's contents are ordered so that the first item is at the lowest
  /// scroll offset, and later items are at greater scroll offsets. The
  /// direction in which the scroll offset increases is given by the
  /// [AxisDirection] of the sliver.
  forward,

  /// This sliver's contents are ordered so that the last item is at the lowest
  /// scroll offset, and earlier items are at greater scroll offsets. The
  /// direction in which the scroll offset increases is given by the
  /// [AxisDirection] of the sliver.
  reverse,
}

enum AxisDirection {
  /// Zero is at the bottom and positive values are above it: ⇈
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A at
  /// the bottom and the Z at the top. This is an unusual configuration.
  up,

  /// Zero is on the left and positive values are to the right of it: ⇉
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A on
  /// the left and the Z on the right. This is the ordinary reading order for a
  /// horizontal set of tabs in an English application, for example.
  right,

  /// Zero is at the top and positive values are below it: ⇊
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A at
  /// the top and the Z at the bottom. This is the ordinary reading order for a
  /// vertical list.
  down,

  /// Zero is to the right and positive values are to the left of it: ⇇
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A at
  /// the right and the Z at the left. This is the ordinary reading order for a
  /// horizontal set of tabs in a Hebrew application, for example.
  left,
}

/// Returns the [Axis] that contains the given [AxisDirection].
///
/// Specifically, returns [Axis.vertical] for [AxisDirection.up] and
/// [AxisDirection.down] and returns [Axis.horizontal] for [AxisDirection.left]
/// and [AxisDirection.right].
Axis axisDirectionToAxis(AxisDirection axisDirection) {
  assert(axisDirection != null);
  switch (axisDirection) {
    case AxisDirection.up:
    case AxisDirection.down:
      return Axis.vertical;
    case AxisDirection.left:
    case AxisDirection.right:
      return Axis.horizontal;
  }
  return null;
}

/// Returns the opposite of the given [AxisDirection].
///
/// Specifically, returns [AxisDirection.up] for [AxisDirection.down] (and
/// vice versa), as well as [AxisDirection.left] for [AxisDirection.right] (and
/// vice versa).
AxisDirection flipAxisDirection(AxisDirection axisDirection) {
  assert(axisDirection != null);
  switch (axisDirection) {
    case AxisDirection.up:
      return AxisDirection.down;
    case AxisDirection.right:
      return AxisDirection.left;
    case AxisDirection.down:
      return AxisDirection.up;
    case AxisDirection.left:
      return AxisDirection.right;
  }
  return null;
}

/// Flips the [AxisDirection] if the [GrowthDirection] is [GrowthDirection.reverse].
///
/// Specifically, returns `axisDirection` if `growthDirection` is
/// [GrowthDirection.forward], otherwise returns [flipAxisDirection] applied to
/// `axisDirection`.
///
/// This function is useful in [RenderSliver] subclasses that are given both an
/// [AxisDirection] and a [GrowthDirection] and wish to compute the
/// [AxisDirection] in which growth will occur.
AxisDirection applyGrowthDirectionToAxisDirection(AxisDirection axisDirection, GrowthDirection growthDirection) {
  assert(axisDirection != null);
  assert(growthDirection != null);
  switch (growthDirection) {
    case GrowthDirection.forward:
      return axisDirection;
    case GrowthDirection.reverse:
      return flipAxisDirection(axisDirection);
  }
  return null;
}

class SliverConstraints extends Constraints {
  const SliverConstraints({
    @required this.axisDirection,
    @required this.growthDirection,
    @required this.userScrollDirection,
    @required this.scrollOffset,
    @required this.overlap,
    @required this.remainingPaintExtent,
    @required this.crossAxisExtent,
    @required this.viewportMainAxisExtent,
  });

  SliverConstraints copyWith({
    AxisDirection axisDirection,
    GrowthDirection growthDirection,
    ScrollDirection userScrollDirection,
    double scrollOffset,
    double overlap,
    double remainingPaintExtent,
    double crossAxisExtent,
    double viewportMainAxisExtent,
  }) {
    return new SliverConstraints(
      axisDirection: axisDirection ?? this.axisDirection,
      growthDirection: growthDirection ?? this.growthDirection,
      userScrollDirection: userScrollDirection ?? this.userScrollDirection,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      overlap: overlap ?? this.overlap,
      remainingPaintExtent: remainingPaintExtent ?? this.remainingPaintExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      viewportMainAxisExtent: viewportMainAxisExtent ?? this.viewportMainAxisExtent,
    );
  }

  /// The direction in which the [scrollOffset] and [remainingPaintExtent]
  /// increase.
  final AxisDirection axisDirection;

  /// The direction in which the contents of slivers are ordered, relative to
  /// the [axisDirection].
  ///
  /// For example, if the [axisDirection] is [AxisDirection.up], and the
  /// [growthDirection] is [GrowthDirection.forward], then an alphabetical list
  /// will have A at the bottom, then B, then C, and so forth, with Z at the
  /// top, with the bottom of the A at scroll offset zero, and the top of the Z
  /// at the highest scroll offset.
  ///
  /// On the other hand, if the [axisDirection] is [AxisDirection.up] but the
  /// [growthDirection] is [GrowthDirection.reverse], then an alphabetical list
  /// will have A at the top, then B, then C, and so forth, with Z at the
  /// bottom, with the bottom of the Z at scroll offset zero, and the top of the
  /// A at the highest scroll offset.
  ///
  /// If a viewport has an overall [AxisDirection] of [AxisDirection.down], then
  /// slivers above the absolute zero offset will have an axis of
  /// [AxisDirection.up] and a growth direction of [GrowthDirection.reverse],
  /// while slivers below the absolute zero offset will have the same axis
  /// direction as the viewport and a growth direction of
  /// [GrowthDirection.forward]. (The slivers with a reverse growth direction
  /// still see only positive scroll offsets; the scroll offsets are reversed as
  /// well, with zero at the absolute zero point, and positive numbers going
  /// away from there.)
  ///
  /// In general, lists grow only in the positive scroll offset direction, so
  /// the only growth direction that is commonly seen is
  /// [GrowthDirection.forward].
  final GrowthDirection growthDirection;

  /// The direction in which the user is attempting to scroll, relative to the
  /// [axisDirection] and [growthDirection].
  ///
  /// For example, if [growthDirection] is [GrowthDirection.reverse] and
  /// [axisDirection] is [AxisDirection.down], then a
  /// [userScrollDirection.forward] means that the user is scrolling up, in the
  /// positive [scrollOffset] direction.
  final ScrollDirection userScrollDirection;

  /// The scroll offset, in this sliver's coordinate system, that corresponds to
  /// the earliest visible part of this sliver in the [AxisDirection].
  ///
  /// For example, if [AxisDirection] is [AxisDirection.down], then this is the
  /// scroll offset at the top of the visible portion of the sliver.
  ///
  /// Whether this corresponds to the beginning or the end of the sliver's
  /// contents depends on the [growthDirection].
  final double scrollOffset;

  /// The number of pixels from where the pixels corresponding to the
  /// [scrollOffset] will be painted up to the first pixel that has not yet been
  /// painted on by an earlier sliver, in the [axisDirection].
  ///
  /// For example, if the previous sliver had a [SliverGeometry.paintExtent] of
  /// 100.0 pixels but a [SliverGeometry.layoutExtent] of only 50.0 pixels,
  /// then the [overlap] of this sliver will be 50.0.
  ///
  /// This is typically ignored unless the sliver is itself going to be pinned
  /// or floating and wants to avoid doing so under the previous sliver.
  final double overlap;

  /// The number of pixels of content that the sliver should consider providing.
  /// (Providing more pixels than this is inefficient.)
  ///
  /// The actual number of pixels provided should be specified in the
  /// [RenderSliver.geometry] as [SliverGeometry.paintExtent].
  ///
  /// This value may be infinite, for example if the viewport is an
  /// unconstrained [RenderShrinkWrappingViewport].
  ///
  /// This value may be 0.0, for example if the sliver is scrolled off the
  /// bottom of a downwards vertical viewport.
  final double remainingPaintExtent;

  /// The number of pixels in the cross-axis.
  ///
  /// For a vertical list, this is the width of the sliver..
  final double crossAxisExtent;

  /// The number of pixels the viewport can display in the main axis.
  ///
  /// For a vertical list, this is the height of the viewport.
  final double viewportMainAxisExtent;

  Axis get axis => axisDirectionToAxis(axisDirection);

  /// Return what the [growthDirection] would be if the [axisDirection] was
  /// either [AxisDirection.down] or [AxisDirection.right].
  ///
  /// This is the same as [growthDirection] unless the [axisDirection] is either
  /// [AxisDirection.up] or [AxisDirection.left], in which case it is the
  /// opposite growth direction.
  ///
  /// This can be useful in combination with [axis] to view the [axisDirection]
  /// and [growthDirection] in different terms.
  GrowthDirection get normalizedGrowthDirection {
    assert(axisDirection != null);
    switch (axisDirection) {
      case AxisDirection.down:
      case AxisDirection.right:
        return growthDirection;
      case AxisDirection.up:
      case AxisDirection.left:
        switch (growthDirection) {
          case GrowthDirection.forward:
            return GrowthDirection.reverse;
          case GrowthDirection.reverse:
            return GrowthDirection.forward;
        }
        return null;
    }
    return null;
  }

  @override
  bool get isTight => false;

  @override
  bool get isNormalized {
    return scrollOffset >= 0.0
        && crossAxisExtent >= 0.0
        && viewportMainAxisExtent >= 0.0
        && remainingPaintExtent >= 0.0;
  }

  BoxConstraints asBoxConstraints({
    double minExtent: 0.0,
    double maxExtent: double.INFINITY,
    double crossAxisExtent,
  }) {
    crossAxisExtent ??= this.crossAxisExtent;
    switch (axis) {
      case Axis.horizontal:
        return new BoxConstraints(
          minHeight: crossAxisExtent,
          maxHeight: crossAxisExtent,
          minWidth: minExtent,
          maxWidth: maxExtent,
        );
      case Axis.vertical:
        return new BoxConstraints(
          minWidth: crossAxisExtent,
          maxWidth: crossAxisExtent,
          minHeight: minExtent,
          maxHeight: maxExtent,
        );
    }
    return null;
  }

  @override
  bool debugAssertIsValid({
    bool isAppliedConstraint: false,
    InformationCollector informationCollector
  }) {
    // TODO(ianh): make these show pretty errors
    assert(axis != null);
    assert(growthDirection != null);
    assert(scrollOffset != null);
    assert(overlap != null);
    assert(remainingPaintExtent != null);
    assert(crossAxisExtent != null);
    assert(viewportMainAxisExtent != null);
    assert(scrollOffset >= 0.0);
    assert(crossAxisExtent >= 0.0);
    assert(viewportMainAxisExtent >= 0.0);
    assert(remainingPaintExtent >= 0.0);
    assert(isNormalized); // should be redundant with earlier checks
    return true;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! SliverConstraints)
      return false;
    final SliverConstraints typedOther = other;
    assert(typedOther.debugAssertIsValid());
    return axisDirection == typedOther.axisDirection &&
           growthDirection == typedOther.growthDirection &&
           scrollOffset == typedOther.scrollOffset &&
           overlap == typedOther.overlap &&
           remainingPaintExtent == typedOther.remainingPaintExtent &&
           crossAxisExtent == typedOther.crossAxisExtent &&
           viewportMainAxisExtent == typedOther.viewportMainAxisExtent;
  }

  @override
  int get hashCode {
    return hashValues(axisDirection, growthDirection, scrollOffset, overlap, remainingPaintExtent, crossAxisExtent, viewportMainAxisExtent);
  }

  @override
  String toString() {
    return 'SliverConstraints('
             '$axisDirection, '
             '$growthDirection, '
             '$userScrollDirection, '
             'scrollOffset: ${scrollOffset.toStringAsFixed(1)}, '
             'remainingPaintExtent: ${remainingPaintExtent.toStringAsFixed(1)}, ' +
             (overlap != 0.0 ? 'overlap: ${overlap.toStringAsFixed(1)}, ' : '') +
             'crossAxisExtent: ${crossAxisExtent.toStringAsFixed(1)}' +
             'viewportMainAxisExtent: ${viewportMainAxisExtent.toStringAsFixed(1)}' +
           ')';
  }
}

class SliverGeometry {
  const SliverGeometry({
    this.scrollExtent: 0.0,
    this.paintExtent: 0.0,
    double layoutExtent,
    this.maxPaintExtent: 0.0,
    double hitTestExtent,
    bool visible,
    this.hasVisualOverflow: false,
    this.scrollOffsetCorrection: 0.0
  }) : layoutExtent = layoutExtent ?? paintExtent,
       hitTestExtent = hitTestExtent ?? paintExtent,
       visible = visible ?? paintExtent > 0.0;

  static final SliverGeometry zero = const SliverGeometry();

  /// The (estimated) total scroll extent that this sliver has content for. In
  /// other words, the scroll offset of the end of the last bit of content of
  /// this sliver.
  ///
  /// This value must be accurate if the [paintExtent] is less than the
  /// [SliverConstraints.remainingPaintExtent] provided during layout.
  final double scrollExtent;

  /// The amount of visual space that was taken by the sliver to render the
  /// subset of the sliver that covers all or part of the
  /// [SliverConstraints.remainingPaintExtent].
  ///
  /// This must be between zero and [SliverConstraints.remainingPaintExtent].
  ///
  /// This contributes to the calculation for the next sliver's
  /// [SliverConstraints.overlap].
  final double paintExtent;

  /// The distance from the first visible part of this sliver to the first
  /// visible part of the next sliver, assuming the next sliver's
  /// [SliverConstraints.scrollOffset] is zero.
  ///
  /// This must be between zero and [paintExtent]. It defaults to [paintExtent].
  final double layoutExtent;

  /// The (estimated) total paint extent that this sliver would be able to
  /// provide if the [SliverConstraints.remainingPaintExtent] was infinite.
  ///
  /// This is used by viewports that implement shrink-wrapping.
  ///
  /// By definition, this cannot be less than [paintExtent].
  final double maxPaintExtent;

  /// The distance from where this sliver started painting to the bottom of
  /// where it should accept hits.
  ///
  /// This must be between zero and [paintExtent]. It defaults to [paintExtent].
  final double hitTestExtent;

  /// Whether this sliver should be painted.
  ///
  /// By default, this is true if [paintExtent] is greater than zero, and
  /// false if [paintExtent] is zero.
  final bool visible;

  /// Whether this sliver has visual overflow.
  ///
  /// By default, this is false, which means the viewport does not need to clip
  /// its children. If any slivers have visual overflow, the viewport will apply
  /// a clip to its children.
  final bool hasVisualOverflow;

  /// If this is non-zero after [RenderSliver.performLayout] returns, the scroll
  /// offset will be adjusted by the parent and then the entire layout of the
  /// parent will be rerun.
  final double scrollOffsetCorrection;

  bool get debugAssertIsValid {
    assert(scrollExtent != null);
    assert(scrollExtent >= 0.0);
    assert(paintExtent != null);
    assert(paintExtent >= 0.0);
    assert(layoutExtent != null);
    assert(layoutExtent >= 0.0);
    assert(() {
      if (layoutExtent > paintExtent) {
        throw new FlutterError(
          'SliverGeometry has a layoutExtent that exceeds its paintExtent.\n' +
          _debugCompareFloats('paintExtent', paintExtent, 'layoutExtent', layoutExtent)
        );
      }
      return true;
    });
    assert(maxPaintExtent != null);
    assert(() {
      if (maxPaintExtent < paintExtent) {
        throw new FlutterError(
          'SliverGeometry has a maxPaintExtent that is less than its paintExtent.\n' +
          _debugCompareFloats('maxPaintExtent', maxPaintExtent, 'paintExtent', paintExtent) +
          'By definition, a sliver can\'t paint more than the maximum that it can paint!'
        );
      }
      return true;
    });
    assert(hitTestExtent != null);
    assert(hitTestExtent >= 0.0);
    assert(visible != null);
    assert(hasVisualOverflow != null);
    assert(scrollOffsetCorrection != null);
    assert(scrollOffsetCorrection == 0.0);
    return true;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('SliverGeometry(');
      buffer.write('scrollExtent: ${scrollExtent.toStringAsFixed(1)}, ');
      if (paintExtent > 0.0) {
        if (visible) {
          buffer.write('paintExtent: ${paintExtent.toStringAsFixed(1)}, ');
        } else {
          buffer.write('paintExtent: ${paintExtent.toStringAsFixed(1)} but not painting, ');
        }
      } else if (paintExtent == 0.0) {
        if (visible) {
          buffer.write('paintExtent: ${paintExtent.toStringAsFixed(1)} but visible, ');
        } else {
          buffer.write('hidden, ');
        }
      } else {
        buffer.write('paintExtent: ${paintExtent.toStringAsFixed(1)} (!), ');
      }
      if (layoutExtent != paintExtent)
        buffer.write('layoutExtent: ${layoutExtent.toStringAsFixed(1)}, ');
      buffer.write('maxPaintExtent: ${maxPaintExtent.toStringAsFixed(1)}, ');
      if (hitTestExtent != paintExtent)
        buffer.write('hitTestExtent: ${hitTestExtent.toStringAsFixed(1)}, ');
      if (hasVisualOverflow)
        buffer.write('hasVisualOverflow: true, ');
      buffer.write('scrollOffsetCorrection: ${scrollOffsetCorrection.toStringAsFixed(1)}');
    buffer.write(')');
    return buffer.toString();
  }
}

class SliverHitTestEntry extends HitTestEntry {
  const SliverHitTestEntry(RenderSliver target, {
    @required this.mainAxisPosition,
    @required this.crossAxisPosition,
  }) : super(target);

  @override
  RenderSliver get target => super.target;

  /// The distance in the [AxisDirection] from the edge of the sliver's painted
  /// area (as given by the [SliverConstraints.scrollOffset]) to the hit point.
  /// This can be an unusual direction, for example in the [AxisDirection.up]
  /// case this is a distance from the _bottom_ of the sliver's painted area.
  final double mainAxisPosition;

  /// The distance to the hit point in the axis opposite the
  /// [SliverConstraints.axis].
  ///
  /// If the cross axis is horizontal (i.e. the
  /// [SliverConstraints.axisDirection] is either [AxisDirection.down] or
  /// [AxisDirection.up]), then the `crossAxisPosition` is a distance from the
  /// left edge of the sliver. If the cross axis is vertical (i.e. the
  /// [SliverConstraints.axisDirection] is either [AxisDirection.right] or
  /// [AxisDirection.left]), then the `crossAxisPosition` is a distance from the
  /// top edge of the sliver.
  ///
  /// This is always a distance from the left or top of the parent, never a
  /// distance from the right or bottom.
  final double crossAxisPosition;

  @override
  String toString() => '${target.runtimeType}@(mainAxis: $mainAxisPosition, crossAxis: $crossAxisPosition)';
}

/// Parent data structure used by parents of slivers that position their
/// children using layout offsets.
///
/// This data structure is optimised for fast layout. It is best used by parents
/// that expect to have many children whose relative positions don't change even
/// when the scroll offset does.
class SliverLogicalParentData extends ParentData {
  /// The position of the child relative to the zero scroll offset.
  ///
  /// The number of pixels from from the zero scroll offset of the parent sliver
  /// (the line at which its [SliverConstraints.scrollOffset] is zero) to the
  /// side of the child closest to that offset.
  ///
  /// In a typical list, this does not change as the parent is scrolled.
  double layoutOffset = 0.0;

  @override
  String toString() => 'layoutOffset=${layoutOffset.toStringAsFixed(1)}';
}

class SliverLogicalContainerParentData extends SliverLogicalParentData with ContainerParentDataMixin<RenderSliver> { }

/// Parent data structure used by parents of slivers that position their
/// children using absolute coordinates. For example, used by [RenderViewport2].
///
/// This data structure is optimised for fast painting, at the cost of requiring
/// additional work during layout when the children change their offsets. It is
/// best used by parents that expect to have few children, especially if those
/// children will themselves be very tall relative to the parent.
class SliverPhysicalParentData extends ParentData {
  /// The position of the child relative to the parent.
  ///
  /// This is the distance from the top left visible corner of the parent to the
  /// top left visible corner of the sliver.
  Offset paintOffset = Offset.zero;

  void applyPaintTransform(Matrix4 transform) {
    transform.translate(paintOffset.dx, paintOffset.dy);
  }

  @override
  String toString() => 'paintOffset=$paintOffset';
}

class SliverPhysicalContainerParentData extends SliverPhysicalParentData with ContainerParentDataMixin<RenderSliver> { }

String _debugCompareFloats(String labelA, double valueA, String labelB, double valueB) {
  if (valueA.toStringAsFixed(1) != valueB.toStringAsFixed(1)) {
    return 'The $labelA is ${valueA.toStringAsFixed(1)}, but '
           'the $labelB is ${valueB.toStringAsFixed(1)}. ';
  }
  return 'The $labelA is $valueA, but the $labelB is $valueB. '
         'Maybe you have fallen prey to floating point rounding errors, and should explicitly '
         'apply the min() or max() functions, or the clamp() method, to the $labelB? ';
}

// ///
// /// ## Writing a RenderSliver subclass
// ///
// /// ### Painting
// ///
// /// The [paint] method is called with an [Offset] to the top-left corner of the
// /// sliver, _regardless of the axis direction_.
// ///
// /// ### childScrollOffset
// ///
// /// If the subclass positions children anywhere other than at scroll offset
// /// 0.0, you need to override [childScrollOffset]...
abstract class RenderSliver extends RenderObject {
  // layout input
  @override
  SliverConstraints get constraints => super.constraints;

  // layout output
  SliverGeometry get geometry => _geometry;
  SliverGeometry _geometry;
  set geometry(SliverGeometry value) {
    assert(!(debugDoingThisResize && debugDoingThisLayout));
    assert(sizedByParent || !debugDoingThisResize);
    assert(() {
      if ((sizedByParent && debugDoingThisResize) ||
          (!sizedByParent && debugDoingThisLayout))
        return true;
      assert(!debugDoingThisResize);
      String contract, violation, hint;
      if (debugDoingThisLayout) {
        assert(sizedByParent);
        violation = 'It appears that the geometry setter was called from performLayout().';
        hint = '';
      } else {
        violation = 'The geometry setter was called from outside layout (neither performResize() nor performLayout() were being run for this object).';
        if (owner != null && owner.debugDoingLayout)
          hint = 'Only the object itself can set its geometry. It is a contract violation for other objects to set it.';
      }
      if (sizedByParent)
        contract = 'Because this RenderSliver has sizedByParent set to true, it must set its geometry in performResize().';
      else
        contract = 'Because this RenderSliver has sizedByParent set to false, it must set its geometry in performLayout().';
      throw new FlutterError(
        'RenderSliver geometry setter called incorrectly.\n'
        '$violation\n'
        '$hint\n'
        '$contract\n'
        'The RenderSliver in question is:\n'
        '  $this'
      );
    });
    _geometry = value;
  }

  @override
  Rect get semanticBounds => paintBounds;

  @override
  Rect get paintBounds {
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        return new Rect.fromLTWH(
          0.0, 0.0,
          constraints.crossAxisExtent,
          geometry.paintExtent
        );
      case Axis.vertical:
        return new Rect.fromLTWH(
          0.0, 0.0,
          geometry.paintExtent,
          constraints.crossAxisExtent
        );
    }
    return null;
  }

  @override
  void debugResetSize() { }

  @override
  void debugAssertDoesMeetConstraints() {
    assert(geometry.debugAssertIsValid);
    assert(() {
      if (geometry.paintExtent > constraints.remainingPaintExtent) {
        throw new FlutterError(
          'SliverGeometry has a paintOffset that exceeds the remainingPaintExtent from the constraints.\n'
          'The render object whose geometry violates the constraints is the following:\n'
          '  ${toStringShallow('\n  ')}\n' +
          _debugCompareFloats('remainingPaintExtent', constraints.remainingPaintExtent,
                              'paintExtent', geometry.paintExtent) +
          'The paintExtent must cause the child sliver to paint within the viewport, and so '
          'cannot exceed the remainingPaintExtent.'
        );
      }
      return true;
    });
  }

  @override
  void performResize() {
    assert(false);
  }

  /// For a center sliver, the distance before the absolute zero scroll offset
  /// that this sliver can cover.
  ///
  /// For example, if an [AxisDirection.down] viewport with an
  /// [RenderViewport2.anchor] of 0.5 has a single sliver with a height of 100.0
  /// and its [centerOffsetAdjustment] returns 50.0, then the sliver will be
  /// centered in the viewport when the scroll offset is 0.0.
  ///
  /// The distance here is in the opposite direction of the
  /// [RenderViewport2.axisDirection], so values will typically be positive.
  double get centerOffsetAdjustment => 0.0;

  /// Determines the set of render objects located at the given position.
  ///
  /// Returns true if the given point is contained in this render object or one
  /// of its descendants. Adds any render objects that contain the point to the
  /// given hit test result.
  ///
  /// The caller is responsible for providing the position in the local
  /// coordinate space of the callee. The callee is responsible for checking
  /// whether the given position is within its bounds.
  ///
  /// Hit testing requires layout to be up-to-date but does not require painting
  /// to be up-to-date. That means a render object can rely upon [performLayout]
  /// having been called in [hitTest] but cannot rely upon [paint] having been
  /// called. For example, a render object might be a child of a [RenderOpacity]
  /// object, which calls [hitTest] on its children when its opacity is zero
  /// even through it does not [paint] its children.
  ///
  /// ## Coordinates for RenderSliver objects
  ///
  /// The `mainAxisPosition` is the distance in the [AxisDirection] (after
  /// applying the [GrowthDirection]) from the edge of the sliver's painted
  /// area. This can be an unusual direction, for example in the
  /// [AxisDirection.up] case this is a distance from the _bottom_ of the
  /// sliver's painted area.
  ///
  /// The `crossAxisPosition` is the distance in the other axis. If the cross
  /// axis is horizontal (i.e. the [SliverConstraints.axisDirection] is either
  /// [AxisDirection.down] or [AxisDirection.up]), then the `crossAxisPosition`
  /// is a distance from the left edge of the sliver. If the cross axis is
  /// vertical (i.e. the [SliverConstraints.axisDirection] is either
  /// [AxisDirection.right] or [AxisDirection.left]), then the
  /// `crossAxisPosition` is a distance from the top edge of the sliver.
  bool hitTest(HitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    if (mainAxisPosition >= 0.0 && mainAxisPosition < geometry.hitTestExtent &&
        crossAxisPosition >= 0.0 && crossAxisPosition < constraints.crossAxisExtent) {
      if (hitTestChildren(result, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition) ||
          hitTestSelf(mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition)) {
        result.add(new SliverHitTestEntry(
          this,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition
        ));
        return true;
      }
    }
    return false;
  }

  /// Override this method if this render object can be hit even if its
  /// children were not hit.
  ///
  /// Used by [hitTest]. If you override [hitTest] and do not call this
  /// function, then you don't need to implement this function.
  ///
  /// For a discussion of the semantics of the arguments, see [hitTest].
  @protected
  bool hitTestSelf({ @required double mainAxisPosition, @required double crossAxisPosition }) => false;

  /// Override this method to check whether any children are located at the
  /// given position.
  ///
  /// Typically children should be hit-tested in reverse paint order so that
  /// hit tests at locations where children overlap hit the child that is
  /// visually "on top" (i.e., paints later).
  ///
  /// Used by [hitTest]. If you override [hitTest] and do not call this
  /// function, then you don't need to implement this function.
  ///
  /// For a discussion of the semantics of the arguments, see [hitTest].
  @protected
  bool hitTestChildren(HitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) => false;

  /// Computes the portion of the region from `from` to `to` that is visible,
  /// assuming that only the region from the [SliverConstraints.scrollOffset]
  /// that is [SliverConstraints.remainingPaintExtent] high is visible, and that
  /// the relationship between scroll offsets and paint offsets is linear.
  ///
  /// For example, if the constraints have a scroll offset of 100 and a
  /// remaining paint extent of 100, and the arguments to this method describe
  /// the region 50..150, then the returned value would be 50 (from scroll
  /// offset 100 to scroll offset 150).
  ///
  /// This method is not useful if there is not a 1:1 relationship between
  /// consumed scroll offset and consumed paint extent. For example, if the
  /// sliver always paints the same amount but consumes a scroll offset extent
  /// that is proportional to the [SliverConstraints.scrollOffset], then this
  /// function's results will not be consistent.
  double calculatePaintOffset(SliverConstraints constraints, { @required double from, @required double to }) {
    assert(from <= to);
    final double a = constraints.scrollOffset;
    final double b = constraints.scrollOffset + constraints.remainingPaintExtent;
    // the clamp on the next line is to avoid floating point rounding errors
    return (to.clamp(a, b) - from.clamp(a, b)).clamp(0.0, constraints.remainingPaintExtent);
  }

  /// Returns the distance from the leading _visible_ edge of the sliver to the
  /// side of the given child closest to that edge.
  ///
  /// For example, if the [constraints] describe this sliver as having an axis
  /// direction of [AxisDirection.down], then this is the distance from the top
  /// of the visible portion of the sliver to the top of the child. On the other
  /// hand, if the [constraints] describe this sliver as having an axis
  /// direction of [AxisDirection.up], then this is the distance from the bottom
  /// of the visible portion of the sliver to the bottom of the child. In both
  /// cases, this is the direction of increasing
  /// [SliverConstraints.scrollOffset] and
  /// [SliverLogicalParentData.layoutOffset].
  ///
  /// Calling this for a child that is not visible is not valid.
  ///
  /// For children that are [RenderSliver]s, the leading edge of the _child_
  /// will be the leading _visible_ edge of the child, not the part of the child
  /// that would locally be a scroll offset 0.0. For children that are not
  /// [RenderSliver]s, for example a [RenderBox] child, it's the actual distance
  /// to the edge of the box, since those boxes do not know how to handle being
  /// scrolled.
  ///
  /// This is used by [RenderSliverHelpers.hitTestBoxChild]. If you do not use
  /// the [RenderSliverHelpers] mixin and do not call this method yourself, you
  /// do not need to implement this method.
  ///
  /// This method differs from [childScrollOffset] in that
  /// [childMainAxisPosition] gives the distance from the leading _visible_ edge
  /// of the sliver whereas [childScrollOffset] gives the distance from sliver's
  /// zero scroll offset.
  @protected
  double childMainAxisPosition(@checked RenderObject child) {
    assert(() {
      throw new FlutterError('$runtimeType does not implement childPosition.');
    });
    return 0.0;
  }

  @protected
  double childCrossAxisPosition(@checked RenderObject child) => 0.0;

  /// Returns the scroll offset for the leading edge of the given child.
  ///
  /// The `child` must be a child of this sliver.
  ///
  /// This method differs from [childMainAxisPosition] in that
  /// [childMainAxisPosition] gives the distance from the leading _visible_ edge
  /// of the sliver whereas [childScrollOffset] gives the distance from sliver's
  /// zero scroll offset.
  double childScrollOffset(@checked RenderObject child) {
    assert(child.parent == this);
    return 0.0;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(() {
      throw new FlutterError('$runtimeType does not implement applyPaintTransform.');
    });
  }

  /// This returns a [Size] with dimensions relative to the leading edge of the
  /// sliver, specifically the same offset that is given to the [paint] method.
  /// This means that the dimensions may be negative.
  @protected
  Size getAbsoluteSizeRelativeToOrigin() {
    assert(geometry != null);
    assert(!debugNeedsLayout);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return new Size(constraints.crossAxisExtent, -geometry.paintExtent);
      case AxisDirection.right:
        return new Size(geometry.paintExtent, constraints.crossAxisExtent);
      case AxisDirection.down:
        return new Size(constraints.crossAxisExtent, geometry.paintExtent);
      case AxisDirection.left:
        return new Size(-geometry.paintExtent, constraints.crossAxisExtent);
    }
    return null;
  }

  void _debugDrawArrow(Canvas canvas, Paint paint, Point p0, Point p1, GrowthDirection direction) {
    assert(() {
      if (p0 == p1)
        return true;
      assert(p0.x == p1.x || p0.y == p1.y); // must be axis-aligned
      final double d = (p1 - p0).distance * 0.2;
      Point temp;
      double dx1, dx2, dy1, dy2;
      switch (direction) {
        case GrowthDirection.forward:
          dx1 = dx2 = dy1 = dy2 = d;
          break;
        case GrowthDirection.reverse:
          temp = p0;
          p0 = p1;
          p1 = temp;
          dx1 = dx2 = dy1 = dy2 = -d;
          break;
      }
      if (p0.x == p1.x) {
        dx2 = -dx2;
      } else {
        dy2 = -dy2;
      }
      canvas.drawPath(
        new Path()
          ..moveTo(p0.x, p0.y)
          ..lineTo(p1.x, p1.y)
          ..moveTo(p1.x - dx1, p1.y - dy1)
          ..lineTo(p1.x, p1.y)
          ..lineTo(p1.x - dx2, p1.y - dy2),
        paint
      );
      return true;
    });
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled) {
        final double strokeWidth = math.min(4.0, geometry.paintExtent / 30.0);
        final Paint paint = new Paint()
          ..color = debugPaintSliverArrowColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..maskFilter = new MaskFilter.blur(BlurStyle.solid, strokeWidth);
        final double arrowExtent = geometry.paintExtent;
        final double padding = math.max(2.0, strokeWidth);
        final Canvas canvas = context.canvas;
        canvas.drawCircle(
          offset.translate(padding, padding).toPoint(),
          padding * 0.5,
          paint,
        );
        switch (constraints.axis) {
          case Axis.vertical:
            canvas.drawLine(
              offset.toPoint(),
              offset.translate(constraints.crossAxisExtent, 0.0).toPoint(),
              paint,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(constraints.crossAxisExtent * 1.0 / 4.0, padding).toPoint(),
              offset.translate(constraints.crossAxisExtent * 1.0 / 4.0, arrowExtent - padding).toPoint(),
              constraints.normalizedGrowthDirection,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(constraints.crossAxisExtent * 3.0 / 4.0, padding).toPoint(),
              offset.translate(constraints.crossAxisExtent * 3.0 / 4.0, arrowExtent - padding).toPoint(),
              constraints.normalizedGrowthDirection,
            );
            break;
          case Axis.horizontal:
            canvas.drawLine(
              offset.toPoint(),
              offset.translate(0.0, constraints.crossAxisExtent).toPoint(),
              paint,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(padding, constraints.crossAxisExtent * 1.0 / 4.0).toPoint(),
              offset.translate(arrowExtent - padding, constraints.crossAxisExtent * 1.0 / 4.0).toPoint(),
              constraints.normalizedGrowthDirection,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(padding, constraints.crossAxisExtent * 3.0 / 4.0).toPoint(),
              offset.translate(arrowExtent - padding, constraints.crossAxisExtent * 3.0 / 4.0).toPoint(),
              constraints.normalizedGrowthDirection,
            );
            break;
        }
      }
      return true;
    });
  }

  @override
  void handleEvent(PointerEvent event, SliverHitTestEntry entry) { }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('geometry: $geometry');
  }
}

/// Mixin for [RenderSliver] subclasses that provides some utility functions.
abstract class RenderSliverHelpers implements RenderSliver {

  bool _getRightWayUp(SliverConstraints constraints) {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    bool rightWayUp;
    switch (constraints.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.left:
        rightWayUp = false;
        break;
      case AxisDirection.down:
      case AxisDirection.right:
        rightWayUp = true;
        break;
    }
    assert(constraints.growthDirection != null);
    switch (constraints.growthDirection) {
      case GrowthDirection.forward:
        break;
      case GrowthDirection.reverse:
        rightWayUp = !rightWayUp;
        break;
    }
    assert(rightWayUp != null);
    return rightWayUp;
  }

  /// Utility function for [hitTestChildren] for use when the children are
  /// [RenderBox] widgets.
  ///
  /// This function takes care of converting the position from the sliver
  /// coordinate system to the cartesian coordinate system used by [RenderBox].
  ///
  /// This function relies on [childMainAxisPosition] to determine the position of
  /// child in question.
  ///
  /// Calling this for a child that is not visible is not valid.
  @protected
  bool hitTestBoxChild(HitTestResult result, RenderBox child, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    final bool rightWayUp = _getRightWayUp(constraints);
    double absolutePosition = mainAxisPosition - childMainAxisPosition(child);
    final double absoluteCrossAxisPosition = crossAxisPosition - childCrossAxisPosition(child);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        if (!rightWayUp)
          absolutePosition = child.size.width - absolutePosition;
        return child.hitTest(result, position: new Point(absolutePosition, absoluteCrossAxisPosition));
      case Axis.vertical:
        if (!rightWayUp)
          absolutePosition = child.size.height - absolutePosition;
        return child.hitTest(result, position: new Point(absoluteCrossAxisPosition, absolutePosition));
    }
    return false;
  }

  /// Utility function for [applyPaintTransform] for use when the children are
  /// [RenderBox] widgets.
  ///
  /// This function turns the value returned by [childMainAxisPosition] and
  /// [childCrossAxisPosition]for the child in question into a translation that
  /// it then applies to the given matrix.
  ///
  /// Calling this for a child that is not visible is not valid.
  @protected
  void applyPaintTransformForBoxChild(RenderBox child, Matrix4 transform) {
    final bool rightWayUp = _getRightWayUp(constraints);
    double delta = childMainAxisPosition(child);
    final double crossAxisDelta = childCrossAxisPosition(child);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        if (!rightWayUp)
          delta = geometry.paintExtent - child.size.width - delta;
        transform.translate(delta, crossAxisDelta);
        break;
      case Axis.vertical:
        if (!rightWayUp)
          delta = geometry.paintExtent - child.size.height - delta;
        transform.translate(crossAxisDelta, delta);
        break;
    }
  }
}


// THE MAIN VIEWPORT CLASS
// Transitions from the RenderBox world to the RenderSliver world.

typedef RenderSliver _Advancer(RenderSliver child);

abstract class RenderAbstractViewport implements RenderObject {
  static RenderAbstractViewport of(RenderObject object) {
    while (object != null) {
      if (object is RenderAbstractViewport)
        return object;
      object = object.parent;
    }
    return null;
  }

  double getOffsetToReveal(RenderObject descendant, double alignment);
}

// ///
// /// See also:
// ///
// /// - [RenderSliver], which explains more about the Sliver protocol.
// /// - [RenderBox], which explains more about the Box protocol.
// /// - [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
// ///   placed inside a [RenderSliver] (the opposite of this class).
abstract class RenderViewportBase2<ParentDataClass extends ContainerParentDataMixin<RenderSliver>>
    extends RenderBox with ContainerRenderObjectMixin<RenderSliver, ParentDataClass>
    implements RenderAbstractViewport {
  RenderViewportBase2({
    AxisDirection axisDirection: AxisDirection.down,
    @required ViewportOffset offset,
  }) : _axisDirection = axisDirection,
       _offset = offset {
    assert(axisDirection != null);
    assert(offset != null);
  }

  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _axisDirection)
      return;
    _axisDirection = value;
    markNeedsLayout();
  }

  Axis get axis => axisDirectionToAxis(axisDirection);

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset)
      return;
    if (attached)
      _offset.removeListener(markNeedsLayout);
    if (_offset.pixels != value.pixels)
      markNeedsLayout();
    _offset = value;
    if (attached)
      _offset.addListener(markNeedsLayout);
    if (hasSize) {
      // If we already have a size, then we should re-report the dimensions
      // to the new ViewportOffset. If we don't then we'll report them when
      // we establish the dimensions later, so don't worry about it now.
      if (!rereportDimensions())
        markNeedsLayout();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @protected
  double layoutOneSide(
    RenderSliver child,
    double scrollOffset,
    double layoutOffset,
    double remainingPaintExtent,
    double mainAxisExtent,
    double crossAxisExtent,
    GrowthDirection growthDirection,
    _Advancer advance,
  ) {
    assert(scrollOffset.isFinite);
    assert(scrollOffset >= 0.0);
    ScrollDirection adjustedUserScrollDirection;
    switch (growthDirection) {
      case GrowthDirection.forward:
        adjustedUserScrollDirection = offset.userScrollDirection;
        break;
      case GrowthDirection.reverse:
        switch (offset.userScrollDirection) {
          case ScrollDirection.forward:
            adjustedUserScrollDirection = ScrollDirection.reverse;
            break;
          case ScrollDirection.reverse:
            adjustedUserScrollDirection = ScrollDirection.forward;
            break;
          case ScrollDirection.idle:
            adjustedUserScrollDirection = ScrollDirection.idle;
            break;
        }
        break;
    }
    assert(adjustedUserScrollDirection != null);
    double maxPaintOffset = layoutOffset;
    double initialLayoutOffset = layoutOffset;
    while (child != null) {
      assert(scrollOffset >= 0.0);
      child.layout(new SliverConstraints(
        axisDirection: axisDirection,
        growthDirection: growthDirection,
        userScrollDirection: adjustedUserScrollDirection,
        scrollOffset: scrollOffset,
        overlap: maxPaintOffset - layoutOffset,
        remainingPaintExtent: math.max(0.0, remainingPaintExtent - layoutOffset + initialLayoutOffset),
        crossAxisExtent: crossAxisExtent,
        viewportMainAxisExtent: mainAxisExtent,
      ), parentUsesSize: true);
      // collect the child's objects
      final SliverGeometry childLayoutGeometry = child.geometry;

      assert(childLayoutGeometry.debugAssertIsValid);

      // first check that there isn't a correction to apply. If there is we'll
      // have to start over.
      if (childLayoutGeometry.scrollOffsetCorrection != 0.0)
        return childLayoutGeometry.scrollOffsetCorrection;

      // geometry
      updateChildLayoutOffset(child, layoutOffset, growthDirection);
      maxPaintOffset = math.max(layoutOffset + childLayoutGeometry.paintExtent, maxPaintOffset);
      scrollOffset -= childLayoutGeometry.scrollExtent;
      layoutOffset += childLayoutGeometry.layoutExtent;

      if (scrollOffset <= 0.0)
        scrollOffset = 0.0;

      updateOutOfBoundsData(growthDirection, childLayoutGeometry);

      // move on to the next child
      child = advance(child);
    }

    // we made it without a correction, whee!
    return 0.0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null)
      return;
    if (hasVisualOverflow) {
      context.pushClipRect(needsCompositing, offset, Point.origin & size, paintContents);
    } else {
      paintContents(context, offset);
    }
  }

  @protected
  void paintContents(PaintingContext context, Offset offset) {
    for (RenderSliver child in childrenInPaintOrder) {
      if (child.geometry.visible)
        context.paintChild(child, offset + paintOffsetOf(child));
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      super.debugPaintSize(context, offset);
      final Paint paint = new Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF00FF00);
      final Canvas canvas = context.canvas;
      RenderSliver child = firstChild;
      while (child != null) {
        Size size;
        switch (axis) {
          case Axis.vertical:
            size = new Size(child.constraints.crossAxisExtent, child.geometry.layoutExtent);
            break;
          case Axis.horizontal:
            size = new Size(child.geometry.layoutExtent, child.constraints.crossAxisExtent);
            break;
        }
        assert(size != null);
        canvas.drawRect(((offset + paintOffsetOf(child)) & size).deflate(0.5), paint);
        child = childAfter(child);
      }
      return true;
    });
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    double mainAxisPosition, crossAxisPosition;
    switch (axis) {
      case Axis.vertical:
        mainAxisPosition = position.y;
        crossAxisPosition = position.x;
        break;
      case Axis.horizontal:
        mainAxisPosition = position.x;
        crossAxisPosition = position.y;
        break;
    }
    assert(mainAxisPosition != null);
    assert(crossAxisPosition != null);
    for (RenderSliver child in childrenInHitTestOrder) {
      if (child.geometry.visible && child.hitTest(
        result,
        mainAxisPosition: computeChildMainAxisPosition(child, mainAxisPosition),
        crossAxisPosition: crossAxisPosition
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  double getOffsetToReveal(RenderObject descendant, double alignment) {
    // TODO(abath): Implement this function for sliver-based viewports.
    return 0.0;
  }

  @protected
  Offset computeAbsolutePaintOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection) {
    assert(hasSize); // this is only usable once we have a size
    assert(axisDirection != null);
    assert(growthDirection != null);
    assert(child != null);
    assert(child.geometry != null);
    switch (applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
      case AxisDirection.up:
        return new Offset(0.0, size.height - (layoutOffset + child.geometry.paintExtent));
      case AxisDirection.right:
        return new Offset(layoutOffset, 0.0);
      case AxisDirection.down:
        return new Offset(0.0, layoutOffset);
      case AxisDirection.left:
        return new Offset(size.width - (layoutOffset + child.geometry.paintExtent), 0.0);
    }
    return null;
  }

  // TODO(ianh): semantics - shouldn't walk the invisible children

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    description.add('offset: $offset');
  }

  @override
  String debugDescribeChildren(String prefix) {
    if (firstChild == null)
      return '$prefix\n';
    int count = indexOfFirstChild();
    String result = '$prefix \u2502\n';
    RenderSliver child = firstChild;
    while (child != lastChild) {
      result += '${child.toStringDeep("$prefix \u251C\u2500${labelForChild(count)}: ", "$prefix \u2502")}';
      count += 1;
      child = childAfter(child);
    }
    assert(child == lastChild);
    result += '${child.toStringDeep("$prefix \u2514\u2500${labelForChild(count)}: ", "$prefix  ")}';
    return result;
  }

  // API TO BE IMPLEMENTED BY SUBCLASSES

  // setupParentData

  // performLayout (and optionally sizedByParent and performResize)

  @protected
  bool get hasVisualOverflow;

  @protected
  void updateOutOfBoundsData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry);

  @protected
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection);

  @protected
  Offset paintOffsetOf(RenderSliver child);

  // applyPaintTransform

  /// Converts the `parentMainAxisPosition` into the child's coordinate system.
  ///
  /// The `parentMainAxisPosition` is a distance from the top edge (for vertical
  /// viewports) or left edge (for horizontal viewports) of the viewport bounds.
  /// This describes a line, perpendicular to the viewport's main axis, heretofor
  /// known as the target line.
  ///
  /// The child's coordinate system's origin in the main axis is at the leading
  /// edge of the given child, as given by the child's
  /// [SliverConstraints.axisDirection] and [SliverConstraints.growthDirection].
  ///
  /// This method returns the distance from the leading edge of the given child to
  /// the target line described above.
  ///
  /// (The `parentMainAxisPosition` is not from the leading edge of the
  /// viewport, it's always the top or left edge.)
  @protected
  double computeChildMainAxisPosition(RenderSliver child, double parentMainAxisPosition);

  /// Notifies the [offset] of the render object's new dimensions.
  ///
  /// Implementations must call [ViewportOffset.applyViewportDimension] and
  /// [ViewportOffset.applyContentDimensions], in that order.
  ///
  /// Return the value returned by [ViewportOffset.applyContentDimensions]:
  /// false if the [ViewportOffset] did not accept the new dimensions
  /// unconditionally, but instead wants to relayout the render object (e.g.
  /// because it changed its mind about the actual offset that the viewport
  /// should be laid out at), and true if the [ViewportOffset] was happy with
  /// the given dimensions and does not think that anything need change. If this
  /// function returns false, the caller will call [markNeedsLayout].
  @protected
  bool rereportDimensions();

  @protected
  int indexOfFirstChild();

  @protected
  String labelForChild(int index);

  /// Provides an iterable that walks the children of the viewport, in the order
  /// that they should be painted.
  ///
  /// This should be the reverse order of [childrenInHitTestOrder].
  @protected
  Iterable<RenderSliver> get childrenInPaintOrder;

  /// Provides an iterable that walks the children of the viewport, in the order
  /// that hit-testing should use.
  ///
  /// This should be the reverse order of [childrenInPaintOrder].
  @protected
  Iterable<RenderSliver> get childrenInHitTestOrder;
}

// ///
// /// See also:
// ///
// /// - [RenderSliver], which explains more about the Sliver protocol.
// /// - [RenderBox], which explains more about the Box protocol.
// /// - [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
// ///   placed inside a [RenderSliver] (the opposite of this class).
// /// - [RenderShrinkWrappingViewport], a variant of [RenderViewport2] that
// ///   shrink-wraps its contents along the main axis.
class RenderViewport2 extends RenderViewportBase2<SliverPhysicalContainerParentData> {
  /// Creates a viewport for [RenderSliver] objects.
  ///
  /// If the [center] is not specified, then the first child in the `children`
  /// list, if any, is used.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [new ViewportOffset.zero] or [new ViewportOffset.fixed].
  RenderViewport2({
    AxisDirection axisDirection: AxisDirection.down,
    @required ViewportOffset offset,
    double anchor: 0.0,
    List<RenderSliver> children,
    RenderSliver center,
  }) : _anchor = anchor,
       _center = center,
       super(axisDirection: axisDirection, offset: offset) {
    assert(anchor != null);
    assert(anchor >= 0.0 && anchor <= 1.0);
    addAll(children);
    if (center == null && firstChild != null)
      _center = firstChild;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData)
      child.parentData = new SliverPhysicalContainerParentData();
  }

  double get anchor => _anchor;
  double _anchor;
  set anchor(double value) {
    assert(value != null);
    assert(value >= 0.0 && value <= 1.0);
    if (value == _anchor)
      return;
    _anchor = value;
    markNeedsLayout();
  }

  RenderSliver get center => _center;
  RenderSliver _center;
  set center(RenderSliver value) {
    if (value == _center)
      return;
    _center = value;
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);
    size = constraints.biggest;
    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
        break;
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
        break;
    }
  }

  static const int _kMaxLayoutCycles = 10;

  // Out-of-band data computed during layout.
  double _minScrollExtent;
  double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }
    assert(center.parent == this);

    double mainAxisExtent;
    double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        mainAxisExtent = size.height;
        crossAxisExtent = size.width;
        break;
      case Axis.horizontal:
        mainAxisExtent = size.width;
        crossAxisExtent = size.height;
        break;
    }

    final double centerOffsetAdjustment = center.centerOffsetAdjustment;

    double correction;
    int count = 0;
    do {
      assert(offset.pixels != null);
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent, offset.pixels + centerOffsetAdjustment);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        // when updating this, also update rereportDimensions
        if (offset.applyContentDimensions(
              math.min(0.0, _minScrollExtent + mainAxisExtent * anchor),
              math.max(0.0, _maxScrollExtent - mainAxisExtent * (1.0 - anchor)),
           ))
          break;
      }
      count += 1;
    } while (count < _kMaxLayoutCycles);
    assert(() {
      if (count >= _kMaxLayoutCycles) {
        assert(count != 1);
        throw new FlutterError(
          'A RenderViewport2 exceeded its maximum number of layout cycles.\n'
          'RenderViewport2 render objects, during layout, can retry if either their '
          'slivers or their ViewportOffset decide that the offset should be corrected '
          'to take into account information collected during that layout.\n'
          'In the case of this RenderViewport2 object, however, this happened $count '
          'times and still there was no consensus on the scroll offset. This usually '
          'indicates a bug. Specifically, it means that one of the following three '
          'problems is being experienced by the RenderViewport2 object:\n'
          ' * One of the RenderSliver children or the ViewportOffset have a bug such'
          ' that they always think that they need to correct the offset regardless.\n'
          ' * Some combination of the RenderSliver children and the ViewportOffset'
          ' have a bad interaction such that one applies a correction then another'
          ' applies a reverse correction, leading to an infinite loop of corrections.\n'
          ' * There is a pathological case that would eventually resolve, but it is'
          ' so complicated that it cannot be resolved in any reasonable number of'
          ' layout passes.'
        );
      }
      return true;
    });
  }

  double _attemptLayout(double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _hasVisualOverflow = false;

    // centerOffset is the offset from the leading edge of the RenderViewport2
    // to the zero scroll offset (the line between the forward slivers and the
    // reverse slivers). The other two are that, but clamped to the visible
    // region of the viewport.
    final double centerOffset = mainAxisExtent * anchor - correctedOffset;
    final double clampedForwardCenter = math.max(0.0, math.min(mainAxisExtent, centerOffset));
    final double clampedReverseCenter = math.max(0.0, math.min(mainAxisExtent, mainAxisExtent - centerOffset));

    // negative scroll offsets
    double result = layoutOneSide(
      childBefore(center),
      math.max(mainAxisExtent, mainAxisExtent * anchor - correctedOffset) - mainAxisExtent,
      clampedReverseCenter,
      clampedForwardCenter,
      mainAxisExtent,
      crossAxisExtent,
      GrowthDirection.reverse,
      childBefore,
    );
    if (result != 0.0)
      return -result;

    // positive scroll offsets
    return layoutOneSide(
      center,
      math.max(0.0, correctedOffset - mainAxisExtent * anchor),
      clampedForwardCenter,
      clampedReverseCenter,
      mainAxisExtent,
      crossAxisExtent,
      GrowthDirection.forward,
      childAfter,
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBoundsData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
        break;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
        break;
    }
    if (childLayoutGeometry.hasVisualOverflow)
      _hasVisualOverflow = true;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection) {
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.paintOffset = computeAbsolutePaintOffset(child, layoutOffset, growthDirection);
  }

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final SliverPhysicalParentData childParentData = child.parentData;
    return childParentData.paintOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  double computeChildMainAxisPosition(RenderSliver child, double parentMainAxisPosition) {
    assert(child != null);
    assert(child.constraints != null);
    final SliverPhysicalParentData childParentData = child.parentData;
    switch (applyGrowthDirectionToAxisDirection(child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
        return parentMainAxisPosition - childParentData.paintOffset.dy;
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.paintOffset.dx;
      case AxisDirection.up:
        return child.geometry.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dy);
      case AxisDirection.left:
        return child.geometry.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dx);
    }
    return 0.0;
  }

  @override
  bool rereportDimensions() {
    assert(_minScrollExtent != null);
    assert(_maxScrollExtent != null);
    assert(anchor != null);
    double effectiveExtent;
    switch (axis) {
      case Axis.vertical:
        effectiveExtent = size.height;
        break;
      case Axis.horizontal:
        effectiveExtent = size.width;
        break;
    }
    assert(effectiveExtent != null);
    offset.applyViewportDimension(effectiveExtent);
    return offset.applyContentDimensions(
             // when updating this, also update similar code in performLayout()
             math.min(0.0, _minScrollExtent + effectiveExtent * anchor),
             math.max(0.0, _maxScrollExtent - effectiveExtent * (1.0 - anchor)),
           );
  }

  @override
  int indexOfFirstChild() {
    assert(center != null);
    assert(center.parent == this);
    assert(firstChild != null);
    int count = 0;
    RenderSliver child = center;
    while (child != firstChild) {
      count -= 1;
      child = childBefore(child);
    }
    return count;
  }

  @override
  String labelForChild(int index) {
    if (index == 0)
      return 'center child';
    return 'child $index';
  }

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    if (firstChild == null)
      return;
    RenderSliver child = firstChild;
    while (child != center) {
      yield child;
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      yield child;
      if (child == center)
        return;
      child = childBefore(child);
    }
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    if (firstChild == null)
      return;
    RenderSliver child = center;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
    child = childBefore(center);
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('anchor: $anchor');
  }
}

// ///
// /// See also:
// ///
// /// - [RenderViewport2], a viewport that does not shrink-wrap its contents
// /// - [RenderSliver], which explains more about the Sliver protocol.
// /// - [RenderBox], which explains more about the Box protocol.
// /// - [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
// ///   placed inside a [RenderSliver] (the opposite of this class).
class RenderShrinkWrappingViewport extends RenderViewportBase2<SliverLogicalContainerParentData> {
  /// Creates a viewport (for [RenderSliver] objects) that shrink-wraps its
  /// contents.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [new ViewportOffset.zero] or [new ViewportOffset.fixed].
  RenderShrinkWrappingViewport({
    AxisDirection axisDirection: AxisDirection.down,
    @required ViewportOffset offset,
    List<RenderSliver> children,
  }) : super(axisDirection: axisDirection, offset: offset) {
    addAll(children);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverLogicalContainerParentData)
      child.parentData = new SliverLogicalContainerParentData();
  }

  // Out-of-band data computed during layout.
  double _maxScrollExtent;
  double _shrinkWrapExtent;
  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    if (firstChild == null) {
      switch (axis) {
        case Axis.vertical:
          assert(constraints.hasBoundedWidth);
          size = new Size(constraints.maxWidth, constraints.minHeight);
          break;
        case Axis.horizontal:
          assert(constraints.hasBoundedHeight);
          size = new Size(constraints.minWidth, constraints.maxHeight);
          break;
      }
      offset.applyViewportDimension(0.0);
      _maxScrollExtent = 0.0;
      _shrinkWrapExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }

    double mainAxisExtent;
    double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        assert(constraints.hasBoundedWidth);
        mainAxisExtent = constraints.maxHeight;
        crossAxisExtent = constraints.maxWidth;
        break;
      case Axis.horizontal:
        assert(constraints.hasBoundedHeight);
        mainAxisExtent = constraints.maxWidth;
        crossAxisExtent = constraints.maxHeight;
        break;
    }

    double correction;
    double effectiveExtent;
    do {
      assert(offset.pixels != null);
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent, offset.pixels);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        switch (axis) {
          case Axis.vertical:
            effectiveExtent = constraints.constrainHeight(_shrinkWrapExtent);
            break;
          case Axis.horizontal:
            effectiveExtent = constraints.constrainWidth(_shrinkWrapExtent);
            break;
        }
        offset.applyViewportDimension(effectiveExtent);
        // when updating this, also update similar code in rereportDimensions
        if (offset.applyContentDimensions(0.0, math.max(0.0, _maxScrollExtent - effectiveExtent)))
          break;
      }
    } while (true);
    switch (axis) {
      case Axis.vertical:
        size = constraints.constrainDimensions(crossAxisExtent, effectiveExtent);
        break;
      case Axis.horizontal:
        size = constraints.constrainDimensions(effectiveExtent, crossAxisExtent);
        break;
    }
  }

  double _attemptLayout(double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _maxScrollExtent = 0.0;
    _shrinkWrapExtent = 0.0;
    _hasVisualOverflow = false;
    return layoutOneSide(
      firstChild,
      math.max(0.0, correctedOffset),
      0.0,
      mainAxisExtent,
      mainAxisExtent,
      crossAxisExtent,
      GrowthDirection.forward,
      childAfter,
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBoundsData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    assert(growthDirection == GrowthDirection.forward);
    _maxScrollExtent += childLayoutGeometry.scrollExtent;
    if (childLayoutGeometry.hasVisualOverflow)
      _hasVisualOverflow = true;
    _shrinkWrapExtent += childLayoutGeometry.maxPaintExtent;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection) {
    assert(growthDirection == GrowthDirection.forward);
    final SliverLogicalParentData childParentData = child.parentData;
    childParentData.layoutOffset = layoutOffset;
  }

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final SliverLogicalParentData childParentData = child.parentData;
    return computeAbsolutePaintOffset(child, childParentData.layoutOffset, GrowthDirection.forward);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    final Offset offset = paintOffsetOf(child);
    transform.translate(offset.dx, offset.dy);
  }

  @override
  double computeChildMainAxisPosition(RenderSliver child, double parentMainAxisPosition) {
    assert(child != null);
    assert(child.constraints != null);
    assert(hasSize);
    final SliverLogicalParentData childParentData = child.parentData;
    switch (applyGrowthDirectionToAxisDirection(child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.layoutOffset;
      case AxisDirection.up:
        return (size.height - parentMainAxisPosition) - childParentData.layoutOffset;
      case AxisDirection.left:
        return (size.width - parentMainAxisPosition) - childParentData.layoutOffset;
    }
    return 0.0;
  }

  @override
  bool rereportDimensions() {
    assert(_maxScrollExtent != null);
    double effectiveExtent;
    switch (axis) {
      case Axis.vertical:
        effectiveExtent = size.height;
        break;
      case Axis.horizontal:
        effectiveExtent = size.width;
        break;
    }
    assert(effectiveExtent != null);
    offset.applyViewportDimension(effectiveExtent);
    return offset.applyContentDimensions(0.0, math.max(0.0, _maxScrollExtent - effectiveExtent));
  }

  @override
  int indexOfFirstChild() => 0;

  @override
  String labelForChild(int index) => 'child $index';

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    RenderSliver child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    RenderSliver child = lastChild;
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }
}


// ADAPTER FOR RENDER BOXES INSIDE SLIVERS
// Transitions from the RenderSliver world to the RenderBox world.

/// A [RenderSliver] that contains a single [RenderBox].
///
/// The child will not be laid out if it is not visible.
///
/// See also:
///
/// - [RenderSliver], which explains more about the Sliver protocol.
/// - [RenderBox], which explains more about the Box protocol.
/// - [RenderViewport2], which allows [RenderSliver] objects to be placed inside
///   a [RenderBox] (the opposite of this class).
class RenderSliverToBoxAdapter extends RenderSliver with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  /// Creates a [RenderSliver] that wraps a [RenderBox].
  RenderSliverToBoxAdapter({
    RenderBox child,
  }) {
    this.child = child;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData)
      child.parentData = new SliverPhysicalParentData();
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child.size.width;
        break;
      case Axis.vertical:
        childExtent = child.size.height;
        break;
    }
    assert(childExtent != null);
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = new SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );

    final SliverPhysicalParentData childParentData = child.parentData;
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        childParentData.paintOffset = new Offset(0.0, -(geometry.scrollExtent - (geometry.paintExtent + constraints.scrollOffset)));
        break;
      case AxisDirection.right:
        childParentData.paintOffset = new Offset(-constraints.scrollOffset, 0.0);
        break;
      case AxisDirection.down:
        childParentData.paintOffset = new Offset(0.0, -constraints.scrollOffset);
        break;
      case AxisDirection.left:
        childParentData.paintOffset = new Offset(-(geometry.scrollExtent - (geometry.paintExtent + constraints.scrollOffset)), 0.0);
        break;
    }
    assert(childParentData.paintOffset != null);
  }

  @override
  bool hitTestChildren(HitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    assert(geometry.hitTestExtent > 0.0);
    if (child != null)
      return hitTestBoxChild(result, child, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return -constraints.scrollOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry.visible) {
      final SliverPhysicalParentData childParentData = child.parentData;
      context.paintChild(child, offset + childParentData.paintOffset);
    }
  }

  // TODO(ianh): semantics - shouldn't walk the invisible children
}
