// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:test/test.dart';

import '../../generated/test_support.dart';

main() {
  group('lint rule', () {
    group('error code reporting', () {
      test('reportLintForToken (custom)', () {
        final rule = TestRule();
        final reporter =
            CollectingReporter(GatheringErrorListener(), _MockSource('mock'));
        rule.reporter = reporter;

        rule.reportLintForToken(Token.eof(0),
            errorCode: customCode, ignoreSyntheticTokens: false);
        expect(reporter.code, customCode);
      });
      test('reportLintForToken (default)', () {
        final rule = TestRule();
        final reporter =
            CollectingReporter(GatheringErrorListener(), _MockSource('mock'));
        rule.reporter = reporter;

        rule.reportLintForToken(Token.eof(0), ignoreSyntheticTokens: false);
        expect(reporter.code, rule.lintCode);
      });
      test('reportLint (custom)', () {
        final rule = TestRule();
        final reporter =
            CollectingReporter(GatheringErrorListener(), _MockSource('mock'));
        rule.reporter = reporter;

        final node = EmptyStatementImpl(
          semicolon: SimpleToken(TokenType.SEMICOLON, 0),
        );
        rule.reportLint(node, errorCode: customCode);
        expect(reporter.code, customCode);
      });
      test('reportLint (default)', () {
        final rule = TestRule();
        final reporter =
            CollectingReporter(GatheringErrorListener(), _MockSource('mock'));
        rule.reporter = reporter;

        final node = EmptyStatementImpl(
          semicolon: SimpleToken(TokenType.SEMICOLON, 0),
        );
        rule.reportLint(node);
        expect(reporter.code, rule.lintCode);
      });
    });
  });
}

const LintCode customCode = LintCode(
    'hash_and_equals', 'Override `==` if overriding `hashCode`.',
    correctionMessage: 'Implement `==`.');

class CollectingReporter extends ErrorReporter {
  ErrorCode? code;

  CollectingReporter(super.listener, super.source)
      : super(isNonNullableByDefault: false);

  @override
  void reportErrorForElement(ErrorCode errorCode, Element element,
      [List<Object?>? arguments]) {
    code = errorCode;
  }

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object?>? arguments, List<DiagnosticMessage>? messages]) {
    code = errorCode;
  }

  @override
  void reportErrorForToken(ErrorCode errorCode, Token token,
      [List<Object?>? arguments, List<DiagnosticMessage>? messages]) {
    code = errorCode;
  }
}

class TestRule extends LintRule {
  TestRule()
      : super(
          name: 'test_rule',
          description: '',
          details: '... tl;dr ...',
          group: Group.errors,
        );
}

class _MockSource implements Source {
  @override
  final String fullName;

  _MockSource(this.fullName);

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
