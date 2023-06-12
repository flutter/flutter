// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' show Random;

/// An associative container that maps a key to multiple values.
///
/// Key lookups return mutable collections that are views of the multimap.
/// Updates to the multimap are reflected in these collections and similarly,
/// modifications to the returned collections are reflected in the multimap.
abstract class Multimap<K, V> {
  /// Constructs a new list-backed multimap.
  factory Multimap() => ListMultimap<K, V>();

  /// Constructs a new list-backed multimap. For each element e of [iterable],
  /// adds an association from [key](e) to [value](e). [key] and [value] each
  /// default to the identity function.
  factory Multimap.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) = ListMultimap<K, V>.fromIterable;

  /// Returns whether this multimap contains the given [value].
  bool containsValue(Object? value);

  /// Returns whether this multimap contains the given [key].
  bool containsKey(Object? key);

  /// Returns whether this multimap contains the given association between [key]
  /// and [value].
  bool contains(Object? key, Object? value);

  /// Returns the values for the given [key]. An empty iterable is returned if
  /// [key] is not mapped. The returned collection is a view on the multimap.
  /// Updates to the collection modify the multimap and likewise, modifications
  /// to the multimap are reflected in the returned collection.
  Iterable<V> operator [](Object? key);

  /// Adds an association from the given key to the given value.
  void add(K key, V value);

  /// Adds an association from the given key to each of the given values.
  void addValues(K key, Iterable<V> values);

  /// Adds all associations of [other] to this multimap.
  ///
  /// The operation is equivalent to doing `this[key] = value` for each key and
  /// associated value in other. It iterates over [other], which must therefore
  /// not change during the iteration.
  void addAll(Multimap<K, V> other);

  /// Removes the association between the given [key] and [value]. Returns
  /// `true` if the association existed, `false` otherwise.
  bool remove(Object? key, V? value);

  /// Removes the association for the given [key]. Returns the collection of
  /// removed values, or an empty iterable if [key] was unmapped.
  Iterable<V> removeAll(Object? key);

  /// Removes all entries of this multimap that satisfy the given [predicate].
  void removeWhere(bool predicate(K key, V value));

  /// Removes all data from the multimap.
  void clear();

  /// Applies [f] to each {key, `Iterable<value>`} pair of the multimap.
  ///
  /// It is an error to add or remove keys from the map during iteration.
  void forEachKey(void f(K key, Iterable<V> value));

  /// Applies [f] to each {key, value} pair of the multimap.
  ///
  /// It is an error to add or remove keys from the map during iteration.
  void forEach(void f(K key, V value));

  /// The keys of [this].
  Iterable<K> get keys;

  /// The values of [this].
  Iterable<V> get values;

  /// Returns a view of this multimap as a map.
  Map<K, Iterable<V>> asMap();

  /// The number of keys in the multimap.
  int get length;

  /// Returns true if there is no key in the multimap.
  bool get isEmpty;

  /// Returns true if there is at least one key in the multimap.
  bool get isNotEmpty;
}

