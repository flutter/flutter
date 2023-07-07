// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'comparators.dart';

const int _hashMask = 0x7fffffff;

/// A generic equality relation on objects.
abstract class Equality<E> {
  const factory Equality() = DefaultEquality<E>;

  /// Compare two elements for being equal.
  ///
  /// This should be a proper equality relation.
  bool equals(E e1, E e2);

  /// Get a hashcode of an element.
  ///
  /// The hashcode should be compatible with [equals], so that if
  /// `equals(a, b)` then `hash(a) == hash(b)`.
  int hash(E e);

  /// Test whether an object is a valid argument to [equals] and [hash].
  ///
  /// Some implementations may be restricted to only work on specific types
  /// of objects.
  bool isValidKey(Object? o);
}

/// Equality of objects based on derived values.
///
/// For example, given the class:
/// ```dart
/// abstract class Employee {
///   int get employmentId;
/// }
/// ```
///
/// The following [Equality] considers employees with the same IDs to be equal:
/// ```dart
/// EqualityBy((Employee e) => e.employmentId);
/// ```
///
/// It's also possible to pass an additional equality instance that should be
/// used to compare the value itself.
class EqualityBy<E, F> implements Equality<E> {
  final F Function(E) _comparisonKey;

  final Equality<F> _inner;

  EqualityBy(F Function(E) comparisonKey,
      [Equality<F> inner = const DefaultEquality<Never>()])
      : _comparisonKey = comparisonKey,
        _inner = inner;

  @override
  bool equals(E e1, E e2) =>
      _inner.equals(_comparisonKey(e1), _comparisonKey(e2));

  @override
  int hash(E e) => _inner.hash(_comparisonKey(e));

  @override
  bool isValidKey(Object? o) {
    if (o is E) {
      final value = _comparisonKey(o);
      return _inner.isValidKey(value);
    }
    return false;
  }
}

/// Equality of objects that compares only the natural equality of the objects.
///
/// This equality uses the objects' own [Object.==] and [Object.hashCode] for
/// the equality.
///
/// Note that [equals] and [hash] take `Object`s rather than `E`s. This allows
/// `E` to be inferred as `Null` in const contexts where `E` wouldn't be a
/// compile-time constant, while still allowing the class to be used at runtime.
class DefaultEquality<E> implements Equality<E> {
  const DefaultEquality();
  @override
  bool equals(Object? e1, Object? e2) => e1 == e2;
  @override
  int hash(Object? e) => e.hashCode;
  @override
  bool isValidKey(Object? o) => true;
}

/// Equality of objects that compares only the identity of the objects.
class IdentityEquality<E> implements Equality<E> {
  const IdentityEquality();
  @override
  bool equals(E e1, E e2) => identical(e1, e2);
  @override
  int hash(E e) => identityHashCode(e);
  @override
  bool isValidKey(Object? o) => true;
}

/// Equality on iterables.
///
/// Two iterables are equal if they have the same elements in the same order.
///
/// The [equals] and [hash] methods accepts `null` values,
/// even if the [isValidKey] returns `false` for `null`.
/// The [hash] of `null` is `null.hashCode`.
class IterableEquality<E> implements Equality<Iterable<E>> {
  final Equality<E?> _elementEquality;
  const IterableEquality(
      [Equality<E> elementEquality = const DefaultEquality<Never>()])
      : _elementEquality = elementEquality;

  @override
  bool equals(Iterable<E>? elements1, Iterable<E>? elements2) {
    if (identical(elements1, elements2)) return true;
    if (elements1 == null || elements2 == null) return false;
    var it1 = elements1.iterator;
    var it2 = elements2.iterator;
    while (true) {
      var hasNext = it1.moveNext();
      if (hasNext != it2.moveNext()) return false;
      if (!hasNext) return true;
      if (!_elementEquality.equals(it1.current, it2.current)) return false;
    }
  }

  @override
  int hash(Iterable<E>? elements) {
    if (elements == null) return null.hashCode;
    // Jenkins's one-at-a-time hash function.
    var hash = 0;
    for (var element in elements) {
      var c = _elementEquality.hash(element);
      hash = (hash + c) & _hashMask;
      hash = (hash + (hash << 10)) & _hashMask;
      hash ^= (hash >> 6);
    }
    hash = (hash + (hash << 3)) & _hashMask;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _hashMask;
    return hash;
  }

  @override
  bool isValidKey(Object? o) => o is Iterable<E>;
}

/// Equality on lists.
///
/// Two lists are equal if they have the same length and their elements
/// at each index are equal.
///
/// This is effectively the same as [IterableEquality] except that it
/// accesses elements by index instead of through iteration.
///
/// The [equals] and [hash] methods accepts `null` values,
/// even if the [isValidKey] returns `false` for `null`.
/// The [hash] of `null` is `null.hashCode`.
class ListEquality<E> implements Equality<List<E>> {
  final Equality<E> _elementEquality;
  const ListEquality(
      [Equality<E> elementEquality = const DefaultEquality<Never>()])
      : _elementEquality = elementEquality;

