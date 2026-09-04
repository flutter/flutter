// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter_test/flutter_test.dart';
///
/// @docImport 'card.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icons.dart';
import 'material.dart';
import 'theme.dart';

/// A list whose items the user can interactively reorder by dragging.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=3fB1mxOsqJE}
///
/// This sample shows by dragging the user can reorder the items of the list.
/// The [onReorderItem] parameter will be called when a child
/// widget is dragged to a new position.
///
/// {@tool dartpad}
///
/// ** See code in examples/api/lib/material/reorderable_list/reorderable_list_view.0.dart **
/// {@end-tool}
///
/// By default, on [TargetPlatformVariant.desktop] platforms each item will
/// have a drag handle added on top of it that will allow the user to grab it
/// to move the item. On [TargetPlatformVariant.mobile], no drag handle will be
/// added, but when the user long presses anywhere on the item it will start
/// moving the item. Displaying drag handles can be controlled with
/// [ReorderableListView.buildDefaultDragHandles].
///
/// All list items must have a key.
///
/// This example demonstrates using the [ReorderableListView.proxyDecorator] callback
/// to customize the appearance of a list item while it's being dragged.
///
/// {@tool dartpad}
/// While a drag is underway, the widget returned by the [ReorderableListView.proxyDecorator]
/// callback serves as a "proxy" (a substitute) for the item in the list. The proxy is
/// created with the original list item as its child. The [ReorderableListView.proxyDecorator]
/// callback in this example is similar to the default one except that it changes the
/// proxy item's background color.
///
/// ** See code in examples/api/lib/material/reorderable_list/reorderable_list_view.1.dart **
/// {@end-tool}
///
/// This example demonstrates using the [ReorderableListView.proxyDecorator] callback to
/// customize the appearance of a [Card] while it's being dragged.
///
/// {@tool dartpad}
/// The default [proxyDecorator] wraps the dragged item in a [Material] widget and animates
/// its elevation. This example demonstrates how to use the [ReorderableListView.proxyDecorator]
/// callback to update the dragged card elevation without inserted a new [Material] widget.
///
/// ** See code in examples/api/lib/material/reorderable_list/reorderable_list_view.2.dart **
/// {@end-tool}
class ReorderableListView extends StatefulWidget {
  /// Creates a reorderable list from a pre-built list of widgets.
  ///
  /// This constructor is appropriate for lists with a small number of
  /// children because constructing the [List] requires doing work for every
  /// child that could possibly be displayed in the list view instead of just
  /// those children that are actually visible.
  ///
  /// See also:
  ///
  ///   * [ReorderableListView.builder], which allows you to build a reorderable
  ///     list where the items are built as needed when scrolling the list.
  ReorderableListView({
    super.key,
    required List<Widget> children,
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
    this.buildDefaultDragHandles = true,
    this.padding,
    this.header,
    this.footer,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
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
    this.mouseCursor,
  }) : assert(
         (itemExtent == null && prototypeItem == null) ||
             (itemExtent == null && itemExtentBuilder == null) ||
             (prototypeItem == null && itemExtentBuilder == null),
         'You can only pass one of itemExtent, prototypeItem and itemExtentBuilder.',
       ),
       assert(
         children.every((Widget w) => w.key != null),
         'All children of this widget must have a key.',
       ),
       assert(
         (onReorderItem != null && onReorder == null) ||
             (onReorderItem == null && onReorder != null),
         'The onReorder callback is obsolete and is replaced by onReorderItem. '
         'Remove the onReorder callback when both callbacks are provided.',
       ),
       itemBuilder = ((BuildContext context, int index) => children[index]),
       itemCount = children.length,
       _separatorBuilder = null,
       _findItemIndexCallback = null;

