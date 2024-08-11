// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" as internal;

import "dart:_internal" show unsafeCast, patch, IterableElementError;

class _TypeTest<T> {
  bool test(v) => v is T;
}

@patch
class HashMap<K, V> {
  @patch
  @pragma("vm:prefer-inline")
  factory HashMap(
      {bool equals(K key1, K key2)?,
      int hashCode(K key)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _HashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _IdentityHashMap<K, V>();
        }
        equals ??= _defaultEquals;
      }
    } else {
      hashCode ??= _defaultHashCode;
      equals ??= _defaultEquals;
    }
    return new _CustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @patch
  factory HashMap.identity() => new _IdentityHashMap<K, V>();

  Set<K> _newKeySet();
}

const int _MODIFICATION_COUNT_MASK = 0x3fffffff;

base class _HashMap<K, V> extends MapBase<K, V> implements HashMap<K, V> {
  static const int _INITIAL_CAPACITY = 8;

  int _elementCount = 0;
  var _buckets = List<_HashMapEntry?>.filled(_INITIAL_CAPACITY, null);
  int _modificationCount = 0;

  int get length => _elementCount;
  bool get isEmpty => _elementCount == 0;
  bool get isNotEmpty => _elementCount != 0;

  Iterable<K> get keys => new _HashMapKeyIterable<K, V>(this);
  Iterable<V> get values => new _HashMapValueIterable<K, V>(this);

  bool containsKey(Object? key) {
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) return true;
      entry = entry.next;
    }
    return false;
  }

  bool containsValue(Object? value) {
    final buckets = _buckets;
    final length = buckets.length;
    for (int i = 0; i < length; i++) {
      var entry = buckets[i];
      while (entry != null) {
        if (entry.value == value) return true;
        entry = entry.next;
      }
    }
    return false;
  }

  V? operator [](Object? key) {
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) {
        return unsafeCast<V>(entry.value);
      }
      entry = entry.next;
    }
    return null;
  }

  void operator []=(K key, V value) {
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) {
        return unsafeCast<V>(entry.value);
      }
      entry = entry.next;
    }
    final stamp = _modificationCount;
    final V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  void forEach(void action(K key, V value)) {
    final stamp = _modificationCount;
    final buckets = _buckets;
    final length = buckets.length;
    for (int i = 0; i < length; i++) {
      var entry = buckets[i];
      while (entry != null) {
        action(unsafeCast<K>(entry.key), unsafeCast<V>(entry.value));
        if (stamp != _modificationCount) {
          throw new ConcurrentModificationError(this);
        }
        entry = entry.next;
      }
    }
  }

  V? remove(Object? key) {
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    _HashMapEntry? previous = null;
    while (entry != null) {
      final next = entry.next;
      if (hashCode == entry.hashCode && entry.key == key) {
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return unsafeCast<V>(entry.value);
      }
      previous = entry;
      entry = next;
    }
    return null;
  }

  void clear() {
    _buckets = new List.filled(_INITIAL_CAPACITY, null);
    if (_elementCount > 0) {
      _elementCount = 0;
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
  }

  void _removeEntry(
      _HashMapEntry entry, _HashMapEntry? previousInBucket, int bucketIndex) {
    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.next;
    } else {
      previousInBucket.next = entry.next;
    }
  }

  void _addEntry(List<_HashMapEntry?> buckets, int index, int length, K key,
      V value, int hashCode) {
    final entry = new _HashMapEntry(key, value, hashCode, buckets[index]);
    buckets[index] = entry;
    final newElements = _elementCount + 1;
    _elementCount = newElements;
    // If we end up with more than 75% non-empty entries, we
    // resize the backing store.
    if ((newElements << 2) > ((length << 1) + length)) _resize();
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _resize() {
    final oldBuckets = _buckets;
    final oldLength = oldBuckets.length;
    final newLength = oldLength << 1;
    final newBuckets = new List<_HashMapEntry?>.filled(newLength, null);
    for (int i = 0; i < oldLength; i++) {
      var entry = oldBuckets[i];
      while (entry != null) {
        final next = entry.next;
        final hashCode = entry.hashCode;
        final index = hashCode & (newLength - 1);
        entry.next = newBuckets[index];
        newBuckets[index] = entry;
        entry = next;
      }
    }
    _buckets = newBuckets;
  }

  @override
  V update(K key, V update(V value), {V Function()? ifAbsent}) {
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) {
        return entry.value = update(unsafeCast<V>(entry.value));
      }
      entry = entry.next;
    }
    if (ifAbsent != null) {
      V newValue = ifAbsent();
      _addEntry(buckets, index, length, key, newValue, hashCode);
      return newValue;
    } else {
      throw ArgumentError.value(key, "key", "Key not in map.");
    }
  }

  Set<K> _newKeySet() => new _HashSet<K>();
}