/// Abstract base class for multimap implementations.
abstract class _BaseMultimap<K, V, C extends Iterable<V>>
    implements Multimap<K, V> {
  _BaseMultimap();

  /// Constructs a new multimap. For each element e of [iterable], adds an
  /// association from [key](e) to [value](e). [key] and [value] each default
  /// to the identity function.
  _BaseMultimap.fromIterable(Iterable iterable,
      {K key(element)?, V value(element)?}) {
    key ??= _id;
    value ??= _id;
    for (final element in iterable) {
      add(key(element), value(element));
    }
  }

  static T _id<T>(x) => x;

  final Map<K, C> _map = {};

  C _create();
  void _add(C iterable, V value);
  void _addAll(C iterable, Iterable<V> value);
  void _clear(C iterable);
  bool _remove(C iterable, V? value);
  void _removeWhere(C iterable, K key, bool predicate(K key, V value));
  Iterable<V> _wrap(Object? key, C iterable);

  @override
  bool containsValue(Object? value) => values.contains(value);
  @override
  bool containsKey(Object? key) => _map.keys.contains(key);
  @override
  bool contains(Object? key, Object? value) =>
      _map[key]?.contains(value) == true;

  @override
  Iterable<V> operator [](Object? key) {
    return _wrap(key, _map[key] ?? _create());
  }

  @override
  void add(K key, V value) {
    C collection = _map.putIfAbsent(key, _create);
    _add(collection, value);
  }

  @override
  void addValues(K key, Iterable<V> values) {
    C collection = _map.putIfAbsent(key, _create);
    _addAll(collection, values);
  }

  /// Adds all associations of [other] to this multimap.
  ///
  /// The operation is equivalent to doing `this[key] = value` for each key and
  /// associated value in other. It iterates over [other], which must therefore
  /// not change during the iteration.
  ///
  /// This implementation iterates through each key of [other] and adds the
  /// associated values to this instance via [addValues].
  @override
  void addAll(Multimap<K, V> other) => other.forEachKey(addValues);

  @override
  bool remove(Object? key, V? value) {
    if (!_map.containsKey(key)) return false;
    bool removed = _remove(_map[key]!, value);
    if (removed && _map[key]!.isEmpty) _map.remove(key);
    return removed;
  }

  @override
  Iterable<V> removeAll(Object? key) {
    // Cast to dynamic to remove warnings
    var values = _map.remove(key) as dynamic;
    var retValues = _create() as dynamic;
    if (values != null) {
      retValues.addAll(values);
      values.clear();
    }
    return retValues;
  }

  @override
  void removeWhere(bool predicate(K key, V value)) {
    final emptyKeys = Set<K>();
    // TODO(cbracken): iterate over entries
    _map.forEach((K key, C values) {
      _removeWhere(values, key, predicate);
      if (_map[key]!.isEmpty) emptyKeys.add(key);
    });
    emptyKeys.forEach(_map.remove);
  }

  @override
  void clear() {
    _map.forEach((K key, C value) => _clear(value));
    _map.clear();
  }

  @override
  void forEachKey(void f(K key, C value)) => _map.forEach(f);

  @override
  void forEach(void f(K key, V value)) {
    _map.forEach((K key, Iterable<V> values) {
      for (final V value in values) {
        f(key, value);
      }
    });
  }

  @override
  Iterable<K> get keys => _map.keys;
  @override
  Iterable<V> get values => _map.values.expand((x) => x);
  Iterable<Iterable<V>> get _groupedValues => _map.values;
  @override
  int get length => _map.length;
  @override
  bool get isEmpty => _map.isEmpty;
  @override
  bool get isNotEmpty => _map.isNotEmpty;
}

/// A multimap implementation that uses [List]s to store the values associated
/// with each key.
class ListMultimap<K, V> extends _BaseMultimap<K, V, List<V>> {
  ListMultimap();

  /// Constructs a new list-backed multimap. For each element e of [iterable],
  /// adds an association from [key](e) to [value](e). [key] and [value] each
  /// default to the identity function.
  ListMultimap.fromIterable(Iterable iterable,
      {K key(element)?, V value(element)?})
      : super.fromIterable(iterable, key: key, value: value);

  @override
  List<V> _create() => [];
  @override
  void _add(List<V> iterable, V value) {
    iterable.add(value);
  }

  @override
  void _addAll(List<V> iterable, Iterable<V> value) => iterable.addAll(value);
  @override
  void _clear(List<V> iterable) => iterable.clear();
  @override
  bool _remove(List<V> iterable, V? value) => iterable.remove(value);
  @override
  void _removeWhere(List<V> iterable, K key, bool predicate(K key, V value)) =>
      iterable.removeWhere((value) => predicate(key, value));
  @override
  List<V> _wrap(Object? key, List<V> iterable) =>
      _WrappedList(_map, key, iterable);
  @override
  List<V> operator [](Object? key) => super[key] as List<V>;
  @override
  List<V> removeAll(Object? key) => super.removeAll(key) as List<V>;
  @override
  Map<K, List<V>> asMap() => _WrappedMap<K, V, List<V>>(this);
}

/// A multimap implementation that uses [Set]s to store the values associated
/// with each key.
class SetMultimap<K, V> extends _BaseMultimap<K, V, Set<V>> {
  SetMultimap();

  /// Constructs a new set-backed multimap. For each element e of [iterable],
  /// adds an association from [key](e) to [value](e). [key] and [value] each
  /// default to the identity function.
  SetMultimap.fromIterable(Iterable iterable,
      {K key(element)?, V value(element)?})
      : super.fromIterable(iterable, key: key, value: value);

  @override
  Set<V> _create() => Set<V>();
  @override
  void _add(Set<V> iterable, V value) {
    iterable.add(value);
  }

  @override
  void _addAll(Set<V> iterable, Iterable<V> value) => iterable.addAll(value);
  @override
  void _clear(Set<V> iterable) => iterable.clear();
  @override
  bool _remove(Set<V> iterable, V? value) => iterable.remove(value);
  @override
  void _removeWhere(Set<V> iterable, K key, bool predicate(K key, V value)) =>
      iterable.removeWhere((value) => predicate(key, value));
  @override
  Set<V> _wrap(Object? key, Set<V> iterable) =>
      _WrappedSet(_map, key, iterable);
  @override
  Set<V> operator [](Object? key) => super[key] as Set<V>;
  @override
  Set<V> removeAll(Object? key) => super.removeAll(key) as Set<V>;
  @override
  Map<K, Set<V>> asMap() => _WrappedMap<K, V, Set<V>>(this);
}

