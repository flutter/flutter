// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const _testSuffix = '_test.dart';

const Set<String> _exemptTestImports = <String>{
  'package:flutter_test/flutter_test.dart',
  'hit_test.dart',
  'package:test_api/src/backend/live_test.dart',
  'package:integration_test/integration_test.dart',
};

/// Verifies that files do not import a test directly.
class NoTestImports extends AnalysisRule {
  NoTestImports()
    : super(name: code.name, description: 'Verify that files do not import a test directly.');

  /// The [LintCode] for this rule.
  static const code = LintCode(
    'no_test_imports',
    'Do not import a test file directly. Test utilities should be in their own file.',
    correctionMessage: 'Move test utilities to a non-test file or use an exempt test package.',
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
    if (node.uri.stringValue case final String uriStr) {
      if (uriStr.endsWith(_testSuffix) && !_exemptTestImports.contains(uriStr)) {
        rule.reportAtNode(node.uri);
      }
    }
  }
}
