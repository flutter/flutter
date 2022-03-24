// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'box.dart';
import 'layer.dart';
import 'object.dart';
import 'viewport.dart';
import 'viewport_offset.dart';

typedef _ChildSizingFunction = double Function(RenderBox child);

/// A delegate used by [RenderListWheelViewport] to manage its children.
///
/// [RenderListWheelViewport] during layout will ask the delegate to create
/// children that are visible in the viewport and remove those that are not.
abstract class ListWheelChildManager {
  /// The maximum number of children that can be provided to
  /// [RenderListWheelViewport].
  ///
  /// If non-null, the children will have index in the range
  /// `[0, childCount - 1]`.
  ///
  /// If null, then there's no explicit limits to the range of the children
  /// except that it has to be contiguous. If [childExistsAt] for a certain
  /// index returns false, that index is already past the limit.
  int? get childCount;

  /// Checks whether the delegate is able to provide a child widget at the given
  /// index.
  ///
  /// This function is not about whether the child at the given index is
  /// attached to the [RenderListWheelViewport] or not.
  bool childExistsAt(int index);

  /// Creates a new child at the given index and updates it to the child list
  /// of [RenderListWheelViewport]. If no child corresponds to `index`, then do
  /// nothing.
  ///
  /// It is possible to create children with negative indices.
  void createChild(int index, { required RenderBox? after });

  /// Removes the child element corresponding with the given RenderBox.
  void removeChild(RenderBox child);
}

/// [ParentData] for use with [RenderListWheelViewport].
class ListWheelParentData extends ContainerBoxParentData<RenderBox> {
  /// Index of this child in its parent's child list.
  ///
  /// This must be maintained by the [ListWheelChildManager].
  int? index;
}

