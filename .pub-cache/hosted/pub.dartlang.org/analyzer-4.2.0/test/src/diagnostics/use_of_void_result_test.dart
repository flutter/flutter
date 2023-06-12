// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfVoidResultTest);
    defineReflectiveTests(UseOfVoidResultTest_NonNullable);
  });
}

@reflectiveTest
class UseOfVoidResultTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_andVoidLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x && true;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_andVoidRhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  true && x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 34, 1),
    ]);
  }

  test_assignmentExpression_function() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 38, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 49, 1),
    ]);
  }

  test_assignmentExpression_method() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_assignmentToVoidParameterOk() async {
    // Note: the spec may decide to disallow this, but at this point that seems
    // highly unlikely.
    await assertNoErrorsInCode('''
void main() {
  void x;
  f(x);
}
void f(void x) {}
''');
  }

  test_assignToVoid_notStrong_error() async {
    // See StrongModeStaticTypeAnalyzer2Test.test_assignToVoidOk
    // for testing that this does not have errors in strong mode.
    await assertErrorsInCode('''
void main() {
  void x;
  x = 42;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
    ]);
  }

  test_await() async {
    await assertNoErrorsInCode('''
main(void x) async {
  await x;
}
''');
  }

  test_extensionApplication() async {
    await assertErrorsInCode('''
extension E on String {
  int get g => 0;
}

void f() {}

main() {
  E(f()).g;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 71, 3),
    ]);
  }

  test_implicitReturnValue() async {
    await assertErrorsInCode(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);
  }

  test_inForLoop_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_inForLoop_ok() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 45, 1),
    ]);
  }

  test_interpolateVoidValueError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  "$x";
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 28, 1),
    ]);
  }

  test_negateVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  !x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 27, 1),
    ]);
  }

  test_nonVoidReturnValue() async {
    await assertErrorsInCode(r'''
int f() => 1;
g() {
  var a = f();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }

  test_orVoidLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x || true;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_orVoidRhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  false || x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 35, 1),
    ]);
  }

  test_throwVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  throw x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 32, 1),
    ]);
  }

  test_unaryNegativeVoidFunction() async {
    await assertErrorsInCode('''
void test(void f()) {
  -f();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 24, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 25, 3),
    ]);
  }

  test_unaryNegativeVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  -x;
}
''', [
      // TODO(mfairhurst) suppress UNDEFINED_OPERATOR
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 26, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 27, 1),
    ]);
  }

  test_useOfVoidAsIndexAssignError() async {
    await assertErrorsInCode('''
void main(List list) {
  void x;
  list[x] = null;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_useOfVoidAsIndexError() async {
    await assertErrorsInCode('''
void main(List list) {
  void x;
  list[x];
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_useOfVoidAssignedToDynamicError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  dynamic z = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 38, 1),
    ]);
  }

  test_useOfVoidByIndexingError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x[0];
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 27, 3),
    ]);
  }

  test_useOfVoidCallSetterError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x.foo = null;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 28, 3),
    ]);
  }

  test_useOfVoidCastsOk() async {
    await assertNoErrorsInCode('''
void use(dynamic x) { }
void main() {
  void x;
  use(x as int);
}
''');
  }

  test_useOfVoidInConditionalConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x ? null : null;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  @failingTest
  test_useOfVoidInConditionalLhsError() async {
    // TODO(mfairhurst) Enable this.
    await assertErrorsInCode('''
void main(bool c) {
  void x;
  c ? x : null;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  @failingTest
  test_useOfVoidInConditionalRhsError() async {
    // TODO(mfairhurst) Enable this.
    await assertErrorsInCode('''
void main(bool c) {
  void x;
  c ? null : x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 43, 1),
    ]);
  }

  test_useOfVoidInDoWhileConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  do {} while (x);
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 39, 1),
    ]);
  }

  test_useOfVoidInExpStmtOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  x;
}
''');
  }

  test_useOfVoidInForeachIterableError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  var y;
  for (y in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 45, 1),
    ]);
  }

  test_useOfVoidInForeachIterableError_declaredVariable() async {
    await assertErrorsInCode('''
void main() {
  void x;
  for (var v in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  @failingTest // This test may be completely invalid.
  test_useOfVoidInForeachVariableError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  for (x in [1, 2]) {}
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_useOfVoidInForPartsOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  for (x; false; x) {}
}
''');
  }

  test_useOfVoidInIsTestError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x is int;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_useOfVoidInListLiteralError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  <dynamic>[x];
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  test_useOfVoidInListLiteralOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  <void>[x]; // not strong mode; we have to specify <void>.
}
''');
  }

  test_useOfVoidInMapLiteralKeyError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m2 = <dynamic, int>{x : 4};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 50, 1),
    ]);
  }

  test_useOfVoidInMapLiteralKeyOk() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m2 = <void, int>{x : 4}; // not strong mode; we have to specify <void>.
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
    ]);
  }

  test_useOfVoidInMapLiteralValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m1 = <int, dynamic>{4: x};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 53, 1),
    ]);
  }

  test_useOfVoidInMapLiteralValueOk() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m1 = <int, void>{4: x}; // not strong mode; we have to specify <void>.
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
    ]);
  }

  test_useOfVoidInNullOperatorLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x ?? 499;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_useOfVoidInNullOperatorRhsOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  null ?? x;
}
''');
  }

  test_useOfVoidInSpecialAssignmentError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 28, 2),
    ]);
  }

  test_useOfVoidInSwitchExpressionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  switch(x) {}
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 33, 1),
    ]);
  }

  test_useOfVoidInWhileConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  while (x) {};
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 33, 1),
    ]);
  }

  test_useOfVoidNullPropertyAccessError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x?.foo;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 29, 3),
    ]);
  }

  test_useOfVoidPropertyAccessError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x.foo;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 28, 3),
    ]);
  }

  test_useOfVoidReturnInExtensionMethod() async {
    await assertErrorsInCode('''
extension on void {
  testVoid() {
    // No access on void. Static type of `this` is void!
    this.toString();
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 22, 8),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 96, 4),
    ]);
  }

  @failingTest
  test_useOfVoidReturnInNonVoidFunctionError() async {
    // TODO(mfairhurst) Get this test to pass once codebase is compliant.
    await assertErrorsInCode('''
dynamic main() {
  void x;
  return x;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 36, 1),
    ]);
  }

  test_useOfVoidReturnInVoidFunctionOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  return x;
}
''');
  }

  test_useOfVoidWhenArgumentError() async {
    await assertErrorsInCode('''
