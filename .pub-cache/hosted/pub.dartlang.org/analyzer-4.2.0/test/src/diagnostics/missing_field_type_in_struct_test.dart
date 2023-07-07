// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingFieldTypeInStructTest);
  });
}

@reflectiveTest
class MissingFieldTypeInStructTest extends PubPackageResolutionTest {
  test_missing() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  external var str;

  external Pointer notEmpty;
}
''', [
      error(FfiCode.MISSING_FIELD_TYPE_IN_STRUCT, 59, 3),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  external Pointer p;
}
''');
  }
}
