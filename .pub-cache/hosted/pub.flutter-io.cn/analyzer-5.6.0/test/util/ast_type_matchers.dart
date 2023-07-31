// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

const isAdjacentStrings = TypeMatcher<AdjacentStrings>();

const isAnnotatedNode = TypeMatcher<AnnotatedNode>();

const isAnnotation = TypeMatcher<Annotation>();

const isArgumentList = TypeMatcher<ArgumentList>();

const isAsExpression = TypeMatcher<AsExpression>();

const isAssertInitializer = TypeMatcher<AssertInitializer>();

const isAssertion = TypeMatcher<Assertion>();

const isAssertStatement = TypeMatcher<AssertStatement>();

const isAssignmentExpression = TypeMatcher<AssignmentExpression>();

const isAwaitExpression = TypeMatcher<AwaitExpression>();

const isBinaryExpression = TypeMatcher<BinaryExpression>();

const isBlock = TypeMatcher<Block>();

const isBlockFunctionBody = TypeMatcher<BlockFunctionBody>();

const isBooleanLiteral = TypeMatcher<BooleanLiteral>();

const isBreakStatement = TypeMatcher<BreakStatement>();

const isCascadeExpression = TypeMatcher<CascadeExpression>();

const isCatchClause = TypeMatcher<CatchClause>();

const isClassDeclaration = TypeMatcher<ClassDeclaration>();

const isClassMember = TypeMatcher<ClassMember>();

const isClassTypeAlias = TypeMatcher<ClassTypeAlias>();

const isCombinator = TypeMatcher<Combinator>();

const isComment = TypeMatcher<Comment>();

const isCommentReference = TypeMatcher<CommentReference>();

const isCompilationUnit = TypeMatcher<CompilationUnit>();

const isCompilationUnitMember = TypeMatcher<CompilationUnitMember>();

const isConditionalExpression = TypeMatcher<ConditionalExpression>();

const isConfiguration = TypeMatcher<Configuration>();

const isConstructorDeclaration = TypeMatcher<ConstructorDeclaration>();

const isConstructorFieldInitializer =
    TypeMatcher<ConstructorFieldInitializer>();

const isConstructorInitializer = TypeMatcher<ConstructorInitializer>();

const isConstructorName = TypeMatcher<ConstructorName>();

const isConstructorReferenceNode = TypeMatcher<ConstructorReferenceNode>();

const isContinueStatement = TypeMatcher<ContinueStatement>();

const isDeclaration = TypeMatcher<Declaration>();

const isDeclaredIdentifier = TypeMatcher<DeclaredIdentifier>();

const isDefaultFormalParameter = TypeMatcher<DefaultFormalParameter>();

const isDirective = TypeMatcher<Directive>();

const isDoStatement = TypeMatcher<DoStatement>();

const isDottedName = TypeMatcher<DottedName>();

const isDoubleLiteral = TypeMatcher<DoubleLiteral>();

const isEmptyFunctionBody = TypeMatcher<EmptyFunctionBody>();

const isEmptyStatement = TypeMatcher<EmptyStatement>();

const isEnumConstantDeclaration = TypeMatcher<EnumConstantDeclaration>();

const isEnumDeclaration = TypeMatcher<EnumDeclaration>();

const isExportDirective = TypeMatcher<ExportDirective>();

const isExpression = TypeMatcher<Expression>();

const isExpressionFunctionBody = TypeMatcher<ExpressionFunctionBody>();

const isExpressionStatement = TypeMatcher<ExpressionStatement>();

const isExtendsClause = TypeMatcher<ExtendsClause>();

const isExtensionOverride = TypeMatcher<ExtensionOverride>();

const isFieldDeclaration = TypeMatcher<FieldDeclaration>();

const isFieldFormalParameter = TypeMatcher<FieldFormalParameter>();

const isFormalParameter = TypeMatcher<FormalParameter>();

const isFormalParameterList = TypeMatcher<FormalParameterList>();

const isFunctionBody = TypeMatcher<FunctionBody>();

const isFunctionDeclaration = TypeMatcher<FunctionDeclaration>();

const isFunctionDeclarationStatement =
    TypeMatcher<FunctionDeclarationStatement>();

const isFunctionExpression = TypeMatcher<FunctionExpression>();

const isFunctionExpressionInvocation =
    TypeMatcher<FunctionExpressionInvocation>();

const isFunctionReference = TypeMatcher<FunctionReference>();

const isFunctionTypeAlias = TypeMatcher<FunctionTypeAlias>();

const isFunctionTypedFormalParameter =
    TypeMatcher<FunctionTypedFormalParameter>();

const isGenericFunctionType = TypeMatcher<GenericFunctionType>();

const isGenericTypeAlias = TypeMatcher<GenericTypeAlias>();

const isHideCombinator = TypeMatcher<HideCombinator>();

const isIdentifier = TypeMatcher<Identifier>();

const isIfStatement = TypeMatcher<IfStatement>();

const isImplementsClause = TypeMatcher<ImplementsClause>();

const isImportDirective = TypeMatcher<ImportDirective>();

const isIndexExpression = TypeMatcher<IndexExpression>();

const isInstanceCreationExpression = TypeMatcher<InstanceCreationExpression>();

const isIntegerLiteral = TypeMatcher<IntegerLiteral>();

const isInterpolationElement = TypeMatcher<InterpolationElement>();

