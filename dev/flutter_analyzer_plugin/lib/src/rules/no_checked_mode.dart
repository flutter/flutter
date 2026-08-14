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

/// An analysis rule that verifies that "checked mode" is not used.
class NoCheckedMode extends AnalysisRule {
  NoCheckedMode() : super(name: code.name, description: 'Verify that "checked mode" is not used.');

  static const LintCode code = LintCode(
    'no_checked_mode',
    'Uses deprecated "checked mode" instead of "debug mode".',
    correctionMessage: 'Replace "checked mode" with "debug mode".',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry
      ..addSimpleStringLiteral(this, visitor)
      ..addInterpolationString(this, visitor)
      ..addComment(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  static const _targetText = 'checked mode';

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.value.toLowerCase().contains(_targetText)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    if (node.value.toLowerCase().contains(_targetText)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitComment(Comment node) {
    for (final Token token in node.tokens) {
      if (token.lexeme.toLowerCase().contains(_targetText)) {
        rule.reportAtNode(node);
        return;
      }
    }
  }
}
