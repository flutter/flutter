// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Helper interface to hide [EfficientLengthIterable] from the public
/// declaration of [Set].
abstract class _SetIterable<E>
    implements EfficientLengthIterable<E>, HideEfficientLengthIterable<E> {}

/// A collection of objects in which each object can occur only once.
///
/// That is, for each object of the element type, the object is either considered
/// to be in the set, or to _not_ be in the set.
///
/// Set implementations may consider some elements indistinguishable. These
/// elements are treated as being the same for any operation on the set.
///
/// The default [Set] implementation, [LinkedHashSet], considers objects
/// indistinguishable if they are equal with regard to [Object.==] and
/// [Object.hashCode].
///
/// Iterating over elements of a set may be either unordered
/// or ordered in some way. Examples:
///
/// * A [HashSet] is unordered, which means that its iteration order is
///   unspecified,
/// * [LinkedHashSet] iterates in the insertion order of its elements, and
/// * a sorted set like [SplayTreeSet] iterates the elements in sorted order.
///
/// It is generally not allowed to modify the set (add or remove elements) while
/// an operation on the set is being performed, for example during a call to
/// [forEach] or [containsAll]. Nor is it allowed to modify the set while
/// iterating either the set itself or any [Iterable] that is backed by the set,
/// such as the ones returned by methods like [where] and [map].
///
/// It is generally not allowed to modify the equality of elements (and thus not
/// their hashcode) while they are in the set. Some specialized subtypes may be
/// more permissive, in which case they should document this behavior.
abstract interface class Set<E> implements Iterable<E>, _SetIterable<E> {
  /// Creates an empty [Set].
  ///
  /// The created [Set] is a plain [LinkedHashSet].
  /// As such, it considers elements that are equal (using [operator ==]) to be
  /// indistinguishable, and requires them to have a compatible
  /// [Object.hashCode] implementation.
  ///
  /// The set is equivalent to one created by `LinkedHashSet<E>()`.
  // TODO: @Deprecated("Use literal <E>{} instead")
  factory Set() = LinkedHashSet<E>;

  /// Creates an empty identity [Set].
  ///
  /// The created [Set] is a [LinkedHashSet] that uses identity as equality
  /// relation.
  ///
  /// The set is equivalent to one created by `LinkedHashSet<E>.identity()`.
  factory Set.identity() = LinkedHashSet<E>.identity;

  /// Creates a [Set] that contains all [elements].
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself can have any type,
  /// so this constructor can be used to down-cast a `Set`, for example as:
  /// ```
  /// Set<SuperType> superSet = ...;
  /// Set<SubType> subSet =
  ///     Set<SubType>.from(superSet.where((e) => e is SubType));
  /// ```
  /// The created [Set] is a [LinkedHashSet]. As such, it considers elements that
  /// are equal (using [operator ==]) to be indistinguishable, and requires them to
  /// have a compatible [Object.hashCode] implementation.
  ///
  /// The set is equivalent to one created by
  /// `LinkedHashSet<E>.from(elements)`.
  /// ```dart
  /// final numbers = <num>{10, 20, 30};
  /// final setFrom = Set<int>.from(numbers);
  /// print(setFrom); // {10, 20, 30}
  /// ```
  factory Set.from(Iterable elements) = LinkedHashSet<E>.from;

  /// Creates a [Set] from [elements].
  ///
  /// The created [Set] is a [LinkedHashSet]. As such, it considers elements that
  /// are equal (using [operator ==]) to be indistinguishable, and requires them to
  /// have a compatible [Object.hashCode] implementation.
  ///
  /// The set is equivalent to one created by
  /// `LinkedHashSet<E>.of(elements)`.
  /// ```dart
  /// final baseSet = <int>{1, 2, 3};
  /// final setOf = Set<num>.of(baseSet);
  /// print(setOf); // {1, 2, 3}
  /// ```
  factory Set.of(Iterable<E> elements) = LinkedHashSet<E>.of;

  /// Creates an unmodifiable [Set] from [elements].
  ///
  /// The new set behaves like the result of [Set.of],
  /// except that the set returned by this constructor is not modifiable.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final unmodifiableSet = Set.unmodifiable(characters);
  /// ```
  @Since("2.12")
  factory Set.unmodifiable(Iterable<E> elements) =>
      UnmodifiableSetView<E>(<E>{...elements});

