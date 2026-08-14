// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';

const String _matchesGoldenFile = 'matchesGoldenFile';
const String _reducedTestSetTag = 'reduced-test-set';
const String _tagsAnnotation = 'Tags';

final Pattern _ignorePattern = RegExp(
  r'//\s*(?:flutter_)?ignore:\s*.*?\b(?:golden_test_tags|golden_tag)\b',
);
final Pattern _ignoreForFilePattern = RegExp(
  r'//\s*(?:flutter_)?ignore_for_file:\s*.*?\b(?:golden_test_tags|golden_tag)\b',
);

/// Files containing golden tests must be tagged using `@Tags(<String>['reduced-test-set'])`.
class GoldenTestTags extends AnalysisRule {
  GoldenTestTags() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      "Files containing golden tests must be tagged using @Tags(<String>['reduced-test-set']) "
      'at the top of the file before import statements.';

  static const LintCode code = LintCode(
    'golden_test_tags',
    ruleDescription,
    correctionMessage:
        'See https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md for details.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  bool _hasInlineIgnore(AstNode node) {
    final RuleContextUnit compilationUnit = context.currentUnit!;
    final LineInfo lineInfo = compilationUnit.unit.lineInfo;
    final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
    final String content = compilationUnit.content;

    // Check the current line.
    final int currentLineStart = lineInfo.getOffsetOfLine(lineNumber - 1);
    final int currentLineEnd =
        lineNumber < lineInfo.lineCount ? lineInfo.getOffsetOfLine(lineNumber) : content.length;
    final String currentLine = content.substring(currentLineStart, currentLineEnd);
    if (currentLine.contains(_ignorePattern)) {
      return true;
    }

    // Check the previous line.
    final int previousLineNumber = lineNumber - 1;
    if (previousLineNumber > 0) {
      final int prevLineStart = lineInfo.getOffsetOfLine(previousLineNumber - 1);
      final int prevLineEnd = lineInfo.getOffsetOfLine(previousLineNumber);
      final String prevLine = content.substring(prevLineStart, prevLineEnd);
      if (prevLine.contains(_ignorePattern)) {
        return true;
      }
    }

    return false;
  }

  bool _hasFileIgnore() {
    final RuleContextUnit compilationUnit = context.currentUnit!;
    return compilationUnit.content.contains(_ignoreForFilePattern);
  }

  bool _isReducedTestSetTag(Annotation annotation) {
    final String? name = switch (annotation.name) {
      SimpleIdentifier(:final String name) => name,
      PrefixedIdentifier(:final SimpleIdentifier identifier) => identifier.name,
      _ => null,
    };
    if (name != _tagsAnnotation) {
      return false;
    }
    final ArgumentList? argumentList = annotation.arguments;
    if (argumentList == null) {
      return false;
    }
    for (final Expression argument in argumentList.arguments) {
      final Expression expr = switch (argument) {
        NamedExpression(:final Expression expression) => expression,
        _ => argument,
      };
      if (expr
          case ListLiteral(:final NodeList<CollectionElement> elements) ||
              SetOrMapLiteral(:final NodeList<CollectionElement> elements)) {
        for (final element in elements) {
          if (element case StringLiteral(
            :final String? stringValue,
          ) when stringValue == _reducedTestSetTag) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _hasReducedTestSetTag(CompilationUnit unit) {
    for (final Directive directive in unit.directives) {
      for (final Annotation annotation in directive.metadata) {
        if (_isReducedTestSetTag(annotation)) {
          return true;
        }
      }
    }
    for (final CompilationUnitMember declaration in unit.declarations) {
      for (final Annotation annotation in declaration.metadata) {
        if (_isReducedTestSetTag(annotation)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != _matchesGoldenFile) {
      return;
    }

    if (_hasFileIgnore() || _hasInlineIgnore(node)) {
      return;
    }

    final CompilationUnit unit = context.currentUnit!.unit;
    if (!_hasReducedTestSetTag(unit)) {
      rule.reportAtNode(node);
    }
  }
}