base class _CustomHashMap<K, V> extends _HashMap<K, V> {
  final _Equality<K> _equals;
  final _Hasher<K> _hashCode;
  final _Predicate _validKey;
  _CustomHashMap(this._equals, this._hashCode, _Predicate? validKey)
      : _validKey = (validKey != null) ? validKey : new _TypeTest<K>().test;

  bool containsKey(Object? key) {
    if (!_validKey(key)) return false;
    K lkey = key as K;
    final hashCode = _hashCode(lkey);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          _equals(unsafeCast<K>(entry.key), unsafeCast<K>(lkey))) {
        return true;
      }
      entry = entry.next;
    }
    return false;
  }

  V? operator [](Object? key) {
    if (!_validKey(key)) return null;
    K lkey = key as K;
    final hashCode = _hashCode(lkey);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          _equals(unsafeCast<K>(entry.key), unsafeCast<K>(lkey))) {
        return unsafeCast<V>(entry.value);
      }
      entry = entry.next;
    }
    return null;
  }

  void operator []=(K key, V value) {
    final hashCode = _hashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          _equals(unsafeCast<K>(entry.key), unsafeCast<K>(key))) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    final hashCode = _hashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          _equals(unsafeCast<K>(entry.key), unsafeCast<K>(key))) {
        return unsafeCast<V>(entry.value);
      }
      entry = entry.next;
    }
    int stamp = _modificationCount;
    V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  V? remove(Object? key) {
    if (!_validKey(key)) return null;
    K lkey = key as K;
    final hashCode = _hashCode(lkey);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    _HashMapEntry? previous = null;
    while (entry != null) {
      final next = entry.next;
      if (hashCode == entry.hashCode &&
          _equals(unsafeCast<K>(entry.key), unsafeCast<K>(lkey))) {
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return unsafeCast<V>(entry.value);
      }
      previous = entry;
      entry = next;
    }
    return null;
  }

  Set<K> _newKeySet() => new _CustomHashSet<K>(_equals, _hashCode, _validKey);
}

base class _IdentityHashMap<K, V> extends _HashMap<K, V> {
  bool containsKey(Object? key) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) return true;
      entry = entry.next;
    }
    return false;
  }

  V? operator [](Object? key) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        return unsafeCast<V>(entry.value);
      }
      entry = entry.next;
    }
    return null;
  }

  void operator []=(K key, V value) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        return unsafeCast<V>(entry.value);
      }
      entry = entry.next;
    }
    final stamp = _modificationCount;
    V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  V? remove(Object? key) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    _HashMapEntry? previous = null;
    while (entry != null) {
      final next = entry.next;
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return unsafeCast<V>(entry.value);
      }
      previous = entry;
      entry = next;
    }
    return null;
  }

  @override
  V update(K key, V update(V value), {V Function()? ifAbsent}) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        return entry.value = update(unsafeCast<V>(entry.value));
      }
      entry = entry.next;
    }
    if (ifAbsent != null) {
      V newValue = ifAbsent();
      _addEntry(buckets, index, length, key, newValue, hashCode);
      return newValue;
    } else {
      throw ArgumentError.value(key, "key", "Key not in map.");
    }
  }

  Set<K> _newKeySet() => new _IdentityHashSet<K>();
}

class _HashMapEntry {
  final Object? key;
  Object? value;
  final int hashCode;
  _HashMapEntry? next;
  _HashMapEntry(this.key, this.value, this.hashCode, this.next);
}

abstract class _HashMapIterable<K, V, E>
    extends internal.EfficientLengthIterable<E> {
  final _HashMap<K, V> _map;
  _HashMapIterable(this._map);
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}

class _HashMapKeyIterable<K, V> extends _HashMapIterable<K, V, K> {
  _HashMapKeyIterable(_HashMap<K, V> map) : super(map);
  Iterator<K> get iterator => new _HashMapKeyIterator<K, V>(_map);
  bool contains(Object? key) => _map.containsKey(key);
  void forEach(void action(K key)) {
    _map.forEach((K key, _) {
      action(key);
    });
  }

  Set<K> toSet() => _map._newKeySet()..addAll(this);
}

class _HashMapValueIterable<K, V> extends _HashMapIterable<K, V, V> {
  _HashMapValueIterable(_HashMap<K, V> map) : super(map);
  Iterator<V> get iterator => new _HashMapValueIterator<K, V>(_map);
  bool contains(Object? value) => _map.containsValue(value);
  void forEach(void action(V value)) {
    _map.forEach((_, V value) {
      action(value);
    });
  }
}

abstract class _HashMapIterator<K, V, E> implements Iterator<E> {
  final _HashMap<K, V> _map;
  final int _stamp;

