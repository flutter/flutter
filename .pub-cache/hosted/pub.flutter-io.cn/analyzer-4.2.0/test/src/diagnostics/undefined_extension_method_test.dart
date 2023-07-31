// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionMethodTest);
  });
}

@reflectiveTest
class UndefinedExtensionMethodTest extends PubPackageResolutionTest {
  test_method_defined() async {
    await assertNoErrorsInCode('''
extension E on String {
  int m() => 0;
}
f() {
  E('a').m();
}
''');
  }

  test_method_undefined() async {
    await assertErrorsInCode('''
extension E on String {}
f() {
  E('a').m();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD, 40, 1),
    ]);

    var node = findNode.methodInvocation('m();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleStringLiteral
          literal: 'a'
      rightParenthesis: )
    extendedType: String
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_static_withInference() async {
    await assertErrorsInCode('''
extension E on Object {}
var a = E.m();
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD, 35, 1),
    ]);
  }

  test_static_withoutInference() async {
    await assertErrorsInCode('''
extension E on Object {}
void f() {
  E.m();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD, 40, 1),
    ]);
  }
}
