// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideTest);
    defineReflectiveTests(ExtensionOverrideWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ExtensionOverrideTest extends PubPackageResolutionTest
    with ExtensionOverrideTestCases {
  test_indexExpression_read_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int operator [](int index) => 0;
}

void f(int? a) {
  E(a)?[0];
}
''');

    assertResolvedNodeText(findNode.index('[0]'), r'''
IndexExpression
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int?
      rightParenthesis: )
    extendedType: int
    staticType: null
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: self::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@extension::E::@method::[]
  staticType: int?
''');
  }

  test_indexExpression_write_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  operator []=(int index, int value) {}
}

void f(int? a) {
  E(a)?[0] = 1;
}
''');

    assertResolvedNodeText(findNode.assignment('[0] ='), r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: int?
        rightParenthesis: )
      extendedType: int
      staticType: null
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@extension::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@extension::E::@method::[]=::@parameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@method::[]=
  writeType: int
  staticElement: <null>
  staticType: int?
''');
  }

  test_methodInvocation_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int foo() => 0;
}

void f(int? a) {
  E(a)?.foo();
}
''');

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int?
      rightParenthesis: )
    extendedType: int
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@method::foo
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int?
''');
  }

  test_propertyAccess_getter_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int get foo => 0;
}

void f(int? a) {
  E(a)?.foo;
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('?.foo'),
      element: findElement.getter('foo'),
      type: 'int?',
    );
  }

  test_propertyAccess_setter_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  set foo(int _) {}
}

void f(int? a) {
  E(a)?.foo = 0;
}
''');
  }
}

mixin ExtensionOverrideTestCases on PubPackageResolutionTest {
  test_call_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int call(String s) => 0;
}
void f(A a) {
  E(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('E(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: self::@extension::E::@method::call
  staticInvokeType: int Function(String)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: self::@extension::E::@method::call
  staticInvokeType: int* Function(String*)*
  staticType: int*
''');
    }
  }

  test_call_noPrefix_typeArguments() async {
    // The test is failing because we're not yet doing type inference.
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int call(T s) => 0;
}
void f(A a) {
  E<String>(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      String
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: MethodMember
    base: self::@extension::E::@method::call
    substitution: {T: String}
  staticInvokeType: int Function(String)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      String*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: MethodMember
    base: self::@extension::E::@method::call
    substitution: {T: String*}
  staticInvokeType: int* Function(String*)*
  staticType: int*
''');
    }
  }

  test_call_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  int call(String s) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('E(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: package:test/lib.dart::@extension::E::@method::call
  staticInvokeType: int Function(String)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: package:test/lib.dart::@extension::E::@method::call
  staticInvokeType: int* Function(String*)*
  staticType: int*
''');
    }
  }

  test_call_prefix_typeArguments() async {
    // The test is failing because we're not yet doing type inference.
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  int call(T s) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<String>(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      String
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: MethodMember
    base: package:test/lib.dart::@extension::E::@method::call
    substitution: {T: String}
  staticInvokeType: int Function(String)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      String*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: MethodMember
    base: package:test/lib.dart::@extension::E::@method::call
    substitution: {T: String*}
  staticInvokeType: int* Function(String*)*
  staticType: int*
''');
    }
  }

  test_getter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int get g => 0;
}
void f(A a) {
  E(a).g;
}
''');

    var node = findNode.propertyAccess('E(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: self::@extension::E::@getter::g
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: self::@extension::E::@getter::g
    staticType: int*
  staticType: int*
''');
    }
  }

  test_getter_noPrefix_noTypeArguments_functionExpressionInvocation() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  double Function(int) get g => (b) => 2.0;
}

