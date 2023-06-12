// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

// TODO(antonm): reconsider later if PbList should take care of equality.
bool _deepEquals(lhs, rhs) {
  // Some GeneratedMessages implement Map, so test this first.
  if (lhs is GeneratedMessage) return lhs == rhs;
  if (rhs is GeneratedMessage) return false;
  if ((lhs is List) && (rhs is List)) return _areListsEqual(lhs, rhs);
  if ((lhs is Map) && (rhs is Map)) return _areMapsEqual(lhs, rhs);
  return lhs == rhs;
}

bool _areListsEqual(List lhs, List rhs) {
  if (lhs.length != rhs.length) return false;
  for (var i = 0; i < lhs.length; i++) {
    if (!_deepEquals(lhs[i], rhs[i])) return false;
  }
  return true;
}

bool _areMapsEqual(Map lhs, Map rhs) {
  if (lhs.length != rhs.length) return false;
  return lhs.keys.every((key) => _deepEquals(lhs[key], rhs[key]));
}

@Deprecated('This function was not intended to be public. '
    'It will be removed from the public api in next major version. ')
List<T> sorted<T>(Iterable<T> list) => List.from(list)..sort();

List<T> _sorted<T>(Iterable<T> list) => List.from(list)..sort();

class _HashUtils {
// Jenkins hash functions copied from https://github.com/google/quiver-dart/blob/master/lib/src/core/hash.dart.

  static int _combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int _finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  /// Generates a hash code for multiple [objects].
  static int _hashObjects(Iterable objects) =>
      _finish(objects.fold(0, (h, i) => _combine(h, i.hashCode)));

  /// Generates a hash code for two objects.
  static int _hash2(a, b) =>
      _finish(_combine(_combine(0, a.hashCode), b.hashCode));
}
