// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest);
  });
}

/// Tests which exercise the parser using a class member.
@reflectiveTest
class ClassMemberParserTest extends FastaParserTestCase
    implements AbstractParserViaProxyTestCase {
  void test_parse_member_called_late() {
    var unit = parseCompilationUnit(
        'class C { void late() { new C().late(); } }',
        featureSet: nonNullable);
    var declaration = unit.declarations[0] as ClassDeclaration;
    var method = declaration.members[0] as MethodDeclaration;

    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.name, 'late');
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);

    var body = method.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    expect(invocation.operator!.lexeme, '.');
    expect(invocation.toSource(), 'new C().late()');
  }

  void test_parseAwaitExpression_asStatement_inAsync() {
    createParser('m() async { await x; }');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    FunctionBody body = method.body;
    expect(body, isBlockFunctionBody);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    expect(statement, isExpressionStatement);
    Expression expression = (statement as ExpressionStatement).expression;
    expect(expression, isAwaitExpression);
    expect((expression as AwaitExpression).awaitKeyword, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseAwaitExpression_asStatement_inSync() {
    createParser('m() { await x; }');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    FunctionBody body = method.body;
    expect(body, isBlockFunctionBody);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    expect(statement, isVariableDeclarationStatement);
  }

  void test_parseAwaitExpression_inSync() {
    createParser('m() { return await x + await y; }');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    expect(method, isNotNull);
    listener.assertErrors([
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 13, 5),
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 23, 5)
    ]);
    FunctionBody body = method.body;
    expect(body, isBlockFunctionBody);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    expect(statement, isReturnStatement);
    Expression expression = (statement as ReturnStatement).expression!;
    expect(expression, isBinaryExpression);
  }

  void test_parseClassMember_constructor_withDocComment() {
    createParser('/// Doc\nC();');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    expectCommentText(constructor.documentationComment, '/// Doc');
  }

  void test_parseClassMember_constructor_withInitializers() {
    // TODO(brianwilkerson) Test other kinds of class members: fields, getters
    // and setters.
    createParser('C(_, _\$, this.__) : _a = _ + _\$ {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    var constructor = member as ConstructorDeclaration;
    expect(constructor.body, isNotNull);
    expect(constructor.separator, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.period, isNull);
    expect(constructor.returnType, isNotNull);
    expect(constructor.initializers, hasLength(1));
  }

  void test_parseClassMember_field_covariant() {
    createParser('covariant T f;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNotNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_generic() {
    createParser('List<List<N>> _allComponents = new List<List<N>>();');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    var type = list.type as NamedType;
    expect(type.name.name, 'List');
    List typeArguments = type.typeArguments!.arguments;
    expect(typeArguments, hasLength(1));
    var type2 = typeArguments[0] as NamedType;
    expect(type2.name.name, 'List');
    NodeList typeArguments2 = type2.typeArguments!.arguments;
    expect(typeArguments2, hasLength(1));
    var type3 = typeArguments2[0] as NamedType;
    expect(type3.name.name, 'N');
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_gftType_gftReturnType() {
    createParser('''
Function(int) Function(String) v;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isFieldDeclaration);
    VariableDeclarationList fields = (member as FieldDeclaration).fields;
    expect(fields.type, isGenericFunctionType);
  }

  void test_parseClassMember_field_gftType_noReturnType() {
    createParser('''
Function(int, String) v;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isFieldDeclaration);
    VariableDeclarationList fields = (member as FieldDeclaration).fields;
    expect(fields.type, isGenericFunctionType);
  }

  void test_parseClassMember_field_instance_prefixedType() {
    createParser('p.A f;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
    _assertIsDeclarationName(variable.name);
  }

  void test_parseClassMember_field_namedGet() {
    createParser('var get;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_namedOperator() {
    createParser('var operator;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_namedOperator_withAssignment() {
    createParser('var operator = (5);');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
    expect(variable.initializer, isNotNull);
  }

  void test_parseClassMember_field_namedSet() {
    createParser('var set;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_nameKeyword() {
    createParser('var for;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 4, 3)
    ]);
  }

  void test_parseClassMember_field_nameMissing() {
    createParser('var ;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)]);
  }

  void test_parseClassMember_field_nameMissing2() {
    createParser('var "";');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 2)]);
  }

  void test_parseClassMember_field_static() {
    createParser('static A f;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNotNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_finalAndCovariantLateWithInitializer() {
    createParser(
      'covariant late final int f = 0;',
      featureSet: nonNullable,
    );
    parser.parseClassMember('C');
    assertErrors(errors: [
      expectedError(
          ParserErrorCode.FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER, 0, 9)
    ]);
  }

  void test_parseClassMember_getter_functionType() {
    createParser('int Function(int) get g {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.body, isNotNull);
    expect(method.parameters, isNull);
  }

  void test_parseClassMember_getter_void() {
    createParser('void get g {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    _assertIsDeclarationName(method.name);
    expect(method.operatorKeyword, isNull);
    expect(method.body, isNotNull);
    expect(method.parameters, isNull);
  }

  void test_parseClassMember_method_external() {
    createParser('external m();');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    _assertIsDeclarationName(method.name);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);

    var body = method.body as EmptyFunctionBody;
    expect(body.keyword, isNull);
    expect(body.star, isNull);
    expect(body.semicolon.type, TokenType.SEMICOLON);
  }

  void test_parseClassMember_method_external_withTypeAndArgs() {
    createParser('external int m(int a);');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.body, isNotNull);
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
  }

  void test_parseClassMember_method_generic_noReturnType() {
    createParser('m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_parameterType() {
    createParser('m<T>(T p) => null;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);

    FormalParameterList parameters = method.parameters!;
    expect(parameters, isNotNull);
    expect(parameters.parameters, hasLength(1));
    var parameter = parameters.parameters[0] as SimpleFormalParameter;
    var parameterType = parameter.type as NamedType;
    expect(parameterType.name.name, 'T');

    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType() {
    createParser('T m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType_bound() {
    createParser('T m<T extends num>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect((method.returnType as NamedType).name.name, 'T');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    TypeParameter tp = method.typeParameters!.typeParameters[0];
    expect(tp.name.name, 'T');
    expect(tp.extendsKeyword, isNotNull);
    expect((tp.bound as NamedType).name.name, 'num');
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType_complex() {
    createParser('Map<int, T> m<T>() => null;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);

    {
      var returnType = method.returnType as NamedType;
      expect(returnType, isNotNull);
      expect(returnType.name.name, 'Map');

      List<TypeAnnotation> typeArguments = returnType.typeArguments!.arguments;
      expect(typeArguments, hasLength(2));
      expect((typeArguments[0] as NamedType).name.name, 'int');
      expect((typeArguments[1] as NamedType).name.name, 'T');
    }

    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType_static() {
    createParser('static T m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect((method.returnType as NamedType).name.name, 'T');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_void() {
    createParser('void m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_noType() {
    createParser('get() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_static_namedAsClass() {
    createParser('static int get C => 0;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors([
      expectedError(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 15, 1),
    ]);
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_type() {
    createParser('int get() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_void() {
    createParser('void get() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_gftReturnType_noReturnType() {
    createParser('''
Function<A>(core.List<core.int> x) m() => null;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isMethodDeclaration);
    expect((member as MethodDeclaration).body, isExpressionFunctionBody);
  }

  void test_parseClassMember_method_gftReturnType_voidReturnType() {
    createParser('''
void Function<A>(core.List<core.int> x) m() => null;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isMethodDeclaration);
    expect((member as MethodDeclaration).body, isExpressionFunctionBody);
  }

  void test_parseClassMember_method_native_allowed() {
    allowNativeClause = true;
    _parseClassMember_method_native();
    assertNoErrors();
  }

  void test_parseClassMember_method_native_missing_literal_allowed() {
    allowNativeClause = true;
    _parseClassMember_method_native_missing_literal();
    assertNoErrors();
  }

  void test_parseClassMember_method_native_missing_literal_not_allowed() {
    allowNativeClause = false;
    _parseClassMember_method_native_missing_literal();
    listener.assertErrors([
      expectedError(ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, 4, 6),
    ]);
  }

  void test_parseClassMember_method_native_not_allowed() {
    allowNativeClause = false;
    _parseClassMember_method_native();
    listener.assertErrors([
      expectedError(ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, 4, 6),
    ]);
  }

  void test_parseClassMember_method_native_with_body_allowed() {
    allowNativeClause = true;
    _parseClassMember_method_native_with_body();
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    assertErrorsWithCodes([
      ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
    ]);
//      listener.assertErrors([
//        expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 17, 2),
//      ]);
  }

  void test_parseClassMember_method_native_with_body_not_allowed() {
    allowNativeClause = false;
    _parseClassMember_method_native_with_body();
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    assertErrorsWithCodes([
      ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
      ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
    ]);
//      listener.assertErrors([
//        expectedError(ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, 4, 6),
//        expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 17, 2),
//      ]);
  }

  void test_parseClassMember_method_operator_noType() {
    createParser('operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_type() {
    createParser('int operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_void() {
    createParser('void operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_returnType_functionType() {
    createParser('int Function(String) m() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.name.name, 'm');
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_returnType_parameterized() {
    createParser('p.A m() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_noType() {
    createParser('set() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_static_namedAsClass() {
    createParser('static void set C(_) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors([
      expectedError(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_type() {
    createParser('int set() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_void() {
    createParser('void set() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_static_class() {
    var unit = parseCompilationUnit('class C { static void m() {} }');

    var c = unit.declarations[0] as ClassDeclaration;
    var method = c.members[0] as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_static_mixin() {
    var unit = parseCompilationUnit('mixin C { static void m() {} }');
    var c = unit.declarations[0] as MixinDeclaration;
    var method = c.members[0] as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_trailing_commas() {
    createParser('void f(int x, int y,) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_functionType() {
    createParser('int Function() operator +(int Function() f) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isGenericFunctionType);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    NodeList<FormalParameter> parameters = method.parameters!.parameters;
    expect(parameters, hasLength(1));
    expect(
        (parameters[0] as SimpleFormalParameter).type, isGenericFunctionType);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_gtgtgt() {
    var unit = parseCompilationUnit(
      'class C { bool operator >>>(other) => false; }',
    );
    var declaration = unit.declarations[0] as ClassDeclaration;
    var method = declaration.members[0] as MethodDeclaration;

    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.name, '>>>');
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_gtgtgteq() {
    var unit = parseCompilationUnit(
      'class C { foo(int value) { x >>>= value; } }',
    );
    var declaration = unit.declarations[0] as ClassDeclaration;
    var method = declaration.members[0] as MethodDeclaration;
    var blockFunctionBody = method.body as BlockFunctionBody;
    NodeList<Statement> statements = blockFunctionBody.block.statements;
    expect(statements, hasLength(1));
    var statement = statements[0] as ExpressionStatement;
    var assignment = statement.expression as AssignmentExpression;
    var leftHandSide = assignment.leftHandSide as SimpleIdentifier;
    expect(leftHandSide.name, 'x');
    expect(assignment.operator.lexeme, '>>>=');
    var rightHandSide = assignment.rightHandSide as SimpleIdentifier;
    expect(rightHandSide.name, 'value');
  }

  void test_parseClassMember_operator_index() {
    createParser('int operator [](int i) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_indexAssign() {
    createParser('int operator []=(int i) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_lessThan() {
    createParser('bool operator <(other) => false;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.name, '<');
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_redirectingFactory_const() {
    createParser('const factory C() = prefix.B.foo;');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword!.keyword, Keyword.CONST);
    expect(constructor.factoryKeyword!.keyword, Keyword.FACTORY);
    expect(constructor.returnType.name, 'C');
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    _assertIsDeclarationName(constructor.returnType as SimpleIdentifier, false);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator!.type, TokenType.EQ);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNotNull);
    expect(constructor.redirectedConstructor!.type2.name.name, 'prefix.B');
    expect(constructor.redirectedConstructor!.period!.type, TokenType.PERIOD);
    expect(constructor.redirectedConstructor!.name!.name, 'foo');
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseClassMember_redirectingFactory_expressionBody() {
    createParser('factory C() => throw 0;');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword!.keyword, Keyword.FACTORY);
    expect(constructor.returnType.name, 'C');
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);

    var body = constructor.body as ExpressionFunctionBody;
    expect(body.keyword, isNull);
    expect(body.star, isNull);
    expect(body.functionDefinition.type, TokenType.FUNCTION);
    expect(body.expression, isNotNull);
    expect(body.semicolon, isNotNull);
  }

  void test_parseClassMember_redirectingFactory_nonConst() {
    createParser('factory C() = B;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    var constructor = member as ConstructorDeclaration;
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword!.keyword, Keyword.FACTORY);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType as SimpleIdentifier, false);
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator!.type, TokenType.EQ);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNotNull);
    expect(constructor.redirectedConstructor!.type2.name.name, 'B');
    expect(constructor.redirectedConstructor!.period, isNull);
    expect(constructor.redirectedConstructor!.name, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_assert() {
    createParser('C(x, y) : _x = x, assert (x < y), _y = y;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(3));
    ConstructorInitializer initializer = initializers[1];
    expect(initializer, isAssertInitializer);
    var assertInitializer = initializer as AssertInitializer;
    expect(assertInitializer.condition, isNotNull);
    expect(assertInitializer.message, isNull);
  }

  void test_parseConstructor_factory_const_external() {
    // Although the spec does not allow external const factory,
    // there are several instances of this in the Dart SDK.
    // For example `external const factory bool.fromEnvironment(...)`.
    createParser('external const factory C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_parseConstructor_factory_named() {
    createParser('factory C.foo() => throw 0;');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNotNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType as SimpleIdentifier, false);
    expect(constructor.period!.type, TokenType.PERIOD);
    expect(constructor.name!.name, 'foo');
    _assertIsDeclarationName(constructor.name!);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isExpressionFunctionBody);
  }

  void test_parseConstructor_initializers_field() {
    createParser('C(x, y) : _x = x, this._y = y;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(2));

    {
      var initializer = initializers[0] as ConstructorFieldInitializer;
      expect(initializer.thisKeyword, isNull);
      expect(initializer.period, isNull);
      expect(initializer.fieldName.name, '_x');
      expect(initializer.expression, isNotNull);
    }

    {
      var initializer = initializers[1] as ConstructorFieldInitializer;
      expect(initializer.thisKeyword, isNotNull);
      expect(initializer.period, isNotNull);
      expect(initializer.fieldName.name, '_y');
      expect(initializer.expression, isNotNull);
    }
  }

  void test_parseConstructor_invalidInitializer() {
    // https://github.com/dart-lang/sdk/issues/37693
    parseCompilationUnit('class C{ C() : super() * (); }', errors: [
      expectedError(ParserErrorCode.INVALID_INITIALIZER, 15, 12),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);
  }

  void test_parseConstructor_named() {
    createParser('C.foo();');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType as SimpleIdentifier, false);
    expect(constructor.period!.type, TokenType.PERIOD);
    expect(constructor.name!.name, 'foo');
    _assertIsDeclarationName(constructor.name!);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_nullSuperArgList_openBrace_37735() {
    // https://github.com/dart-lang/sdk/issues/37735
    var unit = parseCompilationUnit('class{const():super.{n', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 11, 1),
      expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 11, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 20, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 1),
      expectedError(ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, 20, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 21, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 22, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 22, 1),
    ]);
    var classDeclaration = unit.declarations[0] as ClassDeclaration;
    var constructor = classDeclaration.members[0] as ConstructorDeclaration;
    var invocation = constructor.initializers[0] as SuperConstructorInvocation;
    expect(invocation.argumentList.arguments, hasLength(0));
  }

  void test_parseConstructor_operator_name() {
    var unit = parseCompilationUnit('class A { operator/() : super(); }',
        errors: [
          expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 10, 8)
        ]);
    var classDeclaration = unit.declarations[0] as ClassDeclaration;
    var constructor = classDeclaration.members[0] as ConstructorDeclaration;
    var invocation = constructor.initializers[0] as SuperConstructorInvocation;
    expect(invocation.argumentList.arguments, hasLength(0));
  }

  void test_parseConstructor_superIndexed() {
    createParser('C() : super()[];');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    listener.assertErrors([
      expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 6, 5),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 14, 1),
    ]);
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType as SimpleIdentifier, false);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator!.lexeme, ':');
    expect(constructor.initializers, hasLength(1));
    var initializer = constructor.initializers[0] as SuperConstructorInvocation;
    expect(initializer.argumentList.arguments, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_thisIndexed() {
    createParser('C() : this()[];');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    listener.assertErrors([
      expectedError(ParserErrorCode.INVALID_THIS_IN_INITIALIZER, 6, 4),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
    ]);
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType as SimpleIdentifier, false);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator!.lexeme, ':');
    expect(constructor.initializers, hasLength(1));
    var initializer =
        constructor.initializers[0] as RedirectingConstructorInvocation;
    expect(initializer.argumentList.arguments, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_unnamed() {
    createParser('C();');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType as SimpleIdentifier, false);
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_with_pseudo_function_literal() {
    // "(b) {}" should not be misinterpreted as a function literal even though
    // it looks like one.
    createParser('C() : a = (b) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(1));
    ConstructorInitializer initializer = initializers[0];
    expect(initializer, isConstructorFieldInitializer);
    expect((initializer as ConstructorFieldInitializer).expression,
        isParenthesizedExpression);
    expect(constructor.body, isBlockFunctionBody);
  }

  void test_parseConstructorFieldInitializer_qualified() {
    var initializer = parseConstructorInitializer('this.a = b')
        as ConstructorFieldInitializer;
    expect(initializer, isNotNull);
    assertNoErrors();
    expect(initializer.equals, isNotNull);
    expect(initializer.expression, isNotNull);
    expect(initializer.fieldName, isNotNull);
    expect(initializer.thisKeyword, isNotNull);
    expect(initializer.period, isNotNull);
  }

  void test_parseConstructorFieldInitializer_unqualified() {
    var initializer =
        parseConstructorInitializer('a = b') as ConstructorFieldInitializer;
    expect(initializer, isNotNull);
    assertNoErrors();
    expect(initializer.equals, isNotNull);
    expect(initializer.expression, isNotNull);
    expect(initializer.fieldName, isNotNull);
    expect(initializer.thisKeyword, isNull);
    expect(initializer.period, isNull);
  }

  void test_parseField_abstract() {
    createParser('abstract int i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.abstractKeyword, isNotNull);
  }

  void test_parseField_abstract_external() {
    createParser('abstract external int i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.ABSTRACT_EXTERNAL_FIELD, 0, 8),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.abstractKeyword, isNotNull);
    expect(field.externalKeyword, isNotNull);
  }

  void test_parseField_abstract_late() {
    createParser('abstract late int? i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.ABSTRACT_LATE_FIELD, 0, 8),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.abstractKeyword, isNotNull);
  }

  void test_parseField_abstract_late_final() {
    createParser('abstract late final int? i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.ABSTRACT_LATE_FIELD, 0, 8),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.abstractKeyword, isNotNull);
  }

  void test_parseField_abstract_static() {
    createParser('abstract static int? i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.ABSTRACT_STATIC_FIELD, 0, 8),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.abstractKeyword, isNotNull);
  }

  void test_parseField_const_late() {
    createParser('const late T f = 0;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.CONFLICTING_MODIFIERS, 6, 4),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isTrue);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_external() {
    createParser('external int i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.externalKeyword, isNotNull);
  }

  void test_parseField_external_abstract() {
    createParser('external abstract int i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.ABSTRACT_EXTERNAL_FIELD, 9, 8),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.abstractKeyword, isNotNull);
    expect(field.externalKeyword, isNotNull);
  }

  void test_parseField_external_late() {
    createParser('external late int? i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.EXTERNAL_LATE_FIELD, 0, 8),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.externalKeyword, isNotNull);
  }

  void test_parseField_external_late_final() {
    createParser('external late final int? i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.EXTERNAL_LATE_FIELD, 0, 8),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.externalKeyword, isNotNull);
  }

  void test_parseField_external_static() {
    createParser('external static int? i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.externalKeyword, isNotNull);
  }

  void test_parseField_final_late() {
    createParser('final late T f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    assertErrors(errors: [
      expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 4),
    ]);
    expect(member, isNotNull);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isTrue);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late() {
    createParser('late T f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late_const() {
    createParser('late const T f = 0;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.CONFLICTING_MODIFIERS, 5, 5),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isTrue);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late_final() {
    createParser('late final T f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isTrue);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late_var() {
    createParser('late var f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_non_abstract() {
    createParser('int i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.abstractKeyword, isNull);
  }

  void test_parseField_non_external() {
    createParser('int i;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.externalKeyword, isNull);
  }

  void test_parseField_var_late() {
    createParser('var late f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 4, 4),
    ]);
    expect(member, isFieldDeclaration);
    var field = member as FieldDeclaration;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseGetter_identifier_colon_issue_36961() {
    createParser('get a:');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    expect(constructor, isNotNull);
    listener.assertErrors([
      expectedError(ParserErrorCode.GETTER_CONSTRUCTOR, 0, 3),
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 4, 1),
      expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 4, 1),
      expectedError(ParserErrorCode.MISSING_INITIALIZER, 5, 1),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 6, 0),
    ]);
    expect(constructor.body, isNotNull);
    expect(constructor.documentationComment, isNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.returnType, isNotNull);
  }

  void test_parseGetter_nonStatic() {
    createParser('/// Doc\nT get a;');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as NamedType).name.name, 'T');
  }

  void test_parseGetter_static() {
    createParser('/// Doc\nstatic T get a => 42;');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword!.lexeme, 'static');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as NamedType).name.name, 'T');
  }

  void test_parseInitializedIdentifierList_type() {
    createParser("/// Doc\nstatic T a = 1, b, c = 3;");
    var declaration = parser.parseClassMember('C') as FieldDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    VariableDeclarationList fields = declaration.fields;
    expect(fields, isNotNull);
    expect(fields.keyword, isNull);
    expect((fields.type as NamedType).name.name, 'T');
    expect(fields.variables, hasLength(3));
    expect(declaration.staticKeyword!.lexeme, 'static');
    expect(declaration.semicolon, isNotNull);
  }

  void test_parseInitializedIdentifierList_var() {
    createParser('/// Doc\nstatic var a = 1, b, c = 3;');
    var declaration = parser.parseClassMember('C') as FieldDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    VariableDeclarationList fields = declaration.fields;
    expect(fields, isNotNull);
    expect(fields.keyword!.lexeme, 'var');
    expect(fields.type, isNull);
    expect(fields.variables, hasLength(3));
    expect(declaration.staticKeyword!.lexeme, 'static');
    expect(declaration.semicolon, isNotNull);
  }

  void test_parseOperator() {
    createParser('/// Doc\nT operator +(A a);');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect((method.returnType as NamedType).name.name, 'T');
  }

  void test_parseSetter_nonStatic() {
    createParser('/// Doc\nT set a(var x);');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as NamedType).name.name, 'T');
  }

  void test_parseSetter_static() {
    createParser('/// Doc\nstatic T set a(var x) {}');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword!.lexeme, 'static');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as NamedType).name.name, 'T');
  }

  void test_simpleFormalParameter_withDocComment() {
    createParser('''
int f(
    /// Doc
    int x) {}
''');
    var function = parseFullCompilationUnitMember() as FunctionDeclaration;
    var parameter = function.functionExpression.parameters!.parameters[0]
        as NormalFormalParameter;
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  /// Assert that the given [name] is in declaration context.
  void _assertIsDeclarationName(SimpleIdentifier name, [bool expected = true]) {
    expect(name.inDeclarationContext(), expected);
  }

  void _parseClassMember_method_native() {
    createParser('m() native "str";');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    var body = method.body as NativeFunctionBody;
    expect(body.nativeKeyword, isNotNull);
    expect(body.stringLiteral, isNotNull);
    expect(body.stringLiteral?.stringValue, "str");
    expect(body.semicolon, isNotNull);
  }

  void _parseClassMember_method_native_missing_literal() {
    createParser('m() native;');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    var body = method.body as NativeFunctionBody;
    expect(body.nativeKeyword, isNotNull);
    expect(body.stringLiteral, isNull);
    expect(body.semicolon, isNotNull);
  }

  void _parseClassMember_method_native_with_body() {
    createParser('m() native "str" {}');
    parser.parseClassMember('C') as MethodDeclaration;
  }
}
