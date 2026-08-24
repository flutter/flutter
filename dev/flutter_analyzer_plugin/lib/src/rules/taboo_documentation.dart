// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final RegExp _tabooPattern = RegExp(r'\b(simply\b|note:|note that\b)', caseSensitive: false);

/// Avoid taboo words ('simply', 'note:', 'note that') in documentation comments.
class TabooDocumentation extends AnalysisRule {
  TabooDocumentation() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      "Avoid taboo words ('simply', 'note:', 'note that') in documentation comments.";

  static const LintCode code = LintCode(
    'taboo_documentation',
    ruleDescription,
    correctionMessage:
        'See https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md#avoid-empty-prose for details.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path;
    if (!filePath.startsWith('/home/test') &&
        (filePath.contains('/test/') ||
            filePath.endsWith('_test.dart') ||
            filePath.contains('packages/flutter_tools') ||
            filePath.endsWith('taboo_documentation.dart') ||
            filePath.endsWith('taboo_documentation_test.dart'))) {
      return;
    }
    final visitor = _Visitor(this, context);
    registry.addComment(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitComment(Comment node) {
    for (final Token token in node.tokens) {
      final String lexeme = token.lexeme;
      if (lexeme.startsWith('///') && _tabooPattern.hasMatch(lexeme)) {
        rule.reportAtNode(node);
        break;
      }
    }
  }
}
