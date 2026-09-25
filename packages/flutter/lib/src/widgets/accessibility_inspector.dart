// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '_accessibility_evaluations.dart';
import 'binding.dart';
import 'service_extensions.dart';

/// Response map keys used by the [AccessibilityServiceExtensions.getSemanticsTree]
/// service extension in [AccessibilityInspector].
abstract final class AccessibilityInspectorKeys {
  /// Top-level response map key containing the map of semantics node IDs to
  /// serialized node entries.
  static const String data = 'data';

  /// Top-level response map key containing an error message if the semantics
  /// tree could not be retrieved.
  static const String error = 'error';

  /// Entry map key containing the JSON serialized [SemanticsNode] (from
  /// [SemanticsNode.toJson]).
  static const String node = 'node';

  /// Entry map key containing the list of accessibility issue maps detected on
  /// the node.
  static const String issues = 'issues';

  /// Issue map key containing the [AccessibilityEvaluationType] `.name` of the
  /// violated accessibility rule.
  static const String rule = 'rule';

  /// Issue map key containing the human-readable [Violation.reason] describing
  /// why the node violated the rule.
  static const String description = 'description';
}

/// Service that handles accessibility and semantics inspection.
class AccessibilityInspector {
  AccessibilityInspector._();

  /// The active [AccessibilityInspector] instance.
  static final AccessibilityInspector instance = AccessibilityInspector._();

  SemanticsHandle? _semanticsHandle;

  /// Registers accessibility-related VM service extensions.
  void initServiceExtensions(
    void Function({required String name, required ServiceExtensionCallback callback})
    registerServiceExtension,
  ) {
    registerServiceExtension(
      name: AccessibilityServiceExtensions.getSemanticsTree.extensionName,
      callback: _getSemanticsTree,
    );
    registerServiceExtension(
      name: AccessibilityServiceExtensions.enableSemantics.extensionName,
      callback: _enableSemantics,
    );
    registerServiceExtension(
      name: AccessibilityServiceExtensions.disposeSemantics.extensionName,
      callback: _disposeSemantics,
    );
  }

  /// Reset the helper state (primarily used in tests).
  @visibleForTesting
  void resetAllState() {
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
  }

  /// Enables semantics inspection on the connected application.
  ///
  /// Returns a mutable map as required by [BindingBase.registerServiceExtension],
  /// which mutates the returned map to append metadata.
  Future<Map<String, Object?>> _enableSemantics(Map<String, String> parameters) async {
    _semanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
    return <String, Object?>{};
  }

  /// Disposes accessibility semantics state.
  ///
  /// Returns a mutable map as required by [BindingBase.registerServiceExtension].
  Future<Map<String, Object?>> _disposeSemantics(Map<String, String> parameters) async {
    resetAllState();
    return <String, Object?>{};
  }

  /// Evaluates and returns the semantics tree hierarchy of the application.
  Future<Map<String, Object?>> _getSemanticsTree(Map<String, String> parameters) async {
    if (!SemanticsBinding.instance.semanticsEnabled) {
      return <String, Object?>{AccessibilityInspectorKeys.error: 'Semantics not enabled.'};
    }
    final RenderView? renderView = _findRenderView();
    final PipelineOwner? pipelineOwner = renderView?.owner;
    final SemanticsOwner? semanticsOwner = pipelineOwner?.semanticsOwner;
    if (renderView == null || semanticsOwner == null) {
      return <String, Object?>{
        AccessibilityInspectorKeys.error: 'No PipelineOwner with SemanticsOwner found',
      };
    }
    final SemanticsNode? root = semanticsOwner.rootSemanticsNode;
    if (root == null) {
      RendererBinding.instance.ensureVisualUpdate();
      return <String, Object?>{
        AccessibilityInspectorKeys.error: 'rootSemanticsNode is null, needs a frame.',
      };
    }

    // The violations are displayed in Devtool.
    // TODO(hannah-hyj): If we add a "target platforms" option on the devtool side,
    // we can display violations for both iOS/android standards
    // regardless of the testing device platform.
    final Size minSize = switch (defaultTargetPlatform) {
      TargetPlatform.android => const Size(48.0, 48.0),
      TargetPlatform.iOS || TargetPlatform.macOS => const Size(44.0, 44.0),
      _ => const Size(48.0, 48.0),
    };

    final nodeIssues = <int, List<Map<String, Object?>>>{};

    final evaluations = <AccessibilityEvaluation>[
      MinimumTapTargetEvaluation(size: minSize),
      const LabeledTapTargetEvaluation(),
      const UnlabeledLeafNodeEvaluation(),
    ];

    for (final evaluation in evaluations) {
      final EvaluationResult result = await evaluation.evaluate(WidgetsBinding.instance);
      for (final Violation violation in result.violations) {
        if (violation.node.owner == semanticsOwner) {
          nodeIssues.putIfAbsent(violation.node.id, () => <Map<String, Object?>>[]).add(
            <String, Object?>{
              AccessibilityInspectorKeys.rule: evaluation.type.name,
              AccessibilityInspectorKeys.description: violation.reason,
            },
          );
        }
      }
    }

    final nodes = <String, Object?>{};
    final visited = <int>{};
    final queue = <SemanticsNode>[root];
    while (queue.isNotEmpty) {
      final SemanticsNode node = queue.removeLast();
      if (!visited.add(node.id)) {
        continue;
      }

      nodes[node.id.toString()] = <String, Object?>{
        AccessibilityInspectorKeys.node: node.toJson(),
        AccessibilityInspectorKeys.issues: nodeIssues[node.id] ?? <Map<String, Object?>>[],
      };

      for (final SemanticsNode child in node.debugListChildrenInOrder(
        DebugSemanticsDumpOrder.traversalOrder,
      )) {
        if (!visited.contains(child.id)) {
          queue.add(child);
        }
      }
      for (final SemanticsNode child in node.debugListChildrenInOrder(
        DebugSemanticsDumpOrder.inverseHitTest,
      )) {
        if (!visited.contains(child.id)) {
          queue.add(child);
        }
      }
    }

    return <String, Object?>{AccessibilityInspectorKeys.data: nodes};
  }

  // TODO(hannah-hyj): https://github.com/flutter/devtools/issues/9991 - This returns the first RenderView with a SemanticsOwner.
  // This getSemanticsTree feature is used in DevTools, which currently only supports
  // single-view inspection. Add multi-view support when DevTools needs it.
  RenderView? _findRenderView() {
    for (final RenderView renderView in RendererBinding.instance.renderViews) {
      if (renderView.owner?.semanticsOwner != null) {
        return renderView;
      }
    }
    return null;
  }
}
