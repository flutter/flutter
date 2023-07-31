// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationOnPointerFieldTest);
  });
}

@reflectiveTest
class AnnotationOnPointerFieldTest extends PubPackageResolutionTest {
  test_double() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  @Double()
  external Pointer<Int8> x;
}
''', [
      error(FfiCode.ANNOTATION_ON_POINTER_FIELD, 46, 9),
    ]);
  }

  test_int32() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  @Int32()
  external Pointer<Float> x;
}
''', [
      error(FfiCode.ANNOTATION_ON_POINTER_FIELD, 46, 8),
    ]);
  }
}
