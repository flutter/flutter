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

/// An implementation of [Iterable] that delegates all methods to another
/// [Iterable].  For instance you can create a FruitIterable like this :
///
///     class FruitIterable extends DelegatingIterable<Fruit> {
///       final Iterable<Fruit> _fruits = [];
///
///       Iterable<Fruit> get delegate => _fruits;
///
///       // custom methods
///     }
abstract class DelegatingIterable<E> implements Iterable<E> {
  Iterable<E> get delegate;

  @override
  bool any(bool test(E element)) => delegate.any(test);

  @override
  Iterable<T> cast<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  bool contains(Object? element) => delegate.contains(element);

  @override
  E elementAt(int index) => delegate.elementAt(index);

  @override
  bool every(bool test(E element)) => delegate.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> f(E element)) => delegate.expand(f);

  @override
  E get first => delegate.first;

  @override
  E firstWhere(bool test(E element), {E orElse()?}) =>
      delegate.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T combine(T previousValue, E element)) =>
      delegate.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => delegate.followedBy(other);

  @override
  void forEach(void f(E element)) => delegate.forEach(f);

  @override
  bool get isEmpty => delegate.isEmpty;

  @override
  bool get isNotEmpty => delegate.isNotEmpty;

  @override
  Iterator<E> get iterator => delegate.iterator;

  @override
  String join([String separator = '']) => delegate.join(separator);

  @override
  E get last => delegate.last;

  @override
  E lastWhere(bool test(E element), {E orElse()?}) =>
      delegate.lastWhere(test, orElse: orElse);

  @override
  int get length => delegate.length;

  @override
  Iterable<T> map<T>(T f(E e)) => delegate.map(f);

  @override
  E reduce(E combine(E value, E element)) => delegate.reduce(combine);

  @override
  E get single => delegate.single;

  @override
  E singleWhere(bool test(E element), {E orElse()?}) =>
      delegate.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int n) => delegate.skip(n);

  @override
  Iterable<E> skipWhile(bool test(E value)) => delegate.skipWhile(test);

  @override
  Iterable<E> take(int n) => delegate.take(n);

  @override
  Iterable<E> takeWhile(bool test(E value)) => delegate.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => delegate.toList(growable: growable);

  @override
  Set<E> toSet() => delegate.toSet();

  @override
  Iterable<E> where(bool test(E element)) => delegate.where(test);

  @override
  Iterable<T> whereType<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('whereType');
  }
}
