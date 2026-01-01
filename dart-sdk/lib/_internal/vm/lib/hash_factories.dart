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
        CompactLinkedIdentityHashMap;

import "dart:_internal" show patch;

import "dart:typed_data" show Uint32List;

// The [LinkedHashMap] and [LinkedHashSet] factory constructors return different
// internal implementations depending on the supplied callback functions.

@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap({
    bool equals(K key1, K key2)?,
    int hashCode(K key)?,
    bool isValidKey(potentialKey)?,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return DefaultMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return CompactLinkedIdentityHashMap<K, V>();
        }
        equals ??= _defaultEquals;
      }
    } else {
      hashCode ??= _defaultHashCode;
      equals ??= _defaultEquals;
    }
    return CompactLinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

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
      if (hashCode == null) {
        if (equals == null) {
          return DefaultSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return CompactLinkedIdentityHashSet<E>();
        }
        equals ??= _defaultEquals;
      }
    } else {
      hashCode ??= _defaultHashCode;
      equals ??= _defaultEquals;
    }
    return CompactLinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory LinkedHashSet.identity() => CompactLinkedIdentityHashSet<E>();
}
