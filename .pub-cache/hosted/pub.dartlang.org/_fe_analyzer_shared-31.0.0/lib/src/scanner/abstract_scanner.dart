// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.abstract_scanner;

import 'dart:collection' show ListMixin;

import 'dart:typed_data' show Uint16List, Uint32List;

import 'token.dart'
    show BeginToken, Keyword, KeywordToken, SyntheticToken, Token, TokenType;

import 'token.dart' as analyzer show StringToken;

import '../messages/codes.dart'
    show
        messageExpectedHexDigit,
        messageMissingExponent,
        messageUnexpectedDollarInString,
        messageUnterminatedComment;

import '../util/link.dart' show Link;

import 'characters.dart';

import 'error_token.dart'
    show
        NonAsciiIdentifierToken,
        UnmatchedToken,
        UnsupportedOperator,
        UnterminatedString,
        UnterminatedToken;

import 'keyword_state.dart' show KeywordState;

import 'token_impl.dart'
    show CommentToken, DartDocToken, LanguageVersionToken, StringToken;

import 'token_constants.dart';

import 'scanner.dart'
    show ErrorToken, Keyword, Scanner, buildUnexpectedCharacterToken;

typedef void LanguageVersionChanged(
    Scanner scanner, LanguageVersionToken languageVersion);

abstract class AbstractScanner implements Scanner {
  /**
   * A flag indicating whether character sequences `&&=` and `||=`
   * should be tokenized as the assignment operators
   * [AMPERSAND_AMPERSAND_EQ_TOKEN] and [BAR_BAR_EQ_TOKEN] respectively.
   * See issue https://github.com/dart-lang/sdk/issues/30340
   */
  static const bool LAZY_ASSIGNMENT_ENABLED = false;

  final bool includeComments;

  /// Called when the scanner detects a language version comment
  /// so that the listener can update the scanner configuration
  /// based upon the specified language version.
  final LanguageVersionChanged? languageVersionChanged;

  /// Experimental flag for enabling scanning of the `extension` token.
  bool _enableExtensionMethods = false;

  /// Experimental flag for enabling scanning of NNBD tokens
  /// such as 'required' and 'late'.
  bool _enableNonNullable = false;

  /// Experimental flag for enabling scanning of `>>>`.
  /// See https://github.com/dart-lang/language/issues/61
  /// and https://github.com/dart-lang/language/issues/60
  bool _enableTripleShift = false;

  /**
   * The string offset for the next token that will be created.
   *
   * Note that in the [Utf8BytesScanner], [stringOffset] and [scanOffset] values
   * are different. One string character can be encoded using multiple UTF-8
   * bytes.
   */
  int tokenStart = -1;

  /**
   * A pointer to the token stream created by this scanner. The first token
   * is a special token and not part of the source file. This is an
   * implementation detail to avoids special cases in the scanner. This token
   * is not exposed to clients of the scanner, which are expected to invoke
   * [firstToken] to access the token stream.
   */
  final Token tokens = new Token.eof(/* offset = */ -1);

  /**
   * A pointer to the last scanned token.
   */
  late Token tail;

  /**
   * A pointer to the last prepended error token.
   */
  late Token errorTail;

  bool hasErrors = false;

  /**
   * A pointer to the stream of comment tokens created by this scanner
   * before they are assigned to the [Token] precedingComments field
   * of a non-comment token. A value of `null` indicates no comment tokens.
   */
  CommentToken? comments;

  /**
   * A pointer to the last scanned comment token or `null` if none.
   */
  Token? commentsTail;

  final List<int> lineStarts;

  /**
   * The stack of open groups, e.g [: { ... ( .. :]
   * Each BeginToken has a pointer to the token where the group
   * ends. This field is set when scanning the end group token.
   */
  Link<BeginToken> groupingStack = const Link<BeginToken>();

  final bool inRecoveryOption;
  int recoveryCount = 0;

  AbstractScanner(ScannerConfiguration? config, this.includeComments,
      this.languageVersionChanged,
      {int? numberOfBytesHint})
      : lineStarts = new LineStarts(numberOfBytesHint),
        inRecoveryOption = false {
    this.tail = this.tokens;
    this.errorTail = this.tokens;
    this.configuration = config;
  }

  AbstractScanner createRecoveryOptionScanner();

  AbstractScanner.recoveryOptionScanner(AbstractScanner copyFrom)
      : lineStarts = [],
        includeComments = false,
        languageVersionChanged = null,
        inRecoveryOption = true {
    this.tail = this.tokens;
    this.errorTail = this.tokens;
    this._enableExtensionMethods = copyFrom._enableExtensionMethods;
    this._enableNonNullable = copyFrom._enableNonNullable;
    this._enableTripleShift = copyFrom._enableTripleShift;
    this.tokenStart = copyFrom.tokenStart;
    this.groupingStack = copyFrom.groupingStack;
  }

  @override
  set configuration(ScannerConfiguration? config) {
    if (config != null) {
      _enableExtensionMethods = config.enableExtensionMethods;
      _enableNonNullable = config.enableNonNullable;
      _enableTripleShift = config.enableTripleShift;
    }
  }

  /**
   * Advances and returns the next character.
   *
   * If the next character is non-ASCII, then the returned value depends on the
   * scanner implementation. The [Utf8BytesScanner] returns a UTF-8 byte, while
   * the [StringScanner] returns a UTF-16 code unit.
   *
   * The scanner ensures that [advance] is not invoked after it returned [$EOF].
   * This allows implementations to omit bound checks if the data structure ends
   * with '0'.
   */
  int advance();

  /**
   * Returns the current unicode character.
   *
   * If the current character is ASCII, then it is returned unchanged.
   *
   * The [Utf8BytesScanner] decodes the next unicode code point starting at the
   * current position. Note that every unicode character is returned as a single
   * code point, that is, for '\u{1d11e}' it returns 119070, and the following
   * [advance] returns the next character.
   *
   * The [StringScanner] returns the current character unchanged, which might
   * be a surrogate character. In the case of '\u{1d11e}', it returns the first
   * code unit 55348, and the following [advance] returns the second code unit
   * 56606.
   *
   * Invoking [currentAsUnicode] multiple times is safe, i.e.,
   * [:currentAsUnicode(next) == currentAsUnicode(currentAsUnicode(next)):].
   */
  int currentAsUnicode(int next);

  /**
   * Returns the character at the next position. Like in [advance], the
   * [Utf8BytesScanner] returns a UTF-8 byte, while the [StringScanner] returns
   * a UTF-16 code unit.
   */
  int peek();

  /**
   * Notifies the scanner that unicode characters were detected in either a
   * comment or a string literal between [startScanOffset] and the current
   * scan offset.
   */
  void handleUnicode(int startScanOffset);

  /**
   * Returns the current scan offset.
   *
   * In the [Utf8BytesScanner] this is the offset into the byte list, in the
   * [StringScanner] the offset in the source string.
   */
  int get scanOffset;

  /**
   * Returns the current string offset.
   *
   * In the [StringScanner] this is identical to the [scanOffset]. In the
   * [Utf8BytesScanner] it is computed based on encountered UTF-8 characters.
   */
  int get stringOffset;

  /**
   * Returns the first token scanned by this [Scanner].
   */
  Token firstToken() => tokens.next!;

  /**
   * Notifies that a new token starts at current offset.
   */
  void beginToken() {
    tokenStart = stringOffset;
  }

