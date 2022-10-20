// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'sliver.dart';
import 'ticker_provider.dart';

/// Signature for the builder callback used by [AnimatedList].
///
/// This is deprecated, use the identical [AnimatedItemBuilder] instead.
@Deprecated(
  'Use AnimatedItemBuilder instead. '
  'This feature was deprecated after v3.5.0-4.0.pre.',
)
typedef AnimatedListItemBuilder = Widget Function(BuildContext context, int index, Animation<double> animation);

/// Signature for the builder callback used by [AnimatedList] & [AnimatedGrid] to
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

/// Signature for the builder callback used by [AnimatedListState.removeItem].
///
/// This is deprecated, use the identical [AnimatedRemovedItemBuilder]
/// instead.
@Deprecated(
  'Use AnimatedRemovedItemBuilder instead. '
  'This feature was deprecated after v3.5.0-4.0.pre.',
)
typedef AnimatedListRemovedItemBuilder = Widget Function(BuildContext context, Animation<double> animation);

/// Signature for the builder callback used in [AnimatedList.removeItem] &
/// [AnimatedGrid.removeItem] to animated their children after they have
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

// Incoming and outgoing animated items.
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

/// A [SliverList] that animates items when they are inserted or removed.
///
/// This widget's [SliverAnimatedListState] can be used to dynamically insert or
/// remove items. To refer to the [SliverAnimatedListState] either provide a
/// [GlobalKey] or use the static [SliverAnimatedList.of] method from an item's
/// input callback.
///
/// {@tool dartpad}
/// This sample application uses a [SliverAnimatedList] to create an animated
/// effect when items are removed or added to the list.
///
/// ** See code in examples/api/lib/widgets/animated_list/sliver_animated_list.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverList], which does not animate items when they are inserted or
///    removed.
///  * [AnimatedList], a non-sliver scrolling container that animates items when
///    they are inserted or removed.
///  * [SliverAnimatedGrid], a sliver which animates items when they are
///    inserted into or removed from a grid.
///  * [AnimatedGrid], a non-sliver scrolling container that animates items when
///    they are inserted into or removed from a grid.
class SliverAnimatedList extends _SliverAnimatedMultiBoxAdaptor {
  /// Creates a [SliverList] that animates items when they are inserted or
  /// removed.
  const SliverAnimatedList({
    super.key,
    required super.itemBuilder,
    super.findChildIndexCallback,
    super.initialItemCount = 0,
  }) : assert(itemBuilder != null),
       assert(initialItemCount != null && initialItemCount >= 0);

