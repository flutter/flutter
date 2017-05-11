// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

/// A list optimized for containment queries.
///
/// Consider using an [ObserverList] instead of a [List] when the number of
/// [contains] calls dominates the number of [add] and [remove] calls.
class ObserverList<T> extends Iterable<T> {
  final List<T> _list = <T>[];
  bool _isDirty = false;
  HashSet<T> _set;

  /// Adds an item to the end of this list.
  ///
  /// The given item must not already be in the list.
  void add(T item) {
    _isDirty = true;
    _list.add(item);
  }

  /// Removes an item from the list.
  ///
  /// Returns whether the item was present in the list.
  bool remove(T item) {
    _isDirty = true;
    return _list.remove(item);
  }

  @override
  bool contains(Object item) {
    if (_list.length < 3)
      return _list.contains(item);

    if (_isDirty) {
      if (_set == null) {
        _set = new HashSet<T>.from(_list);
      } else {
        _set.clear();
        _set.addAll(_list);
      }
      _isDirty = false;
    }

    return _set.contains(item);
  }

  @override
  Iterator<T> get iterator => _list.iterator;
}