  @override
  bool equals(List<E>? list1, List<E>? list2) {
    if (identical(list1, list2)) return true;
    if (list1 == null || list2 == null) return false;
    var length = list1.length;
    if (length != list2.length) return false;
    for (var i = 0; i < length; i++) {
      if (!_elementEquality.equals(list1[i], list2[i])) return false;
    }
    return true;
  }

  @override
  int hash(List<E>? list) {
    if (list == null) return null.hashCode;
    // Jenkins's one-at-a-time hash function.
    // This code is almost identical to the one in IterableEquality, except
    // that it uses indexing instead of iterating to get the elements.
    var hash = 0;
    for (var i = 0; i < list.length; i++) {
      var c = _elementEquality.hash(list[i]);
      hash = (hash + c) & _hashMask;
      hash = (hash + (hash << 10)) & _hashMask;
      hash ^= (hash >> 6);
    }
    hash = (hash + (hash << 3)) & _hashMask;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _hashMask;
    return hash;
  }

  @override
  bool isValidKey(Object? o) => o is List<E>;
}

abstract class _UnorderedEquality<E, T extends Iterable<E>>
    implements Equality<T> {
  final Equality<E> _elementEquality;

  const _UnorderedEquality(this._elementEquality);

  @override
  bool equals(T? elements1, T? elements2) {
    if (identical(elements1, elements2)) return true;
    if (elements1 == null || elements2 == null) return false;
    var counts = HashMap<E, int>(
        equals: _elementEquality.equals,
        hashCode: _elementEquality.hash,
        isValidKey: _elementEquality.isValidKey);
    var length = 0;
    for (var e in elements1) {
      var count = counts[e] ?? 0;
      counts[e] = count + 1;
      length++;
    }
    for (var e in elements2) {
      var count = counts[e];
      if (count == null || count == 0) return false;
      counts[e] = count - 1;
      length--;
    }
    return length == 0;
  }

  @override
  int hash(T? elements) {
    if (elements == null) return null.hashCode;
    var hash = 0;
    for (E element in elements) {
      var c = _elementEquality.hash(element);
      hash = (hash + c) & _hashMask;
    }
    hash = (hash + (hash << 3)) & _hashMask;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _hashMask;
    return hash;
  }
}

/// Equality of the elements of two iterables without considering order.
///
/// Two iterables are considered equal if they have the same number of elements,
/// and the elements of one set can be paired with the elements
/// of the other iterable, so that each pair are equal.
class UnorderedIterableEquality<E> extends _UnorderedEquality<E, Iterable<E>> {
  const UnorderedIterableEquality(
      [Equality<E> elementEquality = const DefaultEquality<Never>()])
      : super(elementEquality);

  @override
  bool isValidKey(Object? o) => o is Iterable<E>;
}

/// Equality of sets.
///
/// Two sets are considered equal if they have the same number of elements,
/// and the elements of one set can be paired with the elements
/// of the other set, so that each pair are equal.
///
/// This equality behaves the same as [UnorderedIterableEquality] except that
/// it expects sets instead of iterables as arguments.
///
/// The [equals] and [hash] methods accepts `null` values,
/// even if the [isValidKey] returns `false` for `null`.
/// The [hash] of `null` is `null.hashCode`.
class SetEquality<E> extends _UnorderedEquality<E, Set<E>> {
  const SetEquality(
      [Equality<E> elementEquality = const DefaultEquality<Never>()])
      : super(elementEquality);

  @override
  bool isValidKey(Object? o) => o is Set<E>;
}

/// Internal class used by [MapEquality].
///
/// The class represents a map entry as a single object,
/// using a combined hashCode and equality of the key and value.
class _MapEntry {
  final MapEquality equality;
  final Object? key;
  final Object? value;
  _MapEntry(this.equality, this.key, this.value);

  @override
  int get hashCode =>
      (3 * equality._keyEquality.hash(key) +
          7 * equality._valueEquality.hash(value)) &
      _hashMask;

  @override
  bool operator ==(Object other) =>
      other is _MapEntry &&
      equality._keyEquality.equals(key, other.key) &&
      equality._valueEquality.equals(value, other.value);
}

/// Equality on maps.
///
/// Two maps are equal if they have the same number of entries, and if the
/// entries of the two maps are pairwise equal on both key and value.
///
/// The [equals] and [hash] methods accepts `null` values,
/// even if the [isValidKey] returns `false` for `null`.
/// The [hash] of `null` is `null.hashCode`.
class MapEquality<K, V> implements Equality<Map<K, V>> {
  final Equality<K> _keyEquality;
  final Equality<V> _valueEquality;
  const MapEquality(
      {Equality<K> keys = const DefaultEquality<Never>(),
      Equality<V> values = const DefaultEquality<Never>()})
      : _keyEquality = keys,
        _valueEquality = values;

