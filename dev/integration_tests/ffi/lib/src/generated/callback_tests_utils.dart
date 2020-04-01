// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'dylib_utils.dart';

import "expect.dart";

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef NativeCallbackTest = Int32 Function(Pointer);
typedef NativeCallbackTestFn = int Function(Pointer);

class CallbackTest {
  final String name;
  final Pointer callback;
  final bool skip;

  CallbackTest(this.name, this.callback, {bool skipIf: false})
      : skip = skipIf {}

  void run() {
    if (skip) return;

    final NativeCallbackTestFn tester = ffiTestFunctions
        .lookupFunction<NativeCallbackTest, NativeCallbackTestFn>("Test$name");
    final int testCode = tester(callback);
    if (testCode != 0) {
      Expect.fail("Test $name failed.");
    }
  }
}
