// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap, HashMap;
import 'dart:math' as math show max;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'automatic_keep_alive.dart';
import 'basic.dart';
import 'framework.dart';
import 'sliver_layout_builder.dart';

export 'package:flutter/rendering.dart' show
  SliverGridDelegate,
  SliverGridDelegateWithFixedCrossAxisCount,
  SliverGridDelegateWithMaxCrossAxisExtent;

// Examples can assume:
// SliverGridDelegateWithMaxCrossAxisExtent _gridDelegate;

/// A callback which produces a semantic index given a widget and the local index.
///
/// Return a null value to prevent a widget from receiving an index.
///
/// A semantic index is used to tag child semantic nodes for accessibility
/// announcements in scroll view.
///
/// See also:
///
///  * [CustomScrollView], for an explanation of scroll semantics.
///  * [SliverChildBuilderDelegate], for an explanation of how this is used to
///    generate indexes.
typedef SemanticIndexCallback = int Function(Widget widget, int localIndex);

int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

/// A delegate that supplies children for slivers.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. Rather than receiving
/// their children as an explicit [List], they receive their children using a
/// [SliverChildDelegate].
///
/// It's uncommon to subclass [SliverChildDelegate]. Instead, consider using one
/// of the existing subclasses that provide adaptors to builder callbacks or
/// explicit child lists.
///
/// {@template flutter.widgets.sliverChildDelegate.lifecycle}
/// ## Child elements' lifecycle
///
/// ### Creation
///
/// While laying out the list, visible children's elements, states and render
/// objects will be created lazily based on existing widgets (such as in the
/// case of [SliverChildListDelegate]) or lazily provided ones (such as in the
/// case of [SliverChildBuilderDelegate]).
///
/// ### Destruction
///
/// When a child is scrolled out of view, the associated element subtree, states
/// and render objects are destroyed. A new child at the same position in the
/// sliver will be lazily recreated along with new elements, states and render
/// objects when it is scrolled back.
///
/// ### Destruction mitigation
///
/// In order to preserve state as child elements are scrolled in and out of
/// view, the following options are possible:
///
///  * Moving the ownership of non-trivial UI-state-driving business logic
///    out of the sliver child subtree. For instance, if a list contains posts
///    with their number of upvotes coming from a cached network response, store
///    the list of posts and upvote number in a data model outside the list. Let
///    the sliver child UI subtree be easily recreate-able from the
///    source-of-truth model object. Use [StatefulWidget]s in the child widget
///    subtree to store instantaneous UI state only.
///
///  * Letting [KeepAlive] be the root widget of the sliver child widget subtree
///    that needs to be preserved. The [KeepAlive] widget marks the child
///    subtree's top render object child for keep-alive. When the associated top
///    render object is scrolled out of view, the sliver keeps the child's
///    render object (and by extension, its associated elements and states) in a
///    cache list instead of destroying them. When scrolled back into view, the
///    render object is repainted as-is (if it wasn't marked dirty in the
///    interim).
///
///    This only works if the [SliverChildDelegate] subclasses don't wrap the
///    child widget subtree with other widgets such as [AutomaticKeepAlive] and
///    [RepaintBoundary] via `addAutomaticKeepAlives` and
///    `addRepaintBoundaries`.
///
///  * Using [AutomaticKeepAlive] widgets (inserted by default in
///    [SliverChildListDelegate] or [SliverChildListDelegate]). Instead of
///    unconditionally caching the child element subtree when scrolling
///    off-screen like [KeepAlive], [AutomaticKeepAlive] can let whether to
///    cache the subtree be determined by descendant logic in the subtree.
///
///    As an example, the [EditableText] widget signals its sliver child element
///    subtree to stay alive while its text field has input focus. If it doesn't
///    have focus and no other descendants signaled for keep-alive via a
///    [KeepAliveNotification], the sliver child element subtree will be
///    destroyed when scrolled away.
///
///    [AutomaticKeepAlive] descendants typically signal it to be kept alive by
///    using the [AutomaticKeepAliveClientMixin], then implementing the
///    [wantKeepAlive] getter and calling [updateKeepAlive].
/// {@endtemplate}
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
  /// exists. If this returns null, [estimatedChildCount] must subsequently
  /// return a precise non-null value.
  ///
  /// Subclasses typically override this function and wrap their children in
  /// [AutomaticKeepAlive], [IndexedSemantics], and [RepaintBoundary] widgets.
  ///
  /// The values returned by this method are cached. To indicate that the
  /// widgets have changed, a new delegate must be provided, and the new
  /// delegate's [shouldRebuild] method must return true.
  Widget build(BuildContext context, int index);

  /// Returns an estimate of the number of children this delegate will build.
  ///
  /// Used to estimate the maximum scroll offset if [estimateMaxScrollOffset]
  /// returns null.
  ///
  /// Return null if there are an unbounded number of children or if it would
  /// be too difficult to estimate the number of children.
  ///
  /// This must return a precise number once [build] has returned null.
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
  void didFinishLayout(int firstIndex, int lastIndex) { }

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

  /// Find index of child element with associated key.
  ///
  /// This will be called during [performRebuild] in [SliverMultiBoxAdaptorElement]
  /// to check if a child has moved to a different position. It should return the
  /// index of the child element with associated key, null if not found.
  int findIndexByKey(Key key) => null;

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '${describeIdentity(this)}(${description.join(", ")})';
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

