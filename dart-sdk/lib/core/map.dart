// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A collection of key/value pairs, from which you retrieve a value
/// using its associated key.
///
/// There is a finite number of keys in the map,
/// and each key has exactly one value associated with it.
///
/// Maps, and their keys and values, can be iterated.
/// The order of iteration is defined by the individual type of map.
/// Examples:
///
/// * The plain [HashMap] is unordered (no order is guaranteed),
/// * the [LinkedHashMap] iterates in key insertion order,
/// * and a sorted map like [SplayTreeMap] iterates the keys in sorted order.
///
/// It is generally not allowed to modify the map (add or remove keys) while
/// an operation is being performed on the map, for example in functions called
/// during a [forEach] or [putIfAbsent] call.
/// Modifying the map while iterating the keys or values
/// may also break the iteration.
///
/// It is generally not allowed to modify the equality of keys (and thus not
/// their hashcode) while they are in the map. Some specialized subtypes may be
/// more permissive, in which case they should document this behavior.
abstract interface class Map<K, V> {
  /// Creates an empty [LinkedHashMap].
  ///
  /// This constructor is equivalent to the non-const map literal `<K, V>{}`.
  ///
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`.
  /// It iterates in key insertion order.
  // TODO: @Deprecated("Use literal <K, V>{} instead")
  external factory Map();

  /// Creates a [LinkedHashMap] with the same keys and values as [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type, unlike for [Map.of],
  /// and the key and value types are checked (and can fail) at run-time.
  ///
  /// Prefer using [Map.of] when possible, and only use `Map.from`
  /// to create a new map with more precise types than the original,
  /// and when it's known that all the keys and values have those
  /// more precise types.
  ///
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`.
  /// It iterates in key insertion order.
  /// ```dart
  /// final planets = <num, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth', 4: 'Mars'};
  /// final mapFrom = Map<int, String>.from(planets);
  /// print(mapFrom); // {1: Mercury, 2: Venus, 3: Earth, 4: Mars}
  /// ```
  factory Map.from(Map other) = LinkedHashMap<K, V>.from;

  /// Creates a [LinkedHashMap] with the same keys and values as [other].
  ///
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`, and it allows `null` as a key.
  /// It iterates in key insertion order.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// final mapOf = Map<num, String>.of(planets);
  /// print(mapOf); // {1: Mercury, 2: Venus, 3: Earth}
  /// ```
  factory Map.of(Map<K, V> other) = LinkedHashMap<K, V>.of;

  /// Creates an unmodifiable hash-based map containing the entries of [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type.
  ///
  /// The map requires the keys to implement compatible
  /// `operator==` and `hashCode`.
  /// The created map iterates keys in a fixed order,
  /// preserving the order provided by [other].
  ///
  /// The resulting map behaves like the result of [Map.from],
  /// except that the map returned by this constructor is not modifiable.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// final unmodifiableMap = Map.unmodifiable(planets);
  /// unmodifiableMap[4] = 'Mars'; // Throws
  /// ```
  external factory Map.unmodifiable(Map<dynamic, dynamic> other);

  /// Creates an identity map with the default implementation, [LinkedHashMap].
  ///
  /// An identity map uses [identical] for equality and [identityHashCode]
  /// for hash codes of keys instead of the intrinsic [Object.==] and
  /// [Object.hashCode] of the keys.
  ///
  /// The map iterates in key insertion order.
  factory Map.identity() = LinkedHashMap<K, V>.identity;

