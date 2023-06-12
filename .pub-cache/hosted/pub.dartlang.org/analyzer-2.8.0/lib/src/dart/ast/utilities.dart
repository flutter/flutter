// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

export 'package:analyzer/src/dart/ast/constant_evaluator.dart';

/// A function used to handle exceptions that are thrown by delegates while
/// using an [ExceptionHandlingDelegatingAstVisitor].
typedef ExceptionInDelegateHandler = void Function(
    AstNode node, AstVisitor visitor, dynamic exception, StackTrace stackTrace);

/// An AstVisitor that compares the structure of two AstNodes to see whether
/// they are equal.
class AstComparator implements AstVisitor<bool> {
  /// The AST node with which the node being visited is to be compared. This is
  /// only valid at the beginning of each visit method (until [isEqualNodes] is
  /// invoked).
  AstNode? _other;

  /// Notify that [first] and second have different length.
  /// This implementation returns `false`. Subclasses can override and throw.
  bool failDifferentLength(List first, List second) {
    return false;
  }

  /// Check whether the values of the [first] and [second] nodes are [equal].
  /// Subclasses can override to throw.
  bool failIfNotEqual(
      AstNode first, Object? firstValue, AstNode second, Object? secondValue) {
    return firstValue == secondValue;
  }

  /// Check whether [second] is null. Subclasses can override to throw.
  bool failIfNotNull(Object? first, Object? second) {
    return second == null;
  }

  /// Notify that [first] is not `null` while [second] one is `null`.
  /// This implementation returns `false`. Subclasses can override and throw.
  bool failIsNull(Object first, Object? second) {
    return false;
  }

  /// Notify that [first] and [second] have different types.
  /// This implementation returns `false`. Subclasses can override and throw.
  bool failRuntimeType(Object first, Object second) {
    return false;
  }

  /// Return `true` if the [first] node and the [second] node have the same
  /// structure.
  ///
  /// *Note:* This method is only visible for testing purposes and should not be
  /// used by clients.
  bool isEqualNodes(AstNode? first, AstNode? second) {
    if (first == null) {
      return failIfNotNull(first, second);
    } else if (second == null) {
      return failIsNull(first, second);
    } else if (first.runtimeType != second.runtimeType) {
      return failRuntimeType(first, second);
    }
    _other = second;
    return first.accept(this)!;
  }

  /// Return `true` if the [first] token and the [second] token have the same
  /// structure.
  ///
  /// *Note:* This method is only visible for testing purposes and should not be
  /// used by clients.
  bool isEqualTokens(Token? first, Token? second) {
    if (first == null) {
      return failIfNotNull(first, second);
    } else if (second == null) {
      return failIsNull(first, second);
    } else if (identical(first, second)) {
      return true;
    }
    return isEqualTokensNotNull(first, second);
  }

