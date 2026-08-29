// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'service_extensions.dart';

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
      return <String, Object?>{'error': 'Semantics not enabled.'};
    }
    final PipelineOwner? pipelineOwner = _findPipelineOwner();
    final SemanticsOwner? semanticsOwner = pipelineOwner?.semanticsOwner;
    if (semanticsOwner == null) {
      return <String, Object?>{'error': 'No PipelineOwner with SemanticsOwner found'};
    }
    final SemanticsNode? root = semanticsOwner.rootSemanticsNode;
    if (root == null) {
      RendererBinding.instance.ensureVisualUpdate();
      return <String, Object?>{'error': 'rootSemanticsNode is null', 'needsFrame': true};
    }

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

    return <String, Object?>{'data': nodes};
  }

  // TODO(hannahjin): This returns the first SemanticsOwner of any RenderView.
  // This getSemanticsTree feature is used in DevTools, which currently only supports
  // single-view inspection. Add multi-view support when DevTools needs it.
  PipelineOwner? _findPipelineOwner() {
    for (final RenderView renderView in RendererBinding.instance.renderViews) {
      if (renderView.owner?.semanticsOwner != null) {
        return renderView.owner;
      }
    }
    final PipelineOwner deprecatedOwner = RendererBinding.instance.pipelineOwner;
    if (deprecatedOwner.semanticsOwner != null) {
      return deprecatedOwner;
    }
    return null;
  }
}
