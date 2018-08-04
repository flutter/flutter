// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart';

import 'widget_tester.dart';

/// The result of evaluating a semantics node by a [SemanticsPolicy].
class Evaluation {
  /// The policy did not apply to the node and it conforms trivially.
  static const Evaluation trivial = Evaluation.conforms();

  /// The node conforms the policy.
  const Evaluation.conforms([this.justification]) : _conforms = true;

  /// The node does not conform to the policy.
  const Evaluation.violation([this.justification]) : _conforms = false;

  /// An optional justification for the evaluation.
  final String justification;
  final bool _conforms;

  /// Whether the node did conform to a policy.
  bool get doesConform => _conforms;

  /// Whether the node did not conform to a policy.
  bool get doesNotConform => !_conforms;
}

/// A semantics policy describes a restriction on the set of valid semantic
/// trees.
///
/// A given semantics tree conforms to a policy if for every node, the result of
/// [SemanticsPolicy.evaluate] is [Evaluation.conforms].
///
/// Many policies only effect a subset of all semantic nodes. In these cases,
/// [Evaluation.trivial] can be used to indicate conformance.
abstract class SemanticsPolicy {
  /// A const constructor allows subclasses to be const.
  const SemanticsPolicy();

  /// Method which is called once before the policy is enforced on a semantics
  /// tree.
  ///
  /// Use this method to reset any internal state or initialize fields needed in
  /// evaluate.
  @mustCallSuper
  void beforeEnforce() {}

  /// Whether the semantics `data` associated with a given node conforms to the
  /// rule.
  ///
  /// For the root node, null is provided as a parent.
  ///
  /// If there are no child nodes, an empty Iterable is provided instead.
  Evaluation evaluate(SemanticsData data, Iterable<SemanticsData> children, SemanticsData parent);

  /// An optional evaluation result which is called once after the entire
  /// semantics tree has been processed.
  ///
  /// This can be used for policies which only apply to the entire tree, or
  /// regard the interactions between nodes.
  ///
  /// By default returns [Evaluation.trivial].
  @mustCallSuper
  Evaluation evaluateAll() {
    return Evaluation.trivial;
  }
}

/// The results of evaluating a set of semantics policies with a
/// [SemanticsPolicyTester].
class EvaluationResults {
  EvaluationResults._(this._nodeResults, this._treeResults, this._doesConform);

  final Map<int, List<Evaluation>> _nodeResults;
  final List<Evaluation> _treeResults;

  /// Whether all nodes conformed to the enforced policies.
  bool get doesConform => _doesConform;
  bool _doesConform;

  /// Compute a list of all violations of the enforced policies.
  List<Evaluation> violations() {
    return _nodeResults
      .values
      .expand((List<Evaluation> evaluations) => evaluations)
      .where((Evaluation evaluation) => evaluation.doesNotConform)
      .followedBy(_treeResults.where((Evaluation evaluation) => evaluation.doesNotConform))
      .toList();
  }
}

class SemanticsPolicyTester {
  /// Create a new semantics policy tester using a widget tester.
  SemanticsPolicyTester(this.tester) {
    _semanticsHandle = tester.ensureSemantics();
  }

  final WidgetTester tester;
  final Set<SemanticsPolicy> _policies = new Set<SemanticsPolicy>();
  SemanticsHandle _semanticsHandle;

  Iterable<SemanticsPolicy> get activePolicies => _policies;

  /// Enacts a new semantics policy.
  ///
  /// This takes effect the next time [SemanticsPolicyTester.enforce] is called.
  void enact(SemanticsPolicy policy) {
    _policies.add(policy);
  }

  /// Revokes the provided semantics policy.
  ///
  /// This takes effect the next time [SemanticsPolicyTester.enforce] is called.
  void revoke(SemanticsPolicy policy) {
    _policies.remove(policy);
  }

  /// Evaluate the active set of policies on the semantics tree.
  EvaluationResults evaluate() {
    if (_policies.isEmpty)
      throw new StateError('Cannot enforce without any policies');
    final SemanticsNode rootNode = tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode;
    final List<SemanticsNode> nodesToVisit = <SemanticsNode>[rootNode];
    final Map<int, List<Evaluation>> results = <int, List<Evaluation>>{};
    final List<Evaluation> treeResults = <Evaluation>[];
    bool doesConform = true;
    for (SemanticsPolicy policy in _policies)
      policy.beforeEnforce();

    while (nodesToVisit.isNotEmpty) {
      final SemanticsNode current = nodesToVisit.removeLast();
      final List<SemanticsData> children = <SemanticsData>[];
      final SemanticsData currentData = current.getSemanticsData();
      final SemanticsData parentData = current.parent?.getSemanticsData();
      current.visitChildren((SemanticsNode child) {
        nodesToVisit.add(child);
        children.add(child.getSemanticsData());
        return true;
      });
      for (SemanticsPolicy policy in _policies) {
        final Evaluation result = policy.evaluate(currentData, children, parentData);
        if (result != Evaluation.trivial) {
          results.putIfAbsent(current.id, () => <Evaluation>[]);
          results[current.id].add(result);
        }
        if (result.doesNotConform)
          doesConform = false;
      }
    }
    for (SemanticsPolicy policy in _policies) {
      final Evaluation result = policy.evaluateAll();
      if (result != Evaluation.trivial) {
        treeResults.add(result);
      }
      if (result.doesNotConform)
        doesConform = false;
    }

    return new EvaluationResults._(
      results,
      treeResults,
      doesConform,
    );
  }

  void dispose() {
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
  }
}


class _MinimumTapTargetPolicy extends SemanticsPolicy {
  const _MinimumTapTargetPolicy();

  @override
  Evaluation evaluate(SemanticsData data, Iterable<SemanticsData> _, SemanticsData __) {
    if (data.hasAction(SemanticsAction.tap) || data.hasAction(SemanticsAction.longPress)) {
      if (data.rect.width < 48.0 || data.rect.height < 48.0) {
        return new Evaluation.violation('{$data.rect.size} < Size(48.0, 48.0)');
      }
      return new Evaluation.conforms('{$data.rect.size} >= Size(48.0, 48.0)');
    }
    // Nodes with no tap actions are not evaluated by this rule.
    return Evaluation.trivial;
  }
}


class _LabelledImagePolicy extends SemanticsPolicy {
  const _LabelledImagePolicy();

  @override
  Evaluation evaluate(SemanticsData data, Iterable<SemanticsData> _, SemanticsData __) {
    if (data.hasFlag(SemanticsFlag.isImage)) {
      if (data.label != null && data.label != '') {
        return const Evaluation.violation('data.label == null|"" ');
      }
      return new Evaluation.conforms('${data.label} != null|""');
    }
    // Nodes that are not images are not evaluated by this rule.
    return Evaluation.trivial;
  }
}

/// A policy which restricts all tapable semantic nodes a minimum size of
/// 48 by 48.
const SemanticsPolicy minimumTapTargetPolicy = _MinimumTapTargetPolicy();

/// A policy which requires all image nodes to have a non-trivial label.
const SemanticsPolicy labelledImagePolicy = _LabelledImagePolicy();