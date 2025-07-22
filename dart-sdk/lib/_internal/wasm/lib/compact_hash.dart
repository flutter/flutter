// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal"
    show
        EfficientLengthIterable,
        HideEfficientLengthIterable,
        IterableElementError,
        ClassID,
        TypeTest,
        unsafeCast;
import "dart:_list" show GrowableList;
import "dart:_object_helper";
import "dart:_wasm";

import "dart:collection";

import "dart:math" show max;

mixin _UnmodifiableMapMixin<K, V> implements LinkedHashMap<K, V> {
  /// This operation is not supported by an unmodifiable map.
  void operator []=(K key, V value) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  void addAll(Map<K, V> other) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  void clear() {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  V? remove(Object? key) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  void removeWhere(bool test(K key, V value)) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  V putIfAbsent(K key, V ifAbsent()) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  V update(K key, V update(V value), {V Function()? ifAbsent}) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }

  /// This operation is not supported by an unmodifiable map.
  void updateAll(V update(K key, V value)) {
    throw UnsupportedError("Cannot modify unmodifiable map");
  }
}

mixin _UnmodifiableSetMixin<E> implements LinkedHashSet<E> {
  static Never _throwUnmodifiable() {
    throw UnsupportedError("Cannot change an unmodifiable set");
  }

  /// This operation is not supported by an unmodifiable set.
  bool add(E value) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  void clear() => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  void addAll(Iterable<E> elements) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  void removeAll(Iterable<Object?> elements) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  void retainAll(Iterable<Object?> elements) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  void removeWhere(bool test(E element)) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  void retainWhere(bool test(E element)) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  bool remove(Object? value) => _throwUnmodifiable();
}

// Hash table with open addressing that separates the index from keys/values.

/// The object marking uninitialized [_HashBaseData._index] fields.
///
/// This is used to allow uninitialized `_index` fields without making the
/// field type nullable.
@pragma("wasm:entry-point")
final WasmArray<WasmI32> _uninitializedHashBaseIndex =
    const WasmArray<WasmI32>.literal([WasmI32(0)]);

/// The object marking uninitialized [_HashFieldBase._data] fields.
///
/// This is used to allow uninitialized `_data` fields without making the field
/// type nullable.
final WasmArray<Object?> _uninitializedHashBaseData =
    const WasmArray<Object?>.literal([]);

/// The object marking deleted data in [_HashFieldBase._data] and absent values
/// in `_getValueOrData` methods.
@pragma("wasm:initialize-at-startup")
final Object _deletedDataMarker = Object();

/// Base class for all (immutable and mutable) linked hash map and set
/// implementations.
///
/// Constant generator instantiates subclasses of this class directly, in
/// `ConstantCreator.visitMapConstant` and `ConstantCreater.visitSetConstant`.
/// Field indices of `_index` and `_data` are hard-coded in the compiler as
/// `FieldIndex.hashBaseIndex` and `FieldIndex.hashBaseData`.
abstract class _HashFieldBase {
  // Each occupied entry in _index is a fixed-size integer that encodes a pair:
  //   [ hash pattern for key | index of entry in _data ]
  // The hash pattern is based on hashCode, but is guaranteed to be non-zero.
  // The length of _index is always a power of two, and there is always at
  // least one unoccupied entry.
  //
  // Index of this field is used by the code generator:
  // `FieldInfo.hashBaseIndex`.
  WasmArray<WasmI32> _index = _uninitializedHashBaseIndex;

  // Cached in-place mask for the hash pattern component.
  int _hashMask = _HashBase._UNINITIALIZED_HASH_MASK;

  // Fixed-length list of keys (set) or key/value at even/odd indices (map).
  //
  // Can be either a mutable or immutable list.
  //
  // Index of this field is used by the code generator:
  // `FieldInfo.hashBaseData`.
  WasmArray<Object?> _data = _uninitializedHashBaseData;

  // Length of `_data` that is used (i.e., keys + values for a map).
  int _usedData = 0;

  // Number of deleted keys.
  int _deletedKeys = 0;

  _HashFieldBase();
}

