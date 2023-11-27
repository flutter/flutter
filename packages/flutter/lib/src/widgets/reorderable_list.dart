// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'debug.dart';
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
import 'sliver_varied_extent_list.dart';
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
/// If [oldIndex] is before [newIndex], removing the item at [oldIndex] from the
/// list will reduce the list's length by one. Implementations will need to
/// account for this when inserting before [newIndex].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=3fB1mxOsqJE}
///
/// {@tool snippet}
///
/// ```dart
/// final List<MyDataObject> backingList = <MyDataObject>[/* ... */];
///
/// void handleReorder(int oldIndex, int newIndex) {
///   if (oldIndex < newIndex) {
///     // removing the item at oldIndex will shorten the list by 1.
///     newIndex -= 1;
///   }
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
typedef ReorderItemProxyDecorator = Widget Function(Widget child, int index, Animation<double> animation);

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
    required this.onReorder,
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
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.autoScrollerVelocityScalar,
  }) : assert(itemCount >= 0),
        assert(
          (itemExtent == null && prototypeItem == null) ||
          (itemExtent == null && itemExtentBuilder == null) ||
          (prototypeItem == null && itemExtentBuilder == null),
          'You can only pass one of itemExtent, prototypeItem and itemExtentBuilder.',
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
  /// {@endtemplate}
  final ReorderCallback onReorder;

  /// {@template flutter.widgets.reorderable_list.onReorderStart}
  /// A callback that is called when an item drag has started.
  ///
  /// The index parameter of the callback is the index of the selected item.
  ///
  /// See also:
  ///
  ///   * [onReorderEnd], which is a called when the dragged item is dropped.
  ///   * [onReorder], which reports that a list item has been dragged to a new
  ///     location.
  /// {@endtemplate}
  final void Function(int index)? onReorderStart;

  /// {@template flutter.widgets.reorderable_list.onReorderEnd}
  /// A callback that is called when the dragged item is dropped.
  ///
  /// The index parameter of the callback is the index where the item is
  /// dropped. Unlike [onReorder], this is called even when the list item is
  /// dropped in the same location.
  ///
  /// See also:
  ///
  ///   * [onReorderStart], which is a called when an item drag has started.
  ///   * [onReorder], which reports that a list item has been dragged to a new
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
  final double? cacheExtent;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  ///
  /// The default is [ScrollViewKeyboardDismissBehavior.manual]
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

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
          ErrorSummary('ReorderableList.of() called with a context that does not contain a ReorderableList.'),
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
///     onReorder: (int oldIndex, int newIndex) {
///        // ...
///     },
///   );
/// }
/// // ...
/// listKey.currentState!.cancelReorder();
/// ```
class ReorderableListState extends State<ReorderableList> {
  final GlobalKey<SliverReorderableListState> _sliverReorderableListKey = GlobalKey();

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
    _sliverReorderableListKey.currentState!.startItemDragReorder(index: index, event: event, recognizer: recognizer);
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
      cacheExtent: widget.cacheExtent,
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
            itemCount: widget.itemCount,
            onReorder: widget.onReorder,
            onReorderStart: widget.onReorderStart,
            onReorderEnd: widget.onReorderEnd,
            proxyDecorator: widget.proxyDecorator,
            autoScrollerVelocityScalar: widget.autoScrollerVelocityScalar,
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
    required this.onReorder,
    this.onReorderStart,
    this.onReorderEnd,
    this.itemExtent,
    this.itemExtentBuilder,
    this.prototypeItem,
    this.proxyDecorator,
    double? autoScrollerVelocityScalar,
  }) : autoScrollerVelocityScalar = autoScrollerVelocityScalar ?? _kDefaultAutoScrollVelocityScalar,
       assert(itemCount >= 0),
       assert(
         (itemExtent == null && prototypeItem == null) ||
         (itemExtent == null && itemExtentBuilder == null) ||
         (prototypeItem == null && itemExtentBuilder == null),
         'You can only pass one of itemExtent, prototypeItem and itemExtentBuilder.',
       );

  // An eyeballed value for a smooth scrolling experience.
  static const double _kDefaultAutoScrollVelocityScalar = 50;

  /// {@macro flutter.widgets.reorderable_list.itemBuilder}
  final IndexedWidgetBuilder itemBuilder;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.findChildIndexCallback}
  final ChildIndexGetter? findChildIndexCallback;

  /// {@macro flutter.widgets.reorderable_list.itemCount}
  final int itemCount;

  /// {@macro flutter.widgets.reorderable_list.onReorder}
  final ReorderCallback onReorder;

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
    final SliverReorderableListState? result = context.findAncestorStateOfType<SliverReorderableListState>();
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
///     onReorder: (int oldIndex, int newIndex) {
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
class SliverReorderableListState extends State<SliverReorderableList> with TickerProviderStateMixin {
  // Map of index -> child state used manage where the dragging item will need
  // to be inserted.
  final Map<int, _ReorderableItemState> _items = <int, _ReorderableItemState>{};

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _DragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer? _recognizer;
  int? _recognizerPointer;
  // To implement the gap for the dragged item, we replace the dragged item
  // with a zero sized box, and then translate all of the later items down
  // by the size of the dragged item. This allows us to keep the order of the
  // list, while still being able to animate the gap between the items. However
  // for the first frame of the drag, the item has not yet been replaced, so
  // the calculation for the gap is off by the size of the gap. This flag is
  // used to determine if the transition to the zero sized box has completed,
  // so the gap calculation can compensate for it.
  bool _dragStartTransitionComplete = false;

