// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../list_multimap.dart';

/// The Built Collection builder for [BuiltListMultimap].
///
/// It implements the mutating part of the [ListMultimap] interface.
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
class ListMultimapBuilder<K, V> {
  // BuiltLists copied from another instance so they can be reused directly for
  // keys without changes.
  late Map<K, BuiltList<V>> _builtMap;
  // Instance that _builtMap belongs to. If present, _builtMap must not be
  // mutated.
  _BuiltListMultimap<K, V>? _builtMapOwner;
  // ListBuilders for keys that are being changed.
  late Map<K, ListBuilder<V>> _builderMap;

  /// Instantiates with elements from a [Map], [ListMultimap] or
  /// [BuiltListMultimap].
  factory ListMultimapBuilder([multimap = const {}]) {
    return ListMultimapBuilder<K, V>._uninitialized()..replace(multimap);
  }

  /// Converts to a [BuiltListMultimap].
  ///
  /// The `ListMultimapBuilder` can be modified again and used to create any
  /// number of `BuiltListMultimap`s.
  BuiltListMultimap<K, V> build() {
    if (_builtMapOwner == null) {
      for (var key in _builderMap.keys) {
        var builtList = _builderMap[key]!.build();
        if (builtList.isEmpty) {
          _builtMap.remove(key);
        } else {
          _builtMap[key] = builtList;
        }
      }

      _builtMapOwner = _BuiltListMultimap<K, V>.withSafeMap(_builtMap);
    }
    return _builtMapOwner!;
  }

  /// Applies a function to `this`.
  void update(Function(ListMultimapBuilder<K, V>) updates) {
    updates(this);
  }

  /// Replaces all elements with elements from a [Map], [ListMultimap] or
  /// [BuiltListMultimap].
  ///
  /// Any [ListBuilder]s associated with this collection are disconnected.
  void replace(dynamic multimap) {
    if (multimap is _BuiltListMultimap<K, V>) {
      _setOwner(multimap);
    } else if (multimap is Map) {
      _setWithCopyAndCheck(multimap.keys, (k) => multimap[k]);
    } else if (multimap is BuiltListMultimap) {
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

  // Based on ListMultimap.

  /// As [ListMultimap.add].
  void add(K key, V value) {
    _makeWriteableCopy();
    _checkKey(key);
    _checkValue(value);
    _getValuesBuilder(key).add(value);
  }

  /// As [ListMultimap.addValues].
  void addValues(K key, Iterable<V> values) {
    // _disown is called in add.
    values.forEach((value) {
      add(key, value);
    });
  }

  /// As [ListMultimap.remove].
  bool remove(Object? key, V? value) {
    if (key is! K) return false;
    _makeWriteableCopy();
    return _getValuesBuilder(key).remove(value);
  }

  /// As [ListMultimap.removeAll], but results are [BuiltList]s.
  BuiltList<V> removeAll(Object? key) {
    if (key is! K) return BuiltList<V>();
    _makeWriteableCopy();
    var builder = _builderMap[key];
    if (builder == null) {
      _builderMap[key] = ListBuilder<V>();
      return _builtMap[key] ?? BuiltList<V>();
    }
    var old = builder.build();
    builder.clear();
    return old;
  }

  /// As [ListMultimap.clear].
  ///
  /// Any [ListBuilder]s associated with this collection are disconnected.
  void clear() {
    _makeWriteableCopy();

    _builtMap.clear();
    _builderMap.clear();
  }

  /// As [ListMultimap], but results are [ListBuilder]s.
  ListBuilder<V> operator [](Object? key) {
    _makeWriteableCopy();
    return key is K ? _getValuesBuilder(key) : ListBuilder<V>();
  }

  // Internal.

  ListBuilder<V> _getValuesBuilder(K key) {
    var result = _builderMap[key];
    if (result == null) {
      var builtValues = _builtMap[key];
      if (builtValues == null) {
        result = ListBuilder<V>();
      } else {
        result = builtValues.toBuilder();
      }
      _builderMap[key] = result;
    }
    return result;
  }

  void _makeWriteableCopy() {
    if (_builtMapOwner != null) {
      _builtMap = Map<K, BuiltList<V>>.from(_builtMap);
      _builtMapOwner = null;
    }
  }

  ListMultimapBuilder._uninitialized();

  void _setOwner(_BuiltListMultimap<K, V> builtListMultimap) {
    _builtMapOwner = builtListMultimap;
    _builtMap = builtListMultimap._map;
    _builderMap = <K, ListBuilder<V>>{};
  }

  void _setWithCopyAndCheck(Iterable keys, Function lookup) {
    _builtMapOwner = null;
    _builtMap = <K, BuiltList<V>>{};
    _builderMap = <K, ListBuilder<V>>{};

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
      throw ArgumentError('null key');
    }
  }

  void _checkValue(V value) {
    if (isSoundMode) return;
    if (null is V) return;
    if (identical(value, null)) {
      throw ArgumentError('null value');
    }
  }
}
