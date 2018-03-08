// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'viewport_offset.dart';

/// An interface for render objects that are bigger on the inside.
///
/// Some render objects, such as [RenderViewport], present a portion of their
/// content, which can be controlled by a [ViewportOffset]. This interface lets
/// the framework recognize such render objects and interact with them without
/// having specific knowledge of all the various types of viewports.
abstract class RenderAbstractViewport extends RenderObject {
  // This class is intended to be used as an interface with the implements
  // keyword, and should not be extended directly.
  factory RenderAbstractViewport._() => null;

  /// Returns the [RenderAbstractViewport] that most tightly encloses the given
  /// render object.
  ///
  /// If the object does not have a [RenderAbstractViewport] as an ancestor,
  /// this function returns null.
  static RenderAbstractViewport of(RenderObject object) {
    while (object != null) {
      if (object is RenderAbstractViewport)
        return object;
      object = object.parent;
    }
    return null;
  }

  /// Returns the offset that would be needed to reveal the target render object.
  ///
  /// The `alignment` argument describes where the target should be positioned
  /// after applying the returned offset. If `alignment` is 0.0, the child must
  /// be positioned as close to the leading edge of the viewport as possible. If
  /// `alignment` is 1.0, the child must be positioned as close to the trailing
  /// edge of the viewport as possible. If `alignment` is 0.5, the child must be
  /// positioned as close to the center of the viewport as possible.
  ///
  /// The target might not be a direct child of this viewport but it must be a
  /// descendant of the viewport and there must not be any other
  /// [RenderAbstractViewport] objects between the target and this object.
  double getOffsetToReveal(RenderObject target, double alignment);
}

