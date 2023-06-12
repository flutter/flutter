// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackedAnnotationNestingNonPacked);
  });
}

@reflectiveTest
class PackedAnnotationNestingNonPacked extends PubPackageResolutionTest {
  test_error_1() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class TestStruct1603 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(1)
class TestStruct1603Packed extends Struct {
  external Pointer<Uint8> notEmpty;

  external TestStruct1603 nestedNotPacked;
}
''', [
      error(FfiCode.PACKED_NESTING_NON_PACKED, 200, 14),
    ]);
  }

  test_error_2() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Packed(8)
class TestStruct1604 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(1)
class TestStruct1604Packed extends Struct {
  external Pointer<Uint8> notEmpty;

  external TestStruct1604 nestedLooselyPacked;
}
''', [
      error(FfiCode.PACKED_NESTING_NON_PACKED, 211, 14),
    ]);
  }

  test_error_3() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class TestStruct1603 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(1)
class TestStruct1605Packed extends Struct {
  external Pointer<Uint8> notEmpty;

  @Array(2)
  external Array<TestStruct1603> nestedNotPacked;
}
''', [
      error(FfiCode.PACKED_NESTING_NON_PACKED, 212, 21),
    ]);
  }

  test_error_4() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Packed(8)
class TestStruct1604 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(1)
class TestStruct1606Packed extends Struct {
  external Pointer<Uint8> notEmpty;

  @Array(2)
  external Array<TestStruct1604> nestedLooselyPacked;
}
''', [
      error(FfiCode.PACKED_NESTING_NON_PACKED, 223, 21),
    ]);
  }

  test_no_error() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
class TestStruct1604 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(1)
class TestStruct1606Packed extends Struct {
  external Pointer<Uint8> notEmpty;

  @Array(2)
  external Array<TestStruct1604> nestedLooselyPacked;
}
''');
  }
}
