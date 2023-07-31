// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnGenericInvocationTest);
  });
}

/// Tests of HintCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnGenericInvocationTest extends PubPackageResolutionTest {
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

  test_genericFunctionExpression_downwardsInference() async {
    await assertNoErrorsInCode('''
int f(T Function<T>()? m, T Function<T>() n) {
  return (m ?? n)();
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

  test_genericFunctionExpression_noInference() async {
    await assertErrorsInCode('''
void f(void Function<T>()? m, void Function<T>() n) {
  (m ?? n)();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION, 56, 8),
    ]);
  }

  test_genericFunctionExpression_upwardsInference() async {
    await assertNoErrorsInCode('''
void f(void Function<T>(T a)? m, void Function<T>(T a) n) {
  (m ?? n)(1);
}
''');
  }

  test_genericFunctionExpressionLiteral_noInference() async {
    await assertErrorsInCode('''
void f() {
  (<T>() {})();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION, 13, 10),
    ]);
  }
}
