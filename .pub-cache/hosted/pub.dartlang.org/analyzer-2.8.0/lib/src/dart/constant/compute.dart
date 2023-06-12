// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;

/// Compute values of the given [constants] with correct ordering.
void computeConstants(
    TypeProvider typeProvider,
    TypeSystemImpl typeSystem,
    DeclaredVariables declaredVariables,
    List<ConstantEvaluationTarget> constants,
    ExperimentStatus experimentStatus) {
  var walker = _ConstantWalker(declaredVariables, experimentStatus);

  for (var constant in constants) {
    var node = walker._getNode(constant);
    if (!node.isEvaluated) {
      walker.walk(node);
    }
  }
}

/// [graph.Node] that is used to compute constants in dependency order.
class _ConstantNode extends graph.Node<_ConstantNode> {
  final _ConstantWalker walker;
  final ConstantEvaluationTarget constant;

  _ConstantNode(this.walker, this.constant);

  @override
  bool get isEvaluated => constant.isConstantEvaluated;

  @override
  List<_ConstantNode> computeDependencies() {
    return walker._computeDependencies(this);
  }
}

/// [graph.DependencyWalker] for computing constants and detecting cycles.
class _ConstantWalker extends graph.DependencyWalker<_ConstantNode> {
  final DeclaredVariables declaredVariables;
  final ExperimentStatus experimentStatus;
  final Map<ConstantEvaluationTarget, _ConstantNode> nodeMap = {};

  _ConstantWalker(this.declaredVariables, this.experimentStatus);

  @override
  void evaluate(_ConstantNode node) {
    _getEvaluationEngine(node).computeConstantValue(node.constant);
  }

  @override
  void evaluateScc(List<_ConstantNode> scc) {
    var constantsInCycle = scc.map((node) => node.constant);
    for (var node in scc) {
      var constant = node.constant;
      if (constant is ConstructorElementImpl) {
        constant.isCycleFree = false;
      }
      _getEvaluationEngine(node).generateCycleError(constantsInCycle, constant);
    }
  }

  List<_ConstantNode> _computeDependencies(_ConstantNode node) {
    var evaluationEngine = _getEvaluationEngine(node);
    var targets = <ConstantEvaluationTarget>[];
    evaluationEngine.computeDependencies(node.constant, targets.add);
    return targets.map(_getNode).toList();
  }

  ConstantEvaluationEngine _getEvaluationEngine(_ConstantNode node) {
    return ConstantEvaluationEngine(
      declaredVariables: declaredVariables,
      isNonNullableByDefault: experimentStatus.non_nullable,
    );
  }

  _ConstantNode _getNode(ConstantEvaluationTarget constant) {
    return nodeMap.putIfAbsent(
      constant,
      () => _ConstantNode(this, constant),
    );
  }
}
