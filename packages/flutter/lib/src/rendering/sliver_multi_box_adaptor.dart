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

/// A delegate used by [RenderSliverMultiBoxAdaptor] to manage its children.
///
/// [RenderSliverMultiBoxAdaptor] objects reify their children lazily to avoid
/// spending resources on children that are not visible in the viewport. This
/// delegate lets these objects create and remove children as well as estimate
/// the total scroll offset extent occupied by the full child list.
///
/// Subclasses must override these three methods:
///
/// - [createChild], which must create the child for the given index, and then
///   insert it in the given location in the child list.
///
/// - [removeChild], which is called when the given child is cleaned up,
///   and which should remove the given child from the child list.
///
/// - [estimateScrollOffsetExtent], which should return the total extent (e.g.
///   the height, if this is a vertical layout) of all the children.
abstract class RenderSliverBoxChildManager {
  /// Called during layout when a new child is needed. The child should be
  /// inserted into the child list in the appropriate position, after the
  /// `after` child (at the start of the list if `after` is null). Its index and
  /// scroll offsets will automatically be set appropriately.
  ///
  /// The `index` argument gives the index of the child to show. It is possible
  /// for negative indices to be requested. For example: if the user scrolls
  /// from child 0 to child 10, and then those children get much smaller, and
  /// then the user scrolls back up again, this method will eventually be asked
  /// to produce a child for index -1.
  ///
  /// If no child corresponds to `index`, then do nothing.
  ///
  /// Which child is indicated by index zero depends on the [GrowthDirection]
  /// specified in the [RenderSliverMultiBoxAdaptor.constraints]. For example
  /// if the children are the alphabet, then if
  /// [SliverConstraints.growthDirection] is [GrowthDirection.forward] then
  /// index zero is A, and index 25 is Z. On the other hand if
  /// [SliverConstraints.growthDirection] is [GrowthDirection.reverse]
  /// then index zero is Z, and index 25 is A.
  ///
  /// During a call to [createChild] it is valid to remove other children from
  /// the [RenderSliverMultiBoxAdaptor] object if they were not created during
  /// this frame and have not yet been updated during this frame. It is not
  /// valid to add any other children to this render object.
  void createChild(int index, { @required RenderBox after });

  /// Remove the given child from the child list.
  ///
  /// Called by [RenderSliverMultiBoxAdaptor.collectGarbage], which itself is
  /// called from [RenderSliverMultiBoxAdaptor.performLayout].
  ///
  /// The index of the given child can be obtained using the
  /// [RenderSliverMultiBoxAdaptor.indexOf] method, which reads it from the
  /// [SliverMultiBoxAdaptorParentData.index] field of the child's [parentData].
  void removeChild(RenderBox child);

  /// Called to estimate the total scrollable extents of this object.
  ///
  /// Must return the total distance from the start of the child with the
  /// earliest possible index to the end of the child with the last possible
  /// index.
  double estimateScrollOffsetExtent({
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  });
}

class SliverMultiBoxAdaptorParentData extends SliverLogicalParentData with ContainerParentDataMixin<RenderBox> {
  int index;

  @override
  String toString() => 'index=$index; ${super.toString()}';
}

