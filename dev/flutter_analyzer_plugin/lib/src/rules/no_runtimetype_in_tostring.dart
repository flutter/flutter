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

class NoRuntimeTypeInToString extends AnalysisRule {
  NoRuntimeTypeInToString()
    : super(
        name: code.name,
        description:
            'Verify that we do not use runtimeType in toString.',
      );

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
    if (node.name.lexeme != 'toString') {
      return;
    }

    final bodyVisitor = _BodyVisitor(rule, context);
    node.body.accept(bodyVisitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  _BodyVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'runtimeType') {
      // Omit checking if it's the right property, as runtimeType is unique enough
      // in string-based linting. AST gives us a bit more safety in that if we have
      // a local var called runtimeType, we could accidentally flag it, but the
      // string-rule flagged strings too.
      rule.reportAtNode(node);
    }
    super.visitSimpleIdentifier(node);
  }
}
