// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/services/lint.dart';

/// The type of the function that handles exceptions in lints.
typedef LintRuleExceptionHandler = void Function(
    AstNode node, LintRule linter, dynamic exception, StackTrace stackTrace);

/// The AST visitor that runs handlers for nodes from the [registry].
class LinterVisitor extends RecursiveAstVisitor<void> {
  final NodeLintRegistry registry;
  final LintRuleExceptionHandler exceptionHandler;

  LinterVisitor(this.registry, [LintRuleExceptionHandler? exceptionHandler])
      : exceptionHandler = exceptionHandler ??
            LinterExceptionHandler(propagateExceptions: true).logException;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _runSubscriptions(node, registry._forAdjacentStrings);
    super.visitAdjacentStrings(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _runSubscriptions(node, registry._forAnnotation);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _runSubscriptions(node, registry._forArgumentList);
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _runSubscriptions(node, registry._forAsExpression);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _runSubscriptions(node, registry._forAssertInitializer);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _runSubscriptions(node, registry._forAssertStatement);
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _runSubscriptions(node, registry._forAssignmentExpression);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _runSubscriptions(node, registry._forAwaitExpression);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _runSubscriptions(node, registry._forBinaryExpression);
    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    _runSubscriptions(node, registry._forBlock);
    super.visitBlock(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _runSubscriptions(node, registry._forBlockFunctionBody);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _runSubscriptions(node, registry._forBooleanLiteral);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _runSubscriptions(node, registry._forBreakStatement);
    super.visitBreakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _runSubscriptions(node, registry._forCascadeExpression);
    super.visitCascadeExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _runSubscriptions(node, registry._forCatchClause);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _runSubscriptions(node, registry._forClassDeclaration);
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _runSubscriptions(node, registry._forClassTypeAlias);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    _runSubscriptions(node, registry._forComment);
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _runSubscriptions(node, registry._forCommentReference);
    super.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _runSubscriptions(node, registry._forCompilationUnit);
    super.visitCompilationUnit(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _runSubscriptions(node, registry._forConditionalExpression);
    super.visitConditionalExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    _runSubscriptions(node, registry._forConfiguration);
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _runSubscriptions(node, registry._forConstructorDeclaration);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _runSubscriptions(node, registry._forConstructorFieldInitializer);
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _runSubscriptions(node, registry._forConstructorName);
    super.visitConstructorName(node);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _runSubscriptions(node, registry._forConstructorReference);
    super.visitConstructorReference(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _runSubscriptions(node, registry._forContinueStatement);
    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _runSubscriptions(node, registry._forDeclaredIdentifier);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _runSubscriptions(node, registry._forDefaultFormalParameter);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _runSubscriptions(node, registry._forDoStatement);
    super.visitDoStatement(node);
  }

  @override
  void visitDottedName(DottedName node) {
    _runSubscriptions(node, registry._forDottedName);
    super.visitDottedName(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _runSubscriptions(node, registry._forDoubleLiteral);
    super.visitDoubleLiteral(node);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _runSubscriptions(node, registry._forEmptyFunctionBody);
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    _runSubscriptions(node, registry._forEmptyStatement);
    super.visitEmptyStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _runSubscriptions(node, registry._forEnumConstantDeclaration);
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _runSubscriptions(node, registry._forEnumDeclaration);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _runSubscriptions(node, registry._forExportDirective);
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _runSubscriptions(node, registry._forExpressionFunctionBody);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _runSubscriptions(node, registry._forExpressionStatement);
    super.visitExpressionStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _runSubscriptions(node, registry._forExtendsClause);
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _runSubscriptions(node, registry._forExtensionDeclaration);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _runSubscriptions(node, registry._forExtensionOverride);
    super.visitExtensionOverride(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _runSubscriptions(node, registry._forFieldDeclaration);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _runSubscriptions(node, registry._forFieldFormalParameter);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _runSubscriptions(node, registry._forForEachPartsWithDeclaration);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _runSubscriptions(node, registry._forForEachPartsWithIdentifier);
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    _runSubscriptions(node, registry._forForElement);
    super.visitForElement(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _runSubscriptions(node, registry._forFormalParameterList);
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _runSubscriptions(node, registry._forForPartsWithDeclarations);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _runSubscriptions(node, registry._forForPartsWithExpression);
    super.visitForPartsWithExpression(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _runSubscriptions(node, registry._forForStatement);
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _runSubscriptions(node, registry._forFunctionDeclaration);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _runSubscriptions(node, registry._forFunctionDeclarationStatement);
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _runSubscriptions(node, registry._forFunctionExpression);
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _runSubscriptions(node, registry._forFunctionExpressionInvocation);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _runSubscriptions(node, registry._forFunctionTypeAlias);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _runSubscriptions(node, registry._forFunctionTypedFormalParameter);
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _runSubscriptions(node, registry._forGenericFunctionType);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _runSubscriptions(node, registry._forGenericTypeAlias);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _runSubscriptions(node, registry._forHideCombinator);
    super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _runSubscriptions(node, registry._forIfElement);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _runSubscriptions(node, registry._forIfStatement);
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _runSubscriptions(node, registry._forImplementsClause);
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _runSubscriptions(node, registry._forImportDirective);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _runSubscriptions(node, registry._forIndexExpression);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _runSubscriptions(node, registry._forInstanceCreationExpression);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _runSubscriptions(node, registry._forIntegerLiteral);
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _runSubscriptions(node, registry._forInterpolationExpression);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _runSubscriptions(node, registry._forInterpolationString);
    super.visitInterpolationString(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _runSubscriptions(node, registry._forIsExpression);
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    _runSubscriptions(node, registry._forLabel);
    super.visitLabel(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _runSubscriptions(node, registry._forLabeledStatement);
    super.visitLabeledStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _runSubscriptions(node, registry._forLibraryDirective);
    super.visitLibraryDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _runSubscriptions(node, registry._forLibraryIdentifier);
    super.visitLibraryIdentifier(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _runSubscriptions(node, registry._forListLiteral);
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _runSubscriptions(node, registry._forMapLiteralEntry);
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _runSubscriptions(node, registry._forMethodDeclaration);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _runSubscriptions(node, registry._forMethodInvocation);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _runSubscriptions(node, registry._forMixinDeclaration);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _runSubscriptions(node, registry._forNamedExpression);
    super.visitNamedExpression(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _runSubscriptions(node, registry._forNamedType);
    super.visitNamedType(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _runSubscriptions(node, registry._forNativeClause);
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _runSubscriptions(node, registry._forNativeFunctionBody);
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _runSubscriptions(node, registry._forNullLiteral);
    super.visitNullLiteral(node);
  }

  @override
  void visitOnClause(OnClause node) {
    _runSubscriptions(node, registry._forOnClause);
    super.visitOnClause(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _runSubscriptions(node, registry._forParenthesizedExpression);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _runSubscriptions(node, registry._forPartDirective);
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _runSubscriptions(node, registry._forPartOfDirective);
    super.visitPartOfDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _runSubscriptions(node, registry._forPostfixExpression);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _runSubscriptions(node, registry._forPrefixedIdentifier);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _runSubscriptions(node, registry._forPrefixExpression);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _runSubscriptions(node, registry._forPropertyAccess);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _runSubscriptions(node, registry._forRedirectingConstructorInvocation);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _runSubscriptions(node, registry._forRethrowExpression);
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _runSubscriptions(node, registry._forReturnStatement);
    super.visitReturnStatement(node);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    _runSubscriptions(node, registry._forScriptTag);
    super.visitScriptTag(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _runSubscriptions(node, registry._forSetOrMapLiteral);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _runSubscriptions(node, registry._forShowCombinator);
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _runSubscriptions(node, registry._forSimpleFormalParameter);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _runSubscriptions(node, registry._forSimpleIdentifier);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _runSubscriptions(node, registry._forSimpleStringLiteral);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _runSubscriptions(node, registry._forSpreadElement);
    super.visitSpreadElement(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _runSubscriptions(node, registry._forStringInterpolation);
    super.visitStringInterpolation(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _runSubscriptions(node, registry._forSuperConstructorInvocation);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _runSubscriptions(node, registry._forSuperExpression);
    super.visitSuperExpression(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _runSubscriptions(node, registry._forSwitchCase);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _runSubscriptions(node, registry._forSwitchDefault);
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _runSubscriptions(node, registry._forSwitchStatement);
    super.visitSwitchStatement(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _runSubscriptions(node, registry._forSymbolLiteral);
    super.visitSymbolLiteral(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _runSubscriptions(node, registry._forThisExpression);
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _runSubscriptions(node, registry._forThrowExpression);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _runSubscriptions(node, registry._forTopLevelVariableDeclaration);
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _runSubscriptions(node, registry._forTryStatement);
    super.visitTryStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _runSubscriptions(node, registry._forTypeArgumentList);
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _runSubscriptions(node, registry._forTypeParameter);
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _runSubscriptions(node, registry._forTypeParameterList);
    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _runSubscriptions(node, registry._forVariableDeclaration);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _runSubscriptions(node, registry._forVariableDeclarationList);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _runSubscriptions(node, registry._forVariableDeclarationStatement);
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _runSubscriptions(node, registry._forWhileStatement);
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    _runSubscriptions(node, registry._forWithClause);
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _runSubscriptions(node, registry._forYieldStatement);
    super.visitYieldStatement(node);
  }

  void _runSubscriptions<T extends AstNode>(
      T node, List<_Subscription<T>> subscriptions) {
    for (int i = 0; i < subscriptions.length; i++) {
      var subscription = subscriptions[i];
      var timer = subscription.timer;
      timer?.start();
      try {
        node.accept(subscription.visitor);
      } catch (exception, stackTrace) {
        exceptionHandler(node, subscription.linter, exception, stackTrace);
      }
      timer?.stop();
    }
  }
}

/// The container to register visitors for separate AST node types.
class NodeLintRegistry {
  final bool enableTiming;
  final List<_Subscription<AdjacentStrings>> _forAdjacentStrings = [];
  final List<_Subscription<Annotation>> _forAnnotation = [];
  final List<_Subscription<ArgumentList>> _forArgumentList = [];
  final List<_Subscription<AsExpression>> _forAsExpression = [];
  final List<_Subscription<AssertInitializer>> _forAssertInitializer = [];
  final List<_Subscription<AssertStatement>> _forAssertStatement = [];
  final List<_Subscription<AssignmentExpression>> _forAssignmentExpression = [];
  final List<_Subscription<AwaitExpression>> _forAwaitExpression = [];
  final List<_Subscription<BinaryExpression>> _forBinaryExpression = [];
  final List<_Subscription<Block>> _forBlock = [];
  final List<_Subscription<BlockFunctionBody>> _forBlockFunctionBody = [];
  final List<_Subscription<BooleanLiteral>> _forBooleanLiteral = [];
  final List<_Subscription<BreakStatement>> _forBreakStatement = [];
  final List<_Subscription<CascadeExpression>> _forCascadeExpression = [];
  final List<_Subscription<CatchClause>> _forCatchClause = [];
  final List<_Subscription<ClassDeclaration>> _forClassDeclaration = [];
  final List<_Subscription<ClassTypeAlias>> _forClassTypeAlias = [];
  final List<_Subscription<Comment>> _forComment = [];
  final List<_Subscription<CommentReference>> _forCommentReference = [];
  final List<_Subscription<CompilationUnit>> _forCompilationUnit = [];
  final List<_Subscription<ConditionalExpression>> _forConditionalExpression =
      [];
  final List<_Subscription<Configuration>> _forConfiguration = [];
  final List<_Subscription<ConstructorDeclaration>> _forConstructorDeclaration =
      [];
  final List<_Subscription<ConstructorFieldInitializer>>
      _forConstructorFieldInitializer = [];
  final List<_Subscription<ConstructorName>> _forConstructorName = [];
  final List<_Subscription<ConstructorReference>> _forConstructorReference = [];
  final List<_Subscription<ContinueStatement>> _forContinueStatement = [];
  final List<_Subscription<DeclaredIdentifier>> _forDeclaredIdentifier = [];
  final List<_Subscription<DefaultFormalParameter>> _forDefaultFormalParameter =
      [];
  final List<_Subscription<DoStatement>> _forDoStatement = [];
  final List<_Subscription<DottedName>> _forDottedName = [];
  final List<_Subscription<DoubleLiteral>> _forDoubleLiteral = [];
  final List<_Subscription<EmptyFunctionBody>> _forEmptyFunctionBody = [];
  final List<_Subscription<EmptyStatement>> _forEmptyStatement = [];
  final List<_Subscription<EnumConstantDeclaration>>
      _forEnumConstantDeclaration = [];
  final List<_Subscription<EnumDeclaration>> _forEnumDeclaration = [];
  final List<_Subscription<ExportDirective>> _forExportDirective = [];
  final List<_Subscription<ExpressionFunctionBody>> _forExpressionFunctionBody =
      [];
  final List<_Subscription<ExpressionStatement>> _forExpressionStatement = [];
  final List<_Subscription<ExtendsClause>> _forExtendsClause = [];
  final List<_Subscription<ExtensionDeclaration>> _forExtensionDeclaration = [];
  final List<_Subscription<ExtensionOverride>> _forExtensionOverride = [];
  final List<_Subscription<FieldDeclaration>> _forFieldDeclaration = [];
  final List<_Subscription<FieldFormalParameter>> _forFieldFormalParameter = [];
  final List<_Subscription<ForEachPartsWithDeclaration>>
      _forForEachPartsWithDeclaration = [];
  final List<_Subscription<ForEachPartsWithIdentifier>>
      _forForEachPartsWithIdentifier = [];
  final List<_Subscription<ForElement>> _forForElement = [];
  final List<_Subscription<FormalParameterList>> _forFormalParameterList = [];
  final List<_Subscription<ForPartsWithDeclarations>>
      _forForPartsWithDeclarations = [];
  final List<_Subscription<ForPartsWithExpression>> _forForPartsWithExpression =
      [];
  final List<_Subscription<ForStatement>> _forForStatement = [];
  final List<_Subscription<FunctionDeclaration>> _forFunctionDeclaration = [];
  final List<_Subscription<FunctionDeclarationStatement>>
      _forFunctionDeclarationStatement = [];
  final List<_Subscription<FunctionExpression>> _forFunctionExpression = [];
  final List<_Subscription<FunctionExpressionInvocation>>
      _forFunctionExpressionInvocation = [];
  final List<_Subscription<FunctionTypeAlias>> _forFunctionTypeAlias = [];
  final List<_Subscription<FunctionTypedFormalParameter>>
      _forFunctionTypedFormalParameter = [];
  final List<_Subscription<GenericFunctionType>> _forGenericFunctionType = [];
  final List<_Subscription<GenericTypeAlias>> _forGenericTypeAlias = [];
  final List<_Subscription<HideCombinator>> _forHideCombinator = [];
  final List<_Subscription<IfElement>> _forIfElement = [];
  final List<_Subscription<IfStatement>> _forIfStatement = [];
  final List<_Subscription<ImplementsClause>> _forImplementsClause = [];
  final List<_Subscription<ImportDirective>> _forImportDirective = [];
  final List<_Subscription<IndexExpression>> _forIndexExpression = [];
  final List<_Subscription<InstanceCreationExpression>>
      _forInstanceCreationExpression = [];
  final List<_Subscription<IntegerLiteral>> _forIntegerLiteral = [];
  final List<_Subscription<InterpolationExpression>>
      _forInterpolationExpression = [];
  final List<_Subscription<InterpolationString>> _forInterpolationString = [];
  final List<_Subscription<IsExpression>> _forIsExpression = [];
  final List<_Subscription<Label>> _forLabel = [];
  final List<_Subscription<LabeledStatement>> _forLabeledStatement = [];
  final List<_Subscription<LibraryDirective>> _forLibraryDirective = [];
  final List<_Subscription<LibraryIdentifier>> _forLibraryIdentifier = [];
  final List<_Subscription<ListLiteral>> _forListLiteral = [];
  final List<_Subscription<MapLiteralEntry>> _forMapLiteralEntry = [];
  final List<_Subscription<MethodDeclaration>> _forMethodDeclaration = [];
  final List<_Subscription<MethodInvocation>> _forMethodInvocation = [];
  final List<_Subscription<MixinDeclaration>> _forMixinDeclaration = [];
  final List<_Subscription<NamedExpression>> _forNamedExpression = [];
  final List<_Subscription<NamedType>> _forNamedType = [];
  final List<_Subscription<NativeClause>> _forNativeClause = [];
  final List<_Subscription<NativeFunctionBody>> _forNativeFunctionBody = [];
  final List<_Subscription<NullLiteral>> _forNullLiteral = [];
  final List<_Subscription<OnClause>> _forOnClause = [];
  final List<_Subscription<ParenthesizedExpression>>
      _forParenthesizedExpression = [];
  final List<_Subscription<PartDirective>> _forPartDirective = [];
  final List<_Subscription<PartOfDirective>> _forPartOfDirective = [];
  final List<_Subscription<PostfixExpression>> _forPostfixExpression = [];
  final List<_Subscription<PrefixedIdentifier>> _forPrefixedIdentifier = [];
  final List<_Subscription<PrefixExpression>> _forPrefixExpression = [];
  final List<_Subscription<PropertyAccess>> _forPropertyAccess = [];
  final List<_Subscription<RedirectingConstructorInvocation>>
      _forRedirectingConstructorInvocation = [];
  final List<_Subscription<RethrowExpression>> _forRethrowExpression = [];
  final List<_Subscription<ReturnStatement>> _forReturnStatement = [];
  final List<_Subscription<ScriptTag>> _forScriptTag = [];
  final List<_Subscription<SetOrMapLiteral>> _forSetOrMapLiteral = [];
  final List<_Subscription<ShowCombinator>> _forShowCombinator = [];
  final List<_Subscription<SimpleFormalParameter>> _forSimpleFormalParameter =
      [];
  final List<_Subscription<SimpleIdentifier>> _forSimpleIdentifier = [];
  final List<_Subscription<SimpleStringLiteral>> _forSimpleStringLiteral = [];
  final List<_Subscription<SpreadElement>> _forSpreadElement = [];
  final List<_Subscription<StringInterpolation>> _forStringInterpolation = [];
  final List<_Subscription<SuperConstructorInvocation>>
      _forSuperConstructorInvocation = [];
  final List<_Subscription<SuperExpression>> _forSuperExpression = [];
  final List<_Subscription<SwitchCase>> _forSwitchCase = [];
  final List<_Subscription<SwitchDefault>> _forSwitchDefault = [];
  final List<_Subscription<SwitchStatement>> _forSwitchStatement = [];
  final List<_Subscription<SymbolLiteral>> _forSymbolLiteral = [];
  final List<_Subscription<ThisExpression>> _forThisExpression = [];
  final List<_Subscription<ThrowExpression>> _forThrowExpression = [];
  final List<_Subscription<TopLevelVariableDeclaration>>
      _forTopLevelVariableDeclaration = [];
  final List<_Subscription<TryStatement>> _forTryStatement = [];
  final List<_Subscription<TypeArgumentList>> _forTypeArgumentList = [];
  final List<_Subscription<TypeParameter>> _forTypeParameter = [];
  final List<_Subscription<TypeParameterList>> _forTypeParameterList = [];
  final List<_Subscription<VariableDeclaration>> _forVariableDeclaration = [];
  final List<_Subscription<VariableDeclarationList>>
      _forVariableDeclarationList = [];
  final List<_Subscription<VariableDeclarationStatement>>
      _forVariableDeclarationStatement = [];
  final List<_Subscription<WhileStatement>> _forWhileStatement = [];
  final List<_Subscription<WithClause>> _forWithClause = [];
  final List<_Subscription<YieldStatement>> _forYieldStatement = [];

  NodeLintRegistry(this.enableTiming);

  void addAdjacentStrings(LintRule linter, AstVisitor visitor) {
    _forAdjacentStrings.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAnnotation(LintRule linter, AstVisitor visitor) {
    _forAnnotation.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addArgumentList(LintRule linter, AstVisitor visitor) {
    _forArgumentList.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAsExpression(LintRule linter, AstVisitor visitor) {
    _forAsExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAssertInitializer(LintRule linter, AstVisitor visitor) {
    _forAssertInitializer
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAssertStatement(LintRule linter, AstVisitor visitor) {
    _forAssertStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAssignmentExpression(LintRule linter, AstVisitor visitor) {
    _forAssignmentExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAwaitExpression(LintRule linter, AstVisitor visitor) {
    _forAwaitExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addBinaryExpression(LintRule linter, AstVisitor visitor) {
    _forBinaryExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addBlock(LintRule linter, AstVisitor visitor) {
    _forBlock.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addBlockFunctionBody(LintRule linter, AstVisitor visitor) {
    _forBlockFunctionBody
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addBooleanLiteral(LintRule linter, AstVisitor visitor) {
    _forBooleanLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addBreakStatement(LintRule linter, AstVisitor visitor) {
    _forBreakStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addCascadeExpression(LintRule linter, AstVisitor visitor) {
    _forCascadeExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addCatchClause(LintRule linter, AstVisitor visitor) {
    _forCatchClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addClassDeclaration(LintRule linter, AstVisitor visitor) {
    _forClassDeclaration.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addClassTypeAlias(LintRule linter, AstVisitor visitor) {
    _forClassTypeAlias.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addComment(LintRule linter, AstVisitor visitor) {
    _forComment.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addCommentReference(LintRule linter, AstVisitor visitor) {
    _forCommentReference.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addCompilationUnit(LintRule linter, AstVisitor visitor) {
    _forCompilationUnit.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addConditionalExpression(LintRule linter, AstVisitor visitor) {
    _forConditionalExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addConfiguration(LintRule linter, AstVisitor visitor) {
    _forConfiguration.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addConstructorDeclaration(LintRule linter, AstVisitor visitor) {
    _forConstructorDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addConstructorFieldInitializer(LintRule linter, AstVisitor visitor) {
    _forConstructorFieldInitializer
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addConstructorName(LintRule linter, AstVisitor visitor) {
    _forConstructorName.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addConstructorReference(LintRule linter, AstVisitor visitor) {
    _forConstructorReference
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addContinueStatement(LintRule linter, AstVisitor visitor) {
    _forContinueStatement
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addDeclaredIdentifier(LintRule linter, AstVisitor visitor) {
    _forDeclaredIdentifier
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addDefaultFormalParameter(LintRule linter, AstVisitor visitor) {
    _forDefaultFormalParameter
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addDoStatement(LintRule linter, AstVisitor visitor) {
    _forDoStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addDottedName(LintRule linter, AstVisitor visitor) {
    _forDottedName.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addDoubleLiteral(LintRule linter, AstVisitor visitor) {
    _forDoubleLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addEmptyFunctionBody(LintRule linter, AstVisitor visitor) {
    _forEmptyFunctionBody
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addEmptyStatement(LintRule linter, AstVisitor visitor) {
    _forEmptyStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addEnumConstantDeclaration(LintRule linter, AstVisitor visitor) {
    _forEnumConstantDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addEnumDeclaration(LintRule linter, AstVisitor visitor) {
    _forEnumDeclaration.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addExportDirective(LintRule linter, AstVisitor visitor) {
    _forExportDirective.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addExpressionFunctionBody(LintRule linter, AstVisitor visitor) {
    _forExpressionFunctionBody
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addExpressionStatement(LintRule linter, AstVisitor visitor) {
    _forExpressionStatement
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addExtendsClause(LintRule linter, AstVisitor visitor) {
    _forExtendsClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addExtensionDeclaration(LintRule linter, AstVisitor visitor) {
    _forExtensionDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addExtensionOverride(LintRule linter, AstVisitor visitor) {
    _forExtensionOverride
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFieldDeclaration(LintRule linter, AstVisitor visitor) {
    _forFieldDeclaration.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFieldFormalParameter(LintRule linter, AstVisitor visitor) {
    _forFieldFormalParameter
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addForEachPartsWithDeclaration(LintRule linter, AstVisitor visitor) {
    _forForEachPartsWithDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addForEachPartsWithIdentifier(LintRule linter, AstVisitor visitor) {
    _forForEachPartsWithIdentifier
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addForElement(LintRule linter, AstVisitor visitor) {
    _forForElement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFormalParameterList(LintRule linter, AstVisitor visitor) {
    _forFormalParameterList
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addForPartsWithDeclarations(LintRule linter, AstVisitor visitor) {
    _forForPartsWithDeclarations
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addForPartsWithExpression(LintRule linter, AstVisitor visitor) {
    _forForPartsWithExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addForStatement(LintRule linter, AstVisitor visitor) {
    _forForStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFunctionDeclaration(LintRule linter, AstVisitor visitor) {
    _forFunctionDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFunctionDeclarationStatement(LintRule linter, AstVisitor visitor) {
    _forFunctionDeclarationStatement
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFunctionExpression(LintRule linter, AstVisitor visitor) {
    _forFunctionExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFunctionExpressionInvocation(LintRule linter, AstVisitor visitor) {
    _forFunctionExpressionInvocation
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFunctionTypeAlias(LintRule linter, AstVisitor visitor) {
    _forFunctionTypeAlias
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addFunctionTypedFormalParameter(LintRule linter, AstVisitor visitor) {
    _forFunctionTypedFormalParameter
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addGenericFunctionType(LintRule linter, AstVisitor visitor) {
    _forGenericFunctionType
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addGenericTypeAlias(LintRule linter, AstVisitor visitor) {
    _forGenericTypeAlias.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addHideCombinator(LintRule linter, AstVisitor visitor) {
    _forHideCombinator.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addIfElement(LintRule linter, AstVisitor visitor) {
    _forIfElement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addIfStatement(LintRule linter, AstVisitor visitor) {
    _forIfStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addImplementsClause(LintRule linter, AstVisitor visitor) {
    _forImplementsClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addImportDirective(LintRule linter, AstVisitor visitor) {
    _forImportDirective.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addIndexExpression(LintRule linter, AstVisitor visitor) {
    _forIndexExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addInstanceCreationExpression(LintRule linter, AstVisitor visitor) {
    _forInstanceCreationExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addIntegerLiteral(LintRule linter, AstVisitor visitor) {
    _forIntegerLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addInterpolationExpression(LintRule linter, AstVisitor visitor) {
    _forInterpolationExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addInterpolationString(LintRule linter, AstVisitor visitor) {
    _forInterpolationString
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addIsExpression(LintRule linter, AstVisitor visitor) {
    _forIsExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addLabel(LintRule linter, AstVisitor visitor) {
    _forLabel.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addLabeledStatement(LintRule linter, AstVisitor visitor) {
    _forLabeledStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addLibraryDirective(LintRule linter, AstVisitor visitor) {
    _forLibraryDirective.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addLibraryIdentifier(LintRule linter, AstVisitor visitor) {
    _forLibraryIdentifier
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addListLiteral(LintRule linter, AstVisitor visitor) {
    _forListLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addMapLiteralEntry(LintRule linter, AstVisitor visitor) {
    _forMapLiteralEntry.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addMethodDeclaration(LintRule linter, AstVisitor visitor) {
    _forMethodDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addMethodInvocation(LintRule linter, AstVisitor visitor) {
    _forMethodInvocation.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addMixinDeclaration(LintRule linter, AstVisitor visitor) {
    _forMixinDeclaration.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addNamedExpression(LintRule linter, AstVisitor visitor) {
    _forNamedExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addNamedType(LintRule linter, AstVisitor visitor) {
    _forNamedType.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addNativeClause(LintRule linter, AstVisitor visitor) {
    _forNativeClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addNativeFunctionBody(LintRule linter, AstVisitor visitor) {
    _forNativeFunctionBody
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addNullLiteral(LintRule linter, AstVisitor visitor) {
    _forNullLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addOnClause(LintRule linter, AstVisitor visitor) {
    _forOnClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addParenthesizedExpression(LintRule linter, AstVisitor visitor) {
    _forParenthesizedExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPartDirective(LintRule linter, AstVisitor visitor) {
    _forPartDirective.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPartOfDirective(LintRule linter, AstVisitor visitor) {
    _forPartOfDirective.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPostfixExpression(LintRule linter, AstVisitor visitor) {
    _forPostfixExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPrefixedIdentifier(LintRule linter, AstVisitor visitor) {
    _forPrefixedIdentifier
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPrefixExpression(LintRule linter, AstVisitor visitor) {
    _forPrefixExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPropertyAccess(LintRule linter, AstVisitor visitor) {
    _forPropertyAccess.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addRedirectingConstructorInvocation(
      LintRule linter, AstVisitor visitor) {
    _forRedirectingConstructorInvocation
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addRethrowExpression(LintRule linter, AstVisitor visitor) {
    _forRethrowExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addReturnStatement(LintRule linter, AstVisitor visitor) {
    _forReturnStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addScriptTag(LintRule linter, AstVisitor visitor) {
    _forScriptTag.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSetOrMapLiteral(LintRule linter, AstVisitor visitor) {
    _forSetOrMapLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addShowCombinator(LintRule linter, AstVisitor visitor) {
    _forShowCombinator.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSimpleFormalParameter(LintRule linter, AstVisitor visitor) {
    _forSimpleFormalParameter
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSimpleIdentifier(LintRule linter, AstVisitor visitor) {
    _forSimpleIdentifier.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSimpleStringLiteral(LintRule linter, AstVisitor visitor) {
    _forSimpleStringLiteral
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSpreadElement(LintRule linter, AstVisitor visitor) {
    _forSpreadElement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addStringInterpolation(LintRule linter, AstVisitor visitor) {
    _forStringInterpolation
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSuperConstructorInvocation(LintRule linter, AstVisitor visitor) {
    _forSuperConstructorInvocation
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSuperExpression(LintRule linter, AstVisitor visitor) {
    _forSuperExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchCase(LintRule linter, AstVisitor visitor) {
    _forSwitchCase.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchDefault(LintRule linter, AstVisitor visitor) {
    _forSwitchDefault.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchStatement(LintRule linter, AstVisitor visitor) {
    _forSwitchStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSymbolLiteral(LintRule linter, AstVisitor visitor) {
    _forSymbolLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addThisExpression(LintRule linter, AstVisitor visitor) {
    _forThisExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addThrowExpression(LintRule linter, AstVisitor visitor) {
    _forThrowExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addTopLevelVariableDeclaration(LintRule linter, AstVisitor visitor) {
    _forTopLevelVariableDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addTryStatement(LintRule linter, AstVisitor visitor) {
    _forTryStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addTypeArgumentList(LintRule linter, AstVisitor visitor) {
    _forTypeArgumentList.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  @Deprecated('Use addNamedType() instead')
  void addTypeName(LintRule linter, AstVisitor visitor) {
    addNamedType(linter, visitor);
  }

  void addTypeParameter(LintRule linter, AstVisitor visitor) {
    _forTypeParameter.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addTypeParameterList(LintRule linter, AstVisitor visitor) {
    _forTypeParameterList
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addVariableDeclaration(LintRule linter, AstVisitor visitor) {
    _forVariableDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addVariableDeclarationList(LintRule linter, AstVisitor visitor) {
    _forVariableDeclarationList
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addVariableDeclarationStatement(LintRule linter, AstVisitor visitor) {
    _forVariableDeclarationStatement
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addWhileStatement(LintRule linter, AstVisitor visitor) {
    _forWhileStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addWithClause(LintRule linter, AstVisitor visitor) {
    _forWithClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addYieldStatement(LintRule linter, AstVisitor visitor) {
    _forYieldStatement.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  /// Get the timer associated with the given [linter].
  Stopwatch? _getTimer(LintRule linter) {
    if (enableTiming) {
      return lintRegistry.getTimer(linter);
    } else {
      return null;
    }
  }
}

/// A single subscription for a node type, by the specified [linter].
class _Subscription<T> {
  final LintRule linter;
  final AstVisitor visitor;
  final Stopwatch? timer;

  _Subscription(this.linter, this.visitor, this.timer);
}