// /// The contract for adding and removing children from this render object is
// /// more strict than for normal render objects:
// ///
// /// - Children can be removed except during a layout pass if they have already
// ///   been laid out during that layout pass.
// /// - Children cannot be added except during a call to [allowAdditionsFor], and
// ///   then only if there is no child correspending to that index (or the child
// ///   child corresponding to that index was first removed).
abstract class RenderSliverMultiBoxAdaptor extends RenderSliver
  with ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
       RenderSliverHelpers {

  RenderSliverMultiBoxAdaptor({
    @required RenderSliverBoxChildManager childManager
  }) : _childManager = childManager {
    assert(childManager != null);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMultiBoxAdaptorParentData)
      child.parentData = new SliverMultiBoxAdaptorParentData();
  }

  @protected
  RenderSliverBoxChildManager get childManager => _childManager;
  final RenderSliverBoxChildManager _childManager;

  int _currentlyUpdatingChildIndex;

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

  @protected
  bool debugAssertNotCurrentlyAllowingChildAdditions() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  @override
  void adoptChild(RenderObject child) {
    assert(_currentlyUpdatingChildIndex != null);
    super.adoptChild(child);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
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

  /// Called during layout to create and add the child with the given index and
  /// scroll offset.
  ///
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child.
  ///
  /// Returns false if createChild did not add any child, otherwise returns
  /// true.
  ///
  /// Does not layout the new child.
  ///
  /// When this is called, there are no children, so no children can be removed
  /// during the call to createChild. No child should be added during that call
  /// either, except for the one that is created and returned by createChild.
  @protected
  bool addInitialChild({ int index: 0, double scrollOffset: 0.0 }) {
    assert(debugAssertNotCurrentlyAllowingChildAdditions());
    assert(firstChild == null);
    bool result;
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      allowAdditionsFor(index, () {
        _childManager.createChild(index, after: null);
        if (firstChild != null) {
          assert(firstChild == lastChild);
          assert(indexOf(firstChild) == index);
          final SliverMultiBoxAdaptorParentData firstChildParentData = firstChild.parentData;
          firstChildParentData.scrollOffset = scrollOffset;
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
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child.
  ///
  /// Returns the new child or null if no child is created.
  ///
  /// The child that was previously the first child, as well as any subsequent
  /// children, may be removed by this call if they have not yet been laid out
  /// during this layout pass. No child should be added during that call except
  /// for the one that is created and returned by createChild.
  @protected
  RenderBox insertAndLayoutLeadingChild(BoxConstraints childConstraints, {
    bool parentUsesSize: false,
  }) {
    assert(debugAssertNotCurrentlyAllowingChildAdditions());
    final int index = indexOf(firstChild) - 1;
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      allowAdditionsFor(index, () {
        _childManager.createChild(index, after: null);
      });
    });
    if (indexOf(firstChild) == index) {
      firstChild.layout(childConstraints, parentUsesSize: parentUsesSize);
      return firstChild;
    }
    return null;
  }

  /// Called during layout to create, add, and layout the child after
  /// the given child.
  ///
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child.
  ///
  /// Returns the new child. It is the responsibility of the caller to configure
  /// the child's scroll offset.
  ///
  /// Children after the `after` child may be removed in the process. Only the
  /// new child may be added.
  @protected
  RenderBox insertAndLayoutChild(BoxConstraints childConstraints, {
    @required RenderBox after,
    bool parentUsesSize: false,
  }) {
    assert(debugAssertNotCurrentlyAllowingChildAdditions());
    assert(after != null);
    final int index = indexOf(after) + 1;
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      allowAdditionsFor(index, () {
        _childManager.createChild(index, after: after);
      });
    });
    final RenderBox child = childAfter(after);
    if (child != null && indexOf(child) == index) {
      assert(indexOf(child) == index);
      child.layout(childConstraints, parentUsesSize: parentUsesSize);
      return child;
    }
    return null;
  }

  /// Called after layout with the number of children that can be garbage
  /// collected at the head and tail of the child list.
  @protected
  void collectGarbage(int leadingGarbage, int trailingGarbage) {
    assert(debugAssertNotCurrentlyAllowingChildAdditions());
    assert(childCount >= leadingGarbage + trailingGarbage);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      while (leadingGarbage > 0) {
        _childManager.removeChild(firstChild);
        leadingGarbage -= 1;
      }
      while (trailingGarbage > 0) {
        _childManager.removeChild(lastChild);
        trailingGarbage -= 1;
      }
    });
  }

  /// Returns the index of the given child, as given by the
  /// [SliverMultiBoxAdaptorParentData.index] field of the child's [parentData].
  int indexOf(RenderBox child) {
    assert(child != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    assert(childParentData.index != null);
    return childParentData.index;
  }

  /// Returns the scroll offset of the given child, as given by the
  /// [SliverMultiBoxAdaptorParentData.scrollOffset] field of the child's [parentData].
  double offsetOf(RenderBox child) {
    assert(child != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
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
  bool hitTestChildren(HitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    RenderBox child = lastChild;
    while (child != null) {
      if (hitTestBoxChild(result, child, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition))
        return true;
      child = childBefore(child);
    }
    return false;
  }

  @override
  double childPosition(RenderBox child) {
    return offsetOf(child) - constraints.scrollOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    applyPaintTransformForBoxChild(child, transform);
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
      Offset childOffset = originOffset + unitOffset * childPosition(child);
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

  bool debugAssertChildListIsNonEmptyAndContiguous() {
    assert(() {
      assert(firstChild != null);
      int index = indexOf(firstChild);
      RenderBox child = childAfter(firstChild);
      while (child != null) {
        index += 1;
        assert(indexOf(child) == index);
        child = childAfter(child);
      }
      return true;
    });
    return true;
  }
}
