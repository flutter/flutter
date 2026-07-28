// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'debug.dart';
import 'drag_boundary.dart';
import 'framework.dart';
import 'inherited_theme.dart';
import 'localizations.dart';
import 'media_query.dart';
import 'overlay.dart';
import 'scroll_controller.dart';
import 'scroll_delegate.dart';
import 'scroll_physics.dart';
import 'scroll_view.dart';
import 'scrollable.dart';
import 'scrollable_helpers.dart';
import 'sliver.dart';
import 'sliver_prototype_extent_list.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

// Examples can assume:
// class MyDataObject {}

/// A callback used by [ReorderableList] to report that a list item has moved
/// to a new position in the list.
///
/// Implementations should remove the corresponding list item at [oldIndex]
/// and reinsert it at [newIndex].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=3fB1mxOsqJE}
///
/// {@tool snippet}
///
/// ```dart
/// final List<MyDataObject> backingList = <MyDataObject>[/* ... */];
///
/// void handleReorderItem(int oldIndex, int newIndex) {
///   final MyDataObject element = backingList.removeAt(oldIndex);
///   backingList.insert(newIndex, element);
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ReorderableList], a widget list that allows the user to reorder
///    its items.
///  * [SliverReorderableList], a sliver list that allows the user to reorder
///    its items.
///  * [ReorderableListView], a Material Design list that allows the user to
///    reorder its items.
typedef ReorderCallback = void Function(int oldIndex, int newIndex);

/// Signature for the builder callback used to decorate the dragging item in
/// [ReorderableList] and [SliverReorderableList].
///
/// The [child] will be the item that is being dragged, and [index] is the
/// position of the item in the list.
///
/// The [animation] will be driven forward from 0.0 to 1.0 while the item is
/// being picked up during a drag operation, and reversed from 1.0 to 0.0 when
/// the item is dropped. This can be used to animate properties of the proxy
/// like an elevation or border.
///
/// The returned value will typically be the [child] wrapped in other widgets.
typedef ReorderItemProxyDecorator =
    Widget Function(Widget child, int index, Animation<double> animation);

/// Used to provide drag boundaries during drag-and-drop reordering.
///
/// {@tool snippet}
/// ```dart
/// DragBoundary(
///  child: CustomScrollView(
///    slivers: <Widget>[
///      SliverReorderableList(
///        itemBuilder: (BuildContext context, int index) {
///          return ReorderableDragStartListener(
///            key: ValueKey<int>(index),
///            index: index,
///            child: Text('$index'),
///          );
///        },
///        dragBoundaryProvider: (BuildContext context) {
///          return DragBoundary.forRectOf(context);
///        },
///        itemCount: 5,
///        onReorderItem: (int fromIndex, int toIndex) {},
///      ),
///    ],
///  )
/// )
/// ```
/// {@end-tool}
///
/// See also:
/// * [DragBoundary], a widget that provides drag boundaries.
typedef ReorderDragBoundaryProvider = DragBoundaryDelegate<Rect>? Function(BuildContext context);

/// A scrolling container that allows the user to interactively reorder the
/// list items.
///
/// This widget is similar to one created by [ListView.builder], and uses
/// an [IndexedWidgetBuilder] to create each item.
///
/// It is up to the application to wrap each child (or an internal part of the
/// child such as a drag handle) with a drag listener that will recognize
/// the start of an item drag and then start the reorder by calling
/// [ReorderableListState.startItemDragReorder]. This is most easily achieved
/// by wrapping each child in a [ReorderableDragStartListener] or a
/// [ReorderableDelayedDragStartListener]. These will take care of recognizing
/// the start of a drag gesture and call the list state's
/// [ReorderableListState.startItemDragReorder] method.
///
/// This widget's [ReorderableListState] can be used to manually start an item
/// reorder, or cancel a current drag. To refer to the
/// [ReorderableListState] either provide a [GlobalKey] or use the static
/// [ReorderableList.of] method from an item's build method.
///
/// See also:
///
///  * [SliverReorderableList], a sliver list that allows the user to reorder
///    its items.
///  * [ReorderableListView], a Material Design list that allows the user to
///    reorder its items.
class ReorderableList extends StatefulWidget {
  /// Creates a scrolling container that allows the user to interactively
  /// reorder the list items.
  ///
  /// The [itemCount] must be greater than or equal to zero.
  const ReorderableList({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    @Deprecated(
      'Use the onReorderItem callback instead. '
      'The onReorderItem callback adjusts the newIndex parameter for a removed item at the oldIndex. '
      'This feature was deprecated after v3.41.0-0.0.pre.',
    )
    this.onReorder,
    this.onReorderItem,
    this.onReorderStart,
    this.onReorderEnd,
    this.itemExtent,
    this.itemExtentBuilder,
    this.prototypeItem,
    this.proxyDecorator,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    @Deprecated(
      'Use scrollCacheExtent instead. '
      'This feature was deprecated after v3.41.0-0.0.pre.',
    )
    this.cacheExtent,
    this.scrollCacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.autoScrollerVelocityScalar,
    this.dragBoundaryProvider,
  }) : assert(itemCount >= 0),
       assert(
         (itemExtent == null && prototypeItem == null) ||
             (itemExtent == null && itemExtentBuilder == null) ||
             (prototypeItem == null && itemExtentBuilder == null),
         'You can only pass one of itemExtent, prototypeItem and itemExtentBuilder.',
       ),
       assert(
         (onReorderItem != null && onReorder == null) ||
             (onReorderItem == null && onReorder != null),
         'The onReorder callback is obsolete and is replaced by onReorderItem. '
         'Remove the onReorder callback when both callbacks are provided.',
       );

  /// {@template flutter.widgets.reorderable_list.itemBuilder}
  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  ///
  /// The [IndexedWidgetBuilder] index parameter indicates the item's
  /// position in the list. The value of the index parameter will be between
  /// zero and one less than [itemCount]. All items in the list must have a
  /// unique [Key], and should have some kind of listener to start the drag
  /// (usually a [ReorderableDragStartListener] or
  /// [ReorderableDelayedDragStartListener]).
  /// {@endtemplate}
  final IndexedWidgetBuilder itemBuilder;

  /// {@template flutter.widgets.reorderable_list.itemCount}
  /// The number of items in the list.
  ///
  /// It must be a non-negative integer. When zero, nothing is displayed and
  /// the widget occupies no space.
  /// {@endtemplate}
  final int itemCount;

  /// {@template flutter.widgets.reorderable_list.onReorder}
  /// A callback used by the list to report that a list item has been dragged
  /// to a new location in the list and the application should update the order
  /// of the items.
  ///
  /// If `oldIndex` is before `newIndex`, removing the item at `oldIndex` from the
  /// list will reduce the list's length by one. Implementations will need to
  /// account for this when inserting before `newIndex`.
  ///
  /// This callback has been deprecated in favor of [onReorderItem], which
  /// simplifies the reordering logic by automatically handling index adjustments.
  /// To migrate, remove the manual adjustment of `newIndex`
  /// when items are moved downward in the list.
  ///
  /// For example:
  ///
  /// ```dart
  /// onReorder: (int oldIndex, int newIndex) {
  ///   if (newIndex > oldIndex) {
  ///     newIndex -= 1;
  ///   }
  ///
  ///   // Handle reordering...
  /// }
  /// ```
  ///
  /// becomes
  ///
  /// ```dart
  /// onReorderItem: (int oldIndex, int newIndex) {
  ///   // Handle reordering...
  /// }
  /// ```
  /// {@endtemplate}
  @Deprecated(
    'Use the onReorderItem callback instead. '
    'The onReorderItem callback adjusts the newIndex parameter for a removed item at the oldIndex. '
    'This feature was deprecated after v3.41.0-0.0.pre.',
  )
  final ReorderCallback? onReorder;

  /// {@template flutter.widgets.reorderable_list.onReorderItem}
  /// A callback used by the list to report that a list item has been dragged
  /// to a new location in the list and the application should update the order
  /// of the items.
  /// {@endtemplate}
  final ReorderCallback? onReorderItem;

  /// {@template flutter.widgets.reorderable_list.onReorderStart}
  /// A callback that is called when an item drag has started.
  ///
  /// The index parameter of the callback is the index of the selected item.
  ///
  /// See also:
  ///
  ///   * [onReorderEnd], which is a called when the dragged item is dropped.
  ///   * [onReorderItem], which reports that a list item has been dragged to a new
  ///     location.
  /// {@endtemplate}
  final void Function(int index)? onReorderStart;

  /// {@template flutter.widgets.reorderable_list.onReorderEnd}
  /// A callback that is called when the dragged item is dropped.
  ///
  /// The index parameter of the callback is the index where the item is
  /// dropped. Unlike [onReorderItem], this is called even when the list item is
  /// dropped in the same location.
  ///
  /// See also:
  ///
  ///   * [onReorderStart], which is a called when an item drag has started.
  ///   * [onReorderItem], which reports that a list item has been dragged to a new
  ///     location.
  /// {@endtemplate}
  final void Function(int index)? onReorderEnd;

  /// {@template flutter.widgets.reorderable_list.proxyDecorator}
  /// A callback that allows the app to add an animated decoration around
  /// an item when it is being dragged.
  /// {@endtemplate}
  final ReorderItemProxyDecorator? proxyDecorator;

  /// {@template flutter.widgets.reorderable_list.padding}
  /// The amount of space by which to inset the list contents.
  ///
  /// It defaults to `EdgeInsets.all(0)`.
  /// {@endtemplate}
  final EdgeInsetsGeometry? padding;

