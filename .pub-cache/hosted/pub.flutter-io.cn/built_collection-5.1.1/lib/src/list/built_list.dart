// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../list.dart';

/// The Built Collection [List].
///
/// It implements [Iterable] and the non-mutating part of the [List] interface.
/// Modifications are made via [ListBuilder].
///
/// See the
/// [Built Collection library documentation]
/// (#built_collection/built_collection)
/// for the general properties of Built Collections.
abstract class BuiltList<E> implements Iterable<E>, BuiltIterable<E> {
  final List<E> _list;
  int? _hashCode;

  /// Instantiates with elements from an [Iterable].
  factory BuiltList([Iterable iterable = const []]) =>
      BuiltList<E>.from(iterable);

  /// Instantiates with elements from an [Iterable].
  factory BuiltList.from(Iterable iterable) {
    if (iterable is _BuiltList && iterable.hasExactElementType(E)) {
      return iterable as BuiltList<E>;
    } else {
      return _BuiltList<E>.from(iterable);
    }
  }

  /// Instantiates with elements from an [Iterable<E>].
  ///
  /// `E` must not be `dynamic`.
  factory BuiltList.of(Iterable<E> iterable) {
    if (iterable is _BuiltList<E> && iterable.hasExactElementType(E)) {
      return iterable;
    } else {
      return _BuiltList<E>.of(iterable);
    }
  }

  /// Creates a [ListBuilder], applies updates to it, and builds.
  factory BuiltList.build(Function(ListBuilder<E>) updates) =>
      (ListBuilder<E>()..update(updates)).build();

  /// Converts to a [ListBuilder] for modification.
  ///
  /// The `BuiltList` remains immutable and can continue to be used.
  ListBuilder<E> toBuilder() => ListBuilder<E>(this);

  /// Converts to a [ListBuilder], applies updates to it, and builds.
  BuiltList<E> rebuild(Function(ListBuilder<E>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuiltList<E> toBuiltList() => this;

  @override
  BuiltSet<E> toBuiltSet() => BuiltSet<E>(this);

  /// Deep hashCode.
  ///
  /// A `BuiltList` is only equal to another `BuiltList` with equal elements in
  /// the same order. Then, the `hashCode` is guaranteed to be the same.
  @override
  int get hashCode {
    _hashCode ??= hashObjects(_list);
    return _hashCode!;
  }

  /// Deep equality.
  ///
  /// A `BuiltList` is only equal to another `BuiltList` with equal elements in
  /// the same order.
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! BuiltList) return false;
    if (other.length != length) return false;
    if (other.hashCode != hashCode) return false;
    for (var i = 0; i != length; ++i) {
      if (other[i] != this[i]) return false;
    }
    return true;
  }

  @override
  String toString() => _list.toString();

  /// Returns as an immutable list.
  ///
  /// Useful when producing or using APIs that need the [List] interface. This
  /// differs from [toList] where mutations are explicitly disallowed.
  List<E> asList() => List<E>.unmodifiable(_list);

  // List.

  /// As [List.elementAt].
  E operator [](int index) => _list[index];

  /// As [List.+].
  BuiltList<E> operator +(BuiltList<E> other) =>
      _BuiltList<E>.withSafeList(_list + other._list);

  /// As [List.length].
  @override
  int get length => _list.length;

  /// As [List.reversed].
  Iterable<E> get reversed => _list.reversed;

  /// As [List.indexOf].
  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  /// As [List.lastIndexOf].
  int lastIndexOf(E element, [int? start]) => _list.lastIndexOf(element, start);

  /// As [List.indexWhere].
  int indexWhere(bool Function(E) test, [int start = 0]) =>
      _list.indexWhere(test, start);

  /// As [List.lastIndexWhere].
  int lastIndexWhere(bool Function(E) test, [int? start]) =>
      _list.lastIndexWhere(test, start);

