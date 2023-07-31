// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SizeAnnotationDimensions);
  });
}

@reflectiveTest
class SizeAnnotationDimensions extends PubPackageResolutionTest {
  test_error_array_2_3() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class C extends Struct {
  @Array(8, 8)
  external Array<Array<Array<Uint8>>> a0;
}
''', [
      error(FfiCode.SIZE_ANNOTATION_DIMENSIONS, 47, 12),
    ]);
  }

  test_error_array_3_2() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class C extends Struct {
  @Array(8, 8, 8)
  external Array<Array<Uint8>> a0;
}
''', [
      error(FfiCode.SIZE_ANNOTATION_DIMENSIONS, 47, 15),
    ]);
  }

  test_error_multi_2_3() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class C extends Struct {
  @Array.multi([8, 8])
  external Array<Array<Array<Uint8>>> a0;
}
''', [
      error(FfiCode.SIZE_ANNOTATION_DIMENSIONS, 47, 20),
    ]);
  }

  test_no_error() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

class C extends Struct {
  @Array(8, 8)
  external Array<Array<Uint8>> a0;
}
''');
  }
}