// This mixin can be applied to _HashFieldBase, which provide the actual
// fields/accessors that this mixin assumes.
mixin _HashBase on _HashFieldBase {
  // The number of bits used for each component is determined by table size.
  // If initialized, the length of _index is (at least) twice the number of
  // entries in _data, and both are doubled when _data is full. Thus, _index
  // will have a max load factor of 1/2, which enables one more bit to be used
  // for the hash.
  // TODO(koda): Consider growing _data by factor sqrt(2), twice as often.
  static const int _INITIAL_INDEX_BITS = 2;
  static const int _INITIAL_INDEX_SIZE = 1 << (_INITIAL_INDEX_BITS + 1);
  static const int _UNINITIALIZED_INDEX_SIZE = 1;
  static const int _UNINITIALIZED_HASH_MASK = 0;

  // Unused and deleted entries are marked by 0 and 1, respectively.
  static const int _UNUSED_PAIR = 0;
  static const int _DELETED_PAIR = 1;

  static int _indexSizeToHashMask(int indexSize) {
    assert(
      indexSize >= _INITIAL_INDEX_SIZE ||
          indexSize == _UNINITIALIZED_INDEX_SIZE,
    );
    if (indexSize == _UNINITIALIZED_INDEX_SIZE) {
      return _UNINITIALIZED_HASH_MASK;
    }
    int indexBits = indexSize.bitLength - 2;
    return (1 << (30 - indexBits)) - 1;
  }

  static int _hashPattern(int fullHash, int hashMask, int size) {
    final int maskedHash = fullHash & hashMask;
    // TODO(koda): Consider keeping bit length and use left shift.
    return (maskedHash == 0) ? (size >> 1) : maskedHash * (size >> 1);
  }

  // Linear probing.
  static int _firstProbe(int fullHash, int sizeMask) {
    final int i = fullHash & sizeMask;
    // Light, fast shuffle to mitigate bad hashCode (e.g., sequential).
    return ((i << 1) + i) & sizeMask;
  }

  static int _nextProbe(int i, int sizeMask) => (i + 1) & sizeMask;

  static bool _isDeleted(Object? keyOrValue) =>
      identical(keyOrValue, _deletedDataMarker);

  static void _setDeletedAt(WasmArray<Object?> data, int d) {
    data[d] = _deletedDataMarker;
  }

  // Concurrent modification detection relies on this checksum monotonically
  // increasing between reallocations of `_data`.
  int get _checkSum => _usedData + _deletedKeys;
  bool _isModifiedSince(WasmArray<Object?> oldData, int oldCheckSum) =>
      !identical(_data, oldData) || (_checkSum != oldCheckSum);

  int get length;

  // If this collection has never had an insertion, and [other] is the same
  // representation and has had no deletions, then adding the entries of [other]
  // will end up building the same [_data] and [_index]. We can do this more
  // efficiently by copying the Lists directly.
  //
  // Precondition: [this] and [other] must use the same hashcode and equality.
  bool _quickCopy(_HashBase other) {
    if (!identical(_index, _uninitializedHashBaseIndex)) return false;
    if (other._usedData == 0) return true; // [other] is empty, nothing to copy.
    if (other._deletedKeys != 0) return false;

    assert(!identical(other._index, _uninitializedHashBaseIndex));
    assert(!identical(other._data, _uninitializedHashBaseData));
    _index = other._index.clone();
    _hashMask = other._hashMask;
    _data = other._data.clone();
    _usedData = other._usedData;
    _deletedKeys = other._deletedKeys;
    return true;
  }
}

abstract class _EqualsAndHashCode {
  int _hashCode(Object? e);
  bool _equals(Object? e1, Object? e2);
}

mixin _OperatorEqualsAndHashCode implements _EqualsAndHashCode {
  int _hashCode(Object? e) => e.hashCode;
  bool _equals(Object? e1, Object? e2) => e1 == e2;
}

mixin _IdenticalAndIdentityHashCode implements _EqualsAndHashCode {
  int _hashCode(Object? e) => identityHashCode(e);
  bool _equals(Object? e1, Object? e2) => identical(e1, e2);
}

mixin _CustomEqualsAndHashCode<K> implements _EqualsAndHashCode {
  int Function(K) get _hasher;
  bool Function(K, K) get _equality;

  // For backwards compatibility, we must allow any key here that is accepted
  // dynamically by the [_hasher] and [_equality] functions.
  int _hashCode(Object? e) => (_hasher as Function)(e);
  bool _equals(Object? e1, Object? e2) => (_equality as Function)(e1, e2);
}

@pragma("wasm:entry-point")
base class DefaultMap<K, V> extends _HashFieldBase
    with
        MapMixin<K, V>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashMapMixin<K, V>,
        _MapCreateIndexMixin<K, V>
    implements LinkedHashMap<K, V> {
  void addAll(Map<K, V> other) {
    if (other case final DefaultMap otherBase) {
      // If this map is empty we might be able to block-copy from [other].
      if (isEmpty && _quickCopy(otherBase)) return;
      // TODO(48143): Pre-grow capacity if it will reduce rehashing.
    }
    super.addAll(other);
  }

  @pragma("wasm:entry-point")
  static DefaultMap<K, V> fromWasmArray<K, V>(WasmArray<Object?> data) {
    final map = DefaultMap<K, V>();
    assert(map._index == _uninitializedHashBaseIndex);
    assert(map._hashMask == _HashBase._UNINITIALIZED_HASH_MASK);
    assert(map._data == _uninitializedHashBaseData);
    assert(map._usedData == 0);
    assert(map._deletedKeys == 0);

    map._data = data;
    map._usedData = data.length;
    map._createIndex(true);

    return map;
  }
}