  /// Adapts [source] to be a `Set<T>`.
  ///
  /// If [newSet] is provided, it is used to create the new sets returned
  /// by [toSet], [union], and is also used for [intersection] and [difference].
  /// If [newSet] is omitted, it defaults to creating a new set using the
  /// default [Set] constructor, and [intersection] and [difference]
  /// returns an adapted version of calling the same method on the source.
  ///
  /// Any time the set would produce an element that is not a [T],
  /// the element access will throw.
  ///
  /// Any time a [T] value is attempted added into the adapted set,
  /// the store will throw unless the value is also an instance of [S].
  ///
  /// If all accessed elements of [source] are actually instances of [T],
  /// and if all elements added to the returned set are actually instances
  /// of [S],
  /// then the returned set can be used as a `Set<T>`.
  ///
  /// Methods which accept one or more `Object?` as argument,
  /// like [contains], [remove] and [removeAll],
  /// will pass the argument directly to the this set's method
  /// without any checks.
  static Set<T> castFrom<S, T>(Set<S> source, {Set<R> Function<R>()? newSet}) =>
      CastSet<S, T>(source, newSet);

  /// Provides a view of this set as a set of [R] instances.
  ///
  /// If this set contains only instances of [R], all read operations
  /// will work correctly. If any operation tries to access an element
  /// that is not an instance of [R], the access will throw instead.
  ///
  /// Elements added to the set (e.g., by using [add] or [addAll])
  /// must be instances of [R] to be valid arguments to the adding function,
  /// and they must be instances of [E] as well to be accepted by
  /// this set as well.
  ///
  /// Methods which accept one or more `Object?` as argument,
  /// like [contains], [remove] and [removeAll],
  /// will pass the argument directly to the this set's method
  /// without any checks.
  /// That means that you can do `setOfStrings.cast<int>().remove("a")`
  /// successfully, even if it looks like it shouldn't have any effect.
  Set<R> cast<R>();

  /// An iterator that iterates over the elements of this set.
  ///
  /// The order of iteration is defined by the individual `Set` implementation,
  /// but must be consistent between changes to the set.
  Iterator<E> get iterator;

  /// Whether [value] is in the set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final containsB = characters.contains('B'); // true
  /// final containsD = characters.contains('D'); // false
  /// ```
  bool contains(Object? value);

  /// Adds [value] to the set.
  ///
  /// Returns `true` if [value] (or an equal value) was not yet in the set.
  /// Otherwise returns `false` and the set is not changed.
  ///
  /// Example:
  /// ```dart
  /// final dateTimes = <DateTime>{};
  /// final time1 = DateTime.fromMillisecondsSinceEpoch(0);
  /// final time2 = DateTime.fromMillisecondsSinceEpoch(0);
  /// // time1 and time2 are equal, but not identical.
  /// assert(time1 == time2);
  /// assert(!identical(time1, time2));
  /// final time1Added = dateTimes.add(time1);
  /// print(time1Added); // true
  /// // A value equal to time2 exists already in the set, and the call to
  /// // add doesn't change the set.
  /// final time2Added = dateTimes.add(time2);
  /// print(time2Added); // false
  ///
  /// print(dateTimes); // {1970-01-01 02:00:00.000}
  /// assert(dateTimes.length == 1);
  /// assert(identical(time1, dateTimes.first));
  /// print(dateTimes.length);
  /// ```
  bool add(E value);

  /// Adds all [elements] to this set.
  ///
  /// Equivalent to adding each element in [elements] using [add],
  /// but some collections may be able to optimize it.
  /// ```dart
  /// final characters = <String>{'A', 'B'};
  /// characters.addAll({'A', 'B', 'C'});
  /// print(characters); // {A, B, C}
  /// ```
  void addAll(Iterable<E> elements);