void use(dynamic x) { }
void main() {
  void x;
  use(x);
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 54, 1),
    ]);
  }

  test_useOfVoidWithInitializerOk() async {
    await assertErrorsInCode('''
void main() {
  void x;
  void y = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 31, 1),
    ]);
  }

  test_variableDeclaration_function_error() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    Object a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 45, 1),
    ]);
  }

  test_variableDeclaration_function_ok() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    void a = f();
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 39, 1),
    ]);
  }

  test_variableDeclaration_method2() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 47, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 56, 1),
    ]);
  }

  test_variableDeclaration_method_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 47, 1),
    ]);
  }

  test_variableDeclaration_method_ok() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    void a = m();
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
    ]);
  }

  test_yieldStarVoid_asyncStar() async {
    await assertErrorsInCode('''
main(void x) async* {
  yield* x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_yieldStarVoid_syncStar() async {
    await assertErrorsInCode('''
main(void x) sync* {
  yield* x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 30, 1),
    ]);
  }

  test_yieldVoid_asyncStar() async {
    await assertErrorsInCode('''
main(void x) async* {
  yield x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 30, 1),
    ]);
  }

  test_yieldVoid_syncStar() async {
    await assertErrorsInCode('''
main(void x) sync* {
  yield x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 29, 1),
    ]);
  }
}

@reflectiveTest
class UseOfVoidResultTest_NonNullable extends PubPackageResolutionTest {
  test_assignment_toDynamic() async {
    await assertErrorsInCode('''
void f(void x) {
  // ignore:unused_local_variable
  dynamic v = x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 65, 1),
    ]);
  }

  test_assignment_toVoid() async {
    await assertNoErrorsInCode('''
void f(void x) {
  // ignore:unused_local_variable
  void v = x;
}
''');
  }

  test_await() async {
    await assertErrorsInCode('''
main(void x) async {
  await x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 29, 1),
    ]);
  }

  test_constructorFieldInitializer_toDynamic() async {
    await assertErrorsInCode('''
class A {
  dynamic f;
  A(void x) : f = x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 41, 1),
    ]);
  }

  test_constructorFieldInitializer_toVoid() async {
    await assertNoErrorsInCode('''
class A {
  void f;
  A(void x) : f = x;
}
''');
  }

  test_nullCheck() async {
    await assertErrorsInCode(r'''
f(void x) {
  x!;
}
''', [ExpectedError(CompileTimeErrorCode.USE_OF_VOID_RESULT, 14, 2)]);

    assertType(findNode.postfix('x!'), 'void');
  }
}