/// A [Map] that delegates its operations to an underlying multimap.
class _WrappedMap<K, V, C extends Iterable<V>> implements Map<K, C> {
  _WrappedMap(this._multimap);

  final _BaseMultimap<K, V, C> _multimap;

  @override
  C? operator [](Object? key) => _multimap[key] as C; // Always non-null.

  @override
  void operator []=(K key, C value) {
    throw UnsupportedError('Insert unsupported on map view');
  }

  @override
  void addAll(Map<K, C> other) {
    throw UnsupportedError('Insert unsupported on map view');
  }

  @override
  C putIfAbsent(K key, C ifAbsent()) {
    throw UnsupportedError('Insert unsupported on map view');
  }

  @override
  void clear() => _multimap.clear();
  @override
  bool containsKey(Object? key) => _multimap.containsKey(key);
  @override
  bool containsValue(Object? value) => _multimap.containsValue(value);
  @override
  void forEach(void f(K key, C value)) => _multimap.forEachKey(f);
  @override
  bool get isEmpty => _multimap.isEmpty;
  @override
  bool get isNotEmpty => _multimap.isNotEmpty;
  @override
  Iterable<K> get keys => _multimap.keys;
  @override
  int get length => _multimap.length;
  @override
  C? remove(Object? key) => _multimap.removeAll(key) as C; // Always non-null.
  @override
  Iterable<C> get values => _multimap._groupedValues as Iterable<C>;

  @override
  Map<K2, V2> cast<K2, V2>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  Iterable<MapEntry<K, C>> get entries => _multimap._map.entries;

  @override
  void addEntries(Iterable<MapEntry<K, C>> entries) {
    throw UnsupportedError('Insert unsupported on map view');
  }

  @override
  Map<K2, C2> map<K2, C2>(MapEntry<K2, C2> transform(K key, C value)) =>
      _multimap._map.map(transform);

  @override
  C update(K key, C update(C value), {C ifAbsent()?}) {
    throw UnsupportedError('Update unsupported on map view');
  }

  @override
  void updateAll(C update(K key, C value)) {
    throw UnsupportedError('Update unsupported on map view');
  }

  @override
  void removeWhere(bool test(K key, C value)) {
    var keysToRemove = <K>[];
    // TODO(cbracken): iterate over entries.
    for (final key in keys) {
      if (test(key, this[key] as C)) keysToRemove.add(key);
    }
    keysToRemove.forEach(_multimap.removeAll);
  }
}

/// Iterable wrapper that syncs to an underlying map.
class _WrappedIterable<K, V, C extends Iterable<V>> implements Iterable<V> {
  _WrappedIterable(this._map, this._key, this._delegate);

  final K _key;
  final Map<K, C> _map;
  C _delegate;

  void _addToMap() => _map[_key] = _delegate;

  /// Ensures we hold an up-to-date delegate. In the case where all mappings
  /// for _key are removed from the multimap, the Iterable referenced by
  /// _delegate is removed from the underlying map. At that point, any new
  /// addition via the multimap triggers the creation of a new Iterable, and
  /// the empty delegate we hold would be stale. As such, we check the
  /// underlying map and update our delegate when the one we hold is empty.
  void _syncDelegate() {
    if (_delegate.isEmpty) {
      var updated = _map[_key];
      if (updated != null) {
        _delegate = updated;
      }
    }
  }

  @override
  bool any(bool test(V element)) {
    _syncDelegate();
    return _delegate.any(test);
  }

  @override
  Iterable<T> cast<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  bool contains(Object? element) {
    _syncDelegate();
    return _delegate.contains(element);
  }

  @override
  V elementAt(int index) {
    _syncDelegate();
    return _delegate.elementAt(index);
  }

  @override
  bool every(bool test(V element)) {
    _syncDelegate();
    return _delegate.every(test);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> f(V element)) {
    _syncDelegate();
    return _delegate.expand(f);
  }

  @override
  V get first {
    _syncDelegate();
    return _delegate.first;
  }

  @override
  V firstWhere(bool test(V element), {V orElse()?}) {
    _syncDelegate();
    return _delegate.firstWhere(test, orElse: orElse);
  }

