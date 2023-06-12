// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart';
import '../scanner/scanner.dart';
import 'parser.dart';

class ForwardingListener implements Listener {
  Listener? listener;
  bool forwardErrors = true;

  ForwardingListener([this.listener]);

  @override
  Uri? get uri => listener?.uri;

  @override
  void beginArguments(Token token) {
    listener?.beginArguments(token);
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    listener?.beginAssert(assertKeyword, kind);
  }

  @override
  void beginAwaitExpression(Token token) {
    listener?.beginAwaitExpression(token);
  }

  @override
  void beginBinaryExpression(Token token) {
    listener?.beginBinaryExpression(token);
  }

  @override
  void beginBlock(Token token, BlockKind blockKind) {
    listener?.beginBlock(token, blockKind);
  }

  @override
  void beginBlockFunctionBody(Token token) {
    listener?.beginBlockFunctionBody(token);
  }

  @override
  void beginCascade(Token token) {
    listener?.beginCascade(token);
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    listener?.beginCaseExpression(caseKeyword);
  }

  @override
  void beginCatchClause(Token token) {
    listener?.beginCatchClause(token);
  }

  @override
  void beginClassDeclaration(Token begin, Token? abstractToken,
      Token? macroToken, Token? augmentToken, Token name) {
    listener?.beginClassDeclaration(
        begin, abstractToken, macroToken, augmentToken, name);
  }

  @override
  void beginClassOrMixinOrExtensionBody(DeclarationKind kind, Token token) {
    listener?.beginClassOrMixinOrExtensionBody(kind, token);
  }

  @override
  void beginClassOrMixinOrNamedMixinApplicationPrelude(Token token) {
    listener?.beginClassOrMixinOrNamedMixinApplicationPrelude(token);
  }

  @override
  void beginCombinators(Token token) {
    listener?.beginCombinators(token);
  }

  @override
  void beginCompilationUnit(Token token) {
    listener?.beginCompilationUnit(token);
  }

  @override
  void beginConditionalExpression(Token question) {
    listener?.beginConditionalExpression(question);
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    listener?.beginConditionalUri(ifKeyword);
  }

  @override
  void beginConditionalUris(Token token) {
    listener?.beginConditionalUris(token);
  }

  @override
  void beginConstExpression(Token constKeyword) {
    listener?.beginConstExpression(constKeyword);
  }

  @override
  void beginConstLiteral(Token token) {
    listener?.beginConstLiteral(token);
  }

  @override
  void beginConstructorReference(Token start) {
    listener?.beginConstructorReference(start);
  }

  @override
  void beginDoWhileStatement(Token token) {
    listener?.beginDoWhileStatement(token);
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    listener?.beginDoWhileStatementBody(token);
  }

  @override
  void beginElseStatement(Token token) {
    listener?.beginElseStatement(token);
  }

  @override
  void beginEnum(Token enumKeyword) {
    listener?.beginEnum(enumKeyword);
  }

  @override
  void beginExport(Token token) {
    listener?.beginExport(token);
  }

  @override
  void beginUncategorizedTopLevelDeclaration(Token token) {
    listener?.beginUncategorizedTopLevelDeclaration(token);
  }

  @override
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {
    listener?.beginExtensionDeclarationPrelude(extensionKeyword);
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? name) {
    listener?.beginExtensionDeclaration(extensionKeyword, name);
  }

  @override
  void beginFactoryMethod(DeclarationKind declarationKind, Token lastConsumed,
      Token? externalToken, Token? constToken) {
    listener?.beginFactoryMethod(
        declarationKind, lastConsumed, externalToken, constToken);
  }

  @override
  void beginFieldInitializer(Token token) {
    listener?.beginFieldInitializer(token);
  }

  @override
  void beginForControlFlow(Token? awaitToken, Token forToken) {
    listener?.beginForControlFlow(awaitToken, forToken);
  }

  @override
  void beginForInBody(Token token) {
    listener?.beginForInBody(token);
  }

