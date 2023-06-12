// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart' show MessageCode;
import 'package:_fe_analyzer_shared/src/parser/forwarding_listener.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:test/test.dart';

/// Proxy implementation of the fasta parser listener that
/// asserts begin/end pairs of events and forwards all events
/// to the specified listener.
///
/// When `parseUnit` is called, then all events are generated as expected.
/// When "lower level" parse methods are called, then some "higher level"
/// begin/end event pairs will not be generated. In this case,
/// construct a new listener and call `begin('higher-level-event')`
/// before calling the "lower level" parse method. Once the parse method
/// returns, call `end('higher-level-event')` to assert that the stack is in the
/// expected state.
///
/// For example, when calling `parseTopLevelDeclaration`, the
/// [beginCompilationUnit] and [endCompilationUnit] event pair is not generated.
/// In this case, call `begin('CompilationUnit')` before calling
/// `parseTopLevelDeclaration`, and call `end('CompilationUnit')` afterward.
///
/// When calling `parseUnit`, do not call `begin` or `end`,
/// but call `expectEmpty` after `parseUnit` returns.
class ForwardingTestListener extends ForwardingListener {
  final _stack = <String>[];

  ForwardingTestListener([Listener? listener]) : super(listener);

  void begin(String event) {
    expect(event, isNotNull);
    _stack.add(event);
  }

  @override
  void beginArguments(Token token) {
    super.beginArguments(token);
    begin('Arguments');
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    super.beginAssert(assertKeyword, kind);
    begin('Assert');
  }

  @override
  void beginAwaitExpression(Token token) {
    super.beginAwaitExpression(token);
    begin('AwaitExpression');
  }

  @override
  void beginBlock(Token token, BlockKind blockKind) {
    super.beginBlock(token, blockKind);
    begin('Block');
  }

  @override
  void beginBlockFunctionBody(Token token) {
    super.beginBlockFunctionBody(token);
    begin('BlockFunctionBody');
  }

  @override
  void beginCascade(Token token) {
    super.beginCascade(token);
    begin('Cascade');
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    super.beginCaseExpression(caseKeyword);
    begin('CaseExpression');
  }

  @override
  void beginCatchClause(Token token) {
    super.beginCatchClause(token);
    begin('CatchClause');
  }

  @override
  void beginClassDeclaration(
      Token beginToken, Token? abstractToken, Token name) {
    super.beginClassDeclaration(beginToken, abstractToken, name);
    begin('ClassDeclaration');
  }

  @override
  void beginClassOrMixinOrExtensionBody(DeclarationKind kind, Token token) {
    super.beginClassOrMixinOrExtensionBody(kind, token);
    begin('ClassOrMixinBody');
  }

  @override
  void beginClassOrMixinOrNamedMixinApplicationPrelude(Token token) {
    super.beginClassOrMixinOrNamedMixinApplicationPrelude(token);
    begin('ClassOrNamedMixinApplication');
  }

  @override
  void beginCombinators(Token token) {
    super.beginCombinators(token);
    begin('Combinators');
  }

  @override
  void beginCompilationUnit(Token token) {
    expectEmpty();
    super.beginCompilationUnit(token);
    begin('CompilationUnit');
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    expectIn('ConditionalUris');
    super.beginConditionalUri(ifKeyword);
    begin('ConditionalUri');
  }

  @override
  void beginConditionalUris(Token token) {
    super.beginConditionalUris(token);
    begin('ConditionalUris');
  }

  @override
  void beginConstExpression(Token constKeyword) {
    super.beginConstExpression(constKeyword);
    begin('ConstExpression');
  }

  @override
  void beginConstLiteral(Token token) {
    super.beginConstLiteral(token);
    begin('ConstLiteral');
  }

  @override
  void beginConstructorReference(Token start) {
    super.beginConstructorReference(start);
    begin('ConstructorReference');
  }

  @override
  void beginDoWhileStatement(Token token) {
    super.beginDoWhileStatement(token);
    begin('DoWhileStatement');
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    super.beginDoWhileStatementBody(token);
    begin('DoWhileStatementBody');
  }

  @override
  void beginElseStatement(Token token) {
    super.beginElseStatement(token);
    begin('ElseStatement');
  }

  @override
  void beginEnum(Token enumKeyword) {
    super.beginEnum(enumKeyword);
    begin('Enum');
  }