  @override
  bool equals(Map<K, V>? map1, Map<K, V>? map2) {
    if (identical(map1, map2)) return true;
    if (map1 == null || map2 == null) return false;
    var length = map1.length;
    if (length != map2.length) return false;
    Map<_MapEntry, int> equalElementCounts = HashMap();
    for (var key in map1.keys) {
      var entry = _MapEntry(this, key, map1[key]);
      var count = equalElementCounts[entry] ?? 0;
      equalElementCounts[entry] = count + 1;
    }
    for (var key in map2.keys) {
      var entry = _MapEntry(this, key, map2[key]);
      var count = equalElementCounts[entry];
      if (count == null || count == 0) return false;
      equalElementCounts[entry] = count - 1;
    }
    return true;
  }

  @override
  int hash(Map<K, V>? map) {
    if (map == null) return null.hashCode;
    var hash = 0;
    for (var key in map.keys) {
      var keyHash = _keyEquality.hash(key);
      var valueHash = _valueEquality.hash(map[key] as V);
      hash = (hash + 3 * keyHash + 7 * valueHash) & _hashMask;
    }
    hash = (hash + (hash << 3)) & _hashMask;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _hashMask;
    return hash;
  }

  @override
  bool isValidKey(Object? o) => o is Map<K, V>;
}

/// Combines several equalities into a single equality.
///
/// Tries each equality in order, using [Equality.isValidKey], and returns
/// the result of the first equality that applies to the argument or arguments.
///
/// For `equals`, the first equality that matches the first argument is used,
/// and if the second argument of `equals` is not valid for that equality,
/// it returns false.
///
/// Because the equalities are tried in order, they should generally work on
/// disjoint types. Otherwise the multi-equality may give inconsistent results
/// for `equals(e1, e2)` and `equals(e2, e1)`. This can happen if one equality
/// considers only `e1` a valid key, and not `e2`, but an equality which is
/// checked later, allows both.
class MultiEquality<E> implements Equality<E> {
  final Iterable<Equality<E>> _equalities;

  const MultiEquality(Iterable<Equality<E>> equalities)
      : _equalities = equalities;

  @override
  bool equals(E e1, E e2) {
    for (var eq in _equalities) {
      if (eq.isValidKey(e1)) return eq.isValidKey(e2) && eq.equals(e1, e2);
    }
    return false;
  }

  @override
  int hash(E e) {
    for (var eq in _equalities) {
      if (eq.isValidKey(e)) return eq.hash(e);
    }
    return 0;
  }

  @override
  bool isValidKey(Object? o) {
    for (var eq in _equalities) {
      if (eq.isValidKey(o)) return true;
    }
    return false;
  }
}

/// Deep equality on collections.
///
/// Recognizes lists, sets, iterables and maps and compares their elements using
/// deep equality as well.
///
/// Non-iterable/map objects are compared using a configurable base equality.
///
/// Works in one of two modes: ordered or unordered.
///
/// In ordered mode, lists and iterables are required to have equal elements
/// in the same order. In unordered mode, the order of elements in iterables
/// and lists are not important.
///
/// A list is only equal to another list, likewise for sets and maps. All other
/// iterables are compared as iterables only.
class DeepCollectionEquality implements Equality {
  final Equality _base;
  final bool _unordered;
  const DeepCollectionEquality([Equality base = const DefaultEquality<Never>()])
      : _base = base,
        _unordered = false;

  /// Creates a deep equality on collections where the order of lists and
  /// iterables are not considered important. That is, lists and iterables are
  /// treated as unordered iterables.
  const DeepCollectionEquality.unordered(
      [Equality base = const DefaultEquality<Never>()])
      : _base = base,
        _unordered = true;

  @override
  bool equals(e1, e2) {
    if (e1 is Set) {
      return e2 is Set && SetEquality(this).equals(e1, e2);
    }
    if (e1 is Map) {
      return e2 is Map && MapEquality(keys: this, values: this).equals(e1, e2);
    }
    if (!_unordered) {
      if (e1 is List) {
        return e2 is List && ListEquality(this).equals(e1, e2);
      }
      if (e1 is Iterable) {
        return e2 is Iterable && IterableEquality(this).equals(e1, e2);
      }
    } else if (e1 is Iterable) {
      if (e1 is List != e2 is List) return false;
      return e2 is Iterable && UnorderedIterableEquality(this).equals(e1, e2);
    }
    return _base.equals(e1, e2);
  }

  @override
  int hash(Object? o) {
    if (o is Set) return SetEquality(this).hash(o);
    if (o is Map) return MapEquality(keys: this, values: this).hash(o);
    if (!_unordered) {
      if (o is List) return ListEquality(this).hash(o);
      if (o is Iterable) return IterableEquality(this).hash(o);
    } else if (o is Iterable) {
      return UnorderedIterableEquality(this).hash(o);
    }
    return _base.hash(o);
  }

  @override
  bool isValidKey(Object? o) =>
      o is Iterable || o is Map || _base.isValidKey(o);
}

/// String equality that's insensitive to differences in ASCII case.
///
/// Non-ASCII characters are compared as-is, with no conversion.
class CaseInsensitiveEquality implements Equality<String> {
  const CaseInsensitiveEquality();

  @override
  bool equals(String string1, String string2) =>
      equalsIgnoreAsciiCase(string1, string2);

  @override
  int hash(String string) => hashIgnoreAsciiCase(string);

  @override
  bool isValidKey(Object? object) => object is String;
}
