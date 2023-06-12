// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../set_multimap.dart';

/// The Built Collection builder for [BuiltSetMultimap].
///
/// It implements the mutating part of the [SetMultimap] interface.
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
class SetMultimapBuilder<K, V> {
  // BuiltSets copied from another instance so they can be reused directly for
  // keys without changes.
  late Map<K, BuiltSet<V>> _builtMap;
  // Instance that _builtMap belongs to. If present, _builtMap must not be
  // mutated.
  _BuiltSetMultimap<K, V>? _builtMapOwner;
  // SetBuilders for keys that are being changed.
  late Map<K, SetBuilder<V>> _builderMap;

  /// Instantiates with elements from a [Map], [SetMultimap] or
  /// [BuiltSetMultimap].
  factory SetMultimapBuilder([multimap = const {}]) {
    return SetMultimapBuilder<K, V>._uninitialized()..replace(multimap);
  }

  /// Converts to a [BuiltSetMultimap].
  BuiltSetMultimap<K, V> build() {
    if (_builtMapOwner == null) {
      for (var key in _builderMap.keys) {
        var builtSet = _builderMap[key]!.build();
        if (builtSet.isEmpty) {
          _builtMap.remove(key);
        } else {
          _builtMap[key] = builtSet;
        }
      }

      _builtMapOwner = _BuiltSetMultimap<K, V>.withSafeMap(_builtMap);
    }
    return _builtMapOwner!;
  }

  /// Applies a function to `this`.
  void update(Function(SetMultimapBuilder<K, V>) updates) {
    updates(this);
  }

  /// Replaces all elements with elements from a [Map], [SetMultimap] or
  /// [BuiltSetMultimap].
  void replace(dynamic multimap) {
    if (multimap is _BuiltSetMultimap<K, V>) {
      _setOwner(multimap);
    } else if (multimap is Map) {
      _setWithCopyAndCheck(multimap.keys, (k) => multimap[k]);
    } else if (multimap is BuiltSetMultimap) {
      _setWithCopyAndCheck(multimap.keys, (k) => multimap[k]);
    } else {
      _setWithCopyAndCheck(multimap.keys, (k) => multimap[k]);
    }
  }

  /// As [Map.fromIterable] but adds.
  ///
  /// Additionally, you may specify [values] instead of [value]. This new
  /// parameter allows you to supply a function that returns an [Iterable]
  /// of values.
  ///
  /// [key] and [value] default to the identity function. [values] is ignored
  /// if not specified.
  void addIterable<T>(Iterable<T> iterable,
      {K Function(T)? key,
      V Function(T)? value,
      Iterable<V> Function(T)? values}) {
    if (value != null && values != null) {
      throw ArgumentError('expected value or values to be set, got both');
    }

    key ??= (T x) => x as K;

    if (values != null) {
      for (var element in iterable) {
        addValues(key(element), values(element));
      }
    } else {
      value ??= (T x) => x as V;
      for (var element in iterable) {
        add(key(element), value(element));
      }
    }
  }

  // Based on SetMultimap.

  /// As [SetMultimap.add].
  void add(K key, V value) {
    _makeWriteableCopy();
    _checkKey(key);
    _checkValue(value);
    _getValuesBuilder(key).add(value);
  }

  /// As [SetMultimap.addValues].
  void addValues(K key, Iterable<V> values) {
    // _disown is called in add.
    values.forEach((value) {
      add(key, value);
    });
  }

  /// As [SetMultimap.remove] but returns nothing.
  void remove(Object? key, V? value) {
    if (key is K) {
      _makeWriteableCopy();
      _getValuesBuilder(key).remove(value);
    }
  }

  /// As [SetMultimap.removeAll] but returns nothing.
  void removeAll(Object? key) {
    if (key is K) {
      _makeWriteableCopy();

      _builtMap = _builtMap;
      _builderMap[key] = SetBuilder<V>();
    }
  }

  /// As [SetMultimap.clear].
  void clear() {
    _makeWriteableCopy();

    _builtMap.clear();
    _builderMap.clear();
  }

  // Internal.

  SetBuilder<V> _getValuesBuilder(K key) {
    var result = _builderMap[key];
    if (result == null) {
      var builtValues = _builtMap[key];
      if (builtValues == null) {
        result = SetBuilder<V>();
      } else {
        result = builtValues.toBuilder();
      }
      _builderMap[key] = result;
    }
    return result;
  }

  void _makeWriteableCopy() {
    if (_builtMapOwner != null) {
      _builtMap = Map<K, BuiltSet<V>>.from(_builtMap);
      _builtMapOwner = null;
    }
  }

  SetMultimapBuilder._uninitialized();

  void _setOwner(_BuiltSetMultimap<K, V> builtSetMultimap) {
    _builtMapOwner = builtSetMultimap;
    _builtMap = builtSetMultimap._map;
    _builderMap = <K, SetBuilder<V>>{};
  }

  void _setWithCopyAndCheck(Iterable keys, Function lookup) {
    _builtMapOwner = null;
    _builtMap = <K, BuiltSet<V>>{};
    _builderMap = <K, SetBuilder<V>>{};

    for (var key in keys) {
      if (key is K) {
        for (var value in lookup(key)) {
          if (value is V) {
            add(key, value);
          } else {
            throw ArgumentError(
                'map contained invalid value: $value, for key $key');
          }
        }
      } else {
        throw ArgumentError('map contained invalid key: $key');
      }
    }
  }

  void _checkKey(K key) {
    if (isSoundMode) return;
    if (null is K) return;
    if (identical(key, null)) {
      throw ArgumentError('invalid key: $key');
    }
  }

  void _checkValue(V value) {
    if (isSoundMode) return;
    if (null is V) return;
    if (identical(value, null)) {
      throw ArgumentError('invalid value: $value');
    }
  }
}