  /// Removes [value] from the set.
  ///
  /// Returns `true` if [value] was in the set, and `false` if not.
  /// The method has no effect if [value] was not in the set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final didRemoveB = characters.remove('B'); // true
  /// final didRemoveD = characters.remove('D'); // false
  /// print(characters); // {A, C}
  /// ```
  bool remove(Object? value);

  /// If an object equal to [object] is in the set, return it.
  ///
  /// Checks whether [object] is in the set, like [contains], and if so,
  /// returns the object in the set, otherwise returns `null`.
  ///
  /// If the equality relation used by the set is not identity,
  /// then the returned object may not be *identical* to [object].
  /// Some set implementations may not be able to implement this method.
  /// If the [contains] method is computed,
  /// rather than being based on an actual object instance,
  /// then there may not be a specific object instance representing the
  /// set element.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final containsB = characters.lookup('B');
  /// print(containsB); // B
  /// final containsD = characters.lookup('D');
  /// print(containsD); // null
  /// ```
  E? lookup(Object? object);

  /// Removes each element of [elements] from this set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.removeAll({'A', 'B', 'X'});
  /// print(characters); // {C}
  /// ```
  void removeAll(Iterable<Object?> elements);

  /// Removes all elements of this set that are not elements in [elements].
  ///
  /// Checks for each element of [elements] whether there is an element in this
  /// set that is equal to it (according to `this.contains`), and if so, the
  /// equal element in this set is retained, and elements that are not equal
  /// to any element in [elements] are removed.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.retainAll({'A', 'B', 'X'});
  /// print(characters); // {A, B}
  /// ```
  void retainAll(Iterable<Object?> elements);

  /// Removes all elements of this set that satisfy [test].
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.removeWhere((element) => element.startsWith('B'));
  /// print(characters); // {A, C}
  /// ```
  void removeWhere(bool test(E element));

  /// Removes all elements of this set that fail to satisfy [test].
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.retainWhere(
  ///     (element) => element.startsWith('B') || element.startsWith('C'));
  /// print(characters); // {B, C}
  /// ```
  void retainWhere(bool test(E element));

  /// Whether this set contains all the elements of [other].
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final containsAB = characters.containsAll({'A', 'B'});
  /// print(containsAB); // true
  /// final containsAD = characters.containsAll({'A', 'D'});
  /// print(containsAD); // false
  /// ```
  bool containsAll(Iterable<Object?> other);

  /// Creates a new set which is the intersection between this set and [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] that
  /// are also elements of [other] according to `other.contains`.
  /// ```dart
  /// final characters1 = <String>{'A', 'B', 'C'};
  /// final characters2 = <String>{'A', 'E', 'F'};
  /// final intersectionSet = characters1.intersection(characters2);
  /// print(intersectionSet); // {A}
  /// ```
  Set<E> intersection(Set<Object?> other);

  /// Creates a new set which contains all the elements of this set and [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] and
  /// all the elements of [other].
  /// ```dart
  /// final characters1 = <String>{'A', 'B', 'C'};
  /// final characters2 = <String>{'A', 'E', 'F'};
  /// final unionSet1 = characters1.union(characters2);
  /// print(unionSet1); // {A, B, C, E, F}
  /// final unionSet2 = characters2.union(characters1);
  /// print(unionSet2); // {A, E, F, B, C}
  /// ```
  Set<E> union(Set<E> other);

  /// Creates a new set with the elements of this that are not in [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] that
  /// are not elements of [other] according to `other.contains`.
  /// ```dart
  /// final characters1 = <String>{'A', 'B', 'C'};
  /// final characters2 = <String>{'A', 'E', 'F'};
  /// final differenceSet1 = characters1.difference(characters2);
  /// print(differenceSet1); // {B, C}
  /// final differenceSet2 = characters2.difference(characters1);
  /// print(differenceSet2); // {E, F}
  /// ```
  Set<E> difference(Set<Object?> other);

  /// Removes all elements from the set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.clear(); // {}
  /// ```
  void clear();

  /// Creates a [Set] with the same elements and behavior as this `Set`.
  ///
  /// The returned set behaves the same as this set
  /// with regard to adding and removing elements.
  /// It initially contains the same elements.
  /// If this set specifies an ordering of the elements,
  /// the returned set will have the same order.
  Set<E> toSet();
}
