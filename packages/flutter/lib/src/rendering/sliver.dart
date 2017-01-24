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

/// The direction of a scroll, relative to the positive scroll offset axis given
/// by an [AxisDirection] and a [GrowthDirection].
///
/// This contrasts to [GrowthDirection] in that it has a third value, [idle],
/// for the case where no scroll is occurring.
///
/// This is used by [RenderSliverFloatingAppBar] to only expand when the user is
/// scrolling in the same direction as the detected scroll offset change.
enum ScrollDirection {
  /// No scrolling is underway.
  idle,

  /// Scrolling is happening in the positive scroll offset direction.
  ///
  /// For example, for the [GrowthDirection.forward] part of a vertical
  /// [AxisDirection.down] list, this means the content is moving up, exposing
  /// lower content.
  forward,

  /// Scrolling is happening in the negative scroll offset direction.
  ///
  /// For example, for the [GrowthDirection.forward] part of a vertical
  /// [AxisDirection.down] list, this means the content is moving down, exposing
  /// earlier content.
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

AxisDirection applyGrowthDirectionToAxisDirection(AxisDirection axisDirection, GrowthDirection growthDirection) {
  assert(axisDirection != null);
  assert(growthDirection != null);
  switch (growthDirection) {
    case GrowthDirection.forward:
      return axisDirection;
    case GrowthDirection.reverse:
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
  });

  SliverConstraints copyWith({
    AxisDirection axisDirection,
    GrowthDirection growthDirection,
    ScrollDirection userScrollDirection,
    double scrollOffset,
    double overlap,
    double remainingPaintExtent,
    double crossAxisExtent,
  }) {
    return new SliverConstraints(
      axisDirection: axisDirection ?? this.axisDirection,
      growthDirection: growthDirection ?? this.growthDirection,
      userScrollDirection: userScrollDirection ?? this.userScrollDirection,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      overlap: overlap ?? this.overlap,
      remainingPaintExtent: remainingPaintExtent ?? this.remainingPaintExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
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
  final double remainingPaintExtent;

  /// The number of pixels in the cross-axis. For a vertical list, this is the
  /// width of the viewport.
  final double crossAxisExtent;

  Offset get scrollOffsetAsOffset {
    assert(axisDirection != null);
    switch (axisDirection) {
      case AxisDirection.up:
        return new Offset(0.0, -scrollOffset);
      case AxisDirection.down:
        return new Offset(0.0, scrollOffset);
      case AxisDirection.left:
        return new Offset(-scrollOffset, 0.0);
      case AxisDirection.right:
        return new Offset(scrollOffset, 0.0);
    }
    return null;
  }

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
        && remainingPaintExtent >= 0.0;
  }

  BoxConstraints asBoxConstraints({
    double minExtent: 0.0,
    double maxExtent: double.INFINITY,
  }) {
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
    assert(scrollOffset >= 0.0);
    assert(crossAxisExtent >= 0.0);
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
    return axis == typedOther.axis &&
           growthDirection == typedOther.growthDirection &&
           scrollOffset == typedOther.scrollOffset &&
           overlap == typedOther.overlap &&
           remainingPaintExtent == typedOther.remainingPaintExtent &&
           crossAxisExtent == typedOther.crossAxisExtent;
  }

  @override
  int get hashCode {
    return hashValues(axis, growthDirection, scrollOffset, overlap, remainingPaintExtent, crossAxisExtent);
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
             'crossAxisExtent: ${crossAxisExtent.toStringAsFixed(1)}'
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
/// children using scroll offsets.
///
/// This data structure is optimised for fast layout. It is best used by parents
/// that expect to have many children whose relative positions don't change even
/// when the scroll offset does.
class SliverLogicalParentData extends ParentData {
  /// The distance from from the zero scroll offset of the parent sliver (the
  /// line at which its [SliverConstraints.scrollOffset] is zero) to the side of
  /// the child closest to that offset.
  ///
  /// In a typical list, this does not change as the parent is scrolled.
  double scrollOffset = 0.0;

  @override
  String toString() => 'scrollOffset=${scrollOffset.toStringAsFixed(1)}';
}

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

  void didScroll(double delta, Point focus) { }

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
  /// The `mainAxisPosition` is the distance in the [AxisDirection] from the
  /// edge of the sliver's painted area. This can be an unusual direction, for
  /// example in the [AxisDirection.up] case this is a distance from the
  /// _bottom_ of the sliver's painted area.
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
  /// [SliverLogicalParentData.scrollOffset].
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
  @protected
  double childPosition(@checked RenderObject child) {
    assert(() {
      throw new FlutterError('$runtimeType does not implement childPosition.');
    });
    return 0.0;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(() {
      throw new FlutterError('$runtimeType does not implement applyPaintTransform.');
    });
  }

  void _debugDrawArrow(Canvas canvas, Paint paint, Point p0, Point p1, GrowthDirection direction) {
    assert(() {
      if (p0 == p1)
        return;
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
    });
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled) {
        final double strokeWidth = math.min(4.0, geometry.paintExtent / 30.0);
        final Paint paint = new Paint()
          ..color = const Color(0xFF33CC33)
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
  /// This function relies on [childPosition] to determine the position of
  /// child in question.
  ///
  /// Calling this for a child that is not visible is not valid.
  @protected
  bool hitTestBoxChild(HitTestResult result, RenderBox child, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    final bool rightWayUp = _getRightWayUp(constraints);
    double absolutePosition = mainAxisPosition - childPosition(child);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        if (!rightWayUp)
          absolutePosition = child.size.width - absolutePosition;
        return child.hitTest(result, position: new Point(absolutePosition, crossAxisPosition));
      case Axis.vertical:
        if (!rightWayUp)
          absolutePosition = child.size.height - absolutePosition;
        return child.hitTest(result, position: new Point(crossAxisPosition, absolutePosition));
    }
    return false;
  }

  /// Utility function for [applyPaintTransform] for use when the children are
  /// [RenderBox] widgets.
  ///
  /// This function turns the value returned by [childPosition] for the child in
  /// question into a translation that it then applies to the given matrix.
  ///
  /// Calling this for a child that is not visible is not valid.
  @protected
  void applyPaintTransformForBoxChild(RenderBox child, Matrix4 transform) {
    final double sign = _getRightWayUp(constraints) ? 1.0 : -1.0;
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        transform.translate(childPosition(child) * sign, 0.0);
        break;
      case Axis.vertical:
        transform.translate(0.0, childPosition(child) * sign);
        break;
    }
  }
}


// THE MAIN VIEWPORT CLASS
// Transitions from the RenderBox world to the RenderSliver world.

typedef RenderSliver _Advancer(RenderSliver child);

abstract class ViewportOffset extends ChangeNotifier {
  ViewportOffset();
  factory ViewportOffset.fixed(double value) = _FixedViewportOffset;
  factory ViewportOffset.zero() = _FixedViewportOffset.zero;
  double get pixels;

