// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interface for sentinel values used for typed `null` values on a stack.
///
/// This is used to avoid mixing `null` values between different kinds. For
/// instance a stack entry is meant to contain an expression or null, the
/// `NullValues.Expression` is pushed on the stack instead of `null` and when
/// popping the entry `NullValues.Expression` is passed show how `null` is
/// represented.
class NullValue<T> {
  const NullValue();

  @override
  String toString() => "NullValue<$T>";
}