// This is essentially the same class as DefaultMap, but it does
// not permit any modification of map entries from Dart code. We use
// this class for maps constructed from Dart constant maps.
@pragma("wasm:entry-point")
base class _ConstMap<K, V> extends _HashFieldBase
    with
        MapMixin<K, V>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashMapMixin<K, V>,
        _MapCreateIndexMixin<K, V>,
        _UnmodifiableMapMixin<K, V>,
        _ImmutableLinkedHashMapMixin<K, V>
    implements LinkedHashMap<K, V> {
  factory _ConstMap._uninstantiable() {
    throw UnsupportedError("_ConstMap can only be allocated by the compiler");
  }
}

mixin _MapCreateIndexMixin<K, V> on _LinkedHashMapMixin<K, V>, _HashFieldBase {
  void _createIndex(bool canContainDuplicates) {
    assert(_index == _uninitializedHashBaseIndex);
    assert(_hashMask == _HashBase._UNINITIALIZED_HASH_MASK);
    assert(_deletedKeys == 0);

    final size = _roundUpToPowerOfTwo(
      max(_data.length, _HashBase._INITIAL_INDEX_SIZE),
    );
    final newIndex = WasmArray<WasmI32>.filled(size, const WasmI32(0));
    final hashMask = _hashMask = _HashBase._indexSizeToHashMask(size);

    for (int j = 0; j < _usedData; j += 2) {
      final key = _data[j] as K;

      final fullHash = _hashCode(key);
      final hashPattern = _HashBase._hashPattern(fullHash, hashMask, size);
      final d = _findValueOrInsertPoint(
        key,
        fullHash,
        hashPattern,
        size,
        newIndex,
      );

      if (d > 0 && canContainDuplicates) {
        // Replace the existing entry.
        _data[d] = _data[j + 1];

        // Mark this as a free slot.
        _HashBase._setDeletedAt(_data, j);
        _HashBase._setDeletedAt(_data, j + 1);
        _deletedKeys++;
        continue;
      }

      // We just allocated the index, so we should not find this key in it yet.
      assert(d <= 0);

      final i = -d;

      assert(1 <= hashPattern && hashPattern < (1 << 32));
      final index = j >> 1;
      assert((index & hashPattern) == 0);
      newIndex[i] = WasmI32.fromInt(hashPattern | index);
    }

    // Publish new index, uses store release semantics.
    _index = newIndex;
  }
}

mixin _ImmutableLinkedHashMapMixin<K, V> on _MapCreateIndexMixin<K, V> {
  bool containsKey(Object? key) {
    if (identical(_index, _uninitializedHashBaseIndex)) {
      _createIndex(false);
    }
    return super.containsKey(key);
  }

  V? operator [](Object? key) {
    if (identical(_index, _uninitializedHashBaseIndex)) {
      _createIndex(false);
    }
    return super[key];
  }

  Iterable<K> get keys =>
      _CompactIterableImmutable<K>(this, _data, _usedData, -2, 2);
  Iterable<V> get values =>
      _CompactIterableImmutable<V>(this, _data, _usedData, -1, 2);
}

// Implementation is from "Hacker's Delight" by Henry S. Warren, Jr.,
// figure 3-3, page 48, where the function is called clp2.
int _roundUpToPowerOfTwo(int x) {
  x = x - 1;
  x = x | (x >> 1);
  x = x | (x >> 2);
  x = x | (x >> 4);
  x = x | (x >> 8);
  x = x | (x >> 16);
  x = x | (x >> 32);
  return x + 1;
}

