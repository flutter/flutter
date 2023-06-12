// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.g.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfCovariantTest);
  });
}

@reflectiveTest
class InvalidUseOfCovariantTest extends PubPackageResolutionTest {
  test_functionExpression() async {
    await assertErrorsInCode('''
Function f = (covariant int x) {};
''', [
      error(CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, 14, 9),
    ]);
  }

  test_functionType_inFunctionTypedParameterOfInstanceMethod() async {
    await assertErrorsInCode('''
class C {
  void m(void p(covariant int)) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, 26, 9),
    ]);
  }

  test_functionType_inParameterOfInstanceMethod() async {
    await assertErrorsInCode('''
class C {
  void m(void Function(covariant int) p) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, 33, 9),
    ]);
  }

  test_functionType_inTypeAlias() async {
    await assertErrorsInCode('''
typedef F = void Function(covariant int);
''', [
      error(CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, 26, 9),
    ]);
  }

  test_functionType_inTypeArgument() async {
    await assertErrorsInCode('''
List<void Function(covariant int)> a = [];
}
''', [
      error(CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, 19, 9),
      // TODO(srawlins): Recover better from this situation (`covariant` in
      // parameter in type argument).
      error(ParserErrorCode.EXPECTED_EXECUTABLE, 43, 1),
    ]);
  }

  test_functionType_inTypeParameterBound() async {
    await assertErrorsInCode('''
void foo<T extends void Function(covariant int)>() {}
}
''', [
      error(CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, 33, 9),
      // TODO(srawlins): Recover better from this situation (`covariant` in
      // parameter in bound).
      error(ParserErrorCode.EXPECTED_EXECUTABLE, 54, 1),
    ]);
  }

  test_localFunction() async {
    await assertErrorsInCode('''
void foo() {
  void f(covariant int x) {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 20, 1),
      error(CompileTimeErrorCode.INVALID_USE_OF_COVARIANT, 22, 9),
    ]);
  }

  test_staticFunction() async {
    await assertErrorsInCode('''
class C {
  static void m(covariant int x) {}
}
''', [
      // INVALID_USE_OF_COVARIANT is not reported here; it would be redundant.
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 26, 9),
    ]);
  }

  test_staticFunction_onMixin() async {
    await assertErrorsInCode('''
mixin M {
  static void m(covariant int x) {}
}
''', [
      // INVALID_USE_OF_COVARIANT is not reported here; it would be redundant.
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 26, 9),
    ]);
  }

  test_topLevelFunction() async {
    await assertErrorsInCode('''
void f(covariant int x) {}
''', [
      // INVALID_USE_OF_COVARIANT is not reported here; it would be redundant.
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 7, 9),
    ]);
  }
}
