// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        FunctionReferenceResolution_genericFunctionInstantiationTest);
    defineReflectiveTests(FunctionReferenceResolutionTest);
    defineReflectiveTests(
        FunctionReferenceResolutionWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class FunctionReferenceResolution_genericFunctionInstantiationTest
    extends PubPackageResolutionTest {
  test_asExpression() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) f) {
  return (f as dynamic) as void Function<T>(T);
}
''');

    assertResolvedNodeText(
        findNode.functionReference('as void Function<T>(T);'), r'''
FunctionReference
  function: AsExpression
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: AsExpression
        expression: SimpleIdentifier
          token: f
          staticElement: self::@function::foo::@parameter::f
          staticType: void Function<T>(T)
        asOperator: as
        type: NamedType
          name: SimpleIdentifier
            token: dynamic
            staticElement: dynamic@-1
            staticType: null
          type: dynamic
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    asOperator: as
    type: GenericFunctionType
      returnType: NamedType
        name: SimpleIdentifier
          token: void
          staticElement: <null>
          staticType: null
        type: void
      functionKeyword: Function
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: SimpleIdentifier
              token: T
              staticElement: T@89
              staticType: null
            declaredElement: T@89
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: SimpleIdentifier
              token: T
              staticElement: T@89
              staticType: null
            type: T
          declaredElement: @-1
          declaredElementType: T
        rightParenthesis: )
      declaredElement: GenericFunctionTypeElement
        parameters
          <empty>
            kind: required positional
            type: T
        returnType: void
        type: void Function<T>(T)
      type: void Function<T>(T)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_assignmentExpression() async {
    await assertNoErrorsInCode('''
late void Function<T>(T) g;
void Function(int) foo(void Function<T>(T) f) {
  return g = f;
}
''');

    assertResolvedNodeText(findNode.functionReference('g = f;'), r'''
FunctionReference
  function: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: g
      staticElement: <null>
      staticType: null
    operator: =
    rightHandSide: SimpleIdentifier
      token: f
      parameter: self::@setter::g::@parameter::_g
      staticElement: self::@function::foo::@parameter::f
      staticType: void Function<T>(T)
    readElement: <null>
    readType: null
    writeElement: self::@setter::g
    writeType: void Function<T>(T)
    staticElement: <null>
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_assignmentExpression_compound() async {
    await assertNoErrorsInCode('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return f += 1;
}
''');

    assertResolvedNodeText(findNode.functionReference('f += 1'), r'''
FunctionReference
  function: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: f
      staticElement: self::@function::foo::@parameter::f
      staticType: null
    operator: +=
    rightHandSide: IntegerLiteral
      literal: 1
      parameter: self::@extension::0::@method::+::@parameter::i
      staticType: int
    readElement: self::@function::foo::@parameter::f
    readType: void Function<T>(T)
    writeElement: self::@function::foo::@parameter::f
    writeType: void Function<T>(T)
    staticElement: self::@extension::0::@method::+
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_awaitExpression() async {
    await assertNoErrorsInCode('''
Future<void Function(int)> foo(Future<void Function<T>(T)> f) async {
  return await f;
}
''');

    assertResolvedNodeText(findNode.functionReference('await f'), r'''
FunctionReference
  function: AwaitExpression
    awaitKeyword: await
    expression: SimpleIdentifier
      token: f
      staticElement: self::@function::foo::@parameter::f
      staticType: Future<void Function<T>(T)>
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_binaryExpression() async {
    await assertNoErrorsInCode('''
class C {
  void Function<T>(T) operator +(int i) {
    return <T>(T a) {};
  }
}

void Function(int) foo(C c) {
  return c + 1;
}
''');

    assertResolvedNodeText(findNode.functionReference('c + 1'), r'''
FunctionReference
  function: BinaryExpression
    leftOperand: SimpleIdentifier
      token: c
      staticElement: self::@function::foo::@parameter::c
      staticType: C
    operator: +
    rightOperand: IntegerLiteral
      literal: 1
      parameter: self::@class::C::@method::+::@parameter::i
      staticType: int
    staticElement: self::@class::C::@method::+
    staticInvokeType: void Function<T>(T) Function(int)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_cascadeExpression() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) f) {
  return f..toString();
}
''');

    assertResolvedNodeText(findNode.functionReference('f..toString()'), r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    staticElement: self::@function::foo::@parameter::f
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_constructorReference() async {
    await assertNoErrorsInCode('''
class C<T> {
  C(T a);
}
C<int> Function(int) foo() {
  return C.new;
}
''');

    // TODO(srawlins): Leave the constructor reference uninstantiated, then
    // perform generic function instantiation as a wrapping node.
    assertResolvedNodeText(findNode.constructorReference('C.new'), r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: C
        staticElement: self::@class::C
        staticType: null
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: self::@class::C::@constructor::•
      staticType: null
      tearOffTypeArgumentTypes
        int
    staticElement: self::@class::C::@constructor::•
  staticType: C<int> Function(int)
''');
  }

  test_functionExpression() async {
    await assertNoErrorsInCode('''
Null Function(int) foo() {
  return <T>(T a) {};
}
''');

    assertResolvedNodeText(findNode.functionReference('<T>(T a) {};'), r'''
FunctionReference
  function: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: SimpleIdentifier
            token: T
            staticElement: T@37
            staticType: null
          declaredElement: T@37
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: SimpleIdentifier
            token: T
            staticElement: T@37
            staticType: null
          type: T
        identifier: SimpleIdentifier
          token: a
          staticElement: @36::@parameter::a
          staticType: null
        declaredElement: @36::@parameter::a
        declaredElementType: T
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: @36
    staticType: Null Function<T>(T)
  staticType: Null Function(int)
  typeArgumentTypes
    int
''');
  }

  test_functionExpressionInvocation() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) Function() f) {
  return (f)();
}
''');

    assertResolvedNodeText(findNode.functionReference('(f)()'), r'''
FunctionReference
  function: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: f
        staticElement: self::@function::foo::@parameter::f
        staticType: void Function<T>(T) Function()
      rightParenthesis: )
      staticType: void Function<T>(T) Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: void Function<T>(T) Function()
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_functionReference() async {
    await assertNoErrorsInCode('''
typedef Fn = void Function<U>(U);

void Function(int) foo(Fn f) {
  return f;
}
''');

    assertResolvedNodeText(findNode.functionReference('f;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    staticElement: self::@function::foo::@parameter::f
    staticType: void Function<U>(U)
      alias: self::@typeAlias::Fn
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallReference() async {
    await assertNoErrorsInCode('''
class C {
  void call<T>(T a) {}
}

void Function(int) foo(C c) {
  return c;
}
''');

    assertImplicitCallReference(findNode.implicitCallReference('c;'),
        findElement.method('call'), 'void Function(int)');
  }

  test_indexExpression() async {
    await assertNoErrorsInCode('''
void Function(int) foo(List<void Function<T>(T)> f) {
  return f[0];
}
''');

    assertResolvedNodeText(findNode.functionReference('f[0];'), r'''
FunctionReference
  function: IndexExpression
    target: SimpleIdentifier
      token: f
      staticElement: self::@function::foo::@parameter::f
      staticType: List<void Function<T>(T)>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: ParameterMember
        base: dart:core::@class::List::@method::[]::@parameter::index
        substitution: {E: void Function<T>(T)}
      staticType: int
    rightBracket: ]
    staticElement: MethodMember
      base: dart:core::@class::List::@method::[]
      substitution: {E: void Function<T>(T)}
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_methodInvocation() async {
    await assertNoErrorsInCode('''
class C {
  late void Function<T>(T) f;
  void Function<T>(T) m() => f;
}

void Function(int) foo(C c) {
  return c.m();
}
''');

    assertResolvedNodeText(findNode.functionReference('c.m();'), r'''
FunctionReference
  function: MethodInvocation
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::foo::@parameter::c
      staticType: C
    operator: .
    methodName: SimpleIdentifier
      token: m
      staticElement: self::@class::C::@method::m
      staticType: void Function<T>(T) Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: void Function<T>(T) Function()
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_postfixExpression_compound() async {
    await assertNoErrorsInCode('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return f++;
}
''');

    assertResolvedNodeText(findNode.functionReference('f++'), r'''
FunctionReference
  function: PostfixExpression
    operand: SimpleIdentifier
      token: f
      staticElement: self::@function::foo::@parameter::f
      staticType: null
    operator: ++
    readElement: self::@function::foo::@parameter::f
    readType: void Function<T>(T)
    writeElement: self::@function::foo::@parameter::f
    writeType: void Function<T>(T)
    staticElement: self::@extension::0::@method::+
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class C {
  late void Function<T>(T) f;
}

void Function(int) foo(C c) {
  return c.f;
}
''');

    assertResolvedNodeText(findNode.functionReference('c.f;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      staticElement: self::@function::foo::@parameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: f
      staticElement: self::@class::C::@getter::f
      staticType: void Function<T>(T)
    staticElement: self::@class::C::@getter::f
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_prefixExpression_compound() async {
    await assertNoErrorsInCode('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return ++f;
}
''');

    assertResolvedNodeText(findNode.functionReference('++f'), r'''
FunctionReference
  function: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: f
      staticElement: self::@function::foo::@parameter::f
      staticType: null
    readElement: self::@function::foo::@parameter::f
    readType: void Function<T>(T)
    writeElement: self::@function::foo::@parameter::f
    writeType: void Function<T>(T)
    staticElement: self::@extension::0::@method::+
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_propertyAccess() async {
    await assertNoErrorsInCode('''
class C {
  late void Function<T>(T) f;
}

void Function(int) foo(C c) {
  return (c).f;
}
''');

    assertResolvedNodeText(findNode.functionReference('(c).f;'), r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        staticElement: self::@function::foo::@parameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: f
      staticElement: self::@class::C::@getter::f
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_simpleIdentifier() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) f) {
  return f;
}
''');

    assertResolvedNodeText(findNode.functionReference('f;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    staticElement: self::@function::foo::@parameter::f
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }
}

@reflectiveTest
class FunctionReferenceResolutionTest extends PubPackageResolutionTest {
  test_constructorFunction_named() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo() {}
}

var x = (A.foo)<int>;
''');

    assertResolvedNodeText(findNode.functionReference('(A.foo)<int>;'), r'''
FunctionReference
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: ConstructorReference
      constructorName: ConstructorName
        type: NamedType
          name: SimpleIdentifier
            token: A
            staticElement: self::@class::A
            staticType: null
          type: null
        period: .
        name: SimpleIdentifier
          token: foo
          staticElement: self::@class::A::@constructor::foo
          staticType: null
        staticElement: self::@class::A::@constructor::foo
      staticType: A<T> Function<T>()
    rightParenthesis: )
    staticType: A<T> Function<T>()
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
  staticType: A<int> Function()
  typeArgumentTypes
    int
''');
  }

  test_constructorFunction_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}

var x = (A.new)<int>;
''');

    assertResolvedNodeText(findNode.functionReference('(A.new)<int>;'), r'''
FunctionReference
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: ConstructorReference
      constructorName: ConstructorName
        type: NamedType
          name: SimpleIdentifier
            token: A
            staticElement: self::@class::A
            staticType: null
          type: null
        period: .
        name: SimpleIdentifier
          token: new
          staticElement: self::@class::A::@constructor::•
          staticType: null
        staticElement: self::@class::A::@constructor::•
      staticType: A<T> Function<T>()
    rightParenthesis: )
    staticType: A<T> Function<T>()
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
  staticType: A<int> Function()
  typeArgumentTypes
    int
''');
  }

  test_constructorReference() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo() {}
}

var x = A.foo<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 42,
          5,
          messageContains: ["'A.foo'"]),
    ]);

    assertResolvedNodeText(findNode.functionReference('A.foo<int>;'), r'''
FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: A
          staticElement: self::@class::A
          staticType: null
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        staticElement: self::@class::A::@constructor::foo
        staticType: null
      staticElement: self::@class::A::@constructor::foo
    staticType: A<T> Function<T>()
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
  staticType: dynamic
''');
  }

  test_constructorReference_prefixed() async {
    await assertErrorsInCode('''
import 'dart:async' as a;
var x = a.Future.delayed<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 50,
          5,
          messageContains: ["'a.Future.delayed'"]),
    ]);
    assertResolvedNodeText(
        findNode.functionReference('a.Future.delayed<int>;'), r'''
FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: PrefixedIdentifier
          prefix: SimpleIdentifier
            token: a
            staticElement: self::@prefix::a
            staticType: null
          period: .
          identifier: SimpleIdentifier
            token: Future
            staticElement: dart:async::@class::Future
            staticType: null
          staticElement: dart:async::@class::Future
          staticType: null
        type: null
      period: .
      name: SimpleIdentifier
        token: delayed
        staticElement: dart:async::@class::Future::@constructor::delayed
        staticType: null
      staticElement: dart:async::@class::Future::@constructor::delayed
    staticType: Future<T> Function<T>(Duration, [FutureOr<T> Function()?])
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
  staticType: dynamic
''');
  }

  test_dynamicTyped() async {
    await assertErrorsInCode('''
dynamic i = 1;

void bar() {
  i<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 31, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('i<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    staticElement: self::@getter::i
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_dynamicTyped_targetOfMethodCall() async {
    await assertErrorsInCode('''
dynamic i = 1;

void bar() {
  i<int>.foo();
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 31, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('i<int>.foo();'), r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    staticElement: self::@getter::i
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_explicitReceiver_dynamicTyped() async {
    await assertErrorsInCode('''
dynamic f() => 1;

foo() {
  f().instanceMethod<int>;
}
''', [
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          29, 23),
    ]);

    assertResolvedNodeText(
        findNode.functionReference('f().instanceMethod<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: MethodInvocation
      methodName: SimpleIdentifier
        token: f
        staticElement: self::@function::f
        staticType: dynamic Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: instanceMethod
      staticElement: <null>
      staticType: dynamic
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_explicitReceiver_unknown() async {
    await assertErrorsInCode('''
bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_explicitReceiver_unknown_multipleProperties() async {
    await assertErrorsInCode('''
bar() {
  a.b.foo<int>;
}
''', [
      // TODO(srawlins): Get the information to [FunctionReferenceResolve] that
      //  [PropertyElementResolver] encountered an error, to avoid double reporting.
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          10, 12),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: <null>
        staticType: dynamic
      period: .
      identifier: SimpleIdentifier
        token: b
        staticElement: <null>
        staticType: dynamic
      staticElement: <null>
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_extension() async {
    await assertErrorsInCode('''
extension E<T> on String {}

void foo() {
  E<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 44, 1),
    ]);

    var reference = findNode.functionReference('E<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: E
    staticElement: self::@extension::E
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_extension_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
extension E<T> on String {}
''');
    await assertErrorsInCode('''
import 'a.dart' as a;

void foo() {
  a.E<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 38, 3),
    ]);

    assertImportPrefix(findNode.simple('a.E'), findElement.prefix('a'));
    var reference = findNode.functionReference('E<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: E
      staticElement: package:test/a.dart::@extension::E
      staticType: dynamic
    staticElement: package:test/a.dart::@extension::E
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_extensionGetter_extensionOverride() async {
    await assertErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 67, 8),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
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
            staticElement: self::@function::bar::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@extension::E::@getter::foo
      staticType: int
    staticType: int
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
  staticType: dynamic
''');
  }

  test_extensionMethod() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_explicitReceiver_this() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

extension E on A {
  void foo<T>(T a) {}
}

bar(A a) {
  E(a).foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
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
            staticElement: self::@function::bar::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_cascade() async {
    await assertErrorsInCode('''
class A {
  int foo = 0;
}

extension E on A {
  void foo<T>(T a) {}
}

bar(A a) {
  E(a)..foo<int>;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE, 85, 1),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_static() async {
    await assertErrorsInCode('''
class A {}

extension E on A {
  static void foo<T>(T a) {}
}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER, 81,
          3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
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
            staticElement: self::@function::bar::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_unknown() async {
    await assertErrorsInCode('''
class A {}

extension E on A {}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 51, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
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
            staticElement: self::@function::bar::@parameter::a
            staticType: A
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_extensionMethod_fromClassDeclaration() async {
    await assertNoErrorsInCode('''
class A {
  bar() {
    foo<int>;
  }
}

extension E on A {
  void foo<T>(T a) {}
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_unknown() async {
    await assertErrorsInCode('''
extension on double {
  bar() {
    foo<int>;
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 24, 3),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 36, 3,
          messageContains: ["for the type 'double'"]),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_function_call() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo.call<int>;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo.call<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: null
    staticElement: <null>
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_function_call_tooFewTypeArgs() async {
    await assertErrorsInCode('''
void foo<T, U>(T a, U b) {}

void bar() {
  foo.call<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 52, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo.call<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: void Function<T, U>(T, U)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: null
    staticElement: <null>
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
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_function_call_tooManyTypeArgs() async {
    await assertErrorsInCode('''
void foo(String a) {}

void bar() {
  foo.call<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 46, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo.call<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: void Function(String)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: null
    staticElement: <null>
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
  staticType: void Function(String)
''');
  }

  test_function_call_typeArgNotMatchingBound() async {
    await assertNoErrorsInCode('''
void foo<T extends num>(T a) {}

void bar() {
  foo.call<String>;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo.call<String>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: void Function<T extends num>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: null
    staticElement: <null>
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
  staticType: void Function(String)
  typeArgumentTypes
    String
''');
  }

  test_function_extensionOnFunction() async {
    // TODO(srawlins): Test extension on function type, like
    // `extension on void Function<T>(T)`.
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo.m<int>;
}

extension on Function {
  void m<T>(T t) {}
}
''');

    assertResolvedNodeText(findNode.functionReference('foo.m<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: m
      staticElement: self::@extension::0::@method::m
      staticType: null
    staticElement: self::@extension::0::@method::m
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_function_extensionOnFunction_static() async {
    await assertErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo.m<int>;
}

extension on Function {
  static void m<T>(T t) {}
}
''', [
      error(
          CompileTimeErrorCode
              .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
          40,
          1),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo.m<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: m
      staticElement: self::@extension::0::@method::m
      staticType: null
    staticElement: self::@extension::0::@method::m
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

foo() {
  C()<int>;
}
''');

    assertImplicitCallReference(findNode.implicitCallReference('C()<int>;'),
        findElement.method('call'), 'int Function(int)');
  }

  test_implicitCallTearoff_class_staticGetter() async {
    await assertNoErrorsInCode('''
class C {
  static const v = C();
  const C();
  T call<T>(T t) => t;
}

void f() {
  C.v<int>;
}
''');

    var node = findNode.implicitCallReference('C.v<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: v
      staticElement: self::@class::C::@getter::v
      staticType: null
    staticElement: self::@class::C::@getter::v
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
  staticElement: self::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_extensionOnNullable() async {
    await assertNoErrorsInCode('''
Object? v = null;
extension E on Object? {
  void call<R, S>(R r, S s) {}
}
void foo() {
  v<int, String>;
}

''');

    assertImplicitCallReference(
        findNode.implicitCallReference('v<int, String>;'),
        findElement.method('call'),
        'void Function(int, String)');
  }

  test_implicitCallTearoff_prefix_class_staticGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static const v = C();
  const C();
  T call<T>(T t) => t;
}
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.C.v<int>;
}
''');

    var node = findNode.implicitCallReference('C.v<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        staticElement: package:test/a.dart::@class::C
        staticType: null
      staticElement: package:test/a.dart::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: v
      staticElement: package:test/a.dart::@class::C::@getter::v
      staticType: C
    staticType: C
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
  staticElement: package:test/a.dart::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  T call<T>(T t) => t;
}
C c = C();
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.c<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    assertImplicitCallReference(
        findNode.implicitCallReference('c<int>;'),
        findElement.importFind('package:test/a.dart').method('call'),
        'int Function(int)');
  }

  test_implicitCallTearoff_tooFewTypeArguments() async {
    await assertErrorsInCode('''
class C {
  void call<T, U>(T t, U u) {}
}

foo() {
  C()<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 57, 5),
    ]);

    assertImplicitCallReference(findNode.implicitCallReference('C()<int>;'),
        findElement.method('call'), 'void Function(dynamic, dynamic)');
  }

  test_implicitCallTearoff_tooManyTypeArguments() async {
    await assertErrorsInCode('''
class C {
  int call(int t) => t;
}

foo() {
  C()<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 50, 5),
    ]);

    assertImplicitCallReference(findNode.implicitCallReference('C()<int>;'),
        findElement.method('call'), 'int Function(int)');
  }

  test_instanceGetter_explicitReceiver() async {
    await assertNoErrorsInCode('''
class A {
  late void Function<T>(T) foo;
}

bar(A a) {
  a.foo<int>;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::bar::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: null
    staticElement: self::@class::A::@getter::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_functionTyped() async {
    await assertNoErrorsInCode('''
abstract class A {
  late void Function<T>(T) foo;

  bar() {
    foo<int>;
  }
}

''');

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_functionTyped_inherited() async {
    await assertNoErrorsInCode('''
abstract class A {
  late void Function<T>(T) foo;
}
abstract class B extends A {
  bar() {
    foo<int>;
  }
}

''');

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_nonFunctionType() async {
    await assertErrorsInCode('''
abstract class A {
  List<int> get f;
}

void foo(A a) {
  a.f<String>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 61, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('f<String>'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::foo::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: f
      staticElement: self::@class::A::@getter::f
      staticType: List<int>
    staticElement: self::@class::A::@getter::f
    staticType: List<int>
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
  staticType: dynamic
''');
  }

  test_instanceGetter_nonFunctionType_propertyAccess() async {
    await assertErrorsInCode('''
abstract class A {
  List<int> get f;
}

void foo(A a) {
  (a).f<String>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 63, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('f<String>'), r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::foo::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: f
      staticElement: self::@class::A::@getter::f
      staticType: List<int>
    staticType: List<int>
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
  staticType: dynamic
''');
  }

  test_instanceMethod() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_call() async {
    await assertNoErrorsInCode('''
class C {
  void foo<T>(T a) {}

  void bar() {
    foo.call<int>;
  }
}
''');

    var reference = findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@method::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_call() async {
    await assertNoErrorsInCode('''
class C {
  void foo<T>(T a) {}
}

void bar(C c) {
  c.foo.call<int>;
}
''');

    var reference = findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: c
        staticElement: self::@function::bar::@parameter::c
        staticType: C
      period: .
      identifier: SimpleIdentifier
        token: foo
        staticElement: self::@class::C::@method::foo
        staticType: void Function<T>(T)
      staticElement: self::@class::C::@method::foo
      staticType: void Function<T>(T)
    operator: .
    propertyName: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_field() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B {
  A a;
  B(this.a);
  bar() {
    a.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@class::B::@getter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: null
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_getter_wrongNumberOfTypeArguments() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A a) {
  // Extra `()` to force reading the type.
  ((a).foo<double>);
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 97, 3),
    ]);

    var reference = findNode.functionReference('foo<double>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
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
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: int
    staticType: int
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        type: double
    rightBracket: >
  staticType: dynamic
''');
  }

  test_instanceMethod_explicitReceiver_otherExpression() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

void f(A? a, A b) {
  (a ?? b).foo<int>;
}
''');

    assertResolvedNodeText(
        findNode.functionReference('(a ?? b).foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
          staticElement: self::@function::f::@parameter::a
          staticType: A?
        operator: ??
        rightOperand: SimpleIdentifier
          token: b
          parameter: <null>
          staticElement: self::@function::f::@parameter::b
          staticType: A
        staticElement: <null>
        staticInvokeType: null
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_receiverIsNotIdentifier_call() async {
    await assertNoErrorsInCode('''
extension on List<Object?> {
  void foo<T>(T a) {}
}

var a = [].foo.call<int>;
''');

    var reference = findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PropertyAccess
      target: ListLiteral
        leftBracket: [
        rightBracket: ]
        staticType: List<dynamic>
      operator: .
      propertyName: SimpleIdentifier
        token: foo
        staticElement: self::@extension::0::@method::foo
        staticType: void Function<T>(T)
      staticType: void Function<T>(T)
    operator: .
    propertyName: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_super() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}
class B extends A {
  bar() {
    super.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_super_noMethod() async {
    await assertErrorsInCode('''
class A {
  bar() {
    super.foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 24, 9),
      error(CompileTimeErrorCode.UNDEFINED_SUPER_GETTER, 30, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_instanceMethod_explicitReceiver_super_noSuper() async {
    await assertErrorsInCode('''
bar() {
  super.foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 10, 9),
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 10, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_instanceMethod_explicitReceiver_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a.foo<int>.m();
}
''');

    var reference = findNode.functionReference('foo<int>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::bar::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: null
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_this() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}
var a = A();

void bar() {
  a.foo<int>;
}
''');

    assertIdentifierTopGetRef(findNode.simple('a.'), 'a');
    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@getter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: null
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void foo<T>(T a) {}
}
var a = A();
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        staticElement: package:test/a.dart::@getter::a
        staticType: A
      staticElement: package:test/a.dart::@getter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable_prefix_unknown() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
var a = A();
''');
    await assertErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 47, 3),
    ]);

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        staticElement: package:test/a.dart::@getter::a
        staticType: A
      staticElement: package:test/a.dart::@getter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_instanceMethod_explicitReceiver_typeParameter() async {
    await assertErrorsInCode('''
bar<T>() {
  T.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 15, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: T
      staticElement: T@4
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_instanceMethod_explicitReceiver_variable() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::bar::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: null
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_variable_cascade() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a..foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_inherited() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B extends A {
  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>.m();
  }
}
''');

    var reference = findNode.functionReference('foo<int>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_unknown() async {
    await assertErrorsInCode('''
class A {
  bar() {
    foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3,
          messageContains: ["for the type 'A'"]),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_localFunction() async {
    await assertNoErrorsInCode('''
void bar() {
  void foo<T>(T a) {}

  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: foo@20
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable() async {
    await assertNoErrorsInCode('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::bar::@parameter::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_call() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  var fn = foo;
  fn.call<int>;
}
''');

    var reference = findNode.functionReference('fn.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: fn
      staticElement: fn@40
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_call_tooManyTypeArgs() async {
    await assertErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  void Function(int) fn = foo;
  fn.call<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 74, 5),
    ]);

    var reference = findNode.functionReference('fn.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('fn')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: fn
      staticElement: fn@55
      staticType: void Function(int)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: void Function(int)
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
  staticType: void Function(int)
''');
  }

  test_localVariable_typeVariable_boundToFunction() async {
    await assertErrorsInCode('''
void bar<T extends Function>(T foo) {
  foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 40, 3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::bar::@parameter::foo
    staticType: T
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
  staticType: dynamic
''');
  }

  test_localVariable_typeVariable_functionTyped() async {
    await assertNoErrorsInCode('''
void bar<T extends void Function<U>(U)>(T foo) {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::bar::@parameter::foo
    staticType: T
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_typeVariable_nonFunction() async {
    await assertErrorsInCode('''
void bar<T>(T foo) {
  foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 23, 3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::bar::@parameter::foo
    staticType: T
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
  staticType: dynamic
''');
  }

  test_neverTyped() async {
    await assertErrorsInCode('''
external Never get i;

void bar() {
  i<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 38, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('i<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    staticElement: self::@getter::i
    staticType: Never
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
  staticType: dynamic
''');
  }

  test_nonGenericFunction() async {
    await assertErrorsInCode('''
class A {
  void foo() {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 44, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()
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
  staticType: void Function()
''');
  }

  test_otherExpression() async {
    await assertNoErrorsInCode('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int>;
}
''');

    var reference = findNode.functionReference('(1 == 2 ? foo : bar)<int>;');
    assertType(reference, 'void Function(int)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_otherExpression_wrongNumberOfTypeArguments() async {
    await assertErrorsInCode('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int, String>;
}
''', [
      error(
          CompileTimeErrorCode
              .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION,
          85,
          13),
    ]);

    var reference =
        findNode.functionReference('(1 == 2 ? foo : bar)<int, String>;');
    assertType(reference, 'void Function(dynamic)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_receiverIsDynamic() async {
    await assertErrorsInCode('''
bar(dynamic a) {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          19, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('a.foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::bar::@parameter::a
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
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
  staticType: dynamic
''');
  }

  test_staticMethod() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}
}

bar() {
  A.foo<int>;
}
''');

    assertClassRef(findNode.simple('A.'), findElement.class_('A'));
    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: null
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void foo<T>(T a) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

bar() {
  a.A.foo<int>;
}
''');

    assertImportPrefix(findNode.simple('a.A'), findElement.prefix('a'));
    assertClassRef(findNode.simple('A.'),
        findElement.importFind('package:test/a.dart').class_('A'));
    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: self::@prefix::a
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
      staticElement: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_prefix_typeAlias() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void foo<T>(T a) {}
}
typedef TA = A;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.TA.foo<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: TA
        staticElement: package:test/a.dart::@typeAlias::TA
        staticType: Type
      staticElement: package:test/a.dart::@typeAlias::TA
      staticType: Type
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_typeAlias() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}
}
typedef TA = A;

bar() {
  TA.foo<int>;
}
''');

    assertTypeAliasRef(findNode.simple('TA.'), findElement.typeAlias('TA'));
    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: TA
      staticElement: self::@typeAlias::TA
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@method::foo
      staticType: null
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReciver_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void foo<T>(T a) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.A.foo<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
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
      staticElement: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_tooFewTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T, U>(T a, U b) {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 58, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T, U>(T, U)
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
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_tooManyTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int, int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 50, 10),
    ]);

    var reference = findNode.functionReference('foo<int, int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  staticType: void Function(dynamic)
  typeArgumentTypes
    dynamic
''');
  }

  test_topLevelFunction() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
void foo<T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''');

    assertImportPrefix(findNode.simple('a.f'), findElement.prefix('a'));
    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@function::foo
      staticType: void Function<T>(T)
    staticElement: package:test/a.dart::@function::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_importPrefix_asTargetOfFunctionCall() async {
    newFile('$testPackageLibPath/a.dart', '''
void foo<T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

extension on Function {
  void m() {}
}
void bar() {
  a.foo<int>.m();
}
''');

    assertImportPrefix(findNode.simple('a.f'), findElement.prefix('a'));
    var reference = findNode.functionReference('foo<int>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@function::foo
      staticType: void Function<T>(T)
    staticElement: package:test/a.dart::@function::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_prefix_unknownPrefix() async {
    await assertErrorsInCode('''
bar() {
  prefix.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 6),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: <null>
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_topLevelFunction_targetOfCall() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo<int>.call;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo<int>.call;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
    assertSimpleIdentifier(findNode.simple('call;'),
        element: null, type: 'void Function(int)');
  }

  test_topLevelFunction_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
void foo<T>(T arg) {}

extension on Function {
  void m() {}
}
void bar() {
  foo<int>.m();
}
''');

    assertResolvedNodeText(findNode.functionReference('foo<int>'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelVariable_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
void Function<T>(T) foo = <T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.foo<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@getter::foo
      staticType: void Function<T>(T)
    staticElement: package:test/a.dart::@getter::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelVariable_prefix_unknownIdentifier() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          38, 17),
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 45, 1),
    ]);

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        staticElement: <null>
        staticType: dynamic
      staticElement: <null>
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_typeAlias_function_unknownProperty() async {
    await assertErrorsInCode('''
typedef Cb = void Function();

var a = Cb.foo<int>;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 42, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: Cb
      staticElement: self::@typeAlias::Cb
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_typeAlias_typeVariable_unknownProperty() async {
    await assertErrorsInCode('''
typedef T<E> = E;

var a = T.foo<int>;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 29, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: T
      staticElement: self::@typeAlias::T
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_unknownIdentifier() async {
    await assertErrorsInCode('''
void bar() {
  foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_unknownIdentifier_explicitReceiver() async {
    await assertErrorsInCode('''
class A {}

class B {
  bar(A a) {
    a.foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 41, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@class::B::@method::bar::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: dynamic
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }

  test_unknownIdentifier_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 40, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: dynamic
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
  staticType: dynamic
''');
  }
}

@reflectiveTest
class FunctionReferenceResolutionWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_localVariable() async {
    // This code includes a disallowed type instantiation (local variable),
    // but in the case that the experiment is not enabled, we suppress the
    // associated error.
    await assertErrorsInCode('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 43, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::bar::@parameter::foo
    staticType: void Function<T>(T)
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
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }
}