mixin _LinkedHashMapMixin<K, V> on _HashBase, _EqualsAndHashCode {
  int get length => (_usedData >> 1) - _deletedKeys;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;

  void _rehash() {
    if ((_deletedKeys << 2) > _usedData) {
      // TODO(koda): Consider shrinking.
      // TODO(koda): Consider in-place compaction and more costly CME check.
      _init(_index.length, _hashMask, _data, _usedData);
    } else {
      // TODO(koda): Support 32->64 bit transition (and adjust _hashMask).
      _init(_index.length << 1, _hashMask >> 1, _data, _usedData);
    }
  }

  void clear() {
    if (!isEmpty) {
      _index = _uninitializedHashBaseIndex;
      _hashMask = _HashBase._UNINITIALIZED_HASH_MASK;
      _data = _uninitializedHashBaseData;
      _usedData = 0;
      _deletedKeys = 0;
    }
  }

  // Allocate _index and _data, and optionally copy existing contents.
  void _init(int size, int hashMask, WasmArray<Object?>? oldData, int oldUsed) {
    if (size < _HashBase._INITIAL_INDEX_SIZE) {
      size = _HashBase._INITIAL_INDEX_SIZE;
      hashMask = _HashBase._indexSizeToHashMask(size);
    }
    assert(size & (size - 1) == 0);
    assert(_HashBase._UNUSED_PAIR == 0);
    _index = WasmArray<WasmI32>.filled(size, const WasmI32(0));
    _hashMask = hashMask;
    _data = WasmArray<Object?>.filled(size, null);
    _usedData = 0;
    _deletedKeys = 0;
    if (oldData != null) {
      for (int i = 0; i < oldUsed; i += 2) {
        final keyObject = oldData[i];
        if (!_HashBase._isDeleted(keyObject)) {
          // TODO(koda): While there are enough hash bits, avoid hashCode calls.
          final key = unsafeCast<K>(keyObject);
          final value = unsafeCast<V>(oldData[i + 1]);
          _set(key, value, _hashCode(key));
        }
      }
    }
  }

  /// Populate this hash table from the given list of key-value pairs.
  ///
  /// This function is unsafe: it does not perform any type checking on
  /// keys and values assuming that caller has ensured that types are
  /// correct.
  void _populateUnsafeOnlyStringKeys(WasmArray<Object?> data, int usedData) {
    assert(usedData.isEven);
    int size = data.length;
    if (size == 0) {
      // Initial state setup by constructor.
      assert(_index == _uninitializedHashBaseIndex);
      assert(_hashMask == _HashBase._UNINITIALIZED_HASH_MASK);
      assert(_data == _uninitializedHashBaseData);
      assert(_usedData == 0);
      assert(_deletedKeys == 0);
      return;
    }
    assert(size >= _HashBase._INITIAL_INDEX_SIZE);
    assert(size == _roundUpToPowerOfTwo(size));
    final hashMask = _HashBase._indexSizeToHashMask(size);

    assert(size & (size - 1) == 0);
    assert(_HashBase._UNUSED_PAIR == 0);
    _index = WasmArray<WasmI32>.filled(size, const WasmI32(0));
    _hashMask = hashMask;
    _data = data;
    _usedData = 0;
    _deletedKeys = 0;

    for (int i = 0; i < usedData; i += 2) {
      final key = unsafeCast<K>(data[i]);
      final value = unsafeCast<V>(data[i + 1]);

      // Strings store their hash code in the object header's identity hash code
      // field. So before doing a indirect call to obtain the hash code, we can
      // check if it was already computed and if so just use it.
      final int idHash = getIdentityHashField(unsafeCast<Object>(key));
      if (idHash != 0) {
        assert(idHash == key.hashCode);
        _set(key, value, idHash);
      } else {
        _set(key, value, key.hashCode);
      }
    }
  }

  void _insert(K key, V value, int fullHash, int hashPattern, int i) {
    if (_usedData == _data.length) {
      _rehash();
      _set(key, value, fullHash);
    } else {
      assert(1 <= hashPattern && hashPattern < (1 << 32));
      final int index = _usedData >> 1;
      assert((index & hashPattern) == 0);
      _index[i] = WasmI32.fromInt(hashPattern | index);
      _data[_usedData++] = key;
      _data[_usedData++] = value;
    }
  }

  // If key is present, returns the index of the value in _data, else returns
  // the negated insertion point in index.
  int _findValueOrInsertPoint(
    K key,
    int fullHash,
    int hashPattern,
    int size,
    WasmArray<WasmI32> index,
  ) {
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int firstDeleted = -1;
    int pair = index.readUnsigned(i);
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair == _HashBase._DELETED_PAIR) {
        if (firstDeleted < 0) {
          firstDeleted = i;
        }
      } else {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (_equals(key, _data[d])) {
            return d + 1;
          }
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = index.readUnsigned(i);
    }
    return firstDeleted >= 0 ? -firstDeleted : -i;
  }

  void operator []=(K key, V value) {
    final int fullHash = _hashCode(key);
    _set(key, value, fullHash);
  }

  void _set(K key, V value, int fullHash) {
    final int size = _index.length;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    final int d = _findValueOrInsertPoint(
      key,
      fullHash,
      hashPattern,
      size,
      _index,
    );
    if (d > 0) {
      _data[d] = value;
    } else {
      final int i = -d;
      _insert(key, value, fullHash, hashPattern, i);
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    final int size = _index.length;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    final int d = _findValueOrInsertPoint(
      key,
      fullHash,
      hashPattern,
      size,
      _index,
    );
    if (d > 0) {
      return _data[d] as V;
    }
    // 'ifAbsent' is allowed to modify the map.
    WasmArray<Object?> oldData = _data;
    int oldCheckSum = _checkSum;
    V value = ifAbsent();
    if (_isModifiedSince(oldData, oldCheckSum)) {
      this[key] = value;
    } else {
      final int i = -d;
      _insert(key, value, fullHash, hashPattern, i);
    }
    return value;
  }

  V? remove(Object? key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index.readUnsigned(i);
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (_equals(key, _data[d])) {
            _index[i] = WasmI32.fromInt(_HashBase._DELETED_PAIR);
            _HashBase._setDeletedAt(_data, d);
            V value = _data[d + 1] as V;
            _HashBase._setDeletedAt(_data, d + 1);
            ++_deletedKeys;
            return value;
          }
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index.readUnsigned(i);
    }
    return null;
  }

  // If key is absent, returns [_deletedDataMarker].
  Object? _getValueOrData(Object? key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index.readUnsigned(i);
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (_equals(key, _data[d])) {
            return _data[d + 1];
          }
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index.readUnsigned(i);
    }
    return _deletedDataMarker;
  }

  bool containsKey(Object? key) =>
      !identical(_deletedDataMarker, _getValueOrData(key));

  V? operator [](Object? key) {
    var v = _getValueOrData(key);
    return identical(_deletedDataMarker, v) ? null : unsafeCast<V>(v);
  }

  bool containsValue(Object? value) {
    for (var v in values) {
      // Spec. says this should always use "==", also for identity maps, etc.
      if (v == value) {
        return true;
      }
    }
    return false;
  }

  void forEach(void action(K key, V value)) {
    final data = _data;
    final checkSum = _checkSum;
    final len = _usedData;
    for (int offset = 0; offset < len; offset += 2) {
      final current = data[offset];
      if (_HashBase._isDeleted(current)) continue;
      final key = unsafeCast<K>(current);
      final value = unsafeCast<V>(data[offset + 1]);
      action(key, value);
      if (_isModifiedSince(data, checkSum)) {
        throw ConcurrentModificationError(this);
      }
    }
  }

  Iterable<K> get keys => _CompactKeysIterable<K>(this);
  Iterable<V> get values => _CompactValuesIterable<V>(this);
  Iterable<MapEntry<K, V>> get entries => _CompactEntriesIterable<K, V>(this);
}

