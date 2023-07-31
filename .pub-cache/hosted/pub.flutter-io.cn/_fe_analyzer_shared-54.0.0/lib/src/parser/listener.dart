// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.listener;

import '../experiments/errors.dart';
import '../experiments/flags.dart';
import '../messages/codes.dart' show Message, MessageCode;

import '../scanner/token.dart' show Token;

import '../scanner/error_token.dart' show ErrorToken;

import 'assert.dart' show Assert;

import 'block_kind.dart' show BlockKind;

import 'constructor_reference_context.dart' show ConstructorReferenceContext;

import 'formal_parameter_kind.dart' show FormalParameterKind;

import 'identifier_context.dart' show IdentifierContext;

import 'declaration_kind.dart' show DeclarationKind;

import 'member_kind.dart' show MemberKind;

abstract class UnescapeErrorListener {
  void handleUnescapeError(
      Message message, covariant location, int offset, int length);
}

/// A parser event listener that does nothing except throw exceptions
/// on parser errors.
///
/// Events are methods that begin with one of: `begin`, `end`, or `handle`.
///
/// Events starting with `begin` and `end` come in pairs. Normally, a
/// `beginFoo` event is followed by an `endFoo` event. There's a few exceptions
/// documented below.
///
/// Events starting with `handle` are used when isn't possible to have a begin
/// event.
class Listener implements UnescapeErrorListener {
  Uri? get uri => null;

  void logEvent(String name) {}

  void beginArguments(Token token) {}

  void endArguments(int count, Token beginToken, Token endToken) {
    logEvent("Arguments");
  }

  /// Called after the parser has consumed a sequence of patternFields that
  /// forms the arguments to an objectPattern
  void handleObjectPatternFields(int count, Token beginToken, Token endToken) {
    logEvent("ObjectPatternFields");
  }

