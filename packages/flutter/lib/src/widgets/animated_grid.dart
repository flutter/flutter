// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scroll_view.dart';
import 'sliver.dart';
import 'ticker_provider.dart';

/// Signature for the builder callback used by widgets like [AnimatedGrid] to
/// build their animated children.
///
/// The `context` argument is the build context where the widget will be
/// created, the `index` is the index of the item to be built, and the
/// `animation` is an [Animation] that should be used to animate an entry
/// transition for the widget that is built.
///
/// See also:
///
/// * [AnimatedRemovedItemBuilder], a builder that is for removing items with
///   animations instead of adding them.
typedef AnimatedItemBuilder = Widget Function(BuildContext context, int index, Animation<double> animation);

/// Signature for the builder callback used by widgets like [AnimatedGrid] (in
/// [AnimatedGridState.removeItem]) to animated their children after they have
/// been removed.
///
/// The `context` argument is the build context where the widget will be
/// created, and the `animation` is an [Animation] that should be used to
/// animate an exit transition for the widget that is built.
///
/// See also:
///
/// * [AnimatedItemBuilder], a builder that is for adding items with animations
///   instead of removing them.
typedef AnimatedRemovedItemBuilder = Widget Function(BuildContext context, Animation<double> animation);

// The default insert/remove animation duration.
const Duration _kDuration = Duration(milliseconds: 300);

// Incoming and outgoing AnimatedGrid items.
class _ActiveItem implements Comparable<_ActiveItem> {
  _ActiveItem.incoming(this.controller, this.itemIndex) : removedItemBuilder = null;
  _ActiveItem.outgoing(this.controller, this.itemIndex, this.removedItemBuilder);
  _ActiveItem.index(this.itemIndex)
      : controller = null,
        removedItemBuilder = null;

  final AnimationController? controller;
  final AnimatedRemovedItemBuilder? removedItemBuilder;
  int itemIndex;

  @override
  int compareTo(_ActiveItem other) => itemIndex - other.itemIndex;
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
class AnimatedGrid extends StatefulWidget {
  /// Creates a scrolling container that animates items when they are inserted
  /// or removed.
  const AnimatedGrid({
    super.key,
    required this.itemBuilder,
    required this.gridDelegate,
    this.initialItemCount = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.padding,
    this.clipBehavior = Clip.hardEdge,
  })  : assert(itemBuilder != null),
        assert(initialItemCount != null && initialItemCount >= 0);

  /// Called, as needed, to build grid item widgets.
  ///
  /// Grid items are only built when they're scrolled into view.
  ///
  /// The [AnimatedItemBuilder] index parameter indicates the item's position in
  /// the grid. The value of the index parameter will be between 0 and
  /// [initialItemCount] plus the total number of items that have been inserted
  /// with [AnimatedGridState.insertItem] and less the total number of items
  /// that have been removed with [AnimatedGridState.removeItem].
  ///
  /// Implementations of this callback should assume that
  /// [AnimatedGridState.removeItem] removes an item immediately.
  final AnimatedItemBuilder itemBuilder;

  /// A delegate that controls the layout of the children within the
  /// [AnimatedGrid].
  ///
  /// See also:
  ///
  ///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
  ///    a fixed number of tiles in the cross axis.
  ///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
  ///    tiles that have a maximum cross-axis extent.
  final SliverGridDelegate gridDelegate;

  /// {@template flutter.widgets.AnimatedGrid.initialItemCount}
  /// The number of items the grid will start with.
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

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry? padding;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

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
class AnimatedGridState extends State<AnimatedGrid> with TickerProviderStateMixin<AnimatedGrid> {
  final GlobalKey<SliverAnimatedGridState> _sliverAnimatedGridKey = GlobalKey();

  /// Insert an item at [index] and start an animation that will be passed
  /// to [AnimatedGrid.itemBuilder] when the item is visible.
  ///
  /// This method's semantics are the same as Dart's [List.insert] method: it
  /// increases the length of the list of items in the grid by one and shifts
  /// all items at or after [index] towards the end of the list of items in the
  /// grid.
  void insertItem(int index, {Duration duration = _kDuration}) {
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
  void removeItem(int index, AnimatedRemovedItemBuilder builder, {Duration duration = _kDuration}) {
    _sliverAnimatedGridKey.currentState!.removeItem(index, builder, duration: duration);
  }

  @override
  Widget build(BuildContext context) {
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
          sliver: SliverAnimatedGrid(
            key: _sliverAnimatedGridKey,
            gridDelegate: widget.gridDelegate,
            itemBuilder: widget.itemBuilder,
            initialItemCount: widget.initialItemCount,
          ),
        ),
      ],
    );
  }
}