  @override
  void beginForInExpression(Token token) {
    listener?.beginForInExpression(token);
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {
    listener?.beginFormalParameter(
        token, kind, requiredToken, covariantToken, varFinalOrConst);
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    listener?.beginFormalParameterDefaultValueExpression();
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    listener?.beginFormalParameters(token, kind);
  }

  @override
  void beginForStatement(Token token) {
    listener?.beginForStatement(token);
  }

  @override
  void beginForStatementBody(Token token) {
    listener?.beginForStatementBody(token);
  }

  @override
  void beginFunctionExpression(Token token) {
    listener?.beginFunctionExpression(token);
  }

  @override
  void beginFunctionName(Token token) {
    listener?.beginFunctionName(token);
  }

  @override
  void beginFunctionType(Token beginToken) {
    listener?.beginFunctionType(beginToken);
  }

  @override
  void beginTypedef(Token token) {
    listener?.beginTypedef(token);
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    listener?.beginFunctionTypedFormalParameter(token);
  }

  @override
  void beginHide(Token hideKeyword) {
    listener?.beginHide(hideKeyword);
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    listener?.beginIfControlFlow(ifToken);
  }

  @override
  void beginIfStatement(Token token) {
    listener?.beginIfStatement(token);
  }

  @override
  void beginImplicitCreationExpression(Token token) {
    listener?.beginImplicitCreationExpression(token);
  }

  @override
  void beginImport(Token importKeyword) {
    listener?.beginImport(importKeyword);
  }

  @override
  void beginInitializedIdentifier(Token token) {
    listener?.beginInitializedIdentifier(token);
  }

  @override
  void beginInitializer(Token token) {
    listener?.beginInitializer(token);
  }

  @override
  void beginInitializers(Token token) {
    listener?.beginInitializers(token);
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    listener?.beginLabeledStatement(token, labelCount);
  }

  @override
  void beginLibraryAugmentation(Token libraryKeyword, Token augmentKeyword) {
    listener?.beginLibraryAugmentation(libraryKeyword, augmentKeyword);
  }

  @override
  void endLibraryAugmentation(
      Token libraryKeyword, Token augmentKeyword, Token semicolon) {
    listener?.endLibraryAugmentation(libraryKeyword, augmentKeyword, semicolon);
  }

  @override
  void beginLibraryName(Token token) {
    listener?.beginLibraryName(token);
  }

  @override
  void beginLiteralString(Token token) {
    listener?.beginLiteralString(token);
  }

  @override
  void beginLiteralSymbol(Token token) {
    listener?.beginLiteralSymbol(token);
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    listener?.beginLocalFunctionDeclaration(token);
  }

  @override
  void beginMember() {
    listener?.beginMember();
  }

  @override
  void beginMetadata(Token token) {
    listener?.beginMetadata(token);
  }

  @override
  void beginMetadataStar(Token token) {
    listener?.beginMetadataStar(token);
  }

  @override
  void beginMethod(
      DeclarationKind declarationKind,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    listener?.beginMethod(declarationKind, augmentToken, externalToken,
        staticToken, covariantToken, varFinalOrConst, getOrSet, name);
  }

  @override
  void beginMixinDeclaration(
      Token? augmentToken, Token mixinKeyword, Token name) {
    listener?.beginMixinDeclaration(augmentToken, mixinKeyword, name);
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    listener?.beginNamedFunctionExpression(token);
  }

  @override
  void beginNamedMixinApplication(Token begin, Token? abstractToken,
      Token? macroToken, Token? augmentToken, Token name) {
    listener?.beginNamedMixinApplication(
        begin, abstractToken, macroToken, augmentToken, name);
  }

  @override
  void beginNewExpression(Token token) {
    listener?.beginNewExpression(token);
  }

  @override
  void beginOptionalFormalParameters(Token token) {
    listener?.beginOptionalFormalParameters(token);
  }

  @override
  void beginPart(Token token) {
    listener?.beginPart(token);
  }

  @override
  void beginPartOf(Token token) {
    listener?.beginPartOf(token);
  }

  @override
  void beginRedirectingFactoryBody(Token token) {
    listener?.beginRedirectingFactoryBody(token);
  }

  @override
  void beginRethrowStatement(Token token) {
    listener?.beginRethrowStatement(token);
  }

  @override
  void beginReturnStatement(Token token) {
    listener?.beginReturnStatement(token);
  }

  @override
  void beginShow(Token showKeyword) {
    listener?.beginShow(showKeyword);
  }

  @override
  void beginSwitchBlock(Token token) {
    listener?.beginSwitchBlock(token);
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    listener?.beginSwitchCase(labelCount, expressionCount, firstToken);
  }

  @override
  void beginSwitchStatement(Token token) {
    listener?.beginSwitchStatement(token);
  }

  @override
  void handleThenControlFlow(Token token) {
    listener?.handleThenControlFlow(token);
  }

  @override
  void beginThenStatement(Token token) {
    listener?.beginThenStatement(token);
  }

  @override
  void beginTopLevelMember(Token token) {
    listener?.beginTopLevelMember(token);
  }

  @override
  void beginTopLevelMethod(
      Token lastConsumed, Token? augmentToken, Token? externalToken) {
    listener?.beginTopLevelMethod(lastConsumed, augmentToken, externalToken);
  }

  @override
  void beginTryStatement(Token token) {
    listener?.beginTryStatement(token);
  }

  @override
  void beginTypeArguments(Token token) {
    listener?.beginTypeArguments(token);
  }

  @override
  void beginTypeList(Token token) {
    listener?.beginTypeList(token);
  }

  @override
  void beginTypeVariable(Token token) {
    listener?.beginTypeVariable(token);
  }

  @override
  void beginTypeVariables(Token token) {
    listener?.beginTypeVariables(token);
  }

  @override
  void beginVariableInitializer(Token token) {
    listener?.beginVariableInitializer(token);
  }

  @override
  void beginVariablesDeclaration(
      Token token, Token? lateToken, Token? varFinalOrConst) {
    listener?.beginVariablesDeclaration(token, lateToken, varFinalOrConst);
  }

  @override
  void beginWhileStatement(Token token) {
    listener?.beginWhileStatement(token);
  }

  @override
  void beginWhileStatementBody(Token token) {
    listener?.beginWhileStatementBody(token);
  }

  @override
  void beginYieldStatement(Token token) {
    listener?.beginYieldStatement(token);
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    listener?.endArguments(count, beginToken, endToken);
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token? commaToken, Token semicolonToken) {
    listener?.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, semicolonToken);
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    listener?.endAwaitExpression(beginToken, endToken);
  }

