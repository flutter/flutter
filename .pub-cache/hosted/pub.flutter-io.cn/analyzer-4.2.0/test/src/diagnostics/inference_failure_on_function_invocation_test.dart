// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnFunctionInvocationTest);
  });
}

/// Tests of HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnFunctionInvocationTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
    );
    writeTestPackageConfigWithMeta();
  }

  test_functionType_noInference() async {
    await assertErrorsInCode('''
void f(void Function<T>() m) {
  m();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 33, 1),
    ]);
  }

  test_functionType_notGeneric() async {
    await assertNoErrorsInCode('''
void f(void Function() m) {
  m();
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_functionType_optionalTypeArgs() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
void f(@optionalTypeArgs void Function<T>() m) {
  m();
}
''');
  }

  test_genericFunctionExpression_explicitTypeArg() async {
    await assertNoErrorsInCode('''
void f(void Function<T>()? m, void Function<T>() n) {
  (m ?? n)<int>();
}
''');
  }

  test_genericMethod_downwardsInference() async {
    await assertNoErrorsInCode('''
abstract class C {
  T m<T>();
}

int f(C c) {
  return c.m();
}
''');
  }

  test_genericMethod_explicitTypeArgs() async {
    await assertNoErrorsInCode('''
abstract class C {
  void m<T>();
}

void f(C c) {
  c.m<int>();
}
''');
  }

  test_genericMethod_immediatelyCast() async {
    await assertNoErrorsInCode('''
abstract class C {
  T m<T>();
}

void f(C c) {
  c.m() as int;
}
''');
  }

  test_genericMethod_noInference() async {
    await assertErrorsInCode('''
abstract class C {
  void m<T>();
}

void f(C c) {
  c.m();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 55, 1),
    ]);
  }

  test_genericMethod_optionalTypeArgs() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
abstract class C {
  @optionalTypeArgs
  void m<T>();
}

void f(C c) {
  c.m();
}
''');
  }

  test_genericMethod_upwardsInference() async {
    await assertNoErrorsInCode('''
abstract class C {
  void m<T>(T a);
}

void f(C c) {
  c.m(7);
}
''');
  }

  test_genericStaticMethod_noInference() async {
    await assertErrorsInCode('''
class C {
  static void m<T>() {}
}

void f() {
  C.m();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 52, 1),
    ]);
  }

  test_genericTypedef_noInference() async {
    await assertErrorsInCode('''
typedef Fn = void Function<T>();
void g(Fn fn) {
  fn();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 51, 2),
    ]);
  }

  test_genericTypedef_optionalTypeArgs() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
@optionalTypeArgs
typedef Fn = void Function<T>();
void g(Fn fn) {
  fn();
}
''');
  }

  test_localFunction_noInference() async {
    await assertErrorsInCode('''
void f() {
  void g<T>() {}
  g();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 30, 1),
    ]);
  }

  test_localFunctionVariable_noInference() async {
    await assertErrorsInCode('''
void f() {
  var m = <T>() {};
  m();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 33, 1),
    ]);
  }

  test_nonGenericMethod() async {
    await assertNoErrorsInCode('''
abstract class C {
  void m();
}

void f(C c) {
  c.m();
}
''');
  }

  test_topLevelFunction_noInference() async {
    await assertErrorsInCode('''
void f<T>() {}

void g() {
  f();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 29, 1),
    ]);
  }

  test_topLevelFunction_withImportPrefix_noInference() async {
    newFile('$testPackageLibPath/a.dart', '''
void f<T>() {}
''');
    await assertErrorsInCode('''
import 'a.dart' as a;
void g() {
  a.f();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, 37, 1),
    ]);
  }

  test_topLevelFunction_withImportPrefix_optionalTypeArgs() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';
@optionalTypeArgs
void f<T>() {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
void g() {
  a.f();
}
''');
  }
}
