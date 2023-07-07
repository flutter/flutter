// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/// A map whose keys are converted to canonical values of type `C`.
///
/// This is useful for using case-insensitive String keys, for example. It's
/// more efficient than a [LinkedHashMap] with a custom equality operator
/// because it only canonicalizes each key once, rather than doing so for each
/// comparison.
class CanonicalizedMap<C, K, V> implements Map<K, V> {
  final C Function(K) _canonicalize;

  final bool Function(K)? _isValidKeyFn;

  final _base = <C, MapEntry<K, V>>{};

  /// Creates an empty canonicalized map.
  ///
  /// The [canonicalize] function should return the canonical value for the
  /// given key. Keys with the same canonical value are considered equivalent.
  ///
  /// The [isValidKey] function is called before calling [canonicalize] for
  /// methods that take arbitrary objects. It can be used to filter out keys
  /// that can't be canonicalized.
  CanonicalizedMap(C Function(K key) canonicalize,
      {bool Function(K key)? isValidKey})
      : _canonicalize = canonicalize,
        _isValidKeyFn = isValidKey;

  /// Creates a canonicalized map that is initialized with the key/value pairs
  /// of [other].
  ///
  /// The [canonicalize] function should return the canonical value for the
  /// given key. Keys with the same canonical value are considered equivalent.
  ///
  /// The [isValidKey] function is called before calling [canonicalize] for
  /// methods that take arbitrary objects. It can be used to filter out keys
  /// that can't be canonicalized.
  CanonicalizedMap.from(Map<K, V> other, C Function(K key) canonicalize,
      {bool Function(K key)? isValidKey})
      : _canonicalize = canonicalize,
        _isValidKeyFn = isValidKey {
    addAll(other);
  }

  @override
  V? operator [](Object? key) {
    if (!_isValidKey(key)) return null;
    var pair = _base[_canonicalize(key as K)];
    return pair?.value;
  }

  @override
  void operator []=(K key, V value) {
    if (!_isValidKey(key)) return;
    _base[_canonicalize(key)] = MapEntry(key, value);
  }

  @override
  void addAll(Map<K, V> other) {
    other.forEach((key, value) => this[key] = value);
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) => _base.addEntries(entries
      .map((e) => MapEntry(_canonicalize(e.key), MapEntry(e.key, e.value))));

  @override
  Map<K2, V2> cast<K2, V2>() => _base.cast<K2, V2>();

  @override
  void clear() {
    _base.clear();
  }

  @override
  bool containsKey(Object? key) {
    if (!_isValidKey(key)) return false;
    return _base.containsKey(_canonicalize(key as K));
  }

  @override
  bool containsValue(Object? value) =>
      _base.values.any((pair) => pair.value == value);

  @override
  Iterable<MapEntry<K, V>> get entries =>
      _base.entries.map((e) => MapEntry(e.value.key, e.value.value));

  @override
  void forEach(void Function(K, V) f) {
    _base.forEach((key, pair) => f(pair.key, pair.value));
  }

  @override
  bool get isEmpty => _base.isEmpty;

  @override
  bool get isNotEmpty => _base.isNotEmpty;

  @override
  Iterable<K> get keys => _base.values.map((pair) => pair.key);

  @override
  int get length => _base.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K, V) transform) =>
      _base.map((_, pair) => transform(pair.key, pair.value));

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    return _base
        .putIfAbsent(_canonicalize(key), () => MapEntry(key, ifAbsent()))
        .value;
  }

  @override
  V? remove(Object? key) {
    if (!_isValidKey(key)) return null;
    var pair = _base.remove(_canonicalize(key as K));
    return pair?.value;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) =>
      _base.removeWhere((_, pair) => test(pair.key, pair.value));

  @Deprecated("Use cast instead")
  Map<K2, V2> retype<K2, V2>() => cast<K2, V2>();

  @override
  V update(K key, V Function(V) update, {V Function()? ifAbsent}) =>
      _base.update(_canonicalize(key), (pair) {
        var value = pair.value;
        var newValue = update(value);
        if (identical(newValue, value)) return pair;
        return MapEntry(key, newValue);
      },
          ifAbsent:
              ifAbsent == null ? null : () => MapEntry(key, ifAbsent())).value;

  @override
  void updateAll(V Function(K key, V value) update) =>
      _base.updateAll((_, pair) {
        var value = pair.value;
        var key = pair.key;
        var newValue = update(key, value);
        if (identical(value, newValue)) return pair;
        return MapEntry(key, newValue);
      });

  @override
  Iterable<V> get values => _base.values.map((pair) => pair.value);

  @override
  String toString() => MapBase.mapToString(this);

  bool _isValidKey(Object? key) =>
      (key is K) && (_isValidKeyFn == null || _isValidKeyFn!(key));
}
