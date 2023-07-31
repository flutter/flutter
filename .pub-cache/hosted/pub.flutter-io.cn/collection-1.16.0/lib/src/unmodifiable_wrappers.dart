// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'empty_unmodifiable_set.dart';
import 'wrappers.dart';

export 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;

/// A fixed-length list.
///
/// A `NonGrowableListView` contains a [List] object and ensures that
/// its length does not change.
/// Methods that would change the length of the list,
/// such as [add] and [remove], throw an [UnsupportedError].
/// All other methods work directly on the underlying list.
///
/// This class _does_ allow changes to the contents of the wrapped list.
/// You can, for example, [sort] the list.
/// Permitted operations defer to the wrapped list.
class NonGrowableListView<E> extends DelegatingList<E>
    with NonGrowableListMixin<E> {
  NonGrowableListView(List<E> listBase) : super(listBase);
}

/// Mixin class that implements a throwing version of all list operations that
/// change the List's length.
abstract class NonGrowableListMixin<E> implements List<E> {
  static Never _throw() {
    throw UnsupportedError('Cannot change the length of a fixed-length list');
  }

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  set length(int newLength) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  bool add(E value) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void addAll(Iterable<E> iterable) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void insert(int index, E element) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void insertAll(int index, Iterable<E> iterable) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  bool remove(Object? value) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  E removeAt(int index) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  E removeLast() => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void removeWhere(bool Function(E) test) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void retainWhere(bool Function(E) test) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void removeRange(int start, int end) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void replaceRange(int start, int end, Iterable<E> iterable) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the length of the list are disallowed.
  @override
  void clear() => _throw();
}

/// An unmodifiable set.
///
/// An [UnmodifiableSetView] contains a [Set],
/// and prevents that set from being changed through the view.
/// Methods that could change the set,
/// such as [add] and [remove], throw an [UnsupportedError].
/// Permitted operations defer to the wrapped set.
class UnmodifiableSetView<E> extends DelegatingSet<E>
    with UnmodifiableSetMixin<E> {
  UnmodifiableSetView(Set<E> setBase) : super(setBase);

  /// An unmodifiable empty set.
  ///
  /// This is the same as `UnmodifiableSetView(Set())`, except that it
  /// can be used in const contexts.
  const factory UnmodifiableSetView.empty() = EmptyUnmodifiableSet<E>;
}

/// Mixin class that implements a throwing version of all set operations that
/// change the Set.
abstract class UnmodifiableSetMixin<E> implements Set<E> {
  static Never _throw() {
    throw UnsupportedError('Cannot modify an unmodifiable Set');
  }

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  bool add(E value) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  void addAll(Iterable<E> elements) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  bool remove(Object? value) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  void removeAll(Iterable elements) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  void retainAll(Iterable elements) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  void removeWhere(bool Function(E) test) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  void retainWhere(bool Function(E) test) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the set are disallowed.
  @override
  void clear() => _throw();
}

/// Mixin class that implements a throwing version of all map operations that
/// change the Map.
abstract class UnmodifiableMapMixin<K, V> implements Map<K, V> {
  static Never _throw() {
    throw UnsupportedError('Cannot modify an unmodifiable Map');
  }

  /// Throws an [UnsupportedError];
  /// operations that change the map are disallowed.
  @override
  void operator []=(K key, V value) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the map are disallowed.
  @override
  V putIfAbsent(K key, V Function() ifAbsent) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the map are disallowed.
  @override
  void addAll(Map<K, V> other) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the map are disallowed.
  @override
  V remove(Object? key) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the map are disallowed.
  @override
  void clear() => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the map are disallowed.
  set first(_) => _throw();

  /// Throws an [UnsupportedError];
  /// operations that change the map are disallowed.
  set last(_) => _throw();
}
