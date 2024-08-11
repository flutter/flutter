// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

// Casting wrappers for collection classes.

abstract class _CastIterableBase<S, T> extends Iterable<T> {
  Iterable<S> get _source;

  Iterator<T> get iterator => new CastIterator<S, T>(_source.iterator);

  // The following members use the default implementation on the
  // throwing iterator. These are all operations that have no more efficient
  // implementation than visiting every element in order,
  // or that has no more efficient way to get the correct type (toList, toSet).
  //
  // * map
  // * where
  // * expand
  // * forEach
  // * reduce
  // * fold
  // * every
  // * any
  // * join
  // * toList
  // * toSet
  // * skipWhile
  // * takeWhile
  // * firstWhere
  // * singleWhere

  int get length => _source.length;
  bool get isEmpty => _source.isEmpty;
  bool get isNotEmpty => _source.isNotEmpty;

  Iterable<T> skip(int count) => new CastIterable<S, T>(_source.skip(count));
  Iterable<T> take(int count) => new CastIterable<S, T>(_source.take(count));

  T elementAt(int index) => _source.elementAt(index) as T;
  T get first => _source.first as T;
  T get last => _source.last as T;
  T get single => _source.single as T;

  bool contains(Object? other) => _source.contains(other);

  // Might be implemented by testing backwards from the end,
  // so use the _source's implementation.
  T lastWhere(bool test(T element), {T Function()? orElse}) =>
      _source.lastWhere((S element) => test(element as T),
          orElse: (orElse == null) ? null : () => orElse() as S) as T;

  String toString() => _source.toString();
}

class CastIterator<S, T> implements Iterator<T> {
  Iterator<S> _source;
  CastIterator(this._source);
  bool moveNext() => _source.moveNext();
  T get current => _source.current as T;
}

class CastIterable<S, T> extends _CastIterableBase<S, T> {
  final Iterable<S> _source;

  CastIterable._(this._source);

  factory CastIterable(Iterable<S> source) {
    if (source is EfficientLengthIterable<S>) {
      return new _EfficientLengthCastIterable<S, T>(source);
    }
    return new CastIterable<S, T>._(source);
  }

  Iterable<R> cast<R>() => new CastIterable<S, R>(_source);
}

class _EfficientLengthCastIterable<S, T> extends CastIterable<S, T>
    implements EfficientLengthIterable<T>, HideEfficientLengthIterable<T> {
  _EfficientLengthCastIterable(EfficientLengthIterable<S> source)
      : super._(source);
}

abstract class _CastListBase<S, T> extends _CastIterableBase<S, T>
    with ListMixin<T> {
  List<S> get _source;

  // Using the default implementation from ListMixin:
  // * reversed
  // * shuffle
  // * indexOf
  // * lastIndexOf
  // * clear
  // * sublist
  // * asMap

  T operator [](int index) => _source[index] as T;

  void operator []=(int index, T value) {
    _source[index] = value as S;
  }

  void set length(int length) {
    _source.length = length;
  }

  void add(T value) {
    _source.add(value as S);
  }

  void addAll(Iterable<T> values) {
    _source.addAll(new CastIterable<T, S>(values));
  }

  void sort([int Function(T v1, T v2)? compare]) {
    _source.sort(
        compare == null ? null : (S v1, S v2) => compare(v1 as T, v2 as T));
  }

  void shuffle([Random? random]) {
    _source.shuffle(random);
  }

  void insert(int index, T element) {
    _source.insert(index, element as S);
  }

  void insertAll(int index, Iterable<T> elements) {
    _source.insertAll(index, new CastIterable<T, S>(elements));
  }

  void setAll(int index, Iterable<T> elements) {
    _source.setAll(index, new CastIterable<T, S>(elements));
  }

  bool remove(Object? value) => _source.remove(value);

  T removeAt(int index) => _source.removeAt(index) as T;

  T removeLast() => _source.removeLast() as T;

  void removeWhere(bool test(T element)) {
    _source.removeWhere((S element) => test(element as T));
  }

  void retainWhere(bool test(T element)) {
    _source.retainWhere((S element) => test(element as T));
  }

  Iterable<T> getRange(int start, int end) =>
      new CastIterable<S, T>(_source.getRange(start, end));

  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    _source.setRange(start, end, new CastIterable<T, S>(iterable), skipCount);
  }

  void removeRange(int start, int end) {
    _source.removeRange(start, end);
  }

  void fillRange(int start, int end, [T? fillValue]) {
    _source.fillRange(start, end, fillValue as S);
  }

  void replaceRange(int start, int end, Iterable<T> replacement) {
    _source.replaceRange(start, end, new CastIterable<T, S>(replacement));
  }
}

class CastList<S, T> extends _CastListBase<S, T> {
  final List<S> _source;
  CastList(this._source);

  List<R> cast<R>() => new CastList<S, R>(_source);
}

class CastSet<S, T> extends _CastIterableBase<S, T> implements Set<T> {
  final Set<S> _source;

  /// Creates a new empty set of the same *kind* as [_source],
  /// but with `<R>` as type argument.
  /// Used by [toSet] and [union].
  final Set<R> Function<R>()? _emptySet;

