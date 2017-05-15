// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap, HashMap;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/rendering.dart' show
  SliverGridDelegate,
  SliverGridDelegateWithFixedCrossAxisCount,
  SliverGridDelegateWithMaxCrossAxisExtent;

/// A delegate that supplies children for slivers.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. Rather than receiving
/// their children as an explicit [List], they receive their children using a
/// [SliverChildDelegate].
///
/// It's uncommon to subclass [SliverChildDelegate]. Instead, consider using one
/// of the existing subclasses that provide adaptors to builder callbacks or
/// explict child lists.
///
/// See also:
///
///  * [SliverChildBuilderDelegate], which is a delegate that uses a builder
///    callback to construct the children.
///  * [SliverChildListDelegate], which is a delegate that has an explicit list
///    of children.
abstract class SliverChildDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverChildDelegate();

  /// Returns the child with the given index.
  ///
  /// Should return null if asked to build a widget with a greater index than
  /// exists.
  ///
  /// Subclasses typically override this function and wrap their children in
  /// [RepaintBoundary] widgets.
  Widget build(BuildContext context, int index);

  /// Returns an estimate of the number of children this delegate will build.
  ///
  /// Used to estimate the maximum scroll offset if [estimateMaxScrollOffset]
  /// returns null.
  ///
  /// Return null if there are an unbounded number of children or if it would
  /// be too difficult to estimate the number of children.
  int get estimatedChildCount => null;

  /// Returns an estimate of the max scroll extent for all the children.
  ///
  /// Subclasses should override this function if they have additional
  /// information about their max scroll extent.
  ///
  /// The default implementation returns null, which causes the caller to
  /// extrapolate the max scroll offset from the given parameters.
  double estimateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) => null;

  /// Called at the end of layout to indicate that layout is now complete.
  ///
  /// The `firstIndex` argument is the index of the first child that was
  /// included in the current layout. The `lastIndex` argument is the index of
  /// the last child that was included in the current layout.
  ///
  /// Useful for subclasses that which to track which children are included in
  /// the underlying render tree.
  void didFinishLayout(int firstIndex, int lastIndex) {}

  /// Called whenever a new instance of the child delegate class is
  /// provided to the sliver.
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [build] call might be optimized
  /// away.
  bool shouldRebuild(covariant SliverChildDelegate oldDelegate);

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '$runtimeType#$hashCode(${description.join(", ")})';
  }

  /// Add additional information to the given description for use by [toString].
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    try {
      final int children = estimatedChildCount;
      if (children != null)
        description.add('estimated child count: $children');
    } catch (e) {
      description.add('estimated child count: EXCEPTION (${e.runtimeType})');
    }
  }
}

/// A delegate that supplies children for slivers using a builder callback.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an [IndexedWidgetBuilder] callback. The widgets returned from
/// the builder callback are wrapped in [RepaintBoundary] widgets.
///
/// See also:
///
///  * [SliverChildListDelegate], which is a delegate that has an explicit list
///    of children.
class SliverChildBuilderDelegate extends SliverChildDelegate {
  /// Creates a delegate that supplies children for slivers using the given
  /// builder callback
  const SliverChildBuilderDelegate(this.builder, { this.childCount });

  /// Called to build children for the sliver.
  ///
  /// Will be called only for indices greater than or equal to zero and less
  /// than [childCount] (if [childCount] is non-null).
  ///
  /// Should return null if asked to build a widget with a greater index than
  /// exists.
  ///
  /// The delegate wraps the children returned by this builder in
  /// [RepaintBoundary] widgets.
  final IndexedWidgetBuilder builder;

  /// The total number of children this delegate can provide.
  ///
  /// If null, the number of children is determined by the least index for which
  /// [builder] returns null.
  final int childCount;

  @override
  Widget build(BuildContext context, int index) {
    assert(builder != null);
    if (index < 0 || (childCount != null && index >= childCount))
      return null;
    final Widget child = builder(context, index);
    if (child == null)
      return null;
    return new RepaintBoundary.wrap(child, index);
  }

  @override
  int get estimatedChildCount => childCount;

  @override
  bool shouldRebuild(covariant SliverChildBuilderDelegate oldDelegate) => true;
}

