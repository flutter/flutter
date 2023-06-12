// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An exception used to indicate that a request has been hijacked.
///
/// This shouldn't be captured by any code other than the Shelf adapter that
/// created the hijackable request. Middleware that captures exceptions should
/// make sure to pass on HijackExceptions.
///
/// See also [Request.hijack].
class HijackException implements Exception {
  const HijackException();

  @override
  String toString() =>
      "A shelf request's underlying data stream was hijacked.\n"
      'This exception is used for control flow and should only be handled by a '
      'Shelf adapter.';
}
