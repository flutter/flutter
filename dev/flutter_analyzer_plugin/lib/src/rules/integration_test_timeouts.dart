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

import '../flutter_analysis_rule.dart';

/// Integration tests must specify `timeout: Timeout.none` to prevent them from getting stuck.
class IntegrationTestTimeouts extends FlutterAnalysisRule {
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
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path.replaceAll(r'\', '/');
    if (!filePath.contains('/home/test') && !filePath.contains('/dev/')) {
      return;
    }
    if (!filePath.contains('test_driver') ||
        (!filePath.endsWith('_test.dart') &&
            !filePath.endsWith('util.dart') &&
            !filePath.endsWith('test.dart'))) {
      return;
    }
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node case MethodInvocation(
      methodName: SimpleIdentifier(name: 'test'),
      :final ArgumentList argumentList,
    )) {
      final bool hasTimeoutNone = argumentList.arguments.any((Argument argument) {
        if (argument case NamedArgument(
          name: Token(lexeme: 'timeout'),
          argumentExpression: PrefixedIdentifier(
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