  /// Creates a reorderable list from widget items that are created on demand.
  ///
  /// This constructor is appropriate for list views with a large number of
  /// children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// The `itemBuilder` callback will be called only with indices greater than
  /// or equal to zero and less than `itemCount`.
  ///
  /// The `itemBuilder` should always return a non-null widget, and actually
  /// create the widget instances when called. Avoid using a builder that
  /// returns a previously-constructed widget; if the list view's children are
  /// created in advance, or all at once when the [ReorderableListView] itself
  /// is created, it is more efficient to use the [ReorderableListView]
  /// constructor. Even more efficient, however, is to create the instances
  /// on demand using this constructor's `itemBuilder` callback.
  ///
  /// This example creates a list using the
  /// [ReorderableListView.builder] constructor. Using the [IndexedWidgetBuilder], The
  /// list items are built lazily on demand.
  /// {@tool dartpad}
  ///
  /// ** See code in examples/api/lib/material/reorderable_list/reorderable_list_view.reorderable_list_view_builder.0.dart **
  /// {@end-tool}
  /// See also:
  ///
  ///   * [ReorderableListView], which allows you to build a reorderable
  ///     list with all the items passed into the constructor.
  const ReorderableListView.builder({
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
    this.buildDefaultDragHandles = true,
    this.padding,
    this.header,
    this.footer,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
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
    this.mouseCursor,
  }) : _separatorBuilder = null,
       _findItemIndexCallback = null,
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

  /// Creates a reorderable list where the items and the separators between
  /// them are created on demand.
  ///
  /// This constructor is appropriate for separated list views with a large
  /// number of items, and mirrors [ListView.separated]: [itemCount] counts
  /// data items only, and the separator built for boundary index `j` appears
  /// between the items built for indices `j` and `j + 1`.
  ///
  /// The [itemBuilder] is called with item indices in the range `0` to
  /// `itemCount - 1`, and every item it returns must have a unique key, just
  /// like the other [ReorderableListView] constructors.
  ///
  /// The `separatorBuilder` is called with boundary indices in the range `0`
  /// to `itemCount - 2`. Separators do not need a key, never receive a default
  /// drag handle, and cannot start a reorder. They appear only between items:
  /// no separator is created before the first item or after the last item, so
  /// none appears next to [header] or [footer].
  /// {@macro flutter.widgets.reorderable_list.separated.positionBasedSeparators}
  ///
  /// Only the dragged item appears in the drag proxy, so [proxyDecorator]
  /// receives an item-only child and size; no separator is measured or
  /// decorated by it.
  /// {@macro flutter.widgets.reorderable_list.separated.dragBehavior}
  /// See [SliverReorderableList.separated], which implements this behavior,
  /// for details.
  ///
  /// [onReorderItem] reports the reorder using item indices: `newIndex` is
  /// already adjusted for the removal of the item at `oldIndex`, so it is
  /// always in the range `0` to `itemCount - 1` and is the final index of the
  /// moved item.
  ///
  /// The `findItemIndexCallback` matches the parameter of the same name on
  /// [ListView.separated]: it receives the original item keys (the keys of the
  /// widgets returned by [itemBuilder]) and must return the item's logical
  /// index in the range `0` to `itemCount - 1`, or null for an unknown key.
  /// It operates purely in item-index space, unlike
  /// [SliverChildBuilderDelegate.findChildIndexCallback], whose delegate child
  /// indices also count separators.
  /// {@macro flutter.widgets.reorderable_list.separated.statePreservation}
  ///
  /// The `onReorder` and `cacheExtent` parameters are intentionally
  /// unavailable on this constructor; it accepts [onReorderItem] and
  /// [scrollCacheExtent] only. The `itemExtent`, `itemExtentBuilder`, and
  /// `prototypeItem` options are also unavailable, because a single
  /// item-extent policy cannot describe alternating, heterogeneous items and
  /// separators.
  ///
  /// {@tool dartpad}
  /// This example builds a reorderable list of [ListTile]s whose separators are
  /// chosen by boundary index rather than by the items around them, so the
  /// thicker dividers stay on the even boundaries however the items are
  /// reordered. Every separator stays visible while an item is dragged: the
  /// insertion gap opens between the two separators that will surround the item
  /// when it is dropped.
  ///
  /// ** See code in examples/api/lib/material/reorderable_list/reorderable_list_view.separated.0.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///   * [ReorderableListView.builder], which builds a reorderable list
  ///     without separators.
  ///   * [ListView.separated], which is the non-reorderable equivalent of this
  ///     constructor.
  const ReorderableListView.separated({
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
    this.buildDefaultDragHandles = true,
    this.padding,
    this.header,
    this.footer,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    this.scrollCacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.autoScrollerVelocityScalar,
    this.dragBoundaryProvider,
    this.mouseCursor,
  }) : _separatorBuilder = separatorBuilder,
       _findItemIndexCallback = findItemIndexCallback,
       onReorder = null,
       cacheExtent = null,
       itemExtent = null,
       itemExtentBuilder = null,
       prototypeItem = null,
       assert(itemCount >= 0);

