// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const String _flutterToolsPackagePath = 'packages/flutter_tools/';
const String _flutterToolsPackagePrefix = 'package:flutter_tools/';
const String _globalsFileName = 'globals.dart';
const String _globalsFileSuffix = '/globals.dart';
const String _packagePrefix = 'package:';

/// Verifies that `globals.dart` is not imported in specified `flutter_tools` files.
class NoGlobalsInFlutterTools extends AnalysisRule {
  NoGlobalsInFlutterTools([Set<String>? restrictedPaths])
    : restrictedPaths =
          restrictedPaths?.map((String p) => p.replaceAll(r'\', '/')).toSet() ??
          defaultRestrictedPaths,
      super(
        name: code.name,
        description: 'Verify that globals.dart is not imported in migrated flutter_tools files.',
      );

  static const LintCode code = LintCode(
    'no_globals_in_flutter_tools',
    'Do not import globals.dart in this file.',
    correctionMessage:
        'Pass dependencies explicitly via constructor parameters rather than accessing ambient globals.',
    severity: DiagnosticSeverity.ERROR,
  );

  /// Default set of file paths relative to `packages/flutter_tools/` that must
  /// not import `globals.dart`.
  static const Set<String> defaultRestrictedPaths = <String>{
    'lib/src/commands/clean.dart',
    'test/commands.shard/hermetic/clean_test.dart',
  };

  final Set<String> restrictedPaths;

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path.replaceAll(r'\', '/');
    final int toolIndex = filePath.lastIndexOf(_flutterToolsPackagePath);
    if (toolIndex == -1 || (toolIndex > 0 && filePath[toolIndex - 1] != '/')) {
      return;
    }
    final String relativePath = filePath.substring(toolIndex + _flutterToolsPackagePath.length);
    if (!restrictedPaths.contains(relativePath)) {
      return;
    }
    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.uri.stringValue case final String uriStr) {
      final bool isFlutterToolsGlobals =
          uriStr.startsWith(_packagePrefix)
              ? uriStr.startsWith(_flutterToolsPackagePrefix) && uriStr.endsWith(_globalsFileSuffix)
              : uriStr == _globalsFileName || uriStr.endsWith(_globalsFileSuffix);
      if (isFlutterToolsGlobals) {
        rule.reportAtNode(node.uri);
      }
    }
  }
}
