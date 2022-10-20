// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'animated_sliver.dart';
import 'basic.dart';
import 'framework.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scroll_view.dart';
import 'sliver.dart';
import 'ticker_provider.dart';

/// A scrolling container that animates items when they are inserted or removed.
///
/// This widget's [AnimatedListState] can be used to dynamically insert or
/// remove items. To refer to the [AnimatedListState] either provide a
/// [GlobalKey] or use the static [of] method from an item's input callback.
///
/// This widget is similar to one created by [ListView.builder].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ZtfItHwFlZ8}
///
/// {@tool dartpad}
/// This sample application uses an [AnimatedList] to create an effect when
/// items are removed or added to the list.
///
/// ** See code in examples/api/lib/widgets/animated_list/animated_list.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverAnimatedList], a sliver that animates items when they are inserted
///    or removed from a list.
///  * [SliverAnimatedGrid], a sliver which animates items when they are
///    inserted or removed from a grid.
///  * [AnimatedGrid], a non-sliver scrolling container that animates items when
///    they are inserted or removed in a grid.
class AnimatedList extends _AnimatedScrollView {
  /// Creates a scrolling container that animates items when they are inserted
  /// or removed.
  const AnimatedList({
    super.key,
    required super.itemBuilder,
    super.initialItemCount = 0,
    super.scrollDirection = Axis.vertical,
    super.reverse = false,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap = false,
    super.padding,
    super.clipBehavior = Clip.hardEdge,
  }) : assert(itemBuilder != null),
       assert(initialItemCount != null && initialItemCount >= 0);

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [AnimatedList] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [AnimatedList] surrounds the context given, then this function will
  /// assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [maybeOf], a similar function that will return null if no
  ///    [AnimatedList] ancestor is found.
  static AnimatedListState of(BuildContext context) {
    assert(context != null);
    final AnimatedListState? result = context.findAncestorStateOfType<AnimatedListState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('AnimatedList.of() called with a context that does not contain an AnimatedList.'),
          ErrorDescription(
            'No AnimatedList ancestor could be found starting from the context that was passed to AnimatedList.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
                'built the AnimatedList. Please see the AnimatedList documentation for examples '
                'of how to refer to an AnimatedListState object:\n'
                '  https://api.flutter.dev/flutter/widgets/AnimatedListState-class.html',
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
  /// This method is typically used by [AnimatedList] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [AnimatedList] surrounds the context given, then this function will
  /// return null.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [of], a similar function that will throw if no [AnimatedList] ancestor
  ///    is found.
  static AnimatedListState? maybeOf(BuildContext context) {
    assert(context != null);
    return context.findAncestorStateOfType<AnimatedListState>();
  }

  @override
  AnimatedListState createState() => AnimatedListState();
}

/// The state for a scrolling container that animates items when they are
/// inserted or removed.
///
/// When an item is inserted with [insertItem] an animation begins running. The
/// animation is passed to [AnimatedList.itemBuilder] whenever the item's widget
/// is needed.
///
/// When an item is removed with [removeItem] its animation is reversed.
/// The removed item's animation is passed to the [removeItem] builder
/// parameter.
///
/// An app that needs to insert or remove items in response to an event
/// can refer to the [AnimatedList]'s state with a global key:
///
/// ```dart
/// // (e.g. in a stateful widget)
/// GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
///
/// // ...
///
/// @override
/// Widget build(BuildContext context) {
///   return AnimatedList(
///     key: listKey,
///     itemBuilder: (BuildContext context, int index, Animation<double> animation) {
///       return const Placeholder();
///     },
///   );
/// }
///
/// // ...
///
/// void _updateList() {
///   // adds "123" to the AnimatedList
///   listKey.currentState!.insertItem(123);
/// }
/// ```
///
/// [AnimatedList] item input handlers can also refer to their [AnimatedListState]
/// with the static [AnimatedList.of] method.
class AnimatedListState extends _AnimatedScrollViewState<AnimatedList> {
  final GlobalKey<SliverAnimatedListState> _sliverAnimatedListKey = GlobalKey();

  /// Insert an item at [index] and start an animation that will be passed
  /// to [AnimatedList.itemBuilder] when the item is visible.
  ///
  /// This method's semantics are the same as Dart's [List.insert] method:
  /// it increases the length of the list by one and shifts all items at or
  /// after [index] towards the end of the list.
  void insertItem(int index, { Duration?  duration }) {
    _sliverAnimatedListKey.currentState!.insertItem(index, duration: duration);
  }

  /// Remove the item at [index] and start an animation that will be passed
  /// to [builder] when the item is visible.
  ///
  /// Items are removed immediately. After an item has been removed, its index
  /// will no longer be passed to the [AnimatedList.itemBuilder]. However the
  /// item will still appear in the list for [duration] and during that time
  /// [builder] must construct its widget as needed.
  ///
  /// This method's semantics are the same as Dart's [List.remove] method:
  /// it decreases the length of the list by one and shifts all items at or
  /// before [index] towards the beginning of the list.
  void removeItem(int index, AnimatedRemovedItemBuilder builder, { Duration? duration }) {
    _sliverAnimatedListKey.currentState!.removeItem(index, builder, duration: duration);
  }

  @override
  Widget build(BuildContext context) {
    return _wrap(
      SliverAnimatedList(
        key: _sliverAnimatedListKey,
        itemBuilder: widget.itemBuilder,
        initialItemCount: widget.initialItemCount,
      ),
    );
  }
}

/// A scrolling container that animates items when they are inserted or removed
/// in a grid.
///
/// This widget's [AnimatedGridState] can be used to dynamically insert or
/// remove items. To refer to the [AnimatedGridState] either provide a
/// [GlobalKey] or use the static [of] method from an item's input callback.
///
/// This widget is similar to one created by [GridView.builder].
///
/// {@tool dartpad}
/// This sample application uses an [AnimatedGrid] to create an effect when
/// items are removed or added to the grid.
///
/// ** See code in examples/api/lib/widgets/animated_grid/animated_grid.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [SliverAnimatedGrid], a sliver which animates items when they are inserted
///   into or removed from a grid.
/// * [SliverAnimatedList], a sliver which animates items added and removed from
///   a list instead of a grid.
/// * [AnimatedList], which animates items added and removed from a list instead
///   of a grid.
class AnimatedGrid extends _AnimatedScrollView {
  /// Creates a scrolling container that animates items when they are inserted
  /// or removed.
  const AnimatedGrid({
    super.key,
    required super.itemBuilder,
    required this.gridDelegate,
    super.initialItemCount = 0,
    super.scrollDirection = Axis.vertical,
    super.reverse = false,
    super.controller,
    super.primary,
    super.physics,
    super.padding,
    super.clipBehavior = Clip.hardEdge,
  })  : assert(itemBuilder != null),
        assert(initialItemCount != null && initialItemCount >= 0);

  /// {@template flutter.widgets.AnimatedGrid.gridDelegate}
  /// A delegate that controls the layout of the children within the
  /// [AnimatedGrid].
  ///
  /// See also:
  ///
  ///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
  ///    a fixed number of tiles in the cross axis.
  ///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
  ///    tiles that have a maximum cross-axis extent.
  /// {@endtemplate}
  final SliverGridDelegate gridDelegate;

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [AnimatedGrid] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [AnimatedGrid] surrounds the context given, then this function will
  /// assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [maybeOf], a similar function that will return null if no
  ///    [AnimatedGrid] ancestor is found.
  static AnimatedGridState of(BuildContext context) {
    assert(context != null);
    final AnimatedGridState? result = context.findAncestorStateOfType<AnimatedGridState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('AnimatedGrid.of() called with a context that does not contain an AnimatedGrid.'),
          ErrorDescription(
            'No AnimatedGrid ancestor could be found starting from the context that was passed to AnimatedGrid.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the AnimatedGrid. Please see the AnimatedGrid documentation for examples '
            'of how to refer to an AnimatedGridState object:\n'
            '  https://api.flutter.dev/flutter/widgets/AnimatedGridState-class.html',
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
  /// This method is typically used by [AnimatedGrid] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [AnimatedGrid] surrounds the context given, then this function will
  /// return null.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [of], a similar function that will throw if no [AnimatedGrid] ancestor
  ///    is found.
  static AnimatedGridState? maybeOf(BuildContext context) {
    assert(context != null);
    return context.findAncestorStateOfType<AnimatedGridState>();
  }

  @override
  AnimatedGridState createState() => AnimatedGridState();
}

/// The state for a scrolling container that animates items when they are
/// inserted or removed.
///
/// When an item is inserted with [insertItem] an animation begins running. The
/// animation is passed to [AnimatedGrid.itemBuilder] whenever the item's widget
/// is needed.
///
/// When an item is removed with [removeItem] its animation is reversed.
/// The removed item's animation is passed to the [removeItem] builder
/// parameter.
///
/// An app that needs to insert or remove items in response to an event
/// can refer to the [AnimatedGrid]'s state with a global key:
///
/// ```dart
/// // (e.g. in a stateful widget)
/// GlobalKey<AnimatedGridState> gridKey = GlobalKey<AnimatedGridState>();
///
/// // ...
///
/// @override
/// Widget build(BuildContext context) {
///   return AnimatedGrid(
///     key: gridKey,
///     itemBuilder: (BuildContext context, int index, Animation<double> animation) {
///       return const Placeholder();
///     },
///     gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 100.0),
///   );
/// }
///
/// // ...
///
/// void _updateGrid() {
///   // adds "123" to the AnimatedGrid
///   gridKey.currentState!.insertItem(123);
/// }
/// ```
///
/// [AnimatedGrid] item input handlers can also refer to their [AnimatedGridState]
/// with the static [AnimatedGrid.of] method.
class AnimatedGridState extends _AnimatedScrollViewState<AnimatedGrid> {
  final GlobalKey<SliverAnimatedGridState> _sliverAnimatedGridKey = GlobalKey();

  /// Insert an item at [index] and start an animation that will be passed
  /// to [AnimatedGrid.itemBuilder] when the item is visible.
  ///
  /// This method's semantics are the same as Dart's [List.insert] method: it
  /// increases the length of the list of items in the grid by one and shifts
  /// all items at or after [index] towards the end of the list of items in the
  /// grid.
  void insertItem(int index, { Duration? duration }) {
    _sliverAnimatedGridKey.currentState!.insertItem(index, duration: duration);
  }

  /// Remove the item at `index` and start an animation that will be passed to
  /// `builder` when the item is visible.
  ///
  /// Items are removed immediately. After an item has been removed, its index
  /// will no longer be passed to the [AnimatedGrid.itemBuilder]. However, the
  /// item will still appear in the grid for `duration` and during that time
  /// `builder` must construct its widget as needed.
  ///
  /// This method's semantics are the same as Dart's [List.remove] method: it
  /// decreases the length of the list of items in the grid by one and shifts
  /// all items at or before `index` towards the beginning of the list of items
  /// in the grid.
  ///
  /// See also:
  ///
  /// - [AnimatedRemovedItemBuilder], which describes the arguments to the
  ///   `builder` argument.
  void removeItem(int index, AnimatedRemovedItemBuilder builder, { Duration? duration }) {
    _sliverAnimatedGridKey.currentState!.removeItem(index, builder, duration: duration);
  }

  @override
  Widget build(BuildContext context) {
    return _wrap(
      SliverAnimatedGrid(
        key: _sliverAnimatedGridKey,
        gridDelegate: widget.gridDelegate,
        itemBuilder: widget.itemBuilder,
        initialItemCount: widget.initialItemCount,
      ),
    );
  }
}

abstract class _AnimatedScrollView extends StatefulWidget {
  /// Creates a scrolling container that animates items when they are inserted
  /// or removed.
  const _AnimatedScrollView({
    super.key,
    required this.itemBuilder,
    this.initialItemCount = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.clipBehavior = Clip.hardEdge,
  }) : assert(itemBuilder != null),
        assert(initialItemCount != null && initialItemCount >= 0);

  /// {@template flutter.widgets.AnimatedScrollView.itemBuilder}
  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  ///
  /// The [AnimatedItemBuilder] index parameter indicates the item's
  /// position in the list. The value of the index parameter will be between 0
  /// and [initialItemCount] plus the total number of items that have been
  /// inserted with [AnimatedListState.insertItem] and less the total number of
  /// items that have been removed with [AnimatedListState.removeItem].
  ///
  /// Implementations of this callback should assume that
  /// [AnimatedListState.removeItem] removes an item immediately.
  /// {@endtemplate}
  final AnimatedItemBuilder itemBuilder;

  /// {@template flutter.widgets.AnimatedScrollView.initialItemCount}
  /// The number of items the list will start with.
  ///
  /// The appearance of the initial items is not animated. They
  /// are created, as needed, by [itemBuilder] with an animation parameter
  /// of [kAlwaysCompleteAnimation].
  /// {@endtemplate}
  final int initialItemCount;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController? controller;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// On iOS, this identifies the scroll view that will scroll to top in
  /// response to a tap in the status bar.
  ///
  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [controller] is null.
  final bool? primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// If the scroll view does not shrink wrap, then the scroll view will expand
  /// to the maximum allowed size in the [scrollDirection]. If the scroll view
  /// has unbounded constraints in the [scrollDirection], then [shrinkWrap] must
  /// be true.
  ///
  /// Shrink wrapping the content of the scroll view is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// scroll view needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry? padding;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;
}

abstract class _AnimatedScrollViewState<T extends _AnimatedScrollView> extends State<T> with TickerProviderStateMixin {
  Widget _wrap(Widget sliver) {
    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      clipBehavior: widget.clipBehavior,
      slivers: <Widget>[
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: sliver,
        ),
      ],
    );
  }
}