base class CompactLinkedIdentityHashMap<K, V> extends _HashFieldBase
    with
        MapMixin<K, V>,
        _HashBase,
        _IdenticalAndIdentityHashCode,
        _LinkedHashMapMixin<K, V>
    implements LinkedHashMap<K, V> {
  void addAll(Map<K, V> other) {
    if (other case final CompactLinkedIdentityHashMap otherBase) {
      // If this map is empty we might be able to block-copy from [other].
      if (isEmpty && _quickCopy(otherBase)) return;
      // TODO(48143): Pre-grow capacity if it will reduce rehashing.
    }
    super.addAll(other);
  }
}

base class CompactLinkedCustomHashMap<K, V> extends _HashFieldBase
    with
        MapMixin<K, V>,
        _HashBase,
        _CustomEqualsAndHashCode<K>,
        _LinkedHashMapMixin<K, V>
    implements LinkedHashMap<K, V> {
  final bool Function(K, K) _equality;
  final int Function(K) _hasher;
  final bool Function(Object?) _validKey;

  bool containsKey(Object? o) => _validKey(o) ? super.containsKey(o) : false;
  V? operator [](Object? o) => _validKey(o) ? super[o] : null;
  V? remove(Object? o) => _validKey(o) ? super.remove(o) : null;

  CompactLinkedCustomHashMap(
    this._equality,
    this._hasher,
    bool Function(Object?)? validKey,
  ) : _validKey = validKey ?? TypeTest<K>().test;
}

class _CompactKeysIterable<E> extends Iterable<E>
    implements EfficientLengthIterable<E>, HideEfficientLengthIterable<E> {
  final _LinkedHashMapMixin _table;

  _CompactKeysIterable(this._table);

  Iterator<E> get iterator =>
      _CompactIterator<E>(_table, _table._data, _table._usedData, -2, 2);

  int get length => _table.length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;

  bool contains(Object? element) => _table.containsKey(element);
}

class _CompactValuesIterable<E> extends Iterable<E>
    implements EfficientLengthIterable<E>, HideEfficientLengthIterable<E> {
  final _HashBase _table;

  _CompactValuesIterable(this._table);

  Iterator<E> get iterator =>
      _CompactIterator<E>(_table, _table._data, _table._usedData, -1, 2);

  int get length => _table.length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
}

// Iterates through _data[_offset + _step], _data[_offset + 2*_step], ...
// and checks for concurrent modification.
class _CompactIterator<E> implements Iterator<E> {
  final _HashBase _table;

