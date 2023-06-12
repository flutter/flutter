// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A basic LRU Cache.
class LruCache<K, V> {
  _Link<K, V> _head;
  _Link<K, V> _tail;

  final int Function(V) _computeWeight;

  int _currentWeightTotal = 0;
  final int _individualWeightMax;
  final int _totalWeightMax;

  final _entries = <K, _Link<K, V>>{};

  LruCache(
      this._individualWeightMax, this._totalWeightMax, this._computeWeight);

  V operator [](K key) {
    var entry = _entries[key];
    if (entry == null) return null;

    _promote(entry);
    return entry.value;
  }

  void operator []=(K key, V value) {
    var entry = _Link(key, value, _computeWeight(value));
    // Don't cache at all if above the individual weight max.
    if (entry.weight > _individualWeightMax) {
      return;
    }

    _entries[key] = entry;
    _currentWeightTotal += entry.weight;
    _promote(entry);

    while (_currentWeightTotal > _totalWeightMax) {
      assert(_tail != null);
      remove(_tail.key);
    }
  }

  /// Removes the value at [key] from the cache, and returns the value if it
  /// existed.
  V remove(K key) {
    var entry = _entries[key];
    if (entry == null) return null;

    _currentWeightTotal -= entry.weight;
    _entries.remove(key);

    if (entry == _tail) {
      _tail = entry.next;
      _tail?.previous = null;
    }
    if (entry == _head) {
      _head = entry.previous;
      _head?.next = null;
    }

    return entry.value;
  }

  /// Moves [link] to the [_head] of the list.
  void _promote(_Link<K, V> link) {
    if (link == _head) return;

    if (link == _tail) {
      _tail = link.next;
    }

    if (link.previous != null) {
      link.previous.next = link.next;
    }
    if (link.next != null) {
      link.next.previous = link.previous;
    }

    _head?.next = link;
    link.previous = _head;
    _head = link;
    _tail ??= link;
    link.next = null;
  }
}

/// A [MapEntry] which is also a part of a doubly linked list.
class _Link<K, V> implements MapEntry<K, V> {
  _Link<K, V> next;
  _Link<K, V> previous;

  final int weight;

  @override
  final K key;

  @override
  final V value;

  _Link(this.key, this.value, this.weight);
}
