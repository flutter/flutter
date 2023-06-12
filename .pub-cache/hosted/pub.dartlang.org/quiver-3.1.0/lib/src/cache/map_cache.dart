// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:collection';

import 'package:quiver/src/collection/lru_map.dart' show LruMap;

import 'cache.dart';

/// A [Cache] that's backed by a [Map].
class MapCache<K, V> implements Cache<K, V> {
  /// Creates a new [MapCache], optionally using [map] as the backing [Map].
  MapCache({Map<K, V>? map}) : _map = map ?? HashMap<K, V>();

  /// Creates a new [MapCache], using [LruMap] as the backing [Map].
  ///
  /// When [maximumSize] is specified, the cache is limited to the specified
  /// number of pairs, otherwise it is limited to 100.
  factory MapCache.lru({int? maximumSize}) {
    // TODO(cbracken): inline the default value here for readability.
    // https://github.com/google/quiver-dart/issues/653
    return MapCache<K, V>(map: LruMap(maximumSize: maximumSize));
  }

  final Map<K, V> _map;

  /// Map of outstanding ifAbsent calls used to prevent concurrent loads of the
  /// same key.
  final _outstanding = <K, FutureOr<V>>{};

  @override
  Future<V?> get(K key, {Loader<K, V>? ifAbsent}) async {
    if (_map.containsKey(key)) {
      return _map[key];
    }
    // If this key is already loading then return the existing future.
    if (_outstanding.containsKey(key)) {
      return _outstanding[key];
    }
    if (ifAbsent != null) {
      var futureOr = ifAbsent(key);
      _outstanding[key] = futureOr;
      V v;
      try {
        v = await futureOr;
      } finally {
        // Always remove key from [_outstanding] to prevent returning the
        // failed result again.
        _outstanding.remove(key);
      }
      _map[key] = v;
      return v;
    }
    return null;
  }

  @override
  Future<void> set(K key, V value) async {
    _map[key] = value;
  }

  @override
  Future<void> invalidate(K key) async {
    _map.remove(key);
  }
}