/// A base class for render objects that are bigger on the inside.
///
/// This render object provides the shared code for render objects that host
/// [RenderSliver] render objects inside a [RenderBox]. The viewport establishes
/// an [axisDirection], which orients the sliver's coordinate system, which is
/// based on scroll offsets rather than Cartesian coordinates.
///
/// The viewport also listens to an [offset], which determines the
/// [SliverConstraints.scrollOffset] input to the sliver layout protocol.
///
/// Subclasses typically override [performLayout] and call
/// [layoutChildSequence], perhaps multiple times.
///
/// See also:
///
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
abstract class RenderViewportBase<ParentDataClass extends ContainerParentDataMixin<RenderSliver>>
    extends RenderBox with ContainerRenderObjectMixin<RenderSliver, ParentDataClass>
    implements RenderAbstractViewport {
  /// Initializes fields for subclasses.
  RenderViewportBase({
    AxisDirection axisDirection: AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
  }) : assert(axisDirection != null),
       assert(crossAxisDirection != null),
       assert(offset != null),
       assert(axisDirectionToAxis(axisDirection) != axisDirectionToAxis(crossAxisDirection)),
       _axisDirection = axisDirection,
       _crossAxisDirection = crossAxisDirection,
       _offset = offset;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.addTagForChildren(RenderViewport.useTwoPaneSemantics);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (RenderSliver sliver in childrenInPaintOrder) {
      if (sliver.geometry.paintExtent != 0 &&
          sliver.constraints.overlap < sliver.geometry.paintOrigin + sliver.geometry.paintExtent)
        visitor(sliver);
    }
  }

  /// The direction in which the [SliverConstraints.scrollOffset] increases.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
  /// offset of zero is at the top of the viewport and increases towards the
  /// bottom of the viewport.
  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _axisDirection)
      return;
    _axisDirection = value;
    markNeedsLayout();
  }

  /// The direction in which child should be laid out in the cross axis.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], this property
  /// is typically [AxisDirection.left] if the ambient [TextDirection] is
  /// [TextDirection.rtl] and [AxisDirection.right] if the ambient
  /// [TextDirection] is [TextDirection.ltr].
  AxisDirection get crossAxisDirection => _crossAxisDirection;
  AxisDirection _crossAxisDirection;
  set crossAxisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _crossAxisDirection)
      return;
    _crossAxisDirection = value;
    markNeedsLayout();
  }

  /// The axis along which the viewport scrolls.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], then the
  /// [axis] is [Axis.vertical] and the viewport scrolls vertically.
  Axis get axis => axisDirectionToAxis(axisDirection);

  /// Which part of the content inside the viewport should be visible.
  ///
  /// The [ViewportOffset.pixels] value determines the scroll offset that the
  /// viewport uses to select which part of its content to display. As the user
  /// scrolls the viewport, this value changes, which changes the content that
  /// is displayed.
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset)
      return;
    if (attached)
      _offset.removeListener(markNeedsLayout);
    _offset = value;
    if (attached)
      _offset.addListener(markNeedsLayout);
    // We need to go through layout even if the new offset has the same pixels
    // value as the old offset so that we will apply our viewport and content
    // dimensions.
    markNeedsLayout();
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

  /// Throws an exception saying that the object does not support returning
  /// intrinsic dimensions if, in checked mode, we are not in the
  /// [RenderObject.debugCheckingIntrinsics] mode.
  ///
  /// This is used by [computeMinIntrinsicWidth] et al because viewports do not
  /// generally support returning intrinsic dimensions. See the discussion at
  /// [computeMinIntrinsicWidth].
  @protected
  bool debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        assert(this is! RenderShrinkWrappingViewport); // it has its own message
        throw new FlutterError(
          '$runtimeType does not support returning intrinsic dimensions.\n'
          'Calculating the intrinsic dimensions would require instantiating every child of '
          'the viewport, which defeats the point of viewports being lazy.\n'
          'If you are merely trying to shrink-wrap the viewport in the main axis direction, '
          'consider a RenderShrinkWrappingViewport render object (ShrinkWrappingViewport widget), '
          'which achieves that effect without implementing the intrinsic dimension API.'
        );
      }
      return true;
    }());
    return true;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  bool get isRepaintBoundary => true;

  /// Determines the size and position of some of the children of the viewport.
  ///
  /// This function is the workhorse of `performLayout` implementations in
  /// subclasses.
  ///
  /// Layout starts with `child`, proceeds according to the `advance` callback,
  /// and stops once `advance` returns null.
  ///
  ///  * `scrollOffset` is the [SliverConstraints.scrollOffset] to pass the
  ///    first child. The scroll offset is adjusted by
  ///    [SliverGeometry.scrollExtent] for subsequent children.
  ///  * `overlap` is the [SliverConstraints.overlap] to pass the first child.
  ///    The overlay is adjusted by the [SliverGeometry.paintOrigin] and
  ///    [SliverGeometry.paintExtent] for subsequent children.
  ///  * `layoutOffset` is the layout offset at which to place the first child.
  ///    The layout offset is updated by the [SliverGeometry.layoutExtent] for
  ///    subsequent children.
  ///  * `remainingPaintExtent` is [SliverConstraints.remainingPaintExtent] to
  ///    pass the first child. The remaining paint extent is updated by the
  ///    [SliverGeometry.layoutExtent] for subsequent children.
  ///  * `mainAxisExtent` is the [SliverConstraints.viewportMainAxisExtent] to
  ///    pass to each child.
  ///  * `crossAxisExtent` is the [SliverConstraints.crossAxisExtent] to pass to
  ///    each child.
  ///  * `growthDirection` is the [SliverConstraints.growthDirection] to pass to
  ///    each child.
  ///
  /// Returns the first non-zero [SliverGeometry.scrollOffsetCorrection]
  /// encountered, if any. Otherwise returns 0.0. Typical callers will call this
  /// function repeatedly until it returns 0.0.
  @protected
  double layoutChildSequence(
    RenderSliver child,
    double scrollOffset,
    double overlap,
    double layoutOffset,
    double remainingPaintExtent,
    double mainAxisExtent,
    double crossAxisExtent,
    GrowthDirection growthDirection,
    RenderSliver advance(RenderSliver child),
  ) {
    assert(scrollOffset.isFinite);
    assert(scrollOffset >= 0.0);
    final double initialLayoutOffset = layoutOffset;
    final ScrollDirection adjustedUserScrollDirection =
        applyGrowthDirectionToScrollDirection(offset.userScrollDirection, growthDirection);
    assert(adjustedUserScrollDirection != null);
    double maxPaintOffset = layoutOffset + overlap;
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
        crossAxisDirection: crossAxisDirection,
        viewportMainAxisExtent: mainAxisExtent,
      ), parentUsesSize: true);

      final SliverGeometry childLayoutGeometry = child.geometry;
      assert(childLayoutGeometry.debugAssertIsValid());

      // If there is a correction to apply, we'll have to start over.
      if (childLayoutGeometry.scrollOffsetCorrection != null)
        return childLayoutGeometry.scrollOffsetCorrection;

      // We use the child's paint origin in our coordinate system as the
      // layoutOffset we store in the child's parent data.
      final double effectiveLayoutOffset = layoutOffset + childLayoutGeometry.paintOrigin;
      updateChildLayoutOffset(child, effectiveLayoutOffset, growthDirection);
      maxPaintOffset = math.max(effectiveLayoutOffset + childLayoutGeometry.paintExtent, maxPaintOffset);
      scrollOffset -= childLayoutGeometry.scrollExtent;
      layoutOffset += childLayoutGeometry.layoutExtent;

      if (scrollOffset <= 0.0)
        scrollOffset = 0.0;

      updateOutOfBandData(growthDirection, childLayoutGeometry);

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
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, _paintContents);
    } else {
      _paintContents(context, offset);
    }
  }

  void _paintContents(PaintingContext context, Offset offset) {
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
    }());
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    double mainAxisPosition, crossAxisPosition;
    switch (axis) {
      case Axis.vertical:
        mainAxisPosition = position.dy;
        crossAxisPosition = position.dx;
        break;
      case Axis.horizontal:
        mainAxisPosition = position.dx;
        crossAxisPosition = position.dy;
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
  double getOffsetToReveal(RenderObject target, double alignment) {
    double leadingScrollOffset;
    double targetMainAxisExtent;
    RenderObject descendant;

    if (target is RenderBox) {
      final RenderBox targetBox = target;

      RenderBox pivot = targetBox;
      while (pivot.parent is RenderBox)
        pivot = pivot.parent;

      assert(pivot.parent != null);
      assert(pivot.parent != this);
      assert(pivot != this);

      final Matrix4 transform = targetBox.getTransformTo(pivot);
      final Rect bounds = MatrixUtils.transformRect(transform, targetBox.paintBounds);

      target = pivot;
      // TODO(abarth): Support other kinds of render objects besides slivers.
      assert(target.parent is RenderSliver);
      final RenderSliver pivotParent = target.parent;

      final GrowthDirection growthDirection = pivotParent.constraints.growthDirection;
      switch (applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
        case AxisDirection.up:
          double offset;
          switch (growthDirection) {
            case GrowthDirection.forward:
              offset = bounds.bottom;
              break;
            case GrowthDirection.reverse:
              offset = bounds.top;
              break;
          }
          leadingScrollOffset = pivot.size.height - offset;
          targetMainAxisExtent = bounds.height;
          break;
        case AxisDirection.right:
          leadingScrollOffset = bounds.left;
          targetMainAxisExtent = bounds.width;
          break;
        case AxisDirection.down:
          leadingScrollOffset = bounds.top;
          targetMainAxisExtent = bounds.height;
          break;
        case AxisDirection.left:
          double offset;
          switch (growthDirection) {
            case GrowthDirection.forward:
              offset = bounds.right;
              break;
            case GrowthDirection.reverse:
              offset = bounds.left;
              break;
          }
          leadingScrollOffset = pivot.size.width - offset;
          targetMainAxisExtent = bounds.width;
          break;
      }
      descendant = pivot;
    } else if (target is RenderSliver) {
      final RenderSliver targetSliver = target;
      leadingScrollOffset = 0.0;
      targetMainAxisExtent = targetSliver.geometry.scrollExtent;
      descendant = targetSliver;
    } else {
      return offset.pixels;
    }

    // The child will be the topmost object before we get to the viewport.
    RenderObject child = descendant;
    while (child.parent is RenderSliver) {
      final RenderSliver parent = child.parent;
      leadingScrollOffset += parent.childScrollOffset(child);
      child = parent;
    }

    assert(child.parent == this);
    assert(child is RenderSliver);
    final RenderSliver sliver = child;
    final double extentOfPinnedSlivers = maxScrollObstructionExtentBefore(sliver);
    leadingScrollOffset = scrollOffsetOf(sliver, leadingScrollOffset);
    switch (sliver.constraints.growthDirection) {
      case GrowthDirection.forward:
        leadingScrollOffset -= extentOfPinnedSlivers;
        break;
      case GrowthDirection.reverse:
        // Nothing to do.
        break;
    }

    double mainAxisExtent;
    switch (axis) {
      case Axis.horizontal:
        mainAxisExtent = size.width - extentOfPinnedSlivers;
        break;
      case Axis.vertical:
        mainAxisExtent = size.height - extentOfPinnedSlivers;
        break;
    }

    return leadingScrollOffset - (mainAxisExtent - targetMainAxisExtent) * alignment;
  }

  /// The offset at which the given `child` should be painted.
  ///
  /// The returned offset is from the top left corner of the inside of the
  /// viewport to the top left corner of the paint coordinate system of the
  /// `child`.
  ///
  /// See also [paintOffsetOf], which uses the layout offset and growth
  /// direction computed for the child during layout.
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
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new EnumProperty<AxisDirection>('axisDirection', axisDirection));
    description.add(new EnumProperty<AxisDirection>('crossAxisDirection', crossAxisDirection));
    description.add(new DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    RenderSliver child = firstChild;
    if (child == null)
      return children;

    int count = indexOfFirstChild;
    while (true) {
      children.add(child.toDiagnosticsNode(name: labelForChild(count)));
      if (child == lastChild)
        break;
      count += 1;
      child = childAfter(child);
    }
    return children;
  }

  // API TO BE IMPLEMENTED BY SUBCLASSES

  // setupParentData

  // performLayout (and optionally sizedByParent and performResize)

  /// Whether the contents of this viewport would paint outside the bounds of
  /// the viewport if [paint] did not clip.
  ///
  /// This property enables an optimization whereby [paint] can skip apply a
  /// clip of the contents of the viewport are known to paint entirely within
  /// the bounds of the viewport.
  @protected
  bool get hasVisualOverflow;

  /// Called during [layoutChildSequence] for each child.
  ///
  /// Typically used by subclasses to update any out-of-band data, such as the
  /// max scroll extent, for each child.
  @protected
  void updateOutOfBandData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry);

  /// Called during [layoutChildSequence] to store the layout offset for the
  /// given child.
  ///
  /// Different subclasses using different representations for their children's
  /// layout offset (e.g., logical or physical coordinates). This function lets
  /// subclasses transform the child's layout offset before storing it in the
  /// child's parent data.
  @protected
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection);

  /// The offset at which the given `child` should be painted.
  ///
  /// The returned offset is from the top left corner of the inside of the
  /// viewport to the top left corner of the paint coordinate system of the
  /// `child`.
  ///
  /// See also [computeAbsolutePaintOffset], which computes the paint offset
  /// from an explicit layout offset and growth direction instead of using the
  /// values computed for the child during layout.
  @protected
  Offset paintOffsetOf(RenderSliver child);

  /// Returns the scroll offset within the viewport for the given
  /// `scrollOffsetWithinChild` within the given `child`.
  ///
  /// The returned value is an estimate that assumes the slivers within the
  /// viewport do not change the layout extent in response to changes in their
  /// scroll offset.
  @protected
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild);

  /// Returns the total scroll obstruction extent of all slivers in the viewport
  /// before [child].
  ///
  /// This is the extent by which the actual area in which content can scroll
  /// is reduced. For example, an app bar that is pinned at the top will reduce
  /// the area in which content can actually scroll by the height of the app bar.
  @protected
  double maxScrollObstructionExtentBefore(RenderSliver child);

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

  /// The index of the first child of the viewport relative to the center child.
  ///
  /// For example, the center child has index zero and the first child in the
  /// reverse growth direction has index -1.
  @protected
  int get indexOfFirstChild;

  /// A short string to identify the child with the given index.
  ///
  /// Used by [debugDescribeChildren] to label the children.
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

  @override
  void showOnScreen([RenderObject child]) {
    // Logic duplicated in [_RenderSingleChildViewport.showOnScreen].
    if (child != null) {
      // TODO(goderbauer): Don't scroll if it is already visible.
      // TODO(goderbauer): Don't guess if we need to align at leading or trailing edge.
      // Move viewport the smallest distance to bring [child] on screen.
      final double leadingEdgeOffset = getOffsetToReveal(child, 0.0);
      final double trailingEdgeOffset = getOffsetToReveal(child, 1.0);
      final double currentOffset = offset.pixels;
      // TODO(goderbauer): Don't scroll if that puts us outside of viewport's bounds.
      if ((currentOffset - leadingEdgeOffset).abs() < (currentOffset - trailingEdgeOffset).abs()) {
        offset.jumpTo(leadingEdgeOffset);
      } else {
        offset.jumpTo(trailingEdgeOffset);
      }
    }
    // Make sure the viewport itself is on screen.
    super.showOnScreen();
  }
}