  int _index = 0;
  _HashMapEntry? _entry;

  _HashMapIterator(this._map) : _stamp = _map._modificationCount;

  bool moveNext() {
    if (_stamp != _map._modificationCount) {
      throw new ConcurrentModificationError(_map);
    }
    var entry = _entry;
    if (entry != null) {
      final next = entry.next;
      if (next != null) {
        _entry = next;
        return true;
      }
      _entry = null;
    }
    final buckets = _map._buckets;
    final length = buckets.length;
    for (int i = _index; i < length; i++) {
      entry = buckets[i];
      if (entry != null) {
        _index = i + 1;
        _entry = entry;
        return true;
      }
    }
    _index = length;
    return false;
  }
}

class _HashMapKeyIterator<K, V> extends _HashMapIterator<K, V, K> {
  _HashMapKeyIterator(_HashMap<K, V> map) : super(map);
  K get current => unsafeCast<K>(_entry!.key);
}

class _HashMapValueIterator<K, V> extends _HashMapIterator<K, V, V> {
  _HashMapValueIterator(_HashMap<K, V> map) : super(map);
  V get current => unsafeCast<V>(_entry!.value);
}

@patch
class HashSet<E> {
  @patch
  factory HashSet(
      {bool equals(E e1, E e2)?,
      int hashCode(E e)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _HashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _IdentityHashSet<E>();
        }
        equals ??= _defaultEquals;
      }
    } else {
      hashCode ??= _defaultHashCode;
      equals ??= _defaultEquals;
    }
    return new _CustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory HashSet.identity() => new _IdentityHashSet<E>();
}

