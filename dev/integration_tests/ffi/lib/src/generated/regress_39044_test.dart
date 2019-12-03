// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Check that the optimizer does not fuse constants with different
// representations.
//
// SharedObjects=ffi_test_functions

import "dart:ffi";

import "expect.dart";

import "dylib_utils.dart";

main() {
  final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

  final intComputation = ffiTestFunctions.lookupFunction<
      Int64 Function(Int64, Int8), int Function(int, int)>("Regress39044");

  // The arguments are the same Smi constant, however they are different sizes.
  final result = intComputation(
      /* dart::kUnboxedInt64 --> int64_t             */ 1,
      /* dart::kUnboxedInt32 --> truncated to int8_t */ 1);

  Expect.equals(0, result);
}
