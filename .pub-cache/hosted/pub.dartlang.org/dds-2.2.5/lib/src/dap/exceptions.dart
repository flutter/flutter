// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Exception thrown by a debug adapter when a request is not valid, either
/// because the inputs are not correct or the adapter is not in the correct
/// state.
class DebugAdapterException implements Exception {
  final String message;

  DebugAdapterException(this.message);

  String toString() => 'DebugAdapterException: $message';
}
