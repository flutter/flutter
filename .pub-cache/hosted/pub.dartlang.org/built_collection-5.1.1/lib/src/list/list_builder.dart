// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../list.dart';

/// The Built Collection builder for [BuiltList].
///
/// It implements the mutating part of the [List] interface.
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
class ListBuilder<E> {
  late List<E> _list;
  _BuiltList<E>? _listOwner;

  /// Instantiates with elements from an [Iterable].
  factory ListBuilder([Iterable iterable = const []]) {
    return ListBuilder<E>._uninitialized()..replace(iterable);
  }

  /// Converts to a [BuiltList].
  ///
  /// The `ListBuilder` can be modified again and used to create any number
  /// of `BuiltList`s.
  BuiltList<E> build() {
    if (_listOwner == null) {
      _setOwner(_BuiltList<E>.withSafeList(_list));
    }
    return _listOwner!;
  }

  /// Applies a function to `this`.
  void update(Function(ListBuilder<E>) updates) {
    updates(this);
  }

  /// Replaces all elements with elements from an [Iterable].
  void replace(Iterable iterable) {
    if (iterable is _BuiltList<E>) {
      _setOwner(iterable);
    } else {
      _setSafeList(List<E>.from(iterable));
    }
  }

  // Based on List.

  /// As [List.elementAt].
  E operator [](int index) => _list[index];

  /// As [List].
  void operator []=(int index, E element) {
    _maybeCheckElement(element);
    _safeList[index] = element;
  }

  /// As [List.first].
  E get first => _list.first;

  /// As [List.first].
  set first(E value) {
    _maybeCheckElement(value);
    _safeList.first = value;
  }

  /// As [List.last].
  E get last => _list.last;

  /// As [List.last].
  set last(E value) {
    _maybeCheckElement(value);
    _safeList.last = value;
  }

  /// As [List.length].
  int get length => _list.length;

  /// As [List.isEmpty].
  bool get isEmpty => _list.isEmpty;

  /// As [List.isNotEmpty].
  bool get isNotEmpty => _list.isNotEmpty;

  /// As [List.add].
  void add(E value) {
    _maybeCheckElement(value);
    _safeList.add(value);
  }

  /// As [List.addAll].
  void addAll(Iterable<E> iterable) {
    // Add directly to the underlying `List` then check elements there, for
    // performance. Roll back the changes if validation fails.
    var safeList = _safeList;
    var lengthBefore = safeList.length;
    safeList.addAll(iterable);
    if (!_needsNullCheck) return;
    try {
      for (var i = lengthBefore; i != safeList.length; ++i) {
        _checkElement(safeList[i]);
      }
    } catch (_) {
      safeList.removeRange(lengthBefore, safeList.length);
      rethrow;
    }
  }

  /// As [List.reversed], but updates the builder in place. Returns nothing.
  void reverse() {
    _list = _list.reversed.toList(growable: true);
    _listOwner = null;
  }

  /// As [List.sort].
  void sort([int Function(E, E)? compare]) {
    _safeList.sort(compare);
  }

  /// As [List.shuffle].
  void shuffle([Random? random]) {
    _safeList.shuffle(random);
  }

  /// As [List.clear].
  void clear() {
    _safeList.clear();
  }

  /// As [List.insert].
  void insert(int index, E element) {
    _maybeCheckElement(element);
    _safeList.insert(index, element);
  }

  /// As [List.insertAll].
  void insertAll(int index, Iterable<E> iterable) {
    // Add directly to the underlying `List` then check elements there, for
    // performance. Roll back the changes if validation fails.
    var safeList = _safeList;
    var lengthBefore = safeList.length;
    safeList.insertAll(index, iterable);
    if (!_needsNullCheck) return;
    var insertedLength = safeList.length - lengthBefore;
    try {
      for (var i = index; i != index + insertedLength; ++i) {
        _checkElement(safeList[i]);
      }
    } catch (_) {
      safeList.removeRange(index, index + insertedLength);
      rethrow;
    }
  }

  /// As [List.setAll].
  void setAll(int index, Iterable<E> iterable) {
    iterable = evaluateIterable(iterable);
    _maybeCheckElements(iterable);
    _safeList.setAll(index, iterable);
  }

  /// As [List.remove].
  bool remove(Object? value) => _safeList.remove(value);

  /// As [List.removeAt].
  E removeAt(int index) => _safeList.removeAt(index);

  /// As [List.removeLast].
  E removeLast() => _safeList.removeLast();

  /// As [List.removeWhere].
  void removeWhere(bool Function(E) test) {
    _safeList.removeWhere(test);
  }

  /// As [List.retainWhere].
  ///
  /// This method is an alias of [where].
  void retainWhere(bool Function(E) test) {
    _safeList.retainWhere(test);
  }

  /// As [List.sublist], but updates the builder in place. Returns nothing.
  void sublist(int start, [int? end]) {
    _setSafeList(_list.sublist(start, end));
  }

  /// As [List.setRange].
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    iterable = evaluateIterable(iterable);
    _maybeCheckElements(iterable);
    _safeList.setRange(start, end, iterable, skipCount);
  }

  /// As [List.removeRange].
  void removeRange(int start, int end) {
    _safeList.removeRange(start, end);
  }

  /// As [List.fillRange], but requires a value.
  void fillRange(int start, int end, E fillValue) {
    _maybeCheckElement(fillValue);
    _safeList.fillRange(start, end, fillValue);
  }

  /// As [List.replaceRange].
  void replaceRange(int start, int end, Iterable<E> iterable) {
    iterable = evaluateIterable(iterable);
    _maybeCheckElements(iterable);
    _safeList.replaceRange(start, end, iterable);
  }

  // Based on Iterable.

  /// As [Iterable.map], but updates the builder in place. Returns nothing.
  void map(E Function(E) f) {
    var result = _list.map(f).toList(growable: true);
    _maybeCheckElements(result);
    _setSafeList(result);
  }

  /// As [Iterable.where], but updates the builder in place. Returns nothing.
  ///
  /// This method is an alias of [retainWhere].
  void where(bool Function(E) test) => retainWhere(test);

  /// As [Iterable.expand], but updates the builder in place. Returns nothing.
  void expand(Iterable<E> Function(E) f) {
    var result = _list.expand(f).toList(growable: true);
    _maybeCheckElements(result);
    _setSafeList(result);
  }

  /// As [Iterable.take], but updates the builder in place. Returns nothing.
  void take(int n) {
    _setSafeList(_list.take(n).toList(growable: true));
  }

  /// As [Iterable.takeWhile], but updates the builder in place. Returns
  /// nothing.
  void takeWhile(bool Function(E) test) {
    _setSafeList(_list.takeWhile(test).toList(growable: true));
  }

  /// As [Iterable.skip], but updates the builder in place. Returns nothing.
  void skip(int n) {
    _setSafeList(_list.skip(n).toList(growable: true));
  }

  /// As [Iterable.skipWhile], but updates the builder in place. Returns
  /// nothing.
  void skipWhile(bool Function(E) test) {
    _setSafeList(_list.skipWhile(test).toList(growable: true));
  }

  // Internal.

  ListBuilder._uninitialized();

  void _setOwner(_BuiltList<E> listOwner) {
    _list = listOwner._list;
    _listOwner = listOwner;
  }

  void _setSafeList(List<E> list) {
    _list = list;
    _listOwner = null;
  }

  List<E> get _safeList {
    if (_listOwner != null) {
      _setSafeList(List<E>.from(_list, growable: true));
    }
    return _list;
  }

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
