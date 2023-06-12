// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldMustBeExternalInStructTest);
    defineReflectiveTests(FieldMustBeExternalInStructWithoutNullSafetyTest);
  });
}

@reflectiveTest
class FieldMustBeExternalInStructTest extends PubPackageResolutionTest
    with FieldMustBeExternalInStructTestCases {}

mixin FieldMustBeExternalInStructTestCases on PubPackageResolutionTest {
  test_struct() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(FfiCode.FIELD_MUST_BE_EXTERNAL_IN_STRUCT, 62, 1),
    ], legacy: []);
    await assertErrorsInCode(r'''
import 'dart:ffi';

class A extends Struct {
  @Int16()
  int a;
}
''', expectedErrors);
  }

  test_union() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(FfiCode.FIELD_MUST_BE_EXTERNAL_IN_STRUCT, 61, 1),
    ], legacy: []);
    await assertErrorsInCode(r'''
import 'dart:ffi';

class A extends Union {
  @Int16()
  int a;
}
''', expectedErrors);
  }
}

@reflectiveTest
class FieldMustBeExternalInStructWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, FieldMustBeExternalInStructTestCases {}
