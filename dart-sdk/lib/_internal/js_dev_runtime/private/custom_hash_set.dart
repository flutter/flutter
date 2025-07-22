// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

base class CustomKeyHashSet<E> extends CustomHashSet<E> {
  final _Predicate<Object?> _validKey;
  CustomKeyHashSet(_Equality<E> equals, _Hasher<E> hashCode, this._validKey)
    : super(equals, hashCode);

  Set<E> _newSet() => CustomKeyHashSet<E>(_equals, _hashCode, _validKey);

  Set<R> _newSimilarSet<R>() => LinkedSet<R>();

  @override
  @notNull
  bool contains(Object? element) {
    // TODO(jmesserly): there is a subtle difference here compared to Dart 1.
    // See the comment on CustomKeyHashMap.containsKey for more information.
    // Treatment of `null` is different due to strong mode's requirement to
    // perform an `element is E` check before calling equals/hashCode.
    if (!_validKey(element)) return false;
    return super.contains(element);
  }

  @override
  E? lookup(Object? element) {
    if (!_validKey(element)) return null;
    return super.lookup(element);
  }

  @override
  bool remove(Object? element) {
    if (!_validKey(element)) return false;
    return super.remove(element);
  }
}

base class CustomHashSet<E> extends InternalSet<E> {
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

  CustomHashSet(this._equals, this._hashCode);

  Set<E> _newSet() => CustomHashSet<E>(_equals, _hashCode);
  Set<R> _newSimilarSet<R>() => LinkedSet<R>();

  @notNull
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
