// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalExpressionTest);
    defineReflectiveTests(ConditionalExpressionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ConditionalExpressionTest extends PubPackageResolutionTest
    with ConditionalExpressionTestCases {
  @failingTest
  test_downward() async {
    await resolveTestCode('''
void f(int b, int c) {
  var d = a() ? b : c;
  print(d);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('d)'), 'bool Function()');
  }

  test_issue49692() async {
    await assertErrorsInCode('''
T f<T>(T t, bool b) {
  if (t is int) {
    final u = b ? t : null;
    return u;
  } else {
    return t;
  }
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 79, 1),
    ]);

    final node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: t
    staticElement: self::@function::f::@parameter::t
    staticType: T & int
  colon: :
  elseExpression: NullLiteral
    literal: null
    staticType: Null
  staticType: (T & int)?
''');
  }

  test_recordType_differentShape() async {
    await assertNoErrorsInCode('''
void f(bool b, (int, String) r1, ({int a}) r2) {
  b ? r1 : r2;
}
''');

    final node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: r1
    staticElement: self::@function::f::@parameter::r1
    staticType: (int, String)
  colon: :
  elseExpression: SimpleIdentifier
    token: r2
    staticElement: self::@function::f::@parameter::r2
    staticType: ({int a})
  staticType: Record
''');
  }

  test_recordType_sameShape_named() async {
    await assertNoErrorsInCode('''
void f(bool b, ({int a}) r1, ({double a}) r2) {
  b ? r1 : r2;
}
''');

    final node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: r1
    staticElement: self::@function::f::@parameter::r1
    staticType: ({int a})
  colon: :
  elseExpression: SimpleIdentifier
    token: r2
    staticElement: self::@function::f::@parameter::r2
    staticType: ({double a})
  staticType: ({num a})
''');
  }

  test_type() async {
    await assertNoErrorsInCode('''
void f(bool b) {
  b ? 42 : null;
}
''');
    assertType(findNode.conditionalExpression('b ?'), 'int?');
  }
}

mixin ConditionalExpressionTestCases on PubPackageResolutionTest {
  test_upward() async {
    await resolveTestCode('''
void f(bool a, int b, int c) {
  var d = a ? b : c;
  print(d);
}
''');
    assertType(findNode.simple('d)'), 'int');
  }
}

@reflectiveTest
class ConditionalExpressionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ConditionalExpressionTestCases, WithoutNullSafetyMixin {}
