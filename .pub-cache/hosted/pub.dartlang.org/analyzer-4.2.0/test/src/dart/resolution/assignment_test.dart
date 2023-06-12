// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentDriverResolutionTest);
  });
}

@reflectiveTest
class AssignmentDriverResolutionTest extends PubPackageResolutionTest {
  test_compound_plus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a += f();
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      ['int'],
    );
  }

  test_compound_plus_int_context_int_complex() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(List<int> a) {
  a[0] += f();
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      ['int'],
    );
  }

  test_compound_plus_int_context_int_promoted() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a) {
  if (a is int) {
    a += f();
  }
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      ['int'],
    );
  }

  test_compound_plus_int_context_int_promoted_with_subsequent_demotion() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a, bool b) {
  if (a is int) {
    a += b ? f() : 1.0;
    print(a);
  }
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      ['int'],
    );

    assertType(findNode.simple('a);').staticType, 'num');
  }

  test_indexExpression_cascade_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a..[0] += 2;
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    period: ..
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2;
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_instance_compound_double_num() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2.0;
}
''');

    var assignment = findNode.assignment('[0] += 2.0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 2.0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: double
  readElement: self::@class::A::@method::[]
  readType: num
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: double
''');
  }

  test_indexExpression_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? operator[](int? index) => 0;
  operator[]=(int? index, num? _) {}
}

