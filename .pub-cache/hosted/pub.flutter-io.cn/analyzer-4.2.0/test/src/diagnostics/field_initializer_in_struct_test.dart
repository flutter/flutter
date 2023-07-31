// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerInStructTest);
  });
}

@reflectiveTest
class FieldInitializerInStructTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_fieldInitializer() async {
    await assertErrorsInCode('''
import 'dart:ffi';
class C extends Struct {
  @Int32() int f;
  C() : f = 0;
}
''', [
      error(FfiCode.FIELD_INITIALIZER_IN_STRUCT, 70, 5),
    ]);
  }

  test_fieldInitializer2() async {
    await assertErrorsInCode('''
import 'dart:ffi';
class C extends Union {
  @Int32() int f;
  C() : f = 0;
}
''', [
      error(FfiCode.FIELD_INITIALIZER_IN_STRUCT, 69, 5),
    ]);
  }

  test_superInitializer() async {
    await assertNoErrorsInCode('''
import 'dart:ffi';
class C extends Struct {
  @Int32() int f;
  C() : super();
}
''');
  }
}
