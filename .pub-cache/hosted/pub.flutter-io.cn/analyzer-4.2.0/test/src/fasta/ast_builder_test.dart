// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstBuilderTest);
  });
}

@reflectiveTest
class AstBuilderTest extends ParserDiagnosticsTest {
  void test_class_augment() {
    var parseResult = parseStringWithErrors(r'''
augment class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  name: SimpleIdentifier
    token: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_macro() {
    var parseResult = parseStringWithErrors(r'''
macro class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  macroKeyword: macro
  classKeyword: class
  name: SimpleIdentifier
    token: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_classAlias_macro() {
    var parseResult = parseStringWithErrors(r'''
mixin M {}
macro class A = Object with M;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classTypeAlias('class A');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  typedefKeyword: class
  name: SimpleIdentifier
    token: A
  equals: =
  macroKeyword: macro
  superclass: NamedType
    name: SimpleIdentifier
      token: Object
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: SimpleIdentifier
          token: M
  semicolon: ;
''');
  }

  void test_constructor_factory_misnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory B() => null;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
    semicolon: ;
''');
  }

  void test_constructor_wrongName() {
    var parseResult = parseStringWithErrors(r'''
class A {
  B() : super();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  returnType: SimpleIdentifier
    token: B
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    SuperConstructorInvocation
      superKeyword: super
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_enum_constant_name_dot() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MISSING_IDENTIFIER, 14, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 14, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  name: SimpleIdentifier
    token: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_enum_constant_name_dot_identifier_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.named;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 13, 5),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  name: SimpleIdentifier
    token: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: named
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_enum_constant_name_dot_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 13, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  name: SimpleIdentifier
    token: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_enum_constant_name_typeArguments_dot() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 19, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v<int>.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  name: SimpleIdentifier
    token: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_enum_constant_name_typeArguments_dot_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 18, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v<int>');
    assertParsedNodeText(
        node,
        r'''
EnumConstantDeclaration
  name: SimpleIdentifier
    token: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''',
        withCheckingLinking: true);
  }

  void test_enum_constant_withTypeArgumentsWithoutArguments() {
    var parseResult = parseStringWithErrors(r'''
enum E<T> {
  v<int>;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 19, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v<int>');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  name: SimpleIdentifier
    token: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_enum_semicolon_null() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: SimpleIdentifier
    token: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: SimpleIdentifier
        token: v
  rightBracket: }
''');
  }

  void test_enum_semicolon_optional() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: SimpleIdentifier
    token: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: SimpleIdentifier
        token: v
  semicolon: ;
  rightBracket: }
''');
  }

  void test_getter_sameNameAsClass() {
    var parseResult = parseStringWithErrors(r'''
class A {
  get A => 0;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);

    var node = parseResult.findNode.methodDeclaration('get A');
    assertParsedNodeText(node, r'''
MethodDeclaration
  propertyKeyword: get
  name: SimpleIdentifier
    token: A
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
    semicolon: ;
''');
  }

  void test_library_augment() {
    var parseResult = parseStringWithErrors(r'''
library augment 'a.dart';
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.libraryAugmentation('library');
    assertParsedNodeText(node, r'''
LibraryAugmentationDirective
  libraryKeyword: library
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');
  }

  void test_superFormalParameter() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(super.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  identifier: SimpleIdentifier
    token: a
''');
  }
}