  /// The builder used to build separators between items. Non-null only for the
  /// [ReorderableListView.separated] constructor; the other constructors leave
  /// it null so their widget trees and timing are unchanged.
  final IndexedWidgetBuilder? _separatorBuilder;

  /// The finder used to map an original item key to its logical item index for
  /// the separated constructor. See [ReorderableListView.separated].
  final ChildIndexGetter? _findItemIndexCallback;

  /// {@macro flutter.widgets.reorderable_list.itemBuilder}
  final IndexedWidgetBuilder itemBuilder;

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
  final void Function(int index)? onReorderStart;

  /// {@macro flutter.widgets.reorderable_list.onReorderEnd}
  final void Function(int index)? onReorderEnd;

  /// {@macro flutter.widgets.reorderable_list.proxyDecorator}
  final ReorderItemProxyDecorator? proxyDecorator;

  /// If true: on desktop platforms, a drag handle is stacked over the
  /// center of each item's trailing edge; on mobile platforms, a long
  /// press anywhere on the item starts a drag.
  ///
  /// The default desktop drag handle is just an [Icons.drag_handle]
  /// wrapped by a [ReorderableDragStartListener]. On mobile
  /// platforms, the entire item is wrapped with a
  /// [ReorderableDelayedDragStartListener].
  ///
  /// To change the appearance or the layout of the drag handles, make
  /// this parameter false and wrap each list item, or a widget within
  /// each list item, with [ReorderableDragStartListener] or
  /// [ReorderableDelayedDragStartListener], or a custom subclass
  /// of [ReorderableDragStartListener].
  ///
  /// The following sample specifies `buildDefaultDragHandles: false`, and
  /// uses a [Card] at the leading edge of each item for the item's drag handle.
  ///
  /// {@tool dartpad}
  ///
  ///
  /// ** See code in examples/api/lib/material/reorderable_list/reorderable_list_view.build_default_drag_handles.0.dart **
  /// {@end-tool}
  final bool buildDefaultDragHandles;

  /// {@macro flutter.widgets.reorderable_list.padding}
  final EdgeInsets? padding;

  /// A non-reorderable header item to show before the items of the list.
  ///
  /// If null, no header will appear before the list.
  final Widget? header;

  /// A non-reorderable footer item to show after the items of the list.
  ///
  /// If null, no footer will appear after the list.
  final Widget? footer;

  /// {@macro flutter.widgets.scroll_view.scrollDirection}
  final Axis scrollDirection;

  /// {@macro flutter.widgets.scroll_view.reverse}
  final bool reverse;

  /// {@macro flutter.widgets.scroll_view.controller}
  final ScrollController? scrollController;

  /// {@macro flutter.widgets.scroll_view.primary}

  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [scrollController] is null.
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

  /// {@macro flutter.widgets.reorderable_list.dragBoundaryProvider}
  final ReorderDragBoundaryProvider? dragBoundaryProvider;

