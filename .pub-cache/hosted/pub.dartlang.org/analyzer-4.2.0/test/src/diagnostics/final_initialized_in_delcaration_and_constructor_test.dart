// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalInitializedInDeclarationAndConstructorTest);
  });
}

@reflectiveTest
class FinalInitializedInDeclarationAndConstructorTest
    extends PubPackageResolutionTest {
  test_class_fieldFormalParameter() async {
    await assertErrorsInCode('''
class A {
  final x = 0;
  A(this.x) {}
}
''', [
      error(
          CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
          34,
          1),
    ]);
  }

  test_enum_fieldFormalParameter() async {
    await assertErrorsInCode('''
enum E {
  v(0);
  final x = 0;
  const E(this.x);
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 11, 4),
      error(
          CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
          47,
          1),
    ]);
  }
}