  EdgeDraggingAutoScroller? _autoScroller;

  late ScrollableState _scrollable;
  Axis get _scrollDirection => axisDirectionToAxis(_scrollable.axisDirection);
  bool get _reverse =>
    _scrollable.axisDirection == AxisDirection.up ||
    _scrollable.axisDirection == AxisDirection.left;

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

  @override
  void didUpdateWidget(covariant SliverReorderableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
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

  @override
  void dispose() {
    _dragReset();
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

  Drag? _dragStart(Offset position) {
    assert(_dragInfo == null);
    final _ReorderableItemState item = _items[_dragIndex!]!;
    item.dragging = true;
    widget.onReorderStart?.call(_dragIndex!);
    item.rebuild();
    _dragStartTransitionComplete = false;
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      _dragStartTransitionComplete = true;
    });

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

    for (final _ReorderableItemState childItem in _items.values) {
      if (childItem == item || !childItem.mounted) {
        continue;
      }
      childItem.updateForGap(_insertIndex!, _dragInfo!.itemExtent, false, _reverse);
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
    // No changes required if last child is being inserted into the last position.
    if ((_insertIndex! + 1 == _items.length) && _reverse) {
      final RenderBox lastItemRenderBox =  _items[_items.length - 1]!.context.findRenderObject()! as RenderBox;
      final Offset lastItemOffset =  lastItemRenderBox.localToGlobal(Offset.zero);

      // When drag starts, the corresponding element is removed from
      // the list, and moves inside of [ReorderableListState.CustomScrollView],
      // which gives [CustomScrollView] a variable height.
      //
      // So when the element is moved, delta would change accordingly,
      // and since it's the last element,
      // we animate it back to it's position and add it back to the list.
      final double delta = item.itemSize.height;

      setState(() {
        _finalDropPosition = Offset(lastItemOffset.dx, lastItemOffset.dy  - delta);
      });
      return;
    }
    setState(() {
      if (_insertIndex == item.index) {
        _finalDropPosition = _itemOffsetAt(_insertIndex! + (_reverse ? 1 : 0));
      } else if (_insertIndex! < widget.itemCount - 1) {
        // Find the location of the item we want to insert before
        _finalDropPosition = _itemOffsetAt(_insertIndex!);
      } else {
        // Inserting into the last spot on the list. If it's the only spot, put
        // it back where it was. Otherwise, grab the second to last and move
        // down by the gap.
        final int itemIndex = _items.length > 1 ? _insertIndex! - 1 : _insertIndex!;
        if (_reverse) {
          _finalDropPosition = _itemOffsetAt(itemIndex) - _extentOffset(item.itemExtent, _scrollDirection);
        } else {
          _finalDropPosition = _itemOffsetAt(itemIndex) + _extentOffset(item.itemExtent, _scrollDirection);
        }
      }
    });
    widget.onReorderEnd?.call(_insertIndex!);
  }

  void _dropCompleted() {
    final int fromIndex = _dragIndex!;
    final int toIndex = _insertIndex!;
    if (fromIndex != toIndex) {
      widget.onReorder.call(fromIndex, toIndex);
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
    final double proxyItemStart = _offsetExtent(_dragInfo!.dragPosition - _dragInfo!.dragOffset, _scrollDirection);
    final double proxyItemEnd = proxyItemStart + gapExtent;

    // Find the new index for inserting the item being dragged.
    int newIndex = _insertIndex!;
    for (final _ReorderableItemState item in _items.values) {
      if (item.index == _dragIndex! || !item.mounted) {
        continue;
      }

      Rect geometry = item.targetGeometry();
      if (!_dragStartTransitionComplete && _dragIndex! <= item.index) {
        // Transition is not complete, so each item after the dragged item is still
        // in its normal location and not moved up for the zero sized box that will
        // replace the dragged item.
        final Offset transitionOffset = _extentOffset(_reverse ? -gapExtent : gapExtent, _scrollDirection);
        geometry = (geometry.topLeft - transitionOffset) & geometry.size;
      }
      final double itemStart = _scrollDirection == Axis.vertical ? geometry.top : geometry.left;
      final double itemExtent = _scrollDirection == Axis.vertical ? geometry.height : geometry.width;
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
        if (itemStart <= proxyItemStart && proxyItemStart <= itemMiddle) {
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
      for (final _ReorderableItemState item in _items.values) {
        if (item.index == _dragIndex! || !item.mounted) {
          continue;
        }
        item.updateForGap(newIndex, gapExtent, true, _reverse);
      }
    }
  }

  Rect get _dragTargetRect {
    final Offset origin = _dragInfo!.dragPosition - _dragInfo!.dragOffset;
    return Rect.fromLTWH(origin.dx, origin.dy, _dragInfo!.itemSize.width, _dragInfo!.itemSize.height);
  }

  Offset _itemOffsetAt(int index) {
    final RenderBox itemRenderBox =  _items[index]!.context.findRenderObject()! as RenderBox;
    return itemRenderBox.localToGlobal(Offset.zero);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (_dragInfo != null && index >= widget.itemCount) {
      switch (_scrollDirection) {
        case Axis.horizontal:
          return SizedBox(width: _dragInfo!.itemExtent);
        case Axis.vertical:
          return SizedBox(height: _dragInfo!.itemExtent);
      }
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
    void reorder(int startIndex, int endIndex) {
      if (startIndex != endIndex) {
        widget.onReorder(startIndex, endIndex);
      }
    }

    // First, determine which semantics actions apply.
    final Map<CustomSemanticsAction, VoidCallback> semanticsActions = <CustomSemanticsAction, VoidCallback>{};

    // Create the appropriate semantics actions.
    void moveToStart() => reorder(index, 0);
    void moveToEnd() => reorder(index, widget.itemCount);
    void moveBefore() => reorder(index, index - 1);
    // To move after, go to index+2 because it is moved to the space
    // before index+2, which is after the space at index+1.
    void moveAfter() => reorder(index, index + 2);

    final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
    final bool isHorizontal = _scrollDirection == Axis.horizontal;
    // If the item can move to before its current position in the list.
    if (index > 0) {
      semanticsActions[CustomSemanticsAction(label: localizations.reorderItemToStart)] = moveToStart;
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
    return Semantics(
      container: true,
      customSemanticsActions: semanticsActions,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    final SliverChildBuilderDelegate childrenDelegate = SliverChildBuilderDelegate(
      _itemBuilder,
      // When dragging, the dragged item is still in the list but has been replaced
      // by a zero height SizedBox, so that the gap can move around. To make the
      // list extent stable we add a dummy entry to the end.
      childCount: widget.itemCount + (_dragInfo != null ? 1 : 0),
      findChildIndexCallback: widget.findChildIndexCallback,
    );
    if (widget.itemExtent != null) {
      return SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: widget.itemExtent!,
      );
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
    required Key key,
    required this.index,
    required this.child,
    required this.capturedThemes,
  }) : super(key: key);

  final int index;
  final Widget child;
  final CapturedThemes capturedThemes;

  @override
  _ReorderableItemState createState() => _ReorderableItemState();
}

class _ReorderableItemState extends State<_ReorderableItem> {
  late SliverReorderableListState _listState;

  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  AnimationController? _offsetAnimation;

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
    _offsetAnimation?.dispose();
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
      return const SizedBox();
    }
    _listState._registerItem(this);
    return Transform(
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0),
      child: widget.child,
    );
  }

  @override
  void deactivate() {
    _listState._unregisterItem(index, this);
    super.deactivate();
  }

  Offset get offset {
    if (_offsetAnimation != null) {
      final double animValue = Curves.easeInOut.transform(_offsetAnimation!.value);
      return Offset.lerp(_startOffset, _targetOffset, animValue)!;
    }
    return _targetOffset;
  }

  void updateForGap(int gapIndex, double gapExtent, bool animate, bool reverse) {
    final Offset newTargetOffset = (gapIndex <= index)
        ? _extentOffset(reverse ? -gapExtent : gapExtent, _listState._scrollDirection)
        : Offset.zero;
    if (newTargetOffset != _targetOffset) {
      _targetOffset = newTargetOffset;
      if (animate) {
        if (_offsetAnimation == null) {
          _offsetAnimation = AnimationController(
            vsync: _listState,
            duration: const Duration(milliseconds: 250),
          )
            ..addListener(rebuild)
            ..addStatusListener((AnimationStatus status) {
              if (status == AnimationStatus.completed) {
                _startOffset = _targetOffset;
                _offsetAnimation!.dispose();
                _offsetAnimation = null;
              }
            })
            ..forward();
        } else {
          _startOffset = offset;
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

  Rect targetGeometry() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition = itemRenderBox.localToGlobal(Offset.zero) + _targetOffset;
    return itemPosition & itemRenderBox.size;
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
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
      recognizer: createRecognizer()
        ..gestureSettings = gestureSettings,
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
    final RenderBox itemRenderBox = item.context.findRenderObject()! as RenderBox;
    listState = item._listState;
    index = item.index;
    child = item.widget.child;
    capturedThemes = item.widget.capturedThemes;
    dragPosition = initialPosition;
    dragOffset = itemRenderBox.globalToLocal(initialPosition);
    itemSize = item.context.size!;
    itemExtent = _sizeExtent(itemSize, scrollDirection);
    scrollable = Scrollable.of(item.context);
  }

  final Axis scrollDirection;
  final _DragItemUpdate? onUpdate;
  final _DragItemCallback? onEnd;
  final _DragItemCallback? onCancel;
  final VoidCallback? onDropCompleted;
  final ReorderItemProxyDecorator? proxyDecorator;
  final TickerProvider tickerProvider;

  late SliverReorderableListState listState;
  late int index;
  late Widget child;
  late Offset dragPosition;
  late Offset dragOffset;
  late Size itemSize;
  late double itemExtent;
  late CapturedThemes capturedThemes;
  ScrollableState? scrollable;
  AnimationController? _proxyAnimation;

  void dispose() {
    _proxyAnimation?.dispose();
  }

  void startDrag() {
    _proxyAnimation = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 250),
    )
    ..addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        _dropCompleted();
      }
    })
    ..forward();
  }

