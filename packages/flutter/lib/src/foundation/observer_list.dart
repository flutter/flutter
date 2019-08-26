// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

/// A list optimized for containment queries.
///
/// Consider using an [ObserverList] instead of a [List] when the number of
/// [contains] calls dominates the number of [add] and [remove] calls.
// TODO(ianh): Use DelegatingIterable, possibly moving it from the collection
// package to foundation, or to dart:collection.
class ObserverList<T> extends Iterable<T> {
  final Map<T, int> _map = <T, int>{};

  /// Adds an item to the end of this list.
  void add(T item) {
    _map[item] = (_map[item] ?? 0) + 1;
  }

  /// Removes an item from the list.
  ///
  /// This is O(N) in the number of items in the list.
  ///
  /// Returns whether the item was present in the list.
  bool remove(T item) {
    assert(_map.containsKey(item));
    final int count = _map[item] -= 1;
    if (count == 0) {
      _map.remove(item);
      return true;
    }
    return false;
  }

  @override
  bool contains(Object element) {
    return _map.containsKey(element);
  }

  @override
  Iterator<T> get iterator => _map.keys.iterator;

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;
}
