// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../flutter_tools_core/build.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../globals.dart' as globals;
import 'extension_discovery.dart';

/// Retrieve the [ExtensionBuildTargetManager] from the context.
ExtensionBuildTargetManager? get extensionBuildTargetManager =>
    context.get<ExtensionBuildTargetManager>();

/// Manages querying build targets and delegating builds to extension isolates.
class ExtensionBuildTargetManager {
  /// Create a new instance of [ExtensionBuildTargetManager].
  ExtensionBuildTargetManager({
    required ToolExtensionManager extensionManager,
    Logger? logger,
    Platform? platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         extensionManager: extensionManager,
         logger: logger ?? globals.logger,
         platform: platform ?? globals.platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

  List<core.Target>? _cachedTargets;

  /// Retrieve the cached targets synchronously.
  List<core.Target> get cachedTargets => _cachedTargets ?? const <core.Target>[];

  Future<List<ToolExtension>> _getActiveBuildExtensions({required bool throwOnFailure}) async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      if (throwOnFailure) {
        throwToolExit('Tool extension prototype is not enabled.');
      }
      return const <ToolExtension>[];
    }
    return _discoveryHelper.getExtensionsSupporting(
      core.BuildService.serviceNamespace,
      throwOnFailure: throwOnFailure,
    );
  }

  /// Retrieve build targets by routing build.getTargets to active tool extensions.
  Future<List<core.Target>> getTargets() async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return const <core.Target>[];
    }
    if (_cachedTargets != null) {
      return _cachedTargets!;
    }

    final List<core.Target> targets = await _discoveryHelper.getListFromExtensions<core.Target>(
      core.BuildService.serviceNamespace,
      core.BuildService.getTargetsMethod,
      core.ExtensionBuildTarget.listFromJson,
    );

    _cachedTargets = targets;
    return targets;
  }

  /// Request build execution over extension protocol RPC.
  Future<core.BuildResult> buildTarget(String targetName, core.BuildEnvironment environment) async {
    for (final ToolExtension extension in await _getActiveBuildExtensions(throwOnFailure: true)) {
      try {
        final Object? result = await extension
            .callMethod(
              core.BuildService.buildMethod,
              params: <String, Object?>{
                'targetName': targetName,
                'environment': environment.toMap(),
              },
            )
            .timeout(const Duration(seconds: 60));
        if (result case final Map<Object?, Object?> rawResultMap) {
          final buildResult = core.BuildResult.fromJson(rawResultMap.cast<String, Object?>());
          if (buildResult.success) {
            return buildResult;
          }
          throwToolExit('Build compilation failed: ${buildResult.errorMessage ?? 'Unknown error'}');
        }
      } on Object catch (e) {
        if (e is ToolExit) {
          rethrow;
        }
        throwToolExit('Build compilation failed: $e');
      }
    }

    throwToolExit('No extension service handled build for target: $targetName');
  }
}
