// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// Base class for implementing a [Map].
///
/// This class has a basic implementation of all but five of the members of
/// [Map].
/// A basic `Map` class can be implemented by extending this class and
/// implementing `keys`, `operator[]`, `operator[]=`, `remove` and `clear`.
/// The remaining operations are implemented in terms of these five.
///
/// The `keys` iterable should have efficient [Iterable.length] and
/// [Iterable.contains] operations, and it should catch concurrent modifications
/// of the keys while iterating.
///
/// A more efficient implementation is usually possible by overriding
/// some of the other members as well.
abstract mixin class MapBase<K, V> implements Map<K, V> {
  const MapBase();

  Iterable<K> get keys;
  V? operator [](Object? key);
  operator []=(K key, V value);
  V? remove(Object? key);
  // The `clear` operation should not be based on `remove`.
  // It should clear the map even if some keys are not equal to themselves.
  void clear();

  Map<RK, RV> cast<RK, RV>() => Map.castFrom<K, V, RK, RV>(this);
  void forEach(void action(K key, V value)) {
    for (K key in keys) {
      action(key, this[key] as V);
    }
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  bool containsValue(Object? value) {
    for (K key in keys) {
      if (this[key] == value) return true;
    }
    return false;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) {
      return this[key] as V;
    }
    return this[key] = ifAbsent();
  }

  V update(K key, V update(V value), {V Function()? ifAbsent}) {
    if (this.containsKey(key)) {
      return this[key] = update(this[key] as V);
    }
    if (ifAbsent != null) {
      return this[key] = ifAbsent();
    }
    throw ArgumentError.value(key, "key", "Key not in map.");
  }

  void updateAll(V update(K key, V value)) {
    for (var key in this.keys) {
      this[key] = update(key, this[key] as V);
    }
  }

  Iterable<MapEntry<K, V>> get entries {
    return keys.map((K key) => MapEntry<K, V>(key, this[key] as V));
  }

  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(K key, V value)) {
    var result = <K2, V2>{};
    for (var key in this.keys) {
      var entry = transform(key, this[key] as V);
      result[entry.key] = entry.value;
    }
    return result;
  }

  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    for (var entry in newEntries) {
      this[entry.key] = entry.value;
    }
  }

  void removeWhere(bool test(K key, V value)) {
    var keysToRemove = <K>[];
    for (var key in keys) {
      if (test(key, this[key] as V)) keysToRemove.add(key);
    }
    for (var key in keysToRemove) {
      this.remove(key);
    }
  }

  bool containsKey(Object? key) => keys.contains(key);
  int get length => keys.length;
  bool get isEmpty => keys.isEmpty;
  bool get isNotEmpty => keys.isNotEmpty;
  Iterable<V> get values => _MapBaseValueIterable<K, V>(this);
  String toString() => mapToString(this);

  static String mapToString(Map<Object?, Object?> m) {
    // Reuses the list used by Iterable for detecting toString cycles.
    if (isToStringVisiting(m)) {
      return '{...}';
    }

    var result = StringBuffer();
    try {
      toStringVisiting.add(m);
      result.write('{');
      bool first = true;
      m.forEach((Object? k, Object? v) {
        if (!first) {
          result.write(', ');
        }
        first = false;
        result.write(k);
        result.write(': ');
        result.write(v);
      });
      result.write('}');
    } finally {
      assert(identical(toStringVisiting.last, m));
      toStringVisiting.removeLast();
    }

    return result.toString();
  }

  /// Fills a [Map] with key/value pairs computed from [iterable].
  ///
  /// This method is used by [Map] classes in the named constructor
  /// `fromIterable`.
  static void _fillMapWithMappedIterable(
      Map<Object?, Object?> map,
      Iterable<Object?> iterable,
      Object? Function(Object? element)? key,
      Object? Function(Object? element)? value) {
    key ??= _id;
    value ??= _id;

    for (var element in iterable) {
      map[key(element)] = value(element);
    }
  }

  static Object? _id(Object? x) => x;

  /// Fills a map by associating the [keys] to [values].
  ///
  /// This method is used by [Map] classes in the named constructor
  /// `fromIterables`.
  static void _fillMapWithIterables(Map<Object?, Object?> map,
      Iterable<Object?> keys, Iterable<Object?> values) {
    Iterator<Object?> keyIterator = keys.iterator;
    Iterator<Object?> valueIterator = values.iterator;

    bool hasNextKey = keyIterator.moveNext();
    bool hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw ArgumentError("Iterables do not have same length.");
    }
  }
}

/// Mixin implementing a [Map].
///
/// This mixin has a basic implementation of all but five of the members of
/// [Map].
/// A basic `Map` class can be implemented by mixin in this class and
/// implementing `keys`, `operator[]`, `operator[]=`, `remove` and `clear`.
/// The remaining operations are implemented in terms of these five.
///
/// The `keys` iterable should have efficient [Iterable.length] and
/// [Iterable.contains] operations, and it should catch concurrent modifications
/// of the keys while iterating.
///
/// A more efficient implementation is usually possible by overriding
/// some of the other members as well.
// TODO: @Deprecated("Use MapBase instead")
// Longer term: Deprecate `Map` unnamed constructor, to allow using `Map`
// as skeleton class and replace `MapBase`.
typedef MapMixin<K, V> = MapBase<K, V>;

