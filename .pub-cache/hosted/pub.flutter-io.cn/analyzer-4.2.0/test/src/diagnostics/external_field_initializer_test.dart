// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExternalFieldInitializerTest);
  });
}

@reflectiveTest
class ExternalFieldInitializerTest extends PubPackageResolutionTest {
  test_external_field_final_initializer() async {
    await assertErrorsInCode('''
class A {
  external final int x = 0;
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER, 31, 1),
    ]);
  }

  test_external_field_final_no_initializer() async {
    await assertNoErrorsInCode('''
class A {
  external final int x;
}
''');
  }

  test_external_field_initializer() async {
    await assertErrorsInCode('''
class A {
  external int x = 0;
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER, 25, 1),
    ]);
  }

  test_external_field_no_initializer() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
}
''');
  }

  test_external_static_field_final_initializer() async {
    await assertErrorsInCode('''
class A {
  external static final int x = 0;
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER, 38, 1),
    ]);
  }

  test_external_static_field_final_no_initializer() async {
    await assertNoErrorsInCode('''
class A {
  external static final int x;
}
''');
  }

  test_external_static_field_initializer() async {
    await assertErrorsInCode('''
class A {
  external static int x = 0;
}
''', [
      error(CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER, 32, 1),
    ]);
  }

  test_external_static_field_no_initializer() async {
    await assertNoErrorsInCode('''
class A {
  external static int x;
}
''');
  }
}