/// A delegate that supplies children for slivers using an explicit list.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an explicit list, which is convenient but reduces the benefit
/// of building children lazily.
///
/// In general building all the widgets in advance is not efficient. It is
/// better to create a delegate that builds them on demand using
/// [SliverChildBuilderDelegate] or by subclassing [SliverChildDelegate]
/// directly.
///
/// This class is provided for the cases where either the list of children is
/// known well in advance (ideally the children are themselves compile-time
/// constants, for example), and therefore will not be built each time the
/// delegate itself is created, or the list is small, such that it's likely
/// always visible (and thus there is nothing to be gained by building it on
/// demand). For example, the body of a dialog box might fit both of these
/// conditions.
///
/// See also:
///
///  * [SliverChildBuilderDelegate], which is a delegate that uses a builder
///    callback to construct the children.
class SliverChildListDelegate extends SliverChildDelegate {
  /// Creates a delegate that supplies children for slivers using the given
  /// list.
  const SliverChildListDelegate(this.children, { this.addRepaintBoundaries: true });

  /// Whether to wrap each child in a [RepaintBoundary].
  ///
  /// Typically, children in a scrolling container are wrapped in repaint
  /// boundaries so that they do not need to be repainted as the list scrolls.
  /// If the children are easy to repaint (e.g., solid color blocks or a short
  /// snippet of text), it might be more efficient to not add a repaint boundary
  /// and simply repaint the children during scrolling.
  ///
  /// Defaults to true.
  final bool addRepaintBoundaries;

  /// The widgets to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context, int index) {
    assert(children != null);
    if (index < 0 || index >= children.length)
      return null;
    final Widget child = children[index];
    assert(child != null);
    return addRepaintBoundaries ? new RepaintBoundary.wrap(child, index) : child;
  }

  @override
  int get estimatedChildCount => children.length;

  @override
  bool shouldRebuild(covariant SliverChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

/// A base class for sliver that have multiple box children.
///
/// Helps subclasses build their children lazily using a [SliverChildDelegate].
abstract class SliverMultiBoxAdaptorWidget extends RenderObjectWidget {
  /// Initializes fields for subclasses.
  const SliverMultiBoxAdaptorWidget({
    Key key,
    @required this.delegate,
  }) : assert(delegate != null),
       super(key: key);

  /// The delegate that provides the children for this widget.
  ///
  /// The children are constructed lazily using this widget to avoid creating
  /// more children than are visible through the [Viewport].
  ///
  /// See also:
  ///
  ///  * [SliverChildBuilderDelegate] and [SliverChildListDelegate], which are
  ///    commonly used subclasses of [SliverChildDelegate] that use a builder
  ///    callback and an explicit child list, respectively.
  final SliverChildDelegate delegate;

  @override
  SliverMultiBoxAdaptorElement createElement() => new SliverMultiBoxAdaptorElement(this);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context);

  /// Returns an estimate of the max scroll extent for all the children.
  ///
  /// Subclasses should override this function if they have additional
  /// information about their max scroll extent.
  ///
  /// The default implementation returns calls
  /// [SliverChildDelegate.estimateMaxScrollOffset].
  double estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    assert(lastIndex >= firstIndex);
    return delegate.estimateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delegate: $delegate');
  }
}

/// A sliver that places multiple box children in a linear array along the main
/// axis.
///
/// Each child is forced to have the [SliverConstraints.crossAxisExtent] in the
/// cross axis but determines its own main axis extent.
///
/// [SliverList] determines its scroll offset by "dead reckoning" because
/// children outside the visible part of the sliver are not materialized, which
/// means [SliverList] cannot learn their main axis extent. Instead, newly
/// materialized children are placed adjacent to existing children.
///
/// If the children have a fixed extent in the main axis, consider using
/// [SliverFixedExtentList] rather than [SliverList] because
/// [SliverFixedExtentList] does not need to perform layout on its children to
/// obtain their extent in the main axis and is therefore more efficient.
///
/// See also:
///
///  * [SliverFixedExtentList], which is more efficient for children with
///    the same extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item intead a pixel value to define
///    the main axis extent of each item.
///  * [SliverGrid], which places its children in arbitrary positions.
class SliverList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places box children in a linear array.
  const SliverList({
    Key key,
    @required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverList(childManager: element);
  }
}

