// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The iterator for `CombinedIterableView` and `CombinedListView`.
///
/// Moves through each iterable's iterator in sequence.
class CombinedIterator<T> implements Iterator<T> {
  /// The iterators that this combines, or `null` if done iterating.
  ///
  /// Because this comes from a call to [Iterable.map], it's lazy and will
  /// avoid instantiating unnecessary iterators.
  Iterator<Iterator<T>>? _iterators;

  CombinedIterator(Iterator<Iterator<T>> iterators) : _iterators = iterators {
    if (!iterators.moveNext()) _iterators = null;
  }

  @override
  T get current {
    var iterators = _iterators;
    if (iterators != null) return iterators.current.current;
    return null as T;
  }

  @override
  bool moveNext() {
    var iterators = _iterators;
    if (iterators != null) {
      do {
        if (iterators.current.moveNext()) {
          return true;
        }
      } while (iterators.moveNext());
      _iterators = null;
    }
    return false;
  }
}
