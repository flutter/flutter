// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../set.dart';

typedef _SetFactory<E> = Set<E> Function();

/// The Built Collection [Set].
///
/// It implements [Iterable] and the non-mutating part of the [Set] interface.
/// Iteration is in the same order in which the elements were inserted.
/// Modifications are made via [SetBuilder].
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
abstract class BuiltSet<E> implements Iterable<E>, BuiltIterable<E> {
  final _SetFactory<E>? _setFactory;
  final Set<E> _set;
  int? _hashCode;

  /// Instantiates with elements from an [Iterable].
  factory BuiltSet([Iterable iterable = const []]) => BuiltSet.from(iterable);

  /// Instantiates with elements from an [Iterable].
  factory BuiltSet.from(Iterable iterable) {
    if (iterable is _BuiltSet && iterable.hasExactElementType(E)) {
      return iterable as BuiltSet<E>;
    } else {
      return _BuiltSet<E>.from(iterable);
    }
  }

  /// Instantiates with elements from an [Iterable<E>].
  factory BuiltSet.of(Iterable<E> iterable) {
    if (iterable is _BuiltSet<E> && iterable.hasExactElementType(E)) {
      return iterable;
    } else {
      return _BuiltSet<E>.of(iterable);
    }
  }

  /// Creates a [SetBuilder], applies updates to it, and builds.
  factory BuiltSet.build(Function(SetBuilder<E>) updates) =>
      (SetBuilder<E>()..update(updates)).build();

  /// Converts to a [SetBuilder] for modification.
  ///
  /// The `BuiltSet` remains immutable and can continue to be used.
  SetBuilder<E> toBuilder() =>
      SetBuilder<E>._fromBuiltSet(this as _BuiltSet<E>);

  /// Converts to a [SetBuilder], applies updates to it, and builds.
  BuiltSet<E> rebuild(Function(SetBuilder<E>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuiltList<E> toBuiltList() => BuiltList<E>(this);

  @override
  BuiltSet<E> toBuiltSet() => this;

  /// Deep hashCode.
  ///
  /// A `BuiltSet` is only equal to another `BuiltSet` with equal elements in
  /// any order. Then, the `hashCode` is guaranteed to be the same.
  @override
  int get hashCode {
    _hashCode ??= hashObjects(
        _set.map((e) => e.hashCode).toList(growable: false)..sort());
    return _hashCode!;
  }

  /// Deep equality.
  ///
  /// A `BuiltSet` is only equal to another `BuiltSet` with equal elements in
  /// any order.
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! BuiltSet) return false;
    if (other.length != length) return false;
    if (other.hashCode != hashCode) return false;
    return containsAll(other);
  }

  @override
  String toString() => _set.toString();

  /// Returns as an immutable set.
  ///
  /// Useful when producing or using APIs that need the [Set] interface. This
  /// differs from [toSet] where mutations are explicitly disallowed.
  Set<E> asSet() => UnmodifiableSetView<E>(_set);

  // Set.

  /// As [Set.length].
  @override
  int get length => _set.length;

  /// As [Set.containsAll].
  bool containsAll(Iterable<Object?> other) => _set.containsAll(other);

  /// As [Set.difference] but takes a `BuiltSet<Object?>` and returns a
  /// `BuiltSet<E>`.
  BuiltSet<E> difference(BuiltSet<Object?> other) =>
      _BuiltSet<E>.withSafeSet(_setFactory, _set.difference(other._set));

  /// As [Set.intersection] but takes a `BuiltSet<Object?>` and returns a
  /// `BuiltSet<E>`.
  BuiltSet<E> intersection(BuiltSet<Object?> other) =>
      _BuiltSet<E>.withSafeSet(_setFactory, _set.intersection(other._set));

  /// As [Set.lookup].
  E? lookup(Object? object) => _set.lookup(object);

  /// As [Set.union] but takes and returns a `BuiltSet<E>`.
  BuiltSet<E> union(BuiltSet<E> other) =>
      _BuiltSet<E>.withSafeSet(_setFactory, _set.union(other._set));

