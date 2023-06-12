// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart';

/// Data structure tracking the type inference dependencies between generic
/// invocation parameters.
///
/// [planReconciliationStages] is used as part of support for
/// https://github.com/dart-lang/language/issues/731 (improved inference for
/// fold etc.) to choose the proper order in which to recursively analyze
/// function literals passed as invocation arguments.
abstract class FunctionLiteralDependencies<TypeVariable, ParamInfo,
    DeferredParamInfo extends ParamInfo> {
  final List<_Node<ParamInfo>> _paramNodes = [];

  /// Construct a [FunctionLiteralDependencies] object that's prepared to
  /// determine the order to resolve [deferredParams] for a generic invocation
  /// involving the given [typeVariables].
  ///
  /// [unDeferredParams] should contain information about any parameters
  /// corresponding to arguments that have already been type inferred.
  FunctionLiteralDependencies(
      Iterable<DeferredParamInfo> deferredParams,
      Iterable<TypeVariable> typeVariables,
      Iterable<ParamInfo> unDeferredParams) {
    Map<TypeVariable, Set<_Node<ParamInfo>>> paramsDependingOnTypeVar = {};
    Map<TypeVariable, Set<_Node<ParamInfo>>> paramsConstrainingTypeVar = {};
    int deferredParamIndex = 0;
    for (DeferredParamInfo param in deferredParams) {
      _Node<ParamInfo> paramNode =
          new _Node<ParamInfo>(param, deferredParamIndex: deferredParamIndex++);
      _paramNodes.add(paramNode);
      for (TypeVariable v in typeVarsFreeInParamParams(param)) {
        (paramsDependingOnTypeVar[v] ??= {}).add(paramNode);
      }
      for (TypeVariable v in typeVarsFreeInParamReturns(param)) {
        (paramsConstrainingTypeVar[v] ??= {}).add(paramNode);
      }
    }
    for (ParamInfo param in unDeferredParams) {
      _Node<ParamInfo> paramNode =
          new _Node<ParamInfo>(param, deferredParamIndex: null);
      _paramNodes.add(paramNode);
      // Note: for un-deferred parameters, we only care about
      // typeVarsFreeInParamReturns, because these parameters have already been
      // analyzed, so they can't depend on other parameters.
      for (TypeVariable v in typeVarsFreeInParamReturns(param)) {
        (paramsConstrainingTypeVar[v] ??= {}).add(paramNode);
      }
    }
    for (TypeVariable typeVariable in typeVariables) {
      for (_Node<ParamInfo> paramNode
          in paramsDependingOnTypeVar[typeVariable] ?? const {}) {
        paramNode.dependencies
            .addAll(paramsConstrainingTypeVar[typeVariable] ?? const {});
      }
    }
  }

  /// Computes the order in which to resolve the deferred parameters passed to
  /// the constructor.
  ///
  /// Each entry in the returned list represents the set of parameters whose
  /// corresponding arguments should be visited during a single stage of
  /// resolution; after each stage, the assignment of actual types to type
  /// variables should be refined.  The list of parameters in each stage is
  /// sorted to match the order of the `deferredParams` node passed to the
  /// constructor.
  ///
  /// So, for example, if the parameters in question are A, B, and C, and the
  /// returned list is `[[A, B], [C]]`, then first parameters A and B should be
  /// resolved, then the assignment of actual types to type variables should be
  /// refined, and then C should be resolved, and then the final assignment of
  /// actual types to type variables should be computed.
  ///
  /// Note that the first stage may be empty; when this happens, it means that
  /// the assignment of actual types to type variables should be refined before
  /// doing any visiting.
  List<List<DeferredParamInfo>> planReconciliationStages() {
    _DependencyWalker<ParamInfo, DeferredParamInfo> walker =
        new _DependencyWalker<ParamInfo, DeferredParamInfo>();
    for (_Node<ParamInfo> paramNode in _paramNodes) {
      walker.walk(paramNode);
    }
    List<_Node<ParamInfo>> _sortStage(List<_Node<ParamInfo>> stage) {
      stage.sort((a, b) => a.deferredParamIndex! - b.deferredParamIndex!);
      return stage;
    }

    return [
      for (List<_Node<ParamInfo>> stage in walker.reconciliationStages)
        [
          for (_Node<ParamInfo> node in _sortStage(stage))
            node.param as DeferredParamInfo
        ]
    ];
  }

  /// If the type of the parameter corresponding to [param] is a function type,
  /// the set of type parameters referred to by the parameter types of that
  /// parameter.  If the type of the parameter is not a function type, an empty
  /// iterable should be returned.
  ///
  /// Should be overridden by the client.
  Iterable<TypeVariable> typeVarsFreeInParamParams(DeferredParamInfo param);

  /// If the type of the parameter corresponding to [param] is a function type,
  /// the set of type parameters referred to by the return type of that
  /// parameter.  If the type of the parameter is not a function type, the set
  /// type parameters referred to by the type of the parameter should be
  /// returned.
  ///
  /// Should be overridden by the client.
  Iterable<TypeVariable> typeVarsFreeInParamReturns(ParamInfo param);
}

/// Derived class of [DependencyWalker] capable of walking the graph of type
/// inference dependencies among parameters.
class _DependencyWalker<ParamInfo, DeferredParamInfo extends ParamInfo>
    extends DependencyWalker<_Node<ParamInfo>> {
  /// The set of reconciliation stages accumulated so far.
  final List<List<_Node<ParamInfo>>> reconciliationStages = [];

  @override
  void evaluate(_Node<ParamInfo> v) => evaluateScc([v]);

  @override
  void evaluateScc(List<_Node<ParamInfo>> nodes) {
    int stageNum = 0;
    for (_Node<ParamInfo> node in nodes) {
      for (_Node<ParamInfo> dependency in node.dependencies) {
        int? dependencyStageNum = dependency.stageNum;
        if (dependencyStageNum != null && dependencyStageNum >= stageNum) {
          stageNum = dependencyStageNum + 1;
        }
      }
    }
    if (reconciliationStages.length <= stageNum) {
      reconciliationStages.add([]);
      // `stageNum` can't grow by more than 1 each time `evaluateScc` is called,
      // so adding one stage is sufficient to make sure the list is now long
      // enough.
      assert(stageNum < reconciliationStages.length);
    }
    List<_Node<ParamInfo>> stage = reconciliationStages[stageNum];
    for (_Node<ParamInfo> node in nodes) {
      node.stageNum = stageNum;
      if (node.deferredParamIndex != null) {
        stage.add(node);
      }
    }
  }
}

/// Node type representing a single parameter for purposes of walking the graph
/// of type inference dependencies among parameters.
class _Node<ParamInfo> extends Node<_Node<ParamInfo>> {
  /// The [ParamInfo] represented by this node.
  final ParamInfo param;

  /// If not `null`, the index of the reconciliation stage to which this
  /// parameter has been assigned.
  int? stageNum;

  /// The nodes for the parameters depended on by this parameter.
  final List<_Node<ParamInfo>> dependencies = [];

  /// If this node represents a deferred parameter, the index of it in the list
  /// of deferred parameters used to construct [FunctionLiteralDependencies].
  final int? deferredParamIndex;

  _Node(this.param, {required this.deferredParamIndex});

  @override
  bool get isEvaluated => stageNum != null;

  @override
  List<_Node<ParamInfo>> computeDependencies() => dependencies;
}
