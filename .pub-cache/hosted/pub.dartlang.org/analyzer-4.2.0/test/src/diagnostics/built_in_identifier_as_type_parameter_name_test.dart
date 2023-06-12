// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypeParameterNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypeParameterNameTest
    extends PubPackageResolutionTest {
  test_class_as() async {
    await assertErrorsInCode('''
class A<as> {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME, 8,
          2),
    ]);
  }

  test_class_Function() async {
    await assertErrorsInCode('''
class A<Function> {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME, 8,
          8),
    ]);
  }

  test_extension_as() async {
    await assertErrorsInCode('''
extension <as> on List {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME, 11,
          2),
    ]);
  }

  test_function_as() async {
    await assertErrorsInCode('''
void f<as>() {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME, 7,
          2),
    ]);
  }
}