class _SaltedValueKey extends ValueKey<Key>{
  const _SaltedValueKey(Key key): assert(key != null), super(key);
}

typedef ChildIndexGetter = int Function(Key key);

/// A delegate that supplies children for slivers using a builder callback.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an [IndexedWidgetBuilder] callback, so that the children do
/// not even have to be built until they are displayed.
///
/// The widgets returned from the builder callback are automatically wrapped in
/// [AutomaticKeepAlive] widgets if [addAutomaticKeepAlives] is true (the
/// default) and in [RepaintBoundary] widgets if [addRepaintBoundaries] is true
/// (also the default).
///
/// ## Accessibility
///
/// The [CustomScrollView] requires that its semantic children are annotated
/// using [IndexedSemantics]. This is done by default in the delegate with
/// the `addSemanticIndexes` parameter set to true.
///
/// If multiple delegates are used in a single scroll view, then the indexes
/// will not be correct by default. The `semanticIndexOffset` can be used to
/// offset the semantic indexes of each delegate so that the indexes are
/// monotonically increasing. For example, if a scroll view contains two
/// delegates where the first has 10 children contributing semantics, then the
/// second delegate should offset its children by 10.
///
/// {@tool sample}
///
/// This sample code shows how to use `semanticIndexOffset` to handle multiple
/// delegates in a single scroll view.
///
/// ```dart
/// CustomScrollView(
///   semanticChildCount: 4,
///   slivers: <Widget>[
///     SliverGrid(
///       gridDelegate: _gridDelegate,
///       delegate: SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///            return Text('...');
///          },
///          childCount: 2,
///        ),
///      ),
///     SliverGrid(
///       gridDelegate: _gridDelegate,
///       delegate: SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///            return Text('...');
///          },
///          childCount: 2,
///          semanticIndexOffset: 2,
///        ),
///      ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// In certain cases, only a subset of child widgets should be annotated
/// with a semantic index. For example, in [new ListView.separated()] the
/// separators do not have an index associated with them. This is done by
/// providing a `semanticIndexCallback` which returns null for separators
/// indexes and rounds the non-separator indexes down by half.
///
/// {@tool sample}
///
/// This sample code shows how to use `semanticIndexCallback` to handle
/// annotating a subset of child nodes with a semantic index. There is
/// a [Spacer] widget at odd indexes which should not have a semantic
/// index.
///
/// ```dart
/// CustomScrollView(
///   semanticChildCount: 5,
///   slivers: <Widget>[
///     SliverGrid(
///       gridDelegate: _gridDelegate,
///       delegate: SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///            if (index.isEven) {
///              return Text('...');
///            }
///            return Spacer();
///          },
///          semanticIndexCallback: (Widget widget, int localIndex) {
///            if (localIndex.isEven) {
///              return localIndex ~/ 2;
///            }
///            return null;
///          },
///          childCount: 10,
///        ),
///      ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SliverChildListDelegate], which is a delegate that has an explicit list
///    of children.
///  * [IndexedSemantics], for an example of manually annotating child nodes
///    with semantic indexes.
class SliverChildBuilderDelegate extends SliverChildDelegate {
  /// Creates a delegate that supplies children for slivers using the given
  /// builder callback.
  ///
  /// The [builder], [addAutomaticKeepAlives], [addRepaintBoundaries],
  /// [addSemanticIndexes], and [semanticIndexCallback] arguments must not be
  /// null.
  ///
  /// If the order in which [builder] returns children ever changes, consider
  /// providing a [findChildIndex]. This allows the delegate to find the new index
  /// for a child that was previously located at a different index to attach the
  /// existing state to the [Widget] at its new location.
  const SliverChildBuilderDelegate(
    this.builder, {
    this.findChildIndexCallback,
    this.childCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
    this.semanticIndexOffset = 0,
  }) : assert(builder != null),
       assert(addAutomaticKeepAlives != null),
       assert(addRepaintBoundaries != null),
       assert(addSemanticIndexes != null),
       assert(semanticIndexCallback != null);

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

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  ///
  /// Typically, children in lazy list are wrapped in [AutomaticKeepAlive]
  /// widgets so that children can use [KeepAliveNotification]s to preserve
  /// their state when they would otherwise be garbage collected off-screen.
  ///
  /// This feature (and [addRepaintBoundaries]) must be disabled if the children
  /// are going to manually maintain their [KeepAlive] state. It may also be
  /// more efficient to disable this feature if it is known ahead of time that
  /// none of the children will ever try to keep themselves alive.
  ///
  /// Defaults to true.
  final bool addAutomaticKeepAlives;

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