/// A sliver that places multiple box children with the same main axis extent in
/// a linear array.
///
/// [SliverFixedExtentList] places its children in a linear array along the main
/// axis starting at offset zero and without gaps. Each child is forced to have
/// the [itemExtent] in the main axis and the
/// [SliverConstraints.crossAxisExtent] in the cross axis.
///
/// [SliverFixedExtentList] is more efficient than [SliverList] because
/// [SliverFixedExtentList] does not need to perform layout on its children to
/// obtain their extent in the main axis.
///
/// See also:
///
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item intead a pixel value to define
///    the main axis extent of each item.
///  * [SliverFillViewport], which determines the [itemExtent] based on
///    [SliverConstraints.viewportMainAxisExtent].
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
class SliverFixedExtentList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places box children with the same main axis extent
  /// in a linear array.
  const SliverFixedExtentList({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.itemExtent,
  }) : super(key: key, delegate: delegate);

  /// The extent the children are forced to have in the main axis.
  final double itemExtent;

  @override
  RenderSliverFixedExtentList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverFixedExtentList(childManager: element, itemExtent: itemExtent);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverFixedExtentList renderObject) {
    renderObject.itemExtent = itemExtent;
  }
}

/// A sliver that places multiple box children in a two dimensional arrangement.
///
/// [SliverGrid] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the size specified by the
/// [gridDelegate].
///
/// See also:
///
///  * [SliverList], which places its children in a linear array.
///  * [SliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item intead a pixel value to define
///    the main axis extent of each item.
class SliverGrid extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement.
  const SliverGrid({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.gridDelegate,
  }) : super(key: key, delegate: delegate);

  /// The delegate that controls the size and position of the children.
  final SliverGridDelegate gridDelegate;

  @override
  RenderSliverGrid createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverGrid(childManager: element, gridDelegate: gridDelegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverGrid renderObject) {
    renderObject.gridDelegate = gridDelegate;
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    return super.estimateMaxScrollOffset(
      constraints,
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    ) ?? gridDelegate.getLayout(constraints).estimateMaxScrollOffset(delegate.estimatedChildCount);
  }
}

/// A sliver that contains a multiple box children that each fill the viewport.
///
/// [SliverFillViewport] places its children in a linear array along the main
/// axis. Each child is sized to fill the viewport, both in the main and cross
/// axis.
///
/// See also:
///
///  * [SliverFixedExtentList], which has a configurable
///    [SliverFixedExtentList.itemExtent].
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item intead a pixel value to define
///    the main axis extent of each item.
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
class SliverFillViewport extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver whose box children that each fill the viewport.
  const SliverFillViewport({
    Key key,
    @required SliverChildDelegate delegate,
    this.viewportFraction: 1.0,
  }) : assert(viewportFraction != null),
       assert(viewportFraction > 0.0),
       super(key: key, delegate: delegate);

  /// The fraction of the viewport that each child should fill in the main axis.
  ///
  /// If this fraction is less than 1.0, more than one child will be visible at
  /// once. If this fraction is greater than 1.0, each child will be larger than
  /// the viewport in the main axis.
  final double viewportFraction;

  @override
  RenderSliverFillViewport createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverFillViewport(childManager: element, viewportFraction: viewportFraction);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverFillViewport renderObject) {
    renderObject.viewportFraction = viewportFraction;
  }
}

/// An element that lazily builds children for a [SliverMultiBoxAdaptorWidget].
///
/// Implements [RenderSliverBoxChildManager], which lets this element manage
/// the children of subclasses of [RenderSliverMultiBoxAdaptor].
class SliverMultiBoxAdaptorElement extends RenderObjectElement implements RenderSliverBoxChildManager {
  /// Creates an element that lazily builds children for the given widget.
  SliverMultiBoxAdaptorElement(SliverMultiBoxAdaptorWidget widget) : super(widget);

  @override
  SliverMultiBoxAdaptorWidget get widget => super.widget;

  @override
  RenderSliverMultiBoxAdaptor get renderObject => super.renderObject;

