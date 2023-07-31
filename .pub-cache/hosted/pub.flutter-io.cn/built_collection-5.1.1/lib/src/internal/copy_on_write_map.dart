// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

typedef _MapFactory<K, V> = Map<K, V> Function();

class CopyOnWriteMap<K, V> implements Map<K, V> {
  final _MapFactory<K, V>? _mapFactory;
  bool _copyBeforeWrite;
  Map<K, V> _map;

  CopyOnWriteMap(this._map, [this._mapFactory]) : _copyBeforeWrite = true;

  // Read-only methods: just forward.

  @override
  V? operator [](Object? key) => _map[key];

  @override
  Map<K2, V2> cast<K2, V2>() => CopyOnWriteMap<K2, V2>(_map.cast<K2, V2>());

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  @override
  bool containsValue(Object? value) => _map.containsValue(value);

  @override
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  @override
  void forEach(void Function(K, V) f) => _map.forEach(f);

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Iterable<K> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K, V) f) => _map.map(f);

  @override
  Iterable<V> get values => _map.values;

  // Mutating methods: copy first if needed.

  @override
  void operator []=(K key, V value) {
    _maybeCopyBeforeWrite();
    _map[key] = value;
  }

  @override
  void addAll(Map<K, V> other) {
    _maybeCopyBeforeWrite();
    _map.addAll(other);
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    _maybeCopyBeforeWrite();
    _map.addEntries(entries);
  }

  @override
  void clear() {
    _maybeCopyBeforeWrite();
    _map.clear();
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    _maybeCopyBeforeWrite();
    return _map.putIfAbsent(key, ifAbsent);
  }

  @override
  V? remove(Object? key) {
    _maybeCopyBeforeWrite();
    return _map.remove(key);
  }

  @override
  void removeWhere(bool Function(K, V) test) {
    _maybeCopyBeforeWrite();
    _map.removeWhere(test);
  }

  @override
  String toString() => _map.toString();

  @override
  V update(K key, V Function(V) update, {V Function()? ifAbsent}) {
    _maybeCopyBeforeWrite();
    return _map.update(key, update, ifAbsent: ifAbsent);
  }

  @override
  void updateAll(V Function(K, V) update) {
    _maybeCopyBeforeWrite();
    _map.updateAll(update);
  }

  // Internal.

  void _maybeCopyBeforeWrite() {
    if (!_copyBeforeWrite) return;
    _copyBeforeWrite = false;
    _map = _mapFactory != null
        ? (_mapFactory!()..addAll(_map))
        : Map<K, V>.from(_map);
  }
}
