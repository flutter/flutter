// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachElementTest);
    defineReflectiveTests(ForLoopElementTest);
  });
}

@reflectiveTest
class ForEachElementTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A implements Iterable<int> {
  Iterator<int> iterator => throw 0;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {
  for (var v in a) {
    v;
  }
}
''');
  }

  test_withDeclaration_scope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i in [1, 2, 3]) i]; // 1
  <double>[for (var i in [1.1, 2.2, 3.3]) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.simple('i in [1, 2').staticElement,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.simple('i in [1.1').staticElement,
    );
  }

  test_withIdentifier_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
int v = 0;
main() {
  <int>[for (v in [1, 2, 3]) v];
}
''');
    assertElement(
      findNode.simple('v];'),
      findElement.topGet('v'),
    );
  }
}

@reflectiveTest
class ForLoopElementTest extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
f(bool Function() b) {
  <int>[for (; b(); ) 0];
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('b()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'bool Function()',
      type: 'bool',
    );
  }

  test_declaredVariableScope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i = 1; i < 10; i += 3) i]; // 1
  <double>[for (var i = 1.1; i < 10; i += 5) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.simple('i = 1;').staticElement,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.simple('i = 1.1;').staticElement,
    );
  }
}
