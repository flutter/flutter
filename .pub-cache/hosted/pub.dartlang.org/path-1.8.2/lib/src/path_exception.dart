// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An exception class that's thrown when a path operation is unable to be
/// computed accurately.
class PathException implements Exception {
  String message;

  PathException(this.message);

  @override
  String toString() => 'PathException: $message';
}
