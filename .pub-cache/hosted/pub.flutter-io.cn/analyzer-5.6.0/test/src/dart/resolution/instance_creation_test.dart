// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationTest);
    defineReflectiveTests(InstanceCreationWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class InstanceCreationTest extends PubPackageResolutionTest
    with InstanceCreationTestCases {}

mixin InstanceCreationTestCases on PubPackageResolutionTest {
  test_class_generic_named_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

void f() {
  A.named(0);
}

''');

    var node = findNode.instanceCreation('A.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_named_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named();
}

void f() {
  A<int>.named();
}

''');

    var node = findNode.instanceCreation('A<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
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
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A<int>
''');
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_class_generic_unnamed_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f() {
  A(0);
}

''');

    var node = findNode.instanceCreation('A(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A<int>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_unnamed_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

void f() {
  A<int>();
}

''');

    var node = findNode.instanceCreation('A<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
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
      type: A<int>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A<int>
''');
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_class_notGeneric() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

void f() {
  A(0);
}

''');

    var node = findNode.instanceCreation('A(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
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
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_demoteType() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f<S>(S s) {
  if (s is int) {
    A(s);
  }
}

''');

    var node = findNode.instanceCreation('A(s)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A<S>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: S}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: S}
        staticElement: self::@function::f::@parameter::s
        staticType: S & int
    rightParenthesis: )
  staticType: A<S>
''');
  }

  test_error_newWithInvalidTypeParameters_implicitNew_inference_top() async {
    await assertErrorsInCode(r'''
final foo = Map<int>();
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 12, 8),
    ]);

    var node = findNode.instanceCreation('Map<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: Map
        staticElement: dart:core::@class::Map
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
      type: Map<dynamic, dynamic>
    staticElement: ConstructorMember
      base: dart:core::@class::Map::@constructor::new
      substitution: {K: dynamic, V: dynamic}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Map<dynamic, dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 53,
          5,
          messageContains: ["The constructor 'Foo.bar'"]),
    ]);

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: Foo
        staticElement: self::@class::Foo
        staticType: null
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: self::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
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
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_new() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.new();
}

main() {
  new Foo.new<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 53,
          5,
          messageContains: ["The constructor 'Foo.new'"]),
    ]);

    var node = findNode.instanceCreation('Foo.new<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: Foo
        staticElement: self::@class::Foo
        staticType: null
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: self::@class::Foo::@constructor::new
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::Foo::@constructor::new
      substitution: {X: dynamic}
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
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  new p.Foo.bar<int>();
}
''', [
      error(ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS, 44, 3),
    ]);

    // TODO(brianwilkerson) Test this more carefully after we can re-write the
    // AST to reflect the expected structure.
    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: Foo
          staticElement: package:test/a.dart::@class::Foo
          staticType: null
        staticElement: package:test/a.dart::@class::Foo
        staticType: null
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
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
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 49,
          5),
    ]);

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: Foo
        staticElement: self::@class::Foo
        staticType: null
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: self::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
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
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 43,
          5),
    ]);

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: Foo
          staticElement: package:test/a.dart::@class::Foo
          staticType: null
        staticElement: package:test/a.dart::@class::Foo
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
      type: Foo<int>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: int}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<int>
''');
  }

  test_namedArgument_anywhere() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}
class D {}

class X {
  X(A a, B b, {C? c, D? d});
}

T g1<T>() => throw 0;
T g2<T>() => throw 0;
T g3<T>() => throw 0;
T g4<T>() => throw 0;

void f() {
  X(g1(), c: g3(), g2(), d: g4());
}
''');

    var node = findNode.instanceCreation('X(g');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: X
        staticElement: self::@class::X
        staticType: null
      type: X
    staticElement: self::@class::X::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: g1
          staticElement: self::@function::g1
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: self::@class::X::@constructor::new::@parameter::a
        staticInvokeType: A Function()
        staticType: A
        typeArgumentTypes
          A
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            staticElement: self::@class::X::@constructor::new::@parameter::c
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g3
            staticElement: self::@function::g3
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: C? Function()
          staticType: C?
          typeArgumentTypes
            C?
        parameter: self::@class::X::@constructor::new::@parameter::c
      MethodInvocation
        methodName: SimpleIdentifier
          token: g2
          staticElement: self::@function::g2
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: self::@class::X::@constructor::new::@parameter::b
        staticInvokeType: B Function()
        staticType: B
        typeArgumentTypes
          B
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: d
            staticElement: self::@class::X::@constructor::new::@parameter::d
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g4
            staticElement: self::@function::g4
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: D? Function()
          staticType: D?
          typeArgumentTypes
            D?
        parameter: self::@class::X::@constructor::new::@parameter::d
    rightParenthesis: )
  staticType: X
''');
  }

  test_typeAlias_generic_class_generic_named_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B<U> = A<U>;

void f() {
  B.named(0);
}
''');

    var node = findNode.instanceCreation('B.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: self::@typeAlias::B
        staticType: null
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_typeAlias_generic_class_generic_named_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A.named(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B.named(0, '');
}
''');

    var node = findNode.instanceCreation('B.named(0, ');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: self::@typeAlias::B
        staticType: null
      type: A<int, String>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic, U: String}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_typeAlias_generic_class_generic_unnamed_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B<U> = A<U>;

void f() {
  B(0);
}
''');

    var node = findNode.instanceCreation('B(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: self::@typeAlias::B
        staticType: null
      type: A<int>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_typeAlias_generic_class_generic_unnamed_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B(0, '');
}
''');

    var node = findNode.instanceCreation('B(0, ');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: self::@typeAlias::B
        staticType: null
      type: A<int, String>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_typeAlias_notGeneric_class_generic_named_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B = A<String>;

void f() {
  B.named(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 77, 1),
    ]);

    var node = findNode.instanceCreation('B.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: self::@typeAlias::B
        staticType: null
      type: A<String>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: String}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
''');
  }

  test_typeAlias_notGeneric_class_generic_unnamed_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B = A<String>;

void f() {
  B(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 65, 1),
    ]);

    var node = findNode.instanceCreation('B(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: self::@typeAlias::B
        staticType: null
      type: A<String>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
''');
  }

  test_unnamed_declaredNew() async {
    await assertNoErrorsInCode('''
class A {
  A.new(int a);
}

void f() {
  A(0);
}

''');

    var node = findNode.instanceCreation('A(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
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
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unnamedViaNew_declaredNew() async {
    await assertNoErrorsInCode('''
class A {
  A.new(int a);
}

void f() {
  A.new(0);
}

''');

    var node = findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: self::@class::A::@constructor::new
      staticType: null
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unnamedViaNew_declaredUnnamed() async {
    await assertNoErrorsInCode('''
class A {
  A(int a);
}

void f() {
  A.new(0);
}

''');

    var node = findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: self::@class::A::@constructor::new
      staticType: null
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }
}

@reflectiveTest
class InstanceCreationWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_unnamedViaNew() async {
    await assertErrorsInCode('''
class A {
  A(int a);
}

void f() {
  A.new(0);
}

''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 40, 3),
    ]);

    // Resolution should continue even though the experiment is not enabled.
    var node = findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: self::@class::A::@constructor::new
      staticType: null
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }
}
