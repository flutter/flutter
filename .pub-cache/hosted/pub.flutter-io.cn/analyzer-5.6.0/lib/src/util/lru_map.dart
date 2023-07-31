// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/// This handler is notified when an item is evicted from the cache.
typedef EvictionHandler<K, V> = void Function(K key, V value);

/// A hash-table based cache implementation.
///
/// When it reaches the specified number of items, the item that has not been
/// accessed (both get and put) recently is evicted.
class LRUMap<K, V> {
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();
  final int _maxSize;
  final EvictionHandler<K, V>? _handler;

  LRUMap(this._maxSize, [this._handler]);

  /// Returns the value for the given [key] or null if [key] is not
  /// in the cache.
  V? get(K key) {
    V? value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  /// Associates the [key] with the given [value].
  ///
  /// If the cache is full, an item that has not been accessed recently is
  /// evicted.
  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > _maxSize) {
      K evictedKey = _map.keys.first;
      V evictedValue = _map.remove(evictedKey) as V;
      if (_handler != null) {
        _handler!.call(evictedKey, evictedValue);
      }
    }
  }

  /// Removes the association for the given [key].
  void remove(K key) {
    _map.remove(key);
  }
}
