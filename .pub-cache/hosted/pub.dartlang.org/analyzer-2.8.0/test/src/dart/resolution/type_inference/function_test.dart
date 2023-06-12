// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTest);
  });
}

@reflectiveTest
class FunctionTest extends PubPackageResolutionTest {
  test_genericFunction_upwards() async {
    await assertNoErrorsInCode('''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2);
}
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo('),
      ['int'],
    );
  }

  test_genericFunction_upwards_missingRequiredArgument() async {
    await assertErrorsInCode('''
void foo<T>({required T x, required T y}) {}

f() {
  foo(x: 1);
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 54, 3),
    ]);
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo('),
      ['int'],
    );
  }

  test_genericFunction_upwards_notEnoughPositionalArguments() async {
    await assertErrorsInCode('''
void foo<T>(T x, T y) {}

f() {
  foo(1);
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 37, 3),
    ]);
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo('),
      ['int'],
    );
  }

  test_genericFunction_upwards_tooManyPositionalArguments() async {
    await assertErrorsInCode('''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2, 3);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 44, 1),
    ]);
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo('),
      ['int'],
    );
  }

  test_genericFunction_upwards_undefinedNamedParameter() async {
    await assertErrorsInCode('''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2, z: 3);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 44, 1),
    ]);
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo('),
      ['int'],
    );
  }
}
