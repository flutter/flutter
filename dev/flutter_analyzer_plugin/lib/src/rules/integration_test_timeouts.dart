// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as path;

/// Integration tests in flutter test_driver must have `timeout: Timeout.none`.
class IntegrationTestTimeouts extends AnalysisRule {
  IntegrationTestTimeouts() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      'Integration tests must specify `timeout: Timeout.none` to prevent them from getting stuck.';

  static const LintCode code = LintCode(
    'integration_test_timeouts',
    ruleDescription,
    correctionMessage: 'Add `timeout: Timeout.none` to the test() arguments.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

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

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final fullName = context.currentUnit!.file.path;
    
    // Only applies to `dev/**/test_driver/**_test.dart` and `dev/**/test_driver/**util.dart`.
    if (!fullName.contains('test_driver')) {
      return;
    }
    
    // We only care about dev directory in flutter root, but the easiest heuristic
    // here is checking if 'dev' and 'test_driver' are in the path.
    if (!fullName.split(path.separator).contains('dev')) {
      return;
    }

    if (!fullName.endsWith('_test.dart') && !fullName.endsWith('util.dart')) {
      return;
    }

    if (node.methodName.name == 'test') {
      bool hasTimeoutNone = false;
      for (final Expression argument in node.argumentList.arguments) {
        if (argument is NamedExpression && argument.name.label.name == 'timeout') {
          final expression = argument.expression;
          if (expression is PrefixedIdentifier &&
              expression.prefix.name == 'Timeout' &&
              expression.identifier.name == 'none') {
            hasTimeoutNone = true;
          }
        }
      }

      if (!hasTimeoutNone) {
        rule.reportAtNode(node.methodName);
      }
    }
  }
}