  // Iterable.

  @override
  Iterator<E> get iterator => _set.iterator;

  @override
  Iterable<T> cast<T>() => Iterable.castFrom<E, T>(_set);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _set.followedBy(other);

  @override
  Iterable<T> whereType<T>() => _set.whereType<T>();

  @override
  Iterable<T> map<T>(T Function(E) f) => _set.map(f);

  @override
  Iterable<E> where(bool Function(E) test) => _set.where(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) f) => _set.expand(f);

  @override
  bool contains(Object? element) => _set.contains(element);

  @override
  void forEach(void Function(E) f) => _set.forEach(f);

  @override
  E reduce(E Function(E, E) combine) => _set.reduce(combine);

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) =>
      _set.fold(initialValue, combine);

  @override
  bool every(bool Function(E) test) => _set.every(test);

  @override
  String join([String separator = '']) => _set.join(separator);

  @override
  bool any(bool Function(E) test) => _set.any(test);

  /// As [Iterable.toSet].
  ///
  /// Note that the implementation is efficient: it returns a copy-on-write
  /// wrapper around the data from this `BuiltSet`. So, if no mutations are
  /// made to the result, no copy is made.
  ///
  /// This allows efficient use of APIs that ask for a mutable collection
  /// but don't actually mutate it.
  @override
  Set<E> toSet() => CopyOnWriteSet<E>(_set, _setFactory);

  @override
  List<E> toList({bool growable = true}) => _set.toList(growable: growable);

  @override
  bool get isEmpty => _set.isEmpty;

  @override
  bool get isNotEmpty => _set.isNotEmpty;

  @override
  Iterable<E> take(int n) => _set.take(n);

  @override
  Iterable<E> takeWhile(bool Function(E) test) => _set.takeWhile(test);

  @override
  Iterable<E> skip(int n) => _set.skip(n);

  @override
  Iterable<E> skipWhile(bool Function(E) test) => _set.skipWhile(test);

  @override
  E get first => _set.first;

  @override
  E get last => _set.last;

  @override
  E get single => _set.single;

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) =>
      _set.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(bool Function(E) test, {E Function()? orElse}) =>
      _set.lastWhere(test, orElse: orElse);

  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) =>
      _set.singleWhere(test, orElse: orElse);

  @override
  E elementAt(int index) => _set.elementAt(index);

  // Internal.

  BuiltSet._(this._setFactory, this._set);
}

/// Default implementation of the public [BuiltSet] interface.
class _BuiltSet<E> extends BuiltSet<E> {
  _BuiltSet.withSafeSet(_SetFactory<E>? setFactory, Set<E> set)
      : super._(setFactory, set);

  _BuiltSet.from(Iterable iterable) : super._(null, Set<E>.from(iterable)) {
    _maybeCheckForNull();
  }

  _BuiltSet.of(Iterable<E> iterable) : super._(null, <E>{}..addAll(iterable)) {
    _maybeCheckForNull();
  }

  bool get _needsNullCheck => !isSoundMode && null is! E;

  void _maybeCheckForNull() {
    if (!_needsNullCheck) return;
    for (var element in _set) {
      if (identical(element, null)) {
        throw ArgumentError('iterable contained invalid element: null');
      }
    }
  }

  bool hasExactElementType(Type type) => E == type;
}

/// Extensions for [BuiltSet] on [Set].
extension BuiltSetExtension<T> on Set<T> {
  /// Converts to a [BuiltSet].
  BuiltSet<T> build() {
    // We know a `Set` is not a `BuiltSet`, so we have to copy.
    return _BuiltSet<T>.of(this);
  }
}

/// Extensions for [BuiltSet] on [Iterable].
extension BuiltSetIterableExtension<E> on Iterable<E> {
  /// Converts to a [BuiltSet].
  ///
  /// Just returns the [Iterable] if it is already a `BuiltSet<E>`.
  BuiltSet<E> toBuiltSet() => BuiltSet<E>.of(this);
}
