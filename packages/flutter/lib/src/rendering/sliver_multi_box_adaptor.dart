// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'layer.dart';
import 'object.dart';
import 'sliver.dart';
import 'sliver_fixed_extent_list.dart';

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
  /// specified in the `constraints` of the [RenderSliverMultiBoxAdaptor]. For
  /// example if the children are the alphabet, then if
  /// [SliverConstraints.growthDirection] is [GrowthDirection.forward] then
  /// index zero is A, and index 25 is Z. On the other hand if
  /// [SliverConstraints.growthDirection] is [GrowthDirection.reverse] then
  /// index zero is Z, and index 25 is A.
  ///
  /// During a call to [createChild] it is valid to remove other children from
  /// the [RenderSliverMultiBoxAdaptor] object if they were not created during
  /// this frame and have not yet been updated during this frame. It is not
  /// valid to add any other children to this render object.
  void createChild(int index, { required RenderBox? after });

  /// Remove the given child from the child list.
  ///
  /// Called by [RenderSliverMultiBoxAdaptor.collectGarbage], which itself is
  /// called from [RenderSliverMultiBoxAdaptor]'s `performLayout`.
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
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
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

  /// The best available estimate of [childCount], or null if no estimate is available.
  ///
  /// This differs from [childCount] in that [childCount] never returns null (and must
  /// not be accessed if the child count is not yet available, meaning the [createChild]
  /// method has not been provided an index that does not create a child).
  ///
  /// See also:
  ///
  ///  * [SliverChildDelegate.estimatedChildCount], to which this getter defers.
  int? get estimatedChildCount => null;

  /// Called during [RenderSliverMultiBoxAdaptor.adoptChild] or
  /// [RenderSliverMultiBoxAdaptor.move].
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
  /// to the [RenderSliverMultiBoxAdaptor]'s child list and can return
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
  int? index;

  @override
  bool get keptAlive => _keptAlive;
  bool _keptAlive = false;

  @override
  String toString() => 'index=$index; ${keepAlive ? "keepAlive; " : ""}${super.toString()}';
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
///   corresponding to that index was first removed).
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
  RenderSliverMultiBoxAdaptor({
    required RenderSliverBoxChildManager childManager,
  }) : _childManager = childManager {
    assert(() {
      _debugDanglingKeepAlives = <RenderBox>[];
      return true;
    }());
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMultiBoxAdaptorParentData) {
      child.parentData = SliverMultiBoxAdaptorParentData();
    }
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

  late List<RenderBox> _debugDanglingKeepAlives;

  /// Indicates whether integrity check is enabled.
  ///
  /// Setting this property to true will immediately perform an integrity check.
  ///
  /// The integrity check consists of:
  ///
  /// 1. Verify that the children index in childList is in ascending order.
  /// 2. Verify that there is no dangling keepalive child as the result of [move].
  bool get debugChildIntegrityEnabled => _debugChildIntegrityEnabled;
  bool _debugChildIntegrityEnabled = true;
  set debugChildIntegrityEnabled(bool enabled) {
    assert(() {
      _debugChildIntegrityEnabled = enabled;
      return _debugVerifyChildOrder() &&
        (!_debugChildIntegrityEnabled || _debugDanglingKeepAlives.isEmpty);
    }());
  }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    if (!childParentData._keptAlive) {
      childManager.didAdoptChild(child as RenderBox);
    }
  }

  bool _debugAssertChildListLocked() => childManager.debugAssertChildListLocked();

  /// Verify that the child list index is in strictly increasing order.
  ///
  /// This has no effect in release builds.
  bool _debugVerifyChildOrder() {
    if (_debugChildIntegrityEnabled) {
      RenderBox? child = firstChild;
      int index;
      while (child != null) {
        index = indexOf(child);
        child = childAfter(child);
        assert(child == null || indexOf(child) > index);
      }
    }
    return true;
  }

  @override
  void insert(RenderBox child, { RenderBox? after }) {
    assert(!_keepAliveBucket.containsValue(child));
    super.insert(child, after: after);
    assert(firstChild != null);
    assert(_debugVerifyChildOrder());
  }

  @override
  void move(RenderBox child, { RenderBox? after }) {
    // There are two scenarios:
    //
    // 1. The child is not keptAlive.
    // The child is in the childList maintained by ContainerRenderObjectMixin.
    // We can call super.move and update parentData with the new slot.
    //
    // 2. The child is keptAlive.
    // In this case, the child is no longer in the childList but might be stored in
    // [_keepAliveBucket]. We need to update the location of the child in the bucket.
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    if (!childParentData.keptAlive) {
      super.move(child, after: after);
      childManager.didAdoptChild(child); // updates the slot in the parentData
      // Its slot may change even if super.move does not change the position.
      // In this case, we still want to mark as needs layout.
      markNeedsLayout();
    } else {
      // If the child in the bucket is not current child, that means someone has
      // already moved and replaced current child, and we cannot remove this child.
      if (_keepAliveBucket[childParentData.index] == child) {
        _keepAliveBucket.remove(childParentData.index);
      }
      assert(() {
        _debugDanglingKeepAlives.remove(child);
        return true;
      }());
      // Update the slot and reinsert back to _keepAliveBucket in the new slot.
      childManager.didAdoptChild(child);
      // If there is an existing child in the new slot, that mean that child will
      // be moved to other index. In other cases, the existing child should have been
      // removed by updateChild. Thus, it is ok to overwrite it.
      assert(() {
        if (_keepAliveBucket.containsKey(childParentData.index)) {
          _debugDanglingKeepAlives.add(_keepAliveBucket[childParentData.index]!);
        }
        return true;
      }());
      _keepAliveBucket[childParentData.index!] = child;
    }
  }

  @override
  void remove(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    if (!childParentData._keptAlive) {
      super.remove(child);
      return;
    }
    assert(_keepAliveBucket[childParentData.index] == child);
    assert(() {
      _debugDanglingKeepAlives.remove(child);
      return true;
    }());
    _keepAliveBucket.remove(childParentData.index);
    dropChild(child);
  }

  @override
  void removeAll() {
    super.removeAll();
    _keepAliveBucket.values.forEach(dropChild);
    _keepAliveBucket.clear();
  }

  void _createOrObtainChild(int index, { required RenderBox? after }) {
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      if (_keepAliveBucket.containsKey(index)) {
        final RenderBox child = _keepAliveBucket.remove(index)!;
        final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
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
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    if (childParentData.keepAlive) {
      assert(!childParentData._keptAlive);
      remove(child);
      _keepAliveBucket[childParentData.index!] = child;
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
    for (final RenderBox child in _keepAliveBucket.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final RenderBox child in _keepAliveBucket.values) {
      child.detach();
    }
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

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    // Do not visit children in [_keepAliveBucket].
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
      assert(indexOf(firstChild!) == index);
      final SliverMultiBoxAdaptorParentData firstChildParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
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
  RenderBox? insertAndLayoutLeadingChild(
    BoxConstraints childConstraints, {
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    final int index = indexOf(firstChild!) - 1;
    _createOrObtainChild(index, after: null);
    if (indexOf(firstChild!) == index) {
      firstChild!.layout(childConstraints, parentUsesSize: parentUsesSize);
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
  RenderBox? insertAndLayoutChild(
    BoxConstraints childConstraints, {
    required RenderBox? after,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    assert(after != null);
    final int index = indexOf(after!) + 1;
    _createOrObtainChild(index, after: after);
    final RenderBox? child = childAfter(after);
    if (child != null && indexOf(child) == index) {
      child.layout(childConstraints, parentUsesSize: parentUsesSize);
      return child;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  /// Returns the number of children preceding the `firstIndex` that need to be
  /// garbage collected.
  ///
  /// See also:
  ///
  ///   * [collectGarbage], which takes the leading and trailing number of
  ///     children to be garbage collected.
  ///   * [calculateTrailingGarbage], which similarly returns the number of
  ///     trailing children to be garbage collected.
  @visibleForTesting
  @protected
  int calculateLeadingGarbage({required int firstIndex}) {
    RenderBox? walker = firstChild;
    int leadingGarbage = 0;
    while (walker != null && indexOf(walker) < firstIndex) {
      leadingGarbage += 1;
      walker = childAfter(walker);
    }
    return leadingGarbage;
  }

  /// Returns the number of children following the `lastIndex` that need to be
  /// garbage collected.
  ///
  /// See also:
  ///
  ///   * [collectGarbage], which takes the leading and trailing number of
  ///     children to be garbage collected.
  ///   * [calculateLeadingGarbage], which similarly returns the number of
  ///     leading children to be garbage collected.
  @visibleForTesting
  @protected
  int calculateTrailingGarbage({required int lastIndex}) {
    RenderBox? walker = lastChild;
    int trailingGarbage = 0;
    while (walker != null && indexOf(walker) > lastIndex) {
      trailingGarbage += 1;
      walker = childBefore(walker);
    }
    return trailingGarbage;
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
  ///
  /// See also:
  ///
  ///   * [calculateLeadingGarbage], which can be used to determine
  ///     `leadingGarbage` here.
  ///   * [calculateTrailingGarbage], which can be used to determine
  ///     `trailingGarbage` here.
  @protected
  void collectGarbage(int leadingGarbage, int trailingGarbage) {
    assert(_debugAssertChildListLocked());
    assert(childCount >= leadingGarbage + trailingGarbage);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      while (leadingGarbage > 0) {
        _destroyOrCacheChild(firstChild!);
        leadingGarbage -= 1;
      }
      while (trailingGarbage > 0) {
        _destroyOrCacheChild(lastChild!);
        trailingGarbage -= 1;
      }
      // Ask the child manager to remove the children that are no longer being
      // kept alive. (This should cause _keepAliveBucket to change, so we have
      // to prepare our list ahead of time.)
      _keepAliveBucket.values.where((RenderBox child) {
        final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
        return !childParentData.keepAlive;
      }).toList().forEach(_childManager.removeChild);
      assert(_keepAliveBucket.values.where((RenderBox child) {
        final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
        return !childParentData.keepAlive;
      }).isEmpty);
    });
  }

  /// Returns the index of the given child, as given by the
  /// [SliverMultiBoxAdaptorParentData.index] field of the child's [parentData].
  int indexOf(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    assert(childParentData.index != null);
    return childParentData.index!;
  }

  /// Returns the dimension of the given child in the main axis, as given by the
  /// child's [RenderBox.size] property. This is only valid after layout.
  @protected
  double paintExtentOf(RenderBox child) {
    assert(child.hasSize);
    return switch (constraints.axis) {
      Axis.horizontal => child.size.width,
      Axis.vertical   => child.size.height,
    };
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, { required double mainAxisPosition, required double crossAxisPosition }) {
    RenderBox? child = lastChild;
    final BoxHitTestResult boxResult = BoxHitTestResult.wrap(result);
    while (child != null) {
      if (hitTestBoxChild(boxResult, child, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition)) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return childScrollOffset(child)! - constraints.scrollOffset;
  }

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    return childParentData.layoutOffset;
  }

  @override
  bool paintsChild(RenderBox child) {
    final SliverMultiBoxAdaptorParentData? childParentData = child.parentData as SliverMultiBoxAdaptorParentData?;
    return childParentData?.index != null &&
           !_keepAliveBucket.containsKey(childParentData!.index);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (!paintsChild(child)) {
      // This can happen if some child asks for the global transform even though
      // they are not getting painted. In that case, the transform sets set to
      // zero since [applyPaintTransformForBoxChild] would end up throwing due
      // to the child not being configured correctly for applying a transform.
      // There's no assert here because asking for the paint transform is a
      // valid thing to do even if a child would not be painted, but there is no
      // meaningful non-zero matrix to use in this case.
      transform.setZero();
    } else {
      applyPaintTransformForBoxChild(child, transform);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) {
      return;
    }
    // offset is to the top-left corner, regardless of our axis direction.
    // originOffset gives us the delta from the real origin to the origin in the axis direction.
    final Offset mainAxisUnit, crossAxisUnit, originOffset;
    final bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        mainAxisUnit = const Offset(0.0, -1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset + Offset(0.0, geometry!.paintExtent);
        addExtent = true;
      case AxisDirection.right:
        mainAxisUnit = const Offset(1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset;
        addExtent = false;
      case AxisDirection.down:
        mainAxisUnit = const Offset(0.0, 1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset;
        addExtent = false;
      case AxisDirection.left:
        mainAxisUnit = const Offset(-1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset + Offset(geometry!.paintExtent, 0.0);
        addExtent = true;
    }
    RenderBox? child = firstChild;
    while (child != null) {
      final double mainAxisDelta = childMainAxisPosition(child);
      final double crossAxisDelta = childCrossAxisPosition(child);
      Offset childOffset = Offset(
        originOffset.dx + mainAxisUnit.dx * mainAxisDelta + crossAxisUnit.dx * crossAxisDelta,
        originOffset.dy + mainAxisUnit.dy * mainAxisDelta + crossAxisUnit.dy * crossAxisDelta,
      );
      if (addExtent) {
        childOffset += mainAxisUnit * paintExtentOf(child);
      }

      // If the child's visible interval (mainAxisDelta, mainAxisDelta + paintExtentOf(child))
      // does not intersect the paint extent interval (0, constraints.remainingPaintExtent), it's hidden.
      if (mainAxisDelta < constraints.remainingPaintExtent && mainAxisDelta + paintExtentOf(child) > 0) {
        context.paintChild(child, childOffset);
      }

      child = childAfter(child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message(firstChild != null ? 'currently live children: ${indexOf(firstChild!)} to ${indexOf(lastChild!)}' : 'no children current live'));
  }

  /// Asserts that the reified child list is not empty and has a contiguous
  /// sequence of indices.
  ///
  /// Always returns true.
  bool debugAssertChildListIsNonEmptyAndContiguous() {
    assert(() {
      assert(firstChild != null);
      int index = indexOf(firstChild!);
      RenderBox? child = childAfter(firstChild!);
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
      RenderBox? child = firstChild;
      while (true) {
        final SliverMultiBoxAdaptorParentData childParentData = child!.parentData! as SliverMultiBoxAdaptorParentData;
        children.add(child.toDiagnosticsNode(name: 'child with index ${childParentData.index}'));
        if (child == lastChild) {
          break;
        }
        child = childParentData.nextSibling;
      }
    }
    if (_keepAliveBucket.isNotEmpty) {
      final List<int> indices = _keepAliveBucket.keys.toList()..sort();
      for (final int index in indices) {
        children.add(_keepAliveBucket[index]!.toDiagnosticsNode(
          name: 'child with index $index (kept alive but not laid out)',
          style: DiagnosticsTreeStyle.offstage,
        ));
      }
    }
    return children;
  }
}

/// Represents the animation of the children of a parent [SliverTreeNode] that
/// are animating into or out of view.
///
/// The [fromIndex] and [toIndex] are inclusive of the children following the
/// parent, with the [value] representing the status of the current animation.
///
/// Provided to [RenderSliverTree] by [SliverTree] to properly offset animating
/// children.
typedef SliverTreeNodesAnimation = ({
  int fromIndex,
  int toIndex,
  double value,
});

/// Used to pass information down to RenderSliverTree.
///
/// The depth is used for breadth first traversal, where as depth first traversal
/// follows the indexed order. The animationValue is used to compute the offset
// /of children that are currently coming into or out of view.
class TreeNodeParentData extends SliverMultiBoxAdaptorParentData {
  /// The depth of the node, used by [RenderSliverTree] to traverse nodes in the
  /// designated [SliverTreeTraversalOrder].
  int depth = 0;
}

/// Traversal order pattern for [SliverTreeNode]s that are children of a
/// [SliverTree].
enum SliverTreeTraversalOrder {
  /// Pre-order depth traversal.
  ///
  /// This traversal pattern will visit each given [SliverTreeNode] before
  /// visiting each of its children.
  ///
  /// This is the default traversal pattern for [SliverTree.traversalOrder].
  depthFirst,

  /// Lever order traversal.
  ///
  /// This traversal pattern will visit each node that exists at the same
  /// [SliverTreeNode.depth], before progressing to the next depth of nodes in
  /// the tree.
  ///
  /// Can be used in [SliverTree.traversalOrder], which defaults to [depthFirst].
  breadthFirst,
}

/// The style of indentation for [SliverTreeNode]s in a [SliverTree], as handled
/// by [RenderSliverTree].
///
/// By default, the indentation is handled by [RenderSliverTree]. Child nodes
/// are offset by the indentation specified by [value] in the cross axis of the
/// viewport. This means the space allotted to the indentation will not be part
/// of the space made available to the Widget returned by
/// [SliverTree.treeRowBuilder].
///
/// Alternatively, the indentation can be implemented in
/// [SliverTree.treeRowBuilder], with the depth of the given tree row accessed
/// by [SliverTreeNode.depth]. This allows for more customization in building
/// tree rows, such as filling the indented area with decorations or ink effects.
class SliverTreeIndentationType {
  const SliverTreeIndentationType._internal(double value) : _value = value;

  /// The number of pixels by which [SliverTreeNode]s will be offset according
  /// to their [SliverTreeNode.depth].
  double get value => _value;
  final double _value;

  /// The default indentation of child [SliverTreeNode]s in a [SliverTree].
  ///
  /// Child nodes will be offset by 10 pixels for each level in the tree.
  static const SliverTreeIndentationType standard = SliverTreeIndentationType._internal(10.0);

  /// Configures no offsetting of child nodes in a [SliverTree].
  ///
  /// Useful if the indentation is implemented in the
  /// [SliverTree.treeRowBuilder] instead for more customization options.
  ///
  /// Child nodes will not be offset in the tree.
  static const SliverTreeIndentationType none = SliverTreeIndentationType._internal(0.0);

  /// Configures a custom offset for indenting child nodes in a [SliverTree].
  ///
  /// Child nodes will be offset by the provided number of pixels in the tree.
  /// The [value] must be a non negative number.
  static SliverTreeIndentationType custom(double value) {
    assert(value >= 0.0);
    return SliverTreeIndentationType._internal(value);
  }
}

// This will likely need to move to the same file as RenderSliverMultiBoxAdaptor
// to access private API around keep alives and visiting children in depth and breadth first traversal order

/// A sliver that places multiple [SliverTreeNode]s in a linear array along the
/// main access, while staggering nodes that are animating into and out of view.
///
/// The extent of each child node is determined by the [itemExtentBuilder].
///
/// See also:
///
///   * [SliverTree], the widget that creates and manages this render object.
class RenderSliverTree extends RenderSliverVariedExtentList {
  /// Creates the render object that lays out the [SliverTreeNode]s of a
  /// [SliverTree].
  RenderSliverTree({
    required super.childManager,
    required super.itemExtentBuilder,
    required Map<UniqueKey, SliverTreeNodesAnimation> activeAnimations,
    required SliverTreeTraversalOrder traversalOrder,
    required double indentation,
  }) : _activeAnimations = activeAnimations,
       _traversalOrder = traversalOrder,
       _indentation = indentation;

  // TODO(Piinks): There are some opportunities to cache even further as far as
  // extents and layout offsets when using itemExtentBuilder from the super
  // class as we do here. I want to yak shave that in a separate change.

  /// The currently active [SliverTreeNode] animations.
  ///
  /// Since the index of animating nodes can change at any time, the unique key
  /// is used to track an animation of nodes across frames.
  Map<UniqueKey, SliverTreeNodesAnimation> get activeAnimations => _activeAnimations;
  Map<UniqueKey, SliverTreeNodesAnimation> _activeAnimations;
  set activeAnimations(Map<UniqueKey, SliverTreeNodesAnimation> value) {
    if (_activeAnimations == value) {
      return;
    }
    _activeAnimations = value;
    markNeedsLayout();
  }

  /// The order in which child nodes of the tree will be traversed.
  ///
  /// The default traversal order is [SliverTreeTraversalOrder.depthFirst].
  SliverTreeTraversalOrder get traversalOrder => _traversalOrder;
  SliverTreeTraversalOrder _traversalOrder;
  set traversalOrder(SliverTreeTraversalOrder value) {
    if (_traversalOrder == value) {
      return;
    }
    _traversalOrder = value;
    // We don't need to layout again. This is used when we visit children.
  }

  /// The number of pixels by which child nodes will be offset in the cross axis
  /// based on their [TreeNodeParentData.depth].
  ///
  /// If zero, can alternatively offset children in [SliverTree.treeRowBuilder]
  /// for more options to customize the indented space.
  double get indentation => _indentation;
  double _indentation;
  set indentation(double value) {
    if (_indentation == value) {
      return;
    }
    assert(indentation >= 0.0);
    _indentation = value;
    markNeedsLayout();
  }

  // Maps the index of parents to the animation key of their children.
  final Map<int, UniqueKey> _animationLeadingIndices = <int, UniqueKey>{};
  // Maps ths key of child node animations to the fixed distance they are
  // traversing during the animation. Determined at the start of the animation.
  final Map<UniqueKey, double> _animationOffsets = <UniqueKey, double>{};
  void _updateAnimationCache() {
    _animationLeadingIndices.clear();
    _activeAnimations.forEach((UniqueKey key, SliverTreeNodesAnimation animation) {
      _animationLeadingIndices[animation.fromIndex - 1] = key;
    });
    // Remove any stored offsets or clip layers that are no longer actively
    // animating.
    _animationOffsets.removeWhere((UniqueKey key, _) => !_activeAnimations.keys.contains(key));
    _clipHandles.removeWhere((UniqueKey key, LayerHandle<ClipRectLayer> handle) {
      if (!_activeAnimations.keys.contains(key)) {
        handle.layer = null;
        return true;
      }
      return false;
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TreeNodeParentData) {
      child.parentData = TreeNodeParentData();
    }
  }

  @override
  void dispose() {
    _clipHandles.removeWhere((UniqueKey key, LayerHandle<ClipRectLayer> handle) {
      handle.layer = null;
      return true;
    });
    super.dispose();
  }

  // TODO(Piinks): This should be made a public getter on the super class.
  // Multiple subclasses are making use of it now, yak shave that refactor
  // separately.
  late SliverLayoutDimensions _currentLayoutDimensions;

  @override
  void performLayout() {
    _updateAnimationCache();
    _currentLayoutDimensions = SliverLayoutDimensions(
        scrollOffset: constraints.scrollOffset,
        precedingScrollExtent: constraints.precedingScrollExtent,
        viewportMainAxisExtent: constraints.viewportMainAxisExtent,
        crossAxisExtent: constraints.crossAxisExtent
    );
    super.performLayout();
    _buildDepthMap();
  }

  final Map<int, List<RenderBox>> _depthMap = <int, List<RenderBox>>{};
  void _buildDepthMap() {
    _depthMap.clear();
    if (firstChild == null) {
      return;
    }
    RenderBox? child = firstChild;
    late int depth;
    while (child != null) {
      depth = (child.parentData! as TreeNodeParentData).depth;
      if (_depthMap[depth] == null) {
        _depthMap[depth] = <RenderBox>[child];
      } else {
        _depthMap[depth]!.add(child);
      }
      child = childAfter(child);
    }
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    // itemExtent is deprecated in the super class, we ignore it because we use
    // the builder anyways.
    return _getChildIndexForScrollOffset(scrollOffset);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    // itemExtent is deprecated in the super class, we ignore it because we use
    // the builder anyways.
    return _getChildIndexForScrollOffset(scrollOffset);
  }

  int _getChildIndexForScrollOffset(double scrollOffset) {
    if (scrollOffset == 0.0) {
      return 0;
    }
    double position = 0.0;
    int index = 0;
    double totalAnimationOffset = 0.0;
    double? itemExtent;
    final int? childCount = childManager.estimatedChildCount;
    while (position < scrollOffset) {
      if (childCount != null && index > childCount - 1) {
        break;
      }

      itemExtent = itemExtentBuilder(index, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      if (_animationLeadingIndices.keys.contains(index)) {
        final UniqueKey animationKey = _animationLeadingIndices[index]!;
        if (_animationOffsets[animationKey] == null) {
          // We have not computed the distance this block is traversing over the
          // lifetime of the animation.
          _computeAnimationOffsetFor(animationKey, position);
        }
        // We add the offset accounting for the animation value.
        totalAnimationOffset += _animationOffsets[animationKey]! * (1 - _activeAnimations[animationKey]!.value);
      }
      position += itemExtent - totalAnimationOffset;
      // Reset the animation offset so we do not count it multiple times.
      // totalAnimationOffset = 0.0;
      ++index;
    }
    return index - 1;
  }

  void _computeAnimationOffsetFor(UniqueKey key, double position) {
    assert(_activeAnimations[key] != null);
    final double targetPosition = constraints.scrollOffset + constraints.remainingCacheExtent;
    double currentPosition = position;
    final int startingIndex = _activeAnimations[key]!.fromIndex;
    final int lastIndex = _activeAnimations[key]!.toIndex;
    int currentIndex = startingIndex;
    double totalAnimatingOffset = 0.0;
    // We animate only a portion of children that would be visible/in the cache
    // extent, unless all children would fit on the screen.
    while (currentIndex <= lastIndex && currentPosition < targetPosition) {
      final double itemExtent = itemExtentBuilder(currentIndex, _currentLayoutDimensions)!;
      totalAnimatingOffset += itemExtent;
      currentPosition += itemExtent;
      currentIndex++;
    }
    // For the life of this animation, which affects all children following
    // startingIndex (regardless of if they are a child of the triggering
    // parent), they will be offset by totalAnimatingOffset * the
    // animation value. This is because even though more children can be
    // scrolled into view, the same distance must be maintained for a smooth
    // animation.
    _animationOffsets[key] = totalAnimatingOffset;
  }

  @override
  double indexToLayoutOffset(double itemExtent, int index) {
    // itemExtent is deprecated in the super class, we ignore it because we use
    // the builder anyways.
    double position = 0.0;
    int currentIndex = 0;
    double totalAnimationOffset = 0.0;
    double? itemExtent;
    final int? childCount = childManager.estimatedChildCount;
    while (currentIndex < index) {
      if (childCount != null && currentIndex > childCount - 1) {
        break;
      }

      itemExtent = itemExtentBuilder(currentIndex, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      if (_animationLeadingIndices.keys.contains(currentIndex)) {
        final UniqueKey animationKey = _animationLeadingIndices[currentIndex]!;
        assert(_animationOffsets[animationKey] != null);
        // We add the offset accounting for the animation value.
        totalAnimationOffset += _animationOffsets[animationKey]! * (1 - _activeAnimations[animationKey]!.value);
      }
      position += itemExtent;
      currentIndex++;
    }
    return position - totalAnimationOffset;
  }

  final Map<UniqueKey, LayerHandle<ClipRectLayer>> _clipHandles = <UniqueKey, LayerHandle<ClipRectLayer>>{};

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) {
      return;
    }

    RenderBox? nextChild = firstChild;
    void paintUpTo(int index, RenderBox? child) {
      while (child != null && indexOf(child) <= index) {
        final double mainAxisDelta = childMainAxisPosition(child);
        final TreeNodeParentData parentData = child.parentData! as TreeNodeParentData;
        final Offset childOffset = Offset(
          parentData.depth * indentation,
          parentData.layoutOffset!,
        );

        // If the child's visible interval (mainAxisDelta, mainAxisDelta + paintExtentOf(child))
        // does not intersect the paint extent interval (0, constraints.remainingPaintExtent), it's hidden.
        if (mainAxisDelta < constraints.remainingPaintExtent && mainAxisDelta + paintExtentOf(child) > 0) {
          context.paintChild(child, childOffset);
        }
        child = childAfter(child);
      }
      nextChild = child;
    }
    if (_animationLeadingIndices.isEmpty) {
      // There are no animations running.
      paintUpTo(indexOf(lastChild!), firstChild);
      return;
    }

    // We are animating.
    // Separate animating segments to clip for any overlap.
    int leadingIndex = indexOf(firstChild!);
    final List<int> animationIndices = _animationLeadingIndices.keys.toList()..sort();
    final List<({int leadingIndex, int trailingIndex})> paintSegments = <({int leadingIndex, int trailingIndex})>[];
    while (animationIndices.isNotEmpty) {
      final int trailingIndex = animationIndices.removeAt(0);
      paintSegments.add((leadingIndex: leadingIndex, trailingIndex: trailingIndex));
      leadingIndex = trailingIndex + 1;
    }
    paintSegments.add((leadingIndex: leadingIndex, trailingIndex: indexOf(lastChild!)));

    // Paint, clipping for all but the first segment.
    paintUpTo(paintSegments.removeAt(0).trailingIndex, nextChild);
    // Paint the rest with clip layers.
    while (paintSegments.isNotEmpty) {
      final ({int leadingIndex, int trailingIndex}) segment = paintSegments.removeAt(0);
      // final ({int leadingIndex, int trailingIndex}) segment = paintSegments.removeLast();

      // Rect is calculated by the trailing edge of the parent (preceding
      // leadingIndex), and the trailing edge of the trailing index. We cannot
      // rely on the leading edge of the leading index, because it is currently moving.
      final int parentIndex = math.max(segment.leadingIndex - 1, 0);
      final double leadingOffset = indexToLayoutOffset( 0.0, parentIndex)
        + (parentIndex == 0 ? 0.0 : itemExtentBuilder(parentIndex, _currentLayoutDimensions)!);
      final double trailingOffset = indexToLayoutOffset(0.0, segment.trailingIndex)
        + itemExtentBuilder(segment.trailingIndex, _currentLayoutDimensions)!;
      final Rect rect = Rect.fromPoints(
        Offset(0.0, leadingOffset),
        Offset(constraints.crossAxisExtent, trailingOffset),
      );
      // We use the same animation key to keep track of the clip layer, unless
      // this is the odd man out segment.
      final UniqueKey key = _animationLeadingIndices[parentIndex]!;
      _clipHandles[key] ??=  LayerHandle<ClipRectLayer>();
      _clipHandles[key]!.layer = context.pushClipRect(
        needsCompositing,
        offset,
        rect,
        (PaintingContext context, Offset offset) {
          paintUpTo(segment.trailingIndex, nextChild);
        },
        oldLayer: _clipHandles[key]!.layer,
      );
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    switch (traversalOrder) {
      case SliverTreeTraversalOrder.depthFirst:
        super.visitChildren(visitor);
      case SliverTreeTraversalOrder.breadthFirst:
        for (final int depth in _depthMap.keys.toList()..sort()) {
          _depthMap[depth]!.forEach(visitor);
        }
        _keepAliveBucket.values.forEach(visitor);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    switch (traversalOrder) {
      case SliverTreeTraversalOrder.depthFirst:
        super.visitChildren(visitor);
      case SliverTreeTraversalOrder.breadthFirst:
        for (final int depth in _depthMap.keys.toList()..sort()) {
          _depthMap[depth]!.forEach(visitor);
        }
        // Do not visit children in [_keepAliveBucket].
    }
  }
}
