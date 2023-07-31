// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.scanner.string_scanner;

import 'token.dart'
    show
        CommentToken,
        LanguageVersionToken,
        SyntheticStringToken,
        Token,
        TokenType;

import 'token.dart' as analyzer show StringToken;

import 'abstract_scanner.dart'
    show AbstractScanner, LanguageVersionChanged, ScannerConfiguration;

import 'string_canonicalizer.dart'
    show canonicalizeString, canonicalizeSubString;

import 'token_impl.dart'
    show
        CommentTokenImpl,
        DartDocToken,
        LanguageVersionTokenImpl,
        StringTokenImpl;

import 'error_token.dart' show ErrorToken;

/**
 * Scanner that reads from a String and creates tokens that points to
 * substrings.
 */
class StringScanner extends AbstractScanner {
  /** The file content. */
  final String string;

  /** The current offset in [string]. */
  @override
  int scanOffset = -1;

  StringScanner(String string,
      {ScannerConfiguration? configuration,
      bool includeComments = false,
      LanguageVersionChanged? languageVersionChanged})
      : string = ensureZeroTermination(string),
        super(configuration, includeComments, languageVersionChanged);

  StringScanner.recoveryOptionScanner(StringScanner super.copyFrom)
      : string = copyFrom.string,
        scanOffset = copyFrom.scanOffset,
        super.recoveryOptionScanner();

  @override
  StringScanner createRecoveryOptionScanner() {
    return new StringScanner.recoveryOptionScanner(this);
  }

  static String ensureZeroTermination(String string) {
    return (string.isEmpty || string.codeUnitAt(string.length - 1) != 0)
        // TODO(lry): abort instead of copying the array, or warn?
        ? string + '\x00'
        : string;
  }

  static bool isLegalIdentifier(String identifier) {
    StringScanner scanner = new StringScanner(identifier);
    Token startToken = scanner.tokenize();
    return startToken is! ErrorToken && startToken.next!.isEof;
  }

  @override
  int advance() => string.codeUnitAt(++scanOffset);
  @override
  int peek() => string.codeUnitAt(scanOffset + 1);

  @override
  int get stringOffset => scanOffset;

  @override
  int currentAsUnicode(int next) => next;

  @override
  void handleUnicode(int startScanOffset) {}

  @override
  analyzer.StringToken createSubstringToken(
      TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]) {
    return new StringTokenImpl.fromSubstring(
        type, string, start, scanOffset + extraOffset, tokenStart,
        canonicalize: true, precedingComments: comments);
  }

  @override
  analyzer.StringToken createSyntheticSubstringToken(
      TokenType type, int start, bool asciiOnly, String syntheticChars) {
    String value = syntheticChars.length == 0
        ? canonicalizeSubString(string, start, scanOffset)
        : canonicalizeString(
            string.substring(start, scanOffset) + syntheticChars);
    return new SyntheticStringToken(
        type, value, tokenStart, value.length - syntheticChars.length);
  }

  @override
  CommentToken createCommentToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]) {
    return new CommentTokenImpl.fromSubstring(
        type, string, start, scanOffset + extraOffset, tokenStart,
        canonicalize: true);
  }

  @override
  DartDocToken createDartDocToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]) {
    return new DartDocToken.fromSubstring(
        type, string, start, scanOffset + extraOffset, tokenStart,
        canonicalize: true);
  }

  @override
  LanguageVersionToken createLanguageVersionToken(
      int start, int major, int minor) {
    return new LanguageVersionTokenImpl.fromSubstring(
        string, start, scanOffset, tokenStart, major, minor,
        canonicalize: true);
  }

  @override
  bool atEndOfFile() => scanOffset >= string.length - 1;
}
