// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:collection/collection.dart';

class CacheData {
  final int id;
  final Uint8List bytes;

  CacheData(this.id, this.bytes);
}

/// Store of bytes associated with string keys and a hash.
///
/// Each key must be not longer than 100 characters and consist of only `[a-z]`,
/// `[0-9]`, `.` and `_` characters. The key cannot be an empty string, the
/// literal `.`, or contain the sequence `..`.
///
/// Note that associations are not guaranteed to be persistent. The value
/// associated with a key can change or become `null` at any point in time.
abstract class CiderByteStore {
  /// Return the bytes associated with the errors for given [key] and
  /// [signature].
  ///
  /// Return `null` if the association does not exist.
  CacheData? get(String key, Uint8List signature);

  /// Associate the given [bytes] with the [key] and [signature]. Return the
  /// [CacheData].
  CacheData putGet(String key, Uint8List signature, Uint8List bytes);

  ///  Used to decrement reference count for the given ids, if implemented.
  void release(Iterable<int> ids);
}

class CiderByteStoreTestView {
  int length = 0;
}

class CiderCachedByteStore implements CiderByteStore {
  final Cache<String, CiderCacheEntry> _cache;
  int idCounter = 0;

  /// This field gets value only during testing.
  CiderByteStoreTestView? testView;

  CiderCachedByteStore(int maxCacheSize)
      : _cache = Cache<String, CiderCacheEntry>(
            maxCacheSize, (v) => v.data.bytes.length);

  @override
  CacheData? get(String key, Uint8List signature) {
    var entry = _cache.get(key, () => null);

    if (entry != null &&
        const ListEquality<int>().equals(entry.signature, signature)) {
      return entry.data;
    }
    return null;
  }

  @override
  CacheData putGet(String key, Uint8List signature, Uint8List bytes) {
    idCounter++;
    var entry = CiderCacheEntry(signature, CacheData(idCounter, bytes));
    _cache.put(key, entry);
    testView?.length++;
    return entry.data;
  }

  @override
  void release(Iterable<int> ids) {
    // do nothing
  }
}

class CiderCacheEntry {
  final CacheData data;
  final Uint8List signature;

  CiderCacheEntry(this.signature, this.data);
}
