// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

base class CustomKeyHashMap<K, V> extends CustomHashMap<K, V> {
  final _Predicate<Object?> _validKey;
  CustomKeyHashMap(_Equality<K> equals, _Hasher<K> hashCode, this._validKey)
    : super(equals, hashCode);

  @override
  @notNull
  bool containsKey(Object? key) {
    if (!_validKey(key)) return false;
    return super.containsKey(key);
  }

  @override
  V? operator [](Object? key) {
    if (!_validKey(key)) return null;
    return super[key];
  }

  @override
  V? remove(Object? key) {
    if (!_validKey(key)) return null;
    return super.remove(key);
  }
}

base class CustomHashMap<K, V> extends InternalMap<K, V> {
  /// The backing store for this map.
  @notNull
  final _map = JS('', 'new Map()');

  /// Our map used to map keys onto the canonical key that is stored in [_map].
  @notNull
  final _keyMap = JS('', 'new Map()');

  // We track the number of modifications done to the key set of the
  // hash map to be able to throw when the map is modified while being
  // iterated over.
  //
  // Value cycles after 2^30 modifications so that modification counts are
  // always unboxed (Smi) values. Modification detection will be missed if you
  // make exactly some multiple of 2^30 modifications between advances of an
  // iterator.
  @notNull
  int _modifications = 0;

  final _Equality<K> _equals;
  final _Hasher<K> _hashCode;

  CustomHashMap(this._equals, this._hashCode);

  @notNull
  int get length => JS<int>('!', '#.size', _map);

  @notNull
  bool get isEmpty => JS<bool>('!', '#.size == 0', _map);

  @notNull
  bool get isNotEmpty => JS<bool>('!', '#.size != 0', _map);

  Iterable<K> get keys => _JSMapIterable<K>(this, true);
  Iterable<V> get values => _JSMapIterable<V>(this, false);

  @notNull
  bool containsKey(Object? key) {
    if (key is K) {
      var bucket = JS('', '#.get(# & 0x3fffffff)', _keyMap, _hashCode(key));
      if (bucket != null) {
        var equals = _equals;
        for (int i = 0, n = JS<int>('!', '#.length', bucket); i < n; i++) {
          K k = JS('', '#[#]', bucket, i);
          if (equals(k, key)) return true;
        }
      }
    }
    return false;
  }

  bool containsValue(Object? value) {
    for (var v in JS('', '#.values()', _map)) {
      if (value == v) return true;
    }
    return false;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  V? operator [](Object? key) {
    if (key is K) {
      var bucket = JS('', '#.get(# & 0x3fffffff)', _keyMap, _hashCode(key));
      var modifications = _modifications;
      if (bucket != null) {
        var equals = _equals;
        for (int i = 0, n = JS<int>('!', '#.length', bucket); i < n; i++) {
          K k = JS('', '#[#]', bucket, i);
          if (equals(k, key)) {
            if (modifications == _modifications) {
              V value = JS('', '#.get(#)', _map, k);
              // Coerce undefined to null.
              return JS<bool>('!', '# === void 0', value) ? null : value;
            }
            // Calling equals changed the map.
            throw ConcurrentModificationError(this);
          }
        }
      }
    }
    return null;
  }

  void operator []=(K key, V value) {
    int hash = JS('!', '# & 0x3fffffff', _hashCode(key));
    _set(key, hash, value);
  }

  /// Sets a value, just like `[]=`, after having computed hash code.
  ///
  /// Used by `[]=` and `putIfAbsent` if `ifAbsent` modifies the map.
  void _set(K key, int hash, V value) {
    concurrentModification:
    {
      var bucket = JS('', '#.get(#)', _keyMap, hash);
      if (bucket == null) {
        JS('', '#.set(#, [#])', _keyMap, hash, key);
      } else {
        var modifications = _modifications;
        var equals = _equals;
        for (int i = 0, n = JS<int>('!', '#.length', bucket); ;) {
          K k = JS('', '#[#]', bucket, i);
          if (equals(k, key)) {
            if (modifications != _modifications) break concurrentModification;
            key = k;
            break;
          }
          if (++i >= n) {
            // Check for modification before adding key to bucket.
            if (modifications != _modifications) break concurrentModification;
            JS('', '#.push(#)', bucket, key);
            break;
          }
        }
      }
      JS('', '#.set(#, #)', _map, key, value);
      _modifications = (_modifications + 1) & 0x3fffffff;
      return;
    }
    // Break to here in case of modification.
    throw ConcurrentModificationError(this);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    var keyMap = _keyMap;
    var modifications = _modifications;
    int hash = JS('!', '# & 0x3fffffff', _hashCode(key));
    var bucket = JS('', '#.get(#)', keyMap, hash);
    if (bucket != null) {
      var equals = _equals;
      for (int i = 0, n = JS<int>('!', '#.length', bucket); i < n; i++) {
        K k = JS('', '#[#]', bucket, i);
        if (equals(k, key)) {
          if (modifications == _modifications) {
            return JS('', '#.get(#)', _map, k);
          }
          // Calling `equals` changed the map.
          throw ConcurrentModificationError(this);
        }
      }
    }
    V value = ifAbsent();
    if (value == null) JS('', '# = null', value); // coerce undefined to null.
    if (_modifications == modifications) {
      if (bucket == null) {
        JS('', '#.set(#, [#])', keyMap, hash, key);
      } else {
        JS('', '#.push(#)', bucket, key);
      }
      JS('', '#.set(#, #)', _map, key, value);
      _modifications = (_modifications + 1) & 0x3fffffff;
    } else {
      // Start from scratch, an equal key might have been added.
      _set(key, hash, value);
    }
    return value;
  }

  V? remove(Object? key) {
    if (key is K) {
      int hash = JS('!', '# & 0x3fffffff', _hashCode(key));
      var modifications = _modifications;
      var keyMap = _keyMap;
      var bucket = JS('', '#.get(#)', keyMap, hash);
      if (bucket == null) return null; // not found
      var equals = _equals;
      for (int i = 0, n = JS<int>('!', '#.length', bucket); i < n; i++) {
        K k = JS('', '#[#]', bucket, i);
        if (equals(k, key)) {
          if (modifications == _modifications) {
            if (n == 1) {
              JS('', '#.delete(#)', keyMap, hash);
            } else {
              JS('', '#.splice(#, 1)', bucket, i);
            }
            var map = _map;
            V value = JS('', '#.get(#)', map, k);
            JS('', '#.delete(#)', map, k);
            _modifications = (_modifications + 1) & 0x3fffffff;
            // Coerce undefined to null.
            return JS<bool>('!', '# === void 0', value) ? null : value;
          }
          // Calling equals changed the bucket, can't trust position of `k`.
          throw ConcurrentModificationError(this);
        }
      }
    }
    return null;
  }

  void clear() {
    var map = _map;
    if (JS<int>('!', '#.size', map) > 0) {
      JS('', '#.clear()', map);
      JS('', '#.clear()', _keyMap);
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }
}

typedef _Equality<K> = bool Function(K a, K b);
typedef _Hasher<K> = int Function(K object);
typedef _Predicate<T> = bool Function(T value);
