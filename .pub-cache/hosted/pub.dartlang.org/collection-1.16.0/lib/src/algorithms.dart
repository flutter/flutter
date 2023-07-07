// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A selection of data manipulation algorithms.
library pkg.collection.algorithms;

import 'dart:math' show Random;

import 'utils.dart';

/// Returns a position of the [value] in [sortedList], if it is there.
///
/// If the list isn't sorted according to the [compare] function, the result
/// is unpredictable.
///
/// If [compare] is omitted, this defaults to calling [Comparable.compareTo] on
/// the objects. In this case, the objects must be [Comparable].
///
/// Returns -1 if [value] is not in the list.
int binarySearch<E>(List<E> sortedList, E value,
    {int Function(E, E)? compare}) {
  compare ??= defaultCompare;
  return binarySearchBy<E, E>(sortedList, identity, compare, value);
}

/// Returns a position of the [value] in [sortedList], if it is there.
///
/// If the list isn't sorted according to the [compare] function on the [keyOf]
/// property of the elements, the result is unpredictable.
///
/// Returns -1 if [value] is not in the list by default.
///
/// If [start] and [end] are supplied, only that range is searched,
/// and only that range need to be sorted.
int binarySearchBy<E, K>(List<E> sortedList, K Function(E element) keyOf,
    int Function(K, K) compare, E value,
    [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, sortedList.length);
  var min = start;
  var max = end;
  var key = keyOf(value);
  while (min < max) {
    var mid = min + ((max - min) >> 1);
    var element = sortedList[mid];
    var comp = compare(keyOf(element), key);
    if (comp == 0) return mid;
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -1;
}

/// Returns the first position in [sortedList] that does not compare less than
/// [value].
///
/// If the list isn't sorted according to the [compare] function, the result
/// is unpredictable.
///
/// If [compare] is omitted, this defaults to calling [Comparable.compareTo] on
/// the objects. In this case, the objects must be [Comparable].
///
/// Returns [sortedList.length] if all the items in [sortedList] compare less
/// than [value].
int lowerBound<E>(List<E> sortedList, E value, {int Function(E, E)? compare}) {
  compare ??= defaultCompare;
  return lowerBoundBy<E, E>(sortedList, identity, compare, value);
}

/// Returns the first position in [sortedList] that is not before [value].
///
/// Elements are compared using the [compare] function of the [keyOf] property of
/// the elements.
/// If the list isn't sorted according to this order, the result is unpredictable.
///
/// Returns [sortedList.length] if all the items in [sortedList] are before [value].
///
/// If [start] and [end] are supplied, only that range is searched,
/// and only that range need to be sorted.
int lowerBoundBy<E, K>(List<E> sortedList, K Function(E element) keyOf,
    int Function(K, K) compare, E value,
    [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, sortedList.length);
  var min = start;
  var max = end;
  var key = keyOf(value);
  while (min < max) {
    var mid = min + ((max - min) >> 1);
    var element = sortedList[mid];
    var comp = compare(keyOf(element), key);
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return min;
}

/// Shuffles a list randomly.
///
/// A sub-range of a list can be shuffled by providing [start] and [end].
///
/// If [start] or [end] are omitted,
/// they default to the start and end of the list.
///
/// If [random] is omitted, it defaults to a new instance of [Random].
void shuffle(List elements, [int start = 0, int? end, Random? random]) {
  random ??= Random();
  end ??= elements.length;
  var length = end - start;
  while (length > 1) {
    var pos = random.nextInt(length);
    length--;
    var tmp1 = elements[start + pos];
    elements[start + pos] = elements[start + length];
    elements[start + length] = tmp1;
  }
}

/// Reverses a list, or a part of a list, in-place.
void reverse<E>(List<E> elements, [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, elements.length);
  _reverse<E>(elements, start, end);
}

/// Internal helper function that assumes valid arguments.
void _reverse<E>(List<E> elements, int start, int end) {
  for (var i = start, j = end - 1; i < j; i++, j--) {
    var tmp = elements[i];
    elements[i] = elements[j];
    elements[j] = tmp;
  }
}

/// Sort a list between [start] (inclusive) and [end] (exclusive) using
/// insertion sort.
///
/// If [compare] is omitted, this defaults to calling [Comparable.compareTo] on
/// the objects. In this case, the objects must be [Comparable].
///
/// Insertion sort is a simple sorting algorithm. For `n` elements it does on
/// the order of `n * log(n)` comparisons but up to `n` squared moves. The
/// sorting is performed in-place, without using extra memory.
///
/// For short lists the many moves have less impact than the simple algorithm,
/// and it is often the favored sorting algorithm for short lists.
///
/// This insertion sort is stable: Equal elements end up in the same order
/// as they started in.
void insertionSort<E>(List<E> elements,
    {int Function(E, E)? compare, int start = 0, int? end}) {
  // If the same method could have both positional and named optional
  // parameters, this should be (list, [start, end], {compare}).
  compare ??= defaultCompare;
  end ??= elements.length;

  for (var pos = start + 1; pos < end; pos++) {
    var min = start;
    var max = pos;
    var element = elements[pos];
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      var comparison = compare(element, elements[mid]);
      if (comparison < 0) {
        max = mid;
      } else {
        min = mid + 1;
      }
    }
    elements.setRange(min + 1, pos + 1, elements, min);
    elements[min] = element;
  }
}

/// Generalized insertion sort.
///
/// Performs insertion sort on the [elements] range from [start] to [end].
/// Ordering is the [compare] of the [keyOf] of the elements.
void insertionSortBy<E, K>(List<E> elements, K Function(E element) keyOf,
    int Function(K a, K b) compare,
    [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, elements.length);
  _movingInsertionSort(elements, keyOf, compare, start, end, elements, start);
}

/// Limit below which merge sort defaults to insertion sort.
const int _mergeSortLimit = 32;

/// Sorts a list between [start] (inclusive) and [end] (exclusive) using the
/// merge sort algorithm.
///
/// If [compare] is omitted, this defaults to calling [Comparable.compareTo] on
/// the objects. If any object is not [Comparable], that throws a [TypeError].
///
/// Merge-sorting works by splitting the job into two parts, sorting each
/// recursively, and then merging the two sorted parts.
///
/// This takes on the order of `n * log(n)` comparisons and moves to sort
/// `n` elements, but requires extra space of about the same size as the list
/// being sorted.
///
/// This merge sort is stable: Equal elements end up in the same order
/// as they started in.
void mergeSort<E>(List<E> elements,
    {int start = 0, int? end, int Function(E, E)? compare}) {
  end = RangeError.checkValidRange(start, end, elements.length);
  compare ??= defaultCompare;

  var length = end - start;
  if (length < 2) return;
  if (length < _mergeSortLimit) {
    insertionSort(elements, compare: compare, start: start, end: end);
    return;
  }
  // Special case the first split instead of directly calling
  // _mergeSort, because the _mergeSort requires its target to
  // be different from its source, and it requires extra space
  // of the same size as the list to sort.
  // This split allows us to have only half as much extra space,
  // and allows the sorted elements to end up in the original list.
  var firstLength = (end - start) >> 1;
  var middle = start + firstLength;
  var secondLength = end - middle;
  // secondLength is always the same as firstLength, or one greater.
  var scratchSpace = List<E>.filled(secondLength, elements[start]);
  E Function(E) id = identity;
  _mergeSort(elements, id, compare, middle, end, scratchSpace, 0);
  var firstTarget = end - firstLength;
  _mergeSort(elements, id, compare, start, middle, elements, firstTarget);
  _merge(id, compare, elements, firstTarget, end, scratchSpace, 0, secondLength,
      elements, start);
}

/// Sort [elements] using a merge-sort algorithm.
///
/// The elements are compared using [compare] on the value provided by [keyOf]
/// on the element.
/// If [start] and [end] are provided, only that range is sorted.
///
/// Uses insertion sort for smaller sublists.
void mergeSortBy<E, K>(List<E> elements, K Function(E element) keyOf,
    int Function(K a, K b) compare,
    [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, elements.length);
  var length = end - start;
  if (length < 2) return;
  if (length < _mergeSortLimit) {
    _movingInsertionSort(elements, keyOf, compare, start, end, elements, start);
    return;
  }
  // Special case the first split instead of directly calling
  // _mergeSort, because the _mergeSort requires its target to
  // be different from its source, and it requires extra space
  // of the same size as the list to sort.
  // This split allows us to have only half as much extra space,
  // and it ends up in the original place.
  var middle = start + (length >> 1);
  var firstLength = middle - start;
  var secondLength = end - middle;
  // secondLength is always the same as firstLength, or one greater.
  var scratchSpace = List<E>.filled(secondLength, elements[start]);
  _mergeSort(elements, keyOf, compare, middle, end, scratchSpace, 0);
  var firstTarget = end - firstLength;
  _mergeSort(elements, keyOf, compare, start, middle, elements, firstTarget);
  _merge(keyOf, compare, elements, firstTarget, end, scratchSpace, 0,
      secondLength, elements, start);
}

/// Performs an insertion sort into a potentially different list than the
/// one containing the original values.
///
/// It will work in-place as well.
void _movingInsertionSort<E, K>(
    List<E> list,
    K Function(E element) keyOf,
    int Function(K, K) compare,
    int start,
    int end,
    List<E> target,
    int targetOffset) {
  var length = end - start;
  if (length == 0) return;
  target[targetOffset] = list[start];
  for (var i = 1; i < length; i++) {
    var element = list[start + i];
    var elementKey = keyOf(element);
    var min = targetOffset;
    var max = targetOffset + i;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      if (compare(elementKey, keyOf(target[mid])) < 0) {
        max = mid;
      } else {
        min = mid + 1;
      }
    }
    target.setRange(min + 1, targetOffset + i + 1, target, min);
    target[min] = element;
  }
}

