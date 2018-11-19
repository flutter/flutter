// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'box.dart';
import 'object.dart';
import 'sliver.dart';

/// A delegate used by [RenderSliverMultiBoxAdaptor] to manage its children.
///
/// [RenderSliverMultiBoxAdaptor] objects reify their children lazily to avoid
/// spending resources on children that are not visible in the viewport. This
/// delegate lets these objects create and remove children as well as estimate
/// the total scroll offset extent occupied by the full child list.
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
  ///
  /// If this method does not create a child for a given `index` greater than or
  /// equal to zero, then [computeMaxScrollOffset] must be able to return a
  /// precise value.
  void createChild(int index, { @required RenderBox after });

  /// Remove the given child from the child list.
  ///
  /// Called by [RenderSliverMultiBoxAdaptor.collectGarbage], which itself is
  /// called from [RenderSliverMultiBoxAdaptor.performLayout].
  ///
  /// The index of the given child can be obtained using the
  /// [RenderSliverMultiBoxAdaptor.indexOf] method, which reads it from the
  /// [SliverMultiBoxAdaptorParentData.index] field of the child's
  /// [RenderObject.parentData].
  void removeChild(RenderBox child);

  /// Called to estimate the total scrollable extents of this object.
  ///
  /// Must return the total distance from the start of the child with the
  /// earliest possible index to the end of the child with the last possible
  /// index.
  double estimateMaxScrollOffset(SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  });

  /// Called to obtain a precise measure of the total number of children.
  ///
  /// Must return the number that is one greater than the greatest `index` for
  /// which `createChild` will actually create a child.
  ///
  /// This is used when [createChild] cannot add a child for a positive `index`,
  /// to determine the precise dimensions of the sliver. It must return an
  /// accurate and precise non-null value. It will not be called if
  /// [createChild] is always able to create a child (e.g. for an infinite
  /// list).
  int get childCount;

  /// Called during [RenderSliverMultiBoxAdaptor.adoptChild].
  ///
  /// Subclasses must ensure that the [SliverMultiBoxAdaptorParentData.index]
  /// field of the child's [RenderObject.parentData] accurately reflects the
  /// child's index in the child list after this function returns.
  void didAdoptChild(RenderBox child);

  /// Called during layout to indicate whether this object provided insufficient
  /// children for the [RenderSliverMultiBoxAdaptor] to fill the
  /// [SliverConstraints.remainingPaintExtent].
  ///
  /// Typically called unconditionally at the start of layout with false and
  /// then later called with true when the [RenderSliverMultiBoxAdaptor]
  /// fails to create a child required to fill the
  /// [SliverConstraints.remainingPaintExtent].
  ///
  /// Useful for subclasses to determine whether newly added children could
  /// affect the visible contents of the [RenderSliverMultiBoxAdaptor].
  void setDidUnderflow(bool value);

  /// Called at the beginning of layout to indicate that layout is about to
  /// occur.
  void didStartLayout() { }

  /// Called at the end of layout to indicate that layout is now complete.
  void didFinishLayout() { }

  /// In debug mode, asserts that this manager is not expecting any
  /// modifications to the [RenderSliverMultiBoxAdaptor]'s child list.
  ///
  /// This function always returns true.
  ///
  /// The manager is not required to track whether it is expecting modifications
  /// to the [RenderSliverMultiBoxAdaptor]'s child list and can simply return
  /// true without making any assertions.
  bool debugAssertChildListLocked() => true;
}
/// Parent data structure used by [RenderSliverWithKeepAliveMixin].
mixin KeepAliveParentDataMixin implements ParentData {
  /// Whether to keep the child alive even when it is no longer visible.
  bool keepAlive = false;

  /// Whether the widget is currently being kept alive, i.e. has [keepAlive] set
  /// to true and is offscreen.
  bool get keptAlive;
}