  /// {@macro flutter.widgets.scroll_view.scrollDirection}
  final Axis scrollDirection;

  /// {@macro flutter.widgets.scroll_view.reverse}
  final bool reverse;

  /// {@macro flutter.widgets.scroll_view.controller}
  final ScrollController? controller;

  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// {@macro flutter.widgets.scroll_view.physics}
  final ScrollPhysics? physics;

  /// {@macro flutter.widgets.scroll_view.shrinkWrap}
  final bool shrinkWrap;

  /// {@macro flutter.widgets.scroll_view.anchor}
  final double anchor;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  @Deprecated(
    'Use scrollCacheExtent instead. '
    'This feature was deprecated after v3.41.0-0.0.pre.',
  )
  final double? cacheExtent;

  /// {@macro flutter.rendering.RenderViewportBase.scrollCacheExtent}
  final ScrollCacheExtent? scrollCacheExtent;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  ///
  /// If [keyboardDismissBehavior] is null then it will fallback to the inherited
  /// [ScrollBehavior.getKeyboardDismissBehavior].
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.list_view.itemExtent}
  final double? itemExtent;

  /// {@macro flutter.widgets.list_view.itemExtentBuilder}
  final ItemExtentBuilder? itemExtentBuilder;

  /// {@macro flutter.widgets.list_view.prototypeItem}
  final Widget? prototypeItem;

  /// {@macro flutter.widgets.EdgeDraggingAutoScroller.velocityScalar}
  ///
  /// {@macro flutter.widgets.SliverReorderableList.autoScrollerVelocityScalar.default}
  final double? autoScrollerVelocityScalar;

  /// {@template flutter.widgets.reorderable_list.dragBoundaryProvider}
  /// A callback used to provide drag boundaries during drag-and-drop reordering.
  ///
  /// If null, the delegate returned by `DragBoundary.forRectMaybeOf` will be used.
  /// Defaults to null.
  /// {@endtemplate}
  final ReorderDragBoundaryProvider? dragBoundaryProvider;

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [ReorderableList] item widgets that
  /// insert or remove items in response to user input.
  ///
  /// If no [ReorderableList] surrounds the given context, then this function
  /// will assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [maybeOf], a similar function that will return null if no
  ///    [ReorderableList] ancestor is found.
  static ReorderableListState of(BuildContext context) {
    final ReorderableListState? result = context.findAncestorStateOfType<ReorderableListState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'ReorderableList.of() called with a context that does not contain a ReorderableList.',
          ),
          ErrorDescription(
            'No ReorderableList ancestor could be found starting from the context that was passed to ReorderableList.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the ReorderableList. Please see the ReorderableList documentation for examples '
            'of how to refer to an ReorderableListState object:\n'
            '  https://api.flutter.dev/flutter/widgets/ReorderableListState-class.html',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!;
  }

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [ReorderableList] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [ReorderableList] surrounds the context given, then this function will
  /// return null.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [of], a similar function that will throw if no [ReorderableList] ancestor
  ///    is found.
  static ReorderableListState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ReorderableListState>();
  }

  @override
  ReorderableListState createState() => ReorderableListState();
}

/// The state for a list that allows the user to interactively reorder
/// the list items.
///
/// An app that needs to start a new item drag or cancel an existing one
/// can refer to the [ReorderableList]'s state with a global key:
///
/// ```dart
/// GlobalKey<ReorderableListState> listKey = GlobalKey<ReorderableListState>();
/// // ...
/// Widget build(BuildContext context) {
///   return ReorderableList(
///     key: listKey,
///     itemBuilder: (BuildContext context, int index) => const SizedBox(height: 10.0),
///     itemCount: 5,
///     onReorderItem: (int oldIndex, int newIndex) {
///        // ...
///     },
///   );
/// }
/// // ...
/// listKey.currentState!.cancelReorder();
/// ```
class ReorderableListState extends State<ReorderableList> {
  final GlobalKey<SliverReorderableListState> _sliverReorderableListKey = GlobalKey();

  ScrollCacheExtent? get _effectiveScrollCacheExtent {
    if (widget.scrollCacheExtent != null) {
      return widget.scrollCacheExtent;
    }

    if (widget.cacheExtent != null) {
      return ScrollCacheExtent.pixels(widget.cacheExtent!);
    }
    return null;
  }

  /// Initiate the dragging of the item at [index] that was started with
  /// the pointer down [event].
  ///
  /// The given [recognizer] will be used to recognize and start the drag
  /// item tracking and lead to either an item reorder, or a canceled drag.
  /// The list will take ownership of the returned recognizer and will dispose
  /// it when it is no longer needed.
  ///
  /// Most applications will not use this directly, but will wrap the item
  /// (or part of the item, like a drag handle) in either a
  /// [ReorderableDragStartListener] or [ReorderableDelayedDragStartListener]
  /// which call this for the application.
  void startItemDragReorder({
    required int index,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer recognizer,
  }) {
    _sliverReorderableListKey.currentState!.startItemDragReorder(
      index: index,
      event: event,
      recognizer: recognizer,
    );
  }

  /// Cancel any item drag in progress.
  ///
  /// This should be called before any major changes to the item list
  /// occur so that any item drags will not get confused by
  /// changes to the underlying list.
  ///
  /// If no drag is active, this will do nothing.
  void cancelReorder() {
    _sliverReorderableListKey.currentState!.cancelReorder();
  }

  @protected
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      anchor: widget.anchor,
      scrollCacheExtent: _effectiveScrollCacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      slivers: <Widget>[
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: SliverReorderableList(
            key: _sliverReorderableListKey,
            itemExtent: widget.itemExtent,
            prototypeItem: widget.prototypeItem,
            itemBuilder: widget.itemBuilder,
            itemExtentBuilder: widget.itemExtentBuilder,
            itemCount: widget.itemCount,
            onReorder: widget.onReorder,
            onReorderItem: widget.onReorderItem,
            onReorderStart: widget.onReorderStart,
            onReorderEnd: widget.onReorderEnd,
            proxyDecorator: widget.proxyDecorator,
            autoScrollerVelocityScalar: widget.autoScrollerVelocityScalar,
            dragBoundaryProvider: widget.dragBoundaryProvider,
          ),
        ),
      ],
    );
  }
}

/// A sliver list that allows the user to interactively reorder the list items.
///
/// It is up to the application to wrap each child (or an internal part of the
/// child) with a drag listener that will recognize the start of an item drag
/// and then start the reorder by calling
/// [SliverReorderableListState.startItemDragReorder]. This is most easily
/// achieved by wrapping each child in a [ReorderableDragStartListener] or
/// a [ReorderableDelayedDragStartListener]. These will take care of
/// recognizing the start of a drag gesture and call the list state's start
/// item drag method.
///
/// This widget's [SliverReorderableListState] can be used to manually start an item
/// reorder, or cancel a current drag that's already underway. To refer to the
/// [SliverReorderableListState] either provide a [GlobalKey] or use the static
/// [SliverReorderableList.of] method from an item's build method.
///
/// See also:
///
///  * [ReorderableList], a regular widget list that allows the user to reorder
///    its items.
///  * [ReorderableListView], a Material Design list that allows the user to
///    reorder its items.
class SliverReorderableList extends StatefulWidget {
  /// Creates a sliver list that allows the user to interactively reorder its
  /// items.
  ///
  /// The [itemCount] must be greater than or equal to zero.
  const SliverReorderableList({
    super.key,
    required this.itemBuilder,
    this.findChildIndexCallback,
    required this.itemCount,
    @Deprecated(
      'Use the onReorderItem callback instead. '
      'The onReorderItem callback adjusts the newIndex parameter for a removed item at the oldIndex. '
      'This feature was deprecated after v3.41.0-0.0.pre.',
    )
    this.onReorder,
    this.onReorderItem,
    this.onReorderStart,
    this.onReorderEnd,
    this.itemExtent,
    this.itemExtentBuilder,
    this.prototypeItem,
    this.proxyDecorator,
    this.dragBoundaryProvider,
    double? autoScrollerVelocityScalar,
  }) : _separatorBuilder = null,
       _findItemIndexCallback = null,
       autoScrollerVelocityScalar = autoScrollerVelocityScalar ?? _kDefaultAutoScrollVelocityScalar,
       assert(itemCount >= 0),
       assert(
         (itemExtent == null && prototypeItem == null) ||
             (itemExtent == null && itemExtentBuilder == null) ||
             (prototypeItem == null && itemExtentBuilder == null),
         'You can only pass one of itemExtent, prototypeItem and itemExtentBuilder.',
       ),
       assert(
         (onReorderItem != null && onReorder == null) ||
             (onReorderItem == null && onReorder != null),
         'The onReorder callback is obsolete and is replaced by onReorderItem. '
         'Remove the onReorder callback when both callbacks are provided.',
       );

