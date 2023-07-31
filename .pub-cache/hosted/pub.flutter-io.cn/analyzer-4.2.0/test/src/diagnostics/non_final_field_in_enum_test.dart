// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonFinalFieldInEnumTest);
  });
}

@reflectiveTest
class NonFinalFieldInEnumTest extends PubPackageResolutionTest {
  test_instance_notFinal() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM, 20, 3),
    ]);
  }

  test_static_notFinal() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static int foo = 0;
}
''');
  }
}
