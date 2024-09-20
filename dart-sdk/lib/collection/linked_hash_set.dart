// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// A [LinkedHashSet] is a hash-table based [Set] implementation.
///
/// The default implementation of [Set] is [LinkedHashSet].
///
/// The `LinkedHashSet` also keeps track of the order that elements were inserted
/// in, and iteration happens in first-to-last insertion order.
///
/// The elements of a `LinkedHashSet` must have consistent [Object.==]
/// and [Object.hashCode] implementations. This means that the `==` operator
/// must define a stable equivalence relation on the elements (reflexive,
/// symmetric, transitive, and consistent over time), and that `hashCode`
/// must be the same for objects that are considered equal by `==`.
///
/// Iteration of elements is done in element insertion order.
/// An element that was added after another will occur later in the iteration.
/// Adding an element that is already in the set
/// does not change its position in the iteration order,
/// but removing an element and adding it again
/// will make it the last element of an iteration.
///
/// Most simple operations on `HashSet` are done in (potentially amortized)
/// constant time: [add], [contains], [remove], and [length], provided the hash
/// codes of objects are well distributed.
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
/// final planets = <String>{}; // LinkedHashSet
/// ```
/// To add data to a set, use [add] or [addAll].
/// ```dart continued
/// final uranusAdded = planets.add('Uranus'); // true
/// planets.addAll({'Venus', 'Mars', 'Earth', 'Jupiter'});
/// print(planets); // {Uranus, Venus, Mars, Earth, Jupiter}
/// ```
/// To check if the set is empty, use [isEmpty] or [isNotEmpty].
/// To find the number of elements in the set, use [length].
/// ```dart continued
/// print(planets.isEmpty); // false
/// print(planets.length); // 5
/// ```
/// To check whether the set has an element with a specific value,
/// use [contains].
/// ```dart continued
/// final marsExists = planets.contains('Mars'); // true
/// ```
/// The [forEach] method calls a function with each element of the set.
/// ```dart continued
/// planets.forEach(print);
/// // Uranus
/// // Venus
/// // Mars
/// // Earth
/// // Jupiter
/// ```
///
/// To make a copy of the set, use [toSet].
/// ```dart continued
/// final copySet = planets.toSet();
/// print(copySet); // {Uranus, Venus, Mars, Earth, Jupiter}
/// ```
/// To remove an element, use [remove].
/// ```dart continued
/// final removedValue = planets.remove('Mars'); // Mars
/// print(planets); // {Uranus, Venus, Earth, Jupiter}
/// ```
/// To remove multiple elements at the same time, use [removeWhere] or
/// [removeAll].
/// ```dart continued
/// planets.removeWhere((element) => element.startsWith('E'));
/// print(planets); // {Uranus, Venus, Jupiter}
/// ```
/// To removes all elements in this set that do not meet a condition,
/// use [retainWhere].
/// ```dart continued
/// planets.retainWhere((element) => element.contains('Jupiter'));
/// print(planets); // {Jupiter}
/// ```dart continued
/// To remove all elements and empty the set, use [clear].
/// ```dart continued
/// planets.clear();
/// print(planets.isEmpty); // true
/// print(planets); // {}
/// ```
/// **See also:**
/// * [Set] is the general interface of collection where each object can
/// occur only once.
/// * [HashSet] the order of the objects in the iteration is not guaranteed.
/// * [SplayTreeSet] iterates the objects in sorted order.
abstract final class LinkedHashSet<E> implements Set<E> {
  /// Create an insertion-ordered hash set using the provided
  /// [equals] and [hashCode].
  ///
  /// The provided [equals] must define a stable equivalence relation, and
  /// [hashCode] must be consistent with [equals].
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
  /// LinkedHashSet<int>(equals: (int e1, int e2) => (e1 - e2) % 5 == 0,
  ///                    hashCode: (int e) => e % 5);
  /// ```
  /// does not need an `isValidKey` argument, because it defaults to only
  /// accepting `int` values which are accepted by both `equals` and `hashCode`.
  ///
  /// If neither `equals`, `hashCode`, nor `isValidKey` are provided,
  /// the default `isValidKey` instead accepts all values.
  /// The default equality and hashcode operations are assumed to work on all
  /// objects.
  ///
  /// Likewise, if `equals` is [identical], `hashCode` is [identityHashCode]
  /// and `isValidKey` is omitted, the resulting set is identity based,
  /// and the `isValidKey` defaults to accepting all keys.
  /// Such a map can be created directly using [LinkedHashSet.identity].
  external factory LinkedHashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey});

  /// Creates an insertion-ordered identity-based set.
  ///
  /// Effectively shorthand for:
  /// ```dart
  /// LinkedHashSet<E>(equals: identical, hashCode: identityHashCode)
  /// ```
  external factory LinkedHashSet.identity();

  /// Create a linked hash set containing all [elements].
  ///
  /// Creates a linked hash set as by `LinkedHashSet<E>()` and adds each
  /// element of `elements` to this set in the order they are iterated.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type,
  /// so this constructor can be used to down-cast a `Set`, for example as:
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Iterable<SuperType> tmp = superSet.where((e) => e is SubType);
  /// Set<SubType> subSet = LinkedHashSet<SubType>.from(tmp);
  /// ```
  /// Example:
  /// ```dart
  /// final numbers = <num>[10, 20, 30];
  /// final setFrom = LinkedHashSet<int>.from(numbers);
  /// print(setFrom); // {10, 20, 30}
  /// ```
  factory LinkedHashSet.from(Iterable<dynamic> elements) {
    LinkedHashSet<E> result = LinkedHashSet<E>();
    for (final element in elements) {
      result.add(element as E);
    }
    return result;
  }

  /// Create a linked hash set from [elements].
  ///
  /// Creates a linked hash set as by `LinkedHashSet<E>()` and adds each
  /// element of `elements` to this set in the order they are iterated.
  /// Example:
  /// ```dart
  /// final baseSet = <int>{1, 2, 3};
  /// final setOf = LinkedHashSet<num>.of(baseSet);
  /// print(setOf); // {1, 2, 3}
  /// ```
  factory LinkedHashSet.of(Iterable<E> elements) =>
      LinkedHashSet<E>()..addAll(elements);

  /// Executes a function on each element of the set.
  ///
  /// The elements are iterated in insertion order.
  void forEach(void action(E element));

  /// Provides an iterator that iterates over the elements in insertion order.
  Iterator<E> get iterator;
}