  /// Creates a sliver list that allows the user to interactively reorder its
  /// items, with a separator between each pair of adjacent items.
  ///
  /// This is the sliver equivalent of [ListView.separated] with reordering
  /// support. Only the items participate in reordering; the separators are
  /// position-based and are rebuilt for their visual boundary. Callers that
  /// need a separated reorderable list outside a hand-built [CustomScrollView]
  /// can use [ReorderableListView.separated], which wraps this sliver.
  ///
  /// The [itemCount] must be greater than or equal to zero. When [itemCount] is
  /// `n`, there are `n` items and `n - 1` separators.
  ///
  /// The [itemBuilder] is called with item indices in the range `0` to
  /// `itemCount - 1`. Every item must have a unique [Key] and, like
  /// [SliverReorderableList], should include a drag listener (such as a
  /// [ReorderableDragStartListener]) to start a reorder.
  ///
  /// The `separatorBuilder` is called with boundary indices in the range `0` to
  /// `itemCount - 2`. Separator `j` appears between item `j` and item `j + 1`;
  /// separators never appear before the first item or after the last item.
  /// Separators do not need a key, cannot start a reorder, never appear in the
  /// drag proxy, and receive no reorder semantics or callbacks.
  /// {@template flutter.widgets.reorderable_list.separated.positionBasedSeparators}
  /// The `separatorBuilder` index always refers to the current visual
  /// boundary, so an alternating or otherwise index-dependent separator keeps
  /// its position-based appearance during and after a reorder.
  /// {@endtemplate}
  ///
  /// The drag proxy contains and measures only the dragged item, never a
  /// separator.
  /// {@template flutter.widgets.reorderable_list.separated.dragBehavior}
  /// All separators remain visible for the whole drag: they translate to stay
  /// aligned with their current visual boundary, so the insertion gap always
  /// appears as an empty slot, exactly the dragged item's extent, between the
  /// two separators (or list edge) that will surround the item when it is
  /// dropped.
  /// {@endtemplate}
  ///
  /// [onReorderItem] reports the reorder using item indices; `newIndex` is
  /// already adjusted for the removal of the item at `oldIndex`, so it is always
  /// in the range `0` to `itemCount - 1`. The [onReorderStart] and
  /// [onReorderEnd] callbacks are not adjusted this way: [onReorderStart]
  /// receives the dragged item's index and [onReorderEnd] receives the raw
  /// insertion index in the range `0` to `itemCount`, exactly as they do for
  /// the default constructor.
  ///
  /// The `findItemIndexCallback` receives the original item keys (the keys
  /// returned by [itemBuilder]) and must return the item's logical index, not a
  /// delegate index. This differs from [findChildIndexCallback] (available on
  /// the default [SliverReorderableList] constructor), which operates on the
  /// delegate's child indices. For this constructor the delegate interleaves
  /// separators with items, so raw child indices are an internal detail;
  /// `findItemIndexCallback` operates purely in logical item-index space.
  /// {@template flutter.widgets.reorderable_list.separated.statePreservation}
  /// Providing it lets the list relocate an existing keyed item to its new
  /// index when the underlying data moves, preserving the item's [State],
  /// instead of rebuilding it there.
  /// {@endtemplate}
  ///
  /// The deprecated `onReorder` callback and the `itemExtent`,
  /// `itemExtentBuilder`, and `prototypeItem` extent options are intentionally
  /// unavailable on this constructor: a new API must not launch with a
  /// deprecated callback, and a single item-extent policy cannot describe
  /// alternating, heterogeneous items and separators.
  const SliverReorderableList.separated({
    super.key,
    required this.itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    required this.itemCount,
    // The explicit type keeps the parameter non-nullable, unlike the shared
    // field: there is no `onReorder` alternative here, so an explicit null
    // would silently swallow every reorder.
    required ReorderCallback this.onReorderItem,
    ChildIndexGetter? findItemIndexCallback,
    this.onReorderStart,
    this.onReorderEnd,
    this.proxyDecorator,
    this.dragBoundaryProvider,
    double? autoScrollerVelocityScalar,
  }) : _separatorBuilder = separatorBuilder,
       _findItemIndexCallback = findItemIndexCallback,
       onReorder = null,
       findChildIndexCallback = null,
       itemExtent = null,
       itemExtentBuilder = null,
       prototypeItem = null,
       autoScrollerVelocityScalar = autoScrollerVelocityScalar ?? _kDefaultAutoScrollVelocityScalar,
       assert(itemCount >= 0);

  // An eyeballed value for a smooth scrolling experience.
  static const double _kDefaultAutoScrollVelocityScalar = 50;

  /// The builder used to build separators between items. Non-null only for the
  /// [SliverReorderableList.separated] constructor; the other constructors leave
  /// it null so their tree structure and timing are unchanged.
  final IndexedWidgetBuilder? _separatorBuilder;

  /// The finder used to map an original item key to its logical item index for
  /// the separated constructor. See [SliverReorderableList.separated].
  final ChildIndexGetter? _findItemIndexCallback;

  /// {@macro flutter.widgets.reorderable_list.itemBuilder}
  final IndexedWidgetBuilder itemBuilder;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.findChildIndexCallback}
  ///
  /// This is always null for [SliverReorderableList.separated], whose delegate
  /// interleaves separators with items so that delegate child indices are an
  /// internal detail. That constructor takes a `findItemIndexCallback` instead,
  /// which operates in logical item-index space.
  final ChildIndexGetter? findChildIndexCallback;

  /// {@macro flutter.widgets.reorderable_list.itemCount}
  final int itemCount;

  /// {@macro flutter.widgets.reorderable_list.onReorder}
  @Deprecated(
    'Use the onReorderItem callback instead. '
    'The onReorderItem callback adjusts the newIndex parameter for a removed item at the oldIndex. '
    'This feature was deprecated after v3.41.0-0.0.pre.',
  )
  final ReorderCallback? onReorder;

  /// {@macro flutter.widgets.reorderable_list.onReorderItem}
  final ReorderCallback? onReorderItem;

  /// {@macro flutter.widgets.reorderable_list.onReorderStart}
  final void Function(int)? onReorderStart;

  /// {@macro flutter.widgets.reorderable_list.onReorderEnd}
  final void Function(int)? onReorderEnd;

  /// {@macro flutter.widgets.reorderable_list.proxyDecorator}
  final ReorderItemProxyDecorator? proxyDecorator;

  /// {@macro flutter.widgets.list_view.itemExtent}
  final double? itemExtent;

  /// {@macro flutter.widgets.list_view.itemExtentBuilder}
  final ItemExtentBuilder? itemExtentBuilder;

  /// {@macro flutter.widgets.list_view.prototypeItem}
  final Widget? prototypeItem;

  /// {@macro flutter.widgets.EdgeDraggingAutoScroller.velocityScalar}
  ///
  /// {@template flutter.widgets.SliverReorderableList.autoScrollerVelocityScalar.default}
  /// Defaults to 50 if not set or set to null.
  /// {@endtemplate}
  final double autoScrollerVelocityScalar;

  /// {@macro flutter.widgets.reorderable_list.dragBoundaryProvider}
  final ReorderDragBoundaryProvider? dragBoundaryProvider;

  @override
  SliverReorderableListState createState() => SliverReorderableListState();

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [SliverReorderableList] item widgets to
  /// start or cancel an item drag operation.
  ///
  /// If no [SliverReorderableList] surrounds the context given, this function
  /// will assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [maybeOf], a similar function that will return null if no
  ///    [SliverReorderableList] ancestor is found.
  static SliverReorderableListState of(BuildContext context) {
    final SliverReorderableListState? result = context
        .findAncestorStateOfType<SliverReorderableListState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'SliverReorderableList.of() called with a context that does not contain a SliverReorderableList.',
          ),
          ErrorDescription(
            'No SliverReorderableList ancestor could be found starting from the context that was passed to SliverReorderableList.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the SliverReorderableList. Please see the SliverReorderableList documentation for examples '
            'of how to refer to an SliverReorderableList object:\n'
            '  https://api.flutter.dev/flutter/widgets/SliverReorderableListState-class.html',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!;
  }

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [SliverReorderableList] item widgets that
  /// insert or remove items in response to user input.
  ///
  /// If no [SliverReorderableList] surrounds the context given, this function
  /// will return null.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [of], a similar function that will throw if no [SliverReorderableList]
  ///    ancestor is found.
  static SliverReorderableListState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<SliverReorderableListState>();
  }
}

