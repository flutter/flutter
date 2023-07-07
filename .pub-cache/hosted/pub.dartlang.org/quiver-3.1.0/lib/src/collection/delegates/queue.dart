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

import 'dart:collection' show Queue;

import 'iterable.dart';

/// An implementation of [Queue] that delegates all methods to another [Queue].
/// For instance you can create a FruitQueue like this :
///
///     class FruitQueue extends DelegatingQueue<Fruit> {
///       final Queue<Fruit> _fruits = Queue<Fruit>();
///
///       Queue<Fruit> get delegate => _fruits;
///
///       // custom methods
///     }
abstract class DelegatingQueue<E> extends DelegatingIterable<E>
    implements Queue<E> {
  @override
  Queue<E> get delegate;

  @override
  void add(E value) => delegate.add(value);

  @override
  void addAll(Iterable<E> iterable) => delegate.addAll(iterable);

  @override
  void addFirst(E value) => delegate.addFirst(value);

  @override
  void addLast(E value) => delegate.addLast(value);

  @override
  DelegatingQueue<T> cast<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  void clear() => delegate.clear();

  @override
  bool remove(Object? object) => delegate.remove(object);

  @override
  E removeFirst() => delegate.removeFirst();

  @override
  E removeLast() => delegate.removeLast();

  @override
  void removeWhere(bool test(E element)) => delegate.removeWhere(test);

  @override
  void retainWhere(bool test(E element)) => delegate.retainWhere(test);
}