  @override
  T fold<T>(T initialValue, T combine(T previousValue, V element)) {
    _syncDelegate();
    return _delegate.fold(initialValue, combine);
  }

  @override
  Iterable<V> followedBy(Iterable<V> other) {
    _syncDelegate();
    return _delegate.followedBy(other);
  }

  @override
  void forEach(void f(V element)) {
    _syncDelegate();
    _delegate.forEach(f);
  }

  @override
  bool get isEmpty {
    _syncDelegate();
    return _delegate.isEmpty;
  }

  @override
  bool get isNotEmpty {
    _syncDelegate();
    return _delegate.isNotEmpty;
  }

  @override
  Iterator<V> get iterator {
    _syncDelegate();
    return _delegate.iterator;
  }

  @override
  String join([String separator = '']) {
    _syncDelegate();
    return _delegate.join(separator);
  }

  @override
  V get last {
    _syncDelegate();
    return _delegate.last;
  }

  @override
  V lastWhere(bool test(V element), {V orElse()?}) {
    _syncDelegate();
    return _delegate.lastWhere(test, orElse: orElse);
  }

  @override
  int get length {
    _syncDelegate();
    return _delegate.length;
  }

  @override
  Iterable<T> map<T>(T f(V element)) {
    _syncDelegate();
    return _delegate.map(f);
  }

  @override
  V reduce(V combine(V value, V element)) {
    _syncDelegate();
    return _delegate.reduce(combine);
  }

  @override
  V get single {
    _syncDelegate();
    return _delegate.single;
  }

