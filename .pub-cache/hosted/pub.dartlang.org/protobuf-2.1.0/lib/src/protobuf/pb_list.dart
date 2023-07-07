// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

typedef CheckFunc<E> = void Function(E? x);

class FrozenPbList<E> extends PbListBase<E> {
  FrozenPbList._(List<E> wrappedList) : super._(wrappedList);

  factory FrozenPbList.from(PbList<E> other) =>
      FrozenPbList._(other._wrappedList);

  UnsupportedError _unsupported(String method) =>
      UnsupportedError('Cannot call $method on an unmodifiable list');

  @override
  void operator []=(int index, E value) => throw _unsupported('set');
  @override
  set length(int newLength) => throw _unsupported('set length');
  @override
  void setAll(int index, Iterable<E> iterable) => throw _unsupported('setAll');
  @override
  void add(E? element) => throw _unsupported('add');
  @override
  void addAll(Iterable<E> iterable) => throw _unsupported('addAll');
  @override
  void insert(int index, E element) => throw _unsupported('insert');
  @override
  void insertAll(int index, Iterable<E> iterable) =>
      throw _unsupported('insertAll');
  @override
  bool remove(Object? element) => throw _unsupported('remove');
  @override
  void removeWhere(bool Function(E element) test) =>
      throw _unsupported('removeWhere');
  @override
  void retainWhere(bool Function(E element) test) =>
      throw _unsupported('retainWhere');
  @override
  void sort([Comparator<E>? compare]) => throw _unsupported('sort');
  @override
  void shuffle([math.Random? random]) => throw _unsupported('shuffle');
  @override
  void clear() => throw _unsupported('clear');
  @override
  E removeAt(int index) => throw _unsupported('removeAt');
  @override
  E removeLast() => throw _unsupported('removeLast');
  @override
  void setRange(int start, int end, Iterable<E> iterable,
          [int skipCount = 0]) =>
      throw _unsupported('setRange');
  @override
  void removeRange(int start, int end) => throw _unsupported('removeRange');
  @override
  void replaceRange(int start, int end, Iterable<E> newContents) =>
      throw _unsupported('replaceRange');
  @override
  void fillRange(int start, int end, [E? fill]) =>
      throw _unsupported('fillRange');
}

class PbList<E> extends PbListBase<E> {
  PbList({CheckFunc<E> check = _checkNotNull}) : super._noList(check: check);

  PbList.from(List from) : super._from(from);

  @Deprecated('Instead use the default constructor with a check function.'
      'This constructor will be removed in the next major version.')
  PbList.forFieldType(int fieldType)
      : super._noList(check: getCheckFunction(fieldType));

  /// Freezes the list by converting to [FrozenPbList].
  FrozenPbList<E> toFrozenPbList() => FrozenPbList<E>.from(this);

  @override
  void add(E element) {
    check(element);
    _wrappedList.add(element);
  }

  @override
  void addAll(Iterable<E> iterable) {
    iterable.forEach(check);
    _wrappedList.addAll(iterable);
  }

  @override
  Iterable<E> get reversed => _wrappedList.reversed;

  @override
  void sort([int Function(E a, E b)? compare]) => _wrappedList.sort(compare);

  @override
  void shuffle([math.Random? random]) => _wrappedList.shuffle(random);

  @override
  void clear() => _wrappedList.clear();

  @override
  void insert(int index, E element) {
    check(element);
    _wrappedList.insert(index, element);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    iterable.forEach(check);
    _wrappedList.insertAll(index, iterable);
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    iterable.forEach(check);
    _wrappedList.setAll(index, iterable);
  }

  @override
  bool remove(Object? element) => _wrappedList.remove(element);

  @override
  E removeAt(int index) => _wrappedList.removeAt(index);

  @override
  E removeLast() => _wrappedList.removeLast();

  @override
  void removeWhere(bool Function(E element) test) =>
      _wrappedList.removeWhere(test);

