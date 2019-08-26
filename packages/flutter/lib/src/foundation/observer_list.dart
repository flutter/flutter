// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum _ObserverOperationType {
  add,
  remove,
}

class _ObserverOperation<T> {
  _ObserverOperation.add(this.callback) : type = _ObserverOperationType.add;
  _ObserverOperation.remove(this.callback) : type = _ObserverOperationType.remove;

  final _ObserverOperationType type;
  final T callback;
}

typedef ObserverListIterationCallback<T> = void Function(Iterable<T> iterator);

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
    if (_pendingOperations != null) {
      _pendingOperations.add(_ObserverOperation<T>.add(item));
      return;
    }
    _map[item] = (_map[item] ?? 0) + 1;
  }

  /// Removes an item from the list.
  ///
  /// Returns whether the item was present in the list.
  bool remove(T item) {
    if (_pendingOperations != null) {
      _pendingOperations.add(_ObserverOperation<T>.remove(item));
      return _map.containsKey(item);
    }
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

  List<_ObserverOperation<T>> _pendingOperations;
  int _queueModifications = 0;

  /// Allows iteration over the [ObserverList] where it is safe to modify the
  /// list during iteration.
  ///
  /// Any adds/removes that are done on the list during this call are queued
  /// until after the given callback returns, and then they are applied in the
  /// order in which they occurred.
  void safeIteration(ObserverListIterationCallback<T> callback) {
    assert(callback != null);
    _queueModifications++;
    _pendingOperations ??= <_ObserverOperation<T>>[];
    try {
      callback(_map.keys);
    } finally {
      _queueModifications--;
      if (_queueModifications == 0) {
        // Apply all queued operations.
        for (_ObserverOperation<T> operation in _pendingOperations) {
          switch (operation.type) {
            case _ObserverOperationType.add:
              add(operation.callback);
              break;
            case _ObserverOperationType.remove:
              remove(operation.callback);
              break;
          }
        }
        _pendingOperations.clear();
        _pendingOperations = null;
      }
    }
  }

  @override
  bool contains(Object element) => _map.containsKey(element);

  @override
  Iterator<T> get iterator => _map.keys.iterator;

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;
}
