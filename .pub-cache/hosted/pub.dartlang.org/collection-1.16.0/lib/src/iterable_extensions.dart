// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Random;

import 'package:collection/src/utils.dart';

import 'algorithms.dart';

/// Extensions that apply to all iterables.
///
/// These extensions provide direct access to some of the
/// algorithms expose by this package,
/// as well as some generally useful convenience methods.
///
/// More specialized extension methods that only apply to
/// iterables with specific element types include those of
/// [IterableComparableExtension] and [IterableNullableExtension].
extension IterableExtension<T> on Iterable<T> {
  /// Selects [count] elements at random from this iterable.
  ///
  /// The returned list contains [count] different elements of the iterable.
  /// If the iterable contains fewer that [count] elements,
  /// the result will contain all of them, but will be shorter than [count].
  /// If the same value occurs more than once in the iterable,
  /// it can also occur more than once in the chosen elements.
  ///
  /// Each element of the iterable has the same chance of being chosen.
  /// The chosen elements are not in any specific order.
  List<T> sample(int count, [Random? random]) {
    RangeError.checkNotNegative(count, 'count');
    var iterator = this.iterator;
    var chosen = <T>[];
    for (var i = 0; i < count; i++) {
      if (iterator.moveNext()) {
        chosen.add(iterator.current);
      } else {
        return chosen;
      }
    }
    var index = count;
    random ??= Random();
    while (iterator.moveNext()) {
      index++;
      var position = random.nextInt(index);
      if (position < count) chosen[position] = iterator.current;
    }
    return chosen;
  }

  /// The elements that do not satisfy [test].
  Iterable<T> whereNot(bool Function(T element) test) =>
      where((element) => !test(element));

  /// Creates a sorted list of the elements of the iterable.
  ///
  /// The elements are ordered by the [compare] [Comparator].
  List<T> sorted(Comparator<T> compare) => [...this]..sort(compare);

  /// Creates a sorted list of the elements of the iterable.
  ///
  /// The elements are ordered by the natural ordering of the
  /// property [keyOf] of the element.
  List<T> sortedBy<K extends Comparable<K>>(K Function(T element) keyOf) {
    var elements = [...this];
    mergeSortBy<T, K>(elements, keyOf, compareComparable);
    return elements;
  }

  /// Creates a sorted list of the elements of the iterable.
  ///
  /// The elements are ordered by the [compare] [Comparator] of the
  /// property [keyOf] of the element.
  List<T> sortedByCompare<K>(
      K Function(T element) keyOf, Comparator<K> compare) {
    var elements = [...this];
    mergeSortBy<T, K>(elements, keyOf, compare);
    return elements;
  }

  /// Whether the elements are sorted by the [compare] ordering.
  ///
  /// Compares pairs of elements using `compare` to check that
  /// the elements of this iterable to check
  /// that earlier elements always compare
  /// smaller than or equal to later elements.
  ///
  /// An single-element or empty iterable is trivially in sorted order.
  bool isSorted(Comparator<T> compare) {
    var iterator = this.iterator;
    if (!iterator.moveNext()) return true;
    var previousElement = iterator.current;
    while (iterator.moveNext()) {
      var element = iterator.current;
      if (compare(previousElement, element) > 0) return false;
      previousElement = element;
    }
    return true;
  }

  /// Whether the elements are sorted by their [keyOf] property.
  ///
  /// Applies [keyOf] to each element in iteration order,
  /// then checks whether the results are in non-decreasing [Comparable] order.
  bool isSortedBy<K extends Comparable<K>>(K Function(T element) keyOf) {
    var iterator = this.iterator;
    if (!iterator.moveNext()) return true;
    var previousKey = keyOf(iterator.current);
    while (iterator.moveNext()) {
      var key = keyOf(iterator.current);
      if (previousKey.compareTo(key) > 0) return false;
      previousKey = key;
    }
    return true;
  }

  /// Whether the elements are [compare]-sorted by their [keyOf] property.
  ///
  /// Applies [keyOf] to each element in iteration order,
  /// then checks whether the results are in non-decreasing order
  /// using the [compare] [Comparator]..
  bool isSortedByCompare<K>(
      K Function(T element) keyOf, Comparator<K> compare) {
    var iterator = this.iterator;
    if (!iterator.moveNext()) return true;
    var previousKey = keyOf(iterator.current);
    while (iterator.moveNext()) {
      var key = keyOf(iterator.current);
      if (compare(previousKey, key) > 0) return false;
      previousKey = key;
    }
    return true;
  }

