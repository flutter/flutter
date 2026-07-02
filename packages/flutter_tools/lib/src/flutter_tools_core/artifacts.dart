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
}
