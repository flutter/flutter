// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../guid.dart';
import '../../utils.dart';
import '../../winrt_helpers.dart';
import '../foundation/collections/iiterator.dart';
import '../foundation/collections/ikeyvaluepair.dart';
import 'comobject_pointer.dart';

class MapHelper {
  static Map<K, V> toMap<K, V>(
    IIterator<IKeyValuePair<K, V>> iterator, {
    IKeyValuePair<K, V> Function(Pointer<COMObject>)? creator,
    int length = 1,
  }) {
    final pKeyValuePairArray = calloc<COMObject>(length);

    try {
      iterator.getMany(length, pKeyValuePairArray);
      final keyValuePairs = pKeyValuePairArray.toList<IKeyValuePair<K, V>>(
          creator ?? IKeyValuePair.fromRawPointer,
          length: length);
      final map = Map.fromEntries(
          keyValuePairs.map((kvp) => MapEntry(kvp.key, kvp.value)));

      for (final kvp in keyValuePairs) {
        kvp.release();
      }

      return Map.unmodifiable(map);
    } finally {
      iterator.release();
      free(pKeyValuePairArray);
    }
  }
}

/// Determines whether [K] and [V] key-value pair is supported.
///
/// Supported key-value pairs are: `IKeyValuePair<int, IInspectable?>`,
/// `IKeyValuePair<Guid, IInspectable?>`, `IKeyValuePair<Guid, Object?>`,
/// `IKeyValuePair<PedometerStepKind, PedometerReading?>`,
/// `IKeyValuePair<Object, Object?>`,
/// `IKeyValuePair<String, Object?>`, `IKeyValuePair<String, String>`,
/// `IKeyValuePair<String, IInspectable?>`, `IKeyValuePair<String, WinRTEnum>`.
///
/// ```dart
/// isSupportedKeyValuePair<Guid, SpatialSurfaceInfo?>(); // true
/// isSupportedKeyValuePair<String, Object?>(); // true
/// ```
bool isSupportedKeyValuePair<K, V>() {
  // e.g. IKeyValuePair<int, IBuffer?>
  if (isSameType<K, int>() && isSubtypeOfInspectable<V>()) {
    return true;
  }

  // e.g. IKeyValuePair<Guid, SpatialSurfaceInfo?>, IKeyValuePair<Guid, Object?>
  if (isSameType<K, Guid>() &&
      (isSubtypeOfInspectable<V>() || isSimilarType<V, Object>())) {
    return true;
  }

  // e.g. IKeyValuePair<PedometerStepKind, PedometerReading?>
  if (isSubtypeOfWinRTEnum<K>() && isSubtypeOfInspectable<V>()) {
    return true;
  }

  // e.g. IKeyValuePair<Object, Object?>
  if (isSameType<K, Object>() && isSimilarType<V, Object>()) {
    return true;
  }

  // e.g. IKeyValuePair<String, Object?>, IKeyValuePair<String, String>,
  // IKeyValuePair<String, IJsonValue?>, IKeyValuePair<String, ChatMessageStatus>
  if (isSameType<K, String>() &&
      (isSimilarType<V, Object?>() ||
          isSameType<V, String>() ||
          isSubtypeOfInspectable<V>() ||
          isSubtypeOfWinRTEnum<V>())) {
    return true;
  }

  return false;
}
