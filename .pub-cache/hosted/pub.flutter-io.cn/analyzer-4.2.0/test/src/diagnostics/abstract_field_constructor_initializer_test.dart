// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractFieldConstructorInitializerTest);
  });
}

@reflectiveTest
class AbstractFieldConstructorInitializerTest extends PubPackageResolutionTest {
  test_abstract_field_constructor_initializer() async {
    await assertErrorsInCode('''
abstract class A {
  abstract int x;
  A() : x = 0;
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER, 45, 1),
    ]);
  }

  test_abstract_field_final_constructor_initializer() async {
    await assertErrorsInCode('''
abstract class A {
  abstract final int x;
  A() : x = 0;
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER, 51, 1),
    ]);
  }

  test_abstract_field_final_initializing_formal() async {
    await assertErrorsInCode('''
abstract class A {
  abstract final int x;
  A(this.x);
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER, 52, 1),
    ]);
  }

  test_abstract_field_final_no_initialization() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int x;
  A();
}
''');
  }

  test_abstract_field_initializing_formal() async {
    await assertErrorsInCode('''
abstract class A {
  abstract int x;
  A(this.x);
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER, 46, 1),
    ]);
  }

  test_abstract_field_no_initialization() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
  A();
}
''');
  }
}
