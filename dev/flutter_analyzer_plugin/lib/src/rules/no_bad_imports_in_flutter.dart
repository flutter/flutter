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

import '../flutter_analysis_rule.dart';

/// Checks for bad imports in `package:flutter`.
///
/// Restricts `package:meta/meta.dart` imports within `lib/src/` (excluding
/// `src/foundation/`), and prevents recursive self-imports (e.g. files under
/// `lib/src/widgets/` importing `package:flutter/widgets.dart`).
class NoBadImportsInFlutter extends FlutterAnalysisRule {
  NoBadImportsInFlutter()
    : super(name: code.name, description: 'Checks for bad imports in flutter package.');

  static const code = LintCode(
    'no_bad_imports_in_flutter',
    'Bad import in flutter package.',
    correctionMessage:
        'Use relative imports or valid exported packages. Do not recursive import or import meta/meta.dart.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path.replaceAll(r'\', '/');
    if (!filePath.contains('packages/flutter/lib/src/') && !filePath.contains('/home/test')) {
      return;
    }
    final visitor = _Visitor(this, filePath);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.filePath);

  final AnalysisRule rule;
  final String filePath;

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.uri.stringValue case final String uriStr) {
      final String absolutePath = filePath;

      if (uriStr == 'package:meta/meta.dart') {
        final bool isFoundation =
            absolutePath.contains('src/foundation/') || absolutePath.contains(r'src\foundation\');
        if (!isFoundation) {
          rule.reportAtNode(node.uri);
        }
        return;
      }

      final List<String> pathParts = path.split(absolutePath);
      final int srcIndex = pathParts.lastIndexOf('src');
      if (srcIndex != -1 && srcIndex + 1 < pathParts.length) {
        final String currentLayer = pathParts[srcIndex + 1];

        if (uriStr == 'package:flutter/$currentLayer.dart') {
          rule.reportAtNode(node.uri);
        }
      }
    }
  }
}