  /// Whether to wrap each child in an [IndexedSemantics].
  ///
  /// Typically, children in a scrolling container must be annotated with a
  /// semantic index in order to generate the correct accessibility
  /// announcements. This should only be set to false if the indexes have
  /// already been provided by an [IndexedChildSemantics] widget.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///  * [IndexedChildSemantics], for an explanation of how to manually
  ///    provide semantic indexes.
  final bool addSemanticIndexes;

  /// An initial offset to add to the semantic indexes generated by this widget.
  ///
  /// Defaults to zero.
  final int semanticIndexOffset;

  /// A [SemanticIndexCallback] which is used when [addSemanticIndexes] is true.
  ///
  /// Defaults to providing an index for each widget.
  final SemanticIndexCallback semanticIndexCallback;

  /// Called to find the new index of a child based on its key in case of reordering.
  ///
  /// If not provided, a child widget may not map to its existing [RenderObject]
  /// when the order in which children are returned from [builder] changes.
  /// This may result in state-loss.
  ///
  /// This callback should take an input [Key], and It should return the
  /// index of the child element with associated key, null if not found.
  final ChildIndexGetter findChildIndexCallback;

  @override
  int findIndexByKey(Key key) {
    if (findChildIndexCallback == null)
      return null;
    assert(key != null);
    Key childKey;
    if (key is _SaltedValueKey) {
      final _SaltedValueKey saltedValueKey = key;
      childKey = saltedValueKey.value;
    } else {
      childKey = key;
    }
    return findChildIndexCallback(childKey);
  }