  /// Creates a Map instance in which the keys and values are computed from the
  /// [iterable].
  ///
  /// For each element of the [iterable], a key/value pair is computed
  /// by applying [key] and [value] respectively to the element of the iterable.
  ///
  /// Equivalent to the map literal:
  /// ```dart
  /// <K, V>{for (var v in iterable) key(v): value(v)}
  /// ```
  /// The literal is generally preferable because it allows
  /// for a more precise typing.
  ///
  /// The example below creates a new map from a list of integers.
  /// The keys of `map` are the `list` values converted to strings,
  /// and the values of the `map` are the squares of the `list` values:
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// final map = Map<String, int>.fromIterable(numbers,
  ///     key: (item) => item.toString(),
  ///     value: (item) => item * item);
  /// print(map); // {1: 1, 2: 4, 3: 9}
  /// ```
  /// If no values are specified for [key] and [value],
  /// the default is the identity function.
  /// In that case, the iterable element must be assignable to the
  /// key or value type of the created map.
  ///
  /// In the following example, the keys and corresponding values of `map`
  /// are the `list` values directly:
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// final map = Map.fromIterable(numbers);
  /// print(map); // {1: 1, 2: 2, 3: 3}
  /// ```
  /// The keys computed by the source [iterable] do not need to be unique.
  /// The last occurrence of a key will overwrite
  /// the value of any previous occurrence.
  ///
  /// The created map is a [LinkedHashMap].
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`.
  /// It iterates in key insertion order.
  factory Map.fromIterable(Iterable iterable,
      {K key(dynamic element)?,
      V value(dynamic element)?}) = LinkedHashMap<K, V>.fromIterable;

  /// Creates a map associating the given [keys] to the given [values].
  ///
  /// The map construction iterates over [keys] and [values] simultaneously,
  /// and adds an entry to the map for each pair of key and value.
  /// ```dart
  /// final rings = <bool>[false, false, true, true];
  /// final planets = <String>{'Earth', 'Mars', 'Jupiter', 'Saturn'};
  /// final map = Map<String, bool>.fromIterables(planets, rings);
  /// print(map); // {Earth: false, Mars: false, Jupiter: true, Saturn: true}
  /// ```
  /// If [keys] contains the same object multiple times,
  /// the value of the last occurrence overwrites any previous value.
  ///
  /// The two [Iterable]s must have the same length.
  ///
  /// The created map is a [LinkedHashMap].
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`.
  /// It iterates in key insertion order.
  factory Map.fromIterables(Iterable<K> keys, Iterable<V> values) =
      LinkedHashMap<K, V>.fromIterables;

  /// Adapts [source] to be a `Map<K2, V2>`.
  ///
  /// Any time the set would produce a key or value that is not a [K2] or [V2],
  /// the access will throw.
  ///
  /// Any time [K2] key or [V2] value is attempted added into the adapted map,
  /// the store will throw unless the key is also an instance of [K] and
  /// the value is also an instance of [V].
  ///
  /// If all accessed entries of [source] have [K2] keys and [V2] values,
  /// and if all entries added to the returned map have [K] keys and [V] values,
  /// then the returned map can be used as a `Map<K2, V2>`.
  ///
  /// Methods which accept `Object?` as argument,
  /// like [containsKey], [remove] and [operator []],
  /// will pass the argument directly to the this map's method
  /// without any checks.
  static Map<K2, V2> castFrom<K, V, K2, V2>(Map<K, V> source) =>
      CastMap<K, V, K2, V2>(source);

  /// Creates a new map and adds all entries.
  ///
  /// Returns a new `Map<K, V>` where all entries of [entries]
  /// have been added in iteration order.
  ///
  /// If multiple [entries] have the same key,
  /// later occurrences overwrite the value of the earlier ones.
  ///
  /// Equivalent to the map literal:
  /// ```dart
  /// <K, V>{for (var e in entries) e.key: e.value}
  /// ```
  /// Example:
  /// ```dart
  /// final moonCount = <String, int>{'Mercury': 0, 'Venus': 0, 'Earth': 1,
  ///   'Mars': 2, 'Jupiter': 79, 'Saturn': 82, 'Uranus': 27, 'Neptune': 14};
  /// final map = Map.fromEntries(moonCount.entries);
  /// ```
  factory Map.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      <K, V>{}..addEntries(entries);

  /// Provides a view of this map as having [RK] keys and [RV] instances,
  /// if necessary.
  ///
  /// If this map is already a `Map<RK, RV>`, it is returned unchanged.
  ///
  /// If this set contains only keys of type [RK] and values of type [RV],
  /// all read operations will work correctly.
  /// If any operation exposes a non-[RK] key or non-[RV] value,
  /// the operation will throw instead.
  ///
  /// Entries added to the map must be valid for both a `Map<K, V>` and a
  /// `Map<RK, RV>`.
  ///
  /// Methods which accept `Object?` as argument,
  /// like [containsKey], [remove] and [operator []],
  /// will pass the argument directly to the this map's method
  /// without any checks.
  /// That means that you can do `mapWithStringKeys.cast<int,int>().remove("a")`
  /// successfully, even if it looks like it shouldn't have any effect.
  Map<RK, RV> cast<RK, RV>();

  /// Whether this map contains the given [value].
  ///
  /// Returns true if any of the values in the map are equal to `value`
  /// according to the `==` operator.
  /// ```dart
  /// final moonCount = <String, int>{'Mercury': 0, 'Venus': 0, 'Earth': 1,
  ///   'Mars': 2, 'Jupiter': 79, 'Saturn': 82, 'Uranus': 27, 'Neptune': 14};
  /// final moons3 = moonCount.containsValue(3); // false
  /// final moons82 = moonCount.containsValue(82); // true
  /// ```
  bool containsValue(Object? value);

