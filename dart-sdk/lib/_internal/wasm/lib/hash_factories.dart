// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import "dart:_wasm";

import "dart:typed_data" show Uint32List;

@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap(
      {bool equals(K key1, K key2)?,
      int hashCode(K key)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null && equals == null) {
        return _WasmDefaultMap<K, V>();
      }
      if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return _CompactLinkedIdentityHashMap<K, V>();
      }
    }
    hashCode ??= _defaultHashCode;
    equals ??= _defaultEquals;
    return _CompactLinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @pragma("wasm:entry-point")
  static _WasmDefaultMap<K, V> _default<K, V>() => _WasmDefaultMap<K, V>();

  @patch
  factory LinkedHashMap.identity() => _CompactLinkedIdentityHashMap<K, V>();
}

@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet(
      {bool equals(E e1, E e2)?,
      int hashCode(E e)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null && equals == null) {
        return _WasmDefaultSet<E>();
      }
      if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return _CompactLinkedIdentityHashSet<E>();
      }
    }
    hashCode ??= _defaultHashCode;
    equals ??= _defaultEquals;
    return _CompactLinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @pragma("wasm:entry-point")
  static _WasmDefaultSet<E> _default<E>() => _WasmDefaultSet<E>();

  @patch
  factory LinkedHashSet.identity() => _CompactLinkedIdentityHashSet<E>();
}

@pragma("wasm:entry-point")
base class _WasmDefaultMap<K, V> extends _HashFieldBase
    with
        MapMixin<K, V>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashMapMixin<K, V>,
        _MapCreateIndexMixin<K, V>
    implements LinkedHashMap<K, V> {
  @pragma("wasm:entry-point")
  static _WasmDefaultMap<K, V> fromWasmArray<K, V>(WasmArray<Object?> data) {
    final map = _WasmDefaultMap<K, V>();
    assert(map._index == _uninitializedHashBaseIndex);
    assert(map._hashMask == _HashBase._UNINITIALIZED_HASH_MASK);
    assert(map._data == _uninitializedHashBaseData);
    assert(map._usedData == 0);
    assert(map._deletedKeys == 0);

    map._data = data;
    map._usedData = data.length;
    map._createIndex(true);

    return map;
  }

  void operator []=(K key, V value);
}

@pragma('wasm:entry-point')
base class _WasmDefaultSet<E> extends _HashFieldBase
    with
        SetMixin<E>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashSetMixin<E>,
        _SetCreateIndexMixin<E>
    implements LinkedHashSet<E> {
  @pragma("wasm:entry-point")
  static _WasmDefaultSet<E> fromWasmArray<E>(WasmArray<Object?> data) {
    final map = _WasmDefaultSet<E>();
    assert(map._index == _uninitializedHashBaseIndex);
    assert(map._hashMask == _HashBase._UNINITIALIZED_HASH_MASK);
    assert(map._data == _uninitializedHashBaseData);
    assert(map._usedData == 0);
    assert(map._deletedKeys == 0);

    map._data = data;
    map._usedData = data.length;
    map._createIndex(true);

    return map;
  }

  bool add(E key);

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newEmpty);

  static Set<R> _newEmpty<R>() => _WasmDefaultSet<R>();

  Set<E> toSet() => _WasmDefaultSet<E>()..addAll(this);
}

@pragma("wasm:entry-point")
base class _WasmImmutableMap<K, V> extends _HashFieldBase
    with
        MapMixin<K, V>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashMapMixin<K, V>,
        _MapCreateIndexMixin<K, V>,
        _UnmodifiableMapMixin<K, V>,
        _ImmutableLinkedHashMapMixin<K, V>
    implements LinkedHashMap<K, V> {}

@pragma("wasm:entry-point")
base class _WasmImmutableSet<E> extends _HashFieldBase
    with
        SetMixin<E>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashSetMixin<E>,
        _SetCreateIndexMixin<E>,
        _UnmodifiableSetMixin<E>,
        _ImmutableLinkedHashSetMixin<E>
    implements LinkedHashSet<E> {
  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newEmpty);

  static Set<R> _newEmpty<R>() => LinkedHashSet._default<R>();

  // Returns a mutable set.
  Set<E> toSet() => LinkedHashSet._default<E>()..addAll(this);
}
