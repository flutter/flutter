// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'binding.dart';
import 'object.dart';
import 'sliver.dart';

class SliverBlockParentData extends SliverLogicalParentData with ContainerParentDataMixin<RenderBox> {
  int index;

  @override
  String toString() => 'index=$index; ${super.toString()}';
}

// ///
// ///
// /// The contract for adding and removing children from this render object is
// /// more strict than for normal render objects:
// ///
// /// - Children can be removed except during a layout pass if they have already
// ///   been laid out during that layout pass.
// /// - Children cannot be added except during a call to [allowAdditionsFor], and
// ///   then only if there is no child correspending to that index (or the child
// ///   child corresponding to that index was first removed).
// ///
// /// ## Writing a RenderSliverBlock subclass
// ///
// /// There are three methods to override:
// ///
// /// - [createChild], which must create the child for the given index, and then
// ///   insert it in the given location in the child list.
// ///
// /// - [removeChild], which is called when the given child is cleaned up,
// ///   and which should remove the given child from the child list.
// ///
// /// - [estimateScrollOffsetExtent], which should return the total extent (e.g.
// ///   the height, if this is a vertical block) of all the children.
abstract class RenderSliverBlock extends RenderSliver
  with ContainerRenderObjectMixin<RenderBox, SliverBlockParentData>,
       RenderSliverHelpers {

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverBlockParentData)
      child.parentData = new SliverBlockParentData();
  }

  /// Called during layout when a new child is needed. The child should be
  /// inserted into the child list in the appropriate position, after the
  /// `after` child (at the start of the list if `after` is null). Its index and
  /// scroll offsets will automatically be set appropriately.
  ///
  /// The `index` argument gives the index of the child to show. The first child
  /// that will be requested will have index zero, and this should be the child
  /// that is aligned with the zero scroll offset. Subsequent requests will be
  /// for indices adjacent to previously requested indices. It is possible for
  /// negative indices to be requested. For example: if the user scrolls from
  /// child 0 to child 10, and then those children get much smaller, and then
  /// the user scrolls back up again, this method will eventually be asked to
  /// produce a child for index -1.
  ///
  /// If no child corresponds to `index`, then do nothing.
  ///
  /// Which child is indicated by index zero depends on the [GrowthDirection]
  /// specified in the [constraints]. For example if the children are the
  /// alphabet, then if [constraints.growthDirection] is
  /// [GrowthDirection.forward] then index zero is A, and index 25 is Z. On the
  /// other hand if [constraints.growthDirection] is [GrowthDirection.reverse]
  /// then index zero is Z, and index 25 is A.
  ///
  /// During a call to [createChild] it is valid to remove other children from
  /// the [RenderSliverBlock] object if they were not created during this frame
  /// and have not yet been updated during this frame. It is not valid to add
  /// any children to this render object.
  @protected
  void createChild(int index, { @required RenderBox after });

  /// Remove the given child from the child list.
  ///
  /// Called by [collectGarbage], which itself is called from [performLayout],
  /// after the layout algorithm has finished and the non-visible children are
  /// to be removed.
  ///
  /// The default implementation calls [remove], which removes the child from
  /// the child list.
  ///
  /// The index of the given child can be obtained using the [indexOf] method,
  /// which reads it from the [SliverBlockParentData.index] field of the child's
  /// [parentData].
  @protected
  void removeChild(RenderBox child) {
    remove(child);
  }

  int _currentlyUpdatingChildIndex;
  @protected
  void allowAdditionsFor(int index, VoidCallback callback) {
    assert(_currentlyUpdatingChildIndex == null);
    assert(index != null);
    _currentlyUpdatingChildIndex = index;
    try {
      callback();
    } finally {
      _currentlyUpdatingChildIndex = null;
    }
  }

  @override
  void adoptChild(RenderObject child) {
    assert(_currentlyUpdatingChildIndex != null);
    super.adoptChild(child);
    final SliverBlockParentData childParentData = child.parentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  @override
  void insert(RenderBox child, { RenderBox after }) {
    super.insert(child, after: after);
    assert(firstChild != null);
    assert(() {
      int index = indexOf(firstChild);
      RenderBox child = childAfter(firstChild);
      while (child != null) {
        assert(indexOf(child) > index);
        index = indexOf(child);
        child = childAfter(child);
      }
      return true;
    });
  }

  /// Called to estimate the total scrollable extents of this object.
  ///
  /// Must return the total distance from the start of the child with the
  /// earliest possible index to the end of the child with the last possible
  /// index.
  @protected
  double estimateScrollOffsetExtent({
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  });

  /// Called during layout to create and add the child with index 0 and scroll
  /// offset 0.0.
  ///
  /// Calls [createChild] to actually create and add the child.
  ///
  /// Returns false if createChild did not add any child, otherwise returns
  /// true.
  ///
  /// Does not layout the new child.
  ///
  /// When this is called, there are no children, so no children can be removed
  /// during the call to createChild. No child should be added during that call
  /// either, except for the one that is created and returned by [createChild].
  @protected
  bool addInitialChild() {
    assert(_currentlyUpdatingChildIndex == null);
    assert(firstChild == null);
    bool result;
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      allowAdditionsFor(0, () {
        createChild(0, after: null);
        if (firstChild != null) {
          assert(firstChild == lastChild);
          assert(indexOf(firstChild) == 0);
          final SliverBlockParentData firstChildParentData = firstChild.parentData;
          firstChildParentData.scrollOffset = 0.0;
          result = true;
        } else {
          result = false;
        }
      });
    });
    return result;
  }

  /// Called during layout to create, add, and layout the child before
  /// [firstChild].
  ///
  /// Calls [createChild] to actually create and add the child.
  ///
  /// Returns the new child.
  ///
  /// The child that was previously the first child, as well as any subsequent
  /// children, may be removed by this call if they have not yet been laid out
  /// during this layout pass. No child should be added during that call except
  /// for the one that is created and returned by [createChild].
  @protected
  RenderBox insertAndLayoutLeadingChild(BoxConstraints childConstraints) {
    assert(_currentlyUpdatingChildIndex == null);
    final int index = indexOf(firstChild) - 1;
    final double endScrollOffset = offsetOf(firstChild);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      allowAdditionsFor(index, () {
        createChild(index, after: null);
      });
    });
    if (indexOf(firstChild) == index) {
      firstChild.layout(childConstraints, parentUsesSize: true);
      SliverBlockParentData firstChildParentData = firstChild.parentData;
      firstChildParentData.scrollOffset = endScrollOffset - paintExtentOf(firstChild);
      return firstChild;
    }
    return null;
  }

  /// Called during layout to create, add, and layout the child after
  /// the given child.
  ///
  /// Calls [createChild] to actually create and add the child.
  ///
  /// Returns the new child. It is the responsibility of the caller to configure
  /// the child's scroll offset.
  ///
  /// Children after the `after` child may be removed in the process. Only the
  /// new child may be added.
  @protected
  RenderBox insertAndLayoutChild(BoxConstraints childConstraints, { @required RenderBox after }) {
    assert(_currentlyUpdatingChildIndex == null);
    assert(after != null);
    final int index = indexOf(after) + 1;
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      allowAdditionsFor(index, () {
        createChild(index, after: after);
      });
    });
    final RenderBox child = childAfter(after);
    if (child != null && indexOf(child) == index) {
      assert(indexOf(child) == index);
      child.layout(childConstraints, parentUsesSize: true);
      return child;
    }
    return null;
  }

  /// Called after layout with the number of children that can be garbage
  /// collected at the head and tail of the child list.
  @protected
  void collectGarbage(int leadingGarbage, int trailingGarbage) {
    assert(_currentlyUpdatingChildIndex == null);
    assert(childCount >= leadingGarbage + trailingGarbage);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      while (leadingGarbage > 0) {
        removeChild(firstChild);
        leadingGarbage -= 1;
      }
      while (trailingGarbage > 0) {
        removeChild(lastChild);
        trailingGarbage -= 1;
      }
    });
  }

  /// Returns the index of the given child, as given by the
  /// [SliverBlockParentData.index] field of the child's [parentData].
  @protected
  int indexOf(RenderBox child) {
    assert(child != null);
    final SliverBlockParentData childParentData = child.parentData;
    assert(childParentData.index != null);
    return childParentData.index;
  }

  /// Returns the scroll offset of the given child, as given by the
  /// [SliverBlockParentData.scrollOffset] field of the child's [parentData].
  @protected
  double offsetOf(RenderBox child) {
    assert(child != null);
    final SliverBlockParentData childParentData = child.parentData;
    assert(childParentData.scrollOffset != null);
    return childParentData.scrollOffset;
  }

  /// Returns the dimension of the given child in the main axis, as given by the
  /// child's [RenderBox.size] property. This is only valid after layout.
  @protected
  double paintExtentOf(RenderBox child) {
    assert(child != null);
    assert(child.hasSize);
    switch (constraints.axis) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
    return null;
  }

  @override
  void performLayout() {
    assert(_currentlyUpdatingChildIndex == null);
    double scrollOffset = constraints.scrollOffset;
    assert(scrollOffset >= 0.0);
    double remainingPaintExtent = constraints.remainingPaintExtent;
    assert(remainingPaintExtent >= 0.0);
    double targetEndScrollOffset = scrollOffset + remainingPaintExtent;
    BoxConstraints childConstraints = constraints.asBoxConstraints();
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    // This algorithm in principle is straight-forward: find the first child
    // that overlaps the given scrollOffset, creating more children at the top
    // of the list if necessary, then walk down the list updating and laying out
    // each child and adding more at the end if necessary until we have enough
    // children to cover the entire viewport.
    //
    // It is complicated by one minor issue, which is that any time you update
    // or create a child, it's possible that the some of the children that
    // haven't yet been laid out will be removed, leaving the list in an
    // inconsistent state, and requiring that missing nodes be recreated.
    //
    // To keep this mess tractable, this algorithm starts from what is currently
    // the first child, if any, and then walks up and/or down from there, so
    // that the nodes that might get removed are always at the edges of what has
    // already been laid out.

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        // There are no children.
        geometry = new SliverGeometry(
          scrollExtent: 0.0,
          paintExtent: 0.0,
          maxPaintExtent: 0.0,
        );
        return;
      }
    }

    // We have at least one child.

    // These variables track the range of children that we have laid out. Within
    // this range, the children have consecutive indices. Outside this range,
    // it's possible for a child to get removed without notice.
    RenderBox leadingChildWithLayout, trailingChildWithLayout;

    // Find the last child that is at or before the scrollOffset.
    RenderBox earliestUsefulChild = firstChild;
    while (offsetOf(earliestUsefulChild) > scrollOffset) {
      // We have to add children before the earliestUsefulChild.
      earliestUsefulChild = insertAndLayoutLeadingChild(childConstraints);
      if (earliestUsefulChild == null) {
        // We ran out of children before reaching the scroll offset.
        // We must inform our parent that this sliver cannot fulfill
        // its contract and that we need a scroll offset correction.
        geometry = new SliverGeometry(
          scrollOffsetCorrection: -offsetOf(firstChild),
        );
        return;
      }
      assert(earliestUsefulChild == firstChild);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }

    // At this point, earliestUsefulChild is the first child, and is a child
    // whose scrollOffset is at or before the scrollOffset, and
    // leadingChildWithLayout and trailingChildWithLayout are either null or
    // cover a range of render boxes that we have laid out with the first being
    // the same as earliestUsefulChild and the last being either at or after the
    // scroll offset.

    assert(earliestUsefulChild == firstChild);
    assert(offsetOf(earliestUsefulChild) <= scrollOffset);

    // Make sure we've laid out at least one child.
    if (leadingChildWithLayout == null) {
      earliestUsefulChild.layout(childConstraints, parentUsesSize: true);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    // Here, earliestUsefulChild is still the first child, it's got a
    // scrollOffset that is at or before our actual scrollOffset, and it has
    // been laid out, and is in fact our leadingChildWithLayout. It's possible
    // that some children beyond that one have also been laid out.

    bool inLayoutRange = true;
    RenderBox child = earliestUsefulChild;
    int index = indexOf(child);
    double endScrollOffset = offsetOf(child) + paintExtentOf(child);
    bool advance() { // returns true if we advanced, false if we have no more children
      // This function is used in two different places below, to avoid code duplication.
      assert(child != null);
      if (child == trailingChildWithLayout)
        inLayoutRange = false;
      child = childAfter(child);
      if (child == null)
        inLayoutRange = false;
      index += 1;
      if (!inLayoutRange) {
        if (child == null || indexOf(child) != index) {
          // We are missing a child. Insert it (and lay it out) if possible.
          child = insertAndLayoutChild(childConstraints, after: trailingChildWithLayout);
          if (child == null) {
            // We have run out of children.
            return false;
          }
        } else {
          // Lay out the child.
          child.layout(childConstraints, parentUsesSize: true);
        }
        trailingChildWithLayout = child;
      }
      assert(child != null);
      final SliverBlockParentData childParentData = child.parentData;
      childParentData.scrollOffset = endScrollOffset;
      assert(childParentData.index == index);
      endScrollOffset = offsetOf(child) + paintExtentOf(child);
      return true;
    }

    // Find the first child that ends after the scroll offset.
    while (endScrollOffset < scrollOffset) {
      leadingGarbage += 1;
      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        // we want to make sure we keep the last child around so we know the end scroll offset
        collectGarbage(leadingGarbage - 1, 0);
        assert(firstChild == lastChild);
        final double extent = offsetOf(lastChild) + paintExtentOf(lastChild);
        geometry = new SliverGeometry(
          scrollExtent: extent,
          paintExtent: 0.0,
          maxPaintExtent: extent,
        );
        return;
      }
    }

    // Now find the first child that ends after our end.
    while (endScrollOffset < targetEndScrollOffset) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }

    // Finally count up all the remaining children and label them as garbage.
    if (child != null) {
      child = childAfter(child);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child);
      }
    }

    // At this point everything should be good to go, we just have to clean up
    // the garbage and report the geometry.

    collectGarbage(leadingGarbage, trailingGarbage);

    assert(firstChild != null);
    assert(() {
      int index = indexOf(firstChild);
      RenderBox child = childAfter(firstChild);
      while (child != null) {
        index += 1;
        assert(indexOf(child) == index);
        child = childAfter(child);
      }
      return true;
    });
    double estimatedTotalExtent;
    if (reachedEnd) {
      estimatedTotalExtent = endScrollOffset;
    } else {
      estimatedTotalExtent = estimateScrollOffsetExtent(
        firstIndex: indexOf(firstChild),
        lastIndex: indexOf(lastChild),
        leadingScrollOffset: offsetOf(firstChild),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedTotalExtent >= endScrollOffset - offsetOf(firstChild));
    }
    double paintedExtent = calculatePaintOffset(
      constraints,
      from: offsetOf(firstChild),
      to: endScrollOffset,
    );
    geometry = new SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintedExtent,
      maxPaintExtent: estimatedTotalExtent,
    );

    assert(_currentlyUpdatingChildIndex == null);
  }

  @override
  bool hitTestChildren(HitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    RenderBox child = lastChild;
    while (child != null) {
      if (child != null) {
        if (hitTestBoxChild(result, child, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition))
          return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  double childPosition(RenderBox child) {
    return offsetOf(child);
  }

  // TODO(ianh): There's a lot of duplicate code in the next two functions,
  // but I don't see a good way to avoid it, since both functions are hot.

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // coordinate system origin here is at the top-left corner, regardless of our axis direction.
    // originOffset gives us the delta from the real origin to the origin in the axis direction.
    Offset unitOffset, originOffset;
    bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        unitOffset = const Offset(0.0, -1.0);
        originOffset = new Offset(0.0, geometry.paintExtent);
        addExtent = true;
        break;
      case AxisDirection.right:
        unitOffset = const Offset(1.0, 0.0);
        originOffset = Offset.zero;
        addExtent = false;
        break;
      case AxisDirection.down:
        unitOffset = const Offset(0.0, 1.0);
        originOffset = Offset.zero;
        addExtent = false;
        break;
      case AxisDirection.left:
        unitOffset = const Offset(-1.0, 0.0);
        originOffset = new Offset(geometry.paintExtent, 0.0);
        addExtent = true;
        break;
    }
    assert(unitOffset != null);
    assert(addExtent != null);
    Offset childOffset = originOffset + unitOffset * (offsetOf(child) - constraints.scrollOffset);
    if (addExtent)
      childOffset += unitOffset * paintExtentOf(child);
    transform.translate(childOffset.dx, childOffset.dy);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null)
      return;
    // offset is to the top-left corner, regardless of our axis direction.
    // originOffset gives us the delta from the real origin to the origin in the axis direction.
    Offset unitOffset, originOffset;
    bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        unitOffset = const Offset(0.0, -1.0);
        originOffset = offset + new Offset(0.0, geometry.paintExtent);
        addExtent = true;
        break;
      case AxisDirection.right:
        unitOffset = const Offset(1.0, 0.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.down:
        unitOffset = const Offset(0.0, 1.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.left:
        unitOffset = const Offset(-1.0, 0.0);
        originOffset = offset + new Offset(geometry.paintExtent, 0.0);
        addExtent = true;
        break;
    }
    assert(unitOffset != null);
    assert(addExtent != null);
    RenderBox child = firstChild;
    while (child != null) {
      Offset childOffset = originOffset + unitOffset * (offsetOf(child) - constraints.scrollOffset);
      if (addExtent)
        childOffset += unitOffset * paintExtentOf(child);
      context.paintChild(child, childOffset);
      child = childAfter(child);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (firstChild != null) {
      description.add('currently live children: ${indexOf(firstChild)} to ${indexOf(lastChild)}');
    } else {
      description.add('no children current live');
    }
  }
}
