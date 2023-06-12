// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// AST visitor that prints tokens into their original positions.
class AstTextPrinter extends ThrowingAstVisitor<void> {
  final StringBuffer _buffer;
  final LineInfo _lineInfo;

  Token? _last;
  int _lastEnd = 0;
  int _lastEndLine = 0;

  AstTextPrinter(this._buffer, this._lineInfo);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _nodeList(node.strings);
  }

  @override
  void visitAnnotation(Annotation node) {
    _token(node.atSign);
    node.name.accept(this);
    node.typeArguments?.accept(this);
    _token(node.period);
    node.constructorName?.accept(this);
    node.arguments?.accept(this);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _token(node.leftParenthesis);
    _nodeList(node.arguments, node.rightParenthesis);
    _token(node.rightParenthesis);
  }

  @override
  void visitAsExpression(AsExpression node) {
    node.expression.accept(this);
    _token(node.asOperator);
    node.type.accept(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _token(node.assertKeyword);
    _token(node.leftParenthesis);

    node.condition.accept(this);
    _tokenIfNot(node.condition.endToken.next, node.rightParenthesis);

    node.message?.accept(this);
    _tokenIfNot(node.message?.endToken.next, node.rightParenthesis);

    _token(node.rightParenthesis);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _token(node.assertKeyword);
    _token(node.leftParenthesis);

    node.condition.accept(this);
    _tokenIfNot(node.condition.endToken.next, node.rightParenthesis);

    node.message?.accept(this);
    _tokenIfNot(node.message?.endToken.next, node.rightParenthesis);

    _token(node.rightParenthesis);
    _token(node.semicolon);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    _token(node.operator);
    node.rightHandSide.accept(this);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _token(node.awaitKeyword);
    node.expression.accept(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);
    _token(node.operator);
    node.rightOperand.accept(this);
  }

  @override
  void visitBlock(Block node) {
    _token(node.leftBracket);
    _nodeList(node.statements);
    _token(node.rightBracket);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _functionBody(node);
    node.block.accept(this);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _token(node.literal);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _token(node.breakKeyword);
    node.label?.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    node.target.accept(this);
    _nodeList(node.cascadeSections);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _token(node.onKeyword);
    node.exceptionType?.accept(this);
    _token(node.catchKeyword);
    _token(node.leftParenthesis);
    node.exceptionParameter?.accept(this);
    _token(node.comma);
    node.stackTraceParameter?.accept(this);
    _token(node.rightParenthesis);
    node.body.accept(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _compilationUnitMember(node);
    _token(node.abstractKeyword);
    _token(node.classKeyword);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    node.nativeClause?.accept(this);
    _token(node.leftBracket);
    node.members.accept(this);
    _token(node.rightBracket);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _compilationUnitMember(node);
    _token(node.abstractKeyword);
    _token(node.typedefKeyword);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    _token(node.equals);
    node.superclass2.accept(this);
    node.withClause.accept(this);
    node.implementsClause?.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitComment(Comment node) {}

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.scriptTag?.accept(this);
    node.directives.accept(this);
    node.declarations.accept(this);
    _token(node.endToken);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    _token(node.question);
    node.thenExpression.accept(this);
    _token(node.colon);
    node.elseExpression.accept(this);
  }

  @override
  void visitConfiguration(Configuration node) {
    _token(node.ifKeyword);
    _token(node.leftParenthesis);
    node.name.accept(this);
    _token(node.equalToken);
    node.value?.accept(this);
    _token(node.rightParenthesis);
    node.uri.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _classMember(node);
    _token(node.externalKeyword);
    _token(node.constKeyword);
    _token(node.factoryKeyword);
    node.returnType.accept(this);
    _token(node.period);
    node.name?.accept(this);
    node.parameters.accept(this);
    _token(node.separator);
    _nodeList(node.initializers, node.body.beginToken);
    node.redirectedConstructor?.accept(this);
    node.body.accept(this);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _token(node.thisKeyword);
    _token(node.period);
    node.fieldName.accept(this);
    _token(node.equals);
    node.expression.accept(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type2.accept(this);
    _token(node.period);
    node.name?.accept(this);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    node.constructorName.accept(this);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _token(node.continueKeyword);
    node.label?.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _declaration(node);
    _token(node.keyword);
    node.type?.accept(this);
    node.identifier.accept(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
    _token(node.separator);
    node.defaultValue?.accept(this);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _token(node.doKeyword);
    node.body.accept(this);
    _token(node.whileKeyword);
    _token(node.leftParenthesis);
    node.condition.accept(this);
    _token(node.rightParenthesis);
    _token(node.semicolon);
  }

  @override
  void visitDottedName(DottedName node) {
    _nodeList(node.components, node.endToken.next);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _token(node.literal);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _functionBody(node);
    _token(node.semicolon);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    _token(node.semicolon);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _declaration(node);
    node.name.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _compilationUnitMember(node);
    _token(node.enumKeyword);
    node.name.accept(this);
    _token(node.leftBracket);
    _nodeList(node.constants, node.rightBracket);
    _token(node.rightBracket);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _directive(node);
    _token(node.keyword);
    node.uri.accept(this);
    node.configurations.accept(this);
    _nodeList(node.combinators);
    _token(node.semicolon);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _functionBody(node);
    _token(node.functionDefinition);
    node.expression.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _token(node.extendsKeyword);
    node.superclass2.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _compilationUnitMember(node);
    _token(node.extensionKeyword);
    _token(node.typeKeyword);
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    _token(node.onKeyword);
    node.extendedType.accept(this);
    node.showClause?.accept(this);
    node.hideClause?.accept(this);
    _token(node.leftBracket);
    node.members.accept(this);
    _token(node.rightBracket);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    node.extensionName.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _classMember(node);
    _token(node.abstractKeyword);
    _token(node.externalKeyword);
    _token(node.staticKeyword);
    _token(node.covariantKeyword);
    node.fields.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _normalFormalParameter(node);
    _token(node.keyword);
    node.type?.accept(this);
    _token(node.thisKeyword);
    _token(node.period);
    node.identifier.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    node.loopVariable.accept(this);
    _token(node.inKeyword);
    node.iterable.accept(this);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    node.identifier.accept(this);
    _token(node.inKeyword);
    node.iterable.accept(this);
  }

  @override
  void visitForElement(ForElement node) {
    _token(node.forKeyword);
    _token(node.leftParenthesis);
    node.forLoopParts.accept(this);
    _token(node.rightParenthesis);
    node.body.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _token(node.leftParenthesis);

    var parameters = node.parameters;
    for (var i = 0; i < parameters.length; ++i) {
      var parameter = parameters[i];
      if (node.leftDelimiter?.next == parameter.beginToken) {
        _token(node.leftDelimiter);
      }

      parameter.accept(this);

      var itemSeparator = parameter.endToken.next!;
      if (itemSeparator != node.rightParenthesis) {
        _token(itemSeparator);
        itemSeparator = itemSeparator.next!;
      }

      if (itemSeparator == node.rightDelimiter) {
        _token(node.rightDelimiter);
      }
    }

    _token(node.rightParenthesis);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    node.variables.accept(this);
    _token(node.leftSeparator);
    node.condition?.accept(this);
    _token(node.rightSeparator);
    _nodeList(node.updaters, node.endToken.next);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    node.initialization?.accept(this);
    _token(node.leftSeparator);
    node.condition?.accept(this);
    _token(node.rightSeparator);
    _nodeList(node.updaters, node.updaters.endToken?.next);
  }

  @override
  void visitForStatement(ForStatement node) {
    _token(node.awaitKeyword);
    _token(node.forKeyword);
    _token(node.leftParenthesis);
    node.forLoopParts.accept(this);
    _token(node.rightParenthesis);
    node.body.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _compilationUnitMember(node);
    _token(node.externalKeyword);
    node.returnType?.accept(this);
    _token(node.propertyKeyword);
    node.name.accept(this);
    node.functionExpression.accept(this);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    node.functionDeclaration.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    node.body.accept(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    node.function.accept(this);
    node.typeArguments?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _compilationUnitMember(node);
    _token(node.typedefKeyword);
    node.returnType?.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _normalFormalParameter(node);
    node.returnType?.accept(this);
    node.identifier.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
    _token(node.question);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    node.returnType?.accept(this);
    _token(node.functionKeyword);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
    _token(node.question);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _compilationUnitMember(node);
    _token(node.typedefKeyword);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    _token(node.equals);
    node.type.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _token(node.keyword);
    _nodeList(node.hiddenNames, node.endToken.next);
  }

  @override
  void visitIfElement(IfElement node) {
    _token(node.ifKeyword);
    _token(node.leftParenthesis);
    node.condition.accept(this);
    _token(node.rightParenthesis);
    node.thenElement.accept(this);
    _token(node.elseKeyword);
    node.elseElement?.accept(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _token(node.ifKeyword);
    _token(node.leftParenthesis);
    node.condition.accept(this);
    _token(node.rightParenthesis);
    node.thenStatement.accept(this);
    _token(node.elseKeyword);
    node.elseStatement?.accept(this);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _token(node.implementsKeyword);
    _nodeList(node.interfaces2, node.endToken.next);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _directive(node);
    _token(node.keyword);
    node.uri.accept(this);
    node.configurations.accept(this);
    _token(node.deferredKeyword);
    _token(node.asKeyword);
    node.prefix?.accept(this);
    _nodeList(node.combinators);
    _token(node.semicolon);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    _token(node.period);
    _token(node.question);
    _token(node.leftBracket);
    node.index.accept(this);
    _token(node.rightBracket);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _token(node.keyword);
    node.constructorName.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _token(node.literal);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _token(node.leftBracket);
    node.expression.accept(this);
    _token(node.rightBracket);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _token(node.contents);
  }

  @override
  void visitIsExpression(IsExpression node) {
    node.expression.accept(this);
    _token(node.isOperator);
    _token(node.notOperator);
    node.type.accept(this);
  }

  @override
  void visitLabel(Label node) {
    node.label.accept(this);
    _token(node.colon);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _nodeList(node.labels);
    node.statement.accept(this);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _directive(node);
    _token(node.libraryKeyword);
    node.name.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _nodeList(node.components, node.endToken.next);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _typedLiteral(node);
    _token(node.leftBracket);
    _nodeList(node.elements, node.rightBracket);
    _token(node.rightBracket);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    node.key.accept(this);
    _token(node.separator);
    node.value.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _classMember(node);
    _token(node.externalKeyword);
    _token(node.modifierKeyword);
    node.returnType?.accept(this);
    _token(node.propertyKeyword);
    _token(node.operatorKeyword);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    node.body.accept(this);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    _token(node.operator);
    node.methodName.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _compilationUnitMember(node);
    _token(node.mixinKeyword);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
    _token(node.leftBracket);
    node.members.accept(this);
    _token(node.rightBracket);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.name.accept(this);
    node.expression.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    node.name.accept(this);
    node.typeArguments?.accept(this);
    _token(node.question);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _token(node.nativeKeyword);
    node.name?.accept(this);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _token(node.nativeKeyword);
    node.stringLiteral?.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _token(node.literal);
  }

  @override
  void visitOnClause(OnClause node) {
    _token(node.onKeyword);
    _nodeList(node.superclassConstraints2, node.endToken.next);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _token(node.leftParenthesis);
    node.expression.accept(this);
    _token(node.rightParenthesis);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _directive(node);
    _token(node.partKeyword);
    node.uri.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _directive(node);
    _token(node.partKeyword);
    _token(node.ofKeyword);
    node.uri?.accept(this);
    node.libraryName?.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    _token(node.operator);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    _token(node.period);
    node.identifier.accept(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _token(node.operator);
    node.operand.accept(this);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    _token(node.operator);
    node.propertyName.accept(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _token(node.thisKeyword);
    _token(node.period);
    node.constructorName?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _token(node.rethrowKeyword);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _token(node.returnKeyword);
    node.expression?.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    _token(node.scriptTag);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _typedLiteral(node);
    _token(node.leftBracket);
    _nodeList(node.elements, node.rightBracket);
    _token(node.rightBracket);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _token(node.keyword);
    _nodeList(node.shownNames, node.endToken.next);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _normalFormalParameter(node);
    _token(node.keyword);
    node.type?.accept(this);
    node.identifier?.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _token(node.token);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _token(node.literal);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _token(node.spreadOperator);
    node.expression.accept(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _nodeList(node.elements);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _token(node.superKeyword);
    _token(node.period);
    node.constructorName?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _token(node.superKeyword);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _nodeList(node.labels);
    _token(node.keyword);
    node.expression.accept(this);
    _token(node.colon);
    _nodeList(node.statements);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _nodeList(node.labels);
    _token(node.keyword);
    _token(node.colon);
    _nodeList(node.statements);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _token(node.switchKeyword);
    _token(node.leftParenthesis);
    node.expression.accept(this);
    _token(node.rightParenthesis);
    _token(node.leftBracket);
    _nodeList(node.members);
    _token(node.rightBracket);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _token(node.poundSign);
    var components = node.components;
    for (var i = 0; i < components.length; ++i) {
      var component = components[i];
      _token(component);
      if (i != components.length - 1) {
        _token(component.next);
      }
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _token(node.thisKeyword);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _token(node.throwKeyword);
    node.expression.accept(this);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _compilationUnitMember(node);
    _token(node.externalKeyword);
    node.variables.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _token(node.tryKeyword);
    node.body.accept(this);
    _nodeList(node.catchClauses);
    _token(node.finallyKeyword);
    node.finallyBlock?.accept(this);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _token(node.leftBracket);
    _nodeList(node.arguments, node.rightBracket);
    _token(node.rightBracket);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _declaration(node);
    // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
    // added to the interface.
    _token((node as TypeParameterImpl).varianceKeyword);
    node.name.accept(this);
    _token(node.extendsKeyword);
    node.bound?.accept(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _token(node.leftBracket);
    _nodeList(node.typeParameters, node.rightBracket);
    _token(node.rightBracket);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _annotatedNode(node);
    node.name.accept(this);
    _token(node.equals);
    node.initializer?.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _annotatedNode(node);
    _token(node.lateKeyword);
    _token(node.keyword);
    node.type?.accept(this);
    _nodeList(node.variables, node.endToken.next);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.variables.accept(this);
    _token(node.semicolon);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _token(node.whileKeyword);
    _token(node.leftParenthesis);
    node.condition.accept(this);
    _token(node.rightParenthesis);
    node.body.accept(this);
  }

  @override
  void visitWithClause(WithClause node) {
    _token(node.withKeyword);
    _nodeList(node.mixinTypes2, node.endToken.next);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _token(node.yieldKeyword);
    _token(node.star);
    node.expression.accept(this);
    _token(node.semicolon);
  }

  void _annotatedNode(AnnotatedNode node) {
    node.documentationComment?.accept(this);
    _nodeList(node.metadata);
  }

  void _classMember(ClassMember node) {
    _declaration(node);
  }

  void _compilationUnitMember(CompilationUnitMember node) {
    _declaration(node);
  }

  void _declaration(Declaration node) {
    _annotatedNode(node);
  }

  void _directive(Directive node) {
    _annotatedNode(node);
  }

  void _functionBody(FunctionBody node) {
    _token(node.keyword);
    _token(node.star);
  }

  /// Print nodes from the [nodeList].
  ///
  /// If the [endToken] is not `null`, print one token after every node,
  /// unless it is the [endToken].
  void _nodeList(List<AstNode> nodeList, [Token? endToken]) {
    var length = nodeList.length;
    for (var i = 0; i < length; ++i) {
      var node = nodeList[i];
      node.accept(this);
      if (endToken != null && node.endToken.next != endToken) {
        _token(node.endToken.next);
      }
    }
  }

  void _normalFormalParameter(NormalFormalParameter node) {
    node.documentationComment?.accept(this);
    _nodeList(node.metadata);
    _token(node.requiredKeyword);
    _token(node.covariantKeyword);
  }

  void _token(Token? token) {
    if (token == null) return;

    var last = _last;
    if (last != null) {
      if (last.next != token) {
        throw StateError(
          '|$last| must be followed by |${last.next}|, got |$token|',
        );
      }
    }

    // Print preceding comments as a separate sequence of tokens.
    if (token.precedingComments != null) {
      var lastToken = last;
      _last = null;
      for (Token? c = token.precedingComments; c != null; c = c.next) {
        _token(c);
      }
      _last = lastToken;
    }

    for (var offset = _lastEnd; offset < token.offset; offset++) {
      var offsetLocation = _lineInfo.getLocation(offset + 1);
      var offsetLine = offsetLocation.lineNumber - 1;
      if (offsetLine == _lastEndLine) {
        _buffer.write(' ');
      } else {
        _buffer.write('\n');
        _lastEndLine++;
      }
    }

    _buffer.write(token.lexeme);

    _last = token;
    _lastEnd = token.end;

    var endLocation = _lineInfo.getLocation(token.end);
    _lastEndLine = endLocation.lineNumber - 1;
  }

  void _tokenIfNot(Token? maybe, Token ifNot) {
    if (maybe == null) return;
    if (maybe == ifNot) return;
    _token(maybe);
  }

  void _typedLiteral(TypedLiteral node) {
    _token(node.constKeyword);
    node.typeArguments?.accept(this);
  }
}
