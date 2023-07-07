// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import '../path.dart' as p;

/// A map whose keys are paths, compared using [p.equals] and [p.hash].
class PathMap<V> extends MapView<String?, V> {
  /// Creates an empty [PathMap] whose keys are compared using `context.equals`
  /// and `context.hash`.
  ///
  /// The [context] defaults to the current path context.
  PathMap({p.Context? context}) : super(_create(context));

  /// Creates a [PathMap] with the same keys and values as [other] whose keys
  /// are compared using `context.equals` and `context.hash`.
  ///
  /// The [context] defaults to the current path context. If multiple keys in
  /// [other] represent the same logical path, the last key's value will be
  /// used.
  PathMap.of(Map<String, V> other, {p.Context? context})
      : super(_create(context)..addAll(other));

  /// Creates a map that uses [context] for equality and hashing.
  static Map<String?, V> _create<V>(p.Context? context) {
    context ??= p.context;
    return LinkedHashMap(
        equals: (path1, path2) {
          if (path1 == null) return path2 == null;
          if (path2 == null) return false;
          return context!.equals(path1, path2);
        },
        hashCode: (path) => path == null ? 0 : context!.hash(path),
        isValidKey: (path) => path is String || path == null);
  }
}
