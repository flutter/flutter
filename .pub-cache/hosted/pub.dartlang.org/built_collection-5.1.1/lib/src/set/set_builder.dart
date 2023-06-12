// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../set.dart';

/// The Built Collection builder for [BuiltSet].
///
/// It implements the mutating part of the [Set] interface.
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
class SetBuilder<E> {
  /// Used by [_createSet] to instantiate [_set]. The default value is `null`.
  _SetFactory<E>? _setFactory;
  late Set<E> _set;
  _BuiltSet<E>? _setOwner;

  /// Instantiates with elements from an [Iterable].
  factory SetBuilder([Iterable iterable = const []]) {
    return SetBuilder<E>._uninitialized()..replace(iterable);
  }

  /// Converts to a [BuiltSet].
  ///
  /// The `SetBuilder` can be modified again and used to create any number
  /// of `BuiltSet`s.
  BuiltSet<E> build() {
    _setOwner ??= _BuiltSet<E>.withSafeSet(_setFactory, _set);
    return _setOwner!;
  }

  /// Applies a function to `this`.
  void update(Function(SetBuilder<E>) updates) {
    updates(this);
  }

  /// Replaces all elements with elements from an [Iterable].
  void replace(Iterable iterable) {
    if (iterable is _BuiltSet<E> && iterable._setFactory == _setFactory) {
      _withOwner(iterable);
    } else {
      // Can't use addAll because it requires an Iterable<E>.
      var set = _createSet();
      for (var element in iterable) {
        if (element is E) {
          set.add(element);
        } else {
          throw ArgumentError('iterable contained invalid element: $element');
        }
      }
      _setSafeSet(set);
    }
  }

  /// Uses `base` as the collection type for all sets created by this builder.
  ///
  ///     // Iterates over elements in ascending order.
  ///     new SetBuilder<int>()..withBase(() => new SplayTreeSet<int>());
  ///
  ///     // Uses custom equality.
  ///     new SetBuilder<int>()..withBase(() => new LinkedHashSet<int>(
  ///         equals: (int a, int b) => a % 255 == b % 255,
  ///         hashCode: (int n) => (n % 255).hashCode));
  ///
  /// The set returned by `base` must be empty, mutable, and each call must
  /// instantiate and return a new object. The methods `difference`,
  /// `intersection` and `union` of the returned set must create sets of the
  /// same type.
  ///
  /// Use [withDefaultBase] to reset `base` to the default value.
  void withBase(_SetFactory<E> base) {
    ArgumentError.checkNotNull(base, 'base');
    _setFactory = base;
    _setSafeSet(_createSet()..addAll(_set));
  }

  /// As [withBase], but sets `base` back to the default value, which
  /// instantiates `Set<E>`.
  void withDefaultBase() {
    _setFactory = null;
    _setSafeSet(_createSet()..addAll(_set));
  }

  // Based on Set.

  /// As [Set.length].
  int get length => _set.length;

  /// As [Set.isEmpty].
  bool get isEmpty => _set.isEmpty;

  /// As [Set.isNotEmpty].
  bool get isNotEmpty => _set.isNotEmpty;

  /// As [Set.add].
  bool add(E value) {
    _maybeCheckElement(value);
    return _safeSet.add(value);
  }

  /// As [Set.addAll].
  void addAll(Iterable<E> iterable) {
    iterable = evaluateIterable(iterable);
    _maybeCheckElements(iterable);
    _safeSet.addAll(iterable);
  }

  /// As [Set.clear].
  void clear() {
    _safeSet.clear();
  }

  /// As [Set.remove].
  bool remove(Object? value) => _safeSet.remove(value);

  /// As [Set.removeAll].
  void removeAll(Iterable<Object?> elements) {
    _safeSet.removeAll(elements);
  }

  /// As [Set.removeWhere].
  void removeWhere(bool Function(E) test) {
    _safeSet.removeWhere(test);
  }

  /// As [Set.retainAll].
  void retainAll(Iterable<Object?> elements) {
    _safeSet.retainAll(elements);
  }

  /// As [Set.retainWhere].
  ///
  /// This method is an alias of [where].
  void retainWhere(bool Function(E) test) {
    _safeSet.retainWhere(test);
  }

  // Based on Iterable.

  /// As [Iterable.map], but updates the builder in place. Returns nothing.
  void map(E Function(E) f) {
    var result = _createSet()..addAll(_set.map(f));
    _maybeCheckElements(result);
    _setSafeSet(result);
  }

  /// As [Iterable.where], but updates the builder in place. Returns nothing.
  ///
  /// This method is an alias of [retainWhere].
  void where(bool Function(E) test) => retainWhere(test);

  /// As [Iterable.expand], but updates the builder in place. Returns nothing.
  void expand(Iterable<E> Function(E) f) {
    var result = _createSet()..addAll(_set.expand(f));
    _maybeCheckElements(result);
    _setSafeSet(result);
  }

  /// As [Iterable.take], but updates the builder in place. Returns nothing.
  void take(int n) {
    _setSafeSet(_createSet()..addAll(_set.take(n)));
  }

  /// As [Iterable.takeWhile], but updates the builder in place. Returns
  /// nothing.
  void takeWhile(bool Function(E) test) {
    _setSafeSet(_createSet()..addAll(_set.takeWhile(test)));
  }

  /// As [Iterable.skip], but updates the builder in place. Returns nothing.
  void skip(int n) {
    _setSafeSet(_createSet()..addAll(_set.skip(n)));
  }

  /// As [Iterable.skipWhile], but updates the builder in place. Returns
  /// nothing.
  void skipWhile(bool Function(E) test) {
    _setSafeSet(_createSet()..addAll(_set.skipWhile(test)));
  }

  // Internal.

  SetBuilder._uninitialized();

  SetBuilder._fromBuiltSet(_BuiltSet<E> set)
      : _setFactory = set._setFactory,
        _set = set._set,
        _setOwner = set;

  void _withOwner(_BuiltSet<E> setOwner) {
    assert(setOwner._setFactory == _setFactory,
        "Can't reuse a built set that uses a different base");
    _set = setOwner._set;
    _setOwner = setOwner;
  }

  void _setSafeSet(Set<E> set) {
    _setOwner = null;
    _set = set;
  }

  Set<E> get _safeSet {
    if (_setOwner != null) {
      _set = _createSet()..addAll(_set);
      _setOwner = null;
    }
    return _set;
  }

  Set<E> _createSet() => _setFactory != null ? _setFactory!() : <E>{};

  bool get _needsNullCheck => !isSoundMode && null is! E;

  void _maybeCheckElement(E element) {
    if (_needsNullCheck) _checkElement(element);
  }

  void _checkElement(E element) {
    if (identical(element, null)) {
      throw ArgumentError('null element');
    }
  }

  void _maybeCheckElements(Iterable<E> elements) {
    if (!_needsNullCheck) return;
    for (var element in elements) {
      _checkElement(element);
    }
  }
}