  /// Takes an action for each element.
  ///
  /// Calls [action] for each element along with the index in the
  /// iteration order.
  void forEachIndexed(void Function(int index, T element) action) {
    var index = 0;
    for (var element in this) {
      action(index++, element);
    }
  }

  /// Takes an action for each element as long as desired.
  ///
  /// Calls [action] for each element.
  /// Stops iteration if [action] returns `false`.
  void forEachWhile(bool Function(T element) action) {
    for (var element in this) {
      if (!action(element)) break;
    }
  }

  /// Takes an action for each element and index as long as desired.
  ///
  /// Calls [action] for each element along with the index in the
  /// iteration order.
  /// Stops iteration if [action] returns `false`.
  void forEachIndexedWhile(bool Function(int index, T element) action) {
    var index = 0;
    for (var element in this) {
      if (!action(index++, element)) break;
    }
  }

  /// Maps each element and its index to a new value.
  Iterable<R> mapIndexed<R>(R Function(int index, T element) convert) sync* {
    var index = 0;
    for (var element in this) {
      yield convert(index++, element);
    }
  }

  /// The elements whose value and index satisfies [test].
  Iterable<T> whereIndexed(bool Function(int index, T element) test) sync* {
    var index = 0;
    for (var element in this) {
      if (test(index++, element)) yield element;
    }
  }

  /// The elements whose value and index do not satisfy [test].
  Iterable<T> whereNotIndexed(bool Function(int index, T element) test) sync* {
    var index = 0;
    for (var element in this) {
      if (!test(index++, element)) yield element;
    }
  }

  /// Expands each element and index to a number of elements in a new iterable.
  Iterable<R> expandIndexed<R>(
      Iterable<R> Function(int index, T element) expand) sync* {
    var index = 0;
    for (var element in this) {
      yield* expand(index++, element);
    }
  }

