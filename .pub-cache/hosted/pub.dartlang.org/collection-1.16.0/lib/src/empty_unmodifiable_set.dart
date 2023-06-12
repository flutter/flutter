// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';

/// An unmodifiable, empty set which can be constant.
class EmptyUnmodifiableSet<E> extends IterableBase<E>
    with UnmodifiableSetMixin<E>
    implements UnmodifiableSetView<E> {
  const EmptyUnmodifiableSet();

  @override
  Iterator<E> get iterator => Iterable<E>.empty().iterator;
  @override
  int get length => 0;
  @override
  EmptyUnmodifiableSet<T> cast<T>() => EmptyUnmodifiableSet<T>();
  @override
  bool contains(Object? element) => false;
  @override
  bool containsAll(Iterable<Object?> other) => other.isEmpty;
  @override
  Iterable<E> followedBy(Iterable<E> other) => DelegatingIterable(other);
  @override
  E? lookup(Object? element) => null;
  @Deprecated("Use cast instead")
  @override
  EmptyUnmodifiableSet<T> retype<T>() => EmptyUnmodifiableSet<T>();
  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) =>
      orElse != null ? orElse() : throw StateError('No element');
  @override
  Iterable<T> whereType<T>() => Iterable.empty();
  @override
  Set<E> toSet() => {};
  @override
  Set<E> union(Set<E> other) => Set.of(other);
  @override
  Set<E> intersection(Set<Object?> other) => {};
  @override
  Set<E> difference(Set<Object?> other) => {};
}
