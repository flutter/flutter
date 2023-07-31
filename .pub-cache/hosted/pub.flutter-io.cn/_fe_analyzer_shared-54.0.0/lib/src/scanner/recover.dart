// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.recover;

import 'token.dart' show Token, TokenType;

import 'token_impl.dart' show StringTokenImpl;

import 'error_token.dart' show ErrorToken;

/// Recover from errors in [tokens]. The original sources are provided as
/// [bytes]. [lineStarts] are the beginning character offsets of lines, and
/// must be updated if recovery is performed rewriting the original source
/// code.
Token scannerRecovery(List<int> bytes, Token tokens, List<int> lineStarts) {
  // Sanity check that all error tokens are prepended.

  // TODO(danrubel): Remove this in a while after the dust has settled.

  // Skip over prepended error tokens
  Token token = tokens;
  while (token is ErrorToken) {
    token = token.next!;
  }

  // Assert no error tokens in the remaining tokens
  while (!token.isEof) {
    if (token is ErrorToken) {
      for (int count = 0; count < 3; ++count) {
        Token previous = token.previous!;
        if (previous.isEof) break;
        token = previous;
      }
      StringBuffer msg = new StringBuffer(
          "Internal error: All error tokens should have been prepended:");
      for (int count = 0; count < 7; ++count) {
        if (token.isEof) break;
        msg.write(' ${token.runtimeType},');
        token = token.next!;
      }
      throw msg.toString();
    }
    token = token.next!;
  }

  return tokens;
}

Token synthesizeToken(int charOffset, String value, TokenType type) {
  return new StringTokenImpl.fromString(type, value, charOffset);
}

Token skipToEof(Token token) {
  while (!token.isEof) {
    token = token.next!;
  }
  return token;
}

String closeBraceFor(String openBrace) {
  return const {
    '(': ')',
    '[': ']',
    '{': '}',
    '<': '>',
    r'${': '}',
  }[openBrace]!;
}

String closeQuoteFor(String openQuote) {
  return const {
    '"': '"',
    "'": "'",
    '"""': '"""',
    "'''": "'''",
    'r"': '"',
    "r'": "'",
    'r"""': '"""',
    "r'''": "'''",
  }[openQuote]!;
}