/// The state for a sliver list that allows the user to interactively reorder
/// the list items.
///
/// An app that needs to start a new item drag or cancel an existing one
/// can refer to the [SliverReorderableList]'s state with a global key:
///
/// ```dart
/// // (e.g. in a stateful widget)
/// GlobalKey<SliverReorderableListState> listKey = GlobalKey<SliverReorderableListState>();
///
/// // ...
///
/// @override
/// Widget build(BuildContext context) {
///   return SliverReorderableList(
///     key: listKey,
///     itemBuilder: (BuildContext context, int index) => const SizedBox(height: 10.0),
///     itemCount: 5,
///     onReorderItem: (int oldIndex, int newIndex) {
///        // ...
///     },
///   );
/// }
///
/// // ...
///
/// void _stop() {
///   listKey.currentState!.cancelReorder();
/// }
/// ```
///
/// [ReorderableDragStartListener] and [ReorderableDelayedDragStartListener]
/// refer to their [SliverReorderableList] with the static
/// [SliverReorderableList.of] method.
class SliverReorderableListState extends State<SliverReorderableList>
    with TickerProviderStateMixin {
  // Map of index -> child state used manage where the dragging item will need
  // to be inserted.
  final Map<int, _ReorderableItemState> _items = <int, _ReorderableItemState>{};

  /// Map of boundary index -> separator state, used only by the separated
  /// constructor. Separators are position-based and never enter [_items],
  /// [_dragIndex], [_insertIndex], hit testing, semantics, or the drag proxy.
  final Map<int, _ReorderableSeparatorState> _separators = <int, _ReorderableSeparatorState>{};

  /// Natural (untransformed) scroll-axis extents of items and separators, cached
  /// for the duration of a drag so that children which scroll out and later
  /// return keep their correct target computation. An extent is captured when a
  /// child registers or is first measured, not continuously tracked: extents
  /// are assumed to stay stable for the duration of one drag.
  final Map<int, double> _itemExtentCache = <int, double>{};
  final Map<int, double> _separatorExtentCache = <int, double>{};

  bool _separatedGeometryRefreshScheduled = false;

  bool get _isSeparated => widget._separatorBuilder != null;

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _DragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer? _recognizer;
  int? _recognizerPointer;

  EdgeDraggingAutoScroller? _autoScroller;

  late ScrollableState _scrollable;
  Axis get _scrollDirection => axisDirectionToAxis(_scrollable.axisDirection);
  bool get _reverse => axisDirectionIsReversed(_scrollable.axisDirection);

  @protected
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.of(context);
    if (_autoScroller?.scrollable != _scrollable) {
      _autoScroller?.stopAutoScroll();
      _autoScroller = EdgeDraggingAutoScroller(
        _scrollable,
        onScrollViewScrolled: _handleScrollableAutoScrolled,
        velocityScalar: widget.autoScrollerVelocityScalar,
      );
    }
  }

  @protected
  @override
  void didUpdateWidget(covariant SliverReorderableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching between the separated and default constructors changes both
    // the delegate's child model and the drag-offset model, so an in-flight
    // drag can no more survive it than it can survive an itemCount change.
    final wasSeparated = oldWidget._separatorBuilder != null;
    if (widget.itemCount != oldWidget.itemCount || _isSeparated != wasSeparated) {
      cancelReorder();
    }

    if (widget.autoScrollerVelocityScalar != oldWidget.autoScrollerVelocityScalar) {
      _autoScroller?.stopAutoScroll();
      _autoScroller = EdgeDraggingAutoScroller(
        _scrollable,
        onScrollViewScrolled: _handleScrollableAutoScrolled,
        velocityScalar: widget.autoScrollerVelocityScalar,
      );
    }
  }

  @protected
  @override
  void dispose() {
    _dragReset();
    _recognizer?.dispose();
    super.dispose();
  }

  /// Initiate the dragging of the item at [index] that was started with
  /// the pointer down [event].
  ///
  /// The given [recognizer] will be used to recognize and start the drag
  /// item tracking and lead to either an item reorder, or a canceled drag.
  ///
  /// Most applications will not use this directly, but will wrap the item
  /// (or part of the item, like a drag handle) in either a
  /// [ReorderableDragStartListener] or [ReorderableDelayedDragStartListener]
  /// which call this method when they detect the gesture that triggers a drag
  /// start.
  void startItemDragReorder({
    required int index,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer recognizer,
  }) {
    assert(0 <= index && index < widget.itemCount);
    setState(() {
      if (_dragInfo != null) {
        cancelReorder();
      } else if (_recognizer != null && _recognizerPointer != event.pointer) {
        _recognizer!.dispose();
        _recognizer = null;
        _recognizerPointer = null;
      }

      if (_items.containsKey(index)) {
        _dragIndex = index;
        _recognizer = recognizer
          ..onStart = _dragStart
          ..addPointer(event);
        _recognizerPointer = event.pointer;
      } else {
        // TODO(darrenaustin): Can we handle this better, maybe scroll to the item?
        throw Exception('Attempting to start a drag on a non-visible item');
      }
    });
  }

  /// Cancel any item drag in progress.
  ///
  /// This should be called before any major changes to the item list
  /// occur so that any item drags will not get confused by
  /// changes to the underlying list.
  ///
  /// If a drag operation is in progress, this will immediately reset
  /// the list to back to its pre-drag state.
  ///
  /// If no drag is active, this will do nothing.
  void cancelReorder() {
    setState(() {
      _dragReset();
    });
  }

  void _registerItem(_ReorderableItemState item) {
    if (_dragInfo != null && _items[item.index] != item) {
      if (_isSeparated) {
        // Snap the newly (re)registered item to its current target without a
        // rebuild (this can run during build), then refresh once its extent is
        // known after layout.
        _measureChildExtent(item.context, _itemExtentCache, item.index);
        item.initTargetOffset(_separatedItemTargetOffset(item.index));
        _scheduleSeparatedGeometryRefresh();
      } else {
        item.updateForGap(
          _dragInfo!.index,
          _dragInfo!.index,
          _dragInfo!.itemExtent,
          false,
          _reverse,
        );
      }
    }
    _items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item.dragging = true;
      item.rebuild();
    }
  }

  void _unregisterItem(int index, _ReorderableItemState item) {
    final _ReorderableItemState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  void _registerSeparator(_ReorderableSeparatorState separator) {
    if (_dragInfo != null && _separators[separator.index] != separator) {
      _measureChildExtent(separator.context, _separatorExtentCache, separator.index);
      separator.initTargetOffset(_separatedSeparatorTargetOffset(separator.index));
      _scheduleSeparatedGeometryRefresh();
    }
    _separators[separator.index] = separator;
  }

  void _unregisterSeparator(int index, _ReorderableSeparatorState separator) {
    final _ReorderableSeparatorState? currentSeparator = _separators[index];
    if (currentSeparator == separator) {
      _separators.remove(index);
    }
  }

  Drag? _dragStart(Offset position) {
    assert(_dragInfo == null);
    final _ReorderableItemState item = _items[_dragIndex!]!;
    item.dragging = true;
    widget.onReorderStart?.call(_dragIndex!);
    item.rebuild();

    _insertIndex = item.index;
    _dragInfo = _DragInfo(
      item: item,
      initialPosition: position,
      scrollDirection: _scrollDirection,
      onUpdate: _dragUpdate,
      onCancel: _dragCancel,
      onEnd: _dragEnd,
      onDropCompleted: _dropCompleted,
      proxyDecorator: widget.proxyDecorator,
      tickerProvider: this,
    );
    _dragInfo!.startDrag();

    final OverlayState overlay = Overlay.of(context, debugRequiredFor: widget);
    assert(_overlayEntry == null);
    _overlayEntry = OverlayEntry(builder: _dragInfo!.createProxy);
    overlay.insert(_overlayEntry!);

    if (_isSeparated) {
      // Capture the natural extents of all mounted children before autoscroll
      // can dispose any of them. Targets are all zero at drag start
      // (gap == dragIndex), so nothing needs to move yet.
      _cacheMountedChildExtents();
    } else {
      for (final _ReorderableItemState childItem in _items.values) {
        if (childItem == item || !childItem.mounted) {
          continue;
        }
        childItem.updateForGap(
          _insertIndex!,
          _insertIndex!,
          _dragInfo!.itemExtent,
          false,
          _reverse,
        );
      }
    }
    return _dragInfo;
  }

  void _dragUpdate(_DragInfo item, Offset position, Offset delta) {
    setState(() {
      _overlayEntry?.markNeedsBuild();
      _dragUpdateItems();
      _autoScroller?.startAutoScrollIfNecessary(_dragTargetRect);
    });
  }

  void _dragCancel(_DragInfo item) {
    setState(() {
      _dragReset();
    });
  }

  void _dragEnd(_DragInfo item) {
    setState(() {
      if (_isSeparated) {
        _finalDropPosition = _separatedDropPosition(item.index);
      } else if (_insertIndex! - item.index == 1) {
        // When returning to original position from below, _insertIndex equals
        // item.index + 1 because insertion index is calculated with the dragged
        // item still present. Use the actual target position for animation.
        _finalDropPosition = _itemOffsetAt(_insertIndex! - 1);
      } else if (_insertIndex == item.index) {
        // No movement - animate to current position
        _finalDropPosition = _itemOffsetAt(_insertIndex!);
      } else if (_reverse) {
        if (_insertIndex! >= _items.length) {
          // Drop at the starting position of the last element and offset its own extent
          _finalDropPosition =
              _itemOffsetAt(_items.length - 1) - _extentOffset(item.itemExtent, _scrollDirection);
        } else {
          // Drop at the end of the current element occupying the insert position
          _finalDropPosition =
              _itemOffsetAt(_insertIndex!) +
              _extentOffset(_itemExtentAt(_insertIndex!), _scrollDirection);
        }
      } else {
        if (_insertIndex! == 0) {
          // Drop at the starting position of the first element and offset its own extent
          _finalDropPosition = _itemOffsetAt(0) - _extentOffset(item.itemExtent, _scrollDirection);
        } else {
          // Drop at the end of the previous element occupying the insert position
          final int atIndex = _insertIndex! - 1;
          _finalDropPosition =
              _itemOffsetAt(atIndex) + _extentOffset(_itemExtentAt(atIndex), _scrollDirection);
        }
      }
    });
    widget.onReorderEnd?.call(_insertIndex!);
  }

  void _dropCompleted() {
    final int oldIndex = _dragIndex!;

    if (_isSeparated) {
      // `_separatedGap` is already the final item index (it applies the same
      // "-1 for a downward move" adjustment that `_handleReorderItem` would),
      // so call `onReorderItem` directly to avoid decrementing twice. Preserve
      // the "no callback when the item does not move" guard.
      final int newIndex = _separatedGap;
      if (oldIndex != newIndex) {
        // The separated constructor requires onReorderItem, so it cannot be
        // null here.
        widget.onReorderItem!(oldIndex, newIndex);
      }
    } else {
      _handleReorderItem(oldIndex, _insertIndex!);
    }

    setState(() {
      _dragReset();
    });
  }

  void _dragReset() {
    if (_dragInfo != null) {
      if (_dragIndex != null && _items.containsKey(_dragIndex)) {
        final _ReorderableItemState dragItem = _items[_dragIndex!]!;
        dragItem._dragging = false;
        dragItem.rebuild();
        _dragIndex = null;
      }
      _dragInfo?.dispose();
      _dragInfo = null;
      _autoScroller?.stopAutoScroll();
      _resetItemGap();
      // Separator state is reset unconditionally rather than only when
      // `_isSeparated`: if the widget switched between the separated and
      // default constructors mid-drag, `_isSeparated` no longer describes the
      // constructor this drag started under. The collections are all empty in
      // non-separated mode, so this costs nothing there.
      _resetSeparatorGap();
      _itemExtentCache.clear();
      _separatorExtentCache.clear();
      _recognizer?.dispose();
      _recognizer = null;
      _overlayEntry?.remove();
      _overlayEntry?.dispose();
      _overlayEntry = null;
      _finalDropPosition = null;
    }
  }

  void _resetItemGap() {
    for (final _ReorderableItemState item in _items.values) {
      item.resetGap();
    }
  }

  void _resetSeparatorGap() {
    for (final _ReorderableSeparatorState separator in _separators.values) {
      separator.resetGap();
    }
  }

  void _handleReorderItem(int oldIndex, int newIndex) {
    if (widget.onReorder != null && oldIndex != newIndex) {
      widget.onReorder?.call(oldIndex, newIndex);
      return;
    }

    // Removing an item at the old index shortens the list by one.
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex != newIndex) {
      widget.onReorderItem?.call(oldIndex, newIndex);
    }
  }

  void _handleScrollableAutoScrolled() {
    if (_dragInfo == null) {
      return;
    }
    _dragUpdateItems();
    // Continue scrolling if the drag is still in progress.
    _autoScroller?.startAutoScrollIfNecessary(_dragTargetRect);
  }

  void _dragUpdateItems() {
    assert(_dragInfo != null);
    final double gapExtent = _dragInfo!.itemExtent;
    final double proxyItemStart = _offsetExtent(
      _dragInfo!.dragPosition - _dragInfo!.dragOffset,
      _scrollDirection,
    );
    final double proxyItemEnd = proxyItemStart + gapExtent;

    // Find the new index for inserting the item being dragged.
    int newIndex = _insertIndex!;
    for (final _ReorderableItemState item in _items.values) {
      if ((_reverse && item.index == _dragIndex!) || !item.mounted) {
        continue;
      }

      final Rect geometry = item.targetGeometry();
      final double itemStart = _scrollDirection == Axis.vertical ? geometry.top : geometry.left;
      final double itemExtent = _scrollDirection == Axis.vertical
          ? geometry.height
          : geometry.width;
      final double itemEnd = itemStart + itemExtent;
      final double itemMiddle = itemStart + itemExtent / 2;

      if (_reverse) {
        if (itemEnd >= proxyItemEnd && proxyItemEnd >= itemMiddle) {
          // The start of the proxy is in the beginning half of the item, so
          // we should swap the item with the gap and we are done looking for
          // the new index.
          newIndex = item.index;
          break;
        } else if (itemMiddle >= proxyItemStart && proxyItemStart >= itemStart) {
          // The end of the proxy is in the ending half of the item, so
          // we should swap the item with the gap and we are done looking for
          // the new index.
          newIndex = item.index + 1;
          break;
        } else if (itemStart > proxyItemEnd && newIndex < (item.index + 1)) {
          newIndex = item.index + 1;
        } else if (proxyItemStart > itemEnd && newIndex > item.index) {
          newIndex = item.index;
        }
      } else {
        if (item.index == _dragIndex!) {
          // If end of the proxy is not in ending half of item,
          // we don't process, because it's original dragged item.
          if (itemMiddle <= proxyItemEnd && proxyItemEnd <= itemEnd) {
            newIndex = _dragIndex!;
          }
        } else if (itemStart <= proxyItemStart && proxyItemStart <= itemMiddle) {
          // The start of the proxy is in the beginning half of the item, so
          // we should swap the item with the gap and we are done looking for
          // the new index.
          newIndex = item.index;
          break;
        } else if (itemMiddle <= proxyItemEnd && proxyItemEnd <= itemEnd) {
          // The end of the proxy is in the ending half of the item, so
          // we should swap the item with the gap and we are done looking for
          // the new index.
          newIndex = item.index + 1;
          break;
        } else if (itemEnd < proxyItemStart && newIndex < (item.index + 1)) {
          newIndex = item.index + 1;
        } else if (proxyItemEnd < itemStart && newIndex > item.index) {
          newIndex = item.index;
        }
      }
    }

    if (newIndex != _insertIndex) {
      _insertIndex = newIndex;
      if (_isSeparated) {
        _pushSeparatedTargets(animate: true);
      } else {
        for (final _ReorderableItemState item in _items.values) {
          if (item.index == _dragIndex! || !item.mounted) {
            continue;
          }
          item.updateForGap(_dragIndex!, newIndex, gapExtent, true, _reverse);
        }
      }
    }
  }

  Rect get _dragTargetRect {
    final Offset origin = _dragInfo!.dragPosition - _dragInfo!.dragOffset;
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      _dragInfo!.itemSize.width,
      _dragInfo!.itemSize.height,
    );
  }

  Offset _itemOffsetAt(int index) {
    return _items[index]!.targetGeometry().topLeft;
  }

  double _itemExtentAt(int index) {
    return _sizeExtent(_items[index]!.targetGeometry().size, _scrollDirection);
  }

  /// The insertion gap in final item-index space for a given dragged item.
  ///
  /// `_insertIndex` is in insertion-index space (the dragged item is still
  /// counted), so a downward move is decremented by one. The result is the final
  /// index the dragged item would occupy, always in `0 .. itemCount - 1`.
  ///
  /// Only meaningful while an item is being dragged, which implies at least one
  /// item; the clamp below would throw for an empty list because its upper
  /// limit would fall below its lower limit.
  int _separatedGapFor(int dragIndex) {
    assert(
      widget.itemCount > 0,
      'A gap only exists while an item is dragged, so the list is non-empty.',
    );
    final int insert = _insertIndex ?? dragIndex;
    final int gap = insert > dragIndex ? insert - 1 : insert;
    return gap.clamp(0, widget.itemCount - 1);
  }

  /// The insertion gap for the currently dragged item. Only valid while a drag
  /// is active (`_dragIndex != null`).
  int get _separatedGap => _separatedGapFor(_dragIndex!);

  void _measureChildExtent(BuildContext childContext, Map<int, double> cache, int index) {
    final RenderObject? box = childContext.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      cache[index] = _sizeExtent(box.size, _scrollDirection);
    }
  }

  void _cacheMountedChildExtents() {
    for (final MapEntry<int, _ReorderableItemState> entry in _items.entries) {
      if (entry.key == _dragIndex || !entry.value.mounted) {
        continue;
      }
      _measureChildExtent(entry.value.context, _itemExtentCache, entry.key);
    }
    for (final MapEntry<int, _ReorderableSeparatorState> entry in _separators.entries) {
      if (!entry.value.mounted) {
        continue;
      }
      _measureChildExtent(entry.value.context, _separatorExtentCache, entry.key);
    }
  }

  /// The natural extent of the child at `index`, read through `cache`. A miss
  /// measures the mounted [child]'s render box and caches the result; a child
  /// that is unmounted and was never measured during this drag contributes 0.0.
  double _cachedChildExtent(
    Map<int, double> cache,
    _ReorderableGapMixin<StatefulWidget>? child,
    int index,
  ) {
    final double? cached = cache[index];
    if (cached != null) {
      return cached;
    }
    if (child != null && child.mounted) {
      _measureChildExtent(child.context, cache, index);
      return cache[index] ?? 0.0;
    }
    return 0.0;
  }

  double _cachedItemExtent(int index) {
    if (index == _dragIndex && _dragInfo != null) {
      return _dragInfo!.itemExtent;
    }
    return _cachedChildExtent(_itemExtentCache, _items[index], index);
  }

  double _cachedSeparatorExtent(int index) {
    return _cachedChildExtent(_separatorExtentCache, _separators[index], index);
  }

  /// The shared inputs of the separated target-offset formulas: the dragged
  /// item's index, the insertion gap, and the dragged item's extent. Null when
  /// no drag is active.
  (int drag, int gap, double draggedExtent)? get _separatedDragGeometry {
    if (_dragIndex == null) {
      return null;
    }
    return (_dragIndex!, _separatedGap, _cachedItemExtent(_dragIndex!));
  }

  /// The target translation for item `index`, treating items and separators as
  /// fixed-size children that translate to their final visual origins. The
  /// math is computed in non-reversed main-axis coordinates and then flipped for
  /// reversed lists.
  Offset _separatedItemTargetOffset(int index) {
    final (int, int, double)? geometry = _separatedDragGeometry;
    if (geometry == null) {
      return Offset.zero;
    }
    final (int drag, int gap, double draggedExtent) = geometry;
    var main = 0.0;
    if (drag < gap) {
      // Downward move: items in (drag, gap] shift toward the list start.
      if (index > drag && index <= gap) {
        main = -(draggedExtent + _cachedSeparatorExtent(index - 1));
      }
    } else if (gap < drag) {
      // Upward move: items in [gap, drag) shift toward the list end.
      if (index >= gap && index < drag) {
        main = draggedExtent + _cachedSeparatorExtent(index);
      }
    }
    return _extentOffset(_reverse ? -main : main, _scrollDirection);
  }

  /// The target translation for separator `index`. See
  /// [_separatedItemTargetOffset].
  Offset _separatedSeparatorTargetOffset(int index) {
    final (int, int, double)? geometry = _separatedDragGeometry;
    if (geometry == null) {
      return Offset.zero;
    }
    final (int drag, int gap, double draggedExtent) = geometry;
    var main = 0.0;
    if (drag < gap) {
      if (index >= drag && index < gap) {
        main = _cachedItemExtent(index + 1) - draggedExtent;
      }
    } else if (gap < drag) {
      if (index >= gap && index < drag) {
        main = draggedExtent - _cachedItemExtent(index);
      }
    }
    return _extentOffset(_reverse ? -main : main, _scrollDirection);
  }

  void _pushSeparatedTargets({required bool animate}) {
    for (final MapEntry<int, _ReorderableItemState> entry in _items.entries) {
      if (entry.key == _dragIndex || !entry.value.mounted) {
        continue;
      }
      entry.value.updateTargetOffset(_separatedItemTargetOffset(entry.key), animate: animate);
    }
    for (final MapEntry<int, _ReorderableSeparatorState> entry in _separators.entries) {
      if (!entry.value.mounted) {
        continue;
      }
      entry.value.updateTargetOffset(_separatedSeparatorTargetOffset(entry.key), animate: animate);
    }
  }

  /// Lazily built or autoscrolled children register mid-drag before their
  /// extent is known. Refresh the geometry once after the next layout so their
  /// targets reflect real measured extents.
  void _scheduleSeparatedGeometryRefresh() {
    if (_separatedGeometryRefreshScheduled) {
      return;
    }
    _separatedGeometryRefreshScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _separatedGeometryRefreshScheduled = false;
      if (!mounted || _dragInfo == null || !_isSeparated) {
        return;
      }
      _cacheMountedChildExtents();
      _pushSeparatedTargets(animate: false);
    });
  }

  /// The global position the item-only drag proxy animates to on drop: the
  /// origin of the insertion gap in the transformed layout.
  ///
  /// The gap is bounded by the separator on its leading side (boundary
  /// `gap - 1`) or, for the first gap, by the separator on its trailing side
  /// (boundary `gap`). A gap-adjacent separator is mounted whenever the drop
  /// gap itself is on screen - unlike the dragged item's origin slot, which a
  /// long autoscrolled drag may have disposed.
  Offset? _separatedDropPosition(int dragIndex) {
    final int gap = _separatedGapFor(dragIndex);
    final double draggedExtent = _cachedItemExtent(dragIndex);
    final _ReorderableSeparatorState? leading = _separators[gap - 1];
    if (leading != null && leading.mounted) {
      // The gap begins where its leading separator ends.
      final Rect anchor = leading.targetGeometry();
      final double main = _reverse ? -draggedExtent : _sizeExtent(anchor.size, _scrollDirection);
      return anchor.topLeft + _extentOffset(main, _scrollDirection);
    }
    final _ReorderableSeparatorState? trailing = _separators[gap];
    if (trailing != null && trailing.mounted) {
      // The gap ends where its trailing separator begins (for the first gap,
      // which has no leading separator, this is also the list's logical
      // start).
      final Rect anchor = trailing.targetGeometry();
      final double main = _reverse ? _sizeExtent(anchor.size, _scrollDirection) : -draggedExtent;
      return anchor.topLeft + _extentOffset(main, _scrollDirection);
    }
    // A single-item list has no separators; the gap is the dragged item's own
    // slot. With no mounted anchor at all, return null so the proxy settles
    // where it was released instead of animating toward a stale position.
    final _ReorderableItemState? dragItem = _items[dragIndex];
    if (dragItem != null && dragItem.mounted) {
      return dragItem.targetGeometry().topLeft;
    }
    return null;
  }

  Widget _separatedChildBuilder(BuildContext context, int index) {
    if (index.isOdd) {
      final int separatorIndex = index ~/ 2;
      return _ReorderableSeparator(
        key: _ReorderableSeparatorKey(separatorIndex),
        index: separatorIndex,
        child: widget._separatorBuilder!(context, separatorIndex),
      );
    }
    // Even delegate children are items. The index passed on is always in
    // `0 .. itemCount - 1`, so `_itemBuilder`'s trailing drag-filler branch
    // is unreachable in separated mode.
    return _itemBuilder(context, index ~/ 2);
  }

  int? _separatedFindChildIndexCallback(Key key) {
    // Separators are position-fixed: boundary `j` is always delegate child
    // `2j + 1`. Resolve their private keys internally and never forward them to
    // user code.
    if (key is _ReorderableSeparatorKey) {
      return key.value * 2 + 1;
    }
    final ChildIndexGetter? findItemIndexCallback = widget._findItemIndexCallback;
    if (findItemIndexCallback == null) {
      return null;
    }
    // Forward the original user item key (unwrapping the private item key) and
    // map the returned logical item index to the even delegate child `2i`.
    final Key itemKey = key is _ReorderableItemGlobalKey ? key.subKey : key;
    final int? itemIndex = findItemIndexCallback(itemKey);
    return itemIndex == null ? null : itemIndex * 2;
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (_dragInfo != null && index >= widget.itemCount) {
      return switch (_scrollDirection) {
        Axis.horizontal => SizedBox(width: _dragInfo!.itemExtent),
        Axis.vertical => SizedBox(height: _dragInfo!.itemExtent),
      };
    }
    final Widget child = widget.itemBuilder(context, index);
    assert(child.key != null, 'All list items must have a key');
    final OverlayState overlay = Overlay.of(context, debugRequiredFor: widget);
    return _ReorderableItem(
      key: _ReorderableItemGlobalKey(child.key!, index, this),
      index: index,
      capturedThemes: InheritedTheme.capture(from: context, to: overlay.context),
      child: _wrapWithSemantics(child, index),
    );
  }

  Widget _wrapWithSemantics(Widget child, int index) {
    // First, determine which semantics actions apply.
    final semanticsActions = <CustomSemanticsAction, VoidCallback>{};

    // Create the appropriate semantics actions.
    void moveToStart() => _handleReorderItem(index, 0);
    void moveToEnd() => _handleReorderItem(index, widget.itemCount);
    void moveBefore() => _handleReorderItem(index, index - 1);
    // To move after, go to index+2 because it is moved to the space
    // before index+2, which is after the space at index+1.
    void moveAfter() => _handleReorderItem(index, index + 2);

    final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
    final isHorizontal = _scrollDirection == Axis.horizontal;
    // If the item can move to before its current position in the list.
    if (index > 0) {
      semanticsActions[CustomSemanticsAction(label: localizations.reorderItemToStart)] =
          moveToStart;
      String reorderItemBefore = localizations.reorderItemUp;
      if (isHorizontal) {
        reorderItemBefore = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemLeft
            : localizations.reorderItemRight;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] = moveBefore;
    }

    // If the item can move to after its current position in the list.
    if (index < widget.itemCount - 1) {
      String reorderItemAfter = localizations.reorderItemDown;
      if (isHorizontal) {
        reorderItemAfter = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemRight
            : localizations.reorderItemLeft;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemAfter)] = moveAfter;
      semanticsActions[CustomSemanticsAction(label: localizations.reorderItemToEnd)] = moveToEnd;
    }

    // Pass toWrap with a GlobalKey into the item so that when it
    // gets dragged, the accessibility framework can preserve the selected
    // state of the dragging item.
    //
    // Also apply the relevant custom accessibility actions for moving the item
    // up, down, to the start, and to the end of the list.
    return Semantics(container: true, customSemanticsActions: semanticsActions, child: child);
  }

  @protected
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    if (_isSeparated) {
      // A stable 2n - 1 delegate interleaving items (even children) and
      // separators (odd children). The separated constructor does not expose
      // fixed, varied, or prototype item-extent optimizations, so it always
      // uses a plain SliverList.
      final childrenDelegate = SliverChildBuilderDelegate(
        _separatedChildBuilder,
        childCount: widget.itemCount == 0 ? 0 : widget.itemCount * 2 - 1,
        findChildIndexCallback: _separatedFindChildIndexCallback,
        semanticIndexCallback: (Widget _, int index) => index.isEven ? index ~/ 2 : null,
      );
      return SliverList(delegate: childrenDelegate);
    }
    final childrenDelegate = SliverChildBuilderDelegate(
      _itemBuilder,
      childCount: widget.itemCount,
      findChildIndexCallback: widget.findChildIndexCallback,
    );
    if (widget.itemExtent != null) {
      return SliverFixedExtentList(delegate: childrenDelegate, itemExtent: widget.itemExtent!);
    } else if (widget.itemExtentBuilder != null) {
      return SliverVariedExtentList(
        delegate: childrenDelegate,
        itemExtentBuilder: widget.itemExtentBuilder!,
      );
    } else if (widget.prototypeItem != null) {
      return SliverPrototypeExtentList(
        delegate: childrenDelegate,
        prototypeItem: widget.prototypeItem!,
      );
    }
    return SliverList(delegate: childrenDelegate);
  }
}