  final WasmArray<Object?> _data;
  final int _len;
  int _offset;
  final int _step;
  final int _checkSum;
  E? _current;

  _CompactIterator(this._table, this._data, this._len, this._offset, this._step)
    : _checkSum = _table._checkSum;

  bool moveNext() {
    if (_table._isModifiedSince(_data, _checkSum)) {
      throw ConcurrentModificationError(_table);
    }
    do {
      _offset += _step;
    } while (_offset < _len && _HashBase._isDeleted(_data[_offset]));
    if (_offset < _len) {
      _current = unsafeCast<E>(_data[_offset]);
      return true;
    } else {
      _current = null;
      return false;
    }
  }

  E get current => _current as E;
}

// Iterates through map creating a MapEntry for each key-value pair, and checks
// for concurrent modification.
class _CompactEntriesIterable<K, V> extends Iterable<MapEntry<K, V>>
    implements
        EfficientLengthIterable<MapEntry<K, V>>,
        HideEfficientLengthIterable<MapEntry<K, V>> {
  final _HashBase _table;

  _CompactEntriesIterable(this._table);

  Iterator<MapEntry<K, V>> get iterator =>
      _CompactEntriesIterator<K, V>(_table, _table._data, _table._usedData);

  int get length => _table.length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
}

class _CompactEntriesIterator<K, V> implements Iterator<MapEntry<K, V>> {
  final _HashBase _table;

  final WasmArray<Object?> _data;
  final int _len;
  int _offset = -2;
  final int _checkSum;
  MapEntry<K, V>? _current;

  _CompactEntriesIterator(this._table, this._data, this._len)
    : _checkSum = _table._checkSum;

  bool moveNext() {
    if (_table._isModifiedSince(_data, _checkSum)) {
      throw ConcurrentModificationError(_table);
    }
    do {
      _offset += 2;
    } while (_offset < _len && _HashBase._isDeleted(_data[_offset]));
    if (_offset < _len) {
      final key = unsafeCast<K>(_data[_offset]);
      final value = unsafeCast<V>(_data[_offset + 1]);
      _current = MapEntry<K, V>(key, value);
      return true;
    } else {
      _current = null;
      return false;
    }
  }

  MapEntry<K, V> get current => _current!;
}

// Iterates through _data[_offset + _step], _data[_offset + 2*_step], ...
//
// Does not check for concurrent modification since the table
// is known to be immutable.
class _CompactIterableImmutable<E> extends Iterable<E> {
  final _HashBase _table;

  final WasmArray<Object?> _data;
  final int _len;
  final int _offset;
  final int _step;

  _CompactIterableImmutable(
    this._table,
    this._data,
    this._len,
    this._offset,
    this._step,
  );

  Iterator<E> get iterator =>
      _CompactIteratorImmutable<E>(_table, _data, _len, _offset, _step);

  int get length => _table.length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
}

class _CompactIteratorImmutable<E> implements Iterator<E> {
  final _HashBase _table;

  final WasmArray<Object?> _data;
  final int _len;
  int _offset;
  final int _step;
  E? _current;

  _CompactIteratorImmutable(
    this._table,
    this._data,
    this._len,
    this._offset,
    this._step,
  );

  bool moveNext() {
    _offset += _step;
    if (_offset < _len) {
      _current = unsafeCast<E>(_data[_offset]);
      return true;
    } else {
      _current = null;
      return false;
    }
  }

  E get current => _current as E;
}