/// Render, onto a wheel, a bigger sequential set of objects inside this viewport.
///
/// Takes a scrollable set of fixed sized [RenderBox]es and renders them
/// sequentially from top down on a vertical scrolling axis.
///
/// It starts with the first scrollable item in the center of the main axis
/// and ends with the last scrollable item in the center of the main axis. This
/// is in contrast to typical lists that start with the first scrollable item
/// at the start of the main axis and ends with the last scrollable item at the
/// end of the main axis.
///
/// Instead of rendering its children on a flat plane, it renders them
/// as if each child is broken into its own plane and that plane is
/// perpendicularly fixed onto a cylinder which rotates along the scrolling
/// axis.
///
/// This class works in 3 coordinate systems:
///
/// 1. The **scrollable layout coordinates**. This coordinate system is used to
///    communicate with [ViewportOffset] and describes its children's abstract
///    offset from the beginning of the scrollable list at (0.0, 0.0).
///
///    The list is scrollable from the start of the first child item to the
///    start of the last child item.
///
///    Children's layout coordinates don't change as the viewport scrolls.
///
/// 2. The **untransformed plane's viewport painting coordinates**. Children are
///    not painted in this coordinate system. It's an abstract intermediary used
///    before transforming into the next cylindrical coordinate system.
///
///    This system is the **scrollable layout coordinates** translated by the
///    scroll offset such that (0.0, 0.0) is the top left corner of the
///    viewport.
///
///    Because the viewport is centered at the scrollable list's scroll offset
///    instead of starting at the scroll offset, there are paintable children
///    ~1/2 viewport length before and after the scroll offset instead of ~1
///    viewport length after the scroll offset.
///
///    Children's visibility inclusion in the viewport is determined in this
///    system regardless of the cylinder's properties such as [diameterRatio]
///    or [perspective]. In other words, a 100px long viewport will always
///    paint 10-11 visible 10px children if there are enough children in the
///    viewport.
///
/// 3. The **transformed cylindrical space viewport painting coordinates**.
///    Children from system 2 get their positions transformed into a cylindrical
///    projection matrix instead of its Cartesian offset with respect to the
///    scroll offset.
///
///    Children in this coordinate system are painted.
///
///    The wheel's size and the maximum and minimum visible angles are both
///    controlled by [diameterRatio]. Children visible in the **untransformed
///    plane's viewport painting coordinates**'s viewport will be radially
///    evenly laid out between the maximum and minimum angles determined by
///    intersecting the viewport's main axis length with a cylinder whose
///    diameter is [diameterRatio] times longer, as long as those angles are
///    between -pi/2 and pi/2.
///
///    For example, if [diameterRatio] is 2.0 and this [RenderListWheelViewport]
///    is 100.0px in the main axis, then the diameter is 200.0. And children
///    will be evenly laid out between that cylinder's -arcsin(1/2) and
///    arcsin(1/2) angles.
///
///    The cylinder's 0 degree side is always centered in the
///    [RenderListWheelViewport]. The transformation from **untransformed
///    plane's viewport painting coordinates** is also done such that the child
///    in the center of that plane will be mostly untransformed with children
///    above and below it being transformed more as the angle increases.
class RenderListWheelViewport
    extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ListWheelParentData>
    implements RenderAbstractViewport {
  /// Creates a [RenderListWheelViewport] which renders children on a wheel.
  ///
  /// All arguments must not be null. Optional arguments have reasonable defaults.
  RenderListWheelViewport({
    required this.childManager,
    required ViewportOffset offset,
    double diameterRatio = defaultDiameterRatio,
    double perspective = defaultPerspective,
    double offAxisFraction = 0,
    bool useMagnifier = false,
    double magnification = 1,
    double overAndUnderCenterOpacity = 1,
    required double itemExtent,
    double squeeze = 1,
    bool renderChildrenOutsideViewport = false,
    Clip clipBehavior = Clip.none,
    List<RenderBox>? children,
  }) : assert(childManager != null),
       assert(offset != null),
       assert(diameterRatio != null),
       assert(diameterRatio > 0, diameterRatioZeroMessage),
       assert(perspective != null),
       assert(perspective > 0),
       assert(perspective <= 0.01, perspectiveTooHighMessage),
       assert(offAxisFraction != null),
       assert(useMagnifier != null),
       assert(magnification != null),
       assert(magnification > 0),
       assert(overAndUnderCenterOpacity != null),
       assert(overAndUnderCenterOpacity >= 0 && overAndUnderCenterOpacity <= 1),
       assert(itemExtent != null),
       assert(squeeze != null),
       assert(squeeze > 0),
       assert(itemExtent > 0),
       assert(renderChildrenOutsideViewport != null),
       assert(clipBehavior != null),
       assert(
         !renderChildrenOutsideViewport || clipBehavior == Clip.none,
         clipBehaviorAndRenderChildrenOutsideViewportConflict,
       ),
       _offset = offset,
       _diameterRatio = diameterRatio,
       _perspective = perspective,
       _offAxisFraction = offAxisFraction,
       _useMagnifier = useMagnifier,
       _magnification = magnification,
       _overAndUnderCenterOpacity = overAndUnderCenterOpacity,
       _itemExtent = itemExtent,
       _squeeze = squeeze,
       _renderChildrenOutsideViewport = renderChildrenOutsideViewport,
       _clipBehavior = clipBehavior {
    addAll(children);
  }

  /// An arbitrary but aesthetically reasonable default value for [diameterRatio].
  static const double defaultDiameterRatio = 2.0;

  /// An arbitrary but aesthetically reasonable default value for [perspective].
  static const double defaultPerspective = 0.003;

  /// An error message to show when the provided [diameterRatio] is zero.
  static const String diameterRatioZeroMessage = "You can't set a diameterRatio "
      'of 0 or of a negative number. It would imply a cylinder of 0 in diameter '
      'in which case nothing will be drawn.';

  /// An error message to show when the [perspective] value is too high.
  static const String perspectiveTooHighMessage = 'A perspective too high will '
      'be clipped in the z-axis and therefore not renderable. Value must be '
      'between 0 and 0.01.';

  /// An error message to show when [clipBehavior] and [renderChildrenOutsideViewport]
  /// are set to conflicting values.
  static const String clipBehaviorAndRenderChildrenOutsideViewportConflict =
      'Cannot renderChildrenOutsideViewport and clip since children '
      'rendered outside will be clipped anyway.';

  /// The delegate that manages the children of this object.
  ///
  /// This delegate must maintain the [ListWheelParentData.index] value.
  final ListWheelChildManager childManager;

  /// The associated ViewportOffset object for the viewport describing the part
  /// of the content inside that's visible.
  ///
  /// The [ViewportOffset.pixels] value determines the scroll offset that the
  /// viewport uses to select which part of its content to display. As the user
  /// scrolls the viewport, this value changes, which changes the content that
  /// is displayed.
  ///
  /// Must not be null.
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset)
      return;
    if (attached)
      _offset.removeListener(_hasScrolled);
    _offset = value;
    if (attached)
      _offset.addListener(_hasScrolled);
    markNeedsLayout();
  }

  /// {@template flutter.rendering.RenderListWheelViewport.diameterRatio}
  /// A ratio between the diameter of the cylinder and the viewport's size
  /// in the main axis.
  ///
  /// A value of 1 means the cylinder has the same diameter as the viewport's
  /// size.
  ///
  /// A value smaller than 1 means items at the edges of the cylinder are
  /// entirely contained inside the viewport.
  ///
  /// A value larger than 1 means angles less than ±[pi] / 2 from the
  /// center of the cylinder are visible.
  ///
  /// The same number of children will be visible in the viewport regardless of
  /// the [diameterRatio]. The number of children visible is based on the
  /// viewport's length along the main axis divided by the children's
  /// [itemExtent]. Then the children are evenly distributed along the visible
  /// angles up to ±[pi] / 2.
  ///
  /// Just as it's impossible to stretch a paper to cover the an entire
  /// half of a cylinder's surface where the cylinder has the same diameter
  /// as the paper's length, choosing a [diameterRatio] smaller than [pi]
  /// will leave same gaps between the children.
  ///
  /// Defaults to an arbitrary but aesthetically reasonable number of 2.0.
  ///
  /// Must not be null and must be positive.
  /// {@endtemplate}
  double get diameterRatio => _diameterRatio;
  double _diameterRatio;
  set diameterRatio(double value) {
    assert(value != null);
    assert(
      value > 0,
      diameterRatioZeroMessage,
    );
    if (value == _diameterRatio)
      return;
    _diameterRatio = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// {@template flutter.rendering.RenderListWheelViewport.perspective}
  /// Perspective of the cylindrical projection.
  ///
  /// A number between 0 and 0.01 where 0 means looking at the cylinder from
  /// infinitely far with an infinitely small field of view and 1 means looking
  /// at the cylinder from infinitely close with an infinitely large field of
  /// view (which cannot be rendered).
  ///
  /// Defaults to an arbitrary but aesthetically reasonable number of 0.003.
  /// A larger number brings the vanishing point closer and a smaller number
  /// pushes the vanishing point further.
  ///
  /// Must not be null and must be positive.
  /// {@endtemplate}
  double get perspective => _perspective;
  double _perspective;
  set perspective(double value) {
    assert(value != null);
    assert(value > 0);
    assert(
      value <= 0.01,
      perspectiveTooHighMessage,
    );
    if (value == _perspective)
      return;
    _perspective = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// {@template flutter.rendering.RenderListWheelViewport.offAxisFraction}
  /// How much the wheel is horizontally off-center, as a fraction of its width.

  /// This property creates the visual effect of looking at a vertical wheel from
  /// its side where its vanishing points at the edge curves to one side instead
  /// of looking at the wheel head-on.
  ///
  /// The value is horizontal distance between the wheel's center and the vertical
  /// vanishing line at the edges of the wheel, represented as a fraction of the
  /// wheel's width.
  ///
  /// The value `0.0` means the wheel is looked at head-on and its vanishing
  /// line runs through the center of the wheel. Negative values means moving
  /// the wheel to the left of the observer, thus the edges curve to the right.
  /// Positive values means moving the wheel to the right of the observer,
  /// thus the edges curve to the left.
  ///
  /// The visual effect causes the wheel's edges to curve rather than moving
  /// the center. So a value of `0.5` means the edges' vanishing line will touch
  /// the wheel's size's left edge.
  ///
  /// Defaults to `0.0`, which means looking at the wheel head-on.
  /// The visual effect can be unaesthetic if this value is too far from the
  /// range `[-0.5, 0.5]`.
  /// {@endtemplate}
  double get offAxisFraction => _offAxisFraction;
  double _offAxisFraction = 0.0;
  set offAxisFraction(double value) {
    assert(value != null);
    if (value == _offAxisFraction)
      return;
    _offAxisFraction = value;
    markNeedsPaint();
  }

  /// {@template flutter.rendering.RenderListWheelViewport.useMagnifier}
  /// Whether to use the magnifier for the center item of the wheel.
  /// {@endtemplate}
  bool get useMagnifier => _useMagnifier;
  bool _useMagnifier = false;
  set useMagnifier(bool value) {
    assert(value != null);
    if (value == _useMagnifier)
      return;
    _useMagnifier = value;
    markNeedsPaint();
  }
  /// {@template flutter.rendering.RenderListWheelViewport.magnification}
  /// The zoomed-in rate of the magnifier, if it is used.
  ///
  /// The default value is 1.0, which will not change anything.
  /// If the value is > 1.0, the center item will be zoomed in by that rate, and
  /// it will also be rendered as flat, not cylindrical like the rest of the list.
  /// The item will be zoomed out if magnification < 1.0.
  ///
  /// Must be positive.
  /// {@endtemplate}
  double get magnification => _magnification;
  double _magnification = 1.0;
  set magnification(double value) {
    assert(value != null);
    assert(value > 0);
    if (value == _magnification)
      return;
    _magnification = value;
    markNeedsPaint();
  }

  /// {@template flutter.rendering.RenderListWheelViewport.overAndUnderCenterOpacity}
  /// The opacity value that will be applied to the wheel that appears below and
  /// above the magnifier.
  ///
  /// The default value is 1.0, which will not change anything.
  ///
  /// Must be greater than or equal to 0, and less than or equal to 1.
  /// {@endtemplate}
  double get overAndUnderCenterOpacity => _overAndUnderCenterOpacity;
  double _overAndUnderCenterOpacity = 1.0;
  set overAndUnderCenterOpacity(double value) {
    assert(value != null);
    assert(value >= 0 && value <= 1);
    if (value == _overAndUnderCenterOpacity)
      return;
    _overAndUnderCenterOpacity = value;
    markNeedsPaint();
  }

  /// {@template flutter.rendering.RenderListWheelViewport.itemExtent}
  /// The size of the children along the main axis. Children [RenderBox]es will
  /// be given the [BoxConstraints] of this exact size.
  ///
  /// Must not be null and must be positive.
  /// {@endtemplate}
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    assert(value != null);
    assert(value > 0);
    if (value == _itemExtent)
      return;
    _itemExtent = value;
    markNeedsLayout();
  }


  /// {@template flutter.rendering.RenderListWheelViewport.squeeze}
  /// The angular compactness of the children on the wheel.
  ///
  /// This denotes a ratio of the number of children on the wheel vs the number
  /// of children that would fit on a flat list of equivalent size, assuming
  /// [diameterRatio] of 1.
  ///
  /// For instance, if this RenderListWheelViewport has a height of 100px and
  /// [itemExtent] is 20px, 5 items would fit on an equivalent flat list.
  /// With a [squeeze] of 1, 5 items would also be shown in the
  /// RenderListWheelViewport. With a [squeeze] of 2, 10 items would be shown
  /// in the RenderListWheelViewport.
  ///
  /// Changing this value will change the number of children built and shown
  /// inside the wheel.
  ///
  /// Must not be null and must be positive.
  /// {@endtemplate}
  ///
  /// Defaults to 1.
  double get squeeze => _squeeze;
  double _squeeze;
  set squeeze(double value) {
    assert(value != null);
    assert(value > 0);
    if (value == _squeeze)
      return;
    _squeeze = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  /// {@template flutter.rendering.RenderListWheelViewport.renderChildrenOutsideViewport}
  /// Whether to paint children inside the viewport only.
  ///
  /// If false, every child will be painted. However the [Scrollable] is still
  /// the size of the viewport and detects gestures inside only.
  ///
  /// Defaults to false. Must not be null. Cannot be true if [clipBehavior]
  /// is not [Clip.none] since children outside the viewport will be clipped, and
  /// therefore cannot render children outside the viewport.
  /// {@endtemplate}
  bool get renderChildrenOutsideViewport => _renderChildrenOutsideViewport;
  bool _renderChildrenOutsideViewport;
  set renderChildrenOutsideViewport(bool value) {
    assert(value != null);
    assert(
      !renderChildrenOutsideViewport || clipBehavior == Clip.none,
      clipBehaviorAndRenderChildrenOutsideViewportConflict,
    );
    if (value == _renderChildrenOutsideViewport)
      return;
    _renderChildrenOutsideViewport = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  void _hasScrolled() {
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! ListWheelParentData)
      child.parentData = ListWheelParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_hasScrolled);
  }

  @override
  void detach() {
    _offset.removeListener(_hasScrolled);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  /// Main axis length in the untransformed plane.
  double get _viewportExtent {
    assert(hasSize);
    return size.height;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the first item in the center.
  double get _minEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null)
      return double.negativeInfinity;
    return 0.0;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the last item in the center.
  double get _maxEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null)
      return double.infinity;

    return math.max(0.0, (childManager.childCount! - 1) * _itemExtent);
  }

  /// Scroll extent distance in the untransformed plane between the center
  /// position in the viewport and the top position in the viewport.
  ///
  /// It's also the distance in the untransformed plane that children's painting
  /// is offset by with respect to those children's [BoxParentData.offset].
  double get _topScrollMarginExtent {
    assert(hasSize);
    // Consider adding alignment options other than center.
    return -size.height / 2.0 + _itemExtent / 2.0;
  }

  /// Transforms a **scrollable layout coordinates**' y position to the
  /// **untransformed plane's viewport painting coordinates**' y position given
  /// the current scroll offset.
  double _getUntransformedPaintingCoordinateY(double layoutCoordinateY) {
    return layoutCoordinateY - _topScrollMarginExtent - offset.pixels;
  }

  /// Given the _diameterRatio, return the largest absolute angle of the item
  /// at the edge of the portion of the visible cylinder.
  ///
  /// For a _diameterRatio of 1 or less than 1 (i.e. the viewport is bigger
  /// than the cylinder diameter), this value reaches and clips at pi / 2.
  ///
  /// When the center of children passes this angle, they are no longer painted
  /// if [renderChildrenOutsideViewport] is false.
  double get _maxVisibleRadian {
    if (_diameterRatio < 1.0)
      return math.pi / 2.0;
    return math.asin(1.0 / _diameterRatio);
  }

  double _getIntrinsicCrossAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      child = childAfter(child);
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
      (RenderBox child) => child.getMinIntrinsicWidth(height),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
      (RenderBox child) => child.getMaxIntrinsicWidth(height),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (childManager.childCount == null)
      return 0.0;
    return childManager.childCount! * _itemExtent;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (childManager.childCount == null)
      return 0.0;
    return childManager.childCount! * _itemExtent;
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  /// Gets the index of a child by looking at its [parentData].
  ///
  /// This relies on the [childManager] maintaining [ListWheelParentData.index].
  int indexOf(RenderBox child) {
    assert(child != null);
    final ListWheelParentData childParentData = child.parentData! as ListWheelParentData;
    assert(childParentData.index != null);
    return childParentData.index!;
  }

  /// Returns the index of the child at the given offset.
  int scrollOffsetToIndex(double scrollOffset) => (scrollOffset / itemExtent).floor();

  /// Returns the scroll offset of the child with the given index.
  double indexToScrollOffset(int index) => index * itemExtent;

  void _createChild(int index, { RenderBox? after }) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.createChild(index, after: after);
    });
  }

  void _destroyChild(RenderBox child) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.removeChild(child);
    });
  }

  void _layoutChild(RenderBox child, BoxConstraints constraints, int index) {
    child.layout(constraints, parentUsesSize: true);
    final ListWheelParentData childParentData = child.parentData! as ListWheelParentData;
    // Centers the child horizontally.
    final double crossPosition = size.width / 2.0 - child.size.width / 2.0;
    childParentData.offset = Offset(crossPosition, indexToScrollOffset(index));
  }

  /// Performs layout based on how [childManager] provides children.
  ///
  /// From the current scroll offset, the minimum index and maximum index that
  /// is visible in the viewport can be calculated. The index range of the
  /// currently active children can also be acquired by looking directly at
  /// the current child list. This function has to modify the current index
  /// range to match the target index range by removing children that are no
  /// longer visible and creating those that are visible but not yet provided
  /// by [childManager].
  @override
  void performLayout() {
    // Apply the dimensions first in case it changes the scroll offset which
    // determines what should be shown.
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(_minEstimatedScrollExtent, _maxEstimatedScrollExtent);

    // The height, in pixel, that children will be visible and might be laid out
    // and painted.
    double visibleHeight = size.height * _squeeze;
    // If renderChildrenOutsideViewport is true, we spawn extra children by
    // doubling the visibility range, those that are in the backside of the
    // cylinder won't be painted anyway.
    if (renderChildrenOutsideViewport)
      visibleHeight *= 2;

    final double firstVisibleOffset =
      offset.pixels + _itemExtent / 2 - visibleHeight / 2;
    final double lastVisibleOffset = firstVisibleOffset + visibleHeight;

    // The index range that we want to spawn children. We find indexes that
    // are in the interval [firstVisibleOffset, lastVisibleOffset).
    int targetFirstIndex = scrollOffsetToIndex(firstVisibleOffset);
    int targetLastIndex = scrollOffsetToIndex(lastVisibleOffset);
    // Because we exclude lastVisibleOffset, if there's a new child starting at
    // that offset, it is removed.
    if (targetLastIndex * _itemExtent == lastVisibleOffset)
      targetLastIndex--;

    // Validates the target index range.
    while (!childManager.childExistsAt(targetFirstIndex) && targetFirstIndex <= targetLastIndex)
      targetFirstIndex++;
    while (!childManager.childExistsAt(targetLastIndex) && targetFirstIndex <= targetLastIndex)
      targetLastIndex--;

    // If it turns out there's no children to layout, we remove old children and
    // return.
    if (targetFirstIndex > targetLastIndex) {
      while (firstChild != null)
        _destroyChild(firstChild!);
      return;
    }

    // Now there are 2 cases:
    //  - The target index range and our current index range have intersection:
    //    We shorten and extend our current child list so that the two lists
    //    match. Most of the time we are in this case.
    //  - The target list and our current child list have no intersection:
    //    We first remove all children and then add one child from the target
    //    list => this case becomes the other case.

    // Case when there is no intersection.
    if (childCount > 0 &&
        (indexOf(firstChild!) > targetLastIndex || indexOf(lastChild!) < targetFirstIndex)) {
      while (firstChild != null)
        _destroyChild(firstChild!);
    }

    final BoxConstraints childConstraints = constraints.copyWith(
        minHeight: _itemExtent,
        maxHeight: _itemExtent,
        minWidth: 0.0,
      );
    // If there is no child at this stage, we add the first one that is in
    // target range.
    if (childCount == 0) {
      _createChild(targetFirstIndex);
      _layoutChild(firstChild!, childConstraints, targetFirstIndex);
    }

    int currentFirstIndex = indexOf(firstChild!);
    int currentLastIndex = indexOf(lastChild!);

    // Remove all unnecessary children by shortening the current child list, in
    // both directions.
    while (currentFirstIndex < targetFirstIndex) {
      _destroyChild(firstChild!);
      currentFirstIndex++;
    }
    while (currentLastIndex > targetLastIndex) {
      _destroyChild(lastChild!);
      currentLastIndex--;
    }

    // Relayout all active children.
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    // Spawning new children that are actually visible but not in child list yet.
    while (currentFirstIndex > targetFirstIndex) {
      _createChild(currentFirstIndex - 1);
      _layoutChild(firstChild!, childConstraints, --currentFirstIndex);
    }
    while (currentLastIndex < targetLastIndex) {
      _createChild(currentLastIndex + 1, after: lastChild);
      _layoutChild(lastChild!, childConstraints, ++currentLastIndex);
    }

    // Applying content dimensions bases on how the childManager builds widgets:
    // if it is available to provide a child just out of target range, then
    // we don't know whether there's a limit yet, and set the dimension to the
    // estimated value. Otherwise, we set the dimension limited to our target
    // range.
    final double minScrollExtent = childManager.childExistsAt(targetFirstIndex - 1)
      ? _minEstimatedScrollExtent
      : indexToScrollOffset(targetFirstIndex);
    final double maxScrollExtent = childManager.childExistsAt(targetLastIndex + 1)
      ? _maxEstimatedScrollExtent
      : indexToScrollOffset(targetLastIndex);
    offset.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  bool _shouldClipAtCurrentOffset() {
    final double highestUntransformedPaintY =
      _getUntransformedPaintingCoordinateY(0.0);
    return highestUntransformedPaintY < 0.0
      || size.height < highestUntransformedPaintY + _maxEstimatedScrollExtent + _itemExtent;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (childCount > 0) {
      if (_shouldClipAtCurrentOffset() && clipBehavior != Clip.none) {
        _clipRectLayer.layer = context.pushClipRect(
          needsCompositing,
          offset,
          Offset.zero & size,
          _paintVisibleChildren,
          clipBehavior: clipBehavior,
          oldLayer: _clipRectLayer.layer,
        );
      } else {
        _clipRectLayer.layer = null;
        _paintVisibleChildren(context, offset);
      }
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  /// Paints all children visible in the current viewport.
  void _paintVisibleChildren(PaintingContext context, Offset offset) {
    RenderBox? childToPaint = firstChild;
    while (childToPaint != null) {
      final ListWheelParentData childParentData = childToPaint.parentData! as ListWheelParentData;
      _paintTransformedChild(childToPaint, context, offset, childParentData.offset);
      childToPaint = childAfter(childToPaint);
    }
  }

  /// Takes in a child with a **scrollable layout offset** and paints it in the
  /// **transformed cylindrical space viewport painting coordinates**.
  void _paintTransformedChild(
    RenderBox child,
    PaintingContext context,
    Offset offset,
    Offset layoutOffset,
  ) {
    final Offset untransformedPaintingCoordinates = offset
        + Offset(
            layoutOffset.dx,
            _getUntransformedPaintingCoordinateY(layoutOffset.dy),
        );

    // Get child's center as a fraction of the viewport's height.
    final double fractionalY =
        (untransformedPaintingCoordinates.dy + _itemExtent / 2.0) / size.height;
    final double angle = -(fractionalY - 0.5) * 2.0 * _maxVisibleRadian / squeeze;
    // Don't paint the backside of the cylinder when
    // renderChildrenOutsideViewport is true. Otherwise, only children within
    // suitable angles (via _first/lastVisibleLayoutOffset) reach the paint
    // phase.
    if (angle > math.pi / 2.0 || angle < -math.pi / 2.0)
      return;

    final Matrix4 transform = MatrixUtils.createCylindricalProjectionTransform(
      radius: size.height * _diameterRatio / 2.0,
      angle: angle,
      perspective: _perspective,
    );

    // Offset that helps painting everything in the center (e.g. angle = 0).
    final Offset offsetToCenter = Offset(
      untransformedPaintingCoordinates.dx,
      -_topScrollMarginExtent,
    );

    final bool shouldApplyOffCenterDim = overAndUnderCenterOpacity < 1;
    if (useMagnifier || shouldApplyOffCenterDim) {
      _paintChildWithMagnifier(context, offset, child, transform, offsetToCenter, untransformedPaintingCoordinates);
    } else {
      _paintChildCylindrically(context, offset, child, transform, offsetToCenter);
    }
  }

  /// Paint child with the magnifier active - the child will be rendered
  /// differently if it intersects with the magnifier.
  void _paintChildWithMagnifier(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    Matrix4 cylindricalTransform,
    Offset offsetToCenter,
    Offset untransformedPaintingCoordinates,
  ) {
    final double magnifierTopLinePosition =
        size.height / 2 - _itemExtent * _magnification / 2;
    final double magnifierBottomLinePosition =
        size.height / 2 + _itemExtent * _magnification / 2;

    final bool isAfterMagnifierTopLine = untransformedPaintingCoordinates.dy
        >= magnifierTopLinePosition - _itemExtent * _magnification;
    final bool isBeforeMagnifierBottomLine = untransformedPaintingCoordinates.dy
        <= magnifierBottomLinePosition;

    // Some part of the child is in the center magnifier.
    if (isAfterMagnifierTopLine && isBeforeMagnifierBottomLine) {
      final Rect centerRect = Rect.fromLTWH(
        0.0,
        magnifierTopLinePosition,
        size.width,
        _itemExtent * _magnification,
      );
      final Rect topHalfRect = Rect.fromLTWH(
        0.0,
        0.0,
        size.width,
        magnifierTopLinePosition,
      );
      final Rect bottomHalfRect = Rect.fromLTWH(
        0.0,
        magnifierBottomLinePosition,
        size.width,
        magnifierTopLinePosition,
      );

      // Clipping the part in the center.
      context.pushClipRect(
        needsCompositing,
        offset,
        centerRect,
        (PaintingContext context, Offset offset) {
          context.pushTransform(
            needsCompositing,
            offset,
            _magnifyTransform(),
            (PaintingContext context, Offset offset) {
              context.paintChild(child, offset + untransformedPaintingCoordinates);
            },
          );
        },
      );

      // Clipping the part in either the top-half or bottom-half of the wheel.
      context.pushClipRect(
        needsCompositing,
        offset,
        untransformedPaintingCoordinates.dy <= magnifierTopLinePosition
          ? topHalfRect
          : bottomHalfRect,
        (PaintingContext context, Offset offset) {
          _paintChildCylindrically(
            context,
            offset,
            child,
            cylindricalTransform,
            offsetToCenter,
          );
        },
      );
    } else {
      _paintChildCylindrically(
        context,
        offset,
        child,
        cylindricalTransform,
        offsetToCenter,
      );
    }
  }

  // / Paint the child cylindrically at given offset.
  void _paintChildCylindrically(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    Matrix4 cylindricalTransform,
    Offset offsetToCenter,
  ) {
    // Paint child cylindrically, without [overAndUnderCenterOpacity].
    void painter(PaintingContext context, Offset offset) {
      context.paintChild(
        child,
        // Paint everything in the center (e.g. angle = 0), then transform.
        offset + offsetToCenter,
      );
    }

    // Paint child cylindrically, with [overAndUnderCenterOpacity].
    void opacityPainter(PaintingContext context, Offset offset) {
      context.pushOpacity(offset, (overAndUnderCenterOpacity * 255).round(), painter);
    }

    context.pushTransform(
      needsCompositing,
      offset,
      _centerOriginTransform(cylindricalTransform),
      // Pre-transform painting function.
      overAndUnderCenterOpacity == 1 ? painter : opacityPainter,
    );
  }

  /// Return the Matrix4 transformation that would zoom in content in the
  /// magnified area.
  Matrix4 _magnifyTransform() {
    final Matrix4 magnify = Matrix4.identity();
    magnify.translate(size.width * (-_offAxisFraction + 0.5), size.height / 2);
    magnify.scale(_magnification, _magnification, _magnification);
    magnify.translate(-size.width * (-_offAxisFraction + 0.5), -size.height / 2);
    return magnify;
  }

  /// Apply incoming transformation with the transformation's origin at the
  /// viewport's center or horizontally off to the side based on offAxisFraction.
  Matrix4 _centerOriginTransform(Matrix4 originalMatrix) {
    final Matrix4 result = Matrix4.identity();
    final Offset centerOriginTranslation = Alignment.center.alongSize(size);
    result.translate(
      centerOriginTranslation.dx * (-_offAxisFraction * 2 + 1),
      centerOriginTranslation.dy,
    );
    result.multiply(originalMatrix);
    result.translate(
      -centerOriginTranslation.dx * (-_offAxisFraction * 2 + 1),
      -centerOriginTranslation.dy,
    );
    return result;
  }

  /// This returns the matrices relative to the **untransformed plane's viewport
  /// painting coordinates** system.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final ListWheelParentData parentData = child.parentData! as ListWheelParentData;
    transform.translate(0.0, _getUntransformedPaintingCoordinateY(parentData.offset.dy));
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    if (_shouldClipAtCurrentOffset()) {
      return Offset.zero & size;
    }
    return null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) => false;

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment, { Rect? rect }) {
    // `target` is only fully revealed when in the selected/center position. Therefore,
    // this method always returns the offset that shows `target` in the center position,
    // which is the same offset for all `alignment` values.

    rect ??= target.paintBounds;

    // `child` will be the last RenderObject before the viewport when walking up from `target`.
    RenderObject child = target;
    while (child.parent != this)
      child = child.parent! as RenderObject;

    final ListWheelParentData parentData = child.parentData! as ListWheelParentData;
    final double targetOffset = parentData.offset.dy; // the so-called "centerPosition"

    final Matrix4 transform = target.getTransformTo(child);
    final Rect bounds = MatrixUtils.transformRect(transform, rect);
    final Rect targetRect = bounds.translate(0.0, (size.height - itemExtent) / 2);

    return RevealedOffset(offset: targetOffset, rect: targetRect);
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (descendant != null) {
      // Shows the descendant in the selected/center position.
      final RevealedOffset revealedOffset = getOffsetToReveal(descendant, 0.5, rect: rect);
      if (duration == Duration.zero) {
        offset.jumpTo(revealedOffset.offset);
      } else {
        offset.animateTo(revealedOffset.offset, duration: duration, curve: curve);
      }
      rect = revealedOffset.rect;
    }

    super.showOnScreen(
      rect: rect,
      duration: duration,
      curve: curve,
    );
  }
}
