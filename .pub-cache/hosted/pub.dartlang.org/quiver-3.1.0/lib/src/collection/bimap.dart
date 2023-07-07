// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';

/// A bi-directional map whose key-value pairs form a one-to-one
/// correspondence.  BiMaps support an `inverse` property which gives access to
/// an inverted view of the map, such that there is a mapping (v, k) for each
/// pair (k, v) in the original map. Since a one-to-one key-value invariant
/// applies, it is an error to insert duplicate values into this map.
abstract class BiMap<K, V> implements Map<K, V> {
  /// Creates a BiMap instance with the default implementation.
  factory BiMap() => HashBiMap();

  /// Adds an association between key and value.
  ///
  /// Throws [ArgumentError] if an association involving [value] exists in the
  /// map; otherwise, the association is inserted, overwriting any existing
  /// association for the key.
  @override
  void operator []=(K key, V value);

  /// Replaces any existing associations(s) involving key and value.
  ///
  /// If an association involving [key] or [value] exists in the map, it is
  /// removed.
  void replace(K key, V value);

  /// Returns the inverse of this map, with key-value pairs (v, k) for each pair
  /// (k, v) in this map.
  BiMap<V, K> get inverse;
}

/// A hash-table based implementation of BiMap.
class HashBiMap<K, V> implements BiMap<K, V> {
  HashBiMap() : this._from(HashMap<K, V>(), HashMap<V, K>());
  HashBiMap._from(this._map, this._inverse);

  final Map<K, V> _map;
  final Map<V, K> _inverse;
  BiMap<V, K>? _cached;

  @override
  V? operator [](Object? key) => _map[key];

  @override
  void operator []=(K key, V value) {
    _add(key, value, false);
  }

  @override
  void replace(K key, V value) {
    _add(key, value, true);
  }

  @override
  void addAll(Map<K, V> other) => other.forEach((k, v) => _add(k, v, false));

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  @override
  bool containsValue(Object? value) => _inverse.containsKey(value);

  @override
  void forEach(void f(K key, V value)) => _map.forEach(f);

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Iterable<K> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  Iterable<V> get values => _inverse.keys;

  @override
  BiMap<V, K> get inverse => _cached ??= HashBiMap._from(_inverse, _map);

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    for (final entry in entries) {
      _add(entry.key, entry.value, false);
    }
  }

  @override
  Map<K2, V2> cast<K2, V2>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(K key, V value)) =>
      _map.map(transform);

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) {
      return _map[key]!;
    }
    return _add(key, ifAbsent(), false);
  }

  @override
  V? remove(Object? key) {
    _inverse.remove(_map[key]);
    return _map.remove(key);
  }

  @override
  void removeWhere(bool test(K key, V value)) {
    _inverse.removeWhere((v, k) => test(k, v));
    _map.removeWhere(test);
  }

  @override
  V update(K key, V update(V value), {V ifAbsent()?}) {
    var value = _map[key];
    if (value != null) {
      return _add(key, update(value), true);
    } else {
      if (ifAbsent == null) {
        throw ArgumentError.value(key, 'key', 'Key not in map');
      }
      return _add(key, ifAbsent(), false);
    }
  }

  @override
  void updateAll(V update(K key, V value)) {
    for (final key in keys) {
      _add(key, update(key, _map[key]!), true);
    }
  }

  @override
  void clear() {
    _map.clear();
    _inverse.clear();
  }

  V _add(K key, V value, bool replace) {
    var oldValue = _map[key];
    if (containsKey(key) && oldValue == value) return value;
    if (_inverse.containsKey(value)) {
      if (!replace) throw ArgumentError('Mapping for $value exists');
      _map.remove(_inverse[value]);
    }
    _inverse.remove(oldValue);
    _map[key] = value;
    _inverse[value] = key;
    return value;
  }
}
