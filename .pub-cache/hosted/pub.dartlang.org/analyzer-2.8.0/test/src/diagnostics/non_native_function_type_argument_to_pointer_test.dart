// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNativeFunctionTypeArgumentToPointerTest);
  });
}

@reflectiveTest
class NonNativeFunctionTypeArgumentToPointerTest
    extends PubPackageResolutionTest {
  test_asFunction_1() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef R = Int8 Function(Int8);
class C {
  void f(Pointer<Double> p) {
    p.asFunction<R>();
  }
}
''', [
      // This changed from a method to a extension method, uses Dart semantics
      // instead of manual check now.
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 98, 10),
    ]);
  }

  test_asFunction_2() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef TPrime = int Function(int);
typedef F = String Function(String);
class C {
  void f(Pointer<NativeFunction<TPrime>> p) {
    p.asFunction<F>();
  }
}
''', [
      error(FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER, 165, 1),
    ]);
  }

  test_asFunction_F() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef R = int Function(int);
class C<T extends Function> {
  void f(Pointer<NativeFunction<T>> p) {
    p.asFunction<R>();
  }
}
''', [
      error(FfiCode.NON_CONSTANT_TYPE_ARGUMENT, 125, 1),
    ]);
  }
}
