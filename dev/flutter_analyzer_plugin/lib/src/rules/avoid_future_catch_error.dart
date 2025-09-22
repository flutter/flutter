// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

class AvoidFutureCatchError extends AnalysisRule {
  AvoidFutureCatchError()
    : super(
        name: code.name,
        description: 'Future.catchError and Future.onError are not type safe.',
      );

  static const LintCode code = LintCode(
    'avoid_future_catch_error',
    'Avoid using Future.catchError',
    correctionMessage: 'Use Future.then instead (https://github.com/dart-lang/sdk/issues/51248).',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final _Visitor visitor = _Visitor(this, context);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node case MethodInvocation(
      methodName: SimpleIdentifier(name: 'onError' || 'catchError'),
      realTarget: Expression(staticType: DartType(isDartAsyncFuture: true)),
    )) {
      rule.reportAtNode(node);
    }
  }
}