  @override
  void retainWhere(bool Function(E element) test) =>
      _wrappedList.retainWhere(test);

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    // NOTE: In case `take()` returns less than `end - start` elements, the
    // _wrappedList will fail with a `StateError`.
    iterable.skip(skipCount).take(end - start).forEach(check);
    _wrappedList.setRange(start, end, iterable, skipCount);
  }

  @override
  void removeRange(int start, int end) => _wrappedList.removeRange(start, end);

  @override
  void fillRange(int start, int end, [E? fill]) {
    check(fill);
    _wrappedList.fillRange(start, end, fill);
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    final values = newContents.toList();
    newContents.forEach(check);
    _wrappedList.replaceRange(start, end, values);
  }
}

abstract class PbListBase<E> extends ListBase<E> {
  final List<E> _wrappedList;
  final CheckFunc<E> check;

  PbListBase._(this._wrappedList, {this.check = _checkNotNull});

  PbListBase._noList({this.check = _checkNotNull}) : _wrappedList = <E>[] {
    ArgumentError.checkNotNull(check, 'check');
  }

  PbListBase._from(List from)
      // TODO(sra): Should this be validated?
      : _wrappedList = List<E>.from(from),
        check = _checkNotNull;

  @override
  bool operator ==(other) =>
      (other is PbListBase) && _areListsEqual(other, this);

  @override
  int get hashCode => _HashUtils._hashObjects(_wrappedList);

  @override
  Iterator<E> get iterator => _wrappedList.iterator;

  @override
  Iterable<T> map<T>(T Function(E e) f) => _wrappedList.map<T>(f);

  @override
  Iterable<E> where(bool Function(E element) test) => _wrappedList.where(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      _wrappedList.expand(f);

  @override
  bool contains(Object? element) => _wrappedList.contains(element);

  @override
  void forEach(void Function(E element) action) {
    _wrappedList.forEach(action);
  }

  @override
  E reduce(E Function(E value, E element) combine) =>
      _wrappedList.reduce(combine);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      _wrappedList.fold(initialValue, combine);

  @override
  bool every(bool Function(E element) test) => _wrappedList.every(test);

  @override
  String join([String separator = '']) => _wrappedList.join(separator);

  @override
  bool any(bool Function(E element) test) => _wrappedList.any(test);

  @override
  List<E> toList({bool growable = true}) =>
      _wrappedList.toList(growable: growable);

  @override
  Set<E> toSet() => _wrappedList.toSet();

  @override
  bool get isEmpty => _wrappedList.isEmpty;

  @override
  bool get isNotEmpty => _wrappedList.isNotEmpty;

  @override
  Iterable<E> take(int count) => _wrappedList.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) =>
      _wrappedList.takeWhile(test);

  @override
  Iterable<E> skip(int count) => _wrappedList.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) =>
      _wrappedList.skipWhile(test);

  @override
  E get first => _wrappedList.first;

  @override
  E get last => _wrappedList.last;

  @override
  E get single => _wrappedList.single;

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _wrappedList.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _wrappedList.lastWhere(test, orElse: orElse);

  @override
  E elementAt(int index) => _wrappedList.elementAt(index);

  @override
  String toString() => _wrappedList.toString();

  @override
  E operator [](int index) => _wrappedList[index];

  @override
  int get length => _wrappedList.length;

  // TODO(jakobr): E instead of Object once dart-lang/sdk#31311 is fixed.
  @override
  int indexOf(Object? element, [int start = 0]) =>
      _wrappedList.indexOf(element as E, start);

  // TODO(jakobr): E instead of Object once dart-lang/sdk#31311 is fixed.
  @override
  int lastIndexOf(Object? element, [int? start]) =>
      _wrappedList.lastIndexOf(element as E, start);

  @override
  List<E> sublist(int start, [int? end]) => _wrappedList.sublist(start, end);

  @override
  Iterable<E> getRange(int start, int end) => _wrappedList.getRange(start, end);

  @override
  Map<int, E> asMap() => _wrappedList.asMap();

  @override
  void operator []=(int index, E value) {
    check(value);
    _wrappedList[index] = value;
  }

  /// Unsupported -- violated non-null constraint imposed by protobufs.
  ///
  /// Changes the length of the list. If [newLength] is greater than the current
  /// [length], entries are initialized to [:null:]. Throws an
  /// [UnsupportedError] if the list is not extendable.
  @override
  set length(int newLength) {
    if (newLength > length) {
      throw UnsupportedError('Extending protobuf lists is not supported');
    }
    _wrappedList.length = newLength;
  }
}
