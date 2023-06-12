// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypeNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypeNameTest extends PubPackageResolutionTest {
  test_class_as() async {
    await assertErrorsInCode('''
class as {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 2),
    ]);
  }

  test_class_Function() async {
    await assertErrorsInCode('''
class Function {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 8),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode('''
enum as {
  v
}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 5, 2),
    ]);
  }

  test_mixin_as() async {
    await assertErrorsInCode('''
mixin as {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 2),
    ]);
  }

  test_mixin_Function() async {
    await assertErrorsInCode('''
mixin Function {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 8),
    ]);
  }

  test_mixin_OK_on() async {
    await assertNoErrorsInCode(r'''
class A {}

mixin on on A {}

mixin M on on {}

mixin M2 implements on {}

class B = A with on;
class C = B with M;
class D = Object with M2;
''');
  }
}
