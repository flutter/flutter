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

/// Returns an infinite [Iterable] of [num]s, starting from [start] and
/// increasing by [step].
///
/// Calling [Iterator.current] before [Iterator.moveNext] throws [StateError].
Iterable<num> count([num start = 0, num step = 1]) => _Count(start, step);

class _Count extends InfiniteIterable<num> {
  _Count(this.start, this.step);

  final num start, step;

  @override
  Iterator<num> get iterator => _CountIterator(start, step);

  // TODO(justin): return an infinite list for toList() and a special Set
  // implementation for toSet()?
}

class _CountIterator implements Iterator<num> {
  _CountIterator(this._start, this._step);

  final num _start, _step;
  num? _current;

  @override
  num get current {
    return _current as num;
  }

  @override
  bool moveNext() {
    _current = (_current == null) ? _start : _current! + _step;
    return true;
  }
}
