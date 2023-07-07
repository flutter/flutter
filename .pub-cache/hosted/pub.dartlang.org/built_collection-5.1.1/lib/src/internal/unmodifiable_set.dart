// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class UnmodifiableSetView<E> implements Set<E> {
  final Set<E> _set;

  UnmodifiableSetView(this._set);

  // Read-only methods: just forward.

  @override
  int get length => _set.length;

  @override
  E? lookup(Object? object) => _set.lookup(object);

  @override
  Set<E> intersection(Set<Object?> other) => _set.intersection(other);

  @override
  Set<E> union(Set<E> other) => _set.union(other);

  @override
  Set<E> difference(Set<Object?> other) => _set.difference(other);

  @override
  bool containsAll(Iterable<Object?> other) => _set.containsAll(other);

  @override
  bool any(bool Function(E) test) => _set.any(test);

  @override
  Set<T> cast<T>() => UnmodifiableSetView<T>(_set.cast<T>());

  @override
  bool contains(Object? element) => _set.contains(element);

  @override
  E elementAt(int index) => _set.elementAt(index);

  @override
  bool every(bool Function(E) test) => _set.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) f) => _set.expand(f);

  @override
  E get first => _set.first;

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) =>
      _set.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) =>
      _set.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _set.followedBy(other);

  @override
  void forEach(void Function(E) f) => _set.forEach(f);

  @override
  bool get isEmpty => _set.isEmpty;

  @override
  bool get isNotEmpty => _set.isNotEmpty;

  @override
  Iterator<E> get iterator => _set.iterator;

  @override
  String join([String separator = '']) => _set.join(separator);

  @override
  E get last => _set.last;

  @override
  E lastWhere(bool Function(E) test, {E Function()? orElse}) =>
      _set.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E) f) => _set.map(f);

  @override
  E reduce(E Function(E, E) combine) => _set.reduce(combine);

  @override
  E get single => _set.single;

  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) =>
      _set.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => _set.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E) test) => _set.skipWhile(test);

  @override
  Iterable<E> take(int count) => _set.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E) test) => _set.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => _set.toList(growable: growable);

  @override
  Set<E> toSet() => _set.toSet();

  @override
  Iterable<E> where(bool Function(E) test) => _set.where(test);

  @override
  Iterable<T> whereType<T>() => _set.whereType<T>();

  // Mutating methods: just throw!

  @override
  bool add(E value) => _throw();

  @override
  void addAll(Iterable<E> iterable) => _throw();

  @override
  void clear() => _throw();

  @override
  bool remove(Object? value) => _throw();

  @override
  void removeWhere(bool Function(E) test) => _throw();

  @override
  void retainWhere(bool Function(E) test) => _throw();

  @override
  void removeAll(Iterable<Object?> elements) => _throw();

  @override
  void retainAll(Iterable<Object?> elements) => _throw();

  @override
  String toString() => _set.toString();

  // Internal.

  static T _throw<T>() {
    throw UnsupportedError('Cannot modify an unmodifiable Set');
  }
}
