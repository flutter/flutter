// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationResolutionTest);
  });
}

@reflectiveTest
class FunctionDeclarationResolutionTest extends PubPackageResolutionTest {
  test_formalParameterScope_defaultValue() async {
    await assertNoErrorsInCode('''
const foo = 0;

void bar([int foo = foo + 1]) {
}
''');

    assertElement(
      findNode.simple('foo + 1'),
      findElement.topGet('foo'),
    );
  }

  test_formalParameterScope_type() async {
    await assertNoErrorsInCode('''
class a {}

void bar(a a) {
  a;
}
''');

    assertElement(
      findNode.simple('a a'),
      findElement.class_('a'),
    );

    assertElement(
      findNode.simple('a;'),
      findElement.parameter('a'),
    );
  }
}
