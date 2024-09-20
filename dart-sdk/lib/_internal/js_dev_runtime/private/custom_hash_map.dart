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
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, _hashCode(key));
      if (buckets != null) {
        var equals = _equals;
        for (int i = 0, n = JS<int>('!', '#.length', buckets); i < n; i++) {
          K k = JS('', '#[#]', buckets, i);
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
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, _hashCode(key));
      if (buckets != null) {
        var equals = _equals;
        for (int i = 0, n = JS<int>('!', '#.length', buckets); i < n; i++) {
          K k = JS('', '#[#]', buckets, i);
          if (equals(k, key)) {
            V value = JS('', '#.get(#)', _map, k);
            // coerce undefined to null.
            return JS<bool>('!', '# === void 0', value) ? null : value;
          }
        }
      }
    }
    return null;
  }

  void operator []=(K key, V value) {
    var keyMap = _keyMap;
    int hash = JS('!', '# & 0x3fffffff', _hashCode(key));
    var buckets = JS('', '#.get(#)', keyMap, hash);
    if (buckets == null) {
      JS('', '#.set(#, [#])', keyMap, hash, key);
    } else {
      var equals = _equals;
      for (int i = 0, n = JS<int>('!', '#.length', buckets);;) {
        K k = JS('', '#[#]', buckets, i);
        if (equals(k, key)) {
          key = k;
          break;
        }
        if (++i >= n) {
          JS('', '#.push(#)', buckets, key);
          break;
        }
      }
    }
    JS('', '#.set(#, #)', _map, key, value);
    _modifications = (_modifications + 1) & 0x3fffffff;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    var keyMap = _keyMap;
    int hash = JS('!', '# & 0x3fffffff', _hashCode(key));
    var buckets = JS('', '#.get(#)', keyMap, hash);
    if (buckets == null) {
      JS('', '#.set(#, [#])', keyMap, hash, key);
    } else {
      var equals = _equals;
      for (int i = 0, n = JS<int>('!', '#.length', buckets); i < n; i++) {
        K k = JS('', '#[#]', buckets, i);
        if (equals(k, key)) return JS('', '#.get(#)', _map, k);
      }
      JS('', '#.push(#)', buckets, key);
    }
    V value = ifAbsent();
    if (value == null) JS('', '# = null', value); // coerce undefined to null.
    JS('', '#.set(#, #)', _map, key, value);
    _modifications = (_modifications + 1) & 0x3fffffff;
    return value;
  }

  V? remove(Object? key) {
    if (key is K) {
      int hash = JS('!', '# & 0x3fffffff', _hashCode(key));
      var keyMap = _keyMap;
      var buckets = JS('', '#.get(#)', keyMap, hash);
      if (buckets == null) return null; // not found
      var equals = _equals;
      for (int i = 0, n = JS<int>('!', '#.length', buckets); i < n; i++) {
        K k = JS('', '#[#]', buckets, i);
        if (equals(k, key)) {
          if (n == 1) {
            JS('', '#.delete(#)', keyMap, hash);
          } else {
            JS('', '#.splice(#, 1)', buckets, i);
          }
          var map = _map;
          V value = JS('', '#.get(#)', map, k);
          JS('', '#.delete(#)', map, k);
          _modifications = (_modifications + 1) & 0x3fffffff;
          // coerce undefined to null.
          return JS<bool>('!', '# === void 0', value) ? null : value;
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
