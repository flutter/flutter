// Copyright (c) 2014, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:collection';

import 'package:collection/collection.dart';

import 'yaml_node.dart';

/// Returns a [Map] that compares its keys based on [deepEquals].
Map<K, V> deepEqualsMap<K, V>() =>
    LinkedHashMap(equals: deepEquals, hashCode: deepHashCode);

/// Returns whether two objects are structurally equivalent.
///
/// This considers `NaN` values to be equivalent, handles self-referential
/// structures, and considers [YamlScalar]s to be equal to their values.
bool deepEquals(Object? obj1, Object? obj2) => _DeepEquals().equals(obj1, obj2);

/// A class that provides access to the list of parent objects used for loop
/// detection.
class _DeepEquals {
  final _parents1 = [];
  final _parents2 = [];

  /// Returns whether [obj1] and [obj2] are structurally equivalent.
  bool equals(Object? obj1, Object? obj2) {
    if (obj1 is YamlScalar) obj1 = obj1.value;
    if (obj2 is YamlScalar) obj2 = obj2.value;

    // _parents1 and _parents2 are guaranteed to be the same size.
    for (var i = 0; i < _parents1.length; i++) {
      var loop1 = identical(obj1, _parents1[i]);
      var loop2 = identical(obj2, _parents2[i]);
      // If both structures loop in the same place, they're equal at that point
      // in the structure. If one loops and the other doesn't, they're not
      // equal.
      if (loop1 && loop2) return true;
      if (loop1 || loop2) return false;
    }

    _parents1.add(obj1);
    _parents2.add(obj2);
    try {
      if (obj1 is List && obj2 is List) {
        return _listEquals(obj1, obj2);
      } else if (obj1 is Map && obj2 is Map) {
        return _mapEquals(obj1, obj2);
      } else if (obj1 is num && obj2 is num) {
        return _numEquals(obj1, obj2);
      } else {
        return obj1 == obj2;
      }
    } finally {
      _parents1.removeLast();
      _parents2.removeLast();
    }
  }

  /// Returns whether [list1] and [list2] are structurally equal.
  bool _listEquals(List list1, List list2) {
    if (list1.length != list2.length) return false;

    for (var i = 0; i < list1.length; i++) {
      if (!equals(list1[i], list2[i])) return false;
    }

    return true;
  }

  /// Returns whether [map1] and [map2] are structurally equal.
  bool _mapEquals(Map map1, Map map2) {
    if (map1.length != map2.length) return false;

    for (var key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      if (!equals(map1[key], map2[key])) return false;
    }

    return true;
  }

  /// Returns whether two numbers are equivalent.
  ///
  /// This differs from `n1 == n2` in that it considers `NaN` to be equal to
  /// itself.
  bool _numEquals(num n1, num n2) {
    if (n1.isNaN && n2.isNaN) return true;
    return n1 == n2;
  }
}

/// Returns a hash code for [obj] such that structurally equivalent objects
/// will have the same hash code.
///
/// This supports deep equality for maps and lists, including those with
/// self-referential structures, and returns the same hash code for
/// [YamlScalar]s and their values.
int deepHashCode(Object? obj) {
  var parents = [];

  int _deepHashCode(value) {
    if (parents.any((parent) => identical(parent, value))) return -1;

    parents.add(value);
    try {
      if (value is Map) {
        var equality = const UnorderedIterableEquality();
        return equality.hash(value.keys.map(_deepHashCode)) ^
            equality.hash(value.values.map(_deepHashCode));
      } else if (value is Iterable) {
        return const IterableEquality().hash(value.map(deepHashCode));
      } else if (value is YamlScalar) {
        return value.value.hashCode;
      } else {
        return value.hashCode;
      }
    } finally {
      parents.removeLast();
    }
  }

  return _deepHashCode(obj);
}
