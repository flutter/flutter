// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';

/// Base class for all custom analysis rules in the Flutter repository.
///
/// Automatically excludes read-only areas of the repository, including
/// Material and Cupertino implementations and tests.
abstract class FlutterAnalysisRule extends AnalysisRule {
  FlutterAnalysisRule({required super.name, required super.description});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path.replaceAll(r'\', '/');
    if (isReadOnly(filePath)) {
      return;
    }
    registerCustomNodeProcessors(registry, context);
  }

  /// Registers AST node processors for this rule when the target file is not exempt.
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context);

  /// Whether [normalizedPath] belongs to a read-only area of the repository
  /// (e.g. Material and Cupertino implementations and tests).
  static bool isReadOnly(String normalizedPath) {
    // In-memory test files in package:analyzer_testing start with /home/test
    if (normalizedPath.contains('/home/test')) {
      return false;
    }
    return normalizedPath.contains('/material/') ||
        normalizedPath.contains('/cupertino/') ||
        normalizedPath.endsWith('/material.dart') ||
        normalizedPath.endsWith('/cupertino.dart') ||
        normalizedPath.contains('src/material') ||
        normalizedPath.contains('src/cupertino') ||
        normalizedPath.contains('test/material') ||
        normalizedPath.contains('test/cupertino');
  }
}