/// This class exists to dissociate [KeepAlive] from [RenderSliverMultiBoxAdaptor].
///
/// [RenderSliverWithKeepAliveMixin.setupParentData] must be implemented to use
/// a parentData class that uses the right mixin or whatever is appropriate.
mixin RenderSliverWithKeepAliveMixin implements RenderSliver {
  /// Alerts the developer that the child's parentData needs to be of type
  /// [KeepAliveParentDataMixin].
  @override
  void setupParentData(RenderObject child) {
    assert(child.parentData is KeepAliveParentDataMixin);
  }
}

/// Parent data structure used by [RenderSliverMultiBoxAdaptor].
class SliverMultiBoxAdaptorParentData extends SliverLogicalParentData with ContainerParentDataMixin<RenderBox>, KeepAliveParentDataMixin {
  /// The index of this child according to the [RenderSliverBoxChildManager].
  int index;

  @override
  bool get keptAlive => _keptAlive;
  bool _keptAlive = false;

  @override
  String toString() => 'index=$index; ${keepAlive == true ? "keepAlive; " : ""}${super.toString()}';
}

/// A sliver with multiple box children.
///
/// [RenderSliverMultiBoxAdaptor] is a base class for slivers that have multiple
/// box children. The children are managed by a [RenderSliverBoxChildManager],
/// which lets subclasses create children lazily during layout. Typically
/// subclasses will create only those children that are actually needed to fill
/// the [SliverConstraints.remainingPaintExtent].
///
/// The contract for adding and removing children from this render object is
/// more strict than for normal render objects:
///
/// * Children can be removed except during a layout pass if they have already
///   been laid out during that layout pass.
/// * Children cannot be added except during a call to [childManager], and
///   then only if there is no child corresponding to that index (or the child
///   child corresponding to that index was first removed).
///
/// See also:
///
///  * [RenderSliverToBoxAdapter], which has a single box child.
///  * [RenderSliverList], which places its children in a linear
///    array.
///  * [RenderSliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
///  * [RenderSliverGrid], which places its children in arbitrary positions.
abstract class RenderSliverMultiBoxAdaptor extends RenderSliver
  with ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
       RenderSliverHelpers, RenderSliverWithKeepAliveMixin {

  /// Creates a sliver with multiple box children.
  ///
  /// The [childManager] argument must not be null.
  RenderSliverMultiBoxAdaptor({
    @required RenderSliverBoxChildManager childManager
  }) : assert(childManager != null),
       _childManager = childManager;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMultiBoxAdaptorParentData)
      child.parentData = SliverMultiBoxAdaptorParentData();
  }

  /// The delegate that manages the children of this object.
  ///
  /// Rather than having a concrete list of children, a
  /// [RenderSliverMultiBoxAdaptor] uses a [RenderSliverBoxChildManager] to
  /// create children during layout in order to fill the
  /// [SliverConstraints.remainingPaintExtent].
  @protected
  RenderSliverBoxChildManager get childManager => _childManager;
  final RenderSliverBoxChildManager _childManager;

  /// The nodes being kept alive despite not being visible.
  final Map<int, RenderBox> _keepAliveBucket = <int, RenderBox>{};

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    if (!childParentData._keptAlive)
      childManager.didAdoptChild(child);
  }

  bool _debugAssertChildListLocked() => childManager.debugAssertChildListLocked();

  @override
  void insert(RenderBox child, { RenderBox after }) {
    assert(!_keepAliveBucket.containsValue(child));
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
    }());
  }

  @override
  void remove(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    if (!childParentData._keptAlive) {
      super.remove(child);
      return;
    }
    assert(_keepAliveBucket[childParentData.index] == child);
    _keepAliveBucket.remove(childParentData.index);
    dropChild(child);
  }

  @override
  void removeAll() {
    super.removeAll();
    _keepAliveBucket.values.forEach(dropChild);
    _keepAliveBucket.clear();
  }

  void _createOrObtainChild(int index, { RenderBox after }) {
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      if (_keepAliveBucket.containsKey(index)) {
        final RenderBox child = _keepAliveBucket.remove(index);
        final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
        assert(childParentData._keptAlive);
        dropChild(child);
        child.parentData = childParentData;
        insert(child, after: after);
        childParentData._keptAlive = false;
      } else {
        _childManager.createChild(index, after: after);
      }
    });
  }

  void _destroyOrCacheChild(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    if (childParentData.keepAlive) {
      assert(!childParentData._keptAlive);
      remove(child);
      _keepAliveBucket[childParentData.index] = child;
      child.parentData = childParentData;
      super.adoptChild(child);
      childParentData._keptAlive = true;
    } else {
      assert(child.parent == this);
      _childManager.removeChild(child);
      assert(child.parent == null);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _keepAliveBucket.values)
      child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _keepAliveBucket.values)
      child.detach();
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    _keepAliveBucket.values.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    _keepAliveBucket.values.forEach(visitor);
  }

  /// Called during layout to create and add the child with the given index and
  /// scroll offset.
  ///
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child if necessary. The child may instead be obtained from a cache;
  /// see [SliverMultiBoxAdaptorParentData.keepAlive].
  ///
  /// Returns false if there was no cached child and `createChild` did not add
  /// any child, otherwise returns true.
  ///
  /// Does not layout the new child.
  ///
  /// When this is called, there are no visible children, so no children can be
  /// removed during the call to `createChild`. No child should be added during
  /// that call either, except for the one that is created and returned by
  /// `createChild`.
  @protected
  bool addInitialChild({ int index = 0, double layoutOffset = 0.0 }) {
    assert(_debugAssertChildListLocked());
    assert(firstChild == null);
    _createOrObtainChild(index, after: null);
    if (firstChild != null) {
      assert(firstChild == lastChild);
      assert(indexOf(firstChild) == index);
      final SliverMultiBoxAdaptorParentData firstChildParentData = firstChild.parentData;
      firstChildParentData.layoutOffset = layoutOffset;
      return true;
    }
    childManager.setDidUnderflow(true);
    return false;
  }

  /// Called during layout to create, add, and layout the child before
  /// [firstChild].
  ///
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child if necessary. The child may instead be obtained from a cache;
  /// see [SliverMultiBoxAdaptorParentData.keepAlive].
  ///
  /// Returns the new child or null if no child was obtained.
  ///
  /// The child that was previously the first child, as well as any subsequent
  /// children, may be removed by this call if they have not yet been laid out
  /// during this layout pass. No child should be added during that call except
  /// for the one that is created and returned by `createChild`.
  @protected
  RenderBox insertAndLayoutLeadingChild(BoxConstraints childConstraints, {
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    final int index = indexOf(firstChild) - 1;
    _createOrObtainChild(index, after: null);
    if (indexOf(firstChild) == index) {
      firstChild.layout(childConstraints, parentUsesSize: parentUsesSize);
      return firstChild;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  /// Called during layout to create, add, and layout the child after
  /// the given child.
  ///
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child if necessary. The child may instead be obtained from a cache;
  /// see [SliverMultiBoxAdaptorParentData.keepAlive].
  ///
  /// Returns the new child. It is the responsibility of the caller to configure
  /// the child's scroll offset.
  ///
  /// Children after the `after` child may be removed in the process. Only the
  /// new child may be added.
  @protected
  RenderBox insertAndLayoutChild(BoxConstraints childConstraints, {
    @required RenderBox after,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    assert(after != null);
    final int index = indexOf(after) + 1;
    _createOrObtainChild(index, after: after);
    final RenderBox child = childAfter(after);
    if (child != null && indexOf(child) == index) {
      child.layout(childConstraints, parentUsesSize: parentUsesSize);
      return child;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  /// Called after layout with the number of children that can be garbage
  /// collected at the head and tail of the child list.
  ///
  /// Children whose [SliverMultiBoxAdaptorParentData.keepAlive] property is
  /// set to true will be removed to a cache instead of being dropped.
  ///
  /// This method also collects any children that were previously kept alive but
  /// are now no longer necessary. As such, it should be called every time
  /// [performLayout] is run, even if the arguments are both zero.
  @protected
  void collectGarbage(int leadingGarbage, int trailingGarbage) {
    assert(_debugAssertChildListLocked());
    assert(childCount >= leadingGarbage + trailingGarbage);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      while (leadingGarbage > 0) {
        _destroyOrCacheChild(firstChild);
        leadingGarbage -= 1;
      }
      while (trailingGarbage > 0) {
        _destroyOrCacheChild(lastChild);
        trailingGarbage -= 1;
      }
      // Ask the child manager to remove the children that are no longer being
      // kept alive. (This should cause _keepAliveBucket to change, so we have
      // to prepare our list ahead of time.)
      _keepAliveBucket.values.where((RenderBox child) {
        final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
        return !childParentData.keepAlive;
      }).toList().forEach(_childManager.removeChild);
      assert(_keepAliveBucket.values.where((RenderBox child) {
        final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
        return !childParentData.keepAlive;
      }).isEmpty);
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
  double childMainAxisPosition(RenderBox child) {
    return childScrollOffset(child) - constraints.scrollOffset;
  }

  @override
  double childScrollOffset(RenderObject child) {
    assert(child != null);
    assert(child.parent == this);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    assert(childParentData.layoutOffset != null);
    return childParentData.layoutOffset;
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
    Offset mainAxisUnit, crossAxisUnit, originOffset;
    bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        mainAxisUnit = const Offset(0.0, -1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset + Offset(0.0, geometry.paintExtent);
        addExtent = true;
        break;
      case AxisDirection.right:
        mainAxisUnit = const Offset(1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.down:
        mainAxisUnit = const Offset(0.0, 1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.left:
        mainAxisUnit = const Offset(-1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset + Offset(geometry.paintExtent, 0.0);
        addExtent = true;
        break;
    }
    assert(mainAxisUnit != null);
    assert(addExtent != null);
    RenderBox child = firstChild;
    while (child != null) {
      final double mainAxisDelta = childMainAxisPosition(child);
      final double crossAxisDelta = childCrossAxisPosition(child);
      Offset childOffset = Offset(
        originOffset.dx + mainAxisUnit.dx * mainAxisDelta + crossAxisUnit.dx * crossAxisDelta,
        originOffset.dy + mainAxisUnit.dy * mainAxisDelta + crossAxisUnit.dy * crossAxisDelta,
      );
      if (addExtent)
        childOffset += mainAxisUnit * paintExtentOf(child);

      // If the child's visible interval (mainAxisDelta, mainAxisDelta + paintExtentOf(child))
      // does not intersect the paint extent interval (0, constraints.remainingPaintExtent), it's hidden.
      if (mainAxisDelta < constraints.remainingPaintExtent && mainAxisDelta + paintExtentOf(child) > 0)
        context.paintChild(child, childOffset);

      child = childAfter(child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message(firstChild != null ? 'currently live children: ${indexOf(firstChild)} to ${indexOf(lastChild)}' : 'no children current live'));
  }

  /// Asserts that the reified child list is not empty and has a contiguous
  /// sequence of indices.
  ///
  /// Always returns true.
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
    }());
    return true;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild != null) {
      RenderBox child = firstChild;
      while (true) {
        final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
        children.add(child.toDiagnosticsNode(name: 'child with index ${childParentData.index}'));
        if (child == lastChild)
          break;
        child = childParentData.nextSibling;
      }
    }
    if (_keepAliveBucket.isNotEmpty) {
      final List<int> indices = _keepAliveBucket.keys.toList()..sort();
      for (int index in indices) {
        children.add(_keepAliveBucket[index].toDiagnosticsNode(
          name: 'child with index $index (kept alive offstage)',
          style: DiagnosticsTreeStyle.offstage,
        ));
      }
    }
    return children;
  }
}