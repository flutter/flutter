// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

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
    final String fullName = context.currentUnit!.file.path;
    if (!fullName.contains('test_driver') && !fullName.contains('test.dart')) {
      return;
    }

    if (node case MethodInvocation(
      methodName: SimpleIdentifier(name: 'test'),
      :final ArgumentList argumentList,
    )) {
      final bool hasTimeoutNone = argumentList.arguments.any((Expression argument) {
        if (argument case NamedExpression(
          name: Label(label: SimpleIdentifier(name: 'timeout')),
          expression: PrefixedIdentifier(
            prefix: SimpleIdentifier(name: 'Timeout'),
            identifier: SimpleIdentifier(name: 'none'),
          ),
        )) {
          return true;
        }
        return false;
      });

      if (!hasTimeoutNone) {
        rule.reportAtNode(node.methodName);
      }
    }
  }
}
