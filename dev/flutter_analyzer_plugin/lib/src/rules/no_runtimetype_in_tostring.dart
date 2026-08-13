// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// An analysis rule that verifies that runtimeType is not used in toString methods.
class NoRuntimeTypeInToString extends AnalysisRule {
  NoRuntimeTypeInToString()
    : super(name: code.name, description: 'Verify that we do not use runtimeType in toString.');

  static const LintCode code = LintCode(
    'no_runtimetype_in_tostring',
    'Avoid calling runtimeType in toString.',
    correctionMessage: 'Use a fast literal or omit it.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node case MethodDeclaration(:final FunctionBody body) when node.name.lexeme == 'toString') {
      final bodyVisitor = _BodyVisitor(rule, context);
      body.accept(bodyVisitor);
    }
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  _BodyVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitAssertStatement(AssertStatement node) {
    // Ignore runtimeType calls inside asserts.
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node case SimpleIdentifier(name: 'runtimeType')) {
      rule.reportAtNode(node);
    }
    super.visitSimpleIdentifier(node);
  }
}
