// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../scanner/error_token.dart' show UnmatchedToken;
import '../scanner/token.dart'
    show
        BeginToken,
        CommentToken,
        Keyword,
        ReplacementToken,
        SimpleToken,
        SyntheticBeginToken,
        SyntheticKeywordToken,
        SyntheticStringToken,
        SyntheticToken,
        Token,
        TokenType;

abstract class TokenStreamRewriter {
  /// Insert a synthetic open and close parenthesis and return the new synthetic
  /// open parenthesis. If [insertIdentifier] is true, then a synthetic
  /// identifier is included between the open and close parenthesis.
  Token insertParens(Token token, bool includeIdentifier) {
    // Throw if the token is eof, though allow an eof-token if the offset
    // is negative. The last part is because [syntheticPreviousToken] sometimes
    // creates eof tokens that aren't the real eof-token that has a negative
    // offset (which wouldn't be valid for the real eof).
    if (!(!token.isEof || token.offset < 0)) {
      // Inserting here could cause a infinite loop. We prefer to crash.
      throw 'Internal Error: Rewriting at eof.';
    }

    Token next = token.next!;
    int offset = next.charOffset;
    BeginToken leftParen =
        next = new SyntheticBeginToken(TokenType.OPEN_PAREN, offset);
    if (includeIdentifier) {
      next = _setNext(
          next,
          new SyntheticStringToken(
              TokenType.IDENTIFIER, '', offset, /* _length = */ 0));
    }
    next = _setNext(next, new SyntheticToken(TokenType.CLOSE_PAREN, offset));
    _setEndGroup(leftParen, next);
    _setNext(next, token.next!);

    // A no-op rewriter could skip this step.
    _setNext(token, leftParen);

    return leftParen;
  }

  /// Insert [newToken] after [token] and return [newToken].
  Token insertToken(Token token, Token newToken) {
    // Throw if the token is eof, though allow an eof-token if the offset
    // is negative. The last part is because [syntheticPreviousToken] sometimes
    // creates eof tokens that aren't the real eof-token that has a negative
    // offset (which wouldn't be valid for the real eof).
    if (!(!token.isEof || token.offset < 0)) {
      // Inserting here could cause a infinite loop. We prefer to crash.
      throw 'Internal Error: Rewriting at eof.';
    }

    _setNext(newToken, token.next!);

    // A no-op rewriter could skip this step.
    _setNext(token, newToken);

    return newToken;
  }

  /// Move [endGroup] (a synthetic `)`, `]`, or `}` token) and associated
  /// error token after [token] in the token stream and return [endGroup].
  Token moveSynthetic(Token token, Token endGroup) {
    // Throw if the token is eof, though allow an eof-token if the offset
    // is negative. The last part is because [syntheticPreviousToken] sometimes
    // creates eof tokens that aren't the real eof-token that has a negative
    // offset (which wouldn't be valid for the real eof).
    if (!(!token.isEof || token.offset < 0)) {
      // Inserting here could cause a infinite loop. We prefer to crash.
      throw 'Internal Error: Rewriting at eof.';
    }

    // ignore:unnecessary_null_comparison
    assert(endGroup.beforeSynthetic != null);
    if (token == endGroup) return endGroup;
    Token? errorToken;
    if (endGroup.next is UnmatchedToken) {
      errorToken = endGroup.next;
    }

    // Remove endGroup from its current location
    _setNext(endGroup.beforeSynthetic!, (errorToken ?? endGroup).next!);

    // Insert endGroup into its new location
    Token next = token.next!;
    _setNext(token, endGroup);
    _setNext(errorToken ?? endGroup, next);
    _setOffset(endGroup, next.offset);
    if (errorToken != null) {
      _setOffset(errorToken, next.offset);
    }

    return endGroup;
  }

  /// Replace the single token immediately following the [previousToken] with
  /// the chain of tokens starting at the [replacementToken]. Return the
  /// [replacementToken].
  Token replaceTokenFollowing(Token previousToken, Token replacementToken) {
    Token replacedToken = previousToken.next!;
    _setNext(previousToken, replacementToken);

    _setPrecedingComments(
        replacementToken as SimpleToken, replacedToken.precedingComments);

    _setNext(_lastTokenInChain(replacementToken), replacedToken.next!);

    return replacementToken;
  }

