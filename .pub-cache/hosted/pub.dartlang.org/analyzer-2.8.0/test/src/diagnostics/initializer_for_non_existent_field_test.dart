// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializerForNonExistentFieldTest);
  });
}

@reflectiveTest
class InitializerForNonExistentFieldTest extends PubPackageResolutionTest {
  test_const() async {
    // Check that the absence of a matching field doesn't cause a
    // crash during constant evaluation.
    await assertErrorsInCode(r'''
class A {
  const A() : x = 'foo';
}
A a = const A();
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 24, 9,
          messageContains: ["'x'"]),
    ]);
  }

  test_getter() async {
    await assertErrorsInCode('''
class A {
  int get x => 0;
  A() : x = 0;
}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 36, 5,
          messageContains: ["'x'"]),
    ]);
  }

  test_initializer() async {
    await assertErrorsInCode(r'''
class A {
  A() : x = 0 {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);
  }
}
