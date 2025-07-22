// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Efficient JavaScript based implementation of a linked hash set used as a
// backing map for constant sets and the [LinkedHashSet] patch.

part of dart._js_helper;

/// Base class for our internal [LinkedHashSet]/[HashSet] implementations.
///
/// This implements the common functionality.
abstract base class InternalSet<E> extends SetBase<E>
    implements LinkedHashSet<E>, HashSet<E> {
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
      iterator,
    );
  }

  Set<E> _newSet() => LinkedSet<E>();

  Set<R> _newSimilarSet<R>() => LinkedSet<R>();

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newSimilarSet);

  Set<E> difference(Set<Object?> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> intersection(Set<Object?> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> toSet() => _newSet()..addAll(this);
}

/// A linked hash set implementation based on ES6 Maps and Sets.
base class LinkedSet<E> extends InternalSet<E> {
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

  bool contains(Object? key) {
    if (key == null) {
      // Convert undefined to null, if needed.
      key = null;
    } else if (JS<bool>(
      '!',
      '#[#] !== #',
      key,
      dart.extensionSymbol('_equals'),
      dart.identityEquals,
    )) {
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
    if (JS<bool>(
      '!',
      '#[#] !== #',
      key,
      dart.extensionSymbol('_equals'),
      dart.identityEquals,
    )) {
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
    } else if (JS<bool>(
      '!',
      '#[#] !== #',
      key,
      dart.extensionSymbol('_equals'),
      dart.identityEquals,
    )) {
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
      } else if (JS<bool>(
        '!',
        '#[#] !== #',
        key,
        dart.extensionSymbol('_equals'),
        dart.identityEquals,
      )) {
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
    } else if (JS<bool>(
      '!',
      '#[#] !== #',
      key,
      dart.extensionSymbol('_equals'),
      dart.identityEquals,
    )) {
      @notNull
      Object? k = key;
      int hash = JS('!', '# & 0x3fffffff', k.hashCode);
      var buckets = JS('', '#.get(#)', _keyMap, hash);
      if (buckets == null) return false; // not found
      for (int i = 0, n = JS('!', '#.length', buckets); ;) {
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
base class ImmutableSet<E> extends LinkedSet<E> {
  ImmutableSet.from(JSArray<E> entries) {
    var map = _map;
    for (var key in entries) {
      if (key == null) {
        // Convert undefined to null, if needed.
        JS('', '# = null', key);
      } else if (JS<bool>(
        '!',
        '#[#] !== #',
        key,
        dart.extensionSymbol('_equals'),
        dart.identityEquals,
      )) {
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