void f(A a) {
  E(a).g(0);
}
''');

    var node = findNode.functionExpressionInvocation('E(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: g
      staticElement: self::@extension::E::@getter::g
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: g
      staticElement: self::@extension::E::@getter::g
      staticType: double* Function(int*)*
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_getter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int get g => 0;
}
void f(A a) {
  E<int>(a).g;
}
''');

    var node = findNode.propertyAccess('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::g
      substitution: {T: int}
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      int*
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::g
      substitution: {T: int*}
    staticType: int*
  staticType: int*
''');
    }
  }

  test_getter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  int get g => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).g;
}
''');

    var node = findNode.propertyAccess('E(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: package:test/lib.dart::@extension::E::@getter::g
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: package:test/lib.dart::@extension::E::@getter::g
    staticType: int*
  staticType: int*
''');
    }
  }

  test_getter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  int get g => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).g;
}
''');

    var node = findNode.propertyAccess('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: PropertyAccessorMember
      base: package:test/lib.dart::@extension::E::@getter::g
      substitution: {T: int}
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      int*
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: PropertyAccessorMember
      base: package:test/lib.dart::@extension::E::@getter::g
      substitution: {T: int*}
    staticType: int*
  staticType: int*
''');
    }
  }

  test_method_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  void m() {}
}
void f(A a) {
  E(a).m();
}
''');

    var node = findNode.methodInvocation('E(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: self::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: self::@extension::E::@method::m
    staticType: void Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
  }

  test_method_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  void m() {}
}
void f(A a) {
  E<int>(a).m();
}
''');

    var node = findNode.methodInvocation('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: MethodMember
      base: self::@extension::E::@method::m
      substitution: {T: int}
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      int*
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: MethodMember
      base: self::@extension::E::@method::m
      substitution: {T: int*}
    staticType: void Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
  }

  test_method_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).m();
}
''');

    var node = findNode.methodInvocation('E(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: package:test/lib.dart::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: package:test/lib.dart::@extension::E::@method::m
    staticType: void Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
  }

  test_method_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).m();
}
''');

    var node = findNode.methodInvocation('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: MethodMember
      base: package:test/lib.dart::@extension::E::@method::m
      substitution: {T: int}
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      int*
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: MethodMember
      base: package:test/lib.dart::@extension::E::@method::m
      substitution: {T: int*}
    staticType: void Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
  }

  test_operator_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  void operator +(int offset) {}
}
void f(A a) {
  E(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: self::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: self::@extension::E::@method::+::@parameter::offset
    staticType: int*
  staticElement: self::@extension::E::@method::+
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_operator_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  void operator +(int offset) {}
}
void f(A a) {
  E<int>(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: self::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      int*
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: self::@extension::E::@method::+::@parameter::offset
    staticType: int*
  staticElement: self::@extension::E::@method::+
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_operator_onTearOff() async {
    // https://github.com/dart-lang/sdk/issues/38653
    await assertErrorsInCode('''
extension E on int {
  v() {}
}