void f(A a) {
  a[0] ??= 2;
}
''');

    var assignment = findNode.assignment('[0] ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int?
  writeElement: self::@class::A::@method::[]=
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] = 2;
}
''');

    var assignment = findNode.assignment('[0] = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@method::[]=::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_super_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    super[0] += 2;
  }
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_this_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0] += 2;
  }
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 20, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: dynamic
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: <null>
      staticElement: <null>
      staticType: dynamic
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved2_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 26, 3),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 27, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: <null>
      staticElement: <null>
      staticType: dynamic
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved3_simple() async {
    await assertErrorsInCode(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a, int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 73, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticElement: <null>
      staticType: dynamic
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: self::@class::A::@method::[]=::@parameter::_
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_binaryExpression_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  a + b += c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 5),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 5),
    ]);

    var assignment = findNode.assignment('= c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: BinaryExpression
    leftOperand: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int
    operator: +
    rightOperand: SimpleIdentifier
      token: b
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticElement: self::@function::f::@parameter::b
      staticType: int
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: double
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_notLValue_parenthesized_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  (a + b) += c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 7),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 7),
    ]);

    var assignment = findNode.assignment('= c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: int
      operator: +
      rightOperand: SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::+::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: int
      staticElement: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: double
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_notLValue_parenthesized_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  (a + b) = c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 7),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 7),
    ]);

    var assignment = findNode.assignment('= c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: int
      operator: +
      rightOperand: SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::+::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: int
      staticElement: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: double
''');
  }

  test_notLValue_postfixIncrement_compound() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ += y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
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
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_notLValue_postfixIncrement_compound_ifNull() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ ??= y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
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
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_notLValue_postfixIncrement_simple() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ = y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
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
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_prefixIncrement_compound() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x += y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_notLValue_prefixIncrement_compound_ifNull() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x ??= y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_notLValue_prefixIncrement_simple() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x = y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_ambiguous_simple() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', 'class C {}');
    await assertErrorsInCode('''
import 'a.dart';
import 'b.dart';
void f() {
  C = 0;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 47, 1),
    ]);

    var assignment = findNode.assignment('C = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_simple() async {
    await assertErrorsInCode('''
class C {}

void f() {
  C = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 25, 1),
    ]);

    var assignment = findNode.assignment('C = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_nullAware_context() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int? a) {
  a ??= f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['int?']);
  }

  test_prefixedIdentifier_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
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
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  a.x ??= 2;
}
''');

    var assignment = findNode.assignment('x ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
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
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int?
  writeElement: self::@class::A::@setter::x
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  a.x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instanceGetter_simple() async {
    await assertErrorsInCode(r'''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 49, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_static_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  static set x(num _) {}
}

void f() {
  A.x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_staticGetter_simple() async {
    await assertErrorsInCode(r'''
class A {
  static int get x => 0;
}

void f() {
  A.x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_topLevel_compound() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get x => 0;
set x(num _) {}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
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
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_typeAlias_static_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  static int get x => 0;
  static set x(int _) {}
}

typedef B = A;

void f() {
  B.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      staticElement: self::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  a.b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('a.b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved2_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  a.b += c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 27, 1),
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 1),
    ]);

    var assignment = findNode.assignment('a.b += c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_propertyAccess_cascade_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a..x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_forwardingStub() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}
abstract class I<T> {
  T x = throw 0;
}
class B extends A implements I<int> {}
main() {
  new B().x = 1;
}
''');

    var assignment = findNode.assignment('x = 1');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      keyword: new
      constructorName: ConstructorName
        type: NamedType
          name: SimpleIdentifier
            token: B
            staticElement: self::@class::B
            staticType: null
          type: B
        staticElement: self::@class::B::@constructor::•
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@class::A::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  (a).x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_fromMixins_compound() async {
    await assertNoErrorsInCode('''
class M1 {
  int get x => 0;
  set x(num _) {}
}

class M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
}

void f(C c) {
  (c).x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        staticElement: self::@function::f::@parameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::M2::@getter::x
  readType: int
  writeElement: self::@class::M2::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  (a).x ??= 2;
}
''');

    var assignment = findNode.assignment('x ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int?
  writeElement: self::@class::A::@setter::x
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  (a).x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_super_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    super.x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_this_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}

  void f() {
    this.x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  (a).b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 19, 1),
    ]);

    var assignment = findNode.assignment('(a).b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: <null>
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_unresolved2_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  (a).b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 29, 1),
    ]);

    var assignment = findNode.assignment('(a).b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_fieldInstance_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::C::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_fieldStatic_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  static num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::C::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterInstance_simple() async {
    await assertErrorsInCode('''
class C {
  num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 46, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterStatic_simple() async {
    await assertErrorsInCode('''
class C {
  static num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterTopLevel_simple() async {
    await assertErrorsInCode('''
int get x => 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 30, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_hasSuperSetter_simple() async {
    await assertErrorsInCode('''
// ignore:unused_import
import 'dart:math' as x;

class A {
  var x;
}

class B extends A {
  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 109, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@prefix::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_simple() async {
    await assertErrorsInCode('''
import 'dart:math' as x;

main() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 37, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@prefix::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariable_compound() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x += 3;
}
''');

    var assignment = findNode.assignment('x += 3');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@51
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: x@51
  readType: num
  writeElement: x@51
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_simpleIdentifier_localVariable_simple() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@51
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@51
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableConst_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  const num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableFinal_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  final num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull() async {
    await assertNoErrorsInCode('''
void f(num? x) {
  x ??= 0;
}
''');

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: self::@function::f::@parameter::x
  readType: num?
  writeElement: self::@function::f::@parameter::x
  writeType: num?
  staticElement: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull2() async {
    await assertErrorsInCode('''
class A {}
class B extends A {}
class C extends A {}

void f(B? x) {
  x ??= C();
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 77, 3),
    ]);

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: C
          staticElement: self::@class::C
          staticType: null
        type: C
      staticElement: self::@class::C::@constructor::•
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticType: C
  readElement: self::@function::f::@parameter::x
  readType: B?
  writeElement: self::@function::f::@parameter::x
  writeType: B?
  staticElement: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull_notAssignableType() async {
    await assertErrorsInCode('''
void f(double? a, int b) {
  a ??= b;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 1),
    ]);

    var assignment = findNode.assignment('a ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  readElement: self::@function::f::@parameter::a
  readType: double?
  writeElement: self::@function::f::@parameter::a
  writeType: double?
  staticElement: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_double() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x += 1.2;
  x -= 1.2;
  x *= 1.2;
  x %= 1.2;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 23, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 47, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 59, 3),
    ]);
    assertType(findNode.assignment('+='), 'double');
    assertType(findNode.assignment('-='), 'double');
    assertType(findNode.assignment('*='), 'double');
    assertType(findNode.assignment('%='), 'double');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x += 1;
  x -= 1;
  x *= 1;
  x ~/= 1;
  x %= 1;
}
''');
    assertType(findNode.assignment('+='), 'int');
    assertType(findNode.assignment('-='), 'int');
    assertType(findNode.assignment('*='), 'int');
    assertType(findNode.assignment('~/='), 'int');
    assertType(findNode.assignment('%='), 'int');
  }

  test_simpleIdentifier_parameter_simple() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_simple_context() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x is double) {
    x = 1;
  }
}
''');

    var assignment = findNode.assignment('x = 1');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: double
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: Object
  staticElement: <null>
  staticType: double
''');
  }

  test_simpleIdentifier_parameter_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 22, 4),
    ]);

    var assignment = findNode.assignment('x = true');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    parameter: <null>
    staticType: bool
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: int
  staticElement: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_parameterFinal_simple() async {
    await assertErrorsInCode('''
void f(final int x) {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 24, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticGetter_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

class B extends A {
  static int get x => 1;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 68, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 94, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::B::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticMethod_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

class B extends A {
  static void x() {}

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 90, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::B::@method::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_superSetter_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

class B extends A {
  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_synthetic_simple() async {
    await assertErrorsInCode('''
void f(int y) {
  = y;
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: <empty> <synthetic>
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_superGetter_simple() async {
    await assertNoErrorsInCode('''
class A {
  int x = 0;
}

class B extends A {
  int get x => 1;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_compound() async {
    await assertNoErrorsInCode('''
class C {
  int get x => 0;
  set x(num _) {}

  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::C::@getter::x
  readType: int
  writeElement: self::@class::C::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_fromMixins_compound() async {
    await assertNoErrorsInCode('''
class M1 {
  int get x => 0;
  set x(num _) {}
}

class M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::M2::@getter::x
  readType: int
  writeElement: self::@class::M2::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_ifNull() async {
    await assertNoErrorsInCode('''
class C {
  int? get x => 0;
  set x(num? _) {}

  void f() {
    x ??= 2;
  }
}
''');

    var assignment = findNode.assignment('x ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::C::@getter::x
  readType: int?
  writeElement: self::@class::C::@setter::x
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

int get x => 1;

class B extends A {

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 86, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound() async {
    await assertNoErrorsInCode('''
int get x => 0;
set x(num _) {}

void f() {
  x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@getter::x
  readType: int
  writeElement: self::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound_ifNull2() async {
    await assertErrorsInCode('''
void f() {
  x ??= C();
}

class A {}
class B extends A {}
class C extends A {}

B? get x => B();
set x(B? _) {}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 3),
    ]);

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: C
          staticElement: self::@class::C
          staticType: null
        type: C
      staticElement: self::@class::C::@constructor::•
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticType: C
  readElement: self::@getter::x
  readType: B?
  writeElement: self::@setter::x
  writeType: B?
  staticElement: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_topGetter_topSetter_fromClass_compound() async {
    await assertNoErrorsInCode('''
int get x => 0;
set x(num _) {}

class A {
  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@getter::x
  readType: int
  writeElement: self::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple() async {
    await assertNoErrorsInCode(r'''
num x = 0;

void f() {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
int x = 0;

void f() {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 4),
    ]);

    var assignment = findNode.assignment('x = true');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    parameter: self::@setter::x::@parameter::_x
    staticType: bool
  readElement: <null>
  readType: null
  writeElement: self::@setter::x
  writeType: int
  staticElement: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_topLevelVariableFinal_simple() async {
    await assertErrorsInCode(r'''
final num x = 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 31, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@getter::x
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_typeLiteral_compound() async {
    await assertErrorsInCode(r'''
void f() {
  int += 3;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var assignment = findNode.assignment('int += 3');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <null>
    staticType: int
  readElement: dart:core::@class::int
  readType: dynamic
  writeElement: dart:core::@class::int
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_simpleIdentifier_typeLiteral_simple() async {
    await assertErrorsInCode(r'''
void f() {
  int = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var assignment = findNode.assignment('int = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: dart:core::@class::int
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_unresolved_compound() async {
    await assertErrorsInCode(r'''
void f() {
  x += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 13, 1),
    ]);

    var assignment = findNode.assignment('x += 1');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_simpleIdentifier_unresolved_simple() async {
    await assertErrorsInCode(r'''
void f(int a) {
  x = a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('x = a');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    parameter: <null>
    staticElement: self::@function::f::@parameter::a
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: int
''');
  }
}
