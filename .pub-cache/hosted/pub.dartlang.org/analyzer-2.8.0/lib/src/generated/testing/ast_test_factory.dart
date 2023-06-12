// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

/// The class `AstTestFactory` defines utility methods that can be used to
/// create AST nodes. The nodes that are created are complete in the sense that
/// all of the tokens that would have been
/// associated with the nodes by a parser are also created, but the token stream
/// is not constructed. None of the nodes are resolved.
///
/// The general pattern is for the name of the factory method to be the same as
/// the name of the class of AST node being created. There are two notable
/// exceptions. The first is for methods creating nodes that are part of a
/// cascade expression. These methods are all prefixed with 'cascaded'. The
/// second is places where a shorter name seemed unambiguous and easier to read,
/// such as using 'identifier' rather than 'prefixedIdentifier', or 'integer'
/// rather than 'integerLiteral'.
@internal
class AstTestFactory {
  static AdjacentStringsImpl adjacentStrings(List<StringLiteral> strings) =>
      astFactory.adjacentStrings(strings);

  static AnnotationImpl annotation(Identifier name) => astFactory.annotation(
      atSign: TokenFactory.tokenFromType(TokenType.AT), name: name);

  static AnnotationImpl annotation2(Identifier name,
          SimpleIdentifier? constructorName, ArgumentList arguments,
          {TypeArgumentList? typeArguments}) =>
      astFactory.annotation(
          atSign: TokenFactory.tokenFromType(TokenType.AT),
          name: name,
          typeArguments: typeArguments,
          period: constructorName == null
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          constructorName: constructorName,
          arguments: arguments);