  /// Called when the viewport's extents are established.
  ///
  /// The argument is the dimension of the [RenderViewport2] in the main axis
  /// (e.g. the height, for a vertical viewport).
  ///
  /// This may be called redundantly, with the same value, each frame. This is
  /// called during layout for the [RenderViewport2]. If the viewport is
  /// configured to shrink-wrap its contents, it may be called several times,
  /// since the layout is repeated each time the scroll offset is corrected.
  ///
  /// If this is called, it is called before [applyContentDimensions]. If this
  /// is called, [applyContentDimensions] will be called soon afterwards in the
  /// same layout phase. If the viewport is not configured to shrink-wrap its
  /// contents, then this will only be called when the viewport recomputes its
  /// size (i.e. when its parent lays out), and not during normal scrolling.
  void applyViewportDimension(double viewportDimension);

  /// Called when the viewport's content extents are established.
  ///
  /// The arguments are the minimum and maximum scroll extents respectively. The
  /// minimum will be equal to or less than zero, the maximum will be equal to
  /// or greater than zero.
  ///
  /// The maximum scroll extent has the viewport dimension subtracted from it.
  /// For instance, if there is 100.0 pixels of scrollable content, and the
  /// viewport is 80.0 pixels high, then the minimum scroll extent will
  /// typically be 0.0 and the maximum scroll extent will typically be 20.0,
  /// because there's only 20.0 pixels of actual scroll slack.
  ///
  /// If applying the content dimensions changes the scroll offset, return
  /// false. Otherwise, return true. If you return false, the [RenderViewport2]
  /// will be laid out again with the new scroll offset. This is expensive.
  ///
  /// This is called at least once each time the [RenderViewport2] is laid out,
  /// even if the values have not changed. It may be called many times if the
  /// scroll offset is corrected (if this returns false). This is always called
  /// after [applyViewportDimension], if that method is called.
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent);

