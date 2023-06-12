// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInStructWithInitializerTest);
  });
}

@reflectiveTest
class FieldInStructWithInitializerTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_instance_withInitializer() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  Pointer p = nullptr;
}
''', [
      error(FfiCode.FIELD_IN_STRUCT_WITH_INITIALIZER, 54, 1),
    ]);
  }

  test_instance_withInitializer2() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Union {
  Pointer p = nullptr;
}
''', [
      error(FfiCode.FIELD_IN_STRUCT_WITH_INITIALIZER, 53, 1),
    ]);
  }

  test_instance_withoutInitializer() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  Pointer p;
}
''');
  }

  test_static_withInitializer() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  static String str = '';
  Pointer p;
}
''');
  }
}