  static ArgumentListImpl argumentList(
          [List<Expression> arguments = const []]) =>
      astFactory.argumentList(TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          arguments, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static AsExpressionImpl asExpression(
          Expression expression, TypeAnnotation type) =>
      astFactory.asExpression(
          expression, TokenFactory.tokenFromKeyword(Keyword.AS), type);

  static AssertInitializerImpl assertInitializer(
          Expression condition, Expression message) =>
      astFactory.assertInitializer(
          TokenFactory.tokenFromKeyword(Keyword.ASSERT),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.COMMA),
          message,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static AssertStatementImpl assertStatement(Expression condition,
          [Expression? message]) =>
      astFactory.assertStatement(
          TokenFactory.tokenFromKeyword(Keyword.ASSERT),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          message == null ? null : TokenFactory.tokenFromType(TokenType.COMMA),
          message,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static AssignmentExpressionImpl assignmentExpression(Expression leftHandSide,
          TokenType operator, Expression rightHandSide) =>
      astFactory.assignmentExpression(
          leftHandSide, TokenFactory.tokenFromType(operator), rightHandSide);

  static BlockFunctionBodyImpl asyncBlockFunctionBody(
          [List<Statement> statements = const []]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"),
          null,
          block(statements));

  static ExpressionFunctionBodyImpl asyncExpressionFunctionBody(
          Expression expression) =>
      astFactory.expressionFunctionBody2(
        keyword:
            TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"),
        star: null,
        functionDefinition: TokenFactory.tokenFromType(TokenType.FUNCTION),
        expression: expression,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static BlockFunctionBodyImpl asyncGeneratorBlockFunctionBody(
          [List<Statement> statements = const []]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"),
          TokenFactory.tokenFromType(TokenType.STAR),
          block(statements));

  static ExpressionFunctionBodyImpl asyncGeneratorExpressionFunctionBody(
          Expression expression) =>
      astFactory.expressionFunctionBody2(
        keyword:
            TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"),
        star: TokenFactory.tokenFromType(TokenType.STAR),
        functionDefinition: TokenFactory.tokenFromType(TokenType.FUNCTION),
        expression: expression,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static AwaitExpressionImpl awaitExpression(Expression expression) =>
      astFactory.awaitExpression(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "await"),
          expression);

  static BinaryExpressionImpl binaryExpression(Expression leftOperand,
          TokenType operator, Expression rightOperand) =>
      astFactory.binaryExpression(
          leftOperand, TokenFactory.tokenFromType(operator), rightOperand);

  static BlockImpl block([List<Statement> statements = const []]) =>
      astFactory.block(
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          statements,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static BlockFunctionBodyImpl blockFunctionBody(Block block) =>
      astFactory.blockFunctionBody(null, null, block);

  static BlockFunctionBodyImpl blockFunctionBody2(
          [List<Statement> statements = const []]) =>
      astFactory.blockFunctionBody(null, null, block(statements));

  static BooleanLiteralImpl booleanLiteral(
          bool value) =>
      astFactory.booleanLiteral(
          value
              ? TokenFactory.tokenFromKeyword(Keyword.TRUE)
              : TokenFactory.tokenFromKeyword(Keyword.FALSE),
          value);

  static BreakStatementImpl breakStatement() => astFactory.breakStatement(
      TokenFactory.tokenFromKeyword(Keyword.BREAK),
      null,
      TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static BreakStatementImpl breakStatement2(String label) =>
      astFactory.breakStatement(TokenFactory.tokenFromKeyword(Keyword.BREAK),
          identifier3(label), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static IndexExpressionImpl cascadedIndexExpression(Expression index) =>
      astFactory.indexExpressionForCascade2(
          period: TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD),
          leftBracket:
              TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
          index: index,
          rightBracket:
              TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static MethodInvocationImpl cascadedMethodInvocation(String methodName,
          [List<Expression> arguments = const []]) =>
      astFactory.methodInvocation(
          null,
          TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD),
          identifier3(methodName),
          null,
          argumentList(arguments));

  static PropertyAccessImpl cascadedPropertyAccess(String propertyName) =>
      astFactory.propertyAccess(
          null,
          TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD),
          identifier3(propertyName));

  static CascadeExpressionImpl cascadeExpression(Expression target,
      [List<Expression> cascadeSections = const []]) {
    var cascade = astFactory.cascadeExpression(target, cascadeSections);
    cascade.target.endToken.next = cascadeSections.first.beginToken;
    return cascade;
  }

  static CatchClauseImpl catchClause(String exceptionParameter,
          [List<Statement> statements = const []]) =>
      catchClause5(null, exceptionParameter, null, statements);

  static CatchClauseImpl catchClause2(
          String exceptionParameter, String stackTraceParameter,
          [List<Statement> statements = const []]) =>
      catchClause5(null, exceptionParameter, stackTraceParameter, statements);

  static CatchClauseImpl catchClause3(TypeAnnotation exceptionType,
          [List<Statement> statements = const []]) =>
      catchClause5(exceptionType, null, null, statements);

  static CatchClauseImpl catchClause4(
          TypeAnnotation exceptionType, String exceptionParameter,
          [List<Statement> statements = const []]) =>
      catchClause5(exceptionType, exceptionParameter, null, statements);

  static CatchClauseImpl catchClause5(TypeAnnotation? exceptionType,
          String? exceptionParameter, String? stackTraceParameter,
          [List<Statement> statements = const []]) =>
      astFactory.catchClause(
          exceptionType == null
              ? null
              : TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "on"),
          exceptionType,
          exceptionParameter == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.CATCH),
          exceptionParameter == null
              ? null
              : TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          exceptionParameter == null ? null : identifier3(exceptionParameter),
          stackTraceParameter == null
              ? null
              : TokenFactory.tokenFromType(TokenType.COMMA),
          stackTraceParameter == null ? null : identifier3(stackTraceParameter),
          exceptionParameter == null
              ? null
              : TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          block(statements));

  static ClassDeclarationImpl classDeclaration(
          Keyword? abstractKeyword,
          String name,
          TypeParameterList? typeParameters,
          ExtendsClause? extendsClause,
          WithClause? withClause,
          ImplementsClause? implementsClause,
          [List<ClassMember> members = const []]) =>
      astFactory.classDeclaration(
          null,
          null,
          abstractKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(abstractKeyword),
          TokenFactory.tokenFromKeyword(Keyword.CLASS),
          identifier3(name),
          typeParameters,
          extendsClause,
          withClause,
          implementsClause,
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          members,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static ClassTypeAliasImpl classTypeAlias(
          String name,
          TypeParameterList? typeParameters,
          Keyword? abstractKeyword,
          NamedType superclass,
          WithClause withClause,
          ImplementsClause? implementsClause) =>
      astFactory.classTypeAlias(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.CLASS),
          identifier3(name),
          typeParameters,
          TokenFactory.tokenFromType(TokenType.EQ),
          abstractKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(abstractKeyword),
          superclass,
          withClause,
          implementsClause,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static CompilationUnitImpl compilationUnit() =>
      compilationUnit8(null, [], []);

  static CompilationUnitImpl compilationUnit2(
          List<CompilationUnitMember> declarations) =>
      compilationUnit8(null, [], declarations);

  static CompilationUnitImpl compilationUnit3(List<Directive> directives) =>
      compilationUnit8(null, directives, []);

  static CompilationUnitImpl compilationUnit4(List<Directive> directives,
          List<CompilationUnitMember> declarations) =>
      compilationUnit8(null, directives, declarations);

  static CompilationUnitImpl compilationUnit5(String scriptTag) =>
      compilationUnit8(scriptTag, [], []);

  static CompilationUnitImpl compilationUnit6(
          String scriptTag, List<CompilationUnitMember> declarations) =>
      compilationUnit8(scriptTag, [], declarations);

  static CompilationUnitImpl compilationUnit7(
          String scriptTag, List<Directive> directives) =>
      compilationUnit8(scriptTag, directives, []);

  static CompilationUnitImpl compilationUnit8(
          String? scriptTag,
          List<Directive> directives,
          List<CompilationUnitMember> declarations) =>
      astFactory.compilationUnit(
          beginToken: TokenFactory.tokenFromType(TokenType.EOF),
          scriptTag:
              scriptTag == null ? null : AstTestFactory.scriptTag(scriptTag),
          directives: directives,
          declarations: declarations,
          endToken: TokenFactory.tokenFromType(TokenType.EOF),
          featureSet: FeatureSet.latestLanguageVersion());

  static CompilationUnitImpl compilationUnit9(
          {String? scriptTag,
          List<Directive> directives = const [],
          List<CompilationUnitMember> declarations = const [],
          required FeatureSet featureSet}) =>
      astFactory.compilationUnit(
          beginToken: TokenFactory.tokenFromType(TokenType.EOF),
          scriptTag:
              scriptTag == null ? null : AstTestFactory.scriptTag(scriptTag),
          directives: directives,
          declarations: declarations,
          endToken: TokenFactory.tokenFromType(TokenType.EOF),
          featureSet: featureSet);

  static ConditionalExpressionImpl conditionalExpression(Expression condition,
          Expression thenExpression, Expression elseExpression) =>
      astFactory.conditionalExpression(
          condition,
          TokenFactory.tokenFromType(TokenType.QUESTION),
          thenExpression,
          TokenFactory.tokenFromType(TokenType.COLON),
          elseExpression);

  static ConstructorDeclarationImpl constructorDeclaration(
          Identifier returnType,
          String? name,
          FormalParameterList parameters,
          List<ConstructorInitializer> initializers) =>
      astFactory.constructorDeclaration(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.EXTERNAL),
          null,
          null,
          returnType,
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name),
          parameters,
          initializers.isEmpty
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          initializers,
          null,
          emptyFunctionBody());

  static ConstructorDeclarationImpl constructorDeclaration2(
          Keyword? constKeyword,
          Keyword? factoryKeyword,
          Identifier returnType,
          String? name,
          FormalParameterList parameters,
          List<ConstructorInitializer> initializers,
          FunctionBody body) =>
      astFactory.constructorDeclaration(
          null,
          null,
          null,
          constKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(constKeyword),
          factoryKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(factoryKeyword),
          returnType,
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name),
          parameters,
          initializers.isEmpty
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          initializers,
          null,
          body);

  static ConstructorFieldInitializerImpl constructorFieldInitializer(
          bool prefixedWithThis, String fieldName, Expression expression) =>
      astFactory.constructorFieldInitializer(
          prefixedWithThis ? TokenFactory.tokenFromKeyword(Keyword.THIS) : null,
          prefixedWithThis
              ? TokenFactory.tokenFromType(TokenType.PERIOD)
              : null,
          identifier3(fieldName),
          TokenFactory.tokenFromType(TokenType.EQ),
          expression);

