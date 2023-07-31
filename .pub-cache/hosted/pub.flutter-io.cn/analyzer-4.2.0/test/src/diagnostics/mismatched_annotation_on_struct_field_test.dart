// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MismatchedAnnotationOnStructFieldTest);
  });
}

@reflectiveTest
class MismatchedAnnotationOnStructFieldTest extends PubPackageResolutionTest {
  test_double_on_int() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  @Double()
  external int x;
}
''', [
      error(FfiCode.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD, 46, 9),
    ]);
  }

  test_int32_on_double() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  @Int32()
  external double x;
}
''', [
      error(FfiCode.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD, 46, 8),
    ]);
  }
}