/// A sliver that animates items when they are inserted or removed in a grid.
///
/// This widget's [SliverAnimatedGridState] can be used to dynamically insert or
/// remove items. To refer to the [SliverAnimatedGridState] either provide a
/// [GlobalKey] or use the static [SliverAnimatedGrid.of] method from an item's
/// input callback.
///
/// {@tool dartpad}
/// This sample application uses a [SliverAnimatedGrid] to create an animated
/// effect when items are removed or added to the grid.
///
/// ** See code in examples/api/lib/widgets/animated_grid/sliver_animated_grid.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedGrid], a non-sliver scrolling container that animates items when
///    they are inserted into or removed from a grid.
///  * [SliverGrid], which does not animate items when they are inserted or
///    removed from a grid.
///  * [SliverList], which displays a non-animated list of items.
///  * [SliverAnimatedList], which animates items added and removed from a list
///    instead of a grid.
class SliverAnimatedGrid extends StatefulWidget {
  /// Creates a sliver that animates items when they are inserted or removed.
  const SliverAnimatedGrid({
    super.key,
    required this.itemBuilder,
    required this.gridDelegate,
    this.findChildIndexCallback,
    this.initialItemCount = 0,
  })  : assert(itemBuilder != null),
        assert(initialItemCount != null && initialItemCount >= 0);

  /// Called, as needed, to build grid item widgets.
  ///
  /// Grid items are only built when they're scrolled into view.
  ///
  /// The [AnimatedItemBuilder] index parameter indicates the item's position in
  /// the grid. The value of the index parameter will be between 0 and
  /// [initialItemCount] plus the total number of items that have been inserted
  /// with [SliverAnimatedGridState.insertItem] and less the total number of
  /// items that have been removed with [SliverAnimatedGridState.removeItem].
  ///
  /// Implementations of this callback should assume that
  /// [SliverAnimatedGridState.removeItem] removes an item immediately.
  final AnimatedItemBuilder itemBuilder;

