// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiNativeTest);
  });
}

@reflectiveTest
class FfiNativeTest extends PubPackageResolutionTest {
  test_annotation_FfiNative_noArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@FfiNative
external int foo();
''', [
      error(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, 20, 10),
    ]);
  }

  test_annotation_FfiNative_noTypeArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@FfiNative()
external int foo();
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 30, 2),
    ]);
  }

  test_FfiNativeCanUseHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function(Handle)>('DoesntMatter')
external Object doesntMatter(Object);
''', []);
  }

  test_FfiNativeCanUseLeaf() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Int8 Function(Int64)>('DoesntMatter', isLeaf:true)
external int doesntMatter(int);
''', []);
  }

  test_FfiNativeInstanceMethodsMustHaveReceiver() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class K {
  @FfiNative<Void Function(Double)>('DoesntMatter')
  external void doesntMatter(double x);
}
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
          31, 89),
    ]);
  }

  test_FfiNativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function()>('DoesntMatter', isLeaf:true)
external Object doesntMatter();
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 19, 90),
    ]);
  }

  test_FfiNativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Handle)>('DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 19, 100),
    ]);
  }

  test_FfiNativeTooFewParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Double)>('DoesntMatter')
external void doesntMatter(double x, double y);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 19, 97),
    ]);
  }

  test_FfiNativeTooManyParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Double, Double)>('DoesntMatter')
external void doesntMatter(double x);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 19, 95),
    ]);
  }
}
