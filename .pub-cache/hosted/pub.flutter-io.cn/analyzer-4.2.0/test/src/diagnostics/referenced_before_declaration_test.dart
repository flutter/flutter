// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferencedBeforeDeclarationTest);
  });
}

@reflectiveTest
class ReferencedBeforeDeclarationTest extends PubPackageResolutionTest {
  test_cascade_after_declaration() async {
    await assertNoErrorsInCode(r'''
testRequestHandler() {}

main() {
  var s1 = null;
  testRequestHandler()
    ..stream(s1);
  var stream = 123;
  print(stream);
}
''');
  }

  test_hideInBlock_comment() async {
    await assertErrorsInCode(r'''
main() {
  /// [v] is a variable.
  var v = 2;
}
print(x) {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
    ]);
  }

  test_hideInBlock_function() async {
    await assertErrorsInCode(r'''
var v = 1;
main() {
  print(v);
  v() {}
}
print(x) {}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 28, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 34, 1)]),
    ]);
  }

  test_hideInBlock_local() async {
    await assertErrorsInCode(r'''
var v = 1;
main() {
  print(v);
  var v = 2;
}
print(x) {}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 28, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 38, 1)]),
    ]);
  }

  test_hideInBlock_local_subBlock() async {
    await assertErrorsInCode(r'''
var v = 1;
main() {
  {
    print(v);
  }
  var v = 2;
}
print(x) {}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 34, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 48, 1)]),
    ]);
  }

  test_hideInSwitchCase_function() async {
    await assertErrorsInCode(r'''
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
      void v() {}
  }
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 61, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 75, 1)]),
    ]);

    assertElement(findNode.simple('v;'), findElement.localFunction('v'));
  }

  test_hideInSwitchCase_local() async {
    await assertErrorsInCode(r'''
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
      var v = 1;
  }
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 61, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 74, 1)]),
    ]);

    assertElement(findNode.simple('v;'), findElement.localVar('v'));
  }

  test_hideInSwitchDefault_function() async {
    await assertErrorsInCode(r'''
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
      void v() {}
  }
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 62, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 76, 1)]),
    ]);

    assertElement(findNode.simple('v;'), findElement.localFunction('v'));
  }

  test_hideInSwitchDefault_local() async {
    await assertErrorsInCode(r'''
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
      var v = 1;
  }
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 62, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 75, 1)]),
    ]);

    assertElement(findNode.simple('v;'), findElement.localVar('v'));
  }

  test_inInitializer_closure() async {
    await assertErrorsInCode(r'''
main() {
  var v = () => v;
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 25, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 15, 1)]),
    ]);
  }

  test_inInitializer_directly() async {
    await assertErrorsInCode(r'''
main() {
  var v = v;
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 19, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 15, 1)]),
    ]);
  }

  test_labeledStatement_function() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_label
  label: void v() {}
  v;
}
''');

    assertElement(findNode.simple('v;'), findElement.localFunction('v'));
  }

  test_labeledStatement_local() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_label
  label: var v = 0;
  v;
}
''');

    assertElement(findNode.simple('v;'), findElement.localVar('v'));
  }

  test_type_localFunction() async {
    await assertErrorsInCode(r'''
void testTypeRef() {
  String s = '';
  int String(int x) => x + 1;
  print(s + String);
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 23, 6,
          contextMessages: [message('$testPackageLibPath/test.dart', 44, 6)]),
    ]);
  }

  test_type_localVariable() async {
    await assertErrorsInCode(r'''
void testTypeRef() {
  String s = '';
  var String = '';
  print(s + String);
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 23, 6,
          contextMessages: [message('$testPackageLibPath/test.dart', 44, 6)]),
    ]);
  }
}
