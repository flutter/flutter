// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitDynamicListLiteralTest);
    defineReflectiveTests(ImplicitDynamicListLiteralWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ImplicitDynamicListLiteralTest extends PubPackageResolutionTest
    with ImplicitDynamicListLiteralTestCases {}

mixin ImplicitDynamicListLiteralTestCases on PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(implicitDynamic: false),
    );
  }

  test_assignedToListWithExplicitTypeArgument_dynamic() async {
    await assertErrorsInCode('''
List<dynamic> a = [];
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 18, 2),
    ]);
  }

  test_assignedToListWithExplicitTypeArgument_int() async {
    await assertNoErrorsInCode('''
List<int> a = [];
''');
  }

  test_assignedToRawList() async {
    await assertErrorsInCode('''
List a = [];
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 9, 2),
    ]);
  }

  test_assignedToVar_empty() async {
    await assertErrorsInCode('''
var a = [];
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 8, 2),
    ]);
  }

  test_assignedToVar_nonDynamicElements() async {
    await assertNoErrorsInCode('''
var a = [42];
''');
  }

  test_dynamicElements() async {
    await assertErrorsInCode('''
void f(dynamic d) {
  [d, d];
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 22, 6),
    ]);
  }

  test_explicitTypeArgument_dynamic() async {
    await assertNoErrorsInCode('''
var a = <dynamic>[];
''');
  }

  test_explicitTypeArgument_int() async {
    await assertNoErrorsInCode('''
var a = <int>[];
''');
  }
}

@reflectiveTest
class ImplicitDynamicListLiteralWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ImplicitDynamicListLiteralTestCases, WithoutNullSafetyMixin {}
