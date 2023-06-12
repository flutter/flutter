// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableResolutionTest);
  });
}

@reflectiveTest
class LocalVariableResolutionTest extends PubPackageResolutionTest {
  test_annotation_twoVariables() async {
    await assertNoErrorsInCode(r'''
const a = 0;

void f() {
  // ignore:unused_local_variable
  @a var x = 0, y = 0;
}
''');

    var x = findElement.localVar('x');
    assertElement2(
      x.metadata.single.element,
      declaration: findElement.topGet('a'),
    );

    var y = findElement.localVar('y');
    assertElement2(
      y.metadata.single.element,
      declaration: findElement.topGet('a'),
    );
  }

  test_demoteTypeParameterType() async {
    await assertNoErrorsInCode('''
void f<T>(T a, T b) {
  if (a is String) {
    var o = a;
    o = b;
    o; // ref
  }
}
''');

    assertType(findNode.simple('o; // ref'), 'T');
  }

  test_element_block() async {
    await assertErrorsInCode(r'''
void f() {
  int x = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);

    var x = findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_const() async {
    await assertErrorsInCode(r'''
void f() {
  const int x = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 23, 1),
    ]);

    var x = findElement.localVar('x');
    expect(x.isConst, isTrue);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_final() async {
    await assertErrorsInCode(r'''
void f() {
  final int x = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 23, 1),
    ]);

    var x = findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isTrue);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_ifStatement() async {
    await assertErrorsInCode(r'''
void f() {
  if (1 > 2)
    int x = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
    ]);

    var x = findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_late() async {
    await assertErrorsInCode(r'''
void f() {
  late int x = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
    ]);

    var x = findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isTrue);
    expect(x.isStatic, isFalse);
  }

  test_nonNullifyType() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
var a = 0;
''');

    await assertErrorsInCode('''
import 'a.dart';

void f() {
  var x = a;
  x;
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    var x = findElement.localVar('x');
    assertType(x.type, 'int');
  }
}
