// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainFirstPositionalParameterTest);
    defineReflectiveTests(MainFirstPositionalParameterWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MainFirstPositionalParameterTest extends PubPackageResolutionTest
    with MainFirstPositionalParameterTestCases {
  test_positionalRequired_listOfStringQuestion() async {
    await assertNoErrorsInCode('''
void main(List<String?> args) {}
''');
  }

  test_positionalRequired_listQuestionOfString() async {
    await assertNoErrorsInCode('''
void main(List<String>? args) {}
''');
  }

  test_positionalRequired_objectQuestion() async {
    await assertNoErrorsInCode('''
void main(Object? args) {}
''');
  }
}

mixin MainFirstPositionalParameterTestCases on PubPackageResolutionTest {
  test_positionalOptional_listOfInt() async {
    await resolveTestCode('''
void main([List<int> args = const []]) {}
''');
    assertErrorsInResult(expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.MAIN_FIRST_POSITIONAL_PARAMETER_TYPE, 11, 9),
    ], legacy: []));
  }

  test_positionalRequired_dynamic() async {
    await assertNoErrorsInCode('''
void main(dynamic args) {}
''');
  }

  test_positionalRequired_functionTypedFormal() async {
    await resolveTestCode('''
void main(void args()) {}
''');
    assertErrorsInResult(expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.MAIN_FIRST_POSITIONAL_PARAMETER_TYPE, 10, 11),
    ], legacy: []));
  }

  test_positionalRequired_iterableOfString() async {
    await assertNoErrorsInCode('''
void main(Iterable<String> args) {}
''');
  }

  test_positionalRequired_listOfInt() async {
    await resolveTestCode('''
void main(List<int> args) {}
''');
    assertErrorsInResult(expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.MAIN_FIRST_POSITIONAL_PARAMETER_TYPE, 10, 9),
    ], legacy: []));
  }

  test_positionalRequired_listOfString() async {
    await assertNoErrorsInCode('''
void main(List<String> args) {}
''');
  }

  test_positionalRequired_object() async {
    await assertNoErrorsInCode('''
void main(Object args) {}
''');
  }
}

@reflectiveTest
class MainFirstPositionalParameterWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, MainFirstPositionalParameterTestCases {}
