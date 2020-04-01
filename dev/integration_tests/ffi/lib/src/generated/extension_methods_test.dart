// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import "expect.dart";
import "package:ffi/ffi.dart";

main(List<String> arguments) {
  for (int i = 0; i < 100; i++) {
    testStoreLoad();
    testReifiedGeneric();
  }
}

testStoreLoad() {
  final p = allocate<Int8>(count: 2);
  p.value = 10;
  Expect.equals(10, p.value);
  p[1] = 20;
  Expect.equals(20, p[1]);
  if (sizeOf<IntPtr>() == 4) {
    // Test round tripping.
    Expect.equals(20, p.elementAt(0x100000001).value);
    Expect.equals(20, p[0x100000001]);
  }

  // Test negative index.
  final pUseNegative = p.elementAt(1);
  Expect.equals(10, pUseNegative[-1]);

  final p1 = allocate<Double>(count: 2);
  p1.value = 10.0;
  Expect.approxEquals(10.0, p1.value);
  p1[1] = 20.0;
  Expect.approxEquals(20.0, p1[1]);
  free(p1);

  final p2 = allocate<Pointer<Int8>>(count: 2);
  p2.value = p;
  Expect.equals(p, p2.value);
  p2[1] = p;
  Expect.equals(p, p2[1]);
  free(p2);
  free(p);

  final p3 = allocate<Foo>();
  Foo foo = p3.ref;
  foo.a = 1;
  Expect.equals(1, foo.a);
  free(p3);
}

testReifiedGeneric() {
  final p = allocate<Pointer<Int8>>();
  Pointer<Pointer<NativeType>> p2 = p;
  Expect.isTrue(p2.value is Pointer<Int8>);
  free(p);
}

class Foo extends Struct {
  @Int8()
  int a;
}
