// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

// TODO(ianh): These should be on the Set and List classes themselves.

/// Compares two sets for deep equality.
///
/// Returns true if the sets are both null, or if they are both non-null, have
/// the same length, and contain the same members. Returns false otherwise.
/// Order is not compared.
///
/// See also:
///
///  * [listEquals], which does something similar for lists.
bool setEquals<T>(Set<T> a, Set<T> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  for (T value in a) {
    if (!b.contains(value))
      return false;
  }
  return true;
}

/// Compares two lists for deep equality.
///
/// Returns true if the lists are both null, or if they are both non-null, have
/// the same length, and contain the same members in the same order. Returns
/// false otherwise.
///
/// See also:
///
///  * [setEquals], which does something similar for sets.
bool listEquals<T>(List<T> a, List<T> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index])
      return false;
  }
  return true;
}

/// A map of key-value pairs where each key is a [Type] and its value is of
/// that type.
class TypedDictionary {
  /// Creates an empty, mutable, typed dictionary.
  TypedDictionary() : _storage = HashMap<Type, Object>();

  const TypedDictionary._empty() : _storage = const <Type, Object>{};

  /// Creates a typed dictionary whose values cannot be changed.
  ///
  /// The dictionary is initialized to the values of the given dictionary. The
  /// other dictionary is copied; modifying it will not modify this dictionary.
  ///
  /// If the dictionary is large, this call may be expensive (O(N) in the number
  /// of entries), since the values are eagerly copied.
  TypedDictionary.unmodifiable(TypedDictionary other) :
        assert(other != null),
        _storage = Map<Type, Object>.unmodifiable(other._storage);

  /// An empty, immutable, [TypedDictionary].
  ///
  /// This object is equivalent to the object obtained from
  /// `TypedDictionary.unmodifiable(TypedDictionary())`, but the value is a
  /// compile-time constant.
  static const TypedDictionary empty = TypedDictionary._empty();

  final Map<Type, Object> _storage;

  /// Stores data in the dictionary under the key `T`.
  ///
  /// Any previously-existing data associated with that type is removed.
  ///
  /// An exception will be thrown if this dictionary was created using
  /// [TypedDictionary.unmodifiable].
  void set<T>(T data) {
    _storage[T] = data;
  }

  /// Returns the data associated with the key `T` in the dictionary.
  ///
  /// Returns null if no data has been stored under that type.
  T get<T>() {
    return _storage[T];
  }

  /// Returns true if there is no key/value pair in the map.
  bool get isEmpty => _storage.isEmpty;

  /// Returns true if there is at least one key/value pair in the map.
  bool get isNotEmpty => _storage.isNotEmpty;

  /// The number of key/value pairs in the map.
  int get length => _storage.length;

  @override
  String toString() {
    if (_storage.isEmpty)
      return '{}';
    final StringBuffer result = StringBuffer();
    result.write('{');
    final List<Type> keys = _storage.keys.toList();
    keys.sort((Type a, Type b) => a.runtimeType.toString().compareTo(b.runtimeType.toString()));
    bool addComma = false;
    for (Type key in keys) {
      if (addComma)
        result.write(', ');
      result.write(key.toString());
      result.write(': ');
      result.write(_storage[key].toString());
      addComma = true;
    }
    result.write('}');
    return result.toString();
  }
}
