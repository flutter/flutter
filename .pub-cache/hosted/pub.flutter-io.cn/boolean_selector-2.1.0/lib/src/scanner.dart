// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:string_scanner/string_scanner.dart';

import 'token.dart';

/// A regular expression matching both whitespace and single-line comments.
///
/// This will only match if consumes at least one character.
final _whitespaceAndSingleLineComments = RegExp(r'([ \t\n]+|//[^\n]*(\n|$))+');

/// A regular expression matching the body of a multi-line comment, after `/*`
/// but before `*/` or a nested `/*`.
///
/// This will only match if it consumes at least one character.
final _multiLineCommentBody = RegExp(r'([^/*]|/[^*]|\*[^/])+');

/// A regular expression matching a hyphenated identifier.
///
/// This is like a standard Dart identifier, except that it can also contain
/// hyphens.
final _hyphenatedIdentifier = RegExp(r'[a-zA-Z_-][a-zA-Z0-9_-]*');

/// A scanner that converts a boolean selector string into a stream of tokens.
class Scanner {
  /// The underlying string scanner.
  final SpanScanner _scanner;

  /// The next token to emit.
  Token? _next;

  /// Whether the scanner has emitted a [TokenType.endOfFile] token.
  bool _endOfFileEmitted = false;

  Scanner(String selector) : _scanner = SpanScanner(selector);

  /// Returns the next token that will be returned by [next].
  ///
  /// Throws a [StateError] if a [TokenType.endOfFile] token has already been
  /// consumed.
  Token peek() => _next ??= _readNext();

  /// Consumes and returns the next token in the stream.
  ///
  /// Throws a [StateError] if a [TokenType.endOfFile] token has already been
  /// consumed.
  Token next() {
    var token = _next ?? _readNext();
    _endOfFileEmitted = token.type == TokenType.endOfFile;
    _next = null;
    return token;
  }

  /// If the next token matches [type], consumes it and returns `true`;
  /// otherwise, returns `false`.
  ///
  /// Throws a [StateError] if a [TokenType.endOfFile] token has already been
  /// consumed.
  bool scan(TokenType type) {
    if (peek().type != type) return false;
    next();
    return true;
  }

  /// Scan and return the next token in the stream.
  Token _readNext() {
    if (_endOfFileEmitted) throw StateError('No more tokens.');

    _consumeWhitespace();
    if (_scanner.isDone) {
      return Token(TokenType.endOfFile, _scanner.spanFrom(_scanner.state));
    }

    switch (_scanner.peekChar()) {
      case 0x28 /* ( */ :
        return _scanOperator(TokenType.leftParen);
      case 0x29 /* ) */ :
        return _scanOperator(TokenType.rightParen);
      case 0x3F /* ? */ :
        return _scanOperator(TokenType.questionMark);
      case 0x3A /* : */ :
        return _scanOperator(TokenType.colon);
      case 0x21 /* ! */ :
        return _scanOperator(TokenType.not);
      case 0x7C /* | */ :
        return _scanOr();
      case 0x26 /* & */ :
        return _scanAnd();
      default:
        return _scanIdentifier();
    }
  }

  /// Scans a single-character operator and returns a token of type [type].
  ///
  /// This assumes that the caller has already verified that the next character
  /// is correct for the given operator.
  Token _scanOperator(TokenType type) {
    var start = _scanner.state;
    _scanner.readChar();
    return Token(type, _scanner.spanFrom(start));
  }

  /// Scans a `||` operator and returns the appropriate token.
  ///
  /// This validates that the next two characters are `||`.
  Token _scanOr() {
    var start = _scanner.state;
    _scanner.expect('||');
    return Token(TokenType.or, _scanner.spanFrom(start));
  }

  /// Scans a `&&` operator and returns the appropriate token.
  ///
  /// This validates that the next two characters are `&&`.
  Token _scanAnd() {
    var start = _scanner.state;
    _scanner.expect('&&');
    return Token(TokenType.and, _scanner.spanFrom(start));
  }

  /// Scans and returns an identifier token.
  Token _scanIdentifier() {
    _scanner.expect(_hyphenatedIdentifier, name: 'expression');
    return IdentifierToken(_scanner.lastMatch![0]!, _scanner.lastSpan!);
  }

  /// Consumes all whitespace and comments immediately following the cursor's
  /// current position.
  void _consumeWhitespace() {
    while (_scanner.scan(_whitespaceAndSingleLineComments) ||
        _multiLineComment()) {
      // Do nothing.
    }
  }

  /// Consumes a single multi-line comment.
  ///
  /// Returns whether or not a comment was consumed.
  bool _multiLineComment() {
    if (!_scanner.scan('/*')) return false;

    while (_scanner.scan(_multiLineCommentBody) || _multiLineComment()) {
      // Do nothing.
    }
    _scanner.expect('*/');

    return true;
  }
}
