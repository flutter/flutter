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
         logger: logger ?? globals.logger,
         extensionManager: extensionManager,
         platform: platform ?? globals.platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

  static const String _serviceNamespace = 'build';
  static const String _getTargetsMethod = 'build.getTargets';
  static const String _buildMethod = 'build.build';

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
      _serviceNamespace,
      throwOnFailure: throwOnFailure,
    );
  }

  static List<core.Target> _decodeTargets(Object? rpcResult) {
    final targets = <core.Target>[];
    if (rpcResult case final List<Object?> resultList) {
      for (final item in resultList) {
        if (item case final Map<Object?, Object?> itemMap) {
          targets.add(core.ExtensionBuildTarget.fromJson(itemMap.cast<String, Object?>()));
        }
      }
    }
    return targets;
  }

  /// Retrieve build targets by routing build.getTargets to active tool extensions.
  Future<List<core.Target>> getTargets() async {
    if (_cachedTargets != null) {
      return _cachedTargets!;
    }

    final List<core.Target> targets = await _discoveryHelper.getListFromExtensions<core.Target>(
      _serviceNamespace,
      _getTargetsMethod,
      _decodeTargets,
    );

    _cachedTargets = targets;
    return targets;
  }

  /// Request build execution over extension protocol RPC.
  Future<Map<String, Object?>> buildTarget(
    String targetName,
    core.BuildEnvironment environment,
  ) async {
    for (final ToolExtension extension in await _getActiveBuildExtensions(throwOnFailure: true)) {
      try {
        final Object? result = await extension
            .callMethod(
              _buildMethod,
              params: <String, Object?>{
                'targetName': targetName,
                'environment': environment.toMap(),
              },
            )
            .timeout(const Duration(seconds: 60));
        if (result case final Map<Object?, Object?> rawResultMap) {
          final Map<String, Object?> resultMap = rawResultMap.cast<String, Object?>();
          if (resultMap case {'success': true}) {
            return resultMap;
          }
          final String message = switch (resultMap) {
            {'errorMessage': final String msg} => msg,
            {'message': final String msg} => msg,
            _ => 'Unknown error',
          };
          throwToolExit('Build compilation failed: $message');
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