  /// Combine the elements with each other and the current index.
  ///
  /// Calls [combine] for each element except the first.
  /// The call passes the index of the current element, the result of the
  /// previous call, or the first element for the first call, and
  /// the current element.
  ///
  /// Returns the result of the last call, or the first element if
  /// there is only one element.
  /// There must be at least one element.
  T reduceIndexed(T Function(int index, T previous, T element) combine) {
    var iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw StateError('no elements');
    }
    var index = 1;
    var result = iterator.current;
    while (iterator.moveNext()) {
      result = combine(index++, result, iterator.current);
    }
    return result;
  }

  /// Combine the elements with a value and the current index.
  ///
  /// Calls [combine] for each element with the current index,
  /// the result of the previous call, or [initialValue] for the first element,
  /// and the current element.
  ///
  /// Returns the result of the last call to [combine],
  /// or [initialValue] if there are no elements.
  R foldIndexed<R>(
      R initialValue, R Function(int index, R previous, T element) combine) {
    var result = initialValue;
    var index = 0;
    for (var element in this) {
      result = combine(index++, result, element);
    }
    return result;
  }

  /// The first element satisfying [test], or `null` if there are none.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// The first element whose value and index satisfies [test].
  ///
  /// Returns `null` if there are no element and index satisfying [test].
  T? firstWhereIndexedOrNull(bool Function(int index, T element) test) {
    var index = 0;
    for (var element in this) {
      if (test(index++, element)) return element;
    }
    return null;
  }

  /// The first element, or `null` if the iterable is empty.
  T? get firstOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  /// The last element satisfying [test], or `null` if there are none.
  T? lastWhereOrNull(bool Function(T element) test) {
    T? result;
    for (var element in this) {
      if (test(element)) result = element;
    }
    return result;
  }

  /// The last element whose index and value satisfies [test].
  ///
  /// Returns `null` if no element and index satisfies [test].
  T? lastWhereIndexedOrNull(bool Function(int index, T element) test) {
    T? result;
    var index = 0;
    for (var element in this) {
      if (test(index++, element)) result = element;
    }
    return result;
  }

  /// The last element, or `null` if the iterable is empty.
  T? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }

  /// The single element satisfying [test].
  ///
  /// Returns `null` if there are either no elements
  /// or more than one element satisfying [test].
  ///
  /// **Notice**: This behavior differs from [Iterable.singleWhere]
  /// which always throws if there are more than one match,
  /// and only calls the `orElse` function on zero matches.
  T? singleWhereOrNull(bool Function(T element) test) {
    T? result;
    var found = false;
    for (var element in this) {
      if (test(element)) {
        if (!found) {
          result = element;
          found = true;
        } else {
          return null;
        }
      }
    }
    return result;
  }

  /// The single element satisfying [test].
  ///
  /// Returns `null` if there are either none
  /// or more than one element and index satisfying [test].
  T? singleWhereIndexedOrNull(bool Function(int index, T element) test) {
    T? result;
    var found = false;
    var index = 0;
    for (var element in this) {
      if (test(index++, element)) {
        if (!found) {
          result = element;
          found = true;
        } else {
          return null;
        }
      }
    }
    return result;
  }

  /// The single element of the iterable, or `null`.
  ///
  /// The value is `null` if the iterable is empty
  /// or it contains more than one element.
  T? get singleOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var result = iterator.current;
      if (!iterator.moveNext()) {
        return result;
      }
    }
    return null;
  }

  /// Groups elements by [keyOf] then folds the elements in each group.
  ///
  /// A key is found for each element using [keyOf].
  /// Then the elements with the same key are all folded using [combine].
  /// The first call to [combine] for a particular key receives [null] as
  /// the previous value, the remaining ones receive the result of the previous call.
  ///
  /// Can be used to _group_ elements into arbitrary collections.
  /// For example [groupSetsBy] could be written as:
  /// ```dart
  /// iterable.groupFoldBy(keyOf,
  ///     (Set<T>? previous, T element) => (previous ?? <T>{})..add(element));
  /// ````
  Map<K, G> groupFoldBy<K, G>(
      K Function(T element) keyOf, G Function(G? previous, T element) combine) {
    var result = <K, G>{};
    for (var element in this) {
      var key = keyOf(element);
      result[key] = combine(result[key], element);
    }
    return result;
  }

  /// Groups elements into sets by [keyOf].
  Map<K, Set<T>> groupSetsBy<K>(K Function(T element) keyOf) {
    var result = <K, Set<T>>{};
    for (var element in this) {
      (result[keyOf(element)] ??= <T>{}).add(element);
    }
    return result;
  }

  /// Groups elements into lists by [keyOf].
  Map<K, List<T>> groupListsBy<K>(K Function(T element) keyOf) {
    var result = <K, List<T>>{};
    for (var element in this) {
      (result[keyOf(element)] ??= []).add(element);
    }
    return result;
  }

  /// Splits the elements into chunks before some elements.
  ///
  /// Each element except the first is checked using [test]
  /// for whether it should start a new chunk.
  /// If so, the elements since the previous chunk-starting element
  /// are emitted as a list.
  /// Any final elements are emitted at the end.
  ///
  /// Example:
  /// Example:
  /// ```dart
  /// var parts = [1, 2, 3, 4, 5, 6, 7, 8, 9].split(isPrime);
  /// print(parts); // ([1], [2], [3, 4], [5, 6], [7, 8, 9])
  /// ```
  Iterable<List<T>> splitBefore(bool Function(T element) test) =>
      splitBeforeIndexed((_, element) => test(element));

  /// Splits the elements into chunks before some elements.
  ///
  /// Each element is checked using [test] for whether it should start a new chunk.
  /// If so, the elements since the previous chunk-starting element
  /// are emitted as a list.
  /// Any final elements are emitted at the end.
  ///
  /// Example:
  /// ```dart
  /// var parts = [1, 0, 2, 1, 5, 7, 6, 8, 9].splitAfter(isPrime);
  /// print(parts); // ([1, 0, 2], [1, 5], [7], [6, 8, 9])
  /// ```
  Iterable<List<T>> splitAfter(bool Function(T element) test) =>
      splitAfterIndexed((_, element) => test(element));

  /// Splits the elements into chunks between some elements.
  ///
  /// Each pair of adjacent elements are checked using [test]
  /// for whether a chunk should end between them.
  /// If so, the elements since the previous chunk-splitting elements
  /// are emitted as a list.
  /// Any final elements are emitted at the end.
  ///
  /// Example:
  /// ```dart
  /// var parts = [1, 0, 2, 1, 5, 7, 6, 8, 9].splitBetween((v1, v2) => v1 > v2);
  /// print(parts); // ([1], [0, 2], [1, 5, 7], [6, 8, 9])
  /// ```
  Iterable<List<T>> splitBetween(bool Function(T first, T second) test) =>
      splitBetweenIndexed((_, first, second) => test(first, second));

  /// Splits the elements into chunks before some elements and indices.
  ///
  /// Each element and index except the first is checked using [test]
  /// for whether it should start a new chunk.
  /// If so, the elements since the previous chunk-starting element
  /// are emitted as a list.
  /// Any final elements are emitted at the end.
  ///
  /// Example:
  /// ```dart
  /// var parts = [1, 0, 2, 1, 5, 7, 6, 8, 9]
  ///     .splitBeforeIndexed((i, v) => i < v);
  /// print(parts); // ([1], [0, 2], [1, 5, 7], [6, 8, 9])
  /// ```
  Iterable<List<T>> splitBeforeIndexed(
      bool Function(int index, T element) test) sync* {
    var iterator = this.iterator;
    if (!iterator.moveNext()) {
      return;
    }
    var index = 1;
    var chunk = [iterator.current];
    while (iterator.moveNext()) {
      var element = iterator.current;
      if (test(index++, element)) {
        yield chunk;
        chunk = [];
      }
      chunk.add(element);
    }
    yield chunk;
  }

  /// Splits the elements into chunks after some elements and indices.
  ///
  /// Each element and index is checked using [test]
  /// for whether it should end the current chunk.
  /// If so, the elements since the previous chunk-ending element
  /// are emitted as a list.
  /// Any final elements are emitted at the end, whether the last
  /// element should be split after or not.
  ///
  /// Example:
  /// ```dart
  /// var parts = [1, 0, 2, 1, 5, 7, 6, 8, 9].splitAfterIndexed((i, v) => i < v);
  /// print(parts); // ([1, 0], [2, 1], [5, 7, 6], [8, 9])
  /// ```
  Iterable<List<T>> splitAfterIndexed(
      bool Function(int index, T element) test) sync* {
    var index = 0;
    List<T>? chunk;
    for (var element in this) {
      (chunk ??= []).add(element);
      if (test(index++, element)) {
        yield chunk;
        chunk = null;
      }
    }
    if (chunk != null) yield chunk;
  }

  /// Splits the elements into chunks between some elements and indices.
  ///
  /// Each pair of adjacent elements and the index of the latter are
  /// checked using [test] for whether a chunk should end between them.
  /// If so, the elements since the previous chunk-splitting elements
  /// are emitted as a list.
  /// Any final elements are emitted at the end.
  ///
  /// Example:
  /// ```dart
  /// var parts = [1, 0, 2, 1, 5, 7, 6, 8, 9]
  ///    .splitBetweenIndexed((i, v1, v2) => v1 > v2);
  /// print(parts); // ([1], [0, 2], [1, 5, 7], [6, 8, 9])
  /// ```
  Iterable<List<T>> splitBetweenIndexed(
      bool Function(int index, T first, T second) test) sync* {
    var iterator = this.iterator;
    if (!iterator.moveNext()) return;
    var previous = iterator.current;
    var chunk = <T>[previous];
    var index = 1;
    while (iterator.moveNext()) {
      var element = iterator.current;
      if (test(index++, previous, element)) {
        yield chunk;
        chunk = [];
      }
      chunk.add(element);
      previous = element;
    }
    yield chunk;
  }

  /// Whether no element satisfies [test].
  ///
  /// Returns true if no element satisfies [test],
  /// and false if at least one does.
  ///
  /// Equivalent to `iterable.every((x) => !test(x))` or
  /// `!iterable.any(test)`.
  bool none(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return false;
    }
    return true;
  }

  /// Contiguous [slice]s of [this] with the given [length].
  ///
  /// Each slice is [length] elements long, except for the last one which may be
  /// shorter if [this] contains too few elements. Each slice begins after the
  /// last one ends. The [length] must be greater than zero.
  ///
  /// For example, `{1, 2, 3, 4, 5}.slices(2)` returns `([1, 2], [3, 4], [5])`.
  Iterable<List<T>> slices(int length) sync* {
    if (length < 1) throw RangeError.range(length, 1, null, 'length');

    var iterator = this.iterator;
    while (iterator.moveNext()) {
      var slice = [iterator.current];
      for (var i = 1; i < length && iterator.moveNext(); i++) {
        slice.add(iterator.current);
      }
      yield slice;
    }
  }
}

