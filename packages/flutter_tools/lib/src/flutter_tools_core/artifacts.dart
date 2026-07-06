// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core artifacts service and dependency definitions for tool extensions.
///
/// This library defines the interface for downloading engine artifacts
/// required by custom target platforms.
library flutter_tools_core.artifacts;

import '../../generic_extension_protocol.dart';

/// The service responsible for acquiring the necessary files to develop
/// and deploy Flutter applications for a custom target platform.
abstract base class ArtifactService extends ToolExtensionService {
  @override
  String get namespace => 'artifacts';

  /// The set of artifacts provided by the extension.
  Set<ArtifactDependency> get artifacts;

  /// Downloads missing artifacts (e.g., custom engine embeddings or
  /// gen_snapshot) for the target platform.
  Future<void> downloadArtifacts(
    Set<ArtifactDependency> artifacts, {
    required String buildMode,
    required String hostPlatform,
    required String targetPlatform,
  });

  /// Initializes the service by registering RPC methods with the extension provider.
  ///
  /// Registers `getArtifacts` to list dependencies and `download` to trigger downloads.
  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{'getArtifacts': _getArtifactsRpc, 'download': _downloadRpc};
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getArtifactsRpc(Map<String, Object?> params) async {
    return artifacts.map((ArtifactDependency dependency) => dependency.toMap()).toList();
  }

  Future<Map<String, Object?>> _downloadRpc(Map<String, Object?> params) async {
    if (params case {
      'artifacts': final List<Object?> artifactsJsonObj,
      'buildMode': final String buildMode,
      'hostPlatform': final String hostPlatform,
      'targetPlatform': final String targetPlatform,
    }) {
      final Set<ArtifactDependency> deps;
      try {
        deps = ArtifactDependency.listFromJson(artifactsJsonObj).toSet();
      } on Object catch (e, stackTrace) {
        return <String, Object?>{
          'success': false,
          'errorMessage': 'Failed to deserialize artifact dependencies: $e',
          'stackTrace': stackTrace.toString(),
        };
      }

      try {
        await downloadArtifacts(
          deps,
          buildMode: buildMode,
          hostPlatform: hostPlatform,
          targetPlatform: targetPlatform,
        );
        return <String, Object?>{'success': true};
      } on Object catch (e, stackTrace) {
        return <String, Object?>{
          'success': false,
          'errorMessage': e.toString(),
          'stackTrace': stackTrace.toString(),
        };
      }
    }
    return <String, Object?>{
      'success': false,
      'errorMessage':
          'Missing or invalid parameters: "artifacts" (List), "buildMode" (String), "hostPlatform" (String), "targetPlatform" (String).',
    };
  }
}

/// Declares a specific engine artifact required before building can begin.
class ArtifactDependency {
  const ArtifactDependency({
    required this.hostPlatform,
    required this.name,
    required this.sha256Checksums,
    required this.targetArchitecture,
    required this.targetPlatform,
  });

  /// Creates an [ArtifactDependency] from a JSON map.
  factory ArtifactDependency.fromJson(Map<String, Object?> json) {
    return ArtifactDependency(
      hostPlatform: json['hostPlatform']! as String,
      name: json['name']! as String,
      sha256Checksums: (json['sha256Checksums']! as Map<Object?, Object?>).cast<String, String>(),
      targetArchitecture: json['targetArchitecture']! as String,
      targetPlatform: json['targetPlatform']! as String,
    );
  }

  /// The name of the required artifact (e.g., 'gen_snapshot').
  final String name;

  /// The target host platform architecture for the compiler (e.g., 'darwin-x64').
  final String hostPlatform;

  /// The target platform running the embedding (e.g., 'webos', 'tizen').
  final String targetPlatform;

  /// The target architecture for the device (e.g., 'arm64', 'arm').
  final String targetArchitecture;

  /// A mapping of host/target keys to SHA-256 hashes for binary validation.
  final Map<String, String> sha256Checksums;

  /// Converts this dependency to a JSON-compatible map.
  Map<String, Object?> toMap() => <String, Object?>{
    'hostPlatform': hostPlatform,
    'name': name,
    'sha256Checksums': sha256Checksums,
    'targetArchitecture': targetArchitecture,
    'targetPlatform': targetPlatform,
  };

  /// Parses a list of [ArtifactDependency] from an RPC result.
  static List<ArtifactDependency> listFromJson(Object? rpcResult) => <ArtifactDependency>[
    if (rpcResult case final List<Object?> l)
      for (final item in l)
        if (item case final Map<Object?, Object?> m)
          ArtifactDependency.fromJson(m.cast<String, Object?>()),
  ];
}