  /// Handle async modifiers `async`, `async*`, `sync`.
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    logEvent("AsyncModifier");
  }

  /// Ended by either [endAwaitExpression] or [endInvalidAwaitExpression].
  void beginAwaitExpression(Token token) {}

  /// One of the two possible corresponding end events for
  /// [beginAwaitExpression].
  void endAwaitExpression(Token beginToken, Token endToken) {
    logEvent("AwaitExpression");
  }

  /// One of the two possible corresponding end events for
  /// [beginAwaitExpression].
  void endInvalidAwaitExpression(
      Token beginToken, Token endToken, MessageCode errorCode) {
    logEvent("InvalidAwaitExpression");
  }

  void beginBlock(Token token, BlockKind blockKind) {}

  void endBlock(
      int count, Token beginToken, Token endToken, BlockKind blockKind) {
    logEvent("Block");
  }

  /// Called to handle a block that has been parsed but is not associated
  /// with any top level function declaration. Substructures:
  /// - block
  void handleInvalidTopLevelBlock(Token token) {}

  void beginCascade(Token token) {}

  void endCascade() {
    logEvent("Cascade");
  }

  void beginCaseExpression(Token caseKeyword) {}

  void endCaseExpression(Token caseKeyword, Token? when, Token colon) {
    logEvent("CaseExpression");
  }

  /// Handle the start of the body of a class, mixin or extension declaration
  /// beginning at [token]. The actual kind of declaration is indicated by
  /// [kind].
  void beginClassOrMixinOrExtensionBody(DeclarationKind kind, Token token) {}

  /// Handle the end of the body of a class, mixin or extension declaration.
  /// The only substructures are the class, mixin or extension members.
  ///
  /// The actual kind of declaration is indicated by [kind].
  void endClassOrMixinOrExtensionBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    logEvent("ClassOrMixinOrExtensionBody");
  }

  /// Called before parsing a class declaration, mixin declaration, or named
  /// mixin application.
  ///
  /// At this point only the `class` or `mixin` keyword have been seen,
  /// so we know a declaration is coming but not its name or type
  /// parameter declarations.
  ///
  /// Ended by [endTopLevelDeclaration].
  void beginClassOrMixinOrNamedMixinApplicationPrelude(Token token) {}

  /// Handle the beginning of a class declaration.
  /// [begin] may be the same as [name], or may point to modifiers
  /// (or extraneous modifiers in the case of recovery) preceding [name].
  ///
  /// At this point we have parsed the name and type parameter declarations.
  void beginClassDeclaration(
      Token begin,
      Token? abstractToken,
      Token? macroToken,
      Token? inlineToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? finalToken,
      Token? augmentToken,
      Token? mixinToken,
      Token name) {}

  /// Handle an extends clause in a class declaration. Substructures:
  /// - supertype (may be a mixin application)
  /// The typeCount is for error recovery: Invalid code might have more than one
  /// class specified in the extends clause. A parser error has already been
  /// issued.
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    logEvent("ClassExtends");
  }

  /// Handle an implements clause in a class, mixin or enum declaration.
  /// Substructures:
  /// - implemented types
  void handleImplements(Token? implementsKeyword, int interfacesCount) {
    logEvent("Implements");
  }

  /// Handle a show clause in an extension declaration.
  /// Substructures:
  /// - shown types and instance members
  void handleExtensionShowHide(Token? showKeyword, int showElementCount,
      Token? hideKeyword, int hideElementCount) {
    logEvent("ExtensionShowHide");
  }

  /// Handle the header of a class declaration.  Substructures:
  /// - metadata
  /// - modifiers
  /// - class name
  /// - type variables
  /// - supertype
  /// - with clause
  /// - implemented types
  /// - native clause
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    logEvent("ClassHeader");
  }

  /// Handle recovery associated with a class header.
  /// This may be called multiple times after [handleClassHeader]
  /// to recover information about the previous class header.
  /// The substructures are a subset of
  /// and in the same order as [handleClassHeader]:
  /// - supertype
  /// - with clause
  /// - implemented types
  void handleRecoverClassHeader() {
    logEvent("RecoverClassHeader");
  }

  /// Handle the end of a class declaration.  Substructures:
  /// - class header
  /// - class body
  void endClassDeclaration(Token beginToken, Token endToken) {
    logEvent("ClassDeclaration");
  }

  /// Handle the beginning of a mixin declaration.
  void beginMixinDeclaration(
      Token? augmentToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? finalToken,
      Token mixinKeyword,
      Token name) {}

  /// Handle an on clause in a mixin declaration. Substructures:
  /// - implemented types
  void handleMixinOn(Token? onKeyword, int typeCount) {
    logEvent("MixinOn");
  }

  /// Handle the header of a mixin declaration.  Substructures:
  /// - metadata
  /// - mixin name
  /// - type variables
  /// - on types
  /// - implemented types
  void handleMixinHeader(Token mixinKeyword) {
    logEvent("MixinHeader");
  }

  /// Handle recovery associated with a mixin header.
  /// This may be called multiple times after [handleMixinHeader]
  /// to recover information about the previous mixin header.
  /// The substructures are a subset of
  /// and in the same order as [handleMixinHeader]
  /// - on types
  /// - implemented types
  void handleRecoverMixinHeader() {
    logEvent("RecoverMixinHeader");
  }

  /// Handle the end of a mixin declaration.  Substructures:
  /// - mixin header
  /// - class or mixin body
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    logEvent("MixinDeclaration");
  }

  /// Begins a not-further-categorized top-level declaration.
  ///
  /// Ended by [endTopLevelDeclaration].
  void beginUncategorizedTopLevelDeclaration(Token token) {}

  /// Handle the beginning of an extension methods declaration.  Substructures:
  /// - metadata
  ///
  /// At this point only the `extension` keyword have been seen, so we know a
  /// declaration is coming but not its name or type parameter declarations.
  ///
  /// Ended by [endTopLevelDeclaration].
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {}

  /// Handle the beginning of an extension methods declaration.  Substructures:
  /// - type variables
  ///
  /// At this point we have parsed the name and type parameter declarations.
  void beginExtensionDeclaration(Token extensionKeyword, Token? name) {}

  /// Handle the end of an extension methods declaration.  Substructures:
  /// - substructures from [beginExtensionDeclaration]
  /// - on type
  /// - body
  void endExtensionDeclaration(Token extensionKeyword, Token? typeKeyword,
      Token onKeyword, Token? showKeyword, Token? hideKeyword, Token endToken) {
    logEvent('ExtensionDeclaration');
  }

  void beginCombinators(Token token) {}

  void endCombinators(int count) {
    logEvent("Combinators");
  }

  void beginCompilationUnit(Token token) {}

  /// This method exists for analyzer compatibility only
  /// and will be removed once analyzer/fasta integration is complete.
  ///
  /// This is called when [parseDirectives] has parsed all directives
  /// and is skipping the remainder of the file.  Substructures:
  /// - metadata
  void handleDirectivesOnly() {}

  void endCompilationUnit(int count, Token token) {
    logEvent("CompilationUnit");
  }

  void beginConstLiteral(Token token) {}

  void endConstLiteral(Token token) {
    logEvent("ConstLiteral");
  }

  void beginConstructorReference(Token start) {}

  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    logEvent("ConstructorReference");
  }

  void beginDoWhileStatement(Token token) {}

  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    logEvent("DoWhileStatement");
  }

  void beginDoWhileStatementBody(Token token) {}

  void endDoWhileStatementBody(Token token) {
    logEvent("DoWhileStatementBody");
  }

  void beginWhileStatementBody(Token token) {}

  void endWhileStatementBody(Token token) {
    logEvent("WhileStatementBody");
  }

  void beginEnum(Token enumKeyword) {}

  /// Handle the end of an enum declaration.  Substructures:
  /// - [memberCount] times:
  ///   - Enum member
  void endEnum(Token enumKeyword, Token leftBrace, int memberCount) {
    logEvent("Enum");
  }

  /// Handle the end of an enum constructor declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endEnumConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  /// Handle the enum elements. Substructures:
  /// - [elementsCount] times:
  ///   - Enum element
  void handleEnumElements(Token elementsEndToken, int elementsCount) {
    logEvent("EnumElements");
  }

  /// Handle the header of an enum declaration.  Substructures:
  /// - Metadata
  /// - Enum name (identifier)
  /// - type variables
  /// - with clause
  /// - implemented types
  void handleEnumHeader(Token enumKeyword, Token leftBrace) {
    logEvent("EnumHeader");
  }

  /// Handle the enum element. Substructures:
  /// - Metadata
  /// - Enum value (identifier)
  void handleEnumElement(Token beginToken) {
    logEvent("EnumElement");
  }

  void endEnumFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    endClassFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  void beginExport(Token token) {}

  /// Handle the end of an export directive.  Substructures:
  /// - metadata
  /// - uri
  /// - conditional uris
  /// - combinators
  void endExport(Token exportKeyword, Token semicolon) {
    logEvent("Export");
  }

  /// Called by [Parser] after parsing an extraneous expression as error
  /// recovery. For a stack-based listener, the suggested action is to discard
  /// an expression from the stack.
  void handleExtraneousExpression(Token token, Message message) {
    logEvent("ExtraneousExpression");
  }

  void handleExpressionStatement(Token token) {
    logEvent("ExpressionStatement");
  }

  /// Note that this is ended by [endClassFactoryMethod],
  /// [endMixinFactoryMethod] or [endExtensionFactoryMethod].
  void beginFactoryMethod(DeclarationKind declarationKind, Token lastConsumed,
      Token? externalToken, Token? constToken) {}

  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    logEvent("ClassFactoryMethod");
  }

  void endMixinFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  void endExtensionFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {}

  void endFormalParameter(
      Token? thisKeyword,
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    logEvent("FormalParameter");
  }

  void handleNoFormalParameters(Token token, MemberKind kind) {
    logEvent("NoFormalParameters");
  }

  void beginFormalParameters(Token token, MemberKind kind) {}

  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    logEvent("FormalParameters");
  }

  /// Handle the end of a class field declaration.  Substructures:
  /// - Metadata
  /// - Modifiers
  /// - Type
  /// - Variable declarations (count times)
  ///
  /// Started by [beginFields].
  void endClassFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    logEvent("Fields");
  }

  /// Handle the end of a mixin field declaration.  Substructures:
  /// - Metadata
  /// - Modifiers
  /// - Type
  /// - Variable declarations (count times)
  ///
  /// Started by [beginFields].
  void endMixinFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassFields(
        abstractToken,
        augmentToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        count,
        beginToken,
        endToken);
  }

  /// Handle the end of a extension field declaration.  Substructures:
  /// - Metadata
  /// - Modifiers
  /// - Type
  /// - Variable declarations (count times)
  ///
  /// Started by [beginFields].
  void endExtensionFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassFields(
        abstractToken,
        augmentToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        count,
        beginToken,
        endToken);
  }

  /// Handle the end of an enum field declaration.  Substructures:
  /// - Metadata
  /// - Modifiers
  /// - Type
  /// - Variable declarations (count times)
  ///
  /// Started by [beginFields].
  void endEnumFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    endClassFields(
        abstractToken,
        augmentToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        count,
        beginToken,
        endToken);
  }

  /// Handle the end of an enum method declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endEnumMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  /// Marks that the grammar term `forInitializerStatement` has been parsed and
  /// it was an empty statement.
  void handleForInitializerEmptyStatement(Token token) {
    logEvent("ForInitializerEmptyStatement");
  }

  /// Marks that the grammar term `forInitializerStatement` has been parsed and
  /// it was an expression statement.
  void handleForInitializerExpressionStatement(Token token, bool forIn) {
    logEvent("ForInitializerExpressionStatement");
  }

  /// Marks that the grammar term `forInitializerStatement` has been parsed and
  /// it was a `localVariableDeclaration` of the form
  /// `metadata initializedVariableDeclaration ';'`.
  void handleForInitializerLocalVariableDeclaration(Token token, bool forIn) {
    logEvent("ForInitializerLocalVariableDeclaration");
  }

  /// Marks that the grammar term `forInitializerStatement` has been parsed and
  /// it was a `localVariableDeclaration` of the form
  /// `metadata patternVariableDeclaration ';'`.
  void handleForInitializerPatternVariableAssignment(
      Token keyword, Token equals) {
    logEvent("handleForInitializerPatternVariableAssignment");
  }

  /// Marks the start of a for statement which is ended by either
  /// [endForStatement] or [endForIn].
  void beginForStatement(Token token) {}

  /// Marks the end of parsing the control structure of a for statement
  /// or for control flow entry up to and including the closing parenthesis.
  /// `for` `(` initialization `;` condition `;` updaters `)`
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {}

  void endForStatement(Token endToken) {
    logEvent("ForStatement");
  }

  void beginForStatementBody(Token token) {}

  void endForStatementBody(Token token) {
    logEvent("ForStatementBody");
  }

  /// Marks the end of parsing the control structure of a for-in statement
  /// or for control flow entry up to and including the closing parenthesis.
  /// If [patternKeyword] is `null`, this takes the form:
  ///   `for` `(` (type)? identifier `in` iterator `)`
  /// If [patternKeyword] is not `null`, it is either a `var` or `final` token,
  /// and this takes the form:
  ///   `for` `(` patternKeyword pattern `in` iterator `)`
  void handleForInLoopParts(Token? awaitToken, Token forToken,
      Token leftParenthesis, Token? patternKeyword, Token inKeyword) {}

  // One of the two possible corresponding end events for [beginForStatement].
  void endForIn(Token endToken) {
    logEvent("ForIn");
  }

  void beginForInExpression(Token token) {}

  void endForInExpression(Token token) {
    logEvent("ForInExpression");
  }

  void beginForInBody(Token token) {}

  void endForInBody(Token token) {
    logEvent("ForInBody");
  }

  /// Handle the beginning of a named function expression which isn't legal
  /// syntax in Dart.  Useful for recovering from JavaScript code being pasted
  /// into a Dart program, as it will interpret `function foo() {}` as a named
  /// function expression with return type `function` and name `foo`.
  ///
  /// Substructures:
  /// - Type variables
  void beginNamedFunctionExpression(Token token) {}

  /// A named function expression which isn't legal syntax in Dart.
  /// Useful for recovering from JavaScript code being pasted into a Dart
  /// program, as it will interpret `function foo() {}` as a named function
  /// expression with return type `function` and name `foo`.
  ///
  /// Substructures:
  /// - Type variables
  /// - Modifiers
  /// - Return type
  /// - Name
  /// - Formals
  /// - Initializers
  /// - Async modifier
  /// - Function body (block or arrow expression).
  void endNamedFunctionExpression(Token endToken) {
    logEvent("NamedFunctionExpression");
  }

  /// Handle the beginning of a local function declaration.  Substructures:
  /// - Metadata
  /// - Type variables
  void beginLocalFunctionDeclaration(Token token) {}

  /// A function declaration.
  ///
  /// Substructures:
  /// - Metadata
  /// - Type variables
  /// - Return type
  /// - Name
  /// - Type variables
  /// - Formals
  /// - Initializers
  /// - Async modifier
  /// - Function body (block or arrow expression).
  void endLocalFunctionDeclaration(Token endToken) {
    logEvent("FunctionDeclaration");
  }

  /// This method is invoked when the parser sees that a function has a
  /// block function body.  This method is not invoked for empty or expression
  /// function bodies, see the corresponding methods [handleEmptyFunctionBody]
  /// and [handleExpressionFunctionBody].
  void beginBlockFunctionBody(Token token) {}

  /// This method is invoked by the parser after it finished parsing a block
  /// function body.  This method is not invoked for empty or expression
  /// function bodies, see the corresponding methods [handleEmptyFunctionBody]
  /// and [handleExpressionFunctionBody].  The [beginToken] is the '{' token,
  /// and the [endToken] is the '}' token of the block.  The number of
  /// statements is given as the [count] parameter.
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    logEvent("BlockFunctionBody");
  }

  void handleNoFunctionBody(Token token) {
    logEvent("NoFunctionBody");
  }

  /// Handle the end of a function body that was skipped by the parser.
  ///
  /// The boolean [isExpressionBody] indicates whether the function body that
  /// was skipped used "=>" syntax.
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {}

  void beginFunctionName(Token token) {}

  void endFunctionName(Token beginToken, Token token) {
    logEvent("FunctionName");
  }

  void beginTypedef(Token token) {}

  /// Handle the end of a typedef declaration.
  ///
  /// If [equals] is null, then we have the following substructures:
  /// - Metadata
  /// - Return type
  /// - Name (identifier)
  /// - Alias type variables
  /// - Formal parameters
  ///
  /// If [equals] is not null, then the have the following substructures:
  /// - Metadata
  /// - Name (identifier)
  /// - Alias type variables
  /// - Type (FunctionTypeAnnotation)
  void endTypedef(Token typedefKeyword, Token? equals, Token endToken) {
    logEvent("FunctionTypeAlias");
  }

  /// Handle the end of a class with clause (e.g. "with B, C").
  /// Substructures:
  /// - mixin types (TypeList)
  void handleClassWithClause(Token withKeyword) {
    logEvent("ClassWithClause");
  }

  /// Handle the absence of a class with clause.
  void handleClassNoWithClause() {
    logEvent("ClassNoWithClause");
  }

  /// Handle the end of an enum with clause (e.g. "with B, C").
  /// Substructures:
  /// - mixin types (TypeList)
  ///
  /// This method is separated from [handleClassWithClause] to simplify
  /// handling the different objects in the context.
  void handleEnumWithClause(Token withKeyword) {
    logEvent("EnumWithClause");
  }

  /// Handle the absence of an enum with clause.
  void handleEnumNoWithClause() {
    logEvent("EnumNoWithClause");
  }

  /// Handle the beginning of a named mixin application.
  /// [beginToken] may be the same as [name], or may point to modifiers
  /// (or extraneous modifiers in the case of recovery) preceding [name].
  ///
  /// At this point we have parsed the name and type parameter declarations.
  void beginNamedMixinApplication(
      Token begin,
      Token? abstractToken,
      Token? macroToken,
      Token? inlineToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? finalToken,
      Token? augmentToken,
      Token? mixinToken,
      Token name) {}

  /// Handle a named mixin application with clause (e.g. "A with B, C").
  /// Substructures:
  /// - supertype
  /// - mixin types (TypeList)
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    logEvent("NamedMixinApplicationWithClause");
  }

  /// Handle the end of a named mixin declaration.  Substructures:
  /// - metadata
  /// - modifiers
  /// - class name
  /// - type variables
  /// - supertype
  /// - with clause
  /// - implemented types (TypeList)
  ///
  /// TODO(paulberry,ahe): it seems inconsistent that for a named mixin
  /// application, the implemented types are a TypeList, whereas for a class
  /// declaration, each implemented type is listed separately on the stack, and
  /// the number of implemented types is passed as a parameter.
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token? implementsKeyword, Token endToken) {
    logEvent("NamedMixinApplication");
  }

  void beginHide(Token hideKeyword) {}

  /// Handle the end of a "hide" combinator.  Substructures:
  /// - hidden names (IdentifierList)
  void endHide(Token hideKeyword) {
    logEvent("Hide");
  }

  void handleIdentifierList(int count) {
    logEvent("IdentifierList");
  }

  void beginTypeList(Token token) {}

  void endTypeList(int count) {
    logEvent("TypeList");
  }

  void beginIfStatement(Token token) {}

  void endIfStatement(Token ifToken, Token? elseToken) {
    logEvent("IfStatement");
  }

  void beginThenStatement(Token token) {}

  void endThenStatement(Token token) {
    logEvent("ThenStatement");
  }

  void beginElseStatement(Token token) {}

  void endElseStatement(Token token) {
    logEvent("ElseStatement");
  }

  void beginImport(Token importKeyword) {}

  /// Signals that the current import is deferred and/or has a prefix
  /// depending upon whether [deferredKeyword] and [asKeyword]
  /// are not `null` respectively. Substructures:
  /// - prefix identifier (only if asKeyword != null)
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    logEvent("ImportPrefix");
  }

  /// Handle the end of an import directive.  Substructures:
  /// - metadata
  /// - uri
  /// - conditional uris
  /// - prefix identifier
  /// - combinators
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    logEvent("Import");
  }

  /// Handle recovery associated with an import directive.
  /// This may be called multiple times after [endImport]
  /// to recover information about the previous import directive.
  /// The substructures are a subset of and in the same order as [endImport]:
  /// - conditional uris
  /// - prefix identifier
  /// - combinators
  void handleRecoverImport(Token? semicolon) {
    logEvent("ImportRecovery");
  }

  void beginConditionalUris(Token token) {}

  void endConditionalUris(int count) {
    logEvent("ConditionalUris");
  }

  void beginConditionalUri(Token ifKeyword) {}

  /// Handle the end of a conditional URI construct.  Substructures:
  /// - Dotted name
  /// - Condition (literal string; only if [equalSign] != null)
  /// - URI (literal string)
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    logEvent("ConditionalUri");
  }

  void handleDottedName(int count, Token firstIdentifier) {
    logEvent("DottedName");
  }

  void beginImplicitCreationExpression(Token token) {}

  void endImplicitCreationExpression(Token token, Token openAngleBracket) {
    logEvent("ImplicitCreationExpression");
  }

  void beginInitializedIdentifier(Token token) {}

  void endInitializedIdentifier(Token nameToken) {
    logEvent("InitializedIdentifier");
  }

  void beginFieldInitializer(Token token) {}

  /// Handle the end of a field initializer.  Substructures:
  /// - Initializer expression
  void endFieldInitializer(Token assignment, Token token) {
    logEvent("FieldInitializer");
  }

  /// Handle the lack of a field initializer.
  void handleNoFieldInitializer(Token token) {
    logEvent("NoFieldInitializer");
  }

  void beginVariableInitializer(Token token) {}

  /// Handle the end of a variable initializer. Substructures:
  /// - Initializer expression.
  void endVariableInitializer(Token assignmentOperator) {
    logEvent("VariableInitializer");
  }

  /// Used when a variable has no initializer.
  void handleNoVariableInitializer(Token token) {
    logEvent("NoVariableInitializer");
  }

  void beginInitializer(Token token) {}

  void endInitializer(Token token) {
    logEvent("ConstructorInitializer");
  }

  void beginInitializers(Token token) {}

  void endInitializers(int count, Token beginToken, Token endToken) {
    logEvent("Initializers");
  }

  void handleNoInitializers() {
    logEvent("NoInitializers");
  }

  /// Called after the listener has recovered from an invalid expression. The
  /// parser will resume parsing from [token]. Exactly where the parser will
  /// resume parsing is unspecified.
  void handleInvalidExpression(Token token) {
    logEvent("InvalidExpression");
  }

  /// Called after the listener has recovered from an invalid function
  /// body. The parser expected an open curly brace `{` and will resume parsing
  /// from [token] as if a function body had preceded it.
  void handleInvalidFunctionBody(Token token) {
    logEvent("InvalidFunctionBody");
  }

  /// Called after the listener has recovered from an invalid type. The parser
  /// expected an identifier, and will resume parsing type arguments from
  /// [token].
  void handleInvalidTypeReference(Token token) {
    logEvent("InvalidTypeReference");
  }

  void handleLabel(Token token) {
    logEvent("Label");
  }

  void beginLabeledStatement(Token token, int labelCount) {}

  void endLabeledStatement(int labelCount) {
    logEvent("LabeledStatement");
  }

  void beginLibraryAugmentation(Token libraryKeyword, Token augmentKeyword) {}

  /// Handle the end of a library augmentation directive.  Substructures:
  /// - metadata
  /// - uri
  void endLibraryAugmentation(
      Token libraryKeyword, Token augmentKeyword, Token semicolon) {
    logEvent("LibraryAugmentation");
  }

  void beginLibraryName(Token token) {}

  /// Handle the end of a library directive.  Substructures:
  /// - Metadata
  /// - Library name (a qualified identifier)
  void endLibraryName(Token libraryKeyword, Token semicolon, bool hasName) {
    logEvent("LibraryName");
  }

  void handleLiteralMapEntry(Token colon, Token endToken) {
    logEvent("LiteralMapEntry");
  }

  /// Called after the parser has consumed a mapPatternEntry, consisting of an
  /// expression, a colon, and a pattern.
  void handleMapPatternEntry(Token colon, Token endToken) {
    logEvent("MapPatternEntry");
  }

  void beginLiteralString(Token token) {}

  void handleInterpolationExpression(Token leftBracket, Token? rightBracket) {}

  void endLiteralString(int interpolationCount, Token endToken) {
    logEvent("LiteralString");
  }

  void handleStringJuxtaposition(Token startToken, int literalCount) {
    logEvent("StringJuxtaposition");
  }

  /// Called for class-like members (class, mixin, extension), but each member
  /// should also have a more specific begin/end pair, e.g.
  /// [beginFactoryMethod]/[endClassFactoryMethod]/[endMixinFactoryMethod]/
  /// [endExtensionFactoryMethod].
  void beginMember() {}

  /// Handle an invalid member declaration. Substructures:
  /// - metadata
  void handleInvalidMember(Token endToken) {
    logEvent("InvalidMember");
  }

  /// This event is added for convenience to the listener.
  /// Members will actually be begin/end'ed by more specific
  /// events as well.
  /// Normally listeners should probably override
  /// [endClassFields], [endMixinFields], [endExtensionFields],
  /// [endClassMethod], [endMixinMethod], [endExtensionMethod],
  /// [endClassConstructor], [endMixinConstructor],
  /// or [endExtensionConstructor] instead.
  void endMember() {
    logEvent("Member");
  }

  /// Handle the beginning of a class-like method declaration.  Substructures:
  /// - metadata
  /// Note that this is ended with [endClassConstructor], [endClassMethod],
  /// [endExtensionConstructor], [endExtensionMethod], [endMixinConstructor] or
  /// [endMixinMethod].
  void beginMethod(
      DeclarationKind declarationKind,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {}

  /// Handle the end of a class method declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    logEvent("ClassMethod");
  }

  /// Handle the end of a mixin method declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  /// Handle the end of a extension method declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  /// Handle the end of a class constructor declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  /// Handle the end of a mixin constructor declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  /// Handle the end of a extension constructor declaration.  Substructures:
  /// - metadata
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    // TODO(danrubel): push implementation into subclasses
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  void beginMetadataStar(Token token) {}

  void endMetadataStar(int count) {
    logEvent("MetadataStar");
  }

  void beginMetadata(Token token) {}

  /// Handle the end of a metadata annotation.  Substructures:
  /// - Identifier
  /// - Type arguments
  /// - Constructor name (only if [periodBeforeName] is not `null`)
  /// - Arguments
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    logEvent("Metadata");
  }

  void beginOptionalFormalParameters(Token token) {}

  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    logEvent("OptionalFormalParameters");
  }

  void beginPart(Token token) {}

  /// Handle the end of a part directive.  Substructures:
  /// - metadata
  /// - uri
  void endPart(Token partKeyword, Token semicolon) {
    logEvent("Part");
  }

  void beginPartOf(Token token) {}

  /// Handle the end of a "part of" directive.  Substructures:
  /// - Metadata
  /// - Library name (a qualified identifier)
  ///
  /// If [hasName] is true, this part refers to its library by name, otherwise,
  /// by URI.
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    logEvent("PartOf");
  }

  void beginRedirectingFactoryBody(Token token) {}

  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    logEvent("RedirectingFactoryBody");
  }

  void beginReturnStatement(Token token) {}

  /// Handle the end of a `native` function.
  /// The [handleNativeClause] event is sent prior to this event.
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    logEvent("NativeFunctionBody");
  }

  /// Called after the [handleNativeClause] event when the parser determines
  /// that the native clause should be discarded / ignored.
  /// For example, this method is called a native clause is followed by
  /// a function body.
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    logEvent("NativeFunctionBodyIgnored");
  }

  /// Handle the end of a `native` function that was skipped by the parser.
  /// The [handleNativeClause] event is sent prior to this event.
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    logEvent("NativeFunctionBodySkipped");
  }

  /// This method is invoked when a function has the empty body.
  void handleEmptyFunctionBody(Token semicolon) {
    logEvent("EmptyFunctionBody");
  }

  /// This method is invoked when parser finishes parsing the corresponding
  /// expression of the expression function body.
  void handleExpressionFunctionBody(Token arrowToken, Token? endToken) {
    logEvent("ExpressionFunctionBody");
  }

  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    logEvent("ReturnStatement");
  }

  void handleSend(Token beginToken, Token endToken) {
    logEvent("Send");
  }

  void beginShow(Token showKeyword) {}

  /// Handle the end of a "show" combinator.  Substructures:
  /// - shown names (IdentifierList)
  void endShow(Token showKeyword) {
    logEvent("Show");
  }

  void beginSwitchStatement(Token token) {}

  void endSwitchStatement(Token switchKeyword, Token endToken) {
    logEvent("SwitchStatement");
  }

  void beginSwitchExpression(Token token) {}

  void endSwitchExpression(Token switchKeyword, Token endToken) {
    logEvent("SwitchExpression");
  }

  void beginSwitchBlock(Token token) {}

  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    logEvent("SwitchBlock");
  }

  void beginSwitchExpressionBlock(Token token) {}

  void endSwitchExpressionBlock(
      int caseCount, Token beginToken, Token endToken) {
    logEvent("SwitchExpressionBlock");
  }

  void beginLiteralSymbol(Token token) {}

  void endLiteralSymbol(Token hashToken, int identifierCount) {
    logEvent("LiteralSymbol");
  }

  void handleThrowExpression(Token throwToken, Token endToken) {
    logEvent("ThrowExpression");
  }

  void beginRethrowStatement(Token token) {}

  void endRethrowStatement(Token rethrowToken, Token endToken) {
    logEvent("RethrowStatement");
  }

  /// This event is added for convenience for the listener.
  /// All top-level declarations will actually be begin/end'ed by more specific
  /// events as well, e.g. [beginClassDeclaration]/[endClassDeclaration],
  /// [beginEnum]/[endEnum] etc.
  ///
  /// Normally listeners should probably override
  /// [endClassDeclaration], [endNamedMixinApplication], [endEnum],
  /// [endTypedef], [endLibraryName], [endImport], [endExport],
  /// [endPart], [endPartOf], [endTopLevelFields], or [endTopLevelMethod]
  /// instead.
  ///
  /// Started by one of [beginExtensionDeclarationPrelude],
  /// [beginClassOrMixinOrNamedMixinApplicationPrelude], [beginTopLevelMember]
  /// or [beginUncategorizedTopLevelDeclaration].
  void endTopLevelDeclaration(Token nextToken) {
    logEvent("TopLevelDeclaration");
  }

  /// Called by the [Parser] when it recovers from an invalid top level
  /// declaration, where [endToken] is the last token in the declaration
  /// This is called after the begin/end metadata star events,
  /// and is followed by [endTopLevelDeclaration].
  ///
  /// Substructures:
  /// - metadata
  void handleInvalidTopLevelDeclaration(Token endToken) {
    logEvent("InvalidTopLevelDeclaration");
  }

  /// Marks the beginning of a top level field or method declaration.
  /// See also [endTopLevelFields] and [endTopLevelMethod].
  ///
  /// Ended by [endTopLevelDeclaration].
  void beginTopLevelMember(Token token) {}

  /// Marks the beginning of a fields declaration.
  /// Note that this is ended with [endTopLevelFields], [endClassFields],
  /// [endMixinFields] or [endExtensionFields].
  void beginFields(
      DeclarationKind declarationKind,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token lastConsumed) {}

  /// Handle the end of a top level variable declaration.  Substructures:
  /// - Metadata
  /// - Type
  /// - Repeated [count] times:
  ///   - Variable name (identifier)
  ///   - Field initializer
  ///
  /// Started by [beginFields].
  void endTopLevelFields(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    logEvent("TopLevelFields");
  }

  void beginTopLevelMethod(
      Token lastConsumed, Token? augmentToken, Token? externalToken) {}

  /// Handle the end of a top level method.  Substructures:
  /// - metadata
  /// - modifiers
  /// - return type
  /// - identifier
  /// - type variables
  /// - formal parameters
  /// - async marker
  /// - body
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    logEvent("TopLevelMethod");
  }

  void beginTryStatement(Token token) {}

  void beginCatchClause(Token token) {}

  void endCatchClause(Token token) {
    logEvent("CatchClause");
  }

  void handleCatchBlock(Token? onKeyword, Token? catchKeyword, Token? comma) {
    logEvent("CatchBlock");
  }

  void handleFinallyBlock(Token finallyKeyword) {
    logEvent("FinallyBlock");
  }

  void endTryStatement(
      int catchCount, Token tryKeyword, Token? finallyKeyword) {
    logEvent("TryStatement");
  }

  void handleType(Token beginToken, Token? questionMark) {
    logEvent("Type");
  }

  /// Called when parser encounters a '!'
  /// used as a non-null postfix assertion in an expression.
  void handleNonNullAssertExpression(Token bang) {
    logEvent("NonNullAssertExpression");
  }

  /// Called after the parser has consumed a null-assert pattern, consisting of
  /// a pattern followed by a `!` operator.
  void handleNullAssertPattern(Token bang) {
    logEvent("NullAssertPattern");
  }

  /// Called after the parser has consumed a null-check pattern, consisting of a
  /// pattern followed by a `?` operator.
  void handleNullCheckPattern(Token question) {
    logEvent('NullCheckPattern');
  }

  /// Called after the parser has consumed a variable pattern, consisting of an
  /// optional `var` or `final` keyword, an optional type annotation, and a
  /// variable name identifier.
  ///
  /// The flag [inAssignmentPattern] indicates whether this variable pattern is
  /// part of a `patternAssignment` (and hence should refer to a previously
  /// declared variable rather than declaring a fresh one).
  void handleVariablePattern(Token? keyword, Token variable,
      {required bool inAssignmentPattern}) {
    logEvent('VariablePattern');
  }

  void handleNoName(Token token) {
    logEvent("NoName");
  }

  void beginRecordType(Token leftBracket) {}

  /// Handle the end of a record type declaration.
  ///
  /// Substructures:
  /// - RecordTypeEntry*
  /// - RecordTypeNamedFields?
  ///
  /// Notice that [count] is:
  /// - the number of RecordTypeEntries if [hasNamedFields] is `false`, or
  /// - the number of RecordTypeEntries + 1 if [hasNamedFields] is `true`.
  void endRecordType(
      Token leftBracket, Token? questionMark, int count, bool hasNamedFields) {
    logEvent("RecordType");
  }

  void beginRecordTypeEntry() {}

  /// Handle the end of the record type entries.
  ///
  /// Substructures:
  /// - metadata
  /// - type
  /// - identifier
  void endRecordTypeEntry() {
    logEvent("RecordTypeEntry");
  }

  void beginRecordTypeNamedFields(Token leftBracket) {}

  /// Handle the end of the record type named fields.
  ///
  /// Substructures:
  /// - RecordTypeEntry*
  void endRecordTypeNamedFields(int count, Token leftBracket) {
    logEvent("RecordTypeNamedFields");
  }

  void beginFunctionType(Token beginToken) {}

  /// Handle the end of a generic function type declaration.
  ///
  /// Substructures:
  /// - Type variables
  /// - Return type
  /// - Formal parameters
  void endFunctionType(Token functionToken, Token? questionMark) {
    logEvent("FunctionType");
  }

  void beginTypeArguments(Token token) {}

  void endTypeArguments(int count, Token beginToken, Token endToken) {
    logEvent("TypeArguments");
  }

  /// After endTypeArguments has been called,
  /// this event is called if those type arguments are invalid.
  void handleInvalidTypeArguments(Token token) {
    logEvent("NoTypeArguments");
  }

  void handleNoTypeArguments(Token token) {
    logEvent("NoTypeArguments");
  }

  /// Handle the begin of a type formal parameter (e.g. "X extends Y").
  /// Substructures:
  /// - Metadata
  /// - Name (identifier)
  void beginTypeVariable(Token token) {}

  /// Called when [beginTypeVariable] has been called for all of the variables
  /// in a group, and before [endTypeVariable] has been called for any of the
  /// variables in that same group.
  void handleTypeVariablesDefined(Token token, int count) {}

  /// Handle the end of a type formal parameter (e.g. "X extends Y")
  /// where [index] is the index of the type variable in the list of
  /// type variables being declared.
  ///
  /// Substructures:
  /// - Type bound
  ///
  /// See [beginTypeVariable] for additional substructures.
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    logEvent("TypeVariable");
  }

  void beginTypeVariables(Token token) {}

  void endTypeVariables(Token beginToken, Token endToken) {
    logEvent("TypeVariables");
  }

  void reportVarianceModifierNotEnabled(Token? variance) {
    if (variance != null) {
      handleExperimentNotEnabled(ExperimentalFlag.variance, variance, variance);
    }
  }

  void beginFunctionExpression(Token token) {}

  /// Handle the end of a function expression (e.g. "() { ... }").
  /// Substructures:
  /// - Type variables
  /// - Formal parameters
  /// - Async marker
  /// - Body
  void endFunctionExpression(Token beginToken, Token token) {
    logEvent("FunctionExpression");
  }

  /// Handle the start of a variables declaration.  Substructures:
  /// - Metadata
  /// - Type
  void beginVariablesDeclaration(
      Token token, Token? lateToken, Token? varFinalOrConst) {}

  void endVariablesDeclaration(int count, Token? endToken) {
    logEvent("VariablesDeclaration");
  }

  void beginWhileStatement(Token token) {}

  void endWhileStatement(Token whileKeyword, Token endToken) {
    logEvent("WhileStatement");
  }

  void beginAsOperatorType(Token operator) {}

  void endAsOperatorType(Token operator) {
    logEvent("AsOperatorType");
  }

  void handleAsOperator(Token operator) {
    logEvent("AsOperator");
  }

  /// Called after the parser has consumed a cast pattern, consisting of a
  /// pattern, `as` operator, and type annotation.
  void handleCastPattern(Token operator) {
    logEvent('CastPattern');
  }

  void handleAssignmentExpression(Token token) {
    logEvent("AssignmentExpression");
  }

  /// Called when the parser encounters a binary operator, in between the LHS
  /// and RHS subexpressions.
  ///
  /// Not called when the binary operator is `.`, `?.`, or `..`.
  void beginBinaryExpression(Token token) {}

  void endBinaryExpression(Token token) {
    logEvent("BinaryExpression");
  }

  /// Called when the parser has consumed the operator of a binary pattern.
  void beginBinaryPattern(Token token) {}

  /// Called when the parser has consumed a binary pattern, consisting of a LHS
  /// pattern, `&&` or `||` operator, and a RHS pattern.
  void endBinaryPattern(Token token) {
    logEvent("BinaryPattern");
  }

  /// Called for `.`, `?.` and `..`.
  void handleEndingBinaryExpression(Token token) {
    // TODO(jensj): push implementation into subclasses
    endBinaryExpression(token);
  }

  /// Called when the parser encounters a `?` operator and begins parsing a
  /// conditional expression.
  void beginConditionalExpression(Token question) {}

  /// Called when the parser encounters a `:` operator in a conditional
  /// expression.
  void handleConditionalExpressionColon() {}

  /// Called when the parser finishes processing a conditional expression.
  void endConditionalExpression(Token question, Token colon) {
    logEvent("ConditionalExpression");
  }

  void beginConstExpression(Token constKeyword) {}

  void endConstExpression(Token token) {
    logEvent("ConstExpression");
  }

  void handleConstFactory(Token constKeyword) {
    logEvent("ConstFactory");
  }

  /// Called before parsing a "for" control flow list, set, or map entry.
  /// Ended by either [endForControlFlow] or [endForInControlFlow].
  void beginForControlFlow(Token? awaitToken, Token forToken) {}

  /// Called after parsing a "for" control flow list, set, or map entry.
  /// One of the two possible corresponding end events for
  /// [beginForControlFlow].
  void endForControlFlow(Token token) {
    logEvent('endForControlFlow');
  }

  /// Called after parsing a "for-in" control flow list, set, or map entry.
  /// One of the two possible corresponding end events for
  /// [beginForControlFlow].
  void endForInControlFlow(Token token) {
    logEvent('endForInControlFlow');
  }

  /// Called before parsing an `if` control flow list, set, or map entry.
  /// Ended by either [endIfControlFlow] or [endIfElseControlFlow].
  void beginIfControlFlow(Token ifToken) {}

  /// Called before parsing the `then` portion of an `if` control flow list,
  /// set, or map entry.
  void handleThenControlFlow(Token token) {}

  /// Called before parsing the `else` portion of an `if` control flow list,
  /// set, or map entry.
  void handleElseControlFlow(Token elseToken) {
    logEvent("ElseControlFlow");
  }

  /// Called after parsing an `if` control flow list, set, or map entry.
  /// Substructures:
  /// - if conditional expression
  /// - expression
  /// One of the two possible corresponding end events for
  /// [beginIfControlFlow].
  void endIfControlFlow(Token token) {
    logEvent("endIfControlFlow");
  }

  /// Called after parsing an if-else control flow list, set, or map entry.
  /// Substructures:
  /// - if conditional expression
  /// - then expression
  /// - else expression
  /// One of the two possible corresponding end events for
  /// [beginIfControlFlow].
  void endIfElseControlFlow(Token token) {
    logEvent("endIfElseControlFlow");
  }

  /// Called after parsing a list, set, or map entry that starts with
  /// one of the spread collection tokens `...` or `...?`.  Substructures:
  /// - expression
  void handleSpreadExpression(Token spreadToken) {
    logEvent("SpreadExpression");
  }

  /// Called after parsing an element of a list or map pattern that starts with
  /// `...`.  Substructures:
  /// - pattern (if hasSubPattern is `true`)
  void handleRestPattern(Token dots, {required bool hasSubPattern}) {
    logEvent('RestPattern');
  }

  /// Handle the start of a function typed formal parameter.  Substructures:
  /// - type variables
  void beginFunctionTypedFormalParameter(Token token) {}

  /// Handle the end of a function typed formal parameter.  Substructures:
  /// - type variables
  /// - return type
  /// - formal parameters
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    logEvent("FunctionTypedFormalParameter");
  }

  /// Handle an identifier token.
  ///
  /// [context] indicates what kind of construct the identifier appears in.
  void handleIdentifier(Token token, IdentifierContext context) {
    logEvent("Identifier");
  }

  /// Handle an identifier token in a show or hide clause.
  ///
  /// [context] indicates what kind of construct the identifier appears in.
  void handleShowHideIdentifier(Token? modifier, Token identifier) {
    logEvent("ShowHideIdentifier");
  }

  void handleIndexedExpression(
      Token? question, Token openSquareBracket, Token closeSquareBracket) {
    logEvent("IndexedExpression");
  }

  void beginIsOperatorType(Token operator) {}

  void endIsOperatorType(Token operator) {
    logEvent("IsOperatorType");
  }

  void handleIsOperator(Token isOperator, Token? not) {
    logEvent("IsOperator");
  }

  void handleLiteralBool(Token token) {
    logEvent("LiteralBool");
  }

  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    logEvent("BreakStatement");
  }

  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    logEvent("ContinueStatement");
  }

  void handleEmptyStatement(Token token) {
    logEvent("EmptyStatement");
  }

  void beginAssert(Token assertKeyword, Assert kind) {}

  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token? commaToken, Token semicolonToken) {
    logEvent("Assert");
  }

  /** Called with either the token containing a double literal, or
    * an immediately preceding "unary plus" token.
    */
  void handleLiteralDouble(Token token) {
    logEvent("LiteralDouble");
  }

  /** Called with either the token containing an integer literal,
    * or an immediately preceding "unary plus" token.
    */
  void handleLiteralInt(Token token) {
    logEvent("LiteralInt");
  }

  void handleLiteralList(
      int count, Token leftBracket, Token? constKeyword, Token rightBracket) {
    logEvent("LiteralList");
  }

  /// Called after the parser has consumed a list pattern, consisting of a `[`,
  /// a comma-separated sequence of patterns, and a `]`.
  void handleListPattern(int count, Token leftBracket, Token rightBracket) {
    logEvent("ListPattern");
  }

  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token? constKeyword,
    Token rightBrace,
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool hasSetEntry,
  ) {
    logEvent('LiteralSetOrMap');
  }

  /// Called after the parser has consumed a map pattern, consisting of a `{`,
  /// a comma-separated sequence of mapPatternEntry, and a `}`.
  void handleMapPattern(int count, Token leftBrace, Token rightBrace) {
    logEvent('MapPattern');
  }

  void handleLiteralNull(Token token) {
    logEvent("LiteralNull");
  }

  void handleNativeClause(Token nativeToken, bool hasName) {
    logEvent("NativeClause");
  }

  void handleNamedArgument(Token colon) {
    logEvent("NamedArgument");
  }

  /// Called after the parser has consumed a patternField, consisting of an
  /// optional identifier, optional `:`, and a pattern.
  void handlePatternField(Token? colon) {
    logEvent("PatternField");
  }

  void handleNamedRecordField(Token colon) {
    logEvent("NamedRecordField");
  }

  void beginNewExpression(Token token) {}

  void endNewExpression(Token token) {
    logEvent("NewExpression");
  }

  void handleNoArguments(Token token) {
    logEvent("NoArguments");
  }

  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    logEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  void handleNoTypeNameInConstructorReference(Token token) {
    logEvent("NoTypeNameInConstructorReference");
  }

  void handleNoType(Token lastConsumed) {
    logEvent("NoType");
  }

  void handleNoTypeVariables(Token token) {
    logEvent("NoTypeVariables");
  }

  void handleOperator(Token token) {
    logEvent("Operator");
  }

  /// Invoked when a pattern switch case doesn't have the 'when' clause
  void handleSwitchCaseNoWhenClause(Token token) {
    logEvent("SwitchCaseNoWhenClause");
  }

  void handleSwitchExpressionCasePattern(Token token) {
    logEvent("SwitchExpressionCasePattern");
  }

  void handleSymbolVoid(Token token) {
    logEvent("SymbolVoid");
  }

  /// Handle the end of a construct of the form "operator <token>".
  void handleOperatorName(Token operatorKeyword, Token token) {
    logEvent("OperatorName");
  }

  /// Handle the end of a construct of the form "operator <token>"
  /// where <token> is not a valid operator token.
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    logEvent("InvalidOperatorName");
  }

  /// Handle the condition in a control structure:
  /// - if statement
  /// - do while loop
  /// - switch statement
  /// - while loop
  void handleParenthesizedCondition(Token token, Token? case_, Token? when) {
    logEvent("ParenthesizedCondition");
  }

  /// Starts a pattern guard, the expression that follows the 'when' keyword
  void beginPatternGuard(Token when) {
    logEvent("PatternGuard");
  }

  /// Starts a parenthesized expression or a record literal. Will be ended with
  /// either [endParenthesizedExpression] or [endRecordLiteral].
  void beginParenthesizedExpressionOrRecordLiteral(Token token) {}

  /// Starts a guard expression in a switch case, after the 'when' keyword
  void beginSwitchCaseWhenClause(Token when) {
    logEvent("SwitchCaseWhenClause");
  }

  /// Ends a record literal with [count] entries.
  void endRecordLiteral(Token token, int count, Token? constKeyword) {
    logEvent("RecordLiteral");
  }

  /// Called after the parser has consumed a record pattern, consisting of a
  /// `(`, a comma-separated sequence of patternFields, and a `)`.
  void handleRecordPattern(Token token, int count) {
    logEvent("RecordPattern");
  }

  /// End a pattern guard, the expression that follows the 'when' keyword
  void endPatternGuard(Token token) {
    logEvent("PatternGuard");
  }

  /// End a parenthesized expression.
  /// These may be within the condition expression of a control structure
  /// but will not be the condition of a control structure.
  void endParenthesizedExpression(Token token) {
    logEvent("ParenthesizedExpression");
  }

  /// Starts a guard expression in a switch case, after the 'when' keyword
  void endSwitchCaseWhenClause(Token token) {
    logEvent("SwitchCaseWhenClause");
  }

  /// Called after the parser has consumed a parenthesized pattern, consisting
  /// of a `(`, a pattern, and a `)`.
  void handleParenthesizedPattern(Token token) {
    logEvent("ParenthesizedPattern");
  }

  /// Called after the parser has consumed a constant pattern, consisting of an
  /// optional `const` and an expression.
  ///
  /// Note that some expressions can legally begin with `const`, so there is
  /// ambiguity as to whether to associate the `const` keyword with the constant
  /// pattern or the constant expression.  This ambiguity is resolved in favor
  /// of associating the `const` keyword with the constant pattern.  So for
  /// example, in `case const []` the `const` keyword is passed to
  /// [beginConstantPattern] and [endConstantPattern] rather than
  /// [handleLiteralList].
  void beginConstantPattern(Token? constKeyword) {
    logEvent("ConstantPattern");
  }

  /// Called after the parser has consumed a constant pattern, consisting of an
  /// optional `const` and an expression.
  ///
  /// Note that some expressions can legally begin with `const`, so there is
  /// ambiguity as to whether to associate the `const` keyword with the constant
  /// pattern or the constant expression.  This ambiguity is resolved in favor
  /// of associating the `const` keyword with the constant pattern.  So for
  /// example, in `case const []` the `const` keyword is passed to
  /// [beginConstantPattern] and [endConstantPattern] rather than
  /// [handleLiteralList].
  void endConstantPattern(Token? constKeyword) {
    logEvent("ConstantPattern");
  }

  /// Called after the parser has consumed an object pattern, consisting of
  /// an identifier, optional dot and second identifier, optional type
  /// arguments, and a parenthesized list of object pattern fields (see
  /// [handleObjectPatternFields]).
  void handleObjectPattern(
      Token firstIdentifier, Token? dot, Token? secondIdentifier) {
    logEvent("ObjectPattern");
  }

  /// Handle a construct of the form "identifier.identifier" occurring in a part
  /// of the grammar where expressions in general are not allowed.
  /// Substructures:
  /// - Qualified identifier (before the period)
  /// - Identifier (after the period)
  void handleQualified(Token period) {
    logEvent("Qualified");
  }

  void handleStringPart(Token token) {
    logEvent("StringPart");
  }

  void handleSuperExpression(Token token, IdentifierContext context) {
    logEvent("SuperExpression");
  }

  void handleAugmentSuperExpression(
      Token augmentToken, Token superToken, IdentifierContext context) {
    logEvent("AugmentSuperExpression");
  }

  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {}

  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token? defaultKeyword,
      Token? colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    logEvent("SwitchCase");
  }

  void beginSwitchExpressionCase() {}

  void endSwitchExpressionCase(Token? when, Token arrow, Token endToken) {
    logEvent("SwitchExpressionCase");
  }

  void handleThisExpression(Token token, IdentifierContext context) {
    logEvent("ThisExpression");
  }

  void handleUnaryPostfixAssignmentExpression(Token token) {
    logEvent("UnaryPostfixAssignmentExpression");
  }

  void handleUnaryPrefixExpression(Token token) {
    logEvent("UnaryPrefixExpression");
  }

  /// Called after the parser has consumed a relational pattern, consisting of
  /// an equality operator or relational operator, followed by an expression.
  void handleRelationalPattern(Token token) {
    logEvent("RelationalPattern");
  }

  void handleUnaryPrefixAssignmentExpression(Token token) {
    logEvent("UnaryPrefixAssignmentExpression");
  }

  void beginFormalParameterDefaultValueExpression() {}

  void endFormalParameterDefaultValueExpression() {
    logEvent("FormalParameterDefaultValueExpression");
  }

  void handleValuedFormalParameter(Token equals, Token token) {
    logEvent("ValuedFormalParameter");
  }

  void handleFormalParameterWithoutValue(Token token) {
    logEvent("FormalParameterWithoutValue");
  }

  void handleVoidKeyword(Token token) {
    logEvent("VoidKeyword");
  }

  /// The parser saw a void with type arguments (e.g. void<int>).
  /// This is not valid - an error has already been emitted.
  void handleVoidKeywordWithTypeArguments(Token token) {
    logEvent("handleVoidKeywordWithTypeArguments");
  }

  /// Ended by either [endYieldStatement] or [endInvalidYieldStatement].
  void beginYieldStatement(Token token) {}

  /// One of the two possible corresponding end events for
  /// [beginYieldStatement].
  void endYieldStatement(Token yieldToken, Token? starToken, Token endToken) {
    logEvent("YieldStatement");
  }

  /// One of the two possible corresponding end events for
  /// [beginYieldStatement].
  void endInvalidYieldStatement(Token beginToken, Token? starToken,
      Token endToken, MessageCode errorCode) {
    logEvent("InvalidYieldStatement");
  }

  /// The parser noticed a syntax error, but was able to recover from it. The
  /// error should be reported using the [message], and the code between the
  /// beginning of the [startToken] and the end of the [endToken] should be
  /// highlighted. The [startToken] and [endToken] can be the same token.
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {}

  /// The parser noticed a use of the experimental feature by the flag
  /// [experimentalFlag] that was not enabled, but was able to recover from it.
  /// The error should be reported and the code between the beginning of the
  /// [startToken] and the end of the [endToken] should be highlighted. The
  /// [startToken] and [endToken] can be the same token.
  void handleExperimentNotEnabled(
      ExperimentalFlag experimentalFlag, Token startToken, Token endToken) {
    handleRecoverableError(
        getExperimentNotEnabledMessage(experimentalFlag), startToken, endToken);
  }

  /// The parser encountered an [ErrorToken] representing an error
  /// from the scanner but recovered from it. By default, the error is reported
  /// by calling [handleRecoverableError] with the message associated
  /// with the error [token].
  void handleErrorToken(ErrorToken token) {
    handleRecoverableError(token.assertionMessage, token, token);
  }

  @override
  void handleUnescapeError(
      Message message, Token location, int stringOffset, int length) {
    handleRecoverableError(message, location, location);
  }

  /// Signals to the listener that the previous statement contained a semantic
  /// error (described by the given [message]). This method can also be called
  /// after [handleExpressionFunctionBody], in which case it signals that the
  /// implicit return statement of the function contained a semantic error.
  void handleInvalidStatement(Token token, Message message) {
    handleRecoverableError(message, token, token);
  }

  void handleScript(Token token) {
    logEvent("Script");
  }

  /// A single comment reference has been found
  /// where [referenceSource] is the text between the `[` and `]`
  /// and [referenceOffset] is the character offset in the token stream.
  ///
  /// This event is generated by the parser when the parser's
  /// `parseCommentReferences` method is called. For further processing,
  /// a listener may scan the [referenceSource] and then pass the resulting
  /// token stream to the parser's `parseOneCommentReference` method.
  void handleCommentReferenceText(String referenceSource, int referenceOffset) {
    logEvent("CommentReferenceText");
  }

  /// A single comment reference has been parsed.
  /// * [newKeyword] may be null.
  /// * [firstToken] and [firstPeriod] are either both tokens or both
  ///   `null`.
  /// * [secondToken] and [secondPeriod] are either both tokens or both `null`.
  /// * [thirdToken] can be an identifier or an operator.
  ///
  /// This event is generated by the parser when the parser's
  /// `parseOneCommentReference` method is called.
  void handleCommentReference(
      Token? newKeyword,
      Token? firstToken,
      Token? firstPeriod,
      Token? secondToken,
      Token? secondPeriod,
      Token thirdToken) {}

  /// This event is generated by the parser when the parser's
  /// `parseOneCommentReference` method is called.
  void handleNoCommentReference() {}

  /// An expression was encountered consisting of type arguments applied to a
  /// subexpression.  This could validly represent any of the following:
  /// - A type literal (`var x = List<int>;`)
  /// - A function tear-off with type arguments (`var x = f<int>;` or
  ///   `var x = importPrefix.f<int>;`)
  /// - A static method tear-off with type arguments (`var x = ClassName.m<int>`
  ///   or `var x = importPrefix.ClassName.m<int>;`)
  /// - An instance method tear-off with type arguments (`var x = EXPR.m<int>;`)
  ///
  /// Or, in the event of invalid code, it could represent type arguments
  /// erroneously applied to some other expression type (e.g.
  /// `var x = (f)<int>;`).  The client is responsible for reporting an error if
  /// this occurs.
  void handleTypeArgumentApplication(Token openAngleBracket) {}

  /// A `new` token was found in a place where an identifier was expected, and
  /// the "constructor tearoffs" feature permits `new` to be used as an
  /// identifier name.  It is the client's responsibility to report an
  /// appropriate error if the "constructor tearoffs" feature is not enabled.
  void handleNewAsIdentifier(Token token) {}

  /// Called after the parser has processed a variable declaration statement,
  /// consisting of `METADATA KEYWORD PATTERN EQUALS EXPRESSION SEMICOLON`.
  ///
  /// KEYWORD is either `var` or `final`, and PATTERN may only be one of the
  /// patterns accepted by the `outerPattern` grammar rule defined in the
  /// patterns spec.
  void handlePatternVariableDeclarationStatement(
      Token keyword, Token equals, Token semicolon) {
    logEvent('PatternVariableDeclarationStatement');
  }

  /// Called after the parser has processed a pattern assignment consisting of
  /// `PATTERN EQUALS EXPRESSION`.
  ///
  /// PATTERN may only be one of the patterns accepted by the `outerPattern`
  /// grammar rule defined in the patterns spec.
  void handlePatternAssignment(Token equals) {
    logEvent("PatternAssignment");
  }
}
