// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFieldTypeInStructTest);
  });
}

@reflectiveTest
class InvalidFieldTypeInStructTest extends PubPackageResolutionTest {
  // TODO(https://dartbug.com/44677): Remove Pointer notEmpty field.
  test_instance_invalid() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  external String str;

  external Pointer notEmpty;
}
''', [
      error(FfiCode.INVALID_FIELD_TYPE_IN_STRUCT, 55, 6),
    ]);
  }

  // TODO(https://dartbug.com/44677): Remove Pointer notEmpty field.
  test_instance_invalid2() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Union {
  external String str;

  external Pointer notEmpty;
}
''', [
      error(FfiCode.INVALID_FIELD_TYPE_IN_STRUCT, 54, 6),
    ]);
  }

  test_instance_valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  external Pointer p;
}
''');
  }

  test_static() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  static String? str;

  external Pointer notEmpty;
}
''');
  }
}
