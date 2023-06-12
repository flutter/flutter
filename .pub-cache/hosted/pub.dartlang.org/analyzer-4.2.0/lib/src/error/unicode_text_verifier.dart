// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/error/codes.dart';

/// A verifier that checks for unsafe Unicode text.
/// todo(pq): update w/ a Dart CVE link once published
class UnicodeTextVerifier {
  final ErrorReporter errorReporter;
  UnicodeTextVerifier(this.errorReporter);

  void verify(CompilationUnit unit, String source) {
    for (var offset = 0; offset < source.length; ++offset) {
      var codeUnit = source.codeUnitAt(offset);
      // U+202A, U+202B, U+202C, U+202D, U+202E, U+2066, U+2067, U+2068, U+2069.
      if (0x202a <= codeUnit &&
          codeUnit <= 0x2069 &&
          (codeUnit <= 0x202e || 0x2066 <= codeUnit)) {
        // This uses an AST visitor; consider a more direct approach.
        var node = NodeLocator(offset).searchWithin(unit);
        // If it's not in a string literal, we assume we're in a comment.
        // This can potentially over-report on syntactically incorrect sources
        // (where Unicode is outside a string or comment).
        var errorCode =
            node is SimpleStringLiteral || node is InterpolationString
                ? HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL
                : HintCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT;
        var code = codeUnit.toRadixString(16).toUpperCase();
        errorReporter.reportErrorForOffset(errorCode, offset, 1, [code]);
      }
    }
  }
}
