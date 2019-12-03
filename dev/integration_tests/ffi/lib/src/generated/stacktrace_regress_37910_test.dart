// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--stacktrace_every=100

import 'dart:ffi' as ffi;

typedef fooFfi1Type = ffi.Int32 Function();
int fooFfi1() {
  int a = 0;
  for (int i = 0; i < 1000; ++i) {
    a += i;
  }
  return a;
}

int Function() foo1 = ffi.Pointer.fromFunction<fooFfi1Type>(fooFfi1, 0)
    .cast<ffi.NativeFunction<fooFfi1Type>>()
    .asFunction();

main() {
  foo1();
}