  @override
  void beginExport(Token token) {
    super.beginExport(token);
    begin('Export');
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? name) {
    super.beginExtensionDeclaration(extensionKeyword, name);
    begin('ExtensionDeclaration');
  }

  @override
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {
    super.beginExtensionDeclarationPrelude(extensionKeyword);
    begin('ExtensionDeclarationPrelude');
  }

  @override
  void beginFactoryMethod(DeclarationKind declarationKind, Token lastConsumed,
      Token? externalToken, Token? constToken) {
    super.beginFactoryMethod(
        declarationKind, lastConsumed, externalToken, constToken);
    begin('FactoryMethod');
  }

  @override
  void beginFieldInitializer(Token token) {
    super.beginFieldInitializer(token);
    begin('FieldInitializer');
  }

  @override
  void beginForControlFlow(Token? awaitToken, Token forToken) {
    super.beginForControlFlow(awaitToken, forToken);
    begin('ForControlFlow');
  }

  @override
  void beginForInBody(Token token) {
    super.beginForInBody(token);
    begin('ForInBody');
  }

  @override
  void beginForInExpression(Token token) {
    super.beginForInExpression(token);
    begin('ForInExpression');
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {
    super.beginFormalParameter(
        token, kind, requiredToken, covariantToken, varFinalOrConst);
    begin('FormalParameter');
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    super.beginFormalParameters(token, kind);
    begin('FormalParameters');
  }

  @override
  void beginForStatement(Token token) {
    super.beginForStatement(token);
    begin('ForStatement');
  }

  @override
  void beginForStatementBody(Token token) {
    super.beginForStatementBody(token);
    begin('ForStatementBody');
  }

  @override
  void beginFunctionExpression(Token token) {
    super.beginFunctionExpression(token);
    begin('FunctionExpression');
  }

  @override
  void beginFunctionName(Token token) {
    super.beginFunctionName(token);
    begin('FunctionName');
  }

  @override
  void beginFunctionType(Token beginToken) {
    super.beginFunctionType(beginToken);
    begin('FunctionType');
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    super.beginFunctionTypedFormalParameter(token);
    begin('FunctionTypedFormalParameter');
  }

  @override
  void beginHide(Token hideKeyword) {
    super.beginHide(hideKeyword);
    begin('Hide');
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    super.beginIfControlFlow(ifToken);
    begin('IfControlFlow');
  }

  @override
  void beginIfStatement(Token token) {
    super.beginIfStatement(token);
    begin('IfStatement');
  }

  @override
  void beginImport(Token importKeyword) {
    super.beginImport(importKeyword);
    begin('Import');
  }

  @override
  void beginInitializedIdentifier(Token token) {
    super.beginInitializedIdentifier(token);
    begin('InitializedIdentifier');
  }

  @override
  void beginInitializer(Token token) {
    super.beginInitializer(token);
    begin('Initializer');
  }

  @override
  void beginInitializers(Token token) {
    super.beginInitializers(token);
    begin('Initializers');
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    super.beginLabeledStatement(token, labelCount);
    begin('LabeledStatement');
  }

  @override
  void beginLibraryName(Token token) {
    super.beginLibraryName(token);
    begin('LibraryName');
  }

  @override
  void beginLiteralString(Token token) {
    super.beginLiteralString(token);
    begin('LiteralString');
  }

  @override
  void beginLiteralSymbol(Token token) {
    super.beginLiteralSymbol(token);
    begin('LiteralSymbol');
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    super.beginLocalFunctionDeclaration(token);
    begin('LocalFunctionDeclaration');
  }

  @override
  void beginMember() {
    expectIn('ClassOrMixinBody');
    super.beginMember();
    begin('Member');
  }

  @override
  void beginMetadata(Token token) {
    expectIn('MetadataStar');
    super.beginMetadata(token);
    begin('Metadata');
  }

  @override
  void beginMetadataStar(Token token) {
    super.beginMetadataStar(token);
    begin('MetadataStar');
  }

  @override
  void beginMethod(
      DeclarationKind declarationKind,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    super.beginMethod(declarationKind, externalToken, staticToken,
        covariantToken, varFinalOrConst, getOrSet, name);
    begin('Method');
  }

  @override
  void beginMixinDeclaration(Token mixinKeyword, Token name) {
    super.beginMixinDeclaration(mixinKeyword, name);
    begin('MixinDeclaration');
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    super.beginNamedFunctionExpression(token);
    begin('NamedFunctionExpression');
  }

  @override
  void beginNamedMixinApplication(
      Token beginToken, Token? abstractToken, Token name) {
    super.beginNamedMixinApplication(beginToken, abstractToken, name);
    begin('NamedMixinApplication');
  }

  @override
  void beginNewExpression(Token token) {
    super.beginNewExpression(token);
    begin('NewExpression');
  }

  @override
  void beginOptionalFormalParameters(Token token) {
    super.beginOptionalFormalParameters(token);
    begin('OptionalFormalParameters');
  }

  @override
  void beginPart(Token token) {
    super.beginPart(token);
    begin('Part');
  }

  @override
  void beginPartOf(Token token) {
    super.beginPartOf(token);
    begin('PartOf');
  }

  @override
  void beginRedirectingFactoryBody(Token token) {
    super.beginRedirectingFactoryBody(token);
    begin('RedirectingFactoryBody');
  }

  @override
  void beginRethrowStatement(Token token) {
    super.beginRethrowStatement(token);
    begin('RethrowStatement');
  }

  @override
  void beginReturnStatement(Token token) {
    super.beginReturnStatement(token);
    begin('ReturnStatement');
  }

  @override
  void beginShow(Token showKeyword) {
    super.beginShow(showKeyword);
    begin('Show');
  }

  @override
  void beginSwitchBlock(Token token) {
    super.beginSwitchBlock(token);
    begin('SwitchBlock');
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    super.beginSwitchCase(labelCount, expressionCount, firstToken);
    begin('SwitchCase');
  }

  @override
  void beginSwitchStatement(Token token) {
    super.beginSwitchStatement(token);
    begin('SwitchStatement');
  }

  @override
  void beginThenStatement(Token token) {
    super.beginThenStatement(token);
    begin('ThenStatement');
  }

  @override
  void beginTopLevelMember(Token token) {
    super.beginTopLevelMember(token);
    begin('TopLevelMember');
  }

  @override
  void beginTopLevelMethod(Token lastConsumed, Token? externalToken) {
    super.beginTopLevelMethod(lastConsumed, externalToken);
    begin('TopLevelMethod');
  }

  @override
  void beginTryStatement(Token token) {
    super.beginTryStatement(token);
    begin('TryStatement');
  }

  @override
  void beginTypeArguments(Token token) {
    super.beginTypeArguments(token);
    begin('TypeArguments');
  }

  @override
  void beginTypedef(Token token) {
    super.beginTypedef(token);
    begin('FunctionTypeAlias');
  }

  @override
  void beginTypeList(Token token) {
    super.beginTypeList(token);
    begin('TypeList');
  }

  @override
  void beginTypeVariable(Token token) {
    super.beginTypeVariable(token);
    begin('TypeVariable');
  }

  @override
  void beginTypeVariables(Token token) {
    super.beginTypeVariables(token);
    begin('TypeVariables');
  }

  @override
  void beginVariableInitializer(Token token) {
    super.beginVariableInitializer(token);
    begin('VariableInitializer');
  }

  @override
  void beginVariablesDeclaration(
      Token token, Token? lateToken, Token? varFinalOrConst) {
    super.beginVariablesDeclaration(token, lateToken, varFinalOrConst);
    begin('VariablesDeclaration');
  }

  @override
  void beginWhileStatement(Token token) {
    super.beginWhileStatement(token);
    begin('WhileStatement');
  }

  @override
  void beginWhileStatementBody(Token token) {
    super.beginWhileStatementBody(token);
    begin('WhileStatementBody');
  }

  @override
  void beginYieldStatement(Token token) {
    super.beginYieldStatement(token);
    begin('YieldStatement');
  }

  void end(String event) {
    expectIn(event);
    _stack.removeLast();
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    end('Arguments');
    super.endArguments(count, beginToken, endToken);
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token? commaToken, Token semicolonToken) {
    end('Assert');
    super.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, semicolonToken);
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    end('AwaitExpression');
    super.endAwaitExpression(beginToken, endToken);
  }

