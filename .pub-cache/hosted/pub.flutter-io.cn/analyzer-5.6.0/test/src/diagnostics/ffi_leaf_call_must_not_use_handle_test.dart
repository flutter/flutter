// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LeafCallMustNotUseHandle);
  });
}

@reflectiveTest
class LeafCallMustNotUseHandle extends PubPackageResolutionTest {
  test_AsFunctionReturnsHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef NativeReturnsHandle = Handle Function();
typedef ReturnsHandle = Object Function();
doThings() {
  Pointer<NativeFunction<NativeReturnsHandle>> p = Pointer.fromAddress(1337);
  ReturnsHandle f = p.asFunction(isLeaf:true);
  f();
}
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 222, 25),
    ]);
  }

  test_AsFunctionTakesHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef NativeTakesHandle = Void Function(Handle);
typedef TakesHandle = void Function(Object);
class MyClass {}
doThings() {
  Pointer<NativeFunction<NativeTakesHandle>> p = Pointer.fromAddress(1337);
  TakesHandle f = p.asFunction(isLeaf:true);
  f(MyClass());
}
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 239, 25),
    ]);
  }

  test_class_getter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class NativeFieldWrapperClass1 {}

class A extends NativeFieldWrapperClass1 {
  @FfiNative<Handle Function(Pointer<Void>)>('foo', isLeaf:true)
  external Object get foo;
}
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 100, 89),
    ]);
  }

  test_LookupFunctionReturnsHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef NativeReturnsHandle = Handle Function();
typedef ReturnsHandle = Object Function();
doThings() {
  DynamicLibrary l = DynamicLibrary.open("my_lib");
  l.lookupFunction<NativeReturnsHandle, ReturnsHandle>("timesFour", isLeaf:true);
}
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 195, 19),
    ]);
  }

  test_LookupFunctionTakesHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef NativeTakesHandle = Void Function(Handle);
typedef TakesHandle = void Function(Object);
class MyClass {}
doThings() {
  DynamicLibrary l = DynamicLibrary.open("my_lib");
  l.lookupFunction<NativeTakesHandle, TakesHandle>("timesFour", isLeaf:true);
}
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 216, 17),
    ]);
  }

  test_unit_getter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@FfiNative<Handle Function()>('foo', isLeaf:true)
external Object get foo;
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 20, 74),
    ]);
  }
}
