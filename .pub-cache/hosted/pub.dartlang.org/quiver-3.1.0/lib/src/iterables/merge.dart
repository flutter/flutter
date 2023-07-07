// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';

/// Returns the result of merging an [Iterable] of [Iterable]s, according to
/// the order specified by the [compare] function. This function assumes the
/// provided iterables are already sorted according to the provided [compare]
/// function. It will not check for this condition or sort the iterables.
///
/// The compare function must act as a [Comparator]. If [compare] is omitted,
/// [Comparable.compare] is used.
///
/// If any of the [iterables] contain null elements, an exception will be
/// thrown.
Iterable<T> merge<T>(Iterable<Iterable<T>> iterables,
    [Comparator<T>? compare]) {
  if (iterables.isEmpty) return <T>[];
  if (iterables.every((i) => i.isEmpty)) return <T>[];
  return _Merge<T>(iterables, compare ?? _compareAny);
}

int _compareAny<T>(T a, T b) {
  return Comparable.compare(a as Comparable, b as Comparable);
}

class _Merge<T> extends IterableBase<T> {
  _Merge(this._iterables, this._compare);

  final Iterable<Iterable<T>> _iterables;
  final Comparator<T> _compare;

  @override
  Iterator<T> get iterator => _MergeIterator<T>(
      _iterables.map((i) => i.iterator).toList(growable: false), _compare);

  @override
  String toString() => toList().toString();
}

/// Like [Iterator] but one element ahead.
class _IteratorPeeker<T> {
  _IteratorPeeker(Iterator<T> iterator)
      : _iterator = iterator,
        _hasCurrent = iterator.moveNext();

  final Iterator<T> _iterator;
  bool _hasCurrent;

  void moveNext() {
    _hasCurrent = _iterator.moveNext();
  }

  T get current => _iterator.current;
}

class _MergeIterator<T> implements Iterator<T> {
  _MergeIterator(List<Iterator<T>> iterators, this._compare)
      : _peekers = iterators.map((i) => _IteratorPeeker(i)).toList();

  final List<_IteratorPeeker<T>> _peekers;
  final Comparator<T> _compare;
  T? _current;

  @override
  bool moveNext() {
    // Pick the peeker that's peeking at the puniest piece
    _IteratorPeeker<T>? minIter;
    for (final p in _peekers) {
      if (p._hasCurrent) {
        if (minIter == null || _compare(p.current, minIter.current) < 0) {
          minIter = p;
        }
      }
    }

    if (minIter == null) {
      return false;
    }
    _current = minIter.current;
    minIter.moveNext();
    return true;
  }

  @override
  T get current {
    return _current as T;
  }
}
