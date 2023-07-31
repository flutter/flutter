// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackedAnnotation);
  });
}

@reflectiveTest
class PackedAnnotation extends PubPackageResolutionTest {
  test_error_double() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
@Packed(1)
class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''', [
      error(FfiCode.PACKED_ANNOTATION, 31, 10),
    ]);
  }

  /// Regress test for http://dartbug.com/45498.
  test_error_missing() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Packed()
class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''', [
      error(FfiCode.PACKED_ANNOTATION_ALIGNMENT, 20, 9),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          28, 1),
    ]);
  }

  test_no_error_struct_no_annotation() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  test_no_error_struct_one_annotation() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  /// Doesn't do anything on Unions.
  test_no_error_union_no_annotation() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

class C extends Union {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  /// Doesn't do anything on Unions.
  test_no_error_union_one_annotation() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
class C extends Union {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  /// Doesn't do anything on Unions.
  test_no_error_union_two_annotations() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
@Packed(1)
class C extends Union {
  external Pointer<Uint8> notEmpty;
}
''');
  }
}
