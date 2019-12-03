// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This program tests interaction with generic Pointers.
//
// Notation used in following tables:
// * static_type//dynamic_type
// * P = Pointer
// * I = Int8
// * NT = NativeType
//
// Note #1: When NNBD is landed, implicit downcasts will be static errors.
//
// Note #2: When we switch to extension methods we will _only_ use the static
//          type of the container.
//
// ===== a.value = b ======
// Does a.value = b, where a and b have specific static and dynamic types: run
// fine, fail at compile time, or fail at runtime?
// =======================
//                  b     P<I>//P<I>   P<NT>//P<I>           P<NT>//P<NT>
// a
// P<P<I>>//P<P<I>>     1 ok         2 implicit downcast   3 implicit downcast
//                                     of argument:          of argument:
//                                     static error          static error
//
// P<P<NT>>//P<P<I>>    4 ok         5 ok                  6 fail at runtime
//
// P<P<NT>>//P<P<NT>>   7 ok         8 ok                  9 ok
//
// ====== final c = a.value ======
// What is the (inferred) static type and runtime type of `a.value`. Note that
// we assume extension method here: on Pointer<PointerT>> { Pointer<T> load(); }
// ================================
// a                    a.value
//                      inferred static type*//runtime type
// P<P<I>>//P<P<I>>     P<I>//P<I>
//
// P<P<NT>>//P<P<I>>    P<NT>//P<I>
//
// P<P<NT>>//P<P<NT>>   P<NT>//P<NT>
//
// * The inferred static type when we get extension methods.
//
// ====== b = a.value ======
// What happens when we try to assign the result of a.value to variable b with
// a specific static type: runs fine, fails at compile time, or fails at runtime.
// ==========================
//                  b     P<I>                        P<NT>
// a
// P<P<I>>//P<P<I>>     1 ok                        2 ok
//
// P<P<NT>>//P<P<I>>    3 implicit downcast         4 ok
//                        of returnvalue: ok
//
// P<P<NT>>//P<P<NT>>   5 implicit downcast         6 ok
//                        of returnvalue: fail
//                        at runtime
//
// These are the normal Dart assignment rules.

import 'dart:ffi';

import "expect.dart";
import "package:ffi/ffi.dart";

// ===== a.value = b ======
// The tests follow table cells left to right, top to bottom.
void store1() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();
  final Pointer<Int8> b = allocate<Int8>();

  a.value = b;

  free(a);
  free(b);
}

void store2() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();
  final Pointer<NativeType> b =
      allocate<Int8>(); // Reified Pointer<Int8> at runtime.

  // Successful implicit downcast of argument at runtime.
  // Should succeed now, should statically be rejected when NNBD lands.
  a.value = b;

  free(a);
  free(b);
}

void store3() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();
  final Pointer<NativeType> b = allocate<Int8>().cast<Pointer<NativeType>>();

  // Failing implicit downcast of argument at runtime.
  // Should fail now at runtime, should statically be rejected when NNBD lands.
  Expect.throws(() {
    a.value = b;
  });

  free(a);
  free(b);
}

void store4() {
  // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<Int8>>();

  final Pointer<Int8> b = allocate<Int8>();

  a.value = b;

  free(a);
  free(b);
}

void store5() {
  // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<Int8>>();

  final Pointer<NativeType> b =
      allocate<Int8>(); // Reified as Pointer<Int8> at runtime.

  a.value = b;

  free(a);
  free(b);
}

void store6() {
  // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<Int8>>();
  final Pointer<NativeType> b = allocate<Int8>().cast<Pointer<NativeType>>();

  // Fails on type check of argument.
  Expect.throws(() {
    a.value = b;
  });

  free(a);
  free(b);
}

void store7() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();
  final Pointer<Int8> b = allocate<Int8>();

  a.value = b;

  free(a);
  free(b);
}

void store8() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();

  // Reified as Pointer<Int8> at runtime.
  final Pointer<NativeType> b = allocate<Int8>();

  a.value = b;

  free(a);
  free(b);
}

void store9() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();
  final Pointer<NativeType> b = allocate<Int8>().cast<Pointer<NativeType>>();

  a.value = b;

  free(a);
  free(b);
}

// ====== b = a.value ======
// The tests follow table cells left to right, top to bottom.
void load1() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();

  Pointer<Int8> b = a.value;
  Expect.type<Pointer<Int8>>(b);

  free(a);
}

void load2() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();

  Pointer<NativeType> b = a.value;
  Expect.type<Pointer<Int8>>(b);

  free(a);
}

void load3() {
  // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<Int8>>();

  Pointer<Int8> b = a.value;
  Expect.type<Pointer<Int8>>(b);

  free(a);
}

void load4() {
  // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<Int8>>();

  // Return value runtime type is Pointer<Int8>.
  Pointer<NativeType> b = a.value;
  Expect.type<Pointer<Int8>>(b);

  free(a);
}

void load5() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();

  // Failing implicit downcast of return value at runtime.
  // Should fail now at runtime, should statically be rejected when NNBD lands.
  Expect.throws(() {
    Pointer<Int8> b = a.value;
  });

  free(a);
}

void load6() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();

  Pointer<NativeType> b = a.value;
  Expect.type<Pointer<NativeType>>(b);

  free(a);
}

void main() {
  // Trigger both the runtime entry and the IL in bytecode.
  for (int i = 0; i < 100; i++) {
    store1();
    store2();
    store3();
    store4();
    store5();
    store6();
    store7();
    store8();
    store9();
    load1();
    load2();
    load3();
    load4();
    load5();
    load6();
  }
}
