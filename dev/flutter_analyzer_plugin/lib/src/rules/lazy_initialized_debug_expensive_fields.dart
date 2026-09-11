// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_analysis_rule.dart';

/// An analysis rule that verifies that debug expensive fields annotated with @_debugOnly
/// are lazily initialized (declared as a late or static field).
class LazyInitializedDebugExpensiveFields extends FlutterAnalysisRule {
  LazyInitializedDebugExpensiveFields()
    : super(
        name: code.name,
        description: 'Verify that debug expensive fields are lazily initialized.',
      );

  static const LintCode code = LintCode(
    'lazy_initialized_debug_expensive_fields',
    'Non-static fields annotated with @_debugOnly must be lazily initialized.',
    correctionMessage: 'Declare with: @_debugOnly late final <Type> field = <DebugValue>;',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final bool hasDebugOnly = node.metadata.any(
      (Annotation annotation) => annotation.name.name == '_debugOnly',
    );

    // A field is lazy when it's static or late.
    final bool eagerlyInitialized = hasDebugOnly && !(node.isStatic || node.fields.isLate);
    if (eagerlyInitialized) {
      rule.reportAtNode(node);
    }
  }
}
