// Copyright 2014 Google Inc. All Rights Reserved.
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

/// Partitions the input iterable into lists of the specified size.
Iterable<List<T>> partition<T>(Iterable<T> iterable, int size) {
  return iterable.isEmpty ? [] : _Partition<T>(iterable, size);
}

class _Partition<T> extends IterableBase<List<T>> {
  _Partition(this._iterable, this._size) {
    if (_size <= 0) throw ArgumentError(_size);
  }

  final Iterable<T> _iterable;
  final int _size;

  @override
  Iterator<List<T>> get iterator =>
      _PartitionIterator<T>(_iterable.iterator, _size);
}

class _PartitionIterator<T> implements Iterator<List<T>> {
  _PartitionIterator(this._iterator, this._size);

  final Iterator<T> _iterator;
  final int _size;
  List<T>? _current;

  @override
  List<T> get current {
    return _current as List<T>;
  }

  @override
  bool moveNext() {
    var newValue = <T>[];
    var count = 0;
    while (count < _size && _iterator.moveNext()) {
      newValue.add(_iterator.current);
      count++;
    }
    _current = (count > 0) ? newValue : null;
    return _current != null;
  }
}
