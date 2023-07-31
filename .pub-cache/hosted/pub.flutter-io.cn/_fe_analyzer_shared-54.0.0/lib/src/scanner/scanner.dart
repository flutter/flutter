// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library _fe_analyzer_shared.scanner;

import 'dart:convert' show unicodeReplacementCharacterRune, utf8;

import 'token.dart' show Token;

import 'abstract_scanner.dart'
    show LanguageVersionChanged, ScannerConfiguration;

import 'string_scanner.dart' show StringScanner;

import 'utf8_bytes_scanner.dart' show Utf8BytesScanner;

import 'recover.dart' show scannerRecovery;

export 'abstract_scanner.dart'
    show LanguageVersionChanged, ScannerConfiguration;

export 'token_impl.dart'
    show
        StringTokenImpl,
        isBinaryOperator,
        isMinusOperator,
        isTernaryOperator,
        isUnaryOperator,
        isUserDefinableOperator;

export 'error_token.dart' show ErrorToken, buildUnexpectedCharacterToken;

export 'token.dart' show LanguageVersionToken;

export 'token_constants.dart' show EOF_TOKEN;

export 'utf8_bytes_scanner.dart' show Utf8BytesScanner;

export 'string_scanner.dart' show StringScanner;

export 'token.dart' show Keyword, Token;

const int unicodeReplacementCharacter = unicodeReplacementCharacterRune;

typedef Token Recover(List<int> bytes, Token tokens, List<int> lineStarts);

abstract class Scanner {
  /// Returns true if an error occurred during [tokenize].
  bool get hasErrors;

  List<int> get lineStarts;

  /// Configure which tokens are produced.
  set configuration(ScannerConfiguration config);

  Token tokenize();
}

class ScannerResult {
  final Token tokens;
  final List<int> lineStarts;
  final bool hasErrors;

  ScannerResult(this.tokens, this.lineStarts, this.hasErrors);
}

/// Scan/tokenize the given UTF8 [bytes].
ScannerResult scan(List<int> bytes,
    {ScannerConfiguration? configuration,
    bool includeComments = false,
    LanguageVersionChanged? languageVersionChanged}) {
  if (bytes.last != 0) {
    throw new ArgumentError("[bytes]: the last byte must be 0.");
  }
  Scanner scanner = new Utf8BytesScanner(bytes,
      configuration: configuration,
      includeComments: includeComments,
      languageVersionChanged: languageVersionChanged);
  return _tokenizeAndRecover(scanner, bytes: bytes);
}

/// Scan/tokenize the given [source].
ScannerResult scanString(String source,
    {ScannerConfiguration? configuration,
    bool includeComments = false,
    LanguageVersionChanged? languageVersionChanged}) {
  // ignore: unnecessary_null_comparison
  assert(source != null, 'source must not be null');
  StringScanner scanner = new StringScanner(source,
      configuration: configuration,
      includeComments: includeComments,
      languageVersionChanged: languageVersionChanged);
  return _tokenizeAndRecover(scanner, source: source);
}

ScannerResult _tokenizeAndRecover(Scanner scanner,
    {List<int>? bytes, String? source}) {
  Token tokens = scanner.tokenize();
  if (scanner.hasErrors) {
    if (bytes == null) bytes = utf8.encode(source!);
    tokens = scannerRecovery(bytes, tokens, scanner.lineStarts);
  }
  return new ScannerResult(tokens, scanner.lineStarts, scanner.hasErrors);
}
