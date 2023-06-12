// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainHasRequiredNamedParametersTest);
    defineReflectiveTests(MainHasRequiredNamedParametersWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MainHasRequiredNamedParametersTest extends PubPackageResolutionTest
    with MainHasRequiredNamedParametersTestCases {
  test_namedRequired() async {
    await assertErrorsInCode('''
void main({required List<String> a}) {}
''', [
      error(CompileTimeErrorCode.MAIN_HAS_REQUIRED_NAMED_PARAMETERS, 5, 4),
    ]);
  }
}

mixin MainHasRequiredNamedParametersTestCases on PubPackageResolutionTest {
  test_namedOptional() async {
    await resolveTestCode('''
void main({int a = 0}) {}
''');
    assertNoErrorsInResult();
  }
}

@reflectiveTest
class MainHasRequiredNamedParametersWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, MainHasRequiredNamedParametersTestCases {}
