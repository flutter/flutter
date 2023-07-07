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

import 'iterable.dart';

/// An implementation of [Set] that delegates all methods to another [Set].
/// For instance you can create a FruitSet like this :
///
///     class FruitSet extends DelegatingSet<Fruit> {
///       final Set<Fruit> _fruits = Set<Fruit>();
///
///       Set<Fruit> get delegate => _fruits;
///
///       // custom methods
///     }
abstract class DelegatingSet<E> extends DelegatingIterable<E>
    implements Set<E> {
  @override
  Set<E> get delegate;

  @override
  bool add(E value) => delegate.add(value);

  @override
  void addAll(Iterable<E> elements) => delegate.addAll(elements);

  @override
  DelegatingSet<T> cast<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  void clear() => delegate.clear();

  @override
  bool containsAll(Iterable<Object?> other) => delegate.containsAll(other);

  @override
  Set<E> difference(Set<Object?> other) => delegate.difference(other);

  @override
  Set<E> intersection(Set<Object?> other) => delegate.intersection(other);

  @override
  E? lookup(Object? object) => delegate.lookup(object);

  @override
  bool remove(Object? value) => delegate.remove(value);

  @override
  void removeAll(Iterable<Object?> elements) => delegate.removeAll(elements);

  @override
  void removeWhere(bool test(E element)) => delegate.removeWhere(test);

  @override
  void retainAll(Iterable<Object?> elements) => delegate.retainAll(elements);

  @override
  void retainWhere(bool test(E element)) => delegate.retainWhere(test);

  @override
  Set<E> union(Set<E> other) => delegate.union(other);
}
