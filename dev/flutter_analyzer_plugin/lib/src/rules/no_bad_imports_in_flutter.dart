// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Checks for bad imports in `package:flutter`.
///
/// Restricts `package:meta/meta.dart` imports within `lib/src/` (excluding
/// `src/foundation/`), and prevents recursive self-imports (e.g. files under
/// `lib/src/widgets/` importing `package:flutter/widgets.dart`).
class NoBadImportsInFlutter extends AnalysisRule {
  NoBadImportsInFlutter()
    : super(name: code.name, description: 'Checks for bad imports in flutter package.');

  static const LintCode code = LintCode(
    'no_bad_imports_in_flutter',
    'Bad import in flutter package.',
    correctionMessage:
        'Use relative imports or valid exported packages. Do not recursive import or import meta/meta.dart.',
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
      final String? absolutePath = context.currentUnit?.unit.declaredFragment?.source.fullName;
      if (absolutePath == null) {
        return;
      }

      final bool isSrc = absolutePath.contains('lib/src/') || absolutePath.contains(r'lib\src\');
      if (!isSrc) {
        return;
      }

      if (uriStr == 'package:meta/meta.dart') {
        final bool isFoundation =
            absolutePath.contains('src/foundation/') || absolutePath.contains(r'src\foundation\');
        if (!isFoundation) {
          rule.reportAtNode(node.uri);
        }
        return;
      }

      final token = absolutePath.contains('/') ? '/' : r'\';
      final List<String> pathParts = absolutePath.split(token);
      final int srcIndex = pathParts.lastIndexOf('src');
      if (srcIndex != -1 && srcIndex + 1 < pathParts.length) {
        final String currentDir = pathParts[srcIndex + 1];
        if (uriStr == 'package:flutter/$currentDir.dart') {
          rule.reportAtNode(node.uri);
        }
      }
    }
  }
}
