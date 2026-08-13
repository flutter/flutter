// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// An analysis rule that verifies that debug expensive fields annotated with @_debugOnly are null initialized.
class NullInitializedDebugExpensiveFields extends AnalysisRule {
  NullInitializedDebugExpensiveFields()
    : super(
        name: code.name,
        description: 'Verify that debug expensive fields are null initialized.',
      );

  static const LintCode code = LintCode(
    'null_initialized_debug_expensive_fields',
    'Fields annotated with @_debugOnly must null initialize.',
    correctionMessage: 'Initialize with: field = kDebugMode ? <DebugValue> : null;',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final bool hasDebugOnly = node.metadata.any(
      (Annotation annotation) => annotation.name.name == '_debugOnly',
    );
    if (!hasDebugOnly) {
      return;
    }

    for (final VariableDeclaration variable in node.fields.variables) {
      if (!_isCorrectInitializer(variable.initializer)) {
        rule.reportAtNode(variable);
      }
    }
  }

  bool _isCorrectInitializer(Expression? initializer) {
    if (initializer case ConditionalExpression(:final Expression condition, elseExpression: NullLiteral())) {
      Expression unwrappedCondition = condition;
      while (unwrappedCondition is ParenthesizedExpression) {
        unwrappedCondition = unwrappedCondition.expression;
      }
      return switch (unwrappedCondition) {
        SimpleIdentifier(name: 'kDebugMode') => true,
        PrefixedIdentifier(identifier: SimpleIdentifier(name: 'kDebugMode')) => true,
        _ => false,
      };
    }
    return false;
  }
}