base class _HashSet<E> extends _SetBase<E> implements HashSet<E> {
  static const int _INITIAL_CAPACITY = 8;

  var _buckets = List<_HashSetEntry<E>?>.filled(_INITIAL_CAPACITY, null);
  int _elementCount = 0;
  int _modificationCount = 0;

  bool _equals(Object? e1, Object? e2) => e1 == e2;
  int _hashCode(Object? e) => e.hashCode;

  static Set<R> _newEmpty<R>() => new _HashSet<R>();

  // Iterable.

  Iterator<E> get iterator => new _HashSetIterator<E>(this);

  int get length => _elementCount;

  bool get isEmpty => _elementCount == 0;

  bool get isNotEmpty => _elementCount != 0;

  bool contains(Object? object) {
    int index = _hashCode(object) & (_buckets.length - 1);
    var entry = _buckets[index];
    while (entry != null) {
      if (_equals(entry.key, object)) return true;
      entry = entry.next;
    }
    return false;
  }

  E? lookup(Object? object) {
    int index = _hashCode(object) & (_buckets.length - 1);
    var entry = _buckets[index];
    while (entry != null) {
      var key = entry.key;
      if (_equals(key, object)) return key;
      entry = entry.next;
    }
    return null;
  }

  E get first {
    for (int i = 0; i < _buckets.length; i++) {
      var entry = _buckets[i];
      if (entry != null) {
        return entry.key;
      }
    }
    throw IterableElementError.noElement();
  }

  E get last {
    for (int i = _buckets.length - 1; i >= 0; i--) {
      var entry = _buckets[i];
      if (entry != null) {
        var nextEntry = entry.next;
        while (nextEntry != null) {
          entry = nextEntry;
          nextEntry = nextEntry.next;
        }
        return entry!.key;
      }
    }
    throw IterableElementError.noElement();
  }

  // Set.

  bool add(E element) {
    final hashCode = _hashCode(element);
    final index = hashCode & (_buckets.length - 1);
    var entry = _buckets[index];
    while (entry != null) {
      if (_equals(entry.key, element)) return false;
      entry = entry.next;
    }
    _addEntry(element, hashCode, index);
    return true;
  }

  void addAll(Iterable<E> objects) {
    for (E object in objects) {
      add(object);
    }
  }

  bool _remove(Object? object, int hashCode) {
    final index = hashCode & (_buckets.length - 1);
    var entry = _buckets[index];
    _HashSetEntry<E>? previous = null;
    while (entry != null) {
      if (_equals(entry.key, object)) {
        final next = entry.remove();
        if (previous == null) {
          _buckets[index] = next;
        } else {
          previous.next = next;
        }
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return true;
      }
      previous = entry;
      entry = entry.next;
    }
    return false;
  }

  bool remove(Object? object) => _remove(object, _hashCode(object));

  void removeAll(Iterable<Object?> objectsToRemove) {
    for (Object? object in objectsToRemove) {
      _remove(object, _hashCode(object));
    }
  }

  void _filterWhere(bool test(E element), bool removeMatching) {
    int length = _buckets.length;
    for (int index = 0; index < length; index++) {
      var entry = _buckets[index];
      _HashSetEntry<E>? previous = null;
      while (entry != null) {
        int modificationCount = _modificationCount;
        bool testResult = test(entry.key);
        if (modificationCount != _modificationCount) {
          throw new ConcurrentModificationError(this);
        }
        if (testResult == removeMatching) {
          final next = entry.remove();
          if (previous == null) {
            _buckets[index] = next;
          } else {
            previous.next = next;
          }
          _elementCount--;
          _modificationCount =
              (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
          entry = next;
        } else {
          previous = entry;
          entry = entry.next;
        }
      }
    }
  }

  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  void clear() {
    _buckets = List<_HashSetEntry<E>?>.filled(_INITIAL_CAPACITY, null);
    if (_elementCount > 0) {
      _elementCount = 0;
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
  }

  void _addEntry(E key, int hashCode, int index) {
    _buckets[index] = new _HashSetEntry<E>(key, hashCode, _buckets[index]);
    int newElements = _elementCount + 1;
    _elementCount = newElements;
    int length = _buckets.length;
    // If we end up with more than 75% non-empty entries, we
    // resize the backing store.
    if ((newElements << 2) > ((length << 1) + length)) _resize();
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _resize() {
    final oldLength = _buckets.length;
    final newLength = oldLength << 1;
    final oldBuckets = _buckets;
    final newBuckets = List<_HashSetEntry<E>?>.filled(newLength, null);
    for (int i = 0; i < oldLength; i++) {
      var entry = oldBuckets[i];
      while (entry != null) {
        final next = entry.next;
        int newIndex = entry.hashCode & (newLength - 1);
        entry.next = newBuckets[newIndex];
        newBuckets[newIndex] = entry;
        entry = next;
      }
    }
    _buckets = newBuckets;
  }

  HashSet<E> _newSet() => new _HashSet<E>();
  HashSet<R> _newSimilarSet<R>() => new _HashSet<R>();
}

base class _IdentityHashSet<E> extends _HashSet<E> {
  int _hashCode(Object? e) => identityHashCode(e);
  bool _equals(Object? e1, Object? e2) => identical(e1, e2);

  HashSet<E> _newSet() => new _IdentityHashSet<E>();
  HashSet<R> _newSimilarSet<R>() => new _IdentityHashSet<R>();
}

base class _CustomHashSet<E> extends _HashSet<E> {
  final _Equality<E> _equality;
  final _Hasher<E> _hasher;
  final _Predicate _validKey;
  _CustomHashSet(this._equality, this._hasher, _Predicate? validKey)
      : _validKey = (validKey != null) ? validKey : new _TypeTest<E>().test;

  bool remove(Object? element) {
    if (!_validKey(element)) return false;
    return super.remove(element);
  }

  bool contains(Object? element) {
    if (!_validKey(element)) return false;
    return super.contains(element);
  }

  E? lookup(Object? element) {
    if (!_validKey(element)) return null;
    return super.lookup(element);
  }

  bool containsAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (!_validKey(element) || !this.contains(element)) return false;
    }
    return true;
  }

  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (_validKey(element)) {
        super._remove(element, _hashCode(element));
      }
    }
  }

  bool _equals(Object? e1, Object? e2) => _equality(e1 as E, e2 as E);
  int _hashCode(Object? e) => _hasher(e as E);

  HashSet<E> _newSet() => new _CustomHashSet<E>(_equality, _hasher, _validKey);
  HashSet<R> _newSimilarSet<R>() => new _HashSet<R>();
}

class _HashSetEntry<E> {
  final E key;
  final int hashCode;
  _HashSetEntry<E>? next;
  _HashSetEntry(this.key, this.hashCode, this.next);

  _HashSetEntry<E>? remove() {
    final result = next;
    next = null;
    return result;
  }
}

class _HashSetIterator<E> implements Iterator<E> {
  final _HashSet<E> _set;
  final int _modificationCount;
  int _index = 0;
  _HashSetEntry<E>? _next;
  E? _current;

  _HashSetIterator(this._set) : _modificationCount = _set._modificationCount;

  bool moveNext() {
    if (_modificationCount != _set._modificationCount) {
      throw new ConcurrentModificationError(_set);
    }
    var localNext = _next;
    if (localNext != null) {
      _current = localNext.key;
      _next = localNext.next;
      return true;
    }
    final buckets = _set._buckets;
    while (_index < buckets.length) {
      localNext = buckets[_index];
      _index = _index + 1;
      if (localNext != null) {
        _current = localNext.key;
        _next = localNext.next;
        return true;
      }
    }
    _current = null;
    return false;
  }

  E get current => _current as E;
}
