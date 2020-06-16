// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:package_config/package_config.dart';

final RegExp _languageVersion = RegExp(r'\/\/\s*@dart');
final RegExp _declarationEnd = RegExp('(import)|(library)|(part)');
const String _blockCommentStart = '/*';
const String _blockCommentEnd = '*/';

/// Attempts to read the language version of a dart [file], returning
/// the entire comment.
///
/// If this is not present, falls back to the language version defined in
/// [package]. If [package] is not provided and there is no
/// language version header, returns `null`. This does not specifically check
/// for language declarations other than library, part, or import.
///
/// The specification for the language version tag is defined at:
/// https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/feature-specification.md#individual-library-language-version-override
String determineLanguageVersion(File file, Package package) {
  int blockCommentDepth = 0;
  for (final String line in file.readAsLinesSync()) {
    final String trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      continue;
    }
    // Check for the start or end of a block comment. Within a block
    // comment, all language version declarations are ignored. Block
    // comments can be nested, and the start or end may occur on
    // the same line. This does not handle the case of invalid
    // block comment combinations like `*/ /*` since that will cause
    // a compilation error anyway.
    bool sawBlockComment = false;
    final int startMatches = _blockCommentStart.allMatches(trimmedLine).length;
    final int endMatches = _blockCommentEnd.allMatches(trimmedLine).length;
    if (startMatches > 0) {
      blockCommentDepth += startMatches;
      sawBlockComment = true;
    }
    if (endMatches > 0) {
      blockCommentDepth -= endMatches;
      sawBlockComment = true;
    }
    if (blockCommentDepth != 0 || sawBlockComment) {
      continue;
    }
    // Check for a match with the language version.
    final Match match = _languageVersion.matchAsPrefix(trimmedLine);
    if (match != null) {
      return trimmedLine;
    }

    // Check for a declaration which ends the search for a language
    // version.
    if (_declarationEnd.matchAsPrefix(trimmedLine) != null) {
      break;
    }
  }

  // If the language version cannot be found, use the package version.
  if (package != null) {
    return '// @dart = ${package.languageVersion}';
  }
  return null;
}
