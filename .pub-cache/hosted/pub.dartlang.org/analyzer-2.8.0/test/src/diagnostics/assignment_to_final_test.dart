// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalTest);
    defineReflectiveTests(AssignmentToFinalWithoutNullSafetyTest);
  });
}

@reflectiveTest
class AssignmentToFinalTest extends PubPackageResolutionTest
    with AssignmentToFinalTestCases {
  test_prefixedIdentifier_instanceField_abstract() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_abstractFinal() async {
    await assertErrorsInCode('''
abstract class A {
  abstract final int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 64, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 75, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 89, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 96, 1),
    ]);
  }

  test_prefixedIdentifier_instanceField_external() async {
    await assertNoErrorsInCode('''
abstract class A {
  external int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_externalFinal() async {
    await assertErrorsInCode('''
abstract class A {
  external final int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 64, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 75, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 89, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 96, 1),
    ]);
  }

  test_prefixedIdentifier_instanceField_lateFinal() async {
    await assertNoErrorsInCode('''
abstract class A {
  late final int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_lateFinal_hasInitializer() async {
    await assertErrorsInCode('''
abstract class A {
  late final int x = 0;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 64, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 75, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 89, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 96, 1),
    ]);
  }

  test_prefixedIdentifier_staticField_externalFinal() async {
    await assertErrorsInCode('''
abstract class A {
  external static final int x;
}

void f() {
  A.x = 0;
  A.x += 0;
  ++A.x;
  A.x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 68, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 79, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 93, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 100, 1),
    ]);
  }

  test_prefixedIdentifier_staticField_lateFinal() async {
    await assertNoErrorsInCode('''
abstract class A {
  static late final int x;
}

void f() {
  A.x = 0;
  A.x += 0;
  ++A.x;
  A.x++;
}
''');
  }

  test_prefixedIdentifier_staticField_lateFinal_hasInitializer() async {
    await assertErrorsInCode('''
abstract class A {
  static late final int x = 0;
}

void f() {
  A.x = 0;
  A.x += 0;
  ++A.x;
  A.x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 68, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 79, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 93, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 100, 1),
    ]);
  }

  test_propertyAccess_instanceField_lateFinal() async {
    await assertNoErrorsInCode('''
abstract class A {
  late final int x;
}

void f(A a) {
  (a).x = 0;
  (a).x += 0;
  ++(a).x;
  (a).x++;
}
''');
  }

  test_propertyAccess_instanceField_lateFinal_hasInitializer() async {
    await assertErrorsInCode('''
abstract class A {
  late final int x = 0;
}

void f(A a) {
  (a).x = 0;
  (a).x += 0;
  ++(a).x;
  (a).x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 66, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 79, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 95, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 104, 1),
    ]);
  }

  test_simpleIdentifier_instanceField_lateFinal() async {
    await assertNoErrorsInCode('''
abstract class A {
  late final int x;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''');
  }

  test_simpleIdentifier_instanceField_lateFinal_hasInitializer() async {
    await assertErrorsInCode('''
abstract class A {
  late final int x = 0;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 61, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 72, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 86, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 93, 1),
    ]);
  }

  test_simpleIdentifier_staticField_lateFinal() async {
    await assertNoErrorsInCode('''
abstract class A {
  static late final int x;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''');
  }

  test_simpleIdentifier_staticField_lateFinal_hasInitializer() async {
    await assertErrorsInCode('''
abstract class A {
  static late final int x = 0;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 68, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 79, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 93, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 100, 1),
    ]);
  }

  test_simpleIdentifier_topLevelVariable_external() async {
    await assertNoErrorsInCode('''
external int x;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_simpleIdentifier_topLevelVariable_externalFinal() async {
    await assertErrorsInCode('''
external final x;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 32, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 41, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 53, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 58, 1),
    ]);
  }

  test_simpleIdentifier_topLevelVariable_lateFinal() async {
    await assertNoErrorsInCode('''
late final int x;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_simpleIdentifier_topLevelVariable_lateFinal_hasInitializer() async {
    await assertErrorsInCode('''
late final int x = 0;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 36, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 45, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 57, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 62, 1),
    ]);
  }
}

mixin AssignmentToFinalTestCases on PubPackageResolutionTest {
  test_prefixedIdentifier_instanceField() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_final() async {
    await assertErrorsInCode('''
class A {
  final x = 0;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 46, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 57, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 71, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 78, 1),
    ]);
  }

  test_simpleIdentifier_inheritedSetter_shadowedBy_topLevelGetter() async {
    await assertErrorsInCode('''
class A {
  void set foo(int _) {}
}

int get foo => 0;

class B extends A {
  void bar() {
    foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 96, 3),
    ]);
  }

  test_simpleIdentifier_topLevelGetter() async {
    await assertErrorsInCode('''
int get x => 0;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 30, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 39, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 51, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 56, 1),
    ]);
  }

  test_simpleIdentifier_topLevelVariable() async {
    await assertNoErrorsInCode('''
var x = 0;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_simpleIdentifier_topLevelVariable_final() async {
    await assertErrorsInCode('''
final x = 0;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 27, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 36, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 48, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 53, 1),
    ]);
  }
}

@reflectiveTest
class AssignmentToFinalWithoutNullSafetyTest extends PubPackageResolutionTest
    with AssignmentToFinalTestCases, WithoutNullSafetyMixin {}
