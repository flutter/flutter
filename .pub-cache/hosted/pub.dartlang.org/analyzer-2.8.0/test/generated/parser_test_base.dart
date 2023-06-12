// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/async_modifier.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart' as fasta;
import 'package:_fe_analyzer_shared/src/scanner/error_token.dart'
    show ErrorToken;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' as fasta;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, ScannerResult, scanString;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart' show CompilationUnitImpl;
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:pub_semver/src/version.dart';
import 'package:test/test.dart';

import 'parser_fasta_listener.dart';
import 'test_support.dart';

/// Abstract base class for parser tests, which does not make assumptions about
/// which parser is used.
abstract class AbstractParserTestCase implements ParserTestHelpers {
  bool get allowNativeClause;

  set allowNativeClause(bool value);

  /// Set a flag indicating whether the parser should parse instance creation
  /// expressions that lack either the `new` or `const` keyword.
  set enableOptionalNewAndConst(bool value);

  /// Set a flag indicating whether the parser is to parse part-of directives
  /// that specify a URI rather than a library name.
  set enableUriInPartOf(bool value);

  /// The error listener to which scanner and parser errors will be reported.
  ///
  /// This field is typically initialized by invoking [createParser].
  GatheringErrorListener get listener;

  /// Get the parser used by the test.
  ///
  /// Caller must first invoke [createParser].
  analyzer.Parser get parser;

  /// Assert that the number and codes of errors occurred during parsing is the
  /// same as the [expectedErrorCodes].
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes);

  /// Asserts that no errors occurred during parsing.
  void assertNoErrors();

  /// Prepares to parse using tokens scanned from the given [content] string.
  ///
  /// [expectedEndOffset] is the expected offset of the next token to be parsed
  /// after the parser has finished parsing,
  /// or `null` (the default) if EOF is expected.
  /// In general, the analyzer tests do not assert that the last token is EOF,
  /// but the fasta parser adapter tests do assert this.
  /// For any analyzer test where the last token is not EOF, set this value.
  /// It is ignored when not using the fasta parser.
  void createParser(
    String content, {
    int expectedEndOffset,
    FeatureSet featureSet,
  });

  ExpectedError expectedError(ErrorCode code, int offset, int length);

  void expectNotNullIfNoErrors(Object result);

  Expression parseAdditiveExpression(String code);

  Expression parseAssignableExpression(String code, bool primaryAllowed);

  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional = true});

  AwaitExpression parseAwaitExpression(String code);

  Expression parseBitwiseAndExpression(String code);

  Expression parseBitwiseOrExpression(String code);

  Expression parseBitwiseXorExpression(String code);

  Expression parseCascadeSection(String code);

  CommentReference? parseCommentReference(
      String referenceSource, int sourceOffset);

  CompilationUnit parseCompilationUnit(String source,
      {List<ErrorCode> codes, List<ExpectedError> errors});

  ConditionalExpression parseConditionalExpression(String code);

  Expression parseConstExpression(String code);

  ConstructorInitializer parseConstructorInitializer(String code);

  /// Parse the given source as a compilation unit.
  ///
  /// @param source the source to be parsed
  /// @param errorCodes the error codes of the errors that are expected to be
  ///          found
  /// @return the compilation unit that was parsed
  /// @throws Exception if the source could not be parsed, if the compilation
  ///           errors in the source do not match those that are expected, or if
  ///           the result would have been `null`
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]);

  BinaryExpression parseEqualityExpression(String code);

  Expression parseExpression(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset});

  List<Expression> parseExpressionList(String code);

  Expression parseExpressionWithoutCascade(String code);

  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes = const <ErrorCode>[]});

  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[],
      List<ExpectedError> errors});

  /// Parses a single top level member of a compilation unit (other than a
  /// directive), including any comment and/or metadata that precedes it.
  CompilationUnitMember parseFullCompilationUnitMember();

  /// Parses a single top level directive, including any comment and/or metadata
  /// that precedes it.
  Directive parseFullDirective();

  FunctionExpression parseFunctionExpression(String code);

  InstanceCreationExpression parseInstanceCreationExpression(
      String code, Token newToken);

  ListLiteral parseListLiteral(
      Token token, String typeArgumentsCode, String code);

  TypedLiteral parseListOrMapLiteral(Token modifier, String code);

  Expression parseLogicalAndExpression(String code);

  Expression parseLogicalOrExpression(String code);

  SetOrMapLiteral parseMapLiteral(
      Token token, String typeArgumentsCode, String code);

  MapLiteralEntry parseMapLiteralEntry(String code);

  Expression parseMultiplicativeExpression(String code);

  InstanceCreationExpression parseNewExpression(String code);

  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[]});

  Expression parsePostfixExpression(String code);

  Identifier parsePrefixedIdentifier(String code);

  Expression parsePrimaryExpression(String code,
      {int expectedEndOffset, List<ExpectedError> errors});

  Expression parseRelationalExpression(String code);

  RethrowExpression parseRethrowExpression(String code);

  BinaryExpression parseShiftExpression(String code);

  SimpleIdentifier parseSimpleIdentifier(String code);

  Statement parseStatement(String source, {int expectedEndOffset});

  Expression parseStringLiteral(String code);

  SymbolLiteral parseSymbolLiteral(String code);

  Expression parseThrowExpression(String code);

  Expression parseThrowExpressionWithoutCascade(String code);

  PrefixExpression parseUnaryExpression(String code);

  VariableDeclarationList parseVariableDeclarationList(String source);
}

