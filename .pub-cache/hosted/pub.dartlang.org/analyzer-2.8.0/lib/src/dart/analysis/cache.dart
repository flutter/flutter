// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// LRU cache of objects.
class Cache<K, V> {
  final int _maxSizeBytes;
  final int Function(V) _meter;

  final _map = <K, V>{};
  int _currentSizeBytes = 0;

  Cache(this._maxSizeBytes, this._meter);

  V? get(K key, V? Function() getNotCached) {
    V? value = _map.remove(key);
    if (value == null) {
      value = getNotCached();
      if (value != null) {
        _map[key] = value;
        _currentSizeBytes += _meter(value);
        _evict();
      }
    } else {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    V? oldValue = _map[key];
    if (oldValue != null) {
      _currentSizeBytes -= _meter(oldValue);
    }
    _map[key] = value;
    _currentSizeBytes += _meter(value);
    _evict();
  }

  void _evict() {
    if (_currentSizeBytes > _maxSizeBytes) {
      var keysToRemove = <K>[];
      for (var entry in _map.entries) {
        keysToRemove.add(entry.key);
        _currentSizeBytes -= _meter(entry.value);
        if (_currentSizeBytes <= _maxSizeBytes) {
          break;
        }
      }
      for (var key in keysToRemove) {
        _map.remove(key);
      }
    }
  }
}
