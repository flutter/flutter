// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../utils.dart';
import 'analyze.dart';

class NoStdinWrite extends AnalyzeRule {
  final Map<ResolvedUnitResult, List<AstNode>> _errors = <ResolvedUnitResult, List<AstNode>>{};

  @override
  void applyTo(ResolvedUnitResult unit) {
    final _Visitor visitor = _Visitor(unit);
    unit.unit.visitChildren(visitor);
    if (visitor._offendingNodes.isNotEmpty) {
      _errors.putIfAbsent(unit, () => <AstNode>[]).addAll(visitor._offendingNodes);
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
      '\n${bold}No Process.start$reset',
    ]);
  }

  @override
  String toString() => 'Avoid Process.start';
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this._unit);

  final ResolvedUnitResult _unit;

  final List<AstNode> _offendingNodes = <AstNode>[];

  static const List<String> _allowList = <String>[
    'package:flutter_tools/src/base/process.dart',
  ];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_allowList.contains(_unit.libraryElement.location?.encoding)) {
      return;
    }
    if (node.methodName.name != 'start') {
      return;
    }
    final String? className = node.realTarget?.staticType?.element?.name;
    if (className != 'ProcessManager') {
      return;
    }
    final String? libraryLocation = node.realTarget?.staticType?.element?.library?.location?.encoding;
    if (libraryLocation == null || !libraryLocation.startsWith('package:process')) {
      return;
    }

    _offendingNodes.add(node);
  }
}
