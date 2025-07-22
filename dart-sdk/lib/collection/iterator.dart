// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// Wrapper for [Iterator] providing the pre-Dart 1.0 iterator interface.
///
/// This class should not be used in new code.
///
/// The [HasNextIterator] class wraps an [Iterator] and provides methods to
/// iterate over an object using [hasNext] and [next].
///
/// The [HasNextIterator] does not implement the [Iterator] interface.
///
/// This class was intended for migration to the current [Iterator]
/// interface, from an earlier interface using [hasNext] and [next].
/// The API change happened in the Dart 1.0 release.
/// Any other use of this class should be migrated to using the
/// current API directly, e.g., using a separate variable to
/// cache the [Iterator.moveNext] result, so that [hasNext] can be
/// checked multiple times.
@Deprecated("Will be removed in a later version of the Dart SDK")
final class HasNextIterator<E> {
  Iterator<E> _iterator;

  /// Cache for `_iterator.moveNext()`, used by `hasNext`.
  ///
  /// Is reset to `null` when [next] consumes a current element.
  /// Will not change again after becoming `false`.
  bool? _hasNext;

  HasNextIterator(Iterator<E> iterator) : _iterator = iterator;

  /// Whether the iterator has a next element.
  ///
  /// Should be checked to be `true` before calling [next].
  bool get hasNext => _ensureHasNext;

  /// Ensures [_hasNext] has a value, and provides that value.
  bool get _ensureHasNext => _hasNext ??= _iterator.moveNext();

  /// Provides the next element of the iterable, and moves past it.
  ///
  /// Must only be used when [hasNext] is `true`.
  /// The value of [hasNext] can change after calling this method.
  E next() {
    if (_ensureHasNext) {
      _hasNext = null;
      return _iterator.current;
    }
    throw StateError("No more elements");
  }
}