  /// Whether this map contains the given [key].
  ///
  /// Returns true if any of the keys in the map are equal to `key`
  /// according to the equality used by the map.
  /// ```dart
  /// final moonCount = <String, int>{'Mercury': 0, 'Venus': 0, 'Earth': 1,
  ///   'Mars': 2, 'Jupiter': 79, 'Saturn': 82, 'Uranus': 27, 'Neptune': 14};
  /// final containsUranus = moonCount.containsKey('Uranus'); // true
  /// final containsPluto = moonCount.containsKey('Pluto'); // false
  /// ```
  bool containsKey(Object? key);

  /// The value for the given [key], or `null` if [key] is not in the map.
  ///
  /// Some maps allow `null` as a value.
  /// For those maps, a lookup using this operator cannot distinguish between a
  /// key not being in the map, and the key being there with a `null` value.
  /// Methods like [containsKey] or [putIfAbsent] can be used if the distinction
  /// is important.
  V? operator [](Object? key);

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key/value pair is added to the map.
  void operator []=(K key, V value);

  /// The map entries of this [Map].
  Iterable<MapEntry<K, V>> get entries;

  /// Returns a new map where all entries of this map are transformed by
  /// the given [convert] function.
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> convert(K key, V value));

  /// Adds all key/value pairs of [newEntries] to this map.
  ///
  /// If a key of [newEntries] is already in this map,
  /// the corresponding value is overwritten.
  ///
  /// The operation is equivalent to doing `this[entry.key] = entry.value`
  /// for each [MapEntry] of the iterable.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus',
  ///   3: 'Earth', 4: 'Mars'};
  /// final gasGiants = <int, String>{5: 'Jupiter', 6: 'Saturn'};
  /// final iceGiants = <int, String>{7: 'Uranus', 8: 'Neptune'};
  /// planets.addEntries(gasGiants.entries);
  /// planets.addEntries(iceGiants.entries);
  /// print(planets);
  /// // {1: Mercury, 2: Venus, 3: Earth, 4: Mars, 5: Jupiter, 6: Saturn,
  /// //  7: Uranus, 8: Neptune}
  /// ```
  void addEntries(Iterable<MapEntry<K, V>> newEntries);

  /// Updates the value for the provided [key].
  ///
  /// Returns the new value associated with the key.
  ///
  /// If the key is present, invokes [update] with the current value and stores
  /// the new value in the map.
  ///
  /// If the key is not present and [ifAbsent] is provided, calls [ifAbsent]
  /// and adds the key with the returned value to the map.
  ///
  /// If the key is not present, [ifAbsent] must be provided.
  /// ```dart
  /// final planetsFromSun = <int, String>{1: 'Mercury', 2: 'unknown',
  ///   3: 'Earth'};
  /// // Update value for known key value 2.
  /// planetsFromSun.update(2, (value) => 'Venus');
  /// print(planetsFromSun); // {1: Mercury, 2: Venus, 3: Earth}
  ///
  /// final largestPlanets = <int, String>{1: 'Jupiter', 2: 'Saturn',
  ///   3: 'Neptune'};
  /// // Key value 8 is missing from list, add it using [ifAbsent].
  /// largestPlanets.update(8, (value) => 'New', ifAbsent: () => 'Mercury');
  /// print(largestPlanets); // {1: Jupiter, 2: Saturn, 3: Neptune, 8: Mercury}
  /// ```
  V update(K key, V update(V value), {V ifAbsent()?});

  /// Updates all values.
  ///
  /// Iterates over all entries in the map and updates them with the result
  /// of invoking [update].
  /// ```dart
  /// final terrestrial = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// terrestrial.updateAll((key, value) => value.toUpperCase());
  /// print(terrestrial); // {1: MERCURY, 2: VENUS, 3: EARTH}
  /// ```
  void updateAll(V update(K key, V value));

  /// Removes all entries of this map that satisfy the given [test].
  /// ```dart
  /// final terrestrial = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// terrestrial.removeWhere((key, value) => value.startsWith('E'));
  /// print(terrestrial); // {1: Mercury, 2: Venus}
  /// ```
  void removeWhere(bool test(K key, V value));

  /// Look up the value of [key], or add a new entry if it isn't there.
  ///
  /// Returns the value associated to [key], if there is one.
  /// Otherwise calls [ifAbsent] to get a new value, associates [key] to
  /// that value, and then returns the new value.
  /// ```dart
  /// final diameters = <num, String>{1.0: 'Earth'};
  /// final otherDiameters = <double, String>{0.383: 'Mercury', 0.949: 'Venus'};
  ///
  /// for (final item in otherDiameters.entries) {
  ///   diameters.putIfAbsent(item.key, () => item.value);
  /// }
  /// print(diameters); // {1.0: Earth, 0.383: Mercury, 0.949: Venus}
  ///
  /// // If the key already exists, the current value is returned.
  /// final result = diameters.putIfAbsent(0.383, () => 'Random');
  /// print(result); // Mercury
  /// print(diameters); // {1.0: Earth, 0.383: Mercury, 0.949: Venus}
  /// ```
  /// Calling [ifAbsent] must not add or remove keys from the map.
  V putIfAbsent(K key, V ifAbsent());

  /// Adds all key/value pairs of [other] to this map.
  ///
  /// If a key of [other] is already in this map, its value is overwritten.
  ///
  /// The operation is equivalent to doing `this[key] = value` for each key
  /// and associated value in other. It iterates over [other], which must
  /// therefore not change during the iteration.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Earth'};
  /// planets.addAll({5: 'Jupiter', 6: 'Saturn'});
  /// print(planets); // {1: Mercury, 2: Earth, 5: Jupiter, 6: Saturn}
  /// ```
  void addAll(Map<K, V> other);

  /// Removes [key] and its associated value, if present, from the map.
  ///
  /// Returns the value associated with `key` before it was removed.
  /// Returns `null` if `key` was not in the map.
  ///
  /// Note that some maps allow `null` as a value,
  /// so a returned `null` value doesn't always mean that the key was absent.
  /// ```dart
  /// final terrestrial = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// final removedValue = terrestrial.remove(2); // Venus
  /// print(terrestrial); // {1: Mercury, 3: Earth}
  /// ```
  V? remove(Object? key);

  /// Removes all entries from the map.
  ///
  /// After this, the map is empty.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// planets.clear(); // {}
  /// ```
  void clear();

  /// Applies [action] to each key/value pair of the map.
  ///
  /// Calling `action` must not add or remove keys from the map.
  /// ```dart
  /// final planetsByMass = <num, String>{0.81: 'Venus', 1: 'Earth',
  ///   0.11: 'Mars', 17.15: 'Neptune'};
  ///
  /// planetsByMass.forEach((key, value) {
  ///   print('$key: $value');
  ///   // 0.81: Venus
  ///   // 1: Earth
  ///   // 0.11: Mars
  ///   // 17.15: Neptune
  /// });
  /// ```
  void forEach(void action(K key, V value));

  /// The keys of this [Map].
  ///
  /// The returned iterable has efficient `length` and `contains` operations,
  /// based on [length] and [containsKey] of the map.
  ///
  /// The order of iteration is defined by the individual `Map` implementation,
  /// but must be consistent between changes to the map.
  ///
  /// Modifying the map while iterating the keys may break the iteration.
  Iterable<K> get keys;

  /// The values of this [Map].
  ///
  /// The values are iterated in the order of their corresponding keys.
  /// This means that iterating [keys] and [values] in parallel will
  /// provide matching pairs of keys and values.
  ///
  /// The returned iterable has an efficient `length` method based on the
  /// [length] of the map. Its [Iterable.contains] method is based on
  /// `==` comparison.
  ///
  /// Modifying the map while iterating the values may break the iteration.
  Iterable<V> get values;

  /// The number of key/value pairs in the map.
  int get length;

  /// Whether there is no key/value pair in the map.
  bool get isEmpty;

  /// Whether there is at least one key/value pair in the map.
  bool get isNotEmpty;
}