/// This class just narrows the type of [parser] to [ParserProxy].
abstract class AbstractParserViaProxyTestCase
    implements AbstractParserTestCase {
  @override
  ParserProxy get parser;
}

/// Implementation of [AbstractParserTestCase] specialized for testing the
/// Fasta parser.
class FastaParserTestCase
    with ParserTestHelpers
    implements AbstractParserTestCase {
  static final List<ErrorCode> NO_ERROR_COMPARISON = <ErrorCode>[];

  final constructorTearoffs = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [EnableString.constructor_tearoffs],
  );

  final controlFlow = FeatureSet.latestLanguageVersion();

  final spread = FeatureSet.latestLanguageVersion();

  final nonNullable = FeatureSet.latestLanguageVersion();

  final preConstructorTearoffs = FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: Version.parse('2.13.0'), flags: []);

  final preNonNullable = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.9.0'),
    flags: [],
  );

  late ParserProxy parserProxy;

  late Token _fastaTokens;

  @override
  bool allowNativeClause = false;

  @override
  set enableOptionalNewAndConst(bool enable) {
    // ignored
  }

  @override
  set enableUriInPartOf(bool value) {
    if (value == false) {
      throw UnimplementedError(
          'URIs in "part of" declarations cannot be disabled in Fasta.');
    }
  }

  @override
  GatheringErrorListener get listener => parserProxy.errorListener;

  @override
  ParserProxy get parser => parserProxy;

  void assertErrors({List<ErrorCode>? codes, List<ExpectedError>? errors}) {
    if (codes != null) {
      if (!identical(codes, NO_ERROR_COMPARISON)) {
        assertErrorsWithCodes(codes);
      }
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      assertNoErrors();
    }
  }

  @override
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    parserProxy.errorListener.assertErrorsWithCodes(
        _toFastaGeneratedAnalyzerErrorCodes(expectedErrorCodes));
  }

  @override
  void assertNoErrors() {
    parserProxy.errorListener.assertNoErrors();
  }

  @override
  void createParser(String content,
      {int? expectedEndOffset, FeatureSet? featureSet}) {
    featureSet ??= FeatureSet.latestLanguageVersion();
    var result = scanString(content,
        configuration: featureSet.isEnabled(Feature.non_nullable)
            ? ScannerConfiguration.nonNullable
            : ScannerConfiguration.classic,
        includeComments: true);
    _fastaTokens = result.tokens;
    parserProxy = ParserProxy(_fastaTokens, featureSet,
        allowNativeClause: allowNativeClause,
        expectedEndOffset: expectedEndOffset);
  }

  @override
  ExpectedError expectedError(ErrorCode code, int offset, int length) =>
      ExpectedError(_toFastaGeneratedAnalyzerErrorCode(code), offset, length);

  @override
  void expectNotNullIfNoErrors(Object? result) {
    if (!listener.hasErrors) {
      expect(result, isNotNull);
    }
  }

  @override
  Expression parseAdditiveExpression(String code) {
    return _parseExpression(code);
  }

  Expression parseArgument(String source) {
    createParser(source);
    return parserProxy.parseArgument();
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    return _parseExpression(code);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional = true}) {
    if (optional) {
      if (code.isEmpty) {
        return _parseExpression('foo');
      }
      return _parseExpression('(foo)$code');
    }
    return _parseExpression('foo$code');
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    var function = _parseExpression('() async => $code') as FunctionExpression;
    return (function.body as ExpressionFunctionBody).expression
        as AwaitExpression;
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseCascadeSection(String code) {
    var cascadeExpression = _parseExpression('null$code') as CascadeExpression;
    return cascadeExpression.cascadeSections.first;
  }

  @override
  CommentReference? parseCommentReference(
      String referenceSource, int sourceOffset) {
    String padding = ' '.padLeft(sourceOffset - 4, 'a');
    String source = '/**$padding[$referenceSource] */ class C { }';
    CompilationUnit unit = parseCompilationUnit(source);
    var clazz = unit.declarations[0] as ClassDeclaration;
    var comment = clazz.documentationComment!;
    List<CommentReference> references = comment.references;
    if (references.isEmpty) {
      return null;
    } else {
      expect(references, hasLength(1));
      return references[0];
    }
  }

  @override
  CompilationUnitImpl parseCompilationUnit(String content,
      {List<ErrorCode>? codes,
      List<ExpectedError>? errors,
      FeatureSet? featureSet}) {
    GatheringErrorListener listener = GatheringErrorListener(checkRanges: true);

    var unit = parseCompilationUnit2(content, listener, featureSet: featureSet);

    // Assert and return result
    if (codes != null) {
      listener
          .assertErrorsWithCodes(_toFastaGeneratedAnalyzerErrorCodes(codes));
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      listener.assertNoErrors();
    }
    return unit;
  }

  CompilationUnitImpl parseCompilationUnit2(
      String content, GatheringErrorListener listener,
      {FeatureSet? featureSet}) {
    featureSet ??= FeatureSet.latestLanguageVersion();
    var source = StringSource(content, 'parser_test_StringSource.dart');

    // Adjust the feature set based on language version comment.
    void languageVersionChanged(
        fasta.Scanner scanner, LanguageVersionToken languageVersion) {
      featureSet = featureSet!.restrictToVersion(
          Version(languageVersion.major, languageVersion.minor, 0));
      scanner.configuration = Scanner.buildConfig(featureSet);
    }

    // Scan tokens
    ScannerResult result = scanString(content,
        includeComments: true,
        configuration: Scanner.buildConfig(featureSet),
        languageVersionChanged: languageVersionChanged);
    _fastaTokens = result.tokens;

    // Run parser
    ErrorReporter errorReporter = ErrorReporter(
      listener,
      source,
      isNonNullableByDefault: false,
    );
    AstBuilder astBuilder =
        AstBuilder(errorReporter, source.uri, true, featureSet!);
    fasta.Parser parser = fasta.Parser(astBuilder);
    astBuilder.parser = parser;
    astBuilder.allowNativeClause = allowNativeClause;
    parser.parseUnit(_fastaTokens);
    var unit = astBuilder.pop() as CompilationUnitImpl;

    expect(unit, isNotNull);
    return unit;
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    return _parseExpression(code) as ConditionalExpression;
  }

  @override
  Expression parseConstExpression(String code) {
    return _parseExpression(code);
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    createParser('class __Test { __Test() : $code; }');
    CompilationUnit unit = parserProxy.parseCompilationUnit2();
    assertNoErrors();
    var clazz = unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    return constructor.initializers.single;
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    CompilationUnit unit =
        parserProxy.parseDirectives(parserProxy.currentToken);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(0));
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return _parseExpression(code) as BinaryExpression;
  }

  @override
  Expression parseExpression(String source,
      {List<ErrorCode>? codes,
      List<ExpectedError>? errors,
      int? expectedEndOffset,
      bool inAsync = false,
      FeatureSet? featureSet}) {
    createParser(source,
        expectedEndOffset: expectedEndOffset, featureSet: featureSet);
    if (inAsync) {
      parserProxy.fastaParser.asyncState = AsyncModifier.Async;
    }
    Expression result = parserProxy.parseExpression2();
    assertErrors(codes: codes, errors: errors);
    return result;
  }

  @override
  List<Expression> parseExpressionList(String code) {
    return (_parseExpression('[$code]') as ListLiteral)
        .elements
        .toList()
        .cast<Expression>();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes = const <ErrorCode>[],
      FeatureSet? featureSet}) {
    String parametersCode;
    if (kind == ParameterKind.REQUIRED) {
      parametersCode = '($code)';
    } else if (kind == ParameterKind.POSITIONAL) {
      parametersCode = '([$code])';
    } else if (kind == ParameterKind.NAMED) {
      parametersCode = '({$code})';
    } else {
      fail('$kind');
    }
    FormalParameterList list = parseFormalParameterList(parametersCode,
        inFunctionType: false, errorCodes: errorCodes, featureSet: featureSet);
    return list.parameters.single;
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[],
      List<ExpectedError>? errors,
      FeatureSet? featureSet}) {
    createParser(code, featureSet: featureSet);
    FormalParameterList result =
        parserProxy.parseFormalParameterList(inFunctionType: inFunctionType);
    assertErrors(codes: errors != null ? null : errorCodes, errors: errors);
    return result;
  }

  @override
  CompilationUnitMember parseFullCompilationUnitMember() {
    return parserProxy.parseTopLevelDeclaration(false) as CompilationUnitMember;
  }

  @override
  Directive parseFullDirective() {
    return parserProxy.parseTopLevelDeclaration(true) as Directive;
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    return _parseExpression(code) as FunctionExpression;
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, Token newToken) {
    return _parseExpression('$newToken $code') as InstanceCreationExpression;
  }

  @override
  ListLiteral parseListLiteral(
      Token? token, String? typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return _parseExpression(sc) as ListLiteral;
  }

  @override
  TypedLiteral parseListOrMapLiteral(Token? modifier, String code) {
    String literalCode = modifier != null ? '$modifier $code' : code;
    return parsePrimaryExpression(literalCode) as TypedLiteral;
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  SetOrMapLiteral parseMapLiteral(
      Token? token, String? typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return parsePrimaryExpression(sc) as SetOrMapLiteral;
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    var mapLiteral = parseMapLiteral(null, null, '{ $code }');
    return mapLiteral.elements.single as MapLiteralEntry;
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    return _parseExpression(code);
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    return _parseExpression(code) as InstanceCreationExpression;
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[]}) {
    FormalParameterList list = parseFormalParameterList('($code)',
        inFunctionType: inFunctionType, errorCodes: errorCodes);
    return list.parameters.single as NormalFormalParameter;
  }

  @override
  Expression parsePostfixExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    return _parseExpression(code) as Identifier;
  }

  @override
  Expression parsePrimaryExpression(String code,
      {int? expectedEndOffset, List<ExpectedError>? errors}) {
    createParser(code, expectedEndOffset: expectedEndOffset);
    Expression result = parserProxy.parsePrimaryExpression();
    assertErrors(codes: null, errors: errors);
    return result;
  }

  @override
  Expression parseRelationalExpression(String code) {
    return _parseExpression(code);
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    return _parseExpression(code) as RethrowExpression;
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    return _parseExpression(code) as BinaryExpression;
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    return _parseExpression(code) as SimpleIdentifier;
  }

  @override
  Statement parseStatement(String source,
      {int? expectedEndOffset, FeatureSet? featureSet, bool inAsync = false}) {
    createParser(source,
        expectedEndOffset: expectedEndOffset, featureSet: featureSet);
    if (inAsync) {
      parserProxy.fastaParser.asyncState = AsyncModifier.Async;
    }
    Statement statement = parserProxy.parseStatement2();
    assertErrors(codes: NO_ERROR_COMPARISON);
    return statement;
  }

  @override
  Expression parseStringLiteral(String code) {
    return _parseExpression(code);
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    return _parseExpression(code) as SymbolLiteral;
  }

  @override
  Expression parseThrowExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    return _parseExpression(code) as PrefixExpression;
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String code) {
    var statement = parseStatement('$code;') as VariableDeclarationStatement;
    return statement.variables;
  }

  Expression _parseExpression(String code) {
    var statement = parseStatement('$code;') as ExpressionStatement;
    return statement.expression;
  }

  ErrorCode _toFastaGeneratedAnalyzerErrorCode(ErrorCode code) {
    if (code == ParserErrorCode.ABSTRACT_ENUM ||
        code == ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION ||
        code == ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE ||
        code == ParserErrorCode.ABSTRACT_TYPEDEF ||
        code == ParserErrorCode.CONST_ENUM ||
        code == ParserErrorCode.CONST_TYPEDEF ||
        code == ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION ||
        code == ParserErrorCode.FINAL_CLASS ||
        code == ParserErrorCode.FINAL_ENUM ||
        code == ParserErrorCode.FINAL_TYPEDEF ||
        code == ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION) {
      return ParserErrorCode.EXTRANEOUS_MODIFIER;
    }
    return code;
  }

  List<ErrorCode> _toFastaGeneratedAnalyzerErrorCodes(
          List<ErrorCode> expectedErrorCodes) =>
      expectedErrorCodes.map(_toFastaGeneratedAnalyzerErrorCode).toList();
}