/// Extensions that apply to iterables with a nullable element type.
extension IterableNullableExtension<T extends Object> on Iterable<T?> {
  /// The non-`null` elements of this `Iterable`.
  ///
  /// Returns an iterable which emits all the non-`null` elements
  /// of this iterable, in their original iteration order.
  ///
  /// For an `Iterable<X?>`, this method is equivalent to `.whereType<X>()`.
  Iterable<T> whereNotNull() sync* {
    for (var element in this) {
      if (element != null) yield element;
    }
  }
}

/// Extensions that apply to iterables of numbers.
///
/// Specialized version of some extensions of [IterableComparableExtension]
/// since doubles require special handling of [double.nan].
extension IterableNumberExtension on Iterable<num> {
  /// A minimal element of the iterable, or `null` it the iterable is empty.
  num? get minOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      if (value.isNaN) {
        return value;
      }
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (newValue.isNaN) {
          return newValue;
        }
        if (newValue < value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A minimal element of the iterable.
  ///
  /// The iterable must not be empty.
  num get min => minOrNull ?? (throw StateError('No element'));

  /// A maximal element of the iterable, or `null` if the iterable is empty.
  num? get maxOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      if (value.isNaN) {
        return value;
      }
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (newValue.isNaN) {
          return newValue;
        }
        if (newValue > value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A maximal element of the iterable.
  ///
  /// The iterable must not be empty.
  num get max => maxOrNull ?? (throw StateError('No element'));

  /// The sum of the elements.
  ///
  /// The sum is zero if the iterable is empty.
  num get sum {
    num result = 0;
    for (var value in this) {
      result += value;
    }
    return result;
  }

  /// The arithmetic mean of the elements of a non-empty iterable.
  ///
  /// The arithmetic mean is the sum of the elements
  /// divided by the number of elements.
  ///
  /// The iterable must not be empty.
  double get average {
    var result = 0.0;
    var count = 0;
    for (var value in this) {
      count += 1;
      result += (value - result) / count;
    }
    if (count == 0) throw StateError('No elements');
    return result;
  }
}

/// Extension on iterables of integers.
///
/// Specialized version of some extensions of [IterableNumberExtension] or
/// [IterableComparableExtension] since integers are only `Comparable<num>`.
extension IterableIntegerExtension on Iterable<int> {
  /// A minimal element of the iterable, or `null` it the iterable is empty.
  int? get minOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (newValue < value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A minimal element of the iterable.
  ///
  /// The iterable must not be empty.
  int get min => minOrNull ?? (throw StateError('No element'));

  /// A maximal element of the iterable, or `null` if the iterable is empty.
  int? get maxOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (newValue > value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A maximal element of the iterable.
  ///
  /// The iterable must not be empty.
  int get max => maxOrNull ?? (throw StateError('No element'));

  /// The sum of the elements.
  ///
  /// The sum is zero if the iterable is empty.
  int get sum {
    var result = 0;
    for (var value in this) {
      result += value;
    }
    return result;
  }

  /// The arithmetic mean of the elements of a non-empty iterable.
  ///
  /// The arithmetic mean is the sum of the elements
  /// divided by the number of elements.
  /// This method is specialized for integers,
  /// and may give a different result than [IterableNumberExtension.average]
  /// for the same values, because the the number algorithm
  /// converts all numbers to doubles.
  ///
  /// The iterable must not be empty.
  double get average {
    var average = 0;
    var remainder = 0;
    var count = 0;
    for (var value in this) {
      // Invariant: Sum of values so far = average * count + remainder.
      // (Unless overflow has occurred).
      count += 1;
      var delta = value - average + remainder;
      average += delta ~/ count;
      remainder = delta.remainder(count);
    }
    if (count == 0) throw StateError('No elements');
    return average + remainder / count;
  }
}

/// Extension on iterables of double.
///
/// Specialized version of some extensions of [IterableNumberExtension] or
/// [IterableComparableExtension] since doubles are only `Comparable<num>`.
extension IterableDoubleExtension on Iterable<double> {
  /// A minimal element of the iterable, or `null` it the iterable is empty.
  double? get minOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      if (value.isNaN) {
        return value;
      }
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (newValue.isNaN) {
          return newValue;
        }
        if (newValue < value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A minimal element of the iterable.
  ///
  /// The iterable must not be empty.
  double get min => minOrNull ?? (throw StateError('No element'));

  /// A maximal element of the iterable, or `null` if the iterable is empty.
  double? get maxOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      if (value.isNaN) {
        return value;
      }
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (newValue.isNaN) {
          return newValue;
        }
        if (newValue > value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A maximal element of the iterable.
  ///
  /// The iterable must not be empty.
  double get max => maxOrNull ?? (throw StateError('No element'));

  /// The sum of the elements.
  ///
  /// The sum is zero if the iterable is empty.
  double get sum {
    var result = 0.0;
    for (var value in this) {
      result += value;
    }
    return result;
  }
}

/// Extensions on iterables whose elements are also iterables.
extension IterableIterableExtension<T> on Iterable<Iterable<T>> {
  /// The sequential elements of each iterable in this iterable.
  ///
  /// Iterates the elements of this iterable.
  /// For each one, which is itself an iterable,
  /// all the elements of that are emitted
  /// on the returned iterable, before moving on to the next element.
  Iterable<T> get flattened sync* {
    for (var elements in this) {
      yield* elements;
    }
  }
}

/// Extensions that apply to iterables of [Comparable] elements.
///
/// These operations can assume that the elements have a natural ordering,
/// and can therefore omit, or make it optional, for the user to provide
/// a [Comparator].
extension IterableComparableExtension<T extends Comparable<T>> on Iterable<T> {
  /// A minimal element of the iterable, or `null` it the iterable is empty.
  T? get minOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (value.compareTo(newValue) > 0) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A minimal element of the iterable.
  ///
  /// The iterable must not be empty.
  T get min => minOrNull ?? (throw StateError('No element'));

  /// A maximal element of the iterable, or `null` if the iterable is empty.
  T? get maxOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var value = iterator.current;
      while (iterator.moveNext()) {
        var newValue = iterator.current;
        if (value.compareTo(newValue) < 0) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  }

  /// A maximal element of the iterable.
  ///
  /// The iterable must not be empty.
  T get max => maxOrNull ?? (throw StateError('No element'));

  /// Creates a sorted list of the elements of the iterable.
  ///
  /// If the [compare] function is not supplied, the sorting uses the
  /// natural [Comparable] ordering of the elements.
  List<T> sorted([Comparator<T>? compare]) => [...this]..sort(compare);

  /// Whether the elements are sorted by the [compare] ordering.
  ///
  /// If [compare] is omitted, it defaults to comparing the
  /// elements using their natural [Comparable] ordering.
  bool isSorted([Comparator<T>? compare]) {
    if (compare != null) {
      return IterableExtension(this).isSorted(compare);
    }
    var iterator = this.iterator;
    if (!iterator.moveNext()) return true;
    var previousElement = iterator.current;
    while (iterator.moveNext()) {
      var element = iterator.current;
      if (previousElement.compareTo(element) > 0) return false;
      previousElement = element;
    }
    return true;
  }
}

/// Extensions on comparator functions.
extension ComparatorExtension<T> on Comparator<T> {
  /// The inverse ordering of this comparator.
  Comparator<T> get inverse => (T a, T b) => this(b, a);

  /// Makes a comparator on [R] values using this comparator.
  ///
  /// Compares [R] values by comparing their [keyOf] value
  /// using this comparator.
  Comparator<R> compareBy<R>(T Function(R) keyOf) =>
      (R a, R b) => this(keyOf(a), keyOf(b));

  /// Combine comparators sequentially.
  ///
  /// Creates a comparator which orders elements the same way as
  /// this comparator, except that when two elements are considered
  /// equal, the [tieBreaker] comparator is used instead.
  Comparator<T> then(Comparator<T> tieBreaker) => (T a, T b) {
        var result = this(a, b);
        if (result == 0) result = tieBreaker(a, b);
        return result;
      };
}