  @override
  Widget build(BuildContext context, int index) {
    assert(builder != null);
    if (index < 0 || (childCount != null && index >= childCount))
      return null;
    Widget child;
    try {
      child = builder(context, index);
    } catch (exception, stackTrace) {
      child = _createErrorWidget(exception, stackTrace);
    }
    if (child == null)
      return null;
    final Key key = child.key != null ? _SaltedValueKey(child.key) : null;
    if (addRepaintBoundaries)
      child = RepaintBoundary(child: child);
    if (addSemanticIndexes) {
      final int semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null)
        child = IndexedSemantics(index: semanticIndex + semanticIndexOffset, child: child);
    }
    if (addAutomaticKeepAlives)
      child = AutomaticKeepAlive(child: child);
    return KeyedSubtree(child: child, key: key);
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
/// The widgets in the given [children] list are automatically wrapped in
/// [AutomaticKeepAlive] widgets if [addAutomaticKeepAlives] is true (the
/// default) and in [RepaintBoundary] widgets if [addRepaintBoundaries] is true
/// (also the default).
///
/// ## Accessibility
///
/// The [CustomScrollView] requires that its semantic children are annotated
/// using [IndexedSemantics]. This is done by default in the delegate with
/// the `addSemanticIndexes` parameter set to true.
///
/// If multiple delegates are used in a single scroll view, then the indexes
/// will not be correct by default. The `semanticIndexOffset` can be used to
/// offset the semantic indexes of each delegate so that the indexes are
/// monotonically increasing. For example, if a scroll view contains two
/// delegates where the first has 10 children contributing semantics, then the
/// second delegate should offset its children by 10.
///
/// In certain cases, only a subset of child widgets should be annotated
/// with a semantic index. For example, in [new ListView.separated()] the
/// separators do not have an index associated with them. This is done by
/// providing a `semanticIndexCallback` which returns null for separators
/// indexes and rounds the non-separator indexes down by half.
///
/// See [SliverChildBuilderDelegate] for sample code using
/// `semanticIndexOffset` and `semanticIndexCallback`.
///
/// See also:
///
///  * [SliverChildBuilderDelegate], which is a delegate that uses a builder
///    callback to construct the children.
class SliverChildListDelegate extends SliverChildDelegate {
  /// Creates a delegate that supplies children for slivers using the given
  /// list.
  ///
  /// The [children], [addAutomaticKeepAlives], [addRepaintBoundaries],
  /// [addSemanticIndexes], and [semanticIndexCallback] arguments must not be
  /// null.
  ///
  /// If the order of children` never changes, consider using the constant
  /// [SliverChildListDelegate.fixed] constructor.
  SliverChildListDelegate(
    this.children, {
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
    this.semanticIndexOffset = 0,
  }) : assert(children != null),
       assert(addAutomaticKeepAlives != null),
       assert(addRepaintBoundaries != null),
       assert(addSemanticIndexes != null),
       assert(semanticIndexCallback != null),
       _keyToIndex = <Key, int>{null: 0};

  /// Creates a constant version of the delegate that supplies children for
  /// slivers using the given list.
  ///
  /// If the order of the children will change, consider using the regular
  /// [SliverChildListDelegate] constructor.
  ///
  /// The [children], [addAutomaticKeepAlives], [addRepaintBoundaries],
  /// [addSemanticIndexes], and [semanticIndexCallback] arguments must not be
  /// null.
  const SliverChildListDelegate.fixed(
    this.children, {
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
    this.semanticIndexOffset = 0,
  }) : assert(children != null),
       assert(addAutomaticKeepAlives != null),
       assert(addRepaintBoundaries != null),
       assert(addSemanticIndexes != null),
       assert(semanticIndexCallback != null),
       _keyToIndex = null;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  ///
  /// Typically, children in lazy list are wrapped in [AutomaticKeepAlive]
  /// widgets so that children can use [KeepAliveNotification]s to preserve
  /// their state when they would otherwise be garbage collected off-screen.
  ///
  /// This feature (and [addRepaintBoundaries]) must be disabled if the children
  /// are going to manually maintain their [KeepAlive] state. It may also be
  /// more efficient to disable this feature if it is known ahead of time that
  /// none of the children will ever try to keep themselves alive.
  ///
  /// Defaults to true.
  final bool addAutomaticKeepAlives;

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

  /// Whether to wrap each child in an [IndexedSemantics].
  ///
  /// Typically, children in a scrolling container must be annotated with a
  /// semantic index in order to generate the correct accessibility
  /// announcements. This should only be set to false if the indexes have
  /// already been provided by an [IndexedChildSemantics] widget.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///  * [IndexedChildSemantics], for an explanation of how to manually
  ///    provide semantic indexes.
  final bool addSemanticIndexes;

  /// An initial offset to add to the semantic indexes generated by this widget.
  ///
  /// Defaults to zero.
  final int semanticIndexOffset;

  /// A [SemanticIndexCallback] which is used when [addSemanticIndexes] is true.
  ///
  /// Defaults to providing an index for each widget.
  final SemanticIndexCallback semanticIndexCallback;

  /// The widgets to display.
  final List<Widget> children;

  /// A map to cache key to index lookup for children.
  ///
  /// _keyToIndex[null] is used as current index during the lazy loading process
  /// in [_findChildIndex]. _keyToIndex should never be used for looking up null key.
  final Map<Key, int> _keyToIndex;

  bool get _isConstantInstance => _keyToIndex == null;

