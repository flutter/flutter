// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../map.dart';

/// The Built Collection builder for [BuiltMap].
///
/// It implements the mutating part of the [Map] interface.
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
class MapBuilder<K, V> {
  /// Used by [_createMap] to instantiate [_map]. The default value is `null`.
  _MapFactory<K, V>? _mapFactory;
  late Map<K, V> _map;
  _BuiltMap<K, V>? _mapOwner;

  /// Instantiates with elements from a [Map] or [BuiltMap].
  factory MapBuilder([map = const {}]) {
    return MapBuilder<K, V>._uninitialized()..replace(map);
  }

  /// Converts to a [BuiltMap].
  ///
  /// The `MapBuilder` can be modified again and used to create any number
  /// of `BuiltMap`s.
  BuiltMap<K, V> build() {
    _mapOwner ??= _BuiltMap<K, V>.withSafeMap(_mapFactory, _map);
    return _mapOwner!;
  }

  /// Applies a function to `this`.
  void update(Function(MapBuilder<K, V> builder) updates) {
    updates(this);
  }

  /// Replaces all elements with elements from a [Map] or [BuiltMap].
  void replace(Object map) {
    if (map is _BuiltMap<K, V> && map._mapFactory == _mapFactory) {
      _setOwner(map);
    } else if (map is BuiltMap) {
      var replacement = _createMap();
      map.forEach((dynamic key, dynamic value) {
        replacement[key as K] = value as V;
      });
      _setSafeMap(replacement);
    } else if (map is Map) {
      var replacement = _createMap();
      map.forEach((dynamic key, dynamic value) {
        replacement[key as K] = value as V;
      });
      _setSafeMap(replacement);
    } else {
      throw ArgumentError('expected Map or BuiltMap, got ${map.runtimeType}');
    }
  }

  /// Uses `base` as the collection type for all maps created by this builder.
  ///
  ///     // Iterates over elements in ascending order.
  ///     new MapBuilder<int, String>()
  ///       ..withBase(() => new SplayTreeMap<int, String>());
  ///
  ///     // Uses custom equality.
  ///     new MapBuilder<int, String>()
  ///       ..withBase(() => new LinkedHashMap<int, String>(
  ///           equals: (int a, int b) => a % 255 == b % 255,
  ///           hashCode: (int n) => (n % 255).hashCode));
  ///
  /// The map returned by `base` must be empty, mutable, and each call must
  /// instantiate and return a new object.
  ///
  /// Use [withDefaultBase] to reset `base` to the default value.
  void withBase(_MapFactory<K, V> base) {
    ArgumentError.checkNotNull(base, 'base');
    _mapFactory = base;
    _setSafeMap(_createMap()..addAll(_map));
  }

  /// As [withBase], but sets `base` back to the default value, which
  /// instantiates `Map<K, V>`.
  void withDefaultBase() {
    _mapFactory = null;
    _setSafeMap(_createMap()..addAll(_map));
  }

  /// As [Map.fromIterable] but adds.
  ///
  /// [key] and [value] default to the identity function.
  void addIterable<T>(Iterable<T> iterable,
      {K Function(T)? key, V Function(T)? value}) {
    key ??= (T x) => x as K;
    value ??= (T x) => x as V;
    for (var element in iterable) {
      this[key(element)] = value(element);
    }
  }

  // Based on Map.

  /// As [Map].
  V? operator [](Object? key) => _map[key];

  /// As [Map].
  void operator []=(K key, V value) {
    _checkKey(key);
    _checkValue(value);
    _safeMap[key] = value;
  }

  /// As [Map.length].
  int get length => _map.length;

  /// As [Map.isEmpty].
  bool get isEmpty => _map.isEmpty;

  /// As [Map.isNotEmpty].
  bool get isNotEmpty => _map.isNotEmpty;

  /// As [Map.putIfAbsent].
  V putIfAbsent(K key, V Function() ifAbsent) {
    _checkKey(key);
    return _safeMap.putIfAbsent(key, () {
      var value = ifAbsent();
      _checkValue(value);
      return value;
    });
  }

  /// As [Map.addAll].
  void addAll(Map<K, V> other) {
    _checkKeys(other.keys);
    _checkValues(other.values);
    _safeMap.addAll(other);
  }

  /// As [Map.remove].
  V? remove(Object? key) => _safeMap.remove(key);

  /// As [Map.removeWhere].
  void removeWhere(bool Function(K, V) predicate) {
    _safeMap.removeWhere(predicate);
  }

  /// As [Map.clear].
  void clear() {
    _safeMap.clear();
  }

  /// As [Map.addEntries].
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _safeMap.addEntries(newEntries);
  }

  /// As [Map.update].
  V updateValue(K key, V Function(V) update, {V Function()? ifAbsent}) =>
      _safeMap.update(key, update, ifAbsent: ifAbsent);

  /// As [Map.updateAll].
  void updateAllValues(V Function(K, V) update) {
    _safeMap.updateAll(update);
  }

  // Internal.

  MapBuilder._uninitialized();

  MapBuilder._fromBuiltMap(_BuiltMap<K, V> map)
      : _mapFactory = map._mapFactory,
        _map = map._map,
        _mapOwner = map;

  void _setOwner(_BuiltMap<K, V> mapOwner) {
    assert(mapOwner._mapFactory == _mapFactory,
        "Can't reuse a built map that uses a different base");
    _mapOwner = mapOwner;
    _map = mapOwner._map;
  }

  void _setSafeMap(Map<K, V> map) {
    _mapOwner = null;
    _map = map;
  }

  Map<K, V> get _safeMap {
    if (_mapOwner != null) {
      _map = _createMap()..addAll(_map);
      _mapOwner = null;
    }
    return _map;
  }

  Map<K, V> _createMap() => _mapFactory != null ? _mapFactory!() : <K, V>{};

  void _checkKey(K key) {
    if (isSoundMode) return;
    if (null is K) return;
    if (identical(key, null)) {
      throw ArgumentError('null key');
    }
  }

  void _checkKeys(Iterable<K> keys) {
    if (isSoundMode) return;
    if (null is K) return;
    for (var key in keys) {
      _checkKey(key);
    }
  }

  void _checkValue(V value) {
    if (isSoundMode) return;
    if (null is V) return;
    if (identical(value, null)) {
      throw ArgumentError('null value');
    }
  }

  void _checkValues(Iterable<V> values) {
    if (isSoundMode) return;
    if (null is V) return;
    for (var value in values) {
      _checkValue(value);
    }
  }
}
