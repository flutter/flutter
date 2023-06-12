// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitDynamicMapLiteralTest);
    defineReflectiveTests(ImplicitDynamicMapLiteralWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ImplicitDynamicMapLiteralTest extends PubPackageResolutionTest
    with ImplicitDynamicMapLiteralTestCases {}

mixin ImplicitDynamicMapLiteralTestCases on PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(implicitDynamic: false),
    );
  }

  test_assignedToMapWithExplicitTypeArguments_dynamic() async {
    await assertErrorsInCode('''
Map<dynamic, dynamic> a = {};
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 26, 2),
    ]);
  }

  test_assignedToMapWithExplicitTypeArguments_int() async {
    await assertNoErrorsInCode('''
Map<int, int> a = {};
''');
  }

  test_assignedToRawMap() async {
    await assertErrorsInCode('''
Map a = {};
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 8, 2),
    ]);
  }

  test_assignedToVar_empty() async {
    await assertErrorsInCode('''
var a = {};
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 8, 2),
    ]);
  }

  test_assignedToVar_nonDynamicElements() async {
    await assertNoErrorsInCode('''
var a = {0: 1};
''');
  }

  test_dynamicKey() async {
    await assertErrorsInCode('''
dynamic d = 1;
var a = {d: 'x'};
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 23, 8),
    ]);
  }

  test_dynamicValue() async {
    await assertErrorsInCode('''
dynamic d = 1;
var a = {'x': d};
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 23, 8),
    ]);
  }

  test_explicitTypeArguments_dynamic() async {
    await assertNoErrorsInCode('''
var a = <dynamic, dynamic>{};
''');
  }

  test_explicitTypeArguments_int() async {
    await assertNoErrorsInCode('''
var a = <int, int>{};
''');
  }
}

@reflectiveTest
class ImplicitDynamicMapLiteralWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ImplicitDynamicMapLiteralTestCases, WithoutNullSafetyMixin {}
