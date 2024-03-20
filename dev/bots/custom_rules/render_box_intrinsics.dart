// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

import '../utils.dart';
import 'analyze.dart';

/// Verify that no RenderBox subclasses call compute* instead of get* for
/// computing the intrinsic dimensions. The full list of RenderBox intrinsic
/// methods checked by this rule is listed in [candidates].
final AnalyzeRule renderBoxIntrinsicCalculation = _RenderBoxIntrinsicCalculationRule();

const Map<String, String> candidates = <String, String> {
  'computeDryBaseline': 'getDryBaseline',
  'computeDryLayout': 'getDryLayout',
  'computeDistanceToActualBaseline': 'getDistanceToBaseline, or getDistanceToActualBaseline',
  'computeMaxIntrinsicHeight': 'getMaxIntrinsicHeight',
  'computeMinIntrinsicHeight': 'getMinIntrinsicHeight',
  'computeMaxIntrinsicWidth': 'getMaxIntrinsicWidth',
  'computeMinIntrinsicWidth': 'getMinIntrinsicWidth'
};

class _RenderBoxIntrinsicCalculationRule implements AnalyzeRule {
  final Map<ResolvedUnitResult, List<AstNode>> _errors = <ResolvedUnitResult, List<AstNode>>{};

  @override
  void applyTo(ResolvedUnitResult unit) {
    final _RenderBoxSubclassVisitor visitor = _RenderBoxSubclassVisitor(unit);
    unit.unit.visitChildren(visitor);
    final List<AstNode> violationsInUnit = visitor.violationNode;
    if (violationsInUnit.isNotEmpty) {
      _errors.putIfAbsent(unit, () => <AstNode>[]).addAll(violationsInUnit);
    }
  }

  @override
  void reportViolations(String workingDirectory) {
    if (_errors.isEmpty) {
      return;
    }

    foundError(<String>[
      for (final MapEntry<ResolvedUnitResult, List<AstNode>> entry in _errors.entries)
        for (final AstNode node in entry.value)
          '${locationInFile(entry.key, node, workingDirectory)}: ${node.parent}',
      '\n${bold}For performance reasons, we use a custom "clampDouble" function instead of using "double.clamp".$reset',
    ]);
  }

  @override
  String toString() => 'RenderBox subclass intrinsic calculation best practices';
}

class _RenderBoxSubclassVisitor extends RecursiveAstVisitor<void> {
  _RenderBoxSubclassVisitor(this.compilationUnit);

  static final Set<String> methodNames = candidates.keys.toSet();
  static final Map<ClassElement, bool> _isRenderBoxClassElementCache = <ClassElement, bool>{};

  final ResolvedUnitResult compilationUnit;

  final List<AstNode> violationNode = <AstNode>[];


  // The cached version, call this method instead of _checkIfImplementsRenderBox.
  bool _implementsRenderBox(ClassElement classElement) {
    // Framework naming convention: RenderObject subclass names must start with
    // _Render or Render.
    if (!classElement.name.contains('Render') || !_isInternal(classElement.library)) {
      return false;
    }
    return classElement.name == 'RenderBox'
        || _isRenderBoxClassElementCache.putIfAbsent(classElement, () => _checkIfImplementsRenderBox(classElement));
  }

  bool _checkIfImplementsRenderBox(ClassElement classElement) {
    return classElement.allSupertypes.any((InterfaceType interface) {
      final InterfaceElement interfaceElement = interface.element;
      return interfaceElement is ClassElement && _implementsRenderBox(interfaceElement);
    });
  }

  bool _isInternal(LibraryElement libraryElement) {
    return path.isWithin(
      compilationUnit.session.analysisContext.contextRoot.root.path,
      libraryElement.source.fullName,
    );
  }

  // We don't care about directives, comments, or asserts.
  @override
  void visitImportDirective(ImportDirective node) { }
  @override
  void visitExportDirective(ExportDirective node) { }
  @override
  void visitComment(Comment node) { }
  @override
  void visitAssertStatement(AssertStatement node) { }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Ignore the RenderBox class implementation: that's the only place the
    // compute* methods are supposed to be called.
    if (node.name.lexeme != 'RenderBox') {
      super.visitClassDeclaration(node);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!methodNames.contains(node.name)) {
      return;
    }
    final bool isCallingSuperImplementation = switch (node.parent) {
      PropertyAccess(target: SuperExpression())  ||
      MethodInvocation(target: SuperExpression()) => true,
      _ => false,
    };
    if (isCallingSuperImplementation) {
      return;
    }
    final Element? declaredInClassElement = node.staticElement?.declaration?.enclosingElement;
    if (declaredInClassElement is ClassElement && _implementsRenderBox(declaredInClassElement)) {
      violationNode.add(node);
    }
  }
}
