// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

import 'protocol_base/service.dart';

/// Extension service interface for custom builds.
abstract base class BuildService extends ToolExtensionService {
  /// Service namespace identifier for custom builds.
  static const String serviceNamespace = 'build';

  /// RPC method identifier to query contributed build targets.
  static const String getBuildTargetsMethod = 'build.getBuildTargets';

  /// RPC method identifier to trigger a custom build.
  static const String buildMethod = 'build.build';

  /// RPC parameter key for the build mode.
  static const String buildModeParam = 'buildMode';

  /// RPC parameter key for the main entrypoint path.
  static const String mainPathParam = 'mainPath';

  /// RPC parameter key for the resolved platform plugins list.
  static const String pluginsParam = 'plugins';

  /// RPC parameter key for the project root path.
  static const String projectRootParam = 'projectRoot';

  /// RPC parameter key for the target name.
  static const String targetNameParam = 'targetName';

  static const String _getBuildTargetsRpcMethod = 'getBuildTargets';
  static const String _buildRpcMethod = 'build';

  @override
  String get namespace => serviceNamespace;

  /// Returns the custom build targets contributed by this extension.
  Future<List<ExtensionBuildTarget>> getBuildTargets();

  /// Triggers a custom build for the given [targetName].
  ///
  /// When the target specifies [ExtensionBuildTarget.pluginPlatformKey], the
  /// host tool resolves plugins for that platform and passes them in [plugins].
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
    List<ExtensionPlugin> plugins = const <ExtensionPlugin>[],
  });

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getBuildTargetsRpcMethod: _getBuildTargetsRpc,
      _buildRpcMethod: _buildRpc,
    };
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getBuildTargetsRpc(Map<String, Object?> _) async {
    final List<ExtensionBuildTarget> targets = await getBuildTargets();
    return targets.map((ExtensionBuildTarget target) => target.toMap()).toList();
  }

  Future<Map<String, Object?>> _buildRpc(Map<String, Object?> params) async {
    final String targetName;
    final String projectRoot;
    final String mainPath;
    final String buildMode;
    final List<ExtensionPlugin> plugins;
    try {
      targetName = params.requiredField<String>(targetNameParam);
      projectRoot = params.requiredField<String>(projectRootParam);
      mainPath = params.requiredField<String>(mainPathParam);
      buildMode = params.requiredField<String>(buildModeParam);
      final List<Object?>? rawPlugins = params.nullableField<List<Object?>>(pluginsParam);
      plugins = rawPlugins != null
          ? ExtensionPlugin.listFromJson(rawPlugins)
          : const <ExtensionPlugin>[];
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }

    final Uri? projectRootUri = Uri.tryParse(projectRoot);
    if (projectRootUri == null || !projectRootUri.hasAbsolutePath) {
      throw RpcException.invalidParams('Missing or invalid "$projectRootParam" parameter.');
    }

    final BuildMode mode;
    try {
      mode = BuildMode.fromCliName(buildMode);
    } on ArgumentError {
      throw RpcException.invalidParams('Missing or invalid "$buildModeParam" parameter.');
    }

    final ExtensionBuildResult result = await build(
      buildMode: mode,
      mainPath: mainPath,
      plugins: plugins,
      projectRoot: projectRootUri,
      targetName: targetName,
    );
    return result.toMap();
  }
}
