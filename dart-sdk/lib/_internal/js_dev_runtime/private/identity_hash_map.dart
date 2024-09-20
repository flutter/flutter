// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

base class IdentityMap<K, V> extends InternalMap<K, V> {
  final _map = JS('', 'new Map()');

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

  IdentityMap();
  IdentityMap.from(JSArray entries) {
    var map = _map;
    for (int i = 0, n = JS<int>('!', '#.length', entries); i < n; i += 2) {
      JS('', '#.set(#[#], #[#])', map, entries, i, entries, i + 1);
    }
  }

  int get length => JS<int>('!', '#.size', _map);
  bool get isEmpty => JS<bool>('!', '#.size == 0', _map);
  bool get isNotEmpty => JS<bool>('!', '#.size != 0', _map);

  Iterable<K> get keys => _JSMapIterable<K>(this, true);
  Iterable<V> get values => _JSMapIterable<V>(this, false);

  bool containsKey(Object? key) {
    return JS<bool>('!', '#.has(#)', _map, key);
  }

  bool containsValue(Object? value) {
    for (var v in JS('', '#.values()', _map)) {
      if (v == value) return true;
    }
    return false;
  }

  void addAll(Map<K, V> other) {
    if (other.isNotEmpty) {
      var map = _map;
      other.forEach((key, value) {
        JS('', '#.set(#, #)', map, key, value);
      });
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }

  V? operator [](Object? key) {
    V value = JS('', '#.get(#)', _map, key);
    // coerce undefined to null.
    return JS<bool>('!', '# === void 0', value) ? null : value;
  }

  void operator []=(K key, V value) {
    var map = _map;
    int length = JS('!', '#.size', map);
    JS('', '#.set(#, #)', map, key, value);
    if (length != JS<int>('!', '#.size', map)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (JS<bool>('!', '#.has(#)', _map, key)) {
      return JS('', '#.get(#)', _map, key);
    }
    V value = ifAbsent();
    if (value == null) JS('', '# = null', value);
    JS('', '#.set(#, #)', _map, key, value);
    _modifications = (_modifications + 1) & 0x3fffffff;
    return value;
  }

  V? remove(Object? key) {
    V value = JS('', '#.get(#)', _map, key);
    if (JS<bool>('!', '#.delete(#)', _map, key)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
    // coerce undefined to null.
    return JS<bool>('!', '# === void 0', value) ? null : value;
  }

  void clear() {
    if (JS<int>('!', '#.size', _map) > 0) {
      JS('', '#.clear()', _map);
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }
}

class _JSMapIterable<E> extends EfficientLengthIterable<E>
    implements HideEfficientLengthIterable<E> {
  final InternalMap _map;
  @notNull
  final bool _isKeys;
  _JSMapIterable(this._map, this._isKeys);

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;

  @JSExportName('Symbol.iterator')
  _jsIterator() {
    var map = _map;
    var iterator =
        JS('', '# ? #.keys() : #.values()', _isKeys, map._map, map._map);
    int modifications = map._modifications;
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
        map._modifications,
        ConcurrentModificationError(map),
        iterator);
  }

  Iterator<E> get iterator => DartIterator<E>(_jsIterator());

  bool contains(Object? element) =>
      _isKeys ? _map.containsKey(element) : _map.containsValue(element);

  void forEach(void Function(E) f) {
    for (var entry in this) f(entry);
  }
}
