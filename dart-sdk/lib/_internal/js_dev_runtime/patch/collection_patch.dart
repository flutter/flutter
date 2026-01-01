// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:collection classes.
import 'dart:_foreign_helper' show JS, JSExportName;
import 'dart:_runtime' as dart;
import 'dart:_internal' show patch;
import 'dart:_interceptors' show JSArray;
import 'dart:_js_helper'
    show
        LinkedMap,
        IdentityMap,
        CustomHashMap,
        CustomKeyHashMap,
        LinkedSet,
        IdentitySet,
        CustomHashSet,
        CustomKeyHashSet,
        DartIterator,
        notNull,
        putLinkedMapKey;

@patch
class HashMap<K, V> {
  @patch
  factory HashMap({
    bool Function(K, K)? equals,
    int Function(K)? hashCode,
    bool Function(dynamic)? isValidKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(K, String) || identical(K, int)) {
            return IdentityMap<K, V>();
          }
          return LinkedMap<K, V>();
        }
        hashCode = dart.hashCode;
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return IdentityMap<K, V>();
      }
      return CustomHashMap<K, V>(equals ?? dart.equals, hashCode);
    }
    return CustomKeyHashMap<K, V>(
      equals ?? dart.equals,
      hashCode ?? dart.hashCode,
      isValidKey,
    );
  }

  @patch
  factory HashMap.identity() = IdentityMap<K, V>;
}

@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap({
    bool Function(K, K)? equals,
    int Function(K)? hashCode,
    bool Function(dynamic)? isValidKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(K, String) || identical(K, int)) {
            return IdentityMap<K, V>();
          }
          return LinkedMap<K, V>();
        }
        hashCode = dart.hashCode;
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return IdentityMap<K, V>();
      }
      return CustomHashMap<K, V>(equals ?? dart.equals, hashCode);
    }
    return CustomKeyHashMap<K, V>(
      equals ?? dart.equals,
      hashCode ?? dart.hashCode,
      isValidKey,
    );
  }

  @patch
  factory LinkedHashMap.identity() = IdentityMap<K, V>;
}

@patch
class HashSet<E> {
  @patch
  factory HashSet({
    bool Function(E, E)? equals,
    int Function(E)? hashCode,
    bool Function(dynamic)? isValidKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(E, String) || identical(E, int)) {
            return IdentitySet<E>();
          }
          return LinkedSet<E>();
        }
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return IdentitySet<E>();
      }
      return CustomHashSet<E>(equals ?? dart.equals, hashCode ?? dart.hashCode);
    }
    return CustomKeyHashSet<E>(
      equals ?? dart.equals,
      hashCode ?? dart.hashCode,
      isValidKey,
    );
  }

  @patch
  factory HashSet.identity() = IdentitySet<E>;
}

@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet({
    bool Function(E, E)? equals,
    int Function(E)? hashCode,
    bool Function(dynamic)? isValidKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(E, String) || identical(E, int)) {
            return IdentitySet<E>();
          }
          return LinkedSet<E>();
        }
        hashCode = dart.hashCode;
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return IdentitySet<E>();
      }
      return CustomHashSet<E>(equals ?? dart.equals, hashCode);
    }
    return CustomKeyHashSet<E>(
      equals ?? dart.equals,
      hashCode ?? dart.hashCode,
      isValidKey,
    );
  }

  @patch
  factory LinkedHashSet.identity() = IdentitySet<E>;
}
