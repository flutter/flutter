// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// This [Iterable] mixin implements all [Iterable] members except `iterator`.
///
/// All other methods are implemented in terms of `iterator`.
// @Deprecated("Use Iterable instead")
typedef IterableMixin<E> = Iterable<E>;

/// Base class for implementing [Iterable].
///
/// This class implements all methods of [Iterable], except [Iterable.iterator],
/// in terms of `iterator`.
// @Deprecated("Use Iterable instead")
typedef IterableBase<E> = Iterable<E>;

/// Operations on iterables with nullable elements.
@Since("3.0")
extension NullableIterableExtensions<T extends Object> on Iterable<T?> {
  /// The non-`null` elements of this iterable.
  ///
  /// The same elements as this iterable, except that `null` values
  /// are omitted.
  Iterable<T> get nonNulls => NonNullsIterable<T>(this);
}

/// Operations on iterables.
@Since("3.0")
extension IterableExtensions<T> on Iterable<T> {
  /// Pairs of elements of the indices and elements of this iterable.
  ///
  /// The elements are `(0, this.first)` through
  /// `(this.length - 1, this.last)`, in index/iteration order.
  @pragma('vm:prefer-inline')
  Iterable<(int, T)> get indexed => IndexedIterable<T>(this, 0);

  /// The first element of this iterator, or `null` if the iterable is empty.
  T? get firstOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  /// The last element of this iterable, or `null` if the iterable is empty.
  ///
  /// This computation may not be efficient.
  /// The last value is potentially found by iterating the entire iterable
  /// and temporarily storing every value.
  /// The process only iterates the iterable once.
  /// If iterating more than once is not a problem, it may be more efficient
  /// for some iterables to do:
  /// ```dart
  /// var lastOrNull = iterable.isEmpty ? null : iterable.last;
  /// ```
  T? get lastOrNull {
    if (this is EfficientLengthIterable) {
      if (isEmpty) return null;
      return last;
    }
    var iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    T result;
    do {
      result = iterator.current;
    } while (iterator.moveNext());
    return result;
  }

  /// The single element of this iterator, or `null`.
  ///
  /// If the iterator has precisely one element, this is that element.
  /// Otherwise, if the iterator has zero elements, or it has two or more,
  /// the value is `null`.
  T? get singleOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var result = iterator.current;
      if (!iterator.moveNext()) return result;
    }
    return null;
  }

  /// The element at position [index] of this iterable, or `null`.
  ///
  /// The [index] is zero based, and must be non-negative.
  ///
  /// Returns the result of `elementAt(index)` if the iterable has
  /// at least `index + 1` elements, and `null` otherwise.
  T? elementAtOrNull(int index) {
    RangeError.checkNotNegative(index, "index");
    if (this is EfficientLengthIterable) {
      if (index >= length) return null;
      return elementAt(index);
    }
    var iterator = this.iterator;
    do {
      if (!iterator.moveNext()) return null;
    } while (--index >= 0);
    return iterator.current;
  }
}
