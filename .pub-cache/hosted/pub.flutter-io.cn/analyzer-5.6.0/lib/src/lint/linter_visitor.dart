// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/services/lint.dart';

/// The type of the function that handles exceptions in lints.
///
/// Returns `true` if the exception was fully handled, or `false` if
/// the exception should be rethrown.
typedef LintRuleExceptionHandler = bool Function(
    AstNode node, LintRule linter, Object exception, StackTrace stackTrace);

/// The AST visitor that runs handlers for nodes from the [registry].
class LinterVisitor implements AstVisitor<void> {
  final NodeLintRegistry registry;
  final LintRuleExceptionHandler exceptionHandler;

  LinterVisitor(this.registry, [LintRuleExceptionHandler? exceptionHandler])
      : exceptionHandler = exceptionHandler ??
            LinterExceptionHandler(propagateExceptions: true).logException;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _runSubscriptions(node, registry._forAdjacentStrings);
    node.visitChildren(this);
  }

  @override
  void visitAnnotation(Annotation node) {
    _runSubscriptions(node, registry._forAnnotation);
    node.visitChildren(this);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _runSubscriptions(node, registry._forArgumentList);
    node.visitChildren(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _runSubscriptions(node, registry._forAsExpression);
    node.visitChildren(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _runSubscriptions(node, registry._forAssertInitializer);
    node.visitChildren(this);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _runSubscriptions(node, registry._forAssertStatement);
    node.visitChildren(this);
  }

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    _runSubscriptions(node, registry._forAssignedVariablePattern);
    node.visitChildren(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _runSubscriptions(node, registry._forAssignmentExpression);
    node.visitChildren(this);
  }

  @override
  void visitAugmentationImportDirective(AugmentationImportDirective node) {
    _runSubscriptions(node, registry._forAugmentationImportDirective);
    node.visitChildren(this);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _runSubscriptions(node, registry._forAwaitExpression);
    node.visitChildren(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _runSubscriptions(node, registry._forBinaryExpression);
    node.visitChildren(this);
  }

  @override
  void visitBlock(Block node) {
    _runSubscriptions(node, registry._forBlock);
    node.visitChildren(this);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _runSubscriptions(node, registry._forBlockFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _runSubscriptions(node, registry._forBooleanLiteral);
    node.visitChildren(this);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _runSubscriptions(node, registry._forBreakStatement);
    node.visitChildren(this);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _runSubscriptions(node, registry._forCascadeExpression);
    node.visitChildren(this);
  }

  @override
  void visitCaseClause(CaseClause node) {
    _runSubscriptions(node, registry._forCaseClause);
    node.visitChildren(this);
  }

  @override
  void visitCastPattern(CastPattern node) {
    _runSubscriptions(node, registry._forCastPattern);
    node.visitChildren(this);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _runSubscriptions(node, registry._forCatchClause);
    node.visitChildren(this);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    _runSubscriptions(node, registry._forCatchClauseParameter);
    node.visitChildren(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _runSubscriptions(node, registry._forClassDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _runSubscriptions(node, registry._forClassTypeAlias);
    node.visitChildren(this);
  }

  @override
  void visitComment(Comment node) {
    _runSubscriptions(node, registry._forComment);
    node.visitChildren(this);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _runSubscriptions(node, registry._forCommentReference);
    node.visitChildren(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _runSubscriptions(node, registry._forCompilationUnit);
    node.visitChildren(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _runSubscriptions(node, registry._forConditionalExpression);
    node.visitChildren(this);
  }

  @override
  void visitConfiguration(Configuration node) {
    _runSubscriptions(node, registry._forConfiguration);
    node.visitChildren(this);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    _runSubscriptions(node, registry._forConstantPattern);
    node.visitChildren(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _runSubscriptions(node, registry._forConstructorDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _runSubscriptions(node, registry._forConstructorFieldInitializer);
    node.visitChildren(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _runSubscriptions(node, registry._forConstructorName);
    node.visitChildren(this);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _runSubscriptions(node, registry._forConstructorReference);
    node.visitChildren(this);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    _runSubscriptions(node, registry._forConstructorSelector);
    node.visitChildren(this);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _runSubscriptions(node, registry._forContinueStatement);
    node.visitChildren(this);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _runSubscriptions(node, registry._forDeclaredIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _runSubscriptions(node, registry._forDeclaredVariablePattern);
    node.visitChildren(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _runSubscriptions(node, registry._forDefaultFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _runSubscriptions(node, registry._forDoStatement);
    node.visitChildren(this);
  }

  @override
  void visitDottedName(DottedName node) {
    _runSubscriptions(node, registry._forDottedName);
    node.visitChildren(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _runSubscriptions(node, registry._forDoubleLiteral);
    node.visitChildren(this);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _runSubscriptions(node, registry._forEmptyFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    _runSubscriptions(node, registry._forEmptyStatement);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    _runSubscriptions(node, registry._forEnumConstantArguments);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _runSubscriptions(node, registry._forEnumConstantDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _runSubscriptions(node, registry._forEnumDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _runSubscriptions(node, registry._forExportDirective);
    node.visitChildren(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _runSubscriptions(node, registry._forExpressionFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _runSubscriptions(node, registry._forExpressionStatement);
    node.visitChildren(this);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _runSubscriptions(node, registry._forExtendsClause);
    node.visitChildren(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _runSubscriptions(node, registry._forExtensionDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _runSubscriptions(node, registry._forExtensionOverride);
    node.visitChildren(this);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _runSubscriptions(node, registry._forFieldDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _runSubscriptions(node, registry._forFieldFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _runSubscriptions(node, registry._forForEachPartsWithDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _runSubscriptions(node, registry._forForEachPartsWithIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    _runSubscriptions(node, registry._forForEachPartsWithPattern);
    node.visitChildren(this);
  }

  @override
  void visitForElement(ForElement node) {
    _runSubscriptions(node, registry._forForElement);
    node.visitChildren(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _runSubscriptions(node, registry._forFormalParameterList);
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _runSubscriptions(node, registry._forForPartsWithDeclarations);
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _runSubscriptions(node, registry._forForPartsWithExpression);
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    _runSubscriptions(node, registry._forForPartsWithPattern);
    node.visitChildren(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    _runSubscriptions(node, registry._forForStatement);
    node.visitChildren(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _runSubscriptions(node, registry._forFunctionDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _runSubscriptions(node, registry._forFunctionDeclarationStatement);
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _runSubscriptions(node, registry._forFunctionExpression);
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _runSubscriptions(node, registry._forFunctionExpressionInvocation);
    node.visitChildren(this);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _runSubscriptions(node, registry._forFunctionReference);
    node.visitChildren(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _runSubscriptions(node, registry._forFunctionTypeAlias);
    node.visitChildren(this);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _runSubscriptions(node, registry._forFunctionTypedFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _runSubscriptions(node, registry._forGenericFunctionType);
    node.visitChildren(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _runSubscriptions(node, registry._forGenericTypeAlias);
    node.visitChildren(this);
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    _runSubscriptions(node, registry._forCaseClause);
    node.visitChildren(this);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _runSubscriptions(node, registry._forHideCombinator);
    node.visitChildren(this);
  }

  @override
  void visitIfElement(IfElement node) {
    _runSubscriptions(node, registry._forIfElement);
    node.visitChildren(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _runSubscriptions(node, registry._forIfStatement);
    node.visitChildren(this);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _runSubscriptions(node, registry._forImplementsClause);
    node.visitChildren(this);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _runSubscriptions(node, registry._forImplicitCallReference);
    node.visitChildren(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _runSubscriptions(node, registry._forImportDirective);
    node.visitChildren(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _runSubscriptions(node, registry._forIndexExpression);
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _runSubscriptions(node, registry._forInstanceCreationExpression);
    node.visitChildren(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _runSubscriptions(node, registry._forIntegerLiteral);
    node.visitChildren(this);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _runSubscriptions(node, registry._forInterpolationExpression);
    node.visitChildren(this);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _runSubscriptions(node, registry._forInterpolationString);
    node.visitChildren(this);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _runSubscriptions(node, registry._forIsExpression);
    node.visitChildren(this);
  }

  @override
  void visitLabel(Label node) {
    _runSubscriptions(node, registry._forLabel);
    node.visitChildren(this);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _runSubscriptions(node, registry._forLabeledStatement);
    node.visitChildren(this);
  }

  @override
  void visitLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    _runSubscriptions(node, registry._forLibraryAugmentationDirective);
    node.visitChildren(this);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _runSubscriptions(node, registry._forLibraryDirective);
    node.visitChildren(this);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _runSubscriptions(node, registry._forLibraryIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _runSubscriptions(node, registry._forListLiteral);
    node.visitChildren(this);
  }

  @override
  void visitListPattern(ListPattern node) {
    _runSubscriptions(node, registry._forListPattern);
    node.visitChildren(this);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    _runSubscriptions(node, registry._forLogicalAndPattern);
    node.visitChildren(this);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    _runSubscriptions(node, registry._forLogicalOrPattern);
    node.visitChildren(this);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _runSubscriptions(node, registry._forMapLiteralEntry);
    node.visitChildren(this);
  }

  @override
  void visitMapPattern(MapPattern node) {
    _runSubscriptions(node, registry._forMapPattern);
    node.visitChildren(this);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    _runSubscriptions(node, registry._forMapPatternEntry);
    node.visitChildren(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _runSubscriptions(node, registry._forMethodDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _runSubscriptions(node, registry._forMethodInvocation);
    node.visitChildren(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _runSubscriptions(node, registry._forMixinDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _runSubscriptions(node, registry._forNamedExpression);
    node.visitChildren(this);
  }

  @override
  void visitNamedType(NamedType node) {
    _runSubscriptions(node, registry._forNamedType);
    node.visitChildren(this);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _runSubscriptions(node, registry._forNativeClause);
    node.visitChildren(this);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _runSubscriptions(node, registry._forNativeFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    _runSubscriptions(node, registry._forNullAssertPattern);
    node.visitChildren(this);
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    _runSubscriptions(node, registry._forNullCheckPattern);
    node.visitChildren(this);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _runSubscriptions(node, registry._forNullLiteral);
    node.visitChildren(this);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    _runSubscriptions(node, registry._forObjectPattern);
    node.visitChildren(this);
  }

  @override
  void visitOnClause(OnClause node) {
    _runSubscriptions(node, registry._forOnClause);
    node.visitChildren(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _runSubscriptions(node, registry._forParenthesizedExpression);
    node.visitChildren(this);
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    _runSubscriptions(node, registry._forParenthesizedPattern);
    node.visitChildren(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _runSubscriptions(node, registry._forPartDirective);
    node.visitChildren(this);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _runSubscriptions(node, registry._forPartOfDirective);
    node.visitChildren(this);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    _runSubscriptions(node, registry._forPatternAssignment);
    node.visitChildren(this);
  }

  @override
  void visitPatternField(PatternField node) {
    _runSubscriptions(node, registry._forPatternField);
    node.visitChildren(this);
  }

  @override
  void visitPatternFieldName(PatternFieldName node) {
    _runSubscriptions(node, registry._forPatternFieldName);
    node.visitChildren(this);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _runSubscriptions(node, registry._forPatternVariableDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    _runSubscriptions(node, registry._forPatternVariableDeclarationStatement);
    node.visitChildren(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _runSubscriptions(node, registry._forPostfixExpression);
    node.visitChildren(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _runSubscriptions(node, registry._forPrefixedIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _runSubscriptions(node, registry._forPrefixExpression);
    node.visitChildren(this);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _runSubscriptions(node, registry._forPropertyAccess);
    node.visitChildren(this);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _runSubscriptions(node, registry._forRecordLiterals);
    node.visitChildren(this);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    _runSubscriptions(node, registry._forRecordPattern);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _runSubscriptions(node, registry._forRecordTypeAnnotation);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
      RecordTypeAnnotationNamedField node) {
    _runSubscriptions(node, registry._forRecordTypeAnnotationNamedField);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
      RecordTypeAnnotationNamedFields node) {
    _runSubscriptions(node, registry._forRecordTypeAnnotationNamedFields);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
      RecordTypeAnnotationPositionalField node) {
    _runSubscriptions(node, registry._forRecordTypeAnnotationPositionalField);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _runSubscriptions(node, registry._forRedirectingConstructorInvocation);
    node.visitChildren(this);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    _runSubscriptions(node, registry._forRelationalPattern);
    node.visitChildren(this);
  }

  @override
  void visitRestPatternElement(RestPatternElement node) {
    _runSubscriptions(node, registry._forRestPatternElement);
    node.visitChildren(this);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _runSubscriptions(node, registry._forRethrowExpression);
    node.visitChildren(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _runSubscriptions(node, registry._forReturnStatement);
    node.visitChildren(this);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    _runSubscriptions(node, registry._forScriptTag);
    node.visitChildren(this);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _runSubscriptions(node, registry._forSetOrMapLiteral);
    node.visitChildren(this);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _runSubscriptions(node, registry._forShowCombinator);
    node.visitChildren(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _runSubscriptions(node, registry._forSimpleFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _runSubscriptions(node, registry._forSimpleIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _runSubscriptions(node, registry._forSimpleStringLiteral);
    node.visitChildren(this);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _runSubscriptions(node, registry._forSpreadElement);
    node.visitChildren(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _runSubscriptions(node, registry._forStringInterpolation);
    node.visitChildren(this);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _runSubscriptions(node, registry._forSuperConstructorInvocation);
    node.visitChildren(this);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _runSubscriptions(node, registry._forSuperExpression);
    node.visitChildren(this);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _runSubscriptions(node, registry._forSuperFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _runSubscriptions(node, registry._forSwitchCase);
    node.visitChildren(this);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _runSubscriptions(node, registry._forSwitchDefault);
    node.visitChildren(this);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _runSubscriptions(node, registry._forSwitchExpression);
    node.visitChildren(this);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    _runSubscriptions(node, registry._forSwitchExpressionCase);
    node.visitChildren(this);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _runSubscriptions(node, registry._forSwitchPatternCase);
    node.visitChildren(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _runSubscriptions(node, registry._forSwitchStatement);
    node.visitChildren(this);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _runSubscriptions(node, registry._forSymbolLiteral);
    node.visitChildren(this);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _runSubscriptions(node, registry._forThisExpression);
    node.visitChildren(this);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _runSubscriptions(node, registry._forThrowExpression);
    node.visitChildren(this);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _runSubscriptions(node, registry._forTopLevelVariableDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _runSubscriptions(node, registry._forTryStatement);
    node.visitChildren(this);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _runSubscriptions(node, registry._forTypeArgumentList);
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _runSubscriptions(node, registry._forTypeLiteral);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _runSubscriptions(node, registry._forTypeParameter);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _runSubscriptions(node, registry._forTypeParameterList);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _runSubscriptions(node, registry._forVariableDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _runSubscriptions(node, registry._forVariableDeclarationList);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _runSubscriptions(node, registry._forVariableDeclarationStatement);
    node.visitChildren(this);
  }

  @override
  void visitWhenClause(WhenClause node) {
    _runSubscriptions(node, registry._forWhenClause);
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _runSubscriptions(node, registry._forWhileStatement);
    node.visitChildren(this);
  }

  @override
  void visitWildcardPattern(WildcardPattern node) {
    _runSubscriptions(node, registry._forWildcardPattern);
    node.visitChildren(this);
  }

  @override
  void visitWithClause(WithClause node) {
    _runSubscriptions(node, registry._forWithClause);
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _runSubscriptions(node, registry._forYieldStatement);
    node.visitChildren(this);
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
        if (!exceptionHandler(
            node, subscription.linter, exception, stackTrace)) {
          rethrow;
        }
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
  final List<_Subscription<AssignedVariablePattern>>
      _forAssignedVariablePattern = [];
  final List<_Subscription<AssignmentExpression>> _forAssignmentExpression = [];
  final List<_Subscription<AugmentationImportDirective>>
      _forAugmentationImportDirective = [];
  final List<_Subscription<AwaitExpression>> _forAwaitExpression = [];
  final List<_Subscription<BinaryExpression>> _forBinaryExpression = [];
  final List<_Subscription<Block>> _forBlock = [];
  final List<_Subscription<BlockFunctionBody>> _forBlockFunctionBody = [];
  final List<_Subscription<BooleanLiteral>> _forBooleanLiteral = [];
  final List<_Subscription<BreakStatement>> _forBreakStatement = [];
  final List<_Subscription<CascadeExpression>> _forCascadeExpression = [];
  final List<_Subscription<CaseClause>> _forCaseClause = [];
  final List<_Subscription<CastPattern>> _forCastPattern = [];
  final List<_Subscription<CatchClause>> _forCatchClause = [];
  final List<_Subscription<CatchClauseParameter>> _forCatchClauseParameter = [];
  final List<_Subscription<ClassDeclaration>> _forClassDeclaration = [];
  final List<_Subscription<ClassTypeAlias>> _forClassTypeAlias = [];
  final List<_Subscription<Comment>> _forComment = [];
  final List<_Subscription<CommentReference>> _forCommentReference = [];
  final List<_Subscription<CompilationUnit>> _forCompilationUnit = [];
  final List<_Subscription<ConditionalExpression>> _forConditionalExpression =
      [];
  final List<_Subscription<Configuration>> _forConfiguration = [];
  final List<_Subscription<ConstantPattern>> _forConstantPattern = [];
  final List<_Subscription<ConstructorDeclaration>> _forConstructorDeclaration =
      [];
  final List<_Subscription<ConstructorFieldInitializer>>
      _forConstructorFieldInitializer = [];
  final List<_Subscription<ConstructorName>> _forConstructorName = [];
  final List<_Subscription<ConstructorReference>> _forConstructorReference = [];
  final List<_Subscription<ConstructorSelector>> _forConstructorSelector = [];
  final List<_Subscription<ContinueStatement>> _forContinueStatement = [];
  final List<_Subscription<DeclaredIdentifier>> _forDeclaredIdentifier = [];
  final List<_Subscription<DeclaredVariablePattern>>
      _forDeclaredVariablePattern = [];
  final List<_Subscription<DefaultFormalParameter>> _forDefaultFormalParameter =
      [];
  final List<_Subscription<DoStatement>> _forDoStatement = [];
  final List<_Subscription<DottedName>> _forDottedName = [];
  final List<_Subscription<DoubleLiteral>> _forDoubleLiteral = [];
  final List<_Subscription<EmptyFunctionBody>> _forEmptyFunctionBody = [];
  final List<_Subscription<EmptyStatement>> _forEmptyStatement = [];
  final List<_Subscription<EnumConstantArguments>> _forEnumConstantArguments =
      [];
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
  final List<_Subscription<ObjectPattern>> _forObjectPattern = [];
  final List<_Subscription<FieldDeclaration>> _forFieldDeclaration = [];
  final List<_Subscription<FieldFormalParameter>> _forFieldFormalParameter = [];
  final List<_Subscription<ForEachPartsWithDeclaration>>
      _forForEachPartsWithDeclaration = [];
  final List<_Subscription<ForEachPartsWithIdentifier>>
      _forForEachPartsWithIdentifier = [];
  final List<_Subscription<ForEachPartsWithPattern>>
      _forForEachPartsWithPattern = [];
  final List<_Subscription<ForElement>> _forForElement = [];
  final List<_Subscription<FormalParameterList>> _forFormalParameterList = [];
  final List<_Subscription<ForPartsWithDeclarations>>
      _forForPartsWithDeclarations = [];
  final List<_Subscription<ForPartsWithExpression>> _forForPartsWithExpression =
      [];
  final List<_Subscription<ForPartsWithPattern>> _forForPartsWithPattern = [];
  final List<_Subscription<ForStatement>> _forForStatement = [];
  final List<_Subscription<FunctionDeclaration>> _forFunctionDeclaration = [];
  final List<_Subscription<FunctionDeclarationStatement>>
      _forFunctionDeclarationStatement = [];
  final List<_Subscription<FunctionExpression>> _forFunctionExpression = [];
  final List<_Subscription<FunctionExpressionInvocation>>
      _forFunctionExpressionInvocation = [];
  final List<_Subscription<FunctionReference>> _forFunctionReference = [];
  final List<_Subscription<FunctionTypeAlias>> _forFunctionTypeAlias = [];
  final List<_Subscription<FunctionTypedFormalParameter>>
      _forFunctionTypedFormalParameter = [];
  final List<_Subscription<GenericFunctionType>> _forGenericFunctionType = [];
  final List<_Subscription<GenericTypeAlias>> _forGenericTypeAlias = [];
  final List<_Subscription<GuardedPattern>> _forGuardedPattern = [];
  final List<_Subscription<HideCombinator>> _forHideCombinator = [];
  final List<_Subscription<IfElement>> _forIfElement = [];
  final List<_Subscription<IfStatement>> _forIfStatement = [];
  final List<_Subscription<ImplementsClause>> _forImplementsClause = [];
  final List<_Subscription<ImplicitCallReference>> _forImplicitCallReference =
      [];
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
  final List<_Subscription<LibraryAugmentationDirective>>
      _forLibraryAugmentationDirective = [];
  final List<_Subscription<LibraryDirective>> _forLibraryDirective = [];
  final List<_Subscription<LibraryIdentifier>> _forLibraryIdentifier = [];
  final List<_Subscription<ListLiteral>> _forListLiteral = [];
  final List<_Subscription<ListPattern>> _forListPattern = [];
  final List<_Subscription<LogicalAndPattern>> _forLogicalAndPattern = [];
  final List<_Subscription<LogicalOrPattern>> _forLogicalOrPattern = [];
  final List<_Subscription<MapLiteralEntry>> _forMapLiteralEntry = [];
  final List<_Subscription<MapPatternEntry>> _forMapPatternEntry = [];
  final List<_Subscription<MapPattern>> _forMapPattern = [];
  final List<_Subscription<MethodDeclaration>> _forMethodDeclaration = [];
  final List<_Subscription<MethodInvocation>> _forMethodInvocation = [];
  final List<_Subscription<MixinDeclaration>> _forMixinDeclaration = [];
  final List<_Subscription<NamedExpression>> _forNamedExpression = [];
  final List<_Subscription<NamedType>> _forNamedType = [];
  final List<_Subscription<NativeClause>> _forNativeClause = [];
  final List<_Subscription<NativeFunctionBody>> _forNativeFunctionBody = [];
  final List<_Subscription<NullAssertPattern>> _forNullAssertPattern = [];
  final List<_Subscription<NullCheckPattern>> _forNullCheckPattern = [];
  final List<_Subscription<NullLiteral>> _forNullLiteral = [];
  final List<_Subscription<OnClause>> _forOnClause = [];
  final List<_Subscription<ParenthesizedExpression>>
      _forParenthesizedExpression = [];
  final List<_Subscription<ParenthesizedPattern>> _forParenthesizedPattern = [];
  final List<_Subscription<PartDirective>> _forPartDirective = [];
  final List<_Subscription<PartOfDirective>> _forPartOfDirective = [];
  final List<_Subscription<PatternAssignment>> _forPatternAssignment = [];
  final List<_Subscription<PatternVariableDeclaration>>
      _forPatternVariableDeclaration = [];
  final List<_Subscription<PatternVariableDeclarationStatement>>
      _forPatternVariableDeclarationStatement = [];
  final List<_Subscription<PostfixExpression>> _forPostfixExpression = [];
  final List<_Subscription<PrefixedIdentifier>> _forPrefixedIdentifier = [];
  final List<_Subscription<PrefixExpression>> _forPrefixExpression = [];
  final List<_Subscription<PropertyAccess>> _forPropertyAccess = [];
  final List<_Subscription<RecordLiteral>> _forRecordLiterals = [];
  final List<_Subscription<PatternField>> _forPatternField = [];
  final List<_Subscription<PatternFieldName>> _forPatternFieldName = [];
  final List<_Subscription<RecordPattern>> _forRecordPattern = [];
  final List<_Subscription<RecordTypeAnnotation>> _forRecordTypeAnnotation = [];
  final List<_Subscription<RecordTypeAnnotationNamedField>>
      _forRecordTypeAnnotationNamedField = [];
  final List<_Subscription<RecordTypeAnnotationNamedFields>>
      _forRecordTypeAnnotationNamedFields = [];
  final List<_Subscription<RecordTypeAnnotationPositionalField>>
      _forRecordTypeAnnotationPositionalField = [];
  final List<_Subscription<RedirectingConstructorInvocation>>
      _forRedirectingConstructorInvocation = [];
  final List<_Subscription<RelationalPattern>> _forRelationalPattern = [];
  final List<_Subscription<RestPatternElement>> _forRestPatternElement = [];
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
  final List<_Subscription<SuperFormalParameter>> _forSuperFormalParameter = [];
  final List<_Subscription<SwitchCase>> _forSwitchCase = [];
  final List<_Subscription<SwitchDefault>> _forSwitchDefault = [];
  final List<_Subscription<SwitchExpressionCase>> _forSwitchExpressionCase = [];
  final List<_Subscription<SwitchExpression>> _forSwitchExpression = [];
  final List<_Subscription<SwitchPatternCase>> _forSwitchPatternCase = [];
  final List<_Subscription<SwitchStatement>> _forSwitchStatement = [];
  final List<_Subscription<SymbolLiteral>> _forSymbolLiteral = [];
  final List<_Subscription<ThisExpression>> _forThisExpression = [];
  final List<_Subscription<ThrowExpression>> _forThrowExpression = [];
  final List<_Subscription<TopLevelVariableDeclaration>>
      _forTopLevelVariableDeclaration = [];
  final List<_Subscription<TryStatement>> _forTryStatement = [];
  final List<_Subscription<TypeArgumentList>> _forTypeArgumentList = [];
  final List<_Subscription<TypeLiteral>> _forTypeLiteral = [];
  final List<_Subscription<TypeParameter>> _forTypeParameter = [];
  final List<_Subscription<TypeParameterList>> _forTypeParameterList = [];
  final List<_Subscription<VariableDeclaration>> _forVariableDeclaration = [];
  final List<_Subscription<VariableDeclarationList>>
      _forVariableDeclarationList = [];
  final List<_Subscription<VariableDeclarationStatement>>
      _forVariableDeclarationStatement = [];
  final List<_Subscription<WhenClause>> _forWhenClause = [];
  final List<_Subscription<WhileStatement>> _forWhileStatement = [];
  final List<_Subscription<WildcardPattern>> _forWildcardPattern = [];
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

  void addAssignedVariablePattern(LintRule linter, AstVisitor visitor) {
    _forAssignedVariablePattern
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAssignmentExpression(LintRule linter, AstVisitor visitor) {
    _forAssignmentExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addAugmentationImportDirective(LintRule linter, AstVisitor visitor) {
    _forAugmentationImportDirective
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

  void addCaseClause(LintRule linter, AstVisitor visitor) {
    _forCaseClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addCastPattern(LintRule linter, AstVisitor visitor) {
    _forCastPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addCatchClause(LintRule linter, AstVisitor visitor) {
    _forCatchClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addCatchClauseParameter(LintRule linter, AstVisitor visitor) {
    _forCatchClauseParameter
        .add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addConstantPattern(LintRule linter, AstVisitor visitor) {
    _forConstantPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addConstructorSelector(LintRule linter, AstVisitor visitor) {
    _forConstructorSelector
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

  void addDeclaredVariablePattern(LintRule linter, AstVisitor visitor) {
    _forDeclaredVariablePattern
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

  void addEnumConstantArguments(LintRule linter, AstVisitor visitor) {
    _forEnumConstantArguments
        .add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addForEachPartsWithPattern(LintRule linter, AstVisitor visitor) {
    _forForEachPartsWithPattern
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

  void addForPartsWithPattern(LintRule linter, AstVisitor visitor) {
    _forForPartsWithPattern
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

  void addFunctionReference(LintRule linter, AstVisitor visitor) {
    _forFunctionReference
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

  void addGuardedPattern(LintRule linter, AstVisitor visitor) {
    _forGuardedPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addImplicitCallReference(LintRule linter, AstVisitor visitor) {
    _forImplicitCallReference
        .add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addLibraryAugmentationDirective(LintRule linter, AstVisitor visitor) {
    _forLibraryAugmentationDirective
        .add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addListPattern(LintRule linter, AstVisitor visitor) {
    _forListPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addLogicalAndPattern(LintRule linter, AstVisitor visitor) {
    _forLogicalAndPattern
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addLogicalOrPattern(LintRule linter, AstVisitor visitor) {
    _forLogicalOrPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addMapLiteralEntry(LintRule linter, AstVisitor visitor) {
    _forMapLiteralEntry.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addMapPattern(LintRule linter, AstVisitor visitor) {
    _forMapPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addMapPatternEntry(LintRule linter, AstVisitor visitor) {
    _forMapPatternEntry.add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addNullAssertPattern(LintRule linter, AstVisitor visitor) {
    _forNullAssertPattern
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addNullCheckPattern(LintRule linter, AstVisitor visitor) {
    _forNullCheckPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addNullLiteral(LintRule linter, AstVisitor visitor) {
    _forNullLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addObjectPattern(LintRule linter, AstVisitor visitor) {
    _forObjectPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addOnClause(LintRule linter, AstVisitor visitor) {
    _forOnClause.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addParenthesizedExpression(LintRule linter, AstVisitor visitor) {
    _forParenthesizedExpression
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addParenthesizedPattern(LintRule linter, AstVisitor visitor) {
    _forParenthesizedPattern
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPartDirective(LintRule linter, AstVisitor visitor) {
    _forPartDirective.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPartOfDirective(LintRule linter, AstVisitor visitor) {
    _forPartOfDirective.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPatternAssignment(LintRule linter, AstVisitor visitor) {
    _forPatternAssignment
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPatternField(LintRule linter, AstVisitor visitor) {
    _forPatternField.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPatternFieldName(LintRule linter, AstVisitor visitor) {
    _forPatternFieldName.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPatternVariableDeclaration(LintRule linter, AstVisitor visitor) {
    _forPatternVariableDeclaration
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addPatternVariableDeclarationStatement(
      LintRule linter, AstVisitor visitor) {
    _forPatternVariableDeclarationStatement
        .add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addRecordLiteral(LintRule linter, AstVisitor visitor) {
    _forRecordLiterals.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addRecordPattern(LintRule linter, AstVisitor visitor) {
    _forRecordPattern.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  @Deprecated('Use addPatternField instead')
  void addRecordPatternField(LintRule linter, AstVisitor visitor) {
    _forPatternField.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addRecordTypeAnnotation(LintRule linter, AstVisitor visitor) {
    _forRecordTypeAnnotation
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addRedirectingConstructorInvocation(
      LintRule linter, AstVisitor visitor) {
    _forRedirectingConstructorInvocation
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addRelationalPattern(LintRule linter, AstVisitor visitor) {
    _forRelationalPattern
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addRestPatternElement(LintRule linter, AstVisitor visitor) {
    _forRestPatternElement
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

  void addSuperFormalParameter(LintRule linter, AstVisitor visitor) {
    _forSuperFormalParameter
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchCase(LintRule linter, AstVisitor visitor) {
    _forSwitchCase.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchDefault(LintRule linter, AstVisitor visitor) {
    _forSwitchDefault.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchExpression(LintRule linter, AstVisitor visitor) {
    _forSwitchExpression.add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchExpressionCase(LintRule linter, AstVisitor visitor) {
    _forSwitchExpressionCase
        .add(_Subscription(linter, visitor, _getTimer(linter)));
  }

  void addSwitchPatternCase(LintRule linter, AstVisitor visitor) {
    _forSwitchPatternCase
        .add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addTypeLiteral(LintRule linter, AstVisitor visitor) {
    _forTypeLiteral.add(_Subscription(linter, visitor, _getTimer(linter)));
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

  void addWhenClause(LintRule linter, AstVisitor visitor) {
    _forWhenClause.add(_Subscription(linter, visitor, _getTimer(linter)));
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
