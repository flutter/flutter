// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
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

  /// RPC parameter key for the host platform.
  static const String hostPlatformParam = 'hostPlatform';

  /// RPC parameter key for the optional target platform filter.
  static const String targetPlatformParam = 'targetPlatform';

  @override
  String get namespace => serviceNamespace;

  /// Returns the list of [ArtifactDependency] objects required by this
  /// extension for the given [hostPlatform] and optional [targetPlatform].
  Future<List<ArtifactDependency>> downloadArtifacts({
    required HostPlatform hostPlatform,
    String? targetPlatform,
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
    if (params case {hostPlatformParam: final String hp}) {
      final HostPlatform hostPlatform;
      try {
        hostPlatform = HostPlatform.fromName(hp);
      } on ArgumentError catch (e) {
        throw RpcException.invalidParams(e.message.toString());
      }
      final String? targetPlatform = switch (params[targetPlatformParam]) {
        final String tp => tp,
        null => null,
        final Object? invalid => throw RpcException.invalidParams(
          'Invalid "$targetPlatformParam" parameter: $invalid',
        ),
      };
      final List<ArtifactDependency> deps = await downloadArtifacts(
        hostPlatform: hostPlatform,
        targetPlatform: targetPlatform,
      );
      return deps.map((ArtifactDependency d) => d.toMap()).toList();
    }
    throw RpcException.invalidParams('Missing "$hostPlatformParam" parameter.');
  }
}