  CastSet(this._source, this._emptySet);

  Set<R> cast<R>() => new CastSet<S, R>(_source, _emptySet);
  bool add(T value) => _source.add(value as S);

  void addAll(Iterable<T> elements) {
    _source.addAll(new CastIterable<T, S>(elements));
  }

  bool remove(Object? object) => _source.remove(object);

  void removeAll(Iterable<Object?> objects) {
    _source.removeAll(objects);
  }

  void retainAll(Iterable<Object?> objects) {
    _source.retainAll(objects);
  }

  void removeWhere(bool test(T element)) {
    _source.removeWhere((S element) => test(element as T));
  }

  void retainWhere(bool test(T element)) {
    _source.retainWhere((S element) => test(element as T));
  }

  bool containsAll(Iterable<Object?> objects) => _source.containsAll(objects);

  Set<T> intersection(Set<Object?> other) {
    if (_emptySet != null) return _conditionalAdd(other, true);
    return new CastSet<S, T>(_source.intersection(other), null);
  }

  Set<T> difference(Set<Object?> other) {
    if (_emptySet != null) return _conditionalAdd(other, false);
    return new CastSet<S, T>(_source.difference(other), null);
  }

  Set<T> _conditionalAdd(Set<Object?> other, bool otherContains) {
    var emptySet = _emptySet;
    Set<T> result = (emptySet == null) ? new Set<T>() : emptySet<T>();
    for (var element in _source) {
      T castElement = element as T;
      if (otherContains == other.contains(castElement)) result.add(castElement);
    }
    return result;
  }

  Set<T> union(Set<T> other) => _clone()..addAll(other);

  void clear() {
    _source.clear();
  }

  Set<T> _clone() {
    var emptySet = _emptySet;
    Set<T> result = (emptySet == null) ? new Set<T>() : emptySet<T>();
    result.addAll(this);
    return result;
  }

  Set<T> toSet() => _clone();

  T lookup(Object? key) => _source.lookup(key) as T;
}

class CastMap<SK, SV, K, V> extends MapBase<K, V> {
  final Map<SK, SV> _source;

  CastMap(this._source);

  Map<RK, RV> cast<RK, RV>() => new CastMap<SK, SV, RK, RV>(_source);

  bool containsValue(Object? value) => _source.containsValue(value);

  bool containsKey(Object? key) => _source.containsKey(key);

  V? operator [](Object? key) => _source[key] as V?;

  void operator []=(K key, V value) {
    _source[key as SK] = value as SV;
  }

  V putIfAbsent(K key, V Function() ifAbsent) =>
      _source.putIfAbsent(key as SK, () => ifAbsent() as SV) as V;

  void addAll(Map<K, V> other) {
    _source.addAll(new CastMap<K, V, SK, SV>(other));
  }

  V? remove(Object? key) => _source.remove(key) as V?;

  void clear() {
    _source.clear();
  }

  void forEach(void f(K key, V value)) {
    _source.forEach((SK key, SV value) {
      f(key as K, value as V);
    });
  }

  Iterable<K> get keys => new CastIterable<SK, K>(_source.keys);

  Iterable<V> get values => new CastIterable<SV, V>(_source.values);

  int get length => _source.length;

  bool get isEmpty => _source.isEmpty;

  bool get isNotEmpty => _source.isNotEmpty;

  V update(K key, V update(V value), {V Function()? ifAbsent}) {
    return _source.update(key as SK, (SV value) => update(value as V) as SV,
        ifAbsent: (ifAbsent == null) ? null : () => ifAbsent() as SV) as V;
  }

  void updateAll(V update(K key, V value)) {
    _source.updateAll((SK key, SV value) => update(key as K, value as V) as SV);
  }

  Iterable<MapEntry<K, V>> get entries {
    return _source.entries.map<MapEntry<K, V>>(
        (MapEntry<SK, SV> e) => new MapEntry<K, V>(e.key as K, e.value as V));
  }

  void addEntries(Iterable<MapEntry<K, V>> entries) {
    for (var entry in entries) {
      _source[entry.key as SK] = entry.value as SV;
    }
  }

  void removeWhere(bool test(K key, V value)) {
    _source.removeWhere((SK key, SV value) => test(key as K, value as V));
  }
}

class CastQueue<S, T> extends _CastIterableBase<S, T> implements Queue<T> {
  final Queue<S> _source;
  CastQueue(this._source);
  Queue<R> cast<R>() => new CastQueue<S, R>(_source);

  T removeFirst() => _source.removeFirst() as T;
  T removeLast() => _source.removeLast() as T;

  void add(T value) {
    _source.add(value as S);
  }

  void addFirst(T value) {
    _source.addFirst(value as S);
  }

  void addLast(T value) {
    _source.addLast(value as S);
  }

  bool remove(Object? other) => _source.remove(other);
  void addAll(Iterable<T> elements) {
    _source.addAll(new CastIterable<T, S>(elements));
  }

  void removeWhere(bool test(T element)) {
    _source.removeWhere((S element) => test(element as T));
  }

  void retainWhere(bool test(T element)) {
    _source.retainWhere((S element) => test(element as T));
  }

  void clear() {
    _source.clear();
  }
}