  @override
  void endBinaryExpression(Token token) {
    listener?.endBinaryExpression(token);
  }

  @override
  void handleEndingBinaryExpression(Token token) {
    listener?.handleEndingBinaryExpression(token);
  }

  @override
  void endBlock(
      int count, Token beginToken, Token endToken, BlockKind blockKind) {
    listener?.endBlock(count, beginToken, endToken, blockKind);
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    listener?.endBlockFunctionBody(count, beginToken, endToken);
  }

  @override
  void endCascade() {
    listener?.endCascade();
  }

  @override
  void endCaseExpression(Token colon) {
    listener?.endCaseExpression(colon);
  }

  @override
  void endCatchClause(Token token) {
    listener?.endCatchClause(token);
  }

  @override
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    listener?.endClassConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    listener?.endClassDeclaration(beginToken, endToken);
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    listener?.endClassFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
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
    listener?.endClassFields(
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

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    listener?.endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endClassOrMixinOrExtensionBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    listener?.endClassOrMixinOrExtensionBody(
        kind, memberCount, beginToken, endToken);
  }

  @override
  void endCombinators(int count) {
    listener?.endCombinators(count);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    listener?.endCompilationUnit(count, token);
  }

  @override
  void endConditionalExpression(Token question, Token colon) {
    listener?.endConditionalExpression(question, colon);
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    listener?.endConditionalUri(ifKeyword, leftParen, equalSign);
  }

  @override
  void endConditionalUris(int count) {
    listener?.endConditionalUris(count);
  }

  @override
  void endConstExpression(Token token) {
    listener?.endConstExpression(token);
  }

  @override
  void endConstLiteral(Token token) {
    listener?.endConstLiteral(token);
  }