  /**
   * Appends a substring from the scan offset [:start:] to the current
   * [:scanOffset:] plus the [:extraOffset:]. For example, if the current
   * scanOffset is 10, then [:appendSubstringToken(5, -1):] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  void appendSubstringToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]) {
    appendToken(createSubstringToken(type, start, asciiOnly, extraOffset));
  }

  /**
   * Returns a new substring from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  analyzer.StringToken createSubstringToken(
      TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]);

  /**
   * Appends a substring from the scan offset [start] to the current
   * [scanOffset] plus [syntheticChars]. The additional char(s) will be added
   * to the unterminated string literal's lexeme but the returned
   * token's length will *not* include those additional char(s)
   * so as to be true to the original source.
   */
  void appendSyntheticSubstringToken(
      TokenType type, int start, bool asciiOnly, String syntheticChars) {
    appendToken(
        createSyntheticSubstringToken(type, start, asciiOnly, syntheticChars));
  }

  /**
   * Returns a new synthetic substring from the scan offset [start]
   * to the current [scanOffset] plus the [syntheticChars].
   * The [syntheticChars] are appended to the unterminated string
   * literal's lexeme but the returned token's length will *not* include
   * those additional characters so as to be true to the original source.
   */
  analyzer.StringToken createSyntheticSubstringToken(
      TokenType type, int start, bool asciiOnly, String syntheticChars);
  /**
   * Appends a fixed token whose kind and content is determined by [type].
   * Appends an *operator* token from [type].
   *
   * An operator token represent operators like ':', '.', ';', '&&', '==', '--',
   * '=>', etc.
   */
  void appendPrecedenceToken(TokenType type) {
    appendToken(new Token(type, tokenStart, comments));
  }

  /**
   * Appends a fixed token based on whether the current char is [choice] or not.
   * If the current char is [choice] a fixed token whose kind and content
   * is determined by [yes] is appended, otherwise a fixed token whose kind
   * and content is determined by [no] is appended.
   */
  int select(int choice, TokenType yes, TokenType no) {
    int next = advance();
    if (identical(next, choice)) {
      appendPrecedenceToken(yes);
      return advance();
    } else {
      appendPrecedenceToken(no);
      return next;
    }
  }

  /**
   * Appends a keyword token whose kind is determined by [keyword].
   */
  void appendKeywordToken(Keyword keyword) {
    String syntax = keyword.lexeme;
    // Type parameters and arguments cannot contain 'this'.
    if (identical(syntax, 'this')) {
      discardOpenLt();
    }
    appendToken(new KeywordToken(keyword, tokenStart, comments));
  }

  void appendEofToken() {
    beginToken();
    discardOpenLt();
    while (!groupingStack.isEmpty) {
      unmatchedBeginGroup(groupingStack.head);
      groupingStack = groupingStack.tail!;
    }
    appendToken(new Token.eof(tokenStart, comments));
  }

  /**
   * Notifies scanning a whitespace character. Note that [appendWhiteSpace] is
   * not always invoked for [$SPACE] characters.
   *
   * This method is used by the scanners to track line breaks and create the
   * [lineStarts] map.
   */
  void appendWhiteSpace(int next) {
    if (next == $LF) {
      lineStarts.add(stringOffset + 1); // +1, the line starts after the $LF.
    }
  }

  /**
   * Notifies on [$LF] characters in multi-line comments or strings.
   *
   * This method is used by the scanners to track line breaks and create the
   * [lineStarts] map.
   */
  void lineFeedInMultiline() {
    lineStarts.add(stringOffset + 1);
  }

  /**
   * Appends a token that begins a new group, represented by [type].
   * Group begin tokens are '{', '(', '[', '<' and '${'.
   */
  void appendBeginGroup(TokenType type) {
    BeginToken token = new BeginToken(type, tokenStart, comments);
    appendToken(token);

    // { [ ${ cannot appear inside a type parameters / arguments.
    if (!identical(type.kind, LT_TOKEN) &&
        !identical(type.kind, OPEN_PAREN_TOKEN)) {
      discardOpenLt();
    }
    groupingStack = groupingStack.prepend(token);
  }

  /**
   * Appends a token that begins an end group, represented by [type].
   * It handles the group end tokens '}', ')' and ']'. The tokens '>' and
   * '>>' are handled separately by [appendGt] and [appendGtGt].
   */
  int appendEndGroup(TokenType type, int openKind) {
    assert(!identical(openKind, LT_TOKEN)); // openKind is < for > and >>
    bool foundMatchingBrace = discardBeginGroupUntil(openKind);
    return appendEndGroupInternal(foundMatchingBrace, type, openKind);
  }

  /// Append the end group (parenthesis, bracket etc).
  /// If [foundMatchingBrace] is true the grouping stack (stack of parenthesis
  /// etc) is updated, otherwise it's left alone.
  /// In effect, if [foundMatchingBrace] is false this end token is basically
  /// ignored, i.e. not really seen as an end group.
  int appendEndGroupInternal(
      bool foundMatchingBrace, TokenType type, int openKind) {
    if (!foundMatchingBrace) {
      // No begin group. Leave the grouping stack alone and just continue.
      appendPrecedenceToken(type);
      return advance();
    }
    appendPrecedenceToken(type);
    Token close = tail;
    BeginToken begin = groupingStack.head;
    if (!identical(begin.kind, openKind)) {
      assert(begin.kind == STRING_INTERPOLATION_TOKEN &&
          openKind == OPEN_CURLY_BRACKET_TOKEN);
      // We're ending an interpolated expression.
      begin.endGroup = close;
      groupingStack = groupingStack.tail!;
      // Using "start-of-text" to signal that we're back in string
      // scanning mode.
      return $STX;
    }
    begin.endGroup = close;
    groupingStack = groupingStack.tail!;
    return advance();
  }

