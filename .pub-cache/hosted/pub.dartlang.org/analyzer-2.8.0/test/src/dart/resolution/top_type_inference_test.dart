// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopTypeInferenceDriverResolutionTest);
  });
}

@reflectiveTest
class TopTypeInferenceDriverResolutionTest extends PubPackageResolutionTest {
  test_referenceInstanceVariable_withDeclaredType() async {
    await assertNoErrorsInCode(r'''
class A {
  final int a = b + 1;
}
final b = new A().a;
''');

    assertType(findElement.field('a').type, 'int');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_referenceInstanceVariable_withoutDeclaredType() async {
    await assertErrorsInCode(r'''
class A {
  final a = b + 1;
}
final b = new A().a;
''', [
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 18, 1),
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 37, 1),
    ]);

    assertTypeDynamic(findElement.field('a').type);
    assertTypeDynamic(findElement.topVar('b').type);
  }
}