  @override
  void update(DragUpdateDetails details) {
    final Offset delta = _restrictAxis(details.delta, scrollDirection);
    dragPosition += delta;
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
  final RenderBox overlayBox = overlay.context.findRenderObject()! as RenderBox;
  return overlayBox.localToGlobal(Offset.zero);
}

class _DragItemProxy extends StatelessWidget {
  const _DragItemProxy({
    required this.listState,
    required this.index,
    required this.child,
    required this.position,
    required this.size,
    required this.animation,
    required this.proxyDecorator,
  });

  final SliverReorderableListState listState;
  final int index;
  final Widget child;
  final Offset position;
  final Size size;
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
            effectivePosition = Offset.lerp(dropPosition - overlayOrigin, effectivePosition, Curves.easeOut.transform(animation.value))!;
          }
          return Positioned(
            left: effectivePosition.dx,
            top: effectivePosition.dy,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          );
        },
        child: proxyChild,
      ),
    );
  }
}

double _sizeExtent(Size size, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return size.width;
    case Axis.vertical:
      return size.height;
  }
}

double _offsetExtent(Offset offset, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return offset.dx;
    case Axis.vertical:
      return offset.dy;
  }
}

Offset _extentOffset(double extent, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return Offset(extent, 0.0);
    case Axis.vertical:
      return Offset(0.0, extent);
  }
}

Offset _restrictAxis(Offset offset, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return Offset(offset.dx, 0.0);
    case Axis.vertical:
      return Offset(0.0, offset.dy);
  }
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
    return other is _ReorderableItemGlobalKey
        && other.subKey == subKey
        && other.index == index
        && other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, index, state);
}
