// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An exception thrown when a test assertion fails.
class TestFailure implements Exception {
  final String? message;

  TestFailure(this.message);

  @override
  String toString() => message.toString();
}
