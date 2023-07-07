// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnInGenerativeConstructorTest);
  });
}

@reflectiveTest
class ReturnInGenerativeConstructorTest extends PubPackageResolutionTest {
  test_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  A() { return 0; }
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, 25, 1),
    ]);
  }

  test_expressionFunctionBody() async {
    await assertErrorsInCode(r'''
class A {
  A() => A();
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, 16, 7),
    ]);
  }

  test_return_without_value() async {
    await assertNoErrorsInCode(r'''
class A {
  A() { return; }
}
''');
  }
}
