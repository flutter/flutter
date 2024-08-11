// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:collection classes.
import 'dart:_foreign_helper' show JS, JSExportName;
import 'dart:_runtime' as dart;
import 'dart:_internal' show patch;
import 'dart:_interceptors' show JSArray;
import 'dart:_js_helper'
    show
        LinkedMap,
        IdentityMap,
        CustomHashMap,
        CustomKeyHashMap,
        DartIterator,
        notNull,
        putLinkedMapKey;

@patch
class HashMap<K, V> {
  @patch
  factory HashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(K, String) || identical(K, int)) {
            return IdentityMap<K, V>();
          }
          return LinkedMap<K, V>();
        }
        hashCode = dart.hashCode;
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return IdentityMap<K, V>();
      }
      return CustomHashMap<K, V>(equals ?? dart.equals, hashCode);
    }
    return CustomKeyHashMap<K, V>(
        equals ?? dart.equals, hashCode ?? dart.hashCode, isValidKey);
  }

  @patch
  factory HashMap.identity() = IdentityMap<K, V>;
}

@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(K, String) || identical(K, int)) {
            return IdentityMap<K, V>();
          }
          return LinkedMap<K, V>();
        }
        hashCode = dart.hashCode;
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return IdentityMap<K, V>();
      }
      return CustomHashMap<K, V>(equals ?? dart.equals, hashCode);
    }
    return CustomKeyHashMap<K, V>(
        equals ?? dart.equals, hashCode ?? dart.hashCode, isValidKey);
  }

  @patch
  factory LinkedHashMap.identity() = IdentityMap<K, V>;
}

@patch
class HashSet<E> {
  @patch
  factory HashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(E, String) || identical(E, int)) {
            return _IdentityHashSet<E>();
          }
          return _HashSet<E>();
        }
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return _IdentityHashSet<E>();
      }
      return _CustomHashSet<E>(
          equals ?? dart.equals, hashCode ?? dart.hashCode);
    }
    return _CustomKeyHashSet<E>(
        equals ?? dart.equals, hashCode ?? dart.hashCode, isValidKey);
  }

  @patch
  factory HashSet.identity() = _IdentityHashSet<E>;
}

@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          if (identical(E, String) || identical(E, int)) {
            return _IdentityHashSet<E>();
          }
          return _HashSet<E>();
        }
        hashCode = dart.hashCode;
      } else if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return _IdentityHashSet<E>();
      }
      return _CustomHashSet<E>(equals ?? dart.equals, hashCode);
    }
    return _CustomKeyHashSet<E>(
        equals ?? dart.equals, hashCode ?? dart.hashCode, isValidKey);
  }

  @patch
  factory LinkedHashSet.identity() = _IdentityHashSet<E>;
}

