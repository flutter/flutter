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
      name: 'accessibility.${AccessibilityServiceExtensions.getSemanticsTree.name}',
      callback: _getSemanticsTree,
    );
    registerServiceExtension(
      name: 'accessibility.${AccessibilityServiceExtensions.disposeSemantics.name}',
      callback: _disposeSemantics,
    );
  }

  /// Reset the helper state (primarily used in tests).
  @visibleForTesting
  void resetAllState() {
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
  }

  Future<Map<String, dynamic>> _disposeSemantics(Map<String, String> parameters) async {
    resetAllState();
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _getSemanticsTree(Map<String, String> parameters) async {
    _semanticsHandle ??= SemanticsBinding.instance.ensureSemantics();

    final PipelineOwner? pipelineOwner = _findPipelineOwner();
    final SemanticsOwner? semanticsOwner = pipelineOwner?.semanticsOwner;
    if (semanticsOwner == null) {
      return <String, dynamic>{
        'error': 'No PipelineOwner with SemanticsOwner found',
        'needsFrame': true,
      };
    }
    final SemanticsNode? root = semanticsOwner.rootSemanticsNode;
    if (root == null) {
      RendererBinding.instance.ensureVisualUpdate();
      return <String, dynamic>{'error': 'rootSemanticsNode is null', 'needsFrame': true};
    }

    return root.toJsonMap();
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
}