/// A render object that is bigger on the inside.
///
/// [RenderViewport] is the visual workhorse of the scrolling machinery. It
/// displays a subset of its children according to its own dimensions and the
/// given [offset]. As the offset varies, different children are visible through
/// the viewport.
///
/// [RenderViewport] hosts a bidirectional list of slivers, anchored on a
/// [center] sliver, which is placed at the zero scroll offset. The center
/// widget is displayed in the viewport according to the [anchor] property.
///
/// Slivers that are earlier in the child list than [center] are displayed in
/// reverse order in the reverse [axisDirection] starting from the [center]. For
/// example, if the [axisDirection] is [AxisDirection.down], the first sliver
/// before [center] is placed above the [center]. The slivers that are later in
/// the child list than [center] are placed in order in the [axisDirection]. For
/// example, in the preceding scenario, the first sliver after [center] is
/// placed below the [center].
///
/// [RenderViewport] cannot contain [RenderBox] children directly. Instead, use
/// a [RenderSliverList], [RenderSliverFixedExtentList], [RenderSliverGrid], or
/// a [RenderSliverToBoxAdapter], for example.
///
/// See also:
///
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
///  * [RenderShrinkWrappingViewport], a variant of [RenderViewport] that
///    shrink-wraps its contents along the main axis.
class RenderViewport extends RenderViewportBase<SliverPhysicalContainerParentData> {
  /// Creates a viewport for [RenderSliver] objects.
  ///
  /// If the [center] is not specified, then the first child in the `children`
  /// list, if any, is used.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [new ViewportOffset.zero] or [new ViewportOffset.fixed].
  RenderViewport({
    AxisDirection axisDirection: AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    double anchor: 0.0,
    List<RenderSliver> children,
    RenderSliver center,
  }) : assert(anchor != null),
       assert(anchor >= 0.0 && anchor <= 1.0),
       _anchor = anchor,
       _center = center,
       super(axisDirection: axisDirection, crossAxisDirection: crossAxisDirection, offset: offset) {
    addAll(children);
    if (center == null && firstChild != null)
      _center = firstChild;
  }

