// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackedAnnotationAlignment);
  });
}

@reflectiveTest
class PackedAnnotationAlignment extends PubPackageResolutionTest {
  test_error() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Packed(3)
class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''', [
      error(FfiCode.PACKED_ANNOTATION_ALIGNMENT, 28, 1),
    ]);
  }

  test_no_error() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }
}
