// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PostfixExpressionResolutionTest);
    defineReflectiveTests(PostfixExpressionResolutionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class PostfixExpressionResolutionTest extends PubPackageResolutionTest
    with PostfixExpressionResolutionTestCases {
  test_inc_propertyAccess_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  a?.foo++;
}
''');

    assertPostfixExpression(
      findNode.postfix('foo++'),
      readElement: findElement.getter('foo'),
      readType: 'int',
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      element: numElement.getMethod('+'),
      type: 'int?',
    );
  }

  test_inc_simpleIdentifier_parameter_depromote() async {
    await assertNoErrorsInCode(r'''
class A {
  Object operator +(int _) => this;
}

void f(Object x) {
  if (x is A) {
    x++;
    x; // ref
  }
}
''');

    if (hasAssignmentLeftResolution) {
      assertType(findNode.simple('x++;'), 'A');
    }

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.parameter('x'),
      readType: 'A',
      writeElement: findElement.parameter('x'),
      writeType: 'Object',
      element: findElement.method('+'),
      type: 'A',
    );

    assertType(findNode.simple('x; // ref'), 'Object');
  }

  test_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x!;
}
''');

    assertPostfixExpression(
      findNode.postfix('x!'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: null,
      type: 'int',
    );
  }

  test_nullCheck_functionExpressionInvocation_rewrite() async {
    await assertNoErrorsInCode(r'''
void f(Function f2) {
  f2(42)!;
}
''');
  }

  test_nullCheck_indexExpression() async {
    await assertNoErrorsInCode(r'''
void f(Map<String, int> a) {
  int v = a['foo']!;
  v;
}
''');

    assertIndexExpression(
      findNode.index('a['),
      readElement: elementMatcher(
        mapElement.getMethod('[]'),
        substitution: {'K': 'String', 'V': 'int'},
      ),
      writeElement: null,
      type: 'int?',
    );

    assertPostfixExpression(
      findNode.postfix(']!'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: null,
      type: 'int',
    );
  }

  test_nullCheck_null() async {
    await assertErrorsInCode('''
void f(Null x) {
  x!;
}
''', [
      error(HintCode.NULL_CHECK_ALWAYS_FAILS, 19, 2),
    ]);

    assertType(findNode.postfix('x!'), 'Never');
  }

  test_nullCheck_nullableContext() async {
    await assertNoErrorsInCode(r'''
T f<T>(T t) => t;

int g() => f(null)!;
''');

    assertMethodInvocation2(
      findNode.methodInvocation('f(null)'),
      element: findElement.topFunction('f'),
      typeArgumentTypes: ['int?'],
      invokeType: 'int? Function(int?)',
      type: 'int?',
    );

    assertPostfixExpression(
      findNode.postfix('f(null)!'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: null,
      type: 'int',
    );
  }

  /// See https://github.com/dart-lang/language/issues/1163
  test_nullCheck_participatesNullShorting() async {
    await assertErrorsInCode('''
class A {
  int zero;
  int? zeroOrNull;

  A(this.zero, [this.zeroOrNull]);
}

void test1(A? a) => a?.zero!;
void test2(A? a) => a?.zeroOrNull!;
void test3(A? a) => a?.zero!.isEven;
void test4(A? a) => a?.zeroOrNull!.isEven;

class Foo {
  Bar? bar;

  Foo(this.bar);

  Bar? operator [](int? index) => null;
}

class Bar {
  int baz;

  Bar(this.baz);

  int operator [](int index) => index;
}

void test5(Foo? foo) => foo?.bar!;
void test6(Foo? foo) => foo?.bar!.baz;
void test7(Foo? foo, int a) => foo?.bar![a];
void test8(Foo? foo, int? a) => foo?[a]!;
void test9(Foo? foo, int? a) => foo?[a]!.baz;
void test10(Foo? foo, int? a, int b) => foo?[a]![b];
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 107, 1),
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 173, 1),
    ]);

    void assertTestType(int index, String expected) {
      var function = findNode.functionDeclaration('test$index(');
      var body = function.functionExpression.body as ExpressionFunctionBody;
      assertType(body.expression, expected);
    }

    assertTestType(1, 'int?');
    assertTestType(2, 'int?');
    assertTestType(3, 'bool?');
    assertTestType(4, 'bool?');

    assertTestType(5, 'Bar?');
    assertTestType(6, 'int?');
    assertTestType(7, 'int?');
    assertTestType(8, 'Bar?');
    assertTestType(9, 'int?');
    assertTestType(10, 'int?');
  }

  test_nullCheck_superExpression() async {
    await assertErrorsInCode(r'''
class A {
  int foo() => 0;
}

class B extends A {
  void bar() {
    super!.foo();
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 70, 6),
    ]);

    assertTypeDynamic(findNode.super_('super!'));

    assertPostfixExpression(
      findNode.postfix('super!'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: null,
      type: 'dynamic',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('foo();'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_nullCheck_typeParameter() async {
    await assertNoErrorsInCode(r'''
void f<T>(T? x) {
  x!;
}
''');

    var postfixExpression = findNode.postfix('x!');
    assertPostfixExpression(
      postfixExpression,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: null,
      type: 'T & Object',
    );
  }

  test_nullCheck_typeParameter_already_promoted() async {
    await assertNoErrorsInCode('''
void f<T>(T? x) {
  if (x is num?) {
    x!;
  }
}
''');

    var postfixExpression = findNode.postfix('x!');
    assertPostfixExpression(
      postfixExpression,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: null,
      type: 'T & num',
    );
  }
}

mixin PostfixExpressionResolutionTestCases on PubPackageResolutionTest {
  test_dec_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x--;
}
''');

    assertPostfixExpression(
      findNode.postfix('x--'),
      readElement: findElement.parameter('x'),
      readType: 'int',
      writeElement: findElement.parameter('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('-'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_indexExpression_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0]++;
}
''');

    assertPostfixExpression(
      findNode.postfix('a[0]++'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_indexExpression_super() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    super[0]++;
  }
}
''');

    assertPostfixExpression(
      findNode.postfix('[0]++'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_indexExpression_this() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0]++;
  }
}
''');

    assertPostfixExpression(
      findNode.postfix('[0]++'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_notLValue_parenthesized() async {
    await assertErrorsInCode(r'''
void f() {
  (0)++;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 16, 2),
    ]);

    assertPostfixExpression(
      findNode.postfix('(0)++'),
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      element: null,
      type: 'dynamic',
    );
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral() async {
    await assertErrorsInCode(r'''
void f() {
  int++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    assertPostfixExpression(
      findNode.postfix('int++'),
      readElement: intElement,
      readType: 'dynamic',
      writeElement: intElement,
      writeType: 'dynamic',
      element: null,
      type: 'dynamic',
    );
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral_typeParameter() async {
    await assertErrorsInCode(r'''
void f<T>() {
  T++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 16, 1),
    ]);

    var postfix = findNode.postfix('T++');
    assertPostfixExpression(
      postfix,
      readElement: findElement.typeParameter('T'),
      readType: 'dynamic',
      writeElement: findElement.typeParameter('T'),
      writeType: 'dynamic',
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifierAssignmentTarget(
      postfix.operand,
    );
  }

  test_inc_prefixedIdentifier_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f(A a) {
  a.x++;
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
int x = 0;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.x++;
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var postfix = findNode.postfix('x++');
    assertPostfixExpression(
      postfix,
      readElement: importFind.topGet('x'),
      readType: 'int',
      writeElement: importFind.topSet('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var prefixed = postfix.operand as PrefixedIdentifier;
    assertImportPrefix(prefixed.prefix, importFind.prefix);
  }

  test_inc_propertyAccess_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f() {
  A().x++;
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_propertyAccess_super() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    super.x++;
  }
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.getter('x', of: 'A'),
      readType: 'int',
      writeElement: findElement.setter('x', of: 'A'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_propertyAccess_this() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    this.x++;
  }
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_simpleIdentifier_parameter_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  x++;
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.parameter('x'),
      readType: 'double',
      writeElement: findElement.parameter('x'),
      writeType: 'double',
      element: elementMatcher(
        doubleElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_inc_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x++;
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.parameter('x'),
      readType: 'int',
      writeElement: findElement.parameter('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_simpleIdentifier_parameter_num() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  x++;
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      readElement: findElement.parameter('x'),
      readType: 'num',
      writeElement: findElement.parameter('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'num',
    );
  }

  test_inc_simpleIdentifier_thisGetter_superSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

class B extends A {
  int get x => 0;
  void f() {
    x++;
  }
}
''');

    var postfix = findNode.postfix('x++');
    assertPostfixExpression(
      postfix,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      postfix.operand,
    );
  }

  test_inc_simpleIdentifier_topGetter_topSetter() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

void f() {
  x++;
}
''');

    var postfix = findNode.postfix('x++');
    assertPostfixExpression(
      postfix,
      readElement: findElement.topGet('x'),
      readType: 'int',
      writeElement: findElement.topSet('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      postfix.operand,
    );
  }

  test_inc_simpleIdentifier_topGetter_topSetter_fromClass() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    x++;
  }
}
''');

    var postfix = findNode.postfix('x++');
    assertPostfixExpression(
      postfix,
      readElement: findElement.topGet('x'),
      readType: 'int',
      writeElement: findElement.topSet('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      postfix.operand,
    );
  }
}

@reflectiveTest
class PostfixExpressionResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with PostfixExpressionResolutionTestCases, WithoutNullSafetyMixin {}