  /// If a [RenderAbstractViewport] overrides
  /// [RenderObject.describeSemanticsConfiguration] to add the [SemanticsTag]
  /// [useTwoPaneSemantics] to its [SemanticsConfiguration], two semantics nodes
  /// will be used to represent the viewport with its associated scrolling
  /// actions in the semantics tree.
  ///
  /// Two semantics nodes (an inner and an outer node) are necessary to exclude
  /// certain child nodes (via the [excludeFromScrolling] tag) from the
  /// scrollable area for semantic purposes: The [SemanticsNode]s of children
  /// that should be excluded from scrolling will be attached to the outer node.
  /// The semantic scrolling actions and the [SemanticsNode]s of scrollable
  /// children will be attached to the inner node, which itself is a child of
  /// the outer node.
  static const SemanticsTag useTwoPaneSemantics = const SemanticsTag('RenderViewport.twoPane');

  /// When a top-level [SemanticsNode] below a [RenderAbstractViewport] is
  /// tagged with [excludeFromScrolling] it will not be part of the scrolling
  /// area for semantic purposes.
  ///
  /// This behavior is only active if the [RenderAbstractViewport]
  /// tagged its [SemanticsConfiguration] with [useTwoPaneSemantics].
  /// Otherwise, the [excludeFromScrolling] tag is ignored.
  ///
  /// As an example, a [RenderSliver] that stays on the screen within a
  /// [Scrollable] even though the user has scrolled past it (e.g. a pinned app
  /// bar) can tag its [SemanticsNode] with [excludeFromScrolling] to indicate
  /// that it should no longer be considered for semantic actions related to
  /// scrolling.
  static const SemanticsTag excludeFromScrolling = const SemanticsTag('RenderViewport.excludeFromScrolling');

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData)
      child.parentData = new SliverPhysicalContainerParentData();
  }

  /// The relative position of the zero scroll offset.
  ///
  /// For example, if [anchor] is 0.5 and the [axisDirection] is
  /// [AxisDirection.down] or [AxisDirection.up], then the zero scroll offset is
  /// vertically centered within the viewport. If the [anchor] is 1.0, and the
  /// [axisDirection] is [AxisDirection.right], then the zero scroll offset is
  /// on the left edge of the viewport.
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

  /// The first child in the [GrowthDirection.forward] growth direction.
  ///
  /// Children after [center] will be placed in the [axisDirection] relative to
  /// the [center]. Children before [center] will be placed in the opposite of
  /// the [axisDirection] relative to the [center].
  ///
  /// The [center] must be a child of the viewport.
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
    assert(() {
      if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
        switch (axis) {
          case Axis.vertical:
            if (!constraints.hasBoundedHeight) {
              throw new FlutterError(
                'Vertical viewport was given unbounded height.\n'
                'Viewports expand in the scrolling direction to fill their container.'
                'In this case, a vertical viewport was given an unlimited amount of '
                'vertical space in which to expand. This situation typically happens '
                'when a scrollable widget is nested inside another scrollable widget.\n'
                'If this widget is always nested in a scrollable widget there '
                'is no need to use a viewport because there will always be enough '
                'vertical space for the children. In this case, consider using a '
                'Column instead. Otherwise, consider using the "shrinkWrap" property '
                '(or a ShrinkWrappingViewport) to size the height of the viewport '
                'to the sum of the heights of its children.'
              );
            }
            if (!constraints.hasBoundedWidth) {
              throw new FlutterError(
                'Vertical viewport was given unbounded width.\n'
                'Viewports expand in the cross axis to fill their container and '
                'constrain their children to match their extent in the cross axis. '
                'In this case, a vertical viewport was given an unlimited amount of '
                'horizontal space in which to expand.'
              );
            }
            break;
          case Axis.horizontal:
            if (!constraints.hasBoundedWidth) {
              throw new FlutterError(
                'Horizontal viewport was given unbounded width.\n'
                'Viewports expand in the scrolling direction to fill their container.'
                'In this case, a horizontal viewport was given an unlimited amount of '
                'horizontal space in which to expand. This situation typically happens '
                'when a scrollable widget is nested inside another scrollable widget.\n'
                'If this widget is always nested in a scrollable widget there '
                'is no need to use a viewport because there will always be enough '
                'horizontal space for the children. In this case, consider using a '
                'Row instead. Otherwise, consider using the "shrinkWrap" property '
                '(or a ShrinkWrappingViewport) to size the width of the viewport '
                'to the sum of the widths of its children.'
              );
            }
            if (!constraints.hasBoundedHeight) {
              throw new FlutterError(
                'Horizontal viewport was given unbounded height.\n'
                'Viewports expand in the cross axis to fill their container and '
                'constrain their children to match their extent in the cross axis. '
                'In this case, a horizontal viewport was given an unlimited amount of '
                'vertical space in which to expand.'
              );
            }
            break;
        }
      }
      return true;
    }());
    size = constraints.biggest;
    // We ignore the return value of applyViewportDimension below because we are
    // going to go through performLayout next regardless.
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
          'A RenderViewport exceeded its maximum number of layout cycles.\n'
          'RenderViewport render objects, during layout, can retry if either their '
          'slivers or their ViewportOffset decide that the offset should be corrected '
          'to take into account information collected during that layout.\n'
          'In the case of this RenderViewport object, however, this happened $count '
          'times and still there was no consensus on the scroll offset. This usually '
          'indicates a bug. Specifically, it means that one of the following three '
          'problems is being experienced by the RenderViewport object:\n'
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
    }());
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

    // centerOffset is the offset from the leading edge of the RenderViewport
    // to the zero scroll offset (the line between the forward slivers and the
    // reverse slivers). The other two are that, but clamped to the visible
    // region of the viewport.
    final double centerOffset = mainAxisExtent * anchor - correctedOffset;
    final double clampedForwardCenter = math.max(0.0, math.min(mainAxisExtent, centerOffset));
    final double clampedReverseCenter = math.max(0.0, math.min(mainAxisExtent, mainAxisExtent - centerOffset));

    final RenderSliver leadingNegativeChild = childBefore(center);

    if (leadingNegativeChild != null) {
      // negative scroll offsets
      final double result = layoutChildSequence(
        leadingNegativeChild,
        math.max(mainAxisExtent, centerOffset) - mainAxisExtent,
        0.0,
        clampedReverseCenter,
        clampedForwardCenter,
        mainAxisExtent,
        crossAxisExtent,
        GrowthDirection.reverse,
        childBefore,
      );
      if (result != 0.0)
        return -result;
    }

    // positive scroll offsets
    return layoutChildSequence(
      center,
      math.max(0.0, -centerOffset),
      leadingNegativeChild == null ? math.min(0.0, -centerOffset) : 0.0,
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
  void updateOutOfBandData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
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
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    assert(growthDirection != null);
    switch (growthDirection) {
      case GrowthDirection.forward:
        double scrollOffsetToChild = 0.0;
        RenderSliver current = center;
        while (current != child) {
          scrollOffsetToChild += current.geometry.scrollExtent;
          current = childAfter(current);
        }
        return scrollOffsetToChild + scrollOffsetWithinChild;
      case GrowthDirection.reverse:
        double scrollOffsetToChild = 0.0;
        RenderSliver current = childBefore(center);
        while (current != child) {
          scrollOffsetToChild -= current.geometry.scrollExtent;
          current = childBefore(current);
        }
        return scrollOffsetToChild - scrollOffsetWithinChild;
    }
    return null;
  }

  @override
  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    assert(growthDirection != null);
    switch (growthDirection) {
      case GrowthDirection.forward:
        double pinnedExtent = 0.0;
        RenderSliver current = center;
        while (current != child) {
          pinnedExtent += current.geometry.maxScrollObstructionExtent;
          current = childAfter(current);
        }
        return pinnedExtent;
      case GrowthDirection.reverse:
        double pinnedExtent = 0.0;
        RenderSliver current = childBefore(center);
        while (current != child) {
          pinnedExtent += current.geometry.maxScrollObstructionExtent;
          current = childBefore(current);
        }
        return pinnedExtent;
    }
    return null;
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
  int get indexOfFirstChild {
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
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('anchor', anchor));
  }
}

