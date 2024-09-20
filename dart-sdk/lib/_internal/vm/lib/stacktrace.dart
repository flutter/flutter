// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

/// VM internal StackTrace implementation.
@pragma("vm:entry-point")
class _StackTrace implements StackTrace {
  // toString() is overridden on the C++ side.
}