mixin _LinkedHashSetMixin<E> on _HashBase, _EqualsAndHashCode {
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
  int get length => _usedData - _deletedKeys;

  E get first {
    for (int offset = 0; offset < _usedData; offset++) {
      Object? current = _data[offset];
      if (!_HashBase._isDeleted(current)) {
        return current as E;
      }
    }
    throw IterableElementError.noElement();
  }

  E get last {
    for (int offset = _usedData - 1; offset >= 0; offset--) {
      Object? current = _data[offset];
      if (!_HashBase._isDeleted(current)) {
        return current as E;
      }
    }
    throw IterableElementError.noElement();
  }

  void _rehash() {
    if ((_deletedKeys << 1) > _usedData) {
      _init(_index.length, _hashMask, _data, _usedData);
    } else {
      _init(_index.length << 1, _hashMask >> 1, _data, _usedData);
    }
  }

  void clear() {
    if (!isEmpty) {
      _index = _uninitializedHashBaseIndex;
      _hashMask = _HashBase._UNINITIALIZED_HASH_MASK;
      _data = _uninitializedHashBaseData;
      _usedData = 0;
      _deletedKeys = 0;
    }
  }

  void _init(int size, int hashMask, WasmArray<Object?>? oldData, int oldUsed) {
    if (size < _HashBase._INITIAL_INDEX_SIZE) {
      size = _HashBase._INITIAL_INDEX_SIZE;
      hashMask = _HashBase._indexSizeToHashMask(size);
    }
    _index = WasmArray<WasmI32>.filled(size, const WasmI32(0));
    _hashMask = hashMask;
    _data = WasmArray<Object?>.filled(size >> 1, null);
    _usedData = 0;
    _deletedKeys = 0;
    if (oldData != null) {
      for (int i = 0; i < oldUsed; i += 1) {
        var key = oldData[i];
        if (!_HashBase._isDeleted(key)) {
          add(unsafeCast<E>(key));
        }
      }
    }
  }

  bool add(E key) {
    final int fullHash = _hashCode(key);
    return _add(key, fullHash);
  }

  bool _add(E key, int fullHash) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int firstDeleted = -1;
    int pair = _index.readUnsigned(i);
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair == _HashBase._DELETED_PAIR) {
        if (firstDeleted < 0) {
          firstDeleted = i;
        }
      } else {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && _equals(key, _data[d])) {
          return false;
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index.readUnsigned(i);
    }
    if (_usedData == _data.length) {
      _rehash();
      _add(key, fullHash);
    } else {
      final int insertionPoint = (firstDeleted >= 0) ? firstDeleted : i;
      assert(1 <= hashPattern && hashPattern < (1 << 32));
      assert((hashPattern & _usedData) == 0);
      _index[insertionPoint] = WasmI32.fromInt(hashPattern | _usedData);
      _data[_usedData++] = key;
    }
    return true;
  }

  // If key is absent, returns [_deletedDataMarker].
  Object? _getKeyOrData(Object? key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index.readUnsigned(i);
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && _equals(key, _data[d])) {
          return _data[d]; // Note: Must return the existing key.
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index.readUnsigned(i);
    }
    return _deletedDataMarker;
  }

  E? lookup(Object? key) {
    var k = _getKeyOrData(key);
    return identical(_deletedDataMarker, k) ? null : unsafeCast<E>(k);
  }

  bool contains(Object? key) =>
      !identical(_deletedDataMarker, _getKeyOrData(key));

  bool remove(Object? key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index.readUnsigned(i);
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && _equals(key, _data[d])) {
          _index[i] = WasmI32.fromInt(_HashBase._DELETED_PAIR);
          _HashBase._setDeletedAt(_data, d);
          ++_deletedKeys;
          return true;
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index.readUnsigned(i);
    }

    return false;
  }

  Iterator<E> get iterator =>
      _CompactIterator<E>(this, _data, _usedData, -1, 1);
}

// Set implementation, analogous to _Map. Set literals create instances
// of this class.
@pragma("wasm:entry-point")
base class DefaultSet<E> extends _HashFieldBase
    with
        SetMixin<E>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashSetMixin<E>,
        _SetCreateIndexMixin<E>
    implements LinkedHashSet<E> {
  void addAll(Iterable<E> other) {
    if (other case final DefaultSet otherBase) {
      // If this set is empty we might be able to block-copy from [other].
      if (isEmpty && _quickCopy(otherBase)) return;
      // TODO(48143): Pre-grow capacity if it will reduce rehashing.
    }
    super.addAll(other);
  }

  @pragma("wasm:entry-point")
  static DefaultSet<E> fromWasmArray<E>(WasmArray<Object?> data) {
    final set = DefaultSet<E>();
    assert(set._index == _uninitializedHashBaseIndex);
    assert(set._hashMask == _HashBase._UNINITIALIZED_HASH_MASK);
    assert(set._data == _uninitializedHashBaseData);
    assert(set._usedData == 0);
    assert(set._deletedKeys == 0);

    set._data = data;
    set._usedData = data.length;
    set._createIndex(true);

    return set;
  }

  bool add(E key);

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newEmpty);

  static Set<R> _newEmpty<R>() => DefaultSet<R>();

  Set<E> toSet() => DefaultSet<E>()..addAll(this);
}

@pragma("wasm:entry-point")
base class _ConstSet<E> extends _HashFieldBase
    with
        SetMixin<E>,
        _HashBase,
        _OperatorEqualsAndHashCode,
        _LinkedHashSetMixin<E>,
        _UnmodifiableSetMixin<E>,
        _SetCreateIndexMixin<E>,
        _ImmutableLinkedHashSetMixin<E>
    implements LinkedHashSet<E> {
  factory _ConstSet._uninstantiable() {
    throw UnsupportedError("_ConstSet can only be allocated by the compiler");
  }

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newEmpty);

  static Set<R> _newEmpty<R>() => DefaultSet<R>();

  // Returns a mutable set.
  Set<E> toSet() => DefaultSet<E>()..addAll(this);
}

