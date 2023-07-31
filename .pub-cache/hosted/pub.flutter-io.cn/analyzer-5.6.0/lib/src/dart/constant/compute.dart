// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Compute values of the given [constants] with correct ordering.
void computeConstants({
  required DeclaredVariables declaredVariables,
  required List<ConstantEvaluationTarget> constants,
  required FeatureSet featureSet,
  required ConstantEvaluationConfiguration configuration,
}) {
  var walker = _ConstantWalker(
    declaredVariables: declaredVariables,
    featureSet: featureSet,
    configuration: configuration,
  );

  for (var constant in constants) {
    walker.walk(walker._getNode(constant));
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
  final FeatureSet featureSet;
  final ConstantEvaluationConfiguration configuration;
  final Map<ConstantEvaluationTarget, _ConstantNode> nodeMap = {};

  _ConstantWalker({
    required this.declaredVariables,
    required this.featureSet,
    required this.configuration,
  });

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
      isNonNullableByDefault: featureSet.isEnabled(Feature.non_nullable),
      configuration: configuration,
    );
  }

  _ConstantNode _getNode(ConstantEvaluationTarget constant) {
    return nodeMap.putIfAbsent(
      constant,
      () => _ConstantNode(this, constant),
    );
  }
}
