// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Verify that no RenderBox subclasses call compute* instead of get* for
/// computing the intrinsic dimensions. The [candidates] variable contains the
/// full list of RenderBox intrinsic method invocations checked by this rule.
const Map<String, String> candidates = <String, String>{
  'computeDryBaseline': 'getDryBaseline',
  'computeDryLayout': 'getDryLayout',
  'computeDistanceToActualBaseline': 'getDistanceToBaseline, or getDistanceToActualBaseline',
  'computeMaxIntrinsicHeight': 'getMaxIntrinsicHeight',
  'computeMinIntrinsicHeight': 'getMinIntrinsicHeight',
  'computeMaxIntrinsicWidth': 'getMaxIntrinsicWidth',
  'computeMinIntrinsicWidth': 'getMinIntrinsicWidth',
};

class RenderBoxIntrinsicCalculationRule extends AnalysisRule {
  RenderBoxIntrinsicCalculationRule()
    : super(
        name: code.name,
        description: 'get* methods should be used to obtain the intrinsics of a RenderBox.',
      );

  static const LintCode code = LintCode(
    'render_box_intrinsics',
    'Typically the get* methods should be used to obtain the intrinsics of a RenderBox.',
    correctionMessage: 'Consider calling {0} instead.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final _Visitor visitor = _Visitor(this, context);
    registry
      .addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  static final Map<InterfaceElement, bool> _isRenderBoxClassElementCache =
      <InterfaceElement, bool>{};
  // The cached version, call this method instead of _checkIfImplementsRenderBox.
  static bool _implementsRenderBox(InterfaceElement interfaceElement) {
    // Framework naming convention: a RenderObject subclass names have "Render" in its name.
    if (!interfaceElement.name!.contains('Render')) {
      return false;
    }
    return interfaceElement.name == 'RenderBox' ||
        _isRenderBoxClassElementCache.putIfAbsent(
          interfaceElement,
          () => _checkIfImplementsRenderBox(interfaceElement),
        );
  }

  static bool _checkIfImplementsRenderBox(InterfaceElement element) {
    return element.allSupertypes.any(
      (InterfaceType interface) => _implementsRenderBox(interface.element),
    );
  }
  static bool _checkIfRenderBoxParent(AstNode? node) {
    if (node == null) {
      return false;
    }
    if (node case ClassDeclaration(:final Token name)) {
      // Ignore the RenderBox class implementation: that's the only place the
      // compute* methods are supposed to be called.
      return name.lexeme == 'RenderBox';
    }
    return _checkIfRenderBoxParent(node.parent);
  }

  static bool _checkForCommentContext(AstNode? node) {
    if (node == null) {
      return false;
    }
    if (node is CommentReference) {
      return true;
    }
    return _checkForCommentContext(node.parent);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is CommentReference) {
      return;
    }
    final String? correctMethodName = candidates[node.name];
    if (correctMethodName == null) {
      return;
    }
    if (_checkIfRenderBoxParent(node.parent) || _checkForCommentContext(node.parent)) {
      return;
    }
    final bool isCallingSuperImplementation = switch (node.parent) {
      PropertyAccess(target: SuperExpression()) ||
      MethodInvocation(target: SuperExpression()) => true,
      _ => false,
    };
    if (isCallingSuperImplementation) {
      return;
    }
    final Element? declaredInClassElement = node.element?.enclosingElement;
    if (declaredInClassElement is InterfaceElement &&
        _implementsRenderBox(declaredInClassElement)) {
      rule.reportAtNode(node, arguments: <Object>[correctMethodName]);
    }
  }
}
