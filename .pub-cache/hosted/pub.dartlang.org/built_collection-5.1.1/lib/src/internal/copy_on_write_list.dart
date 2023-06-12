// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

class CopyOnWriteList<E> implements List<E> {
  bool _copyBeforeWrite;
  final bool _growable;
  List<E> _list;

  CopyOnWriteList(this._list, this._growable) : _copyBeforeWrite = true;

  // Read-only methods: just forward.

  @override
  int get length => _list.length;

  @override
  E operator [](int index) => _list[index];

  @override
  List<E> operator +(List<E> other) => _list + other;

  @override
  bool any(bool Function(E) test) => _list.any(test);

  @override
  Map<int, E> asMap() => _list.asMap();

  @override
  List<T> cast<T>() => CopyOnWriteList<T>(_list.cast<T>(), _growable);

  @override
  bool contains(Object? element) => _list.contains(element);

  @override
  E elementAt(int index) => _list.elementAt(index);

  @override
  bool every(bool Function(E) test) => _list.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) f) => _list.expand(f);

  @override
  E get first => _list.first;

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) =>
      _list.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) =>
      _list.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _list.followedBy(other);

  @override
  void forEach(void Function(E) f) => _list.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => _list.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  @override
  int indexWhere(bool Function(E) test, [int start = 0]) =>
      _list.indexWhere(test, start);

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  Iterator<E> get iterator => _list.iterator;

  @override
  String join([String separator = '']) => _list.join(separator);

  @override
  E get last => _list.last;

  @override
  int lastIndexOf(E element, [int? start]) => _list.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E) test, [int? start]) =>
      _list.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E) test, {E Function()? orElse}) =>
      _list.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E) f) => _list.map(f);

  @override
  E reduce(E Function(E, E) combine) => _list.reduce(combine);

  @override
  Iterable<E> get reversed => _list.reversed;

  @override
  E get single => _list.single;

  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) =>
      _list.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => _list.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E) test) => _list.skipWhile(test);

  @override
  List<E> sublist(int start, [int? end]) => _list.sublist(start, end);

  @override
  Iterable<E> take(int count) => _list.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E) test) => _list.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => _list.toList(growable: growable);

  @override
  Set<E> toSet() => _list.toSet();

  @override
  Iterable<E> where(bool Function(E) test) => _list.where(test);

  @override
  Iterable<T> whereType<T>() => _list.whereType<T>();

  // Mutating methods: copy first if needed.

  @override
  set length(int length) {
    _maybeCopyBeforeWrite();
    _list.length = length;
  }

  @override
  void operator []=(int index, E element) {
    _maybeCopyBeforeWrite();
    _list[index] = element;
  }

  @override
  set first(E element) {
    _maybeCopyBeforeWrite();
    _list.first = element;
  }

  @override
  set last(E element) {
    _maybeCopyBeforeWrite();
    _list.last = element;
  }

  @override
  void add(E value) {
    _maybeCopyBeforeWrite();
    _list.add(value);
  }

  @override
  void addAll(Iterable<E> iterable) {
    _maybeCopyBeforeWrite();
    _list.addAll(iterable);
  }

  @override
  void sort([int Function(E, E)? compare]) {
    _maybeCopyBeforeWrite();
    _list.sort(compare);
  }

  @override
  void shuffle([Random? random]) {
    _maybeCopyBeforeWrite();
    _list.shuffle(random);
  }

  @override
  void clear() {
    _maybeCopyBeforeWrite();
    _list.clear();
  }

  @override
  void insert(int index, E element) {
    _maybeCopyBeforeWrite();
    _list.insert(index, element);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _maybeCopyBeforeWrite();
    _list.insertAll(index, iterable);
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    _maybeCopyBeforeWrite();
    _list.setAll(index, iterable);
  }

  @override
  bool remove(Object? value) {
    _maybeCopyBeforeWrite();
    return _list.remove(value);
  }

  @override
  E removeAt(int index) {
    _maybeCopyBeforeWrite();
    return _list.removeAt(index);
  }

  @override
  E removeLast() {
    _maybeCopyBeforeWrite();
    return _list.removeLast();
  }

  @override
  void removeWhere(bool Function(E) test) {
    _maybeCopyBeforeWrite();
    _list.removeWhere(test);
  }

  @override
  void retainWhere(bool Function(E) test) {
    _maybeCopyBeforeWrite();
    _list.retainWhere(test);
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _maybeCopyBeforeWrite();
    _list.setRange(start, end, iterable, skipCount);
  }

  @override
  void removeRange(int start, int end) {
    _maybeCopyBeforeWrite();
    _list.removeRange(start, end);
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    _maybeCopyBeforeWrite();
    _list.fillRange(start, end, fillValue);
  }

  @override
  void replaceRange(int start, int end, Iterable<E> iterable) {
    _maybeCopyBeforeWrite();
    _list.replaceRange(start, end, iterable);
  }

  @override
  String toString() => _list.toString();

  // Internal.

  void _maybeCopyBeforeWrite() {
    if (!_copyBeforeWrite) return;
    _copyBeforeWrite = false;
    _list = List<E>.from(_list, growable: _growable);
  }
}