const isInterpolationExpression = TypeMatcher<InterpolationExpression>();

const isInterpolationString = TypeMatcher<InterpolationString>();

const isInvocationExpression = TypeMatcher<InvocationExpression>();

const isIsExpression = TypeMatcher<IsExpression>();

const isLabel = TypeMatcher<Label>();

const isLabeledStatement = TypeMatcher<LabeledStatement>();

const isLibraryDirective = TypeMatcher<LibraryDirective>();

const isLibraryIdentifier = TypeMatcher<LibraryIdentifier>();

const isListLiteral = TypeMatcher<ListLiteral>();

const isLiteral = TypeMatcher<Literal>();

const isMapLiteralEntry = TypeMatcher<MapLiteralEntry>();

const isMethodDeclaration = TypeMatcher<MethodDeclaration>();

const isMethodInvocation = TypeMatcher<MethodInvocation>();

const isMethodReferenceExpression = TypeMatcher<MethodReferenceExpression>();

const isMixinDeclaration = TypeMatcher<MixinDeclaration>();

const isNamedCompilationUnitMember = TypeMatcher<NamedCompilationUnitMember>();

const isNamedExpression = TypeMatcher<NamedExpression>();

const isNamedType = TypeMatcher<NamedType>();

const isNamespaceDirective = TypeMatcher<NamespaceDirective>();

const isNativeClause = TypeMatcher<NativeClause>();

const isNativeFunctionBody = TypeMatcher<NativeFunctionBody>();

const isNormalFormalParameter = TypeMatcher<NormalFormalParameter>();

const isNullLiteral = TypeMatcher<NullLiteral>();

const isOnClause = TypeMatcher<OnClause>();

const isParenthesizedExpression = TypeMatcher<ParenthesizedExpression>();

const isPartDirective = TypeMatcher<PartDirective>();

const isPartOfDirective = TypeMatcher<PartOfDirective>();

const isPostfixExpression = TypeMatcher<PostfixExpression>();

const isPrefixedIdentifier = TypeMatcher<PrefixedIdentifier>();

const isPrefixExpression = TypeMatcher<PrefixExpression>();

const isPropertyAccess = TypeMatcher<PropertyAccess>();

const isRedirectingConstructorInvocation =
    TypeMatcher<RedirectingConstructorInvocation>();

const isRethrowExpression = TypeMatcher<RethrowExpression>();

const isReturnStatement = TypeMatcher<ReturnStatement>();

const isScriptTag = TypeMatcher<ScriptTag>();

const isSetOrMapLiteral = TypeMatcher<SetOrMapLiteral>();

const isShowCombinator = TypeMatcher<ShowCombinator>();

const isSimpleFormalParameter = TypeMatcher<SimpleFormalParameter>();

const isSimpleIdentifier = TypeMatcher<SimpleIdentifier>();

const isSimpleStringLiteral = TypeMatcher<SimpleStringLiteral>();

const isSingleStringLiteral = TypeMatcher<SingleStringLiteral>();

const isStatement = TypeMatcher<Statement>();

const isStringInterpolation = TypeMatcher<StringInterpolation>();

const isStringLiteral = TypeMatcher<StringLiteral>();

const isSuperConstructorInvocation = TypeMatcher<SuperConstructorInvocation>();

const isSuperExpression = TypeMatcher<SuperExpression>();

const isSwitchCase = TypeMatcher<SwitchCase>();

const isSwitchDefault = TypeMatcher<SwitchDefault>();

const isSwitchMember = TypeMatcher<SwitchMember>();

const isSwitchStatement = TypeMatcher<SwitchStatement>();

const isSymbolLiteral = TypeMatcher<SymbolLiteral>();

const isThisExpression = TypeMatcher<ThisExpression>();

const isThrowExpression = TypeMatcher<ThrowExpression>();

const isTopLevelVariableDeclaration =
    TypeMatcher<TopLevelVariableDeclaration>();

const isTryStatement = TypeMatcher<TryStatement>();

const isTypeAlias = TypeMatcher<TypeAlias>();

const isTypeAnnotation = TypeMatcher<TypeAnnotation>();

const isTypeArgumentList = TypeMatcher<TypeArgumentList>();

const isTypedLiteral = TypeMatcher<TypedLiteral>();

const isTypeParameter = TypeMatcher<TypeParameter>();

const isTypeParameterList = TypeMatcher<TypeParameterList>();

const isUriBasedDirective = TypeMatcher<UriBasedDirective>();

const isVariableDeclaration = TypeMatcher<VariableDeclaration>();

const isVariableDeclarationList = TypeMatcher<VariableDeclarationList>();

const isVariableDeclarationStatement =
    TypeMatcher<VariableDeclarationStatement>();

const isWhileStatement = TypeMatcher<WhileStatement>();

const isWithClause = TypeMatcher<WithClause>();

const isYieldStatement = TypeMatcher<YieldStatement>();

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isForEachStatement = predicate(
    (Object o) => o is ForStatement && o.forLoopParts is ForEachParts);

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isForStatement =
    predicate((Object o) => o is ForStatement && o.forLoopParts is ForParts);

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isMapLiteral =
    predicate((Object o) => o is SetOrMapLiteral && o.isMap);

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isSetLiteral =
    predicate((Object o) => o is SetOrMapLiteral && o.isSet);