  int _findChildIndex(Key key) {
    if (_isConstantInstance) {
      return null;
    }
    // Lazily fill the [_keyToIndex].
    if (!_keyToIndex.containsKey(key)) {
      int index = _keyToIndex[null];
      while (index < children.length) {
        final Widget child = children[index];
        if (child.key != null) {
          _keyToIndex[child.key] = index;
        }
        if (child.key == key) {
          // Record current index for next function call.
          _keyToIndex[null] = index + 1;
          return index;
        }
        index += 1;
      }
      _keyToIndex[null] = index;
    } else {
      return _keyToIndex[key];
    }
    return null;
  }

  @override
  int findIndexByKey(Key key) {
    assert(key != null);
    Key childKey;
    if (key is _SaltedValueKey) {
      final _SaltedValueKey saltedValueKey = key;
      childKey = saltedValueKey.value;
    } else {
      childKey = key;
    }
    return _findChildIndex(childKey);
  }

  @override
  Widget build(BuildContext context, int index) {
    assert(children != null);
    if (index < 0 || index >= children.length)
      return null;
    Widget child = children[index];
    final Key key = child.key != null? _SaltedValueKey(child.key) : null;
    assert(
      child != null,
      "The sliver's children must not contain null values, but a null value was found at index $index"
    );
    if (addRepaintBoundaries)
      child = RepaintBoundary(child: child);
    if (addSemanticIndexes) {
      final int semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null)
        child = IndexedSemantics(index: semanticIndex + semanticIndexOffset, child: child);
    }
    if (addAutomaticKeepAlives)
      child = AutomaticKeepAlive(child: child);
    return KeyedSubtree(child: child, key: key);
  }

  @override
  int get estimatedChildCount => children.length;

