// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

import 'protocol_base/service.dart';

/// The service responsible for providing custom artifact dependencies to
/// `flutter precache` and build/run commands.
abstract base class ArtifactService extends ToolExtensionService {
  /// Service namespace identifier for artifacts.
  static const String serviceNamespace = 'artifact';

  static const String _downloadArtifactsRpcMethod = 'downloadArtifacts';

  /// RPC method identifier to query contributed artifact dependencies.
  static const String downloadArtifactsMethod = '$serviceNamespace.$_downloadArtifactsRpcMethod';

  /// RPC parameter key for the Flutter engine version (revision).
  static const String engineVersionParam = 'engineVersion';

  /// RPC parameter key for the host platform.
  static const String hostPlatformParam = 'hostPlatform';

  /// RPC parameter key for the optional target platforms filter.
  static const String targetPlatformsParam = 'targetPlatforms';

  @override
  String get namespace => serviceNamespace;

  /// Returns the list of [ArtifactDependency] objects required by this
  /// extension for the given [engineVersion], [hostPlatform], and optional
  /// [targetPlatforms].
  ///
  /// [targetPlatforms] contains [String] identifiers rather than `TargetPlatform`
  /// values so extensions can match custom out-of-tree embedder identifiers
  /// (e.g. `'tizen-arm64'`) as well as built-in platform names or OS prefixes
  /// (e.g. `'linux'`). When `null`, artifacts for all target platforms supported
  /// on [hostPlatform] should be returned.
  Future<List<ArtifactDependency>> downloadArtifacts({
    required String engineVersion,
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  });

  /// Initializes the service by registering RPC methods with the extension provider.
  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{_downloadArtifactsRpcMethod: _downloadArtifactsRpc};
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _downloadArtifactsRpc(Map<String, Object?> params) async {
    final String engineVersion;
    final HostPlatform hostPlatform;
    final Set<String>? targetPlatforms;
    try {
      engineVersion = params.requiredField<String>(engineVersionParam);
      if (engineVersion.trim().isEmpty) {
        throw const FormatException('Missing or empty engineVersion');
      }
      final String hp = params.requiredField<String>(hostPlatformParam);
      hostPlatform = HostPlatform.fromName(hp);
      targetPlatforms = params[targetPlatformsParam] != null
          ? params.stringIterable(targetPlatformsParam).toSet()
          : null;
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final List<ArtifactDependency> deps = await downloadArtifacts(
      engineVersion: engineVersion,
      hostPlatform: hostPlatform,
      targetPlatforms: targetPlatforms,
    );
    return deps.map((ArtifactDependency d) => d.toMap()).toList();
  }
}
