// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantPatternResolutionTest);
  });
}

@reflectiveTest
class ConstantPatternResolutionTest extends PubPackageResolutionTest {
  test_expression_class_field() async {
    await assertNoErrorsInCode(r'''
class A {
  static const foo = 0;
}

void f(x) {
  if (x case A.foo) {}
}
''');

    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: int
    staticElement: self::@class::A::@getter::foo
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_instanceCreation() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

void f(x) {
  if (x case const A()) {}
}
''');

    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: A
          staticElement: self::@class::A
          staticType: null
        type: A
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  matchedValueType: dynamic
''');
  }

  test_expression_integerLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_integerLiteral_contextType_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: double
  matchedValueType: double
''');
  }

  test_expression_listLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const [0]) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    leftBracket: [
    elements
      IntegerLiteral
        literal: 0
        staticType: int
    rightBracket: ]
    staticType: List<int>
  matchedValueType: dynamic
''');
  }

  test_expression_mapLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const {0: 1}) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    leftBracket: {
    elements
      SetOrMapLiteral
        key: IntegerLiteral
          literal: 0
          staticType: int
        separator: :
        value: IntegerLiteral
          literal: 1
          staticType: int
    rightBracket: }
    isMap: true
    staticType: Map<int, int>
  matchedValueType: dynamic
''');
  }

  test_expression_prefix_class_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const foo = 0;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.A.foo) {}
}
''');

    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: package:test/a.dart::@class::A
        staticType: null
      staticElement: package:test/a.dart::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@class::A::@getter::foo
      staticType: int
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_prefix_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.foo) {}
}
''');

    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@getter::foo
      staticType: int
    staticElement: package:test/a.dart::@getter::foo
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_setLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const {0, 1}) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    leftBracket: {
    elements
      IntegerLiteral
        literal: 0
        staticType: int
      IntegerLiteral
        literal: 1
        staticType: int
    rightBracket: }
    isMap: false
    staticType: Set<int>
  matchedValueType: dynamic
''');
  }

  test_expression_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
const foo = 0;

void f(x) {
  if (x case foo) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_location_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_location_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }
}