  @override
  bool shouldRebuild(covariant SliverChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

/// A base class for sliver that have [KeepAlive] children.
abstract class SliverWithKeepAliveWidget extends RenderObjectWidget {
  /// Initializes fields for subclasses.
  const SliverWithKeepAliveWidget({
    Key key,
  }) : super(key : key);

  @override
  RenderSliverWithKeepAliveMixin createRenderObject(BuildContext context);
}

/// A base class for sliver that have multiple box children.
///
/// Helps subclasses build their children lazily using a [SliverChildDelegate].
///
/// The widgets returned by the [delegate] are cached and the delegate is only
/// consulted again if it changes and the new delegate's [shouldRebuild] method
/// returns true.
abstract class SliverMultiBoxAdaptorWidget extends SliverWithKeepAliveWidget {
  /// Initializes fields for subclasses.
  const SliverMultiBoxAdaptorWidget({
    Key key,
    @required this.delegate,
  }) : assert(delegate != null),
       super(key: key);

  /// {@template flutter.widgets.sliverChildDelegate}
  /// The delegate that provides the children for this widget.
  ///
  /// The children are constructed lazily using this delegate to avoid creating
  /// more children than are visible through the [Viewport].
  ///
  /// See also:
  ///
  ///  * [SliverChildBuilderDelegate] and [SliverChildListDelegate], which are
  ///    commonly used subclasses of [SliverChildDelegate] that use a builder
  ///    callback and an explicit child list, respectively.
  /// {@endtemplate}
  final SliverChildDelegate delegate;

  @override
  SliverMultiBoxAdaptorElement createElement() => SliverMultiBoxAdaptorElement(this);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context);

  /// Returns an estimate of the max scroll extent for all the children.
  ///
  /// Subclasses should override this function if they have additional
  /// information about their max scroll extent.
  ///
  /// This is used by [SliverMultiBoxAdaptorElement] to implement part of the
  /// [RenderSliverBoxChildManager] API.
  ///
  /// The default implementation defers to [delegate] via its
  /// [SliverChildDelegate.estimateMaxScrollOffset] method.
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SliverChildDelegate>('delegate', delegate));
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
/// {@youtube 560 315 https://www.youtube.com/watch?v=ORiTTaVY6mM}
///
/// If the children have a fixed extent in the main axis, consider using
/// [SliverFixedExtentList] rather than [SliverList] because
/// [SliverFixedExtentList] does not need to perform layout on its children to
/// obtain their extent in the main axis and is therefore more efficient.
///
/// {@macro flutter.widgets.sliverChildDelegate.lifecycle}
///
/// See also:
///
///  * [SliverFixedExtentList], which is more efficient for children with
///    the same extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
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
    return RenderSliverList(childManager: element);
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
/// {@tool sample}
///
/// This example, which would be inserted into a [CustomScrollView.slivers]
/// list, shows an infinite number of items in varying shades of blue:
///
/// ```dart
/// SliverFixedExtentList(
///   itemExtent: 50.0,
///   delegate: SliverChildBuilderDelegate(
///     (BuildContext context, int index) {
///       return Container(
///         alignment: Alignment.center,
///         color: Colors.lightBlue[100 * (index % 9)],
///         child: Text('list item $index'),
///       );
///     },
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.sliverChildDelegate.lifecycle}
///
/// See also:
///
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
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
    return RenderSliverFixedExtentList(childManager: element, itemExtent: itemExtent);
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
/// The main axis direction of a grid is the direction in which it scrolls; the
/// cross axis direction is the orthogonal direction.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ORiTTaVY6mM}
///
/// {@tool sample}
///
/// This example, which would be inserted into a [CustomScrollView.slivers]
/// list, shows twenty boxes in a pretty teal grid:
///
/// ```dart
/// SliverGrid(
///   gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
///     maxCrossAxisExtent: 200.0,
///     mainAxisSpacing: 10.0,
///     crossAxisSpacing: 10.0,
///     childAspectRatio: 4.0,
///   ),
///   delegate: SliverChildBuilderDelegate(
///     (BuildContext context, int index) {
///       return Container(
///         alignment: Alignment.center,
///         color: Colors.teal[100 * (index % 9)],
///         child: Text('grid item $index'),
///       );
///     },
///     childCount: 20,
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.sliverChildDelegate.lifecycle}
///
/// See also:
///
///  * [SliverList], which places its children in a linear array.
///  * [SliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
class SliverGrid extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement.
  const SliverGrid({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.gridDelegate,
  }) : super(key: key, delegate: delegate);

  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement with a fixed number of tiles in the cross axis.
  ///
  /// Uses a [SliverGridDelegateWithFixedCrossAxisCount] as the [gridDelegate],
  /// and a [SliverChildListDelegate] as the [delegate].
  ///
  /// See also:
  ///
  ///  * [new GridView.count], the equivalent constructor for [GridView] widgets.
  SliverGrid.count({
    Key key,
    @required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    List<Widget> children = const <Widget>[],
  }) : gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       super(key: key, delegate: SliverChildListDelegate(children));

  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement with tiles that each have a maximum cross-axis extent.
  ///
  /// Uses a [SliverGridDelegateWithMaxCrossAxisExtent] as the [gridDelegate],
  /// and a [SliverChildListDelegate] as the [delegate].
  ///
  /// See also:
  ///
  ///  * [new GridView.extent], the equivalent constructor for [GridView] widgets.
  SliverGrid.extent({
    Key key,
    @required double maxCrossAxisExtent,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    List<Widget> children = const <Widget>[],
  }) : gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
         maxCrossAxisExtent: maxCrossAxisExtent,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       super(key: key, delegate: SliverChildListDelegate(children));

  /// The delegate that controls the size and position of the children.
  final SliverGridDelegate gridDelegate;

  @override
  RenderSliverGrid createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return RenderSliverGrid(childManager: element, gridDelegate: gridDelegate);
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
    ) ?? gridDelegate.getLayout(constraints).computeMaxScrollOffset(delegate.estimatedChildCount);
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
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
class SliverFillViewport extends StatelessWidget {
  /// Creates a sliver whose box children that each fill the viewport.
  const SliverFillViewport({
    Key key,
    @required this.delegate,
    this.viewportFraction = 1.0,
  }) : assert(viewportFraction != null),
       assert(viewportFraction > 0.0),
       assert(delegate != null),
       super(key: key);

  /// The fraction of the viewport that each child should fill in the main axis.
  ///
  /// If this fraction is less than 1.0, more than one child will be visible at
  /// once. If this fraction is greater than 1.0, each child will be larger than
  /// the viewport in the main axis.
  final double viewportFraction;

  /// {@macro flutter.widgets.sliverChildDelegate}
  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double fixedExtent = constraints.viewportMainAxisExtent * viewportFraction;
        final double padding = math.max(0, constraints.viewportMainAxisExtent - fixedExtent) / 2;

        EdgeInsets sliverPaddingValue;
        switch (constraints.axis) {
          case Axis.horizontal:
            sliverPaddingValue = EdgeInsets.symmetric(horizontal: padding);
            break;
          case Axis.vertical:
            sliverPaddingValue = EdgeInsets.symmetric(vertical: padding);
        }

