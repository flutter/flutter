// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'combined_iterable.dart';

/// Returns a new map that represents maps flattened into a single map.
///
/// All methods and accessors treat the new map as-if it were a single
/// concatenated map, but the underlying implementation is based on lazily
/// accessing individual map instances. In the occasion where a key occurs in
/// multiple maps the first value is returned.
///
/// The resulting map has an index operator (`[]`) that is `O(maps)`, rather
/// than `O(1)`, and the map is unmodifiable, but underlying changes to these
/// maps are still accessible from the resulting map.
///
/// The `length` getter is `O(M)` where M is the total number of entries in
/// all maps, since it has to remove duplicate entries.
class CombinedMapView<K, V> extends UnmodifiableMapBase<K, V> {
  final Iterable<Map<K, V>> _maps;

  /// Create a new combined view of multiple maps.
  ///
  /// The iterable is accessed lazily so it should be collection type like
  /// [List] or [Set] rather than a lazy iterable produced by `map()` et al.
  CombinedMapView(this._maps);

  @override
  V? operator [](Object? key) {
    for (var map in _maps) {
      // Avoid two hash lookups on a positive hit.
      var value = map[key];
      if (value != null || map.containsKey(value)) {
        return value;
      }
    }
    return null;
  }

  /// The keys of [this].
  ///
  /// The returned iterable has efficient `contains` operations, assuming the
  /// iterables returned by the wrapped maps have efficient `contains` operations
  /// for their `keys` iterables.
  ///
  /// The `length` must do deduplication and thus is not optimized.
  ///
  /// The order of iteration is defined by the individual `Map` implementations,
  /// but must be consistent between changes to the maps.
  ///
  /// Unlike most [Map] implementations, modifying an individual map while
  /// iterating the keys will _sometimes_ throw. This behavior may change in
  /// the future.
  @override
  Iterable<K> get keys => _DeduplicatingIterableView(
      CombinedIterableView(_maps.map((m) => m.keys)));
}

/// A view of an iterable that skips any duplicate entries.
class _DeduplicatingIterableView<T> extends IterableBase<T> {
  final Iterable<T> _iterable;

  const _DeduplicatingIterableView(this._iterable);

  @override
  Iterator<T> get iterator => _DeduplicatingIterator(_iterable.iterator);

  // Special cased contains/isEmpty since many iterables have an efficient
  // implementation instead of running through the entire iterator.
  //
  // Note: We do not do this for `length` because we have to remove the
  // duplicates.

  @override
  bool contains(Object? element) => _iterable.contains(element);

  @override
  bool get isEmpty => _iterable.isEmpty;
}

/// An iterator that wraps another iterator and skips duplicate values.
class _DeduplicatingIterator<T> implements Iterator<T> {
  final Iterator<T> _iterator;

  final _emitted = HashSet<T>();

  _DeduplicatingIterator(this._iterator);

  @override
  T get current => _iterator.current;

  @override
  bool moveNext() {
    while (_iterator.moveNext()) {
      if (_emitted.add(current)) {
        return true;
      }
    }
    return false;
  }
}