class _ReorderableItem extends StatefulWidget {
  const _ReorderableItem({
    required Key super.key,
    required this.index,
    required this.child,
    required this.capturedThemes,
  });

  final int index;
  final Widget child;
  final CapturedThemes capturedThemes;

  @override
  _ReorderableItemState createState() => _ReorderableItemState();
}

/// Shared drag-offset animation machinery for the children (items and
/// separators) of a [SliverReorderableList]. It owns the interruptible 250 ms
/// transform animation and the current/target offsets, but not the policy that
/// decides a target: the target is always supplied by the owning state (via
/// [_ReorderableItemState.updateForGap] for items, or directly by the list
/// state for the separated path), so exactly one code path writes a given
/// child's [_targetOffset] at a time.
mixin _ReorderableGapMixin<T extends StatefulWidget> on State<T> {
  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  AnimationController? _offsetAnimation;

  SliverReorderableListState get _listState;

  Offset get offset {
    if (_offsetAnimation != null) {
      final double animValue = Curves.easeInOut.transform(_offsetAnimation!.value);
      return Offset.lerp(_startOffset, _targetOffset, animValue)!;
    }
    return _targetOffset;
  }

  /// Immediately snaps the child to [target] without animating or scheduling a
  /// rebuild. Used when a child is (re)registered during an active drag so that
  /// it appears at its correct offset on its first build, avoiding a setState
  /// during build or initState.
  void initTargetOffset(Offset target) {
    _offsetAnimation?.dispose();
    _offsetAnimation = null;
    _startOffset = target;
    _targetOffset = target;
  }

  /// Moves the child toward [newTargetOffset]. When [animate] is true, an
  /// interrupted animation is retargeted from its currently painted offset
  /// rather than snapping to an endpoint.
  void updateTargetOffset(Offset newTargetOffset, {required bool animate}) {
    if (newTargetOffset == _targetOffset) {
      return;
    }
    final Offset previousTarget = _targetOffset;
    _targetOffset = newTargetOffset;
    if (animate) {
      if (_offsetAnimation == null) {
        _offsetAnimation =
            AnimationController(vsync: _listState, duration: const Duration(milliseconds: 250))
              ..addListener(rebuild)
              ..addStatusListener((AnimationStatus status) {
                if (status.isCompleted) {
                  _startOffset = _targetOffset;
                  _offsetAnimation!.dispose();
                  _offsetAnimation = null;
                }
              })
              ..forward();
      } else {
        // Animation interrupted - calculate current position from previous animation
        final double currentAnimValue = Curves.easeInOut.transform(_offsetAnimation!.value);
        final Offset currentPosition = Offset.lerp(_startOffset, previousTarget, currentAnimValue)!;
        _startOffset = currentPosition;
        _offsetAnimation!.forward(from: 0.0);
      }
    } else {
      if (_offsetAnimation != null) {
        _offsetAnimation!.dispose();
        _offsetAnimation = null;
      }
      _startOffset = _targetOffset;
    }
    rebuild();
  }

  void resetGap() {
    if (_offsetAnimation != null) {
      _offsetAnimation!.dispose();
      _offsetAnimation = null;
    }
    _startOffset = Offset.zero;
    _targetOffset = Offset.zero;
    rebuild();
  }

  void disposeGap() {
    _offsetAnimation?.dispose();
  }

  Rect targetGeometry() {
    final itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition = itemRenderBox.localToGlobal(Offset.zero) + _targetOffset;
    return itemPosition & itemRenderBox.size;
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _ReorderableItemState extends State<_ReorderableItem>
    with _ReorderableGapMixin<_ReorderableItem> {
  @override
  late SliverReorderableListState _listState;

  Key get key => widget.key!;
  int get index => widget.index;

  bool get dragging => _dragging;
  set dragging(bool dragging) {
    if (mounted) {
      setState(() {
        _dragging = dragging;
      });
    }
  }

  bool _dragging = false;

  @override
  void initState() {
    _listState = SliverReorderableList.of(context);
    _listState._registerItem(this);
    super.initState();
  }

  @override
  void dispose() {
    disposeGap();
    _listState._unregisterItem(index, this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReorderableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _listState._unregisterItem(oldWidget.index, this);
      _listState._registerItem(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dragging) {
      final Size size = _extentSize(_listState._dragInfo!.itemExtent, _listState._scrollDirection);
      return SizedBox.fromSize(size: size);
    }
    _listState._registerItem(this);
    Widget child = widget.child;
    if (_listState._isSeparated) {
      // [_ReorderableItemGlobalKey] compares the item index too, so relocating
      // a keyed item to a new index (via findItemIndexCallback) recreates this
      // element. The inner key is index-independent and reparents the subtree
      // into the recreated element, preserving the item's State. It is added
      // here, below the wrapper, so that the drag proxy's copy of
      // [widget.child] never contains it and cannot claim the same global key.
      final Key userKey = (key as _ReorderableItemGlobalKey).subKey;
      child = KeyedSubtree(key: _ReorderableItemChildGlobalKey(userKey, _listState), child: child);
    }
    return Transform.translate(offset: offset, child: child);
  }

  @override
  void deactivate() {
    _listState._unregisterItem(index, this);
    super.deactivate();
  }

  void updateForGap(int dragIndex, int gapIndex, double gapExtent, bool animate, bool reverse) {
    assert(
      !_listState._isSeparated,
      'The uniform-gap model must never drive a child during a separated drag; '
      'the separated path supplies per-child targets directly from the list '
      'state via updateTargetOffset.',
    );
    // An offset needs to be added to create a gap when we are between the
    // moving element (dragIndex) and the current gap position (gapIndex).
    // For how to update the gap position, refer to [_dragUpdateItems].
    final Offset newTargetOffset;
    if (gapIndex < dragIndex && index < dragIndex && index >= gapIndex) {
      newTargetOffset = _extentOffset(
        reverse ? -gapExtent : gapExtent,
        _listState._scrollDirection,
      );
    } else if (gapIndex > dragIndex && index > dragIndex && index < gapIndex) {
      newTargetOffset = _extentOffset(
        reverse ? gapExtent : -gapExtent,
        _listState._scrollDirection,
      );
    } else {
      newTargetOffset = Offset.zero;
    }
    updateTargetOffset(newTargetOffset, animate: animate);
  }
}

/// A private wrapper for a separator built by
/// [SliverReorderableList.separated]. Separators are position-based: separator
/// `index` is always rebuilt for the visual boundary between item `index` and
/// item `index + 1`. They translate to follow the moving gap during a drag but
/// never become reorder targets.
class _ReorderableSeparator extends StatefulWidget {
  const _ReorderableSeparator({required Key super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  _ReorderableSeparatorState createState() => _ReorderableSeparatorState();
}

class _ReorderableSeparatorState extends State<_ReorderableSeparator>
    with _ReorderableGapMixin<_ReorderableSeparator> {
  @override
  late SliverReorderableListState _listState;

  int get index => widget.index;

  @override
  void initState() {
    _listState = SliverReorderableList.of(context);
    _listState._registerSeparator(this);
    super.initState();
  }

  @override
  void dispose() {
    disposeGap();
    _listState._unregisterSeparator(index, this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReorderableSeparator oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      oldWidget.index == widget.index,
      "The wrapper's key is derived from the boundary index, and an element is "
      'only updated with a widget whose key matches, so the index cannot '
      'change for a live separator state.',
    );
  }

  @override
  void deactivate() {
    _listState._unregisterSeparator(index, this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    _listState._registerSeparator(this);
    return Transform.translate(offset: offset, child: widget.child);
  }
}

/// A wrapper widget that will recognize the start of a drag on the wrapped
/// widget by a [PointerDownEvent], and immediately initiate dragging the
/// wrapped item to a new location in a reorderable list.
///
/// See also:
///
///  * [ReorderableDelayedDragStartListener], a similar wrapper that will
///    only recognize the start after a long press event.
///  * [ReorderableList], a widget list that allows the user to reorder
///    its items.
///  * [SliverReorderableList], a sliver list that allows the user to reorder
///    its items.
///  * [ReorderableListView], a Material Design list that allows the user to
///    reorder its items.
class ReorderableDragStartListener extends StatelessWidget {
  /// Creates a listener for a drag immediately following a pointer down
  /// event over the given child widget.
  ///
  /// This is most commonly used to wrap part of a list item like a drag
  /// handle.
  const ReorderableDragStartListener({
    super.key,
    required this.child,
    required this.index,
    this.enabled = true,
  });

  /// The widget for which the application would like to respond to a tap and
  /// drag gesture by starting a reordering drag on a reorderable list.
  final Widget child;

  /// The index of the associated item that will be dragged in the list.
  final int index;

  /// Whether the [child] item can be dragged and moved in the list.
  ///
  /// If true, the item can be moved to another location in the list when the
  /// user taps on the child. If false, tapping on the child will be ignored.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled ? (PointerDownEvent event) => _startDragging(context, event) : null,
      child: child,
    );
  }

  /// Provides the gesture recognizer used to indicate the start of a reordering
  /// drag operation.
  ///
  /// By default this returns an [ImmediateMultiDragGestureRecognizer] but
  /// subclasses can use this to customize the drag start gesture.
  @protected
  MultiDragGestureRecognizer createRecognizer() {
    return ImmediateMultiDragGestureRecognizer(debugOwner: this);
  }

  void _startDragging(BuildContext context, PointerDownEvent event) {
    final DeviceGestureSettings? gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    final SliverReorderableListState? list = SliverReorderableList.maybeOf(context);
    list?.startItemDragReorder(
      index: index,
      event: event,
      recognizer: createRecognizer()..gestureSettings = gestureSettings,
    );
  }
}

/// A wrapper widget that will recognize the start of a drag operation by
/// looking for a long press event. Once it is recognized, it will start
/// a drag operation on the wrapped item in the reorderable list.
///
/// See also:
///
///  * [ReorderableDragStartListener], a similar wrapper that will
///    recognize the start of the drag immediately after a pointer down event.
///  * [ReorderableList], a widget list that allows the user to reorder
///    its items.
///  * [SliverReorderableList], a sliver list that allows the user to reorder
///    its items.
///  * [ReorderableListView], a Material Design list that allows the user to
///    reorder its items.
class ReorderableDelayedDragStartListener extends ReorderableDragStartListener {
  /// Creates a listener for an drag following a long press event over the
  /// given child widget.
  ///
  /// This is most commonly used to wrap an entire list item in a reorderable
  /// list.
  const ReorderableDelayedDragStartListener({
    super.key,
    required super.child,
    required super.index,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(debugOwner: this);
  }
}

typedef _DragItemUpdate = void Function(_DragInfo item, Offset position, Offset delta);
typedef _DragItemCallback = void Function(_DragInfo item);

class _DragInfo extends Drag {
  _DragInfo({
    required _ReorderableItemState item,
    Offset initialPosition = Offset.zero,
    this.scrollDirection = Axis.vertical,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
    this.onDropCompleted,
    this.proxyDecorator,
    required this.tickerProvider,
  }) {
    assert(debugMaybeDispatchCreated('widgets', '_DragInfo', this));
    final itemRenderBox = item.context.findRenderObject()! as RenderBox;
    listState = item._listState;
    index = item.index;
    child = item.widget.child;
    capturedThemes = item.widget.capturedThemes;
    dragOffset = itemRenderBox.globalToLocal(initialPosition);
    itemSize = item.context.size!;
    _rawDragPosition = initialPosition;
    if (listState.widget.dragBoundaryProvider != null) {
      boundary = listState.widget.dragBoundaryProvider!.call(listState.context);
    } else {
      boundary = DragBoundary.forRectMaybeOf(listState.context);
    }
    dragPosition = _adjustedDragOffset(initialPosition);
    itemExtent = _sizeExtent(itemSize, scrollDirection);
    itemLayoutConstraints = itemRenderBox.constraints;
    scrollable = Scrollable.of(item.context);
  }

  final Axis scrollDirection;
  final _DragItemUpdate? onUpdate;
  final _DragItemCallback? onEnd;
  final _DragItemCallback? onCancel;
  final VoidCallback? onDropCompleted;
  final ReorderItemProxyDecorator? proxyDecorator;
  final TickerProvider tickerProvider;

  late DragBoundaryDelegate<Rect>? boundary;
  late SliverReorderableListState listState;
  late int index;
  late Widget child;
  late Offset dragPosition;
  late Offset dragOffset;
  late Size itemSize;
  late BoxConstraints itemLayoutConstraints;
  late double itemExtent;
  late CapturedThemes capturedThemes;
  ScrollableState? scrollable;
  AnimationController? _proxyAnimation;
  late Offset _rawDragPosition;

  void dispose() {
    assert(debugMaybeDispatchDisposed(this));
    _proxyAnimation?.dispose();
  }

  void startDrag() {
    _proxyAnimation =
        AnimationController(vsync: tickerProvider, duration: const Duration(milliseconds: 250))
          ..addStatusListener((AnimationStatus status) {
            if (status.isDismissed) {
              _dropCompleted();
            }
          })
          ..forward();
  }

  @override
  void update(DragUpdateDetails details) {
    final Offset delta = _restrictAxis(details.delta, scrollDirection);
    _rawDragPosition += delta;
    dragPosition = _adjustedDragOffset(_rawDragPosition);
    onUpdate?.call(this, dragPosition, details.delta);
  }

  @override
  void end(DragEndDetails details) {
    _proxyAnimation!.reverse();
    onEnd?.call(this);
  }

  @override
  void cancel() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onCancel?.call(this);
  }

  Offset _adjustedDragOffset(Offset offset) {
    if (boundary == null) {
      return offset;
    }
    final Offset adjOffset = boundary!
        .nearestPositionWithinBoundary((offset - dragOffset) & itemSize)
        .shift(dragOffset)
        .topLeft;
    return adjOffset;
  }

  void _dropCompleted() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onDropCompleted?.call();
  }

  Widget createProxy(BuildContext context) {
    return capturedThemes.wrap(
      _DragItemProxy(
        listState: listState,
        index: index,
        size: itemSize,
        constraints: itemLayoutConstraints,
        animation: _proxyAnimation!,
        position: dragPosition - dragOffset - _overlayOrigin(context),
        proxyDecorator: proxyDecorator,
        child: child,
      ),
    );
  }
}

Offset _overlayOrigin(BuildContext context) {
  final OverlayState overlay = Overlay.of(context, debugRequiredFor: context.widget);
  final overlayBox = overlay.context.findRenderObject()! as RenderBox;
  return overlayBox.localToGlobal(Offset.zero);
}

class _DragItemProxy extends StatelessWidget {
  const _DragItemProxy({
    required this.listState,
    required this.index,
    required this.child,
    required this.position,
    required this.size,
    required this.constraints,
    required this.animation,
    required this.proxyDecorator,
  });

  final SliverReorderableListState listState;
  final int index;
  final Widget child;
  final Offset position;
  final Size size;
  final BoxConstraints constraints;
  final AnimationController animation;
  final ReorderItemProxyDecorator? proxyDecorator;

  @override
  Widget build(BuildContext context) {
    final Widget proxyChild = proxyDecorator?.call(child, index, animation.view) ?? child;
    final Offset overlayOrigin = _overlayOrigin(context);

    return MediaQuery(
      // Remove the top padding so that any nested list views in the item
      // won't pick up the scaffold's padding in the overlay.
      data: MediaQuery.of(context).removePadding(removeTop: true),
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          Offset effectivePosition = position;
          final Offset? dropPosition = listState._finalDropPosition;
          if (dropPosition != null) {
            effectivePosition = Offset.lerp(
              dropPosition - overlayOrigin,
              effectivePosition,
              Curves.easeOut.transform(animation.value),
            )!;
          }
          return Positioned(
            left: effectivePosition.dx,
            top: effectivePosition.dy,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: OverflowBox(
                minWidth: constraints.minWidth,
                minHeight: constraints.minHeight,
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                alignment: listState._scrollDirection == Axis.horizontal
                    ? Alignment.centerLeft
                    : Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
        child: proxyChild,
      ),
    );
  }
}

double _sizeExtent(Size size, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => size.width,
    Axis.vertical => size.height,
  };
}

Size _extentSize(double extent, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => Size(extent, 0),
    Axis.vertical => Size(0, extent),
  };
}

double _offsetExtent(Offset offset, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => offset.dx,
    Axis.vertical => offset.dy,
  };
}

Offset _extentOffset(double extent, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => Offset(extent, 0.0),
    Axis.vertical => Offset(0.0, extent),
  };
}

