// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An expected exception caused by user-controllable circumstances.
class ApplicationException implements Exception {
  final String message;

  ApplicationException(this.message);

  @override
  String toString() => message;
}
