// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'scroll_view.dart';
import 'ticker_provider.dart';

typedef Widget AnimatedListItemBuilder(BuildContext context, int index, Animation<double> animation);
typedef Widget AnimatedListRemovedItemBuilder(BuildContext context, Animation<double> animation);
typedef void AnimatedListInitialItemsBuilder(AnimatedListState list);

// The default insert/remove animation duration.
const Duration _kDuration = const Duration(milliseconds: 3000);

class _ActiveItem implements Comparable<_ActiveItem> {
  _ActiveItem.incoming(this.controller, this.itemIndex) : removedItemBuilder = null;
  _ActiveItem.outgoing(this.controller, this.itemIndex, this.removedItemBuilder);

  final AnimationController controller;
  final AnimatedListRemovedItemBuilder removedItemBuilder;
  int itemIndex;

  @override
  int compareTo(_ActiveItem other) => itemIndex - other.itemIndex;
}

/// A scrolling container that animates items when they are inserted or removed.
///
/// This widget's [AnimatedListState] can be used to insert or remove items. To
/// refer to the [AnimatedListState] either provide a [GlobalKey] or use
/// the static [of] method from a item's input callback.
class AnimatedList extends StatefulWidget {
  AnimatedList({ Key key,  this.itemBuilder, this.initialItemCount: 0 }) : super(key: key) {
    assert(itemBuilder != null);
    assert(initialItemCount != null && initialItemCount >= 0);
  }

  final AnimatedListItemBuilder itemBuilder;
  final int initialItemCount;

  // TBD: explain that this is typically used by List item handlers that want to refer to the list.
  static AnimatedListState of(BuildContext context, { bool nullOk: false }) {
    assert(nullOk != null);
    assert(context != null);
    final AnimatedListState result = context.ancestorStateOfType(const TypeMatcher<AnimatedListState>());
    if (nullOk || result != null)
      return result;
    throw new FlutterError(
      'AnimatedList.of() called with a context that does not contain a AnimatedList.\n'
      'No AnimatedList ancestor could be found starting from the context that was passed to AnimatedList.of(). '
      'This can happen when the context provided is from the same StatefulWidget that '
      'built the AnimatedList. Please see the AnimatedList documentation for examples '
      'of how to refer to an AnimatedListState object: '
      '  https://docs.flutter.io/flutter/widgets/AnimatedState-class.html\n'
      'The context used was:\n'
      '  $context'
    );
  }

  @override
  AnimatedListState createState() => new AnimatedListState();
}

class AnimatedListState extends State<AnimatedList> with TickerProviderStateMixin {
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
    for (_ActiveItem item in _incomingItems)
      item.controller.dispose();
    for (_ActiveItem item in _outgoingItems)
      item.controller.dispose();
    super.dispose();
  }

  _ActiveItem _removeActiveItemAt(List<_ActiveItem> items, int itemIndex) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].itemIndex == itemIndex)
        return items.removeAt(i);
    }
    return null;
  }

  _ActiveItem _activeItemAt(List<_ActiveItem> items, int itemIndex) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].itemIndex == itemIndex)
        return items[i];
    }
    return null;
  }

  // The insertItem() and removeItem() index parameters are defined as if the
  // removeItem() operation removed the corresponding list entry immediately.
  // The entry is only actually removed from the ListView when the remove animation
  // finishes. The entry is added to _outgoingItems when removeItem is called
  // and removed from _outgoingItems when the remove animation finishes.

  int _indexToItemIndex(int index) {
    int itemIndex = index;
    for (_ActiveItem item in _outgoingItems) {
      if (item.itemIndex <= itemIndex)
        itemIndex += 1;
      else
        break;
    }
    return itemIndex;
  }

  int _itemIndexToIndex(int itemIndex) {
    int index = itemIndex;
    for (_ActiveItem item in _outgoingItems) {
      assert(item.itemIndex != itemIndex);
      if (item.itemIndex < itemIndex)
        index -= 1;
      else
        break;
    }
    return index;
  }

  void insertItem(int index, { Duration duration: _kDuration }) {
    assert(index != null && index >= 0);
    assert(duration != null);

    final int itemIndex = _indexToItemIndex(index);
    assert(itemIndex >= 0 && itemIndex <= _itemsCount);

    // Increment the incoming and outgoing item indices to account
    // for the insertion.
    for (_ActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex)
        item.itemIndex += 1;
    }
    for (_ActiveItem item in _outgoingItems) {
      if (item.itemIndex >= itemIndex)
        item.itemIndex += 1;
    }

    final AnimationController controller = new AnimationController(duration: duration, vsync: this);
    final _ActiveItem incomingItem = new _ActiveItem.incoming(controller, itemIndex);
    _incomingItems
      ..add(incomingItem)
      ..sort();

    setState(() {
      _itemsCount += 1;
    });

    controller.forward().then((Null value) {
      _removeActiveItemAt(_incomingItems, incomingItem.itemIndex).controller.dispose();
    });
  }

  void removeItem(int index, AnimatedListRemovedItemBuilder builder, { Duration duration: _kDuration }) {
    assert(index != null && index >= 0);
    assert(duration != null);

    final int itemIndex = _indexToItemIndex(index);
    assert(itemIndex >= 0 && itemIndex < _itemsCount);
    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    final _ActiveItem incomingItem = _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.controller
      ?? new AnimationController(duration: duration, value: 1.0, vsync: this);
    final _ActiveItem outgoingItem = new _ActiveItem.outgoing(controller, itemIndex, builder);
    _outgoingItems
      ..add(outgoingItem)
      ..sort();

    controller.reverse().then((Null value) {
      _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex).controller.dispose();

      for (_ActiveItem item in _incomingItems) {
        if (item.itemIndex > outgoingItem.itemIndex)
          item.itemIndex -= 1;
      }
      for (_ActiveItem item in _outgoingItems) {
        if (item.itemIndex > outgoingItem.itemIndex)
          item.itemIndex -= 1;
      }

      setState(() {
        _itemsCount -= 1;
      });
    });
  }

  Widget _itemBuilder(BuildContext context, int itemIndex) {
    final _ActiveItem outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null)
      return outgoingItem.removedItemBuilder(context, outgoingItem.controller.view);

    final _ActiveItem incomingItem = _activeItemAt(_incomingItems, itemIndex);
    final Animation<double> animation = incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    return widget.itemBuilder(context, _itemIndexToIndex(itemIndex), animation);
  }

  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      itemBuilder: _itemBuilder,
      itemCount: _itemsCount,
    );
  }
}