  @override
  void update(covariant SliverMultiBoxAdaptorWidget newWidget) {
    final SliverMultiBoxAdaptorWidget oldWidget = widget;
    super.update(newWidget);
    final SliverChildDelegate newDelegate = newWidget.delegate;
    final SliverChildDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate)))
      performRebuild();
  }

  final SplayTreeMap<int, Element> _childElements = new SplayTreeMap<int, Element>();
  final Map<int, Widget> _childWidgets = new HashMap<int, Widget>();
  RenderBox _currentBeforeChild;

  @override
  void performRebuild() {
    _childWidgets.clear();
    super.performRebuild();
    _currentBeforeChild = null;
    assert(_currentlyUpdatingChildIndex == null);
    try {
      int firstIndex = _childElements.firstKey();
      int lastIndex = _childElements.lastKey();
      if (_childElements.isEmpty) {
        firstIndex = 0;
        lastIndex = 0;
      } else if (_didUnderflow) {
        lastIndex += 1;
      }
      // We won't call the delegate's build function multiple times, because we
      // cache the delegate's results until the next time we need to rebuild the
      // whole widget.
      for (int index = firstIndex; index <= lastIndex; ++index) {
        _currentlyUpdatingChildIndex = index;
        final Element newChild = updateChild(_childElements[index], _build(index), index);
        if (newChild != null) {
          _childElements[index] = newChild;
          _currentBeforeChild = newChild.renderObject;
        } else {
          _childElements.remove(index);
        }
      }
    } finally {
      _currentlyUpdatingChildIndex = null;
    }
  }

  Widget _build(int index) {
    return _childWidgets.putIfAbsent(index, () => widget.delegate.build(this, index));
  }

  @override
  void createChild(int index, { @required RenderBox after }) {
    assert(_currentlyUpdatingChildIndex == null);
    owner.buildScope(this, () {
      final bool insertFirst = after == null;
      assert(insertFirst || _childElements[index-1] != null);
      _currentBeforeChild = insertFirst ? null : _childElements[index-1].renderObject;
      Element newChild;
      try {
        _currentlyUpdatingChildIndex = index;
        newChild = updateChild(_childElements[index], _build(index), index);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  void forgetChild(Element child) {
    assert(child != null);
    assert(child.slot != null);
    assert(_childElements.containsKey(child.slot));
    _childElements.remove(child.slot);
  }

  @override
  void removeChild(RenderBox child) {
    final int index = renderObject.indexOf(child);
    assert(_currentlyUpdatingChildIndex == null);
    assert(index >= 0);
    owner.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingChildIndex = index;
        final Element result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  double _extrapolateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    final int childCount = widget.delegate.estimatedChildCount;
    if (childCount == null)
      return double.INFINITY;
    if (lastIndex == childCount - 1)
      return trailingScrollOffset;
    final int reifiedCount = lastIndex - firstIndex + 1;
    final double averageExtent = (trailingScrollOffset - leadingScrollOffset) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  @override
  double estimateMaxScrollOffset(SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    return widget.estimateMaxScrollOffset(
      constraints,
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    ) ?? _extrapolateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  @override
  void didStartLayout() {
    assert(debugAssertChildListLocked());
  }

  @override
  void didFinishLayout() {
    assert(debugAssertChildListLocked());
    final int firstIndex = _childElements.firstKey() ?? 0;
    final int lastIndex = _childElements.lastKey() ?? 0;
    widget.delegate.didFinishLayout(firstIndex, lastIndex);
  }

  int _currentlyUpdatingChildIndex;

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  bool _didUnderflow = false;

  @override
  void setDidUnderflow(bool value) {
    _didUnderflow = value;
  }

  @override
  void insertChildRenderObject(covariant RenderObject child, int slot) {
    assert(slot != null);
    assert(_currentlyUpdatingChildIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: _currentBeforeChild);
    assert(() {
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      assert(slot == childParentData.index);
      return true;
    });
  }

  @override
  void moveChildRenderObject(covariant RenderObject child, int slot) {
    // TODO(ianh): At some point we should be better about noticing when a
    // particular LocalKey changes slot, and handle moving the nodes around.
    assert(false);
  }

  @override
  void removeChildRenderObject(covariant RenderObject child) {
    assert(_currentlyUpdatingChildIndex != null);
    renderObject.remove(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
   // The toList() is to make a copy so that the underlying list can be modified by
   // the visitor:
   assert(!_childElements.values.any((Element child) => child == null));
    _childElements.values.toList().forEach(visitor);
  }
}

/// A sliver that contains a single box child that fills the remaining space in
/// the viewport.
///
/// [SliverFillRemaining] sizes its child to fill the viewport in the cross axis
/// and to fill the remaining space in the viewport in the main axis.
///
/// Typically this will be the last sliver in a viewport, since (by definition)
/// there is never any room for anything beyond this sliver.
///
/// See also:
///
///  * [SliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
///  * [SliverList], which shows a list of variable-sized children in a
///    viewport.
class SliverFillRemaining extends SingleChildRenderObjectWidget {
  /// Creates a sliver that fills the remaining space in the viewport.
  const SliverFillRemaining({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverFillRemaining createRenderObject(BuildContext context) => new RenderSliverFillRemaining();
}