/// Sorts [elements] from [start] to [end] into [target] at [targetOffset].
///
/// The `target` list must be able to contain the range from `start` to `end`
/// after `targetOffset`.
///
/// Allows target to be the same list as [elements], as long as it's not
/// overlapping the `start..end` range.
void _mergeSort<E, K>(
    List<E> elements,
    K Function(E element) keyOf,
    int Function(K, K) compare,
    int start,
    int end,
    List<E> target,
    int targetOffset) {
  var length = end - start;
  if (length < _mergeSortLimit) {
    _movingInsertionSort<E, K>(
        elements, keyOf, compare, start, end, target, targetOffset);
    return;
  }
  var middle = start + (length >> 1);
  var firstLength = middle - start;
  var secondLength = end - middle;
  // Here secondLength >= firstLength (differs by at most one).
  var targetMiddle = targetOffset + firstLength;
  // Sort the second half into the end of the target area.
  _mergeSort(elements, keyOf, compare, middle, end, target, targetMiddle);
  // Sort the first half into the end of the source area.
  _mergeSort(elements, keyOf, compare, start, middle, elements, middle);
  // Merge the two parts into the target area.
  _merge(keyOf, compare, elements, middle, middle + firstLength, target,
      targetMiddle, targetMiddle + secondLength, target, targetOffset);
}