  /// Apply a layout-time correction to the scroll offset.
  ///
  /// This method should change the [pixels] value by `correction`, but without
  /// calling [notifyListeners]. It is called during layout by the
  /// [RenderViewport2], before [applyContentDimensions]. After this method is
  /// called, the layout will be recomputed and that may result in this method
  /// being called again, though this should be very rare.
  void correctBy(double correction);

  /// The direction in which the user is trying to change [pixels], relative to
  /// the viewport's [RenderViewport2.axisDirection].
  ///
  /// This is used by some slivers to determine how to react to a change in
  /// scroll offset. For example, [RenderSliverFloatingAppBar] will only expand
  /// a floating app bar when the [userScrollDirection] is in the positive
  /// scroll offset direction.
  ScrollDirection get userScrollDirection;

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '$runtimeType(${description.join(", ")})';
  }

  @mustCallSuper
  void debugFillDescription(List<String> description) {
    description.add('offset: ${pixels.toStringAsFixed(1)}');
  }
}

class _FixedViewportOffset extends ViewportOffset {
  _FixedViewportOffset(this._pixels);
  _FixedViewportOffset.zero() : _pixels = 0.0;

  double _pixels;

  @override
  double get pixels => _pixels;

  @override
  void applyViewportDimension(double viewportDimension) { }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) => true;

  @override
  void correctBy(double correction) {
    _pixels += correction;
  }

  @override
  ScrollDirection get userScrollDirection => ScrollDirection.idle;
}