  /// The cursor for a mouse pointer when it enters or is hovering over the drag
  /// handle.
  ///
  /// If [mouseCursor] is a [WidgetStateMouseCursor],
  /// [WidgetStateProperty.resolve] is used for the following [WidgetState]s:
  ///
  ///  * [WidgetState.dragged].
  ///
  /// If this property is null, [SystemMouseCursors.grab] will be used when
  ///  hovering, and [SystemMouseCursors.grabbing] when dragging.
  final MouseCursor? mouseCursor;

  @override
  State<ReorderableListView> createState() => _ReorderableListViewState();
}

class _ReorderableListViewState extends State<ReorderableListView> {
  final ValueNotifier<bool> _dragging = ValueNotifier<bool>(false);

  Widget _itemBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);
    assert(() {
      if (item.key == null) {
        throw FlutterError('Every item of ReorderableListView must have a key.');
      }
      return true;
    }());

    final Key itemGlobalKey = _ReorderableListViewChildGlobalKey(item.key!, this);

    if (widget.buildDefaultDragHandles) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.linux:
        case TargetPlatform.windows:
        case TargetPlatform.macOS:
          final dragHandle = ListenableBuilder(
            listenable: _dragging,
            builder: (BuildContext context, Widget? child) {
              final MouseCursor effectiveMouseCursor = WidgetStateProperty.resolveAs<MouseCursor>(
                widget.mouseCursor ??
                    const WidgetStateMouseCursor.fromMap(<WidgetStatesConstraint, MouseCursor>{
                      WidgetState.dragged: SystemMouseCursors.grabbing,
                      WidgetState.any: SystemMouseCursors.grab,
                    }),
                <WidgetState>{if (_dragging.value) WidgetState.dragged},
              );
              return MouseRegion(cursor: effectiveMouseCursor, child: child);
            },
            child: const Icon(Icons.drag_handle),
          );
          switch (widget.scrollDirection) {
            case Axis.horizontal:
              return Stack(
                key: itemGlobalKey,
                children: <Widget>[
                  item,
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    start: 0,
                    end: 0,
                    bottom: 8,
                    child: Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: ReorderableDragStartListener(index: index, child: dragHandle),
                    ),
                  ),
                ],
              );
            case Axis.vertical:
              return Stack(
                key: itemGlobalKey,
                children: <Widget>[
                  item,
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: 0,
                    bottom: 0,
                    end: 8,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ReorderableDragStartListener(index: index, child: dragHandle),
                    ),
                  ),
                ],
              );
          }

        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          return ReorderableDelayedDragStartListener(key: itemGlobalKey, index: index, child: item);
      }
    }

    return KeyedSubtree(key: itemGlobalKey, child: item);
  }

  /// Unwraps the private key that [_itemBuilder] adds around every item before
  /// invoking the user's `findItemIndexCallback`, so user code only ever sees
  /// original item keys. Unknown keys map to null.
  int? _findItemIndex(Key key) {
    assert(
      widget._findItemIndexCallback != null,
      'Only forwarded to the sliver when the user supplied a callback.',
    );
    if (key is! _ReorderableListViewChildGlobalKey) {
      return null;
    }
    return widget._findItemIndexCallback!(key.subKey);
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(elevation: elevation, child: child);
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _dragging.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasOverlay(context));

    // If there is a header or footer we can't just apply the padding to the list,
    // so we break it up into padding for the header, footer and padding for the list.
    final EdgeInsets padding = widget.padding ?? EdgeInsets.zero;
    double? start = widget.header == null ? null : 0.0;
    double? end = widget.footer == null ? null : 0.0;
    if (widget.reverse) {
      (start, end) = (end, start);
    }

    final EdgeInsets startPadding, endPadding, listPadding;
    (startPadding, endPadding, listPadding) = switch (widget.scrollDirection) {
      Axis.horizontal ||
      Axis.vertical when (start ?? end) == null => (EdgeInsets.zero, EdgeInsets.zero, padding),
      Axis.horizontal => (
        padding.copyWith(left: 0),
        padding.copyWith(right: 0),
        padding.copyWith(left: start, right: end),
      ),
      Axis.vertical => (
        padding.copyWith(top: 0),
        padding.copyWith(bottom: 0),
        padding.copyWith(top: start, bottom: end),
      ),
    };
    final (EdgeInsets headerPadding, EdgeInsets footerPadding) = widget.reverse
        ? (startPadding, endPadding)
        : (endPadding, startPadding);

    final ScrollCacheExtent? scrollCacheExtent =
        widget.scrollCacheExtent ??
        (widget.cacheExtent == null ? null : ScrollCacheExtent.pixels(widget.cacheExtent!));

    void handleReorderStart(int index) {
      _dragging.value = true;
      widget.onReorderStart?.call(index);
    }

    void handleReorderEnd(int index) {
      _dragging.value = false;
      widget.onReorderEnd?.call(index);
    }

    final IndexedWidgetBuilder? separatorBuilder = widget._separatorBuilder;

    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.scrollController,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      anchor: widget.anchor,
      scrollCacheExtent: scrollCacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      // Only the separated path reports a semantic child count: its sliver's
      // children include separators, which are not semantic list items, so
      // accessibility scrolling needs the dense item-only count. The other
      // constructors deliberately leave it unset.
      semanticChildCount: separatorBuilder == null ? null : widget.itemCount,
      slivers: <Widget>[
        if (widget.header != null)
          SliverPadding(
            padding: headerPadding,
            sliver: SliverToBoxAdapter(child: widget.header),
          ),
        SliverPadding(
          padding: listPadding,
          sliver: separatorBuilder == null
              ? SliverReorderableList(
                  itemBuilder: _itemBuilder,
                  itemExtent: widget.itemExtent,
                  itemExtentBuilder: widget.itemExtentBuilder,
                  prototypeItem: widget.prototypeItem,
                  itemCount: widget.itemCount,
                  onReorder: widget.onReorder,
                  onReorderItem: widget.onReorderItem,
                  onReorderStart: handleReorderStart,
                  onReorderEnd: handleReorderEnd,
                  proxyDecorator: widget.proxyDecorator ?? _proxyDecorator,
                  autoScrollerVelocityScalar: widget.autoScrollerVelocityScalar,
                  dragBoundaryProvider: widget.dragBoundaryProvider,
                )
              : SliverReorderableList.separated(
                  itemBuilder: _itemBuilder,
                  separatorBuilder: separatorBuilder,
                  itemCount: widget.itemCount,
                  onReorderItem: widget.onReorderItem!,
                  // Forward the unwrapping wrapper only when the user supplied
                  // a callback: a null here keeps the sliver's relocation
                  // lookup disabled exactly as if no callback existed.
                  findItemIndexCallback: widget._findItemIndexCallback == null
                      ? null
                      : _findItemIndex,
                  onReorderStart: handleReorderStart,
                  onReorderEnd: handleReorderEnd,
                  proxyDecorator: widget.proxyDecorator ?? _proxyDecorator,
                  autoScrollerVelocityScalar: widget.autoScrollerVelocityScalar,
                  dragBoundaryProvider: widget.dragBoundaryProvider,
                ),
        ),
        if (widget.footer != null)
          SliverPadding(
            padding: footerPadding,
            sliver: SliverToBoxAdapter(child: widget.footer),
          ),
      ],
    );
  }
}

// A global key that takes its identity from the object and uses a value of a
// particular type to identify itself.
//
// The difference with GlobalObjectKey is that it uses [==] instead of [identical]
// of the objects used to generate widgets.
@optionalTypeArgs
class _ReorderableListViewChildGlobalKey extends GlobalObjectKey {
  const _ReorderableListViewChildGlobalKey(this.subKey, this.state) : super(subKey);

  final Key subKey;
  final State state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableListViewChildGlobalKey &&
        other.subKey == subKey &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}
