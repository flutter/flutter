// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../map.dart';

typedef _MapFactory<K, V> = Map<K, V> Function();

/// The Built Collection [Map].
///
/// It implements the non-mutating part of the [Map] interface. Iteration over
/// keys is in the same order in which they were inserted. Modifications are
/// made via [MapBuilder].
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
abstract class BuiltMap<K, V> {
  final _MapFactory<K, V>? _mapFactory;
  final Map<K, V> _map;

  // Cached.
  int? _hashCode;
  Iterable<K>? _keys;
  Iterable<V>? _values;

  /// Instantiates with elements from a [Map] or [BuiltMap].
  factory BuiltMap([map = const {}]) {
    if (map is _BuiltMap && map.hasExactKeyAndValueTypes(K, V)) {
      return map as BuiltMap<K, V>;
    } else if (map is Map || map is BuiltMap) {
      return _BuiltMap<K, V>.copyAndCheckTypes(map.keys, (k) => map[k]);
    } else {
      throw ArgumentError('expected Map or BuiltMap, got ${map.runtimeType}');
    }
  }

  /// Instantiates with elements from a [Map].
  factory BuiltMap.from(Map map) {
    return _BuiltMap<K, V>.copyAndCheckTypes(map.keys, (k) => map[k]);
  }

  /// Instantiates with elements from a [Map<K, V>].
  ///
  /// `K` and `V` are inferred from `map`.
  factory BuiltMap.of(Map<K, V> map) {
    return _BuiltMap<K, V>.copyAndCheckForNull(map.keys, (k) => map[k] as V);
  }

  /// Creates a [MapBuilder], applies updates to it, and builds.
  factory BuiltMap.build(Function(MapBuilder<K, V>) updates) =>
      (MapBuilder<K, V>()..update(updates)).build();

  /// Converts to a [MapBuilder] for modification.
  ///
  /// The `BuiltMap` remains immutable and can continue to be used.
  MapBuilder<K, V> toBuilder() =>
      MapBuilder<K, V>._fromBuiltMap(this as _BuiltMap<K, V>);

  /// Converts to a [MapBuilder], applies updates to it, and builds.
  BuiltMap<K, V> rebuild(Function(MapBuilder<K, V>) updates) =>
      (toBuilder()..update(updates)).build();

  /// Returns as an immutable map.
  ///
  /// Useful when producing or using APIs that need the [Map] interface. This
  /// differs from [toMap] where mutations are explicitly disallowed.
  Map<K, V> asMap() => Map<K, V>.unmodifiable(_map);

  /// Converts to a [Map].
  ///
  /// Note that the implementation is efficient: it returns a copy-on-write
  /// wrapper around the data from this `BuiltMap`. So, if no mutations are
  /// made to the result, no copy is made.
  ///
  /// This allows efficient use of APIs that ask for a mutable collection
  /// but don't actually mutate it.
  Map<K, V> toMap() => CopyOnWriteMap<K, V>(_map, _mapFactory);

  /// Deep hashCode.
  ///
  /// A `BuiltMap` is only equal to another `BuiltMap` with equal key/value
  /// pairs in any order. Then, the `hashCode` is guaranteed to be the same.
  @override
  int get hashCode {
    _hashCode ??= hashObjects(_map.keys
        .map((key) => hash2(key.hashCode, _map[key].hashCode))
        .toList(growable: false)
      ..sort());
    return _hashCode!;
  }

  /// Deep equality.
  ///
  /// A `BuiltMap` is only equal to another `BuiltMap` with equal key/value
  /// pairs in any order.
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! BuiltMap) return false;
    if (other.length != length) return false;
    if (other.hashCode != hashCode) return false;
    for (var key in keys) {
      if (other[key] != this[key]) return false;
    }
    return true;
  }

  @override
  String toString() => _map.toString();

  // Map.

  /// As [Map].
  V? operator [](Object? key) => _map[key];

  /// As [Map.containsKey].
  bool containsKey(Object key) => _map.containsKey(key);

  /// As [Map.containsValue].
  bool containsValue(Object value) => _map.containsValue(value);

  /// As [Map.forEach].
  void forEach(void Function(K, V) f) {
    _map.forEach(f);
  }

  /// As [Map.isEmpty].
  bool get isEmpty => _map.isEmpty;

  /// As [Map.isNotEmpty].
  bool get isNotEmpty => _map.isNotEmpty;

  /// As [Map.keys], but result is stable; it always returns the same instance.
  Iterable<K> get keys {
    _keys ??= _map.keys;
    return _keys!;
  }

  /// As [Map.length].
  int get length => _map.length;

  /// As [Map.values], but result is stable; it always returns the same
  /// instance.
  Iterable<V> get values {
    _values ??= _map.values;
    return _values!;
  }

  /// As [Map.entries].
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  /// As [Map.map], but returns a [BuiltMap].
  BuiltMap<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K, V) f) =>
      _BuiltMap<K2, V2>.withSafeMap(null, _map.map(f));

  // Internal.

  BuiltMap._(this._mapFactory, this._map);
}

/// Default implementation of the public [BuiltMap] interface.
class _BuiltMap<K, V> extends BuiltMap<K, V> {
  _BuiltMap.withSafeMap(_MapFactory<K, V>? mapFactory, Map<K, V> map)
      : super._(mapFactory, map);

  _BuiltMap.copyAndCheckTypes(Iterable keys, Function lookup)
      : super._(null, <K, V>{}) {
    for (var key in keys) {
      if (key is K) {
        var value = lookup(key);
        if (value is V) {
          _map[key] = value;
        } else {
          throw ArgumentError('map contained invalid value: $value');
        }
      } else {
        throw ArgumentError('map contained invalid key: $key');
      }
    }
  }

  _BuiltMap.copyAndCheckForNull(Iterable<K> keys, V Function(K) lookup)
      : super._(null, <K, V>{}) {
    var checkKeys = !isSoundMode && null is! K;
    var checkValues = !isSoundMode && null is! V;
    for (var key in keys) {
      if (checkKeys && identical(key, null)) {
        throw ArgumentError('map contained invalid key: null');
      }
      var value = lookup(key);
      if (checkValues && value == null) {
        throw ArgumentError('map contained invalid value: null');
      }
      _map[key] = value;
    }
  }

  bool hasExactKeyAndValueTypes(Type key, Type value) => K == key && V == value;
}

/// Extensions for [BuiltMap] on [Map].
extension BuiltMapExtension<K, V> on Map<K, V> {
  /// Converts to a [BuiltMap].
  BuiltMap<K, V> build() => BuiltMap<K, V>.of(this);
}