  /// Return `true` if the [first] token and the [second] token have the same
  /// structure.  Both [first] and [second] are not `null`.
  bool isEqualTokensNotNull(Token first, Token second) =>
      first.offset == second.offset &&
      first.length == second.length &&
      first.lexeme == second.lexeme;

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings other = _other as AdjacentStrings;
    return _isEqualNodeLists(node.strings, other.strings);
  }

  @override
  bool visitAnnotation(Annotation node) {
    Annotation other = _other as Annotation;
    return isEqualTokens(node.atSign, other.atSign) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.arguments, other.arguments);
  }

  @override
  bool visitArgumentList(ArgumentList node) {
    ArgumentList other = _other as ArgumentList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        _isEqualNodeLists(node.arguments, other.arguments) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitAsExpression(AsExpression node) {
    AsExpression other = _other as AsExpression;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.asOperator, other.asOperator) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitAssertInitializer(AssertInitializer node) {
    AssertInitializer other = _other as AssertInitializer;
    return isEqualTokens(node.assertKeyword, other.assertKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.comma, other.comma) &&
        isEqualNodes(node.message, other.message) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitAssertStatement(AssertStatement node) {
    AssertStatement other = _other as AssertStatement;
    return isEqualTokens(node.assertKeyword, other.assertKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.comma, other.comma) &&
        isEqualNodes(node.message, other.message) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression other = _other as AssignmentExpression;
    return isEqualNodes(node.leftHandSide, other.leftHandSide) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.rightHandSide, other.rightHandSide);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    AwaitExpression other = _other as AwaitExpression;
    return isEqualTokens(node.awaitKeyword, other.awaitKeyword) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    BinaryExpression other = _other as BinaryExpression;
    return isEqualNodes(node.leftOperand, other.leftOperand) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.rightOperand, other.rightOperand);
  }

  @override
  bool visitBlock(Block node) {
    Block other = _other as Block;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.statements, other.statements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody other = _other as BlockFunctionBody;
    return isEqualNodes(node.block, other.block);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral other = _other as BooleanLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitBreakStatement(BreakStatement node) {
    BreakStatement other = _other as BreakStatement;
    return isEqualTokens(node.breakKeyword, other.breakKeyword) &&
        isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    CascadeExpression other = _other as CascadeExpression;
    return isEqualNodes(node.target, other.target) &&
        _isEqualNodeLists(node.cascadeSections, other.cascadeSections);
  }

  @override
  bool visitCatchClause(CatchClause node) {
    CatchClause other = _other as CatchClause;
    return isEqualTokens(node.onKeyword, other.onKeyword) &&
        isEqualNodes(node.exceptionType, other.exceptionType) &&
        isEqualTokens(node.catchKeyword, other.catchKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.exceptionParameter, other.exceptionParameter) &&
        isEqualTokens(node.comma, other.comma) &&
        isEqualNodes(node.stackTraceParameter, other.stackTraceParameter) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration other = _other as ClassDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualTokens(node.classKeyword, other.classKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.extendsClause, other.extendsClause) &&
        isEqualNodes(node.withClause, other.withClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias other = _other as ClassTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualNodes(node.superclass2, other.superclass2) &&
        isEqualNodes(node.withClause, other.withClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitComment(Comment node) {
    Comment other = _other as Comment;
    return _isEqualNodeLists(node.references, other.references);
  }

  @override
  bool visitCommentReference(CommentReference node) {
    CommentReference other = _other as CommentReference;
    return isEqualTokens(node.newKeyword, other.newKeyword) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit other = _other as CompilationUnit;
    return isEqualTokens(node.beginToken, other.beginToken) &&
        isEqualNodes(node.scriptTag, other.scriptTag) &&
        _isEqualNodeLists(node.directives, other.directives) &&
        _isEqualNodeLists(node.declarations, other.declarations) &&
        isEqualTokens(node.endToken, other.endToken);
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression other = _other as ConditionalExpression;
    return isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.question, other.question) &&
        isEqualNodes(node.thenExpression, other.thenExpression) &&
        isEqualTokens(node.colon, other.colon) &&
        isEqualNodes(node.elseExpression, other.elseExpression);
  }

  @override
  bool visitConfiguration(Configuration node) {
    Configuration other = _other as Configuration;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.equalToken, other.equalToken) &&
        isEqualNodes(node.value, other.value) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.uri, other.uri);
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration other = _other as ConstructorDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualTokens(node.factoryKeyword, other.factoryKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.separator, other.separator) &&
        _isEqualNodeLists(node.initializers, other.initializers) &&
        isEqualNodes(node.redirectedConstructor, other.redirectedConstructor) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer other = _other as ConstructorFieldInitializer;
    return isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.fieldName, other.fieldName) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitConstructorName(ConstructorName node) {
    ConstructorName other = _other as ConstructorName;
    return isEqualNodes(node.type2, other.type2) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitConstructorReference(ConstructorReference node) {
    ConstructorReference other = _other as ConstructorReference;
    return isEqualNodes(node.constructorName, other.constructorName);
  }

  @override
  bool visitContinueStatement(ContinueStatement node) {
    ContinueStatement other = _other as ContinueStatement;
    return isEqualTokens(node.continueKeyword, other.continueKeyword) &&
        isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier other = _other as DeclaredIdentifier;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var other = _other as DefaultFormalParameterImpl;
    return isEqualNodes(node.parameter, other.parameter) &&
        node.kind == other.kind &&
        isEqualTokens(node.separator, other.separator) &&
        isEqualNodes(node.defaultValue, other.defaultValue);
  }

  @override
  bool visitDoStatement(DoStatement node) {
    DoStatement other = _other as DoStatement;
    return isEqualTokens(node.doKeyword, other.doKeyword) &&
        isEqualNodes(node.body, other.body) &&
        isEqualTokens(node.whileKeyword, other.whileKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitDottedName(DottedName node) {
    DottedName other = _other as DottedName;
    return _isEqualNodeLists(node.components, other.components);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral other = _other as DoubleLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody other = _other as EmptyFunctionBody;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement other = _other as EmptyStatement;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration other = _other as EnumConstantDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration other = _other as EnumDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.enumKeyword, other.enumKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.constants, other.constants) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitExportDirective(ExportDirective node) {
    ExportDirective other = _other as ExportDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.uri, other.uri) &&
        _isEqualNodeLists(node.combinators, other.combinators) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody other = _other as ExpressionFunctionBody;
    return isEqualTokens(node.functionDefinition, other.functionDefinition) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement other = _other as ExpressionStatement;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause other = _other as ExtendsClause;
    return isEqualTokens(node.extendsKeyword, other.extendsKeyword) &&
        isEqualNodes(node.superclass2, other.superclass2);
  }

  @override
  bool visitExtensionDeclaration(ExtensionDeclaration node) {
    ExtensionDeclaration other = _other as ExtensionDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.extensionKeyword, other.extensionKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.onKeyword, other.onKeyword) &&
        isEqualNodes(node.extendedType, other.extendedType) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitExtensionOverride(ExtensionOverride node) {
    ExtensionOverride other = _other as ExtensionOverride;
    return isEqualNodes(node.extensionName, other.extensionName) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = _other as FieldDeclaration;
    return isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualTokens(node.covariantKeyword, other.covariantKeyword) &&
        isEqualNodes(node.documentationComment, other.documentationComment) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.staticKeyword, other.staticKeyword) &&
        isEqualNodes(node.fields, other.fields) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter other = _other as FieldFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    ForEachPartsWithDeclaration other = _other as ForEachPartsWithDeclaration;
    return isEqualNodes(node.loopVariable, other.loopVariable) &&
        isEqualTokens(node.inKeyword, other.inKeyword) &&
        isEqualNodes(node.iterable, other.iterable);
  }

  @override
  bool visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    ForEachPartsWithIdentifier other = _other as ForEachPartsWithIdentifier;
    return isEqualNodes(node.identifier, other.identifier) &&
        isEqualTokens(node.inKeyword, other.inKeyword) &&
        isEqualNodes(node.iterable, other.iterable);
  }

  @override
  bool visitForElement(ForElement node) {
    ForElement other = _other as ForElement;
    return isEqualTokens(node.awaitKeyword, other.awaitKeyword) &&
        isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.forLoopParts, other.forLoopParts) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList other = _other as FormalParameterList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        _isEqualNodeLists(node.parameters, other.parameters) &&
        isEqualTokens(node.leftDelimiter, other.leftDelimiter) &&
        isEqualTokens(node.rightDelimiter, other.rightDelimiter) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    ForPartsWithDeclarations other = _other as ForPartsWithDeclarations;
    return isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.leftSeparator, other.leftSeparator) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightSeparator, other.rightSeparator) &&
        _isEqualNodeLists(node.updaters, other.updaters);
  }

  @override
  bool visitForPartsWithExpression(ForPartsWithExpression node) {
    ForPartsWithExpression other = _other as ForPartsWithExpression;
    return isEqualNodes(node.initialization, other.initialization) &&
        isEqualTokens(node.leftSeparator, other.leftSeparator) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightSeparator, other.rightSeparator) &&
        _isEqualNodeLists(node.updaters, other.updaters);
  }

  @override
  bool visitForStatement(ForStatement node) {
    ForStatement other = _other as ForStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.awaitKeyword, other.awaitKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.forLoopParts, other.forLoopParts) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration other = _other as FunctionDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.functionExpression, other.functionExpression);
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement other = _other as FunctionDeclarationStatement;
    return isEqualNodes(node.functionDeclaration, other.functionDeclaration);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpression other = _other as FunctionExpression;
    return isEqualNodes(node.parameters, other.parameters) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation other = _other as FunctionExpressionInvocation;
    return isEqualNodes(node.function, other.function) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitFunctionReference(FunctionReference node) {
    FunctionReference other = _other as FunctionReference;
    return isEqualNodes(node.function, other.function) &&
        isEqualNodes(node.typeArguments, other.typeArguments);
  }

  @override
  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias other = _other as FunctionTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter other = _other as FunctionTypedFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualNodes(node.identifier, other.identifier) &&
        isEqualNodes(node.parameters, other.parameters);
  }

  @override
  bool visitGenericFunctionType(GenericFunctionType node) {
    GenericFunctionType other = _other as GenericFunctionType;
    return isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.functionKeyword, other.functionKeyword) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.question, other.question);
  }

  @override
  bool visitGenericTypeAlias(GenericTypeAlias node) {
    GenericTypeAlias other = _other as GenericTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitHideClause(HideClause node) {
    HideClause other = _other as HideClause;
    return isEqualTokens(node.hideKeyword, other.hideKeyword) &&
        _isEqualNodeLists(node.elements, other.elements);
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    HideCombinator other = _other as HideCombinator;
    return isEqualTokens(node.keyword, other.keyword) &&
        _isEqualNodeLists(node.hiddenNames, other.hiddenNames);
  }

  @override
  bool visitIfElement(IfElement node) {
    IfElement other = _other as IfElement;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.thenElement, other.thenElement) &&
        isEqualTokens(node.elseKeyword, other.elseKeyword) &&
        isEqualNodes(node.elseElement, other.elseElement);
  }

  @override
  bool visitIfStatement(IfStatement node) {
    IfStatement other = _other as IfStatement;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.thenStatement, other.thenStatement) &&
        isEqualTokens(node.elseKeyword, other.elseKeyword) &&
        isEqualNodes(node.elseStatement, other.elseStatement);
  }

  @override
  bool visitImplementsClause(ImplementsClause node) {
    ImplementsClause other = _other as ImplementsClause;
    return isEqualTokens(node.implementsKeyword, other.implementsKeyword) &&
        _isEqualNodeLists(node.interfaces2, other.interfaces2);
  }

  @override
  bool visitImplicitCallReference(ImplicitCallReference node) {
    ImplicitCallReference other = _other as ImplicitCallReference;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualNodes(node.typeArguments, other.typeArguments);
  }

  @override
  bool visitImportDirective(ImportDirective node) {
    ImportDirective other = _other as ImportDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.uri, other.uri) &&
        _isEqualNodeLists(node.configurations, other.configurations) &&
        isEqualTokens(node.deferredKeyword, other.deferredKeyword) &&
        isEqualTokens(node.asKeyword, other.asKeyword) &&
        isEqualNodes(node.prefix, other.prefix) &&
        _isEqualNodeLists(node.combinators, other.combinators) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    IndexExpression other = _other as IndexExpression;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        isEqualNodes(node.index, other.index) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression other = _other as InstanceCreationExpression;
    return isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral other = _other as IntegerLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression other = _other as InterpolationExpression;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitInterpolationString(InterpolationString node) {
    InterpolationString other = _other as InterpolationString;
    return isEqualTokens(node.contents, other.contents) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitIsExpression(IsExpression node) {
    IsExpression other = _other as IsExpression;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.isOperator, other.isOperator) &&
        isEqualTokens(node.notOperator, other.notOperator) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitLabel(Label node) {
    Label other = _other as Label;
    return isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.colon, other.colon);
  }

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement other = _other as LabeledStatement;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualNodes(node.statement, other.statement);
  }

  @override
  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective other = _other as LibraryDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.libraryKeyword, other.libraryKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier other = _other as LibraryIdentifier;
    return _isEqualNodeLists(node.components, other.components);
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    ListLiteral other = _other as ListLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.elements, other.elements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry other = _other as MapLiteralEntry;
    return isEqualNodes(node.key, other.key) &&
        isEqualTokens(node.separator, other.separator) &&
        isEqualNodes(node.value, other.value);
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration other = _other as MethodDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualTokens(node.modifierKeyword, other.modifierKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
        isEqualTokens(node.operatorKeyword, other.operatorKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    MethodInvocation other = _other as MethodInvocation;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.methodName, other.methodName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitMixinDeclaration(MixinDeclaration node) {
    MixinDeclaration other = _other as MixinDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.mixinKeyword, other.mixinKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.onClause, other.onClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitNamedExpression(NamedExpression node) {
    NamedExpression other = _other as NamedExpression;
    return isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool? visitNamedType(NamedType node) {
    NamedType other = _other as NamedType;
    return isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.question, other.question);
  }

  @override
  bool visitNativeClause(NativeClause node) {
    NativeClause other = _other as NativeClause;
    return isEqualTokens(node.nativeKeyword, other.nativeKeyword) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody other = _other as NativeFunctionBody;
    return isEqualTokens(node.nativeKeyword, other.nativeKeyword) &&
        isEqualNodes(node.stringLiteral, other.stringLiteral) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitNullLiteral(NullLiteral node) {
    NullLiteral other = _other as NullLiteral;
    return isEqualTokens(node.literal, other.literal);
  }

  @override
  bool visitOnClause(OnClause node) {
    OnClause other = _other as OnClause;
    return isEqualTokens(node.onKeyword, other.onKeyword) &&
        _isEqualNodeLists(
            node.superclassConstraints2, other.superclassConstraints2);
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression other = _other as ParenthesizedExpression;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitPartDirective(PartDirective node) {
    PartDirective other = _other as PartDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.partKeyword, other.partKeyword) &&
        isEqualNodes(node.uri, other.uri) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitPartOfDirective(PartOfDirective node) {
    PartOfDirective other = _other as PartOfDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.partKeyword, other.partKeyword) &&
        isEqualTokens(node.ofKeyword, other.ofKeyword) &&
        isEqualNodes(node.libraryName, other.libraryName) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    PostfixExpression other = _other as PostfixExpression;
    return isEqualNodes(node.operand, other.operand) &&
        isEqualTokens(node.operator, other.operator);
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier other = _other as PrefixedIdentifier;
    return isEqualNodes(node.prefix, other.prefix) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression other = _other as PrefixExpression;
    return isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.operand, other.operand);
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    PropertyAccess other = _other as PropertyAccess;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.propertyName, other.propertyName);
  }

  @override
  bool visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation other =
        _other as RedirectingConstructorInvocation;
    return isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) {
    RethrowExpression other = _other as RethrowExpression;
    return isEqualTokens(node.rethrowKeyword, other.rethrowKeyword);
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement other = _other as ReturnStatement;
    return isEqualTokens(node.returnKeyword, other.returnKeyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitScriptTag(ScriptTag node) {
    ScriptTag other = _other as ScriptTag;
    return isEqualTokens(node.scriptTag, other.scriptTag);
  }

  @override
  bool visitSetOrMapLiteral(SetOrMapLiteral node) {
    SetOrMapLiteral other = _other as SetOrMapLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.elements, other.elements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitShowClause(ShowClause node) {
    ShowClause other = _other as ShowClause;
    return isEqualTokens(node.showKeyword, other.showKeyword) &&
        _isEqualNodeLists(node.elements, other.elements);
  }

  @override
  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator other = _other as ShowCombinator;
    return isEqualTokens(node.keyword, other.keyword) &&
        _isEqualNodeLists(node.shownNames, other.shownNames);
  }

  @override
  bool visitShowHideElement(ShowHideElement node) {
    ShowHideElement other = _other as ShowHideElement;
    return isEqualTokens(node.modifier, other.modifier) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter other = _other as SimpleFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier other = _other as SimpleIdentifier;
    return isEqualTokens(node.token, other.token);
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral other = _other as SimpleStringLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitSpreadElement(SpreadElement node) {
    SpreadElement other = _other as SpreadElement;
    return isEqualTokens(node.spreadOperator, other.spreadOperator) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation other = _other as StringInterpolation;
    return _isEqualNodeLists(node.elements, other.elements);
  }

  @override
  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation other = _other as SuperConstructorInvocation;
    return isEqualTokens(node.superKeyword, other.superKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitSuperExpression(SuperExpression node) {
    SuperExpression other = _other as SuperExpression;
    return isEqualTokens(node.superKeyword, other.superKeyword);
  }

  @override
  bool visitSuperFormalParameter(SuperFormalParameter node) {
    SuperFormalParameter other = _other as SuperFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualTokens(node.superKeyword, other.superKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitSwitchCase(SwitchCase node) {
    SwitchCase other = _other as SwitchCase;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.colon, other.colon) &&
        _isEqualNodeLists(node.statements, other.statements);
  }

  @override
  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault other = _other as SwitchDefault;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualTokens(node.colon, other.colon) &&
        _isEqualNodeLists(node.statements, other.statements);
  }

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement other = _other as SwitchStatement;
    return isEqualTokens(node.switchKeyword, other.switchKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral other = _other as SymbolLiteral;
    return isEqualTokens(node.poundSign, other.poundSign) &&
        _isEqualTokenLists(node.components, other.components);
  }

  @override
  bool visitThisExpression(ThisExpression node) {
    ThisExpression other = _other as ThisExpression;
    return isEqualTokens(node.thisKeyword, other.thisKeyword);
  }

  @override
  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression other = _other as ThrowExpression;
    return isEqualTokens(node.throwKeyword, other.throwKeyword) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration other = _other as TopLevelVariableDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitTryStatement(TryStatement node) {
    TryStatement other = _other as TryStatement;
    return isEqualTokens(node.tryKeyword, other.tryKeyword) &&
        isEqualNodes(node.body, other.body) &&
        _isEqualNodeLists(node.catchClauses, other.catchClauses) &&
        isEqualTokens(node.finallyKeyword, other.finallyKeyword) &&
        isEqualNodes(node.finallyBlock, other.finallyBlock);
  }

  @override
  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList other = _other as TypeArgumentList;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.arguments, other.arguments) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitTypeLiteral(TypeLiteral node) {
    TypeLiteral other = _other as TypeLiteral;
    return isEqualNodes(node.type, other.type);
  }

  @Deprecated('Override visitNamedType instead')
  @override
  bool visitTypeName(TypeName node) {
    throw StateError('Should not be invoked');
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    TypeParameter other = _other as TypeParameter;
    // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
    // added to the interface.
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens((node as TypeParameterImpl).varianceKeyword,
            (other as TypeParameterImpl).varianceKeyword) &&
        isEqualTokens(node.extendsKeyword, other.extendsKeyword) &&
        isEqualNodes(node.bound, other.bound);
  }

  @override
  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList other = _other as TypeParameterList;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration other = _other as VariableDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.initializer, other.initializer);
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList other = _other as VariableDeclarationList;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        _isEqualNodeLists(node.variables, other.variables);
  }

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement other = _other as VariableDeclarationStatement;
    return isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    WhileStatement other = _other as WhileStatement;
    return isEqualTokens(node.whileKeyword, other.whileKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitWithClause(WithClause node) {
    WithClause other = _other as WithClause;
    return isEqualTokens(node.withKeyword, other.withKeyword) &&
        _isEqualNodeLists(node.mixinTypes2, other.mixinTypes2);
  }

  @override
  bool visitYieldStatement(YieldStatement node) {
    YieldStatement other = _other as YieldStatement;
    return isEqualTokens(node.yieldKeyword, other.yieldKeyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  /// Return `true` if the [first] and [second] lists of AST nodes have the same
  /// size and corresponding elements are equal.
  bool _isEqualNodeLists(NodeList? first, NodeList? second) {
    if (first == null) {
      return failIfNotNull(first, second);
    } else if (second == null) {
      return failIsNull(first, second);
    }
    int size = first.length;
    if (second.length != size) {
      return failDifferentLength(first, second);
    }
    for (int i = 0; i < size; i++) {
      if (!isEqualNodes(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  /// Return `true` if the [first] and [second] lists of tokens have the same
  /// length and corresponding elements are equal.
  bool _isEqualTokenLists(List<Token> first, List<Token> second) {
    int length = first.length;
    if (second.length != length) {
      return failDifferentLength(first, second);
    }
    for (int i = 0; i < length; i++) {
      if (!isEqualTokens(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  /// Return `true` if the [first] and [second] nodes are equal.
  static bool equalNodes(AstNode first, AstNode second) {
    AstComparator comparator = AstComparator();
    return comparator.isEqualNodes(first, second);
  }
}

/// A recursive AST visitor that is used to run over [Expression]s to determine
/// whether the expression is composed by at least one deferred
/// [PrefixedIdentifier].
///
/// See [PrefixedIdentifier.isDeferred].
class DeferredLibraryReferenceDetector extends RecursiveAstVisitor<void> {
  /// A flag indicating whether an identifier from a deferred library has been
  /// found.
  bool _result = false;

  /// Return `true` if the visitor found a [PrefixedIdentifier] that returned
  /// `true` to the [PrefixedIdentifier.isDeferred] query.
  bool get result => _result;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!_result) {
      if (node.isDeferred) {
        _result = true;
      }
    }
  }
}

/// Class capable of handling exceptions generated during linting.
///
/// Clients may not extend, implement or mix-in this class.
class LinterExceptionHandler {
  /// Indicates whether linter exceptions should be propagated to the caller (by
  /// re-throwing them)
  final bool propagateExceptions;

  LinterExceptionHandler({
    required this.propagateExceptions,
  });

  /// A method that can be passed to the `LinterVisitor` constructor to handle
  /// exceptions that occur during linting.
  void logException(
      AstNode node, Object visitor, dynamic exception, StackTrace stackTrace) {
    StringBuffer buffer = StringBuffer();
    buffer.write('Exception while using a ${visitor.runtimeType} to visit a ');
    AstNode? currentNode = node;
    bool first = true;
    while (currentNode != null) {
      if (first) {
        first = false;
      } else {
        buffer.write(' in ');
      }
      buffer.write(currentNode.runtimeType);
      currentNode = currentNode.parent;
    }
    // TODO(39284): should this exception be silent?
    AnalysisEngine.instance.instrumentationService.logException(
        SilentException(buffer.toString(), exception, stackTrace));
    if (propagateExceptions) {
      throw exception;
    }
  }
}

/// An object used to locate the [AstNode] associated with a source range, given
/// the AST structure built from the source. More specifically, they will return
/// the [AstNode] with the shortest length whose source range completely
/// encompasses the specified range.
class NodeLocator extends UnifyingAstVisitor<void> {
  /// The start offset of the range used to identify the node.
  final int _startOffset;

  /// The end offset of the range used to identify the node.
  final int _endOffset;

  /// The element that was found that corresponds to the given source range, or
  /// `null` if there is no such element.
  AstNode? _foundNode;

  /// Initialize a newly created locator to locate an [AstNode] by locating the
  /// node within an AST structure that corresponds to the given range of
  /// characters (between the [startOffset] and [endOffset] in the source.
  NodeLocator(int startOffset, [int? endOffset])
      : _startOffset = startOffset,
        _endOffset = endOffset ?? startOffset;

  /// Return the node that was found that corresponds to the given source range
  /// or `null` if there is no such node.
  AstNode? get foundNode => _foundNode;

  /// Search within the given AST [node] for an identifier representing an
  /// element in the specified source range. Return the element that was found,
  /// or `null` if no element was found.
  AstNode? searchWithin(AstNode? node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException(
              "Unable to locate element at offset ($_startOffset - $_endOffset)",
              exception,
              stackTrace));
      return null;
    }
    return _foundNode;
  }

  @override
  void visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return;
    }
    // Check whether the current node covers the selection.
    Token beginToken = node.beginToken;
    Token endToken = node.endToken;
    // Don't include synthetic tokens.
    while (endToken != beginToken) {
      // Fasta scanner reports unterminated string literal errors
      // and generates a synthetic string token with non-zero length.
      // Because of this, check for length > 0 rather than !isSynthetic.
      if (endToken.type == TokenType.EOF || endToken.length > 0) {
        break;
      }
      endToken = endToken.previous!;
    }
    int end = endToken.end;
    int start = node.offset;
    if (end < _startOffset || start > _endOffset) {
      return;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException("Exception caught while traversing an AST structure.",
              exception, stackTrace));
    }
    // Found a child.
    if (_foundNode != null) {
      return;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset <= end) {
      _foundNode = node;
    }
  }
}

/// An object used to locate the [AstNode] associated with a source range.
/// More specifically, they will return the deepest [AstNode] which completely
/// encompasses the specified range.
class NodeLocator2 extends UnifyingAstVisitor<void> {
  /// The inclusive start offset of the range used to identify the node.
  final int _startOffset;

  /// The inclusive end offset of the range used to identify the node.
  final int _endOffset;

  /// The found node or `null` if there is no such node.
  AstNode? _foundNode;

  /// Initialize a newly created locator to locate the deepest [AstNode] for
  /// which `node.offset <= [startOffset]` and `[endOffset] < node.end`.
  ///
  /// If [endOffset] is not provided, then it is considered the same as the
  /// given [startOffset].
  NodeLocator2(int startOffset, [int? endOffset])
      : _startOffset = startOffset,
        _endOffset = endOffset ?? startOffset;

  /// Search within the given AST [node] and return the node that was found,
  /// or `null` if no node was found.
  AstNode? searchWithin(AstNode? node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService
          .logException(SilentException(
              'Unable to locate element at offset '
              '($_startOffset - $_endOffset)',
              exception,
              stackTrace));
      return null;
    }
    return _foundNode;
  }

  @override
  void visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return;
    }
    // Check whether the current node covers the selection.
    Token beginToken = node.beginToken;
    Token endToken = node.endToken;
    // Don't include synthetic tokens.
    while (endToken != beginToken) {
      // Fasta scanner reports unterminated string literal errors
      // and generates a synthetic string token with non-zero length.
      // Because of this, check for length > 0 rather than !isSynthetic.
      if (endToken.type == TokenType.EOF || endToken.length > 0) {
        break;
      }
      endToken = endToken.previous!;
    }
    int end = endToken.end;
    int start = node.offset;
    if (end <= _startOffset || start > _endOffset) {
      return;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException("Exception caught while traversing an AST structure.",
              exception, stackTrace));
    }
    // Found a child.
    if (_foundNode != null) {
      return;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset < end) {
      _foundNode = node;
    }
  }
}

/// An object that will replace one child node in an AST node with another node.
class NodeReplacer implements AstVisitor<bool> {
  /// The node being replaced.
  final AstNode _oldNode;

  /// The node that is replacing the old node.
  final AstNode _newNode;

  /// Initialize a newly created node locator to replace the [_oldNode] with the
  /// [_newNode].
  NodeReplacer(this._oldNode, this._newNode);

  @override
  bool visitAdjacentStrings(covariant AdjacentStringsImpl node) {
    if (_replaceInList(node.strings)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitAnnotatedNode(covariant AnnotatedNodeImpl node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAnnotation(covariant AnnotationImpl node) {
    if (identical(node.arguments, _oldNode)) {
      node.arguments = _newNode as ArgumentList;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentList?;
      return true;
    } else if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as Identifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitArgumentList(covariant ArgumentListImpl node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAsExpression(covariant AsExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssertInitializer(covariant AssertInitializerImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    if (identical(node.message, _oldNode)) {
      node.message = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssertStatement(covariant AssertStatementImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    if (identical(node.message, _oldNode)) {
      node.message = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssignmentExpression(covariant AssignmentExpressionImpl node) {
    if (identical(node.leftHandSide, _oldNode)) {
      node.leftHandSide = _newNode as Expression;
      return true;
    } else if (identical(node.rightHandSide, _oldNode)) {
      node.rightHandSide = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAwaitExpression(covariant AwaitExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBinaryExpression(covariant BinaryExpressionImpl node) {
    if (identical(node.leftOperand, _oldNode)) {
      node.leftOperand = _newNode as Expression;
      return true;
    } else if (identical(node.rightOperand, _oldNode)) {
      node.rightOperand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlock(covariant BlockImpl node) {
    if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlockFunctionBody(covariant BlockFunctionBodyImpl node) {
    if (identical(node.block, _oldNode)) {
      node.block = _newNode as Block;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  @override
  bool visitBreakStatement(covariant BreakStatementImpl node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCascadeExpression(covariant CascadeExpressionImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.cascadeSections)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCatchClause(covariant CatchClauseImpl node) {
    if (identical(node.exceptionType, _oldNode)) {
      node.exceptionType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.exceptionParameter, _oldNode)) {
      node.exceptionParameter = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.stackTraceParameter, _oldNode)) {
      node.stackTraceParameter = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Block;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitClassDeclaration(covariant ClassDeclarationImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.extendsClause, _oldNode)) {
      node.extendsClause = _newNode as ExtendsClause;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClause;
      return true;
    } else if (identical(node.nativeClause, _oldNode)) {
      node.nativeClause = _newNode as NativeClause;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.superclass2, _oldNode)) {
      node.superclass = _newNode as NamedType;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClause;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitComment(covariant CommentImpl node) {
    if (_replaceInList(node.references)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCommentReference(covariant CommentReferenceImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Identifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCompilationUnit(covariant CompilationUnitImpl node) {
    if (identical(node.scriptTag, _oldNode)) {
      node.scriptTag = _newNode as ScriptTag;
      return true;
    } else if (_replaceInList(node.directives)) {
      return true;
    } else if (_replaceInList(node.declarations)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConditionalExpression(covariant ConditionalExpressionImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenExpression, _oldNode)) {
      node.thenExpression = _newNode as Expression;
      return true;
    } else if (identical(node.elseExpression, _oldNode)) {
      node.elseExpression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConfiguration(covariant ConfigurationImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as DottedName;
      return true;
    } else if (identical(node.value, _oldNode)) {
      node.value = _newNode as StringLiteral;
      return true;
    } else if (identical(node.uri, _oldNode)) {
      node.uri = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as Identifier;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.redirectedConstructor, _oldNode)) {
      node.redirectedConstructor = _newNode as ConstructorName;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    } else if (_replaceInList(node.initializers)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitConstructorFieldInitializer(
      covariant ConstructorFieldInitializerImpl node) {
    if (identical(node.fieldName, _oldNode)) {
      node.fieldName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorName(covariant ConstructorNameImpl node) {
    if (identical(node.type2, _oldNode)) {
      node.type = _newNode as NamedType;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorReference(covariant ConstructorReferenceImpl node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as ConstructorNameImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitContinueStatement(covariant ContinueStatementImpl node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDeclaredIdentifier(covariant DeclaredIdentifierImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    if (identical(node.parameter, _oldNode)) {
      node.parameter = _newNode as NormalFormalParameter;
      return true;
    } else if (identical(node.defaultValue, _oldNode)) {
      node.defaultValue = _newNode as Expression;
      var parameterElement = node.declaredElement;
      if (parameterElement is DefaultParameterElementImpl) {
        parameterElement.constantInitializer = _newNode as Expression;
      } else if (parameterElement is DefaultFieldFormalParameterElementImpl) {
        parameterElement.constantInitializer = _newNode as Expression;
      }
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoStatement(covariant DoStatementImpl node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDottedName(covariant DottedNameImpl node) {
    if (_replaceInList(node.components)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  @override
  bool visitEmptyStatement(EmptyStatement node) => visitNode(node);

  @override
  bool visitEnumConstantDeclaration(
      covariant EnumConstantDeclarationImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (_replaceInList(node.constants)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitExportDirective(covariant ExportDirectiveImpl node) =>
      visitNamespaceDirective(node);

  @override
  bool visitExpressionFunctionBody(covariant ExpressionFunctionBodyImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExpressionStatement(covariant ExpressionStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtendsClause(covariant ExtendsClauseImpl node) {
    if (identical(node.superclass2, _oldNode)) {
      node.superclass = _newNode as NamedType;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.extendedType, _oldNode)) {
      node.extendedType = _newNode as TypeAnnotation;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtensionOverride(ExtensionOverride node) {
    if (identical(node.extensionName, _oldNode)) {
      (node as ExtensionOverrideImpl).extensionName = _newNode as Identifier;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      (node as ExtensionOverrideImpl).typeArguments =
          _newNode as TypeArgumentList;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      (node as ExtensionOverrideImpl).argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    if (identical(node.fields, _oldNode)) {
      node.fields = _newNode as VariableDeclarationList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    if (identical(node.loopVariable, _oldNode)) {
      (node as ForEachPartsWithDeclarationImpl).loopVariable =
          _newNode as DeclaredIdentifier;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      (node as ForEachPartsWithDeclarationImpl).iterable =
          _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    if (identical(node.identifier, _oldNode)) {
      (node as ForEachPartsWithIdentifierImpl).identifier =
          _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      (node as ForEachPartsWithIdentifierImpl).iterable =
          _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForElement(ForElement node) {
    if (identical(node.forLoopParts, _oldNode)) {
      (node as ForElementImpl).forLoopParts = _newNode as ForLoopParts;
      return true;
    } else if (identical(node.body, _oldNode)) {
      (node as ForElementImpl).body = _newNode as CollectionElement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFormalParameterList(covariant FormalParameterListImpl node) {
    if (_replaceInList(node.parameters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForPartsWithDeclarations(
      covariant ForPartsWithDeclarationsImpl node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.updaters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForPartsWithExpression(covariant ForPartsWithExpressionImpl node) {
    if (identical(node.initialization, _oldNode)) {
      node.initialization = _newNode as Expression;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.updaters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForStatement(ForStatement node) {
    if (identical(node.forLoopParts, _oldNode)) {
      (node as ForStatementImpl).forLoopParts = _newNode as ForLoopParts;
      return true;
    } else if (identical(node.body, _oldNode)) {
      (node as ForStatementImpl).body = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.functionExpression, _oldNode)) {
      node.functionExpression = _newNode as FunctionExpression;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionDeclarationStatement(
      covariant FunctionDeclarationStatementImpl node) {
    if (identical(node.functionDeclaration, _oldNode)) {
      node.functionDeclaration = _newNode as FunctionDeclaration;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpression(covariant FunctionExpressionImpl node) {
    if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpressionInvocation(
      covariant FunctionExpressionInvocationImpl node) {
    if (identical(node.function, _oldNode)) {
      node.function = _newNode as Expression;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionReference(covariant FunctionReferenceImpl node) {
    if (identical(node.function, _oldNode)) {
      node.function = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionTypedFormalParameter(
      covariant FunctionTypedFormalParameterImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool? visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return null;
  }

  @override
  bool visitGenericTypeAlias(GenericTypeAlias node) {
    var nodeImpl = node as GenericTypeAliasImpl;
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      nodeImpl.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.type, _oldNode)) {
      nodeImpl.type = _newNode as TypeAnnotation;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitHideClause(covariant HideClauseImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitHideCombinator(covariant HideCombinatorImpl node) {
    if (_replaceInList(node.hiddenNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIfElement(IfElement node) {
    if (identical(node.condition, _oldNode)) {
      (node as IfElementImpl).condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenElement, _oldNode)) {
      (node as IfElementImpl).thenElement = _newNode as CollectionElement;
      return true;
    } else if (identical(node.elseElement, _oldNode)) {
      (node as IfElementImpl).elseElement = _newNode as CollectionElement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIfStatement(covariant IfStatementImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenStatement, _oldNode)) {
      node.thenStatement = _newNode as Statement;
      return true;
    } else if (identical(node.elseStatement, _oldNode)) {
      node.elseStatement = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImplementsClause(covariant ImplementsClauseImpl node) {
    if (_replaceInList(node.interfaces2)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImplicitCallReference(covariant ImplicitCallReferenceImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImportDirective(covariant ImportDirectiveImpl node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNamespaceDirective(node);
  }

  @override
  bool visitIndexExpression(covariant IndexExpressionImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.index, _oldNode)) {
      node.index = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInstanceCreationExpression(
      covariant InstanceCreationExpressionImpl node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as ConstructorName;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  @override
  bool visitInterpolationExpression(
      covariant InterpolationExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInterpolationString(InterpolationString node) => visitNode(node);

  @override
  bool visitIsExpression(covariant IsExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabel(covariant LabelImpl node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabeledStatement(covariant LabeledStatementImpl node) {
    if (identical(node.statement, _oldNode)) {
      node.statement = _newNode as Statement;
      return true;
    } else if (_replaceInList(node.labels)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLibraryDirective(covariant LibraryDirectiveImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as LibraryIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitLibraryIdentifier(covariant LibraryIdentifierImpl node) {
    if (_replaceInList(node.components)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitListLiteral(covariant ListLiteralImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitMapLiteralEntry(covariant MapLiteralEntryImpl node) {
    if (identical(node.key, _oldNode)) {
      node.key = _newNode as Expression;
      return true;
    } else if (identical(node.value, _oldNode)) {
      node.value = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitMethodInvocation(covariant MethodInvocationImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.methodName, _oldNode)) {
      node.methodName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.onClause, _oldNode)) {
      node.onClause = _newNode as OnClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClause;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNamedExpression(covariant NamedExpressionImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as Label;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitNamedType(covariant NamedTypeImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as Identifier;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentList;
      return true;
    }
    return visitNode(node);
  }

  bool visitNamespaceDirective(covariant NamespaceDirectiveImpl node) {
    if (_replaceInList(node.combinators)) {
      return true;
    }
    return visitUriBasedDirective(node);
  }

  @override
  bool visitNativeClause(covariant NativeClauseImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNativeFunctionBody(covariant NativeFunctionBodyImpl node) {
    if (identical(node.stringLiteral, _oldNode)) {
      node.stringLiteral = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  bool visitNode(AstNode node) {
    throw ArgumentError("The old node is not a child of it's parent");
  }

  bool visitNormalFormalParameter(covariant NormalFormalParameterImpl node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNullLiteral(NullLiteral node) => visitNode(node);

  @override
  bool visitOnClause(covariant OnClauseImpl node) {
    if (_replaceInList(node.superclassConstraints2)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitParenthesizedExpression(
      covariant ParenthesizedExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPartDirective(covariant PartDirectiveImpl node) =>
      visitUriBasedDirective(node);

  @override
  bool visitPartOfDirective(covariant PartOfDirectiveImpl node) {
    if (identical(node.libraryName, _oldNode)) {
      node.libraryName = _newNode as LibraryIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitPostfixExpression(covariant PostfixExpressionImpl node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixExpression(covariant PrefixExpressionImpl node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPropertyAccess(covariant PropertyAccessImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.propertyName, _oldNode)) {
      node.propertyName = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRedirectingConstructorInvocation(
      covariant RedirectingConstructorInvocationImpl node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) => visitNode(node);

  @override
  bool visitReturnStatement(covariant ReturnStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  bool visitSetOrMapLiteral(covariant SetOrMapLiteralImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitShowClause(covariant ShowClauseImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitShowCombinator(covariant ShowCombinatorImpl node) {
    if (_replaceInList(node.shownNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitShowHideElement(covariant ShowHideElementImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  @override
  bool visitSpreadElement(SpreadElement node) {
    if (identical(node.expression, _oldNode)) {
      (node as SpreadElementImpl).expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitStringInterpolation(covariant StringInterpolationImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperConstructorInvocation(
      covariant SuperConstructorInvocationImpl node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperExpression(covariant SuperExpressionImpl node) =>
      visitNode(node);

  @override
  bool visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitSwitchCase(covariant SwitchCaseImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitSwitchMember(node);
  }

  @override
  bool visitSwitchDefault(covariant SwitchDefaultImpl node) =>
      visitSwitchMember(node);

  bool visitSwitchMember(covariant SwitchMemberImpl node) {
    if (_replaceInList(node.labels)) {
      return true;
    } else if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSwitchStatement(covariant SwitchStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  @override
  bool visitThisExpression(ThisExpression node) => visitNode(node);

  @override
  bool visitThrowExpression(covariant ThrowExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTopLevelVariableDeclaration(
      covariant TopLevelVariableDeclarationImpl node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitTryStatement(covariant TryStatementImpl node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as Block;
      return true;
    } else if (identical(node.finallyBlock, _oldNode)) {
      node.finallyBlock = _newNode as Block;
      return true;
    } else if (_replaceInList(node.catchClauses)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeArgumentList(covariant TypeArgumentListImpl node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitTypedLiteral(covariant TypedLiteralImpl node) {
    if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeLiteral(covariant TypeLiteralImpl node) {
    if (identical(node.type, _oldNode)) {
      node.typeName = _newNode as NamedTypeImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeName(covariant NamedTypeImpl node) {
    throw StateError('Should not be invoked');
  }

  @override
  bool visitTypeParameter(covariant TypeParameterImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.bound, _oldNode)) {
      node.bound = _newNode as TypeAnnotation;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeParameterList(covariant TypeParameterListImpl node) {
    if (_replaceInList(node.typeParameters)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitUriBasedDirective(covariant UriBasedDirectiveImpl node) {
    if (identical(node.uri, _oldNode)) {
      node.uri = _newNode as StringLiteral;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.initializer, _oldNode)) {
      node.initializer = _newNode as Expression;
      return true;
      // TODO(srawlins) also replace node's declared element's
      // `constantInitializer`, if the element is [ConstFieldElementImpl],
      // [ConstLocalVariableElementImpl], or [ConstTopLevelVariableElementImpl].
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclarationList(
      covariant VariableDeclarationListImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    } else if (_replaceInList(node.variables)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclarationStatement(
      covariant VariableDeclarationStatementImpl node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWhileStatement(covariant WhileStatementImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWithClause(covariant WithClauseImpl node) {
    if (_replaceInList(node.mixinTypes2)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitYieldStatement(covariant YieldStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  bool _replaceInList(NodeList list) {
    int count = list.length;
    for (int i = 0; i < count; i++) {
      if (identical(_oldNode, list[i])) {
        list[i] = _newNode;
        return true;
      }
    }
    return false;
  }

  /// Replace the [oldNode] with the [newNode] in the AST structure containing
  /// the old node. Return `true` if the replacement was successful.
  ///
  /// Throws an [ArgumentError] if either node is `null`, if the old node does
  /// not have a parent node, or if the AST structure has been corrupted.
  ///
  /// If [newNode] is the parent of [oldNode] already (because [newNode] became
  /// the parent of [oldNode] in its constructor), this action will loop
  /// infinitely; pass [oldNode]'s previous parent as [parent] to avoid this.
  static bool replace(AstNode oldNode, AstNode newNode, {AstNode? parent}) {
    if (identical(oldNode, newNode)) {
      return true;
    }
    parent ??= oldNode.parent;
    if (parent == null) {
      throw ArgumentError("The old node is not a child of another node");
    }
    NodeReplacer replacer = NodeReplacer(oldNode, newNode);
    return parent.accept(replacer)!;
  }
}

/// Traverse the AST from initial child node to successive parents, building a
/// collection of local variable and parameter names visible to the initial
/// child node. In case of name shadowing, the first name seen is the most
/// specific one so names are not redefined.
///
/// Completion test code coverage is 95%. The two basic blocks that are not
/// executed cannot be executed. They are included for future reference.
class ScopedNameFinder extends GeneralizingAstVisitor<void> {
  Declaration? _declarationNode;

  AstNode? _immediateChild;

  final Map<String, SimpleIdentifier> _locals =
      HashMap<String, SimpleIdentifier>();

  final int _position;

  bool _referenceIsWithinLocalFunction = false;

  ScopedNameFinder(this._position);

  Declaration? get declaration => _declarationNode;

  Map<String, SimpleIdentifier> get locals => _locals;

  @override
  void visitBlock(Block node) {
    _checkStatements(node.statements);
    super.visitBlock(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _addToScope(node.exceptionParameter);
    _addToScope(node.stackTraceParameter);
    super.visitCatchClause(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _addToScope(node.loopVariable.identifier);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _addVariables(node.variables.variables);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! FunctionDeclarationStatement) {
      _declarationNode = node;
    } else {
      super.visitFunctionDeclaration(node);
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _referenceIsWithinLocalFunction = true;
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var parameters = node.parameters;
    if (parameters != null && !identical(_immediateChild, parameters)) {
      _addParameters(parameters.parameters);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _declarationNode = node;
    var parameters = node.parameters;
    if (parameters != null && !identical(_immediateChild, parameters)) {
      _addParameters(parameters.parameters);
    }
  }

  @override
  void visitNode(AstNode node) {
    _immediateChild = node;
    node.parent?.accept(this);
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    _checkStatements(node.statements);
    super.visitSwitchMember(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitTypeAlias(TypeAlias node) {
    _declarationNode = node;
  }

  void _addParameters(NodeList<FormalParameter> vars) {
    for (FormalParameter var2 in vars) {
      _addToScope(var2.identifier);
    }
  }

  void _addToScope(SimpleIdentifier? identifier) {
    if (identifier != null && _isInRange(identifier)) {
      String name = identifier.name;
      if (!_locals.containsKey(name)) {
        _locals[name] = identifier;
      }
    }
  }

  void _addVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      _addToScope(variable.name);
    }
  }

  /// Check the given list of [statements] for any that come before the
  /// immediate child and that define a name that would be visible to the
  /// immediate child.
  void _checkStatements(List<Statement> statements) {
    for (Statement statement in statements) {
      if (identical(statement, _immediateChild)) {
        return;
      }
      if (statement is VariableDeclarationStatement) {
        _addVariables(statement.variables.variables);
      } else if (statement is FunctionDeclarationStatement &&
          !_referenceIsWithinLocalFunction) {
        _addToScope(statement.functionDeclaration.name);
      }
    }
  }

  bool _isInRange(AstNode node) {
    if (_position < 0) {
      // if source position is not set then all nodes are in range
      return true;
      // not reached
    }
    return node.end < _position;
  }
}

/// A visitor used to write a source representation of a visited AST node (and
/// all of it's children) to a sink.
@Deprecated('Use ToSourceVisitor')
class ToSourceVisitor2 extends ToSourceVisitor {
  ToSourceVisitor2(StringSink sink) : super(sink);
}