        return SliverPadding(
          padding: sliverPaddingValue,
          sliver: SliverFixedExtentList(
            delegate: delegate,
            itemExtent: fixedExtent,
          ),
        );
      }
    );
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

  // We inflate widgets at two different times:
  //  1. When we ourselves are told to rebuild (see performRebuild).
  //  2. When our render object needs a new child (see createChild).
  // In both cases, we cache the results of calling into our delegate to get the widget,
  // so that if we do case 2 later, we don't call the builder again.
  // Any time we do case 1, though, we reset the cache.

  final Map<int, Widget> _childWidgets = HashMap<int, Widget>();
  final SplayTreeMap<int, Element> _childElements = SplayTreeMap<int, Element>();
  RenderBox _currentBeforeChild;

  @override
  void performRebuild() {
    _childWidgets.clear(); // Reset the cache, as described above.
    super.performRebuild();
    _currentBeforeChild = null;
    assert(_currentlyUpdatingChildIndex == null);
    try {
      final SplayTreeMap<int, Element> newChildren = SplayTreeMap<int, Element>();

      void processElement(int index) {
        _currentlyUpdatingChildIndex = index;
        if (_childElements[index] != null && _childElements[index] != newChildren[index]) {
          // This index has an old child that isn't used anywhere and should be deactivated.
          _childElements[index] = updateChild(_childElements[index], null, index);
        }
        final Element newChild = updateChild(newChildren[index], _build(index), index);
        if (newChild != null) {
          _childElements[index] = newChild;
          final SliverMultiBoxAdaptorParentData parentData = newChild.renderObject.parentData;
          if (!parentData.keptAlive)
            _currentBeforeChild = newChild.renderObject;
        } else {
          _childElements.remove(index);
        }
      }

      for (int index in _childElements.keys.toList()) {
        final Key key = _childElements[index].widget.key;
        final int newIndex = key == null ? null : widget.delegate.findIndexByKey(key);
        if (newIndex != null && newIndex != index) {
          newChildren[newIndex] = _childElements[index];
          // We need to make sure the original index gets processed.
          newChildren.putIfAbsent(index, () => null);
          // We do not want the remapped child to get deactivated during processElement.
          _childElements.remove(index);
        } else {
          newChildren.putIfAbsent(index, () => _childElements[index]);
        }
      }

      renderObject.debugChildIntegrityEnabled = false; // Moving children will temporary violate the integrity.
      newChildren.keys.forEach(processElement);
      if (_didUnderflow) {
        final int lastKey = _childElements.lastKey() ?? -1;
        final int rightBoundary = lastKey + 1;
        newChildren[rightBoundary] = _childElements[rightBoundary];
        processElement(rightBoundary);
      }
    } finally {
      _currentlyUpdatingChildIndex = null;
      renderObject.debugChildIntegrityEnabled = true;
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
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    final SliverMultiBoxAdaptorParentData oldParentData = child?.renderObject?.parentData;
    final Element newChild = super.updateChild(child, newWidget, newSlot);
    final SliverMultiBoxAdaptorParentData newParentData = newChild?.renderObject?.parentData;

    // Preserve the old layoutOffset if the renderObject was swapped out.
    if (oldParentData != newParentData && oldParentData != null && newParentData != null) {
      newParentData.layoutOffset = oldParentData.layoutOffset;
    }
    return newChild;
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

  static double _extrapolateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
    int childCount,
  ) {
    if (lastIndex == childCount - 1)
      return trailingScrollOffset;
    final int reifiedCount = lastIndex - firstIndex + 1;
    final double averageExtent = (trailingScrollOffset - leadingScrollOffset) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    final int childCount = this.childCount;
    if (childCount == null)
      return double.infinity;
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
      childCount,
    );
  }

  @override
  int get childCount => widget.delegate.estimatedChildCount;

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
    }());
  }

  @override
  void moveChildRenderObject(covariant RenderObject child, int slot) {
    assert(slot != null);
    assert(_currentlyUpdatingChildIndex == slot);
    renderObject.move(child, after: _currentBeforeChild);
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

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    _childElements.values.where((Element child) {
      final SliverMultiBoxAdaptorParentData parentData = child.renderObject.parentData;
      double itemExtent;
      switch (renderObject.constraints.axis) {
        case Axis.horizontal:
          itemExtent = child.renderObject.paintBounds.width;
          break;
        case Axis.vertical:
          itemExtent = child.renderObject.paintBounds.height;
          break;
      }

      return parentData.layoutOffset < renderObject.constraints.scrollOffset + renderObject.constraints.remainingPaintExtent &&
          parentData.layoutOffset + itemExtent > renderObject.constraints.scrollOffset;
    }).forEach(visitor);
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
    this.hasScrollBody = true,
    this.fillOverscroll = false,
  }) : assert(hasScrollBody != null),
       super(key: key, child: child);

  /// Indicates whether the child has a scrollable body, this value cannot be
  /// null.
  ///
  /// Defaults to true such that the child will extend beyond the viewport and
  /// scroll, as seen in [NestedScrollView].
  ///
  /// Setting this value to false will allow the child to fill the remainder of
  /// the viewport and not extend further. However, if the
  /// [precedingScrollExtent] exceeds the size of the viewport, the sliver will
  /// defer to the child's size rather than overriding it.
  final bool hasScrollBody;

  /// Indicates whether the child should stretch to fill the overscroll area
  /// created by certain scroll physics, such as iOS' default scroll physics.
  /// This value cannot be null. This flag is only relevant when the
  /// [hasScrollBody] value is false.
  ///
  /// Defaults to false, meaning the default behavior is for the child to
  /// maintain its size and not extend into the overscroll area.
  final bool fillOverscroll;

  @override
  RenderSliverFillRemaining createRenderObject(BuildContext context) {
    return RenderSliverFillRemaining(
      hasScrollBody: hasScrollBody,
      fillOverscroll: fillOverscroll,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverFillRemaining renderObject) {
    renderObject.hasScrollBody = hasScrollBody;
    renderObject.fillOverscroll = fillOverscroll;
  }
}