/// Merges two lists into a target list.
///
/// One of the input lists may be positioned at the end of the target
/// list.
///
/// For equal object, elements from [firstList] are always preferred.
/// This allows the merge to be stable if the first list contains elements
/// that started out earlier than the ones in [secondList]
void _merge<E, K>(
    K Function(E element) keyOf,
    int Function(K, K) compare,
    List<E> firstList,
    int firstStart,
    int firstEnd,
    List<E> secondList,
    int secondStart,
    int secondEnd,
    List<E> target,
    int targetOffset) {
  // No empty lists reaches here.
  assert(firstStart < firstEnd);
  assert(secondStart < secondEnd);
  var cursor1 = firstStart;
  var cursor2 = secondStart;
  var firstElement = firstList[cursor1++];
  var firstKey = keyOf(firstElement);
  var secondElement = secondList[cursor2++];
  var secondKey = keyOf(secondElement);
  while (true) {
    if (compare(firstKey, secondKey) <= 0) {
      target[targetOffset++] = firstElement;
      if (cursor1 == firstEnd) break; // Flushing second list after loop.
      firstElement = firstList[cursor1++];
      firstKey = keyOf(firstElement);
    } else {
      target[targetOffset++] = secondElement;
      if (cursor2 != secondEnd) {
        secondElement = secondList[cursor2++];
        secondKey = keyOf(secondElement);
        continue;
      }
      // Second list empties first. Flushing first list here.
      target[targetOffset++] = firstElement;
      target.setRange(targetOffset, targetOffset + (firstEnd - cursor1),
          firstList, cursor1);
      return;
    }
  }
  // First list empties first. Reached by break above.
  target[targetOffset++] = secondElement;
  target.setRange(
      targetOffset, targetOffset + (secondEnd - cursor2), secondList, cursor2);
}

/// Sort [elements] using a quick-sort algorithm.
///
/// The elements are compared using [compare] on the elements.
/// If [start] and [end] are provided, only that range is sorted.
///
/// Uses insertion sort for smaller sublists.
void quickSort<E>(List<E> elements, int Function(E a, E b) compare,
    [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, elements.length);
  _quickSort<E, E>(elements, identity, compare, Random(), start, end);
}

/// Sort [elements] using a quick-sort algorithm.
///
/// The elements are compared using [compare] on the value provided by [keyOf]
/// on the element.
/// If [start] and [end] are provided, only that range is sorted.
///
/// Uses insertion sort for smaller sublists.
void quickSortBy<E, K>(
    List<E> list, K Function(E element) keyOf, int Function(K a, K b) compare,
    [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, list.length);
  _quickSort(list, keyOf, compare, Random(), start, end);
}

void _quickSort<E, K>(List<E> list, K Function(E element) keyOf,
    int Function(K a, K b) compare, Random random, int start, int end) {
  const minQuickSortLength = 24;
  var length = end - start;
  while (length >= minQuickSortLength) {
    var pivotIndex = random.nextInt(length) + start;
    var pivot = list[pivotIndex];
    var pivotKey = keyOf(pivot);
    var endSmaller = start;
    var startGreater = end;
    var startPivots = end - 1;
    list[pivotIndex] = list[startPivots];
    list[startPivots] = pivot;
    while (endSmaller < startPivots) {
      var current = list[endSmaller];
      var relation = compare(keyOf(current), pivotKey);
      if (relation < 0) {
        endSmaller++;
      } else {
        startPivots--;
        var currentTarget = startPivots;
        list[endSmaller] = list[startPivots];
        if (relation > 0) {
          startGreater--;
          currentTarget = startGreater;
          list[startPivots] = list[startGreater];
        }
        list[currentTarget] = current;
      }
    }
    if (endSmaller - start < end - startGreater) {
      _quickSort(list, keyOf, compare, random, start, endSmaller);
      start = startGreater;
    } else {
      _quickSort(list, keyOf, compare, random, startGreater, end);
      end = endSmaller;
    }
    length = end - start;
  }
  _movingInsertionSort<E, K>(list, keyOf, compare, start, end, list, start);
}
