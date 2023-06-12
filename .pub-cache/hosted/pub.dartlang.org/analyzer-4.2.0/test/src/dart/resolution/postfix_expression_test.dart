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

    assertResolvedNodeText(findNode.postfix('foo++'), r'''
PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::foo
  readType: int
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int?
''');
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

    assertResolvedNodeText(findNode.postfix('x++'), r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: A
  writeElement: self::@function::f::@parameter::x
  writeType: Object
  staticElement: self::@class::A::@method::+
  staticType: A
''');

    assertType(findNode.simple('x; // ref'), 'Object');
  }

  test_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x!;
}
''');

    assertResolvedNodeText(findNode.postfix('x!'), r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  operator: !
  staticElement: <null>
  staticType: int
''');
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

    assertResolvedNodeText(findNode.index('a['), r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: Map<String, int>
  leftBracket: [
  index: SimpleStringLiteral
    literal: 'foo'
  rightBracket: ]
  staticElement: MethodMember
    base: dart:core::@class::Map::@method::[]
    substitution: {K: String, V: int}
  staticType: int?
''');

    assertResolvedNodeText(findNode.postfix(']!'), r'''
PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: Map<String, int>
    leftBracket: [
    index: SimpleStringLiteral
      literal: 'foo'
    rightBracket: ]
    staticElement: MethodMember
      base: dart:core::@class::Map::@method::[]
      substitution: {K: String, V: int}
    staticType: int?
  operator: !
  staticElement: <null>
  staticType: int
''');
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

    var node = findNode.postfix('f(null)!');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        NullLiteral
          literal: null
          parameter: ParameterMember
            base: root::@parameter::t
            substitution: {T: int?}
          staticType: Null
      rightParenthesis: )
    staticInvokeType: int? Function(int?)
    staticType: int?
    typeArgumentTypes
      int?
  operator: !
  staticElement: <null>
  staticType: int
''');
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

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PostfixExpression
    operand: SuperExpression
      superKeyword: super
      staticType: dynamic
    operator: !
    staticElement: <null>
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_nullCheck_typeParameter() async {
    await assertNoErrorsInCode(r'''
void f<T>(T? x) {
  x!;
}
''');

    var postfixExpression = findNode.postfix('x!');
    assertResolvedNodeText(postfixExpression, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: T?
  operator: !
  staticElement: <null>
  staticType: T & Object
''');
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
    assertResolvedNodeText(postfixExpression, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: T? & num?
  operator: !
  staticElement: <null>
  staticType: T & num
''');
  }
}

mixin PostfixExpressionResolutionTestCases on PubPackageResolutionTest {
  test_dec_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x--;
}
''');

    var node = findNode.postfix('x--');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: --
  readElement: self::@function::f::@parameter::x
  readType: int
  writeElement: self::@function::f::@parameter::x
  writeType: int
  staticElement: dart:core::@class::num::@method::-
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: --
  readElement: self::@function::f::@parameter::x
  readType: int*
  writeElement: self::@function::f::@parameter::x
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::-
    isLegacy: true
  staticType: int*
''');
    }
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

    var node = findNode.postfix('a[0]++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A*
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int*
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@method::[]
  readType: int*
  writeElement: self::@class::A::@method::[]=
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
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

    var node = findNode.postfix('[0]++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B*
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int*
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@method::[]
  readType: int*
  writeElement: self::@class::A::@method::[]=
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
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

    var node = findNode.postfix('[0]++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: A*
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int*
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@method::[]
  readType: int*
  writeElement: self::@class::A::@method::[]=
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_inc_notLValue_parenthesized() async {
    await assertErrorsInCode(r'''
void f() {
  (0)++;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 16, 2),
    ]);

    var node = findNode.postfix('(0)++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: ++
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int*
    rightParenthesis: )
    staticType: int*
  operator: ++
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    }
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral() async {
    await assertErrorsInCode(r'''
void f() {
  int++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var node = findNode.postfix('int++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: int
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: dart:core::@class::int
  readType: dynamic
  writeElement: dart:core::@class::int
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: int
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: dart:core::@class::int
  readType: dynamic
  writeElement: dart:core::@class::int
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    }
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral_typeParameter() async {
    await assertErrorsInCode(r'''
void f<T>() {
  T++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 16, 1),
    ]);

    var node = findNode.postfix('T++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: T
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: T@7
  readType: dynamic
  writeElement: T@7
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: T
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: T@7
  readType: dynamic
  writeElement: T@7
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    }
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

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A*
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int*
  writeElement: self::@class::A::@setter::x
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_inc_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.x++;
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: self::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: self::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: package:test/a.dart::@getter::x
  readType: int*
  writeElement: package:test/a.dart::@setter::x
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }

    var prefixed = node.operand as PrefixedIdentifier;
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

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: SimpleIdentifier
            token: A
            staticElement: self::@class::A
            staticType: null
          type: A
        staticElement: self::@class::A::@constructor::•
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: SimpleIdentifier
            token: A
            staticElement: self::@class::A
            staticType: null
          type: A*
        staticElement: self::@class::A::@constructor::•
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A*
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int*
  writeElement: self::@class::A::@setter::x
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
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

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B*
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int*
  writeElement: self::@class::A::@setter::x
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
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

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A*
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@class::A::@getter::x
  readType: int*
  writeElement: self::@class::A::@setter::x
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_inc_simpleIdentifier_parameter_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  x++;
}
''');

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: double
  writeElement: self::@function::f::@parameter::x
  writeType: double
  staticElement: dart:core::@class::double::@method::+
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: double*
  writeElement: self::@function::f::@parameter::x
  writeType: double*
  staticElement: MethodMember
    base: dart:core::@class::double::@method::+
    isLegacy: true
  staticType: double*
''');
    }
  }

  test_inc_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x++;
}
''');

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: int
  writeElement: self::@function::f::@parameter::x
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: int*
  writeElement: self::@function::f::@parameter::x
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_inc_simpleIdentifier_parameter_num() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  x++;
}
''');

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: num
  writeElement: self::@function::f::@parameter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: num*
  writeElement: self::@function::f::@parameter::x
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: num*
''');
    }
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

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::B::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@class::B::@getter::x
  readType: int*
  writeElement: self::@class::A::@setter::x
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_inc_simpleIdentifier_topGetter_topSetter() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

void f() {
  x++;
}
''');

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@getter::x
  readType: int
  writeElement: self::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@getter::x
  readType: int*
  writeElement: self::@setter::x
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
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

    var node = findNode.postfix('x++');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@getter::x
  readType: int
  writeElement: self::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ++
  readElement: self::@getter::x
  readType: int*
  writeElement: self::@setter::x
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }
}

@reflectiveTest
class PostfixExpressionResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with PostfixExpressionResolutionTestCases, WithoutNullSafetyMixin {}
