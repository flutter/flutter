// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An exception thrown by various front-end methods when the test framework has
/// been closed and a test must shut down as soon as possible.
class ClosedException implements Exception {
  ClosedException();

  @override
  String toString() => 'This test has been closed.';
}