Offset _restrictAxis(Offset offset, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => Offset(offset.dx, 0.0),
    Axis.vertical => Offset(0.0, offset.dy),
  };
}

// A global key that takes its identity from the object and uses a value of a
// particular type to identify itself.
//
// The difference with GlobalObjectKey is that it uses [==] instead of [identical]
// of the objects used to generate widgets.
@optionalTypeArgs
class _ReorderableItemGlobalKey extends GlobalObjectKey {
  const _ReorderableItemGlobalKey(this.subKey, this.index, this.state) : super(subKey);

  final Key subKey;
  final int index;
  final SliverReorderableListState state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableItemGlobalKey &&
        other.subKey == subKey &&
        other.index == index &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, index, state);
}

/// A global key for the subtree below a separated item's [_ReorderableItem]
/// wrapper, derived from the item's key and the list state but not the item
/// index.
///
/// [_ReorderableItemGlobalKey] compares the index too, so relocating a keyed
/// item to a new index recreates its wrapper element; this key survives the
/// recreation and reparents the item's subtree into the new wrapper,
/// preserving the item's [State]. It is applied inside
/// [_ReorderableItemState.build] rather than around [_ReorderableItem.child]
/// so that the drag proxy, which builds its own copy of that child in the
/// overlay, never contains the same global key as the in-list subtree.
@optionalTypeArgs
class _ReorderableItemChildGlobalKey extends GlobalObjectKey {
  const _ReorderableItemChildGlobalKey(this.subKey, this.state) : super(subKey);

  final Key subKey;
  final SliverReorderableListState state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableItemChildGlobalKey &&
        other.subKey == subKey &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}

/// A private local key for a separator wrapper, derived from its boundary index
/// alone. Separators are position-fixed and are never dragged into the overlay,
/// so they need neither the global identity nor the overlay state-preservation
/// semantics that items require; a value key by boundary index suffices and
/// avoids the global-key registry overhead and uniqueness constraints. The
/// dedicated subtype lets [SliverReorderableListState._separatedFindChildIndexCallback]
/// recognize separator keys without mistaking them for a user's `ValueKey<int>`.
class _ReorderableSeparatorKey extends ValueKey<int> {
  const _ReorderableSeparatorKey(super.value);
}