  @override
  SliverAnimatedListState createState() => SliverAnimatedListState();

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [SliverAnimatedList] item widgets that
  /// insert or remove items in response to user input.
  ///
  /// If no [SliverAnimatedList] surrounds the context given, then this function
  /// will assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [maybeOf], a similar function that will return null if no
  ///    [SliverAnimatedList] ancestor is found.
  static SliverAnimatedListState of(BuildContext context) {
    assert(context != null);
    final SliverAnimatedListState? result = context.findAncestorStateOfType<SliverAnimatedListState>();
    assert(() {
      if (result == null) {
        throw FlutterError(
          'SliverAnimatedList.of() called with a context that does not contain a SliverAnimatedList.\n'
          'No SliverAnimatedListState ancestor could be found starting from the '
          'context that was passed to SliverAnimatedListState.of(). This can '
          'happen when the context provided is from the same StatefulWidget that '
          'built the AnimatedList. Please see the SliverAnimatedList documentation '
          'for examples of how to refer to an AnimatedListState object: '
          'https://api.flutter.dev/flutter/widgets/SliverAnimatedListState-class.html\n'
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
  /// This method is typically used by [SliverAnimatedList] item widgets that
  /// insert or remove items in response to user input.
  ///
  /// If no [SliverAnimatedList] surrounds the context given, then this function
  /// will return null.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [of], a similar function that will throw if no [SliverAnimatedList]
  ///    ancestor is found.
  static SliverAnimatedListState? maybeOf(BuildContext context) {
    assert(context != null);
    return context.findAncestorStateOfType<SliverAnimatedListState>();
  }
}

/// The state for a [SliverAnimatedList] that animates items when they are
/// inserted or removed.
///
/// When an item is inserted with [insertItem] an animation begins running. The
/// animation is passed to [SliverAnimatedList.itemBuilder] whenever the item's
/// widget is needed.
///
/// When an item is removed with [removeItem] its animation is reversed.
/// The removed item's animation is passed to the [removeItem] builder
/// parameter.
///
/// An app that needs to insert or remove items in response to an event
/// can refer to the [SliverAnimatedList]'s state with a global key:
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
/// [SliverAnimatedList] item input handlers can also refer to their
/// [SliverAnimatedListState] with the static [SliverAnimatedList.of] method.
class SliverAnimatedListState extends _SliverAnimatedMultiBoxAdaptorState<SliverAnimatedList> {

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: _createDelegate(),
    );
  }
}

/// A [SliverGrid] that animates items when they are inserted or removed.
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
class SliverAnimatedGrid extends _SliverAnimatedMultiBoxAdaptor {
  /// Creates a [SliverGrid] that animates items when they are inserted or
  /// removed.
  const SliverAnimatedGrid({
    super.key,
    required super.itemBuilder,
    required this.gridDelegate,
    super.findChildIndexCallback,
    super.initialItemCount = 0,
  })  : assert(itemBuilder != null),
        assert(initialItemCount != null && initialItemCount >= 0);

  @override
  SliverAnimatedGridState createState() => SliverAnimatedGridState();

  /// {@macro flutter.widgets.AnimatedGrid.gridDelegate}
  final SliverGridDelegate gridDelegate;

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

/// The state for a [SliverAnimatedGrid] that animates items when they are
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
class SliverAnimatedGridState extends _SliverAnimatedMultiBoxAdaptorState<SliverAnimatedGrid> {

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: widget.gridDelegate,
      delegate: _createDelegate(),
    );
  }
}

abstract class _SliverAnimatedMultiBoxAdaptor extends StatefulWidget {
  /// Creates a sliver that animates items when they are inserted or removed.
  const _SliverAnimatedMultiBoxAdaptor({
    super.key,
    required this.itemBuilder,
    this.findChildIndexCallback,
    this.initialItemCount = 0,
  })  : assert(itemBuilder != null),
        assert(initialItemCount != null && initialItemCount >= 0);

  /// {@macro flutter.widgets.AnimatedScrollView.itemBuilder}
  final AnimatedItemBuilder itemBuilder;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.findChildIndexCallback}
  final ChildIndexGetter? findChildIndexCallback;

  /// {@macro flutter.widgets.AnimatedScrollView.initialItemCount}
  final int initialItemCount;
}

abstract class _SliverAnimatedMultiBoxAdaptorState<T extends _SliverAnimatedMultiBoxAdaptor> extends State<T> with TickerProviderStateMixin {

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

  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  _ActiveItem? _removeActiveItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items.removeAt(i);
  }

  _ActiveItem? _activeItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items[i];
  }

  // The insertItem() and removeItem() index parameters are defined as if the
  // removeItem() operation removed the corresponding list entry immediately.
  // The entry is only actually removed from the ListView when the remove animation
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

  /// Insert an item at [index] and start an animation that will be passed to
  /// [SliverAnimatedGrid.itemBuilder] or [SliverAnimatedList.itemBuilder] when
  /// the item is visible.
  ///
  /// This method's semantics are the same as Dart's [List.insert] method: it
  /// increases the length of the list of items in the grid by one and shifts
  /// all items at or after [index] towards the end of the list of items in the
  /// grid.
  void insertItem(int index, {Duration? duration}) {
    duration ??= _kDuration;

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
  /// will no longer be passed to the subclass' [SliverAnimatedGrid.itemBuilder]
  /// or [SliverAnimatedList.itemBuilder]. However the item will still appear
  /// for [duration], and during that time [builder] must construct its widget
  /// as needed.
  ///
  /// This method's semantics are the same as Dart's [List.remove] method: it
  /// decreases the length of the list of items in the grid by one and shifts
  /// all items at or before [index] towards the beginning of the list of items
  /// in the grid.
  void removeItem(int index, AnimatedRemovedItemBuilder builder, {Duration? duration}) {
    duration ??= _kDuration;

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
}
