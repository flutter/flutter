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

/// Returns an [Iterable] of [IndexedValue]s where the nth value holds the nth
/// element of [iterable] and its index.
Iterable<IndexedValue<E>> enumerate<E>(Iterable<E> iterable) =>
    EnumerateIterable<E>(iterable);

class IndexedValue<V> {
  IndexedValue(this.index, this.value);

  final int index;
  final V value;

  @override
  bool operator ==(other) =>
      other is IndexedValue && other.index == index && other.value == value;

  @override
  int get hashCode => index * 31 + value.hashCode;

  @override
  String toString() => '($index, $value)';
}

/// An [Iterable] of [IndexedValue]s where the nth value holds the nth
/// element of [iterable] and its index. See [enumerate].
// This was inspired by MappedIterable internal to Dart collections.
class EnumerateIterable<V> extends IterableBase<IndexedValue<V>> {
  EnumerateIterable(this._iterable);

  final Iterable<V> _iterable;

  @override
  Iterator<IndexedValue<V>> get iterator =>
      EnumerateIterator<V>(_iterable.iterator);

  // Length related functions are independent of the mapping.
  @override
  int get length => _iterable.length;

  @override
  bool get isEmpty => _iterable.isEmpty;

  // Index based lookup can be done before transforming.
  @override
  IndexedValue<V> get first => IndexedValue<V>(0, _iterable.first);

  @override
  IndexedValue<V> get last => IndexedValue<V>(length - 1, _iterable.last);

  @override
  IndexedValue<V> get single => IndexedValue<V>(0, _iterable.single);

  @override
  IndexedValue<V> elementAt(int index) =>
      IndexedValue<V>(index, _iterable.elementAt(index));
}

/// The [Iterator] returned by [EnumerateIterable.iterator].
class EnumerateIterator<V> extends Iterator<IndexedValue<V>> {
  EnumerateIterator(this._iterator);

  final Iterator<V> _iterator;
  int _index = 0;
  IndexedValue<V>? _current;

  @override
  IndexedValue<V> get current {
    return _current as IndexedValue<V>;
  }

  @override
  bool moveNext() {
    if (_iterator.moveNext()) {
      _current = IndexedValue(_index++, _iterator.current);
      return true;
    }
    _current = null;
    return false;
  }
}
