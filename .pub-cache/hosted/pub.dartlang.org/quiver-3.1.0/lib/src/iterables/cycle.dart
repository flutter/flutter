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

import 'infinite_iterable.dart';

/// Returns an [Iterable] that infinitely cycles through the elements of
/// [iterable]. If [iterable] is empty, the returned Iterable will also be empty.
Iterable<T> cycle<T>(Iterable<T> iterable) => _Cycle<T>(iterable);

class _Cycle<T> extends InfiniteIterable<T> {
  _Cycle(this._iterable);

  final Iterable<T> _iterable;

  @override
  Iterator<T> get iterator => _CycleIterator(_iterable);

  @override
  bool get isEmpty => _iterable.isEmpty;

  @override
  bool get isNotEmpty => _iterable.isNotEmpty;

  // TODO(justin): add methods that can be answered by the wrapped iterable
}

class _CycleIterator<T> implements Iterator<T> {
  _CycleIterator(Iterable<T> _iterable)
      : _iterable = _iterable,
        _iterator = _iterable.iterator;

  final Iterable<T> _iterable;
  Iterator<T> _iterator;

  @override
  T get current => _iterator.current;

  @override
  bool moveNext() {
    if (!_iterator.moveNext()) {
      _iterator = _iterable.iterator;
      return _iterator.moveNext();
    }
    return true;
  }
}