/// Proxy implementation of the analyzer parser, implemented in terms of the
/// Fasta parser.
///
/// This allows many of the analyzer parser tests to be run on Fasta, even if
/// they call into the analyzer parser class directly.
class ParserProxy extends analyzer.Parser {
  /// The error listener to which scanner and parser errors will be reported.
  final GatheringErrorListener errorListener;

  late final ForwardingTestListener _eventListener;

  final int? expectedEndOffset;

  /// Creates a [ParserProxy] which is prepared to begin parsing at the given
  /// Fasta token.
  factory ParserProxy(Token firstToken, FeatureSet featureSet,
      {bool allowNativeClause = false, int? expectedEndOffset}) {
    TestSource source = TestSource();
    var errorListener = GatheringErrorListener(checkRanges: true);
    return ParserProxy._(firstToken, source, errorListener, featureSet,
        allowNativeClause: allowNativeClause,
        expectedEndOffset: expectedEndOffset);
  }

  ParserProxy._(Token firstToken, Source source, this.errorListener,
      FeatureSet featureSet,
      {bool allowNativeClause = false, this.expectedEndOffset})
      : super(source, errorListener,
            featureSet: featureSet, allowNativeClause: allowNativeClause) {
    _eventListener = ForwardingTestListener(astBuilder);
    fastaParser.listener = _eventListener;
    currentToken = firstToken;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Annotation parseAnnotation() {
    return _run('MetadataStar', () {
      currentToken = fastaParser
          .parseMetadata(fastaParser.syntheticPreviousToken(currentToken))
          .next!;
      return astBuilder.pop() as Annotation;
    });
  }

  ArgumentList parseArgumentList() {
    return _run('unspecified', () {
      currentToken = fastaParser
          .parseArguments(fastaParser.syntheticPreviousToken(currentToken))
          .next!;
      var result = astBuilder.pop();
      return result is MethodInvocation
          ? result.argumentList
          : result as ArgumentList;
    });
  }

  ClassMember parseClassMember(String className) {
    return parseClassMemberOrNull(className)!;
  }

  ClassMember? parseClassMemberOrNull(String className) {
    return _run('ClassOrMixinBody', () {
      astBuilder.classDeclaration = astFactory.classDeclaration(
        null,
        null,
        null,
        Token(Keyword.CLASS, 0),
        astFactory.simpleIdentifier(
            fasta.StringToken.fromString(TokenType.IDENTIFIER, className, 6)),
        null,
        null,
        null,
        null,
        Tokens.openCurlyBracket() /* leftBracket */,
        <ClassMember>[],
        Tokens.closeCurlyBracket() /* rightBracket */,
      );
      // TODO(danrubel): disambiguate between class and mixin
      currentToken = fastaParser.parseClassMember(currentToken, className);
      //currentToken = fastaParser.parseMixinMember(currentToken);
      ClassDeclaration declaration = astBuilder.classDeclaration!;
      astBuilder.classDeclaration = null;
      return declaration.members.isNotEmpty ? declaration.members[0] : null;
    });
  }

  List<Combinator> parseCombinators() {
    return _run('Import', () {
      currentToken = fastaParser
          .parseCombinatorStar(fastaParser.syntheticPreviousToken(currentToken))
          .next!;
      return astBuilder.pop() as List<Combinator>;
    });
  }

  List<CommentReference> parseCommentReferences(
      List<DocumentationCommentToken> tokens) {
    for (int index = 0; index < tokens.length - 1; ++index) {
      var next = tokens[index].next;
      if (next == null) {
        tokens[index].setNext(tokens[index + 1]);
      } else {
        expect(next, tokens[index + 1]);
      }
    }
    expect(tokens[tokens.length - 1].next, isNull);
    List<CommentReference> references =
        astBuilder.parseCommentReferences(tokens.first);
    if (astBuilder.stack.isNotEmpty) {
      throw 'Expected empty stack, but found:'
          '\n  ${astBuilder.stack.values.join('\n  ')}';
    }
    return references;
  }

  @override
  CompilationUnitImpl parseCompilationUnit2() {
    var result = super.parseCompilationUnit2();
    expect(currentToken.isEof, isTrue, reason: currentToken.lexeme);
    expect(astBuilder.stack, hasLength(0));
    _eventListener.expectEmpty();
    return result;
  }

  @override
  Configuration parseConfiguration() {
    return _run('ConditionalUris', () => super.parseConfiguration());
  }

  @override
  DottedName parseDottedName() {
    return _run('unspecified', () => super.parseDottedName());
  }

  @override
  Expression parseExpression2() {
    return _run('unspecified', () => super.parseExpression2());
  }

  @override
  FormalParameterList parseFormalParameterList({bool inFunctionType = false}) {
    return _run('unspecified',
        () => super.parseFormalParameterList(inFunctionType: inFunctionType));
  }

  @override
  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    Token? lastToken;
    FunctionBody body = _run('unspecified', () {
      FunctionBody body =
          super.parseFunctionBody(mayBeEmpty, emptyErrorCode, inExpression);
      lastToken = currentToken;
      currentToken = currentToken.next!;
      return body;
    });
    if (!inExpression) {
      if (![';', '}'].contains(lastToken!.lexeme)) {
        fail('Expected ";" or "}", but found: ${lastToken!.lexeme}');
      }
    }
    return body;
  }

