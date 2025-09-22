// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Verify that we use clampDouble instead of double.clamp for performance
/// reasons.
///
/// See also:
///   * https://github.com/flutter/flutter/pull/103559
///   * https://github.com/flutter/flutter/issues/103917
class NoDoubleClamp extends AnalysisRule {
  NoDoubleClamp()
    : super(
        name: code.name,
        description:
            'Verify that we use clampDouble instead of double.clamp for performance reasons.',
      );

  static const LintCode code = LintCode(
    'no_double_clamp',
    'Avoid double.clamp for performance reasons.',
    correctionMessage: 'Use clampDouble instead.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final _Visitor visitor = _Visitor(this, context);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'clamp' || node.element is! MethodElement) {
      return;
    }
    final bool isAllowed = switch (node.parent) {
      // PropertyAccess matches num.clamp in tear-off form. Always prefer
      // doubleClamp over tear-offs: even when all 3 operands are int literals,
      // the return type doesn't get promoted to int:
      // final x = 1.clamp(0, 2); // The inferred return type is int, where as:
      // final f = 1.clamp;
      // final y = f(0, 2)       // The inferred return type is num.
      PropertyAccess(
        target: Expression(
          staticType: DartType(isDartCoreDouble: true) ||
              DartType(isDartCoreNum: true) ||
              DartType(isDartCoreInt: true),
        ),
      ) =>
        false,

      // Expressions like `final int x = 1.clamp(0, 2);` should be allowed.
      MethodInvocation(
        target: Expression(staticType: DartType(isDartCoreInt: true)),
        argumentList: ArgumentList(
          arguments: [
            Expression(staticType: DartType(isDartCoreInt: true)),
            Expression(staticType: DartType(isDartCoreInt: true)),
          ],
        ),
      ) =>
        true,

      // Otherwise, disallow num.clamp() invocations.
      MethodInvocation(
        target: Expression(
          staticType: DartType(isDartCoreDouble: true) ||
              DartType(isDartCoreNum: true) ||
              DartType(isDartCoreInt: true),
        ),
      ) =>
        false,

      _ => true,
    };
    if (!isAllowed) {
      rule.reportAtNode(node);
    }
  }
}
