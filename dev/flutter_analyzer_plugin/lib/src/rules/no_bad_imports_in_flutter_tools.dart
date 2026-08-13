// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoBadImportsInFlutterTools extends AnalysisRule {
  NoBadImportsInFlutterTools() : super(name: code.name, description: 'flutter_tools should not import flutter_tools');

  static const LintCode code = LintCode(
    'no_bad_imports_in_flutter_tools',
    'Do not import flutter_tools from within flutter_tools.',
    correctionMessage: 'Use relative imports instead.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.uri.stringValue?.contains('package:flutter_tools/') == true) {
      rule.reportAtNode(node.uri);
    }
  }
}