  @override
  V singleWhere(bool test(V element), {V orElse()?}) {
    _syncDelegate();
    return _delegate.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<V> skip(int n) {
    _syncDelegate();
    return _delegate.skip(n);
  }

  @override
  Iterable<V> skipWhile(bool test(V value)) {
    _syncDelegate();
    return _delegate.skipWhile(test);
  }

  @override
  Iterable<V> take(int n) {
    _syncDelegate();
    return _delegate.take(n);
  }

  @override
  Iterable<V> takeWhile(bool test(V value)) {
    _syncDelegate();
    return _delegate.takeWhile(test);
  }

  @override
  List<V> toList({bool growable = true}) {
    _syncDelegate();
    return _delegate.toList(growable: growable);
  }

  @override
  Set<V> toSet() {
    _syncDelegate();
    return _delegate.toSet();
  }

  @override
  String toString() {
    _syncDelegate();
    return _delegate.toString();
  }

  @override
  Iterable<V> where(bool test(V element)) {
    _syncDelegate();
    return _delegate.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('whereType');
  }
}

class _WrappedList<K, V> extends _WrappedIterable<K, V, List<V>>
    implements List<V> {
  _WrappedList(Map<K, List<V>> map, K key, List<V> delegate)
      : super(map, key, delegate);

  @override
  V operator [](int index) => elementAt(index);

  @override
  void operator []=(int index, V value) {
    _syncDelegate();
    _delegate[index] = value;
  }

  @override
  List<V> operator +(List<V> other) {
    _syncDelegate();
    return _delegate + other;
  }

  @override
  void add(V value) {
    _syncDelegate();
    var wasEmpty = _delegate.isEmpty;
    _delegate.add(value);
    if (wasEmpty) _addToMap();
  }

  @override
  void addAll(Iterable<V> iterable) {
    _syncDelegate();
    var wasEmpty = _delegate.isEmpty;
    _delegate.addAll(iterable);
    if (wasEmpty) _addToMap();
  }

  @override
  Map<int, V> asMap() {
    _syncDelegate();
    return _delegate.asMap();
  }

  @override
  List<T> cast<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  void clear() {
    _syncDelegate();
    _delegate.clear();
    _map.remove(_key);
  }

  @override
  void fillRange(int start, int end, [V? fillValue]) {
    _syncDelegate();
    _delegate.fillRange(start, end, fillValue);
  }

  @override
  set first(V value) {
    if (isEmpty) throw RangeError.index(0, this);
    this[0] = value;
  }

  @override
  Iterable<V> getRange(int start, int end) {
    _syncDelegate();
    return _delegate.getRange(start, end);
  }

  @override
  int indexOf(V element, [int start = 0]) {
    _syncDelegate();
    return _delegate.indexOf(element, start);
  }

  @override
  int indexWhere(bool test(V element), [int start = 0]) {
    _syncDelegate();
    return _delegate.indexWhere(test, start);
  }

  @override
  void insert(int index, V element) {
    _syncDelegate();
    var wasEmpty = _delegate.isEmpty;
    _delegate.insert(index, element);
    if (wasEmpty) _addToMap();
  }

  @override
  void insertAll(int index, Iterable<V> iterable) {
    _syncDelegate();
    var wasEmpty = _delegate.isEmpty;
    _delegate.insertAll(index, iterable);
    if (wasEmpty) _addToMap();
  }

  @override
  set last(V value) {
    if (isEmpty) throw RangeError.index(0, this);
    this[length - 1] = value;
  }

  @override
  int lastIndexOf(V element, [int? start]) {
    _syncDelegate();
    return _delegate.lastIndexOf(element, start);
  }

  @override
  int lastIndexWhere(bool test(V element), [int? start]) {
    _syncDelegate();
    return _delegate.lastIndexWhere(test, start);
  }

  @override
  set length(int newLength) {
    _syncDelegate();
    var wasEmpty = _delegate.isEmpty;
    _delegate.length = newLength;
    if (wasEmpty) _addToMap();
  }

  @override
  bool remove(Object? value) {
    _syncDelegate();
    bool removed = _delegate.remove(value);
    if (_delegate.isEmpty) _map.remove(_key);
    return removed;
  }

  @override
  V removeAt(int index) {
    _syncDelegate();
    V removed = _delegate.removeAt(index);
    if (_delegate.isEmpty) _map.remove(_key);
    return removed;
  }

  @override
  V removeLast() {
    _syncDelegate();
    V removed = _delegate.removeLast();
    if (_delegate.isEmpty) _map.remove(_key);
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    _syncDelegate();
    _delegate.removeRange(start, end);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  void removeWhere(bool test(V element)) {
    _syncDelegate();
    _delegate.removeWhere(test);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  void replaceRange(int start, int end, Iterable<V> iterable) {
    _syncDelegate();
    _delegate.replaceRange(start, end, iterable);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  void retainWhere(bool test(V element)) {
    _syncDelegate();
    _delegate.retainWhere(test);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  Iterable<V> get reversed {
    _syncDelegate();
    return _delegate.reversed;
  }

  @override
  void setAll(int index, Iterable<V> iterable) {
    _syncDelegate();
    _delegate.setAll(index, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<V> iterable, [int skipCount = 0]) {
    _syncDelegate();
  }

  @override
  void shuffle([Random? random]) {
    _syncDelegate();
    _delegate.shuffle(random);
  }

  @override
  void sort([int compare(V a, V b)?]) {
    _syncDelegate();
    _delegate.sort(compare);
  }

  @override
  List<V> sublist(int start, [int? end]) {
    _syncDelegate();
    return _delegate.sublist(start, end);
  }
}

class _WrappedSet<K, V> extends _WrappedIterable<K, V, Set<V>>
    implements Set<V> {
  _WrappedSet(Map<K, Set<V>> map, K key, Set<V> delegate)
      : super(map, key, delegate);

  @override
  bool add(V value) {
    _syncDelegate();
    var wasEmpty = _delegate.isEmpty;
    bool wasAdded = _delegate.add(value);
    if (wasEmpty) _addToMap();
    return wasAdded;
  }

  @override
  void addAll(Iterable<V> elements) {
    _syncDelegate();
    var wasEmpty = _delegate.isEmpty;
    _delegate.addAll(elements);
    if (wasEmpty) _addToMap();
  }

  @override
  Set<T> cast<T>() {
    // TODO(cbracken): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  void clear() {
    _syncDelegate();
    _delegate.clear();
    _map.remove(_key);
  }

  @override
  bool containsAll(Iterable<Object?> other) {
    _syncDelegate();
    return _delegate.containsAll(other);
  }

  @override
  Set<V> difference(Set<Object?> other) {
    _syncDelegate();
    return _delegate.difference(other);
  }

  @override
  Set<V> intersection(Set<Object?> other) {
    _syncDelegate();
    return _delegate.intersection(other);
  }

  @override
  V? lookup(Object? object) {
    _syncDelegate();
    return _delegate.lookup(object);
  }

  @override
  bool remove(Object? value) {
    _syncDelegate();
    bool removed = _delegate.remove(value);
    if (_delegate.isEmpty) _map.remove(_key);
    return removed;
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    _syncDelegate();
    _delegate.removeAll(elements);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  void removeWhere(bool test(V element)) {
    _syncDelegate();
    _delegate.removeWhere(test);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    _syncDelegate();
    _delegate.retainAll(elements);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  void retainWhere(bool test(V element)) {
    _syncDelegate();
    _delegate.retainWhere(test);
    if (_delegate.isEmpty) _map.remove(_key);
  }

  @override
  Set<V> union(Set<V> other) {
    _syncDelegate();
    return _delegate.union(other);
  }
}