  /// Given the [firstToken] in a chain of tokens to be inserted, return the
  /// last token in the chain.
  ///
  /// As a side-effect, this method also ensures that the tokens in the chain
  /// have their `previous` pointers set correctly.
  Token _lastTokenInChain(Token firstToken) {
    Token? previous;
    Token current = firstToken;
    while (current.next != null && current.next!.type != TokenType.EOF) {
      if (previous != null) {
        _setPrevious(current, previous);
      }
      previous = current;
      current = current.next!;
    }
    if (previous != null) {
      _setPrevious(current, previous);
    }
    return current;
  }

  /// Insert a new simple synthetic token of [newTokenType] after
  /// [previousToken] instead of the token actually coming after it and return
  /// the new token.
  /// The old token will be linked from the new one though, so it's not totally
  /// gone.
  ReplacementToken replaceNextTokenWithSyntheticToken(
      Token previousToken, TokenType newTokenType) {
    assert(newTokenType is! Keyword,
        'use an unwritten variation of insertSyntheticKeyword instead');

    // [token] <--> [a] <--> [b]
    ReplacementToken replacement =
        new ReplacementToken(newTokenType, previousToken.next!);
    insertToken(previousToken, replacement);
    // [token] <--> [replacement] <--> [a] <--> [b]
    _setNext(replacement, replacement.next!.next!);
    // [token] <--> [replacement] <--> [b]

    return replacement;
  }

  /// Insert a new simple synthetic token of [newTokenType] after
  /// [previousToken] instead of the [count] tokens actually coming after it and
  /// return the new token.
  /// The first old token will be linked from the new one (and the next ones can
  /// be found via the next pointer chain on it) though, so it's not totally
  /// gone.
  ReplacementToken replaceNextTokensWithSyntheticToken(
      Token previousToken, int count, TokenType newTokenType) {
    assert(newTokenType is! Keyword,
        'use an unwritten variation of insertSyntheticKeyword instead');

    // [token] <--> [a_1] <--> ... <--> [a_n] <--> [b]
    ReplacementToken replacement =
        new ReplacementToken(newTokenType, previousToken.next!);
    insertToken(previousToken, replacement);
    // [token] <--> [replacement] <--> [a_1] <--> ... <--> [a_n] <--> [b]

    Token end = replacement.next!;
    while (count > 0) {
      count--;
      end = end.next!;
    }
    _setNext(replacement, end);
    // [token] <--> [replacement] <--> [b]

    return replacement;
  }

  /// Insert a synthetic identifier after [token] and return the new identifier.
  Token insertSyntheticIdentifier(Token token, [String value = '']) {
    return insertToken(
        token,
        new SyntheticStringToken(TokenType.IDENTIFIER, value,
            token.next!.charOffset, /* _length = */ 0));
  }

  /// Insert a new synthetic [keyword] after [token] and return the new token.
  Token insertSyntheticKeyword(Token token, Keyword keyword) => insertToken(
      token, new SyntheticKeywordToken(keyword, token.next!.charOffset));

  /// Insert a new simple synthetic token of [newTokenType] after [token]
  /// and return the new token.
  Token insertSyntheticToken(Token token, TokenType newTokenType) {
    assert(newTokenType is! Keyword, 'use insertSyntheticKeyword instead');
    return insertToken(
        token, new SyntheticToken(newTokenType, token.next!.charOffset));
  }

  Token _setNext(Token setOn, Token nextToken);
  void _setEndGroup(BeginToken setOn, Token endGroup);
  void _setOffset(Token setOn, int offset);
  void _setPrecedingComments(SimpleToken setOn, CommentToken? comment);
  void _setPrevious(Token setOn, Token previous);
}

/// Provides the capability of inserting tokens into a token stream. This
/// implementation does this by rewriting the previous token to point to the
/// inserted token.
class TokenStreamRewriterImpl extends TokenStreamRewriter {
  // TODO(brianwilkerson):
  //
  // When we get to the point of removing `token.previous`, the plan is to
  // convert this into an interface and provide two implementations.
  //
  // One, used by Fasta, will connect the inserted tokens to the following token
  // without modifying the previous token.
  //
  // The other, used by 'analyzer', will be created with the first token in the
  // stream (actually with the BOF marker at the beginning of the stream). It
  // will be created only when invoking 'analyzer' specific parse methods (in
  // `Parser`), such as
  //
  // Token parseUnitWithRewrite(Token bof) {
  //   rewriter = AnalyzerTokenStreamRewriter(bof);
  //   return parseUnit(bof.next);
  // }
  //

