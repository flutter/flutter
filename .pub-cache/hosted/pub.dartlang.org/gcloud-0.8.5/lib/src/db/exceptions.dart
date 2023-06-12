// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.db;

/// Exception that gets thrown when a caller attempts to look up a value by
/// its key, and the key cannot be found in the datastore.
class KeyNotFoundException implements Exception {
  /// Creates a new [KeyNotFoundException] for the specified [key].
  const KeyNotFoundException(this.key);

  /// The [Key] that was not found in the datastore.
  final Key key;

  @override
  String toString() => 'Key not found: ${key.type}:${key.id}';
}