mixin _SetCreateIndexMixin<E>
    on Set<E>, _LinkedHashSetMixin<E>, _HashFieldBase {
  void _createIndex(bool canContainDuplicates) {
    assert(_index == _uninitializedHashBaseIndex);
    assert(_hashMask == _HashBase._UNINITIALIZED_HASH_MASK);
    assert(_deletedKeys == 0);

    final size = _roundUpToPowerOfTwo(
      max(_data.length * 2, _HashBase._INITIAL_INDEX_SIZE),
    );
    final index = WasmArray<WasmI32>.filled(size, const WasmI32(0));
    final hashMask = _hashMask = _HashBase._indexSizeToHashMask(size);

    final sizeMask = size - 1;
    final maxEntries = size >> 1;

    for (int j = 0; j < _usedData; j++) {
      next:
      {
        final key = _data[j];

        final fullHash = _hashCode(key);
        final hashPattern = _HashBase._hashPattern(fullHash, hashMask, size);

        int i = _HashBase._firstProbe(fullHash, sizeMask);
        int pair = index.readUnsigned(i);
        while (pair != _HashBase._UNUSED_PAIR) {
          assert(pair != _HashBase._DELETED_PAIR);

          final int d = hashPattern ^ pair;
          if (d < maxEntries) {
            // We should not already find an entry in the index.
            if (canContainDuplicates && _equals(key, _data[d])) {
              // Exists already, skip this entry.
              _HashBase._setDeletedAt(_data, j);
              _deletedKeys++;
              break next;
            } else {
              assert(!_equals(key, _data[d]));
            }
          }

          i = _HashBase._nextProbe(i, sizeMask);
          pair = index.readUnsigned(i);
        }

        final int insertionPoint = i;
        assert(1 <= hashPattern && hashPattern < (1 << 32));
        assert((hashPattern & j) == 0);
        index[insertionPoint] = WasmI32.fromInt(hashPattern | j);
      }
    }

    // Publish new index, uses store release semantics.
    _index = index;
  }
}

mixin _ImmutableLinkedHashSetMixin<E> on _SetCreateIndexMixin<E> {
  E? lookup(Object? key) {
    if (identical(_index, _uninitializedHashBaseIndex)) {
      _createIndex(false);
    }
    return super.lookup(key);
  }

  bool contains(Object? key) {
    if (identical(_index, _uninitializedHashBaseIndex)) {
      _createIndex(false);
    }
    return super.contains(key);
  }

  Iterator<E> get iterator =>
      _CompactIteratorImmutable<E>(this, _data, _usedData, -1, 1);
}

base class CompactLinkedIdentityHashSet<E> extends _HashFieldBase
    with
        SetMixin<E>,
        _HashBase,
        _IdenticalAndIdentityHashCode,
        _LinkedHashSetMixin<E>
    implements LinkedHashSet<E> {
  Set<E> toSet() => CompactLinkedIdentityHashSet<E>()..addAll(this);

  static Set<R> _newEmpty<R>() => CompactLinkedIdentityHashSet<R>();

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newEmpty);

  void addAll(Iterable<E> other) {
    if (other is CompactLinkedIdentityHashSet<E>) {
      // If this set is empty we might be able to block-copy from [other].
      if (isEmpty && _quickCopy(other)) return;
      // TODO(48143): Pre-grow capacity if it will reduce rehashing.
    }
    super.addAll(other);
  }
}

base class CompactLinkedCustomHashSet<E> extends _HashFieldBase
    with
        SetMixin<E>,
        _HashBase,
        _CustomEqualsAndHashCode<E>,
        _LinkedHashSetMixin<E>
    implements LinkedHashSet<E> {
  final bool Function(E, E) _equality;
  final int Function(E) _hasher;
  final bool Function(Object?) _validKey;

  bool contains(Object? o) => _validKey(o) ? super.contains(o) : false;
  E? lookup(Object? o) => _validKey(o) ? super.lookup(o) : null;
  bool remove(Object? o) => _validKey(o) ? super.remove(o) : false;

  CompactLinkedCustomHashSet(
    this._equality,
    this._hasher,
    bool Function(Object?)? validKey,
  ) : _validKey = validKey ?? TypeTest<E>().test;

  Set<R> cast<R>() => Set.castFrom<E, R>(this);
  Set<E> toSet() =>
      CompactLinkedCustomHashSet<E>(_equality, _hasher, _validKey)
        ..addAll(this);
}

@pragma('wasm:prefer-inline')
Map<K, V> createMapFromStringKeyValueListUnsafe<K, V>(
  WasmArray<Object?> keyValuePairData,
  int usedData,
) =>
    DefaultMap<K, V>()
      .._populateUnsafeOnlyStringKeys(keyValuePairData, usedData);
