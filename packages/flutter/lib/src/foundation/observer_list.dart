// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:collection';

/// A list optimized for the observer pattern.
///
/// Consider using an [ObserverList] instead of a [List] when you need a
/// container that can contain multiple copies of the same entry in insertion
/// order, but only returns the first copy inserted when iterating, and is
/// optimized for [add], [remove], and [contains] operations.
///
/// It is O(1) (amortized) for [add], [remove], and [contains] operations.
class ObserverList<T> extends Iterable<T> {
  final LinkedHashMap<T, int> _map = LinkedHashMap<T, int>();

  /// Adds an item to the end of the list.
  ///
  /// Multiple copies of the same item may be inserted, but only the first one
  /// will be returned when iterating over the list.
  void add(T item) {
    _map[item] = (_map[item] ?? 0) + 1;
  }

  /// Removes an item from the list.
  ///
  /// Returns whether the item was present in the list when it was removed.
  ///
  /// If more than one copy of the given item is in the list, then only the
  /// last one is removed.
  ///
  /// The iteration performed by [iterator] will be unchanged until all copies
  /// of the same item are moved (i.e. `remove` is called the same number of
  /// times that add was called for the item).
  bool remove(T item) {
    final int value = _map[item];
    if (value == null) {
      return false;
    }
    if (value == 1) {
      _map.remove(item);
    } else {
      _map[item] = value - 1;
    }
    return true;
  }

  @override
  bool contains(Object element) => _map.containsKey(element);

  /// Returns an iterator that will iterate over the items in the list.
  ///
  /// If there are multiple copies of the same item added to the list, then only
  /// the first copy is visited as part of the iteration.
  @override
  Iterator<T> get iterator => _map.keys.iterator;

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;
}
