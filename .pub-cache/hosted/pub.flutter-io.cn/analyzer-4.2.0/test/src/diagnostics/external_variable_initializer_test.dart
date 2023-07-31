// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExternalVariableInitializerTest);
  });
}

@reflectiveTest
class ExternalVariableInitializerTest extends PubPackageResolutionTest {
  test_external_variable_final_initializer() async {
    await assertErrorsInCode('''
external final int x = 0;
''', [
      error(CompileTimeErrorCode.EXTERNAL_VARIABLE_INITIALIZER, 19, 1),
    ]);
  }

  test_external_variable_final_no_initializer() async {
    await assertNoErrorsInCode('''
external final int x;
''');
  }

  test_external_variable_initializer() async {
    await assertErrorsInCode('''
external int x = 0;
''', [
      error(CompileTimeErrorCode.EXTERNAL_VARIABLE_INITIALIZER, 13, 1),
    ]);
  }

  test_external_variable_no_initializer() async {
    await assertNoErrorsInCode('''
external int x;
''');
  }
}
