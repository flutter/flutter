// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// An unordered hash-table based [Set] implementation.
///
/// The elements of a `HashSet` must have consistent equality
/// and hashCode implementations. This means that the equals operation
/// must define a stable equivalence relation on the elements (reflexive,
/// symmetric, transitive, and consistent over time), and that the hashCode
/// must be consistent with equality, so that it's the same for objects that are
/// considered equal.
///
/// Most simple operations on `HashSet` are done in (potentially amortized)
/// constant time: [add], [contains], [remove], and [length], provided the hash
/// codes of objects are well distributed.
///
/// **The iteration order of the set is not specified and depends on
/// the hashcodes of the provided elements.** However, the order is stable:
/// multiple iterations over the same set produce the same order, as long as
/// the set is not modified.
///
/// **Note:**
/// Do not modify a set (add or remove elements) while an operation
/// is being performed on that set, for example in functions
/// called during a [forEach] or [containsAll] call,
/// or while iterating the set.
///
/// Do not modify elements in a way which changes their equality (and thus their
/// hash code) while they are in the set. Some specialized kinds of sets may be
/// more permissive with regards to equality, in which case they should document
/// their different behavior and restrictions.
///
/// Example:
/// ```dart
/// final letters = HashSet<String>();
/// ```
/// To add data to a set, use  [add] or [addAll].
/// ```dart continued
/// letters.add('A');
/// letters.addAll({'B', 'C', 'D'});
/// ```
/// To check if the set is empty, use [isEmpty] or [isNotEmpty].
/// To find the number of elements in the set, use [length].
/// ```dart continued
/// print(letters.isEmpty); // false
/// print(letters.length); // 4
/// print(letters); // fx {A, D, C, B}
/// ```
/// To check whether the set has an element with a specific value,
/// use [contains].
/// ```dart continued
/// final bExists = letters.contains('B'); // true
/// ```
/// The [forEach] method calls a function with each element of the set.
/// ```dart continued
/// letters.forEach(print);
/// // A
/// // D
/// // C
/// // B
/// ```
/// To make a copy of the set, use [toSet].
/// ```dart continued
/// final anotherSet = letters.toSet();
/// print(anotherSet); // fx {A, C, D, B}
/// ```
/// To remove an element, use [remove].
/// ```dart continued
/// final removedValue = letters.remove('A'); // true
/// print(letters); // fx {B, C, D}
/// ```
/// To remove multiple elements at the same time, use [removeWhere] or
/// [removeAll].
/// ```dart continued
/// letters.removeWhere((element) => element.startsWith('B'));
/// print(letters); // fx {D, C}
/// ```
/// To removes all elements in this set that do not meet a condition,
/// use [retainWhere].
/// ```dart continued
/// letters.retainWhere((element) => element.contains('C'));
/// print(letters); // {C}
/// ```
/// To remove all elements and empty the set, use [clear].
/// ```dart continued
/// letters.clear();
/// print(letters.isEmpty); // true
/// print(letters); // {}
/// ```
/// **See also:**
/// * [Set] is the general interface of collection where each object can
/// occur only once.
/// * [LinkedHashSet] objects stored based on insertion order.
/// * [SplayTreeSet] iterates the objects in sorted order.
abstract final class HashSet<E> implements Set<E> {
  /// Create a hash set using the provided [equals] as equality.
  ///
  /// The provided [equals] must define a stable equivalence relation, and
  /// [hashCode] must be consistent with [equals].
  ///
  /// If [equals] or [hashCode] are omitted, the set uses
  /// the elements' intrinsic [Object.==] and [Object.hashCode].
  ///
  /// If you supply one of [equals] and [hashCode],
  /// you should generally also supply the other.
  ///
  /// Some [equals] or [hashCode] functions might not work for all objects.
  /// If [isValidKey] is supplied, it's used to check a potential element
  /// which is not necessarily an instance of [E], like the argument to
  /// [contains] which is typed as `Object?`.
  /// If [isValidKey] returns `false`, for an object, the [equals] and
  /// [hashCode] functions are not called, and no key equal to that object
  /// is assumed to be in the map.
  /// The [isValidKey] function defaults to just testing if the object is an
  /// instance of [E], which means that:
  /// ```dart template:expression
  /// HashSet<int>(equals: (int e1, int e2) => (e1 - e2) % 5 == 0,
  ///              hashCode: (int e) => e % 5)
  /// ```
  /// does not need an `isValidKey` argument because it defaults to only
  /// accepting `int` values which are accepted by both `equals` and `hashCode`.
  ///
  /// If neither `equals`, `hashCode`, nor `isValidKey` is provided,
  /// the default `isValidKey` instead accepts all values.
  /// The default equality and hashcode operations are assumed to work on all
  /// objects.
  ///
  /// Likewise, if `equals` is [identical], `hashCode` is [identityHashCode]
  /// and `isValidKey` is omitted, the resulting set is identity based,
  /// and the `isValidKey` defaults to accepting all keys.
  /// Such a map can be created directly using [HashSet.identity].
  external factory HashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey});

  /// Creates an unordered identity-based set.
  ///
  /// Effectively shorthand for:
  /// ```dart
  /// HashSet<E>(equals: identical, hashCode: identityHashCode)
  /// ```
  external factory HashSet.identity();

  /// Create a hash set containing all [elements].
  ///
  /// Creates a hash set as by `HashSet<E>()` and adds all given [elements]
  /// to the set. The elements are added in order. If [elements] contains
  /// two entries that are equal, but not identical, then the first one is
  /// the one in the resulting set.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `Set`, for example as:
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Set<SubType> subSet =
  ///     HashSet<SubType>.from(superSet.whereType<SubType>());
  /// ```
  /// Example:
  /// ```dart
  /// final numbers = <num>[10, 20, 30];
  /// final hashSetFrom = HashSet<int>.from(numbers);
  /// print(hashSetFrom); // fx {20, 10, 30}
  /// ```
  factory HashSet.from(Iterable<dynamic> elements) {
    HashSet<E> result = HashSet<E>();
    for (final e in elements) {
      result.add(e as E);
    }
    return result;
  }

  /// Create a hash set containing all [elements].
  ///
  /// Creates a hash set as by `HashSet<E>()` and adds all given [elements]
  /// to the set. The elements are added in order. If [elements] contains
  /// two entries that are equal, but not identical, then the first one is
  /// the one in the resulting set.
  /// Example:
  /// ```dart
  /// final baseSet = <int>{1, 2, 3};
  /// final hashSetOf = HashSet<num>.of(baseSet);
  /// print(hashSetOf); // fx {3, 1, 2}
  /// ```
  factory HashSet.of(Iterable<E> elements) => HashSet<E>()..addAll(elements);

  /// Provides an iterator that iterates over the elements of this set.
  ///
  /// The order of iteration is unspecified,
  /// but is consistent between changes to the set.
  Iterator<E> get iterator;
}
