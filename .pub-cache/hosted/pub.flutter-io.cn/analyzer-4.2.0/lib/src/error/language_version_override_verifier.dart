// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';

/// Finds invalid, or misplaced language override comments.
class LanguageVersionOverrideVerifier {
  static final _overrideCommentLine = RegExp(r'^\s*//\s*@dart\s*=\s*\d+\.\d+');

  final ErrorReporter _errorReporter;

  LanguageVersionOverrideVerifier(this._errorReporter);

  void verify(CompilationUnit unit) {
    _verifyMisplaced(unit);

    Token beginToken = unit.beginToken;
    if (beginToken.type == TokenType.SCRIPT_TAG) {
      beginToken = beginToken.next!;
    }
    Token? commentToken = beginToken.precedingComments;
    while (commentToken != null) {
      if (_findLanguageVersionOverrideComment(commentToken)) {
        // A valid language version override was found. Do not search for any
        // later invalid language version comments.
        return;
      }
      commentToken = commentToken.next;
    }
  }

  /// Look for comments which look almost like a Dart language version override,
  /// according to the spec [1].
  ///
  /// The idea of a comment which looks "almost" like a language version
  /// override is a tricky dance. It is important that this function _not_
  /// falsely report comment lines as an "invalid language version override"
  /// when the user was likely not trying to override the language version. Here
  /// is the general algorithm for deciding what to report:
  ///
  /// * When a comment begins with "@dart" or "dart" (letters in any case),
  ///   followed by optional whitespace, followed by optional non-alphanumeric,
  ///   non-whitespace characters, followed by optional whitespace, followed by
  ///   an optional alphabetical character, followed by a digit, followed by the
  ///   end of the line or a non-alphabetical character, then the comment is
  ///   considered to be an attempt at a language version override comment
  ///   (with one exception, below).
  ///   * If the "@" character is missing before "dart", _and_ the
  ///     non-alphabetical characters are not present, the comment is too
  ///     different from a valid language version override comment, and is not
  ///     considered to be an attempt. Examples include: "/// dart2 is great."
  ///   * If the comment began with more than two slashes, report the comment.
  ///     For example: "/// dart = 2".
  ///   * If the "@" character is missing before "dart", report the comment.
  ///     Examples include: "// dart = 2.0", "// dart @ 2.0".
  ///   * If the letters, "dart", are not all lower case, report the comment.
  ///     For example: "// @Dart = 2".
  ///   * If the non-alphabetical characters are not present or are not the
  ///     single character "=", report the comment. Examples include:
  ///     "// @dart: 2", "// @dart > 2.0", "// @dart >= 2.0", "// @dart 2.0".
  ///   * If the optional alphabetical letter is present, report the comment.
  ///     For example: "// @dart = v2".
  ///   * If the digit is not immediately followed by a "." character, then
  ///     another digit, then optional whitespace, then the end of the line,
  ///     report the comment. Examples include: "// @dart = 2",
  ///     "// @dart = 2,0", "// @dart = 2.15", "// @dart = 2.2.2",
  ///     "// @dart = 2.2 or so".
  ///   * Otherwise, the comment is a valid language version override comment.
  /// * Otherwise, the comment is not considered to be an attempt at a language
  ///   version override comment. Nothing is reported. Examples include:
  ///   "/// dart", "/// dart is great", "// dartisans are great",
  ///   "// dart = java, basically".
  ///
  /// [1] https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
  bool _findLanguageVersionOverrideComment(Token commentToken) {
    String comment = commentToken.lexeme;
    int offset = commentToken.offset;
    int length = comment.length;
    int index = 0;

    // TODO(srawlins): Actual whitespace.
    bool isWhitespace(int character) => character == 0x09 || character == 0x20;

    bool isNumeric(int character) => character >= 0x30 && character <= 0x39;

    bool isAlphabetical(int character) =>
        (character >= 0x41 && character <= 0x5A) ||
        (character >= 0x61 && character <= 0x7A);

    void skipWhitespaces() {
      while (index < length && isWhitespace(comment.codeUnitAt(index))) {
        index++;
      }
    }

    // Count the number of `/` characters at the beginning.
    while (index < length && comment.codeUnitAt(index) == 0x2F) {
      index++;
    }
    int slashCount = index;

    skipWhitespaces();
    if (index == length) {
      // This is not an attempted language version override comment.
      return false;
    }

    bool atSignPresent = comment.codeUnitAt(index) == 0x40;
    if (atSignPresent) {
      index++;
    }
    if (length - index < 4) {
      // This is not an attempted language version override comment.
      return false;
    }

    String possibleDart = comment.substring(index, index + 4);
    if (possibleDart.toLowerCase() != 'dart') {
      // This is not an attempted language version override comment.
      return false;
    }

    index += 4;
    skipWhitespaces();
    if (index == length) {
      // This is not an attempted language version override comment.
      return false;
    }

    // The separator between "@dart" and the version number.
    int dartVersionSeparatorStartIndex = index;
    // Move through any other consecutive punctuation, whitespace,
    while (index < length) {
      int possibleSeparatorCharacter = comment.codeUnitAt(index);
      if (isNumeric(possibleSeparatorCharacter) ||
          isAlphabetical(possibleSeparatorCharacter) ||
          isWhitespace(possibleSeparatorCharacter)) {
        break;
      }
      index++;
    }
    if (index == length) {
      // This is not an attempted language version override comment.
      return false;
    }

    int dartVersionSeparatorLength = index - dartVersionSeparatorStartIndex;
    skipWhitespaces();
    if (index == length) {
      // This is not an attempted language version override comment.
      return false;
    }

    bool containsInvalidVersionNumberPrefix = false;
    if (isAlphabetical(comment.codeUnitAt(index))) {
      containsInvalidVersionNumberPrefix = true;
      index++;
      if (index == length) {
        // This is not an attempted language version override comment.
        return false;
      }
    }

    if (!isNumeric(comment.codeUnitAt(index))) {
      // This is not an attempted language version override comment.
      return false;
    }

    if (index + 1 < length && isAlphabetical(comment.codeUnitAt(index + 1))) {
      // This is not an attempted language version override comment.
      return false;
    }

    if (!atSignPresent && dartVersionSeparatorLength == 0) {
      // The comment is too different from a valid language version override
      // comment, like "/// dart2 is great".
      return false;
    }

    // At this point, the comment is considered an "attempted" language version
    // override comment. Check for all issues which would make it an invalid
    // language version override comment.

    if (slashCount > 2) {
      _errorReporter.reportErrorForOffset(
          HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES,
          offset,
          length);
      return false;
    }

    if (!atSignPresent) {
      _errorReporter.reportErrorForOffset(
          HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN, offset, length);
      return false;
    }

    if (possibleDart != 'dart') {
      // The 4 characters after `@` are "dart", but in the wrong case.
      _errorReporter.reportErrorForOffset(
          HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE,
          offset,
          length);
      return false;
    }

    if (dartVersionSeparatorLength != 1 ||
        comment.codeUnitAt(dartVersionSeparatorStartIndex) != 0x3D) {
      // The separator between "@dart" and the version number is either not
      // present, or is not a single "=" character.
      _errorReporter.reportErrorForOffset(
          HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS, offset, length);
      return false;
    }

    if (containsInvalidVersionNumberPrefix) {
      _errorReporter.reportErrorForOffset(
          HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX, offset, length);
      return false;
    }

    void reportInvalidNumber() {
      _errorReporter.reportErrorForOffset(
          HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER, offset, length);
    }

    // Nothing preceding the version number makes this comment invalid. Check
    // the format of the version number, and trailing characters.

    // Skip major version.
    while (index < length && isNumeric(comment.codeUnitAt(index))) {
      index++;
    }

    // Skip '.' separator.
    if (index == length || comment.codeUnitAt(index) != 0x2E) {
      reportInvalidNumber();
      return false;
    }
    index++;

    // Skip minor version.
    while (index < length && isNumeric(comment.codeUnitAt(index))) {
      index++;
    }

    skipWhitespaces();

    // OK, no trailing characters.
    if (index == length) {
      return true;
    }

    // This comment is a valid language version override, except for trailing
    // characters.
    _errorReporter.reportErrorForOffset(
        HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS,
        offset,
        length);
    return false;
  }

  /// Verify that all language version overrides are before declarations.
  void _verifyMisplaced(CompilationUnit unit) {
    Token firstMeaningfulToken;
    if (unit.directives.isNotEmpty) {
      firstMeaningfulToken = unit.directives.first.beginToken;
    } else if (unit.declarations.isNotEmpty) {
      firstMeaningfulToken = unit.declarations.first.beginToken;
    } else {
      return;
    }

    var token = firstMeaningfulToken.next;
    while (token != null) {
      if (token.offset > firstMeaningfulToken.offset) {
        Token? commentToken = token.precedingComments;
        for (; commentToken != null; commentToken = commentToken.next) {
          var lexeme = commentToken.lexeme;

          var match = _overrideCommentLine.firstMatch(lexeme);
          if (match != null) {
            var atDartStart = lexeme.indexOf('@dart');
            _errorReporter.reportErrorForOffset(
              HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION,
              commentToken.offset + atDartStart,
              match.end - atDartStart,
            );
          }
        }
      }

      if (token.next == token) {
        break;
      } else {
        token = token.next;
      }
    }
  }
}