  @override
  Expression parsePrimaryExpression() {
    return _run('unspecified', () => super.parsePrimaryExpression());
  }

  @override
  Statement parseStatement(Token token) {
    return _run('unspecified', () => super.parseStatement(token));
  }

  @override
  Statement parseStatement2() {
    return _run('unspecified', () => super.parseStatement2());
  }

  @override
  AnnotatedNode parseTopLevelDeclaration(bool isDirective) {
    return _run(
        'CompilationUnit', () => super.parseTopLevelDeclaration(isDirective));
  }

  @override
  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    return _run('unspecified', () => super.parseTypeAnnotation(inExpression));
  }

  @override
  TypeArgumentList parseTypeArgumentList() {
    return _run('unspecified', () => super.parseTypeArgumentList());
  }

  @override
  NamedType parseTypeName(bool inExpression) {
    return _run('unspecified', () => super.parseTypeName(inExpression));
  }

  @override
  TypeParameter parseTypeParameter() {
    return _run('unspecified', () => super.parseTypeParameter());
  }

  @override
  TypeParameterList? parseTypeParameterList() {
    return _run('unspecified', () => super.parseTypeParameterList());
  }

  /// Runs the specified function and returns the result. It checks the
  /// enclosing listener events, that the parse consumed all of the tokens, and
  /// that the result stack is empty.
  _run(String enclosingEvent, Function() f) {
    _eventListener.begin(enclosingEvent);

    // Simulate error handling of parseUnit by skipping error tokens
    // before parsing and reporting them after parsing is complete.
    Token errorToken = currentToken;
    currentToken = fastaParser.skipErrorTokens(currentToken);
    var result = f();
    fastaParser.reportAllErrorTokens(errorToken);

    _eventListener.end(enclosingEvent);

    String lexeme = currentToken is ErrorToken
        ? currentToken.runtimeType.toString()
        : currentToken.lexeme;
    if (expectedEndOffset == null) {
      expect(currentToken.isEof, isTrue, reason: lexeme);
    } else {
      expect(currentToken.offset, expectedEndOffset, reason: lexeme);
    }
    expect(astBuilder.stack, hasLength(0));
    expect(astBuilder.directives, hasLength(0));
    expect(astBuilder.declarations, hasLength(0));
    return result;
  }
}

