// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// LRU cache of objects.
class Cache<K, V> {
  final int _maxSizeBytes;
  final int Function(V) _meter;

  @visibleForTesting
  final map = <K, V>{};
  int _currentSizeBytes = 0;

  Cache(this._maxSizeBytes, this._meter);

  V? get(K key) {
    final value = map.remove(key);
    if (value != null) {
      map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    V? oldValue = map[key];
    if (oldValue != null) {
      _currentSizeBytes -= _meter(oldValue);
    }
    map[key] = value;
    _currentSizeBytes += _meter(value);
    _evict();
  }

  void _evict() {
    if (_currentSizeBytes > _maxSizeBytes) {
      var keysToRemove = <K>[];
      for (var entry in map.entries) {
        keysToRemove.add(entry.key);
        _currentSizeBytes -= _meter(entry.value);
        if (_currentSizeBytes <= _maxSizeBytes) {
          break;
        }
      }
      for (var key in keysToRemove) {
        map.remove(key);
      }
    }
  }
}
