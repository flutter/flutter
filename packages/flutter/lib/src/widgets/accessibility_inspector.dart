// Copyright 2026 The Flutter Authors. All rights reserved.
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
      name: 'accessibility.${AccessibilityServiceExtensions.getSemanticsTree.name}',
      callback: _getSemanticsTree,
    );
  }

  /// Reset the helper state (primarily used in tests).
  @visibleForTesting
  void resetAllState() {
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
  }

  Future<Map<String, dynamic>> _getSemanticsTree(Map<String, String> parameters) async {
    _semanticsHandle ??= SemanticsBinding.instance.ensureSemantics();

    PipelineOwner? findPipelineOwner() {
      for (final RenderView renderView in RendererBinding.instance.renderViews) {
        if (renderView.owner?.semanticsOwner != null) {
          return renderView.owner;
        }
      }
      final PipelineOwner rootOwner = RendererBinding.instance.rootPipelineOwner;
      if (rootOwner.semanticsOwner != null) {
        return rootOwner;
      }
      final PipelineOwner deprecatedOwner = RendererBinding.instance.pipelineOwner;
      if (deprecatedOwner.semanticsOwner != null) {
        return deprecatedOwner;
      }
      return null;
    }

    final PipelineOwner? pipelineOwner = findPipelineOwner();
    if (pipelineOwner == null) {
      return <String, dynamic>{
        'error': 'No PipelineOwner with SemanticsOwner found',
        'needsFrame': true,
      };
    }

    final SemanticsOwner semanticsOwner = pipelineOwner.semanticsOwner!;
    final SemanticsNode? root = semanticsOwner.rootSemanticsNode;
    if (root == null) {
      RendererBinding.instance.ensureVisualUpdate();
      return <String, dynamic>{'error': 'rootSemanticsNode is null', 'needsFrame': true};
    }

    Map<String, dynamic> toJsonMap(SemanticsNode node) {
      final SemanticsData data = node.getSemanticsData();
      final flags = <String>[];
      for (final SemanticsFlag flag in SemanticsFlag.values) {
        if (data.hasFlag(flag)) {
          flags.add(flag.name);
        }
      }
      final actions = <String>[];
      for (final SemanticsAction action in SemanticsAction.values) {
        if (data.hasAction(action)) {
          actions.add(action.name);
        }
      }
      final children = <Map<String, dynamic>>[];
      node.visitChildren((SemanticsNode child) {
        children.add(toJsonMap(child));
        return true;
      });
      return <String, dynamic>{
        'id': node.id.toString(),
        'label': data.label,
        'value': data.value,
        'hint': data.hint,
        'tooltip': data.tooltip,
        'increasedValue': data.increasedValue,
        'decreasedValue': data.decreasedValue,
        'flags': flags,
        'actions': actions,
        'rect': <String, double>{
          'left': node.rect.left,
          'top': node.rect.top,
          'width': node.rect.width,
          'height': node.rect.height,
        },
        if (node.transform != null) 'transform': node.transform!.storage.toList(),
        'children': children,
      };
    }

    return toJsonMap(root);
  }
}
