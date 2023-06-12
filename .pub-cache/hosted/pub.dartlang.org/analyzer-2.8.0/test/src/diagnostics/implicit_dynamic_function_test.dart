// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitDynamicFunctionTest);
    defineReflectiveTests(ImplicitDynamicFunctionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ImplicitDynamicFunctionTest extends PubPackageResolutionTest
    with ImplicitDynamicFunctionTestCases {}

mixin ImplicitDynamicFunctionTestCases on PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(implicitDynamic: false),
    );
  }

  test_local_downwardInferenceGivesInt() async {
    await assertNoErrorsInCode('''
void f(int d) {
  T g<T>() => throw 'x';
  d = g();
}
''');
  }

  test_local_noDownwardsInference() async {
    await assertErrorsInCode('''
void f(dynamic d) {
  T a<T>() => throw 'x';
  d = a();
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 51, 1),
    ]);
  }

  test_local_noInference() async {
    await assertErrorsInCode('''
void f(dynamic d) {
  void a<T>() {};
  a();
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 40, 1),
    ]);
  }

  test_local_upwardsInferenceGivesDynamic() async {
    await assertErrorsInCode('''
void f(dynamic d) {
  void a<T>(T t) {};
  a(d);
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 43, 1),
    ]);
  }

  test_local_upwardsInferenceGivesInt() async {
    await assertNoErrorsInCode('''
void f() {
  void a<T>(T t) {};
  a(42);
}
''');
  }

  test_topLevel_downwardInferenceGivesDynamic() async {
    await assertErrorsInCode('''
external T a<T>();

void f(dynamic d) {
  d = a();
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 46, 1),
    ]);
  }

  test_topLevel_downwardInferenceGivesInt() async {
    await assertNoErrorsInCode('''
external T a<T>();

void f(int d) {
  d = a();
}
''');
  }

  test_topLevel_dynamicAssignmentToTypeVariable() async {
    await assertErrorsInCode('''
T a<T>(T t) => t;

void f(dynamic d) {
  a(d);
  a(42);
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 41, 1),
    ]);
  }

  test_topLevel_intAssignmentToTypeVariable() async {
    await assertNoErrorsInCode('''
T a<T>(T t) => t;

void f() {
  a(42);
}
''');
  }

  test_topLevel_noInference() async {
    await assertErrorsInCode('''
void a<T>() {}

void f() {
  a();
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 29, 1),
    ]);
  }
}

@reflectiveTest
class ImplicitDynamicFunctionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ImplicitDynamicFunctionTestCases, WithoutNullSafetyMixin {}
