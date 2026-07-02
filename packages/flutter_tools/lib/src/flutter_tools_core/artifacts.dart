// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{'getArtifacts': _getArtifactsRpc, 'download': _downloadRpc};
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getArtifactsRpc(Map<String, Object?> params) async {
    return artifacts.map((ArtifactDependency dependency) => dependency.toMap()).toList();
  }

  Future<Map<String, Object?>> _downloadRpc(Map<String, Object?> params) async {
    final Object? artifactsJsonObj = params['artifacts'];
    final Object? buildModeObj = params['buildMode'];
    final Object? hostPlatformObj = params['hostPlatform'];
    final Object? targetPlatformObj = params['targetPlatform'];

    if (artifactsJsonObj is! List<Object?> ||
        buildModeObj is! String ||
        hostPlatformObj is! String ||
        targetPlatformObj is! String) {
      return <String, Object?>{
        'success': false,
        'errorMessage':
            'Missing or invalid parameters: "artifacts" (List), "buildMode" (String), "hostPlatform" (String), "targetPlatform" (String).',
      };
    }

    final Set<ArtifactDependency> deps;
    try {
      deps = artifactsJsonObj.map((Object? item) {
        if (item is! Map<Object?, Object?>) {
          throw FormatException('Invalid artifact item: $item');
        }
        return ArtifactDependency.fromJson(item.cast<String, Object?>());
      }).toSet();
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
        buildMode: buildModeObj,
        hostPlatform: hostPlatformObj,
        targetPlatform: targetPlatformObj,
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
}

/// Declares a specific engine artifact required before building can begin.
class ArtifactDependency {
  ArtifactDependency({
    required this.hostPlatform,
    required this.name,
    required this.sha256Checksums,
    required this.targetArchitecture,
    required this.targetPlatform,
  });

  /// Create an ArtifactDependency from a JSON map.
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

  /// Convert the ArtifactDependency to a JSON-compatible map.
  Map<String, Object?> toMap() => <String, Object?>{
    'hostPlatform': hostPlatform,
    'name': name,
    'sha256Checksums': sha256Checksums,
    'targetArchitecture': targetArchitecture,
    'targetPlatform': targetPlatform,
  };
}
