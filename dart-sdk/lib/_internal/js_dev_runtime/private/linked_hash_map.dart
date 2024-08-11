// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Efficient JavaScript based implementation of a linked hash map used as a
// backing map for constant maps and the [LinkedHashMap] patch

part of dart._js_helper;

abstract base class InternalMap<K, V> extends MapBase<K, V>
    implements LinkedHashMap<K, V>, HashMap<K, V> {
  @notNull
  get _map;

  @notNull
  int get _modifications;

  void forEach(void action(K key, V value)) {
    int modifications = _modifications;
    for (var entry in JS('Iterable', '#.entries()', _map)) {
      action(JS('', '#[0]', entry), JS('', '#[1]', entry));
      if (modifications != _modifications) {
        throw ConcurrentModificationError(this);
      }
    }
  }
}

/// A linked hash map implementation based on ES6 Map.
///
/// Items that can use identity semantics are stored directly in the backing
/// map.
///
/// Items that have a custom equality/hashCode are first canonicalized by
/// looking up the canonical key by its hashCode.
base class LinkedMap<K, V> extends InternalMap<K, V> {
  /// The backing store for this map.
  ///
  /// Keys that use identity equality are stored directly. For other types of
  /// keys, we first look them up (by hashCode) in the [_keyMap] map, then
  /// we lookup the key in this map.
  @notNull
  final _map = JS('', 'new Map()');

  /// Items that use custom equality semantics.
  ///
  /// This maps from the item's hashCode to the canonical key, which is then
  /// used to lookup the item in [_map]. Keeping the data in our primary backing
  /// map gives us the ordering semantics required by [LinkedHashMap], while
  /// also providing convenient access to keys/values.
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

  LinkedMap();

  /// Called by generated code for a map literal.
  LinkedMap.from(JSArray entries) {
    var map = _map;
    var keyMap = _keyMap;
    for (int i = 0, n = JS('!', '#.length', entries); i < n; i += 2) {
      K key = JS('', '#[#]', entries, i);
      V value = JS('', '#[#]', entries, i + 1);
      if (key == null) {
        key = JS('', 'null');
      } else if (JS<bool>('!', '#[#] !== #', key,
          dart.extensionSymbol('_equals'), dart.identityEquals)) {
        key = putLinkedMapKey(key, keyMap);
      }
      JS('', '#.set(#, #)', map, key, value);
    }
  }

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
    if (key == null) {
      key = JS('', 'null');
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, key.hashCode);
      if (buckets != null) {
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          K k = JS('', '#[#]', buckets, i);
          if (k == key) return true;
        }
      }
      return false;
    }
    return JS<bool>('!', '#.has(#)', _map, key);
  }

  bool containsValue(Object? value) {
    for (var v in JS('', '#.values()', _map)) {
      if (v == value) return true;
    }
    return false;
  }

  void addAll(Map<K, V> other) {
    var map = _map;
    int length = JS('', '#.size', map);
    other.forEach((K key, V value) {
      if (key == null) {
        key = JS('', 'null');
      } else if (JS<bool>('!', '#[#] !== #', key,
          dart.extensionSymbol('_equals'), dart.identityEquals)) {
        key = putLinkedMapKey(key, _keyMap);
      }
      JS('', '#.set(#, #)', _map, key, value);
    });
    if (length != JS<int>('!', '#.size', map)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }

  V? operator [](Object? key) {
    if (key == null) {
      key = JS('', 'null');
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, key.hashCode);
      if (buckets != null) {
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          K k = JS('', '#[#]', buckets, i);
          if (k == key) return JS('', '#.get(#)', _map, k);
        }
      }
      return null;
    }
    V value = JS('', '#.get(#)', _map, key);
    // coerce undefined to null.
    return JS<bool>('!', '# === void 0', value) ? null : value;
  }

  void operator []=(K key, V value) {
    if (key == null) {
      key = JS('', 'null');
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      key = putLinkedMapKey(key, _keyMap);
    }
    var map = _map;
    int length = JS('', '#.size', map);
    JS('', '#.set(#, #)', map, key, value);
    if (length != JS<int>('!', '#.size', map)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    var map = _map;
    if (key == null) {
      key = JS('', 'null');
      if (JS<bool>('!', '#.has(null)', map)) return JS('', '#.get(null)', map);
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      @notNull
      K k = key;
      var hash = JS<int>('!', '# & 0x3fffffff', k.hashCode);
      var buckets = JS('', '#.get(#)', _keyMap, hash);
      if (buckets == null) {
        JS('', '#.set(#, [#])', _keyMap, hash, key);
      } else {
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          k = JS('', '#[#]', buckets, i);
          if (k == key) return JS('', '#.get(#)', map, k);
        }
        JS('', '#.push(#)', buckets, key);
      }
    } else if (JS<bool>('!', '#.has(#)', map, key)) {
      return JS('', '#.get(#)', map, key);
    }
    V value = ifAbsent();
    if (value == null) {
      value = JS('', 'null');
    }
    JS('', '#.set(#, #)', map, key, value);
    _modifications = (_modifications + 1) & 0x3fffffff;
    return value;
  }

  V? remove(Object? key) {
    if (key == null) {
      key = JS('', 'null');
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      @notNull
      var hash = JS<int>('!', '# & 0x3fffffff', key.hashCode);
      var buckets = JS('', '#.get(#)', _keyMap, hash);
      if (buckets == null) return null; // not found
      for (int i = 0, n = JS('!', '#.length', buckets);;) {
        K k = JS('', '#[#]', buckets, i);
        if (k == key) {
          key = k;
          if (n == 1) {
            JS('', '#.delete(#)', _keyMap, hash);
          } else {
            JS('', '#.splice(#, 1)', buckets, i);
          }
          break;
        }
        if (++i >= n) return null; // not found
      }
    }
    var map = _map;
    V value = JS('', '#.get(#)', map, key);
    if (JS<bool>('!', '#.delete(#)', map, key)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
    // coerce undefined to null.
    return JS<bool>('!', '# === void 0', value) ? null : value;
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

@NoReifyGeneric()
K putLinkedMapKey<K>(@notNull K key, keyMap) {
  var hash = JS<int>('!', '# & 0x3fffffff', key.hashCode);
  var buckets = JS('', '#.get(#)', keyMap, hash);
  if (buckets == null) {
    JS('', '#.set(#, [#])', keyMap, hash, key);
    return key;
  }
  for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
    @notNull
    K k = JS('', '#[#]', buckets, i);
    if (k == key) return k;
  }
  JS('', '#.push(#)', buckets, key);
  return key;
}

base class ImmutableMap<K, V> extends LinkedMap<K, V> {
  ImmutableMap.from(JSArray entries) : super.from(entries);

  void operator []=(K key, V value) {
    throw _unsupported();
  }

  void addAll(Object other) => throw _unsupported();
  void clear() => throw _unsupported();
  V? remove(Object? key) => throw _unsupported();
  V putIfAbsent(K key, V ifAbsent()) => throw _unsupported();

  static Error _unsupported() =>
      UnsupportedError("Cannot modify unmodifiable map");
}