// ///
// /// See also:
// ///
// /// - [RenderSliver], which explains more about the Sliver protocol.
// /// - [RenderBox], which explains more about the Box protocol.
// /// - [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
// ///   placed inside a [RenderSliver] (the opposite of this class).
class RenderViewport2 extends RenderBox with ContainerRenderObjectMixin<RenderSliver, SliverPhysicalContainerParentData> {
  /// Creates a viewport for [RenderSliver] objects.
  ///
  /// If the [center] is not specified, then the first child in the `children`
  /// list, if any, is used.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [new ViewportOffset.zero] or [new ViewportOffset.fixed].
  RenderViewport2({
    AxisDirection axisDirection: AxisDirection.down,
    double anchor: 0.0,
    @required ViewportOffset offset,
    List<RenderSliver> children,
    RenderSliver center,
  }) : _axisDirection = axisDirection,
       _anchor = anchor,
       _offset = offset,
       _center = center {
    assert(offset != null);
    assert(axisDirection != null);
    assert(anchor != null);
    assert(anchor >= 0.0 && anchor <= 1.0);
    addAll(children);
    if (center == null && firstChild != null)
      _center = firstChild;
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

  // TODO(ianh): Extract the shrink-wrap logic into a separate viewport class.
  bool _shrinkWrap = false;

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
      assert(_minScrollExtent != null);
      assert(_maxScrollExtent != null);
      assert(anchor != null);
      // If we already have a size, then we should re-report the dimensions
      // to the new ViewportOffset. If we don't then we'll report them when
      // we establish the dimensions later, so don't worry about it now.
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
      if (offset.applyContentDimensions(
            // when updating this, also update similar code in performLayout()
            math.min(0.0, _minScrollExtent + effectiveExtent * anchor),
            math.max(0.0, _maxScrollExtent - effectiveExtent * (1.0 - anchor)),
         ))
       markNeedsLayout();
    }
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
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData)
      child.parentData = new SliverPhysicalContainerParentData();
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

  @override
  bool get sizedByParent => !_shrinkWrap;

  @override
  void performResize() {
    assert(!_shrinkWrap);
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

  // Out-of-band data computed during layout.
  double _minScrollExtent;
  double _maxScrollExtent;
  double _shrinkWrapExtent;

  @override
  void performLayout() {
    assert(!_shrinkWrap || anchor == 0.0);
    if (center == null) {
      assert(firstChild == null);
      if (_shrinkWrap) {
        switch (axis) {
          case Axis.vertical:
            size = new Size(constraints.maxWidth, 0.0);
            break;
          case Axis.horizontal:
            size = new Size(0.0, constraints.maxHeight);
            break;
        }
        offset.applyViewportDimension(0.0);
      }
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _shrinkWrapExtent = 0.0;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }
    assert(center.parent == this);

    double extent;
    double crossExtent;
    if (_shrinkWrap) {
      switch (axis) {
        case Axis.vertical:
          assert(constraints.hasBoundedWidth);
          extent = constraints.maxHeight;
          crossExtent = constraints.maxWidth;
          break;
        case Axis.horizontal:
          assert(constraints.hasBoundedHeight);
          extent = constraints.maxWidth;
          crossExtent = constraints.maxHeight;
          break;
      }
    } else {
      assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);
      switch (axis) {
        case Axis.vertical:
          extent = size.height;
          crossExtent = size.width;
          break;
        case Axis.horizontal:
          extent = size.width;
          crossExtent = size.height;
          break;
      }
    }

    final double centerOffsetAdjustment = center.centerOffsetAdjustment;

    double correction;
    double effectiveExtent;
    do {
      assert(offset.pixels != null);
      correction = _attemptLayout(extent, crossExtent, offset.pixels + centerOffsetAdjustment);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        if (_shrinkWrap) {
          switch (axis) {
            case Axis.vertical:
              effectiveExtent = constraints.constrainHeight(_shrinkWrapExtent);
              break;
            case Axis.horizontal:
              effectiveExtent = constraints.constrainWidth(_shrinkWrapExtent);
              break;
          }
          offset.applyViewportDimension(effectiveExtent);
        } else {
          switch (axis) {
            case Axis.vertical:
              effectiveExtent = size.height;
              break;
            case Axis.horizontal:
              effectiveExtent = size.width;
              break;
          }
        }
        // when updating this, also update similar code in offset setter
        if (offset.applyContentDimensions(
              math.min(0.0, _minScrollExtent + effectiveExtent * anchor),
              math.max(0.0, _maxScrollExtent - effectiveExtent * (1.0 - anchor))
           ))
          break;
      }
    } while (true);

    assert(_shrinkWrap != sizedByParent);
    if (_shrinkWrap) {
      switch (axis) {
        case Axis.vertical:
          size = new Size(crossExtent, effectiveExtent);
          break;
        case Axis.horizontal:
          size = new Size(effectiveExtent, crossExtent);
          break;
      }
    }
  }

  double _attemptLayout(double extent, double crossExtent, double correctedOffset) {
    assert(!extent.isNaN);
    assert(extent >= 0.0);
    assert(crossExtent.isFinite);
    assert(crossExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _shrinkWrapExtent = 0.0;

    // centerOffset is the offset from the leading edge of the RenderViewport2
    // to the zero scroll offset (the line between the forward slivers and the
    // reverse slivers). The other two are that, but clamped to the visible
    // region of the viewport.
    final double centerOffset = extent * anchor - correctedOffset;
    final double clampedForwardCenter = math.max(0.0, math.min(extent, centerOffset));
    final double clampedReverseCenter = math.max(0.0, math.min(extent, extent - centerOffset));

    // negative scroll offsets
    double result = _layoutOneSide(
      childBefore(center),
      math.max(extent, extent * anchor - correctedOffset) - extent,
      clampedReverseCenter,
      clampedForwardCenter,
      crossExtent,
      GrowthDirection.reverse,
      childBefore,
    );
    if (result != 0.0)
      return -result;

    // positive scroll offsets
    return _layoutOneSide(
      center,
      math.max(0.0, correctedOffset - extent * anchor),
      clampedForwardCenter,
      clampedReverseCenter,
      crossExtent,
      GrowthDirection.forward,
      childAfter,
    );
  }

  double _layoutOneSide(
    RenderSliver child,
    double scrollOffset,
    double layoutOffset,
    double remainingPaintExtent,
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
      ), parentUsesSize: true);

      // collect the child's objects
      final SliverGeometry childLayoutGeometry = child.geometry;
      final SliverPhysicalParentData childParentData = child.parentData;

      assert(childLayoutGeometry.debugAssertIsValid);

      // first check that there isn't a correction to apply. If there is we'll
      // have to start over.
      if (childLayoutGeometry.scrollOffsetCorrection != 0.0)
        return childLayoutGeometry.scrollOffsetCorrection;

      // geometry
      childParentData.paintOffset = _computeAbsolutePaintOffset(child, layoutOffset, growthDirection);
      maxPaintOffset = math.max(layoutOffset + childLayoutGeometry.paintExtent, maxPaintOffset);
      scrollOffset -= childLayoutGeometry.scrollExtent;
      layoutOffset += childLayoutGeometry.layoutExtent;

      if (scrollOffset <= 0.0)
        scrollOffset = 0.0;

      // out-of-band data mutation
      switch (growthDirection) {
        case GrowthDirection.forward:
          _maxScrollExtent += childLayoutGeometry.scrollExtent;
          break;
        case GrowthDirection.reverse:
          _minScrollExtent -= childLayoutGeometry.scrollExtent;
          break;
      }
      _shrinkWrapExtent += childLayoutGeometry.maxPaintExtent;

      // move on to the next child
      assert(child.parentData == childParentData);
      child = advance(child);
    }

    // we made it without a correction, whee!
    return 0.0;
  }

  Offset _computeAbsolutePaintOffset(RenderSliver child, double paintOffset, GrowthDirection growthDirection) {
    assert(axisDirection != null);
    assert(growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
      case AxisDirection.up:
        return new Offset(0.0, size.height - (paintOffset + child.geometry.paintExtent));
      case AxisDirection.right:
        return new Offset(paintOffset, 0.0);
      case AxisDirection.down:
        return new Offset(0.0, paintOffset);
      case AxisDirection.left:
        return new Offset(size.width - (paintOffset + child.geometry.paintExtent), 0.0);
    }
    return null;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child.parent == this);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (center == null) {
      assert(firstChild == null);
      return;
    }
    assert(center.parent == this);
    assert(firstChild != null);
    RenderSliver child;
    // TODO(ianh): if we have content beyond our max extents, clip
    child = firstChild;
    while (child != center) {
      if (child.geometry.visible) {
        final SliverPhysicalParentData childParentData = child.parentData;
        context.paintChild(child, offset + childParentData.paintOffset);
      }
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      if (child.geometry.visible) {
        final SliverPhysicalParentData childParentData = child.parentData;
        context.paintChild(child, offset + childParentData.paintOffset);
      }
      if (child == center)
        break;
      child = childBefore(child);
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
        final SliverPhysicalParentData childParentData = child.parentData;
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
        canvas.drawRect(((offset + childParentData.paintOffset) & size).deflate(0.5), paint);
        child = childAfter(child);
      }
      return true;
    });
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (center == null) {
      assert(firstChild == null);
      return false;
    }
    assert(center.parent == this);
    assert(firstChild != null);
    double crossAxisPosition, mainAxisPosition;
    switch (axis) {
      case Axis.vertical:
        crossAxisPosition = position.x;
        mainAxisPosition = position.y;
        break;
      case Axis.horizontal:
        crossAxisPosition = position.y;
        mainAxisPosition = position.x;
        break;
    }
    assert(crossAxisPosition != null);
    RenderSliver child;
    child = center;
    while (child != null) {
      if (child.geometry.visible && child.hitTest(
        result,
        mainAxisPosition: _computeChildMainAxisPosition(child, mainAxisPosition),
        crossAxisPosition: crossAxisPosition
      )) {
        return true;
      }
      child = childAfter(child);
    }
    child = childBefore(center);
    while (child != null) {
      if (child.geometry.visible && child.hitTest(
        result,
        mainAxisPosition: _computeChildMainAxisPosition(child, mainAxisPosition),
        crossAxisPosition: crossAxisPosition
      )) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  double _computeChildMainAxisPosition(RenderSliver child, double parentMainAxisPosition) {
    final SliverPhysicalParentData childParentData = child.parentData;
    switch (applyGrowthDirectionToAxisDirection(child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.up:
        return child.geometry.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dy);
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.paintOffset.dx;
      case AxisDirection.down:
        return parentMainAxisPosition - childParentData.paintOffset.dy;
      case AxisDirection.left:
        return child.geometry.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dx);
    }
    return 0.0;
  }

  // TODO(ianh): semantics - shouldn't walk the invisible children

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    if (_shrinkWrap)
      description.add('shrink-wrap enabled');
    description.add('anchor: $anchor');
    description.add('offset: $offset');
  }

  @override
  String debugDescribeChildren(String prefix) {
    String result = '$prefix \u2502\n';
    if (center == null) {
      assert(firstChild == null);
      return result;
    }
    assert(center.parent == this);
    assert(firstChild != null);

    int count = 0;
    RenderSliver child = center;
    while (child != firstChild) {
      count -= 1;
      child = childBefore(child);
    }

    child = firstChild;
    while (child != lastChild) {
      result += '${child.toStringDeep("$prefix \u251C\u2500${_labelChild(count)}: ", "$prefix \u2502")}';
      count += 1;
      child = childAfter(child);
    }
    if (child != null) {
      assert(child == lastChild);
      result += '${child.toStringDeep("$prefix \u2514\u2500${_labelChild(count)}: ", "$prefix  ")}';
    }
    return result;
  }

  static String _labelChild(int count) {
    if (count == 0)
      return 'center child';
    return 'child $count';
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
  double childPosition(RenderBox child) {
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