  @override
  void endBlock(
      int count, Token beginToken, Token endToken, BlockKind blockKind) {
    end('Block');
    super.endBlock(count, beginToken, endToken, blockKind);
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    end('BlockFunctionBody');
    super.endBlockFunctionBody(count, beginToken, endToken);
  }

  @override
  void endCascade() {
    end('Cascade');
    super.endCascade();
  }

  @override
  void endCaseExpression(Token colon) {
    end('CaseExpression');
    super.endCaseExpression(colon);
  }

  @override
  void endCatchClause(Token token) {
    end('CatchClause');
    super.endCatchClause(token);
  }

  @override
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    end('Method');
    super.endClassConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    end('ClassDeclaration');
    end('ClassOrNamedMixinApplication');
    super.endClassDeclaration(beginToken, endToken);
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    end('FactoryMethod');
    super.endClassFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endClassFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    // beginMember --> endClassFields, endMember
    expectIn('Member');
    super.endClassFields(
        abstractToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        count,
        beginToken,
        endToken);
  }

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    end('Method');
    super.endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endClassOrMixinOrExtensionBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    end('ClassOrMixinBody');
    super.endClassOrMixinOrExtensionBody(
        kind, memberCount, beginToken, endToken);
  }

  @override
  void endCombinators(int count) {
    end('Combinators');
    super.endCombinators(count);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    end('CompilationUnit');
    super.endCompilationUnit(count, token);
    expectEmpty();
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    end('ConditionalUri');
    super.endConditionalUri(ifKeyword, leftParen, equalSign);
  }

  @override
  void endConditionalUris(int count) {
    end('ConditionalUris');
    super.endConditionalUris(count);
  }

  @override
  void endConstExpression(Token token) {
    end('ConstExpression');
    super.endConstExpression(token);
  }

  @override
  void endConstLiteral(Token token) {
    end('ConstLiteral');
    super.endConstLiteral(token);
  }

  @override
  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    end('ConstructorReference');
    super.endConstructorReference(
        start, periodBeforeName, endToken, constructorReferenceContext);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    end('DoWhileStatement');
    super.endDoWhileStatement(doKeyword, whileKeyword, endToken);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    end('DoWhileStatementBody');
    super.endDoWhileStatementBody(token);
  }

  @override
  void endElseStatement(Token token) {
    end('ElseStatement');
    super.endElseStatement(token);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    end('Enum');
    super.endEnum(enumKeyword, leftBrace, count);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    end('Export');
    super.endExport(exportKeyword, semicolon);
  }

  @override
  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    end('Method');
    super.endExtensionConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endExtensionDeclaration(Token extensionKeyword, Token? typeKeyword,
      Token onKeyword, Token? showKeyword, Token? hideKeyword, Token token) {
    super.endExtensionDeclaration(extensionKeyword, typeKeyword, onKeyword,
        showKeyword, hideKeyword, token);
    end('ExtensionDeclaration');
  }

  @override
  void endExtensionFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    end('FactoryMethod');
    super.endExtensionFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endExtensionFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    // beginMember --> endExtensionFields, endMember
    expectIn('Member');
    super.endExtensionFields(
        abstractToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        count,
        beginToken,
        endToken);
  }

  @override
  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    end('Method');
    super.endExtensionMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    end('FieldInitializer');
    super.endFieldInitializer(assignment, token);
  }

  @override
  void endForControlFlow(Token token) {
    end('ForControlFlow');
    super.endForControlFlow(token);
  }

  @override
  void endForIn(Token endToken) {
    end('ForStatement');
    super.endForIn(endToken);
  }

  @override
  void endForInBody(Token token) {
    end('ForInBody');
    super.endForInBody(token);
  }

  @override
  void endForInControlFlow(Token token) {
    end('ForControlFlow');
    super.endForInControlFlow(token);
  }

  @override
  void endForInExpression(Token token) {
    end('ForInExpression');
    super.endForInExpression(token);
  }

  @override
  void endFormalParameter(
      Token? thisKeyword,
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    end('FormalParameter');
    super.endFormalParameter(thisKeyword, superKeyword, periodAfterThisOrSuper,
        nameToken, initializerStart, initializerEnd, kind, memberKind);
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    end('FormalParameters');
    super.endFormalParameters(count, beginToken, endToken, kind);
  }

  @override
  void endForStatement(Token endToken) {
    end('ForStatement');
    super.endForStatement(endToken);
  }

  @override
  void endForStatementBody(Token token) {
    end('ForStatementBody');
    super.endForStatementBody(token);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    end('FunctionExpression');
    super.endFunctionExpression(beginToken, token);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    end('FunctionName');
    super.endFunctionName(beginToken, token);
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    end('FunctionType');
    super.endFunctionType(functionToken, questionMark);
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    end('FunctionTypedFormalParameter');
    super.endFunctionTypedFormalParameter(nameToken, question);
  }

  @override
  void endHide(Token hideKeyword) {
    end('Hide');
    super.endHide(hideKeyword);
  }

  @override
  void endIfControlFlow(Token token) {
    end('IfControlFlow');
    super.endIfControlFlow(token);
  }

  @override
  void endIfElseControlFlow(Token token) {
    end('IfControlFlow');
    super.endIfElseControlFlow(token);
  }

  @override
  void endIfStatement(Token ifToken, Token? elseToken) {
    end('IfStatement');
    super.endIfStatement(ifToken, elseToken);
  }

  @override
  void endImport(Token importKeyword, Token? semicolon) {
    end('Import');
    super.endImport(importKeyword, semicolon);
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    end('InitializedIdentifier');
    super.endInitializedIdentifier(nameToken);
  }

  @override
  void endInitializer(Token token) {
    end('Initializer');
    super.endInitializer(token);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    end('Initializers');
    super.endInitializers(count, beginToken, endToken);
  }

  @override
  void endInvalidAwaitExpression(
      Token beginToken, Token endToken, MessageCode errorCode) {
    end('InvalidAwaitExpression');
    super.endInvalidAwaitExpression(beginToken, endToken, errorCode);
  }

  @override
  void endInvalidYieldStatement(Token beginToken, Token? starToken,
      Token endToken, MessageCode errorCode) {
    end('InvalidYieldStatement');
    super.endInvalidYieldStatement(beginToken, starToken, endToken, errorCode);
  }

  @override
  void endLabeledStatement(int labelCount) {
    end('LabeledStatement');
    super.endLabeledStatement(labelCount);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    end('LibraryName');
    super.endLibraryName(libraryKeyword, semicolon);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    end('LiteralString');
    super.endLiteralString(interpolationCount, endToken);
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    end('LiteralSymbol');
    super.endLiteralSymbol(hashToken, identifierCount);
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    end('LocalFunctionDeclaration');
    super.endLocalFunctionDeclaration(endToken);
  }

  @override
  void endMember() {
    end('Member');
    super.endMember();
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    end('Metadata');
    super.endMetadata(beginToken, periodBeforeName, endToken);
  }

  @override
  void endMetadataStar(int count) {
    end('MetadataStar');
    super.endMetadataStar(count);
  }

  @override
  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    end('Method');
    super.endMixinConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    end('MixinDeclaration');
    end('ClassOrNamedMixinApplication');
    super.endMixinDeclaration(mixinKeyword, endToken);
  }

  @override
  void endMixinFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    end('FactoryMethod');
    super.endMixinFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endMixinFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    // beginMember --> endMixinFields, endMember
    expectIn('Member');
    super.endMixinFields(
        abstractToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        count,
        beginToken,
        endToken);
  }

  @override
  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    end('Method');
    super.endMixinMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    end('NamedFunctionExpression');
    super.endNamedFunctionExpression(endToken);
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token? implementsKeyword, Token endToken) {
    end('NamedMixinApplication');
    end('ClassOrNamedMixinApplication');
    super.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, endToken);
  }

  @override
  void endNewExpression(Token token) {
    end('NewExpression');
    super.endNewExpression(token);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    end('OptionalFormalParameters');
    super.endOptionalFormalParameters(count, beginToken, endToken);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    end('Part');
    super.endPart(partKeyword, semicolon);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    end('PartOf');
    super.endPartOf(partKeyword, ofKeyword, semicolon, hasName);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    end('RedirectingFactoryBody');
    super.endRedirectingFactoryBody(beginToken, endToken);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    end('RethrowStatement');
    super.endRethrowStatement(rethrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    end('ReturnStatement');
    super.endReturnStatement(hasExpression, beginToken, endToken);
  }

  @override
  void endShow(Token showKeyword) {
    end('Show');
    super.endShow(showKeyword);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    end('SwitchBlock');
    super.endSwitchBlock(caseCount, beginToken, endToken);
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token? defaultKeyword,
      Token? colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    end('SwitchCase');
    super.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        colonAfterDefault, statementCount, firstToken, endToken);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    end('SwitchStatement');
    super.endSwitchStatement(switchKeyword, endToken);
  }

  @override
  void endThenStatement(Token token) {
    end('ThenStatement');
    super.endThenStatement(token);
  }

  @override
  void endTopLevelDeclaration(Token token) {
    // There is no corresponding beginTopLevelDeclaration.
    // It is insteads started by another begin, see listener.
    //_expectBegin('TopLevelDeclaration');
    expectIn('CompilationUnit');
    super.endTopLevelDeclaration(token);
  }

  @override
  void endTopLevelFields(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    end('TopLevelMember');
    super.endTopLevelFields(externalToken, staticToken, covariantToken,
        lateToken, varFinalOrConst, count, beginToken, endToken);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    end('TopLevelMethod');
    end('TopLevelMember');
    super.endTopLevelMethod(beginToken, getOrSet, endToken);
  }

  @override
  void endTryStatement(
      int catchCount, Token tryKeyword, Token? finallyKeyword) {
    end('TryStatement');
    super.endTryStatement(catchCount, tryKeyword, finallyKeyword);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    end('TypeArguments');
    super.endTypeArguments(count, beginToken, endToken);
  }

  @override
  void endTypedef(Token typedefKeyword, Token? equals, Token endToken) {
    end('FunctionTypeAlias');
    super.endTypedef(typedefKeyword, equals, endToken);
  }

  @override
  void endTypeList(int count) {
    end('TypeList');
    super.endTypeList(count);
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    end('TypeVariable');
    super.endTypeVariable(token, index, extendsOrSuper, variance);
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    end('TypeVariables');
    super.endTypeVariables(beginToken, endToken);
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    end('VariableInitializer');
    super.endVariableInitializer(assignmentOperator);
  }

  @override
  void endVariablesDeclaration(int count, Token? endToken) {
    end('VariablesDeclaration');
    super.endVariablesDeclaration(count, endToken);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    end('WhileStatement');
    super.endWhileStatement(whileKeyword, endToken);
  }

  @override
  void endWhileStatementBody(Token token) {
    end('WhileStatementBody');
    super.endWhileStatementBody(token);
  }

  @override
  void endYieldStatement(Token yieldToken, Token? starToken, Token endToken) {
    end('YieldStatement');
    super.endYieldStatement(yieldToken, starToken, endToken);
  }

  void expectEmpty() {
    expect(_stack, isEmpty);
  }

  void expectIn(String event) {
    if (_stack.isEmpty || _stack.last != event) {
      fail('Expected $event, but found $_stack');
    }
  }

  void expectInOneOf(List<String> events) {
    if (_stack.isEmpty || !events.contains(_stack.last)) {
      fail('Expected one of $events, but found $_stack');
    }
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    expectIn('ClassDeclaration');
    listener?.handleClassExtends(extendsKeyword, typeCount);
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    expectIn('ClassDeclaration');
    listener?.handleClassHeader(begin, classKeyword, nativeToken);
  }

  @override
  void handleClassOrMixinImplements(
      Token? implementsKeyword, int interfacesCount) {
    expectInOneOf(['ClassDeclaration', 'MixinDeclaration']);
    listener?.handleClassOrMixinImplements(implementsKeyword, interfacesCount);
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    expectIn('ConditionalUri');
    super.handleDottedName(count, firstIdentifier);
  }

  @override
  void handleIdentifierList(int count) {
    expectInOneOf(['Hide', 'Show']);
    super.handleIdentifierList(count);
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    // This event normally happens within "Import",
    // but happens within "CompilationUnit" during recovery.
    expectInOneOf(const ['Import', 'CompilationUnit']);
    listener?.handleImportPrefix(deferredKeyword, asKeyword);
  }

  @override
  void handleInvalidMember(Token endToken) {
    expectIn('Member');
    super.handleInvalidMember(endToken);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    end('TopLevelMember');
    listener?.handleInvalidTopLevelDeclaration(endToken);
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    expectInOneOf(['ClassDeclaration', 'Method']);
    listener?.handleNativeClause(nativeToken, hasName);
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    expectInOneOf(['Method']);
    listener?.handleNativeFunctionBody(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    expectInOneOf(['Method']);
    listener?.handleNativeFunctionBodyIgnored(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    expectInOneOf(['Method']);
    listener?.handleNativeFunctionBodySkipped(nativeToken, semicolon);
  }

  @override
  void handleRecoverClassHeader() {
    expectIn('ClassDeclaration');
    listener?.handleRecoverClassHeader();
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    expectIn('CompilationUnit');
    listener?.handleRecoverImport(semicolon);
  }

  @override
  void handleRecoverMixinHeader() {
    expectIn('MixinDeclaration');
    listener?.handleRecoverMixinHeader();
  }

  @override
  void handleScript(Token token) {
    expectIn('CompilationUnit');
    listener?.handleScript(token);
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    listener?.handleTypeVariablesDefined(token, count);
  }
}
