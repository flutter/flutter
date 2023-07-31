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
    defineReflectiveTests(NativeTest);
  });
}

@reflectiveTest
class FfiNativeTest extends PubPackageResolutionTest {
  test_annotation_FfiNative_getters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class NativeFieldWrapperClass1 {}

class Paragraph extends NativeFieldWrapperClass1 {
  @FfiNative<Double Function(Pointer<Void>)>('Paragraph::ideographicBaseline', isLeaf: true)
  external double get ideographicBaseline;

  @FfiNative<Void Function(Pointer<Void>, Double)>('Paragraph::ideographicBaseline', isLeaf: true)
  external set ideographicBaseline(double d);
}
''', []);
  }

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
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          31, 1),
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
external int doesntMatter(int x);
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

  test_FfiNativeNonFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<IntPtr Function(int)>('doesntmatter')
external int nonFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 19, 85),
    ]);
  }

  test_FfiNativeNonFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<double Function(IntPtr)>('doesntmatter')
external double nonFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 19, 92),
    ]);
  }

  test_FfiNativePointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Pointer)>('free')
external void posixFree(Pointer pointer);
''');
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

  test_FfiNativeVoidReturn() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function(Uint32, Uint32, Handle)>('doesntmatter')
external void voidReturn(int width, int height, Object outImage);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 133),
    ]);
  }

  test_FfiNativeWrongFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<IntPtr Function(Double)>('doesntmatter')
external int wrongFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 90),
    ]);
  }

  test_FfiNativeWrongFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<IntPtr Function(IntPtr)>('doesntmatter')
external double wrongFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 94),
    ]);
  }
}

@reflectiveTest
class NativeTest extends PubPackageResolutionTest {
  test_annotation_Native_getters() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

class NativeFieldWrapperClass1 {}

class Paragraph extends NativeFieldWrapperClass1 {
  @Native<Double Function(Pointer<Void>)>(isLeaf: true)
  external double get ideographicBaseline;

  @Native<Void Function(Pointer<Void>, Double)>(isLeaf: true)
  external set ideographicBaseline(double d);
}
''');
  }

  test_annotation_Native_noArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native
external int foo();
''', [
      error(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, 20, 7),
    ]);
  }

  test_NativeCanUseHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function(Handle)>()
external Object doesntMatter(Object);
''', []);
  }

  test_NativeCanUseLeaf() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64)>(isLeaf:true)
external int doesntMatter(int x);
''', []);
  }

  test_NativeInstanceMethodsMustHaveReceiver() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class K {
  @Native<Void Function(Double)>()
  external void doesntMatter(double x);
}
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
          31, 72),
    ]);
  }

  test_NativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function()>(isLeaf:true)
external Object doesntMatter();
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 19, 71),
    ]);
  }

  test_NativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 19, 105),
    ]);
  }

  test_NativeNonFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(int)>()
external int nonFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 19, 68),
    ]);
  }

  test_NativeNonFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<double Function(IntPtr)>()
external double nonFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 19, 75),
    ]);
  }

  test_NativePointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Pointer)>()
external void free(Pointer pointer);
''');
  }

  test_NativeTooFewParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Double)>()
external void doesntMatter(double x, double y);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 19, 80),
    ]);
  }

  test_NativeTooManyParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Double, Double)>()
external void doesntMatter(double x);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 19, 78),
    ]);
  }

  test_NativeVoidReturn() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function(Uint32, Uint32, Handle)>()
external void voidReturn(int width, int height, Object outImage);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 116),
    ]);
  }

  test_NativeWrongFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(Double)>()
external int wrongFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 73),
    ]);
  }

  test_NativeWrongFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>()
external double wrongFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 77),
    ]);
  }
}