f(){
  E(0).v++;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 45, 1),
    ]);

    var node = findNode.postfix('++;');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            parameter: <null>
            staticType: int
        rightParenthesis: )
      extendedType: int
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: v
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@extension::E::@method::v
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            parameter: <null>
            staticType: int*
        rightParenthesis: )
      extendedType: int*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: v
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: self::@extension::E::@method::v
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
    }
  }

  test_operator_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  void operator +(int offset) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: package:test/lib.dart::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: package:test/lib.dart::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: package:test/lib.dart::@extension::E::@method::+::@parameter::offset
    staticType: int*
  staticElement: package:test/lib.dart::@extension::E::@method::+
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_operator_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  void operator +(int offset) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: package:test/lib.dart::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: package:test/lib.dart::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: self::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      staticElement: package:test/lib.dart::@extension::E
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
    typeArgumentTypes
      int*
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: package:test/lib.dart::@extension::E::@method::+::@parameter::offset
    staticType: int*
  staticElement: package:test/lib.dart::@extension::E::@method::+
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_setter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  set s(int x) {}
}
void f(A a) {
  E(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@extension::E::@setter::s::@parameter::x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::s
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@extension::E::@setter::s::@parameter::x
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::s
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_setter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  set s(int x) {}
}
void f(A a) {
  E<int>(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: self::@extension::E::@setter::s::@parameter::x
      substitution: {T: int}
    staticType: int
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::s
    substitution: {T: int}
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int*
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
      typeArgumentTypes
        int*
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: self::@extension::E::@setter::s::@parameter::x
      substitution: {T: int*}
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::s
    substitution: {T: int*}
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_setter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: package:test/lib.dart::@extension::E::@setter::s::@parameter::x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/lib.dart::@extension::E::@setter::s
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: package:test/lib.dart::@extension::E::@setter::s::@parameter::x
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: package:test/lib.dart::@extension::E::@setter::s
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_setter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/lib.dart::@extension::E::@setter::s::@parameter::x
      substitution: {T: int}
    staticType: int
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/lib.dart::@extension::E::@setter::s
    substitution: {T: int}
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int*
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
      typeArgumentTypes
        int*
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/lib.dart::@extension::E::@setter::s::@parameter::x
      substitution: {T: int*}
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/lib.dart::@extension::E::@setter::s
    substitution: {T: int*}
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_setterAndGetter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int get s => 0;
  set s(int x) {}
}
void f(A a) {
  E(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@extension::E::@getter::s
  readType: int
  writeElement: self::@extension::E::@setter::s
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: self::@extension::E::@getter::s
  readType: int*
  writeElement: self::@extension::E::@setter::s
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_setterAndGetter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int get s => 0;
  set s(int x) {}
}
void f(A a) {
  E<int>(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: PropertyAccessorMember
    base: self::@extension::E::@getter::s
    substitution: {T: int}
  readType: int
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::s
    substitution: {T: int}
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: self::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int*
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
      typeArgumentTypes
        int*
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: PropertyAccessorMember
    base: self::@extension::E::@getter::s
    substitution: {T: int*}
  readType: int*
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::s
    substitution: {T: int*}
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_setterAndGetter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  int get s => 0;
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: package:test/lib.dart::@extension::E::@getter::s
  readType: int
  writeElement: package:test/lib.dart::@extension::E::@setter::s
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: package:test/lib.dart::@extension::E::@getter::s
  readType: int*
  writeElement: package:test/lib.dart::@extension::E::@setter::s
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_setterAndGetter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  int get s => 0;
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: PropertyAccessorMember
    base: package:test/lib.dart::@extension::E::@getter::s
    substitution: {T: int}
  readType: int
  writeElement: PropertyAccessorMember
    base: package:test/lib.dart::@extension::E::@setter::s
    substitution: {T: int}
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: E
          staticElement: package:test/lib.dart::@extension::E
          staticType: null
        staticElement: package:test/lib.dart::@extension::E
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int*
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A*
      staticType: null
      typeArgumentTypes
        int*
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: PropertyAccessorMember
    base: package:test/lib.dart::@extension::E::@getter::s
    substitution: {T: int*}
  readType: int*
  writeElement: PropertyAccessorMember
    base: package:test/lib.dart::@extension::E::@setter::s
    substitution: {T: int*}
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_tearOff() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
}

f(C c) => E(c).a;
''');

    var node = findNode.propertyAccess('E(c)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: c
          parameter: <null>
          staticElement: self::@function::f::@parameter::c
          staticType: C
      rightParenthesis: )
    extendedType: C
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: self::@extension::E::@method::a
    staticType: void Function(int)
  staticType: void Function(int)
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: c
          parameter: <null>
          staticElement: self::@function::f::@parameter::c
          staticType: C*
      rightParenthesis: )
    extendedType: C*
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: self::@extension::E::@method::a
    staticType: void Function(int*)*
  staticType: void Function(int*)*
''');
    }
  }
}

@reflectiveTest
class ExtensionOverrideWithoutNullSafetyTest extends PubPackageResolutionTest
    with ExtensionOverrideTestCases, WithoutNullSafetyMixin {}
