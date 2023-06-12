// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryExpressionResolutionTest);
  });
}

@reflectiveTest
class BinaryExpressionResolutionTest extends PubPackageResolutionTest
    with BinaryExpressionResolutionTestCases {
  test_ifNull_left_nullableContext() async {
    await assertNoErrorsInCode(r'''
T f<T>(T t) => t;

int g() => f(null) ?? 0;
''');

    assertMethodInvocation2(
      findNode.methodInvocation('f(null)'),
      element: findElement.topFunction('f'),
      typeArgumentTypes: ['int?'],
      invokeType: 'int? Function(int?)',
      type: 'int?',
    );

    assertBinaryExpression(
      findNode.binary('?? 0'),
      element: null,
      type: 'int',
    );
  }

  test_ifNull_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
void f(int? x, int y) {
  x ?? y;
}
''');

    assertBinaryExpression(
      findNode.binary('x ?? y'),
      element: null,
      type: 'int',
    );
  }

  test_ifNull_nullableInt_nullableDouble() async {
    await assertNoErrorsInCode(r'''
void f(int? x, double? y) {
  x ?? y;
}
''');

    assertBinaryExpression(
      findNode.binary('x ?? y'),
      element: null,
      type: 'num?',
    );
  }

  test_ifNull_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x ?? x;
}
''');

    assertBinaryExpression(
      findNode.binary('x ?? x'),
      element: null,
      type: 'int?',
    );
  }

  test_plus_int_never() async {
    await assertNoErrorsInCode('''
f(int a, Never b) {
  a + b;
}
''');

    assertBinaryExpression(findNode.binary('a + b'),
        element: numElement.getMethod('+'), type: 'num');
  }

  test_plus_never_int() async {
    await assertErrorsInCode(r'''
f(Never a, int b) {
  a + b;
}
''', [
      error(HintCode.RECEIVER_OF_TYPE_NEVER, 22, 1),
      error(HintCode.DEAD_CODE, 26, 2),
    ]);

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: isNull,
      type: 'Never',
    );
  }
}

mixin BinaryExpressionResolutionTestCases on PubPackageResolutionTest {
  test_bangEq() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a != b;
}
''');

    assertBinaryExpression(
      findNode.binary('a != b'),
      element: elementMatcher(
        numElement.getMethod('=='),
        isLegacy: isLegacyLibrary,
      ),
      type: 'bool',
    );
  }

  test_bangEq_extensionOverride_left() async {
    await assertErrorsInCode(r'''
extension E on int {}

void f(int a) {
  E(a) != 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 46, 2),
    ]);

    assertBinaryExpression(
      findNode.binary('!= 0'),
      element: null,
      type: 'dynamic',
    );
  }

  test_bangEqEq() async {
    await assertErrorsInCode(r'''
f(int a, int b) {
  a !== b;
}
''', [
      error(ScannerErrorCode.UNSUPPORTED_OPERATOR, 22, 1),
    ]);

    assertBinaryExpression(
      findNode.binary('a !== b'),
      element: null,
      type: 'dynamic',
    );

    assertType(findNode.simple('a !=='), 'int');
    assertType(findNode.simple('b;'), 'int');
  }

  test_eqEq() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a == b;
}
''');

    assertBinaryExpression(
      findNode.binary('a == b'),
      element: elementMatcher(
        numElement.getMethod('=='),
        isLegacy: isLegacyLibrary,
      ),
      type: 'bool',
    );
  }

  test_eqEq_extensionOverride_left() async {
    await assertErrorsInCode(r'''
extension E on int {}

