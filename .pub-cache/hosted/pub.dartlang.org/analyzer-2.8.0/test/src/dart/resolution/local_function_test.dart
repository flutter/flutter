// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalFunctionResolutionTest);
  });
}

@reflectiveTest
class LocalFunctionResolutionTest extends PubPackageResolutionTest {
  test_element_block() async {
    await assertNoErrorsInCode(r'''
f() {
  g() {}
  g();
}
''');
    var element = findElement.localFunction('g');
    expect(element.name, 'g');
    expect(element.nameOffset, 8);

    assertElement(findNode.methodInvocation('g();'), element);
  }

  test_element_ifStatement() async {
    await assertErrorsInCode(r'''
f() {
  if (1 > 2)
    g() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 23, 1),
    ]);
    var node = findNode.functionDeclaration('g() {}');
    var element = node.declaredElement!;
    expect(element.name, 'g');
    expect(element.nameOffset, 23);
  }

  test_element_switchCase() async {
    await assertNoErrorsInCode(r'''
f(int a) {
  switch (a) {
    case 1:
      g() {}
      g();
      break;
  }
}
''');
    var element = findElement.localFunction('g');
    expect(element.name, 'g');
    expect(element.nameOffset, 44);

    assertElement(findNode.methodInvocation('g();'), element);
  }
}
