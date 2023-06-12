// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustBeASubtypeTest);
  });
}

@reflectiveTest
class MustBeASubtypeTest extends PubPackageResolutionTest {
  test_fromFunction_firstArgument() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
String f(int i) => i.toString();
void g() {
  Pointer.fromFunction<T>(f, 5);
}
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 122, 1),
    ]);
  }

  test_fromFunction_secondArgument() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
int f(int i) => i * 2;
void g() {
  Pointer.fromFunction<T>(f, '');
}
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 115, 2),
    ]);
  }

  test_fromFunction_valid_oneArgument() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
typedef T = Void Function(Int8);
void f(int i) {}
void g() {
  Pointer.fromFunction<T>(f);
}
''');
  }

  test_fromFunction_valid_twoArguments() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
int f(int i) => i * 2;
void g() {
  Pointer.fromFunction<T>(f, 42);
}
''');
  }

  test_lookupFunction_F() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
class C<F extends int Function(int)> {
  void f(DynamicLibrary lib, NativeFunction x) {
    lib.lookupFunction<T, F>('g');
  }
}
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 166, 1),
    ]);
  }
}
