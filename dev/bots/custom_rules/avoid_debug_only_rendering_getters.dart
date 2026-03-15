// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../utils.dart';
import 'analyze.dart';

// The comment pattern representing the "flutter_ignore" inline directive that
// indicates the line should be exempt from the debug-only getter check.
final Pattern _ignoreDirective = RegExp(
  r'// flutter_ignore: .*debug_only_rendering_getter .*\(see analyze\.dart\)',
);

/// Verify that debug-only getters on RenderObject are not used outside of
/// asserts or debug-only contexts.
///
/// The following getters on RenderObject return meaningless values in release
/// builds and should only be used in asserts or debug-only code:
///
///  * `debugNeedsLayout`
///  * `debugNeedsPaint`
///  * `debugNeedsCompositedLayerUpdate`
///  * `debugNeedsSemanticsUpdate`
final AnalyzeRule avoidDebugOnlyRenderingGetters = _AvoidDebugOnlyRenderingGetters();

const Set<String> _debugOnlyGetters = <String>{
  'debugNeedsLayout',
  'debugNeedsPaint',
  'debugNeedsCompositedLayerUpdate',
  'debugNeedsSemanticsUpdate',
};

class _AvoidDebugOnlyRenderingGetters implements AnalyzeRule {
  final Map<ResolvedUnitResult, List<AstNode>> _errors = <ResolvedUnitResult, List<AstNode>>{};

  @override
  void applyTo(ResolvedUnitResult unit) {
    final visitor = _Visitor(unit);
    unit.unit.visitChildren(visitor);
    final List<AstNode> violationsInUnit = visitor.offendingNodes;
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
      '\n${bold}Debug-only getters on RenderObject (debugNeedsLayout, debugNeedsPaint, debugNeedsCompositedLayerUpdate, debugNeedsSemanticsUpdate) are only meaningful in debug mode. Only use them in asserts.$reset',
    ]);
  }

  @override
  String toString() => 'Avoid debug-only RenderObject getters outside of asserts';
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.compilationUnit);

  final ResolvedUnitResult compilationUnit;
  final List<AstNode> offendingNodes = <AstNode>[];

  // We don't care about directives or comments.
  @override
  void visitImportDirective(ImportDirective node) {}

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitComment(Comment node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_debugOnlyGetters.contains(node.name)) {
      return;
    }

    // Check that the getter belongs to a RenderObject subclass.
    final Element? element = node.element;
    if (element is! PropertyAccessorElement) {
      return;
    }
    final Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) {
      return;
    }
    if (!_isRenderObjectSubclass(enclosingElement)) {
      return;
    }

    // Allow usage inside assert statements.
    if (_isInAssert(node)) {
      return;
    }

    // Allow usage inside the debug getter definitions themselves.
    if (_isInDebugGetterDefinition(node)) {
      return;
    }

    // Allow usage with a trailing flutter_ignore comment.
    if (_hasTrailingFlutterIgnore(node)) {
      return;
    }

    offendingNodes.add(node);
  }

  /// Returns true if [enclosingElement] is `RenderObject` or a subclass of it.
  static bool _isRenderObjectSubclass(InterfaceElement enclosingElement) {
    bool isRenderObjectType(InterfaceElement element) {
      return element.name == 'RenderObject' &&
          element.library.source.uri.toString() == 'package:flutter/src/rendering/object.dart';
    }

    if (isRenderObjectType(enclosingElement)) {
      return true;
    }
    return enclosingElement.allSupertypes.any((InterfaceType supertype) => isRenderObjectType(supertype.element));
  }

  /// Returns true if [node] is inside an `assert(...)` statement or an
  /// `assert(() { ... }())` closure.
  static bool _isInAssert(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is Assertion) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  /// Returns true if [node] is inside the definition of one of the debug-only
  /// getters (i.e., the getter body itself in RenderObject).
  static bool _isInDebugGetterDefinition(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration &&
          current.isGetter &&
          _debugOnlyGetters.contains(current.name.lexeme)) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  bool _hasTrailingFlutterIgnore(AstNode node) {
    return compilationUnit.content
        .substring(
          node.offset + node.length,
          compilationUnit.lineInfo.getOffsetOfLineAfter(node.offset + node.length),
        )
        .contains(_ignoreDirective);
  }
}