/// Mark a child as needing to stay alive even when it's in a lazy list that
/// would otherwise remove it.
///
/// This widget is for use in [SliverWithKeepAliveWidget]s, such as
/// [SliverGrid] or [SliverList].
///
/// This widget is rarely used directly. The [SliverChildBuilderDelegate] and
/// [SliverChildListDelegate] delegates, used with [SliverList] and
/// [SliverGrid], as well as the scroll view counterparts [ListView] and
/// [GridView], have an `addAutomaticKeepAlives` feature, which is enabled by
/// default, and which causes [AutomaticKeepAlive] widgets to be inserted around
/// each child, causing [KeepAlive] widgets to be automatically added and
/// configured in response to [KeepAliveNotification]s.
///
/// Therefore, to keep a widget alive, it is more common to use those
/// notifications than to directly deal with [KeepAlive] widgets.
///
/// In practice, the simplest way to deal with these notifications is to mix
/// [AutomaticKeepAliveClientMixin] into one's [State]. See the documentation
/// for that mixin class for details.
class KeepAlive extends ParentDataWidget<SliverWithKeepAliveWidget> {
  /// Marks a child as needing to remain alive.
  ///
  /// The [child] and [keepAlive] arguments must not be null.
  const KeepAlive({
    Key key,
    @required this.keepAlive,
    @required Widget child,
  }) : assert(child != null),
       assert(keepAlive != null),
       super(key: key, child: child);

  /// Whether to keep the child alive.
  ///
  /// If this is false, it is as if this widget was omitted.
  final bool keepAlive;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is KeepAliveParentDataMixin);
    final KeepAliveParentDataMixin parentData = renderObject.parentData;
    if (parentData.keepAlive != keepAlive) {
      parentData.keepAlive = keepAlive;
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject && !keepAlive)
        targetParent.markNeedsLayout(); // No need to redo layout if it became true.
    }
  }

  // We only return true if [keepAlive] is true, because turning _off_ keep
  // alive requires a layout to do the garbage collection (but turning it on
  // requires nothing, since by definition the widget is already alive and won't
  // go away _unless_ we do a layout).
  @override
  bool debugCanApplyOutOfTurn() => keepAlive;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('keepAlive', keepAlive));
  }
}

// Return a Widget for the given Exception
Widget _createErrorWidget(dynamic exception, StackTrace stackTrace) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stackTrace,
    library: 'widgets library',
    context: ErrorDescription('building'),
  );
  FlutterError.reportError(details);
  return ErrorWidget.builder(details);
}
