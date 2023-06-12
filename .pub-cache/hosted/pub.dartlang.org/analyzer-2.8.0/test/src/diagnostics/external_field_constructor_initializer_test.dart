// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExternalFieldConstructorInitializerTest);
  });
}

@reflectiveTest
class ExternalFieldConstructorInitializerTest extends PubPackageResolutionTest {
  test_external_field_constructor_initializer() async {
    await assertErrorsInCode('''
class A {
  external int x;
  A() : x = 0;
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER, 36, 1),
    ]);
  }

  test_external_field_final_constructor_initializer() async {
    await assertErrorsInCode('''
class A {
  external final int x;
  A() : x = 0;
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER, 42, 1),
    ]);
  }

  test_external_field_final_initializing_formal() async {
    await assertErrorsInCode('''
class A {
  external final int x;
  A(this.x);
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER, 43, 1),
    ]);
  }

  test_external_field_final_no_initialization() async {
    await assertNoErrorsInCode('''
class A {
  external final int x;
  A();
}
''');
  }

  test_external_field_initializing_formal() async {
    await assertErrorsInCode('''
class A {
  external int x;
  A(this.x);
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER, 37, 1),
    ]);
  }

  test_external_field_no_initialization() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
  A();
}
''');
  }
}