base class _HashSet<E> extends _InternalSet<E>
    implements HashSet<E>, LinkedHashSet<E> {
  /// The backing store for this set.
  ///
  /// Keys that use identity equality are stored directly. For other types of
  /// keys, we first look them up (by hashCode) in the [_keyMap] map, then
  /// we lookup the key in this map.
  @notNull
  final _map = JS('', 'new Set()');

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

  _HashSet();

  Set<E> _newSet() => _HashSet<E>();

  Set<R> _newSimilarSet<R>() => _HashSet<R>();

  bool contains(Object? key) {
    if (key == null) {
      // Convert undefined to null, if needed.
      key = null;
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      @notNull
      Object? k = key;
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, k.hashCode);
      if (buckets != null) {
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          k = JS('', '#[#]', buckets, i);
          if (k == key) return true;
        }
      }
      return false;
    }
    return JS<bool>('!', '#.has(#)', _map, key);
  }

  E? lookup(Object? key) {
    if (key == null) return null;
    if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      @notNull
      Object? k = key;
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, k.hashCode);
      if (buckets != null) {
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          k = JS('', '#[#]', buckets, i);
          if (k == key) return JS('', '#', k);
        }
      }
      return null;
    }
    return JS('', '#.has(#) ? # : null', _map, key, key);
  }

  bool add(E key) {
    var map = _map;
    if (key == null) {
      if (JS<bool>('!', '#.has(null)', map)) return false;
      // Convert undefined to null, if needed.
      JS('', '# = null', key);
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      var keyMap = _keyMap;
      @notNull
      var k = key;
      int hash = JS('!', '# & 0x3fffffff', k.hashCode);
      var buckets = JS('', '#.get(#)', keyMap, hash);
      if (buckets == null) {
        JS('', '#.set(#, [#])', keyMap, hash, key);
      } else {
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          k = JS('', '#[#]', buckets, i);
          if (k == key) return false;
        }
        JS('', '#.push(#)', buckets, key);
      }
    } else if (JS<bool>('!', '#.has(#)', map, key)) {
      return false;
    }
    JS('', '#.add(#)', map, key);
    _modifications = (_modifications + 1) & 0x3fffffff;
    return true;
  }

  void addAll(Iterable<E> objects) {
    var map = _map;
    int length = JS('', '#.size', map);
    for (E key in objects) {
      if (key == null) {
        // Convert undefined to null, if needed.
        JS('', '# = null', key);
      } else if (JS<bool>('!', '#[#] !== #', key,
          dart.extensionSymbol('_equals'), dart.identityEquals)) {
        key = putLinkedMapKey(key, _keyMap);
      }
      JS('', '#.add(#)', map, key);
    }
    if (length != JS<int>('!', '#.size', map)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }

  bool remove(Object? key) {
    if (key == null) {
      // Convert undefined to null, if needed.
      key = null;
    } else if (JS<bool>('!', '#[#] !== #', key, dart.extensionSymbol('_equals'),
        dart.identityEquals)) {
      @notNull
      Object? k = key;
      int hash = JS('!', '# & 0x3fffffff', k.hashCode);
      var buckets = JS('', '#.get(#)', _keyMap, hash);
      if (buckets == null) return false; // not found
      for (int i = 0, n = JS('!', '#.length', buckets);;) {
        k = JS('', '#[#]', buckets, i);
        if (k == key) {
          key = k;
          if (n == 1) {
            JS('', '#.delete(#)', _keyMap, hash);
          } else {
            JS('', '#.splice(#, 1)', buckets, i);
          }
          break;
        }
        if (++i >= n) return false; // not found
      }
    }
    var map = _map;
    if (JS<bool>('!', '#.delete(#)', map, key)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
      return true;
    }
    return false;
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

// Used for DDC const sets.
base class _ImmutableSet<E> extends _HashSet<E> {
  _ImmutableSet.from(JSArray<E> entries) {
    var map = _map;
    for (var key in entries) {
      if (key == null) {
        // Convert undefined to null, if needed.
        JS('', '# = null', key);
      } else if (JS<bool>('!', '#[#] !== #', key,
          dart.extensionSymbol('_equals'), dart.identityEquals)) {
        key = putLinkedMapKey(key, _keyMap);
      }
      JS('', '#.add(#)', map, key);
    }
  }

  bool add(E value) => throw _unsupported();
  void addAll(Iterable<E> elements) => throw _unsupported();
  void clear() => throw _unsupported();
  bool remove(Object? value) => throw _unsupported();

  static Error _unsupported() =>
      UnsupportedError("Cannot modify unmodifiable set");
}

base class _IdentityHashSet<E> extends _InternalSet<E>
    implements HashSet<E>, LinkedHashSet<E> {
  /// The backing store for this set.
  @notNull
  final _map = JS('', 'new Set()');

  @notNull
  int _modifications = 0;

  _IdentityHashSet();

  Set<E> _newSet() => _IdentityHashSet<E>();

  Set<R> _newSimilarSet<R>() => _IdentityHashSet<R>();

  bool contains(Object? element) {
    return JS<bool>('!', '#.has(#)', _map, element);
  }

  E? lookup(Object? element) {
    return element is E && JS<bool>('!', '#.has(#)', _map, element)
        ? element
        : null;
  }

  bool add(E element) {
    var map = _map;
    if (JS<bool>('!', '#.has(#)', map, element)) return false;
    JS('', '#.add(#)', map, element);
    _modifications = (_modifications + 1) & 0x3fffffff;
    return true;
  }

  void addAll(Iterable<E> objects) {
    var map = _map;
    int length = JS('', '#.size', map);
    for (E key in objects) {
      JS('', '#.add(#)', map, key);
    }
    if (length != JS<int>('!', '#.size', map)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }

  bool remove(Object? element) {
    if (JS<bool>('!', '#.delete(#)', _map, element)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
      return true;
    }
    return false;
  }

  void clear() {
    var map = _map;
    if (JS<int>('!', '#.size', map) > 0) {
      JS('', '#.clear()', map);
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }
}

base class _CustomKeyHashSet<E> extends _CustomHashSet<E> {
  _Predicate<Object?> _validKey;
  _CustomKeyHashSet(_Equality<E> equals, _Hasher<E> hashCode, this._validKey)
      : super(equals, hashCode);

  Set<E> _newSet() => _CustomKeyHashSet<E>(_equals, _hashCode, _validKey);

  Set<R> _newSimilarSet<R>() => _HashSet<R>();

  bool contains(Object? element) {
    // TODO(jmesserly): there is a subtle difference here compared to Dart 1.
    // See the comment on CustomKeyHashMap.containsKey for more information.
    // Treatment of `null` is different due to strong mode's requirement to
    // perform an `element is E` check before calling equals/hashCode.
    if (!_validKey(element)) return false;
    return super.contains(element);
  }

  E? lookup(Object? element) {
    if (!_validKey(element)) return null;
    return super.lookup(element);
  }

  bool remove(Object? element) {
    if (!_validKey(element)) return false;
    return super.remove(element);
  }
}

base class _CustomHashSet<E> extends _InternalSet<E>
    implements HashSet<E>, LinkedHashSet<E> {
  _Equality<E> _equals;
  _Hasher<E> _hashCode;

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

  /// The backing store for this set, used to handle ordering.
  // TODO(jmesserly): a non-linked custom hash set could skip this.
  @notNull
  final _map = JS('', 'new Set()');

  /// Our map used to map keys onto the canonical key that is stored in [_map].
  @notNull
  final _keyMap = JS('', 'new Map()');

  _CustomHashSet(this._equals, this._hashCode);

  Set<E> _newSet() => _CustomHashSet<E>(_equals, _hashCode);
  Set<R> _newSimilarSet<R>() => _HashSet<R>();

  bool contains(Object? key) {
    if (key is E) {
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, _hashCode(key));
      if (buckets != null) {
        var equals = _equals;
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          E k = JS('', '#[#]', buckets, i);
          if (equals(k, key)) return true;
        }
      }
    }
    return false;
  }

  E? lookup(Object? key) {
    if (key is E) {
      var buckets = JS('', '#.get(# & 0x3fffffff)', _keyMap, _hashCode(key));
      if (buckets != null) {
        var equals = _equals;
        for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
          E k = JS('', '#[#]', buckets, i);
          if (equals(k, key)) return k;
        }
      }
    }
    return null;
  }

  bool add(E key) {
    var keyMap = _keyMap;
    var hash = JS<int>('!', '# & 0x3fffffff', _hashCode(key));
    var buckets = JS('', '#.get(#)', keyMap, hash);
    if (buckets == null) {
      JS('', '#.set(#, [#])', keyMap, hash, key);
    } else {
      var equals = _equals;
      for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
        E k = JS('', '#[#]', buckets, i);
        if (equals(k, key)) return false;
      }
      JS('', '#.push(#)', buckets, key);
    }
    JS('', '#.add(#)', _map, key);
    _modifications = (_modifications + 1) & 0x3fffffff;
    return true;
  }

  void addAll(Iterable<E> objects) {
    // TODO(jmesserly): it'd be nice to skip the covariance check here.
    for (E element in objects) add(element);
  }

  bool remove(Object? key) {
    if (key is E) {
      var hash = JS<int>('!', '# & 0x3fffffff', _hashCode(key));
      var keyMap = _keyMap;
      var buckets = JS('', '#.get(#)', keyMap, hash);
      if (buckets == null) return false; // not found
      var equals = _equals;
      for (int i = 0, n = JS('!', '#.length', buckets); i < n; i++) {
        E k = JS('', '#[#]', buckets, i);
        if (equals(k, key)) {
          if (n == 1) {
            JS('', '#.delete(#)', keyMap, hash);
          } else {
            JS('', '#.splice(#, 1)', buckets, i);
          }
          JS('', '#.delete(#)', _map, k);
          _modifications = (_modifications + 1) & 0x3fffffff;
          return true;
        }
      }
    }
    return false;
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

/// Base class for our internal [LinkedHashSet]/[HashSet] implementations.
///
/// This implements the common functionality.
abstract base class _InternalSet<E> extends _SetBase<E> {
  @notNull
  get _map;

  @notNull
  int get _modifications;

  @notNull
  int get length => JS<int>('!', '#.size', _map);

  @notNull
  bool get isEmpty => JS<bool>('!', '#.size == 0', _map);

  @notNull
  bool get isNotEmpty => JS<bool>('!', '#.size != 0', _map);

  Iterator<E> get iterator => DartIterator<E>(_jsIterator());

  @JSExportName('Symbol.iterator')
  _jsIterator() {
    var self = this;
    var iterator = JS('', '#.values()', self._map);
    int modifications = self._modifications;
    return JS(
        '',
        '''{
      next() {
        if (# != #) {
          throw #;
        }
        return #.next();
      }
    }''',
        modifications,
        self._modifications,
        ConcurrentModificationError(self),
        iterator);
  }
}
