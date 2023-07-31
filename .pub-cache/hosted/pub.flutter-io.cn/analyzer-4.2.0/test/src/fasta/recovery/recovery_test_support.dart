// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:test/test.dart';

import '../../../generated/parser_test_base.dart';
import '../../../generated/test_support.dart';

/// The base class for tests that test how well the parser recovers from various
/// syntactic errors.
abstract class AbstractRecoveryTest extends FastaParserTestCase {
  void testRecovery(
      String invalidCode, List<ErrorCode>? errorCodes, String validCode,
      {CompilationUnitImpl Function(CompilationUnitImpl unit)?
          adjustValidUnitBeforeComparison,
      List<ErrorCode>? expectedErrorsInValidCode,
      FeatureSet? featureSet}) {
    CompilationUnitImpl validUnit;

    // Assert that the valid code is indeed valid.
    try {
      validUnit = parseCompilationUnit(validCode,
          codes: expectedErrorsInValidCode, featureSet: featureSet);
      validateTokenStream(validUnit.beginToken);
    } catch (e) {
//      print('');
//      print('  Errors in valid code.');
//      print('    Error: $e');
//      print('    Code: $validCode');
//      print('');
      rethrow;
    }

    // Compare the structures before asserting valid errors.
    GatheringErrorListener listener = GatheringErrorListener(checkRanges: true);
    var invalidUnit =
        parseCompilationUnit2(invalidCode, listener, featureSet: featureSet);
    validateTokenStream(invalidUnit.beginToken);
    if (adjustValidUnitBeforeComparison != null) {
      validUnit = adjustValidUnitBeforeComparison(validUnit);
    }
    ResultComparator.compare(invalidUnit, validUnit);

    // Assert valid errors.
    if (errorCodes != null) {
      listener.assertErrorsWithCodes(errorCodes);
    } else {
      listener.assertNoErrors();
    }
  }

  void validateTokenStream(Token token) {
    while (!token.isEof) {
      Token next = token.next!;
      expect(token.end, lessThanOrEqualTo(next.offset));
      if (next.isSynthetic) {
        if (const [')', ']', '}'].contains(next.lexeme)) {
          expect(next.beforeSynthetic, token);
        }
      }
      token = next;
    }
  }
}

/// An object used to compare to AST structures and cause the test to fail if
/// they differ in any important ways.
class ResultComparator extends AstComparator {
  @override
  bool failDifferentLength(List first, List second) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Expected a list of length ${second.length}');
    buffer.writeln('  $second');
    buffer.writeln('But found a list of length ${first.length}');
    buffer.writeln('  $first');
    if (first is NodeList) {
      _safelyWriteNodePath(buffer, first.owner);
    }
    fail(buffer.toString());
  }

  @override
  bool failIfNotNull(Object? first, Object? second) {
    if (second != null) {
      StringBuffer buffer = StringBuffer();
      buffer.write('Expected null; found a ');
      buffer.writeln(second.runtimeType);
      if (second is AstNode) {
        _safelyWriteNodePath(buffer, second);
      }
      fail(buffer.toString());
    }
    return true;
  }

  @override
  bool failIsNull(Object first, Object? second) {
    StringBuffer buffer = StringBuffer();
    buffer.write('Expected a ');
    buffer.write(first.runtimeType);
    buffer.writeln('; found null');
    if (first is AstNode) {
      _safelyWriteNodePath(buffer, first);
    }
    fail(buffer.toString());
  }

  @override
  bool failRuntimeType(Object first, Object second) {
    StringBuffer buffer = StringBuffer();
    buffer.write('Expected a ');
    buffer.writeln(second.runtimeType);
    buffer.write('; found ');
    buffer.writeln(first.runtimeType);
    if (first is AstNode) {
      _safelyWriteNodePath(buffer, first);
    }
    fail(buffer.toString());
  }

  /// Overridden to allow the valid code to contain an explicit identifier where
  /// a synthetic identifier is expected to be inserted by recovery.
  @override
  bool isEqualNodes(AstNode? first, AstNode? second) {
    if (first is SimpleIdentifier && second is SimpleIdentifier) {
      if (first.isSynthetic && second.name == '_s_') {
        return true;
      }
      if (first.token.isKeyword && second.name == '_k_') {
        return true;
      }
    }
    return super.isEqualNodes(first, second);
  }

  /// Overridden to ignore the offsets of tokens because these can legitimately
  /// be different.
  @override
  bool isEqualTokensNotNull(Token first, Token second) =>
      (first.isSynthetic && first.type == second.type) ||
      (first.length == second.length && first.lexeme == second.lexeme);

  void _safelyWriteNodePath(StringBuffer buffer, AstNode? node) {
    buffer.write('  path: ');
    if (node == null) {
      buffer.write(' null');
    } else {
      _writeNodePath(buffer, node);
    }
  }

  void _writeNodePath(StringBuffer buffer, AstNode node) {
    var parent = node.parent;
    if (parent != null) {
      _writeNodePath(buffer, parent);
      buffer.write(', ');
    }
    buffer.write(node.runtimeType);
  }

  /// Compare the [actual] and [expected] nodes, failing the test if they are
  /// different.
  static void compare(AstNode actual, AstNode expected) {
    ResultComparator comparator = ResultComparator();
    if (!comparator.isEqualNodes(actual, expected)) {
      fail('Expected: $expected\n   Found: $actual');
    }
  }
}
