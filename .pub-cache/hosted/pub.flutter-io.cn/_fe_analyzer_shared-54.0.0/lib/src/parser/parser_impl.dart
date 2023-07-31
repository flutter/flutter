// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.parser;

import 'package:_fe_analyzer_shared/src/parser/type_info_impl.dart';

import '../experiments/flags.dart';

import '../messages/codes.dart' as codes;

import '../scanner/scanner.dart' show ErrorToken, Token;

import '../scanner/token.dart'
    show
        ASSIGNMENT_PRECEDENCE,
        BeginToken,
        CASCADE_PRECEDENCE,
        EQUALITY_PRECEDENCE,
        Keyword,
        MULTIPLICATIVE_PRECEDENCE,
        POSTFIX_PRECEDENCE,
        PREFIX_PRECEDENCE,
        RELATIONAL_PRECEDENCE,
        SELECTOR_PRECEDENCE,
        SHIFT_PRECEDENCE,
        StringToken,
        SyntheticBeginToken,
        SyntheticKeywordToken,
        SyntheticStringToken,
        SyntheticToken,
        TokenType;

import '../scanner/token_constants.dart'
    show
        BANG_EQ_EQ_TOKEN,
        COMMA_TOKEN,
        DOUBLE_TOKEN,
        EOF_TOKEN,
        EQ_EQ_EQ_TOKEN,
        EQ_TOKEN,
        FUNCTION_TOKEN,
        HASH_TOKEN,
        HEXADECIMAL_TOKEN,
        IDENTIFIER_TOKEN,
        INT_TOKEN,
        KEYWORD_TOKEN,
        LT_TOKEN,
        OPEN_CURLY_BRACKET_TOKEN,
        OPEN_PAREN_TOKEN,
        OPEN_SQUARE_BRACKET_TOKEN,
        SEMICOLON_TOKEN,
        STRING_INTERPOLATION_IDENTIFIER_TOKEN,
        STRING_INTERPOLATION_TOKEN,
        STRING_TOKEN;

import 'assert.dart' show Assert;

import 'async_modifier.dart' show AsyncModifier;

import 'block_kind.dart';

import 'constructor_reference_context.dart' show ConstructorReferenceContext;

import 'declaration_kind.dart' show DeclarationKind;

import 'directive_context.dart';

import 'formal_parameter_kind.dart'
    show FormalParameterKind, FormalParameterKindExtension;

import 'forwarding_listener.dart' show ForwardingListener, NullListener;

import 'identifier_context.dart'
    show
        IdentifierContext,
        looksLikeExpressionStart,
        looksLikePatternStart,
        okNextValueInFormalParameter;

import 'identifier_context_impl.dart'
    show looksLikeStartOfNextTopLevelDeclaration;

import 'listener.dart' show Listener;

import 'literal_entry_info.dart'
    show
        LiteralEntryInfo,
        computeLiteralEntry,
        looksLikeLiteralEntry,
        simpleEntry;

import 'loop_state.dart' show LoopState;

import 'member_kind.dart' show MemberKind;

import 'modifier_context.dart' show ModifierContext, isModifier;

import 'recovery_listeners.dart'
    show
        ClassHeaderRecoveryListener,
        ImportRecoveryListener,
        MixinHeaderRecoveryListener;

import 'token_stream_rewriter.dart'
    show
        TokenStreamRewriter,
        TokenStreamRewriterImpl,
        UndoableTokenStreamRewriter;

import 'type_info.dart'
    show
        TypeInfo,
        TypeParamOrArgInfo,
        computeMethodTypeArguments,
        computeType,
        computeTypeParamOrArg,
        computeVariablePatternType,
        isValidNonRecordTypeReference,
        noType,
        noTypeParamOrArg;

import 'util.dart'
    show
        findNonZeroLengthToken,
        findPreviousNonZeroLengthToken,
        isLetter,
        isLetterOrDigit,
        isOneOf,
        isOneOfOrEof,
        isWhitespace,
        optional;

/// An event generating parser of Dart programs. This parser expects all tokens
/// in a linked list (aka a token stream).
///
/// The class [Scanner] is used to generate a token stream. See the file
/// [scanner.dart](../scanner.dart).
///
/// Subclasses of the class [Listener] are used to listen to events.
///
/// Most methods of this class belong in one of four major categories: parse
/// methods, peek methods, ensure methods, and skip methods.
///
/// Parse methods all have the prefix `parse`, generate events
/// (by calling methods on [listener]), and return the next token to parse.
/// Some exceptions to this last point are methods such as [parseFunctionBody]
/// and [parseClassOrMixinOrExtensionBody] which return the last token parsed
/// rather than the next token to be parsed.
/// Parse methods are generally named `parseGrammarProductionSuffix`.
/// The suffix can be one of `opt`, or `star`.
/// `opt` means zero or one matches, `star` means zero or more matches.
/// For example, [parseMetadataStar] corresponds to this grammar snippet:
/// `metadata*`, and [parseArgumentsOpt] corresponds to: `arguments?`.
///
/// Peek methods all have the prefix `peek`, do not generate events
/// (except for errors) and may return null.
///
/// Ensure methods all have the prefix `ensure` and may generate events.
/// They return the current token, or insert and return a synthetic token
/// if the current token does not match. For example,
/// [ensureSemicolon] returns the current token if the current token is a
/// semicolon, otherwise inserts a synthetic semicolon in the token stream
/// before the current token and then returns that new synthetic token.
///
/// Skip methods are like parse methods, but all have the prefix `skip`
/// and skip over some parts of the file being parsed.
/// Typically, skip methods generate an event for the structure being skipped,
/// but not for its substructures.
///
/// ## Current Token
///
/// The current token is always to be found in a formal parameter named
/// `token`. This parameter should be the first as this increases the chance
/// that a compiler will place it in a register.
///
/// ## Implementation Notes
///
/// The parser assumes that keywords, built-in identifiers, and other special
/// words (pseudo-keywords) are all canonicalized. To extend the parser to
/// recognize a new identifier, one should modify
/// [keyword.dart](../scanner/keyword.dart) and ensure the identifier is added
/// to the keyword table.
///
/// As a consequence of this, one should not use `==` to compare strings in the
/// parser. One should favor the methods [optional] and [expect] to recognize
/// keywords or identifiers. In some cases, it's possible to compare a token's
/// `stringValue` using [identical], but normally [optional] will suffice.
///
/// Historically, we over-used identical, and when identical is used on objects
/// other than strings, it can often be replaced by `==`.
///
/// ## Flexibility, Extensibility, and Specification
///
/// The parser is designed to be flexible and extensible. Its methods are
/// designed to be overridden in subclasses, so it can be extended to handle
/// unspecified language extension or experiments while everything in this file
/// attempts to follow the specification (unless when it interferes with error
/// recovery).
///
/// We achieve flexibility, extensible, and specification compliance by
/// following a few rules-of-thumb:
///
/// 1. All methods in the parser should be public.
///
/// 2. The methods follow the specified grammar, and do not implement custom
/// extensions, for example, `native`.
///
/// 3. The parser doesn't rewrite the token stream (when dealing with `>>`).
///
/// ### Implementing Extensions
///
/// For various reasons, some Dart language implementations have used
/// custom/unspecified extensions to the Dart grammar. Examples of this
/// includes diet parsing, patch files, `native` keyword, and generic
/// comments. This class isn't supposed to implement any of these
/// features. Instead it provides hooks for those extensions to be implemented
/// in subclasses or listeners. Let's examine how diet parsing and `native`
/// keyword is currently supported by Fasta.
///
/// #### Legacy Implementation of `native` Keyword
///
/// TODO(ahe,danrubel): Remove this section.
///
/// Both dart2js and the Dart VM have used the `native` keyword to mark methods
/// that couldn't be implemented in the Dart language and needed to be
/// implemented in JavaScript or C++, respectively. An example of the syntax
/// extension used by the Dart VM is:
///
///     nativeFunction() native "NativeFunction";
///
/// When attempting to parse this function, the parser eventually calls
/// [parseFunctionBody]. This method will report an unrecoverable error to the
/// listener with the code [fasta.messageExpectedFunctionBody]. The listener can
/// then look at the error code and the token and use the methods in
/// [native_support.dart](native_support.dart) to parse the native syntax.
///
/// #### Implementation of Diet Parsing
///
/// We call it _diet_ _parsing_ when the parser skips parts of a file. Both
/// dart2js and the Dart VM have been relying on this from early on as it allows
/// them to more quickly compile small programs that use small parts of big
/// libraries. It's also become an integrated part of how Fasta builds up
/// outlines before starting to parse method bodies.
///
/// When looking through this parser, you'll find a number of unused methods
/// starting with `skip`. These methods are only used by subclasses, such as
/// [ClassMemberParser](class_member_parser.dart) and
/// [TopLevelParser](top_level_parser.dart). These methods violate the
/// principle above about following the specified grammar, and originally lived
/// in subclasses. However, we realized that these methods were so widely used
/// and hard to maintain in subclasses, that it made sense to move them here.
///
/// ### Specification and Error Recovery
///
/// To improve error recovery, the parser will inform the listener of
/// recoverable errors and continue to parse.  An example of a recoverable
/// error is:
///
///     Error: Asynchronous for-loop can only be used in 'async' or 'async*'...
///     main() { await for (var x in []) {} }
///              ^^^^^
///
/// ### Legacy Error Recovery
///
/// What's described below will be phased out in preference of the parser
/// reporting and recovering from syntax errors. The motivation for this is
/// that we have multiple listeners that use the parser, and this will ensure
/// consistency.
///
/// For unrecoverable errors, the parser will ask the listener for help to
/// recover from the error. We haven't made much progress on these kinds of
/// errors, so in most cases, the parser aborts by skipping to the end of file.
///
/// Historically, this parser has been rather lax in what it allows, and
/// deferred the enforcement of some syntactical rules to subsequent phases. It
/// doesn't matter how we got there, only that we've identified that it's
/// easier if the parser reports as many errors it can, but informs the
/// listener if the error is recoverable or not.
class Parser {
  Listener listener;

  Uri? get uri => listener.uri;

  bool mayParseFunctionExpressions = true;

  /// Represents parser state: what asynchronous syntax is allowed in the
  /// function being currently parsed. In rare situations, this can be set by
  /// external clients, for example, to parse an expression outside a function.
  AsyncModifier asyncState = AsyncModifier.Sync;

  // TODO(danrubel): The [loopState] and associated functionality in the
  // [Parser] duplicates work that the resolver needs to do when resolving
  // break/continue targets. Long term, this state and functionality will be
  // removed from the [Parser] class and the resolver will be responsible
  // for generating all break/continue error messages.

  /// Represents parser state: whether parsing outside a loop,
  /// inside a loop, or inside a switch. This is used to determine whether
  /// break and continue statements are allowed.
  LoopState loopState = LoopState.OutsideLoop;

  /// A rewriter for inserting synthetic tokens.
  /// Access using [rewriter] for lazy initialization.
  TokenStreamRewriter? cachedRewriter;

  TokenStreamRewriter get rewriter {
    return cachedRewriter ??= new TokenStreamRewriterImpl();
  }

  /// If `true`, syntax like `foo<bar>.baz()` is parsed like an implicit
  /// creation expression. Otherwise it is parsed as a explicit instantiation
  /// followed by an invocation.
  ///
  /// With the constructor-tearoffs experiment, such syntax can lead to a valid
  /// expression that is _not_ an implicit creation expression, and the parser
  /// should therefore not special case the syntax but instead let listeners
  /// resolve the expression by the seen selectors.
  ///
  /// Use this flag to test that the implementation doesn't need the special
  /// casing.
  // TODO(johnniwinther): Remove this when both analyzer and CFE can parse the
  // implicit create expression without the special casing.
  final bool useImplicitCreationExpression;

  /// Indicates whether pattern parsing is enabled.
  ///
  /// This ensures that we don't regress non-pattern functionality while pattern
  /// parsing logic is being developed.  Eventually we will want to turn this
  /// functionality on permanently, and leave it to the client to report an
  /// appropriate error if a pattern is used while patterns are not enabled.
  /// TODO(paulberry): remove this flag when appropriate.
  final bool allowPatterns;

  Parser(this.listener,
      {this.useImplicitCreationExpression = true, this.allowPatterns = false})
      : assert(listener != null); // ignore:unnecessary_null_comparison

  /// Executes [callback]; however if `this` is the `TestParser` (from
  /// `pkg/front_end/test/parser_test_parser.dart`) then no output is printed
  /// during its execution.
  ///
  /// This is sometimes necessary inside `assert` statements, to ensure that the
  /// output of `TestParser` is the same regardless of whether assertions are
  /// enabled.
  T inhibitPrinting<T>(T Function() callback) {
    return callback();
  }

  bool get inGenerator {
    return asyncState == AsyncModifier.AsyncStar ||
        asyncState == AsyncModifier.SyncStar;
  }

  bool get inAsync {
    return asyncState == AsyncModifier.Async ||
        asyncState == AsyncModifier.AsyncStar;
  }

  bool get inPlainSync => asyncState == AsyncModifier.Sync;

  bool get isBreakAllowed => loopState != LoopState.OutsideLoop;

  bool get isContinueAllowed => loopState == LoopState.InsideLoop;

  bool get isContinueWithLabelAllowed => loopState != LoopState.OutsideLoop;

  /// Parse a compilation unit.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  ///
  /// ```
  /// libraryDefinition:
  ///   scriptTag?
  ///   libraryName?
  ///   importOrExport*
  ///   partDirective*
  ///   topLevelDefinition*
  /// ;
  ///
  /// partDeclaration:
  ///   partHeader topLevelDefinition*
  /// ;
  /// ```
  Token parseUnit(Token token) {
    // Skip over error tokens and report them at the end
    // so that the parser has the chance to adjust the error location.
    Token errorToken = token;
    token = skipErrorTokens(errorToken);

    listener.beginCompilationUnit(token);
    int count = 0;
    DirectiveContext directiveState = new DirectiveContext();
    token = syntheticPreviousToken(token);
    if (identical(token.next!.type, TokenType.SCRIPT_TAG)) {
      directiveState.checkScriptTag(this, token.next!);
      token = parseScript(token);
    }
    while (!token.next!.isEof) {
      final Token start = token.next!;
      token = parseTopLevelDeclarationImpl(token, directiveState);
      listener.endTopLevelDeclaration(token.next!);
      count++;
      if (start == token.next!) {
        // Recovery:
        // If progress has not been made reaching the end of the token stream,
        // then report an error and skip the current token.
        token = token.next!;
        listener.beginMetadataStar(token);
        listener.endMetadataStar(/* count = */ 0);
        reportRecoverableErrorWithToken(
            token, codes.templateExpectedDeclaration);
        listener.handleInvalidTopLevelDeclaration(token);
        listener.endTopLevelDeclaration(token.next!);
        count++;
      }
    }
    token = token.next!;
    reportAllErrorTokens(errorToken);
    listener.endCompilationUnit(count, token);
    // Clear fields that could lead to memory leak.
    cachedRewriter = null;
    return token;
  }

  /// This method exists for analyzer compatibility only
  /// and will be removed once analyzer/fasta integration is complete.
  ///
  /// Similar to [parseUnit], this method parses a compilation unit,
  /// but stops when it reaches the first declaration or EOF.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseDirectives(Token token) {
    listener.beginCompilationUnit(token);
    int count = 0;
    DirectiveContext directiveState = new DirectiveContext();
    token = syntheticPreviousToken(token);
    while (!token.next!.isEof) {
      final Token start = token.next!;
      final String? nextValue = start.next!.stringValue;

      // If a built-in keyword is being used as function name, then stop.
      if (identical(nextValue, '.') ||
          identical(nextValue, '<') ||
          identical(nextValue, '(')) {
        break;
      }

      if (identical(token.next!.type, TokenType.SCRIPT_TAG)) {
        directiveState.checkScriptTag(this, token.next!);
        token = parseScript(token);
      } else {
        token = parseMetadataStar(token);
        Token keyword = token.next!;
        final String? value = keyword.stringValue;
        if (identical(value, 'import')) {
          directiveState.checkImport(this, keyword);
          token = parseImport(keyword);
        } else if (identical(value, 'export')) {
          directiveState.checkExport(this, keyword);
          token = parseExport(keyword);
        } else if (identical(value, 'library')) {
          directiveState.checkLibrary(this, keyword);
          token = parseLibraryName(keyword);
        } else if (identical(value, 'part')) {
          token = parsePartOrPartOf(keyword, directiveState);
        } else if (identical(value, ';')) {
          token = start;
          listener.handleDirectivesOnly();
        } else {
          listener.handleDirectivesOnly();
          break;
        }
      }
      listener.endTopLevelDeclaration(token.next!);
    }
    token = token.next!;
    listener.endCompilationUnit(count, token);
    // Clear fields that could lead to memory leak.
    cachedRewriter = null;
    return token;
  }

  /// Parse a top-level declaration.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseTopLevelDeclaration(Token token) {
    token = parseTopLevelDeclarationImpl(
            syntheticPreviousToken(token), /* directiveState = */ null)
        .next!;
    listener.endTopLevelDeclaration(token);
    return token;
  }

  /// ```
  /// topLevelDefinition:
  ///   classDefinition |
  ///   enumType |
  ///   typeAlias |
  ///   'external'? functionSignature ';' |
  ///   'external'? getterSignature ';' |
  ///   'external''? setterSignature ';' |
  ///   functionSignature functionBody |
  ///   returnType? 'get' identifier functionBody |
  ///   returnType? 'set' identifier formalParameterList functionBody |
  ///   ('final' | 'const') type? staticFinalDeclarationList ';' |
  ///   variableDeclaration ';'
  /// ;
  /// ```
  Token parseTopLevelDeclarationImpl(
      Token token, DirectiveContext? directiveState) {
    token = parseMetadataStar(token);
    Token next = token.next!;
    if (next.isTopLevelKeyword) {
      return parseTopLevelKeywordDeclaration(
          /* start = */ token,
          /* keyword = */ next,
          /* macroToken = */ null,
          /* inlineToken = */ null,
          /* sealedToken = */ null,
          /* baseToken = */ null,
          /* interfaceToken = */ null,
          directiveState);
    }
    Token start = token;
    // Skip modifiers to find a top level keyword or identifier
    if (next.isModifier) {
      if (optional('var', next) ||
          optional('late', next) ||
          (optional('final', next) &&
              (!optional('class', next.next!) &&
                  !optional('mixin', next.next!))) ||
          // Ignore using 'final' as a modifier for a class or a mixin, but
          // allow in other contexts.
          (optional('const', next) && !optional('class', next.next!))) {
        // Ignore `const class` so that it is reported below as an invalid
        // modifier on a class.
        directiveState?.checkDeclaration();
        return parseTopLevelMemberImpl(token);
      }
      while (token.next!.isModifier) {
        token = token.next!;
      }
    }
    next = token.next!;
    Token? macroToken;
    Token? inlineToken;
    Token? sealedToken;
    Token? baseToken;
    Token? interfaceToken;
    if (next.isIdentifier &&
        next.lexeme == 'inline' &&
        optional('class', next.next!)) {
      inlineToken = next;
      next = next.next!;
    } else if (next.isIdentifier &&
        next.lexeme == 'macro' &&
        optional('class', next.next!)) {
      macroToken = next;
      next = next.next!;
    } else if (next.isIdentifier && next.lexeme == 'sealed') {
      sealedToken = next;
      if (optional('class', next.next!) || optional('mixin', next.next!)) {
        next = next.next!;
      } else if (optional('abstract', next.next!) &&
          optional('class', next.next!.next!)) {
        // Defer error handling of sealed abstract to
        // [parseClassOrNamedMixinApplication] after the abstract is parsed.
        start = next;
        next = next.next!.next!;
      }
    } else if (next.isIdentifier && next.lexeme == 'base') {
      baseToken = next;
      if (optional('class', next.next!) || optional('mixin', next.next!)) {
        next = next.next!;
      }
    } else if (next.isIdentifier && next.lexeme == 'interface') {
      interfaceToken = next;
      if (optional('class', next.next!) || optional('mixin', next.next!)) {
        next = next.next!;
      }
      // TODO(kallentu): Handle incorrect ordering of modifiers.
    }
    if (next.isTopLevelKeyword) {
      return parseTopLevelKeywordDeclaration(
          /* start = */ start,
          /* keyword = */ next,
          /* macroToken = */ macroToken,
          /* inlineToken = */ inlineToken,
          /* sealedToken = */ sealedToken,
          /* baseToken = */ baseToken,
          /* interfaceToken = */ interfaceToken,
          directiveState);
    } else if (next.isKeywordOrIdentifier) {
      // TODO(danrubel): improve parseTopLevelMember
      // so that we don't parse modifiers twice.
      directiveState?.checkDeclaration();
      return parseTopLevelMemberImpl(start);
    } else if (start.next != next) {
      directiveState?.checkDeclaration();
      // Handle the edge case where a modifier is being used as an identifier
      return parseTopLevelMemberImpl(start);
    } else if (/* record type */ optional('(', next)) {
      directiveState?.checkDeclaration();
      return parseTopLevelMemberImpl(start);
    }

    // Recovery
    if (next.isOperator && optional('(', next.next!)) {
      // This appears to be a top level operator declaration, which is invalid.
      reportRecoverableError(next, codes.messageTopLevelOperator);
      // Insert a synthetic identifier
      // and continue parsing as a top level function.
      rewriter.insertSyntheticIdentifier(
          next, '#synthetic_function_${next.charOffset}');
      return parseTopLevelMemberImpl(next);
    }
    // Ignore any preceding modifiers and just report the unexpected token
    listener.beginTopLevelMember(next);
    return parseInvalidTopLevelDeclaration(token);
  }

  /// Parse any top-level declaration that begins with a keyword.
  /// [start] is the token before any modifiers preceding [keyword].
  Token parseTopLevelKeywordDeclaration(
      Token start,
      Token keyword,
      Token? macroToken,
      Token? inlineToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      DirectiveContext? directiveState) {
    assert(keyword.isTopLevelKeyword);
    final String? value = keyword.stringValue;
    if (identical(value, 'class')) {
      return _handleModifiersForClassDeclaration(
          start,
          keyword,
          macroToken,
          inlineToken,
          sealedToken,
          baseToken,
          interfaceToken,
          /* mixinToken = */ null,
          directiveState);
    } else if (identical(value, 'enum')) {
      directiveState?.checkDeclaration();
      ModifierContext context = new ModifierContext(this);
      context.parseEnumModifiers(start, keyword);
      return parseEnum(keyword);
    } else {
      // The remaining top level keywords are built-in keywords
      // and can be used in a top level declaration
      // as an identifier such as "abstract<T>() => 0;"
      // or as a prefix such as "abstract.A b() => 0;".
      // This also means that `typedef ({int? j}) => 0;` is a method, but with
      // records something like `typedef ({int? j}) X();` is a typedef.
      String? nextValue = keyword.next!.stringValue;
      bool typedefWithRecord = false;
      if (identical(value, 'typedef') && identical(nextValue, '(')) {
        Token? endParen = keyword.next!.endGroup;
        if (endParen != null &&
            _isIdentifierOrQuestionIdentifier(endParen.next!)) {
          // Looks like a typedef with a record.
          TypeInfo typeInfo = computeType(keyword, /* required = */ false);
          if (typeInfo is ComplexTypeInfo && typeInfo.isRecordType) {
            typedefWithRecord = true;
          }
        }
      }

      if ((identical(nextValue, '(') || identical(nextValue, '.')) &&
          !typedefWithRecord) {
        directiveState?.checkDeclaration();
        return parseTopLevelMemberImpl(start);
      } else if (identical(nextValue, '<')) {
        if (identical(value, 'extension')) {
          // The name in an extension declaration is optional:
          // `extension<T> on ...`
          Token? endGroup = keyword.next!.endGroup;
          if (endGroup != null && optional('on', endGroup.next!)) {
            directiveState?.checkDeclaration();
            return parseExtension(keyword);
          }
        }
        directiveState?.checkDeclaration();
        return parseTopLevelMemberImpl(start);
      } else {
        ModifierContext context = new ModifierContext(this);
        if (identical(value, 'import')) {
          context.parseTopLevelKeywordModifiers(start, keyword);
          directiveState?.checkImport(this, keyword);
          return parseImport(keyword);
        } else if (identical(value, 'export')) {
          context.parseTopLevelKeywordModifiers(start, keyword);
          directiveState?.checkExport(this, keyword);
          return parseExport(keyword);
        } else if (identical(value, 'typedef')) {
          context.parseTopLevelKeywordModifiers(start, keyword);
          directiveState?.checkDeclaration();
          return parseTypedef(keyword);
        } else if (identical(value, 'mixin')) {
          if (identical(nextValue, 'class')) {
            // TODO(kallentu): Error handling for any class modifier here other
            // than base. Only base mixin classes are allowed.
            return _handleModifiersForClassDeclaration(
                start,
                keyword.next!,
                macroToken,
                inlineToken,
                sealedToken,
                baseToken,
                /* interfaceToken = */ null,
                keyword,
                directiveState);
          }
          context.parseMixinModifiers(start, keyword);
          directiveState?.checkDeclaration();
          return parseMixin(context.augmentToken, sealedToken, baseToken,
              interfaceToken, context.finalToken, keyword);
        } else if (identical(value, 'extension')) {
          context.parseTopLevelKeywordModifiers(start, keyword);
          directiveState?.checkDeclaration();
          return parseExtension(keyword);
        } else if (identical(value, 'part')) {
          context.parseTopLevelKeywordModifiers(start, keyword);
          return parsePartOrPartOf(keyword, directiveState);
        } else if (identical(value, 'library')) {
          context.parseTopLevelKeywordModifiers(start, keyword);
          directiveState?.checkLibrary(this, keyword);
          final Token tokenAfterKeyword = keyword.next!;
          if (tokenAfterKeyword.isIdentifier &&
              tokenAfterKeyword.lexeme == 'augment') {
            return parseLibraryAugmentation(keyword, tokenAfterKeyword);
          } else {
            return parseLibraryName(keyword);
          }
        }
      }
    }

    throw "Internal error: Unhandled top level keyword '$value'.";
  }

  Token _handleModifiersForClassDeclaration(
      Token start,
      Token classKeyword,
      Token? macroToken,
      Token? inlineToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? mixinToken,
      DirectiveContext? directiveState) {
    directiveState?.checkDeclaration();
    ModifierContext context = new ModifierContext(this);
    if (mixinToken != null) {
      context.parseClassModifiers(start, mixinToken);
    } else {
      context.parseClassModifiers(start, classKeyword);
    }
    return parseClassOrNamedMixinApplication(
        context.abstractToken,
        macroToken,
        inlineToken,
        sealedToken,
        baseToken,
        interfaceToken,
        context.finalToken,
        context.augmentToken,
        mixinToken,
        classKeyword);
  }

  bool _isIdentifierOrQuestionIdentifier(Token token) {
    if (token.isIdentifier) return true;
    if (optional("?", token)) {
      return token.next!.isIdentifier;
    }
    return false;
  }

  /// ```
  /// libraryAugmentationDirective:
  ///   'library' 'augment' uri ';'
  /// ;
  /// ```
  Token parseLibraryAugmentation(Token libraryKeyword, Token augmentKeyword) {
    assert(optional('library', libraryKeyword));
    assert(optional('augment', augmentKeyword));
    listener.beginUncategorizedTopLevelDeclaration(libraryKeyword);
    listener.beginLibraryAugmentation(libraryKeyword, augmentKeyword);
    Token start = augmentKeyword;
    Token token = ensureLiteralString(start);
    Token semicolon = ensureSemicolon(token);
    listener.endLibraryAugmentation(libraryKeyword, augmentKeyword, semicolon);
    return semicolon;
  }

  /// ```
  /// libraryDirective:
  ///   'library' qualified? ';'
  /// ;
  /// ```
  Token parseLibraryName(Token libraryKeyword) {
    assert(optional('library', libraryKeyword));
    listener.beginUncategorizedTopLevelDeclaration(libraryKeyword);
    listener.beginLibraryName(libraryKeyword);
    Token token = libraryKeyword.next!;
    bool hasName = !optional(';', token);
    if (hasName) {
      token = parseQualified(libraryKeyword, IdentifierContext.libraryName,
          IdentifierContext.libraryNameContinuation);
      token = ensureSemicolon(token);
    } else {
      token = ensureSemicolon(libraryKeyword);
    }
    listener.endLibraryName(libraryKeyword, token, hasName);
    return token;
  }

  /// ```
  /// importPrefix:
  ///   'deferred'? 'as' identifier
  /// ;
  /// ```
  Token parseImportPrefixOpt(Token token) {
    Token next = token.next!;
    if (optional('deferred', next) && optional('as', next.next!)) {
      Token deferredToken = next;
      Token asKeyword = next.next!;
      token = ensureIdentifier(
          asKeyword, IdentifierContext.importPrefixDeclaration);
      listener.handleImportPrefix(deferredToken, asKeyword);
    } else if (optional('as', next)) {
      Token asKeyword = next;
      token = ensureIdentifier(next, IdentifierContext.importPrefixDeclaration);
      listener.handleImportPrefix(/* deferredKeyword = */ null, asKeyword);
    } else {
      listener.handleImportPrefix(
        /* deferredKeyword = */ null,
        /* asKeyword = */ null,
      );
    }
    return token;
  }

  /// ```
  /// importDirective:
  ///   'import' uri ('if' '(' test ')' uri)* importPrefix? combinator* ';'
  /// ;
  /// ```
  Token parseImport(Token importKeyword) {
    assert(optional('import', importKeyword));
    listener.beginUncategorizedTopLevelDeclaration(importKeyword);
    listener.beginImport(importKeyword);
    Token start = importKeyword;
    Token? augmentToken;
    if (start.next!.isIdentifier && start.next!.lexeme == 'augment') {
      start = augmentToken = start.next!;
    }
    Token token = ensureLiteralString(start);
    Token uri = token;
    token = parseConditionalUriStar(token);
    token = parseImportPrefixOpt(token);
    token = parseCombinatorStar(token).next!;
    if (optional(';', token)) {
      listener.endImport(importKeyword, augmentToken, token);
      return token;
    } else {
      // Recovery
      listener.endImport(importKeyword, augmentToken, /* semicolon = */ null);
      return parseImportRecovery(uri);
    }
  }

  /// Recover given out-of-order clauses in an import directive where [token] is
  /// the import keyword.
  Token parseImportRecovery(Token token) {
    final Listener primaryListener = listener;
    final ImportRecoveryListener recoveryListener =
        new ImportRecoveryListener();

    // Reparse to determine which clauses have already been parsed
    // but intercept the events so they are not sent to the primary listener
    listener = recoveryListener;
    token = parseConditionalUriStar(token);
    token = parseImportPrefixOpt(token);
    token = parseCombinatorStar(token);

    Token? firstDeferredKeyword = recoveryListener.deferredKeyword;
    bool hasPrefix = recoveryListener.asKeyword != null;
    bool hasCombinator = recoveryListener.hasCombinator;

    // Update the recovery listener to forward subsequent events
    // to the primary listener
    recoveryListener.listener = primaryListener;

    // Parse additional out-of-order clauses.
    Token? semicolon;
    do {
      Token start = token.next!;

      // Check for extraneous token in the middle of an import statement.
      token = skipUnexpectedTokenOpt(
          token, const <String>['if', 'deferred', 'as', 'hide', 'show', ';']);

      // During recovery, clauses are parsed in the same order
      // and generate the same events as in the parseImport method above.
      recoveryListener.clear();
      token = parseConditionalUriStar(token);
      if (recoveryListener.ifKeyword != null) {
        if (firstDeferredKeyword != null) {
          // TODO(danrubel): report error indicating conditional should
          // be moved before deferred keyword
        } else if (hasPrefix) {
          // TODO(danrubel): report error indicating conditional should
          // be moved before prefix clause
        } else if (hasCombinator) {
          // TODO(danrubel): report error indicating conditional should
          // be moved before combinators
        }
      }

      if (optional('deferred', token.next!) &&
          !optional('as', token.next!.next!)) {
        listener.handleImportPrefix(token.next!, /* asKeyword = */ null);
        token = token.next!;
      } else {
        token = parseImportPrefixOpt(token);
      }
      if (recoveryListener.deferredKeyword != null) {
        if (firstDeferredKeyword != null) {
          reportRecoverableError(recoveryListener.deferredKeyword!,
              codes.messageDuplicateDeferred);
        } else {
          if (hasPrefix) {
            reportRecoverableError(recoveryListener.deferredKeyword!,
                codes.messageDeferredAfterPrefix);
          }
          firstDeferredKeyword = recoveryListener.deferredKeyword;
        }
      }
      if (recoveryListener.asKeyword != null) {
        if (hasPrefix) {
          reportRecoverableError(
              recoveryListener.asKeyword!, codes.messageDuplicatePrefix);
        } else {
          if (hasCombinator) {
            reportRecoverableError(recoveryListener.asKeyword!,
                codes.messagePrefixAfterCombinator);
          }
          hasPrefix = true;
        }
      }

      token = parseCombinatorStar(token);
      hasCombinator = hasCombinator || recoveryListener.hasCombinator;

      if (optional(';', token.next!)) {
        semicolon = token.next!;
      } else if (identical(start, token.next!)) {
        // If no forward progress was made, insert ';' so that we exit loop.
        semicolon = ensureSemicolon(token);
      }
      listener.handleRecoverImport(semicolon);
    } while (semicolon == null);

    if (firstDeferredKeyword != null && !hasPrefix) {
      reportRecoverableError(
          firstDeferredKeyword, codes.messageMissingPrefixInDeferredImport);
    }

    return semicolon;
  }

  /// ```
  /// conditionalUris:
  ///   conditionalUri*
  /// ;
  /// ```
  Token parseConditionalUriStar(Token token) {
    listener.beginConditionalUris(token.next!);
    int count = 0;
    while (optional('if', token.next!)) {
      count++;
      token = parseConditionalUri(token);
    }
    listener.endConditionalUris(count);
    return token;
  }

  /// ```
  /// conditionalUri:
  ///   'if' '(' dottedName ('==' literalString)? ')' uri
  /// ;
  /// ```
  Token parseConditionalUri(Token token) {
    Token ifKeyword = token = token.next!;
    assert(optional('if', token));
    listener.beginConditionalUri(token);
    Token leftParen = token.next!;
    if (!optional('(', leftParen)) {
      reportRecoverableError(
          leftParen, codes.templateExpectedButGot.withArguments('('));
      leftParen = rewriter.insertParens(token, /* includeIdentifier = */ true);
    }
    token = parseDottedName(leftParen);
    Token next = token.next!;
    Token? equalitySign;
    if (optional('==', next)) {
      equalitySign = next;
      token = ensureLiteralString(next);
      next = token.next!;
    }
    if (next != leftParen.endGroup) {
      Token endGroup = leftParen.endGroup!;
      if (endGroup.isSynthetic) {
        // The scanner did not place the synthetic ')' correctly, so move it.
        next = rewriter.moveSynthetic(token, endGroup);
      } else {
        reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
        next = endGroup;
      }
    }
    token = next;
    assert(optional(')', token));

    token = ensureLiteralString(token);
    listener.endConditionalUri(ifKeyword, leftParen, equalitySign);
    return token;
  }

  /// ```
  /// dottedName:
  ///   identifier ('.' identifier)*
  /// ;
  /// ```
  Token parseDottedName(Token token) {
    token = ensureIdentifier(token, IdentifierContext.dottedName);
    Token firstIdentifier = token;
    int count = 1;
    while (optional('.', token.next!)) {
      token = ensureIdentifier(
          token.next!, IdentifierContext.dottedNameContinuation);
      count++;
    }
    listener.handleDottedName(count, firstIdentifier);
    return token;
  }

  /// ```
  /// exportDirective:
  ///   'export' uri conditional-uris* combinator* ';'
  /// ;
  /// ```
  Token parseExport(Token exportKeyword) {
    assert(optional('export', exportKeyword));
    listener.beginUncategorizedTopLevelDeclaration(exportKeyword);
    listener.beginExport(exportKeyword);
    Token token = ensureLiteralString(exportKeyword);
    token = parseConditionalUriStar(token);
    token = parseCombinatorStar(token);
    token = ensureSemicolon(token);
    listener.endExport(exportKeyword, token);
    return token;
  }

  /// ```
  /// combinators:
  ///   (hideCombinator | showCombinator)*
  /// ;
  /// ```
  Token parseCombinatorStar(Token token) {
    Token next = token.next!;
    listener.beginCombinators(next);
    int count = 0;
    while (true) {
      String? value = next.stringValue;
      if (identical('hide', value)) {
        token = parseHide(token);
      } else if (identical('show', value)) {
        token = parseShow(token);
      } else {
        listener.endCombinators(count);
        break;
      }
      next = token.next!;
      count++;
    }
    return token;
  }

  /// ```
  /// hideCombinator:
  ///   'hide' identifierList
  /// ;
  /// ```
  Token parseHide(Token token) {
    Token hideKeyword = token.next!;
    assert(optional('hide', hideKeyword));
    listener.beginHide(hideKeyword);
    token = parseIdentifierList(hideKeyword);
    listener.endHide(hideKeyword);
    return token;
  }

  /// ```
  /// showCombinator:
  ///   'show' identifierList
  /// ;
  /// ```
  Token parseShow(Token token) {
    Token showKeyword = token.next!;
    assert(optional('show', showKeyword));
    listener.beginShow(showKeyword);
    token = parseIdentifierList(showKeyword);
    listener.endShow(showKeyword);
    return token;
  }

  /// ```
  /// identifierList:
  ///   identifier (',' identifier)*
  /// ;
  /// ```
  Token parseIdentifierList(Token token) {
    token = ensureIdentifier(token, IdentifierContext.combinator);
    int count = 1;
    while (optional(',', token.next!)) {
      token = ensureIdentifier(token.next!, IdentifierContext.combinator);
      count++;
    }
    listener.handleIdentifierList(count);
    return token;
  }

  /// ```
  /// typeList:
  ///   type (',' type)*
  /// ;
  /// ```
  Token parseTypeList(Token token) {
    listener.beginTypeList(token.next!);
    token =
        computeType(token, /* required = */ true).ensureTypeOrVoid(token, this);
    int count = 1;
    while (optional(',', token.next!)) {
      token = computeType(token.next!, /* required = */ true)
          .ensureTypeOrVoid(token.next!, this);
      count++;
    }
    listener.endTypeList(count);
    return token;
  }

  Token parsePartOrPartOf(Token partKeyword, DirectiveContext? directiveState) {
    assert(optional('part', partKeyword));
    listener.beginUncategorizedTopLevelDeclaration(partKeyword);
    if (optional('of', partKeyword.next!)) {
      directiveState?.checkPartOf(this, partKeyword);
      return parsePartOf(partKeyword);
    } else {
      directiveState?.checkPart(this, partKeyword);
      return parsePart(partKeyword);
    }
  }

  /// ```
  /// partDirective:
  ///   'part' uri ';'
  /// ;
  /// ```
  Token parsePart(Token partKeyword) {
    assert(optional('part', partKeyword));
    listener.beginPart(partKeyword);
    Token token = ensureLiteralString(partKeyword);
    token = ensureSemicolon(token);
    listener.endPart(partKeyword, token);
    return token;
  }

  /// ```
  /// partOfDirective:
  ///   'part' 'of' (qualified | uri) ';'
  /// ;
  /// ```
  Token parsePartOf(Token partKeyword) {
    Token ofKeyword = partKeyword.next!;
    assert(optional('part', partKeyword));
    assert(optional('of', ofKeyword));
    listener.beginPartOf(partKeyword);
    bool hasName = ofKeyword.next!.isIdentifier;
    Token token;
    if (hasName) {
      token = parseQualified(ofKeyword, IdentifierContext.partName,
          IdentifierContext.partNameContinuation);
    } else {
      token = ensureLiteralString(ofKeyword);
    }
    token = ensureSemicolon(token);
    listener.endPartOf(partKeyword, ofKeyword, token, hasName);
    return token;
  }

  /// ```
  /// metadata:
  ///   annotation*
  /// ;
  /// ```
  Token parseMetadataStar(Token token) {
    listener.beginMetadataStar(token.next!);
    int count = 0;
    while (optional('@', token.next!)) {
      token = parseMetadata(token);
      count++;
    }
    listener.endMetadataStar(count);
    return token;
  }

  /// ```
  /// <metadata> ::= (‘@’ <metadatum>)*
  /// <metadatum> ::= <identifier>
  ///   | <qualifiedName>
  ///   | <constructorDesignation> <arguments>
  /// <qualifiedName> ::= <typeIdentifier> ‘.’ <identifier>
  ///   | <typeIdentifier> ‘.’ <typeIdentifier> ‘.’ <identifier>
  /// <constructorDesignation> ::= <typeIdentifier>
  ///   | <qualifiedName>
  ///   | <typeName> <typeArguments> (‘.’ <identifier>)?
  /// <typeName> ::= <typeIdentifier> (‘.’ <typeIdentifier>)?
  /// ```
  /// (where typeIdentifier is an identifier that's not on the list of
  /// built in identifiers)
  /// So these are legal:
  /// * identifier
  /// qualifiedName:
  /// * typeIdentifier.identifier
  /// * typeIdentifier.typeIdentifier.identifier
  /// via constructorDesignation part 1
  /// * typeIdentifier(arguments)
  /// via constructorDesignation part 2
  /// * typeIdentifier.identifier(arguments)
  /// * typeIdentifier.typeIdentifier.identifier(arguments)
  /// via constructorDesignation part 3
  /// * typeIdentifier<typeArguments>(arguments)
  /// * typeIdentifier<typeArguments>.identifier(arguments)
  /// * typeIdentifier.typeIdentifier<typeArguments>(arguments)
  /// * typeIdentifier.typeIdentifier<typeArguments>.identifier(arguments)
  ///
  /// So in another way (ignoring the difference between typeIdentifier and
  /// identifier):
  /// * 1, 2 or 3 identifiers with or without arguments.
  /// * 1 or 2 identifiers, then type arguments, then possibly followed by a
  ///   single identifier, and then (required!) arguments.
  ///
  /// Note that if this is updated [skipMetadata] (in util.dart) should be
  /// updated as well.
  Token parseMetadata(Token token) {
    Token atToken = token.next!;
    assert(optional('@', atToken));
    listener.beginMetadata(atToken);
    token = ensureIdentifier(atToken, IdentifierContext.metadataReference);
    token =
        parseQualifiedRestOpt(token, IdentifierContext.metadataContinuation);
    bool hasTypeArguments = optional("<", token.next!);
    token = computeTypeParamOrArg(token).parseArguments(token, this);
    Token? period = null;
    if (optional('.', token.next!)) {
      period = token.next!;
      token = ensureIdentifier(
          period, IdentifierContext.metadataContinuationAfterTypeArguments);
    }
    if (hasTypeArguments && !optional("(", token.next!)) {
      reportRecoverableError(
          token, codes.messageMetadataTypeArgumentsUninstantiated);
    }
    token = parseArgumentsOptMetadata(token, hasTypeArguments);
    listener.endMetadata(atToken, period, token.next!);
    return token;
  }

  /// ```
  /// scriptTag:
  ///   '#!' (˜NEWLINE)* NEWLINE
  /// ;
  /// ```
  Token parseScript(Token token) {
    token = token.next!;
    assert(identical(token.type, TokenType.SCRIPT_TAG));
    listener.handleScript(token);
    return token;
  }

  /// ```
  /// typeAlias:
  ///   metadata 'typedef' typeAliasBody |
  ///   metadata 'typedef' identifier typeParameters? '=' functionType ';'
  /// ;
  ///
  /// functionType:
  ///   returnType? 'Function' typeParameters? parameterTypeList
  ///
  /// typeAliasBody:
  ///   functionTypeAlias
  /// ;
  ///
  /// functionTypeAlias:
  ///   functionPrefix typeParameters? formalParameterList ‘;’
  /// ;
  ///
  /// functionPrefix:
  ///   returnType? identifier
  /// ;
  /// ```
  Token parseTypedef(Token typedefKeyword) {
    assert(optional('typedef', typedefKeyword));
    listener.beginUncategorizedTopLevelDeclaration(typedefKeyword);
    listener.beginTypedef(typedefKeyword);
    TypeInfo typeInfo = computeType(typedefKeyword, /* required = */ false);
    Token token = typeInfo.skipType(typedefKeyword);
    Token next = token.next!;
    Token? equals;
    TypeParamOrArgInfo typeParam =
        computeTypeParamOrArg(next, /* inDeclaration = */ true);
    if (typeInfo == noType && optional('=', typeParam.skip(next).next!)) {
      // New style typedef, e.g. typedef foo = void Function();".

      // Parse as recovered here to 'force' using it as an identifier as we've
      // already established that the next token is the equal sign we're looking
      // for.
      token = ensureIdentifierPotentiallyRecovered(token,
          IdentifierContext.typedefDeclaration, /* isRecovered = */ true);

      token = typeParam.parseVariables(token, this);
      next = token.next!;
      // parseVariables rewrites so even though we checked in the if,
      // we might not have an equal here now.
      if (!optional('=', next) && optional('=', next.next!)) {
        // Recovery after recovery: A token was inserted, but we'll skip it now
        // to get more in line with what we thought in the if before.
        next = next.next!;
      }
      if (optional('=', next)) {
        equals = next;
        TypeInfo type = computeType(equals, /* required = */ true);
        if (!type.isFunctionType) {
          // Recovery: In certain cases insert missing 'Function' and missing
          // parens.
          Token skippedType = type.skipType(equals);
          if (optional('(', skippedType.next!) &&
              skippedType.next!.endGroup != null &&
              optional(';', skippedType.next!.endGroup!.next!)) {
            // Turn "<return type>? '(' <whatever> ')';"
            // into "<return type>? Function '(' <whatever> ')';".
            // Assume the type is meant as the return type.
            Token functionToken =
                rewriter.insertSyntheticKeyword(skippedType, Keyword.FUNCTION);
            reportRecoverableError(functionToken,
                codes.templateExpectedButGot.withArguments('Function'));
            type = computeType(equals, /* required = */ true);
          } else if (type is NoType &&
              optional('<', skippedType.next!) &&
              skippedType.next!.endGroup != null) {
            // Recover these two:
            // "<whatever>;" => "Function<whatever>();"
            // "<whatever>(<whatever>);" => "Function<whatever>(<whatever>);"
            Token endGroup = skippedType.next!.endGroup!;
            bool recover = false;
            if (optional(';', endGroup.next!)) {
              // Missing parenthesis. Insert them.
              // Turn "<whatever>;" into "<whatever>();"
              // Insert missing 'Function' below.
              reportRecoverableError(endGroup,
                  missingParameterMessage(MemberKind.FunctionTypeAlias));
              rewriter.insertParens(endGroup, /* includeIdentifier = */ false);
              recover = true;
            } else if (optional('(', endGroup.next!) &&
                endGroup.next!.endGroup != null &&
                optional(';', endGroup.next!.endGroup!.next!)) {
              // "<whatever>(<whatever>);". Insert missing 'Function' below.
              recover = true;
            }

            if (recover) {
              // Assume the '<' indicates type arguments to the function.
              // Insert 'Function' before them.
              Token functionToken =
                  rewriter.insertSyntheticKeyword(equals, Keyword.FUNCTION);
              reportRecoverableError(functionToken,
                  codes.templateExpectedButGot.withArguments('Function'));
              type = computeType(equals, /* required = */ true);
            }
          } else {
            // E.g. "typedef j = foo;" -- don't attempt any recovery.
          }
        }
        token = type.ensureTypeOrVoid(equals, this);
      } else {
        // A rewrite caused the = to disappear
        token = parseFormalParametersRequiredOpt(
            next, MemberKind.FunctionTypeAlias);
      }
    } else {
      // Old style typedef, e.g. "typedef void foo();".
      token = typeInfo.parseType(typedefKeyword, this);
      next = token.next!;
      bool isIdentifierRecovered = false;
      if (next.kind != IDENTIFIER_TOKEN &&
          optional('(', typeParam.skip(next).next!)) {
        // Recovery: Not a valid identifier, but is used as such.
        isIdentifierRecovered = true;
      }
      token = ensureIdentifierPotentiallyRecovered(
          token, IdentifierContext.typedefDeclaration, isIdentifierRecovered);
      token = typeParam.parseVariables(token, this);
      token =
          parseFormalParametersRequiredOpt(token, MemberKind.FunctionTypeAlias);
    }
    token = ensureSemicolon(token);
    listener.endTypedef(typedefKeyword, equals, token);
    return token;
  }

  /// Parse a mixin application starting from `with`. Assumes that the first
  /// type has already been parsed.
  Token parseMixinApplicationRest(Token token) {
    Token withKeyword = token.next!;
    if (!optional('with', withKeyword)) {
      // Recovery: Report an error and insert synthetic `with` clause.
      reportRecoverableError(
          withKeyword, codes.templateExpectedButGot.withArguments('with'));
      withKeyword = rewriter.insertSyntheticKeyword(token, Keyword.WITH);
      if (!isValidNonRecordTypeReference(withKeyword.next!)) {
        rewriter.insertSyntheticIdentifier(withKeyword);
      }
    }
    token = parseTypeList(withKeyword);
    listener.handleNamedMixinApplicationWithClause(withKeyword);
    return token;
  }

  Token parseClassWithClauseOpt(Token token) {
    // <mixins> ::= with <typeNotVoidList>
    Token withKeyword = token.next!;
    if (optional('with', withKeyword)) {
      token = parseTypeList(withKeyword);
      listener.handleClassWithClause(withKeyword);
    } else {
      listener.handleClassNoWithClause();
    }
    return token;
  }

  Token parseEnumWithClauseOpt(Token token) {
    // <mixins> ::= with <typeNotVoidList>
    Token withKeyword = token.next!;
    if (optional('with', withKeyword)) {
      token = parseTypeList(withKeyword);
      listener.handleEnumWithClause(withKeyword);
    } else {
      listener.handleEnumNoWithClause();
    }
    return token;
  }

  /// Parse the formal parameters of a getter (which shouldn't have parameters)
  /// or function or method.
  Token parseGetterOrFormalParameters(
      Token token, Token name, bool isGetter, MemberKind kind) {
    Token next = token.next!;
    if (optional("(", next)) {
      if (isGetter) {
        reportRecoverableError(next, codes.messageGetterWithFormals);
      }
      token = parseFormalParameters(token, kind);
    } else if (isGetter) {
      listener.handleNoFormalParameters(next, kind);
    } else {
      // Recovery
      if (optional('operator', name)) {
        Token next = name.next!;
        if (next.isOperator) {
          name = next;
        } else if (isUnaryMinus(next)) {
          name = next.next!;
        }
      }
      reportRecoverableError(name, missingParameterMessage(kind));
      token = rewriter.insertParens(token, /* includeIdentifier = */ false);
      token = parseFormalParametersRest(token, kind);
    }
    return token;
  }

  Token parseFormalParametersOpt(Token token, MemberKind kind) {
    Token next = token.next!;
    if (optional('(', next)) {
      token = parseFormalParameters(token, kind);
    } else {
      listener.handleNoFormalParameters(next, kind);
    }
    return token;
  }

  Token skipFormalParameters(Token token, MemberKind kind) {
    return skipFormalParametersRest(token.next!, kind);
  }

  Token skipFormalParametersRest(Token token, MemberKind kind) {
    assert(optional('(', token));
    // TODO(ahe): Shouldn't this be `beginFormalParameters`?
    listener.beginOptionalFormalParameters(token);
    Token closeBrace = token.endGroup!;
    assert(optional(')', closeBrace));
    listener.endFormalParameters(/* count = */ 0, token, closeBrace, kind);
    return closeBrace;
  }

  /// Parse a record type similarly as a formal parameter list of a function.
  ///
  /// recordType          ::= '(' recordTypeFields ',' recordTypeNamedFields ')'
  ///                       | '(' recordTypeFields ','? ')'
  ///                       | '(' recordTypeNamedFields? ')'
  ///
  /// recordTypeFields      ::= recordTypeField ( ',' recordTypeField )*
  /// recordTypeField       ::= metadata type identifier?
  ///
  /// recordTypeNamedFields ::= '{' recordTypeNamedField
  ///                           ( ',' recordTypeNamedField )* ','? '}'
  /// recordTypeNamedField  ::= metadata type identifier
  Token parseRecordType(
      final Token start, Token token, bool isQuestionMarkPartOfType) {
    token = token.next!;
    assert(optional('(', token));

    listener.beginRecordType(start);

    Token begin = token;

    /// parameterCount counting the presence of named fields as 1.
    int parameterCount = 0;
    bool hasNamedFields = false;
    bool sawComma = false;
    Token? illegalTrailingComma;
    while (true) {
      Token next = token.next!;
      if (optional(')', next)) {
        token = next;
        break;
      } else if (parameterCount == 0 &&
          optional(',', next) &&
          optional(')', next.next!)) {
        illegalTrailingComma = next;
        token = next.next!;
        break;
      }
      ++parameterCount;
      String? value = next.stringValue;
      if (identical(value, '{')) {
        hasNamedFields = true;
        token = parseRecordTypeNamedFields(token);
        token = ensureCloseParen(token, begin);
        break;
      }
      token = parseRecordTypeField(token, identifierIsOptional: true);
      next = token.next!;
      if (!optional(',', next)) {
        Token next = token.next!;
        if (optional(')', next)) {
          token = next;
        } else {
          // Recovery.
          // TODO: This is copied from parseFormalParametersRest.
          // We could possibly either have more specific recovery here
          // or have the recovery in a shared method.
          if (begin.endGroup!.isSynthetic) {
            // Scanner has already reported a missing `)` error,
            // but placed the `)` in the wrong location, so move it.
            token = rewriter.moveSynthetic(token, begin.endGroup!);
          } else if (next.kind == IDENTIFIER_TOKEN &&
              next.next!.kind == IDENTIFIER_TOKEN) {
            // Looks like a missing comma
            token = rewriteAndRecover(
                token,
                codes.templateExpectedButGot.withArguments(','),
                new SyntheticToken(TokenType.COMMA, next.charOffset));
            continue;
          } else {
            token = ensureCloseParen(token, begin);
          }
        }
        break;
      } else {
        sawComma = true;
      }
      token = next;
    }
    assert(optional(')', token));

    if (parameterCount == 0 && illegalTrailingComma != null) {
      // Empty record type with a comma `(,)`.
      reportRecoverableError(illegalTrailingComma,
          codes.messageRecordTypeZeroFieldsButTrailingComma);
    } else if (parameterCount == 1 && !hasNamedFields && !sawComma) {
      // Single non-named element without trailing comma.
      reportRecoverableError(
          token, codes.messageRecordTypeOnePositionalFieldNoTrailingComma);
    }

    // Only consume the `?` if it is part of the type.
    Token? questionMark = token.next!;
    if (optional('?', questionMark) && isQuestionMarkPartOfType) {
      token = questionMark;
    } else {
      questionMark = null;
    }
    listener.endRecordType(start, questionMark, parameterCount,
        /* hasNamedFields = */ hasNamedFields);

    return token;
  }

  Token parseRecordTypeField(Token token,
      {required bool identifierIsOptional}) {
    listener.beginRecordTypeEntry();
    token = parseMetadataStar(token);
    token = computeType(
      token,
      /* required = */ true,
    ).ensureTypeOrVoid(token, this);
    if (token.next!.isIdentifier || !identifierIsOptional) {
      token = ensureIdentifier(token, IdentifierContext.recordFieldDeclaration);
    } else {
      listener.handleNoName(token.next!);
    }
    listener.endRecordTypeEntry();
    return token;
  }

  Token parseRecordTypeNamedFields(Token token) {
    Token begin = token = token.next!;
    assert(optional('{', token));
    listener.beginRecordTypeNamedFields(begin);
    int parameterCount = 0;
    Token next;
    while (true) {
      next = token.next!;
      if (optional('}', next)) {
        // breaking with next pointing to '}'.
        break;
      }
      token = parseRecordTypeField(token, identifierIsOptional: false);
      next = token.next!;
      ++parameterCount;
      if (!optional(',', next)) {
        if (!optional('}', next)) {
          // Recovery
          reportRecoverableError(
              next, codes.templateExpectedButGot.withArguments('}'));
          // Scanner guarantees a closing bracket.
          next = begin.endGroup!;
        }
        // breaking with next pointing to '}'.
        break;
      }
      token = next;
    }
    token = next;
    assert(optional('}', token));
    if (parameterCount == 0) {
      reportRecoverableError(
          token, codes.messageEmptyRecordTypeNamedFieldsList);
    }
    listener.endRecordTypeNamedFields(parameterCount, begin);
    return token;
  }

  /// Parses the formal parameter list of a function.
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParametersRequiredOpt(Token token, MemberKind kind) {
    Token next = token.next!;
    if (!optional('(', next)) {
      reportRecoverableError(next, missingParameterMessage(kind));
      next = rewriter.insertParens(token, /* includeIdentifier = */ false);
    }
    return parseFormalParametersRest(next, kind);
  }

  /// Parses the formal parameter list of a function given that the left
  /// parenthesis is known to exist.
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParameters(Token token, MemberKind kind) {
    return parseFormalParametersRest(token.next!, kind);
  }

  /// Parses the formal parameter list of a function given that the left
  /// parenthesis passed in as [token].
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParametersRest(Token token, MemberKind kind) {
    Token begin = token;
    assert(optional('(', token));
    listener.beginFormalParameters(begin, kind);
    int parameterCount = 0;
    while (true) {
      Token next = token.next!;
      if (optional(')', next)) {
        token = next;
        break;
      }
      ++parameterCount;
      String? value = next.stringValue;
      if (identical(value, '[')) {
        token = parseOptionalPositionalParameters(token, kind);
        token = ensureCloseParen(token, begin);
        break;
      } else if (identical(value, '{')) {
        token = parseOptionalNamedParameters(token, kind);
        token = ensureCloseParen(token, begin);
        break;
      } else if (identical(value, '[]')) {
        // Recovery
        token = rewriteSquareBrackets(token);
        token = parseOptionalPositionalParameters(token, kind);
        token = ensureCloseParen(token, begin);
        break;
      }
      token = parseFormalParameter(
          token, FormalParameterKind.requiredPositional, kind);
      next = token.next!;
      if (!optional(',', next)) {
        Token next = token.next!;
        if (optional(')', next)) {
          token = next;
        } else {
          // Recovery
          if (begin.endGroup!.isSynthetic) {
            // Scanner has already reported a missing `)` error,
            // but placed the `)` in the wrong location, so move it.
            token = rewriter.moveSynthetic(token, begin.endGroup!);
          } else if (next.kind == IDENTIFIER_TOKEN &&
              next.next!.kind == IDENTIFIER_TOKEN) {
            // Looks like a missing comma
            token = rewriteAndRecover(
                token,
                codes.templateExpectedButGot.withArguments(','),
                new SyntheticToken(TokenType.COMMA, next.charOffset));
            continue;
          } else {
            token = ensureCloseParen(token, begin);
          }
        }
        break;
      }
      token = next;
    }
    assert(optional(')', token));
    listener.endFormalParameters(parameterCount, begin, token, kind);
    return token;
  }

  /// Return the message that should be produced when the formal parameters are
  /// missing.
  codes.Message missingParameterMessage(MemberKind kind) {
    if (kind == MemberKind.FunctionTypeAlias) {
      return codes.messageMissingTypedefParameters;
    } else if (kind == MemberKind.NonStaticMethod ||
        kind == MemberKind.StaticMethod) {
      return codes.messageMissingMethodParameters;
    }
    return codes.messageMissingFunctionParameters;
  }

  /// Check if [token] is the usage of 'required' in a formal parameter in a
  /// context where it's not legal (i.e. in non-nnbd-mode).
  bool _isUseOfRequiredInNonNNBD(Token token) {
    if (token.next is StringToken && token.next!.value() == "required") {
      // Possible recovery: Figure out if we're in a situation like
      // required covariant? <type> name
      // (in non-nnbd-mode) where the required modifier is not legal and thus
      // would normally be parsed as the type.
      token = token.next!;
      Token next = token.next!;
      // Skip modifiers.
      while (next.isModifier) {
        token = next;
        next = next.next!;
      }
      // Parse the (potential) new type.
      TypeInfo typeInfoAlternative = computeType(
        token,
        /* required = */ false,
        /* inDeclaration = */ true,
      );
      token = typeInfoAlternative.skipType(token);
      next = token.next!;

      // We've essentially ignored the 'required' at this point.
      // `token` is (in the good state) the last token of the type,
      // `next` is (in the good state) the name;
      // Are we in a 'good' state?
      if (typeInfoAlternative != noType &&
          next.isIdentifier &&
          (optional(',', next.next!) || optional('}', next.next!))) {
        return true;
      }
    }
    return false;
  }

  /// ```
  /// normalFormalParameter:
  ///   functionFormalParameter |
  ///   fieldFormalParameter |
  ///   simpleFormalParameter
  /// ;
  ///
  /// functionFormalParameter:
  ///   metadata 'covariant'? returnType? identifier formalParameterList
  /// ;
  ///
  /// simpleFormalParameter:
  ///   metadata 'covariant'? finalConstVarOrType? identifier |
  /// ;
  ///
  /// fieldFormalParameter:
  ///   metadata finalConstVarOrType? 'this' '.' identifier formalParameterList?
  /// ;
  /// ```
  Token parseFormalParameter(
      Token token, FormalParameterKind parameterKind, MemberKind memberKind) {
    // ignore: unnecessary_null_comparison
    assert(parameterKind != null);
    token = parseMetadataStar(token);

    Token? skippedNonRequiredRequired;
    if (_isUseOfRequiredInNonNNBD(token)) {
      skippedNonRequiredRequired = token.next!;
      reportRecoverableErrorWithToken(skippedNonRequiredRequired,
          codes.templateUnexpectedModifierInNonNnbd);
      token = token.next!;
    }

    Token next = token.next!;
    Token start = next;

    final bool inFunctionType =
        memberKind == MemberKind.GeneralizedFunctionType;

    Token? requiredToken;
    Token? covariantToken;
    Token? varFinalOrConst;
    if (isModifier(next)) {
      if (optional('required', next)) {
        if (parameterKind == FormalParameterKind.optionalNamed) {
          parameterKind = FormalParameterKind.requiredNamed;
          requiredToken = token = next;
          next = token.next!;
        }
      }

      if (isModifier(next)) {
        if (optional('covariant', next)) {
          if (memberKind != MemberKind.StaticMethod &&
              memberKind != MemberKind.TopLevelMethod &&
              memberKind != MemberKind.ExtensionNonStaticMethod &&
              memberKind != MemberKind.ExtensionStaticMethod) {
            covariantToken = token = next;
            next = token.next!;
          }
        }

        if (isModifier(next)) {
          if (!inFunctionType) {
            if (optional('var', next)) {
              varFinalOrConst = token = next;
              next = token.next!;
            } else if (optional('final', next)) {
              varFinalOrConst = token = next;
              next = token.next!;
            }
          }

          if (isModifier(next)) {
            // Recovery
            ModifierContext context = new ModifierContext(this)
              ..covariantToken = covariantToken
              ..requiredToken = requiredToken
              ..varFinalOrConst = varFinalOrConst;

            token = context.parseFormalParameterModifiers(
                token, parameterKind, memberKind);
            next = token.next!;

            covariantToken = context.covariantToken;
            requiredToken = context.requiredToken;
            varFinalOrConst = context.varFinalOrConst;
          }
        }
      }
    }

    if (requiredToken == null) {
      // `required` was used as a modifier in non-nnbd mode. An error has been
      // emitted. Still use it as a required token for the remainder in an
      // attempt to avoid cascading errors (and for passing to the listener).
      requiredToken = skippedNonRequiredRequired;
    }

    listener.beginFormalParameter(
        start, memberKind, requiredToken, covariantToken, varFinalOrConst);

    // Type is required in a generalized function type, but optional otherwise.
    final Token beforeType = token;
    TypeInfo typeInfo = computeType(
      token,
      inFunctionType,
      /* inDeclaration = */ false,
      /* acceptKeywordForSimpleType = */ true,
    );
    token = typeInfo.skipType(token);
    next = token.next!;
    if (typeInfo == noType &&
        (optional('.', next) ||
            (next.isIdentifier && optional('.', next.next!)))) {
      // Recovery: Malformed type reference.
      typeInfo = computeType(beforeType, /* required = */ true);
      token = typeInfo.skipType(beforeType);
      next = token.next!;
    }

    Token? thisKeyword;
    Token? superKeyword;
    Token? periodAfterThisOrSuper;
    IdentifierContext nameContext =
        IdentifierContext.formalParameterDeclaration;

    if (!inFunctionType &&
        (optional('this', next) || optional('super', next))) {
      Token originalToken = token;
      if (optional('this', next)) {
        thisKeyword = token = next;
      } else {
        superKeyword = token = next;
      }
      next = token.next!;
      if (!optional('.', next)) {
        if (isOneOf(next, okNextValueInFormalParameter)) {
          // Recover by not parsing as 'this' --- an error will be given
          // later that it's not an allowed identifier.
          token = originalToken;
          next = token.next!;
          thisKeyword = superKeyword = null;
        } else {
          // Recover from a missing period by inserting one.
          next = rewriteAndRecover(
              token,
              codes.templateExpectedButGot.withArguments('.'),
              new SyntheticToken(TokenType.PERIOD, next.charOffset));
          // These 3 lines are duplicated here and below.
          periodAfterThisOrSuper = token = next;
          next = token.next!;
          nameContext = IdentifierContext.fieldInitializer;
        }
      } else {
        // These 3 lines are duplicated here and above.
        periodAfterThisOrSuper = token = next;
        next = token.next!;
        nameContext = IdentifierContext.fieldInitializer;
      }
    }

    if (next.isIdentifier) {
      token = next;
      next = token.next!;
    }
    Token? beforeInlineFunctionType;
    TypeParamOrArgInfo typeParam = noTypeParamOrArg;
    if (optional("<", next)) {
      typeParam = computeTypeParamOrArg(token);
      if (typeParam != noTypeParamOrArg) {
        Token closer = typeParam.skip(token);
        if (optional("(", closer.next!)) {
          if (varFinalOrConst != null) {
            reportRecoverableError(
                varFinalOrConst, codes.messageFunctionTypedParameterVar);
          }
          beforeInlineFunctionType = token;
          token = closer.next!.endGroup!;
          next = token.next!;
        }
      }
    } else if (optional("(", next)) {
      if (varFinalOrConst != null) {
        reportRecoverableError(
            varFinalOrConst, codes.messageFunctionTypedParameterVar);
      }
      beforeInlineFunctionType = token;
      token = next.endGroup!;
      next = token.next!;
    }
    if (typeInfo != noType &&
        varFinalOrConst != null &&
        optional('var', varFinalOrConst)) {
      reportRecoverableError(varFinalOrConst, codes.messageTypeAfterVar);
    }

    Token? endInlineFunctionType;
    if (beforeInlineFunctionType != null) {
      endInlineFunctionType =
          typeParam.parseVariables(beforeInlineFunctionType, this);
      listener
          .beginFunctionTypedFormalParameter(beforeInlineFunctionType.next!);
      token = typeInfo.parseType(beforeType, this);
      endInlineFunctionType = parseFormalParametersRequiredOpt(
          endInlineFunctionType, MemberKind.FunctionTypedParameter);
      Token? question;
      if (optional('?', endInlineFunctionType.next!)) {
        question = endInlineFunctionType = endInlineFunctionType.next!;
      }
      listener.endFunctionTypedFormalParameter(
          beforeInlineFunctionType, question);

      // Generalized function types don't allow inline function types.
      // The following isn't allowed:
      //    int Function(int bar(String x)).
      if (inFunctionType) {
        reportRecoverableError(beforeInlineFunctionType.next!,
            codes.messageInvalidInlineFunctionType);
      }
    } else if (inFunctionType) {
      token = typeInfo.ensureTypeOrVoid(beforeType, this);
    } else {
      token = typeInfo.parseType(beforeType, this);
    }

    Token nameToken;
    if (periodAfterThisOrSuper != null) {
      token = periodAfterThisOrSuper;
    }
    final bool isNamedParameter = parameterKind.isNamed;
    next = token.next!;
    if (inFunctionType &&
        !isNamedParameter &&
        !next.isKeywordOrIdentifier &&
        beforeInlineFunctionType == null) {
      nameToken = token.next!;
      listener.handleNoName(nameToken);
    } else {
      nameToken = token = ensureIdentifier(token, nameContext);
      if (isNamedParameter && nameToken.lexeme.startsWith("_")) {
        reportRecoverableError(nameToken, codes.messagePrivateNamedParameter);
      }
    }
    if (endInlineFunctionType != null) {
      token = endInlineFunctionType;
    }
    next = token.next!;

    String? value = next.stringValue;
    Token? initializerStart, initializerEnd;
    if ((identical('=', value)) || (identical(':', value))) {
      Token equal = next;
      initializerStart = equal.next!;
      listener.beginFormalParameterDefaultValueExpression();
      token = initializerEnd = parseExpression(equal);
      next = token.next!;
      listener.endFormalParameterDefaultValueExpression();
      // TODO(danrubel): Consider removing the last parameter from the
      // handleValuedFormalParameter event... it appears to be unused.
      listener.handleValuedFormalParameter(equal, next);
      if (parameterKind.isRequiredPositional) {
        reportRecoverableError(
            equal, codes.messageRequiredParameterWithDefault);
      } else if (parameterKind.isOptionalPositional && identical(':', value)) {
        reportRecoverableError(
            equal, codes.messagePositionalParameterWithEquals);
      } else if (inFunctionType ||
          memberKind == MemberKind.FunctionTypeAlias ||
          memberKind == MemberKind.FunctionTypedParameter) {
        reportRecoverableError(equal, codes.messageFunctionTypeDefaultValue);
      }
    } else {
      listener.handleFormalParameterWithoutValue(next);
    }
    listener.endFormalParameter(
        thisKeyword,
        superKeyword,
        periodAfterThisOrSuper,
        nameToken,
        initializerStart,
        initializerEnd,
        parameterKind,
        memberKind);
    return token;
  }

  /// ```
  /// defaultFormalParameter:
  ///   normalFormalParameter ('=' expression)?
  /// ;
  /// ```
  Token parseOptionalPositionalParameters(Token token, MemberKind kind) {
    Token begin = token = token.next!;
    assert(optional('[', token));
    listener.beginOptionalFormalParameters(begin);
    int parameterCount = 0;
    while (true) {
      Token next = token.next!;
      if (optional(']', next)) {
        break;
      }
      token = parseFormalParameter(
          token, FormalParameterKind.optionalPositional, kind);
      next = token.next!;
      ++parameterCount;
      if (!optional(',', next)) {
        if (!optional(']', next)) {
          // Recovery
          reportRecoverableError(
              next, codes.templateExpectedButGot.withArguments(']'));
          // Scanner guarantees a closing bracket.
          next = begin.endGroup!;
          while (token.next != next) {
            token = token.next!;
          }
        }
        break;
      }
      token = next;
    }
    if (parameterCount == 0) {
      rewriteAndRecover(
          token,
          codes.messageEmptyOptionalParameterList,
          new SyntheticStringToken(TokenType.IDENTIFIER, '',
              token.next!.charOffset, /* _length = */ 0));
      token = parseFormalParameter(
          token, FormalParameterKind.optionalPositional, kind);
      ++parameterCount;
    }
    token = token.next!;
    assert(optional(']', token));
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    return token;
  }

  /// ```
  /// defaultNamedParameter:
  ///   normalFormalParameter ('=' expression)? |
  ///   normalFormalParameter (':' expression)?
  /// ;
  /// ```
  Token parseOptionalNamedParameters(Token token, MemberKind kind) {
    Token begin = token = token.next!;
    assert(optional('{', token));
    listener.beginOptionalFormalParameters(begin);
    int parameterCount = 0;
    while (true) {
      Token next = token.next!;
      if (optional('}', next)) {
        break;
      }
      token =
          parseFormalParameter(token, FormalParameterKind.optionalNamed, kind);
      next = token.next!;
      ++parameterCount;
      if (!optional(',', next)) {
        if (!optional('}', next)) {
          // Recovery
          reportRecoverableError(
              next, codes.templateExpectedButGot.withArguments('}'));
          // Scanner guarantees a closing bracket.
          next = begin.endGroup!;
          while (token.next != next) {
            token = token.next!;
          }
        }
        break;
      }
      token = next;
    }
    if (parameterCount == 0) {
      rewriteAndRecover(
          token,
          codes.messageEmptyNamedParameterList,
          new SyntheticStringToken(TokenType.IDENTIFIER, '',
              token.next!.charOffset, /* _length = */ 0));
      token =
          parseFormalParameter(token, FormalParameterKind.optionalNamed, kind);
      ++parameterCount;
    }
    token = token.next!;
    assert(optional('}', token));
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    return token;
  }

  /// ```
  /// qualified:
  ///   identifier qualifiedRest*
  /// ;
  /// ```
  Token parseQualified(Token token, IdentifierContext context,
      IdentifierContext continuationContext) {
    token = ensureIdentifier(token, context);
    while (optional('.', token.next!)) {
      token = parseQualifiedRest(token, continuationContext);
    }
    return token;
  }

  /// ```
  /// qualifiedRestOpt:
  ///   qualifiedRest?
  /// ;
  /// ```
  Token parseQualifiedRestOpt(
      Token token, IdentifierContext continuationContext) {
    if (optional('.', token.next!)) {
      return parseQualifiedRest(token, continuationContext);
    } else {
      return token;
    }
  }

  /// ```
  /// qualifiedRest:
  ///   '.' identifier
  /// ;
  /// ```
  Token parseQualifiedRest(Token token, IdentifierContext context) {
    token = token.next!;
    assert(optional('.', token));
    _tryRewriteNewToIdentifier(token, context);
    Token period = token;
    token = ensureIdentifier(token, context);
    listener.handleQualified(period);
    return token;
  }

  Token skipBlock(Token token) {
    // The scanner ensures that `{` always has a closing `}`.
    return ensureBlock(
            token, /* template = */ null, /* missingBlockName = */ null)
        .endGroup!;
  }

  /// ```
  /// enumType:
  ///   metadata 'enum' id typeParameters? mixins? interfaces? '{'
  ///      enumEntry (',' enumEntry)* (',')? (';'
  ///      (metadata classMemberDefinition)*
  ///      )?
  ///   '}'
  ///
  /// enumEntry:
  ///     metadata id argumentPart?
  ///   | metadata id typeArguments? '.' id arguments
  /// ```
  Token parseEnum(Token enumKeyword) {
    assert(optional('enum', enumKeyword));
    listener.beginUncategorizedTopLevelDeclaration(enumKeyword);
    Token token =
        ensureIdentifier(enumKeyword, IdentifierContext.enumDeclaration);
    String name = token.lexeme;
    listener.beginEnum(enumKeyword);
    token = parseEnumHeaderOpt(token, enumKeyword);
    Token leftBrace = token.next!;
    int elementCount = 0;
    int memberCount = 0;
    if (optional('{', leftBrace)) {
      listener.handleEnumHeader(enumKeyword, leftBrace);
      token = leftBrace;
      while (true) {
        Token next = token.next!;
        if (optional('}', next) || optional(';', next)) {
          token = next;
          if (elementCount == 0) {
            reportRecoverableError(token, codes.messageEnumDeclarationEmpty);
          }
          break;
        }
        token = parseEnumElement(token);
        next = token.next!;
        elementCount++;
        if (optional(',', next)) {
          token = next;
        } else if (optional('}', next) || optional(';', next)) {
          token = next;
          break;
        } else {
          // Recovery
          Token endGroup = leftBrace.endGroup!;
          if (endGroup.isSynthetic) {
            // The scanner did not place the synthetic '}' correctly.
            token = rewriter.moveSynthetic(token, endGroup);
            break;
          } else if (next.isIdentifier) {
            // If the next token is an identifier, assume a missing comma.
            // TODO(danrubel): Consider improved recovery for missing `}`
            // both here and when the scanner inserts a synthetic `}`
            // for situations such as `enum Letter {a, b   Letter e;`.
            reportRecoverableError(
                next, codes.templateExpectedButGot.withArguments(','));
          } else {
            // Otherwise assume a missing `}` and exit the loop
            reportRecoverableError(
                next, codes.templateExpectedButGot.withArguments('}'));
            token = leftBrace.endGroup!;
            break;
          }
        }
      }
      listener.handleEnumElements(token, elementCount);
      if (optional(';', token)) {
        while (notEofOrValue('}', token.next!)) {
          token = parseClassOrMixinOrExtensionOrEnumMemberImpl(
              token, DeclarationKind.Enum, name);
          ++memberCount;
        }
        token = token.next!;
        assert(token.isEof || optional('}', token));
      }
    } else {
      // TODO(danrubel): merge this error message with missing class/mixin body
      leftBrace = ensureBlock(
          token, codes.templateExpectedEnumBody, /* missingBlockName = */ null);
      listener.handleEnumHeader(enumKeyword, leftBrace);
      listener.handleEnumElements(token, elementCount);
      token = leftBrace.endGroup!;
    }
    assert(optional('}', token));
    listener.endEnum(enumKeyword, leftBrace, memberCount);
    return token;
  }

  Token parseEnumHeaderOpt(Token token, Token enumKeyword) {
    token = computeTypeParamOrArg(
            token, /* inDeclaration = */ true, /* allowsVariance = */ true)
        .parseVariables(token, this);
    List<String> lookForNext = const ['{', 'with', 'implements'];
    if (!isOneOf(token.next!, lookForNext)) {
      // Recovery: Possible unexpected tokens before any clauses.
      Token? skipToken = recoverySmallLookAheadSkipTokens(token, lookForNext);
      if (skipToken != null) {
        token = skipToken;
      }
    }

    Token beforeWith = token;
    token = parseEnumWithClauseOpt(token);

    while (!isOneOf(token.next!, const ['{', 'implements'])) {
      // Recovery: Skip unexpected tokens and more with clauses.
      // Note that if we find a "with" we've seen one already (otherwise the
      // parseEnumWithClauseOpt call above would have found this 'with').
      Token? skipToken = recoveryEnumWith(token,
              codes.templateMultipleClauses.withArguments("enum", "with")) ??
          recoverySmallLookAheadSkipTokens(token, lookForNext);

      if (skipToken != null) {
        // Skipped tokens.
        token = skipToken;
      } else {
        break;
      }
    }

    token = parseClassOrMixinOrEnumImplementsOpt(token);

    bool? hasWithClauses;
    while (!optional('{', token.next!)) {
      if (hasWithClauses == null) {
        hasWithClauses = optional('with', beforeWith.next!);
      }

      // Recovery: Skip unexpected tokens and more with/implements clauses.
      Token? skipToken = recoveryEnumWith(
          token,
          hasWithClauses
              ? codes.templateMultipleClauses.withArguments("enum", "with")
              : codes.templateOutOfOrderClauses
                  .withArguments("with", "implements"));
      if (skipToken != null) {
        hasWithClauses = true;
      }
      if (skipToken == null) {
        // Note that if we find a "implements" we've seen one already (otherwise
        // the parseClassOrMixinOrEnumImplementsOpt call above would have found
        // this 'implements').
        skipToken = recoveryEnumImplements(token,
            codes.templateMultipleClauses.withArguments("enum", "implements"));
      }
      if (skipToken == null) {
        skipToken = recoverySmallLookAheadSkipTokens(token, lookForNext);
      }

      if (skipToken != null) {
        // Skipped tokens.
        token = skipToken;
      } else {
        break;
      }
    }

    return token;
  }

  Token? recoveryEnumWith(Token token, codes.Message message) {
    if (optional('with', token.next!)) {
      reportRecoverableError(token.next!, message);
      Listener originalListener = listener;
      listener = new NullListener();
      token = parseEnumWithClauseOpt(token);
      listener = originalListener;
      return token;
    }
    return null;
  }

  Token? recoveryEnumImplements(Token token, codes.Message message) {
    if (optional('implements', token.next!)) {
      reportRecoverableError(token.next!, message);
      Listener originalListener = listener;
      listener = new NullListener();
      token = parseClassOrMixinOrEnumImplementsOpt(token);
      listener = originalListener;
      return token;
    }
    return null;
  }

  /// Allow a small lookahead (currently up to 3 tokens) trying to find any in
  /// [lookFor].
  ///
  /// If any wanted token is found an error is issued about unexpected tokens,
  /// and the last skipped token is returned.
  /// Otherwise null is returned.
  Token? recoverySmallLookAheadSkipTokens(
      final Token token, Iterable<String> lookFor) {
    // Recovery: Allow a small lookahead for '{'. E.g. the user might be in
    // the middle of writing 'with' or 'implements'.
    Token skipToken = token.next!;
    bool foundWanted = false;

    if (looksLikeStartOfNextTopLevelDeclaration(skipToken)) return null;

    int skipped = 0;
    while (skipped < 3) {
      skipped++;
      if (isOneOf(skipToken.next!, lookFor)) {
        foundWanted = true;
        break;
      }

      skipToken = skipToken.next!;
      if (looksLikeStartOfNextTopLevelDeclaration(skipToken)) return null;
    }

    if (foundWanted) {
      // Give error and skip the tokens.
      if (skipped == 1) {
        reportRecoverableError(
            skipToken, codes.templateUnexpectedToken.withArguments(skipToken));
      } else {
        reportRecoverableErrorWithEnd(
            token.next!, skipToken, codes.messageUnexpectedTokens);
      }
      return skipToken;
    }

    return null;
  }

  Token parseEnumElement(Token token) {
    Token beginToken = token;
    token = parseMetadataStar(token);
    token = ensureIdentifier(token, IdentifierContext.enumValueDeclaration);
    bool hasTypeArgumentsOrDot = false;
    {
      // This is almost a verbatim copy of [parseConstructorReference] inserted
      // to provide better recovery.
      Token start = token;
      listener.handleNoTypeNameInConstructorReference(token.next!);
      listener.beginConstructorReference(start);
      TypeParamOrArgInfo typeArg = computeTypeParamOrArg(token);
      if (typeArg != noTypeParamOrArg) {
        hasTypeArgumentsOrDot = true;
      }
      token = typeArg.parseArguments(token, this);
      Token? period = null;
      if (optional('.', token.next!)) {
        hasTypeArgumentsOrDot = true;
        period = token.next!;
        token = ensureIdentifier(
            period,
            IdentifierContext
                .constructorReferenceContinuationAfterTypeArguments);
      } else {
        listener.handleNoConstructorReferenceContinuationAfterTypeArguments(
            token.next!);
      }
      listener.endConstructorReference(
          start, period, token.next!, ConstructorReferenceContext.Const);
    }
    Token next = token.next!;
    if (optional('(', next) || hasTypeArgumentsOrDot) {
      token = parseConstructorInvocationArguments(token);
    } else {
      listener.handleNoArguments(token);
    }
    listener.handleEnumElement(beginToken);
    return token;
  }

  Token parseClassOrNamedMixinApplication(
      Token? abstractToken,
      Token? macroToken,
      Token? inlineToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? finalToken,
      Token? augmentToken,
      Token? mixinToken,
      Token classKeyword) {
    assert(optional('class', classKeyword));
    Token begin = abstractToken ?? classKeyword;
    listener.beginClassOrMixinOrNamedMixinApplicationPrelude(begin);
    Token name = ensureIdentifier(
        classKeyword, IdentifierContext.classOrMixinOrExtensionDeclaration);
    Token token = computeTypeParamOrArg(
            name, /* inDeclaration = */ true, /* allowsVariance = */ true)
        .parseVariables(name, this);
    if (abstractToken != null && sealedToken != null) {
      reportRecoverableError(sealedToken, codes.messageAbstractSealedClass);
    }
    if (optional('=', token.next!)) {
      listener.beginNamedMixinApplication(
          begin,
          abstractToken,
          macroToken,
          inlineToken,
          sealedToken,
          baseToken,
          interfaceToken,
          finalToken,
          augmentToken,
          mixinToken,
          name);
      return parseNamedMixinApplication(token, begin, classKeyword);
    } else {
      listener.beginClassDeclaration(
          begin,
          abstractToken,
          macroToken,
          inlineToken,
          sealedToken,
          baseToken,
          interfaceToken,
          finalToken,
          augmentToken,
          mixinToken,
          name);
      return parseClass(token, begin, classKeyword, name.lexeme);
    }
  }

  Token parseNamedMixinApplication(
      Token token, Token begin, Token classKeyword) {
    Token equals = token = token.next!;
    assert(optional('=', equals));
    token = computeType(token, /* required = */ true)
        .ensureTypeNotVoid(token, this);
    token = parseMixinApplicationRest(token);
    Token? implementsKeyword = null;
    if (optional('implements', token.next!)) {
      implementsKeyword = token.next!;
      token = parseTypeList(implementsKeyword);
    }
    token = ensureSemicolon(token);
    listener.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, token);
    return token;
  }

  /// Parse the portion of a class declaration (not a mixin application) that
  /// follows the end of the type parameters.
  ///
  /// ```
  /// classDefinition:
  ///   metadata abstract? 'class' identifier typeParameters?
  ///       (superclass mixins?)? interfaces?
  ///       '{' (metadata classMemberDefinition)* '}' |
  ///   metadata abstract? 'class' mixinApplicationClass
  /// ;
  /// ```
  Token parseClass(
      Token token, Token begin, Token classKeyword, String className) {
    Token start = token;
    token = parseClassHeaderOpt(token, begin, classKeyword);
    if (!optional('{', token.next!)) {
      // Recovery
      token = parseClassHeaderRecovery(start, begin, classKeyword);
      ensureBlock(token, /* template = */ null, 'class declaration');
    }
    token = parseClassOrMixinOrExtensionBody(
        token, DeclarationKind.Class, className);
    listener.endClassDeclaration(begin, token);
    return token;
  }

  Token parseClassHeaderOpt(Token token, Token begin, Token classKeyword) {
    token = parseClassExtendsOpt(token);
    token = parseClassWithClauseOpt(token);
    token = parseClassOrMixinOrEnumImplementsOpt(token);
    Token? nativeToken;
    if (optional('native', token.next!)) {
      nativeToken = token.next!;
      token = parseNativeClause(token);
    }
    listener.handleClassHeader(begin, classKeyword, nativeToken);
    return token;
  }

  /// Recover given out-of-order clauses in a class header.
  Token parseClassHeaderRecovery(Token token, Token begin, Token classKeyword) {
    final Listener primaryListener = listener;
    final ClassHeaderRecoveryListener recoveryListener =
        new ClassHeaderRecoveryListener();

    // Reparse to determine which clauses have already been parsed
    // but intercept the events so they are not sent to the primary listener.
    listener = recoveryListener;
    token = parseClassHeaderOpt(token, begin, classKeyword);
    bool hasExtends = recoveryListener.extendsKeyword != null;
    bool hasImplements = recoveryListener.implementsKeyword != null;
    bool hasWith = recoveryListener.withKeyword != null;

    // Update the recovery listener to forward subsequent events
    // to the primary listener.
    recoveryListener.listener = primaryListener;

    // Parse additional out-of-order clauses
    Token start;
    do {
      start = token;

      // Check for extraneous token in the middle of a class header.
      token = skipUnexpectedTokenOpt(
          token, const <String>['extends', 'with', 'implements', '{']);

      // During recovery, clauses are parsed in the same order
      // and generate the same events as in the parseClassHeader method above.
      recoveryListener.clear();

      if (token.next!.isKeywordOrIdentifier &&
          const ['extend', 'on'].contains(token.next!.lexeme)) {
        reportRecoverableError(token.next!,
            codes.templateExpectedInstead.withArguments('extends'));
        token = parseClassExtendsSeenExtendsClause(token.next!, token);
      } else {
        token = parseClassExtendsOpt(token);
      }

      if (recoveryListener.extendsKeyword != null) {
        if (hasExtends) {
          reportRecoverableError(
              recoveryListener.extendsKeyword!, codes.messageMultipleExtends);
        } else {
          if (hasWith) {
            reportRecoverableError(recoveryListener.extendsKeyword!,
                codes.messageWithBeforeExtends);
          } else if (hasImplements) {
            reportRecoverableError(recoveryListener.extendsKeyword!,
                codes.messageImplementsBeforeExtends);
          }
          hasExtends = true;
        }
      }

      token = parseClassWithClauseOpt(token);

      if (recoveryListener.withKeyword != null) {
        if (hasWith) {
          reportRecoverableError(
              recoveryListener.withKeyword!, codes.messageMultipleWith);
        } else {
          if (hasImplements) {
            reportRecoverableError(recoveryListener.withKeyword!,
                codes.messageImplementsBeforeWith);
          }
          hasWith = true;
        }
      }

      token = parseClassOrMixinOrEnumImplementsOpt(token);

      if (recoveryListener.implementsKeyword != null) {
        if (hasImplements) {
          reportRecoverableError(recoveryListener.implementsKeyword!,
              codes.messageMultipleImplements);
        } else {
          hasImplements = true;
        }
      }

      listener.handleRecoverClassHeader();

      // Exit if a class body is detected, or if no progress has been made
    } while (!optional('{', token.next!) && start != token);

    listener = primaryListener;
    return token;
  }

  Token parseClassExtendsOpt(Token token) {
    // extends <typeNotVoid>
    Token next = token.next!;
    if (optional('extends', next)) {
      token = parseClassExtendsSeenExtendsClause(next, token);
    } else {
      listener.handleNoType(token);
      listener.handleClassExtends(
        /* extendsKeyword = */ null,
        /* typeCount = */ 1,
      );
    }
    return token;
  }

  Token parseClassExtendsSeenExtendsClause(Token extendsKeyword, Token token) {
    Token next = extendsKeyword;
    token =
        computeType(next, /* required = */ true).ensureTypeNotVoid(next, this);
    int count = 1;

    // Error recovery: extends <typeNotVoid>, <typeNotVoid> [...]
    if (optional(',', token.next!)) {
      reportRecoverableError(token.next!, codes.messageMultipleExtends);

      while (optional(',', token.next!)) {
        next = token.next!;
        token = computeType(next, /* required = */ true)
            .ensureTypeNotVoid(next, this);
        count++;
      }
    }

    listener.handleClassExtends(extendsKeyword, count);
    return token;
  }

  /// ```
  /// implementsClause:
  ///   'implements' typeName (',' typeName)*
  /// ;
  /// ```
  Token parseClassOrMixinOrEnumImplementsOpt(Token token) {
    Token? implementsKeyword;
    int interfacesCount = 0;
    if (optional('implements', token.next!)) {
      implementsKeyword = token.next!;
      do {
        token = computeType(token.next!, /* required = */ true)
            .ensureTypeNotVoid(token.next!, this);
        ++interfacesCount;
      } while (optional(',', token.next!));
    }
    listener.handleImplements(implementsKeyword, interfacesCount);
    return token;
  }

  /// Parse a mixin declaration.
  ///
  /// ```
  /// mixinDeclaration:
  ///   metadata? 'augment'? mixinModifiers? 'mixin' [SimpleIdentifier]
  ///        [TypeParameterList]? [OnClause]? [ImplementsClause]?
  ///        '{' [ClassMember]* '}'
  /// ;
  ///
  /// mixinModifiers: 'sealed' | 'base' | 'interface' | 'final'
  /// ```
  Token parseMixin(Token? augmentToken, Token? sealedToken, Token? baseToken,
      Token? interfaceToken, Token? finalToken, Token mixinKeyword) {
    assert(optional('mixin', mixinKeyword));
    listener.beginClassOrMixinOrNamedMixinApplicationPrelude(mixinKeyword);
    Token name = ensureIdentifier(
        mixinKeyword, IdentifierContext.classOrMixinOrExtensionDeclaration);
    Token headerStart = computeTypeParamOrArg(
            name, /* inDeclaration = */ true, /* allowsVariance = */ true)
        .parseVariables(name, this);
    listener.beginMixinDeclaration(augmentToken, sealedToken, baseToken,
        interfaceToken, finalToken, mixinKeyword, name);
    Token token = parseMixinHeaderOpt(headerStart, mixinKeyword);
    if (!optional('{', token.next!)) {
      // Recovery
      token = parseMixinHeaderRecovery(token, mixinKeyword, headerStart);
      ensureBlock(token, /* template = */ null, 'mixin declaration');
    }
    token = parseClassOrMixinOrExtensionBody(
        token, DeclarationKind.Mixin, name.lexeme);
    listener.endMixinDeclaration(mixinKeyword, token);
    return token;
  }

  Token parseMixinHeaderOpt(Token token, Token mixinKeyword) {
    token = parseMixinOnOpt(token);
    token = parseClassOrMixinOrEnumImplementsOpt(token);
    listener.handleMixinHeader(mixinKeyword);
    return token;
  }

  Token parseMixinHeaderRecovery(
      Token token, Token mixinKeyword, Token headerStart) {
    final Listener primaryListener = listener;
    final MixinHeaderRecoveryListener recoveryListener =
        new MixinHeaderRecoveryListener();

    // Reparse to determine which clauses have already been parsed
    // but intercept the events so they are not sent to the primary listener.
    listener = recoveryListener;
    token = parseMixinHeaderOpt(headerStart, mixinKeyword);
    bool hasOn = recoveryListener.onKeyword != null;
    bool hasImplements = recoveryListener.implementsKeyword != null;

    // Update the recovery listener to forward subsequent events
    // to the primary listener.
    recoveryListener.listener = primaryListener;

    // Parse additional out-of-order clauses
    Token start;
    do {
      start = token;

      // Check for extraneous token in the middle of a class header.
      token = skipUnexpectedTokenOpt(
          token, const <String>['on', 'implements', '{']);

      // During recovery, clauses are parsed in the same order and
      // generate the same events as in the parseMixinHeaderOpt method above.
      recoveryListener.clear();

      if (token.next!.isKeywordOrIdentifier &&
          const ['extend', 'extends'].contains(token.next!.lexeme)) {
        reportRecoverableError(
            token.next!, codes.templateExpectedInstead.withArguments('on'));
        token = parseMixinOn(token);
      } else {
        token = parseMixinOnOpt(token);
      }

      if (recoveryListener.onKeyword != null) {
        if (hasOn) {
          reportRecoverableError(
              recoveryListener.onKeyword!, codes.messageMultipleOnClauses);
        } else {
          if (hasImplements) {
            reportRecoverableError(
                recoveryListener.onKeyword!, codes.messageImplementsBeforeOn);
          }
          hasOn = true;
        }
      }

      token = parseClassOrMixinOrEnumImplementsOpt(token);

      if (recoveryListener.implementsKeyword != null) {
        if (hasImplements) {
          reportRecoverableError(recoveryListener.implementsKeyword!,
              codes.messageMultipleImplements);
        } else {
          hasImplements = true;
        }
      }

      listener.handleRecoverMixinHeader();

      // Exit if a mixin body is detected, or if no progress has been made
    } while (!optional('{', token.next!) && start != token);

    listener = primaryListener;
    return token;
  }

  /// ```
  /// onClause:
  ///   'on' typeName (',' typeName)*
  /// ;
  /// ```
  Token parseMixinOnOpt(Token token) {
    if (!optional('on', token.next!)) {
      listener.handleMixinOn(/* onKeyword = */ null, /* typeCount = */ 0);
      return token;
    }
    return parseMixinOn(token);
  }

  Token parseMixinOn(Token token) {
    Token onKeyword = token.next!;
    // During recovery, the [onKeyword] can be "extend" or "extends"
    assert(optional('on', onKeyword) ||
        optional('extends', onKeyword) ||
        onKeyword.lexeme == 'extend');
    int typeCount = 0;
    do {
      token = computeType(token.next!, /* required = */ true)
          .ensureTypeNotVoid(token.next!, this);
      ++typeCount;
    } while (optional(',', token.next!));
    listener.handleMixinOn(onKeyword, typeCount);
    return token;
  }

  /// ```
  /// 'extension' <identifier>? <typeParameters>? 'on' <type> '?'?
  //   `{'
  //     <memberDeclaration>*
  //   `}'
  /// ```
  Token parseExtension(Token extensionKeyword) {
    assert(optional('extension', extensionKeyword));
    Token token = extensionKeyword;
    listener.beginExtensionDeclarationPrelude(extensionKeyword);
    Token? name = token.next!;
    Token? typeKeyword = null;
    if (name.isIdentifier &&
        name.lexeme == 'type' &&
        name.next!.isIdentifier &&
        !optional('on', name.next!)) {
      typeKeyword = name;
      token = token.next!;
      name = token.next!;
    }
    if (name.isIdentifier && !optional('on', name)) {
      token = name;
      if (name.type.isBuiltIn) {
        reportRecoverableErrorWithToken(
            token, codes.templateBuiltInIdentifierInDeclaration);
      }
    } else {
      name = null;
    }
    token = computeTypeParamOrArg(token, /* inDeclaration = */ true)
        .parseVariables(token, this);
    listener.beginExtensionDeclaration(extensionKeyword, name);
    Token onKeyword = token.next!;
    if (!optional('on', onKeyword)) {
      // Recovery
      if (optional('extends', onKeyword) ||
          optional('implements', onKeyword) ||
          optional('with', onKeyword)) {
        reportRecoverableError(
            onKeyword, codes.templateExpectedInstead.withArguments('on'));
      } else {
        reportRecoverableError(
            token, codes.templateExpectedAfterButGot.withArguments('on'));
        onKeyword = rewriter.insertSyntheticKeyword(token, Keyword.ON);
      }
    }
    TypeInfo typeInfo = computeType(onKeyword, /* required = */ true);
    token = typeInfo.ensureTypeOrVoid(onKeyword, this);

    int handleShowHideElements() {
      int elementCount = 0;
      do {
        Token next = token.next!.next!;
        if (optional('get', next)) {
          token = IdentifierContext.extensionShowHideElementGetter
              .ensureIdentifier(next, this);
          listener.handleShowHideIdentifier(next, token);
        } else if (optional('operator', next)) {
          token = IdentifierContext.extensionShowHideElementOperator
              .ensureIdentifier(next, this);
          listener.handleShowHideIdentifier(next, token);
        } else if (optional('set', next)) {
          token = IdentifierContext.extensionShowHideElementSetter
              .ensureIdentifier(next, this);
          listener.handleShowHideIdentifier(next, token);
        } else {
          TypeInfo typeInfo = computeType(
              token.next!,
              /* required = */ true,
              /* inDeclaration = */ true,
              /* acceptKeywordForSimpleType = */ true);
          final bool isUnambiguouslyType =
              typeInfo.hasTypeArguments || typeInfo is PrefixedType;
          if (isUnambiguouslyType) {
            token = typeInfo.ensureTypeOrVoid(token.next!, this);
          } else {
            token = IdentifierContext.extensionShowHideElementMemberOrType
                .ensureIdentifier(token.next!, this);
            listener.handleShowHideIdentifier(/* modifier = */ null, token);
          }
        }
        ++elementCount;
      } while (optional(',', token.next!));
      return elementCount;
    }

    Token? showKeyword = token.next!;
    int showElementCount = 0;
    if (optional('show', showKeyword)) {
      showElementCount = handleShowHideElements();
    } else {
      showKeyword = null;
    }

    Token? hideKeyword = token.next!;
    int hideElementCount = 0;
    if (optional('hide', hideKeyword)) {
      hideElementCount = handleShowHideElements();
    } else {
      hideKeyword = null;
    }

    listener.handleExtensionShowHide(
        showKeyword, showElementCount, hideKeyword, hideElementCount);

    if (!optional('{', token.next!)) {
      // Recovery
      Token next = token.next!;
      while (!next.isEof) {
        if (optional(',', next) ||
            optional('extends', next) ||
            optional('implements', next) ||
            optional('on', next) ||
            optional('with', next)) {
          // Report an error and skip `,` or specific keyword
          // optionally followed by an identifier
          reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
          token = next;
          next = token.next!;
          if (next.isIdentifier) {
            token = next;
            next = token.next!;
          }
        } else {
          break;
        }
      }
      ensureBlock(token, /* template = */ null, 'extension declaration');
    }
    token = parseClassOrMixinOrExtensionBody(
        token, DeclarationKind.Extension, name?.lexeme);
    listener.endExtensionDeclaration(extensionKeyword, typeKeyword, onKeyword,
        showKeyword, hideKeyword, token);
    return token;
  }

  Token parseStringPart(Token token) {
    Token next = token.next!;
    if (next.kind != STRING_TOKEN) {
      reportRecoverableErrorWithToken(next, codes.templateExpectedString);
      next = rewriter.insertToken(token,
          new SyntheticStringToken(TokenType.STRING, '', next.charOffset));
    }
    listener.handleStringPart(next);
    return next;
  }

  /// Insert a synthetic identifier after the given [token] and create an error
  /// message based on the given [context]. Return the synthetic identifier that
  /// was inserted.
  Token insertSyntheticIdentifier(Token token, IdentifierContext context,
      {codes.Message? message, Token? messageOnToken}) {
    Token next = token.next!;
    reportRecoverableError(messageOnToken ?? next,
        message ?? context.recoveryTemplate.withArguments(next));
    return rewriter.insertSyntheticIdentifier(token);
  }

  /// Parse a simple identifier at the given [token], and return the identifier
  /// that was parsed.
  ///
  /// If the token is not an identifier, or is not appropriate for use as an
  /// identifier in the given [context], create a synthetic identifier, report
  /// an error, and return the synthetic identifier.
  Token ensureIdentifier(Token token, IdentifierContext context) {
    // ignore: unnecessary_null_comparison
    assert(context != null);
    _tryRewriteNewToIdentifier(token, context);
    Token identifier = token.next!;
    if (identifier.kind != IDENTIFIER_TOKEN) {
      identifier = context.ensureIdentifier(token, this);
      // ignore: unnecessary_null_comparison
      assert(identifier != null);
      assert(identifier.isKeywordOrIdentifier);
    }
    listener.handleIdentifier(identifier, context);
    return identifier;
  }

  /// Returns `true` if [token] is either an identifier or a `new` token.  This
  /// can be used to match identifiers in contexts where a constructor name can
  /// appear, since `new` can be used to refer to the unnamed constructor.
  bool _isNewOrIdentifier(Token token) {
    if (token.isIdentifier) return true;
    if (token.kind == KEYWORD_TOKEN) {
      final String? value = token.stringValue;
      if (value == 'new') {
        // Treat `new` as an identifier so that it can represent an unnamed
        // constructor.
        return true;
      }
    }
    return false;
  }

  /// If the token following [token] is a `new` keyword, and [context] is a
  /// context that permits `new` to be treated as an identifier, rewrites the
  /// `new` token to an identifier token, and reports the rewritten token to the
  /// listener.  Otherwise does nothing.
  void _tryRewriteNewToIdentifier(Token token, IdentifierContext context) {
    if (!context.allowsNewAsIdentifier) return;
    Token identifier = token.next!;
    if (identifier.kind == KEYWORD_TOKEN) {
      final String? value = token.next!.stringValue;
      if (value == 'new') {
        // `new` after `.` is treated as an identifier so that it can represent
        // an unnamed constructor.
        Token replacementToken = rewriter.replaceTokenFollowing(
            token,
            new StringToken(TokenType.IDENTIFIER, identifier.lexeme,
                token.next!.charOffset));
        listener.handleNewAsIdentifier(replacementToken);
      }
    }
  }

  /// Checks whether the next token is (directly) an identifier. If this returns
  /// true a call to [ensureIdentifier] will return the next token.
  bool isNextIdentifier(Token token) => token.next?.kind == IDENTIFIER_TOKEN;

  /// Parse a simple identifier at the given [token], and return the identifier
  /// that was parsed.
  ///
  /// If the token is not an identifier, or is not appropriate for use as an
  /// identifier in the given [context], create a synthetic identifier, report
  /// an error, and return the synthetic identifier.
  /// [isRecovered] is passed to [context] which - if true - allows implementers
  /// to use the token as an identifier, even if it isn't a valid identifier.
  Token ensureIdentifierPotentiallyRecovered(
      Token token, IdentifierContext context, bool isRecovered) {
    // ignore: unnecessary_null_comparison
    assert(context != null);
    Token identifier = token.next!;
    if (identifier.kind != IDENTIFIER_TOKEN) {
      identifier = context.ensureIdentifierPotentiallyRecovered(
          token, this, isRecovered);
      // ignore: unnecessary_null_comparison
      assert(identifier != null);
      assert(identifier.isKeywordOrIdentifier);
    }
    listener.handleIdentifier(identifier, context);
    return identifier;
  }

  bool notEofOrValue(String value, Token token) {
    return !identical(token.kind, EOF_TOKEN) &&
        !identical(value, token.stringValue);
  }

  Token parseTypeVariablesOpt(Token token) {
    return computeTypeParamOrArg(token, /* inDeclaration = */ true)
        .parseVariables(token, this);
  }

  /// Parse a top level field or function.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseTopLevelMember(Token token) {
    token = parseMetadataStar(syntheticPreviousToken(token));
    return parseTopLevelMemberImpl(token).next!;
  }

  /// Check if [token] is the usage of 'late' before a field declaration in a
  /// context where it's not legal (i.e. in non-nnbd-mode).
  bool _isUseOfLateInNonNNBD(Token token) {
    if (token is StringToken && token.value() == "late") {
      // Possible recovery: Figure out if we're in a situation like
      // late final? <type>/var/const name [...]
      // (in non-nnbd-mode) where the late modifier is not legal and thus would
      // normally be parsed as the type.
      Token next = token.next!;
      // Skip modifiers.
      while (next.isModifier) {
        token = next;
        next = next.next!;
      }
      // Parse the (potential) new type.
      TypeInfo typeInfoAlternative = computeType(
        token,
        /* required = */ false,
        /* inDeclaration = */ true,
      );
      token = typeInfoAlternative.skipType(token);
      next = token.next!;

      // We've essentially ignored the 'late' at this point.
      // `token` is (in the good state) the last token of the type,
      // `next` is (in the good state) the name;
      // Are we in a 'good' state?
      if (typeInfoAlternative != noType &&
          next.isIdentifier &&
          indicatesMethodOrField(next.next!)) {
        return true;
      }
    }
    return false;
  }

  Token parseTopLevelMemberImpl(Token token) {
    Token beforeStart = token;
    Token next = token.next!;
    listener.beginTopLevelMember(next);

    Token? skippedNonLateLate;

    if (_isUseOfLateInNonNNBD(next)) {
      skippedNonLateLate = next;
      reportRecoverableErrorWithToken(
          skippedNonLateLate, codes.templateUnexpectedModifierInNonNnbd);
      token = token.next!;
      beforeStart = token;
      next = token.next!;
    }

    Token? externalToken;
    Token? augmentToken;
    Token? lateToken;
    Token? varFinalOrConst;

    if (isModifier(next)) {
      if (optional('external', next)) {
        externalToken = token = next;
        next = token.next!;
      } else if (optional('augment', next)) {
        augmentToken = token = next;
        next = token.next!;
      }
      if (isModifier(next)) {
        if (optional('final', next)) {
          varFinalOrConst = token = next;
          next = token.next!;
        } else if (optional('var', next)) {
          varFinalOrConst = token = next;
          next = token.next!;
        } else if (optional('const', next)) {
          varFinalOrConst = token = next;
          next = token.next!;
        } else if (optional('late', next)) {
          lateToken = token = next;
          next = token.next!;
          if (isModifier(next) && optional('final', next)) {
            varFinalOrConst = token = next;
            next = token.next!;
          }
        }
        if (isModifier(next)) {
          // Recovery
          if (varFinalOrConst != null &&
              (optional('final', next) ||
                  optional('var', next) ||
                  optional('const', next))) {
            // If another `var`, `final`, or `const` then fall through
            // to parse that as part of the next top level declaration.
          } else {
            ModifierContext context = new ModifierContext(this)
              ..externalToken = externalToken
              ..augmentToken = augmentToken
              ..lateToken = lateToken
              ..varFinalOrConst = varFinalOrConst;

            token = context.parseTopLevelMemberModifiers(token);
            next = token.next!;

            augmentToken = context.augmentToken;
            externalToken = context.externalToken;
            lateToken = context.lateToken;
            varFinalOrConst = context.varFinalOrConst;
          }
        }
      }
    }
    if (lateToken == null) {
      // `late` was used as a modifier in non-nnbd mode. An error has been
      // emitted. Still use it as a late token for the remainder in an attempt
      // to avoid cascading errors (and for passing to the listener).
      lateToken = skippedNonLateLate;
    }

    Token beforeType = token;
    TypeInfo typeInfo =
        computeType(token, /* required = */ false, /* inDeclaration = */ true);
    token = typeInfo.skipType(token);
    next = token.next!;

    Token? getOrSet;
    String? value = next.stringValue;
    if (identical(value, 'get') || identical(value, 'set')) {
      if (next.next!.isIdentifier) {
        getOrSet = token = next;
        next = token.next!;
      }
    }

    bool nameIsRecovered = false;

    // Recovery: If the code is
    // <return type>? <reserved word> <token indicating method or field>
    // take the reserved keyword as the name.
    if (typeInfo == noType &&
        varFinalOrConst == null &&
        isReservedKeyword(next.next!) &&
        indicatesMethodOrField(next.next!.next!)) {
      // Recovery: Use the reserved keyword despite that not being legal.
      typeInfo = computeType(
        token,
        /* required = */ true,
        /* inDeclaration = */ true,
      );
      token = typeInfo.skipType(token);
      next = token.next!;
      nameIsRecovered = true;
    }

    if (next.type != TokenType.IDENTIFIER) {
      value = next.stringValue;
      if (identical(value, 'factory') || identical(value, 'operator')) {
        // `factory` and `operator` can be used as an identifier.
        value = next.next!.stringValue;
        if (getOrSet == null &&
            !identical(value, '(') &&
            !identical(value, '{') &&
            !identical(value, '<') &&
            !identical(value, '=>') &&
            !identical(value, '=') &&
            !identical(value, ';') &&
            !identical(value, ',')) {
          // Recovery
          value = next.stringValue;
          if (identical(value, 'factory')) {
            reportRecoverableError(
                next, codes.messageFactoryTopLevelDeclaration);
          } else {
            reportRecoverableError(next, codes.messageTopLevelOperator);
            if (next.next!.isOperator) {
              token = next;
              next = token.next!;
              if (optional('(', next.next!)) {
                rewriter.insertSyntheticIdentifier(
                    next, '#synthetic_identifier_${next.charOffset}');
              }
            }
          }
          listener.handleInvalidTopLevelDeclaration(next);
          return next;
        }
        // Fall through and continue parsing
      } else if (!next.isIdentifier) {
        // Recovery
        if (next.isKeyword) {
          // Fall through to parse the keyword as the identifier.
          // ensureIdentifier will report the error.
        } else if (token == beforeStart) {
          // Ensure we make progress.
          return parseInvalidTopLevelDeclaration(token);
        } else {
          // Looks like a declaration missing an identifier.
          // Insert synthetic identifier and fall through.
          insertSyntheticIdentifier(token, IdentifierContext.methodDeclaration);
          next = token.next!;
        }
      }
    }
    // At this point, `token` is beforeName.

    // Recovery: Inserted ! after method name.
    if (optional('!', next.next!)) {
      next = next.next!;
    }

    next = next.next!;
    value = next.stringValue;
    if (getOrSet != null ||
        identical(value, '(') ||
        identical(value, '{') ||
        identical(value, '<') ||
        identical(value, '.') ||
        identical(value, '=>')) {
      if (varFinalOrConst != null) {
        if (optional('var', varFinalOrConst)) {
          reportRecoverableError(varFinalOrConst, codes.messageVarReturnType);
        } else {
          reportRecoverableErrorWithToken(
              varFinalOrConst, codes.templateExtraneousModifier);
        }
      } else if (lateToken != null) {
        reportRecoverableErrorWithToken(
            lateToken, codes.templateExtraneousModifier);
      }
      return parseTopLevelMethod(beforeStart, augmentToken, externalToken,
          beforeType, typeInfo, getOrSet, token.next!, nameIsRecovered);
    }

    if (getOrSet != null) {
      reportRecoverableErrorWithToken(
          getOrSet, codes.templateExtraneousModifier);
    }
    return parseFields(
        beforeStart,
        /* abstractToken = */ null,
        augmentToken,
        externalToken,
        /* staticToken = */ null,
        /* covariantToken = */ null,
        lateToken,
        varFinalOrConst,
        beforeType,
        typeInfo,
        token.next!,
        DeclarationKind.TopLevel,
        /* enclosingDeclarationName = */ null,
        nameIsRecovered);
  }

  Token parseFields(
      Token beforeStart,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token beforeType,
      TypeInfo typeInfo,
      Token name,
      DeclarationKind kind,
      String? enclosingDeclarationName,
      bool nameIsRecovered) {
    listener.beginFields(kind, abstractToken, augmentToken, externalToken,
        staticToken, covariantToken, lateToken, varFinalOrConst, beforeStart);

    // Covariant affects only the setter and final fields do not have a setter,
    // unless it's a late field (dartbug.com/40805).
    // Field that are covariant late final with initializers are checked further
    // down.
    if (covariantToken != null && lateToken == null) {
      if (varFinalOrConst != null && optional('final', varFinalOrConst)) {
        reportRecoverableError(covariantToken, codes.messageFinalAndCovariant);
        covariantToken = null;
      }
    }
    if (typeInfo == noType) {
      if (varFinalOrConst == null) {
        reportRecoverableError(name, codes.messageMissingConstFinalVarOrType);
      }
    } else {
      if (varFinalOrConst != null && optional('var', varFinalOrConst)) {
        reportRecoverableError(varFinalOrConst, codes.messageTypeAfterVar);
      }
    }
    if (abstractToken != null && externalToken != null) {
      reportRecoverableError(abstractToken, codes.messageAbstractExternalField);
    }

    Token token = typeInfo.parseType(beforeType, this);
    assert(token.next == name || token.next!.isEof);

    IdentifierContext context = kind == DeclarationKind.TopLevel
        ? IdentifierContext.topLevelVariableDeclaration
        : IdentifierContext.fieldDeclaration;
    Token firstName = name = ensureIdentifierPotentiallyRecovered(
        token, context, /* isRecovered = */ nameIsRecovered);

    // Check for covariant late final with initializer.
    if (covariantToken != null && lateToken != null) {
      if (varFinalOrConst != null && optional('final', varFinalOrConst)) {
        Token next = name.next!;
        if (optional('=', next)) {
          reportRecoverableError(covariantToken,
              codes.messageFinalAndCovariantLateWithInitializer);
          covariantToken = null;
        }
      }
    }

    int fieldCount = 1;
    token = parseFieldInitializerOpt(
        name,
        name,
        lateToken,
        abstractToken,
        augmentToken,
        externalToken,
        varFinalOrConst,
        kind,
        enclosingDeclarationName);
    while (optional(',', token.next!)) {
      name = ensureIdentifier(token.next!, context);
      token = parseFieldInitializerOpt(
          name,
          name,
          lateToken,
          abstractToken,
          augmentToken,
          externalToken,
          varFinalOrConst,
          kind,
          enclosingDeclarationName);
      ++fieldCount;
    }
    Token semicolon = token.next!;
    if (optional(';', semicolon)) {
      token = semicolon;
    } else {
      // Recovery
      if (kind == DeclarationKind.TopLevel &&
          beforeType.next!.isIdentifier &&
          beforeType.next!.lexeme == 'extension') {
        // Looks like an extension method
        // TODO(danrubel): Remove when extension methods are enabled by default
        // because then 'extension' will be interpreted as a built-in
        // and this code will never be executed
        reportExperimentNotEnabled(ExperimentalFlag.extensionMethods,
            beforeType.next!, beforeType.next!);
        token = rewriter.insertSyntheticToken(token, TokenType.SEMICOLON);
      } else {
        token = ensureSemicolon(token);
      }
    }
    switch (kind) {
      case DeclarationKind.TopLevel:
        assert(abstractToken == null);
        listener.endTopLevelFields(externalToken, staticToken, covariantToken,
            lateToken, varFinalOrConst, fieldCount, beforeStart.next!, token);
        break;
      case DeclarationKind.Class:
        listener.endClassFields(
            abstractToken,
            augmentToken,
            externalToken,
            staticToken,
            covariantToken,
            lateToken,
            varFinalOrConst,
            fieldCount,
            beforeStart.next!,
            token);
        break;
      case DeclarationKind.Mixin:
        listener.endMixinFields(
            abstractToken,
            augmentToken,
            externalToken,
            staticToken,
            covariantToken,
            lateToken,
            varFinalOrConst,
            fieldCount,
            beforeStart.next!,
            token);
        break;
      case DeclarationKind.Extension:
        if (abstractToken != null) {
          reportRecoverableError(
              firstName, codes.messageAbstractExtensionField);
        }
        if (staticToken == null && externalToken == null) {
          reportRecoverableError(
              firstName, codes.messageExtensionDeclaresInstanceField);
        }
        listener.endExtensionFields(
            abstractToken,
            augmentToken,
            externalToken,
            staticToken,
            covariantToken,
            lateToken,
            varFinalOrConst,
            fieldCount,
            beforeStart.next!,
            token);
        break;
      case DeclarationKind.Enum:
        listener.endEnumFields(
            abstractToken,
            augmentToken,
            externalToken,
            staticToken,
            covariantToken,
            lateToken,
            varFinalOrConst,
            fieldCount,
            beforeStart.next!,
            token);
        break;
    }
    return token;
  }

  Token parseTopLevelMethod(
      Token beforeStart,
      Token? augmentToken,
      Token? externalToken,
      Token beforeType,
      TypeInfo typeInfo,
      Token? getOrSet,
      Token name,
      bool nameIsRecovered) {
    listener.beginTopLevelMethod(beforeStart, augmentToken, externalToken);

    Token token = typeInfo.parseType(beforeType, this);
    assert(token.next == (getOrSet ?? name) || token.next!.isEof);
    name = ensureIdentifierPotentiallyRecovered(
        getOrSet ?? token,
        IdentifierContext.topLevelFunctionDeclaration,
        /* isRecovered = */ nameIsRecovered);

    bool isGetter = false;
    if (getOrSet == null) {
      token = parseMethodTypeVar(name);
    } else {
      isGetter = optional("get", getOrSet);
      token = name;
      listener.handleNoTypeVariables(token.next!);
    }
    token = parseGetterOrFormalParameters(
        token, name, isGetter, MemberKind.TopLevelMethod);
    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token.next!;
    token = parseAsyncModifierOpt(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableError(asyncToken, codes.messageSetterNotSync);
    }
    // TODO(paulberry): code below is slightly hacky to allow for implementing
    // the feature "Infer non-nullability from local boolean variables"
    // (https://github.com/dart-lang/language/issues/1274).  Since the version
    // of Dart that is used for presubmit checks lags slightly behind master,
    // we need the code to analyze correctly regardless of whether local boolean
    // variables cause promotion or not.  Once the version of dart used for
    // presubmit checks has been updated, this can be cleaned up to:
    //   bool isExternal = externalToken != null;
    //   if (externalToken != null && !optional(';', token.next!)) {
    //     reportRecoverableError(
    //         externalToken, codes.messageExternalMethodWithBody);
    //   }
    bool isExternal = false;
    if (externalToken != null) {
      isExternal = true;
      if (!optional(';', token.next!)) {
        reportRecoverableError(
            externalToken, codes.messageExternalMethodWithBody);
      }
    }
    token = parseFunctionBody(
        token, /* ofFunctionExpression = */ false, isExternal);
    asyncState = savedAsyncModifier;
    listener.endTopLevelMethod(beforeStart.next!, getOrSet, token);
    return token;
  }

  Token parseMethodTypeVar(Token name) {
    if (optional('!', name.next!)) {
      // Recovery
      name = name.next!;
      reportRecoverableErrorWithToken(name, codes.templateUnexpectedToken);
    }
    if (!optional('<', name.next!)) {
      return noTypeParamOrArg.parseVariables(name, this);
    }
    TypeParamOrArgInfo typeVar =
        computeTypeParamOrArg(name, /* inDeclaration = */ true);
    Token token = typeVar.parseVariables(name, this);
    if (optional('=', token.next!)) {
      // Recovery
      token = token.next!;
      reportRecoverableErrorWithToken(token, codes.templateUnexpectedToken);
    }
    return token;
  }

  Token parseFieldInitializerOpt(
      Token token,
      Token name,
      Token? lateToken,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? varFinalOrConst,
      DeclarationKind kind,
      String? enclosingDeclarationName) {
    if (name.lexeme == enclosingDeclarationName) {
      reportRecoverableError(name, codes.messageMemberWithSameNameAsClass);
    }
    Token next = token.next!;
    if (optional('=', next)) {
      Token assignment = next;
      listener.beginFieldInitializer(next);
      token = parseExpression(next);
      listener.endFieldInitializer(assignment, token.next!);
    } else {
      if (varFinalOrConst != null && !name.isSynthetic) {
        if (optional("const", varFinalOrConst)) {
          reportRecoverableError(
              name,
              codes.templateConstFieldWithoutInitializer
                  .withArguments(name.lexeme));
        } else if (kind == DeclarationKind.TopLevel &&
            optional("final", varFinalOrConst) &&
            lateToken == null &&
            abstractToken == null &&
            externalToken == null) {
          reportRecoverableError(
              name,
              codes.templateFinalFieldWithoutInitializer
                  .withArguments(name.lexeme));
        }
      }
      listener.handleNoFieldInitializer(token.next!);
    }
    return token;
  }

  Token parseVariableInitializerOpt(Token token) {
    if (optional('=', token.next!)) {
      Token assignment = token.next!;
      listener.beginVariableInitializer(assignment);
      token = parseExpression(assignment);
      listener.endVariableInitializer(assignment);
    } else {
      listener.handleNoVariableInitializer(token);
    }
    return token;
  }

  Token parseInitializersOpt(Token token) {
    if (optional(':', token.next!)) {
      return parseInitializers(token.next!);
    } else {
      listener.handleNoInitializers();
      return token;
    }
  }

  /// ```
  /// initializers:
  ///   ':' initializerListEntry (',' initializerListEntry)*
  /// ;
  /// ```
  Token parseInitializers(Token token) {
    Token begin = token;
    assert(optional(':', begin));
    listener.beginInitializers(begin);
    int count = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = false;
    Token next = begin;
    while (true) {
      token = parseInitializer(next);
      ++count;
      next = token.next!;
      if (!optional(',', next)) {
        // Recovery: Found an identifier which could be
        // 1) missing preceding `,` thus it's another initializer, or
        // 2) missing preceding `;` thus it's a class member, or
        // 3) missing preceding '{' thus it's a statement
        if (optional('assert', next)) {
          next = next.next!;
          if (!optional('(', next)) {
            break;
          }
          // Looks like assert expression ... fall through to insert comma.
        } else if (optional('this', next) || optional('super', next)) {
          next = next.next!;
          if (!optional('(', next) && !optional('.', next)) {
            break;
          }
          // `this` or `super` followed by either `.` or `(`.
          // Fall through to insert comma.
        } else if (next.isIdentifier) {
          next = next.next!;
          if (!optional('=', next)) {
            break;
          }
          // Looks like field assignment... fall through to insert comma.
        } else {
          break;
        }
        // TODO(danrubel): Consider enhancing this to indicate that we are
        // expecting one of `,` or `;` or `{`
        reportRecoverableError(
            token, codes.templateExpectedAfterButGot.withArguments(','));
        next = rewriter.insertSyntheticToken(token, TokenType.COMMA);
      }
    }
    mayParseFunctionExpressions = old;
    listener.endInitializers(count, begin, token.next!);
    return token;
  }

  /// ```
  /// initializerListEntry:
  ///   'super' ('.' identifier)? arguments |
  ///   fieldInitializer |
  ///   assertion
  /// ;
  ///
  /// fieldInitializer:
  ///   ('this' '.')? identifier '=' conditionalExpression cascadeSection*
  /// ;
  /// ```
  Token parseInitializer(Token token) {
    Token next = token.next!;
    listener.beginInitializer(next);
    Token beforeExpression = token;
    if (optional('assert', next)) {
      token = parseAssert(token, Assert.Initializer);
      listener.endInitializer(token.next!);
      return token;
    } else if (optional('super', next)) {
      return parseSuperInitializerExpression(token);
    } else if (optional('this', next)) {
      token = next;
      next = token.next!;
      if (optional('.', next)) {
        token = next;
        Token? afterIdentifier = token.next!.next;
        if (afterIdentifier != null && optional('(', afterIdentifier)) {
          _tryRewriteNewToIdentifier(token, IdentifierContext.fieldInitializer);
        }
        next = token.next!;
        if (next.isIdentifier) {
          token = next;
        } else {
          // Recovery
          token = insertSyntheticIdentifier(
              token, IdentifierContext.fieldInitializer);
        }
        next = token.next!;
        if (optional('=', next)) {
          return parseInitializerExpressionRest(beforeExpression);
        }
      }
      if (optional('(', next)) {
        token = parseInitializerExpressionRest(beforeExpression);
        next = token.next!;
        if (optional('{', next) || optional('=>', next)) {
          reportRecoverableError(
              next, codes.messageRedirectingConstructorWithBody);
        }
        return token;
      }
      // Recovery
      if (optional('this', token)) {
        // TODO(danrubel): Consider a better error message indicating that
        // `this.<fieldname>=` is expected.
        reportRecoverableError(
            next, codes.templateExpectedButGot.withArguments('.'));
        rewriter.insertSyntheticToken(token, TokenType.PERIOD);
        token = rewriter.insertSyntheticIdentifier(token.next!);
        next = token.next!;
      }
      // Fall through to recovery
    } else if (next.isIdentifier) {
      Token next2 = next.next!;
      if (optional('=', next2)) {
        return parseInitializerExpressionRest(token);
      }
      // Recovery: If this looks like an expression,
      // then fall through to insert the LHS and `=` of the assignment,
      // otherwise insert an `=` and synthetic identifier.
      if (!next2.isOperator && !optional('.', next2)) {
        token = rewriter.insertSyntheticToken(next, TokenType.EQ);
        token = insertSyntheticIdentifier(token, IdentifierContext.expression,
            message: codes.messageMissingAssignmentInInitializer,
            messageOnToken: next);
        return parseInitializerExpressionRest(beforeExpression);
      }
    } else {
      // Recovery: Insert a synthetic assignment.
      token = insertSyntheticIdentifier(
          token, IdentifierContext.fieldInitializer,
          message: codes.messageExpectedAnInitializer, messageOnToken: token);
      token = rewriter.insertSyntheticToken(token, TokenType.EQ);
      token = rewriter.insertSyntheticIdentifier(token);
      return parseInitializerExpressionRest(beforeExpression);
    }
    // Recovery:
    // Insert a synthetic identifier and assignment operator
    // to ensure that the expression is indeed an assignment.
    // Failing to do so causes this test to fail:
    // pkg/front_end/testcases/regress/issue_31192.dart
    // TODO(danrubel): Investigate better recovery.
    token = insertSyntheticIdentifier(
        beforeExpression, IdentifierContext.fieldInitializer,
        message: codes.messageMissingAssignmentInInitializer);
    rewriter.insertSyntheticToken(token, TokenType.EQ);
    return parseInitializerExpressionRest(beforeExpression);
  }

  /// Parse the `super` initializer:
  /// ```
  ///   'super' ('.' identifier)? arguments ;
  /// ```
  Token parseSuperInitializerExpression(final Token start) {
    Token token = start.next!;
    assert(optional('super', token));
    Token next = token.next!;
    if (optional('.', next)) {
      token = next;
      _tryRewriteNewToIdentifier(
          token, IdentifierContext.constructorReferenceContinuation);
      next = token.next!;
      if (next.kind != IDENTIFIER_TOKEN) {
        next = IdentifierContext.expressionContinuation
            .ensureIdentifier(token, this);
      }
      token = next;
      next = token.next!;
    }
    if (!optional('(', next)) {
      // Recovery
      if (optional('?.', next)) {
        // An error for `super?.` is reported in parseSuperExpression.
        token = next;
        next = token.next!;
        if (!next.isIdentifier) {
          // Insert a synthetic identifier but don't report another error.
          next = rewriter.insertSyntheticIdentifier(token);
        }
        token = next;
        next = token.next!;
      }
      if (optional('=', next)) {
        if (optional('super', token)) {
          // parseExpression will report error on assignment to super
        } else {
          reportRecoverableError(
              token, codes.messageFieldInitializedOutsideDeclaringClass);
        }
      } else if (!optional('(', next)) {
        reportRecoverableError(
            next, codes.templateExpectedAfterButGot.withArguments('('));
        rewriter.insertParens(token, /* includeIdentifier = */ false);
      }
    }
    return parseInitializerExpressionRest(start);
  }

  Token parseInitializerExpressionRest(Token token) {
    token = parseExpression(token);
    listener.endInitializer(token.next!);
    return token;
  }

  /// If the next token is an opening curly brace, return it. Otherwise, use the
  /// given [template] or [missingBlockName] to report an error, insert an
  /// opening and a closing curly brace, and return the newly inserted opening
  /// curly brace. If  [template] and [missingBlockName] are `null`, then use
  /// a default error message instead.
  Token ensureBlock(
      Token token,
      codes.Template<codes.Message Function(Token token)>? template,
      String? missingBlockName) {
    Token next = token.next!;
    if (optional('{', next)) return next;
    if (template == null) {
      if (missingBlockName == null) {
        // TODO(danrubel): rename ExpectedButGot to ExpectedBefore
        reportRecoverableError(
            next, codes.templateExpectedButGot.withArguments('{'));
      } else {
        // TODO(danrubel): rename ExpectedClassOrMixinBody
        //  to ExpectedDeclarationOrClauseBody
        reportRecoverableError(
            token,
            codes.templateExpectedClassOrMixinBody
                .withArguments(missingBlockName));
      }
    } else {
      reportRecoverableError(next, template.withArguments(next));
    }
    return insertBlock(token);
  }

  Token insertBlock(Token token) {
    Token next = token.next!;
    BeginToken beginGroup = rewriter.insertToken(token,
            new SyntheticBeginToken(TokenType.OPEN_CURLY_BRACKET, next.offset))
        as BeginToken;
    Token endGroup = rewriter.insertToken(beginGroup,
        new SyntheticToken(TokenType.CLOSE_CURLY_BRACKET, next.offset));
    beginGroup.endGroup = endGroup;
    return beginGroup;
  }

  /// If the next token is a closing parenthesis, return it.
  /// Otherwise, report an error and return the closing parenthesis
  /// associated with the specified open parenthesis.
  Token ensureCloseParen(Token token, Token openParen) {
    Token next = token.next!;
    if (optional(')', next)) {
      return next;
    }
    if (openParen.endGroup!.isSynthetic) {
      // Scanner has already reported a missing `)` error,
      // but placed the `)` in the wrong location, so move it.
      return rewriter.moveSynthetic(token, openParen.endGroup!);
    }

    // TODO(danrubel): Pass in context for better error message.
    reportRecoverableError(
        next, codes.templateExpectedButGot.withArguments(')'));

    // Scanner guarantees a closing parenthesis
    // TODO(danrubel): Improve recovery by having callers parse tokens
    // between `token` and `openParen.endGroup`.
    return openParen.endGroup!;
  }

  /// If the next token is a colon, return it. Otherwise, report an
  /// error, insert a synthetic colon, and return the inserted colon.
  Token ensureColon(Token token) {
    Token next = token.next!;
    if (optional(':', next)) return next;
    codes.Message message = codes.templateExpectedButGot.withArguments(':');
    Token newToken = new SyntheticToken(TokenType.COLON, next.charOffset);
    return rewriteAndRecover(token, message, newToken);
  }

  /// If the next token is a function arrow (`=>`), return it.  Otherwise report
  /// an error, insert a synthetic function arrow, and return the inserted
  /// function arrow.
  Token ensureFunctionArrow(Token token) {
    Token next = token.next!;
    if (optional('=>', next)) return next;
    codes.Message message = codes.templateExpectedButGot.withArguments('=>');
    Token newToken = new SyntheticToken(TokenType.FUNCTION, next.charOffset);
    return rewriteAndRecover(token, message, newToken);
  }

  /// If the token after [token] is a not literal string,
  /// then insert a synthetic literal string.
  /// Call `parseLiteralString` and return the result.
  Token ensureLiteralString(Token token) {
    Token next = token.next!;
    if (!identical(next.kind, STRING_TOKEN)) {
      codes.Message message = codes.templateExpectedString.withArguments(next);
      Token newToken = new SyntheticStringToken(
          TokenType.STRING, '""', next.charOffset, /* _length = */ 0);
      rewriteAndRecover(token, message, newToken);
    }
    return parseLiteralString(token);
  }

  /// If the token after [token] is a semi-colon, return it.
  /// Otherwise, report an error, insert a synthetic semi-colon,
  /// and return the inserted semi-colon.
  Token ensureSemicolon(Token token) {
    // TODO(danrubel): Once all expect(';'...) call sites have been converted
    // to use this method, remove similar semicolon recovery code
    // from the handleError method in element_listener.dart.
    Token next = token.next!;
    if (optional(';', next)) return next;

    // Find a token on the same line as where the ';' should be inserted.
    // Reporting the error on this token makes it easier
    // for users to understand and fix the error.
    reportRecoverableError(findPreviousNonZeroLengthToken(token),
        codes.templateExpectedAfterButGot.withArguments(';'));
    return rewriter.insertSyntheticToken(token, TokenType.SEMICOLON);
  }

  /// Report an error at the token after [token] that has the given [message].
  /// Insert the [newToken] after [token] and return [newToken].
  Token rewriteAndRecover(Token token, codes.Message message, Token newToken) {
    reportRecoverableError(token.next!, message);
    return rewriter.insertToken(token, newToken);
  }

  /// Replace the token after [token] with `[` followed by `]`
  /// and return [token].
  Token rewriteSquareBrackets(Token token) {
    Token next = token.next!;
    assert(optional('[]', next));
    Token replacement;
    if (next.isSynthetic) {
      replacement = link(
          new SyntheticBeginToken(TokenType.OPEN_SQUARE_BRACKET, next.offset,
              next.precedingComments),
          new SyntheticToken(TokenType.CLOSE_SQUARE_BRACKET, next.offset));
    } else {
      replacement = link(
          new BeginToken(TokenType.OPEN_SQUARE_BRACKET, next.offset,
              next.precedingComments),
          new Token(TokenType.CLOSE_SQUARE_BRACKET, next.offset + 1));
    }
    rewriter.replaceTokenFollowing(token, replacement);
    return token;
  }

  /// Report the given token as unexpected and return the next token if the next
  /// token is one of the [expectedNext], otherwise just return the given token.
  Token skipUnexpectedTokenOpt(Token token, List<String> expectedNext) {
    Token next = token.next!;
    if (next.keyword == null) {
      final String? nextValue = next.next!.stringValue;
      for (String expectedValue in expectedNext) {
        if (identical(nextValue, expectedValue)) {
          reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
          return next;
        }
      }
    }
    return token;
  }

  Token parseNativeClause(Token token) {
    Token nativeToken = token = token.next!;
    assert(optional('native', nativeToken));
    bool hasName = false;
    if (token.next!.kind == STRING_TOKEN) {
      hasName = true;
      token = parseLiteralString(token);
    }
    listener.handleNativeClause(nativeToken, hasName);
    reportRecoverableError(
        nativeToken, codes.messageNativeClauseShouldBeAnnotation);
    return token;
  }

  Token skipClassOrMixinOrExtensionBody(Token token) {
    // The scanner ensures that `{` always has a closing `}`.
    return ensureBlock(
        token, /* template = */ null, /* missingBlockName = */ null);
  }

  /// ```
  /// classBody:
  ///   '{' classMember* '}'
  /// ;
  /// ```
  Token parseClassOrMixinOrExtensionBody(
      Token token, DeclarationKind kind, String? enclosingDeclarationName) {
    Token begin = token = token.next!;
    assert(optional('{', token));
    listener.beginClassOrMixinOrExtensionBody(kind, token);
    int count = 0;
    while (notEofOrValue('}', token.next!)) {
      token = parseClassOrMixinOrExtensionOrEnumMemberImpl(
          token, kind, enclosingDeclarationName);
      ++count;
    }
    token = token.next!;
    assert(token.isEof || optional('}', token));
    listener.endClassOrMixinOrExtensionBody(kind, count, begin, token);
    return token;
  }

  bool isUnaryMinus(Token token) =>
      token.kind == IDENTIFIER_TOKEN &&
      token.lexeme == 'unary' &&
      optional('-', token.next!);

  /// Parse a class member.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseClassMember(Token token, String? className) {
    return parseClassOrMixinOrExtensionOrEnumMemberImpl(
            syntheticPreviousToken(token), DeclarationKind.Class, className)
        .next!;
  }

  /// Parse a mixin member.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseMixinMember(Token token, String mixinName) {
    return parseClassOrMixinOrExtensionOrEnumMemberImpl(
            syntheticPreviousToken(token), DeclarationKind.Mixin, mixinName)
        .next!;
  }

  /// Parse an extension member.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseExtensionMember(Token token, String extensionName) {
    return parseClassOrMixinOrExtensionOrEnumMemberImpl(
            syntheticPreviousToken(token),
            DeclarationKind.Extension,
            extensionName)
        .next!;
  }

  bool isReservedKeyword(Token token) {
    if (!token.isKeyword) return false;
    return token.type.isReservedWord;
  }

  bool indicatesMethodOrField(Token token) {
    String? value = token.stringValue;
    if (identical(value, ';') ||
        identical(value, '=') ||
        identical(value, '(') ||
        identical(value, '{') ||
        identical(value, '=>') ||
        identical(value, '<')) {
      return true;
    }
    return false;
  }

  /// ```
  /// classMember:
  ///   fieldDeclaration |
  ///   constructorDeclaration |
  ///   methodDeclaration
  /// ;
  ///
  /// mixinMember:
  ///   fieldDeclaration |
  ///   methodDeclaration
  /// ;
  ///
  /// extensionMember:
  ///   staticFieldDeclaration |
  ///   methodDeclaration
  /// ;
  /// ```
  Token parseClassOrMixinOrExtensionOrEnumMemberImpl(
      Token token, DeclarationKind kind, String? enclosingDeclarationName) {
    Token beforeStart = token = parseMetadataStar(token);

    Token? skippedNonLateLate;

    if (_isUseOfLateInNonNNBD(token.next!)) {
      skippedNonLateLate = token.next!;
      reportRecoverableErrorWithToken(
          skippedNonLateLate, codes.templateUnexpectedModifierInNonNnbd);
      token = token.next!;
      beforeStart = token;
    }

    Token? covariantToken;
    Token? abstractToken;
    Token? augmentToken;
    Token? externalToken;
    Token? lateToken;
    Token? staticToken;
    Token? varFinalOrConst;

    Token next = token.next!;
    if (isModifier(next)) {
      if (optional('external', next)) {
        externalToken = token = next;
        next = token.next!;
      } else if (optional('augment', next)) {
        augmentToken = token = next;
        next = token.next!;
      } else if (optional('abstract', next)) {
        abstractToken = token = next;
        next = token.next!;
      }
      if (isModifier(next)) {
        if (optional('static', next)) {
          staticToken = token = next;
          next = token.next!;
        } else if (optional('covariant', next)) {
          covariantToken = token = next;
          next = token.next!;
        }
        if (isModifier(next)) {
          if (optional('final', next)) {
            varFinalOrConst = token = next;
            next = token.next!;
          } else if (optional('var', next)) {
            varFinalOrConst = token = next;
            next = token.next!;
          } else if (optional('const', next) && covariantToken == null) {
            varFinalOrConst = token = next;
            next = token.next!;
          } else if (optional('late', next)) {
            lateToken = token = next;
            next = token.next!;
            if (isModifier(next) && optional('final', next)) {
              varFinalOrConst = token = next;
              next = token.next!;
            }
          }
          if (isModifier(next)) {
            ModifierContext context = new ModifierContext(this)
              ..covariantToken = covariantToken
              ..augmentToken = augmentToken
              ..externalToken = externalToken
              ..lateToken = lateToken
              ..staticToken = staticToken
              ..varFinalOrConst = varFinalOrConst
              ..abstractToken = abstractToken;

            token = context.parseClassMemberModifiers(token);
            next = token.next!;

            covariantToken = context.covariantToken;
            externalToken = context.externalToken;
            lateToken = context.lateToken;
            staticToken = context.staticToken;
            varFinalOrConst = context.varFinalOrConst;
            abstractToken = context.abstractToken;
          }
        }
      }
    }

    if (lateToken == null) {
      // `late` was used as a modifier in non-nnbd mode. An error has been
      // emitted. Still use it as a late token for the remainder in an attempt
      // to avoid cascading errors (and for passing to the listener).
      lateToken = skippedNonLateLate;
    }

    listener.beginMember();

    Token beforeType = token;
    TypeInfo typeInfo = computeType(
      token,
      /* required = */ false,
      /* inDeclaration = */ true,
    );
    token = typeInfo.skipType(token);
    next = token.next!;

    Token? getOrSet;
    bool nameIsRecovered = false;
    if (next.type != TokenType.IDENTIFIER) {
      String? value = next.stringValue;
      if (identical(value, 'get') || identical(value, 'set')) {
        if (next.next!.isIdentifier) {
          getOrSet = token = next;
          next = token.next!;
        } else if (isReservedKeyword(next.next!) &&
            indicatesMethodOrField(next.next!.next!)) {
          // Recovery: Getter or setter followed by a reserved word (name).
          getOrSet = token = next;
          next = token.next!;
          nameIsRecovered = true;
        }
        // Fall through to continue parsing `get` or `set` as an identifier.
      } else if (identical(value, 'factory')) {
        Token next2 = next.next!;
        if (next2.isIdentifier || next2.isModifier) {
          if (beforeType != token) {
            reportRecoverableError(token, codes.messageTypeBeforeFactory);
          }
          if (abstractToken != null) {
            reportRecoverableError(
                abstractToken, codes.messageAbstractClassMember);
          }
          token = parseFactoryMethod(token, kind, beforeStart, externalToken,
              staticToken ?? covariantToken, varFinalOrConst);
          listener.endMember();
          return token;
        }
        // Fall through to continue parsing `factory` as an identifier.
      } else if (identical(value, 'operator')) {
        Token next2 = next.next!;
        TypeParamOrArgInfo typeParam = computeTypeParamOrArg(next);
        // `operator` can be used as an identifier as in
        // `int operator<T>()` or `int operator = 2`
        if (next2.isUserDefinableOperator && typeParam == noTypeParamOrArg) {
          token = parseMethod(
              beforeStart,
              abstractToken,
              augmentToken,
              externalToken,
              staticToken,
              covariantToken,
              lateToken,
              varFinalOrConst,
              beforeType,
              typeInfo,
              getOrSet,
              token.next!,
              kind,
              enclosingDeclarationName,
              nameIsRecovered);
          listener.endMember();
          return token;
        } else if (optional('===', next2) ||
            optional('!==', next2) ||
            (next2.isOperator &&
                !optional('=', next2) &&
                !optional('<', next2))) {
          // Recovery: Invalid operator
          return parseInvalidOperatorDeclaration(
              beforeStart,
              abstractToken,
              augmentToken,
              externalToken,
              staticToken,
              covariantToken,
              lateToken,
              varFinalOrConst,
              beforeType,
              kind,
              enclosingDeclarationName);
        } else if (isUnaryMinus(next2)) {
          // Recovery
          token = parseMethod(
              beforeStart,
              abstractToken,
              augmentToken,
              externalToken,
              staticToken,
              covariantToken,
              lateToken,
              varFinalOrConst,
              beforeType,
              typeInfo,
              getOrSet,
              token.next!,
              kind,
              enclosingDeclarationName,
              nameIsRecovered);
          listener.endMember();
          return token;
        }
        // Fall through to continue parsing `operator` as an identifier.
      } else if (!next.isIdentifier ||
          (identical(value, 'typedef') &&
              token == beforeStart &&
              next.next!.isIdentifier)) {
        if (abstractToken != null) {
          reportRecoverableError(
              abstractToken, codes.messageAbstractClassMember);
        }
        // Recovery
        return recoverFromInvalidMember(
            token,
            beforeStart,
            abstractToken,
            augmentToken,
            externalToken,
            staticToken,
            covariantToken,
            lateToken,
            varFinalOrConst,
            beforeType,
            typeInfo,
            getOrSet,
            kind,
            enclosingDeclarationName);
      }
    } else if (typeInfo == noType && varFinalOrConst == null) {
      Token next2 = next.next!;
      if (next2.isUserDefinableOperator && next2.endGroup == null) {
        String? value = next2.next!.stringValue;
        if (identical(value, '(') ||
            identical(value, '{') ||
            identical(value, '=>')) {
          // Recovery: Missing `operator` keyword
          return parseInvalidOperatorDeclaration(
              beforeStart,
              abstractToken,
              augmentToken,
              externalToken,
              staticToken,
              covariantToken,
              lateToken,
              varFinalOrConst,
              beforeType,
              kind,
              enclosingDeclarationName);
        }
      } else if (isReservedKeyword(next2) &&
          indicatesMethodOrField(next2.next!)) {
        // Recovery: Use the reserved keyword despite that not being legal.
        typeInfo = computeType(
          token,
          /* required = */ true,
          /* inDeclaration = */ true,
        );
        token = typeInfo.skipType(token);
        next = token.next!;
        nameIsRecovered = true;
      }
    }

    // At this point, token is before the name, and next is the name
    next = next.next!;
    String? value = next.stringValue;
    if (getOrSet != null ||
        identical(value, '(') ||
        identical(value, '{') ||
        identical(value, '<') ||
        identical(value, '.') ||
        identical(value, '=>')) {
      token = parseMethod(
          beforeStart,
          abstractToken,
          augmentToken,
          externalToken,
          staticToken,
          covariantToken,
          lateToken,
          varFinalOrConst,
          beforeType,
          typeInfo,
          getOrSet,
          token.next!,
          kind,
          enclosingDeclarationName,
          nameIsRecovered);
    } else {
      if (getOrSet != null) {
        reportRecoverableErrorWithToken(
            getOrSet, codes.templateExtraneousModifier);
      }
      token = parseFields(
          beforeStart,
          abstractToken,
          augmentToken,
          externalToken,
          staticToken,
          covariantToken,
          lateToken,
          varFinalOrConst,
          beforeType,
          typeInfo,
          token.next!,
          kind,
          enclosingDeclarationName,
          nameIsRecovered);
    }
    listener.endMember();
    return token;
  }

  Token parseMethod(
      Token beforeStart,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token beforeType,
      TypeInfo typeInfo,
      Token? getOrSet,
      Token name,
      DeclarationKind kind,
      String? enclosingDeclarationName,
      bool nameIsRecovered) {
    if (abstractToken != null) {
      reportRecoverableError(abstractToken, codes.messageAbstractClassMember);
    }
    if (lateToken != null) {
      reportRecoverableErrorWithToken(
          lateToken, codes.templateExtraneousModifier);
    }
    bool isOperator = false;
    if (getOrSet == null && optional('operator', name)) {
      Token operator = name.next!;
      if (operator.isOperator ||
          identical(operator.kind, EQ_EQ_EQ_TOKEN) ||
          identical(operator.kind, BANG_EQ_EQ_TOKEN) ||
          isUnaryMinus(operator)) {
        isOperator = true;
        if (optional(">>", operator) &&
            optional(">", operator.next!) &&
            operator.charEnd == operator.next!.charOffset) {
          // Special case use of triple-shift in cases where it isn't enabled.
          reportExperimentNotEnabled(
              ExperimentalFlag.tripleShift, operator, operator.next!);
          operator = rewriter.replaceNextTokensWithSyntheticToken(
              name, /* count = */ 2, TokenType.GT_GT_GT);
        }
      }
    }

    if (staticToken != null) {
      if (isOperator) {
        reportRecoverableError(staticToken, codes.messageStaticOperator);
        staticToken = null;
      }
    } else if (covariantToken != null) {
      if (getOrSet == null || optional('get', getOrSet)) {
        reportRecoverableError(covariantToken, codes.messageCovariantMember);
        covariantToken = null;
      }
    }
    if (varFinalOrConst != null) {
      if (optional('const', varFinalOrConst)) {
        if (getOrSet != null) {
          reportRecoverableErrorWithToken(
              varFinalOrConst, codes.templateExtraneousModifier);
          varFinalOrConst = null;
        }
      } else if (optional('var', varFinalOrConst)) {
        reportRecoverableError(varFinalOrConst, codes.messageVarReturnType);
        varFinalOrConst = null;
      } else {
        assert(optional('final', varFinalOrConst));
        reportRecoverableErrorWithToken(
            varFinalOrConst, codes.templateExtraneousModifier);
        varFinalOrConst = null;
      }
    }

    // TODO(danrubel): Consider parsing the name before calling beginMethod
    // rather than passing the name token into beginMethod.
    listener.beginMethod(kind, augmentToken, externalToken, staticToken,
        covariantToken, varFinalOrConst, getOrSet, name);

    Token token = typeInfo.parseType(beforeType, this);
    assert(token.next == (getOrSet ?? name) ||
        // [skipType] and [parseType] for something ending in `>>` is different
        // because [`>>`] is split to [`>`, `>`] in both cases. For skip it's
        // cached as the end but for parse a new pair is created (which is also
        // woven into the token stream). At least for now we allow this and let
        // the assert not fail because of it.
        (token.next!.type == name.type && token.next!.offset == name.offset));
    token = getOrSet ?? token;

    bool hasQualifiedName = false;

    if (isOperator) {
      token = parseOperatorName(token);
    } else {
      token = ensureIdentifierPotentiallyRecovered(
          token,
          IdentifierContext.methodDeclaration,
          /* isRecovered = */ nameIsRecovered);
      // Possible recovery: This call only does something if the next token is
      // a '.' --- that's not legal for get or set, but an error is reported
      // later, and it will recover better if we allow it.
      Token qualified = parseQualifiedRestOpt(
          token, IdentifierContext.methodDeclarationContinuation);
      if (token != qualified) {
        hasQualifiedName = true;
      }
      token = qualified;
    }

    bool isConsideredGetter = false;
    if (getOrSet == null) {
      token = parseMethodTypeVar(token);
    } else {
      isConsideredGetter = optional("get", getOrSet);
      listener.handleNoTypeVariables(token.next!);

      // If it becomes considered a constructor below, don't consider it a
      // getter now (this also enforces parenthesis (and thus parameters)).
      if (hasQualifiedName) {
        isConsideredGetter = false;
      } else if (isConsideredGetter && optional(':', token.next!)) {
        isConsideredGetter = false;
      } else if (isConsideredGetter &&
          name.lexeme == enclosingDeclarationName) {
        // This is a simple case of an badly named getter so we don't consider
        // that a constructor. We issue an error about the name below.
      }
    }

    Token beforeParam = token;
    Token? beforeInitializers = parseGetterOrFormalParameters(
        token,
        name,
        isConsideredGetter,
        kind == DeclarationKind.Extension
            ? staticToken != null
                ? MemberKind.ExtensionStaticMethod
                : MemberKind.ExtensionNonStaticMethod
            : staticToken != null
                ? MemberKind.StaticMethod
                : MemberKind.NonStaticMethod);
    token = parseInitializersOpt(beforeInitializers);
    if (token == beforeInitializers) beforeInitializers = null;

    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token.next!;
    token = parseAsyncModifierOpt(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableError(asyncToken, codes.messageSetterNotSync);
    }
    final Token bodyStart = token.next!;
    if (externalToken != null) {
      if (!optional(';', bodyStart)) {
        reportRecoverableError(bodyStart, codes.messageExternalMethodWithBody);
      }
    }
    if (optional('=', bodyStart)) {
      reportRecoverableError(bodyStart, codes.messageRedirectionInNonFactory);
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(
        token,
        /* ofFunctionExpression = */ false,
        (staticToken == null || externalToken != null) && inPlainSync,
      );
    }
    asyncState = savedAsyncModifier;

    bool isConstructor = false;
    if (optional('.', name.next!) || beforeInitializers != null) {
      // This is only legal for constructors.
      isConstructor = true;
    } else if (name.lexeme == enclosingDeclarationName) {
      if (getOrSet != null) {
        // Recovery: The (simple) get/set member name is invalid.
        // Report an error and continue with invalid name
        // (keeping it as a getter/setter).
        reportRecoverableError(name, codes.messageMemberWithSameNameAsClass);
      } else {
        isConstructor = true;
      }
    }

    if (isConstructor) {
      //
      // constructor
      //
      if (name.lexeme != enclosingDeclarationName) {
        reportRecoverableError(name, codes.messageConstructorWithWrongName);
      }
      if (staticToken != null) {
        reportRecoverableError(staticToken, codes.messageStaticConstructor);
      }
      if (getOrSet != null) {
        if (optional("get", getOrSet)) {
          reportRecoverableError(getOrSet, codes.messageGetterConstructor);
        } else {
          reportRecoverableError(getOrSet, codes.messageSetterConstructor);
        }
      }
      if (typeInfo != noType) {
        reportRecoverableError(
            beforeType.next!, codes.messageConstructorWithReturnType);
      }
      if (beforeInitializers != null && externalToken != null) {
        reportRecoverableError(beforeInitializers.next!,
            codes.messageExternalConstructorWithInitializer);
      }

      switch (kind) {
        case DeclarationKind.Class:
          // TODO(danrubel): Remove getOrSet from constructor events
          listener.endClassConstructor(getOrSet, beforeStart.next!,
              beforeParam.next!, beforeInitializers?.next, token);
          break;
        case DeclarationKind.Mixin:
          reportRecoverableError(name, codes.messageMixinDeclaresConstructor);
          listener.endMixinConstructor(getOrSet, beforeStart.next!,
              beforeParam.next!, beforeInitializers?.next, token);
          break;
        case DeclarationKind.Extension:
          reportRecoverableError(
              name, codes.messageExtensionDeclaresConstructor);
          listener.endExtensionConstructor(getOrSet, beforeStart.next!,
              beforeParam.next!, beforeInitializers?.next, token);
          break;
        case DeclarationKind.TopLevel:
          throw "Internal error: TopLevel constructor.";
        case DeclarationKind.Enum:
          listener.endEnumConstructor(getOrSet, beforeStart.next!,
              beforeParam.next!, beforeInitializers?.next, token);
          break;
      }
    } else {
      //
      // method
      //
      if (varFinalOrConst != null) {
        assert(optional('const', varFinalOrConst));
        reportRecoverableError(varFinalOrConst, codes.messageConstMethod);
      }
      switch (kind) {
        case DeclarationKind.Class:
          // TODO(danrubel): Remove beginInitializers token from method events
          listener.endClassMethod(getOrSet, beforeStart.next!,
              beforeParam.next!, beforeInitializers?.next, token);
          break;
        case DeclarationKind.Mixin:
          listener.endMixinMethod(getOrSet, beforeStart.next!,
              beforeParam.next!, beforeInitializers?.next, token);
          break;
        case DeclarationKind.Extension:
          if (optional(';', bodyStart) && externalToken == null) {
            reportRecoverableError(isOperator ? name.next! : name,
                codes.messageExtensionDeclaresAbstractMember);
          }
          listener.endExtensionMethod(getOrSet, beforeStart.next!,
              beforeParam.next!, beforeInitializers?.next, token);
          break;
        case DeclarationKind.TopLevel:
          throw "Internal error: TopLevel method.";
        case DeclarationKind.Enum:
          listener.endEnumMethod(getOrSet, beforeStart.next!, beforeParam.next!,
              beforeInitializers?.next, token);
          break;
      }
    }
    return token;
  }

  Token parseFactoryMethod(Token token, DeclarationKind kind, Token beforeStart,
      Token? externalToken, Token? staticOrCovariant, Token? varFinalOrConst) {
    Token factoryKeyword = token = token.next!;
    assert(optional('factory', factoryKeyword));

    if (!isValidNonRecordTypeReference(token.next!)) {
      // Recovery
      ModifierContext context = new ModifierContext(this)
        ..externalToken = externalToken
        ..staticOrCovariant = staticOrCovariant
        ..varFinalOrConst = varFinalOrConst;

      token = context.parseModifiersAfterFactory(token);

      externalToken = context.externalToken;
      staticOrCovariant = context.staticToken ?? context.covariantToken;
      varFinalOrConst = context.varFinalOrConst;
    }

    if (staticOrCovariant != null) {
      reportRecoverableErrorWithToken(
          staticOrCovariant, codes.templateExtraneousModifier);
    }
    if (varFinalOrConst != null && !optional('const', varFinalOrConst)) {
      reportRecoverableErrorWithToken(
          varFinalOrConst, codes.templateExtraneousModifier);
      varFinalOrConst = null;
    }

    listener.beginFactoryMethod(
        kind, beforeStart, externalToken, varFinalOrConst);
    token = ensureIdentifier(token, IdentifierContext.methodDeclaration);
    token = parseQualifiedRestOpt(
        token, IdentifierContext.methodDeclarationContinuation);
    token = parseMethodTypeVar(token);
    token = parseFormalParametersRequiredOpt(token, MemberKind.Factory);
    Token asyncToken = token.next!;
    token = parseAsyncModifierOpt(token);
    Token next = token.next!;
    if (!inPlainSync) {
      reportRecoverableError(asyncToken, codes.messageFactoryNotSync);
    }
    if (optional('=', next)) {
      if (externalToken != null) {
        reportRecoverableError(next, codes.messageExternalFactoryRedirection);
      }
      token = parseRedirectingFactoryBody(token);
    } else if (externalToken != null) {
      if (!optional(';', next)) {
        reportRecoverableError(next, codes.messageExternalFactoryWithBody);
      }
      token = parseFunctionBody(
        token,
        /* ofFunctionExpression = */ false,
        /* allowAbstract = */ true,
      );
    } else {
      if (varFinalOrConst != null && !optional('native', next)) {
        if (optional('const', varFinalOrConst)) {
          listener.handleConstFactory(varFinalOrConst);
        }
      }
      token = parseFunctionBody(
        token,
        /* ofFunctionExpression = */ false,
        /* allowAbstract = */ false,
      );
    }
    switch (kind) {
      case DeclarationKind.Class:
        listener.endClassFactoryMethod(
            beforeStart.next!, factoryKeyword, token);
        break;
      case DeclarationKind.Mixin:
        reportRecoverableError(
            factoryKeyword, codes.messageMixinDeclaresConstructor);
        listener.endMixinFactoryMethod(
            beforeStart.next!, factoryKeyword, token);
        break;
      case DeclarationKind.Extension:
        reportRecoverableError(
            factoryKeyword, codes.messageExtensionDeclaresConstructor);
        listener.endExtensionFactoryMethod(
            beforeStart.next!, factoryKeyword, token);
        break;
      case DeclarationKind.TopLevel:
        throw "Internal error: TopLevel factory.";
      case DeclarationKind.Enum:
        listener.endEnumFactoryMethod(beforeStart.next!, factoryKeyword, token);
        break;
    }
    return token;
  }

  Token parseOperatorName(Token token) {
    Token beforeToken = token;
    token = token.next!;
    assert(optional('operator', token));
    Token next = token.next!;
    if (next.isUserDefinableOperator) {
      if (computeTypeParamOrArg(token) != noTypeParamOrArg) {
        // `operator` is being used as an identifier.
        // For example: `int operator<T>(foo) => 0;`
        listener.handleIdentifier(token, IdentifierContext.methodDeclaration);
        return token;
      } else {
        listener.handleOperatorName(token, next);
        return next;
      }
    } else if (optional('(', next)) {
      return ensureIdentifier(beforeToken, IdentifierContext.operatorName);
    } else if (isUnaryMinus(next)) {
      // Recovery
      reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
      next = next.next!;
      listener.handleOperatorName(token, next);
      return next;
    } else {
      // Recovery
      // Scanner reports an error for `===` and `!==`.
      if (next.type != TokenType.EQ_EQ_EQ &&
          next.type != TokenType.BANG_EQ_EQ) {
        // The user has specified an invalid operator name.
        // Report the error, accept the invalid operator name, and move on.
        reportRecoverableErrorWithToken(next, codes.templateInvalidOperator);
      }
      listener.handleInvalidOperatorName(token, next);
      return next;
    }
  }

  Token parseFunctionExpression(Token token) {
    Token beginToken = token.next!;
    listener.beginFunctionExpression(beginToken);
    token = parseFormalParametersRequiredOpt(token, MemberKind.Local);
    token = parseAsyncOptBody(
        token, /* ofFunctionExpression = */ true, /* allowAbstract = */ false);
    listener.endFunctionExpression(beginToken, token.next!);
    return token;
  }

  Token parseFunctionLiteral(
      Token start,
      Token beforeName,
      Token name,
      TypeInfo typeInfo,
      TypeParamOrArgInfo typeParam,
      IdentifierContext context) {
    Token formals = typeParam.parseVariables(name, this);
    listener.beginNamedFunctionExpression(start.next!);
    typeInfo.parseType(start, this);
    return parseNamedFunctionRest(
        beforeName, start.next!, formals, /* isFunctionExpression = */ true);
  }

  /// Parses the rest of a named function declaration starting from its [name]
  /// but then skips any type parameters and continue parsing from [formals]
  /// (the formal parameters).
  ///
  /// If [isFunctionExpression] is true, this method parses the rest of named
  /// function expression which isn't legal syntax in Dart.  Useful for
  /// recovering from JavaScript code being pasted into a Dart program, as it
  /// will interpret `function foo() {}` as a named function expression with
  /// return type `function` and name `foo`.
  ///
  /// Precondition: the parser has previously generated these events:
  ///
  /// - Type variables.
  /// - `beginLocalFunctionDeclaration` if [isFunctionExpression] is false,
  ///   otherwise `beginNamedFunctionExpression`.
  /// - Return type.
  Token parseNamedFunctionRest(
      Token beforeName, Token begin, Token formals, bool isFunctionExpression) {
    Token token = beforeName.next!;
    listener.beginFunctionName(token);
    token =
        ensureIdentifier(beforeName, IdentifierContext.localFunctionDeclaration)
            .next!;
    if (isFunctionExpression) {
      reportRecoverableError(
          beforeName.next!, codes.messageNamedFunctionExpression);
    }
    listener.endFunctionName(begin, token);
    token = parseFormalParametersRequiredOpt(formals, MemberKind.Local);
    token = parseInitializersOpt(token);
    token = parseAsyncOptBody(
        token, isFunctionExpression, /* allowAbstract = */ false);
    if (isFunctionExpression) {
      listener.endNamedFunctionExpression(token);
    } else {
      listener.endLocalFunctionDeclaration(token);
    }
    return token;
  }

  /// Parses a function body optionally preceded by an async modifier (see
  /// [parseAsyncModifierOpt]).  This method is used in both expression context
  /// (when [ofFunctionExpression] is true) and statement context. In statement
  /// context (when [ofFunctionExpression] is false), and if the function body
  /// is on the form `=> expression`, a trailing semicolon is required.
  ///
  /// It's an error if there's no function body unless [allowAbstract] is true.
  Token parseAsyncOptBody(
      Token token, bool ofFunctionExpression, bool allowAbstract) {
    AsyncModifier savedAsyncModifier = asyncState;
    token = parseAsyncModifierOpt(token);
    token = parseFunctionBody(token, ofFunctionExpression, allowAbstract);
    asyncState = savedAsyncModifier;
    return token;
  }

  Token parseConstructorReference(
      Token token, ConstructorReferenceContext constructorReferenceContext,
      [TypeParamOrArgInfo? typeArg]) {
    // Note that there's an almost verbatim copy in [parseEnumElement] so
    // any change here should be added there too.
    Token start;
    start = ensureIdentifier(token, IdentifierContext.constructorReference);
    listener.beginConstructorReference(start);
    token = parseQualifiedRestOpt(
        start, IdentifierContext.constructorReferenceContinuation);
    typeArg ??= computeTypeParamOrArg(token);
    token = typeArg.parseArguments(token, this);
    Token? period = null;
    if (optional('.', token.next!)) {
      period = token.next!;
      token = ensureIdentifier(period,
          IdentifierContext.constructorReferenceContinuationAfterTypeArguments);
    } else {
      listener.handleNoConstructorReferenceContinuationAfterTypeArguments(
          token.next!);
    }
    listener.endConstructorReference(
        start, period, token.next!, constructorReferenceContext);
    return token;
  }

  Token parseRedirectingFactoryBody(Token token) {
    token = token.next!;
    assert(optional('=', token));
    listener.beginRedirectingFactoryBody(token);
    Token equals = token;
    token = parseConstructorReference(
        token, ConstructorReferenceContext.RedirectingFactory);
    token = ensureSemicolon(token);
    listener.endRedirectingFactoryBody(equals, token);
    return token;
  }

  Token skipFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    assert(!isExpression);
    token = skipAsyncModifier(token);
    Token next = token.next!;
    if (optional('native', next)) {
      Token nativeToken = next;
      // TODO(danrubel): skip the native clause rather than parsing it
      // or remove this code completely when we remove support
      // for the `native` clause.
      token = parseNativeClause(token);
      next = token.next!;
      if (optional(';', next)) {
        listener.handleNativeFunctionBodySkipped(nativeToken, next);
        return token.next!;
      }
      listener.handleNativeFunctionBodyIgnored(nativeToken, next);
      // Fall through to recover and skip function body
    }
    String? value = next.stringValue;
    if (identical(value, ';')) {
      token = next;
      if (!allowAbstract) {
        reportRecoverableError(token, codes.messageExpectedBody);
      }
      listener.handleNoFunctionBody(token);
    } else if (identical(value, '=>')) {
      token = parseExpression(next);
      // There ought to be a semicolon following the expression, but we check
      // before advancing in order to be consistent with the way the method
      // [parseFunctionBody] recovers when the semicolon is missing.
      if (optional(';', token.next!)) {
        token = token.next!;
      }
      listener.handleFunctionBodySkipped(token, /* isExpressionBody = */ true);
    } else if (identical(value, '=')) {
      token = next;
      reportRecoverableError(token, codes.messageExpectedBody);
      token = parseExpression(token);
      // There ought to be a semicolon following the expression, but we check
      // before advancing in order to be consistent with the way the method
      // [parseFunctionBody] recovers when the semicolon is missing.
      if (optional(';', token.next!)) {
        token = token.next!;
      }
      listener.handleFunctionBodySkipped(token, /* isExpressionBody = */ true);
    } else {
      token = skipBlock(token);
      listener.handleFunctionBodySkipped(token, /* isExpressionBody = */ false);
    }
    return token;
  }

  /// Parses a function body.  This method is used in both expression context
  /// (when [ofFunctionExpression] is true) and statement context. In statement
  /// context (when [ofFunctionExpression] is false), and if the function body
  /// is on the form `=> expression`, a trailing semicolon is required.
  ///
  /// It's an error if there's no function body unless [allowAbstract] is true.
  Token parseFunctionBody(
      Token token, bool ofFunctionExpression, bool allowAbstract) {
    Token next = token.next!;
    if (optional('native', next)) {
      Token nativeToken = next;
      token = parseNativeClause(token);
      next = token.next!;
      if (optional(';', next)) {
        listener.handleNativeFunctionBody(nativeToken, next);
        return next;
      }
      reportRecoverableError(next, codes.messageExternalMethodWithBody);
      listener.handleNativeFunctionBodyIgnored(nativeToken, next);
      // Ignore the native keyword and fall through to parse the body
    }
    if (optional(';', next)) {
      if (!allowAbstract) {
        reportRecoverableError(next, codes.messageExpectedBody);
      }
      listener.handleEmptyFunctionBody(next);
      return next;
    } else if (optional('=>', next)) {
      return parseExpressionFunctionBody(next, ofFunctionExpression);
    } else if (optional('=', next)) {
      // Recover from a bad factory method.
      reportRecoverableError(next, codes.messageExpectedBody);
      next = rewriter.insertToken(
          next, new SyntheticToken(TokenType.FUNCTION, next.next!.charOffset));
      Token begin = next;
      token = parseExpression(next);
      if (!ofFunctionExpression) {
        token = ensureSemicolon(token);
        listener.handleExpressionFunctionBody(begin, token);
      } else {
        listener.handleExpressionFunctionBody(begin, /* endToken = */ null);
      }
      return token;
    }
    Token begin = next;
    int statementCount = 0;
    if (!optional('{', next)) {
      // Recovery
      // If `return` used instead of `=>`, then report an error and continue
      if (optional('return', next)) {
        reportRecoverableError(next, codes.messageExpectedBody);
        next = rewriter.insertToken(next,
            new SyntheticToken(TokenType.FUNCTION, next.next!.charOffset));
        return parseExpressionFunctionBody(next, ofFunctionExpression);
      }
      // If there is a stray simple identifier in the function expression
      // because the user is typing (e.g. `() asy => null;`)
      // then report an error, skip the token, and continue parsing.
      if (next.isKeywordOrIdentifier && optional('=>', next.next!)) {
        reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
        return parseExpressionFunctionBody(next.next!, ofFunctionExpression);
      }
      if (next.isKeywordOrIdentifier && optional('{', next.next!)) {
        reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
        token = next;
        begin = next = token.next!;
        // Fall through to parse the block.
      } else {
        token = ensureBlock(token, codes.templateExpectedFunctionBody,
            /* missingBlockName = */ null);
        listener.handleInvalidFunctionBody(token);
        return token.endGroup!;
      }
    }

    LoopState savedLoopState = loopState;
    loopState = LoopState.OutsideLoop;
    listener.beginBlockFunctionBody(begin);
    token = next;
    while (notEofOrValue('}', token.next!)) {
      Token startToken = token.next!;
      token = parseStatement(token);
      if (identical(token.next!, startToken)) {
        // No progress was made, so we report the current token as being invalid
        // and move forward.
        reportRecoverableError(
            token, codes.templateUnexpectedToken.withArguments(token));
        token = token.next!;
      }
      ++statementCount;
    }
    token = token.next!;
    assert(token.isEof || optional('}', token));
    listener.endBlockFunctionBody(statementCount, begin, token);
    loopState = savedLoopState;
    return token;
  }

  Token parseExpressionFunctionBody(Token token, bool ofFunctionExpression) {
    assert(optional('=>', token));
    Token begin = token;
    token = parseExpression(token);
    if (!ofFunctionExpression) {
      token = ensureSemicolon(token);
      listener.handleExpressionFunctionBody(begin, token);
    } else {
      listener.handleExpressionFunctionBody(begin, /* endToken = */ null);
    }
    if (inGenerator) {
      listener.handleInvalidStatement(
          begin, codes.messageGeneratorReturnsValue);
    }
    return token;
  }

  Token skipAsyncModifier(Token token) {
    String? value = token.next!.stringValue;
    if (identical(value, 'async')) {
      token = token.next!;
      value = token.next!.stringValue;

      if (identical(value, '*')) {
        token = token.next!;
      }
    } else if (identical(value, 'sync')) {
      token = token.next!;
      value = token.next!.stringValue;

      if (identical(value, '*')) {
        token = token.next!;
      }
    }
    return token;
  }

  Token parseAsyncModifierOpt(Token token) {
    Token? async;
    Token? star;
    asyncState = AsyncModifier.Sync;
    Token next = token.next!;
    if (optional('async', next)) {
      async = token = next;
      next = token.next!;
      if (optional('*', next)) {
        asyncState = AsyncModifier.AsyncStar;
        star = next;
        token = next;
      } else {
        asyncState = AsyncModifier.Async;
      }
    } else if (optional('sync', next)) {
      async = token = next;
      next = token.next!;
      if (optional('*', next)) {
        asyncState = AsyncModifier.SyncStar;
        star = next;
        token = next;
      } else {
        reportRecoverableError(async, codes.messageInvalidSyncModifier);
      }
    }
    listener.handleAsyncModifier(async, star);
    if (!inPlainSync && optional(';', token.next!)) {
      reportRecoverableError(token.next!, codes.messageAbstractNotSync);
    }
    return token;
  }

  int statementDepth = 0;
  Token parseStatement(Token token) {
    if (statementDepth++ > 500) {
      // This happens for degenerate programs, for example, a lot of nested
      // if-statements. The language test deep_nesting2_negative_test, for
      // example, provokes this.
      return recoverFromStackOverflow(token);
    }
    Token result = parseStatementX(token);
    statementDepth--;
    return result;
  }

  Token parseStatementX(Token token) {
    if (identical(token.next!.kind, IDENTIFIER_TOKEN)) {
      if (optional(':', token.next!.next!)) {
        return parseLabeledStatement(token);
      }
      return parseExpressionStatementOrDeclarationAfterModifiers(
          token,
          token,
          /* lateToken = */ null,
          /* varFinalOrConst = */ null,
          /* typeInfo = */ null);
    }
    final String? value = token.next!.stringValue;
    if (identical(value, '{')) {
      // The scanner ensures that `{` always has a closing `}`.
      if (allowPatterns && optional('=', token.next!.endGroup!.next!)) {
        // Expression statement beginning with a pattern assignment
        return parseExpressionStatement(token);
      } else {
        return parseBlock(token, BlockKind.statement);
      }
    } else if (identical(value, 'return')) {
      return parseReturnStatement(token);
    } else if (identical(value, 'var') || identical(value, 'final')) {
      Token varOrFinal = token.next!;
      if (!isModifier(varOrFinal.next!)) {
        return parseExpressionStatementOrDeclarationAfterModifiers(varOrFinal,
            token, /* lateToken = */ null, varOrFinal, /* typeInfo = */ null);
      }
      return parseExpressionStatementOrDeclaration(token);
    } else if (identical(value, 'if')) {
      return parseIfStatement(token);
    } else if (identical(value, 'await') &&
        optional('for', token.next!.next!)) {
      return parseForStatement(token.next!, token.next!);
    } else if (identical(value, 'for')) {
      return parseForStatement(token, /* awaitToken = */ null);
    } else if (identical(value, 'rethrow')) {
      return parseRethrowStatement(token);
    } else if (identical(value, 'while')) {
      return parseWhileStatement(token);
    } else if (identical(value, 'do')) {
      return parseDoWhileStatement(token);
    } else if (identical(value, 'try')) {
      return parseTryStatement(token);
    } else if (identical(value, 'switch')) {
      return parseSwitchStatement(token);
    } else if (identical(value, 'break')) {
      return parseBreakStatement(token);
    } else if (identical(value, 'continue')) {
      return parseContinueStatement(token);
    } else if (identical(value, 'assert')) {
      return parseAssertStatement(token);
    } else if (identical(value, ';')) {
      return parseEmptyStatement(token);
    } else if (identical(value, 'yield')) {
      switch (asyncState) {
        case AsyncModifier.Sync:
          if (optional(':', token.next!.next!)) {
            return parseLabeledStatement(token);
          }
          if (looksLikeYieldStatement(token, AwaitOrYieldContext.Statement)) {
            // Recovery: looks like an expression preceded by `yield` but not
            // inside an Async or AsyncStar context. parseYieldStatement will
            // report the error.
            return parseYieldStatement(token);
          }
          return parseExpressionStatementOrDeclaration(token);

        case AsyncModifier.SyncStar:
        case AsyncModifier.AsyncStar:
          return parseYieldStatement(token);

        case AsyncModifier.Async:
          reportRecoverableError(token.next!, codes.messageYieldNotGenerator);
          return parseYieldStatement(token);
      }
    } else if (identical(value, 'const')) {
      return parseExpressionStatementOrConstDeclaration(token);
    } else if (identical(value, 'await')) {
      if (inPlainSync) {
        if (!looksLikeAwaitExpression(token, AwaitOrYieldContext.Statement)) {
          return parseExpressionStatementOrDeclaration(token);
        }
        // Recovery: looks like an expression preceded by `await`
        // but not inside an async context.
        // Fall through to parseExpressionStatement
        // and parseAwaitExpression will report the error.
      }
      return parseExpressionStatement(token);
    } else if (identical(value, 'set') && token.next!.next!.isIdentifier) {
      // Recovery: invalid use of `set`
      reportRecoverableErrorWithToken(
          token.next!, codes.templateUnexpectedToken);
      return parseStatementX(token.next!);
    } else if (token.next!.isIdentifier) {
      if (optional(':', token.next!.next!)) {
        return parseLabeledStatement(token);
      }
      return parseExpressionStatementOrDeclaration(token);
    } else {
      return parseExpressionStatementOrDeclaration(token);
    }
  }

  /// ```
  /// yieldStatement:
  ///   'yield' expression? ';'
  /// ;
  /// ```
  Token parseYieldStatement(Token token) {
    Token begin = token = token.next!;
    assert(optional('yield', token));
    listener.beginYieldStatement(begin);
    Token? starToken;
    if (optional('*', token.next!)) {
      starToken = token = token.next!;
    }
    token = parseExpression(token);
    token = ensureSemicolon(token);
    if (inPlainSync) {
      // `yield` is only allowed in generators; A recoverable error is already
      // reported in the "async" case in `parseStatementX`. Only the "sync" case
      // needs to be handled here.
      codes.MessageCode errorCode = codes.messageYieldNotGenerator;
      reportRecoverableError(begin, errorCode);
      // TODO(srawlins): Add tests in analyzer to ensure the AstBuilder
      //  correctly handles invalid yields, and that the error message is
      //  correctly plumbed through.
      listener.endInvalidYieldStatement(begin, starToken, token, errorCode);
    } else {
      listener.endYieldStatement(begin, starToken, token);
    }
    return token;
  }

  /// ```
  /// returnStatement:
  ///   'return' expression? ';'
  /// ;
  /// ```
  Token parseReturnStatement(Token token) {
    Token begin = token = token.next!;
    assert(optional('return', token));
    listener.beginReturnStatement(begin);
    Token next = token.next!;
    if (optional(';', next)) {
      listener.endReturnStatement(/* hasExpression = */ false, begin, next);
      return next;
    }
    token = parseExpression(token);
    token = ensureSemicolon(token);
    listener.endReturnStatement(/* hasExpression = */ true, begin, token);
    if (inGenerator) {
      listener.handleInvalidStatement(
          begin, codes.messageGeneratorReturnsValue);
    }
    return token;
  }

  /// ```
  /// label:
  ///   identifier ':'
  /// ;
  /// ```
  Token parseLabel(Token token) {
    assert(token.next!.isIdentifier);
    token = ensureIdentifier(token, IdentifierContext.labelDeclaration).next!;
    assert(optional(':', token));
    listener.handleLabel(token);
    return token;
  }

  /// ```
  /// statement:
  ///   label* nonLabelledStatement
  /// ;
  /// ```
  Token parseLabeledStatement(Token token) {
    Token next = token.next!;
    assert(next.isIdentifier);
    assert(optional(':', next.next!));
    int labelCount = 0;
    do {
      token = parseLabel(token);
      next = token.next!;
      labelCount++;
    } while (next.isIdentifier && optional(':', next.next!));
    listener.beginLabeledStatement(next, labelCount);
    token = parseStatement(token);
    listener.endLabeledStatement(labelCount);
    return token;
  }

  /// ```
  /// expressionStatement:
  ///   expression? ';'
  /// ;
  /// ```
  ///
  /// Note: This method can fail to make progress. If there is neither an
  /// expression nor a semi-colon, then a synthetic identifier and synthetic
  /// semicolon will be inserted before [token] and the semicolon will be
  /// returned.
  Token parseExpressionStatement(Token token) {
    // TODO(brianwilkerson): If the next token is not the start of a valid
    // expression, then this method shouldn't report that we have an expression
    // statement.
    token = parseExpression(token);
    token = ensureSemicolon(token);
    listener.handleExpressionStatement(token);
    return token;
  }

  int expressionDepth = 0;

  Token parseExpression(Token token) {
    if (expressionDepth++ > 500) {
      // This happens in degenerate programs, for example, with a lot of nested
      // list literals. This is provoked by, for example, the language test
      // deep_nesting1_negative_test.
      Token next = token.next!;
      reportRecoverableError(next, codes.messageStackOverflow);

      // Recovery
      Token? endGroup = next.endGroup;
      if (endGroup != null) {
        while (!next.isEof && !identical(next, endGroup)) {
          token = next;
          next = token.next!;
        }
      } else {
        while (!isOneOf(next, const [')', ']', '}', ';'])) {
          token = next;
          next = token.next!;
        }
      }
      if (!token.isEof) {
        token = rewriter.insertSyntheticIdentifier(token);
        listener.handleIdentifier(token, IdentifierContext.expression);
      }
    } else {
      if (allowPatterns && looksLikeOuterPatternEquals(token)) {
        token = parsePatternAssignment(token);
      } else {
        token = optional('throw', token.next!)
            ? parseThrowExpression(token, /* allowCascades = */ true)
            : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE,
                /* allowCascades = */ true, ConstantPatternContext.none);
      }
    }
    expressionDepth--;
    return token;
  }

  Token parseExpressionWithoutCascade(Token token) {
    return optional('throw', token.next!)
        ? parseThrowExpression(token, /* allowCascades = */ false)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE,
            /* allowCascades = */ false, ConstantPatternContext.none);
  }

  bool canParseAsConditional(Token question) {
    // We want to check if we can parse, not send events and permanently change
    // the token stream. Set it up so we can do that.
    Listener originalListener = listener;
    TokenStreamRewriter? originalRewriter = cachedRewriter;
    NullListener nullListener = listener = new NullListener();
    UndoableTokenStreamRewriter undoableTokenStreamRewriter =
        new UndoableTokenStreamRewriter();
    cachedRewriter = undoableTokenStreamRewriter;

    bool isConditional = false;

    Token afterExpression1 = parseExpressionWithoutCascade(question);
    if (!nullListener.hasErrors && optional(':', afterExpression1.next!)) {
      parseExpressionWithoutCascade(afterExpression1.next!);
      if (!nullListener.hasErrors) {
        // Now we know it's a conditional expression.
        isConditional = true;
      }
    }

    // Undo all changes and reset.
    undoableTokenStreamRewriter.undo();
    listener = originalListener;
    cachedRewriter = originalRewriter;

    return isConditional;
  }

  Token parseConditionalExpressionRest(Token token) {
    Token question = token = token.next!;
    assert(optional('?', question));
    listener.beginConditionalExpression(token);
    token = parseExpressionWithoutCascade(token);
    Token colon = ensureColon(token);
    listener.handleConditionalExpressionColon();
    token = parseExpressionWithoutCascade(colon);
    listener.endConditionalExpression(question, colon);
    return token;
  }

  Token parsePrecedenceExpression(Token token, int precedence,
      bool allowCascades, ConstantPatternContext constantPatternContext) {
    assert(precedence >= 1);
    assert(precedence <= SELECTOR_PRECEDENCE);
    token = parseUnaryExpression(token, allowCascades, constantPatternContext);
    Token bangToken = token;
    if (optional('!', token.next!)) {
      bangToken = token.next!;
    }
    TypeParamOrArgInfo typeArg = computeMethodTypeArguments(bangToken);
    if (typeArg != noTypeParamOrArg) {
      if (optional('!', bangToken)) {
        // For example `e!<int>()`, where [token] is before '<'.
        listener.handleNonNullAssertExpression(bangToken);
      }
      token = typeArg.parseArguments(bangToken, this);
      if (!optional('(', token.next!)) {
        // For example `e<a, b>;`, where [token] is before ';' or
        // `C<int>.new`, where [token] is before '.'.
        if (constantPatternContext != ConstantPatternContext.none) {
          reportRecoverableError(
              bangToken.next!, codes.messageInvalidConstantPatternGeneric);
        }
        listener.handleTypeArgumentApplication(bangToken.next!);
        typeArg = noTypeParamOrArg;
      }
    }

    return _parsePrecedenceExpressionLoop(
        precedence, allowCascades, typeArg, token, constantPatternContext);
  }

  Token _parsePrecedenceExpressionLoop(
      int precedence,
      bool allowCascades,
      TypeParamOrArgInfo typeArg,
      Token token,
      ConstantPatternContext constantPatternContext) {
    Token next = token.next!;
    TokenType type = next.type;
    int tokenLevel = _computePrecedence(next, forPattern: false);
    if (constantPatternContext != ConstantPatternContext.none) {
      // For error recovery we allow too much when parsing constant patterns,
      // so for the cases that shouldn't be parsed as expressions in this
      // context we return directly.
      if (type == TokenType.BANG) {
        if (tokenLevel == POSTFIX_PRECEDENCE) {
          // This is a suffixed ! which is a null assert pattern.
          return token;
        } else if (optional('?', next.next!)) {
          // This is a suffixed !? which is a null assert pattern in a null
          // check pattern.
          return token;
        }
      } else if (type == TokenType.AS) {
        // This is a suffixed `as` which is a case pattern.
        return token;
      }
    }
    if (constantPatternContext != ConstantPatternContext.none &&
        precedence <= tokenLevel &&
        tokenLevel < SELECTOR_PRECEDENCE) {
      // If we are parsing a constant pattern, only [SELECTOR_PRECEDENCE] is
      // supported but we allow for parsing [EQUALITY_PRECEDENCE] and higher for
      // better error recovery.
      if (constantPatternContext == ConstantPatternContext.explicit) {
        reportRecoverableError(
            token, codes.messageInvalidConstantPatternConstPrefix);
      } else if (tokenLevel <= MULTIPLICATIVE_PRECEDENCE) {
        reportRecoverableError(
            next,
            codes.templateInvalidConstantPatternBinary
                .withArguments(type.lexeme));
      } else {
        // These are prefix or postfix ++/-- and will not be constant
        // expressions, anyway.
        assert(
            tokenLevel == POSTFIX_PRECEDENCE || tokenLevel == PREFIX_PRECEDENCE,
            "Unexpected precedence level for $type: $tokenLevel");
      }
      // Avoid additional constant pattern errors.
      constantPatternContext = ConstantPatternContext.none;
    }
    bool enteredLoop = false;
    for (int level = tokenLevel; level >= precedence; --level) {
      int lastBinaryExpressionLevel = -1;
      Token? lastCascade;
      while (identical(tokenLevel, level)) {
        enteredLoop = true;
        Token operator = next;
        if (identical(tokenLevel, CASCADE_PRECEDENCE)) {
          if (!allowCascades) {
            return token;
          } else if (lastCascade != null && optional('?..', next)) {
            reportRecoverableError(
                next, codes.messageNullAwareCascadeOutOfOrder);
          }
          lastCascade = next;
          token = parseCascadeExpression(token);
        } else if (identical(tokenLevel, ASSIGNMENT_PRECEDENCE)) {
          // Right associative, so we recurse at the same precedence
          // level.
          Token next = token.next!;
          if (optional(">=", next.next!)) {
            // Special case use of triple-shift in cases where it isn't
            // enabled.
            reportExperimentNotEnabled(
                ExperimentalFlag.tripleShift, next, next.next!);
            assert(next == operator);
            next = rewriter.replaceNextTokensWithSyntheticToken(
                token, /* count = */ 2, TokenType.GT_GT_GT_EQ);
            operator = next;
          }
          token = optional('throw', next.next!)
              ? parseThrowExpression(next, /* allowCascades = */ false)
              : parsePrecedenceExpression(
                  next, level, allowCascades, ConstantPatternContext.none);
          listener.handleAssignmentExpression(operator);
        } else if (identical(tokenLevel, POSTFIX_PRECEDENCE)) {
          if ((identical(type, TokenType.PLUS_PLUS)) ||
              (identical(type, TokenType.MINUS_MINUS))) {
            listener.handleUnaryPostfixAssignmentExpression(token.next!);
            token = next;
          } else if (identical(type, TokenType.BANG)) {
            listener.handleNonNullAssertExpression(next);
            token = next;
          }
        } else if (identical(tokenLevel, SELECTOR_PRECEDENCE)) {
          if (identical(type, TokenType.PERIOD) ||
              identical(type, TokenType.QUESTION_PERIOD)) {
            // Left associative, so we recurse at the next higher precedence
            // level. However, SELECTOR_PRECEDENCE is the highest level, so we
            // should just call [parseUnaryExpression] directly. However, a
            // unary expression isn't legal after a period, so we call
            // [parsePrimary] instead.
            token = parsePrimary(
                token.next!,
                IdentifierContext.expressionContinuation,
                constantPatternContext);
            listener.handleEndingBinaryExpression(operator);

            Token bangToken = token;
            if (optional('!', token.next!)) {
              bangToken = token.next!;
            }
            typeArg = computeMethodTypeArguments(bangToken);
            if (typeArg != noTypeParamOrArg) {
              // For example e.f<T>(c), where token is before '<'.
              if (optional('!', bangToken)) {
                listener.handleNonNullAssertExpression(bangToken);
              }
              token = typeArg.parseArguments(bangToken, this);
              if (!optional('(', token.next!)) {
                if (constantPatternContext != ConstantPatternContext.none) {
                  reportRecoverableError(bangToken.next!,
                      codes.messageInvalidConstantPatternGeneric);
                }
                listener.handleTypeArgumentApplication(bangToken.next!);
                typeArg = noTypeParamOrArg;
              }
            }
          } else if (identical(type, TokenType.OPEN_PAREN) ||
              identical(type, TokenType.OPEN_SQUARE_BRACKET)) {
            token = parseArgumentOrIndexStar(
                token, typeArg, /* checkedNullAware = */ false);
          } else if (identical(type, TokenType.QUESTION)) {
            // We have determined selector precedence so this is a null-aware
            // bracket operator.
            token = parseArgumentOrIndexStar(
                token, typeArg, /* checkedNullAware = */ true);
          } else if (identical(type, TokenType.INDEX)) {
            rewriteSquareBrackets(token);
            token = parseArgumentOrIndexStar(
                token, noTypeParamOrArg, /* checkedNullAware = */ false);
          } else if (identical(type, TokenType.BANG)) {
            listener.handleNonNullAssertExpression(token.next!);
            token = next;
          } else {
            // Recovery
            reportRecoverableErrorWithToken(
                token.next!, codes.templateUnexpectedToken);
            token = next;
          }
        } else if (identical(type, TokenType.IS)) {
          token = parseIsOperatorRest(token);
        } else if (identical(type, TokenType.AS)) {
          token = parseAsOperatorRest(token);
        } else if (identical(type, TokenType.QUESTION)) {
          token = parseConditionalExpressionRest(token);
        } else {
          if (level == EQUALITY_PRECEDENCE || level == RELATIONAL_PRECEDENCE) {
            // We don't allow (a == b == c) or (a < b < c).
            if (lastBinaryExpressionLevel == level) {
              // Report an error, then continue parsing as if it is legal.
              reportRecoverableError(
                  next, codes.messageEqualityCannotBeEqualityOperand);
            } else {
              // Set a flag to catch subsequent binary expressions of this type.
              lastBinaryExpressionLevel = level;
            }
          }
          if (optional(">>", next) && next.charEnd == next.next!.charOffset) {
            if (optional(">", next.next!)) {
              // Special case use of triple-shift in cases where it isn't
              // enabled.
              reportExperimentNotEnabled(
                  ExperimentalFlag.tripleShift, next, next.next!);
              assert(next == operator);
              next = rewriter.replaceNextTokensWithSyntheticToken(
                  token, /* count = */ 2, TokenType.GT_GT_GT);
              operator = next;
            }
          }
          listener.beginBinaryExpression(next);
          // Left associative, so we recurse at the next higher
          // precedence level.
          token = parsePrecedenceExpression(token.next!, level + 1,
              allowCascades, ConstantPatternContext.none);
          listener.endBinaryExpression(operator);
        }
        next = token.next!;
        type = next.type;
        tokenLevel = _computePrecedence(next, forPattern: false);
        if (constantPatternContext != ConstantPatternContext.none) {
          // For error recovery we allow too much when parsing constant
          // patterns, so for the cases that shouldn't be parsed as expressions
          // in this context we break out of the parsing loop directly.
          if (type == TokenType.BANG) {
            if (tokenLevel == POSTFIX_PRECEDENCE) {
              // This is a suffixed ! which is a null assert pattern.
              return token;
            } else if (optional('?', next.next!)) {
              // This is a suffixed !? which is a null assert pattern in a null
              // check pattern.
              return token;
            }
          } else if (type == TokenType.AS) {
            // This is a suffixed `as` which is a case pattern.
            return token;
          }
        }
      }
      if (_recoverAtPrecedenceLevel && !_currentlyRecovering) {
        // Attempt recovery
        if (_attemptPrecedenceLevelRecovery(
            token, precedence, level, allowCascades, typeArg)) {
          // Recovered - try again at same level with the replacement token.
          level++;
          next = token.next!;
          type = next.type;
          tokenLevel = _computePrecedence(next, forPattern: false);
        }
      }
    }

    if (!enteredLoop && _recoverAtPrecedenceLevel && !_currentlyRecovering) {
      // Attempt recovery
      if (_attemptPrecedenceLevelRecovery(
          token, precedence, /* currentLevel = */ -1, allowCascades, typeArg)) {
        return _parsePrecedenceExpressionLoop(precedence, allowCascades,
            typeArg, token, ConstantPatternContext.none);
      }
    }
    return token;
  }

  /// Attempt a recovery where [token.next] is replaced.
  bool _attemptPrecedenceLevelRecovery(Token token, int precedence,
      int currentLevel, bool allowCascades, TypeParamOrArgInfo typeArg) {
    // Attempt recovery.
    _recoverAtPrecedenceLevel = false;
    assert(_tokenRecoveryReplacements.containsKey(token.next!.lexeme));
    List<TokenType> replacements =
        _tokenRecoveryReplacements[token.next!.lexeme]!;
    for (int i = 0; i < replacements.length; i++) {
      TokenType replacement = replacements[i];

      if (currentLevel >= 0) {
        // Check that the new precedence and currentLevel would have accepted
        // this replacement here.
        int newLevel = replacement.precedence;
        // The loop it would normally have gone through is something like
        // for (; ; --level) {
        //   while (identical(tokenLevel, level)) {
        //   }
        // }
        // So if the new tokens level <= the "old" (current) level, [level] (in
        // the above code snippet) would get down to it and accept it.
        // But if the new tokens level > the "old" (current) level, normally we
        // would never get to it - so we shouldn't here either.
        // As the loop starts by taking the first tokens tokenLevel as level,
        // recursing below won't weed that out so we need to do it here.
        if (newLevel > currentLevel) continue;
      }

      _currentlyRecovering = true;
      Listener originalListener = listener;
      TokenStreamRewriter? originalRewriter = cachedRewriter;
      NullListener nullListener = listener = new NullListener();
      UndoableTokenStreamRewriter undoableTokenStreamRewriter =
          new UndoableTokenStreamRewriter();
      cachedRewriter = undoableTokenStreamRewriter;
      rewriter.replaceNextTokenWithSyntheticToken(token, replacement);
      bool acceptRecovery = false;
      Token afterExpression = _parsePrecedenceExpressionLoop(precedence,
          allowCascades, typeArg, token, ConstantPatternContext.none);
      Token afterExpressionNext = afterExpression.next!;

      if (!nullListener.hasErrors &&
          token != afterExpression &&
          (isOneOfOrEof(afterExpressionNext,
                  const [';', ',', ')', '{', '}', '|', '||', '&', '&&']) ||
              (afterExpressionNext.type == TokenType.IDENTIFIER &&
                  _tokenRecoveryReplacements
                      .containsKey(afterExpressionNext.lexeme)))) {
        // Seems good!
        acceptRecovery = true;
      }

      // Undo all changes and reset.
      _currentlyRecovering = false;
      undoableTokenStreamRewriter.undo();
      listener = originalListener;
      cachedRewriter = originalRewriter;

      if (acceptRecovery) {
        // Report and redo recovery.
        reportRecoverableError(
            token.next!,
            codes.templateBinaryOperatorWrittenOut
                .withArguments(token.next!.lexeme, replacement.lexeme));
        rewriter.replaceNextTokenWithSyntheticToken(token, replacement);
        return true;
      }
    }

    return false;
  }

  bool _recoverAtPrecedenceLevel = false;
  bool _currentlyRecovering = false;
  static const Map<String, List<TokenType>> _tokenRecoveryReplacements = const {
    // E.g. in Kotlin binary operators are written out, see.
    // https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/-int/.
    "xor": [
      TokenType.CARET,
    ],
    "and": [
      TokenType.AMPERSAND,
      TokenType.AMPERSAND_AMPERSAND,
    ],
    "or": [
      TokenType.BAR,
      TokenType.BAR_BAR,
    ],
    "shl": [
      TokenType.LT_LT,
    ],
    "shr": [
      TokenType.GT_GT,
    ],
  };

  /// Computes the precedence of [token].  [forPattern] indicates whether a
  /// pattern is being parsed (this changes the precedence of a few operators).
  int _computePrecedence(Token token, {required bool forPattern}) {
    TokenType type = token.type;
    if (identical(type, TokenType.BANG)) {
      // The '!' has prefix precedence but here it's being used as a
      // postfix operator to assert the expression has a non-null value.
      TokenType nextType = token.next!.type;
      if (identical(nextType, TokenType.PERIOD) ||
          identical(nextType, TokenType.QUESTION) ||
          identical(nextType, TokenType.OPEN_PAREN) ||
          identical(nextType, TokenType.OPEN_SQUARE_BRACKET) ||
          identical(nextType, TokenType.QUESTION_PERIOD)) {
        return SELECTOR_PRECEDENCE;
      }
      return POSTFIX_PRECEDENCE;
    } else if (identical(type, TokenType.GT_GT)) {
      // ">>" followed by ">=" (without space between tokens) should for
      // recovery be seen as ">>>=".
      TokenType nextType = token.next!.type;
      if (identical(nextType, TokenType.GT_EQ) &&
          token.charEnd == token.next!.offset) {
        return TokenType.GT_GT_GT_EQ.precedence;
      }
    } else if (identical(type, TokenType.QUESTION)) {
      if (forPattern) {
        // The '?' has conditional precedence but here it's being used as a
        // postfix operator as part of a pattern, so it should have selector
        // precedence.
        return SELECTOR_PRECEDENCE;
      } else if (optional('[', token.next!)) {
        // "?[" can be a null-aware bracket or a conditional. If it's a
        // null-aware bracket it has selector precedence.
        bool isConditional = canParseAsConditional(token);
        if (!isConditional) {
          return SELECTOR_PRECEDENCE;
        }
      }
    } else if (identical(type, TokenType.IDENTIFIER)) {
      // An identifier at this point is not right. So some recovery is going to
      // happen soon. The question is, if we can do a better recovery here.
      if (!_currentlyRecovering &&
          _tokenRecoveryReplacements.containsKey(token.lexeme)) {
        _recoverAtPrecedenceLevel = true;
      }
    }

    return type.precedence;
  }

  Token parseCascadeExpression(Token token) {
    Token cascadeOperator = token = token.next!;
    assert(optional('..', cascadeOperator) || optional('?..', cascadeOperator));
    listener.beginCascade(cascadeOperator);
    if (optional('[', token.next!)) {
      token = parseArgumentOrIndexStar(
          token, noTypeParamOrArg, /* checkedNullAware = */ false);
    } else {
      token = parseSend(token, IdentifierContext.expressionContinuation,
          ConstantPatternContext.none);
      listener.handleEndingBinaryExpression(cascadeOperator);
    }
    Token next = token.next!;
    Token mark;
    do {
      mark = token;
      if (optional('.', next) || optional('?.', next)) {
        Token period = next;
        token = parseSend(next, IdentifierContext.expressionContinuation,
            ConstantPatternContext.none);
        next = token.next!;
        listener.handleEndingBinaryExpression(period);
      } else if (optional('!', next)) {
        listener.handleNonNullAssertExpression(next);
        token = next;
        next = token.next!;
      }
      TypeParamOrArgInfo typeArg = computeMethodTypeArguments(token);
      if (typeArg != noTypeParamOrArg) {
        // For example a(b)..<T>(c), where token is '<'.
        token = typeArg.parseArguments(token, this);
        next = token.next!;
        if (!optional('(', next)) {
          listener.handleTypeArgumentApplication(token.next!);
          typeArg = noTypeParamOrArg;
        }
      }
      TokenType nextType = next.type;
      if (identical(nextType, TokenType.INDEX)) {
        // If we don't split the '[]' here we will stop parsing it as a cascade
        // and either split it later (parsing it wrong) or inserting ; before it
        // (also wrong).
        // See also https://github.com/dart-lang/sdk/issues/42267.
        rewriteSquareBrackets(token);
      }
      token = parseArgumentOrIndexStar(
          token, typeArg, /* checkedNullAware = */ false);
      next = token.next!;
    } while (!identical(mark, token));

    if (identical(next.type.precedence, ASSIGNMENT_PRECEDENCE)) {
      Token assignment = next;
      token = parseExpressionWithoutCascade(next);
      listener.handleAssignmentExpression(assignment);
    }
    listener.endCascade();
    return token;
  }

  Token parseUnaryExpression(Token token, bool allowCascades,
      ConstantPatternContext constantPatternContext) {
    String? value = token.next!.stringValue;
    // Prefix:
    if (identical(value, 'await')) {
      if (inPlainSync) {
        if (!looksLikeAwaitExpression(
            token, AwaitOrYieldContext.UnaryExpression)) {
          return parsePrimary(
              token, IdentifierContext.expression, ConstantPatternContext.none);
        }
        // Recovery: Looks like an expression preceded by `await`.
        // Fall through and let parseAwaitExpression report the error.
      }
      return parseAwaitExpression(token, allowCascades);
    } else if (identical(value, '+')) {
      // Dart no longer allows prefix-plus.
      rewriteAndRecover(
          token,
          // TODO(danrubel): Consider reporting "missing identifier" instead.
          codes.messageUnsupportedPrefixPlus,
          new SyntheticStringToken(
              TokenType.IDENTIFIER, '', token.next!.offset));
      return parsePrimary(
          token, IdentifierContext.expression, constantPatternContext);
    } else if ((identical(value, '!')) || (identical(value, '~'))) {
      Token operator = token.next!;
      if (constantPatternContext != ConstantPatternContext.none) {
        reportRecoverableError(operator,
            codes.templateInvalidConstantPatternUnary.withArguments(value!));
      }
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(operator, POSTFIX_PRECEDENCE,
          allowCascades, ConstantPatternContext.none);
      listener.handleUnaryPrefixExpression(operator);
      return token;
    } else if (identical(value, '-')) {
      Token operator = token.next!;
      if (constantPatternContext == ConstantPatternContext.explicit) {
        reportRecoverableError(
            operator, codes.messageInvalidConstantPatternConstPrefix);
        // Avoid subsequent errors.
        constantPatternContext = ConstantPatternContext.none;
      }
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(
          operator,
          POSTFIX_PRECEDENCE,
          allowCascades,
          constantPatternContext != ConstantPatternContext.none
              ? ConstantPatternContext.numericLiteralOnly
              : ConstantPatternContext.none);
      listener.handleUnaryPrefixExpression(operator);
      return token;
    } else if ((identical(value, '++')) || identical(value, '--')) {
      // TODO(ahe): Validate this is used correctly.
      Token operator = token.next!;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(operator, POSTFIX_PRECEDENCE,
          allowCascades, ConstantPatternContext.none);
      listener.handleUnaryPrefixAssignmentExpression(operator);
      return token;
    } else if (useImplicitCreationExpression && token.next!.isIdentifier) {
      Token identifier = token.next!;
      if (optional(".", identifier.next!)) {
        identifier = identifier.next!.next!;
      }
      if (identifier.isIdentifier) {
        // Looking at `identifier ('.' identifier)?`.
        if (optional("<", identifier.next!)) {
          TypeParamOrArgInfo typeArg = computeTypeParamOrArg(identifier);
          if (typeArg != noTypeParamOrArg) {
            Token endTypeArguments = typeArg.skip(identifier);
            Token afterTypeArguments = endTypeArguments.next!;
            if (optional(".", afterTypeArguments)) {
              Token afterPeriod = afterTypeArguments.next!;
              if (_isNewOrIdentifier(afterPeriod) &&
                  optional('(', afterPeriod.next!)) {
                return parseImplicitCreationExpression(
                    token, identifier.next!, typeArg);
              }
            }
          }
        }
      }
    }
    return parsePrimary(
        token, IdentifierContext.expression, constantPatternContext);
  }

  Token parseArgumentOrIndexStar(
      Token token, TypeParamOrArgInfo typeArg, bool checkedNullAware) {
    Token next = token.next!;
    final Token beginToken = next;
    while (true) {
      bool potentialNullAware =
          (optional('?', next) && optional('[', next.next!));
      if (potentialNullAware && !checkedNullAware) {
        // While it's a potential null aware index it hasn't been checked.
        // It might be a conditional expression.
        assert(optional('?', next));
        bool isConditional = canParseAsConditional(next);
        if (isConditional) potentialNullAware = false;
      }

      if (optional('[', next) || potentialNullAware) {
        assert(typeArg == noTypeParamOrArg);
        Token openSquareBracket = next;
        Token? question;
        if (optional('?', next)) {
          question = next;
          next = next.next!;
          openSquareBracket = next;
          assert(optional('[', openSquareBracket));
        }
        bool old = mayParseFunctionExpressions;
        mayParseFunctionExpressions = true;
        token = parseExpression(next);
        next = token.next!;
        mayParseFunctionExpressions = old;
        if (!optional(']', next)) {
          // Recovery
          reportRecoverableError(
              next, codes.templateExpectedButGot.withArguments(']'));
          // Scanner ensures a closing ']'
          Token endGroup = openSquareBracket.endGroup!;
          if (endGroup.isSynthetic) {
            // Scanner inserted closing ']' in the wrong place, so move it.
            next = rewriter.moveSynthetic(token, endGroup);
          } else {
            // Skip over unexpected tokens to where the user placed the `]`.
            next = endGroup;
          }
        }
        listener.handleIndexedExpression(question, openSquareBracket, next);
        token = next;
        Token bangToken = token;
        if (optional('!', token.next!)) {
          bangToken = token.next!;
        }
        typeArg = computeMethodTypeArguments(bangToken);
        if (typeArg != noTypeParamOrArg) {
          // For example a[b]<T>(c), where token is before '<'.
          if (optional('!', bangToken)) {
            listener.handleNonNullAssertExpression(bangToken);
          }
          token = typeArg.parseArguments(bangToken, this);
          if (!optional('(', token.next!)) {
            listener.handleTypeArgumentApplication(bangToken.next!);
            typeArg = noTypeParamOrArg;
          }
        }
        next = token.next!;
      } else if (optional('(', next)) {
        if (typeArg == noTypeParamOrArg) {
          listener.handleNoTypeArguments(next);
        }
        token = parseArguments(token);
        listener.handleSend(beginToken, token);
        Token bangToken = token;
        if (optional('!', token.next!)) {
          bangToken = token.next!;
        }
        typeArg = computeMethodTypeArguments(bangToken);
        if (typeArg != noTypeParamOrArg) {
          // For example a(b)<T>(c), where token is before '<'.
          if (optional('!', bangToken)) {
            listener.handleNonNullAssertExpression(bangToken);
          }
          token = typeArg.parseArguments(bangToken, this);
          if (!optional('(', token.next!)) {
            listener.handleTypeArgumentApplication(bangToken.next!);
            typeArg = noTypeParamOrArg;
          }
        }
        next = token.next!;
      } else {
        break;
      }
    }
    return token;
  }

  Token parsePrimary(Token token, IdentifierContext context,
      ConstantPatternContext constantPatternContext) {
    _tryRewriteNewToIdentifier(token, context);
    final Token next = token.next!;
    final int kind = next.kind;
    if (kind == IDENTIFIER_TOKEN) {
      if (constantPatternContext == ConstantPatternContext.numericLiteralOnly) {
        reportRecoverableError(
            next, codes.messageInvalidConstantPatternNegation);
        // Avoid subsequent errors.
        constantPatternContext == ConstantPatternContext.none;
      }
      return parseSendOrFunctionLiteral(token, context, constantPatternContext);
    } else if (kind == INT_TOKEN || kind == HEXADECIMAL_TOKEN) {
      if (constantPatternContext == ConstantPatternContext.explicit) {
        reportRecoverableError(
            next, codes.messageInvalidConstantPatternConstPrefix);
      }
      return parseLiteralInt(token);
    } else if (kind == DOUBLE_TOKEN) {
      if (constantPatternContext == ConstantPatternContext.explicit) {
        reportRecoverableError(
            next, codes.messageInvalidConstantPatternConstPrefix);
      }
      return parseLiteralDouble(token);
    } else if (kind == STRING_TOKEN) {
      if (constantPatternContext == ConstantPatternContext.explicit) {
        reportRecoverableError(
            next, codes.messageInvalidConstantPatternConstPrefix);
      } else if (constantPatternContext ==
          ConstantPatternContext.numericLiteralOnly) {
        reportRecoverableError(
            next, codes.messageInvalidConstantPatternNegation);
      }
      return parseLiteralString(token);
    } else if (kind == HASH_TOKEN) {
      if (constantPatternContext == ConstantPatternContext.explicit) {
        reportRecoverableError(
            next, codes.messageInvalidConstantPatternConstPrefix);
      } else if (constantPatternContext ==
          ConstantPatternContext.numericLiteralOnly) {
        reportRecoverableError(
            next, codes.messageInvalidConstantPatternNegation);
      }
      return parseLiteralSymbol(token);
    } else if (kind == KEYWORD_TOKEN) {
      final String? value = next.stringValue;
      if (identical(value, "true") || identical(value, "false")) {
        if (constantPatternContext == ConstantPatternContext.explicit) {
          reportRecoverableError(
              next, codes.messageInvalidConstantPatternConstPrefix);
        } else if (constantPatternContext ==
            ConstantPatternContext.numericLiteralOnly) {
          reportRecoverableError(
              next, codes.messageInvalidConstantPatternNegation);
        }
        return parseLiteralBool(token);
      } else if (identical(value, "null")) {
        if (constantPatternContext == ConstantPatternContext.explicit) {
          reportRecoverableError(
              next, codes.messageInvalidConstantPatternConstPrefix);
        } else if (constantPatternContext ==
            ConstantPatternContext.numericLiteralOnly) {
          reportRecoverableError(
              next, codes.messageInvalidConstantPatternNegation);
        }
        return parseLiteralNull(token);
      } else if (identical(value, "this")) {
        return parseThisExpression(token, context);
      } else if (identical(value, "super")) {
        return parseSuperExpression(token, context);
      } else if (identical(value, "augment") &&
          optional('super', token.next!.next!)) {
        return parseAugmentSuperExpression(token, context);
      } else if (identical(value, "new")) {
        return parseNewExpression(token);
      } else if (identical(value, "const")) {
        if (constantPatternContext == ConstantPatternContext.explicit) {
          reportRecoverableError(
              next, codes.messageInvalidConstantPatternDuplicateConst);
        }
        return parseConstExpression(token);
      } else if (identical(value, "void")) {
        return parseSendOrFunctionLiteral(
            token, context, constantPatternContext);
      } else if (!inPlainSync &&
          (identical(value, "yield") || identical(value, "async"))) {
        // Fall through to the recovery code.
      } else if (identical(value, "assert")) {
        return parseAssert(token, Assert.Expression);
      } else if (allowPatterns && identical(value, "switch")) {
        return parseSwitchExpression(token);
      } else if (next.isIdentifier) {
        if (constantPatternContext ==
            ConstantPatternContext.numericLiteralOnly) {
          reportRecoverableError(
              next, codes.messageInvalidConstantPatternNegation);
          // Avoid subsequent errors.
          constantPatternContext == ConstantPatternContext.none;
        }
        return parseSendOrFunctionLiteral(
            token, context, constantPatternContext);
      } else if (identical(value, "return")) {
        // Recovery
        token = token.next!;
        reportRecoverableErrorWithToken(token, codes.templateUnexpectedToken);
        return parsePrimary(token, context, ConstantPatternContext.none);
      } else {
        // Fall through to the recovery code.
      }
    } else if (kind == OPEN_PAREN_TOKEN) {
      return parseParenthesizedExpressionFunctionLiteralOrRecordLiteral(
          token, constantPatternContext);
    } else if (kind == OPEN_SQUARE_BRACKET_TOKEN ||
        optional('[]', token.next!)) {
      listener.handleNoTypeArguments(token.next!);
      return parseLiteralListSuffix(token, /* constKeyword = */ null);
    } else if (kind == OPEN_CURLY_BRACKET_TOKEN) {
      listener.handleNoTypeArguments(token.next!);
      return parseLiteralSetOrMapSuffix(token, /* constKeyword = */ null);
    } else if (kind == LT_TOKEN) {
      return parseLiteralListSetMapOrFunction(token, /* constKeyword = */ null);
    } else {
      // Fall through to the recovery code.
    }
    //
    // Recovery code.
    //
    return parseSend(token, context, constantPatternContext);
  }

  Token parseParenthesizedExpressionFunctionLiteralOrRecordLiteral(
      Token token, ConstantPatternContext constantPatternContext) {
    Token next = token.next!;
    assert(optional('(', next));

    if (mayParseFunctionExpressions) {
      Token nextToken = next.endGroup!.next!;
      int kind = nextToken.kind;
      if ((identical(kind, FUNCTION_TOKEN) ||
          identical(kind, OPEN_CURLY_BRACKET_TOKEN))) {
        listener.handleNoTypeVariables(next);
        return parseFunctionExpression(token);
      } else if (identical(kind, KEYWORD_TOKEN) ||
          identical(kind, IDENTIFIER_TOKEN)) {
        if (optional('async', nextToken) || optional('sync', nextToken)) {
          listener.handleNoTypeVariables(next);
          return parseFunctionExpression(token);
        }
        // Recovery
        // If there is a stray simple identifier in the function expression
        // because the user is typing (e.g. `() asy {}`) then continue parsing
        // and allow parseFunctionExpression to report an unexpected token.
        kind = nextToken.next!.kind;
        if ((identical(kind, FUNCTION_TOKEN) ||
            identical(kind, OPEN_CURLY_BRACKET_TOKEN))) {
          listener.handleNoTypeVariables(next);
          return parseFunctionExpression(token);
        }
      }
    }
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseParenthesizedExpressionOrRecordLiteral(
        token, /* constKeywordForRecord = */ null, constantPatternContext);
    mayParseFunctionExpressions = old;
    return token;
  }

  /// Parses an expression inside parentheses that represents the condition part
  /// of an if-statement, if-element, do-while statement, or while statement, or
  /// the scrutinee part of a switch statement.  [token] is the token before
  /// where the `(` is expected.
  ///
  /// [allowCase] indicates whether the condition may optionally be followed
  /// by a caseHead.
  Token ensureParenthesizedCondition(Token token, {required bool allowCase}) {
    Token openParen = token.next!;
    if (!optional('(', openParen)) {
      // Recover
      reportRecoverableError(
          openParen, codes.templateExpectedToken.withArguments('('));
      openParen = rewriter.insertParens(token, /* includeIdentifier = */ false);
    }
    token = parseExpressionInParenthesisRest(openParen, allowCase: allowCase);
    return token;
  }

  /// Parse either a parenthesized expression or a record literal.
  /// If [constKeywordForRecord] is non-null it is forced to be a record
  /// literal and an error will be issued if there is no trailing comma.
  Token parseParenthesizedExpressionOrRecordLiteral(
      Token token,
      Token? constKeywordForRecord,
      ConstantPatternContext constantPatternContext) {
    Token begin = token.next!;
    assert(optional('(', begin));
    listener.beginParenthesizedExpressionOrRecordLiteral(begin);

    // For parsing of parenthesized expression we need parity with
    // parseExpressionInParenthesisRest used in ensureParenthesizedCondition.

    token = begin;
    int count = 0;
    bool wasRecord = constKeywordForRecord != null;
    bool wasValidRecord = false;
    Token? illegalTrailingComma;
    while (true) {
      Token next = token.next!;
      if (optional(')', next)) {
        if (count == 0) {
          wasRecord = true;
        }
        break;
      } else if (count == 0 &&
          optional(',', next) &&
          optional(')', next.next!)) {
        illegalTrailingComma = next;
        wasRecord = true;
        token = next;
        break;
      }
      Token? colon = null;
      if (optional(':', next.next!) || /* recovery */ optional(':', next)) {
        // Record with named expression.
        wasRecord = true;
        token = ensureIdentifier(
          token,
          IdentifierContext.namedRecordFieldReference,
        ).next!;
        colon = token;
        wasValidRecord = true;
      }
      token = parseExpression(token);
      next = token.next!;
      if (colon != null) listener.handleNamedRecordField(colon);
      ++count;
      if (!optional(',', next)) {
        // TODO(jensj): Possible more specific recovery.
        break;
      } else {
        // It is a comma, i.e. it's a record.
        wasRecord = true;
        wasValidRecord = true;
      }
      token = next;
    }
    token = ensureCloseParen(token, begin);
    assert(optional(')', token));

    assert(wasRecord || count <= 1);

    if (wasRecord) {
      if (count == 0 && illegalTrailingComma != null) {
        // Empty record literal with a comma `(,)`.
        reportRecoverableError(illegalTrailingComma,
            codes.messageRecordLiteralZeroFieldsWithTrailingComma);
      } else if (count == 1 && !wasValidRecord) {
        reportRecoverableError(
            token, codes.messageRecordLiteralOnePositionalFieldNoTrailingComma);
      } else if (count == 0 &&
          constantPatternContext != ConstantPatternContext.none) {
        reportRecoverableError(
            begin, codes.messageInvalidConstantPatternEmptyRecordLiteral);
      }
      listener.endRecordLiteral(begin, count, constKeywordForRecord);
    } else {
      listener.endParenthesizedExpression(begin);
    }

    return token;
  }

  /// Parses an expression inside parentheses that represents the condition part
  /// of an if-statement, if-element, do-while statement, or while statement, or
  /// the scrutinee part of a switch statement.  [token] is the `(` token.
  ///
  /// [allowCase] indicates whether the condition may optionally be followed by
  /// a caseHead.
  Token parseExpressionInParenthesisRest(Token token,
      {required bool allowCase}) {
    assert(optional('(', token));
    BeginToken begin = token as BeginToken;
    token = parseExpression(token);
    Token next = token.next!;
    if (allowPatterns && optional('case', next)) {
      Token case_ = token = next;
      token = parsePattern(token, PatternContext.matching);
      next = token.next!;
      Token? when;
      if (optional('when', next)) {
        when = token = next;
        listener.beginPatternGuard(when);
        token = parseExpression(token);
        listener.endPatternGuard(when);
      }
      token = ensureCloseParen(token, begin);
      listener.handleParenthesizedCondition(begin, case_, when);
    } else {
      token = ensureCloseParen(token, begin);
      listener.handleParenthesizedCondition(
          begin, /* case_ = */ null, /* when = */ null);
    }
    assert(optional(')', token));
    return token;
  }

  Token parseThisExpression(Token token, IdentifierContext context) {
    Token thisToken = token = token.next!;
    assert(optional('this', thisToken));
    listener.handleThisExpression(thisToken, context);
    Token next = token.next!;
    if (optional('(', next)) {
      // Constructor forwarding.
      listener.handleNoTypeArguments(next);
      token = parseArguments(token);
      listener.handleSend(thisToken, token.next!);
    }
    return token;
  }

  Token parseSuperExpression(Token token, IdentifierContext context) {
    Token superToken = token = token.next!;
    assert(optional('super', token));
    listener.handleSuperExpression(superToken, context);
    Token next = token.next!;
    if (optional('(', next)) {
      // Super constructor.
      listener.handleNoTypeArguments(next);
      token = parseArguments(token);
      listener.handleSend(superToken, token.next!);
    } else if (optional("?.", next)) {
      reportRecoverableError(next, codes.messageSuperNullAware);
    }
    return token;
  }

  Token parseAugmentSuperExpression(Token token, IdentifierContext context) {
    Token augmentToken = token = token.next!;
    assert(optional('augment', token));
    Token superToken = token = token.next!;
    assert(optional('super', token));
    listener.handleAugmentSuperExpression(augmentToken, superToken, context);
    Token next = token.next!;
    if (optional('(', next)) {
      listener.handleNoTypeArguments(next);
      token = parseArguments(token);
      listener.handleSend(augmentToken, token.next!);
    }
    return token;
  }

  /// This method parses the portion of a list literal starting with the left
  /// square bracket.
  ///
  /// ```
  /// listLiteral:
  ///   'const'? typeArguments? '[' (expressionList ','?)? ']'
  /// ;
  /// ```
  ///
  /// Provide a [constKeyword] if the literal is preceded by 'const', or `null`
  /// if not. This is a suffix parser because it is assumed that type arguments
  /// have been parsed, or `listener.handleNoTypeArguments` has been executed.
  Token parseLiteralListSuffix(Token token, Token? constKeyword) {
    Token beforeToken = token;
    Token beginToken = token = token.next!;
    assert(optional('[', token) || optional('[]', token));
    int count = 0;
    if (optional('[]', token)) {
      token = rewriteSquareBrackets(beforeToken).next!;
      listener.handleLiteralList(
        /* count = */ 0,
        token,
        constKeyword,
        token.next!,
      );
      return token.next!;
    }
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    while (true) {
      Token next = token.next!;
      if (optional(']', next)) {
        token = next;
        break;
      }
      int ifCount = 0;
      LiteralEntryInfo? info = computeLiteralEntry(token);
      while (info != null) {
        if (info.hasEntry) {
          token = parseExpression(token);
        } else {
          token = info.parse(token, this);
        }
        ifCount += info.ifConditionDelta;
        info = info.computeNext(token);
      }
      next = token.next!;
      ++count;
      if (!optional(',', next)) {
        if (optional(']', next)) {
          token = next;
          break;
        }

        // Recovery
        if (!looksLikeLiteralEntry(next)) {
          if (beginToken.endGroup!.isSynthetic) {
            // The scanner has already reported an error,
            // but inserted `]` in the wrong place.
            token = rewriter.moveSynthetic(token, beginToken.endGroup!);
          } else {
            // Report an error and jump to the end of the list.
            reportRecoverableError(
                next, codes.templateExpectedButGot.withArguments(']'));
            token = beginToken.endGroup!;
          }
          break;
        }
        // This looks like the start of an expression.
        // Report an error, insert the comma, and continue parsing.
        SyntheticToken comma = new SyntheticToken(TokenType.COMMA, next.offset);
        codes.Message message = ifCount > 0
            ? codes.messageExpectedElseOrComma
            : codes.templateExpectedButGot.withArguments(',');
        next = rewriteAndRecover(token, message, comma);
      }
      token = next;
    }
    mayParseFunctionExpressions = old;
    listener.handleLiteralList(count, beginToken, constKeyword, token);
    return token;
  }

  /// This method parses the portion of a set or map literal that starts with
  /// the left curly brace when there are no leading type arguments.
  Token parseLiteralSetOrMapSuffix(Token token, Token? constKeyword) {
    Token leftBrace = token = token.next!;
    assert(optional('{', leftBrace));
    Token next = token.next!;
    if (optional('}', next)) {
      listener.handleLiteralSetOrMap(/* count = */ 0, leftBrace, constKeyword,
          next, /* hasSetEntry = */ false);
      return next;
    }

    final bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    int count = 0;
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool? hasSetEntry;

    while (true) {
      int ifCount = 0;
      LiteralEntryInfo? info = computeLiteralEntry(token);
      if (info == simpleEntry) {
        // TODO(danrubel): Remove this section and use the while loop below
        // once hasSetEntry is no longer needed.
        token = parseExpression(token);
        bool isMapEntry = optional(':', token.next!);
        hasSetEntry ??= !isMapEntry;
        if (isMapEntry) {
          Token colon = token.next!;
          token = parseExpression(colon);
          listener.handleLiteralMapEntry(colon, token.next!);
        }
      } else {
        while (info != null) {
          if (info.hasEntry) {
            token = parseExpression(token);
            if (optional(':', token.next!)) {
              Token colon = token.next!;
              token = parseExpression(colon);
              listener.handleLiteralMapEntry(colon, token.next!);
            }
          } else {
            token = info.parse(token, this);
          }
          ifCount += info.ifConditionDelta;
          info = info.computeNext(token);
        }
      }
      ++count;
      next = token.next!;

      Token? comma;
      if (optional(',', next)) {
        comma = token = next;
        next = token.next!;
      }
      if (optional('}', next)) {
        listener.handleLiteralSetOrMap(
            count, leftBrace, constKeyword, next, hasSetEntry ?? false);
        mayParseFunctionExpressions = old;
        return next;
      }

      if (comma == null) {
        // Recovery
        if (looksLikeLiteralEntry(next)) {
          // If this looks like the start of an expression,
          // then report an error, insert the comma, and continue parsing.
          // TODO(danrubel): Consider better error message
          SyntheticToken comma =
              new SyntheticToken(TokenType.COMMA, next.offset);
          codes.Message message = ifCount > 0
              ? codes.messageExpectedElseOrComma
              : codes.templateExpectedButGot.withArguments(',');
          token = rewriteAndRecover(token, message, comma);
        } else {
          reportRecoverableError(
              next, codes.templateExpectedButGot.withArguments('}'));
          // Scanner guarantees a closing curly bracket
          next = leftBrace.endGroup!;
          listener.handleLiteralSetOrMap(
              count, leftBrace, constKeyword, next, hasSetEntry ?? false);
          mayParseFunctionExpressions = old;
          return next;
        }
      }
    }
  }

  /// formalParameterList functionBody.
  ///
  /// This is a suffix parser because it is assumed that type arguments have
  /// been parsed, or `listener.handleNoTypeArguments(..)` has been executed.
  Token parseLiteralFunctionSuffix(Token token) {
    assert(optional('(', token.next!));
    // Scanner ensures `(` has matching `)`.
    Token next = token.next!.endGroup!.next!;
    int kind = next.kind;
    if (!identical(kind, FUNCTION_TOKEN) &&
        !identical(kind, OPEN_CURLY_BRACKET_TOKEN) &&
        (!identical(kind, KEYWORD_TOKEN) ||
            !optional('async', next) && !optional('sync', next))) {
      reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
    }
    return parseFunctionExpression(token);
  }

  /// genericListLiteral | genericMapLiteral | genericFunctionLiteral.
  ///
  /// Where
  ///   genericListLiteral ::= typeArguments '[' (expressionList ','?)? ']'
  ///   genericMapLiteral ::=
  ///       typeArguments '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
  ///   genericFunctionLiteral ::=
  ///       typeParameters formalParameterList functionBody
  /// Provide token for [constKeyword] if preceded by 'const', null if not.
  Token parseLiteralListSetMapOrFunction(
      final Token start, Token? constKeyword) {
    assert(optional('<', start.next!));
    TypeParamOrArgInfo typeParamOrArg =
        computeTypeParamOrArg(start, /* inDeclaration = */ true);
    Token token = typeParamOrArg.skip(start);
    if (optional('(', token.next!)) {
      if (constKeyword != null) {
        reportRecoverableErrorWithToken(
            constKeyword, codes.templateUnexpectedToken);
      }
      token = typeParamOrArg.parseVariables(start, this);
      return parseLiteralFunctionSuffix(token);
    }
    // Note that parseArguments can rewrite the token stream!
    token = typeParamOrArg.parseArguments(start, this);
    Token next = token.next!;
    if (optional('{', next)) {
      if (typeParamOrArg.typeArgumentCount > 2) {
        reportRecoverableErrorWithEnd(start.next!, token,
            codes.messageSetOrMapLiteralTooManyTypeArguments);
      }
      return parseLiteralSetOrMapSuffix(token, constKeyword);
    }
    if (!optional('[', next) && !optional('[]', next)) {
      // TODO(danrubel): Improve this error message.
      reportRecoverableError(
          next, codes.templateExpectedButGot.withArguments('['));
      rewriter.insertSyntheticToken(token, TokenType.INDEX);
    }
    return parseLiteralListSuffix(token, constKeyword);
  }

  /// ```
  /// mapLiteralEntry:
  ///   expression ':' expression |
  ///   'if' '(' expression ')' mapLiteralEntry ( 'else' mapLiteralEntry )? |
  ///   'await'? 'for' '(' forLoopParts ')' mapLiteralEntry |
  ///   ( '...' | '...?' ) expression
  /// ;
  /// ```
  Token parseMapLiteralEntry(Token token) {
    // Assume the listener rejects non-string keys.
    // TODO(brianwilkerson): Change the assumption above by moving error
    // checking into the parser, making it possible to recover.
    LiteralEntryInfo? info = computeLiteralEntry(token);
    while (info != null) {
      if (info.hasEntry) {
        token = parseExpression(token);
        Token colon = ensureColon(token);
        token = parseExpression(colon);
        // TODO remove unused 2nd parameter
        listener.handleLiteralMapEntry(colon, token.next!);
      } else {
        token = info.parse(token, this);
      }
      info = info.computeNext(token);
    }
    return token;
  }

  Token parseSendOrFunctionLiteral(Token token, IdentifierContext context,
      ConstantPatternContext constantPatternContext) {
    if (!mayParseFunctionExpressions) {
      return parseSend(token, context, constantPatternContext);
    }
    TypeInfo typeInfo = computeType(token, /* required = */ false);
    Token beforeName = typeInfo.skipType(token);
    Token name = beforeName.next!;
    if (name.isIdentifier) {
      TypeParamOrArgInfo typeParam = computeTypeParamOrArg(name);
      Token next = typeParam.skip(name).next!;
      if (optional('(', next)) {
        if (looksLikeFunctionBody(next.endGroup!.next!)) {
          return parseFunctionLiteral(
              token, beforeName, name, typeInfo, typeParam, context);
        }
      }
    }
    return parseSend(token, context, constantPatternContext);
  }

  Token ensureArguments(Token token) {
    Token next = token.next!;
    if (!optional('(', next)) {
      reportRecoverableError(
          token, codes.templateExpectedAfterButGot.withArguments('('));
      next = rewriter.insertParens(token, /* includeIdentifier = */ false);
    }
    return parseArgumentsRest(next);
  }

  Token parseConstructorInvocationArguments(Token token) {
    Token next = token.next!;
    if (!optional('(', next)) {
      // Recovery: Check for invalid type parameters
      TypeParamOrArgInfo typeArg = computeTypeParamOrArg(token);
      if (typeArg == noTypeParamOrArg) {
        reportRecoverableError(
            token, codes.templateExpectedAfterButGot.withArguments('('));
      } else {
        reportRecoverableError(
            token, codes.messageConstructorWithTypeArguments);
        token = typeArg.parseArguments(token, this);
        listener.handleInvalidTypeArguments(token);
        next = token.next!;
      }
      if (!optional('(', next)) {
        next = rewriter.insertParens(token, /* includeIdentifier = */ false);
      }
    }
    return parseArgumentsRest(next);
  }

  /// ```
  /// newExpression:
  ///   'new' type ('.' identifier)? arguments
  /// ;
  /// ```
  Token parseNewExpression(Token token) {
    Token newKeyword = token.next!;
    assert(optional('new', newKeyword));

    TypeParamOrArgInfo? potentialTypeArg;

    if (isNextIdentifier(newKeyword)) {
      Token identifier = newKeyword.next!;
      String value = identifier.lexeme;
      if ((value == "Map" || value == "Set") &&
          !optional('.', identifier.next!)) {
        potentialTypeArg = computeTypeParamOrArg(identifier);
        Token afterToken = potentialTypeArg.skip(identifier).next!;
        if (optional('{', afterToken)) {
          // Recover by ignoring both the `new` and the `Map`/`Set` and parse as
          // a literal map/set.
          reportRecoverableErrorWithEnd(
              newKeyword,
              identifier,
              codes.templateLiteralWithClassAndNew
                  .withArguments(value.toLowerCase(), identifier));
          return parsePrimary(identifier, IdentifierContext.expression,
              ConstantPatternContext.none);
        }
      } else if (value == "List" && !optional('.', identifier.next!)) {
        potentialTypeArg = computeTypeParamOrArg(identifier);
        Token afterToken = potentialTypeArg.skip(identifier).next!;
        if (optional('[', afterToken) || optional('[]', afterToken)) {
          // Recover by ignoring both the `new` and the `List` and parse as
          // a literal list.
          reportRecoverableErrorWithEnd(
              newKeyword,
              identifier,
              codes.templateLiteralWithClassAndNew
                  .withArguments(value.toLowerCase(), identifier));
          return parsePrimary(identifier, IdentifierContext.expression,
              ConstantPatternContext.none);
        }
      }
    } else {
      // This is probably an error. "Normal" recovery will happen in
      // parseConstructorReference.
      // Do special recovery for literal maps/set/list erroneously prepended
      // with 'new'.
      Token notIdentifier = newKeyword.next!;
      String value = notIdentifier.lexeme;
      if (value == "<") {
        potentialTypeArg = computeTypeParamOrArg(newKeyword);
        Token afterToken = potentialTypeArg.skip(newKeyword).next!;
        if (optional('{', afterToken) ||
            optional('[', afterToken) ||
            optional('[]', afterToken)) {
          // Recover by ignoring the `new` and parse as a literal map/set/list.
          reportRecoverableError(newKeyword, codes.messageLiteralWithNew);
          return parsePrimary(newKeyword, IdentifierContext.expression,
              ConstantPatternContext.none);
        }
      } else if (value == "{" || value == "[" || value == "[]") {
        // Recover by ignoring the `new` and parse as a literal map/set/list.
        reportRecoverableError(newKeyword, codes.messageLiteralWithNew);
        return parsePrimary(newKeyword, IdentifierContext.expression,
            ConstantPatternContext.none);
      }
    }

    listener.beginNewExpression(newKeyword);
    token = parseConstructorReference(newKeyword,
        ConstructorReferenceContext.New, /* typeArg = */ potentialTypeArg);
    token = parseConstructorInvocationArguments(token);
    listener.endNewExpression(newKeyword);
    return token;
  }

  Token parseImplicitCreationExpression(
      Token token, Token openAngleBracket, TypeParamOrArgInfo typeArg) {
    Token begin = token.next!; // This is the class name.
    listener.beginImplicitCreationExpression(begin);
    token = parseConstructorReference(
        token, ConstructorReferenceContext.Implicit, /* typeArg = */ typeArg);
    token = parseConstructorInvocationArguments(token);
    listener.endImplicitCreationExpression(begin, openAngleBracket);
    return token;
  }

  /// This method parses a list or map literal that is known to start with the
  /// keyword 'const'.
  ///
  /// ```
  /// listLiteral:
  ///   'const'? typeArguments? '[' (expressionList ','?)? ']'
  /// ;
  ///
  /// mapLiteral:
  ///   'const'? typeArguments?
  ///     '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
  /// ;
  ///
  /// mapLiteralEntry:
  ///   expression ':' expression
  /// ;
  /// ```
  Token parseConstExpression(Token token) {
    Token constKeyword = token = token.next!;
    assert(optional('const', constKeyword));
    Token next = token.next!;
    final String? value = next.stringValue;
    if ((identical(value, '[')) || (identical(value, '[]'))) {
      listener.beginConstLiteral(next);
      listener.handleNoTypeArguments(next);
      token = parseLiteralListSuffix(token, constKeyword);
      listener.endConstLiteral(token.next!);
      return token;
    }
    if (identical(value, '(')) {
      // Const record literal.
      listener.beginConstLiteral(next);
      token = parseParenthesizedExpressionOrRecordLiteral(
          token, constKeyword, ConstantPatternContext.none);
      listener.endConstLiteral(token.next!);
      return token;
    }
    if (identical(value, '{')) {
      listener.beginConstLiteral(next);
      listener.handleNoTypeArguments(next);
      token = parseLiteralSetOrMapSuffix(token, constKeyword);
      listener.endConstLiteral(token.next!);
      return token;
    }
    if (identical(value, '<')) {
      listener.beginConstLiteral(next);
      token = parseLiteralListSetMapOrFunction(token, constKeyword);
      listener.endConstLiteral(token.next!);
      return token;
    }
    final String lexeme = next.lexeme;
    Token nextNext = next.next!;
    TypeParamOrArgInfo? potentialTypeArg;
    if ((lexeme == "Map" || lexeme == "Set") && !optional('.', nextNext)) {
      // Special-case-recovery for `const Map<..>?{}` and `const Set<..>?{}`.
      potentialTypeArg = computeTypeParamOrArg(next);
      Token afterToken = potentialTypeArg.skip(next).next!;
      if (optional('{', afterToken)) {
        final String? nextValue = nextNext.stringValue;
        if (identical(nextValue, '{')) {
          // Recover by ignoring the `Map`/`Set` and parse as a literal map/set.
          reportRecoverableError(
              next,
              codes.templateLiteralWithClass
                  .withArguments(lexeme.toLowerCase(), next));
          listener.beginConstLiteral(nextNext);
          listener.handleNoTypeArguments(nextNext);
          token = parseLiteralSetOrMapSuffix(next, constKeyword);
          listener.endConstLiteral(token.next!);
          return token;
        }
        if (identical(nextValue, '<')) {
          // Recover by ignoring the `Map`/`Set` and parse as a literal map/set.
          reportRecoverableError(
              next,
              codes.templateLiteralWithClass
                  .withArguments(lexeme.toLowerCase(), next));

          listener.beginConstLiteral(nextNext);
          token = parseLiteralListSetMapOrFunction(next, constKeyword);
          listener.endConstLiteral(token.next!);
          return token;
        }
        assert(false, "Expected either { or < but found neither.");
      }
    } else if (lexeme == "List" && !optional('.', nextNext)) {
      // Special-case-recovery for `const List<..>?[` and `const List<..>?[]`.
      potentialTypeArg = computeTypeParamOrArg(next);
      Token afterToken = potentialTypeArg.skip(next).next!;
      if (optional('[', afterToken) || optional('[]', afterToken)) {
        final String? nextValue = nextNext.stringValue;
        if (identical(nextValue, '[') || identical(nextValue, '[]')) {
          // Recover by ignoring the `List` and parse as a literal list.
          reportRecoverableError(
              next,
              codes.templateLiteralWithClass
                  .withArguments(lexeme.toLowerCase(), next));
          listener.beginConstLiteral(nextNext);
          listener.handleNoTypeArguments(nextNext);
          token = parseLiteralListSuffix(next, constKeyword);
          listener.endConstLiteral(token.next!);
          return token;
        }
        if (identical(nextValue, '<')) {
          // Recover by ignoring the `List` and parse as a literal list.
          reportRecoverableError(
              next,
              codes.templateLiteralWithClass
                  .withArguments(lexeme.toLowerCase(), next));
          listener.beginConstLiteral(nextNext);
          token = parseLiteralListSetMapOrFunction(next, constKeyword);
          listener.endConstLiteral(token.next!);
          return token;
        }
        assert(false, "Expected either [, [] or < but found neither.");
      }
    }
    listener.beginConstExpression(constKeyword);
    token = parseConstructorReference(token, ConstructorReferenceContext.Const,
        /* typeArg = */ potentialTypeArg);
    token = parseConstructorInvocationArguments(token);
    listener.endConstExpression(constKeyword);
    return token;
  }

  /// ```
  /// intLiteral:
  ///   integer
  /// ;
  /// ```
  Token parseLiteralInt(Token token) {
    token = token.next!;
    assert(identical(token.kind, INT_TOKEN) ||
        identical(token.kind, HEXADECIMAL_TOKEN));
    listener.handleLiteralInt(token);
    return token;
  }

  /// ```
  /// doubleLiteral:
  ///   double
  /// ;
  /// ```
  Token parseLiteralDouble(Token token) {
    token = token.next!;
    assert(identical(token.kind, DOUBLE_TOKEN));
    listener.handleLiteralDouble(token);
    return token;
  }

  /// ```
  /// stringLiteral:
  ///   (multilineString | singleLineString)+
  /// ;
  /// ```
  Token parseLiteralString(Token token) {
    Token startToken = token;
    assert(identical(token.next!.kind, STRING_TOKEN));
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseSingleLiteralString(token);
    int count = 1;
    while (identical(token.next!.kind, STRING_TOKEN)) {
      token = parseSingleLiteralString(token);
      count++;
    }
    if (count > 1) {
      listener.handleStringJuxtaposition(startToken, count);
    }
    mayParseFunctionExpressions = old;
    return token;
  }

  /// ```
  /// symbolLiteral:
  ///   '#' (operator | (identifier ('.' identifier)*))
  /// ;
  /// ```
  Token parseLiteralSymbol(Token token) {
    Token hashToken = token = token.next!;
    assert(optional('#', hashToken));
    listener.beginLiteralSymbol(hashToken);
    Token next = token.next!;
    if (next.isUserDefinableOperator) {
      listener.handleOperator(next);
      listener.endLiteralSymbol(hashToken, /* identifierCount = */ 1);
      return next;
    } else if (optional('void', next)) {
      listener.handleSymbolVoid(next);
      listener.endLiteralSymbol(hashToken, /* identifierCount = */ 1);
      return next;
    } else {
      int count = 1;
      token = ensureIdentifier(token, IdentifierContext.literalSymbol);
      while (optional('.', token.next!)) {
        count++;
        token = ensureIdentifier(
            token.next!, IdentifierContext.literalSymbolContinuation);
      }
      listener.endLiteralSymbol(hashToken, count);
      return token;
    }
  }

  Token parseSingleLiteralString(Token token) {
    token = token.next!;
    assert(identical(token.kind, STRING_TOKEN));
    listener.beginLiteralString(token);
    // Parsing the prefix, for instance 'x of 'x${id}y${id}z'
    int interpolationCount = 0;
    Token next = token.next!;
    int kind = next.kind;
    while (kind != EOF_TOKEN) {
      if (identical(kind, STRING_INTERPOLATION_TOKEN)) {
        // Parsing ${expression}.
        token = parseExpression(next).next!;
        if (!optional('}', token)) {
          reportRecoverableError(
              token, codes.templateExpectedButGot.withArguments('}'));
          token = next.endGroup!;
        }
        listener.handleInterpolationExpression(next, token);
      } else if (identical(kind, STRING_INTERPOLATION_IDENTIFIER_TOKEN)) {
        // Parsing $identifier.
        token = parseIdentifierExpression(next);
        listener.handleInterpolationExpression(next, /* rightBracket = */ null);
      } else {
        break;
      }
      ++interpolationCount;
      // Parsing the infix/suffix, for instance y and z' of 'x${id}y${id}z'
      token = parseStringPart(token);
      next = token.next!;
      kind = next.kind;
    }
    listener.endLiteralString(interpolationCount, next);
    return token;
  }

  Token parseIdentifierExpression(Token token) {
    Token next = token.next!;
    if (next.kind == KEYWORD_TOKEN && identical(next.stringValue, "this")) {
      listener.handleThisExpression(next, IdentifierContext.expression);
      return next;
    } else {
      return parseSend(
          token, IdentifierContext.expression, ConstantPatternContext.none);
    }
  }

  /// ```
  /// booleanLiteral:
  ///   'true' |
  ///   'false'
  /// ;
  /// ```
  Token parseLiteralBool(Token token) {
    token = token.next!;
    assert(optional('false', token) || optional('true', token));
    listener.handleLiteralBool(token);
    return token;
  }

  /// ```
  /// nullLiteral:
  ///   'null'
  /// ;
  /// ```
  Token parseLiteralNull(Token token) {
    token = token.next!;
    assert(optional('null', token));
    listener.handleLiteralNull(token);
    return token;
  }

  Token parseSend(Token token, IdentifierContext context,
      ConstantPatternContext constantPatternContext) {
    // Least-costly recovery of `Map<...>?{`, `Set<...>?{`, `List<...>[` and
    // `List<...>?[]`.
    // Note that we have to "peek" into the identifier because we don't want to
    // send an `handleIdentifier` if we end up recovering.
    TypeParamOrArgInfo? potentialTypeArg;
    Token? afterToken;
    if (isNextIdentifier(token)) {
      Token identifier = token.next!;
      String value = identifier.lexeme;
      if (value == "Map" || value == "Set") {
        potentialTypeArg = computeTypeParamOrArg(identifier);
        afterToken = potentialTypeArg.skip(identifier).next!;
        if (optional('{', afterToken)) {
          // Recover by ignoring the `Map`/`Set` and parse as a literal map/set.
          reportRecoverableError(
              identifier,
              codes.templateLiteralWithClass
                  .withArguments(value.toLowerCase(), identifier));
          return parsePrimary(identifier, context, ConstantPatternContext.none);
        }
      } else if (value == "List") {
        potentialTypeArg = computeTypeParamOrArg(identifier);
        afterToken = potentialTypeArg.skip(identifier).next!;
        if ((potentialTypeArg != noTypeParamOrArg &&
                optional('[', afterToken)) ||
            optional('[]', afterToken)) {
          // Recover by ignoring the `List` and parse as a literal List.
          // Note that we here require the `<...>` for `[` as `List[` would be
          // an indexed expression. `List[]` wouldn't though, so we don't
          // require it there.
          reportRecoverableError(
              identifier,
              codes.templateLiteralWithClass
                  .withArguments(value.toLowerCase(), identifier));
          return parsePrimary(identifier, context, ConstantPatternContext.none);
        }
      }
    }

    Token beginToken = token = ensureIdentifier(token, context);
    // Notice that we don't parse the bang (!) here as we do in many other
    // instances where we call computeMethodTypeArguments.
    // The reason is, that on a method call like "e.f!<int>()" we need the
    // "e.f" to become a "single unit" before processing the bang (!),
    // the type arguments and the arguments.
    // By not handling bang here we don't parse any of it, and the parser will
    // parse it correctly in a different recursion step.

    // Special-case [computeMethodTypeArguments] to re-use potentialTypeArg if
    // already computed.
    potentialTypeArg ??= computeTypeParamOrArg(token);
    afterToken ??= potentialTypeArg.skip(token).next!;
    TypeParamOrArgInfo typeArg;
    if (optional('(', afterToken) && !potentialTypeArg.recovered) {
      typeArg = potentialTypeArg;
    } else {
      typeArg = noTypeParamOrArg;
    }

    if (typeArg != noTypeParamOrArg) {
      token = typeArg.parseArguments(token, this);
    } else {
      listener.handleNoTypeArguments(token.next!);
    }
    if (constantPatternContext == ConstantPatternContext.explicit &&
        !(optional('.', token.next!) ||
            optional('(', token.next!) ||
            optional('<', token.next!))) {
      // For '.', '(' and '<' we might end up with a valid constant pattern,
      // i.e. a const constructor invocation, so we only report an error here
      // otherwise.
      reportRecoverableError(
          token, codes.messageInvalidConstantPatternConstPrefix);
      // Avoid subsequent errors.
      constantPatternContext = ConstantPatternContext.none;
    }
    token = parseArgumentsOpt(token);
    listener.handleSend(beginToken, token.next!);
    return token;
  }

  Token skipArgumentsOpt(Token token) {
    Token next = token.next!;
    listener.handleNoArguments(next);
    if (optional('(', next)) {
      return next.endGroup!;
    } else {
      return token;
    }
  }

  /// Parse optional arguments specifically for metadata as metadata arguments
  /// has to follow the previous token without space.
  /// See also
  /// https://github.com/dart-lang/language/blob/master/accepted/future-releases/records/records-feature-specification.md#ambiguity-with-metadata-annotations
  Token parseArgumentsOptMetadata(Token token, bool hasTypeArguments) {
    final Token next = token.next!;
    if (!optional('(', next)) {
      listener.handleNoArguments(next);
      return token;
    } else if (token.charEnd == next.charOffset) {
      return parseArguments(token);
    } else {
      // There is a '(', but it's not technically arguments to the metadata.
      // Decide if we should recover as if it is. This should only be done
      // if we know that it isn't a record type.
      if (hasTypeArguments) {
        // Arguments are required, so parse as arguments anyway.
        reportRecoverableError(
            next, codes.messageMetadataSpaceBeforeParenthesis);
        return parseArguments(token);
      }
      final Token startParen = next;
      final Token endParen = startParen.endGroup!;
      final Token afterParen = endParen.next!;
      final String? value = afterParen.stringValue;
      if (identical(value, 'class') || identical(value, 'enum')) {
        // The 'class' and 'enum' keywords are reserved keywords and recovery
        // should be safe. Other keywords aren't reserved and needs more
        // lookahead to determine if recovery here would be good.
        //For now we don't.
        reportRecoverableError(
            next, codes.messageMetadataSpaceBeforeParenthesis);
        return parseArguments(token);
      }

      listener.handleNoArguments(next);
      return token;
    }
  }

  Token parseArgumentsOpt(Token token) {
    Token next = token.next!;
    if (!optional('(', next)) {
      listener.handleNoArguments(next);
      return token;
    } else {
      return parseArguments(token);
    }
  }

  /// ```
  /// arguments:
  ///   '(' (argumentList ','?)? ')'
  /// ;
  ///
  /// argumentList:
  ///   namedArgument (',' namedArgument)* |
  ///   expressionList (',' namedArgument)*
  /// ;
  ///
  /// namedArgument:
  ///   label expression
  /// ;
  /// ```
  Token parseArguments(Token token) {
    return parseArgumentsRest(token.next!);
  }

  /// Parses the rest of an arguments list, where [token] is the `(`.
  Token parseArgumentsRest(Token token) {
    Token begin = token;
    assert(optional('(', begin));
    listener.beginArguments(begin);
    int argumentCount = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    while (true) {
      Token next = token.next!;
      if (optional(')', next)) {
        token = next;
        break;
      }
      Token? colon = null;
      if (optional(':', next.next!) || /* recovery */ optional(':', next)) {
        token =
            ensureIdentifier(token, IdentifierContext.namedArgumentReference)
                .next!;
        colon = token;
      }
      token = parseExpression(token);
      next = token.next!;
      if (colon != null) listener.handleNamedArgument(colon);
      ++argumentCount;
      if (!optional(',', next)) {
        if (optional(')', next)) {
          token = next;
          break;
        }
        // Recovery
        if (looksLikeExpressionStart(next)) {
          // If this looks like the start of an expression,
          // then report an error, insert the comma, and continue parsing.
          next = rewriteAndRecover(
              token,
              codes.templateExpectedButGot.withArguments(','),
              new SyntheticToken(TokenType.COMMA, next.offset));
        } else {
          token = ensureCloseParen(token, begin);
          break;
        }
      }
      token = next;
    }
    assert(optional(')', token));
    mayParseFunctionExpressions = old;
    listener.endArguments(argumentCount, begin, token);
    return token;
  }

  /// ```
  /// typeTest::
  ///   'is' '!'? type
  /// ;
  /// ```
  Token parseIsOperatorRest(Token token) {
    Token operator = token = token.next!;
    assert(optional('is', operator));
    Token? not = null;
    if (optional('!', token.next!)) {
      not = token = token.next!;
    }
    listener.beginIsOperatorType(operator);
    TypeInfo typeInfo = computeTypeAfterIsOrAs(token);
    token = typeInfo.ensureTypeNotVoid(token, this);
    listener.endIsOperatorType(operator);
    listener.handleIsOperator(operator, not);
    return skipChainedAsIsOperators(token);
  }

  TypeInfo computeTypeAfterIsOrAs(Token token) {
    TypeInfo typeInfo = computeType(token, /* required = */ true);
    if (typeInfo.isNullable) {
      Token skipToken = typeInfo.skipType(token);
      Token next = skipToken.next!;
      if (isOneOfOrEof(next, const [
        ')',
        '}',
        ']',
        '?',
        '??',
        ',',
        ';',
        ':',
        'is',
        'as',
        '..',
        '||',
        '&&'
      ])) {
        // TODO(danrubel): investigate other situations
        // where `?` should be considered part of the type info
        // rather than the start of a conditional expression.
        return typeInfo;
      }
      if (optional('{', next)) {
        // <expression> is/as <type> ? {
        // This could be either a nullable type (e.g. last initializer in a
        // constructor with a body), or a non-nullable type and a conditional.
        // As with "?[" we check and have it as a conditional if it can be.
        bool isConditional = canParseAsConditional(skipToken);
        if (!isConditional) {
          return typeInfo;
        }
      }
      typeInfo = typeInfo.asNonNullable;
    }
    return typeInfo;
  }

  /// ```
  /// typeCast:
  ///   'as' type
  /// ;
  /// ```
  Token parseAsOperatorRest(Token token) {
    Token operator = token = token.next!;
    assert(optional('as', operator));
    listener.beginAsOperatorType(operator);
    TypeInfo typeInfo = computeTypeAfterIsOrAs(token);
    token = typeInfo.ensureTypeNotVoid(token, this);
    listener.endAsOperatorType(operator);
    listener.handleAsOperator(operator);
    return skipChainedAsIsOperators(token);
  }

  Token skipChainedAsIsOperators(Token token) {
    while (true) {
      Token next = token.next!;
      String? value = next.stringValue;
      if (!identical(value, 'is') && !identical(value, 'as')) {
        return token;
      }
      // The is- and as-operators cannot be chained.
      // TODO(danrubel): Consider a better error message.
      reportRecoverableErrorWithToken(next, codes.templateUnexpectedToken);
      if (optional('!', next.next!)) {
        next = next.next!;
      }
      TypeInfo typeInfo = computeTypeAfterIsOrAs(next);
      token = typeInfo.skipType(next);
      next = token.next!;
      value = next.stringValue;
    }
  }

  /// Returns true if [token] could be the start of a function declaration
  /// without a return type.
  bool looksLikeLocalFunction(Token token) {
    if (token.isIdentifier) {
      if (optional('<', token.next!)) {
        TypeParamOrArgInfo typeParam = computeTypeParamOrArg(token);
        if (typeParam == noTypeParamOrArg) {
          return false;
        }
        token = typeParam.skip(token);
      }
      token = token.next!;
      if (optional('(', token)) {
        token = token.endGroup!.next!;
        return optional('{', token) ||
            optional('=>', token) ||
            optional('async', token) ||
            optional('sync', token);
      } else if (optional('=>', token)) {
        // Recovery: Looks like a local function that is missing parenthesis.
        return true;
      }
    }
    return false;
  }

  /// Returns true if [token] could be the start of a function body.
  bool looksLikeFunctionBody(Token token) {
    return optional('{', token) ||
        optional('=>', token) ||
        optional('async', token) ||
        optional('sync', token);
  }

  Token parseExpressionStatementOrConstDeclaration(final Token start) {
    Token constToken = start.next!;
    assert(optional('const', constToken));
    if (!isModifier(constToken.next!)) {
      TypeInfo typeInfo = computeType(constToken, /* required = */ false);
      if (typeInfo == noType) {
        Token next = constToken.next!;
        if (!next.isIdentifier) {
          return parseExpressionStatement(start);
        }
        next = next.next!;
        if (!(optional('=', next) ||
            // Recovery
            next.isKeywordOrIdentifier ||
            optional(';', next) ||
            optional(',', next) ||
            optional('{', next))) {
          return parseExpressionStatement(start);
        }
      }
      return parseExpressionStatementOrDeclarationAfterModifiers(
          constToken, start, /* lateToken = */ null, constToken, typeInfo);
    }
    return parseExpressionStatementOrDeclaration(start);
  }

  /// This method has two modes based upon [onlyParseVariableDeclarationStart].
  ///
  /// If [forPartsContext] is `null` (the default), then the parser is currently
  /// processing a statement or declaration.  This method will parse a local
  /// variable declaration, a local function, or an expression statement, and
  /// then return the last consumed token.
  ///
  /// If [forPartsContext] is non-null, then this method will only parse the
  /// metadata, modifiers, and type of a local variable declaration if it
  /// exists; it is the responsibility of the caller to call
  /// [parseVariablesDeclarationRest] to finish parsing the local variable
  /// declaration.  Or it will parse the metadata, `var` or `final` keyword, and
  /// pattern of a pattern variable declaration, and store the `var` or `final`
  /// keyword in [forPartsContext]; it is the responsibility of the caller to
  /// consume the rest of the pattern variable declaration.  Or, if neither a
  /// local variable declaration nor a pattern variable declaration is found,
  /// then this method will return [start].
  Token parseExpressionStatementOrDeclaration(final Token start,
      [ForPartsContext? forPartsContext]) {
    Token token = start;
    Token next = token.next!;
    if (optional('@', next)) {
      token = parseMetadataStar(token);
      next = token.next!;
    }

    Token? lateToken;
    Token? varFinalOrConst;

    if (isModifier(next)) {
      if (optional('augment', next) && optional('super', next.next!)) {
        return parseExpressionStatement(start);
      } else if (optional('var', next) ||
          optional('final', next) ||
          optional('const', next)) {
        varFinalOrConst = token = token.next!;
        next = token.next!;
      } else if (optional('late', next)) {
        lateToken = token = next;
        next = token.next!;
        if (isModifier(next) &&
            (optional('var', next) || optional('final', next))) {
          varFinalOrConst = token = next;
          next = token.next!;
        }
      }

      if (isModifier(next)) {
        // Recovery
        ModifierContext context = new ModifierContext(this)
          ..lateToken = lateToken
          ..varFinalOrConst = varFinalOrConst;

        token = context.parseVariableDeclarationModifiers(token);
        next = token.next!;

        lateToken = context.lateToken;
        varFinalOrConst = context.varFinalOrConst;
      }
    }

    return parseExpressionStatementOrDeclarationAfterModifiers(token, start,
        lateToken, varFinalOrConst, /* typeInfo = */ null, forPartsContext);
  }

  /// See [parseExpressionStatementOrDeclaration].
  ///
  /// If `start.next` is an `@` token (i.e. this is a declaration with metadata)
  /// then the caller should parse it before calling this method; otherwise,
  /// this method will handle the lack of metadata appropriately.
  Token parseExpressionStatementOrDeclarationAfterModifiers(Token beforeType,
      Token start, Token? lateToken, Token? varFinalOrConst, TypeInfo? typeInfo,
      [ForPartsContext? forPartsContext]) {
    // In simple cases check for bad 'late' modifier in non-nnbd-mode.
    if (typeInfo == null &&
        lateToken == null &&
        varFinalOrConst == null &&
        beforeType == start &&
        _isUseOfLateInNonNNBD(beforeType.next!)) {
      lateToken = beforeType.next!;
      reportRecoverableErrorWithToken(
          lateToken, codes.templateUnexpectedModifierInNonNnbd);
      beforeType = start = beforeType.next!;

      // The below doesn't parse modifiers, so we need to do it here.
      ModifierContext context = new ModifierContext(this);
      beforeType =
          start = context.parseVariableDeclarationModifiers(beforeType);
      varFinalOrConst = context.varFinalOrConst;
    }

    // TODO(paulberry): maybe some of the conditions in this `if` test should be
    // removed to allow for better error recovery.
    if (allowPatterns &&
        lateToken == null &&
        varFinalOrConst != null &&
        (optional('var', varFinalOrConst) ||
            optional('final', varFinalOrConst))) {
      Token? afterOuterPattern = skipOuterPattern(beforeType);
      if (afterOuterPattern != null &&
          (optional('=', afterOuterPattern.next!) ||
              (forPartsContext != null &&
                  optional('in', afterOuterPattern.next!)))) {
        // If there was any metadata, then the caller was responsible for
        // parsing it; if not, then we need to let the listener know there
        // wasn't any.
        if (!optional('@', start.next!)) {
          listener.beginMetadataStar(start.next!);
          listener.endMetadataStar(/* count = */ 0);
        }
        if (forPartsContext != null) {
          forPartsContext.patternKeyword = varFinalOrConst;
          return parsePattern(beforeType, PatternContext.declaration);
        } else {
          return parsePatternVariableDeclarationStatement(
              beforeType, start, varFinalOrConst);
        }
      }
    }

    typeInfo ??= computeType(beforeType, /* required = */ false);

    Token token = typeInfo.skipType(beforeType);
    Token next = token.next!;

    if (forPartsContext != null) {
      if (lateToken != null) {
        reportRecoverableErrorWithToken(
            lateToken, codes.templateExtraneousModifier);
      }
    } else {
      if (looksLikeLocalFunction(next)) {
        // Parse a local function declaration.
        if (varFinalOrConst != null) {
          reportRecoverableErrorWithToken(
              varFinalOrConst, codes.templateExtraneousModifier);
        } else if (lateToken != null) {
          reportRecoverableErrorWithToken(
              lateToken, codes.templateExtraneousModifier);
        }
        // If there was any metadata, then the caller was responsible for
        // parsing it; if not, then we need to let the listener know there
        // wasn't any.
        if (!optional('@', start.next!)) {
          listener.beginMetadataStar(start.next!);
          listener.endMetadataStar(/* count = */ 0);
        }
        Token beforeFormals =
            computeTypeParamOrArg(next).parseVariables(next, this);
        listener.beginLocalFunctionDeclaration(start.next!);
        token = typeInfo.parseType(beforeType, this);
        return parseNamedFunctionRest(
          token,
          start.next!,
          beforeFormals,
          /* isFunctionExpression = */ false,
        );
      }
    }

    if (beforeType == start &&
        typeInfo.isNullable &&
        typeInfo.couldBeExpression) {
      assert(optional('?', token));
      assert(next.isKeywordOrIdentifier);
      if (!looksLikeName(next)) {
        reportRecoverableError(
            next, codes.templateExpectedIdentifier.withArguments(next));
        next = rewriter.insertSyntheticIdentifier(next);
      }
      Token afterIdentifier = next.next!;
      //
      // found <typeref> `?` <identifier>
      // with no annotations or modifiers preceding it
      //
      if (optional('=', afterIdentifier)) {
        //
        // look past the next expression
        // to determine if this is part of a conditional expression
        //
        Listener originalListener = listener;
        TokenStreamRewriter? originalRewriter = cachedRewriter;
        listener = new NullListener();
        UndoableTokenStreamRewriter undoableTokenStreamRewriter =
            new UndoableTokenStreamRewriter();
        cachedRewriter = undoableTokenStreamRewriter;
        Token afterExpression =
            parseExpressionWithoutCascade(afterIdentifier).next!;
        // Undo all changes and reset.
        undoableTokenStreamRewriter.undo();
        listener = originalListener;
        cachedRewriter = originalRewriter;

        if (optional(':', afterExpression)) {
          // Looks like part of a conditional expression.
          // Drop the type information and reset the last consumed token.
          typeInfo = noType;
          token = start;
          next = token.next!;
        }
      } else if (!afterIdentifier.isKeyword &&
          !isOneOfOrEof(afterIdentifier, const [';', ',', ')'])) {
        // Looks like part of a conditional expression.
        // Drop the type information and reset the last consumed token.
        typeInfo = noType;
        token = start;
        next = token.next!;
      }
    }

    if (token == start) {
      // If no annotation, modifier, or type, and this is not a local function
      // then this must be an expression statement.
      if (forPartsContext != null) {
        return start;
      } else {
        return parseExpressionStatement(start);
      }
    }

    if (next.type.isBuiltIn &&
        beforeType == start &&
        typeInfo.couldBeExpression) {
      // Detect expressions such as identifier `as` identifier
      // and treat those as expressions.
      if (optional('as', next) || optional('is', next)) {
        int kind = next.next!.kind;
        if (EQ_TOKEN != kind &&
            SEMICOLON_TOKEN != kind &&
            COMMA_TOKEN != kind) {
          if (forPartsContext != null) {
            if (!optional('in', next.next!)) {
              return start;
            }
          } else {
            return parseExpressionStatement(start);
          }
        }
      }
    }

    if (next.isIdentifier) {
      // Only report these errors if there is an identifier. If there is not an
      // identifier, then allow ensureIdentifier to report an error
      // and don't report errors here.
      if (varFinalOrConst == null) {
        if (typeInfo == noType) {
          reportRecoverableError(next, codes.messageMissingConstFinalVarOrType);
        }
      } else if (optional('var', varFinalOrConst)) {
        if (typeInfo != noType) {
          reportRecoverableError(varFinalOrConst, codes.messageTypeAfterVar);
        }
      }
    }

    // If there was any metadata, then the caller was responsible for parsing
    // it; if not, then we need to let the listener know there wasn't any.
    if (!optional('@', start.next!)) {
      listener.beginMetadataStar(start.next!);
      listener.endMetadataStar(/* count = */ 0);
    }
    token = typeInfo.parseType(beforeType, this);
    next = token.next!;
    listener.beginVariablesDeclaration(next, lateToken, varFinalOrConst);
    if (forPartsContext == null) {
      token =
          parseVariablesDeclarationRest(token, /* endWithSemicolon = */ true);
    }
    return token;
  }

  Token parseVariablesDeclarationRest(Token token, bool endWithSemicolon) {
    int count = 1;
    token = parseOptionallyInitializedIdentifier(token);
    while (optional(',', token.next!)) {
      token = parseOptionallyInitializedIdentifier(token.next!);
      ++count;
    }
    if (endWithSemicolon) {
      Token semicolon = ensureSemicolon(token);
      listener.endVariablesDeclaration(count, semicolon);
      return semicolon;
    } else {
      listener.endVariablesDeclaration(count, /* endToken = */ null);
      return token;
    }
  }

  Token parseOptionallyInitializedIdentifier(Token token) {
    Token nameToken =
        ensureIdentifier(token, IdentifierContext.localVariableDeclaration);
    listener.beginInitializedIdentifier(nameToken);
    token = parseVariableInitializerOpt(nameToken);
    listener.endInitializedIdentifier(nameToken);
    return token;
  }

  /// ```
  /// ifStatement:
  ///   'if' '(' expression ')' statement ('else' statement)?
  /// ;
  /// ```
  Token parseIfStatement(Token token) {
    Token ifToken = token.next!;
    assert(optional('if', ifToken));
    listener.beginIfStatement(ifToken);
    token = ensureParenthesizedCondition(ifToken, allowCase: allowPatterns);
    listener.beginThenStatement(token.next!);
    token = parseStatement(token);
    listener.endThenStatement(token);
    Token? elseToken = null;
    if (optional('else', token.next!)) {
      elseToken = token.next!;
      listener.beginElseStatement(elseToken);
      token = parseStatement(elseToken);
      listener.endElseStatement(elseToken);
    }
    listener.endIfStatement(ifToken, elseToken);
    return token;
  }

  /// ```
  /// forStatement:
  ///   'await'? 'for' '(' forLoopParts ')' statement
  /// ;
  ///
  ///  forLoopParts:
  ///      localVariableDeclaration ';' expression? ';' expressionList?
  ///    | expression? ';' expression? ';' expressionList?
  ///    | localVariableDeclaration 'in' expression
  ///    | identifier 'in' expression
  ///    | metadata ( 'final' | 'var' ) outerPattern 'in' expression
  /// ;
  ///
  /// forInitializerStatement:
  ///   localVariableDeclaration |
  ///   expression? ';'
  /// ;
  /// ```
  Token parseForStatement(Token token, Token? awaitToken) {
    Token forToken = token = token.next!;
    assert(awaitToken == null || optional('await', awaitToken));
    assert(optional('for', token));
    listener.beginForStatement(forToken);

    ForPartsContext forPartsContext = new ForPartsContext();
    token = parseForLoopPartsStart(awaitToken, forToken, forPartsContext);
    Token? patternKeyword = forPartsContext.patternKeyword;
    if (patternKeyword != null) {
      if (optional('=', token.next!)) {
        // Process `for ( pattern = expression ; ... ; ... )`
        Token equals = token.next!;
        token = parseExpression(equals);
        listener.handleForInitializerPatternVariableAssignment(
            patternKeyword, equals);
        return parseForRest(awaitToken, token, forToken);
      } else {
        // Process `for ( pattern in expression )`
        assert(optional('in', token.next!));
        return parseForInRest(token, awaitToken, forToken, patternKeyword,
            /* identifier = */ null);
      }
    }
    Token identifier = token.next!;
    token = parseForLoopPartsMid(token, awaitToken, forToken);
    if (optional('in', token.next!) || optional(':', token.next!)) {
      // Process `for ( ... in ... )`
      return parseForInRest(
          token, awaitToken, forToken, /* patternKeyword = */ null, identifier);
    } else {
      // Process `for ( ... ; ... ; ... )`
      return parseForRest(awaitToken, token, forToken);
    }
  }

  /// Parse the start of a for loop control structure
  /// from the open parenthesis up to but not including the identifier.
  Token parseForLoopPartsStart(
      Token? awaitToken, Token forToken, ForPartsContext forPartsContext) {
    Token leftParenthesis = forToken.next!;
    if (!optional('(', leftParenthesis)) {
      // Recovery
      reportRecoverableError(
          leftParenthesis, codes.templateExpectedButGot.withArguments('('));

      BeginToken openParen = rewriter.insertToken(
          forToken,
          new SyntheticBeginToken(
              TokenType.OPEN_PAREN, leftParenthesis.offset)) as BeginToken;

      Token token;
      if (awaitToken != null) {
        token = rewriter.insertSyntheticIdentifier(openParen);
        token = rewriter.insertSyntheticKeyword(token, Keyword.IN);
        token = rewriter.insertSyntheticIdentifier(token);
      } else {
        token = rewriter.insertSyntheticToken(openParen, TokenType.SEMICOLON);
        token = rewriter.insertSyntheticToken(token, TokenType.SEMICOLON);
      }

      openParen.endGroup = token = rewriter.insertToken(token,
          new SyntheticToken(TokenType.CLOSE_PAREN, leftParenthesis.offset));

      token = rewriter.insertSyntheticIdentifier(token);
      rewriter.insertSyntheticToken(token, TokenType.SEMICOLON);

      leftParenthesis = openParen;
    }

    // Pass `true` so that the [parseExpressionStatementOrDeclaration] only
    // parses the metadata, modifiers, and type of a local variable
    // declaration if it exists. This enables capturing [beforeIdentifier]
    // for later error reporting.
    return parseExpressionStatementOrDeclaration(
        leftParenthesis, forPartsContext);
  }

  /// Parse the remainder of the local variable declaration
  /// or an expression if no local variable declaration was found.
  Token parseForLoopPartsMid(Token token, Token? awaitToken, Token forToken) {
    if (token != forToken.next) {
      token =
          parseVariablesDeclarationRest(token, /* endWithSemicolon = */ false);
      listener.handleForInitializerLocalVariableDeclaration(
          token, optional('in', token.next!) || optional(':', token.next!));
    } else if (optional(';', token.next!)) {
      listener.handleForInitializerEmptyStatement(token.next!);
    } else {
      token = parseExpression(token);
      listener.handleForInitializerExpressionStatement(
          token,
          optional('in', token.next!) ||
              optional(':', token.next!) ||
              // If this is an empty `await for`, we rewrite it into an
              // `await for (_ in _)`.
              (awaitToken != null && optional(')', token.next!)));
    }
    Token next = token.next!;
    if (optional(';', next)) {
      if (awaitToken != null) {
        reportRecoverableError(awaitToken, codes.messageInvalidAwaitFor);
      }
    } else if (!optional('in', next)) {
      // Recovery
      if (optional(':', next)) {
        reportRecoverableError(next, codes.messageColonInPlaceOfIn);
      } else if (awaitToken != null) {
        reportRecoverableError(
            next, codes.templateExpectedButGot.withArguments('in'));
        token.setNext(
            new SyntheticKeywordToken(Keyword.IN, next.offset)..setNext(next));
      }
    }
    return token;
  }

  /// This method parses the portion of the forLoopParts that starts with the
  /// first semicolon (the one that terminates the forInitializerStatement).
  ///
  /// ```
  ///  forLoopParts:
  ///      localVariableDeclaration ';' expression? ';' expressionList?
  ///    | expression? ';' expression? ';' expressionList?
  ///    | localVariableDeclaration 'in' expression
  ///    | identifier 'in' expression
  /// ;
  /// ```
  Token parseForRest(Token? awaitToken, Token token, Token forToken) {
    token = parseForLoopPartsRest(token, forToken, awaitToken);
    listener.beginForStatementBody(token.next!);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(token);
    loopState = savedLoopState;
    listener.endForStatementBody(token.next!);
    listener.endForStatement(token.next!);
    return token;
  }

  Token parseForLoopPartsRest(Token token, Token forToken, Token? awaitToken) {
    Token leftParenthesis = forToken.next!;
    assert(optional('for', forToken));
    assert(optional('(', leftParenthesis));

    Token leftSeparator = ensureSemicolon(token);
    if (optional(';', leftSeparator.next!)) {
      token = parseEmptyStatement(leftSeparator);
    } else {
      token = parseExpressionStatement(leftSeparator);
    }
    int expressionCount = 0;
    while (true) {
      Token next = token.next!;
      if (optional(')', next)) {
        token = next;
        break;
      }
      token = parseExpression(token).next!;
      ++expressionCount;
      if (!optional(',', token)) {
        break;
      }
    }
    if (token != leftParenthesis.endGroup) {
      reportRecoverableErrorWithToken(token, codes.templateUnexpectedToken);
      token = leftParenthesis.endGroup!;
    }
    listener.handleForLoopParts(
        forToken, leftParenthesis, leftSeparator, expressionCount);
    return token;
  }

  /// This method parses the portion of the forLoopParts that starts with the
  /// keyword 'in'. For the sake of recovery, we accept a colon in place of the
  /// keyword.
  ///
  /// ```
  ///  forLoopParts:
  ///      localVariableDeclaration ';' expression? ';' expressionList?
  ///    | expression? ';' expression? ';' expressionList?
  ///    | localVariableDeclaration 'in' expression
  ///    | identifier 'in' expression
  ///    | metadata ( 'final' | 'var' ) outerPattern 'in' expression
  /// ;
  /// ```
  Token parseForInRest(Token token, Token? awaitToken, Token forToken,
      Token? patternKeyword, Token? identifier) {
    token = parseForInLoopPartsRest(
        token, awaitToken, forToken, patternKeyword, identifier);
    listener.beginForInBody(token.next!);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(token);
    loopState = savedLoopState;
    listener.endForInBody(token.next!);
    listener.endForIn(token.next!);
    return token;
  }

  Token parseForInLoopPartsRest(Token token, Token? awaitToken, Token forToken,
      Token? patternKeyword, Token? identifier) {
    Token inKeyword = token.next!;
    assert(optional('for', forToken));
    assert(optional('(', forToken.next!));
    assert(optional('in', inKeyword) || optional(':', inKeyword));

    if (identifier != null) {
      if (!identifier.isIdentifier) {
        // TODO(jensj): This should probably (sometimes) be
        // templateExpectedIdentifierButGotKeyword instead.
        reportRecoverableErrorWithToken(
            identifier, codes.templateExpectedIdentifier);
      } else if (identifier != token) {
        if (optional('=', identifier.next!)) {
          reportRecoverableError(
              identifier.next!, codes.messageInitializedVariableInForEach);
        } else {
          reportRecoverableErrorWithToken(
              identifier.next!, codes.templateUnexpectedToken);
        }
      } else if (awaitToken != null && !inAsync) {
        // TODO(danrubel): consider reporting the error on awaitToken
        reportRecoverableError(inKeyword, codes.messageAwaitForNotAsync);
      }
    }
    listener.beginForInExpression(inKeyword.next!);
    token = parseExpression(inKeyword);
    token = ensureCloseParen(token, forToken.next!);
    listener.endForInExpression(token);
    listener.handleForInLoopParts(
        awaitToken, forToken, forToken.next!, patternKeyword, inKeyword);
    return token;
  }

  /// ```
  /// whileStatement:
  ///   'while' '(' expression ')' statement
  /// ;
  /// ```
  Token parseWhileStatement(Token token) {
    Token whileToken = token.next!;
    assert(optional('while', whileToken));
    listener.beginWhileStatement(whileToken);
    token = ensureParenthesizedCondition(whileToken, allowCase: false);
    listener.beginWhileStatementBody(token.next!);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(token);
    loopState = savedLoopState;
    listener.endWhileStatementBody(token.next!);
    listener.endWhileStatement(whileToken, token.next!);
    return token;
  }

  /// ```
  /// doStatement:
  ///   'do' statement 'while' '(' expression ')' ';'
  /// ;
  /// ```
  Token parseDoWhileStatement(Token token) {
    Token doToken = token.next!;
    assert(optional('do', doToken));
    listener.beginDoWhileStatement(doToken);
    listener.beginDoWhileStatementBody(doToken.next!);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(doToken);
    loopState = savedLoopState;
    listener.endDoWhileStatementBody(token);
    Token whileToken = token.next!;
    if (!optional('while', whileToken)) {
      reportRecoverableError(
          whileToken, codes.templateExpectedButGot.withArguments('while'));
      whileToken = rewriter.insertSyntheticKeyword(token, Keyword.WHILE);
    }
    token = ensureParenthesizedCondition(whileToken, allowCase: false);
    token = ensureSemicolon(token);
    listener.endDoWhileStatement(doToken, whileToken, token);
    return token;
  }

  /// ```
  /// block:
  ///   '{' statement* '}'
  /// ;
  /// ```
  Token parseBlock(Token token, BlockKind blockKind) {
    Token begin = token =
        ensureBlock(token, /* template = */ null, blockKind.missingBlockName);
    listener.beginBlock(begin, blockKind);
    int statementCount = 0;
    Token startToken = token.next!;
    while (notEofOrValue('}', startToken)) {
      token = parseStatement(token);
      if (identical(token.next!, startToken)) {
        // No progress was made, so we report the current token as being invalid
        // and move forward.
        token = token.next!;
        reportRecoverableError(
            token, codes.templateUnexpectedToken.withArguments(token));
      }
      ++statementCount;
      startToken = token.next!;
    }
    token = token.next!;
    assert(token.isEof || optional('}', token));
    listener.endBlock(statementCount, begin, token, blockKind);
    return token;
  }

  Token parseInvalidBlock(Token token) {
    Token begin = token.next!;
    assert(optional('{', begin));
    // Parse and report the invalid block, but suppress errors
    // because an error has already been reported by the caller.
    Listener originalListener = listener;
    listener = new ForwardingListener(listener)..forwardErrors = false;
    // The scanner ensures that `{` always has a closing `}`.
    token = parseBlock(token, BlockKind.invalid);
    listener = originalListener;
    listener.handleInvalidTopLevelBlock(begin);
    return token;
  }

  /// Determine if the following tokens look like an expression and not a local
  /// variable or local function declaration.
  bool looksLikeExpressionAfterAwaitOrYield(
      Token token, AwaitOrYieldContext context) {
    // TODO(srawlins): Consider parsing the potential expression once doing so
    //  does not modify the token stream. For now, use simple look ahead and
    //  ensure no false positives.

    token = token.next!;
    if (token.isIdentifier) {
      token = token.next!;
      if (optional('(', token)) {
        token = token.endGroup!.next!;
        if (isOneOf(token, const [';', '.', ',', '..', '?', '?.', ')'])) {
          // E.g. (in a non-async function): `await f();`.
          return true;
        } else if (token.type.isBinaryOperator) {
          // E.g. (in a non-async function):
          // `await returnsFuture() + await returnsFuture()`.
          return true;
        }
      } else if (isOneOf(token, const ['.', ')', ']'])) {
        // TODO(srawlins): Also consider when `token` is `;`. There is still not
        // good error recovery on `yield x;`. This would also require
        // modification to analyzer's
        // test_parseCompilationUnit_pseudo_asTypeName.

        // E.g. (in a non-async function): `if (await f) {}`.
        return true;
      } else if (optional(',', token) &&
          context == AwaitOrYieldContext.UnaryExpression) {
        // E.g. (in a non-async function): `xor(await f, await f, await f);`,
        // but not `await y, z` (`await` is a class here so it's declaring two
        // variables).
        return true;
      } else if (token.type.isBinaryOperator) {
        // E.g. (in a non-async function): (first part of) `await f + await f;`,
        return true;
      } else if (optional(';', token) &&
          context == AwaitOrYieldContext.UnaryExpression) {
        // E.g. (in a non-async function): (second part of) `await f + await f;`
        // but not `await f;` (`await` is a class here so it's a variable
        // declaration).
        return true;
      }
    } else if (token == Keyword.NULL) {
      return true;
    }
    // TODO(srawlins): Consider other possibilities for `token` which would
    //  imply it looks like an expression, for example beginning with `<`, as
    //  part of a collection literal type argument list, `(`, other literals,
    //  etc. For example, there is still not good error recovery on
    //  `yield <int>[]`.

    return false;
  }

  /// Determine if the following tokens look like an 'await' expression
  /// and not a local variable or local function declaration.
  bool looksLikeAwaitExpression(Token token, AwaitOrYieldContext context) {
    token = token.next!;
    assert(optional('await', token));

    return looksLikeExpressionAfterAwaitOrYield(token, context);
  }

  /// Determine if the following tokens look like a 'yield' expression and not a
  /// local variable or local function declaration.
  bool looksLikeYieldStatement(Token token, AwaitOrYieldContext context) {
    token = token.next!;
    assert(optional('yield', token));

    return looksLikeExpressionAfterAwaitOrYield(token, context);
  }

  /// ```
  /// awaitExpression:
  ///   'await' unaryExpression
  /// ;
  /// ```
  Token parseAwaitExpression(Token token, bool allowCascades) {
    Token awaitToken = token.next!;
    assert(optional('await', awaitToken));
    listener.beginAwaitExpression(awaitToken);
    token = parsePrecedenceExpression(awaitToken, POSTFIX_PRECEDENCE,
        allowCascades, ConstantPatternContext.none);
    if (inAsync) {
      listener.endAwaitExpression(awaitToken, token.next!);
    } else {
      codes.MessageCode errorCode = codes.messageAwaitNotAsync;
      reportRecoverableError(awaitToken, errorCode);
      listener.endInvalidAwaitExpression(awaitToken, token.next!, errorCode);
    }
    return token;
  }

  /// ```
  /// throwExpression:
  ///   'throw' expression
  /// ;
  ///
  /// throwExpressionWithoutCascade:
  ///   'throw' expressionWithoutCascade
  /// ;
  /// ```
  Token parseThrowExpression(Token token, bool allowCascades) {
    Token throwToken = token.next!;
    assert(optional('throw', throwToken));
    if (optional(';', throwToken.next!)) {
      // TODO(danrubel): Find a better way to intercept the parseExpression
      // recovery to generate this error message rather than explicitly
      // checking the next token as we are doing here.
      reportRecoverableError(
          throwToken.next!, codes.messageMissingExpressionInThrow);
      rewriter.insertToken(
          throwToken,
          new SyntheticStringToken(TokenType.STRING, '""',
              throwToken.next!.charOffset, /* _length = */ 0));
    }
    token = allowCascades
        ? parseExpression(throwToken)
        : parseExpressionWithoutCascade(throwToken);
    listener.handleThrowExpression(throwToken, token.next!);
    return token;
  }

  /// ```
  /// rethrowStatement:
  ///   'rethrow' ';'
  /// ;
  /// ```
  Token parseRethrowStatement(Token token) {
    Token throwToken = token.next!;
    assert(optional('rethrow', throwToken));
    listener.beginRethrowStatement(throwToken);
    token = ensureSemicolon(throwToken);
    listener.endRethrowStatement(throwToken, token);
    return token;
  }

  /// ```
  /// tryStatement:
  ///   'try' block (onPart+ finallyPart? | finallyPart)
  /// ;
  ///
  /// onPart:
  ///   catchPart block |
  ///   'on' type catchPart? block
  /// ;
  ///
  /// catchPart:
  ///   'catch' '(' identifier (',' identifier)? ')'
  /// ;
  ///
  /// finallyPart:
  ///   'finally' block
  /// ;
  /// ```
  Token parseTryStatement(Token token) {
    Token tryKeyword = token.next!;
    assert(optional('try', tryKeyword));
    listener.beginTryStatement(tryKeyword);
    Token lastConsumed = parseBlock(tryKeyword, BlockKind.tryStatement);
    token = lastConsumed.next!;
    int catchCount = 0;

    String? value = token.stringValue;
    while (identical(value, 'catch') || identical(value, 'on')) {
      bool didBeginCatchClause = false;
      Token? onKeyword = null;
      if (identical(value, 'on')) {
        // 'on' type catchPart?
        // Note https://github.com/dart-lang/language/blob/master/accepted/future-releases/records/records-feature-specification.md#ambiguity-with-on-clauses
        // "Whenever on appears after a try block or after a preceding on clause
        // on a try block, we unconditionally parse it as an on clause".
        onKeyword = token;
        TypeInfo typeInfo = computeType(token, /* required = */ true);
        listener.beginCatchClause(token);
        didBeginCatchClause = true;
        lastConsumed = typeInfo.ensureTypeNotVoid(token, this);
        token = lastConsumed.next!;
        value = token.stringValue;
      }
      Token? catchKeyword = null;
      Token? comma = null;
      if (identical(value, 'catch')) {
        if (!didBeginCatchClause) {
          listener.beginCatchClause(token);
          didBeginCatchClause = true;
        }
        catchKeyword = token;

        Token openParens = catchKeyword.next!;
        if (!optional("(", openParens)) {
          reportRecoverableError(openParens, codes.messageCatchSyntax);
          openParens = rewriter.insertParens(
              catchKeyword, /* includeIdentifier = */ true);
        }

        Token exceptionName = openParens.next!;
        if (exceptionName.kind != IDENTIFIER_TOKEN) {
          exceptionName = IdentifierContext.catchParameter
              .ensureIdentifier(openParens, this);
        }

        if (optional(")", exceptionName.next!)) {
          // OK: `catch (identifier)`.
        } else {
          comma = exceptionName.next!;
          if (!optional(",", comma)) {
            // Recovery
            if (!exceptionName.isSynthetic) {
              reportRecoverableError(comma, codes.messageCatchSyntax);
            }

            // TODO(danrubel): Consider inserting `on` clause if
            // exceptionName is preceded by type and followed by a comma.
            // Then this
            //   } catch (E e, t) {
            // will recover to
            //   } on E catch (e, t) {
            // with a detailed explanation for the user in the error
            // indicating what they should do to fix the code.

            // TODO(danrubel): Consider inserting synthetic identifier if
            // exceptionName is a non-synthetic identifier followed by `.`.
            // Then this
            //   } catch (
            //   e.f();
            // will recover to
            //   } catch (_s_) {}
            //   e.f();
            // rather than
            //   } catch (e) {}
            //   _s_.f();

            if (openParens.endGroup!.isSynthetic) {
              // The scanner did not place the synthetic ')' correctly.
              rewriter.moveSynthetic(exceptionName, openParens.endGroup!);
              comma = null;
            } else {
              comma =
                  rewriter.insertSyntheticToken(exceptionName, TokenType.COMMA);
            }
          }
          if (comma != null) {
            Token traceName = comma.next!;
            if (traceName.kind != IDENTIFIER_TOKEN) {
              traceName = IdentifierContext.catchParameter
                  .ensureIdentifier(comma, this);
            }
            if (!optional(")", traceName.next!)) {
              // Recovery
              if (!traceName.isSynthetic) {
                reportRecoverableError(
                    traceName.next!, codes.messageCatchSyntaxExtraParameters);
              }
              if (openParens.endGroup!.isSynthetic) {
                // The scanner did not place the synthetic ')' correctly.
                rewriter.moveSynthetic(traceName, openParens.endGroup!);
              }
            }
          }
        }
        lastConsumed = parseFormalParameters(catchKeyword, MemberKind.Catch);
        token = lastConsumed.next!;
      }
      listener.endCatchClause(token);
      lastConsumed = parseBlock(lastConsumed, BlockKind.catchClause);
      token = lastConsumed.next!;
      ++catchCount;
      listener.handleCatchBlock(onKeyword, catchKeyword, comma);
      value = token.stringValue; // while condition
    }

    Token? finallyKeyword = null;
    if (optional('finally', token)) {
      finallyKeyword = token;
      lastConsumed = parseBlock(token, BlockKind.finallyClause);
      token = lastConsumed.next!;
      listener.handleFinallyBlock(finallyKeyword);
    } else {
      if (catchCount == 0) {
        reportRecoverableError(tryKeyword, codes.messageOnlyTry);
      }
    }
    listener.endTryStatement(catchCount, tryKeyword, finallyKeyword);
    return lastConsumed;
  }

  /// ```
  /// switchStatement:
  ///   'switch' parenthesizedExpression switchBlock
  /// ;
  /// ```
  Token parseSwitchStatement(Token token) {
    Token switchKeyword = token.next!;
    assert(optional('switch', switchKeyword));
    listener.beginSwitchStatement(switchKeyword);
    token = ensureParenthesizedCondition(switchKeyword, allowCase: false);
    LoopState savedLoopState = loopState;
    if (loopState == LoopState.OutsideLoop) {
      loopState = LoopState.InsideSwitch;
    }
    token = parseSwitchBlock(token);
    loopState = savedLoopState;
    listener.endSwitchStatement(switchKeyword, token);
    return token;
  }

  /// ```
  /// switchBlock:
  ///   '{' switchCase* defaultCase? '}'
  /// ;
  /// ```
  Token parseSwitchBlock(Token token) {
    Token beginSwitch =
        token = ensureBlock(token, /* template = */ null, 'switch statement');
    listener.beginSwitchBlock(beginSwitch);
    int caseCount = 0;
    Token? defaultKeyword = null;
    Token? colonAfterDefault = null;
    while (notEofOrValue('}', token.next!)) {
      Token beginCase = token.next!;
      int expressionCount = 0;
      int labelCount = 0;
      Token peek = peekPastLabels(beginCase);
      while (true) {
        // Loop until we find something that can't be part of a switch case.
        String? value = peek.stringValue;
        if (identical(value, 'default')) {
          while (!identical(token.next!, peek)) {
            token = parseLabel(token);
            labelCount++;
          }
          if (defaultKeyword != null) {
            reportRecoverableError(
                token.next!, codes.messageSwitchHasMultipleDefaults);
          }
          defaultKeyword = token.next!;
          colonAfterDefault = token = ensureColon(defaultKeyword);
          peek = token.next!;
          break;
        } else if (identical(value, 'case')) {
          while (!identical(token.next!, peek)) {
            token = parseLabel(token);
            labelCount++;
          }
          Token caseKeyword = token.next!;
          if (defaultKeyword != null) {
            reportRecoverableError(
                caseKeyword, codes.messageSwitchHasCaseAfterDefault);
          }
          listener.beginCaseExpression(caseKeyword);
          if (allowPatterns) {
            token = parsePattern(caseKeyword, PatternContext.matching);
          } else {
            token = parseExpression(caseKeyword);
          }
          Token? next = token.next!;
          Token? when;
          if (optional('when', next)) {
            when = token = next;
            listener.beginSwitchCaseWhenClause(when);
            token = parseExpression(token);
            listener.endSwitchCaseWhenClause(token);
          } else {
            listener.handleSwitchCaseNoWhenClause(token);
          }
          token = ensureColon(token);
          listener.endCaseExpression(caseKeyword, when, token);
          expressionCount++;
          peek = peekPastLabels(token.next!);
        } else if (expressionCount > 0) {
          break;
        } else {
          // Recovery
          reportRecoverableError(
              peek, codes.templateExpectedToken.withArguments("case"));
          Token endGroup = beginSwitch.endGroup!;
          while (token.next != endGroup) {
            token = token.next!;
          }
          peek = peekPastLabels(token.next!);
          break;
        }
      }
      token = parseStatementsInSwitchCase(token, peek, beginCase, labelCount,
          expressionCount, defaultKeyword, colonAfterDefault);
      ++caseCount;
    }
    token = token.next!;
    listener.endSwitchBlock(caseCount, beginSwitch, token);
    assert(token.isEof || optional('}', token));
    return token;
  }

  /// Peek after the following labels (if any). The following token
  /// is used to determine if the labels belong to a statement or a
  /// switch case.
  Token peekPastLabels(Token token) {
    while (token.isIdentifier && optional(':', token.next!)) {
      token = token.next!.next!;
    }
    return token;
  }

  /// Parse statements after a switch `case:` or `default:`.
  Token parseStatementsInSwitchCase(
      Token token,
      Token peek,
      Token begin,
      int labelCount,
      int expressionCount,
      Token? defaultKeyword,
      Token? colonAfterDefault) {
    listener.beginSwitchCase(labelCount, expressionCount, begin);
    // Finally zero or more statements.
    int statementCount = 0;
    while (!identical(token.next!.kind, EOF_TOKEN)) {
      String? value = peek.stringValue;
      if ((identical(value, 'case')) ||
          (identical(value, 'default')) ||
          ((identical(value, '}')) && (identical(token.next!, peek)))) {
        // A label just before "}" will be handled as a statement error.
        break;
      } else {
        Token startToken = token.next!;
        token = parseStatement(token);
        Token next = token.next!;
        if (identical(next, startToken)) {
          // No progress was made, so we report the current token as being
          // invalid and move forward.
          reportRecoverableError(
              next, codes.templateUnexpectedToken.withArguments(next));
          token = next;
        }
        ++statementCount;
      }
      peek = peekPastLabels(token.next!);
    }
    listener.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        colonAfterDefault, statementCount, begin, token.next!);
    return token;
  }

  /// ```
  /// breakStatement:
  ///   'break' identifier? ';'
  /// ;
  /// ```
  Token parseBreakStatement(Token token) {
    Token breakKeyword = token = token.next!;
    assert(optional('break', breakKeyword));
    bool hasTarget = false;
    if (token.next!.isIdentifier) {
      token = ensureIdentifier(token, IdentifierContext.labelReference);
      hasTarget = true;
    } else if (!isBreakAllowed) {
      reportRecoverableError(breakKeyword, codes.messageBreakOutsideOfLoop);
    }
    token = ensureSemicolon(token);
    listener.handleBreakStatement(hasTarget, breakKeyword, token);
    return token;
  }

  /// ```
  /// assertion:
  ///   'assert' '(' expression (',' expression)? ','? ')'
  /// ;
  /// ```
  Token parseAssert(Token token, Assert kind) {
    token = token.next!;
    assert(optional('assert', token));
    listener.beginAssert(token, kind);
    Token assertKeyword = token;
    Token leftParenthesis = token.next!;
    if (!optional('(', leftParenthesis)) {
      // Recovery
      reportRecoverableError(
          leftParenthesis, codes.templateExpectedButGot.withArguments('('));
      leftParenthesis =
          rewriter.insertParens(token, /* includeIdentifier = */ true);
    }
    token = leftParenthesis;
    Token? commaToken = null;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;

    token = parseExpression(token);
    if (optional(',', token.next!)) {
      token = token.next!;
      if (!optional(')', token.next!)) {
        commaToken = token;
        token = parseExpression(token);
        if (optional(',', token.next!)) {
          // Trailing comma is ignored.
          token = token.next!;
        }
      }
    }

    Token endGroup = leftParenthesis.endGroup!;
    if (token.next == endGroup) {
      token = endGroup;
    } else {
      // Recovery
      if (endGroup.isSynthetic) {
        // The scanner did not place the synthetic ')' correctly, so move it.
        token = rewriter.moveSynthetic(token, endGroup);
      } else {
        reportRecoverableErrorWithToken(
            token.next!, codes.templateUnexpectedToken);
        token = endGroup;
      }
    }

    assert(optional(')', token));
    mayParseFunctionExpressions = old;
    if (kind == Assert.Expression) {
      reportRecoverableError(assertKeyword, codes.messageAssertAsExpression);
    } else if (kind == Assert.Statement) {
      ensureSemicolon(token);
    }
    listener.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, token.next!);
    return token;
  }

  /// ```
  /// assertStatement:
  ///   assertion ';'
  /// ;
  /// ```
  Token parseAssertStatement(Token token) {
    assert(optional('assert', token.next!));
    // parseAssert ensures that there is a trailing semicolon.
    return parseAssert(token, Assert.Statement).next!;
  }

  /// ```
  /// continueStatement:
  ///   'continue' identifier? ';'
  /// ;
  /// ```
  Token parseContinueStatement(Token token) {
    Token continueKeyword = token = token.next!;
    assert(optional('continue', continueKeyword));
    bool hasTarget = false;
    if (token.next!.isIdentifier) {
      token = ensureIdentifier(token, IdentifierContext.labelReference);
      hasTarget = true;
      if (!isContinueWithLabelAllowed) {
        reportRecoverableError(
            continueKeyword, codes.messageContinueOutsideOfLoop);
      }
    } else if (!isContinueAllowed) {
      reportRecoverableError(
          continueKeyword,
          loopState == LoopState.InsideSwitch
              ? codes.messageContinueWithoutLabelInCase
              : codes.messageContinueOutsideOfLoop);
    }
    token = ensureSemicolon(token);
    listener.handleContinueStatement(hasTarget, continueKeyword, token);
    return token;
  }

  /// ```
  /// emptyStatement:
  ///   ';'
  /// ;
  /// ```
  Token parseEmptyStatement(Token token) {
    token = token.next!;
    assert(optional(';', token));
    listener.handleEmptyStatement(token);
    return token;
  }

  /// Given a token ([beforeToken]) that is known to be before another [token],
  /// return the token that is immediately before the [token].
  Token previousToken(Token beforeToken, Token token) {
    Token next = beforeToken.next!;
    while (next != token && next != beforeToken) {
      beforeToken = next;
      next = beforeToken.next!;
    }
    return beforeToken;
  }

  /// Recover from finding an operator declaration missing the `operator`
  /// keyword. The metadata for the member, if any, has already been parsed
  /// (and events have already been generated).
  Token parseInvalidOperatorDeclaration(
      Token beforeStart,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token beforeType,
      DeclarationKind kind,
      String? enclosingDeclarationName) {
    TypeInfo typeInfo = computeType(
        beforeStart, /* required = */ false, /* inDeclaration = */ true);
    Token beforeName = typeInfo.skipType(beforeType);
    Token next = beforeName.next!;

    if (optional('operator', next)) {
      next = next.next!;
    } else {
      // The 'operator' keyword is missing, but we may or may not have a type
      // before the token that is the actual operator.
      Token operator = next;
      if (!next.isOperator && next.next!.isOperator) {
        beforeName = next;
        operator = next.next!;
      }
      reportRecoverableError(operator, codes.messageMissingOperatorKeyword);
      rewriter.insertSyntheticKeyword(beforeName, Keyword.OPERATOR);

      // Having inserted the keyword the type now possibly compute differently.
      typeInfo = computeType(
          beforeStart, /* required = */ true, /* inDeclaration = */ true);
      beforeName = typeInfo.skipType(beforeType);
      next = beforeName.next!;

      // The 'next' token can be the just-inserted 'operator' keyword.
      // If it is, change it so it points to the actual operator.
      if (!next.isOperator &&
          next.next!.isOperator &&
          identical(next.stringValue, 'operator')) {
        next = next.next!;
      }
    }

    assert((next.isOperator && next.endGroup == null) ||
        optional('===', next) ||
        optional('!==', next));

    Token token = parseMethod(
        beforeStart,
        abstractToken,
        augmentToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        beforeType,
        typeInfo,
        /* getOrSet = */ null,
        beforeName.next!,
        kind,
        enclosingDeclarationName,
        /* nameIsRecovered = */ false);
    listener.endMember();
    return token;
  }

  /// Recover from finding an invalid class member. The metadata for the member,
  /// if any, has already been parsed (and events have already been generated).
  /// The member was expected to start with the token after [token].
  Token recoverFromInvalidMember(
      Token token,
      Token beforeStart,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token beforeType,
      TypeInfo typeInfo,
      Token? getOrSet,
      DeclarationKind kind,
      String? enclosingDeclarationName) {
    Token next = token.next!;
    String? value = next.stringValue;

    if (identical(value, 'class')) {
      return reportAndSkipClassInClass(next);
    } else if (identical(value, 'enum')) {
      return reportAndSkipEnumInClass(next);
    } else if (identical(value, 'typedef')) {
      return reportAndSkipTypedefInClass(next);
    } else if (next.isOperator && next.endGroup == null) {
      return parseInvalidOperatorDeclaration(
          beforeStart,
          abstractToken,
          augmentToken,
          externalToken,
          staticToken,
          covariantToken,
          lateToken,
          varFinalOrConst,
          beforeType,
          kind,
          enclosingDeclarationName);
    }

    if (getOrSet != null ||
        identical(value, '(') ||
        identical(value, '=>') ||
        identical(value, '{')) {
      token = parseMethod(
          beforeStart,
          abstractToken,
          augmentToken,
          externalToken,
          staticToken,
          covariantToken,
          lateToken,
          varFinalOrConst,
          beforeType,
          typeInfo,
          getOrSet,
          token.next!,
          kind,
          enclosingDeclarationName,
          /* nameIsRecovered = */ false);
    } else if (token == beforeStart) {
      // TODO(danrubel): Provide a more specific error message for extra ';'.
      reportRecoverableErrorWithToken(next, codes.templateExpectedClassMember);
      listener.handleInvalidMember(next);
      if (!identical(value, '}')) {
        // Ensure we make progress.
        token = next;
      }
    } else {
      token = parseFields(
          beforeStart,
          abstractToken,
          augmentToken,
          externalToken,
          staticToken,
          covariantToken,
          lateToken,
          varFinalOrConst,
          beforeType,
          typeInfo,
          token.next!,
          kind,
          enclosingDeclarationName,
          /* nameIsRecovered = */ false);
    }

    listener.endMember();
    return token;
  }

  /// Report that the nesting depth of the code being parsed is too large for
  /// the parser to safely handle. Return the next `}` or EOF.
  Token recoverFromStackOverflow(Token token) {
    Token next = token.next!;
    reportRecoverableError(next, codes.messageStackOverflow);
    next = rewriter.insertSyntheticToken(token, TokenType.SEMICOLON);
    listener.handleEmptyStatement(next);

    while (notEofOrValue('}', next)) {
      token = next;
      next = token.next!;
    }
    return token;
  }

  void reportRecoverableError(Token token, codes.Message message) {
    // Find a non-synthetic token on which to report the error.
    token = findNonZeroLengthToken(token);
    listener.handleRecoverableError(message, token, token);
  }

  void reportRecoverableErrorWithEnd(
      Token startToken, Token endToken, codes.Message message) {
    listener.handleRecoverableError(message, startToken, endToken);
  }

  void reportExperimentNotEnabled(
      ExperimentalFlag experimentalFlag, Token startToken, Token endToken) {
    listener.handleExperimentNotEnabled(experimentalFlag, startToken, endToken);
  }

  void reportRecoverableErrorWithToken(
      Token token, codes.Template<_MessageWithArgument<Token>> template) {
    // Find a non-synthetic token on which to report the error.
    token = findNonZeroLengthToken(token);
    listener.handleRecoverableError(
        template.withArguments(token), token, token);
  }

  Token reportAllErrorTokens(Token token) {
    while (token is ErrorToken) {
      listener.handleErrorToken(token);
      token = token.next!;
    }
    return token;
  }

  Token skipErrorTokens(Token token) {
    while (token is ErrorToken) {
      token = token.next!;
    }
    return token;
  }

  Token parseInvalidTopLevelDeclaration(Token token) {
    Token next = token.next!;
    reportRecoverableErrorWithToken(
        next,
        optional(';', next)
            ? codes.templateUnexpectedToken
            : codes.templateExpectedDeclaration);
    if (optional('{', next)) {
      next = parseInvalidBlock(token);
    }
    listener.handleInvalidTopLevelDeclaration(next);
    return next;
  }

  Token reportAndSkipClassInClass(Token token) {
    assert(optional('class', token));
    reportRecoverableError(token, codes.messageClassInClass);
    listener.handleInvalidMember(token);
    Token next = token.next!;
    // If the declaration appears to be a valid class declaration
    // then skip the entire declaration so that we only generate the one
    // error (above) rather than a plethora of unhelpful errors.
    if (next.isIdentifier) {
      // skip class name
      token = next;
      next = token.next!;
      // TODO(danrubel): consider parsing (skipping) the class header
      // with a recovery listener so that no events are generated
      if (optional('{', next) && next.endGroup != null) {
        // skip class body
        token = next.endGroup!;
      }
    }
    listener.endMember();
    return token;
  }

  Token reportAndSkipEnumInClass(Token token) {
    assert(optional('enum', token));
    reportRecoverableError(token, codes.messageEnumInClass);
    listener.handleInvalidMember(token);
    Token next = token.next!;
    // If the declaration appears to be a valid enum declaration
    // then skip the entire declaration so that we only generate the one
    // error (above) rather than a plethora of unhelpful errors.
    if (next.isIdentifier) {
      // skip enum name
      token = next;
      next = token.next!;
      if (optional('{', next) && next.endGroup != null) {
        // TODO(danrubel): Consider replacing this `skip enum` functionality
        // with something that can parse and resolve the declaration
        // even though it is in a class context
        token = next.endGroup!;
      }
    }
    listener.endMember();
    return token;
  }

  Token reportAndSkipTypedefInClass(Token token) {
    assert(optional('typedef', token));
    reportRecoverableError(token, codes.messageTypedefInClass);
    listener.handleInvalidMember(token);
    // TODO(brianwilkerson): If the declaration appears to be a valid typedef
    // then skip the entire declaration so that we generate a single error
    // (above) rather than many unhelpful errors.
    listener.endMember();
    return token;
  }

  /// Create a short token chain from the [beginToken] and [endToken] and return
  /// the [beginToken].
  Token link(BeginToken beginToken, Token endToken) {
    beginToken.setNext(endToken);
    beginToken.endGroup = endToken;
    return beginToken;
  }

  /// Create and return a token whose next token is the given [token].
  Token syntheticPreviousToken(Token token) {
    // Return the previous token if there is one so that any token inserted
    // before `token` will be properly inserted into the token stream.
    // TODO(danrubel): remove this once all methods have been converted to
    // use and return the last token consumed and the `previous` field
    // has been removed.
    if (token.previous != null) {
      return token.previous!;
    }
    Token before = new Token.eof(/* offset = */ -1);
    before.next = token;
    return before;
  }

  /// Return the first dartdoc comment token preceding the given token
  /// or `null` if no dartdoc token is found.
  Token? findDartDoc(Token token) {
    Token? comments = token.precedingComments;
    Token? dartdoc = null;
    bool isMultiline = false;
    while (comments != null) {
      String lexeme = comments.lexeme;
      if (lexeme.startsWith('///')) {
        if (!isMultiline) {
          dartdoc = comments;
          isMultiline = true;
        }
      } else if (lexeme.startsWith('/**')) {
        dartdoc = comments;
        isMultiline = false;
      }
      comments = comments.next;
    }
    return dartdoc;
  }

  /// Parse the comment references in a sequence of comment tokens
  /// where [dartdoc] (not null) is the first token in the sequence.
  /// Return the number of comment references parsed.
  int parseCommentReferences(Token dartdoc) {
    return dartdoc.lexeme.startsWith('///')
        ? parseReferencesInSingleLineComments(dartdoc)
        : parseReferencesInMultiLineComment(dartdoc);
  }

  /// Parse the comment references in a multi-line comment token.
  /// Return the number of comment references parsed.
  int parseReferencesInMultiLineComment(Token multiLineDoc) {
    String comment = multiLineDoc.lexeme;
    assert(comment.startsWith('/**'));
    int count = 0;
    int length = comment.length;
    int start = 3;
    bool inCodeBlock = false;
    int codeBlock = comment.indexOf('```', /* start = */ 3);
    if (codeBlock == -1) {
      codeBlock = length;
    }
    while (start < length) {
      if (isWhitespace(comment.codeUnitAt(start))) {
        ++start;
        continue;
      }
      int end = comment.indexOf('\n', start);
      if (end == -1) {
        end = length;
      }
      if (codeBlock < end) {
        inCodeBlock = !inCodeBlock;
        codeBlock = comment.indexOf('```', end);
        if (codeBlock == -1) {
          codeBlock = length;
        }
      }
      if (!inCodeBlock && !comment.startsWith('*     ', start)) {
        count += parseCommentReferencesInText(multiLineDoc, start, end);
      }
      start = end + 1;
    }
    return count;
  }

  /// Parse the comment references in a sequence of single line comment tokens
  /// where [token] is the first comment token in the sequence.
  /// Return the number of comment references parsed.
  int parseReferencesInSingleLineComments(Token? token) {
    int count = 0;
    bool inCodeBlock = false;
    while (token != null && !token.isEof) {
      String comment = token.lexeme;
      if (comment.startsWith('///')) {
        if (comment.indexOf('```', /* start = */ 3) != -1) {
          inCodeBlock = !inCodeBlock;
        }
        if (!inCodeBlock) {
          bool parseReferences;
          if (comment.startsWith('///    ')) {
            String? previousComment = token.previous?.lexeme;
            parseReferences = previousComment != null &&
                previousComment.startsWith('///') &&
                previousComment.trim().length > 3;
          } else {
            parseReferences = true;
          }
          if (parseReferences) {
            count += parseCommentReferencesInText(
                token, /* start = */ 3, comment.length);
          }
        }
      }
      token = token.next;
    }
    return count;
  }

  /// Parse the comment references in the text between [start] inclusive
  /// and [end] exclusive. Return a count indicating how many were parsed.
  int parseCommentReferencesInText(Token commentToken, int start, int end) {
    String comment = commentToken.lexeme;
    int count = 0;
    int index = start;
    while (index < end) {
      int ch = comment.codeUnitAt(index);
      if (ch == 0x5B /* `[` */) {
        ++index;
        if (index < end && comment.codeUnitAt(index) == 0x3A /* `:` */) {
          // Skip old-style code block.
          index = comment.indexOf(':]', index + 1) + 1;
          if (index == 0 || index > end) {
            break;
          }
        } else {
          int referenceStart = index;
          index = comment.indexOf(']', index);
          if (index == -1 || index >= end) {
            // Recovery: terminating ']' is not typed yet.
            index = findReferenceEnd(comment, referenceStart, end);
          }
          if (ch != 0x27 /* `'` */ && ch != 0x22 /* `"` */) {
            if (isLinkText(comment, index)) {
              // TODO(brianwilkerson) Handle the case where there's a library
              // URI in the link text.
            } else {
              listener.handleCommentReferenceText(
                  comment.substring(referenceStart, index),
                  commentToken.charOffset + referenceStart);
              ++count;
            }
          }
        }
      } else if (ch == 0x60 /* '`' */) {
        // Skip inline code block if there is both starting '`' and ending '`'
        int endCodeBlock = comment.indexOf('`', index + 1);
        if (endCodeBlock != -1 && endCodeBlock < end) {
          index = endCodeBlock;
        }
      }
      ++index;
    }
    return count;
  }

  /// Given a comment reference without a closing `]`,
  /// search for a possible place where `]` should be.
  int findReferenceEnd(String comment, int index, int end) {
    // Find the end of the identifier if there is one
    if (index >= end || !isLetter(comment.codeUnitAt(index))) {
      return index;
    }
    while (index < end && isLetterOrDigit(comment.codeUnitAt(index))) {
      ++index;
    }

    // Check for a trailing `.`
    if (index >= end || comment.codeUnitAt(index) != 0x2E /* `.` */) {
      return index;
    }
    ++index;

    // Find end of the identifier after the `.`
    if (index >= end || !isLetter(comment.codeUnitAt(index))) {
      return index;
    }
    ++index;
    while (index < end && isLetterOrDigit(comment.codeUnitAt(index))) {
      ++index;
    }
    return index;
  }

  /// Parse the tokens in a single comment reference and generate either a
  /// `handleCommentReference` or `handleNoCommentReference` event.
  /// Return `true` if a comment reference was successfully parsed.
  bool parseOneCommentReference(Token token, int referenceOffset) {
    Token begin = token;
    Token? newKeyword = null;
    if (optional('new', token)) {
      newKeyword = token;
      token = token.next!;
    }
    Token? firstToken, firstPeriod, secondToken, secondPeriod;
    if (token.isIdentifier && optional('.', token.next!)) {
      secondToken = token;
      secondPeriod = token.next!;
      if (secondPeriod.next!.isIdentifier &&
          optional('.', secondPeriod.next!.next!)) {
        firstToken = secondToken;
        firstPeriod = secondPeriod;
        secondToken = secondPeriod.next!;
        secondPeriod = secondToken.next!;
      }
      Token identifier = secondPeriod.next!;
      if (identifier.kind == KEYWORD_TOKEN && optional('new', identifier)) {
        // Treat `new` after `.` is as an identifier so that it can represent an
        // unnamed constructor. This support is separate from the
        // constructor-tearoffs feature.
        rewriter.replaceTokenFollowing(
            secondPeriod,
            new StringToken(TokenType.IDENTIFIER, identifier.lexeme,
                identifier.charOffset));
      }
      token = secondPeriod.next!;
    }
    if (token.isEof) {
      // Recovery: Insert a synthetic identifier for code completion
      token = rewriter.insertSyntheticIdentifier(
          secondPeriod ?? newKeyword ?? syntheticPreviousToken(token));
      if (begin == token.next!) {
        begin = token;
      }
    }
    Token? operatorKeyword = null;
    if (optional('operator', token)) {
      operatorKeyword = token;
      token = token.next!;
    }
    if (token.isUserDefinableOperator) {
      if (token.next!.isEof) {
        parseOneCommentReferenceRest(begin, referenceOffset, newKeyword,
            firstToken, firstPeriod, secondToken, secondPeriod, token);
        return true;
      }
    } else {
      token = operatorKeyword ?? token;
      if (token.next!.isEof) {
        if (token.isIdentifier) {
          parseOneCommentReferenceRest(begin, referenceOffset, newKeyword,
              firstToken, firstPeriod, secondToken, secondPeriod, token);
          return true;
        }
        Keyword? keyword = token.keyword;
        if (newKeyword == null &&
            secondToken == null &&
            (keyword == Keyword.THIS ||
                keyword == Keyword.NULL ||
                keyword == Keyword.TRUE ||
                keyword == Keyword.FALSE)) {
          // TODO(brianwilkerson) If we want to support this we will need to
          // extend the definition of CommentReference to take an expression
          // rather than an identifier. For now we just ignore it to reduce the
          // number of errors produced, but that's probably not a valid long
          // term approach.
        }
      }
    }
    listener.handleNoCommentReference();
    return false;
  }

  void parseOneCommentReferenceRest(
      Token begin,
      int referenceOffset,
      Token? newKeyword,
      Token? firstToken,
      Token? firstPeriod,
      Token? secondToken,
      Token? secondPeriod,
      Token identifierOrOperator) {
    // Adjust the token offsets to match the enclosing comment token.
    Token token = begin;
    do {
      token.offset += referenceOffset;
      token = token.next!;
    } while (!token.isEof);

    listener.handleCommentReference(newKeyword, firstToken, firstPeriod,
        secondToken, secondPeriod, identifierOrOperator);
  }

  /// Given that we have just found bracketed text within the given [comment],
  /// look to see whether that text is (a) followed by a parenthesized link
  /// address, (b) followed by a colon, or (c) followed by optional whitespace
  /// and another square bracket. The [rightIndex] is the index of the right
  /// bracket. Return `true` if the bracketed text is followed by a link
  /// address.
  ///
  /// This method uses the syntax described by the
  /// <a href="http://daringfireball.net/projects/markdown/syntax">markdown</a>
  /// project.
  bool isLinkText(String comment, int rightIndex) {
    int length = comment.length;
    int index = rightIndex + 1;
    if (index >= length) {
      return false;
    }
    int ch = comment.codeUnitAt(index);
    if (ch == 0x28 || ch == 0x3A) {
      return true;
    }
    while (isWhitespace(ch)) {
      index = index + 1;
      if (index >= length) {
        return false;
      }
      ch = comment.codeUnitAt(index);
    }
    return ch == 0x5B;
  }

  /// pattern               ::= logicalOrPattern
  /// logicalOrPattern      ::= logicalOrPattern ( '|' logicalAndPattern )?
  /// logicalAndPattern     ::= logicalAndPattern ( '&' relationalPattern )?
  /// relationalPattern     ::= ( equalityOperator | relationalOperator)
  ///                               relationalExpression
  ///                         | unaryPattern
  /// unaryPattern          ::= castPattern
  ///                         | nullCheckPattern
  ///                         | nullAssertPattern
  ///                         | primaryPattern
  /// castPattern ::= primaryPattern 'as' type
  /// nullAssertPattern ::= primaryPattern '!'
  /// nullCheckPattern ::= primaryPattern '?'
  ///
  /// [patternContext] indicates whether the pattern is refutable or
  /// irrefutable, and whether it occurs as part of a patternAssignment.
  Token parsePattern(Token token, PatternContext patternContext,
      {int precedence = 1}) {
    assert(precedence >= 1);
    assert(precedence <= SELECTOR_PRECEDENCE);
    token = parsePrimaryPattern(token, patternContext);
    while (true) {
      Token next = token.next!;
      int tokenLevel = _computePrecedence(next, forPattern: true);
      if (tokenLevel < precedence) return token;
      switch (next.lexeme) {
        // castPattern ::= primaryPattern 'as' type
        case 'as':
          Token operator = token = next;
          listener.beginAsOperatorType(token);
          TypeInfo typeInfo = computeTypeAfterIsOrAs(token);
          token = typeInfo.ensureTypeNotVoid(token, this);
          listener.endAsOperatorType(operator);
          listener.handleCastPattern(operator);
          // TODO(paulberry): report error if cast is followed by something the
          // grammar doesn't permit
          break;
        case '!':
          // nullAssertPattern ::= primaryPattern '!'
          listener.handleNullAssertPattern(next);
          token = next;
          break;
        case '?':
          // nullCheckPattern ::= primaryPattern '?'
          listener.handleNullCheckPattern(next);
          token = next;
          break;
        case '&&':
        case '||':
          listener.beginBinaryPattern(next);
          // Left associative so we parse the RHS one precedence level higher
          token =
              parsePattern(next, patternContext, precedence: tokenLevel + 1);
          listener.endBinaryPattern(next);
          break;
        default:
          // Some other operator that doesn't belong in a pattern
          return token;
      }
    }
  }

  /// primaryPattern        ::= constantPattern
  ///                         | variablePattern
  ///                         | parenthesizedPattern
  ///                         | listPattern
  ///                         | mapPattern
  ///                         | recordPattern
  ///                         | objectPattern
  /// listPattern ::= typeArguments? '[' patterns? ']'
  /// mapPattern        ::= typeArguments? '{' mapPatternEntries? '}'
  /// mapPatternEntries ::= mapPatternEntry ( ',' mapPatternEntry )* ','?
  /// mapPatternEntry   ::= expression ':' pattern
  /// variablePattern ::= ( 'var' | 'final' | 'final'? type )? identifier
  /// parenthesizedPattern  ::= '(' pattern ')'
  /// recordPattern         ::= '(' patternFields? ')'
  /// patternFields         ::= patternField ( ',' patternField )* ','?
  /// patternField          ::= ( identifier? ':' )? pattern
  /// constantPattern ::= booleanLiteral
  ///                   | nullLiteral
  ///                   | numericLiteral
  ///                   | stringLiteral
  ///                   | identifier
  ///                   | qualifiedName
  ///                   | constObjectExpression
  ///                   | 'const' typeArguments? '[' elements? ']'
  ///                   | 'const' typeArguments? '{' elements? '}'
  ///                   | 'const' '(' expression ')'
  /// objectPattern ::= typeName typeArguments? '(' patternFields? ')'
  Token parsePrimaryPattern(Token token, PatternContext patternContext) {
    Token start = token;
    TypeParamOrArgInfo typeArg =
        computeTypeParamOrArg(token, /* inDeclaration = */ true);
    Token next = typeArg.skip(token).next!;
    switch (next.lexeme) {
      case '[]':
      case '[':
        // listPattern ::= typeArguments? '[' patterns? ']'
        token = typeArg.parseArguments(token, this);
        token = parseListPatternSuffix(token, patternContext);
        // A list pattern is a valid form of outerPattern, so verify that
        // skipOuterPattern would have skipped this pattern properly.
        assert(
            identical(inhibitPrinting(() => skipOuterPattern(start)), token));
        return token;
      case '{':
        // mapPattern        ::= typeArguments? '{' mapPatternEntries? '}'
        // mapPatternEntries ::= mapPatternEntry ( ',' mapPatternEntry )* ','?
        // mapPatternEntry   ::= expression ':' pattern
        token = typeArg.parseArguments(token, this);
        token = parseMapPatternSuffix(token, patternContext);
        // A map pattern is a valid form of outerPattern, so verify that
        // skipOuterPattern would have skipped this pattern properly.
        assert(
            identical(inhibitPrinting(() => skipOuterPattern(start)), token));
        return token;
    }
    // Whatever was after the optional type arguments didn't parse as a pattern
    // that can start with type arguments, so back up and reparse assuming that
    // we weren't looking at type arguments after all.
    next = token.next!;
    switch (next.lexeme) {
      case 'var':
      case 'final':
        // variablePattern ::= ( 'var' | 'final' | 'final'? type )? identifier
        return parseVariablePattern(token, patternContext);
      case '(':
        // "(" could start a record type (which has to be followed by an
        // identifier though), e.g. `(int, int) foo`.
        if (next.endGroup!.next!.isIdentifier) {
          TypeInfo typeInfo = computeVariablePatternType(token);
          if (typeInfo is ComplexTypeInfo &&
              typeInfo.isRecordType &&
              !typeInfo.recovered) {
            return parseVariablePattern(token, patternContext,
                typeInfo: typeInfo);
          }
        }
        // parenthesizedPattern  ::= '(' pattern ')'
        // recordPattern         ::= '(' patternFields? ')'
        // patternFields         ::= patternField ( ',' patternField )* ','?
        // patternField          ::= ( identifier? ':' )? pattern
        Token nextNext = next.next!;
        if (optional(')', nextNext)) {
          listener.handleRecordPattern(next, /* count = */ 0);
          token = nextNext;
        } else {
          token =
              parseParenthesizedPatternOrRecordPattern(token, patternContext);
        }
        // A record or parenthesized pattern is a valid form of outerPattern, so
        // verify that skipOuterPattern would have skipped this pattern
        // properly.
        assert(
            identical(inhibitPrinting(() => skipOuterPattern(start)), token));
        return token;
      case 'const':
        // constantPattern ::= booleanLiteral
        //                   | nullLiteral
        //                   | '-'? numericLiteral
        //                   | stringLiteral
        //                   | identifier
        //                   | qualifiedName
        //                   | constObjectExpression
        //                   | 'const' typeArguments? '[' elements? ']'
        //                   | 'const' typeArguments? '{' elements? '}'
        //                   | 'const' '(' expression ')'
        Token const_ = next;
        listener.beginConstantPattern(const_);
        // The supported precedence is [SELECTOR_PRECEDENCE] but for better
        // error recovery we allow for parsing [EQUALITY_PRECEDENCE] and higher,
        // and report an error in [_parsePrecedenceExpressionLoop] instead.
        token = parsePrecedenceExpression(const_, EQUALITY_PRECEDENCE,
            /* allowCascades = */ false, ConstantPatternContext.explicit);
        listener.endConstantPattern(const_);
        return token;
    }
    TokenType type = next.type;
    if (type.isRelationalOperator || type.isEqualityOperator) {
      // TODO(paulberry): maybe handle other operators for error recovery?
      Token operator = next;
      // Note: the spec says we should use RELATIONAL_PRECEDENCE here, but
      // that leads to parsing ambiguities.  So we use SHIFT_PRECEDENCE, as
      // suggested in https://github.com/dart-lang/language/issues/2501.
      // TODO(paulberry): update this code if necessary when that issue is
      // resolved.
      token = parsePrecedenceExpression(next, SHIFT_PRECEDENCE,
          /* allowCascades = */ false, ConstantPatternContext.none);
      listener.handleRelationalPattern(operator);
      return token;
    }
    TypeInfo typeInfo = computeVariablePatternType(token);
    if (typeInfo != noType) {
      return parseVariablePattern(token, patternContext, typeInfo: typeInfo);
    }
    // objectPattern ::= typeName typeArguments? '(' patternFields? ')'
    // TODO(paulberry): Make sure OTHER_IDENTIFIER is handled
    // TODO(paulberry): Technically `dynamic` is valid for
    // `typeIdentifier`--file an issue
    if (next.isIdentifier) {
      Token beforeFirstIdentifier = token;
      Token firstIdentifier = token = next;
      next = token.next!;
      Token? dot;
      Token? secondIdentifier;
      if (optional('.', next)) {
        dot = token = next;
        next = token.next!;
        if (next.isIdentifier) {
          secondIdentifier = token = next;
          // TODO(paulberry): grammar specifies
          // `typeIdentifier | qualifiedName`, but that permits `a.b.c`,
          // which doesn't make sense.
        } else {
          throw new UnimplementedError('TODO(paulberry)');
        }
      }
      TypeParamOrArgInfo potentialTypeArg = computeTypeParamOrArg(token);
      Token afterToken = potentialTypeArg.skip(token).next!;
      if (optional('(', afterToken) && !potentialTypeArg.recovered) {
        TypeParamOrArgInfo typeArg = potentialTypeArg;
        token = typeArg.parseArguments(token, this);
        token = parseObjectPatternRest(token, patternContext);
        listener.handleObjectPattern(firstIdentifier, dot, secondIdentifier);
        // An object pattern is a valid form of outerPattern, so verify that
        // skipOuterPattern would have skipped this pattern properly.
        assert(
            identical(inhibitPrinting(() => skipOuterPattern(start)), token));
        return token;
      } else if (dot == null) {
        // It's a single identifier.  If it's a wildcard pattern or we're in an
        // irrefutable context, parse it as a variable pattern.
        if (!patternContext.isRefutable || firstIdentifier.lexeme == '_') {
          // It's a wildcard pattern with no preceding type, so parse it as a
          // variable pattern.
          return parseVariablePattern(beforeFirstIdentifier, patternContext,
              typeInfo: typeInfo);
        }
      }
      // It's not an object pattern so parse it as an expression.
      token = beforeFirstIdentifier;
    }
    listener.beginConstantPattern(/* constKeyword = */ null);
    // The supported precedence is [SELECTOR_PRECEDENCE] but for better
    // error recovery we allow for parsing [EQUALITY_PRECEDENCE] and higher,
    // and report an error in [_parsePrecedenceExpressionLoop] instead.
    token = parsePrecedenceExpression(token, EQUALITY_PRECEDENCE,
        /* allowCascades = */ false, ConstantPatternContext.implicit);
    listener.endConstantPattern(/* constKeyword = */ null);
    return token;
  }

  /// Parses variable pattern starting after [token].  [typeInfo] is information
  /// about the type appearing after [token], if any.
  ///
  /// variablePattern ::= ( 'var' | 'final' | 'final'? type )? identifier
  Token parseVariablePattern(Token token, PatternContext patternContext,
      {TypeInfo typeInfo = noType}) {
    Token? keyword;
    if (typeInfo != noType) {
      token = typeInfo.parseType(token, this);
    } else {
      Token next = token.next!;
      if (optional('var', next) || optional('final', next)) {
        token = keyword = next;
        bool nextIsParen = optional("(", token.next!);
        // TODO(paulberry): this accepts `var <type> name` as a variable
        // pattern.  We want to accept that for error recovery, but don't forget
        // to report the appropriate error.
        typeInfo = computeVariablePatternType(token, nextIsParen);
        token = typeInfo.parseType(token, this);
      } else {
        // Bare identifier pattern
        listener.handleNoType(token);
      }
    }
    Token next = token.next!;
    if (next.isIdentifier) {
      token = next;
    } else {
      // Recovery
      token = insertSyntheticIdentifier(
          token, IdentifierContext.localVariableDeclaration);
    }
    listener.handleVariablePattern(keyword, token,
        inAssignmentPattern: patternContext == PatternContext.assignment);
    return token;
  }

  /// This method parses the portion of a list pattern starting with the left
  /// bracket.
  ///
  /// listPattern ::= typeArguments? '[' patterns? ']'
  Token parseListPatternSuffix(Token token, PatternContext patternContext) {
    Token beforeToken = token;
    Token beginToken = token = token.next!;
    assert(optional('[', token) || optional('[]', token));
    int count = 0;
    if (optional('[]', token)) {
      token = rewriteSquareBrackets(beforeToken).next!;
      listener.handleListPattern(
        /* count = */ 0,
        token,
        token.next!,
      );
      return token.next!;
    }
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    while (true) {
      Token next = token.next!;
      if (optional(']', next)) {
        token = next;
        break;
      }
      if (optional('...', next)) {
        Token dots = next;
        token = next;
        next = token.next!;
        bool hasSubPattern = looksLikePatternStart(next);
        if (hasSubPattern) {
          token = parsePattern(token, patternContext);
        }
        listener.handleRestPattern(dots, hasSubPattern: hasSubPattern);
      } else {
        token = parsePattern(token, patternContext);
      }
      next = token.next!;
      ++count;
      if (!optional(',', next)) {
        if (optional(']', next)) {
          token = next;
          break;
        }

        // TODO(paulberry): test this error recovery logic
        // Recovery
        if (!looksLikeLiteralEntry(next)) {
          if (beginToken.endGroup!.isSynthetic) {
            // The scanner has already reported an error,
            // but inserted `]` in the wrong place.
            token = rewriter.moveSynthetic(token, beginToken.endGroup!);
          } else {
            // Report an error and jump to the end of the list.
            reportRecoverableError(
                next, codes.templateExpectedButGot.withArguments(']'));
            token = beginToken.endGroup!;
          }
          break;
        }
        // This looks like the start of an expression.
        // Report an error, insert the comma, and continue parsing.
        SyntheticToken comma = new SyntheticToken(TokenType.COMMA, next.offset);
        codes.Message message = codes.templateExpectedButGot.withArguments(',');
        next = rewriteAndRecover(token, message, comma);
      }
      token = next;
    }
    listener.handleListPattern(count, beginToken, token);
    mayParseFunctionExpressions = old;
    return token;
  }

  /// This method parses the portion of a map pattern starting with the left
  /// curly brace.
  ///
  /// mapPattern        ::= typeArguments? '{' mapPatternEntries? '}'
  /// mapPatternEntries ::= mapPatternEntry ( ',' mapPatternEntry )* ','?
  /// mapPatternEntry   ::= expression ':' pattern
  Token parseMapPatternSuffix(Token token, PatternContext patternContext) {
    Token leftBrace = token = token.next!;
    assert(optional('{', leftBrace));
    Token next = token.next!;
    if (optional('}', next)) {
      listener.handleMapPattern(/* count = */ 0, leftBrace, next);
      return next;
    }

    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    int count = 0;
    while (true) {
      if (optional('...', next)) {
        Token dots = next;
        token = next;
        next = token.next!;
        bool hasSubPattern = looksLikePatternStart(next);
        if (hasSubPattern) {
          token = parsePattern(token, patternContext);
        }
        listener.handleRestPattern(dots, hasSubPattern: hasSubPattern);
      } else {
        token = parseExpression(token);
        Token colon = token.next!;
        if (!optional(':', colon)) {
          // TODO(paulberry): test this error recovery logic
          // Recover from a missing colon by inserting one.
          colon = rewriteAndRecover(
              token,
              codes.templateExpectedButGot.withArguments(':'),
              new SyntheticToken(TokenType.COLON, next.charOffset));
        }
        token = parsePattern(colon, patternContext);
        listener.handleMapPatternEntry(colon, token.next!);
      }
      ++count;
      next = token.next!;

      Token? comma;
      if (optional(',', next)) {
        comma = token = next;
        next = token.next!;
      }
      if (optional('}', next)) {
        break;
      }

      if (comma == null) {
        // TODO(paulberry): test this error recovery logic
        // Recovery
        if (looksLikeLiteralEntry(next)) {
          // If this looks like the start of an expression,
          // then report an error, insert the comma, and continue parsing.
          SyntheticToken comma =
              new SyntheticToken(TokenType.COMMA, next.offset);
          codes.Message message =
              codes.templateExpectedButGot.withArguments(',');
          token = rewriteAndRecover(token, message, comma);
        } else {
          reportRecoverableError(
              next, codes.templateExpectedButGot.withArguments('}'));
          // Scanner guarantees a closing curly bracket
          next = leftBrace.endGroup!;
          break;
        }
      }
    }
    mayParseFunctionExpressions = old;
    listener.handleMapPattern(count, leftBrace, next);
    return next;
  }

  /// Parses either a parenthesizedPattern or a recordPattern.
  ///
  /// parenthesizedPattern  ::= '(' pattern ')'
  /// recordPattern         ::= '(' patternFields? ')'
  /// patternFields         ::= patternField ( ',' patternField )* ','?
  /// patternField          ::= ( identifier? ':' )? pattern
  Token parseParenthesizedPatternOrRecordPattern(
      Token token, PatternContext patternContext) {
    Token begin = token.next!;
    assert(optional('(', begin));
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;

    token = begin;
    int count = 0;
    bool wasRecord = false;
    bool wasValidRecord = false;
    while (true) {
      Token next = token.next!;
      if ((count > 0 || wasRecord) && optional(')', next)) {
        break;
      }
      Token? colon = null;
      // TODO(paulberry): test error recovery
      if (optional(':', next)) {
        wasRecord = true;
        wasValidRecord = true;
        listener.handleNoName(token);
        colon = token = next;
      } else if (optional(':', next.next!) || /* recovery */
          optional(':', next)) {
        // Record with named expression.
        wasRecord = true;
        token = ensureIdentifier(
          token,
          IdentifierContext.namedRecordFieldReference,
        ).next!;
        colon = token;
        wasValidRecord = true;
      }
      token = parsePattern(token, patternContext);
      next = token.next!;
      if (wasRecord || colon != null) {
        listener.handlePatternField(colon);
      }
      ++count;
      if (!optional(',', next)) {
        // TODO(paulberry): make sure to test the error case where there's a
        // colon but it's not a record.
        break;
      } else {
        // It is a comma, i.e. it's a record.
        if (!wasRecord && colon == null) {
          listener.handlePatternField(colon);
        }
        wasRecord = true;
        wasValidRecord = true;
      }
      token = next;
    }
    token = ensureCloseParen(token, begin);
    assert(optional(')', token));

    assert(wasRecord || count <= 1);

    if (wasRecord) {
      if (count == 1 && !wasValidRecord) {
        reportRecoverableError(
            token, codes.messageRecordLiteralOnePositionalFieldNoTrailingComma);
      }
      listener.handleRecordPattern(begin, count);
    } else {
      listener.handleParenthesizedPattern(begin);
    }

    mayParseFunctionExpressions = old;
    return token;
  }

  /// Parses the rest of an objectPattern, where [token] is the token before the
  /// `(`.
  ///
  /// objectPattern ::= typeName typeArguments? '(' patternFields? ')'
  Token parseObjectPatternRest(Token token, PatternContext patternContext) {
    Token begin = token = token.next!;
    assert(optional('(', begin));
    int argumentCount = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    while (true) {
      Token next = token.next!;
      if (optional(')', next)) {
        token = next;
        break;
      }
      Token? colon = null;
      if (optional(':', next)) {
        listener.handleNoName(token);
        colon = token = next;
      } else if (optional(':', next.next!)) {
        token =
            ensureIdentifier(token, IdentifierContext.namedArgumentReference)
                .next!;
        colon = token;
      }
      token = parsePattern(token, patternContext);
      next = token.next!;
      listener.handlePatternField(colon);
      ++argumentCount;
      if (!optional(',', next)) {
        if (optional(')', next)) {
          token = next;
          break;
        }
        // TODO(paulberry): test error recovery
        // Recovery
        if (looksLikeExpressionStart(next)) {
          // If this looks like the start of an expression,
          // then report an error, insert the comma, and continue parsing.
          next = rewriteAndRecover(
              token,
              codes.templateExpectedButGot.withArguments(','),
              new SyntheticToken(TokenType.COMMA, next.offset));
        } else {
          token = ensureCloseParen(token, begin);
          break;
        }
      }
      token = next;
    }
    assert(optional(')', token));
    mayParseFunctionExpressions = old;
    listener.handleObjectPatternFields(argumentCount, begin, token);
    return token;
  }

  /// Returns `true` if the given [token] looks like an outer pattern followed
  /// by `=`.  This occurs in the following grammar productions:
  ///
  /// patternVariableDeclaration ::= ( 'final' | 'var' ) outerPattern '='
  ///                                expression
  /// patternAssignment ::= outerPattern '=' expression
  bool looksLikeOuterPatternEquals(Token token) {
    Token? afterOuterPattern = skipOuterPattern(token);
    if (afterOuterPattern == null) return false;
    return optional('=', afterOuterPattern.next!);
  }

  /// Tries to advance beyond an "outer pattern" starting from [token].  If the
  /// next construct after [token] is not an outer pattern, returns `null`.
  ///
  /// outerPattern ::= parenthesizedPattern
  ///                | listPattern
  ///                | mapPattern
  ///                | recordPattern
  ///                | objectPattern
  Token? skipOuterPattern(Token token) {
    Token next = token.next!;
    if (next.isIdentifier) {
      token = next;
      next = token.next!;
      if (!optional('.', next)) {
        return skipObjectPatternRest(token);
      }
      token = next;
      next = token.next!;
      if (next.isIdentifier) {
        return skipObjectPatternRest(next);
      } else {
        // IDENTIFIER `.` NON-IDENTIFIER (not a pattern)
        return null;
      }
    }
    TypeParamOrArgInfo typeParamOrArg = computeTypeParamOrArg(token);
    token = typeParamOrArg.skip(token);
    next = token.next!;
    if (optional('[]', next)) {
      // Empty list pattern
      return next;
    }
    if (optional('[', next) || optional('{', next)) {
      // List or map pattern
      return next.endGroup;
    }
    if (typeParamOrArg == noTypeParamOrArg && optional('(', next)) {
      // Record or parenthesized pattern
      return next.endGroup;
    }
    // Not an outer pattern
    return null;
  }

  /// Tries to advance through an object pattern, where [token] is the last
  /// token of the object pattern's type name.  If the tokens following
  /// [token] don't look like the rest of an object pattern, returns `null`.
  ///
  /// objectPattern ::= typeName typeArguments? '(' patternFields? ')'
  Token? skipObjectPatternRest(Token token) {
    TypeParamOrArgInfo typeParamOrArg = computeTypeParamOrArg(token);
    token = typeParamOrArg.skip(token);
    Token? next = token.next;
    if (next == null) return null;
    if (!optional('(', next)) return null;
    return next.endGroup;
  }

  /// patternVariableDeclaration ::= ( 'final' | 'var' ) outerPattern '='
  ///                                expression
  Token parsePatternVariableDeclarationStatement(
      Token keyword, Token start, Token varOrFinal) {
    Token token = parsePattern(keyword, PatternContext.declaration);
    Token equals = token.next!;
    // Caller should have assured that the pattern was followed by an `=`.
    assert(optional('=', equals));
    token = parseExpression(equals);
    Token semicolon = ensureSemicolon(token);
    listener.handlePatternVariableDeclarationStatement(
        keyword, equals, semicolon);
    return semicolon;
  }

  /// patternAssignment ::= outerPattern '=' expression
  Token parsePatternAssignment(Token token) {
    token = parsePattern(token, PatternContext.assignment);
    Token equals = token.next!;
    // Caller should have assured that the pattern was followed by an `=`.
    assert(optional('=', equals));
    token = parseExpression(equals);
    listener.handlePatternAssignment(equals);
    return token;
  }

  /// switchExpression    ::= 'switch' '(' expression ')' '{'
  ///                         switchExpressionCase ( ',' switchExpressionCase )*
  ///                             ','? '}'
  /// switchExpressionCase    ::= guardedPattern '=>' expression
  Token parseSwitchExpression(Token token) {
    Token switchKeyword = token.next!;
    assert(optional('switch', switchKeyword));
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    listener.beginSwitchExpression(switchKeyword);
    token = ensureParenthesizedCondition(switchKeyword, allowCase: false);
    Token beginSwitch =
        token = ensureBlock(token, /* template = */ null, 'switch expression');
    listener.beginSwitchExpressionBlock(beginSwitch);
    Token next = token.next!;
    int caseCount = 0;
    if (!optional('}', next)) {
      mayParseFunctionExpressions = false;
      while (true) {
        listener.beginSwitchExpressionCase();
        token = parsePattern(token, PatternContext.matching);
        listener.handleSwitchExpressionCasePattern(token);
        Token? when;
        next = token.next!;
        if (optional('when', next)) {
          when = token = next;
          token = parseExpression(token);
        }
        Token arrow = token = ensureFunctionArrow(token);
        mayParseFunctionExpressions = true;
        token = parseExpression(token);
        mayParseFunctionExpressions = false;
        listener.endSwitchExpressionCase(when, arrow, token);
        ++caseCount;
        next = token.next!;

        Token? comma;
        if (optional(',', next)) {
          comma = token = next;
          next = token.next!;
        }
        if (optional('}', next)) {
          break;
        }

        if (comma == null) {
          // TODO(paulberry): test this error recovery logic
          // Recovery
          if (looksLikePatternStart(next)) {
            // If this looks like the start of a pattern, then report an error,
            // insert the comma, and continue parsing.
            SyntheticToken comma =
                new SyntheticToken(TokenType.COMMA, next.offset);
            codes.Message message =
                codes.templateExpectedButGot.withArguments(',');
            token = rewriteAndRecover(token, message, comma);
          } else {
            reportRecoverableError(
                next, codes.templateExpectedButGot.withArguments('}'));
            // Scanner guarantees a closing curly bracket
            next = beginSwitch.endGroup!;
            break;
          }
        }
      }
    }
    listener.endSwitchExpressionBlock(caseCount, beginSwitch, next);
    mayParseFunctionExpressions = old;
    token = next;
    assert(token.isEof || optional('}', token));
    listener.endSwitchExpression(switchKeyword, token);
    return token;
  }
}

// TODO(ahe): Remove when analyzer supports generalized function syntax.
typedef _MessageWithArgument<T> = codes.Message Function(T);

enum AwaitOrYieldContext { Statement, UnaryExpression }

/// Data structure tracking additional information when parsing the
/// `forLoopParts` grammar production.
class ForPartsContext {
  /// If `forLoopParts` began with `( 'final' | 'var' ) outerPattern`, followed
  /// by either `=` or `in`, the `final` or `var` keyword.  Otherwise `null`.
  Token? patternKeyword;

  @override
  String toString() => 'ForPartsContext($patternKeyword)';
}

/// Enum describing the different contexts in which a pattern can occur.
enum PatternContext {
  /// The pattern is part of a localVariableDeclaration or forLoopParts, meaning
  /// bare identifiers refer to freshly declared variables.
  declaration(isRefutable: false),

  /// The pattern is part of a guardedPattern inside an if-case, switch
  /// expression, or switch statement, meaning bare identifiers refer to
  /// constants.
  matching(isRefutable: true),

  /// The pattern is part of a pattern assignment, meaning bare identifiers
  /// refer to previously declared variables.
  assignment(isRefutable: false);

  final bool isRefutable;

  const PatternContext({required this.isRefutable});
}

/// Enum describing the different contexts in which a constant pattern is
/// parsed.
///
/// This restricts what expressions are allowed.
enum ConstantPatternContext {
  /// A constant pattern is not currently being parsed.
  none,

  /// A constant pattern without a preceding `const` is being parsed.
  ///
  /// For instance `e` in
  ///
  ///     if (o case e) {}
  ///
  /// Here `e` can be any valid constant pattern, but not for instance
  /// expressions like `!foo`.
  implicit,

  /// A constant pattern with a preceding `const` is being parsed.
  ///
  /// For instance `e` in
  ///
  ///     if (o case const e) {}
  ///
  /// Here `e` cannot start with `const`.
  explicit,

  /// A constant pattern started with a `-` is being parsed.
  ///
  /// For instance `e` in
  ///
  ///     if (o case -e) {}
  ///
  /// Here `e` is only allowed to be a numeric literal.
  numericLiteralOnly,
}