void f(int a) {
  E(a) == 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 46, 2),
    ]);

    assertBinaryExpression(
      findNode.binary('== 0'),
      element: null,
      type: 'dynamic',
    );
  }

  test_eqEqEq() async {
    await assertErrorsInCode(r'''
f(int a, int b) {
  a === b;
}
''', [
      error(ScannerErrorCode.UNSUPPORTED_OPERATOR, 22, 1),
    ]);

    assertBinaryExpression(
      findNode.binary('a === b'),
      element: null,
      type: 'dynamic',
    );

    assertType(findNode.simple('a ==='), 'int');
    assertType(findNode.simple('b;'), 'int');
  }

  test_ifNull() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertNoErrorsInCode('''
f(int$question a, double b) {
  a ?? b;
}
''');

    assertBinaryExpression(
      findNode.binary('a ?? b'),
      element: null,
      type: 'num',
    );
  }

  test_logicalAnd() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a && b;
}
''');

    assertBinaryExpression(
      findNode.binary('a && b'),
      element: boolElement.getMethod('&&'),
      type: 'bool',
    );
  }

  test_logicalOr() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a || b;
}
''');

    assertBinaryExpression(
      findNode.binary('a || b'),
      element: boolElement.getMethod('||'),
      type: 'bool',
    );
  }

  test_minus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a - f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_minus_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a - b;
}
''');

    assertBinaryExpression(
      findNode.binary('a - b'),
      element: elementMatcher(
        numElement.getMethod('-'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_minus_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a - b;
}
''');

    assertBinaryExpression(
      findNode.binary('a - b'),
      element: elementMatcher(
        numElement.getMethod('-'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_mod_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a % f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_mod_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a % b;
}
''');

    assertBinaryExpression(
      findNode.binary('a % b'),
      element: elementMatcher(
        numElement.getMethod('%'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_mod_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a % b;
}
''');

    assertBinaryExpression(
      findNode.binary('a % b'),
      element: elementMatcher(
        numElement.getMethod('%'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plus_double_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a + f());
}
h(double x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_double_context_int() async {
    await assertErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 45, 7),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_double_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  a + f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_double_dynamic() async {
    await assertNoErrorsInCode(r'''
f(double a, dynamic b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        doubleElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_plus_int_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a + f());
}
h(double x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'double', legacy: 'num')]);
  }

  test_plus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a + f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_plus_int_context_int_target_rewritten() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int Function() a) {
  h(a() + f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_plus_int_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
extension E on int {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a) + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 98, 10),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a + f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_plus_int_dynamic() async {
    await assertNoErrorsInCode(r'''
f(int a, dynamic b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'num',
    );
  }

  test_plus_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plus_int_int_target_rewritten() async {
    await assertNoErrorsInCode('''
f(int Function() a, int b) {
  a() + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a() + b'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plus_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
extension E on int {
  String operator+(int other) => '';
}
f(int a, int b) {
  E(a) + b;
}
''');

    assertBinaryExpression(
      findNode.binary('E(a) + b'),
      element: elementMatcher(
        findElement.method('+', of: 'E'),
        isLegacy: false,
      ),
      type: 'String',
    );
  }

  test_plus_int_num() async {
    await assertNoErrorsInCode(r'''
f(int a, num b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'num',
    );
  }

  test_plus_num_context_int() async {
    await assertErrorsInCode(
        '''
T f<T>() => throw Error();
g(num a) {
  h(a + f());
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 7),
        ], legacy: []));

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_other_context_int() async {
    await assertErrorsInCode(
        '''
abstract class A {
  num operator+(String x);
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 88, 7),
        ], legacy: []));

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['String']);
  }

  test_plus_other_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a) + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 10),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_other_context_int_via_extension_implicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 7),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_other_double() async {
    await assertNoErrorsInCode('''
abstract class A {
  String operator+(double other);
}
f(A a, double b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        findElement.method('+', of: 'A'),
        isLegacy: false,
      ),
      type: 'String',
    );
  }

  test_plus_other_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String operator+(int other) => '';
}
f(A a, int b) {
  E(a) + b;
}
''');

    assertBinaryExpression(
      findNode.binary('E(a) + b'),
      element: elementMatcher(
        findElement.method('+', of: 'E'),
        isLegacy: false,
      ),
      type: 'String',
    );
  }

  test_plus_other_int_via_extension_implicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String operator+(int other) => '';
}
f(A a, int b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        findElement.method('+', of: 'E'),
        isLegacy: false,
      ),
      type: 'String',
    );
  }

  test_receiverTypeParameter_bound_dynamic() async {
    await assertNoErrorsInCode(r'''
f<T extends dynamic>(T a) {
  a + 0;
}
''');

    assertBinaryExpression(
      findNode.binary('a + 0'),
      element: null,
      type: 'dynamic',
    );
  }

  test_receiverTypeParameter_bound_num() async {
    await assertNoErrorsInCode(r'''
f<T extends num>(T a) {
  a + 0;
}
''');

    assertBinaryExpression(
      findNode.binary('a + 0'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'num',
    );
  }

  test_slash() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a / b;
}
''');

    assertBinaryExpression(
      findNode.binary('a / b'),
      element: elementMatcher(
        numElement.getMethod('/'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_star_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a * f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_star_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a * b;
}
''');

    assertBinaryExpression(
      findNode.binary('a * b'),
      element: elementMatcher(
        numElement.getMethod('*'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_star_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a * b;
}
''');

    assertBinaryExpression(
      findNode.binary('a * b'),
      element: elementMatcher(
        numElement.getMethod('*'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }
}