/// A render object that is bigger on the inside and shrink wraps its children
/// in the main axis.
///
/// [RenderShrinkWrappingViewport] displays a subset of its children according
/// to its own dimensions and the given [offset]. As the offset varies, different
/// children are visible through the viewport.
///
/// [RenderShrinkWrappingViewport] differs from [RenderViewport] in that
/// [RenderViewport] expands to fill the main axis whereas
/// [RenderShrinkWrappingViewport] sizes itself to match its children in the
/// main axis. This shrink wrapping behavior is expensive because the children,
/// and hence the viewport, could potentially change size whenever the [offset]
/// changes (e.g., because of a collapsing header).
///
/// [RenderShrinkWrappingViewport] cannot contain [RenderBox] children directly.
/// Instead, use a [RenderSliverList], [RenderSliverFixedExtentList],
/// [RenderSliverGrid], or a [RenderSliverToBoxAdapter], for example.
///
/// See also:
///
///  * [RenderViewport], a viewport that does not shrink-wrap its contents
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
class RenderShrinkWrappingViewport extends RenderViewportBase<SliverLogicalContainerParentData> {
  /// Creates a viewport (for [RenderSliver] objects) that shrink-wraps its
  /// contents.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [new ViewportOffset.zero] or [new ViewportOffset.fixed].
  RenderShrinkWrappingViewport({
    AxisDirection axisDirection: AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    List<RenderSliver> children,
  }) : super(axisDirection: axisDirection, crossAxisDirection: crossAxisDirection, offset: offset) {
    addAll(children);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverLogicalContainerParentData)
      child.parentData = new SliverLogicalContainerParentData();
  }

  @override
  bool debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw new FlutterError(
          '$runtimeType does not support returning intrinsic dimensions.\n'
          'Calculating the intrinsic dimensions would require instantiating every child of '
          'the viewport, which defeats the point of viewports being lazy.\n'
          'If you are merely trying to shrink-wrap the viewport in the main axis direction, '
          'you should be able to achieve that effect by just giving the viewport loose '
          'constraints, without needing to measure its intrinsic dimensions.'
        );
      }
      return true;
    }());
    return true;
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
        final bool didAcceptViewportDimension = offset.applyViewportDimension(effectiveExtent);
        final bool didAcceptContentDimension = offset.applyContentDimensions(0.0, math.max(0.0, _maxScrollExtent - effectiveExtent));
        if (didAcceptViewportDimension && didAcceptContentDimension)
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
    return layoutChildSequence(
      firstChild,
      math.max(0.0, correctedOffset),
      math.min(0.0, correctedOffset),
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
  void updateOutOfBandData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
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
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    assert(child.constraints.growthDirection == GrowthDirection.forward);
    double scrollOffsetToChild = 0.0;
    RenderSliver current = firstChild;
    while (current != child) {
      scrollOffsetToChild += current.geometry.scrollExtent;
      current = childAfter(current);
    }
    return scrollOffsetToChild + scrollOffsetWithinChild;
  }

  @override
  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    assert(child.constraints.growthDirection == GrowthDirection.forward);
    double pinnedExtent = 0.0;
    RenderSliver current = firstChild;
    while (current != child) {
      pinnedExtent += current.geometry.maxScrollObstructionExtent;
      current = childAfter(current);
    }
    return pinnedExtent;
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
  int get indexOfFirstChild => 0;

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
