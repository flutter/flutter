// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types, omit_obvious_local_variable_types, prefer_final_locals
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NullInitializedDebugExpensiveFields extends AnalysisRule {
  NullInitializedDebugExpensiveFields()
    : super(
        name: code.name,
        description:
            'Verify that debug expensive fields are null initialized.',
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
    bool hasDebugOnly = false;
    for (final annotation in node.metadata) {
      if (annotation.name.name == '_debugOnly') {
        hasDebugOnly = true;
        break;
      }
    }

    if (!hasDebugOnly) {
      return;
    }

    for (final variable in node.fields.variables) {
      final initializer = variable.initializer;

      bool isCorrect = false;
      if (initializer is ConditionalExpression) {
        final condition = initializer.condition;
        final elseExp = initializer.elseExpression;
        if (condition is SimpleIdentifier && condition.name == 'kDebugMode') {
          if (elseExp is NullLiteral) {
            isCorrect = true;
          }
        }
      }

      if (!isCorrect) {
        rule.reportAtNode(variable);
      }
    }
  }
}