  /**
   * Appends a token for '>'.
   * This method does not issue unmatched errors, because > is also the
   * greater-than operator. It does not necessarily have to close a group.
   */
  void appendGt(TokenType type) {
    appendPrecedenceToken(type);
    if (groupingStack.isEmpty) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail!;
    }
  }

  /**
   * Appends a token for '>>'.
   * This method does not issue unmatched errors, because >> is also the
   * shift operator. It does not necessarily have to close a group.
   */
  void appendGtGt(TokenType type) {
    appendPrecedenceToken(type);
    if (groupingStack.isEmpty) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      // Don't assign endGroup: in "T<U<V>>", the '>>' token closes the outer
      // '<', the inner '<' is left without endGroup.
      groupingStack = groupingStack.tail!;
    }
    if (groupingStack.isEmpty) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail!;
    }
  }

  /// Prepend [token] to the token stream.
  void prependErrorToken(ErrorToken token) {
    hasErrors = true;
    if (errorTail == tail) {
      appendToken(token);
      errorTail = tail;
    } else {
      token.next = errorTail.next;
      token.next!.previous = token;
      errorTail.next = token;
      token.previous = errorTail;
      errorTail = errorTail.next!;
    }
  }

  /**
   * Returns a new comment from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  CommentToken createCommentToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]);

  /**
   * Returns a new dartdoc from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  DartDocToken createDartDocToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]);

  /**
   * Returns a new language version token from the scan offset [start]
   * to the current [scanOffset] similar to createCommentToken.
   */
  LanguageVersionToken createLanguageVersionToken(
      int start, int major, int minor);

  /**
   * If a begin group token matches [openKind],
   * then discard begin group tokens up to that match and return `true`,
   * otherwise return `false`.
   * This recovers nicely from from situations like "{[}" and "{foo());}",
   * but not "foo(() {bar());});"
   */
  bool discardBeginGroupUntil(int openKind) {
    Link<BeginToken> originalStack = groupingStack;

    bool first = true;
    do {
      // Don't report unmatched errors for <; it is also the less-than operator.
      discardOpenLt();
      if (groupingStack.isEmpty) break; // recover
      BeginToken begin = groupingStack.head;
      if (openKind == begin.kind ||
          (openKind == OPEN_CURLY_BRACKET_TOKEN &&
              begin.kind == STRING_INTERPOLATION_TOKEN)) {
        if (first) {
          // If the expected opener has been found on the first pass
          // then no recovery necessary.
          return true;
        }
        break; // recover
      }
      first = false;
      groupingStack = groupingStack.tail!;
    } while (!groupingStack.isEmpty);

    recoveryCount++;

    // If the stack does not have any opener of the given type,
    // then return without discarding anything.
    // This recovers nicely from from situations like "{foo());}".
    if (groupingStack.isEmpty) {
      groupingStack = originalStack;
      return false;
    }

    // We found a matching group somewhere in the stack, but generally don't
    // know if we should recover by inserting synthetic closers or
    // basically ignore the current token.
    // We're in a recovery setting so we're allowed to be 'relatively slow' ---
    // try both and see which is better (i.e. gives fewest rewrites later).
    // To not get exponential runtime we will not do this nested though.
    // E.g. we can recover "{[}" as "{[]}" (better) or (with . for ignored
    // tokens) "{[.".
    // Or we can recover "[(])]" as "[()].." or "[(.)]" (better).
    if (!inRecoveryOption) {
      TokenType type;
      switch (openKind) {
        case OPEN_SQUARE_BRACKET_TOKEN:
          type = TokenType.CLOSE_SQUARE_BRACKET;
          break;
        case OPEN_CURLY_BRACKET_TOKEN:
          type = TokenType.CLOSE_CURLY_BRACKET;
          break;
        case OPEN_PAREN_TOKEN:
          type = TokenType.CLOSE_PAREN;
          break;
        default:
          throw new StateError("Unexpected openKind");
      }

      // Option #1: Insert synthetic closers.
      int option1Recoveries;
      {
        AbstractScanner option1 = createRecoveryOptionScanner();
        option1.insertSyntheticClosers(originalStack, groupingStack);
        option1Recoveries =
            option1.recoveryOptionTokenizer(option1.appendEndGroupInternal(
                /* foundMatchingBrace = */ true,
                type,
                openKind));
        option1Recoveries += option1.groupingStack.slowLength();
      }

      // Option #2: ignore this token.
      int option2Recoveries;
      {
        AbstractScanner option2 = createRecoveryOptionScanner();
        option2.groupingStack = originalStack;
        option2Recoveries =
            option2.recoveryOptionTokenizer(option2.appendEndGroupInternal(
                /* foundMatchingBrace = */ false,
                type,
                openKind));
        // We add 1 to make this option pay for ignoring this token.
        option2Recoveries += option2.groupingStack.slowLength() + 1;
      }

      // The option-runs might have set invalid endGroup pointers. Reset them.
      for (Link<BeginToken> link = originalStack;
          link.isNotEmpty;
          link = link.tail!) {
        link.head.endToken = null;
      }

      if (option2Recoveries < option1Recoveries) {
        // Perform option #2 recovery.
        groupingStack = originalStack;
        return false;
      }
      // option #1 is the default, so fall though.
    }

    // Insert synthetic closers and report errors for any unbalanced openers.
    // This recovers nicely from from situations like "{[}".
    insertSyntheticClosers(originalStack, groupingStack);
    return true;
  }

  void insertSyntheticClosers(
      Link<BeginToken> originalStack, Link<BeginToken> entryToUse) {
    // Insert synthetic closers and report errors for any unbalanced openers.
    // This recovers nicely from from situations like "{[}".
    while (!identical(originalStack, entryToUse)) {
      // Don't report unmatched errors for <; it is also the less-than operator.
      if (!identical(entryToUse.head.kind, LT_TOKEN)) {
        unmatchedBeginGroup(originalStack.head);
      }
      originalStack = originalStack.tail!;
    }
  }

  /**
   * This method is called to discard '<' from the "grouping" stack.
   *
   * [PartialParser.skipExpression] relies on the fact that we do not
   * create groups for stuff like:
   * [:a = b < c, d = e > f:].
   *
   * In other words, this method is called when the scanner recognizes
   * something which cannot possibly be part of a type parameter/argument
   * list, like the '=' in the above example.
   */
  void discardOpenLt() {
    while (!groupingStack.isEmpty &&
        identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack = groupingStack.tail!;
    }
  }

  /**
   * This method is called to discard '${' from the "grouping" stack.
   *
   * This method is called when the scanner finds an unterminated
   * interpolation expression.
   */
  void discardInterpolation() {
    while (!groupingStack.isEmpty) {
      BeginToken beginToken = groupingStack.head;
      unmatchedBeginGroup(beginToken);
      groupingStack = groupingStack.tail!;
      if (identical(beginToken.kind, STRING_INTERPOLATION_TOKEN)) break;
    }
  }

  void unmatchedBeginGroup(BeginToken begin) {
    // We want to ensure that unmatched BeginTokens are reported as
    // errors.  However, the diet parser assumes that groups are well-balanced
    // and will never look at the endGroup token.  This is a nice property that
    // allows us to skip quickly over correct code. By inserting an additional
    // synthetic token in the stream, we can keep ignoring endGroup tokens.
    //
    // [begin] --next--> [tail]
    // [begin] --endG--> [synthetic] --next--> [next] --next--> [tail]
    //
    // This allows the diet parser to skip from [begin] via endGroup to
    // [synthetic] and ignore the [synthetic] token (assuming it's correct),
    // then the error will be reported when parsing the [next] token.
    //
    // For example, tokenize("{[1};") produces:
    //
    // SymbolToken({) --endGroup------------------------+
    //      |                                           |
    //     next                                         |
    //      v                                           |
    // SymbolToken([) --endGroup--+                     |
    //      |                     |                     |
    //     next                   |                     |
    //      v                     |                     |
    // StringToken(1)             |                     |
    //      |                     |                     |
    //     next                   |                     |
    //      v                     |                     |
    // SymbolToken(])<------------+ <-- Synthetic token |
    //      |                                           |
    //     next                                         |
    //      v                                           |
    // UnmatchedToken([)                                |
    //      |                                           |
    //     next                                         |
    //      v                                           |
    // SymbolToken(})<----------------------------------+
    //      |
    //     next
    //      v
    // SymbolToken(;)
    //      |
    //     next
    //      v
    //     EOF
    TokenType type = closeBraceInfoFor(begin);
    appendToken(new SyntheticToken(type, tokenStart)..beforeSynthetic = tail);
    begin.endGroup = tail;
    prependErrorToken(new UnmatchedToken(begin));
    recoveryCount++;
  }

  /// Return true when at EOF.
  bool atEndOfFile();

  Token tokenize() {
    while (!atEndOfFile()) {
      int next = advance();

      // Scan the header looking for a language version
      if (!identical(next, $EOF)) {
        Token oldTail = tail;
        next = bigHeaderSwitch(next);
        if (!identical(next, $EOF) && tail.kind == SCRIPT_TOKEN) {
          oldTail = tail;
          next = bigHeaderSwitch(next);
        }
        while (!identical(next, $EOF) && tail == oldTail) {
          next = bigHeaderSwitch(next);
        }
        next = next;
      }

      while (!identical(next, $EOF)) {
        next = bigSwitch(next);
      }
      if (atEndOfFile()) {
        appendEofToken();
      } else {
        unexpectedEof();
      }
    }

    // Always pretend that there's a line at the end of the file.
    lineStarts.add(stringOffset + 1);

    return firstToken();
  }

  /// Tokenize a (small) part of the data. Used for recovery "option testing".
  ///
  /// Returns the number of recoveries performed.
  int recoveryOptionTokenizer(int next) {
    int iterations = 0;
    while (!atEndOfFile()) {
      while (!identical(next, $EOF)) {
        // TODO(jensj): Look at number of lines, tokens, parenthesis stack,
        // semi-colon etc, not just number of iterations.
        next = bigSwitch(next);
        iterations++;

        if (iterations > 100) {
          return recoveryCount;
        }
      }
      if (!atEndOfFile()) {
        // $EOF in the middle of the file. Skip it as `tokenize`.
        next = advance();
        iterations++;

        if (iterations > 100) {
          return recoveryCount;
        }
      }
    }
    return recoveryCount;
  }

  int bigHeaderSwitch(int next) {
    if (!identical(next, $SLASH)) {
      return bigSwitch(next);
    }
    beginToken();
    if (!identical($SLASH, peek())) {
      return tokenizeSlashOrComment(next);
    }
    return tokenizeLanguageVersionOrSingleLineComment(next);
  }

  int bigSwitch(int next) {
    beginToken();
    if (identical(next, $SPACE) ||
        identical(next, $TAB) ||
        identical(next, $LF) ||
        identical(next, $CR)) {
      appendWhiteSpace(next);
      next = advance();
      // Sequences of spaces are common, so advance through them fast.
      while (identical(next, $SPACE)) {
        // We don't invoke [:appendWhiteSpace(next):] here for efficiency,
        // assuming that it does not do anything for space characters.
        next = advance();
      }
      return next;
    }

    int nextLower = next | 0x20;

    if ($a <= nextLower && nextLower <= $z) {
      if (identical($r, next)) {
        return tokenizeRawStringKeywordOrIdentifier(next);
      }
      return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
    }

    if (identical(next, $CLOSE_PAREN)) {
      return appendEndGroup(TokenType.CLOSE_PAREN, OPEN_PAREN_TOKEN);
    }

    if (identical(next, $OPEN_PAREN)) {
      appendBeginGroup(TokenType.OPEN_PAREN);
      return advance();
    }

    if (identical(next, $SEMICOLON)) {
      appendPrecedenceToken(TokenType.SEMICOLON);
      // Type parameters and arguments cannot contain semicolon.
      discardOpenLt();
      return advance();
    }

    if (identical(next, $PERIOD)) {
      return tokenizeDotsOrNumber(next);
    }

    if (identical(next, $COMMA)) {
      appendPrecedenceToken(TokenType.COMMA);
      return advance();
    }

    if (identical(next, $EQ)) {
      return tokenizeEquals(next);
    }

    if (identical(next, $CLOSE_CURLY_BRACKET)) {
      return appendEndGroup(
          TokenType.CLOSE_CURLY_BRACKET, OPEN_CURLY_BRACKET_TOKEN);
    }

    if (identical(next, $SLASH)) {
      return tokenizeSlashOrComment(next);
    }

    if (identical(next, $OPEN_CURLY_BRACKET)) {
      appendBeginGroup(TokenType.OPEN_CURLY_BRACKET);
      return advance();
    }

    if (identical(next, $DQ) || identical(next, $SQ)) {
      return tokenizeString(next, scanOffset, /* raw = */ false);
    }

    if (identical(next, $_)) {
      return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
    }

    if (identical(next, $COLON)) {
      appendPrecedenceToken(TokenType.COLON);
      return advance();
    }

    if (identical(next, $LT)) {
      return tokenizeLessThan(next);
    }

    if (identical(next, $GT)) {
      return tokenizeGreaterThan(next);
    }

    if (identical(next, $BANG)) {
      return tokenizeExclamation(next);
    }

    if (identical(next, $OPEN_SQUARE_BRACKET)) {
      return tokenizeOpenSquareBracket(next);
    }

    if (identical(next, $CLOSE_SQUARE_BRACKET)) {
      return appendEndGroup(
          TokenType.CLOSE_SQUARE_BRACKET, OPEN_SQUARE_BRACKET_TOKEN);
    }

    if (identical(next, $AT)) {
      return tokenizeAt(next);
    }

    if (next >= $1 && next <= $9) {
      return tokenizeNumber(next);
    }

    if (identical(next, $AMPERSAND)) {
      return tokenizeAmpersand(next);
    }

    if (identical(next, $0)) {
      return tokenizeHexOrNumber(next);
    }

    if (identical(next, $QUESTION)) {
      return tokenizeQuestion(next);
    }

    if (identical(next, $BAR)) {
      return tokenizeBar(next);
    }

    if (identical(next, $PLUS)) {
      return tokenizePlus(next);
    }

    if (identical(next, $$)) {
      return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
    }

    if (identical(next, $MINUS)) {
      return tokenizeMinus(next);
    }

    if (identical(next, $STAR)) {
      return tokenizeMultiply(next);
    }

    if (identical(next, $CARET)) {
      return tokenizeCaret(next);
    }

    if (identical(next, $TILDE)) {
      return tokenizeTilde(next);
    }

    if (identical(next, $PERCENT)) {
      return tokenizePercent(next);
    }

    if (identical(next, $BACKPING)) {
      appendPrecedenceToken(TokenType.BACKPING);
      return advance();
    }

    if (identical(next, $BACKSLASH)) {
      appendPrecedenceToken(TokenType.BACKSLASH);
      return advance();
    }

    if (identical(next, $HASH)) {
      return tokenizeTag(next);
    }

    if (next < 0x1f) {
      return unexpected(next);
    }

    next = currentAsUnicode(next);

    return unexpected(next);
  }

  int tokenizeTag(int next) {
    // # or #!.*[\n\r]
    if (scanOffset == 0) {
      if (identical(peek(), $BANG)) {
        int start = scanOffset;
        bool asciiOnly = true;
        do {
          next = advance();
          if (next > 127) asciiOnly = false;
        } while (!identical(next, $LF) &&
            !identical(next, $CR) &&
            !identical(next, $EOF));
        if (!asciiOnly) handleUnicode(start);
        appendSubstringToken(TokenType.SCRIPT_TAG, start, asciiOnly);
        return next;
      }
    }
    appendPrecedenceToken(TokenType.HASH);
    return advance();
  }

  int tokenizeTilde(int next) {
    // ~ ~/ ~/=
    next = advance();
    if (identical(next, $SLASH)) {
      return select($EQ, TokenType.TILDE_SLASH_EQ, TokenType.TILDE_SLASH);
    } else {
      appendPrecedenceToken(TokenType.TILDE);
      return next;
    }
  }

  int tokenizeOpenSquareBracket(int next) {
    // [ [] []=
    next = advance();
    if (identical(next, $CLOSE_SQUARE_BRACKET)) {
      return select($EQ, TokenType.INDEX_EQ, TokenType.INDEX);
    }
    appendBeginGroup(TokenType.OPEN_SQUARE_BRACKET);
    return next;
  }

  int tokenizeCaret(int next) {
    // ^ ^=
    return select($EQ, TokenType.CARET_EQ, TokenType.CARET);
  }

  int tokenizeQuestion(int next) {
    // ? ?. ?.. ?? ??=
    next = advance();
    if (identical(next, $QUESTION)) {
      return select(
          $EQ, TokenType.QUESTION_QUESTION_EQ, TokenType.QUESTION_QUESTION);
    } else if (identical(next, $PERIOD)) {
      next = advance();
      if (_enableNonNullable) {
        if (identical($PERIOD, next)) {
          appendPrecedenceToken(TokenType.QUESTION_PERIOD_PERIOD);
          return advance();
        }
      }
      appendPrecedenceToken(TokenType.QUESTION_PERIOD);
      return next;
    } else {
      appendPrecedenceToken(TokenType.QUESTION);
      return next;
    }
  }

  int tokenizeBar(int next) {
    // | || |= ||=
    next = advance();
    if (identical(next, $BAR)) {
      next = advance();
      if (LAZY_ASSIGNMENT_ENABLED && identical(next, $EQ)) {
        appendPrecedenceToken(TokenType.BAR_BAR_EQ);
        return advance();
      }
      appendPrecedenceToken(TokenType.BAR_BAR);
      return next;
    } else if (identical(next, $EQ)) {
      appendPrecedenceToken(TokenType.BAR_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.BAR);
      return next;
    }
  }

  int tokenizeAmpersand(int next) {
    // && &= & &&=
    next = advance();
    if (identical(next, $AMPERSAND)) {
      next = advance();
      if (LAZY_ASSIGNMENT_ENABLED && identical(next, $EQ)) {
        appendPrecedenceToken(TokenType.AMPERSAND_AMPERSAND_EQ);
        return advance();
      }
      appendPrecedenceToken(TokenType.AMPERSAND_AMPERSAND);
      return next;
    } else if (identical(next, $EQ)) {
      appendPrecedenceToken(TokenType.AMPERSAND_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.AMPERSAND);
      return next;
    }
  }

  int tokenizePercent(int next) {
    // % %=
    return select($EQ, TokenType.PERCENT_EQ, TokenType.PERCENT);
  }

  int tokenizeMultiply(int next) {
    // * *=
    return select($EQ, TokenType.STAR_EQ, TokenType.STAR);
  }

  int tokenizeMinus(int next) {
    // - -- -=
    next = advance();
    if (identical(next, $MINUS)) {
      appendPrecedenceToken(TokenType.MINUS_MINUS);
      return advance();
    } else if (identical(next, $EQ)) {
      appendPrecedenceToken(TokenType.MINUS_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.MINUS);
      return next;
    }
  }

  int tokenizePlus(int next) {
    // + ++ +=
    next = advance();
    if (identical($PLUS, next)) {
      appendPrecedenceToken(TokenType.PLUS_PLUS);
      return advance();
    } else if (identical($EQ, next)) {
      appendPrecedenceToken(TokenType.PLUS_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.PLUS);
      return next;
    }
  }

  int tokenizeExclamation(int next) {
    // ! !=
    // !== is kept for user-friendly error reporting.

    next = advance();
    if (identical(next, $EQ)) {
      //was `return select($EQ, TokenType.BANG_EQ_EQ, TokenType.BANG_EQ);`
      int next = advance();
      if (identical(next, $EQ)) {
        appendPrecedenceToken(TokenType.BANG_EQ_EQ);
        prependErrorToken(new UnsupportedOperator(tail, tokenStart));
        return advance();
      } else {
        appendPrecedenceToken(TokenType.BANG_EQ);
        return next;
      }
    }
    appendPrecedenceToken(TokenType.BANG);
    return next;
  }

  int tokenizeEquals(int next) {
    // = == =>
    // === is kept for user-friendly error reporting.

    // Type parameters and arguments cannot contain any token that
    // starts with '='.
    discardOpenLt();

    next = advance();
    if (identical(next, $EQ)) {
      // was `return select($EQ, TokenType.EQ_EQ_EQ, TokenType.EQ_EQ);`
      int next = advance();
      if (identical(next, $EQ)) {
        appendPrecedenceToken(TokenType.EQ_EQ_EQ);
        prependErrorToken(new UnsupportedOperator(tail, tokenStart));
        return advance();
      } else {
        appendPrecedenceToken(TokenType.EQ_EQ);
        return next;
      }
    } else if (identical(next, $GT)) {
      appendPrecedenceToken(TokenType.FUNCTION);
      return advance();
    }
    appendPrecedenceToken(TokenType.EQ);
    return next;
  }

  int tokenizeGreaterThan(int next) {
    // > >= >> >>= >>> >>>=
    next = advance();
    if (identical($EQ, next)) {
      appendPrecedenceToken(TokenType.GT_EQ);
      return advance();
    } else if (identical($GT, next)) {
      next = advance();
      if (identical($EQ, next)) {
        appendPrecedenceToken(TokenType.GT_GT_EQ);
        return advance();
      } else if (_enableTripleShift && identical($GT, next)) {
        next = advance();
        if (_enableTripleShift && identical($EQ, next)) {
          appendPrecedenceToken(TokenType.GT_GT_GT_EQ);
          return advance();
        }
        appendPrecedenceToken(TokenType.GT_GT_GT);
        return next;
      } else {
        appendGtGt(TokenType.GT_GT);
        return next;
      }
    } else {
      appendGt(TokenType.GT);
      return next;
    }
  }

  int tokenizeLessThan(int next) {
    // < <= << <<=
    next = advance();
    if (identical($EQ, next)) {
      appendPrecedenceToken(TokenType.LT_EQ);
      return advance();
    } else if (identical($LT, next)) {
      return select($EQ, TokenType.LT_LT_EQ, TokenType.LT_LT);
    } else {
      appendBeginGroup(TokenType.LT);
      return next;
    }
  }

  int tokenizeNumber(int next) {
    int start = scanOffset;
    while (true) {
      next = advance();
      if ($0 <= next && next <= $9) {
        continue;
      } else if (identical(next, $e) || identical(next, $E)) {
        return tokenizeFractionPart(next, start);
      } else {
        if (identical(next, $PERIOD)) {
          int nextnext = peek();
          if ($0 <= nextnext && nextnext <= $9) {
            return tokenizeFractionPart(advance(), start);
          }
        }
        appendSubstringToken(TokenType.INT, start, /* asciiOnly = */ true);
        return next;
      }
    }
  }

  int tokenizeHexOrNumber(int next) {
    int x = peek();
    if (identical(x, $x) || identical(x, $X)) {
      return tokenizeHex(next);
    }
    return tokenizeNumber(next);
  }

  int tokenizeHex(int next) {
    int start = scanOffset;
    next = advance(); // Advance past the $x or $X.
    bool hasDigits = false;
    while (true) {
      next = advance();
      if (($0 <= next && next <= $9) ||
          ($A <= next && next <= $F) ||
          ($a <= next && next <= $f)) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          prependErrorToken(new UnterminatedToken(
              messageExpectedHexDigit, start, stringOffset));
          // Recovery
          appendSyntheticSubstringToken(
              TokenType.HEXADECIMAL, start, /* asciiOnly = */ true, "0");
          return next;
        }
        appendSubstringToken(
            TokenType.HEXADECIMAL, start, /* asciiOnly = */ true);
        return next;
      }
    }
  }

  int tokenizeDotsOrNumber(int next) {
    int start = scanOffset;
    next = advance();
    if (($0 <= next && next <= $9)) {
      return tokenizeFractionPart(next, start);
    } else if (identical($PERIOD, next)) {
      next = advance();
      if (identical(next, $PERIOD)) {
        next = advance();
        if (identical(next, $QUESTION)) {
          appendPrecedenceToken(TokenType.PERIOD_PERIOD_PERIOD_QUESTION);
          return advance();
        } else {
          appendPrecedenceToken(TokenType.PERIOD_PERIOD_PERIOD);
          return next;
        }
      } else {
        appendPrecedenceToken(TokenType.PERIOD_PERIOD);
        return next;
      }
    } else {
      appendPrecedenceToken(TokenType.PERIOD);
      return next;
    }
  }

  int tokenizeFractionPart(int next, int start) {
    bool done = false;
    bool hasDigit = false;
    LOOP:
    while (!done) {
      if ($0 <= next && next <= $9) {
        hasDigit = true;
      } else if (identical($e, next) || identical($E, next)) {
        hasDigit = true;
        next = advance();
        if (identical(next, $PLUS) || identical(next, $MINUS)) {
          next = advance();
        }
        bool hasExponentDigits = false;
        while (true) {
          if ($0 <= next && next <= $9) {
            hasExponentDigits = true;
          } else {
            if (!hasExponentDigits) {
              appendSyntheticSubstringToken(
                  TokenType.DOUBLE, start, /* asciiOnly = */ true, '0');
              prependErrorToken(new UnterminatedToken(
                  messageMissingExponent, tokenStart, stringOffset));
              return next;
            }
            break;
          }
          next = advance();
        }

        done = true;
        continue LOOP;
      } else {
        done = true;
        continue LOOP;
      }
      next = advance();
    }
    if (!hasDigit) {
      // Reduce offset, we already advanced to the token past the period.
      appendSubstringToken(
          TokenType.INT, start, /* asciiOnly = */ true, /* extraOffset = */ -1);

      // TODO(ahe): Wrong offset for the period. Cannot call beginToken because
      // the scanner already advanced past the period.
      if (identical($PERIOD, next)) {
        return select(
            $PERIOD, TokenType.PERIOD_PERIOD_PERIOD, TokenType.PERIOD_PERIOD);
      }
      appendPrecedenceToken(TokenType.PERIOD);
      return next;
    }
    appendSubstringToken(TokenType.DOUBLE, start, /* asciiOnly = */ true);
    return next;
  }

  int tokenizeSlashOrComment(int next) {
    int start = scanOffset;
    next = advance();
    if (identical($STAR, next)) {
      return tokenizeMultiLineComment(next, start);
    } else if (identical($SLASH, next)) {
      return tokenizeSingleLineComment(next, start);
    } else if (identical($EQ, next)) {
      appendPrecedenceToken(TokenType.SLASH_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.SLASH);
      return next;
    }
  }

  int tokenizeLanguageVersionOrSingleLineComment(int next) {
    int start = scanOffset;
    next = advance();

    // Dart doc
    if (identical($SLASH, peek())) {
      return tokenizeSingleLineComment(next, start);
    }

    // "@dart"
    next = advance();
    while (identical($SPACE, next)) {
      next = advance();
    }
    if (!identical($AT, next)) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if (!identical($d, next)) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if (!identical($a, next)) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if (!identical($r, next)) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if (!identical($t, next)) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();

    // "="
    while (identical($SPACE, next)) {
      next = advance();
    }
    if (!identical($EQ, next)) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();

    // major
    while (identical($SPACE, next)) {
      next = advance();
    }
    int major = 0;
    int majorStart = scanOffset;
    while (isDigit(next)) {
      major = major * 10 + next - $0;
      next = advance();
    }
    if (scanOffset == majorStart) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }

    // minor
    if (!identical($PERIOD, next)) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    int minor = 0;
    int minorStart = scanOffset;
    while (isDigit(next)) {
      minor = minor * 10 + next - $0;
      next = advance();
    }
    if (scanOffset == minorStart) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }

    // trailing spaces
    while (identical($SPACE, next)) {
      next = advance();
    }
    if (next != $LF && next != $CR && next != $EOF) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }

    LanguageVersionToken languageVersion =
        createLanguageVersionToken(start, major, minor);
    if (languageVersionChanged != null) {
      // TODO(danrubel): make this required and remove the languageVersion field
      languageVersionChanged!(this, languageVersion);
    } else {
      // TODO(danrubel): remove this hack and require listener to update
      // the scanner's configuration.
      configuration = ScannerConfiguration.classic;
    }
    if (includeComments) {
      _appendToCommentStream(languageVersion);
    }
    return next;
  }

  int tokenizeSingleLineComment(int next, int start) {
    bool dartdoc = identical($SLASH, peek());
    next = advance();
    return tokenizeSingleLineCommentRest(next, start, dartdoc);
  }

  int tokenizeSingleLineCommentRest(int next, int start, bool dartdoc) {
    bool asciiOnly = true;
    while (true) {
      if (next > 127) asciiOnly = false;
      if (identical($LF, next) ||
          identical($CR, next) ||
          identical($EOF, next)) {
        if (!asciiOnly) handleUnicode(start);
        if (dartdoc) {
          appendDartDoc(start, TokenType.SINGLE_LINE_COMMENT, asciiOnly);
        } else {
          appendComment(start, TokenType.SINGLE_LINE_COMMENT, asciiOnly);
        }
        return next;
      }
      next = advance();
    }
  }

  int tokenizeMultiLineComment(int next, int start) {
    bool asciiOnlyComment = true; // Track if the entire comment is ASCII.
    bool asciiOnlyLines = true; // Track ASCII since the last handleUnicode.
    int unicodeStart = start;
    int nesting = 1;
    next = advance();
    bool dartdoc = identical($STAR, next);
    while (true) {
      if (identical($EOF, next)) {
        if (!asciiOnlyLines) handleUnicode(unicodeStart);
        prependErrorToken(new UnterminatedToken(
            messageUnterminatedComment, tokenStart, stringOffset));
        advanceAfterError(/* shouldAdvance = */ true);
        break;
      } else if (identical($STAR, next)) {
        next = advance();
        if (identical($SLASH, next)) {
          --nesting;
          if (0 == nesting) {
            if (!asciiOnlyLines) handleUnicode(unicodeStart);
            next = advance();
            if (dartdoc) {
              appendDartDoc(
                  start, TokenType.MULTI_LINE_COMMENT, asciiOnlyComment);
            } else {
              appendComment(
                  start, TokenType.MULTI_LINE_COMMENT, asciiOnlyComment);
            }
            break;
          } else {
            next = advance();
          }
        }
      } else if (identical($SLASH, next)) {
        next = advance();
        if (identical($STAR, next)) {
          next = advance();
          ++nesting;
        }
      } else if (identical(next, $LF)) {
        if (!asciiOnlyLines) {
          // Synchronize the string offset in the utf8 scanner.
          handleUnicode(unicodeStart);
          asciiOnlyLines = true;
          unicodeStart = scanOffset;
        }
        lineFeedInMultiline();
        next = advance();
      } else {
        if (next > 127) {
          asciiOnlyLines = false;
          asciiOnlyComment = false;
        }
        next = advance();
      }
    }
    return next;
  }

  void appendComment(int start, TokenType type, bool asciiOnly) {
    if (!includeComments) return;
    CommentToken newComment = createCommentToken(type, start, asciiOnly);
    _appendToCommentStream(newComment);
  }

  void appendDartDoc(int start, TokenType type, bool asciiOnly) {
    if (!includeComments) return;
    CommentToken newComment = createDartDocToken(type, start, asciiOnly);
    _appendToCommentStream(newComment);
  }

  /**
   * Append the given token to the [tail] of the current stream of tokens.
   */
  void appendToken(Token token) {
    tail.next = token;
    token.previous = tail;
    tail = token;
    if (comments != null && comments == token.precedingComments) {
      comments = null;
      commentsTail = null;
    } else {
      // It is the responsibility of the caller to construct the token
      // being appended with preceding comments if any
      assert(comments == null || token.isSynthetic || token is ErrorToken);
    }
  }

  void _appendToCommentStream(CommentToken newComment) {
    if (comments == null) {
      comments = newComment;
      commentsTail = comments;
    } else {
      commentsTail!.next = newComment;
      commentsTail!.next!.previous = commentsTail;
      commentsTail = commentsTail!.next;
    }
  }

  int tokenizeRawStringKeywordOrIdentifier(int next) {
    // [next] is $r.
    int nextnext = peek();
    if (identical(nextnext, $DQ) || identical(nextnext, $SQ)) {
      int start = scanOffset;
      next = advance();
      return tokenizeString(next, start, /* raw = */ true);
    }
    return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
  }

  int tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    KeywordState? state = KeywordState.KEYWORD_STATE;
    int start = scanOffset;
    // We allow a leading capital character.
    if ($A <= next && next <= $Z) {
      state = state.nextCapital(next);
      next = advance();
    } else if ($a <= next && next <= $z) {
      // Do the first next call outside the loop to avoid an additional test
      // and to make the loop monomorphic.
      state = state.next(next);
      next = advance();
    }
    while (state != null && $a <= next && next <= $z) {
      state = state.next(next);
      next = advance();
    }
    if (state == null) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    Keyword? keyword = state.keyword;
    if (keyword == null) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if (!_enableExtensionMethods && keyword == Keyword.EXTENSION) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if (!_enableNonNullable &&
        (keyword == Keyword.LATE || keyword == Keyword.REQUIRED)) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if (($A <= next && next <= $Z) ||
        ($0 <= next && next <= $9) ||
        identical(next, $_) ||
        identical(next, $$)) {
      return tokenizeIdentifier(next, start, allowDollar);
    } else {
      appendKeywordToken(keyword);
      return next;
    }
  }

  /**
   * [allowDollar] can exclude '$', which is not allowed as part of a string
   * interpolation identifier.
   */
  int tokenizeIdentifier(int next, int start, bool allowDollar) {
    while (true) {
      if (_isIdentifierChar(next, allowDollar)) {
        next = advance();
      } else {
        // Identifier ends here.
        if (start == scanOffset) {
          return unexpected(next);
        } else {
          appendSubstringToken(
              TokenType.IDENTIFIER, start, /* asciiOnly = */ true);
        }
        break;
      }
    }
    return next;
  }

  int tokenizeAt(int next) {
    appendPrecedenceToken(TokenType.AT);
    return advance();
  }

  int tokenizeString(int next, int start, bool raw) {
    int quoteChar = next;
    next = advance();
    if (identical(quoteChar, next)) {
      next = advance();
      if (identical(quoteChar, next)) {
        // Multiline string.
        return tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        // Empty string.
        appendSubstringToken(TokenType.STRING, start, /* asciiOnly = */ true);
        return next;
      }
    }
    if (raw) {
      return tokenizeSingleLineRawString(next, quoteChar, start);
    } else {
      return tokenizeSingleLineString(next, quoteChar, start);
    }
  }

  /**
   * [next] is the first character after the quote.
   * [quoteStart] is the scanOffset of the quote.
   *
   * The token contains a substring of the source file, including the
   * string quotes, backslashes for escaping. For interpolated strings,
   * the parts before and after are separate tokens.
   *
   *   "a $b c"
   *
   * gives StringToken("a $), StringToken(b) and StringToken( c").
   */
  int tokenizeSingleLineString(int next, int quoteChar, int quoteStart) {
    int start = quoteStart;
    bool asciiOnly = true;
    while (!identical(next, quoteChar)) {
      if (identical(next, $BACKSLASH)) {
        next = advance();
      } else if (identical(next, $$)) {
        if (!asciiOnly) handleUnicode(start);
        next = tokenizeStringInterpolation(start, asciiOnly);
        start = scanOffset;
        asciiOnly = true;
        continue;
      }
      if (next <= $CR &&
          (identical(next, $LF) ||
              identical(next, $CR) ||
              identical(next, $EOF))) {
        if (!asciiOnly) handleUnicode(start);
        unterminatedString(quoteChar, quoteStart, start,
            asciiOnly: asciiOnly, isMultiLine: false, isRaw: false);
        return next;
      }
      if (next > 127) asciiOnly = false;
      next = advance();
    }
    if (!asciiOnly) handleUnicode(start);
    // Advance past the quote character.
    next = advance();
    appendSubstringToken(TokenType.STRING, start, asciiOnly);
    return next;
  }

  int tokenizeStringInterpolation(int start, bool asciiOnly) {
    appendSubstringToken(TokenType.STRING, start, asciiOnly);
    beginToken(); // $ starts here.
    int next = advance();
    if (identical(next, $OPEN_CURLY_BRACKET)) {
      return tokenizeInterpolatedExpression(next);
    } else {
      return tokenizeInterpolatedIdentifier(next);
    }
  }

  int tokenizeInterpolatedExpression(int next) {
    appendBeginGroup(TokenType.STRING_INTERPOLATION_EXPRESSION);
    beginToken(); // The expression starts here.
    next = advance(); // Move past the curly bracket.
    while (!identical(next, $EOF) && !identical(next, $STX)) {
      next = bigSwitch(next);
    }
    if (identical(next, $EOF)) {
      beginToken();
      discardInterpolation();
      return next;
    }
    next = advance(); // Move past the $STX.
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeInterpolatedIdentifier(int next) {
    appendPrecedenceToken(TokenType.STRING_INTERPOLATION_IDENTIFIER);

    if ($a <= next && next <= $z ||
        $A <= next && next <= $Z ||
        identical(next, $_)) {
      beginToken(); // The identifier starts here.
      next = tokenizeKeywordOrIdentifier(next, /* allowDollar = */ false);
    } else {
      beginToken(); // The synthetic identifier starts here.
      appendSyntheticSubstringToken(
          TokenType.IDENTIFIER, scanOffset, /* asciiOnly = */ true, '');
      prependErrorToken(new UnterminatedToken(
          messageUnexpectedDollarInString, tokenStart, stringOffset));
    }
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeSingleLineRawString(int next, int quoteChar, int quoteStart) {
    bool asciiOnly = true;
    while (next != $EOF) {
      if (identical(next, quoteChar)) {
        if (!asciiOnly) handleUnicode(quoteStart);
        next = advance();
        appendSubstringToken(TokenType.STRING, quoteStart, asciiOnly);
        return next;
      } else if (identical(next, $LF) || identical(next, $CR)) {
        if (!asciiOnly) handleUnicode(quoteStart);
        unterminatedString(quoteChar, quoteStart, quoteStart,
            asciiOnly: asciiOnly, isMultiLine: false, isRaw: true);
        return next;
      } else if (next > 127) {
        asciiOnly = false;
      }
      next = advance();
    }
    if (!asciiOnly) handleUnicode(quoteStart);
    unterminatedString(quoteChar, quoteStart, quoteStart,
        asciiOnly: asciiOnly, isMultiLine: false, isRaw: true);
    return next;
  }

  int tokenizeMultiLineRawString(int quoteChar, int quoteStart) {
    bool asciiOnlyString = true;
    bool asciiOnlyLine = true;
    int unicodeStart = quoteStart;
    int next = advance(); // Advance past the (last) quote (of three).
    outer:
    while (!identical(next, $EOF)) {
      while (!identical(next, quoteChar)) {
        if (identical(next, $LF)) {
          if (!asciiOnlyLine) {
            // Synchronize the string offset in the utf8 scanner.
            handleUnicode(unicodeStart);
            asciiOnlyLine = true;
            unicodeStart = scanOffset;
          }
          lineFeedInMultiline();
        } else if (next > 127) {
          asciiOnlyLine = false;
          asciiOnlyString = false;
        }
        next = advance();
        if (identical(next, $EOF)) break outer;
      }
      next = advance();
      if (identical(next, quoteChar)) {
        next = advance();
        if (identical(next, quoteChar)) {
          if (!asciiOnlyLine) handleUnicode(unicodeStart);
          next = advance();
          appendSubstringToken(TokenType.STRING, quoteStart, asciiOnlyString);
          return next;
        }
      }
    }
    if (!asciiOnlyLine) handleUnicode(unicodeStart);
    unterminatedString(quoteChar, quoteStart, quoteStart,
        asciiOnly: asciiOnlyLine, isMultiLine: true, isRaw: true);
    return next;
  }

  int tokenizeMultiLineString(int quoteChar, int quoteStart, bool raw) {
    if (raw) return tokenizeMultiLineRawString(quoteChar, quoteStart);
    int start = quoteStart;
    bool asciiOnlyString = true;
    bool asciiOnlyLine = true;
    int unicodeStart = start;
    int next = advance(); // Advance past the (last) quote (of three).
    while (!identical(next, $EOF)) {
      if (identical(next, $$)) {
        if (!asciiOnlyLine) handleUnicode(unicodeStart);
        next = tokenizeStringInterpolation(start, asciiOnlyString);
        start = scanOffset;
        unicodeStart = start;
        asciiOnlyString = true; // A new string token is created for the rest.
        asciiOnlyLine = true;
        continue;
      }
      if (identical(next, quoteChar)) {
        next = advance();
        if (identical(next, quoteChar)) {
          next = advance();
          if (identical(next, quoteChar)) {
            if (!asciiOnlyLine) handleUnicode(unicodeStart);
            next = advance();
            appendSubstringToken(TokenType.STRING, start, asciiOnlyString);
            return next;
          }
        }
        continue;
      }
      if (identical(next, $BACKSLASH)) {
        next = advance();
        if (identical(next, $EOF)) break;
      }
      if (identical(next, $LF)) {
        if (!asciiOnlyLine) {
          // Synchronize the string offset in the utf8 scanner.
          handleUnicode(unicodeStart);
          asciiOnlyLine = true;
          unicodeStart = scanOffset;
        }
        lineFeedInMultiline();
      } else if (next > 127) {
        asciiOnlyString = false;
        asciiOnlyLine = false;
      }
      next = advance();
    }
    if (!asciiOnlyLine) handleUnicode(unicodeStart);
    unterminatedString(quoteChar, quoteStart, start,
        asciiOnly: asciiOnlyString, isMultiLine: true, isRaw: false);
    return next;
  }

  int unexpected(int character) {
    ErrorToken errorToken =
        buildUnexpectedCharacterToken(character, tokenStart);
    if (errorToken is NonAsciiIdentifierToken) {
      int charOffset;
      List<int> codeUnits = <int>[];
      if (tail.type == TokenType.IDENTIFIER && tail.charEnd == tokenStart) {
        charOffset = tail.charOffset;
        codeUnits.addAll(tail.lexeme.codeUnits);
        tail = tail.previous!;
      } else {
        charOffset = errorToken.charOffset;
      }
      codeUnits.add(errorToken.character);
      prependErrorToken(errorToken);
      int next = advanceAfterError(/* shouldAdvance = */ true);
      while (_isIdentifierChar(next, /* allowDollar = */ true)) {
        codeUnits.add(next);
        next = advance();
      }
      appendToken(new StringToken.fromString(
          TokenType.IDENTIFIER, new String.fromCharCodes(codeUnits), charOffset,
          precedingComments: comments));
      return next;
    } else {
      prependErrorToken(errorToken);
      return advanceAfterError(/* shouldAdvance = */ true);
    }
  }

  void unexpectedEof() {
    ErrorToken errorToken = buildUnexpectedCharacterToken($EOF, tokenStart);
    prependErrorToken(errorToken);
  }

  void unterminatedString(int quoteChar, int quoteStart, int start,
      {required bool asciiOnly,
      required bool isMultiLine,
      required bool isRaw}) {
    String suffix = new String.fromCharCodes(
        isMultiLine ? [quoteChar, quoteChar, quoteChar] : [quoteChar]);
    String prefix = isRaw ? 'r$suffix' : suffix;

    appendSyntheticSubstringToken(TokenType.STRING, start, asciiOnly, suffix);
    // Ensure that the error is reported on a visible token
    int errorStart = tokenStart < stringOffset ? tokenStart : quoteStart;
    prependErrorToken(new UnterminatedString(prefix, errorStart, stringOffset));
  }

  int advanceAfterError(bool shouldAdvance) {
    if (atEndOfFile()) return $EOF;
    if (shouldAdvance) {
      return advance(); // Ensure progress.
    } else {
      return -1;
    }
  }
}

TokenType closeBraceInfoFor(BeginToken begin) {
  return const {
    '(': TokenType.CLOSE_PAREN,
    '[': TokenType.CLOSE_SQUARE_BRACKET,
    '{': TokenType.CLOSE_CURLY_BRACKET,
    '<': TokenType.GT,
    r'${': TokenType.CLOSE_CURLY_BRACKET,
  }[begin.lexeme]!;
}

class LineStarts extends Object with ListMixin<int> {
  List<int> array;
  int arrayLength = 0;

  LineStarts(int? numberOfBytesHint)
      : array = _createInitialArray(numberOfBytesHint) {
    // The first line starts at character offset 0.
    add(/* value = */ 0);
  }

  // Implement abstract members used by [ListMixin]

  int get length => arrayLength;

  int operator [](int index) {
    assert(index < arrayLength);
    return array[index];
  }

  void set length(int newLength) {
    if (newLength > array.length) {
      grow(newLength);
    }
    arrayLength = newLength;
  }

  void operator []=(int index, int value) {
    if (value > 65535 && array is! Uint32List) {
      switchToUint32(array.length);
    }
    array[index] = value;
  }

  // Specialize methods from [ListMixin].
  void add(int value) {
    if (arrayLength >= array.length) {
      grow(/* newLengthMinimum = */ 0);
    }
    if (value > 65535 && array is! Uint32List) {
      switchToUint32(array.length);
    }
    array[arrayLength++] = value;
  }

  // Helper methods.

  void grow(int newLengthMinimum) {
    int newLength = array.length * 2;
    if (newLength < newLengthMinimum) newLength = newLengthMinimum;

    if (array is Uint16List) {
      final Uint16List newArray = new Uint16List(newLength);
      newArray.setRange(/* start = */ 0, arrayLength, array);
      array = newArray;
    } else {
      switchToUint32(newLength);
    }
  }

  void switchToUint32(int newLength) {
    final Uint32List newArray = new Uint32List(newLength);
    newArray.setRange(/* start = */ 0, arrayLength, array);
    array = newArray;
  }

  static List<int> _createInitialArray(int? numberOfBytesHint) {
    // Let's assume the average Dart file is 300 bytes.
    numberOfBytesHint ??= 300;

    // Let's assume we have on average 22 bytes per line.
    final int expectedNumberOfLines = 1 + (numberOfBytesHint ~/ 22);

    if (numberOfBytesHint > 65535) {
      return new Uint32List(expectedNumberOfLines);
    } else {
      return new Uint16List(expectedNumberOfLines);
    }
  }
}

/// [ScannerConfiguration] contains information for configuring which tokens
/// the scanner produces based upon the Dart language level.
class ScannerConfiguration {
  static const ScannerConfiguration classic = const ScannerConfiguration();
  static const ScannerConfiguration nonNullable =
      const ScannerConfiguration(enableNonNullable: true);

  /// Experimental flag for enabling scanning of the `extension` keyword.
  final bool enableExtensionMethods;

  /// Experimental flag for enabling scanning of NNBD tokens
  /// such as 'required' and 'late'
  final bool enableNonNullable;

  /// Experimental flag for enabling scanning of `>>>`.
  /// See https://github.com/dart-lang/language/issues/61
  /// and https://github.com/dart-lang/language/issues/60
  final bool enableTripleShift;

  const ScannerConfiguration({
    bool enableExtensionMethods = false,
    bool enableNonNullable = false,
    bool enableTripleShift = false,
  })  : this.enableExtensionMethods = enableExtensionMethods,
        this.enableNonNullable = enableNonNullable,
        this.enableTripleShift = enableTripleShift;
}

bool _isIdentifierChar(int next, bool allowDollar) {
  return ($a <= next && next <= $z) ||
      ($A <= next && next <= $Z) ||
      ($0 <= next && next <= $9) ||
      identical(next, $_) ||
      (identical(next, $$) && allowDollar);
}
