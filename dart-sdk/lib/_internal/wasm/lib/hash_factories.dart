// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_compact_hash"
    show
        DefaultMap,
        DefaultSet,
        CompactLinkedIdentityHashSet,
        CompactLinkedCustomHashSet,
        CompactLinkedCustomHashMap,
        CompactLinkedIdentityHashMap,
        MapInitializationFromWasmArray,
        SetInitializationFromWasmArray;
import "dart:_internal" show patch;
import "dart:_wasm";

import "dart:typed_data" show Uint32List;

@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap({
    bool equals(K key1, K key2)?,
    int hashCode(K key)?,
    bool isValidKey(potentialKey)?,
  }) {
    if (isValidKey == null) {
      if (hashCode == null && equals == null) {
        return DefaultMap<K, V>();
      }
      if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return CompactLinkedIdentityHashMap<K, V>();
      }
    }
    hashCode ??= _defaultHashCode;
    equals ??= _defaultEquals;
    return CompactLinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @pragma("wasm:entry-point")
  static DefaultMap<K, V> _default<K, V>() => DefaultMap<K, V>();

  @patch
  factory LinkedHashMap.identity() => CompactLinkedIdentityHashMap<K, V>();
}

@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet({
    bool equals(E e1, E e2)?,
    int hashCode(E e)?,
    bool isValidKey(potentialKey)?,
  }) {
    if (isValidKey == null) {
      if (hashCode == null && equals == null) {
        return DefaultSet<E>();
      }
      if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return CompactLinkedIdentityHashSet<E>();
      }
    }
    hashCode ??= _defaultHashCode;
    equals ??= _defaultEquals;
    return CompactLinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @pragma("wasm:entry-point")
  static DefaultSet<E> _default<E>() => DefaultSet<E>();

  @patch
  factory LinkedHashSet.identity() => CompactLinkedIdentityHashSet<E>();
}
