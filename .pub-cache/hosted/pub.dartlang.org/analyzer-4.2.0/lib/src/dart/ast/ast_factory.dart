// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/// The instance of [AstFactoryImpl].
final AstFactoryImpl astFactory = AstFactoryImpl();

class AstFactoryImpl {
  AnnotationImpl annotation(
          {required Token atSign,
          required Identifier name,
          TypeArgumentList? typeArguments,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList? arguments}) =>
      AnnotationImpl(
          atSign,
          name as IdentifierImpl,
          typeArguments as TypeArgumentListImpl?,
          period,
          constructorName as SimpleIdentifierImpl?,
          arguments as ArgumentListImpl?);

  BlockImpl block(
          Token leftBracket, List<Statement> statements, Token rightBracket) =>
      BlockImpl(leftBracket, statements, rightBracket);

  CommentImpl blockComment(List<Token> tokens) =>
      CommentImpl.createBlockComment(tokens);

  BlockFunctionBodyImpl blockFunctionBody(
          Token? keyword, Token? star, Block block) =>
      BlockFunctionBodyImpl(keyword, star, block as BlockImpl);

  BooleanLiteralImpl booleanLiteral(Token literal, bool value) =>
      BooleanLiteralImpl(literal, value);

  BreakStatementImpl breakStatement(
          Token breakKeyword, SimpleIdentifier? label, Token semicolon) =>
      BreakStatementImpl(
          breakKeyword, label as SimpleIdentifierImpl?, semicolon);

  CascadeExpressionImpl cascadeExpression(
          Expression target, List<Expression> cascadeSections) =>
      CascadeExpressionImpl(target as ExpressionImpl, cascadeSections);

  CatchClauseImpl catchClause(
          Token? onKeyword,
          TypeAnnotation? exceptionType,
          Token? catchKeyword,
          Token? leftParenthesis,
          SimpleIdentifier? exceptionParameter,
          Token? comma,
          SimpleIdentifier? stackTraceParameter,
          Token? rightParenthesis,
          Block body) =>
      CatchClauseImpl(
          onKeyword,
          exceptionType as TypeAnnotationImpl?,
          catchKeyword,
          leftParenthesis,
          exceptionParameter as SimpleIdentifierImpl?,
          comma,
          stackTraceParameter as SimpleIdentifierImpl?,
          rightParenthesis,
          body as BlockImpl);