/// Implementation of [AbstractParserTestCase] specialized for testing the
/// analyzer parser.
class ParserTestCase with ParserTestHelpers implements AbstractParserTestCase {
  /// A flag indicating whether parser is to parse function bodies.
  static bool parseFunctionBodies = true;

  @override
  bool allowNativeClause = true;

  /// A flag indicating whether parser is to parse async.
  bool parseAsync = true;

  /// A flag indicating whether the parser should parse instance creation
  /// expressions that lack either the `new` or `const` keyword.
  bool enableOptionalNewAndConst = false;

  /// A flag indicating whether the parser should parse mixin declarations.
  /// https://github.com/dart-lang/language/issues/12
  bool isMixinSupportEnabled = false;

  /// A flag indicating whether the parser is to parse part-of directives that
  /// specify a URI rather than a library name.
  bool enableUriInPartOf = false;

  @override
  late final GatheringErrorListener listener;

  /// The parser used by the test.
  ///
  /// This field is typically initialized by invoking [createParser].
  @override
  late final analyzer.Parser parser;

  @override
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  @override
  void assertNoErrors() {
    listener.assertNoErrors();
  }

  /// Create the [parser] and [listener] used by a test. The [parser] will be
  /// prepared to parse the tokens scanned from the given [content].
  @override
  void createParser(
    String content, {
    int? expectedEndOffset,
    LanguageVersionToken? languageVersion,
    FeatureSet? featureSet,
  }) {
    featureSet ??= FeatureSet.latestLanguageVersion();
    Source source = TestSource();
    listener = GatheringErrorListener();

    fasta.ScannerResult result =
        fasta.scanString(content, includeComments: true);
    listener.setLineInfo(source, result.lineStarts);

    parser = analyzer.Parser(
      source,
      listener,
      featureSet: featureSet,
    );
    parser.allowNativeClause = allowNativeClause;
    parser.parseFunctionBodies = parseFunctionBodies;
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    parser.currentToken = result.tokens;
  }

