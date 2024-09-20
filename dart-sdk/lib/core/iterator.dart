// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An interface for getting items, one at a time, from an object.
///
/// The for-in construct transparently uses `Iterator` to test for the end
/// of the iteration, and to get each item (or _element_).
///
/// If the object iterated over is changed during the iteration, the
/// behavior is unspecified.
///
/// The `Iterator` is initially positioned before the first element.
/// Before accessing the first element the iterator must thus be advanced using
/// [moveNext] to point to the first element.
/// If no element is left, then [moveNext] returns false,
/// and all further calls to [moveNext] will also return false.
///
/// The [current] value must not be accessed before calling [moveNext]
/// or after a call to [moveNext] has returned false.
///
/// A typical usage of an `Iterator` looks as follows:
/// ```dart
/// var it = obj.iterator;
/// while (it.moveNext()) {
///   use(it.current);
/// }
/// ```
/// **See also:**
/// [Iteration](https://dart.dev/guides/libraries/library-tour#iteration)
/// in the [library tour](https://dart.dev/guides/libraries/library-tour)
abstract interface class Iterator<E> {
  /// Advances the iterator to the next element of the iteration.
  ///
  /// Should be called before reading [current].
  /// If the call to `moveNext` returns `true`,
  /// then [current] will contain the next element of the iteration
  /// until `moveNext` is called again.
  /// If the call returns `false`, there are no further elements
  /// and [current] should not be used any more.
  ///
  /// It is safe to call [moveNext] after it has already returned `false`,
  /// but it must keep returning `false` and not have any other effect.
  ///
  /// A call to `moveNext` may throw for various reasons,
  /// including a concurrent change to an underlying collection.
  /// If that happens, the iterator may be in an inconsistent
  /// state, and any further behavior of the iterator is unspecified,
  /// including the effect of reading [current].
  /// ```dart
  /// final colors = ['blue', 'yellow', 'red'];
  /// final colorsIterator = colors.iterator;
  /// print(colorsIterator.moveNext()); // true
  /// print(colorsIterator.moveNext()); // true
  /// print(colorsIterator.moveNext()); // true
  /// print(colorsIterator.moveNext()); // false
  /// ```
  bool moveNext();

  /// The current element.
  ///
  /// If the iterator has not yet been moved to the first element
  /// ([moveNext] has not been called yet),
  /// or if the iterator has been moved past the last element of the [Iterable]
  /// ([moveNext] has returned false),
  /// then [current] is unspecified.
  /// An [Iterator] may either throw or return an iterator specific default value
  /// in that case.
  ///
  /// The `current` getter should keep its value until the next call to
  /// [moveNext], even if an underlying collection changes.
  /// After a successful call to `moveNext`, the user doesn't need to cache
  /// the current value, but can keep reading it from the iterator.
  /// ```dart
  /// final colors = ['blue', 'yellow', 'red'];
  /// var colorsIterator = colors.iterator;
  /// while (colorsIterator.moveNext()) {
  ///   print(colorsIterator.current);
  /// }
  /// ```
  /// The output of the example is:
  /// ```
  /// blue
  /// yellow
  /// red
  /// ```
  E get current;
}