  Token _setNext(Token setOn, Token nextToken) {
    return setOn.setNext(nextToken);
  }

  void _setEndGroup(BeginToken setOn, Token endGroup) {
    setOn.endGroup = endGroup;
  }

  void _setOffset(Token setOn, int offset) {
    setOn.offset = offset;
  }

  void _setPrecedingComments(SimpleToken setOn, CommentToken? comment) {
    setOn.precedingComments = comment;
  }

  void _setPrevious(Token setOn, Token previous) {
    setOn.previous = previous;
  }
}

abstract class TokenStreamChange {
  void undo();
}

class NextTokenStreamChange implements TokenStreamChange {
  final Token setOn;
  final Token? setOnNext;
  final Token nextToken;
  final Token? nextTokenPrevious;
  final Token? nextTokenBeforeSynthetic;

  NextTokenStreamChange(
      UndoableTokenStreamRewriter rewriter, this.setOn, this.nextToken)
      : setOnNext = setOn.next,
        nextTokenPrevious = nextToken.previous,
        nextTokenBeforeSynthetic = nextToken.beforeSynthetic {
    rewriter._changes.add(this);
    setOn.next = nextToken;
    nextToken.previous = setOn;
    nextToken.beforeSynthetic = setOn;
  }

  @override
  void undo() {
    nextToken.beforeSynthetic = nextTokenBeforeSynthetic;
    nextToken.previous = nextTokenPrevious;
    setOn.next = setOnNext;
  }
}

class EndGroupTokenStreamChange implements TokenStreamChange {
  final BeginToken setOn;
  final Token? endGroup;

  EndGroupTokenStreamChange(
      UndoableTokenStreamRewriter rewriter, this.setOn, Token endGroup)
      : endGroup = setOn.endGroup {
    rewriter._changes.add(this);
    setOn.endGroup = endGroup;
  }

  @override
  void undo() {
    setOn.endGroup = endGroup;
  }
}

class OffsetTokenStreamChange implements TokenStreamChange {
  final Token setOn;
  final int offset;

  OffsetTokenStreamChange(
      UndoableTokenStreamRewriter rewriter, this.setOn, int offset)
      : offset = setOn.offset {
    rewriter._changes.add(this);
    setOn.offset = offset;
  }

  @override
  void undo() {
    setOn.offset = offset;
  }
}

class PrecedingCommentsTokenStreamChange implements TokenStreamChange {
  final SimpleToken setOn;
  final CommentToken? comment;

  PrecedingCommentsTokenStreamChange(
      UndoableTokenStreamRewriter rewriter, this.setOn, CommentToken? comment)
      : comment = setOn.precedingComments {
    rewriter._changes.add(this);
    setOn.precedingComments = comment;
  }

  @override
  void undo() {
    setOn.precedingComments = comment;
  }
}

class PreviousTokenStreamChange implements TokenStreamChange {
  final Token setOn;
  final Token previous;

  PreviousTokenStreamChange(
      UndoableTokenStreamRewriter rewriter, this.setOn, Token previous)
      : previous = setOn.previous! {
    rewriter._changes.add(this);
    setOn.previous = previous;
  }

  @override
  void undo() {
    setOn.previous = previous;
  }
}

/// Provides the capability of inserting tokens into a token stream. This
/// implementation does this by rewriting the previous token to point to the
/// inserted token. It also allows to undo these changes.
class UndoableTokenStreamRewriter extends TokenStreamRewriter {
  List<TokenStreamChange> _changes = <TokenStreamChange>[];

  void undo() {
    for (int i = _changes.length - 1; i >= 0; i--) {
      TokenStreamChange change = _changes[i];
      change.undo();
    }
    _changes.clear();
  }

  @override
  void _setEndGroup(BeginToken setOn, Token endGroup) {
    new EndGroupTokenStreamChange(this, setOn, endGroup);
  }

  @override
  Token _setNext(Token setOn, Token nextToken) {
    return new NextTokenStreamChange(this, setOn, nextToken).nextToken;
  }

  @override
  void _setOffset(Token setOn, int offset) {
    new OffsetTokenStreamChange(this, setOn, offset);
  }

  @override
  void _setPrecedingComments(SimpleToken setOn, CommentToken? comment) {
    new PrecedingCommentsTokenStreamChange(this, setOn, comment);
  }

  @override
  void _setPrevious(Token setOn, Token previous) {
    new PreviousTokenStreamChange(this, setOn, previous);
  }
}