  /// A delegate that controls the layout of the children within the
  /// [SliverAnimatedGrid].
  ///
  /// See also:
  ///
  ///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
  ///    a fixed number of tiles in the cross axis.
  ///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
  ///    tiles that have a maximum cross-axis extent.
  final SliverGridDelegate gridDelegate;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.findChildIndexCallback}
  final ChildIndexGetter? findChildIndexCallback;

  /// {@macro flutter.widgets.AnimatedGrid.initialItemCount}
  final int initialItemCount;

  @override
  SliverAnimatedGridState createState() => SliverAnimatedGridState();

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [SliverAnimatedGrid] item widgets that
  /// insert or remove items in response to user input.
  ///
  /// If no [SliverAnimatedGrid] surrounds the context given, then this function
  /// will assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [maybeOf], a similar function that will return null if no
  ///    [SliverAnimatedGrid] ancestor is found.
  static SliverAnimatedGridState of(BuildContext context) {
    assert(context != null);
    final SliverAnimatedGridState? result = context.findAncestorStateOfType<SliverAnimatedGridState>();
    assert(() {
      if (result == null) {
        throw FlutterError(
          'SliverAnimatedGrid.of() called with a context that does not contain a SliverAnimatedGrid.\n'
          'No SliverAnimatedGridState ancestor could be found starting from the '
          'context that was passed to SliverAnimatedGridState.of(). This can '
          'happen when the context provided is from the same StatefulWidget that '
          'built the AnimatedGrid. Please see the SliverAnimatedGrid documentation '
          'for examples of how to refer to an AnimatedGridState object: '
          'https://api.flutter.dev/flutter/widgets/SliverAnimatedGridState-class.html\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return result!;
  }

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [SliverAnimatedGrid] item widgets that
  /// insert or remove items in response to user input.
  ///
  /// If no [SliverAnimatedGrid] surrounds the context given, then this function
  /// will return null.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [of], a similar function that will throw if no [SliverAnimatedGrid]
  ///    ancestor is found.
  static SliverAnimatedGridState? maybeOf(BuildContext context) {
    assert(context != null);
    return context.findAncestorStateOfType<SliverAnimatedGridState>();
  }
}

/// The state for a sliver that animates items when they are
/// inserted or removed.
///
/// When an item is inserted with [insertItem] an animation begins running. The
/// animation is passed to [SliverAnimatedGrid.itemBuilder] whenever the item's
/// widget is needed.
///
/// When an item is removed with [removeItem] its animation is reversed.
/// The removed item's animation is passed to the [removeItem] builder
/// parameter.
///
/// An app that needs to insert or remove items in response to an event
/// can refer to the [SliverAnimatedGrid]'s state with a global key:
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
/// [SliverAnimatedGrid] item input handlers can also refer to their
/// [SliverAnimatedGridState] with the static [SliverAnimatedGrid.of] method.
class SliverAnimatedGridState extends State<SliverAnimatedGrid> with TickerProviderStateMixin {
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  @override
  void initState() {
    super.initState();
    _itemsCount = widget.initialItemCount;
  }

  @override
  void dispose() {
    for (final _ActiveItem item in _incomingItems.followedBy(_outgoingItems)) {
      item.controller!.dispose();
    }
    super.dispose();
  }

  _ActiveItem? _removeActiveItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items.removeAt(i);
  }

  _ActiveItem? _activeItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items[i];
  }

  // The insertItem() and removeItem() index parameters are defined as if the
  // removeItem() operation removed the corresponding grid entry immediately.
  // The entry is only actually removed from the grid when the remove animation
  // finishes. The entry is added to _outgoingItems when removeItem is called
  // and removed from _outgoingItems when the remove animation finishes.

  int _indexToItemIndex(int index) {
    int itemIndex = index;
    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex <= itemIndex) {
        itemIndex += 1;
      } else {
        break;
      }
    }
    return itemIndex;
  }

  int _itemIndexToIndex(int itemIndex) {
    int index = itemIndex;
    for (final _ActiveItem item in _outgoingItems) {
      assert(item.itemIndex != itemIndex);
      if (item.itemIndex < itemIndex) {
        index -= 1;
      } else {
        break;
      }
    }
    return index;
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(
      _itemBuilder,
      childCount: _itemsCount,
      findChildIndexCallback: widget.findChildIndexCallback == null
          ? null
          : (Key key) {
              final int? index = widget.findChildIndexCallback!(key);
              return index != null ? _indexToItemIndex(index) : null;
            },
    );
  }

  /// Insert an item at [index] and start an animation that will be passed to
  /// [SliverAnimatedGrid.itemBuilder] when the item is visible.
  ///
  /// This method's semantics are the same as Dart's [List.insert] method: it
  /// increases the length of the list of items in the grid by one and shifts
  /// all items at or after [index] towards the end of the list of items in the
  /// grid.
  void insertItem(int index, {Duration duration = _kDuration}) {
    assert(index != null && index >= 0);
    assert(duration != null);

    final int itemIndex = _indexToItemIndex(index);
    assert(itemIndex >= 0 && itemIndex <= _itemsCount);

    // Increment the incoming and outgoing item indices to account
    // for the insertion.
    for (final _ActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex) {
        item.itemIndex += 1;
      }
    }
    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex >= itemIndex) {
        item.itemIndex += 1;
      }
    }

    final AnimationController controller = AnimationController(
      duration: duration,
      vsync: this,
    );
    final _ActiveItem incomingItem = _ActiveItem.incoming(
      controller,
      itemIndex,
    );
    setState(() {
      _incomingItems
        ..add(incomingItem)
        ..sort();
      _itemsCount += 1;
    });

    controller.forward().then<void>((_) {
      _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!.controller!.dispose();
    });
  }

  /// Remove the item at [index] and start an animation that will be passed
  /// to [builder] when the item is visible.
  ///
  /// Items are removed immediately. After an item has been removed, its index
  /// will no longer be passed to the [SliverAnimatedGrid.itemBuilder]. However
  /// the item will still appear in the grid for [duration] and during that time
  /// [builder] must construct its widget as needed.
  ///
  /// This method's semantics are the same as Dart's [List.remove] method: it
  /// decreases the length of the list of items in the grid by one and shifts
  /// all items at or before [index] towards the beginning of the list of items
  /// in the grid.
  void removeItem(int index, AnimatedRemovedItemBuilder builder, {Duration duration = _kDuration}) {
    assert(index != null && index >= 0);
    assert(builder != null);
    assert(duration != null);

    final int itemIndex = _indexToItemIndex(index);
    assert(itemIndex >= 0 && itemIndex < _itemsCount);
    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    final _ActiveItem? incomingItem = _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller =
        incomingItem?.controller ?? AnimationController(duration: duration, value: 1.0, vsync: this);
    final _ActiveItem outgoingItem = _ActiveItem.outgoing(controller, itemIndex, builder);
    setState(() {
      _outgoingItems
        ..add(outgoingItem)
        ..sort();
    });

    controller.reverse().then<void>((void value) {
      _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex)!.controller!.dispose();

      // Decrement the incoming and outgoing item indices to account
      // for the removal.
      for (final _ActiveItem item in _incomingItems) {
        if (item.itemIndex > outgoingItem.itemIndex) {
          item.itemIndex -= 1;
        }
      }
      for (final _ActiveItem item in _outgoingItems) {
        if (item.itemIndex > outgoingItem.itemIndex) {
          item.itemIndex -= 1;
        }
      }

      setState(() => _itemsCount -= 1);
    });
  }

  Widget _itemBuilder(BuildContext context, int itemIndex) {
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null) {
      return outgoingItem.removedItemBuilder!(
        context,
        outgoingItem.controller!.view,
      );
    }

    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, itemIndex);
    final Animation<double> animation = incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    return widget.itemBuilder(
      context,
      _itemIndexToIndex(itemIndex),
      animation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: widget.gridDelegate,
      delegate: _createDelegate(),
    );
  }
}
