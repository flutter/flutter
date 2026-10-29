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
  /// serialized [SemanticsNode] entries (from [SemanticsNode.toJson]).
  static const String data = 'data';

  /// Top-level response map key containing an error message if the semantics
  /// tree could not be retrieved.
  static const String error = 'error';

  /// Top-level response map key containing the list of accessibility issue maps
  /// detected in the application.
  static const String issues = 'issues';

  /// Issue map key containing the ID of the [SemanticsNode] associated with the
  /// issue.
  static const String nodeId = 'nodeId';

  /// Issue map key containing the [AccessibilityEvaluationType] `.name` of the
  /// violated accessibility rule.
  static const String rule = 'rule';

  /// Issue map key containing the human-readable [Violation.reason] describing
  /// why the rule was violated.
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
      name: AccessibilityServiceExtensions.getIssuesAndSemanticsTree.extensionName,
      callback: _getIssuesAndSemanticsTree,
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

  (SemanticsOwner, SemanticsNode)? _getSemanticsOwnerAndRoot(Map<String, Object?> errorMap) {
    if (!SemanticsBinding.instance.semanticsEnabled) {
      errorMap[AccessibilityInspectorKeys.error] = 'Semantics not enabled.';
      return null;
    }
    final RenderView? renderView = _findRenderView();
    final PipelineOwner? pipelineOwner = renderView?.owner;
    final SemanticsOwner? semanticsOwner = pipelineOwner?.semanticsOwner;
    if (renderView == null || semanticsOwner == null) {
      errorMap[AccessibilityInspectorKeys.error] = 'No PipelineOwner with SemanticsOwner found';
      return null;
    }
    final SemanticsNode? root = semanticsOwner.rootSemanticsNode;
    if (root == null) {
      RendererBinding.instance.ensureVisualUpdate();
      errorMap[AccessibilityInspectorKeys.error] = 'rootSemanticsNode is null, needs a frame.';
      return null;
    }
    return (semanticsOwner, root);
  }

  Map<String, Object?> _buildSemanticsNodes(SemanticsNode root) {
    final nodes = <String, Object?>{};
    final visited = <int>{};
    final queue = <SemanticsNode>[root];
    while (queue.isNotEmpty) {
      final SemanticsNode node = queue.removeLast();
      if (!visited.add(node.id)) {
        continue;
      }

      nodes[node.id.toString()] = node.toJson();

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
    return nodes;
  }

  /// Returns the semantics tree hierarchy of the application.
  Future<Map<String, Object?>> _getSemanticsTree(Map<String, String> parameters) async {
    final errorMap = <String, Object?>{};
    final (SemanticsOwner, SemanticsNode)? result = _getSemanticsOwnerAndRoot(errorMap);
    if (result == null) {
      return errorMap;
    }
    final (SemanticsOwner _, SemanticsNode root) = result;

    return <String, Object?>{AccessibilityInspectorKeys.data: _buildSemanticsNodes(root)};
  }

  /// Evaluates accessibility rules and returns detected issues along with the
  /// semantics tree hierarchy from the same frame.
  Future<Map<String, Object?>> _getIssuesAndSemanticsTree(Map<String, String> parameters) async {
    final errorMap = <String, Object?>{};
    final (SemanticsOwner, SemanticsNode)? ownerAndRoot = _getSemanticsOwnerAndRoot(errorMap);
    if (ownerAndRoot == null) {
      return errorMap;
    }
    final (SemanticsOwner semanticsOwner, SemanticsNode root) = ownerAndRoot;

    // The violations are displayed in Devtool.
    // TODO(hannah-hyj): If we add a "target platforms" option on the devtool side,
    // we can display violations for both iOS/android standards
    // regardless of the testing device platform.
    final Size minSize = switch (defaultTargetPlatform) {
      TargetPlatform.android => const Size(48.0, 48.0),
      TargetPlatform.iOS || TargetPlatform.macOS => const Size(44.0, 44.0),
      _ => const Size(48.0, 48.0),
    };

    final issues = <Map<String, Object?>>[];

    final evaluations = <AccessibilityEvaluation>[
      MinimumTapTargetEvaluation(size: minSize),
      const LabeledTapTargetEvaluation(),
      const UnlabeledLeafNodeEvaluation(),
    ];

    for (final evaluation in evaluations) {
      final EvaluationResult result = await evaluation.evaluate(WidgetsBinding.instance);
      for (final Violation violation in result.violations) {
        if (violation.node.owner == semanticsOwner) {
          issues.add(<String, Object?>{
            AccessibilityInspectorKeys.nodeId: violation.node.id,
            AccessibilityInspectorKeys.rule: evaluation.type.name,
            AccessibilityInspectorKeys.description: violation.reason,
          });
        }
      }
    }

    return <String, Object?>{
      AccessibilityInspectorKeys.data: _buildSemanticsNodes(root),
      AccessibilityInspectorKeys.issues: issues,
    };
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
