// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// Used in [ResolvedAstPrinter] to print lines of code that corresponding
/// to a subtree of AST. This help to make the bulky presentation of AST a
/// bit more understandable.
abstract class CodeLinesProvider {
  /// If the [offset] corresponds to a new, never requested before line,
  /// return this line, otherwise return `null`.
  String nextLine(int offset);
}

/// Prints AST as a tree, with properties and children.
class ResolvedAstPrinter extends ThrowingAstVisitor<void> {
  /// The URI of the library that contains the AST being printed.
  final String? _selfUriStr;

  /// The target sink to print AST.
  final StringSink _sink;

  /// The optional provider for code lines, might be `null`.
  final CodeLinesProvider? _codeLinesProvider;

  /// If `true`, types should be printed with nullability suffixes.
  final bool _withNullability;

  /// If `true`, selected tokens and nodes should be printed with offsets.
  final bool _withOffsets;

  String _indent = '';

  ResolvedAstPrinter({
    required String? selfUriStr,
    required StringSink sink,
    required String indent,
    CodeLinesProvider? codeLinesProvider,
    bool withNullability = false,
    bool withOffsets = false,
  })  : _selfUriStr = selfUriStr,
        _sink = sink,
        _codeLinesProvider = codeLinesProvider,
        _withNullability = withNullability,
        _withOffsets = withOffsets,
        _indent = indent;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _writeNextCodeLine(node);
    _writeln('AdjacentStrings');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('strings', node.strings);
      _addStringLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitAnnotation(Annotation node) {
    _writeNextCodeLine(node);
    _writeln('Annotation');
    _withIndent(() {
      _writeNode('arguments', node.arguments);
      _writeToken('atSign', node.atSign);
      _writeNode('constructorName', node.constructorName);
      _writeElement('element', node.element);
      _writeNode('name', node.name);
      _writeNode('typeArguments', node.typeArguments);
    });
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _writeNextCodeLine(node);
    _writeln('ArgumentList');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftParenthesis', node.leftParenthesis);
      properties.addNodeList('arguments', node.arguments);
      properties.addToken('rightParenthesis', node.rightParenthesis);
      _writeProperties(properties);
    });
  }

  @override
  void visitAsExpression(AsExpression node) {
    _writeNextCodeLine(node);
    _writeln('AsExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addToken('asOperator', node.asOperator);
      properties.addNode('type', node.type);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _writeNextCodeLine(node);
    _writeln('AssertInitializer');
    _withIndent(() {
      var properties = _Properties();
      _addAssertion(properties, node);
      _addConstructorInitializer(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _writeNextCodeLine(node);
    _writeln('AssertStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('semicolon', node.semicolon);
      _addAssertion(properties, node);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _writeNextCodeLine(node);
    _writeln('AssignmentExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('leftHandSide', node.leftHandSide);
      properties.addToken('operator', node.operator);
      properties.addNode('rightHandSide', node.rightHandSide);
      properties.addElement('readElement', node.readElement);
      properties.addType('readType', node.readType);
      properties.addElement('writeElement', node.writeElement);
      properties.addType('writeType', node.writeType);
      _addExpression(properties, node);
      _addMethodReferenceExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _writeNextCodeLine(node);
    _writeln('AwaitExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('awaitKeyword', node.awaitKeyword);
      properties.addNode('expression', node.expression);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _writeNextCodeLine(node);
    _writeln('BinaryExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('leftOperand', node.leftOperand);
      properties.addToken('operator', node.operator);
      properties.addNode('rightOperand', node.rightOperand);
      properties.addType('staticInvokeType', node.staticInvokeType);
      _addExpression(properties, node);
      _addMethodReferenceExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitBlock(Block node) {
    _writeNextCodeLine(node);
    _writeln('Block');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftBracket', node.leftBracket);
      properties.addToken('rightBracket', node.rightBracket);
      properties.addNodeList('statements', node.statements);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _writeNextCodeLine(node);
    _writeln('BlockFunctionBody');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('block', node.block);
      _addFunctionBody(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _writeNextCodeLine(node);
    _writeln('BooleanLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('literal', node.literal);
      _addLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _writeNextCodeLine(node);
    _writeln('BreakStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('breakKeyword', node.breakKeyword);
      properties.addNode('label', node.label);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _writeNextCodeLine(node);
    _writeln('CascadeExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('cascadeSections', node.cascadeSections);
      properties.addNode('target', node.target);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitCatchClause(CatchClause node) {
    _writeNextCodeLine(node);
    _writeln('CatchClause');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addToken('catchKeyword', node.catchKeyword);
      properties.addNode('exceptionParameter', node.exceptionParameter);
      properties.addNode('exceptionType', node.exceptionType);
      properties.addToken('onKeyword', node.onKeyword);
      properties.addNode('stackTraceParameter', node.stackTraceParameter);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('ClassDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('abstractKeyword', node.abstractKeyword);
      properties.addToken('classKeyword', node.classKeyword);
      properties.addNode('extendsClause', node.extendsClause);
      properties.addNode('nativeClause', node.nativeClause);
      properties.addNode('withClause', node.withClause);
      _addClassOrMixinDeclaration(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitComment(Comment node) {
    _writeNextCodeLine(node);
    _writeln('Comment');
    _withIndent(() {
      var properties = _Properties();
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _writeNextCodeLine(node);
    _writeln('CompilationUnit');
    _withIndent(() {
      _writeNode('scriptTag', node.scriptTag);
      _writeNodeList('directives', node.directives);
      _writeNodeList('declarations', node.declarations);
    });
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _writeNextCodeLine(node);
    _writeln('ConditionalExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('colon', node.colon);
      properties.addNode('condition', node.condition);
      properties.addNode('elseExpression', node.elseExpression);
      properties.addToken('question', node.question);
      properties.addNode('thenExpression', node.thenExpression);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('ConstructorDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addToken('constKeyword', node.constKeyword);
      properties.addToken('externalKeyword', node.externalKeyword);
      properties.addToken('factoryKeyword', node.factoryKeyword);
      properties.addNodeList('initializers', node.initializers);
      properties.addNode('name', node.name);
      properties.addNode('parameters', node.parameters);
      properties.addNode('redirectedConstructor', node.redirectedConstructor);
      properties.addNode('returnType', node.returnType);
      _addClassMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _writeNextCodeLine(node);
    _writeln('ConstructorFieldInitializer');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('equals', node.equals);
      properties.addNode('expression', node.expression);
      properties.addNode('fieldName', node.fieldName);
      properties.addToken('period', node.period);
      properties.addToken('thisKeyword', node.thisKeyword);
      _addConstructorInitializer(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _writeNextCodeLine(node);
    _writeln('ConstructorName');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('name', node.name);
      properties.addToken('period', node.period);
      properties.addElement('staticElement', node.staticElement);
      properties.addNode('type', node.type2);
      _writeProperties(properties);
    });
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _writeln('ConstructorReference');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('constructorName', node.constructorName);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _writeNextCodeLine(node);
    _writeln('ContinueStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('continueKeyword', node.continueKeyword);
      properties.addNode('label', node.label);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('DeclaredIdentifier');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('identifier', node.identifier);
      properties.addToken('keyword', node.keyword);
      properties.addNode('type', node.type);
      _addDeclaration(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('DefaultFormalParameter');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('defaultValue', node.defaultValue);
      properties.addNode('parameter', node.parameter);
      _addFormalParameter(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitDoStatement(DoStatement node) {
    _writeNextCodeLine(node);
    _writeln('DoStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addNode('condition', node.condition);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _writeNextCodeLine(node);
    _writeln('DoubleLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('literal', node.literal);
      _addLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _writeNextCodeLine(node);
    _writeln('EmptyFunctionBody');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('semicolon', node.semicolon);
      _addFunctionBody(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('EnumConstantDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('name', node.name);
      _addDeclaration(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('EnumDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('constants', node.constants);
      _addNamedCompilationUnitMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _writeNextCodeLine(node);
    _writeln('ExportDirective');
    _withIndent(() {
      var properties = _Properties();
      _addNamespaceDirective(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _writeNextCodeLine(node);
    _writeln('ExpressionFunctionBody');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addToken('functionDefinition', node.functionDefinition);
      properties.addToken('semicolon', node.semicolon);
      _addFunctionBody(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _writeNextCodeLine(node);
    _writeln('ExpressionStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addToken('semicolon', node.semicolon);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _writeNextCodeLine(node);
    _writeln('ExtendsClause');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('superclass', node.superclass2);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('FieldDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('abstractKeyword', node.abstractKeyword);
      properties.addToken('externalKeyword', node.externalKeyword);
      properties.addToken('covariantKeyword', node.covariantKeyword);
      properties.addNode('fields', node.fields);
      properties.addToken('semicolon', node.semicolon);
      properties.addToken('staticKeyword', node.staticKeyword);
      _addClassMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('FieldFormalParameter');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('keyword', node.keyword);
      properties.addNode('parameters', node.parameters);
      properties.addToken('thisKeyword', node.thisKeyword);
      properties.addNode('type', node.type);
      properties.addNode('typeParameters', node.typeParameters);
      _addNormalFormalParameter(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('ForEachPartsWithDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('loopVariable', node.loopVariable);
      _addForEachParts(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('ForEachPartsWithIdentifier');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('identifier', node.identifier);
      _addForEachParts(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _writeNextCodeLine(node);
    _writeln('FormalParameterList');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftParenthesis', node.leftParenthesis);
      properties.addToken('rightParenthesis', node.rightParenthesis);
      properties.addNodeList('parameters', node.parameters);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _writeNextCodeLine(node);
    _writeln('ForPartsWithDeclarations');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('variables', node.variables);
      _addForParts(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _writeNextCodeLine(node);
    _writeln('ForPartsWithExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('initialization', node.initialization);
      _addForParts(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitForStatement(ForStatement node) {
    _writeNextCodeLine(node);
    _writeln('ForStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addNode('forLoopParts', node.forLoopParts);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('FunctionDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addType('declaredElementType', node.declaredElement!.type);
      properties.addToken('externalKeyword', node.externalKeyword);
      properties.addNode('functionExpression', node.functionExpression);
      properties.addToken('propertyKeyword', node.propertyKeyword);
      properties.addNode('returnType', node.returnType);
      _addNamedCompilationUnitMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _writeNextCodeLine(node);
    _writeln('FunctionDeclarationStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('functionDeclaration', node.functionDeclaration);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _writeNextCodeLine(node);
    _writeln('FunctionExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addElement('declaredElement', node.declaredElement);
      properties.addNode('parameters', node.parameters);
      properties.addNode('typeParameters', node.typeParameters);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _writeNextCodeLine(node);
    _writeln('FunctionExpressionInvocation');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('function', node.function);
      properties.addElement('staticElement', node.staticElement);
      _addInvocationExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _writeln('FunctionReference');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('function', node.function);
      properties.addNode('typeArguments', node.typeArguments);
      properties.addTypeList('typeArgumentTypes', node.typeArgumentTypes);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _writeNextCodeLine(node);
    _writeln('FunctionTypeAlias');
    _withIndent(() {
      var properties = _Properties();
      properties.addElement('declaredElement', node.declaredElement);
      properties.addNode('parameters', node.parameters);
      properties.addNode('returnType', node.returnType);
      properties.addNode('typeParameters', node.typeParameters);
      _addTypeAlias(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('FunctionTypedFormalParameter');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('parameters', node.parameters);
      properties.addToken('question', node.question);
      properties.addNode('returnType', node.returnType);
      properties.addNode('typeParameters', node.typeParameters);
      _addNormalFormalParameter(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    _writeNextCodeLine(node);
    _writeln('GenericFunctionType');
    _withIndent(() {
      var properties = _Properties();
      properties.addGenericFunctionTypeElement(
        'declaredElement',
        node.declaredElement,
      );
      properties.addToken('functionKeyword', node.functionKeyword);
      properties.addNode('parameters', node.parameters);
      properties.addNode('returnType', node.returnType);
      properties.addNode('typeParameters', node.typeParameters);
      _addTypeAnnotation(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _writeNextCodeLine(node);
    _writeln('GenericTypeAlias');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('equals', node.equals);
      properties.addNode('functionType', node.functionType);
      properties.addNode('typeParameters', node.typeParameters);
      _addTypeAlias(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _writeNextCodeLine(node);
    _writeln('HideCombinator');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('hiddenNames', node.hiddenNames);
      _addCombinator(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitIfElement(IfElement node) {
    _writeln('IfElement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('condition', node.condition);
      properties.addNode('elseStatement', node.elseElement);
      properties.addNode('thenStatement', node.thenElement);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitIfStatement(IfStatement node) {
    _writeNextCodeLine(node);
    _writeln('IfStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('condition', node.condition);
      properties.addNode('elseStatement', node.elseStatement);
      properties.addNode('thenStatement', node.thenStatement);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _writeNextCodeLine(node);
    _writeln('ImplementsClause');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('implementsKeyword', node.implementsKeyword);
      properties.addNodeList('interfaces', node.interfaces2);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _writeNextCodeLine(node);
    _writeln('ImportDirective');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('prefix', node.prefix);
      _addNamespaceDirective(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _writeNextCodeLine(node);
    _writeln('IndexExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftBracket', node.leftBracket);
      properties.addNode('index', node.index);
      properties.addToken('period', node.period);
      properties.addToken('rightBracket', node.rightBracket);
      properties.addNode('target', node.target);
      _addExpression(properties, node);
      _addMethodReferenceExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _writeNextCodeLine(node);
    _writeln('InstanceCreationExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('argumentList', node.argumentList);
      properties.addNode('constructorName', node.constructorName);
      properties.addToken('keyword', node.keyword);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _writeNextCodeLine(node);
    _writeln('IntegerLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('literal', node.literal);
      _addLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _writeNextCodeLine(node);
    _writeln('InterpolationExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addToken('leftBracket', node.leftBracket);
      properties.addToken('rightBracket', node.rightBracket);
      _addInterpolationElement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _writeNextCodeLine(node);
    _writeln('InterpolationString');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('contents', node.contents);
      _addInterpolationElement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitIsExpression(IsExpression node) {
    _writeNextCodeLine(node);
    _writeln('IsExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addToken('isOperator', node.isOperator);
      properties.addNode('type', node.type);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitLabel(Label node) {
    _writeNextCodeLine(node);
    _writeln('Label');
    _withIndent(() {
      _writeNode('label', node.label);
    });
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _writeNextCodeLine(node);
    _writeln('LibraryDirective');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('name', node.name);
      _addDirective(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('LibraryIdentifier');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('components', node.components);
      _addIdentifier(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _writeNextCodeLine(node);
    _writeln('ListLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftBracket', node.leftBracket);
      properties.addNodeList('elements', node.elements);
      properties.addToken('rightBracket', node.rightBracket);
      _addTypedLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _writeNextCodeLine(node);
    _writeln('SetOrMapLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('key', node.key);
      properties.addNode('value', node.value);
      _addCollectionElement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('MethodDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addType('declaredElementType', node.declaredElement!.type);
      properties.addToken('externalKeyword', node.externalKeyword);
      properties.addToken('modifierKeyword', node.modifierKeyword);
      properties.addNode('name', node.name);
      properties.addToken('operatorKeyword', node.operatorKeyword);
      properties.addNode('parameters', node.parameters);
      properties.addToken('propertyKeyword', node.propertyKeyword);
      properties.addNode('returnType', node.returnType);
      properties.addNode('typeParameters', node.typeParameters);
      _addClassMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _writeNextCodeLine(node);
    _writeln('MethodInvocation');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('methodName', node.methodName);
      properties.addToken('operator', node.operator);
      properties.addNode('target', node.target);
      _addInvocationExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('MixinDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('mixinKeyword', node.mixinKeyword);
      properties.addNode('onClause', node.onClause);
      _addClassOrMixinDeclaration(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _writeNextCodeLine(node);
    _writeln('NamedExpression');
    _withIndent(() {
      _writeNode('name', node.name);
      _writeNode('expression', node.expression);
    });
  }

  @override
  void visitNamedType(NamedType node) {
    _writeNextCodeLine(node);
    _writeln('NamedType');
    _withIndent(() {
      _writeNode('name', node.name);
      _writeType('type', node.type);
      _writeNode('typeArguments', node.typeArguments);
    });
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _writeNextCodeLine(node);
    _writeln('NullLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('literal', node.literal);
      _addLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitOnClause(OnClause node) {
    _writeNextCodeLine(node);
    _writeln('OnClause');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('onKeyword', node.onKeyword);
      properties.addNodeList(
          'superclassConstraints', node.superclassConstraints2);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _writeNextCodeLine(node);
    _writeln('ParenthesizedExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftParenthesis', node.leftParenthesis);
      properties.addNode('expression', node.expression);
      properties.addToken('rightParenthesis', node.rightParenthesis);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitPartDirective(PartDirective node) {
    _writeNextCodeLine(node);
    _writeln('PartDirective');
    _withIndent(() {
      var properties = _Properties();
      _addUriBasedDirective(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _writeNextCodeLine(node);
    _writeln('PartOfDirective');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('libraryName', node.libraryName);
      properties.addToken('ofKeyword', node.ofKeyword);
      properties.addToken('partKeyword', node.partKeyword);
      properties.addToken('semicolon', node.semicolon);
      _addDirective(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _writeNextCodeLine(node);
    _writeln('PostfixExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('operand', node.operand);
      properties.addToken('operator', node.operator);
      if (node.operator.type.isIncrementOperator) {
        properties.addElement('readElement', node.readElement);
        properties.addType('readType', node.readType);
        properties.addElement('writeElement', node.writeElement);
        properties.addType('writeType', node.writeType);
      }
      _addExpression(properties, node);
      _addMethodReferenceExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('PrefixedIdentifier');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('identifier', node.identifier);
      properties.addToken('period', node.period);
      properties.addNode('prefix', node.prefix);
      _addIdentifier(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _writeNextCodeLine(node);
    _writeln('PrefixExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('operand', node.operand);
      properties.addToken('operator', node.operator);
      if (node.operator.type.isIncrementOperator) {
        properties.addElement('readElement', node.readElement);
        properties.addType('readType', node.readType);
        properties.addElement('writeElement', node.writeElement);
        properties.addType('writeType', node.writeType);
      }
      _addExpression(properties, node);
      _addMethodReferenceExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _writeNextCodeLine(node);
    _writeln('PropertyAccess');
    _withIndent(() {
      var properties = _Properties();
      _writeToken('operator', node.operator);
      properties.addNode('propertyName', node.propertyName);
      properties.addNode('target', node.target);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _writeNextCodeLine(node);
    _writeln('RedirectingConstructorInvocation');
    _withIndent(() {
      _writeNode('argumentList', node.argumentList);
      _writeNode('constructorName', node.constructorName);
      _writeToken('period', node.period);
      _writeElement('staticElement', node.staticElement);
      _writeToken('thisKeyword', node.thisKeyword);
    });
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _writeNextCodeLine(node);
    _writeln('ReturnStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addToken('returnKeyword', node.returnKeyword);
      properties.addToken('semicolon', node.semicolon);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _writeNextCodeLine(node);
    _writeln('SetOrMapLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('elements', node.elements);
      properties.addRaw('isMap', node.isMap);
      properties.addToken('leftBracket', node.leftBracket);
      properties.addToken('rightBracket', node.rightBracket);
      _addTypedLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _writeNextCodeLine(node);
    _writeln('ShowCombinator');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('shownNames', node.shownNames);
      _addCombinator(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('SimpleFormalParameter');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('keyword', node.keyword);
      properties.addNode('type', node.type);
      _addNormalFormalParameter(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('SimpleIdentifier');
    _withIndent(() {
      var properties = _Properties();
      properties.addElement('staticElement', node.staticElement);
      properties.addType('staticType', node.staticType);
      properties.addTypeList(
        'tearOffTypeArgumentTypes',
        node.tearOffTypeArgumentTypes,
      );
      properties.addToken('token', node.token);
      _writeProperties(properties);
    });
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writeNextCodeLine(node);
    _writeln('SimpleStringLiteral');
    _withIndent(() {
      _writeToken('literal', node.literal);
    });
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _writeln('SpreadElement');
    _withIndent(() {
      _writeNode('expression', node.expression);
      _writeToken('spreadOperator', node.spreadOperator);
    });
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _writeNextCodeLine(node);
    _writeln('StringInterpolation');
    _withIndent(() {
      var properties = _Properties();
      properties.addNodeList('elements', node.elements);
      _addSingleStringLiteral(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writeNextCodeLine(node);
    _writeln('SuperConstructorInvocation');
    _withIndent(() {
      _writeNode('argumentList', node.argumentList);
      _writeNode('constructorName', node.constructorName);
      _writeToken('period', node.period);
      _writeElement('staticElement', node.staticElement);
      _writeToken('superKeyword', node.superKeyword);
    });
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _writeNextCodeLine(node);
    _writeln('SuperExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('superKeyword', node.superKeyword);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _writeNextCodeLine(node);
    _writeln('SwitchCase');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      _addSwitchMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _writeNextCodeLine(node);
    _writeln('SwitchDefault');
    _withIndent(() {
      var properties = _Properties();
      _addSwitchMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _writeNextCodeLine(node);
    _writeln('SwitchStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addNodeList('members', node.members);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _writeln('SymbolLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('poundSign', node.poundSign);
      properties.addTokenList('components', node.components);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _writeNextCodeLine(node);
    _writeln('ThisExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('thisKeyword', node.thisKeyword);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _writeNextCodeLine(node);
    _writeln('ThrowExpression');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('TopLevelVariableDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('externalKeyword', node.externalKeyword);
      properties.addToken('semicolon', node.semicolon);
      properties.addNode('variables', node.variables);
      _addCompilationUnitMember(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitTryStatement(TryStatement node) {
    _writeNextCodeLine(node);
    _writeln('TryStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addNodeList('catchClauses', node.catchClauses);
      properties.addNode('finallyBlock', node.finallyBlock);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _writeNextCodeLine(node);
    _writeln('TypeArgumentList');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftBracket', node.leftBracket);
      properties.addNodeList('arguments', node.arguments);
      properties.addToken('rightBracket', node.rightBracket);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _writeln('TypeLiteral');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('type', node.type);
      _addExpression(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _writeNextCodeLine(node);
    _writeln('TypeParameter');
    _withIndent(() {
      var properties = _Properties();
      // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
      // added to the interface.
      if ((node as TypeParameterImpl).varianceKeyword != null) {
        properties.addToken('variance', node.varianceKeyword);
      }
      properties.addNode('bound', node.bound);
      properties.addNode('name', node.name);
      _addDeclaration(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _writeNextCodeLine(node);
    _writeln('TypeParameterList');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('leftBracket', node.leftBracket);
      properties.addNodeList('typeParameters', node.typeParameters);
      properties.addToken('rightBracket', node.rightBracket);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('VariableDeclaration');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('initializer', node.initializer);
      properties.addNode('name', node.name);
      _addDeclaration(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _writeNextCodeLine(node);
    _writeln('VariableDeclarationList');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('keyword', node.keyword);
      properties.addToken('lateKeyword', node.lateKeyword);
      properties.addNode('type', node.type);
      properties.addNodeList('variables', node.variables);
      _addAnnotatedNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _writeNextCodeLine(node);
    _writeln('VariableDeclarationStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('semicolon', node.semicolon);
      properties.addNode('variables', node.variables);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _writeNextCodeLine(node);
    _writeln('WhileStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('body', node.body);
      properties.addNode('condition', node.condition);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitWithClause(WithClause node) {
    _writeNextCodeLine(node);
    _writeln('WithClause');
    _withIndent(() {
      var properties = _Properties();
      properties.addToken('withKeyword', node.withKeyword);
      properties.addNodeList('mixinTypes', node.mixinTypes2);
      _addAstNode(properties, node);
      _writeProperties(properties);
    });
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _writeNextCodeLine(node);
    _writeln('YieldStatement');
    _withIndent(() {
      var properties = _Properties();
      properties.addNode('expression', node.expression);
      properties.addToken('star', node.star);
      properties.addToken('yieldKeyword', node.yieldKeyword);
      _addStatement(properties, node);
      _writeProperties(properties);
    });
  }

  void writeElement(String name, Element? element) {
    _writeElement(name, element);
  }

  void _addAnnotatedNode(_Properties properties, AnnotatedNode node) {
    properties.addNode('documentationComment', node.documentationComment);
    properties.addNodeList('metadata', node.metadata);
    _addAstNode(properties, node);
  }

  void _addAssertion(_Properties properties, Assertion node) {
    properties.addToken('assertKeyword', node.assertKeyword);
    properties.addNode('condition', node.condition);
    properties.addToken('leftParenthesis', node.leftParenthesis);
    properties.addNode('message', node.message);
    properties.addToken('rightParenthesis', node.rightParenthesis);
    _addAstNode(properties, node);
  }

  void _addAstNode(_Properties properties, AstNode node) {}

  void _addClassMember(_Properties properties, ClassMember node) {
    _addDeclaration(properties, node);
  }

  void _addClassOrMixinDeclaration(
    _Properties properties,
    ClassOrMixinDeclaration node,
  ) {
    properties.addNode('implementsClause', node.implementsClause);
    properties.addNodeList('members', node.members);
    properties.addNode('typeParameters', node.typeParameters);
    _addNamedCompilationUnitMember(properties, node);
  }

  void _addCollectionElement(_Properties properties, CollectionElement node) {
    _addAstNode(properties, node);
  }

  void _addCombinator(_Properties properties, Combinator node) {
    properties.addToken('keyword', node.keyword);
    _addAstNode(properties, node);
  }

  void _addCompilationUnitMember(
    _Properties properties,
    CompilationUnitMember node,
  ) {
    _addDeclaration(properties, node);
  }

  void _addConstructorInitializer(
    _Properties properties,
    ConstructorInitializer node,
  ) {
    _addAstNode(properties, node);
  }

  void _addDeclaration(_Properties properties, Declaration node) {
    properties.addElement('declaredElement', node.declaredElement);
    _addAnnotatedNode(properties, node);
  }

  void _addDirective(
    _Properties properties,
    Directive node,
  ) {
    properties.addElement('element', node.element);
    _addAnnotatedNode(properties, node);
  }

  void _addExpression(_Properties properties, Expression node) {
    properties.addType('staticType', node.staticType);
    _addAstNode(properties, node);
  }

  void _addForEachParts(_Properties properties, ForEachParts node) {
    properties.addToken('inKeyword', node.inKeyword);
    properties.addNode('iterable', node.iterable);
    _addForLoopParts(properties, node);
  }

  void _addForLoopParts(_Properties properties, ForLoopParts node) {
    _addAstNode(properties, node);
  }

  void _addFormalParameter(_Properties properties, FormalParameter node) {
    properties.addToken('covariantKeyword', node.covariantKeyword);
    properties.addElement('declaredElement', node.declaredElement);
    properties.addType('declaredElementType', node.declaredElement!.type);
    properties.addNode('identifier', node.identifier);
    properties.addNodeList('metadata', node.metadata);
    properties.addToken('requiredKeyword', node.requiredKeyword);
    _addAstNode(properties, node);
  }

  void _addForParts(_Properties properties, ForParts node) {
    properties.addNode('condition', node.condition);
    properties.addNodeList('updaters', node.updaters);
    _addForLoopParts(properties, node);
  }

  void _addFunctionBody(_Properties properties, FunctionBody node) {
    properties.addToken('keyword', node.keyword);
    properties.addToken('star', node.star);
    _addAstNode(properties, node);
  }

  void _addIdentifier(
    _Properties properties,
    Identifier node,
  ) {
    properties.addElement('staticElement', node.staticElement);
    _addExpression(properties, node);
  }

  void _addInterpolationElement(
    _Properties properties,
    InterpolationElement node,
  ) {
    _addAstNode(properties, node);
  }

  void _addInvocationExpression(
    _Properties properties,
    InvocationExpression node,
  ) {
    properties.addNode('argumentList', node.argumentList);
    properties.addType('staticInvokeType', node.staticInvokeType);
    properties.addNode('typeArguments', node.typeArguments);
    properties.addTypeList('typeArgumentTypes', node.typeArgumentTypes);
    _addExpression(properties, node);
  }

  void _addLiteral(_Properties properties, Literal node) {
    _addExpression(properties, node);
  }

  void _addMethodReferenceExpression(
    _Properties properties,
    MethodReferenceExpression node,
  ) {
    properties.addElement('staticElement', node.staticElement);
    _addAstNode(properties, node);
  }

  void _addNamedCompilationUnitMember(
    _Properties properties,
    NamedCompilationUnitMember node,
  ) {
    properties.addNode('name', node.name);
    _addCompilationUnitMember(properties, node);
  }

  void _addNamespaceDirective(
    _Properties properties,
    NamespaceDirective node,
  ) {
    properties.addNodeList('combinators', node.combinators);
    properties.addNodeList('configurations', node.configurations);
    properties.addSource('selectedSource', node.selectedSource);
    properties.addRaw('selectedUriContent', node.selectedUriContent);
    _addUriBasedDirective(properties, node);
  }

  void _addNormalFormalParameter(
    _Properties properties,
    NormalFormalParameter node,
  ) {
    properties.addNode('documentationComment', node.documentationComment);
    _addFormalParameter(properties, node);
  }

  void _addSingleStringLiteral(
      _Properties properties, SingleStringLiteral node) {
    _addStringLiteral(properties, node);
  }

  void _addStatement(_Properties properties, Statement node) {
    _addAstNode(properties, node);
  }

  void _addStringLiteral(_Properties properties, StringLiteral node) {
    properties.addRaw('stringValue', node.stringValue);
    _addLiteral(properties, node);
  }

  void _addSwitchMember(_Properties properties, SwitchMember node) {
    properties.addToken('keyword', node.keyword);
    properties.addNodeList('labels', node.labels);
    properties.addNodeList('statements', node.statements);
    _addAstNode(properties, node);
  }

  void _addTypeAlias(_Properties properties, TypeAlias node) {
    properties.addToken('semicolon', node.semicolon);
    properties.addToken('typedefKeyword', node.typedefKeyword);
    _addNamedCompilationUnitMember(properties, node);
  }

  void _addTypeAnnotation(_Properties properties, TypeAnnotation node) {
    properties.addToken('question', node.question);
    properties.addType('type', node.type);
    _addAstNode(properties, node);
  }

  void _addTypedLiteral(_Properties properties, TypedLiteral node) {
    properties.addToken('constKeyword', node.constKeyword);
    properties.addNode('typeArguments', node.typeArguments);
    _addLiteral(properties, node);
  }

  void _addUriBasedDirective(
    _Properties properties,
    UriBasedDirective node,
  ) {
    properties.addNode('uri', node.uri);
    properties.addRaw('uriContent', node.uriContent);
    properties.addElement('uriElement', node.uriElement);
    properties.addSource('uriSource', node.uriSource);
    _addDirective(properties, node);
  }

  String _referenceToString(Reference reference) {
    var parent = reference.parent!;
    if (parent.parent == null) {
      var libraryUriStr = reference.name;
      if (libraryUriStr == _selfUriStr) {
        return 'self';
      }

      // TODO(scheglov) Make it precise again, after Windows.
      if (libraryUriStr.startsWith('file:')) {
        return libraryUriStr.substring(libraryUriStr.lastIndexOf('/') + 1);
      }

      return libraryUriStr;
    }

    // Ignore the unit, skip to the library.
    if (parent.name == '@unit') {
      return _referenceToString(parent.parent!);
    }

    var name = reference.name;
    if (name.isEmpty) {
      name = '•';
    }
    return _referenceToString(parent) + '::$name';
  }

  String _substitutionMapStr(Map<TypeParameterElement, DartType> map) {
    var entriesStr = map.entries.map((entry) {
      return '${entry.key.name}: ${_typeStr(entry.value)}';
    }).join(', ');
    return '{$entriesStr}';
  }

  /// TODO(scheglov) Make [type] non-nullable?
  String? _typeStr(DartType? type) {
    return type?.getDisplayString(withNullability: _withNullability);
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeElement(String name, Element? element) {
    _sink.write(_indent);
    _sink.write('$name: ');
    _writeElement0(element);
  }

  void _writeElement0(Element? element) {
    if (element == null) {
      _sink.writeln('<null>');
      return;
    } else if (element is Member) {
      _sink.writeln(_nameOfMemberClass(element));
      _withIndent(() {
        _writeElement('base', element.declaration);
        var map = element.substitution.map;
        var mapStr = _substitutionMapStr(map);
        _writelnWithIndent('substitution: $mapStr');
      });
    } else if (element is MultiplyDefinedElement) {
      _sink.writeln('<null>');
    } else {
      var reference = (element as ElementImpl).reference;
      if (reference != null) {
        var referenceStr = _referenceToString(reference);
        _sink.writeln(referenceStr);
      } else {
        _sink.writeln('${element.name}@${element.nameOffset}');
      }
    }
  }

  void _writeGenericFunctionTypeElement(
    String name,
    GenericFunctionTypeElement? element,
  ) {
    _sink.write(_indent);
    _sink.write('$name: ');
    if (element == null) {
      _sink.writeln('<null>');
    } else {
      _withIndent(() {
        _sink.writeln('GenericFunctionTypeElement');
        _writeParameterElements(element.parameters);
        _writeType('returnType', element.returnType);
        _writeType('type', element.type);
      });
    }
  }

  void _writeln(String line) {
    _sink.writeln(line);
  }

  void _writelnWithIndent(String line) {
    _sink.write(_indent);
    _sink.writeln(line);
  }

  void _writeNextCodeLine(AstNode node) {
    var nextCodeLine = _codeLinesProvider?.nextLine(node.offset);
    if (nextCodeLine != null) {
      nextCodeLine = nextCodeLine.trim();
      _sink.writeln('// $nextCodeLine');
      _sink.write(_indent);
    }
  }

  void _writeNode(String name, AstNode? node) {
    if (node != null) {
      _sink.write(_indent);
      _sink.write('$name: ');
      node.accept(this);
    }
  }

  void _writeNodeList(String name, NodeList nodeList) {
    if (nodeList.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var node in nodeList) {
          _sink.write(_indent);
          node.accept(this);
        }
      });
    }
  }

  void _writeOffset(String name, int offset) {
    _writelnWithIndent('$name: $offset');
  }

  void _writeParameterElements(List<ParameterElement> parameters) {
    _writelnWithIndent('parameters');
    _withIndent(() {
      for (var parameter in parameters) {
        _writelnWithIndent(parameter.name);
        _withIndent(() {
          _writeParameterKind(parameter);
          _writeType('type', parameter.type);
        });
      }
    });
  }

  void _writeParameterKind(ParameterElement parameter) {
    if (parameter.isOptionalNamed) {
      _writelnWithIndent('kind: optional named');
    } else if (parameter.isOptionalPositional) {
      _writelnWithIndent('kind: optional positional');
    } else if (parameter.isRequiredNamed) {
      _writelnWithIndent('kind: required named');
    } else if (parameter.isRequiredPositional) {
      _writelnWithIndent('kind: required positional');
    } else {
      throw StateError('Unknown kind: $parameter');
    }
  }

  void _writeProperties(_Properties container) {
    var properties = container.properties;
    properties.sort((a, b) => a.name.compareTo(b.name));
    for (var property in properties) {
      property.write(this);
    }
  }

  void _writeSource(String name, Source? source) {
    if (source != null) {
      _writelnWithIndent('$name: ${source.uri}');
    } else {
      _writelnWithIndent('$name: <null>');
    }
  }

  void _writeToken(String name, Token? token) {
    if (token != null) {
      if (_withOffsets) {
        _writelnWithIndent('$name: $token @${token.offset}');
      } else {
        _writelnWithIndent('$name: $token');
      }
    }
  }

  /// TODO(scheglov) maybe inline?
  void _writeTokenList(String name, List<Token> tokens) {
    if (tokens.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var token in tokens) {
          _writelnWithIndent('$name: $token');
          _withIndent(() {
            _writeOffset('offset', token.offset);
          });
        }
      });
    }
  }

  void _writeType(String name, DartType? type) {
    var typeStr = _typeStr(type);
    _writelnWithIndent('$name: $typeStr');
  }

  void _writeTypeList(String name, List<DartType>? types) {
    if (types != null && types.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var type in types) {
          var typeStr = _typeStr(type);
          _writelnWithIndent('$typeStr');
        }
      });
    }
  }

  static String _nameOfMemberClass(Member member) {
    return '${member.runtimeType}';
  }
}

class _ElementProperty extends _Property {
  final Element? element;

  _ElementProperty(String name, this.element) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeElement(name, element);
  }
}

class _GenericFunctionTypeElementProperty extends _Property {
  final GenericFunctionTypeElement? element;

  _GenericFunctionTypeElementProperty(String name, this.element) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeGenericFunctionTypeElement(name, element);
  }
}

class _NodeListProperty extends _Property {
  final NodeList nodeList;

  _NodeListProperty(String name, this.nodeList) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeNodeList(name, nodeList);
  }
}

class _NodeProperty extends _Property {
  final AstNode? node;

  _NodeProperty(String name, this.node) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeNode(name, node);
  }
}

class _Properties {
  final properties = <_Property>[];

  void addElement(String name, Element? element) {
    properties.add(
      _ElementProperty(name, element),
    );
  }

  void addGenericFunctionTypeElement(
    String name,
    GenericFunctionTypeElement? element,
  ) {
    properties.add(
      _GenericFunctionTypeElementProperty(name, element),
    );
  }

  void addNode(String name, AstNode? node) {
    properties.add(
      _NodeProperty(name, node),
    );
  }

  void addNodeList(String name, NodeList nodeList) {
    properties.add(
      _NodeListProperty(name, nodeList),
    );
  }

  void addRaw(String name, Object? value) {
    properties.add(
      _RawProperty(name, value),
    );
  }

  void addSource(String name, Source? source) {
    properties.add(
      _SourceProperty(name, source),
    );
  }

  void addToken(String name, Token? token) {
    properties.add(
      _TokenProperty(name, token),
    );
  }

  void addTokenList(String name, List<Token> tokens) {
    properties.add(
      _TokenListProperty(name, tokens),
    );
  }

  void addType(String name, DartType? type) {
    properties.add(
      _TypeProperty(name, type),
    );
  }

  void addTypeList(String name, List<DartType>? types) {
    properties.add(
      _TypeListProperty(name, types),
    );
  }
}

abstract class _Property {
  final String name;

  _Property(this.name);

  void write(ResolvedAstPrinter printer);
}

class _RawProperty extends _Property {
  final Object? value;

  _RawProperty(String name, this.value) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writelnWithIndent('$name: $value');
  }
}

class _SourceProperty extends _Property {
  final Source? source;

  _SourceProperty(String name, this.source) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeSource(name, source);
  }
}

class _TokenListProperty extends _Property {
  final List<Token> tokens;

  _TokenListProperty(String name, this.tokens) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeTokenList(name, tokens);
  }
}

class _TokenProperty extends _Property {
  final Token? token;

  _TokenProperty(String name, this.token) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeToken(name, token);
  }
}

class _TypeListProperty extends _Property {
  final List<DartType>? types;

  _TypeListProperty(String name, this.types) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeTypeList(name, types);
  }
}

class _TypeProperty extends _Property {
  final DartType? type;

  _TypeProperty(String name, this.type) : super(name);

  @override
  void write(ResolvedAstPrinter printer) {
    printer._writeType(name, type);
  }
}
