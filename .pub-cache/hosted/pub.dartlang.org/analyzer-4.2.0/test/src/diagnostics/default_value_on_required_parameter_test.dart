// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueOnRequiredParameterTest);
  });
}

@reflectiveTest
class DefaultValueOnRequiredParameterTest extends PubPackageResolutionTest {
  test_function_notRequired_default() async {
    await assertNoErrorsInCode('''
void log({String message: 'no message'}) {}
''');
  }

  test_function_notRequired_noDefault() async {
    await assertNoErrorsInCode('''
void log({String? message}) {}
''');
  }

  test_function_required_default() async {
    await assertErrorsInCode('''
void log({required String? message: 'no message'}) {}
''', [
      error(CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER, 27, 7),
    ]);
  }

  test_function_required_noDefault() async {
    await assertNoErrorsInCode('''
void log({required String message}) {}
''');
  }

  test_method_abstract_required_default() async {
    await assertErrorsInCode('''
abstract class C {
  void foo({required int? a = 0});
}
''', [
      error(CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER, 45, 1),
    ]);
  }

  test_method_required_default() async {
    await assertErrorsInCode('''
class C {
  void foo({required int? a = 0}) {}
}
''', [
      error(CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER, 36, 1),
    ]);
  }
}
