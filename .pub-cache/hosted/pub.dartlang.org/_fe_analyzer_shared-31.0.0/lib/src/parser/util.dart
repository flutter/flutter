// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.util;

import '../messages/codes.dart' show noLength;

import '../scanner/scanner.dart' show Token;

import '../scanner/token.dart'
    show BeginToken, SimpleToken, SyntheticToken, TokenType;

/// Returns true if [token] is the symbol or keyword [value].
bool optional(String value, Token token) {
  return identical(value, token.stringValue);
}

/// Returns the token before the close brace, bracket, or parenthesis
/// associated with [left]. For '<', it may return `null`.
Token? beforeCloseBraceTokenFor(BeginToken left) {
  Token? endToken = left.endToken;
  if (endToken == null) {
    return null;
  }
  Token token = left;
  Token next = token.next!;
  while (next != endToken && next != next.next) {
    token = next;
    next = token.next!;
  }
  return token;
}

/// Return [token] or a token before [token] which is either
/// not synthetic or synthetic with non-zero length.
Token findPreviousNonZeroLengthToken(Token token) {
  while (token.isSynthetic && token.length == 0) {
    Token? previous = token.beforeSynthetic;
    if (previous == token) {
      throw new StateError("token == token.beforeSynthetic");
    }
    if (previous == null) {
      break;
    }
    token = previous;
  }
  return token;
}

/// Return [token] or a token after [token] which is either
/// not synthetic or synthetic with non-zero length.
/// This may return EOF if there are no more non-synthetic tokens in the stream.
Token findNonZeroLengthToken(Token token) {
  while (token.isSynthetic && token.length == 0 && !token.isEof) {
    token = token.next!;
  }
  return token;
}

bool isDigit(int c) => c >= 0x30 && c <= 0x39;

bool isLetter(int c) => c >= 0x41 && c <= 0x5A || c >= 0x61 && c <= 0x7A;

bool isLetterOrDigit(int c) => isLetter(c) || isDigit(c);

bool isWhitespace(int c) => c == 0x20 || c == 0xA || c == 0xD || c == 0x9;

/// Return true if the given token matches one of the given values.
bool isOneOf(Token token, Iterable<String> values) {
  for (String tokenValue in values) {
    if (optional(tokenValue, token)) {
      return true;
    }
  }
  return false;
}

/// Return true if the given token matches one of the given values or is EOF.
bool isOneOfOrEof(Token token, Iterable<String> values) {
  for (String tokenValue in values) {
    if (optional(tokenValue, token)) {
      return true;
    }
  }
  return token.isEof;
}

/// A null-aware alternative to `token.length`.  If [token] is `null`, returns
/// [noLength].
int lengthForToken(Token? token) {
  return token == null ? noLength : token.length;
}

/// Returns the length of the span from [begin] to [end] (inclusive). If both
/// tokens are null, return [noLength]. If one of the tokens are null, return
/// the length of the other token.
int lengthOfSpan(Token? begin, Token? end) {
  if (begin == null) return lengthForToken(end);
  if (end == null) return lengthForToken(begin);
  return end.offset + end.length - begin.offset;
}

Token skipMetadata(Token token) {
  token = token.next!;
  assert(optional('@', token));
  Token next = token.next!;
  // Corresponds to 'ensureIdentifier' in [parseMetadata].
  if (next.isIdentifier) {
    token = next;
    next = token.next!;
    // Corresponds to 'parseQualifiedRestOpt' in [parseMetadata].
    if (optional('.', next)) {
      token = next;
      next = token.next!;
      if (next.isIdentifier) {
        token = next;
        next = token.next!;
      }
    }
    // Corresponds to 'computeTypeParamOrArg' in [parseMetadata].
    if (optional('<', next) && !next.endGroup!.isSynthetic) {
      token = next.endGroup!;
      next = token.next!;
    }

    // The extra .identifier after arguments in in [parseMetadata].
    if (optional('.', next)) {
      token = next;
      next = token.next!;
      if (next.isIdentifier) {
        token = next;
        next = token.next!;
      }
    }

    // Corresponds to 'parseArgumentsOpt' in [parseMetadata].
    if (optional('(', next) && !next.endGroup!.isSynthetic) {
      token = next.endGroup!;
      next = token.next!;
    }
  }
  return token;
}

/// Split `>=` into two separate tokens.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtEq(Token token) {
  assert(optional('>=', token));
  return new SimpleToken(
      TokenType.GT, token.charOffset, token.precedingComments)
    ..setNext(new SimpleToken(TokenType.EQ, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next);
}

/// Split `>>` into two separate tokens.
/// Call [Token.setNext] to add the token to the stream.
SimpleToken splitGtGt(Token token) {
  assert(optional('>>', token));
  return new SimpleToken(
      TokenType.GT, token.charOffset, token.precedingComments)
    ..setNext(new SimpleToken(TokenType.GT, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next);
}

/// Split `>>=` into three separate tokens.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtGtEq(Token token) {
  assert(optional('>>=', token));
  return new SimpleToken(
      TokenType.GT, token.charOffset, token.precedingComments)
    ..setNext(new SimpleToken(TokenType.GT, token.charOffset + 1)
      ..setNext(new SimpleToken(TokenType.EQ, token.charOffset + 2)
        // Set next rather than calling Token.setNext
        // so that the previous token is not set.
        ..next = token.next));
}

/// Split `>>=` into two separate tokens... `>` followed by `>=`.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtFromGtGtEq(Token token) {
  assert(optional('>>=', token));
  return new SimpleToken(
      TokenType.GT, token.charOffset, token.precedingComments)
    ..setNext(new SimpleToken(TokenType.GT_EQ, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next);
}

/// Split `>>>` into two separate tokens... `>` followed by `>>`.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtFromGtGtGt(Token token) {
  assert(optional('>>>', token));
  return new SimpleToken(
      TokenType.GT, token.charOffset, token.precedingComments)
    ..setNext(new SimpleToken(TokenType.GT_GT, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next);
}

/// Split `>>>=` into two separate tokens... `>` followed by `>>=`.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtFromGtGtGtEq(Token token) {
  assert(optional('>>>=', token));
  return new SimpleToken(
      TokenType.GT, token.charOffset, token.precedingComments)
    ..setNext(new SimpleToken(TokenType.GT_GT_EQ, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next);
}

/// Return a synthetic `>` followed by [next].
/// Call [Token.setNext] to add the token to the stream.
Token syntheticGt(Token next) {
  return new SyntheticToken(TokenType.GT, next.charOffset)
    // Set next rather than calling Token.setNext
    // so that the previous token is not set.
    ..next = next;
}