  @override
  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    listener?.endConstructorReference(
        start, periodBeforeName, endToken, constructorReferenceContext);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    listener?.endDoWhileStatement(doKeyword, whileKeyword, endToken);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    listener?.endDoWhileStatementBody(token);
  }

  @override
  void endElseStatement(Token token) {
    listener?.endElseStatement(token);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int memberCount) {
    listener?.endEnum(enumKeyword, leftBrace, memberCount);
  }

  @override
  void endEnumConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    listener?.endEnumConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void handleEnumElement(Token beginToken) {
    listener?.handleEnumElement(beginToken);
  }

  @override
  void handleEnumElements(Token elementsEndToken, int elementsCount) {
    listener?.handleEnumElements(elementsEndToken, elementsCount);
  }

  @override
  void handleEnumHeader(Token enumKeyword, Token leftBrace) {
    listener?.handleEnumHeader(enumKeyword, leftBrace);
  }

  @override
  void endEnumFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    listener?.endEnumFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
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
    listener?.endClassFields(
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

  @override
  void endEnumMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    listener?.endEnumMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    listener?.endExport(exportKeyword, semicolon);
  }

  @override
  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    listener?.endExtensionConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endExtensionDeclaration(Token extensionKeyword, Token? typeKeyword,
      Token onKeyword, Token? showKeyword, Token? hideKeyword, Token endToken) {
    listener?.endExtensionDeclaration(extensionKeyword, typeKeyword, onKeyword,
        showKeyword, hideKeyword, endToken);
  }

  @override
  void endExtensionFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    listener?.endExtensionFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
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
    listener?.endExtensionFields(
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

  @override
  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    listener?.endExtensionMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    listener?.endFieldInitializer(assignment, token);
  }

  @override
  void endForControlFlow(Token token) {
    listener?.endForControlFlow(token);
  }

  @override
  void endForIn(Token endToken) {
    listener?.endForIn(endToken);
  }

  @override
  void endForInBody(Token token) {
    listener?.endForInBody(token);
  }

  @override
  void endForInControlFlow(Token token) {
    listener?.endForInControlFlow(token);
  }

  @override
  void endForInExpression(Token token) {
    listener?.endForInExpression(token);
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
    listener?.endFormalParameter(
        thisKeyword,
        superKeyword,
        periodAfterThisOrSuper,
        nameToken,
        initializerStart,
        initializerEnd,
        kind,
        memberKind);
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    listener?.endFormalParameterDefaultValueExpression();
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    listener?.endFormalParameters(count, beginToken, endToken, kind);
  }

  @override
  void endForStatement(Token endToken) {
    listener?.endForStatement(endToken);
  }

  @override
  void endForStatementBody(Token token) {
    listener?.endForStatementBody(token);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    listener?.endFunctionExpression(beginToken, token);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    listener?.endFunctionName(beginToken, token);
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    listener?.endFunctionType(functionToken, questionMark);
  }

  @override
  void endTypedef(Token typedefKeyword, Token? equals, Token endToken) {
    listener?.endTypedef(typedefKeyword, equals, endToken);
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    listener?.endFunctionTypedFormalParameter(nameToken, question);
  }

  @override
  void handleTypeArgumentApplication(Token openAngleBracket) {
    listener?.handleTypeArgumentApplication(openAngleBracket);
  }

  @override
  void endHide(Token hideKeyword) {
    listener?.endHide(hideKeyword);
  }

  @override
  void endIfControlFlow(Token token) {
    listener?.endIfControlFlow(token);
  }

  @override
  void endIfElseControlFlow(Token token) {
    listener?.endIfElseControlFlow(token);
  }

  @override
  void endIfStatement(Token ifToken, Token? elseToken) {
    listener?.endIfStatement(ifToken, elseToken);
  }

  @override
  void endImplicitCreationExpression(Token token, Token openAngleBracket) {
    listener?.endImplicitCreationExpression(token, openAngleBracket);
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    listener?.endImport(importKeyword, augmentToken, semicolon);
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    listener?.endInitializedIdentifier(nameToken);
  }

  @override
  void endInitializer(Token token) {
    listener?.endInitializer(token);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    listener?.endInitializers(count, beginToken, endToken);
  }

  @override
  void endInvalidAwaitExpression(
      Token beginToken, Token endToken, MessageCode errorCode) {
    listener?.endInvalidAwaitExpression(beginToken, endToken, errorCode);
  }

  @override
  void endInvalidYieldStatement(Token beginToken, Token? starToken,
      Token endToken, MessageCode errorCode) {
    listener?.endInvalidYieldStatement(
        beginToken, starToken, endToken, errorCode);
  }

  @override
  void endLabeledStatement(int labelCount) {
    listener?.endLabeledStatement(labelCount);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    listener?.endLibraryName(libraryKeyword, semicolon);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    listener?.endLiteralString(interpolationCount, endToken);
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    listener?.endLiteralSymbol(hashToken, identifierCount);
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    listener?.endLocalFunctionDeclaration(endToken);
  }

  @override
  void endMember() {
    listener?.endMember();
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    listener?.endMetadata(beginToken, periodBeforeName, endToken);
  }

  @override
  void endMetadataStar(int count) {
    listener?.endMetadataStar(count);
  }

  @override
  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    listener?.endMixinConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    listener?.endMixinDeclaration(mixinKeyword, endToken);
  }

  @override
  void endMixinFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    listener?.endMixinFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
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
    listener?.endMixinFields(
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

  @override
  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    listener?.endMixinMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    listener?.endNamedFunctionExpression(endToken);
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token? implementsKeyword, Token endToken) {
    listener?.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, endToken);
  }

  @override
  void endNewExpression(Token token) {
    listener?.endNewExpression(token);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    listener?.endOptionalFormalParameters(count, beginToken, endToken);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    listener?.endPart(partKeyword, semicolon);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    listener?.endPartOf(partKeyword, ofKeyword, semicolon, hasName);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    listener?.endRedirectingFactoryBody(beginToken, endToken);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    listener?.endRethrowStatement(rethrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    listener?.endReturnStatement(hasExpression, beginToken, endToken);
  }

  @override
  void endShow(Token showKeyword) {
    listener?.endShow(showKeyword);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    listener?.endSwitchBlock(caseCount, beginToken, endToken);
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
    listener?.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        colonAfterDefault, statementCount, firstToken, endToken);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    listener?.endSwitchStatement(switchKeyword, endToken);
  }

  @override
  void endThenStatement(Token token) {
    listener?.endThenStatement(token);
  }

  @override
  void endTopLevelDeclaration(Token nextToken) {
    listener?.endTopLevelDeclaration(nextToken);
  }

  @override
  void beginFields(
      DeclarationKind declarationKind,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token lastConsumed) {
    listener?.beginFields(
        declarationKind,
        abstractToken,
        augmentToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        lastConsumed);
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
    listener?.endTopLevelFields(externalToken, staticToken, covariantToken,
        lateToken, varFinalOrConst, count, beginToken, endToken);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    listener?.endTopLevelMethod(beginToken, getOrSet, endToken);
  }

  @override
  void endTryStatement(
      int catchCount, Token tryKeyword, Token? finallyKeyword) {
    listener?.endTryStatement(catchCount, tryKeyword, finallyKeyword);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    listener?.endTypeArguments(count, beginToken, endToken);
  }

  @override
  void endTypeList(int count) {
    listener?.endTypeList(count);
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    listener?.endTypeVariable(token, index, extendsOrSuper, variance);
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    listener?.endTypeVariables(beginToken, endToken);
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    listener?.endVariableInitializer(assignmentOperator);
  }

  @override
  void endVariablesDeclaration(int count, Token? endToken) {
    listener?.endVariablesDeclaration(count, endToken);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    listener?.endWhileStatement(whileKeyword, endToken);
  }

  @override
  void endWhileStatementBody(Token token) {
    listener?.endWhileStatementBody(token);
  }

  @override
  void endYieldStatement(Token yieldToken, Token? starToken, Token endToken) {
    listener?.endYieldStatement(yieldToken, starToken, endToken);
  }

  @override
  void beginAsOperatorType(Token operator) {
    listener?.beginAsOperatorType(operator);
  }

  @override
  void endAsOperatorType(Token operator) {
    listener?.endAsOperatorType(operator);
  }

  @override
  void handleAsOperator(Token operator) {
    listener?.handleAsOperator(operator);
  }

  @override
  void handleAssignmentExpression(Token token) {
    listener?.handleAssignmentExpression(token);
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    listener?.handleAsyncModifier(asyncToken, starToken);
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    listener?.handleBreakStatement(hasTarget, breakKeyword, endToken);
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    listener?.handleCaseMatch(caseKeyword, colon);
  }

  @override
  void handleCatchBlock(Token? onKeyword, Token? catchKeyword, Token? comma) {
    listener?.handleCatchBlock(onKeyword, catchKeyword, comma);
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    listener?.handleClassExtends(extendsKeyword, typeCount);
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    listener?.handleClassHeader(begin, classKeyword, nativeToken);
  }

  @override
  void handleClassNoWithClause() {
    listener?.handleClassNoWithClause();
  }

  @override
  void handleEnumNoWithClause() {
    listener?.handleEnumNoWithClause();
  }

  @override
  void handleImplements(Token? implementsKeyword, int interfacesCount) {
    listener?.handleImplements(implementsKeyword, interfacesCount);
  }

  @override
  void handleExtensionShowHide(Token? showKeyword, int showElementCount,
      Token? hideKeyword, int hideElementCount) {
    listener?.handleExtensionShowHide(
        showKeyword, showElementCount, hideKeyword, hideElementCount);
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    listener?.handleClassWithClause(withKeyword);
  }

  @override
  void handleEnumWithClause(Token withKeyword) {
    listener?.handleEnumWithClause(withKeyword);
  }

  @override
  void handleCommentReference(
      Token? newKeyword,
      Token? firstToken,
      Token? firstPeriod,
      Token? secondToken,
      Token? secondPeriod,
      Token thirdToken) {
    listener?.handleCommentReference(newKeyword, firstToken, firstPeriod,
        secondToken, secondPeriod, thirdToken);
  }

  @override
  void handleCommentReferenceText(String referenceSource, int referenceOffset) {
    listener?.handleCommentReferenceText(referenceSource, referenceOffset);
  }

  @override
  void handleConditionalExpressionColon() {
    listener?.handleConditionalExpressionColon();
  }

  @override
  void handleConstFactory(Token constKeyword) {
    listener?.handleConstFactory(constKeyword);
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    listener?.handleContinueStatement(hasTarget, continueKeyword, endToken);
  }

  @override
  void handleDirectivesOnly() {
    listener?.handleDirectivesOnly();
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    listener?.handleDottedName(count, firstIdentifier);
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    listener?.handleElseControlFlow(elseToken);
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    listener?.handleEmptyFunctionBody(semicolon);
  }

  @override
  void handleEmptyStatement(Token token) {
    listener?.handleEmptyStatement(token);
  }

  @override
  void handleErrorToken(ErrorToken token) {
    listener?.handleErrorToken(token);
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token? endToken) {
    listener?.handleExpressionFunctionBody(arrowToken, endToken);
  }

  @override
  void handleExpressionStatement(Token token) {
    listener?.handleExpressionStatement(token);
  }

  @override
  void handleExtraneousExpression(Token token, Message message) {
    listener?.handleExtraneousExpression(token, message);
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    listener?.handleFinallyBlock(finallyKeyword);
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    listener?.handleForInitializerEmptyStatement(token);
  }

  @override
  void handleForInitializerExpressionStatement(Token token, bool forIn) {
    listener?.handleForInitializerExpressionStatement(token, forIn);
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token, bool forIn) {
    listener?.handleForInitializerLocalVariableDeclaration(token, forIn);
  }

  @override
  void handleForInLoopParts(Token? awaitToken, Token forToken,
      Token leftParenthesis, Token inKeyword) {
    listener?.handleForInLoopParts(
        awaitToken, forToken, leftParenthesis, inKeyword);
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    listener?.handleForLoopParts(
        forKeyword, leftParen, leftSeparator, updateExpressionCount);
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    listener?.handleFormalParameterWithoutValue(token);
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    listener?.handleFunctionBodySkipped(token, isExpressionBody);
  }

  @override
  void handleShowHideIdentifier(Token? modifier, Token identifier) {
    listener?.handleShowHideIdentifier(modifier, identifier);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    listener?.handleIdentifier(token, context);
  }

  @override
  void handleIdentifierList(int count) {
    listener?.handleIdentifierList(count);
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    listener?.handleImportPrefix(deferredKeyword, asKeyword);
  }

  @override
  void handleIndexedExpression(
      Token? question, Token openSquareBracket, Token closeSquareBracket) {
    listener?.handleIndexedExpression(
        question, openSquareBracket, closeSquareBracket);
  }

  @override
  void handleInterpolationExpression(Token leftBracket, Token? rightBracket) {
    listener?.handleInterpolationExpression(leftBracket, rightBracket);
  }

  @override
  void handleInvalidExpression(Token token) {
    listener?.handleInvalidExpression(token);
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    listener?.handleInvalidFunctionBody(token);
  }

  @override
  void handleInvalidMember(Token endToken) {
    listener?.handleInvalidMember(endToken);
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    listener?.handleInvalidOperatorName(operatorKeyword, token);
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    listener?.handleInvalidStatement(token, message);
  }

  void handleInvalidTopLevelBlock(Token token) {
    listener?.handleInvalidTopLevelBlock(token);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    listener?.handleInvalidTopLevelDeclaration(endToken);
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    listener?.handleInvalidTypeArguments(token);
  }

  @override
  void handleInvalidTypeReference(Token token) {
    listener?.handleInvalidTypeReference(token);
  }

  @override
  void beginIsOperatorType(Token operator) {
    listener?.beginIsOperatorType(operator);
  }

  @override
  void endIsOperatorType(Token operator) {
    listener?.endIsOperatorType(operator);
  }

  @override
  void handleIsOperator(Token isOperator, Token? not) {
    listener?.handleIsOperator(isOperator, not);
  }

  @override
  void handleLabel(Token token) {
    listener?.handleLabel(token);
  }

  @override
  void handleLiteralBool(Token token) {
    listener?.handleLiteralBool(token);
  }

  @override
  void handleLiteralDouble(Token token) {
    listener?.handleLiteralDouble(token);
  }

  @override
  void handleLiteralInt(Token token) {
    listener?.handleLiteralInt(token);
  }

  @override
  void handleLiteralList(
      int count, Token beginToken, Token? constKeyword, Token endToken) {
    listener?.handleLiteralList(count, beginToken, constKeyword, endToken);
  }

  @override
  void handleLiteralMapEntry(Token colon, Token endToken) {
    listener?.handleLiteralMapEntry(colon, endToken);
  }

  @override
  void handleLiteralNull(Token token) {
    listener?.handleLiteralNull(token);
  }

  @override
  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token? constKeyword,
    Token rightBrace,
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool hasSetEntry,
  ) {
    listener?.handleLiteralSetOrMap(
        count, leftBrace, constKeyword, rightBrace, hasSetEntry);
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    listener?.handleMixinHeader(mixinKeyword);
  }

  @override
  void handleMixinOn(Token? onKeyword, int typeCount) {
    listener?.handleMixinOn(onKeyword, typeCount);
  }

  @override
  void handleNamedArgument(Token colon) {
    listener?.handleNamedArgument(colon);
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    listener?.handleNamedMixinApplicationWithClause(withKeyword);
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    listener?.handleNativeClause(nativeToken, hasName);
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    listener?.handleNativeFunctionBody(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    listener?.handleNativeFunctionBodyIgnored(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    listener?.handleNativeFunctionBodySkipped(nativeToken, semicolon);
  }

  @override
  void handleNewAsIdentifier(Token token) {
    listener?.handleNewAsIdentifier(token);
  }

  @override
  void handleNoArguments(Token token) {
    listener?.handleNoArguments(token);
  }

  @override
  void handleNoCommentReference() {
    listener?.handleNoCommentReference();
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    listener?.handleNoConstructorReferenceContinuationAfterTypeArguments(token);
  }

  @override
  void handleNoFieldInitializer(Token token) {
    listener?.handleNoFieldInitializer(token);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    listener?.handleNoFormalParameters(token, kind);
  }

  @override
  void handleNoFunctionBody(Token token) {
    listener?.handleNoFunctionBody(token);
  }

  @override
  void handleNoInitializers() {
    listener?.handleNoInitializers();
  }

  @override
  void handleNoName(Token token) {
    listener?.handleNoName(token);
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    listener?.handleNonNullAssertExpression(bang);
  }

  @override
  void handleNoType(Token lastConsumed) {
    listener?.handleNoType(lastConsumed);
  }

  @override
  void handleNoTypeArguments(Token token) {
    listener?.handleNoTypeArguments(token);
  }

  @override
  void handleNoTypeNameInConstructorReference(Token token) {
    listener?.handleNoTypeNameInConstructorReference(token);
  }

  @override
  void handleNoTypeVariables(Token token) {
    listener?.handleNoTypeVariables(token);
  }

  @override
  void handleNoVariableInitializer(Token token) {
    listener?.handleNoVariableInitializer(token);
  }

  @override
  void handleOperator(Token token) {
    listener?.handleOperator(token);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    listener?.handleOperatorName(operatorKeyword, token);
  }

  @override
  void handleParenthesizedCondition(Token token) {
    listener?.handleParenthesizedCondition(token);
  }

  @override
  void handleParenthesizedExpression(Token token) {
    listener?.handleParenthesizedExpression(token);
  }

  @override
  void handleQualified(Token period) {
    listener?.handleQualified(period);
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    if (forwardErrors) {
      listener?.handleRecoverableError(message, startToken, endToken);
    }
  }

  @override
  void handleRecoverClassHeader() {
    listener?.handleRecoverClassHeader();
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    listener?.handleRecoverImport(semicolon);
  }

  @override
  void handleRecoverMixinHeader() {
    listener?.handleRecoverMixinHeader();
  }

  @override
  void handleScript(Token token) {
    listener?.handleScript(token);
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    listener?.handleSend(beginToken, endToken);
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    listener?.handleSpreadExpression(spreadToken);
  }

  @override
  void handleStringJuxtaposition(Token startToken, int literalCount) {
    listener?.handleStringJuxtaposition(startToken, literalCount);
  }

  @override
  void handleStringPart(Token token) {
    listener?.handleStringPart(token);
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    listener?.handleSuperExpression(token, context);
  }

  @override
  void handleAugmentSuperExpression(
      Token augmentToken, Token superToken, IdentifierContext context) {
    listener?.handleAugmentSuperExpression(augmentToken, superToken, context);
  }

  @override
  void handleSymbolVoid(Token token) {
    listener?.handleSymbolVoid(token);
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    listener?.handleThisExpression(token, context);
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    listener?.handleThrowExpression(throwToken, endToken);
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    listener?.handleType(beginToken, questionMark);
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    listener?.handleTypeVariablesDefined(token, count);
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    listener?.handleUnaryPostfixAssignmentExpression(token);
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    listener?.handleUnaryPrefixAssignmentExpression(token);
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    listener?.handleUnaryPrefixExpression(token);
  }

  @override
  void handleUnescapeError(
      Message message, Token location, int offset, int length) {
    listener?.handleUnescapeError(message, location, offset, length);
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    listener?.handleValuedFormalParameter(equals, token);
  }

  @override
  void handleVoidKeyword(Token token) {
    listener?.handleVoidKeyword(token);
  }

  @override
  void handleVoidKeywordWithTypeArguments(Token token) {
    listener?.handleVoidKeywordWithTypeArguments(token);
  }

  @override
  void logEvent(String name) {
    listener?.logEvent(name);
  }

  @override
  void reportVarianceModifierNotEnabled(Token? variance) {
    listener?.reportVarianceModifierNotEnabled(variance);
  }
}

class NullListener extends ForwardingListener {
  bool hasErrors = false;

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    hasErrors = true;
  }
}
