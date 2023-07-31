// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantPatternWithNonConstantExpressionTest);
  });
}

@reflectiveTest
class ConstantPatternWithNonConstantExpressionTest
    extends PubPackageResolutionTest {
  test_boolLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case true) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
      staticType: bool
    matchedValueType: dynamic
''');
  }

  test_class_field_const() async {
    await assertNoErrorsInCode(r'''
class A {
  static const a = 0;
}

void f(x) {
  if (x case A.a) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        staticElement: self::@class::A::@getter::a
        staticType: int
      staticElement: self::@class::A::@getter::a
      staticType: int
    matchedValueType: dynamic
''');
  }

  test_class_field_notConst() async {
    await assertErrorsInCode(r'''
class A {
  static final a = 0;
}

void f(x) {
  if (x case A.a) {}
}
''', [
      error(CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
          60, 3),
    ]);
  }

  test_doubleLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 1.2) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.2
      staticType: double
    matchedValueType: dynamic
''');
  }

  test_importPrefix_class_field_const() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.A.a) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
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
        token: a
        staticElement: package:test/a.dart::@class::A::@getter::a
        staticType: int
      staticType: int
    matchedValueType: dynamic
''');
  }

  test_importPrefix_class_field_notConst() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.A.a) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
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
        token: a
        staticElement: package:test/a.dart::@class::A::@getter::a
        staticType: int
      staticType: int
    matchedValueType: dynamic
''');
  }

  test_instanceCreation_const() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

void f(x) {
  if (x case const A()) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
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

  test_intLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 0
      staticType: int
    matchedValueType: dynamic
''');
  }

  test_listLiteral_element_intLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const [0]) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
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

  test_listLiteral_element_localVariable_const() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  if (x case const [a]) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      elements
        SimpleIdentifier
          token: a
          staticElement: a@20
          staticType: int
      rightBracket: ]
      staticType: List<int>
    matchedValueType: dynamic
''');
  }

  test_listLiteral_element_localVariable_notConst() async {
    await assertErrorsInCode(r'''
void f(x) {
  final a = 0;
  if (x case const [a]) {}
}
''', [
      error(CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
          47, 1),
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
    ]);
  }

  test_localVariable_const() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  if (x case a) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: a
      staticElement: a@20
      staticType: int
    matchedValueType: dynamic
''');
  }

  test_localVariable_notConst() async {
    await assertErrorsInCode(r'''
void f(x) {
  var a = 0;
  if (x case a) {}
}
''', [
      error(CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
          38, 1),
    ]);
  }

  test_mapLiteral_entries_intLiteral_intLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const {0: 1}) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
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

  test_mapLiteral_entries_key_localVariable_const() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  if (x case const {a: 1}) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        SetOrMapLiteral
          key: SimpleIdentifier
            token: a
            staticElement: a@20
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

  test_mapLiteral_entries_key_localVariable_notConst() async {
    await assertErrorsInCode(r'''
void f(x) {
  final a = 0;
  if (x case const {a: 1}) {}
}
''', [
      error(CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
          47, 1),
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 47, 1),
    ]);
  }

  test_mapLiteral_entries_value_localVariable_const() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  if (x case const {0: a}) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        SetOrMapLiteral
          key: IntegerLiteral
            literal: 0
            staticType: int
          separator: :
          value: SimpleIdentifier
            token: a
            staticElement: a@20
            staticType: int
      rightBracket: }
      isMap: true
      staticType: Map<int, int>
    matchedValueType: dynamic
''');
  }

  test_mapLiteral_entries_value_localVariable_notConst() async {
    await assertErrorsInCode(r'''
void f(x) {
  final a = 0;
  if (x case const {0: a}) {}
}
''', [
      error(CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
          50, 1),
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 50, 1),
    ]);
  }

  test_setLiteral_element_intLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const {0}) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        IntegerLiteral
          literal: 0
          staticType: int
      rightBracket: }
      isMap: false
      staticType: Set<int>
    matchedValueType: dynamic
''');
  }

  test_setLiteral_element_localVariable_const() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  if (x case const {a}) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        SimpleIdentifier
          token: a
          staticElement: a@20
          staticType: int
      rightBracket: }
      isMap: false
      staticType: Set<int>
    matchedValueType: dynamic
''');
  }

  test_switch_constPattern_parameter() async {
    await assertErrorsInCode(r'''
void f(var e, int a) {
  switch (e) {
    case const (3 + a):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
          58, 1),
    ]);
  }

  test_topLevelVariable_const() async {
    await assertNoErrorsInCode(r'''
const a = 0;

void f(x) {
  if (x case a) {}
}
''');

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: a
      staticElement: self::@getter::a
      staticType: int
    matchedValueType: dynamic
''');
  }

  test_topLevelVariable_notConst() async {
    await assertErrorsInCode(r'''
final a = 0;

void f(x) {
  if (x case a) {}
}
''', [
      error(CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION,
          39, 1),
    ]);

    var node = findNode.singleGuardedPattern;
    assertResolvedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: a
      staticElement: self::@getter::a
      staticType: int
    matchedValueType: dynamic
''');
  }
}
