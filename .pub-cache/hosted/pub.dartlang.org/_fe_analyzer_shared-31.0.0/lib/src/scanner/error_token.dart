// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_scanner.error_token;

import '../messages/codes.dart'
    show
        Code,
        Message,
        messageEncoding,
        templateAsciiControlCharacter,
        templateNonAsciiIdentifier,
        templateNonAsciiWhitespace,
        templateUnmatchedToken,
        templateUnsupportedOperator,
        templateUnterminatedString;

import 'recover.dart' show closeBraceFor, closeQuoteFor;

import 'scanner.dart' show Token, unicodeReplacementCharacter;

import 'token.dart' show BeginToken, SimpleToken, TokenType;

ErrorToken buildUnexpectedCharacterToken(int character, int charOffset) {
  if (character < 0x1f) {
    return new AsciiControlCharacterToken(character, charOffset);
  }
  switch (character) {
    case unicodeReplacementCharacter:
      return new EncodingErrorToken(charOffset);

    /// See [General Punctuation]
    /// (http://www.unicode.org/charts/PDF/U2000.pdf).
    case 0x00A0: // No-break space.
    case 0x1680: // Ogham space mark.
    case 0x180E: // Mongolian vowel separator.
    case 0x2000: // En quad.
    case 0x2001: // Em quad.
    case 0x2002: // En space.
    case 0x2003: // Em space.
    case 0x2004: // Three-per-em space.
    case 0x2005: // Four-per-em space.
    case 0x2006: // Six-per-em space.
    case 0x2007: // Figure space.
    case 0x2008: // Punctuation space.
    case 0x2009: // Thin space.
    case 0x200A: // Hair space.
    case 0x200B: // Zero width space.
    case 0x2028: // Line separator.
    case 0x2029: // Paragraph separator.
    case 0x202F: // Narrow no-break space.
    case 0x205F: // Medium mathematical space.
    case 0x3000: // Ideographic space.
    case 0xFEFF: // Zero width no-break space.
      return new NonAsciiWhitespaceToken(character, charOffset);

    default:
      return new NonAsciiIdentifierToken(character, charOffset);
  }
}

/// Common superclass for all error tokens.
///
/// It's considered an implementation error to access [lexeme] of an
/// [ErrorToken].
abstract class ErrorToken extends SimpleToken {
  ErrorToken(int offset) : super(TokenType.BAD_INPUT, offset, null);

  /// This is a token that wraps around an error message. Return 1
  /// instead of the size of the length of the error message.
  @override
  int get length => 1;

  String get lexeme {
    String errorMsg = assertionMessage.problemMessage;

    // Attempt to include the location which is calling the parser
    // in an effort to debug https://github.com/dart-lang/sdk/issues/37528
    RegExp pattern = new RegExp('^#[0-9]* *Parser');
    List<String> traceLines = StackTrace.current.toString().split('\n');
    for (int index = traceLines.length - 2; index >= 0; --index) {
      String line = traceLines[index];
      if (line.startsWith(pattern)) {
        errorMsg = '$errorMsg - ${traceLines[index + 1]}';
        break;
      }
    }

    throw errorMsg;
  }

  Message get assertionMessage;

  Code<dynamic> get errorCode => assertionMessage.code;

  int? get character => null;

  String? get start => null;

  int? get endOffset => null;

  BeginToken? get begin => null;

  @override
  Token copy() {
    throw 'unsupported operation';
  }
}

/// Represents an encoding error.
class EncodingErrorToken extends ErrorToken {
  EncodingErrorToken(int charOffset) : super(charOffset);

  String toString() => "EncodingErrorToken()";

  Message get assertionMessage => messageEncoding;
}

/// Represents a non-ASCII character outside a string or comment.
class NonAsciiIdentifierToken extends ErrorToken {
  final int character;

  NonAsciiIdentifierToken(this.character, int charOffset) : super(charOffset);

  String toString() => "NonAsciiIdentifierToken($character)";

  Message get assertionMessage => templateNonAsciiIdentifier.withArguments(
      new String.fromCharCodes([character]), character);
}

/// Represents a non-ASCII whitespace outside a string or comment.
class NonAsciiWhitespaceToken extends ErrorToken {
  final int character;

  NonAsciiWhitespaceToken(this.character, int charOffset) : super(charOffset);

  String toString() => "NonAsciiWhitespaceToken($character)";

  Message get assertionMessage =>
      templateNonAsciiWhitespace.withArguments(character);
}

/// Represents an ASCII control character outside a string or comment.
class AsciiControlCharacterToken extends ErrorToken {
  final int character;

  AsciiControlCharacterToken(this.character, int charOffset)
      : super(charOffset);

  String toString() => "AsciiControlCharacterToken($character)";

  Message get assertionMessage =>
      templateAsciiControlCharacter.withArguments(character);
}

/// Denotes an operator that is not supported in the Dart language.
class UnsupportedOperator extends ErrorToken {
  Token token;

  UnsupportedOperator(this.token, int charOffset) : super(charOffset);

  @override
  Message get assertionMessage =>
      templateUnsupportedOperator.withArguments(token);

  @override
  String toString() => "UnsupportedOperator(${token.lexeme})";
}

/// Represents an unterminated string.
class UnterminatedString extends ErrorToken {
  final String start;
  final int endOffset;

  UnterminatedString(this.start, int charOffset, this.endOffset)
      : super(charOffset);

  String toString() => "UnterminatedString($start)";

  int get charCount => endOffset - charOffset;

  int get length => charCount;

  Message get assertionMessage =>
      templateUnterminatedString.withArguments(start, closeQuoteFor(start));
}

/// Represents an unterminated token.
class UnterminatedToken extends ErrorToken {
  final Message assertionMessage;
  final int endOffset;

  UnterminatedToken(this.assertionMessage, int charOffset, this.endOffset)
      : super(charOffset);

  String toString() => "UnterminatedToken(${assertionMessage.code.name})";

  int get charCount => endOffset - charOffset;
}

/// Represents an open brace without a matching close brace.
///
/// In this case, brace means any of `(`, `{`, `[`, and `<`, parenthesis, curly
/// brace, square brace, and angle brace, respectively.
class UnmatchedToken extends ErrorToken {
  final BeginToken begin;

  UnmatchedToken(BeginToken begin)
      : this.begin = begin,
        super(begin.charOffset);

  String toString() => "UnmatchedToken(${begin.lexeme})";

  Message get assertionMessage =>
      templateUnmatchedToken.withArguments(closeBraceFor(begin.lexeme), begin);
}
