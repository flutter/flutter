// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

/// Like [mergeMaps], but assumes both maps are unmodifiable and so avoids
/// creating a new map unnecessarily.
///
/// The return value *may or may not* be unmodifiable.
Map<K, V> mergeUnmodifiableMaps<K, V>(Map<K, V> map1, Map<K, V> map2,
    {V Function(V, V)? value}) {
  if (map1.isEmpty) return map2;
  if (map2.isEmpty) return map1;
  return mergeMaps(map1, map2, value: value);
}