/// Basic implementation of an unmodifiable [Map].
///
/// This class has a basic implementation of all but two of the members of
/// an unmodifiable [Map].
/// A simple unmodifiable `Map` class can be implemented by extending this
/// class and implementing `keys` and `operator[]`.
///
/// Modifying operations throw when used.
/// The remaining non-modifying operations are implemented in terms of `keys`
/// and `operator[]`.
///
/// The `keys` iterable should have efficient [Iterable.length] and
/// [Iterable.contains] operations, and it should catch concurrent modifications
/// of the keys while iterating.
///
/// A more efficient implementation is usually possible by overriding
/// some of the other members as well.
abstract class UnmodifiableMapBase<K, V> = MapBase<K, V>
    with _UnmodifiableMapMixin<K, V>;

/// Implementation of [Map.values] based on the map and its [Map.keys] iterable.
///
/// Iterable that iterates over the values of a `Map`.
/// It accesses the values by iterating over the keys of the map, and using the
/// map's `operator[]` to lookup the keys.
class _MapBaseValueIterable<K, V> extends EfficientLengthIterable<V>
    implements HideEfficientLengthIterable<V> {
  final Map<K, V> _map;
  _MapBaseValueIterable(this._map);

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  V get first => _map[_map.keys.first] as V;
  V get single => _map[_map.keys.single] as V;
  V get last => _map[_map.keys.last] as V;

  Iterator<V> get iterator => _MapBaseValueIterator<K, V>(_map);
}

/// Iterator created by [_MapBaseValueIterable].
///
/// Iterates over the values of a map by iterating its keys and lookup up the
/// values.
class _MapBaseValueIterator<K, V> implements Iterator<V> {
  final Iterator<K> _keys;
  final Map<K, V> _map;
  V? _current;

  _MapBaseValueIterator(Map<K, V> map)
      : _map = map,
        _keys = map.keys.iterator;

  bool moveNext() {
    if (_keys.moveNext()) {
      _current = _map[_keys.current];
      return true;
    }
    _current = null;
    return false;
  }

  V get current => _current as V;
}

/// Mixin that overrides mutating map operations with implementations that
/// throw.
mixin _UnmodifiableMapMixin<K, V> implements Map<K, V> {
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

/// Wrapper around a class that implements [Map] that only exposes `Map`
/// members.
///
/// A simple wrapper that delegates all `Map` members to the map provided in the
/// constructor.
///
/// Base for delegating map implementations like [UnmodifiableMapView].
class MapView<K, V> implements Map<K, V> {
  final Map<K, V> _map;

  /// Creates a view which forwards operations to [map].
  const MapView(Map<K, V> map) : _map = map;

  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();
  V? operator [](Object? key) => _map[key];
  void operator []=(K key, V value) {
    _map[key] = value;
  }

  void addAll(Map<K, V> other) {
    _map.addAll(other);
  }

  void clear() {
    _map.clear();
  }

  V putIfAbsent(K key, V ifAbsent()) => _map.putIfAbsent(key, ifAbsent);
  bool containsKey(Object? key) => _map.containsKey(key);
  bool containsValue(Object? value) => _map.containsValue(value);
  void forEach(void action(K key, V value)) {
    _map.forEach(action);
  }

  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  int get length => _map.length;
  Iterable<K> get keys => _map.keys;
  V? remove(Object? key) => _map.remove(key);
  String toString() => _map.toString();
  Iterable<V> get values => _map.values;

  Iterable<MapEntry<K, V>> get entries => _map.entries;

  void addEntries(Iterable<MapEntry<K, V>> entries) {
    _map.addEntries(entries);
  }

  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(K key, V value)) =>
      _map.map<K2, V2>(transform);

  V update(K key, V update(V value), {V Function()? ifAbsent}) =>
      _map.update(key, update, ifAbsent: ifAbsent);

  void updateAll(V update(K key, V value)) {
    _map.updateAll(update);
  }

  void removeWhere(bool test(K key, V value)) {
    _map.removeWhere(test);
  }
}

/// View of a [Map] that disallow modifying the map.
///
/// A wrapper around a `Map` that forwards all members to the map provided in
/// the constructor, except for operations that modify the map.
/// Modifying operations throw instead.
///
/// ```dart
/// final baseMap = <int, String>{1: 'Mars', 2: 'Mercury', 3: 'Venus'};
/// final unmodifiableMapView = UnmodifiableMapView(baseMap);
///
/// // Remove an entry from the original map.
/// baseMap.remove(3);
/// print(unmodifiableMapView); // {1: Mars, 2: Mercury}
///
/// unmodifiableMapView.remove(1); // Throws.
/// ```
class UnmodifiableMapView<K, V> extends MapView<K, V>
    with _UnmodifiableMapMixin<K, V> {
  UnmodifiableMapView(Map<K, V> map) : super(map);

  Map<RK, RV> cast<RK, RV>() =>
      UnmodifiableMapView<RK, RV>(_map.cast<RK, RV>());
}