  static ConstructorNameImpl constructorName(NamedType type, String? name) =>
      astFactory.constructorName(
          type,
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name));

  static ContinueStatementImpl continueStatement([String? label]) =>
      astFactory.continueStatement(
          TokenFactory.tokenFromKeyword(Keyword.CONTINUE),
          label == null ? null : identifier3(label),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DeclaredIdentifierImpl declaredIdentifier(
          Keyword keyword, String identifier) =>
      declaredIdentifier2(keyword, null, identifier);

  static DeclaredIdentifierImpl declaredIdentifier2(
          Keyword? keyword, TypeAnnotation? type, String identifier) =>
      astFactory.declaredIdentifier(
          null,
          null,
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type,
          identifier3(identifier));

  static DeclaredIdentifierImpl declaredIdentifier3(String identifier) =>
      declaredIdentifier2(Keyword.VAR, null, identifier);

  static DeclaredIdentifierImpl declaredIdentifier4(
          TypeAnnotation type, String identifier) =>
      declaredIdentifier2(null, type, identifier);

  static CommentImpl documentationComment(
      List<Token> tokens, List<CommentReference> references) {
    return astFactory.documentationComment(tokens, references);
  }

  static DoStatementImpl doStatement(Statement body, Expression condition) =>
      astFactory.doStatement(
          TokenFactory.tokenFromKeyword(Keyword.DO),
          body,
          TokenFactory.tokenFromKeyword(Keyword.WHILE),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DoubleLiteralImpl doubleLiteral(double value) => astFactory
      .doubleLiteral(TokenFactory.tokenFromString(value.toString()), value);

  static EmptyFunctionBodyImpl emptyFunctionBody() => astFactory
      .emptyFunctionBody(TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static EmptyStatementImpl emptyStatement() => astFactory
      .emptyStatement(TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static EnumDeclarationImpl enumDeclaration(
          SimpleIdentifier name, List<EnumConstantDeclaration> constants) =>
      astFactory.enumDeclaration(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.ENUM),
          name,
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          constants,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static EnumDeclarationImpl enumDeclaration2(
      String name, List<String> constantNames) {
    var constants = constantNames.map((name) {
      return astFactory.enumConstantDeclaration(
        null,
        null,
        identifier3(name),
      );
    }).toList();
    return enumDeclaration(identifier3(name), constants);
  }

  static ExportDirectiveImpl exportDirective(
          List<Annotation> metadata, String uri,
          [List<Combinator> combinators = const []]) =>
      astFactory.exportDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.EXPORT),
          string2(uri),
          null,
          combinators,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExportDirectiveImpl exportDirective2(String uri,
          [List<Combinator> combinators = const []]) =>
      exportDirective([], uri, combinators);

  static ExpressionFunctionBodyImpl expressionFunctionBody(
          Expression expression) =>
      astFactory.expressionFunctionBody2(
        keyword: null,
        star: null,
        functionDefinition: TokenFactory.tokenFromType(TokenType.FUNCTION),
        expression: expression,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static ExpressionStatementImpl expressionStatement(Expression expression) =>
      astFactory.expressionStatement(
          expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExtendsClauseImpl extendsClause(NamedType type) => astFactory
      .extendsClause(TokenFactory.tokenFromKeyword(Keyword.EXTENDS), type);

  static ExtensionDeclarationImpl extensionDeclaration(
          {required String name,
          required bool isExtensionTypeDeclaration,
          TypeParameterList? typeParameters,
          required TypeAnnotation extendedType,
          ShowClause? showClause,
          HideClause? hideClause,
          List<ClassMember> members = const []}) =>
      astFactory.extensionDeclaration(
          comment: null,
          metadata: null,
          extensionKeyword: TokenFactory.tokenFromKeyword(Keyword.EXTENSION),
          typeKeyword: isExtensionTypeDeclaration
              ? TokenFactory.tokenFromString('type')
              : null,
          name: identifier3(name),
          typeParameters: typeParameters,
          onKeyword: TokenFactory.tokenFromKeyword(Keyword.ON),
          extendedType: extendedType,
          showClause: showClause,
          hideClause: hideClause,
          leftBracket: TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          members: members,
          rightBracket:
              TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static ExtensionOverrideImpl extensionOverride(
          {required Identifier extensionName,
          TypeArgumentList? typeArguments,
          required ArgumentList argumentList}) =>
      astFactory.extensionOverride(
          extensionName: extensionName,
          typeArguments: typeArguments,
          argumentList: argumentList);

  static FieldDeclarationImpl fieldDeclaration(bool isStatic, Keyword? keyword,
          TypeAnnotation? type, List<VariableDeclaration> variables,
          {bool isAbstract = false, bool isExternal = false}) =>
      astFactory.fieldDeclaration2(
          abstractKeyword: isAbstract
              ? TokenFactory.tokenFromKeyword(Keyword.ABSTRACT)
              : null,
          externalKeyword: isExternal
              ? TokenFactory.tokenFromKeyword(Keyword.EXTERNAL)
              : null,
          staticKeyword:
              isStatic ? TokenFactory.tokenFromKeyword(Keyword.STATIC) : null,
          fieldList: variableDeclarationList(keyword, type, variables),
          semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static FieldDeclarationImpl fieldDeclaration2(bool isStatic, Keyword? keyword,
          List<VariableDeclaration> variables) =>
      fieldDeclaration(isStatic, keyword, null, variables);

  static FieldFormalParameterImpl fieldFormalParameter(
          Keyword? keyword, TypeAnnotation? type, String identifier,
          [FormalParameterList? parameterList]) =>
      astFactory.fieldFormalParameter2(
          keyword:
              keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type: type,
          thisKeyword: TokenFactory.tokenFromKeyword(Keyword.THIS),
          period: TokenFactory.tokenFromType(TokenType.PERIOD),
          identifier: identifier3(identifier),
          parameters: parameterList);

  static FieldFormalParameterImpl fieldFormalParameter2(String identifier) =>
      fieldFormalParameter(null, null, identifier);

  static ForEachPartsWithDeclarationImpl forEachPartsWithDeclaration(
          DeclaredIdentifier loopVariable, Expression iterable) =>
      astFactory.forEachPartsWithDeclaration(
          loopVariable: loopVariable,
          inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
          iterable: iterable);

  static ForEachPartsWithIdentifierImpl forEachPartsWithIdentifier(
          SimpleIdentifier identifier, Expression iterable) =>
      astFactory.forEachPartsWithIdentifier(
          identifier: identifier,
          inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
          iterable: iterable);

  static ForElementImpl forElement(
          ForLoopParts forLoopParts, CollectionElement body,
          {bool hasAwait = false}) =>
      astFactory.forElement(
          awaitKeyword:
              hasAwait ? TokenFactory.tokenFromKeyword(Keyword.AWAIT) : null,
          forKeyword: TokenFactory.tokenFromKeyword(Keyword.FOR),
          leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          forLoopParts: forLoopParts,
          rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body: body);

  static FormalParameterListImpl formalParameterList(
          [List<FormalParameter> parameters = const []]) =>
      astFactory.formalParameterList(
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          parameters,
          null,
          null,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static ForPartsWithDeclarationsImpl forPartsWithDeclarations(
          VariableDeclarationList variables,
          Expression? condition,
          List<Expression>? updaters) =>
      astFactory.forPartsWithDeclarations(
          variables: variables,
          leftSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
          condition: condition,
          rightSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
          updaters: updaters);

  static ForPartsWithExpressionImpl forPartsWithExpression(
          Expression? initialization,
          Expression? condition,
          List<Expression>? updaters) =>
      astFactory.forPartsWithExpression(
          initialization: initialization,
          leftSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
          condition: condition,
          rightSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
          updaters: updaters);

  static ForStatementImpl forStatement(
          ForLoopParts forLoopParts, Statement body) =>
      astFactory.forStatement(
          forKeyword: TokenFactory.tokenFromKeyword(Keyword.FOR),
          leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          forLoopParts: forLoopParts,
          rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body: body);

  static FunctionDeclarationImpl functionDeclaration(
          TypeAnnotation? type,
          Keyword? keyword,
          String name,
          FunctionExpression functionExpression) =>
      astFactory.functionDeclaration(
          null,
          null,
          null,
          type,
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          identifier3(name),
          functionExpression);

  static FunctionDeclarationStatementImpl functionDeclarationStatement(
          TypeAnnotation? type,
          Keyword? keyword,
          String name,
          FunctionExpression functionExpression) =>
      astFactory.functionDeclarationStatement(
          functionDeclaration(type, keyword, name, functionExpression));

  static FunctionExpressionImpl functionExpression() => astFactory
      .functionExpression(null, formalParameterList(), blockFunctionBody2());

  static FunctionExpressionImpl functionExpression2(
          FormalParameterList parameters, FunctionBody body) =>
      astFactory.functionExpression(null, parameters, body);

  static FunctionExpressionImpl functionExpression3(
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          FunctionBody body) =>
      astFactory.functionExpression(typeParameters, parameters, body);

  static FunctionExpressionInvocationImpl functionExpressionInvocation(
          Expression function,
          [List<Expression> arguments = const []]) =>
      functionExpressionInvocation2(function, null, arguments);

  static FunctionExpressionInvocationImpl functionExpressionInvocation2(
          Expression function,
          [TypeArgumentList? typeArguments,
          List<Expression> arguments = const []]) =>
      astFactory.functionExpressionInvocation(
          function, typeArguments, argumentList(arguments));

  static FunctionTypedFormalParameterImpl functionTypedFormalParameter(
          TypeAnnotation? returnType, String identifier,
          [List<FormalParameter> parameters = const []]) =>
      astFactory.functionTypedFormalParameter2(
          returnType: returnType,
          identifier: identifier3(identifier),
          parameters: formalParameterList(parameters));

  static GenericFunctionTypeImpl genericFunctionType(TypeAnnotation returnType,
          TypeParameterList typeParameters, FormalParameterList parameters,
          {bool question = false}) =>
      astFactory.genericFunctionType(returnType,
          TokenFactory.tokenFromString("Function"), typeParameters, parameters,
          question:
              question ? TokenFactory.tokenFromType(TokenType.QUESTION) : null);

  static GenericTypeAliasImpl genericTypeAlias(String name,
          TypeParameterList typeParameters, GenericFunctionType functionType) =>
      astFactory.genericTypeAlias(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.TYPEDEF),
          identifier3(name),
          typeParameters,
          TokenFactory.tokenFromType(TokenType.EQ),
          functionType,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static HideClauseImpl hideClause(List<ShowHideClauseElement> elements) =>
      astFactory.hideClause(
          hideKeyword: TokenFactory.tokenFromString("hide"),
          elements: elements);

  static HideCombinatorImpl hideCombinator(
          List<SimpleIdentifier> identifiers) =>
      astFactory.hideCombinator(
          TokenFactory.tokenFromString("hide"), identifiers);

  static HideCombinatorImpl hideCombinator2(List<String> identifiers) =>
      astFactory.hideCombinator(
          TokenFactory.tokenFromString("hide"), identifierList(identifiers));

  static PrefixedIdentifierImpl identifier(
          SimpleIdentifier prefix, SimpleIdentifier identifier) =>
      astFactory.prefixedIdentifier(
          prefix, TokenFactory.tokenFromType(TokenType.PERIOD), identifier);

  static SimpleIdentifierImpl identifier3(String lexeme) =>
      astFactory.simpleIdentifier(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, lexeme));

  static PrefixedIdentifierImpl identifier4(
          String prefix, SimpleIdentifier identifier) =>
      astFactory.prefixedIdentifier(identifier3(prefix),
          TokenFactory.tokenFromType(TokenType.PERIOD), identifier);

  static PrefixedIdentifierImpl identifier5(String prefix, String identifier) =>
      astFactory.prefixedIdentifier(
          identifier3(prefix),
          TokenFactory.tokenFromType(TokenType.PERIOD),
          identifier3(identifier));

  static List<SimpleIdentifier> identifierList(List<String> identifiers) {
    return identifiers
        .map((String identifier) => identifier3(identifier))
        .toList();
  }

  static IfElementImpl ifElement(
          Expression condition, CollectionElement thenElement,
          [CollectionElement? elseElement]) =>
      astFactory.ifElement(
          ifKeyword: TokenFactory.tokenFromKeyword(Keyword.IF),
          leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition: condition,
          rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          thenElement: thenElement,
          elseKeyword: elseElement == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.ELSE),
          elseElement: elseElement);

  static IfStatementImpl ifStatement(
          Expression condition, Statement thenStatement) =>
      ifStatement2(condition, thenStatement, null);

  static IfStatementImpl ifStatement2(Expression condition,
          Statement thenStatement, Statement? elseStatement) =>
      astFactory.ifStatement(
          TokenFactory.tokenFromKeyword(Keyword.IF),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          thenStatement,
          elseStatement == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.ELSE),
          elseStatement);

  static ImplementsClauseImpl implementsClause(List<NamedType> types) =>
      astFactory.implementsClause(
          TokenFactory.tokenFromKeyword(Keyword.IMPLEMENTS), types);

  static ImportDirectiveImpl importDirective(List<Annotation> metadata,
          String uri, bool isDeferred, String? prefix,
          [List<Combinator> combinators = const []]) =>
      astFactory.importDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.IMPORT),
          string2(uri),
          null,
          !isDeferred ? null : TokenFactory.tokenFromKeyword(Keyword.DEFERRED),
          prefix == null ? null : TokenFactory.tokenFromKeyword(Keyword.AS),
          prefix == null ? null : identifier3(prefix),
          combinators,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ImportDirectiveImpl importDirective2(
          String uri, bool isDeferred, String prefix,
          [List<Combinator> combinators = const []]) =>
      importDirective([], uri, isDeferred, prefix, combinators);

  static ImportDirectiveImpl importDirective3(String uri, String? prefix,
          [List<Combinator> combinators = const []]) =>
      importDirective([], uri, false, prefix, combinators);

  static IndexExpressionImpl indexExpression({
    required Expression target,
    bool hasQuestion = false,
    required Expression index,
  }) {
    return astFactory.indexExpressionForTarget2(
      target: target,
      question: hasQuestion
          ? TokenFactory.tokenFromType(
              TokenType.QUESTION,
            )
          : null,
      leftBracket: TokenFactory.tokenFromType(
        TokenType.OPEN_SQUARE_BRACKET,
      ),
      index: index,
      rightBracket: TokenFactory.tokenFromType(
        TokenType.CLOSE_SQUARE_BRACKET,
      ),
    );
  }

  static IndexExpressionImpl indexExpressionForCascade(Expression array,
          Expression index, TokenType period, TokenType leftBracket) =>
      astFactory.indexExpressionForCascade2(
          period: TokenFactory.tokenFromType(period),
          leftBracket: TokenFactory.tokenFromType(leftBracket),
          index: index,
          rightBracket:
              TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static InstanceCreationExpressionImpl instanceCreationExpression(
          Keyword? keyword, ConstructorName name,
          [List<Expression> arguments = const []]) =>
      astFactory.instanceCreationExpression(
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          name,
          argumentList(arguments));

  static InstanceCreationExpressionImpl instanceCreationExpression2(
          Keyword? keyword, NamedType type,
          [List<Expression> arguments = const []]) =>
      instanceCreationExpression3(keyword, type, null, arguments);

  static InstanceCreationExpressionImpl instanceCreationExpression3(
          Keyword? keyword, NamedType type, String? identifier,
          [List<Expression> arguments = const []]) =>
      instanceCreationExpression(
          keyword,
          astFactory.constructorName(
              type,
              identifier == null
                  ? null
                  : TokenFactory.tokenFromType(TokenType.PERIOD),
              identifier == null ? null : identifier3(identifier)),
          arguments);

  static IntegerLiteralImpl integer(int value) => astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, value.toString()),
      value);

  static InterpolationExpressionImpl interpolationExpression(
          Expression expression) =>
      astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static InterpolationExpressionImpl interpolationExpression2(
          String identifier) =>
      astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_IDENTIFIER),
          identifier3(identifier),
          null);

  static InterpolationStringImpl interpolationString(
          String contents, String value) =>
      astFactory.interpolationString(
          TokenFactory.tokenFromString(contents), value);

  static IsExpressionImpl isExpression(
          Expression expression, bool negated, TypeAnnotation type) =>
      astFactory.isExpression(
          expression,
          TokenFactory.tokenFromKeyword(Keyword.IS),
          negated ? TokenFactory.tokenFromType(TokenType.BANG) : null,
          type);

  static LabelImpl label(SimpleIdentifier label) =>
      astFactory.label(label, TokenFactory.tokenFromType(TokenType.COLON));

  static LabelImpl label2(String label) =>
      AstTestFactory.label(identifier3(label));

  static LabeledStatementImpl labeledStatement(
          List<Label> labels, Statement statement) =>
      astFactory.labeledStatement(labels, statement);

  static LibraryDirectiveImpl libraryDirective(
          List<Annotation> metadata, LibraryIdentifier libraryName) =>
      astFactory.libraryDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.LIBRARY),
          libraryName,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static LibraryDirectiveImpl libraryDirective2(String libraryName) =>
      libraryDirective(<Annotation>[], libraryIdentifier2([libraryName]));

  static LibraryIdentifierImpl libraryIdentifier(
          List<SimpleIdentifier> components) =>
      astFactory.libraryIdentifier(components);

  static LibraryIdentifierImpl libraryIdentifier2(List<String> components) {
    return astFactory.libraryIdentifier(identifierList(components));
  }

  static List list(List<Object> elements) {
    return elements;
  }

  static ListLiteralImpl listLiteral([List<Expression> elements = const []]) =>
      listLiteral2(null, null, elements);

  static ListLiteralImpl listLiteral2(
          Keyword? keyword, TypeArgumentList? typeArguments,
          [List<CollectionElement> elements = const []]) =>
      astFactory.listLiteral(
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          typeArguments,
          TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
          elements,
          TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static MapLiteralEntryImpl mapLiteralEntry(String key, Expression value) =>
      astFactory.mapLiteralEntry(
          string2(key), TokenFactory.tokenFromType(TokenType.COLON), value);

  static MapLiteralEntryImpl mapLiteralEntry2(
          Expression key, Expression value) =>
      astFactory.mapLiteralEntry(
          key, TokenFactory.tokenFromType(TokenType.COLON), value);

  static MapLiteralEntryImpl mapLiteralEntry3(String key, String value) =>
      astFactory.mapLiteralEntry(string2(key),
          TokenFactory.tokenFromType(TokenType.COLON), string2(value));

  static MethodDeclarationImpl methodDeclaration(
          Keyword? modifier,
          TypeAnnotation? returnType,
          Keyword? property,
          Keyword? operator,
          SimpleIdentifier name,
          FormalParameterList? parameters) =>
      astFactory.methodDeclaration(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.EXTERNAL),
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator == null ? null : TokenFactory.tokenFromKeyword(operator),
          name,
          null,
          parameters,
          emptyFunctionBody());

  static MethodDeclarationImpl methodDeclaration2(
          Keyword? modifier,
          TypeAnnotation? returnType,
          Keyword? property,
          Keyword? operator,
          SimpleIdentifier name,
          FormalParameterList? parameters,
          FunctionBody body) =>
      astFactory.methodDeclaration(
          null,
          null,
          null,
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator == null ? null : TokenFactory.tokenFromKeyword(operator),
          name,
          null,
          parameters,
          body);

  static MethodDeclarationImpl methodDeclaration3(
          Keyword? modifier,
          TypeAnnotation? returnType,
          Keyword? property,
          Keyword? operator,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          FunctionBody body) =>
      astFactory.methodDeclaration(
          null,
          null,
          null,
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator == null ? null : TokenFactory.tokenFromKeyword(operator),
          name,
          typeParameters,
          parameters,
          body);

  static MethodDeclarationImpl methodDeclaration4(
          {bool external = false,
          Keyword? modifier,
          TypeAnnotation? returnType,
          Keyword? property,
          bool operator = false,
          required String name,
          FormalParameterList? parameters,
          required FunctionBody body}) =>
      astFactory.methodDeclaration(
          null,
          null,
          external ? TokenFactory.tokenFromKeyword(Keyword.EXTERNAL) : null,
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator ? TokenFactory.tokenFromKeyword(Keyword.OPERATOR) : null,
          identifier3(name),
          null,
          parameters,
          body);

  static MethodInvocationImpl methodInvocation(
          Expression? target, String methodName,
          [List<Expression> arguments = const [],
          TokenType operator = TokenType.PERIOD]) =>
      astFactory.methodInvocation(
          target,
          target == null ? null : TokenFactory.tokenFromType(operator),
          identifier3(methodName),
          null,
          argumentList(arguments));

  static MethodInvocationImpl methodInvocation2(String methodName,
          [List<Expression> arguments = const []]) =>
      methodInvocation(null, methodName, arguments);

  static MethodInvocationImpl methodInvocation3(Expression? target,
          String methodName, TypeArgumentList? typeArguments,
          [List<Expression> arguments = const [],
          TokenType operator = TokenType.PERIOD]) =>
      astFactory.methodInvocation(
          target,
          target == null ? null : TokenFactory.tokenFromType(operator),
          identifier3(methodName),
          typeArguments,
          argumentList(arguments));

  static NamedExpressionImpl namedExpression(
          Label label, Expression expression) =>
      astFactory.namedExpression(label, expression);

  static NamedExpressionImpl namedExpression2(
          String label, Expression expression) =>
      namedExpression(label2(label), expression);

  static DefaultFormalParameterImpl namedFormalParameter(
          NormalFormalParameter parameter, Expression? expression) =>
      astFactory.defaultFormalParameter(
          parameter,
          ParameterKind.NAMED,
          expression == null
              ? null
              : TokenFactory.tokenFromType(TokenType.COLON),
          expression);

  /// Create a type name whose name has been resolved to the given [element] and
  /// whose type has been resolved to the type of the given element.
  ///
  /// <b>Note:</b> This method does not correctly handle class elements that
  /// have type parameters.
  static NamedTypeImpl namedType(ClassElement element,
      [List<TypeAnnotation>? arguments]) {
    var name = identifier3(element.name);
    name.staticElement = element;
    var typeName = namedType3(name, arguments);
    typeName.type = element.instantiate(
      typeArguments: List.filled(
        element.typeParameters.length,
        DynamicTypeImpl.instance,
      ),
      nullabilitySuffix: NullabilitySuffix.star,
    );
    return typeName;
  }

  static NamedTypeImpl namedType3(Identifier name,
          [List<TypeAnnotation>? arguments]) =>
      astFactory.namedType(
        name: name,
        typeArguments: typeArgumentList(arguments),
      );

  static NamedTypeImpl namedType4(String name,
          [List<TypeAnnotation>? arguments, bool question = false]) =>
      astFactory.namedType(
        name: identifier3(name),
        typeArguments: typeArgumentList(arguments),
        question:
            question ? TokenFactory.tokenFromType(TokenType.QUESTION) : null,
      );

  static NativeClauseImpl nativeClause(String nativeCode) =>
      astFactory.nativeClause(
          TokenFactory.tokenFromString("native"), string2(nativeCode));

  static NativeFunctionBodyImpl nativeFunctionBody(String nativeMethodName) =>
      astFactory.nativeFunctionBody(
          TokenFactory.tokenFromString("native"),
          string2(nativeMethodName),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static NullLiteralImpl nullLiteral() =>
      astFactory.nullLiteral(TokenFactory.tokenFromKeyword(Keyword.NULL));

  static ParenthesizedExpressionImpl parenthesizedExpression(
          Expression expression) =>
      astFactory.parenthesizedExpression(
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static PartDirectiveImpl partDirective(
          List<Annotation> metadata, String url) =>
      astFactory.partDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.PART),
          string2(url),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static PartDirectiveImpl partDirective2(String url) =>
      partDirective(<Annotation>[], url);

  static PartOfDirectiveImpl partOfDirective(LibraryIdentifier libraryName) =>
      partOfDirective2(<Annotation>[], libraryName);

  static PartOfDirectiveImpl partOfDirective2(
          List<Annotation> metadata, LibraryIdentifier libraryName) =>
      astFactory.partOfDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.PART),
          TokenFactory.tokenFromString("of"),
          null,
          libraryName,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DefaultFormalParameterImpl positionalFormalParameter(
          NormalFormalParameter parameter, Expression? expression) =>
      astFactory.defaultFormalParameter(
          parameter,
          ParameterKind.POSITIONAL,
          expression == null ? null : TokenFactory.tokenFromType(TokenType.EQ),
          expression);

  static PostfixExpressionImpl postfixExpression(
          Expression expression, TokenType operator) =>
      astFactory.postfixExpression(
          expression, TokenFactory.tokenFromType(operator));

  static PrefixExpressionImpl prefixExpression(
          TokenType operator, Expression expression) =>
      astFactory.prefixExpression(
          TokenFactory.tokenFromType(operator), expression);

  static PropertyAccessImpl propertyAccess(
          Expression? target, SimpleIdentifier propertyName) =>
      astFactory.propertyAccess(
          target, TokenFactory.tokenFromType(TokenType.PERIOD), propertyName);

  static PropertyAccessImpl propertyAccess2(
          Expression? target, String propertyName,
          [TokenType operator = TokenType.PERIOD]) =>
      astFactory.propertyAccess(target, TokenFactory.tokenFromType(operator),
          identifier3(propertyName));

  static RedirectingConstructorInvocationImpl redirectingConstructorInvocation(
          [List<Expression> arguments = const []]) =>
      redirectingConstructorInvocation2(null, arguments);

  static RedirectingConstructorInvocationImpl redirectingConstructorInvocation2(
          String? constructorName,
          [List<Expression> arguments = const []]) =>
      astFactory.redirectingConstructorInvocation(
          TokenFactory.tokenFromKeyword(Keyword.THIS),
          constructorName == null
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          constructorName == null ? null : identifier3(constructorName),
          argumentList(arguments));

  static RethrowExpressionImpl rethrowExpression() => astFactory
      .rethrowExpression(TokenFactory.tokenFromKeyword(Keyword.RETHROW));

  static ReturnStatementImpl returnStatement() => returnStatement2(null);

  static ReturnStatementImpl returnStatement2(Expression? expression) =>
      astFactory.returnStatement(TokenFactory.tokenFromKeyword(Keyword.RETURN),
          expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ScriptTagImpl scriptTag(String scriptTag) =>
      astFactory.scriptTag(TokenFactory.tokenFromString(scriptTag));

  static SetOrMapLiteralImpl setOrMapLiteral(
          Keyword? keyword, TypeArgumentList? typeArguments,
          [List<CollectionElement> elements = const []]) =>
      astFactory.setOrMapLiteral(
        constKeyword:
            keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
        typeArguments: typeArguments,
        leftBracket: TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
        elements: elements,
        rightBracket: TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET),
      );

  static ShowClauseImpl showClause(List<ShowHideClauseElement> elements) =>
      astFactory.showClause(
          showKeyword: TokenFactory.tokenFromString("show"),
          elements: elements);

  static ShowCombinatorImpl showCombinator(
          List<SimpleIdentifier> identifiers) =>
      astFactory.showCombinator(
          TokenFactory.tokenFromString("show"), identifiers);

  static ShowCombinatorImpl showCombinator2(List<String> identifiers) =>
      astFactory.showCombinator(
          TokenFactory.tokenFromString("show"), identifierList(identifiers));

  static ShowHideElementImpl showHideElement(String name) =>
      astFactory.showHideElement(modifier: null, name: identifier3(name));

  static ShowHideElementImpl showHideElementGetter(String name) =>
      astFactory.showHideElement(
          modifier: TokenFactory.tokenFromString("get"),
          name: identifier3(name));

  static ShowHideElementImpl showHideElementOperator(String name) =>
      astFactory.showHideElement(
          modifier: TokenFactory.tokenFromString("operator"),
          name: identifier3(name));

  static ShowHideElementImpl showHideElementSetter(String name) =>
      astFactory.showHideElement(
          modifier: TokenFactory.tokenFromString("set"),
          name: identifier3(name));

  static SimpleFormalParameterImpl simpleFormalParameter(
          Keyword keyword, String parameterName) =>
      simpleFormalParameter2(keyword, null, parameterName);

  static SimpleFormalParameterImpl simpleFormalParameter2(
          Keyword? keyword, TypeAnnotation? type, String? parameterName) =>
      astFactory.simpleFormalParameter2(
          keyword:
              keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type: type,
          identifier:
              parameterName == null ? null : identifier3(parameterName));

  static SimpleFormalParameterImpl simpleFormalParameter3(
          String parameterName) =>
      simpleFormalParameter2(null, null, parameterName);

  static SimpleFormalParameterImpl simpleFormalParameter4(
          TypeAnnotation type, String? parameterName) =>
      simpleFormalParameter2(null, type, parameterName);

  static SpreadElementImpl spreadElement(
          TokenType operator, Expression expression) =>
      astFactory.spreadElement(
          spreadOperator: TokenFactory.tokenFromType(operator),
          expression: expression);

  static StringInterpolationImpl string(
          [List<InterpolationElement> elements = const []]) =>
      astFactory.stringInterpolation(elements);

  static SimpleStringLiteralImpl string2(String content) => astFactory
      .simpleStringLiteral(TokenFactory.tokenFromString("'$content'"), content);

  static SuperConstructorInvocationImpl superConstructorInvocation(
          [List<Expression> arguments = const []]) =>
      superConstructorInvocation2(null, arguments);

  static SuperConstructorInvocationImpl superConstructorInvocation2(
          String? name,
          [List<Expression> arguments = const []]) =>
      astFactory.superConstructorInvocation(
          TokenFactory.tokenFromKeyword(Keyword.SUPER),
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name),
          argumentList(arguments));

  static SuperExpressionImpl superExpression() =>
      astFactory.superExpression(TokenFactory.tokenFromKeyword(Keyword.SUPER));

  static SuperFormalParameterImpl superFormalParameter(
          Keyword? keyword, TypeAnnotation? type, String identifier,
          [FormalParameterList? parameterList]) =>
      astFactory.superFormalParameter(
          keyword:
              keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type: type,
          superKeyword: TokenFactory.tokenFromKeyword(Keyword.SUPER),
          period: TokenFactory.tokenFromType(TokenType.PERIOD),
          identifier: identifier3(identifier),
          parameters: parameterList);

  static SuperFormalParameterImpl superFormalParameter2(String identifier) =>
      superFormalParameter(null, null, identifier);

  static SwitchCaseImpl switchCase(
          Expression expression, List<Statement> statements) =>
      switchCase2(<Label>[], expression, statements);

  static SwitchCaseImpl switchCase2(List<Label> labels, Expression expression,
          List<Statement> statements) =>
      astFactory.switchCase(labels, TokenFactory.tokenFromKeyword(Keyword.CASE),
          expression, TokenFactory.tokenFromType(TokenType.COLON), statements);

  static SwitchDefaultImpl switchDefault(
          List<Label> labels, List<Statement> statements) =>
      astFactory.switchDefault(
          labels,
          TokenFactory.tokenFromKeyword(Keyword.DEFAULT),
          TokenFactory.tokenFromType(TokenType.COLON),
          statements);

  static SwitchDefaultImpl switchDefault2(List<Statement> statements) =>
      switchDefault(<Label>[], statements);

  static SwitchStatementImpl switchStatement(
          Expression expression, List<SwitchMember> members) =>
      astFactory.switchStatement(
          TokenFactory.tokenFromKeyword(Keyword.SWITCH),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          members,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static SymbolLiteralImpl symbolLiteral(List<String> components) {
    List<Token> identifierList = <Token>[];
    for (String component in components) {
      identifierList.add(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, component));
    }
    return astFactory.symbolLiteral(
        TokenFactory.tokenFromType(TokenType.HASH), identifierList);
  }

  static BlockFunctionBodyImpl syncBlockFunctionBody(
          [List<Statement> statements = const []]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "sync"),
          null,
          block(statements));

  static BlockFunctionBodyImpl syncGeneratorBlockFunctionBody(
          [List<Statement> statements = const []]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "sync"),
          TokenFactory.tokenFromType(TokenType.STAR),
          block(statements));

  static ThisExpressionImpl thisExpression() =>
      astFactory.thisExpression(TokenFactory.tokenFromKeyword(Keyword.THIS));

  static ThrowExpressionImpl throwExpression2(Expression expression) =>
      astFactory.throwExpression(
          TokenFactory.tokenFromKeyword(Keyword.THROW), expression);

  static TopLevelVariableDeclarationImpl topLevelVariableDeclaration(
          Keyword? keyword,
          TypeAnnotation? type,
          List<VariableDeclaration> variables) =>
      astFactory.topLevelVariableDeclaration(
          null,
          null,
          variableDeclarationList(keyword, type, variables),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TopLevelVariableDeclarationImpl topLevelVariableDeclaration2(
          Keyword? keyword, List<VariableDeclaration> variables,
          {bool isExternal = false}) =>
      astFactory.topLevelVariableDeclaration(
          null,
          null,
          variableDeclarationList(keyword, null, variables),
          TokenFactory.tokenFromType(TokenType.SEMICOLON),
          externalKeyword: isExternal
              ? TokenFactory.tokenFromKeyword(Keyword.EXTERNAL)
              : null);

  static TryStatementImpl tryStatement(Block body, Block finallyClause) =>
      tryStatement3(body, <CatchClause>[], finallyClause);

  static TryStatementImpl tryStatement2(
          Block body, List<CatchClause> catchClauses) =>
      tryStatement3(body, catchClauses, null);

  static TryStatementImpl tryStatement3(
          Block body, List<CatchClause> catchClauses, Block? finallyClause) =>
      astFactory.tryStatement(
          TokenFactory.tokenFromKeyword(Keyword.TRY),
          body,
          catchClauses,
          finallyClause == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.FINALLY),
          finallyClause);

  static FunctionTypeAliasImpl typeAlias(TypeAnnotation returnType, String name,
          TypeParameterList? typeParameters, FormalParameterList parameters) =>
      astFactory.functionTypeAlias(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.TYPEDEF),
          returnType,
          identifier3(name),
          typeParameters,
          parameters,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TypeArgumentList? typeArgumentList(List<TypeAnnotation>? types) {
    if (types == null || types.isEmpty) {
      return null;
    }
    return typeArgumentList2(types);
  }

  static TypeArgumentListImpl typeArgumentList2(List<TypeAnnotation> types) {
    return astFactory.typeArgumentList(TokenFactory.tokenFromType(TokenType.LT),
        types, TokenFactory.tokenFromType(TokenType.GT));
  }

  static TypeParameterImpl typeParameter(String name) =>
      astFactory.typeParameter(null, null, identifier3(name), null, null);

  static TypeParameterImpl typeParameter2(String name, TypeAnnotation bound) =>
      astFactory.typeParameter(null, null, identifier3(name),
          TokenFactory.tokenFromKeyword(Keyword.EXTENDS), bound);

  static TypeParameterImpl typeParameter3(String name, String varianceLexeme) =>
      // TODO (kallentu) : Clean up AstFactoryImpl casting once variance is
      // added to the interface.
      astFactory.typeParameter2(
          comment: null,
          metadata: null,
          name: identifier3(name),
          extendsKeyword: null,
          bound: null,
          varianceKeyword: TokenFactory.tokenFromString(varianceLexeme));

  static TypeParameterList? typeParameterList([List<String>? typeNames]) {
    if (typeNames == null || typeNames.isEmpty) {
      return null;
    }
    return typeParameterList2(typeNames);
  }

  static TypeParameterListImpl typeParameterList2(List<String> typeNames) {
    var typeParameters = <TypeParameter>[];
    for (String typeName in typeNames) {
      typeParameters.add(typeParameter(typeName));
    }

    return astFactory.typeParameterList(
        TokenFactory.tokenFromType(TokenType.LT),
        typeParameters,
        TokenFactory.tokenFromType(TokenType.GT));
  }

  static VariableDeclarationImpl variableDeclaration(String name) =>
      astFactory.variableDeclaration(identifier3(name), null, null);

  static VariableDeclarationImpl variableDeclaration2(
          String name, Expression initializer) =>
      astFactory.variableDeclaration(identifier3(name),
          TokenFactory.tokenFromType(TokenType.EQ), initializer);

  static VariableDeclarationListImpl variableDeclarationList(Keyword? keyword,
          TypeAnnotation? type, List<VariableDeclaration> variables) =>
      astFactory.variableDeclarationList(
          null,
          null,
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type,
          variables);

  static VariableDeclarationListImpl variableDeclarationList2(
          Keyword? keyword, List<VariableDeclaration> variables) =>
      variableDeclarationList(keyword, null, variables);

  static VariableDeclarationStatementImpl variableDeclarationStatement(
          Keyword? keyword,
          TypeAnnotation? type,
          List<VariableDeclaration> variables) =>
      astFactory.variableDeclarationStatement(
          variableDeclarationList(keyword, type, variables),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static VariableDeclarationStatementImpl variableDeclarationStatement2(
          Keyword keyword, List<VariableDeclaration> variables) =>
      variableDeclarationStatement(keyword, null, variables);

  static WhileStatementImpl whileStatement(
          Expression condition, Statement body) =>
      astFactory.whileStatement(
          TokenFactory.tokenFromKeyword(Keyword.WHILE),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body);

  static WithClauseImpl withClause(List<NamedType> types) =>
      astFactory.withClause(TokenFactory.tokenFromKeyword(Keyword.WITH), types);

  static YieldStatementImpl yieldEachStatement(Expression expression) =>
      astFactory.yieldStatement(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"),
          TokenFactory.tokenFromType(TokenType.STAR),
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static YieldStatementImpl yieldStatement(Expression expression) =>
      astFactory.yieldStatement(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"),
          null,
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));
}
