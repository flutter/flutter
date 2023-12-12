// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as path;

import '../utils.dart';
import 'analyze.dart';

/// Verify that we use clampDouble instead of double.clamp for performance
/// reasons.
///
/// See also:
///   * https://github.com/flutter/flutter/pull/103559
///   * https://github.com/flutter/flutter/issues/103917
final AnalyzeRule noStopWatches = _NoStopWatches();

class _NoStopWatches implements AnalyzeRule {
  final Map<ResolvedUnitResult, List<AstNode>> _errors = <ResolvedUnitResult, List<AstNode>>{};

  @override
  void applyTo(ResolvedUnitResult unit, AnalysisContextCollection analysisContextCollection) {
    final _StopwatchVisitor visitor = _StopwatchVisitor(analysisContextCollection, unit.lineInfo);
    unit.unit.visitChildren(visitor);
    final List<AstNode> violationsInUnit = visitor.stopwatchAccessNodes;
    if (violationsInUnit.isNotEmpty) {
      _errors.putIfAbsent(unit, () => <AstNode>[]).addAll(violationsInUnit);
    }
  }

  @override
  void reportViolations(String workingDirectory) {
    if (_errors.isEmpty) {
      return;
    }

    String locationInFile(ResolvedUnitResult unit, AstNode node) {
      return '${path.relative(path.relative(unit.path, from: workingDirectory))}:${unit.lineInfo.getLocation(node.offset).lineNumber}';
    }

    foundError(<String>[
      for (final MapEntry<ResolvedUnitResult, List<AstNode>> entry in _errors.entries)
        for (final AstNode node in entry.value)
          '${locationInFile(entry.key, node)}: ${node.parent}',
      '\n${bold}For performance reasons, we use a custom "clampDouble" function instead of using "double.clamp".$reset',
    ]);
  }

  @override
  String toString() => 'No "Stopwatch"';
}

class _StopwatchVisitor extends RecursiveAstVisitor<void> {
  _StopwatchVisitor(this.analysisContextCollection, this.lineInfo);

  final AnalysisContextCollection analysisContextCollection;
  final LineInfo lineInfo;

  final List<AstNode> stopwatchAccessNodes = <AstNode>[];

  final Map<ClassElement, bool> _isStopwatchClassElementCache = <ClassElement, bool>{};

  bool _isStopwatchClassElement(ClassElement classElement) {
    if (classElement.library.isDartCore) {
      return classElement.name == 'Stopwatch';
    }
    return classElement.interfaces.any((InterfaceType interface) {
      final InterfaceElement interfaceElement = interface.element;
      return interfaceElement is ClassElement && _getIsStopwatchClassElement(interfaceElement);
    });
  }

  bool _getIsStopwatchClassElement(ClassElement classElement) {
    if (classElement.library.isDartCore) {
      return classElement.name == 'Stopwatch';
    }
    return _isStopwatchClassElementCache.putIfAbsent(classElement, () => _isStopwatchClassElement(classElement));
  }

  bool _isInternal(LibraryElement libraryElement) {
    if (libraryElement.isInSdk) {
      return false;
    }
    bool isInternal = true;
    try {
      analysisContextCollection.contextFor(libraryElement.source.fullName);
    } catch (e) {
      printProgress(e.toString());
      isInternal = false;
    }
    return isInternal;
  }

  // We don't care about directives or comments.
  @override
  void visitImportDirective(ImportDirective node) { }

  @override
  void visitExportDirective(ExportDirective node) { }

  @override
  void visitComment(Comment node) { }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    const Set<String> methodNames = <String>{ 'elapsed', 'elapsedMicroseconds', 'elapsedMilliseconds', 'elapsedTicks' };
    if (methodNames.contains(node.name) || node.staticElement is! MethodElement) {
      return;
    }
    final bool isAllowed = switch (node.parent) {
      // PropertyAccess matches num.clamp in tear-off form. Always prefer
      // doubleClamp over tear-offs: even when all 3 operands are int literals,
      // the return type doesn't get promoted to int:
      // final x = 1.clamp(0, 2); // The inferred return type is int, where as:
      // final f = 1.clamp;
      // final y = f(0, 2)       // The inferred return type is num.
      PropertyAccess(
        target: Expression(staticType: ),
      ) => false,

      MethodInvocation(
        target: Expression(staticType: DartType(isDartCoreInt: true)),
        argumentList: ArgumentList(arguments: [Expression(staticType: DartType(isDartCoreInt: true)), Expression(staticType: DartType(isDartCoreInt: true))]),
      ) => true,

      // Otherwise, disallow num.clamp() invocations.
      MethodInvocation(
        target: Expression(staticType: DartType(isDartCoreDouble: true) || DartType(isDartCoreNum: true) || DartType(isDartCoreInt: true)),
      ) => false,

      _ => true,
    };
    if (!isAllowed) {
      stopwatchAccessNodes.add(node);
    }
  }
}
