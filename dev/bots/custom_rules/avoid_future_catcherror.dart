// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../utils.dart';
import 'analyze.dart';

/// Don't use Future.catchError or Future.onError.
///
/// See https://github.com/flutter/flutter/pull/130662 for more context.
///
/// **BAD:**
///
/// ```dart
/// Future<Object?> doSomething() {
///   return doSomethingAsync().catchError((_) => null);
/// }
///
/// Future<Object?> doSomethingAsync() {
///   return Future<Object>.error(Exception('error'));
/// }
/// ```
///
/// **GOOD:**
///
/// ```dart
/// Future<Object?> doSomething() {
///   return doSomethingAsync().then(
///     (Object? obj) => obj,
///     onError: (_) => null,
///   );
/// }
///
/// Future<Object?> doSomethingAsync() {
///   return Future<Object>.error(Exception('error'));
/// }
/// ```
class AvoidFutureCatchError extends AnalyzeRule {
  final Map<ResolvedUnitResult, List<AstNode>> _errors = <ResolvedUnitResult, List<AstNode>>{};

  @override
  void applyTo(ResolvedUnitResult unit) {
    final _Visitor visitor = _Visitor();
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
      '\n${bold}Future.catchError and Future.onError are not type safe--instead use Future.then: https://github.com/dart-lang/sdk/issues/51248$reset',
    ]);
  }

  @override
  String toString() => 'Avoid "Future.catchError" and "Future.onError"';
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor();

  final List<AstNode> _offendingNodes = <AstNode>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'onError' && node.methodName.name != 'catchError') {
      return;
    }
    final DartType? targetType = node.realTarget?.staticType;
    if (targetType == null || !targetType.isDartAsyncFuture) {
      return;
    }
    _offendingNodes.add(node);
  }
}