/// A key/value pair representing an entry in a [Map].
///
/// The [Map] interface contains various methods that can
/// inspect or modify the map based on entry objects.
/// ```dart
/// final map = {'1': 'A', '2': 'B'};
/// map.addEntries([
///  MapEntry('3', 'C'),
///  MapEntry('4', 'D'),
/// ]);
/// print(map); // {1: A, 2: B, 3: C, 4: D}
/// ```
///
/// Do not extend or implement the `MapEntry` class.
/// If the Dart language introduces value types,
/// the `MapEntry` class will be changed to such a type,
/// and will likely no longer be able to be implemented or extended
/// by classes.
final class MapEntry<K, V> {
  /// The key of the entry.
  ///
  /// ```dart
  /// final map = {'theKey': 'theValue'}; // Map<String, String>
  /// var entry = map.entries.first; // MapEntry<String, String>
  /// print(entry.key); // 'theKey'
  /// ```
  final K key;

  /// The value associated to [key] in a map.
  ///
  /// ```dart
  /// final map = {'theKey': 'theValue'}; // Map<String, String>
  /// var entry = map.entries.first; // MapEntry<String, String>
  /// print(entry.value); // 'theValue'
  /// ```
  final V value;

  /// Creates an entry with [key] and [value].
  const factory MapEntry(K key, V value) = MapEntry<K, V>._;

  const MapEntry._(this.key, this.value);

  /// String representation intended for debugging only.
  ///
  /// Not guaranteed to be stable over time.
  String toString() => "MapEntry($key: $value)";
}