  ClassDeclarationImpl classDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? abstractKeyword,
          Token? macroKeyword,
          Token? augmentKeyword,
          Token classKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          ExtendsClause? extendsClause,
          WithClause? withClause,
          ImplementsClause? implementsClause,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket) =>
      ClassDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          abstractKeyword,
          macroKeyword,
          augmentKeyword,
          classKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          extendsClause as ExtendsClauseImpl?,
          withClause as WithClauseImpl?,
          implementsClause as ImplementsClauseImpl?,
          leftBracket,
          members,
          rightBracket);

  ClassTypeAliasImpl classTypeAlias(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          Token equals,
          Token? abstractKeyword,
          Token? macroKeyword,
          Token? augmentKeyword,
          NamedType superclass,
          WithClause withClause,
          ImplementsClause? implementsClause,
          Token semicolon) =>
      ClassTypeAliasImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          equals,
          abstractKeyword,
          macroKeyword,
          augmentKeyword,
          superclass as NamedTypeImpl,
          withClause as WithClauseImpl,
          implementsClause as ImplementsClauseImpl?,
          semicolon);

  CommentReferenceImpl commentReference(
          Token? newKeyword, CommentReferableExpression expression) =>
      CommentReferenceImpl(
          newKeyword, expression as CommentReferableExpressionImpl);

  CompilationUnitImpl compilationUnit(
          {required Token beginToken,
          ScriptTag? scriptTag,
          List<Directive>? directives,
          List<CompilationUnitMember>? declarations,
          required Token endToken,
          required FeatureSet featureSet,
          // TODO(dantup): LineInfo should be made required and non-nullable
          //   when breaking API changes can be made. Callers that do not
          //   provide lineInfos may have offsets incorrectly mapped to line/col
          //   for LSP.
          LineInfo? lineInfo}) =>
      CompilationUnitImpl(beginToken, scriptTag as ScriptTagImpl?, directives,
          declarations, endToken, featureSet, lineInfo ?? LineInfo([0]));

  ConditionalExpressionImpl conditionalExpression(
          Expression condition,
          Token question,
          Expression thenExpression,
          Token colon,
          Expression elseExpression) =>
      ConditionalExpressionImpl(
          condition as ExpressionImpl,
          question,
          thenExpression as ExpressionImpl,
          colon,
          elseExpression as ExpressionImpl);

  ConfigurationImpl configuration(
          Token ifKeyword,
          Token leftParenthesis,
          DottedName name,
          Token? equalToken,
          StringLiteral? value,
          Token rightParenthesis,
          StringLiteral libraryUri) =>
      ConfigurationImpl(
          ifKeyword,
          leftParenthesis,
          name as DottedNameImpl,
          equalToken,
          value as StringLiteralImpl?,
          rightParenthesis,
          libraryUri as StringLiteralImpl);

  ConstructorDeclarationImpl constructorDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? externalKeyword,
          Token? constKeyword,
          Token? factoryKeyword,
          Identifier returnType,
          Token? period,
          SimpleIdentifier? name,
          FormalParameterList parameters,
          Token? separator,
          List<ConstructorInitializer>? initializers,
          ConstructorName? redirectedConstructor,
          FunctionBody? body) =>
      ConstructorDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          externalKeyword,
          constKeyword,
          factoryKeyword,
          returnType as IdentifierImpl,
          period,
          name as SimpleIdentifierImpl?,
          parameters as FormalParameterListImpl,
          separator,
          initializers,
          redirectedConstructor as ConstructorNameImpl?,
          body as FunctionBodyImpl);

  ConstructorFieldInitializerImpl constructorFieldInitializer(
          Token? thisKeyword,
          Token? period,
          SimpleIdentifier fieldName,
          Token equals,
          Expression expression) =>
      ConstructorFieldInitializerImpl(
          thisKeyword,
          period,
          fieldName as SimpleIdentifierImpl,
          equals,
          expression as ExpressionImpl);

  ConstructorNameImpl constructorName(
          NamedType type, Token? period, SimpleIdentifier? name) =>
      ConstructorNameImpl(
          type as NamedTypeImpl, period, name as SimpleIdentifierImpl?);

  ConstructorReferenceImpl constructorReference(
          {required ConstructorName constructorName}) =>
      ConstructorReferenceImpl(constructorName as ConstructorNameImpl);

  ContinueStatementImpl continueStatement(
          Token continueKeyword, SimpleIdentifier? label, Token semicolon) =>
      ContinueStatementImpl(
          continueKeyword, label as SimpleIdentifierImpl?, semicolon);

  DeclaredIdentifierImpl declaredIdentifier(
          Comment? comment,
          List<Annotation>? metadata,
          Token? keyword,
          TypeAnnotation? type,
          SimpleIdentifier identifier) =>
      DeclaredIdentifierImpl(comment as CommentImpl?, metadata, keyword,
          type as TypeAnnotationImpl?, identifier as SimpleIdentifierImpl);

  DefaultFormalParameterImpl defaultFormalParameter(
          NormalFormalParameter parameter,
          ParameterKind kind,
          Token? separator,
          Expression? defaultValue) =>
      DefaultFormalParameterImpl(parameter as NormalFormalParameterImpl, kind,
          separator, defaultValue as ExpressionImpl?);

  CommentImpl documentationComment(List<Token> tokens,
          [List<CommentReference>? references]) =>
      CommentImpl.createDocumentationCommentWithReferences(
          tokens, references ?? <CommentReference>[]);

  DoStatementImpl doStatement(
          Token doKeyword,
          Statement body,
          Token whileKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Token semicolon) =>
      DoStatementImpl(
          doKeyword,
          body as StatementImpl,
          whileKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          rightParenthesis,
          semicolon);

  DottedNameImpl dottedName(List<SimpleIdentifier> components) =>
      DottedNameImpl(components);

  DoubleLiteralImpl doubleLiteral(Token literal, double value) =>
      DoubleLiteralImpl(literal, value);

  EmptyFunctionBodyImpl emptyFunctionBody(Token semicolon) =>
      EmptyFunctionBodyImpl(semicolon);

  EmptyStatementImpl emptyStatement(Token semicolon) =>
      EmptyStatementImpl(semicolon);

  CommentImpl endOfLineComment(List<Token> tokens) =>
      CommentImpl.createEndOfLineComment(tokens);

  EnumConstantDeclarationImpl enumConstantDeclaration(Comment? comment,
          List<Annotation>? metadata, SimpleIdentifier name) =>
      EnumConstantDeclarationImpl(
        documentationComment: comment as CommentImpl?,
        metadata: metadata,
        name: name as SimpleIdentifierImpl,
        arguments: null,
      );

  @Deprecated('Use enumDeclaration2() instead')
  EnumDeclarationImpl enumDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token enumKeyword,
          SimpleIdentifier name,
          Token leftBracket,
          List<EnumConstantDeclaration> constants,
          Token rightBracket) =>
      enumDeclaration2(
          comment: comment,
          metadata: metadata,
          enumKeyword: enumKeyword,
          name: name,
          typeParameters: null,
          withClause: null,
          implementsClause: null,
          leftBracket: leftBracket,
          constants: constants,
          semicolon: null,
          members: [],
          rightBracket: rightBracket);

  EnumDeclarationImpl enumDeclaration2({
    required Comment? comment,
    required List<Annotation>? metadata,
    required Token enumKeyword,
    required SimpleIdentifier name,
    required TypeParameterList? typeParameters,
    required WithClause? withClause,
    required ImplementsClause? implementsClause,
    required Token leftBracket,
    required List<EnumConstantDeclaration> constants,
    required List<ClassMember> members,
    required Token? semicolon,
    required Token rightBracket,
  }) {
    return EnumDeclarationImpl(
      comment as CommentImpl?,
      metadata,
      enumKeyword,
      name as SimpleIdentifierImpl,
      typeParameters as TypeParameterListImpl?,
      withClause as WithClauseImpl?,
      implementsClause as ImplementsClauseImpl?,
      leftBracket,
      constants,
      semicolon,
      members,
      rightBracket,
    );
  }

  ExportDirectiveImpl exportDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration>? configurations,
          List<Combinator>? combinators,
          Token semicolon) =>
      ExportDirectiveImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          libraryUri as StringLiteralImpl,
          configurations,
          combinators,
          semicolon);

  ExpressionFunctionBodyImpl expressionFunctionBody(Token? keyword,
          Token functionDefinition, Expression expression, Token? semicolon) =>
      ExpressionFunctionBodyImpl(keyword, null, functionDefinition,
          expression as ExpressionImpl, semicolon);

  ExpressionFunctionBodyImpl expressionFunctionBody2({
    Token? keyword,
    Token? star,
    required Token functionDefinition,
    required Expression expression,
    Token? semicolon,
  }) =>
      ExpressionFunctionBodyImpl(keyword, star, functionDefinition,
          expression as ExpressionImpl, semicolon);

  ExpressionStatementImpl expressionStatement(
          Expression expression, Token? semicolon) =>
      ExpressionStatementImpl(expression as ExpressionImpl, semicolon);

  ExtendsClauseImpl extendsClause(Token extendsKeyword, NamedType superclass) =>
      ExtendsClauseImpl(extendsKeyword, superclass as NamedTypeImpl);

  ExtensionDeclarationImpl extensionDeclaration(
          {Comment? comment,
          List<Annotation>? metadata,
          required Token extensionKeyword,
          Token? typeKeyword,
          SimpleIdentifier? name,
          TypeParameterList? typeParameters,
          required Token onKeyword,
          required TypeAnnotation extendedType,
          ShowClause? showClause,
          HideClause? hideClause,
          required Token leftBracket,
          required List<ClassMember> members,
          required Token rightBracket}) =>
      ExtensionDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          extensionKeyword,
          typeKeyword,
          name as SimpleIdentifierImpl?,
          typeParameters as TypeParameterListImpl?,
          onKeyword,
          extendedType as TypeAnnotationImpl,
          showClause as ShowClauseImpl?,
          hideClause as HideClauseImpl?,
          leftBracket,
          members,
          rightBracket);

  ExtensionOverrideImpl extensionOverride(
          {required Identifier extensionName,
          TypeArgumentList? typeArguments,
          required ArgumentList argumentList}) =>
      ExtensionOverrideImpl(
          extensionName as IdentifierImpl,
          typeArguments as TypeArgumentListImpl?,
          argumentList as ArgumentListImpl);

  FieldDeclarationImpl fieldDeclaration2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? abstractKeyword,
          Token? augmentKeyword,
          Token? covariantKeyword,
          Token? externalKeyword,
          Token? staticKeyword,
          required VariableDeclarationList fieldList,
          required Token semicolon}) =>
      FieldDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          abstractKeyword,
          augmentKeyword,
          covariantKeyword,
          externalKeyword,
          staticKeyword,
          fieldList as VariableDeclarationListImpl,
          semicolon);

  FieldFormalParameterImpl fieldFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required Token thisKeyword,
          required Token period,
          required SimpleIdentifier identifier,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          Token? question}) =>
      FieldFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          thisKeyword,
          period,
          identifier as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?,
          question);

  ForEachPartsWithDeclarationImpl forEachPartsWithDeclaration(
          {required DeclaredIdentifier loopVariable,
          required Token inKeyword,
          required Expression iterable}) =>
      ForEachPartsWithDeclarationImpl(loopVariable as DeclaredIdentifierImpl,
          inKeyword, iterable as ExpressionImpl);

  ForEachPartsWithIdentifierImpl forEachPartsWithIdentifier(
          {required SimpleIdentifier identifier,
          required Token inKeyword,
          required Expression iterable}) =>
      ForEachPartsWithIdentifierImpl(identifier as SimpleIdentifierImpl,
          inKeyword, iterable as ExpressionImpl);

  ForElementImpl forElement(
          {Token? awaitKeyword,
          required Token forKeyword,
          required Token leftParenthesis,
          required ForLoopParts forLoopParts,
          required Token rightParenthesis,
          required CollectionElement body}) =>
      ForElementImpl(
          awaitKeyword,
          forKeyword,
          leftParenthesis,
          forLoopParts as ForLoopPartsImpl,
          rightParenthesis,
          body as CollectionElementImpl);

  FormalParameterListImpl formalParameterList(
          Token leftParenthesis,
          List<FormalParameter> parameters,
          Token? leftDelimiter,
          Token? rightDelimiter,
          Token rightParenthesis) =>
      FormalParameterListImpl(leftParenthesis, parameters, leftDelimiter,
          rightDelimiter, rightParenthesis);

  ForPartsWithDeclarationsImpl forPartsWithDeclarations(
          {required VariableDeclarationList variables,
          required Token leftSeparator,
          Expression? condition,
          required Token rightSeparator,
          List<Expression>? updaters}) =>
      ForPartsWithDeclarationsImpl(
          variables as VariableDeclarationListImpl,
          leftSeparator,
          condition as ExpressionImpl?,
          rightSeparator,
          updaters);

  ForPartsWithExpressionImpl forPartsWithExpression(
          {Expression? initialization,
          required Token leftSeparator,
          Expression? condition,
          required Token rightSeparator,
          List<Expression>? updaters}) =>
      ForPartsWithExpressionImpl(
          initialization as ExpressionImpl?,
          leftSeparator,
          condition as ExpressionImpl?,
          rightSeparator,
          updaters);

  ForStatementImpl forStatement(
      {Token? awaitKeyword,
      required Token forKeyword,
      required Token leftParenthesis,
      required ForLoopParts forLoopParts,
      required Token rightParenthesis,
      required Statement body}) {
    return ForStatementImpl(
        awaitKeyword,
        forKeyword,
        leftParenthesis,
        forLoopParts as ForLoopPartsImpl,
        rightParenthesis,
        body as StatementImpl);
  }

  FunctionDeclarationImpl functionDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? augmentKeyword,
          Token? externalKeyword,
          TypeAnnotation? returnType,
          Token? propertyKeyword,
          SimpleIdentifier name,
          FunctionExpression functionExpression) =>
      FunctionDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          augmentKeyword,
          externalKeyword,
          returnType as TypeAnnotationImpl?,
          propertyKeyword,
          name as SimpleIdentifierImpl,
          functionExpression as FunctionExpressionImpl);

  FunctionDeclarationStatementImpl functionDeclarationStatement(
          FunctionDeclaration functionDeclaration) =>
      FunctionDeclarationStatementImpl(
          functionDeclaration as FunctionDeclarationImpl);

  FunctionExpressionImpl functionExpression(TypeParameterList? typeParameters,
          FormalParameterList? parameters, FunctionBody body) =>
      FunctionExpressionImpl(typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?, body as FunctionBodyImpl);

  FunctionExpressionInvocationImpl functionExpressionInvocation(
          Expression function,
          TypeArgumentList? typeArguments,
          ArgumentList argumentList) =>
      FunctionExpressionInvocationImpl(
          function as ExpressionImpl,
          typeArguments as TypeArgumentListImpl?,
          argumentList as ArgumentListImpl);

  FunctionReferenceImpl functionReference(
          {required Expression function, TypeArgumentList? typeArguments}) =>
      FunctionReferenceImpl(function as ExpressionImpl,
          typeArguments: typeArguments as TypeArgumentListImpl?);

  FunctionTypeAliasImpl functionTypeAlias(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          TypeAnnotation? returnType,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          FormalParameterList parameters,
          Token semicolon) =>
      FunctionTypeAliasImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          returnType as TypeAnnotationImpl?,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl,
          semicolon);

  FunctionTypedFormalParameterImpl functionTypedFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          TypeAnnotation? returnType,
          required SimpleIdentifier identifier,
          TypeParameterList? typeParameters,
          required FormalParameterList parameters,
          Token? question}) =>
      FunctionTypedFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          returnType as TypeAnnotationImpl?,
          identifier as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl,
          question);

  GenericFunctionTypeImpl genericFunctionType(
          TypeAnnotation? returnType,
          Token functionKeyword,
          TypeParameterList? typeParameters,
          FormalParameterList parameters,
          {Token? question}) =>
      GenericFunctionTypeImpl(
          returnType as TypeAnnotationImpl?,
          functionKeyword,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl,
          question: question);

  GenericTypeAliasImpl genericTypeAlias(
          Comment? comment,
          List<Annotation>? metadata,
          Token typedefKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          Token equals,
          TypeAnnotation type,
          Token semicolon) =>
      GenericTypeAliasImpl(
          comment as CommentImpl?,
          metadata,
          typedefKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          equals,
          type as TypeAnnotationImpl,
          semicolon);

  HideClauseImpl hideClause(
          {required Token hideKeyword,
          required List<ShowHideClauseElement> elements}) =>
      HideClauseImpl(hideKeyword, elements);

  HideCombinatorImpl hideCombinator(
          Token keyword, List<SimpleIdentifier> hiddenNames) =>
      HideCombinatorImpl(keyword, hiddenNames);

  IfElementImpl ifElement(
          {required Token ifKeyword,
          required Token leftParenthesis,
          required Expression condition,
          required Token rightParenthesis,
          required CollectionElement thenElement,
          Token? elseKeyword,
          CollectionElement? elseElement}) =>
      IfElementImpl(
          ifKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          rightParenthesis,
          thenElement as CollectionElementImpl,
          elseKeyword,
          elseElement as CollectionElementImpl?);

  IfStatementImpl ifStatement(
          Token ifKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Statement thenStatement,
          Token? elseKeyword,
          Statement? elseStatement) =>
      IfStatementImpl(
          ifKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          rightParenthesis,
          thenStatement as StatementImpl,
          elseKeyword,
          elseStatement as StatementImpl?);

  ImplementsClauseImpl implementsClause(
          Token implementsKeyword, List<NamedType> interfaces) =>
      ImplementsClauseImpl(implementsKeyword, interfaces);

  ImplicitCallReferenceImpl implicitCallReference({
    required Expression expression,
    required MethodElement staticElement,
    required TypeArgumentList? typeArguments,
    required List<DartType> typeArgumentTypes,
  }) =>
      ImplicitCallReferenceImpl(expression as ExpressionImpl,
          staticElement: staticElement,
          typeArguments: typeArguments as TypeArgumentListImpl?,
          typeArgumentTypes: typeArgumentTypes);

  ImportDirectiveImpl importDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration>? configurations,
          Token? deferredKeyword,
          Token? asKeyword,
          SimpleIdentifier? prefix,
          List<Combinator>? combinators,
          Token semicolon,
          {Token? augmentKeyword}) =>
      ImportDirectiveImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          augmentKeyword,
          libraryUri as StringLiteralImpl,
          configurations,
          deferredKeyword,
          asKeyword,
          prefix as SimpleIdentifierImpl?,
          combinators,
          semicolon);

  IndexExpressionImpl indexExpressionForCascade2(
          {required Token period,
          Token? question,
          required Token leftBracket,
          required Expression index,
          required Token rightBracket}) =>
      IndexExpressionImpl.forCascade(
          period, question, leftBracket, index as ExpressionImpl, rightBracket);

  IndexExpressionImpl indexExpressionForTarget2(
          {required Expression target,
          Token? question,
          required Token leftBracket,
          required Expression index,
          required Token rightBracket}) =>
      IndexExpressionImpl.forTarget(target as ExpressionImpl, question,
          leftBracket, index as ExpressionImpl, rightBracket);

  InstanceCreationExpressionImpl instanceCreationExpression(Token? keyword,
          ConstructorName constructorName, ArgumentList argumentList,
          {TypeArgumentList? typeArguments}) =>
      InstanceCreationExpressionImpl(
          keyword,
          constructorName as ConstructorNameImpl,
          argumentList as ArgumentListImpl,
          typeArguments: typeArguments as TypeArgumentListImpl?);

  IntegerLiteralImpl integerLiteral(Token literal, int? value) =>
      IntegerLiteralImpl(literal, value);

  InterpolationExpressionImpl interpolationExpression(
          Token leftBracket, Expression expression, Token? rightBracket) =>
      InterpolationExpressionImpl(
          leftBracket, expression as ExpressionImpl, rightBracket);

  InterpolationStringImpl interpolationString(Token contents, String value) =>
      InterpolationStringImpl(contents, value);

  IsExpressionImpl isExpression(Expression expression, Token isOperator,
          Token? notOperator, TypeAnnotation type) =>
      IsExpressionImpl(expression as ExpressionImpl, isOperator, notOperator,
          type as TypeAnnotationImpl);

  LabelImpl label(SimpleIdentifier label, Token colon) =>
      LabelImpl(label as SimpleIdentifierImpl, colon);

  LabeledStatementImpl labeledStatement(
          List<Label> labels, Statement statement) =>
      LabeledStatementImpl(labels, statement as StatementImpl);

  LibraryDirectiveImpl libraryDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token libraryKeyword,
          LibraryIdentifier name,
          Token semicolon) =>
      LibraryDirectiveImpl(comment as CommentImpl?, metadata, libraryKeyword,
          name as LibraryIdentifierImpl, semicolon);

  LibraryIdentifierImpl libraryIdentifier(List<SimpleIdentifier> components) =>
      LibraryIdentifierImpl(components);

  ListLiteralImpl listLiteral(
      Token? constKeyword,
      TypeArgumentList? typeArguments,
      Token leftBracket,
      List<CollectionElement> elements,
      Token rightBracket) {
    if (elements is List<Expression>) {
      return ListLiteralImpl(
          constKeyword,
          typeArguments as TypeArgumentListImpl?,
          leftBracket,
          elements,
          rightBracket);
    }
    return ListLiteralImpl.experimental(
        constKeyword,
        typeArguments as TypeArgumentListImpl?,
        leftBracket,
        elements,
        rightBracket);
  }

  MapLiteralEntryImpl mapLiteralEntry(
          Expression key, Token separator, Expression value) =>
      MapLiteralEntryImpl(
          key as ExpressionImpl, separator, value as ExpressionImpl);

  MethodDeclarationImpl methodDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? externalKeyword,
          Token? modifierKeyword,
          TypeAnnotation? returnType,
          Token? propertyKeyword,
          Token? operatorKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          FunctionBody body) =>
      MethodDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          externalKeyword,
          modifierKeyword,
          returnType as TypeAnnotationImpl?,
          propertyKeyword,
          operatorKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?,
          body as FunctionBodyImpl);

  MethodInvocationImpl methodInvocation(
          Expression? target,
          Token? operator,
          SimpleIdentifier methodName,
          TypeArgumentList? typeArguments,
          ArgumentList argumentList) =>
      MethodInvocationImpl(
          target as ExpressionImpl?,
          operator,
          methodName as SimpleIdentifierImpl,
          typeArguments as TypeArgumentListImpl?,
          argumentList as ArgumentListImpl);

  MixinDeclarationImpl mixinDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? augmentKeyword,
          Token mixinKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          OnClause? onClause,
          ImplementsClause? implementsClause,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket) =>
      MixinDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          augmentKeyword,
          mixinKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          onClause as OnClauseImpl?,
          implementsClause as ImplementsClauseImpl?,
          leftBracket,
          members,
          rightBracket);

  NamedExpressionImpl namedExpression(Label name, Expression expression) =>
      NamedExpressionImpl(name as LabelImpl, expression as ExpressionImpl);

  NamedTypeImpl namedType({
    required Identifier name,
    TypeArgumentList? typeArguments,
    Token? question,
  }) =>
      NamedTypeImpl(
          name as IdentifierImpl, typeArguments as TypeArgumentListImpl?,
          question: question);

  NativeClauseImpl nativeClause(Token nativeKeyword, StringLiteral? name) =>
      NativeClauseImpl(nativeKeyword, name as StringLiteralImpl?);

  NativeFunctionBodyImpl nativeFunctionBody(
          Token nativeKeyword, StringLiteral? stringLiteral, Token semicolon) =>
      NativeFunctionBodyImpl(
          nativeKeyword, stringLiteral as StringLiteralImpl?, semicolon);

  NodeListImpl<E> nodeList<E extends AstNode>(AstNode owner) =>
      NodeListImpl<E>(owner as AstNodeImpl);

  NullLiteralImpl nullLiteral(Token literal) => NullLiteralImpl(literal);

  OnClauseImpl onClause(
          Token onKeyword, List<NamedType> superclassConstraints) =>
      OnClauseImpl(onKeyword, superclassConstraints);

  ParenthesizedExpressionImpl parenthesizedExpression(Token leftParenthesis,
          Expression expression, Token rightParenthesis) =>
      ParenthesizedExpressionImpl(
          leftParenthesis, expression as ExpressionImpl, rightParenthesis);

  PartDirectiveImpl partDirective(Comment? comment, List<Annotation>? metadata,
          Token partKeyword, StringLiteral partUri, Token semicolon) =>
      PartDirectiveImpl(comment as CommentImpl?, metadata, partKeyword,
          partUri as StringLiteralImpl, semicolon);

  PartOfDirectiveImpl partOfDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token partKeyword,
          Token ofKeyword,
          StringLiteral? uri,
          LibraryIdentifier? libraryName,
          Token semicolon) =>
      PartOfDirectiveImpl(
          comment as CommentImpl?,
          metadata,
          partKeyword,
          ofKeyword,
          uri as StringLiteralImpl?,
          libraryName as LibraryIdentifierImpl?,
          semicolon);

  PostfixExpressionImpl postfixExpression(Expression operand, Token operator) =>
      PostfixExpressionImpl(operand as ExpressionImpl, operator);

  PrefixedIdentifierImpl prefixedIdentifier(
          SimpleIdentifier prefix, Token period, SimpleIdentifier identifier) =>
      PrefixedIdentifierImpl(prefix as SimpleIdentifierImpl, period,
          identifier as SimpleIdentifierImpl);

  PrefixExpressionImpl prefixExpression(Token operator, Expression operand) =>
      PrefixExpressionImpl(operator, operand as ExpressionImpl);

  PropertyAccessImpl propertyAccess(
          Expression? target, Token operator, SimpleIdentifier propertyName) =>
      PropertyAccessImpl(target as ExpressionImpl?, operator,
          propertyName as SimpleIdentifierImpl);

  RedirectingConstructorInvocationImpl redirectingConstructorInvocation(
          Token thisKeyword,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList argumentList) =>
      RedirectingConstructorInvocationImpl(
          thisKeyword,
          period,
          constructorName as SimpleIdentifierImpl?,
          argumentList as ArgumentListImpl);

  RethrowExpressionImpl rethrowExpression(Token rethrowKeyword) =>
      RethrowExpressionImpl(rethrowKeyword);

  ReturnStatementImpl returnStatement(
          Token returnKeyword, Expression? expression, Token semicolon) =>
      ReturnStatementImpl(
          returnKeyword, expression as ExpressionImpl?, semicolon);

  ScriptTagImpl scriptTag(Token scriptTag) => ScriptTagImpl(scriptTag);

  SetOrMapLiteralImpl setOrMapLiteral(
          {Token? constKeyword,
          TypeArgumentList? typeArguments,
          required Token leftBracket,
          required List<CollectionElement> elements,
          required Token rightBracket}) =>
      SetOrMapLiteralImpl(constKeyword, typeArguments as TypeArgumentListImpl?,
          leftBracket, elements, rightBracket);

  ShowClauseImpl showClause(
          {required Token showKeyword,
          required List<ShowHideClauseElement> elements}) =>
      ShowClauseImpl(showKeyword, elements);

  ShowCombinatorImpl showCombinator(
          Token keyword, List<SimpleIdentifier> shownNames) =>
      ShowCombinatorImpl(keyword, shownNames);

  ShowHideElementImpl showHideElement(
          {required Token? modifier, required SimpleIdentifier name}) =>
      ShowHideElementImpl(modifier, name);

  SimpleFormalParameterImpl simpleFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required SimpleIdentifier? identifier}) =>
      SimpleFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          identifier as SimpleIdentifierImpl?);

  SimpleIdentifierImpl simpleIdentifier(Token token,
      {bool isDeclaration = false}) {
    if (isDeclaration) {
      return DeclaredSimpleIdentifier(token);
    }
    return SimpleIdentifierImpl(token);
  }

  SimpleStringLiteralImpl simpleStringLiteral(Token literal, String value) =>
      SimpleStringLiteralImpl(literal, value);

  SpreadElementImpl spreadElement(
          {required Token spreadOperator, required Expression expression}) =>
      SpreadElementImpl(spreadOperator, expression as ExpressionImpl);

  StringInterpolationImpl stringInterpolation(
          List<InterpolationElement> elements) =>
      StringInterpolationImpl(elements);

  SuperConstructorInvocationImpl superConstructorInvocation(
          Token superKeyword,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList argumentList) =>
      SuperConstructorInvocationImpl(
          superKeyword,
          period,
          constructorName as SimpleIdentifierImpl?,
          argumentList as ArgumentListImpl);

  SuperExpressionImpl superExpression(Token superKeyword) =>
      SuperExpressionImpl(superKeyword);

  SuperFormalParameterImpl superFormalParameter(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required Token superKeyword,
          required Token period,
          required SimpleIdentifier identifier,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          Token? question}) =>
      SuperFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          superKeyword,
          period,
          identifier as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?,
          question);

  SwitchCaseImpl switchCase(List<Label> labels, Token keyword,
          Expression expression, Token colon, List<Statement> statements) =>
      SwitchCaseImpl(
          labels, keyword, expression as ExpressionImpl, colon, statements);

  SwitchDefaultImpl switchDefault(List<Label> labels, Token keyword,
          Token colon, List<Statement> statements) =>
      SwitchDefaultImpl(labels, keyword, colon, statements);

  SwitchStatementImpl switchStatement(
          Token switchKeyword,
          Token leftParenthesis,
          Expression expression,
          Token rightParenthesis,
          Token leftBracket,
          List<SwitchMember> members,
          Token rightBracket) =>
      SwitchStatementImpl(
          switchKeyword,
          leftParenthesis,
          expression as ExpressionImpl,
          rightParenthesis,
          leftBracket,
          members,
          rightBracket);

  SymbolLiteralImpl symbolLiteral(Token poundSign, List<Token> components) =>
      SymbolLiteralImpl(poundSign, components);

  ThisExpressionImpl thisExpression(Token thisKeyword) =>
      ThisExpressionImpl(thisKeyword);

  ThrowExpressionImpl throwExpression(
          Token throwKeyword, Expression expression) =>
      ThrowExpressionImpl(throwKeyword, expression as ExpressionImpl);

  TopLevelVariableDeclarationImpl topLevelVariableDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          VariableDeclarationList variableList,
          Token semicolon,
          {Token? externalKeyword}) =>
      TopLevelVariableDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          externalKeyword,
          variableList as VariableDeclarationListImpl,
          semicolon);

  TryStatementImpl tryStatement(
          Token tryKeyword,
          Block body,
          List<CatchClause> catchClauses,
          Token? finallyKeyword,
          Block? finallyBlock) =>
      TryStatementImpl(tryKeyword, body as BlockImpl, catchClauses,
          finallyKeyword, finallyBlock as BlockImpl?);

  TypeArgumentListImpl typeArgumentList(Token leftBracket,
          List<TypeAnnotation> arguments, Token rightBracket) =>
      TypeArgumentListImpl(leftBracket, arguments, rightBracket);

  TypeLiteralImpl typeLiteral({required NamedType typeName}) =>
      TypeLiteralImpl(typeName as NamedTypeImpl);

  TypeParameterImpl typeParameter(
          Comment? comment,
          List<Annotation>? metadata,
          SimpleIdentifier name,
          Token? extendsKeyword,
          TypeAnnotation? bound) =>
      TypeParameterImpl(
          comment as CommentImpl?,
          metadata,
          name as SimpleIdentifierImpl,
          extendsKeyword,
          bound as TypeAnnotationImpl?);

  TypeParameterImpl typeParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          required SimpleIdentifier name,
          Token? extendsKeyword,
          TypeAnnotation? bound,
          Token? varianceKeyword}) =>
      TypeParameterImpl(
          comment as CommentImpl?,
          metadata,
          name as SimpleIdentifierImpl,
          extendsKeyword,
          bound as TypeAnnotationImpl?)
        ..varianceKeyword = varianceKeyword;

  TypeParameterListImpl typeParameterList(Token leftBracket,
          List<TypeParameter> typeParameters, Token rightBracket) =>
      TypeParameterListImpl(leftBracket, typeParameters, rightBracket);

  VariableDeclarationImpl variableDeclaration(
          SimpleIdentifier name, Token? equals, Expression? initializer) =>
      VariableDeclarationImpl(
          name as SimpleIdentifierImpl, equals, initializer as ExpressionImpl?);

  VariableDeclarationListImpl variableDeclarationList(
          Comment? comment,
          List<Annotation>? metadata,
          Token? keyword,
          TypeAnnotation? type,
          List<VariableDeclaration> variables) =>
      VariableDeclarationListImpl(comment as CommentImpl?, metadata, null,
          keyword, type as TypeAnnotationImpl?, variables);

  VariableDeclarationListImpl variableDeclarationList2(
      {Comment? comment,
      List<Annotation>? metadata,
      Token? lateKeyword,
      Token? keyword,
      TypeAnnotation? type,
      required List<VariableDeclaration> variables}) {
    return VariableDeclarationListImpl(comment as CommentImpl?, metadata,
        lateKeyword, keyword, type as TypeAnnotationImpl?, variables);
  }

  VariableDeclarationStatementImpl variableDeclarationStatement(
          VariableDeclarationList variableList, Token semicolon) =>
      VariableDeclarationStatementImpl(
          variableList as VariableDeclarationListImpl, semicolon);

  WhileStatementImpl whileStatement(Token whileKeyword, Token leftParenthesis,
          Expression condition, Token rightParenthesis, Statement body) =>
      WhileStatementImpl(whileKeyword, leftParenthesis,
          condition as ExpressionImpl, rightParenthesis, body as StatementImpl);

  WithClauseImpl withClause(Token withKeyword, List<NamedType> mixinTypes) =>
      WithClauseImpl(withKeyword, mixinTypes);

  YieldStatementImpl yieldStatement(Token yieldKeyword, Token? star,
          Expression expression, Token semicolon) =>
      YieldStatementImpl(
          yieldKeyword, star, expression as ExpressionImpl, semicolon);
}
