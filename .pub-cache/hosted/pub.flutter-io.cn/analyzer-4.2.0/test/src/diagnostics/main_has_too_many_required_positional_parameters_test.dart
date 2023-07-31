// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      MainHasTooManyRequiredPositionalParametersTest,
    );
    defineReflectiveTests(
      MainHasTooManyRequiredPositionalParametersWithoutNullSafetyTest,
    );
  });
}

@reflectiveTest
class MainHasTooManyRequiredPositionalParametersTest
    extends PubPackageResolutionTest
    with MainHasTooManyRequiredPositionalParametersTestCases {
  test_positionalRequired_3_namedRequired_1() async {
    await resolveTestCode('''
void main(args, int a, int b, {required int c}) {}
''');
    assertErrorsInResult(expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.MAIN_HAS_REQUIRED_NAMED_PARAMETERS, 5, 4),
      error(
          CompileTimeErrorCode.MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS,
          5,
          4),
    ], legacy: []));
  }
}

mixin MainHasTooManyRequiredPositionalParametersTestCases
    on PubPackageResolutionTest {
  test_namedOptional_1() async {
    await resolveTestCode('''
void main({int a = 0}) {}
''');
    assertNoErrorsInResult();
  }

  test_positionalOptional_1() async {
    await resolveTestCode('''
void f([int a = 0]) {}
''');
    assertNoErrorsInResult();
  }

  test_positionalRequired_0() async {
    await resolveTestCode('''
void main() {}
''');
    assertNoErrorsInResult();
  }

  test_positionalRequired_1() async {
    await resolveTestCode('''
void main(args) {}
''');
    assertNoErrorsInResult();
  }

  test_positionalRequired_2() async {
    await resolveTestCode('''
void main(args, int a) {}
''');
    assertNoErrorsInResult();
  }

  test_positionalRequired_2_positionalOptional_1() async {
    await resolveTestCode('''
void main(args, int a, [int b = 0]) {}
''');
    assertNoErrorsInResult();
  }

  test_positionalRequired_3() async {
    await resolveTestCode('''
void main(args, int a, int b) {}
''');
    assertErrorsInResult(expectedErrorsByNullability(nullable: [
      error(
          CompileTimeErrorCode.MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS,
          5,
          4),
    ], legacy: []));
  }

  test_positionalRequired_3_namedOptional_1() async {
    await resolveTestCode('''
void main(args, int a, int b, {int c = 0}) {}
''');
    assertErrorsInResult(expectedErrorsByNullability(nullable: [
      error(
          CompileTimeErrorCode.MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS,
          5,
          4),
    ], legacy: []));
  }
}

@reflectiveTest
class MainHasTooManyRequiredPositionalParametersWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        WithoutNullSafetyMixin,
        MainHasTooManyRequiredPositionalParametersTestCases {}
