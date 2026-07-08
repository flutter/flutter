// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Build target manager for tool extensions.
///
/// This library manages discovery of custom build targets from active tool
/// extensions and handles routing build requests to them.
library experimental.build_targets;

import 'dart:async';

import '../../flutter_tools_core.dart' as core;
import '../base/common.dart';
import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../generic_extension_protocol/manager.dart';
import 'extension_discovery.dart';

/// Retrieve the [ExtensionBuildTargetManager] from the context.
ExtensionBuildTargetManager? get extensionBuildTargetManager =>
    context.get<ExtensionBuildTargetManager>();

/// Manages querying build targets and delegating builds to extension isolates.
///
/// This manager interacts with active [ToolExtension]s to discover custom
/// build targets and delegate the compilation process to them over the
/// extension protocol RPC.
base class ExtensionBuildTargetManager extends core.BuildService {
  ExtensionBuildTargetManager({
    required ToolExtensionManager extensionManager,
    required Logger logger,
    required Platform platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger,
         extensionManager: extensionManager,
         platform: platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

  static const String _serviceNamespace = core.BuildService.serviceNamespace;
  static const String _getTargetsMethod = core.BuildService.getTargetsMethod;
  static const String _buildMethod = core.BuildService.buildMethod;

  List<core.Target>? _cachedTargets;

  /// Retrieve the cached targets synchronously.
  ///
  /// Returns the list of build targets cached from the last [getTargets] call.
  List<core.Target> get cachedTargets => _cachedTargets ?? const <core.Target>[];

  /// Retrieves active extensions that support the build service namespace.
  ///
  /// If [throwOnFailure] is true and the prototype flag is disabled, it will
  /// throw a [ToolExit].
  // TODO(bkonyi): Dynamically load user-installed extensions rather than unconditionally starting the prototype linux extension.
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

  /// Decodes the raw RPC result into a list of [core.Target]s.
  static List<core.Target> _decodeTargets(Object? rpcResult) {
    final targets = <core.Target>[];
    if (rpcResult case final List<Object?> resultList) {
      for (final item in resultList) {
        if (item case final Map<dynamic, dynamic> itemMap) {
          targets.add(core.ExtensionBuildTarget.fromJson(itemMap.cast<String, Object?>()));
        }
      }
    }
    return targets;
  }

  /// Retrieve build targets by routing `build.getTargets` to active tool extensions.
  ///
  /// Results are cached after the first successful call.
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
  ///
  /// Delegates the compilation of [targetName] to the active tool extension,
  /// passing the [environment] configuration.
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
        if (result case final Map<dynamic, dynamic> rawResultMap) {
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

  @override
  List<core.Target> get targets => cachedTargets;

  @override
  Map<String, Object?> get nativeAssetsConfig => const <String, Object?>{};

  @override
  List<core.ArtifactDependency> get artifactDependencies => const <core.ArtifactDependency>[];
}
