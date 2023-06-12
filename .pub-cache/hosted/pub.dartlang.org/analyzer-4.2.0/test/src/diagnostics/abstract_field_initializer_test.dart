// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractFieldInitializerTest);
  });
}

@reflectiveTest
class AbstractFieldInitializerTest extends PubPackageResolutionTest {
  test_abstract_field_final_initializer() async {
    await assertErrorsInCode('''
abstract class A {
  abstract final int x = 0;
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER, 40, 1),
    ]);
  }

  test_abstract_field_final_no_initializer() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int x;
}
''');
  }

  test_abstract_field_initializer() async {
    await assertErrorsInCode('''
abstract class A {
  abstract int x = 0;
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER, 34, 1),
    ]);
  }

  test_abstract_field_no_initializer() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
}
''');
  }
}
