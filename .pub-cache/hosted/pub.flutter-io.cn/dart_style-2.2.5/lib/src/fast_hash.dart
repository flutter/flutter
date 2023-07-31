// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A mixin for classes with identity equality that need to be frequently
/// hashed.
abstract class FastHash {
  static int _nextId = 0;

  /// A semi-unique numeric identifier for the object.
  ///
  /// This is useful for debugging and also speeds up using the object in hash
  /// sets. Ids are *semi*-unique because they may wrap around in long running
  /// processes. Since objects are equal based on their identity, this is
  /// innocuous and prevents ids from growing without bound.
  final int id = _nextId = (_nextId + 1) & 0x0fffffff;

  @override
  // ignore: hash_and_equals
  int get hashCode => id;
}