  @override
  ExpectedError expectedError(ErrorCode code, int offset, int length) =>
      ExpectedError(code, offset, length);

  @override
  void expectNotNullIfNoErrors(Object result) {
    if (!listener.hasErrors) {
      expect(result, isNotNull);
    }
  }

  @override
  Expression parseAdditiveExpression(String code) {
    createParser(code);
    return parser.parseAdditiveExpression();
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    createParser(code);
    return parser.parseAssignableExpression(primaryAllowed);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional = true}) {
    if (optional) {
      if (code.isEmpty) {
        createParser('foo');
      } else {
        createParser('(foo)$code');
      }
    } else {
      createParser('foo$code');
    }
    return parser.parseExpression2();
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    createParser('() async => $code');
    var function = parser.parseExpression2() as FunctionExpression;
    return (function.body as ExpressionFunctionBody).expression
        as AwaitExpression;
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    createParser(code);
    return parser.parseBitwiseAndExpression();
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    createParser(code);
    return parser.parseBitwiseOrExpression();
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    createParser(code);
    return parser.parseBitwiseXorExpression();
  }

  @override
  Expression parseCascadeSection(String code) {
    var statement = parseStatement('null$code;') as ExpressionStatement;
    var cascadeExpression = statement.expression as CascadeExpression;
    return cascadeExpression.cascadeSections.first;
  }

  @override
  CommentReference? parseCommentReference(
      String referenceSource, int sourceOffset) {
    String padding = ' '.padLeft(sourceOffset - 4, 'a');
    String source = '/**$padding[$referenceSource] */ class C { }';
    CompilationUnit unit = parseCompilationUnit(source);
    var clazz = unit.declarations[0] as ClassDeclaration;
    var comment = clazz.documentationComment!;
    List<CommentReference> references = comment.references;
    if (references.isEmpty) {
      return null;
    } else {
      expect(references, hasLength(1));
      return references[0];
    }
  }

  /// Parse the given source as a compilation unit.
  ///
  /// @param source the source to be parsed
  /// @param errorCodes the error codes of the errors that are expected to be
  ///          found
  /// @return the compilation unit that was parsed
  /// @throws Exception if the source could not be parsed, if the compilation
  ///           errors in the source do not match those that are expected, or if
  ///           the result would have been `null`
  @override
  CompilationUnit parseCompilationUnit(String content,
      {List<ErrorCode>? codes, List<ExpectedError>? errors}) {
    Source source = TestSource();
    GatheringErrorListener listener = GatheringErrorListener();

    fasta.ScannerResult result =
        fasta.scanString(content, includeComments: true);
    listener.setLineInfo(source, result.lineStarts);

    analyzer.Parser parser = analyzer.Parser(
      source,
      listener,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    CompilationUnit unit = parser.parseCompilationUnit(result.tokens);
    expect(unit, isNotNull);
    if (codes != null) {
      listener.assertErrorsWithCodes(codes);
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      listener.assertNoErrors();
    }
    return unit;
  }

  /// Parse the given [content] as a compilation unit.
  CompilationUnit parseCompilationUnit2(String content,
      {AnalysisErrorListener? listener}) {
    Source source = NonExistingSource.unknown;
    listener ??= AnalysisErrorListener.NULL_LISTENER;

    fasta.ScannerResult result =
        fasta.scanString(content, includeComments: true);

    analyzer.Parser parser = analyzer.Parser(
      source,
      listener,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    var unit = parser.parseCompilationUnit(result.tokens);
    unit.lineInfo = LineInfo(result.lineStarts);
    return unit;
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    createParser(code);
    return parser.parseConditionalExpression() as ConditionalExpression;
  }

  @override
  Expression parseConstExpression(String code) {
    createParser(code);
    return parser.parseConstExpression();
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    createParser('class __Test { __Test() : $code; }');
    CompilationUnit unit = parser.parseCompilationUnit2();
    var clazz = unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    return constructor.initializers.single;
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    CompilationUnit unit = parser.parseDirectives2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(0));
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    createParser(code);
    return parser.parseEqualityExpression() as BinaryExpression;
  }

  /// Parse the given [source] as an expression. If a list of error [codes] is
  /// provided, then assert that the produced errors matches the list.
  /// Otherwise, if a list of [errors] is provided, the assert that the produced
  /// errors matches the list. Otherwise, assert that there are no errors.
  @override
  Expression parseExpression(String source,
      {List<ErrorCode>? codes,
      List<ExpectedError>? errors,
      int? expectedEndOffset}) {
    createParser(source, expectedEndOffset: expectedEndOffset);
    Expression expression = parser.parseExpression2();
    expectNotNullIfNoErrors(expression);
    if (codes != null) {
      listener.assertErrorsWithCodes(codes);
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      assertNoErrors();
    }
    return expression;
  }

  @override
  List<Expression> parseExpressionList(String code) {
    createParser('[$code]');
    return (parser.parseExpression2() as ListLiteral)
        .elements
        .toList()
        .cast<Expression>();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    createParser(code);
    return parser.parseExpressionWithoutCascade();
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes = const <ErrorCode>[]}) {
    String parametersCode;
    if (kind == ParameterKind.REQUIRED) {
      parametersCode = '($code)';
    } else if (kind == ParameterKind.POSITIONAL) {
      parametersCode = '([$code])';
    } else if (kind == ParameterKind.NAMED) {
      parametersCode = '({$code})';
    } else {
      fail('$kind');
    }
    FormalParameterList list = parseFormalParameterList(parametersCode,
        inFunctionType: false, errorCodes: errorCodes);
    return list.parameters.single;
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[],
      List<ExpectedError>? errors}) {
    createParser(code);
    FormalParameterList list =
        parser.parseFormalParameterList(inFunctionType: inFunctionType);
    if (errors != null) {
      errorCodes = errors.map((e) => e.code).toList();
    }
    assertErrorsWithCodes(errorCodes);
    return list;
  }

  /// Parses a single top level member of a compilation unit (other than a
  /// directive), including any comment and/or metadata that precedes it.
  @override
  CompilationUnitMember parseFullCompilationUnitMember() =>
      parser.parseCompilationUnit2().declarations.first;

  @override
  Directive parseFullDirective() {
    return parser.parseTopLevelDeclaration(true) as Directive;
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    createParser(code);
    return parser.parseFunctionExpression();
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, Token newToken) {
    createParser('$newToken $code');
    return parser.parseExpression2() as InstanceCreationExpression;
  }

  @override
  ListLiteral parseListLiteral(
      Token? token, String? typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    createParser(sc);
    return parser.parseExpression2() as ListLiteral;
  }

  @override
  TypedLiteral parseListOrMapLiteral(Token? modifier, String code) {
    String literalCode = modifier != null ? '$modifier $code' : code;
    createParser(literalCode);
    return parser.parseExpression2() as TypedLiteral;
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    createParser(code);
    return parser.parseLogicalAndExpression();
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    createParser(code);
    return parser.parseLogicalOrExpression();
  }

  @override
  SetOrMapLiteral parseMapLiteral(
      Token? token, String? typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    createParser(sc);
    return parser.parseExpression2() as SetOrMapLiteral;
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    var mapLiteral = parseMapLiteral(null, null, '{ $code }');
    return mapLiteral.elements.single as MapLiteralEntry;
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    createParser(code);
    return parser.parseMultiplicativeExpression();
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    createParser(code);
    return parser.parseNewExpression();
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[]}) {
    FormalParameterList list = parseFormalParameterList('($code)',
        inFunctionType: inFunctionType, errorCodes: errorCodes);
    return list.parameters.single as NormalFormalParameter;
  }

  @override
  Expression parsePostfixExpression(String code) {
    createParser(code);
    return parser.parsePostfixExpression();
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    createParser(code);
    return parser.parsePrefixedIdentifier();
  }

  @override
  Expression parsePrimaryExpression(String code,
      {int? expectedEndOffset, List<ExpectedError>? errors}) {
    createParser(code);
    var expression = parser.parsePrimaryExpression();
    if (errors != null) {
      listener.assertErrors(errors);
    }
    return expression;
  }

  @override
  Expression parseRelationalExpression(String code) {
    createParser(code);
    return parser.parseRelationalExpression();
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    createParser(code);
    return parser.parseRethrowExpression() as RethrowExpression;
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    createParser(code);
    return parser.parseShiftExpression() as BinaryExpression;
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    createParser(code);
    return parser.parseSimpleIdentifier();
  }

  /// Parse the given [content] as a statement. If
  /// [enableLazyAssignmentOperators] is `true`, then lazy assignment operators
  /// should be enabled.
  @override
  Statement parseStatement(String content, {int? expectedEndOffset}) {
    Source source = TestSource();
    listener = GatheringErrorListener();

    fasta.ScannerResult result =
        fasta.scanString(content, includeComments: true);
    listener.setLineInfo(source, result.lineStarts);

    analyzer.Parser parser = analyzer.Parser(
      source,
      listener,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    Statement statement = parser.parseStatement(result.tokens);
    expect(statement, isNotNull);
    return statement;
  }

  @override
  Expression parseStringLiteral(String code) {
    createParser(code);
    return parser.parseStringLiteral();
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    createParser(code);
    return parser.parseSymbolLiteral();
  }

  @override
  Expression parseThrowExpression(String code) {
    createParser(code);
    return parser.parseThrowExpression();
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    createParser(code);
    return parser.parseThrowExpressionWithoutCascade();
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    createParser(code);
    return parser.parseUnaryExpression() as PrefixExpression;
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String code) {
    var statement = parseStatement('$code;') as VariableDeclarationStatement;
    return statement.variables;
  }

  void setUp() {
    parseFunctionBodies = true;
  }
}

/// Helper methods that aid in parser tests.
///
/// Intended to be mixed in to parser test case classes.
mixin ParserTestHelpers {
  void expectCommentText(Comment? comment, String expectedText) {
    comment!;
    expect(comment.beginToken, same(comment.endToken));
    expect(comment.beginToken.lexeme, expectedText);
  }

  void expectDottedName(DottedName name, List<String> expectedComponents) {
    int count = expectedComponents.length;
    NodeList<SimpleIdentifier> components = name.components;
    expect(components, hasLength(count));
    for (int i = 0; i < count; i++) {
      SimpleIdentifier component = components[i];
      expect(component, isNotNull);
      expect(component.name, expectedComponents[i]);
    }
  }
}
