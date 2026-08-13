// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types, omit_obvious_local_variable_types, prefer_final_locals
// TODO(nate-thegrate): remove this file if @protected changes, or add a test if it doesn't.
// https://github.com/dart-lang/sdk/issues/57094

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

class ProtectPublicStateSubtypes extends AnalysisRule {
  ProtectPublicStateSubtypes()
    : super(
        name: code.name,
        description:
            'Public State subtypes should add @protected when overriding methods '
            'to avoid exposing internal logic to developers.',
      );

  static const LintCode code = LintCode(
    'protect_public_state_subtypes',
    'Public State subtypes should add @protected when overriding methods '
        'to avoid exposing internal logic to developers.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  /// Holds the `State` class [InterfaceElement].
  InterfaceElement? _stateElement;

  bool _isPublicStateSubtype(InterfaceElement element) {
    if (!element.isPublic) {
      return false;
    }
    final InterfaceElement? stateElement = _stateElement;
    if (stateElement != null) {
      return element.allSupertypes.any((InterfaceType t) => t.element == stateElement);
    }
    for (final InterfaceType superType in element.allSupertypes) {
      if (superType.element.name == 'State') {
        _stateElement = superType.element;
        return true;
      }
    }
    return false;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final InterfaceElement? element = node.declaredFragment?.element;
    if (element != null && _isPublicStateSubtype(element)) {
      node.visitChildren(this);
    }
  }

  /// Checks whether overridden `State` methods have the `@protected` annotation,
  /// and reports the method if not.
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    switch (node.name.lexeme) {
      case 'initState':
      case 'setState':
      case 'didUpdateWidget':
      case 'didChangeDependencies':
      case 'reassemble':
      case 'deactivate':
      case 'activate':
      case 'dispose':
      case 'build':
      case 'debugFillProperties':
        final ExecutableElement? element = node.declaredFragment?.element;
        if (element != null && !element.metadata.hasProtected) {
          rule.reportAtNode(node);
        }
    }
  }
}