  /// As [List.sublist] but returns a `BuiltList<E>`.
  BuiltList<E> sublist(int start, [int? end]) =>
      _BuiltList<E>.withSafeList(_list.sublist(start, end));

  /// As [List.getRange].
  Iterable<E> getRange(int start, int end) => _list.getRange(start, end);

  /// As [List.asMap].
  Map<int, E> asMap() => _list.asMap();

  // Iterable.

  @override
  Iterator<E> get iterator => _list.iterator;

  @override
  Iterable<T> map<T>(T Function(E) f) => _list.map(f);

  @override
  Iterable<E> where(bool Function(E) test) => _list.where(test);

  @override
  Iterable<T> whereType<T>() => _list.whereType<T>();

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) f) => _list.expand(f);

  @override
  bool contains(Object? element) => _list.contains(element);

  @override
  void forEach(void Function(E) f) => _list.forEach(f);

  @override
  E reduce(E Function(E, E) combine) => _list.reduce(combine);

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) =>
      _list.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _list.followedBy(other);

  @override
  bool every(bool Function(E) test) => _list.every(test);

  @override
  String join([String separator = '']) => _list.join(separator);

  @override
  bool any(bool Function(E) test) => _list.any(test);

  /// As [Iterable.toList].
  ///
  /// Note that the implementation is efficient: it returns a copy-on-write
  /// wrapper around the data from this `BuiltList`. So, if no mutations are
  /// made to the result, no copy is made.
  ///
  /// This allows efficient use of APIs that ask for a mutable collection
  /// but don't actually mutate it.
  @override
  List<E> toList({bool growable = true}) => CopyOnWriteList<E>(_list, growable);

  @override
  Set<E> toSet() => _list.toSet();

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  Iterable<E> take(int n) => _list.take(n);

  @override
  Iterable<E> takeWhile(bool Function(E) test) => _list.takeWhile(test);

  @override
  Iterable<E> skip(int n) => _list.skip(n);

  @override
  Iterable<E> skipWhile(bool Function(E) test) => _list.skipWhile(test);

  @override
  E get first => _list.first;

  @override
  E get last => _list.last;

  @override
  E get single => _list.single;

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) =>
      _list.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(bool Function(E) test, {E Function()? orElse}) =>
      _list.lastWhere(test, orElse: orElse);

  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) =>
      _list.singleWhere(test, orElse: orElse);

  @override
  E elementAt(int index) => _list.elementAt(index);

  @override
  Iterable<T> cast<T>() => Iterable.castFrom<E, T>(_list);

  // Internal.

  BuiltList._(this._list);
}

/// Default implementation of the public [BuiltList] interface.
class _BuiltList<E> extends BuiltList<E> {
  _BuiltList.withSafeList(List<E> list) : super._(list);

  _BuiltList.from([Iterable iterable = const []])
      : super._(List<E>.from(iterable, growable: false)) {
    _maybeCheckForNull();
  }

  _BuiltList.of(Iterable<E> iterable)
      : super._(List<E>.from(iterable, growable: false)) {
    _maybeCheckForNull();
  }

  bool get _needsNullCheck => !isSoundMode && null is! E;

  void _maybeCheckForNull() {
    if (!_needsNullCheck) return;
    for (var element in _list) {
      if (identical(element, null)) {
        throw ArgumentError('iterable contained invalid element: null');
      }
    }
  }

  bool hasExactElementType(Type type) => E == type;
}

/// Extensions for [BuiltList] on [List].
extension BuiltListExtension<T> on List<T> {
  /// Converts to a [BuiltList].
  BuiltList<T> build() {
    // We know a `List` is not a `BuiltList`, so we have to copy.
    return _BuiltList<T>.of(this);
  }
}

/// Extensions for [BuiltList] on [Iterable].
extension BuiltListIterableExtension<E> on Iterable<E> {
  /// Converts to a [BuiltList].
  ///
  /// Just returns the [Iterable] if it is already a `BuiltList<E>`.
  BuiltList<E> toBuiltList() => BuiltList<E>.of(this);
}
