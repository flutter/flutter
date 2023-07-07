// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionOperatorTest);
  });
}

@reflectiveTest
class UndefinedExtensionOperatorTest extends PubPackageResolutionTest {
  test_binary_defined() async {
    await assertNoErrorsInCode('''
extension E on String {
  void operator +(int offset) {}
}
f() {
  E('a') + 1;
}
''');
  }

  test_binary_undefined() async {
    await assertErrorsInCode('''
extension E on String {}
f() {
  E('a') + 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 40, 1),
    ]);
    var binaryExpression = findNode.binary('+ 1');
    assertElementNull(binaryExpression);
    assertInvokeTypeNull(binaryExpression);
    assertTypeDynamic(binaryExpression);
  }

  test_index_get_hasGetter() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  E(a)[0];
}
''');
  }

  test_index_get_hasNone() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {}

f(A a) {
  E(a)[0];
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 48, 3),
    ]);
  }

  test_index_get_hasSetter() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0];
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 93, 3),
    ]);
  }

  test_index_getSet_hasBoth() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0] += 1;
}
''');
  }

  test_index_getSet_hasGetter() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  E(a)[0] += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 83, 3),
    ]);
  }

  test_index_getSet_hasNone() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {}

f(A a) {
  E(a)[0] += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 48, 3),
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 48, 3),
    ]);
  }

  test_index_getSet_hasSetter() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0] += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 93, 3),
    ]);
  }

  test_index_set_hasGetter() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  E(a)[0] = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 83, 3),
    ]);
  }

  test_index_set_hasNone() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {}

f(A a) {
  E(a)[0] = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 48, 3),
    ]);
  }

  test_index_set_hasSetter() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0] = 1;
}
''');
  }

  test_prefix_minus_defined() async {
    await assertNoErrorsInCode('''
extension E on String {
  String operator -() => substring(1);
}
f() {
  -E('a');
}
''');
  }

  test_prefix_minus_undefined() async {
    await assertErrorsInCode('''
extension E on String {}
f() {
  -E('a');
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 33, 1),
    ]);
  }
}
