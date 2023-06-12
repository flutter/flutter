// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A class for mapping JS stack traces to Dart stack traces using source maps.
abstract class StackTraceMapper {
  /// Converts [trace] into a Dart stack trace.
  StackTrace mapStackTrace(StackTrace trace);

  /// Returns a Map representation which is suitable for JSON serialization.
  Map<String, dynamic> serialize();
}
