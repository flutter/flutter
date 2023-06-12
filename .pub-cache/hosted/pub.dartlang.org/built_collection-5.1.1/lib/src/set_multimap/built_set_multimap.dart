// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../set_multimap.dart';

/// The Built Collection [SetMultimap].
///
/// It implements the non-mutating part of the [SetMultimap] interface.
/// Iteration over keys is in the same order in which they were inserted.
/// Modifications are made via [SetMultimapBuilder].
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
abstract class BuiltSetMultimap<K, V> {
  final Map<K, BuiltSet<V>> _map;

  // Precomputed.
  final BuiltSet<V> _emptySet = BuiltSet<V>();

  // Cached.
  int? _hashCode;
  Iterable<K>? _keys;
  Iterable<V>? _values;

  /// Instantiates with elements from a [Map], [SetMultimap] or
  /// [BuiltSetMultimap].
  factory BuiltSetMultimap([multimap = const {}]) {
    if (multimap is _BuiltSetMultimap &&
        multimap.hasExactKeyAndValueTypes(K, V)) {
      return multimap as BuiltSetMultimap<K, V>;
    } else if (multimap is Map) {
      return _BuiltSetMultimap<K, V>.copyAndCheck(
          multimap.keys, (k) => multimap[k]);
    } else if (multimap is BuiltSetMultimap) {
      return _BuiltSetMultimap<K, V>.copyAndCheck(
          multimap.keys, (k) => multimap[k]);
    } else {
      return _BuiltSetMultimap<K, V>.copyAndCheck(
          multimap.keys, (k) => multimap[k]);
    }
  }

  /// Creates a [SetMultimapBuilder], applies updates to it, and builds.
  factory BuiltSetMultimap.build(Function(SetMultimapBuilder<K, V>) updates) =>
      (SetMultimapBuilder<K, V>()..update(updates)).build();

  /// Converts to a [SetMultimapBuilder] for modification.
  ///
  /// The `BuiltSetMultimap` remains immutable and can continue to be used.
  SetMultimapBuilder<K, V> toBuilder() => SetMultimapBuilder<K, V>(this);

  /// Converts to a [SetMultimapBuilder], applies updates to it, and builds.
  BuiltSetMultimap<K, V> rebuild(Function(SetMultimapBuilder<K, V>) updates) =>
      (toBuilder()..update(updates)).build();

  /// Converts to a [Map].
  ///
  /// Note that the implementation is efficient: it returns a copy-on-write
  /// wrapper around the data from this `BuiltSetMultimap`. So, if no mutations
  /// are made to the result, no copy is made.
  ///
  /// This allows efficient use of APIs that ask for a mutable collection
  /// but don't actually mutate it.
  Map<K, BuiltSet<V>> toMap() => CopyOnWriteMap<K, BuiltSet<V>>(_map);

  /// Deep hashCode.
  ///
  /// A `BuiltSetMultimap` is only equal to another `BuiltSetMultimap` with
  /// equal key/values pairs in any order. Then, the `hashCode` is guaranteed
  /// to be the same.
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
  /// A `BuiltSetMultimap` is only equal to another `BuiltSetMultimap` with
  /// equal key/values pairs in any order.
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! BuiltSetMultimap) return false;
    if (other.length != length) return false;
    if (other.hashCode != hashCode) return false;
    for (var key in keys) {
      if (other[key] != this[key]) return false;
    }
    return true;
  }

  /// Returns as an immutable map.
  ///
  /// Useful when producing or using APIs that need the [Map] interface. This
  /// differs from [toMap] where mutations are explicitly disallowed.
  Map<K, Iterable<V>> asMap() => Map<K, Iterable<V>>.unmodifiable(_map);

  @override
  String toString() => _map.toString();

  // SetMultimap.

  /// As [SetMultimap], but results are [BuiltSet]s and not mutable.
  BuiltSet<V>? operator [](Object? key) {
    var result = _map[key];
    return identical(result, null) ? _emptySet : result;
  }

  /// As [SetMultimap.containsKey].
  bool containsKey(Object? key) => _map.containsKey(key);

  /// As [SetMultimap.containsValue].
  bool containsValue(Object? value) => values.contains(value);

  /// As [SetMultimap.forEach].
  void forEach(void Function(K, V) f) {
    _map.forEach((key, values) {
      values.forEach((value) {
        f(key, value);
      });
    });
  }

  /// As [SetMultimap.forEachKey].
  void forEachKey(void Function(K, Iterable<V>) f) {
    _map.forEach((key, values) {
      f(key, values);
    });
  }

  /// As [SetMultimap.isEmpty].
  bool get isEmpty => _map.isEmpty;

  /// As [SetMultimap.isNotEmpty].
  bool get isNotEmpty => _map.isNotEmpty;

  /// As [SetMultimap.keys], but result is stable; it always returns the same
  /// instance.
  Iterable<K> get keys {
    _keys ??= _map.keys;
    return _keys!;
  }

  /// As [SetMultimap.length].
  int get length => _map.length;

  /// As [SetMultimap.values], but result is stable; it always returns the
  /// same instance.
  Iterable<V> get values {
    _values ??= _map.values.expand((x) => x);
    return _values!;
  }

  // Internal.

  BuiltSetMultimap._(this._map);
}

/// Default implementation of the public [BuiltSetMultimap] interface.
class _BuiltSetMultimap<K, V> extends BuiltSetMultimap<K, V> {
  _BuiltSetMultimap.withSafeMap(Map<K, BuiltSet<V>> map) : super._(map);

  _BuiltSetMultimap.copyAndCheck(Iterable keys, Function lookup)
      : super._(<K, BuiltSet<V>>{}) {
    for (var key in keys) {
      if (key is K) {
        _map[key] = BuiltSet<V>(lookup(key));
      } else {
        throw ArgumentError('map contained invalid key: $key');
      }
    }
  }

  bool hasExactKeyAndValueTypes(Type key, Type value) => K == key && V == value;
}
