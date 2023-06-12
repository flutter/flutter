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

import 'dart:math' show Random;

import 'iterable.dart';

/// An implementation of [List] that delegates all methods to another [List].
/// For instance you can create a FruitList like this :
///
///     class FruitList extends DelegatingList<Fruit> {
///       final List<Fruit> _fruits = [];
///
///       List<Fruit> get delegate => _fruits;
///
///       // custom methods
///     }
abstract class DelegatingList<E> extends DelegatingIterable<E>
    implements List<E> {
  @override
  List<E> get delegate;

  @override
  E operator [](int index) => delegate[index];

  @override
  void operator []=(int index, E value) {
    delegate[index] = value;
  }

  @override
  List<E> operator +(List<E> other) => delegate + other;

  @override
  void add(E value) => delegate.add(value);

  @override
  void addAll(Iterable<E> iterable) => delegate.addAll(iterable);

  @override
  Map<int, E> asMap() => delegate.asMap();

  @override
  DelegatingList<T> cast<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  void clear() => delegate.clear();

  @override
  void fillRange(int start, int end, [E? fillValue]) =>
      delegate.fillRange(start, end, fillValue);

  @override
  set first(E element) {
    if (isEmpty) throw RangeError.index(0, this);
    this[0] = element;
  }

  @override
  Iterable<E> getRange(int start, int end) => delegate.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => delegate.indexOf(element, start);

  @override
  int indexWhere(bool test(E element), [int start = 0]) =>
      delegate.indexWhere(test, start);

  @override
  void insert(int index, E element) => delegate.insert(index, element);

  @override
  void insertAll(int index, Iterable<E> iterable) =>
      delegate.insertAll(index, iterable);

  @override
  set last(E element) {
    if (isEmpty) throw RangeError.index(0, this);
    this[length - 1] = element;
  }

  @override
  int lastIndexOf(E element, [int? start]) =>
      delegate.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool test(E element), [int? start]) =>
      delegate.lastIndexWhere(test, start);

  @override
  set length(int newLength) {
    delegate.length = newLength;
  }

  @override
  bool remove(Object? value) => delegate.remove(value);

  @override
  E removeAt(int index) => delegate.removeAt(index);

  @override
  E removeLast() => delegate.removeLast();

  @override
  void removeRange(int start, int end) => delegate.removeRange(start, end);

  @override
  void removeWhere(bool test(E element)) => delegate.removeWhere(test);

  @override
  void replaceRange(int start, int end, Iterable<E> iterable) =>
      delegate.replaceRange(start, end, iterable);

  @override
  void retainWhere(bool test(E element)) => delegate.retainWhere(test);

  @override
  Iterable<E> get reversed => delegate.reversed;

  @override
  void setAll(int index, Iterable<E> iterable) =>
      delegate.setAll(index, iterable);

  @override
  void setRange(int start, int end, Iterable<E> iterable,
          [int skipCount = 0]) =>
      delegate.setRange(start, end, iterable, skipCount);

  @override
  void shuffle([Random? random]) => delegate.shuffle(random);

  @override
  void sort([int compare(E a, E b)?]) => delegate.sort(compare);

  @override
  List<E> sublist(int start, [int? end]) => delegate.sublist(start, end);
}
