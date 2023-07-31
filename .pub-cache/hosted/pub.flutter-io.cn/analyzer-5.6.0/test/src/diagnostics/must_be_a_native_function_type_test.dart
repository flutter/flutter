// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustBeANativeFunctionTypeTest);
  });
}

@reflectiveTest
class MustBeANativeFunctionTypeTest extends PubPackageResolutionTest {
  test_fromFunction() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
int f(int i) => i * 2;
class C<T extends Function> {
  void g() {
    Pointer.fromFunction<T>(f);
  }
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 110, 1),
    ]);
  }

  test_lookupFunction() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef S = int Function(int);
typedef F = String Function(String);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 137, 1),
    ]);
  }

  test_lookupFunction_Pointer() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
typedef S = Void Function(Pointer);
typedef F = void Function(Pointer);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''');
  }

  // TODO(https://dartbug.com/44594): Should this be an error or not?
  test_lookupFunction_PointerNativeFunction() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef S = Void Function(Pointer<NativeFunction>);
typedef F = void Function(Pointer<NativeFunction>);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''', [error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 173, 1)]);
  }

  test_lookupFunction_PointerNativeFunction2() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
typedef S = Void Function(Pointer<NativeFunction<Int8 Function()>>);
typedef F = void Function(Pointer<NativeFunction<Int8 Function()>>);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''');
  }

  test_lookupFunction_PointerVoid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
typedef S = Pointer<Void> Function(Pointer<Void>);
typedef F = Pointer<Void> Function(Pointer<Void>);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''');
  }

  test_lookupFunction_T() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef F = int Function(int);
class C<T extends Function> {
  void f(DynamicLibrary lib, NativeFunction x) {
    lib.lookupFunction<T, F>('g');
  }
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 152, 1),
    ]);
  }

  test_lookupFunction_VarArgs1() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Doublex2 =
  lib.lookupFunction<
    Double Function(Double, VarArgs<(Double,)>),
    double Function(double, double)
  >(
    "VariadicAt1Doublex2"
  );
''');
  }

  test_lookupFunction_VarArgs2() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, Int64)>),
    int Function(int, int, int, int, int)
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''');
  }

  test_lookupFunction_VarArgs3() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, Int64)>),
    int Function(int, int, int, int, double)
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 187, 40),
    ]);
  }

  test_lookupFunction_VarArgs4() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, {Int64 named})>),
    int Function(int, int, int, int)
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 121, 68),
    ]);
  }

  test_lookupFunction_VarArgs5() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64)>, Int64),
    int Function(int, int, int, int, int)
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 121, 60),
    ]);
  }
}
