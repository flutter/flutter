// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux implementation of [ArtifactService].
final class LinuxArtifactService extends ArtifactService {
  LinuxArtifactService({
    List<ArtifactDependency>? artifacts,
    String? engineRevision,
    String? storageBaseUrl,
  }) : _artifacts =
           artifacts ??
           _buildDefaultArtifacts(
             engineRevision: engineRevision ?? defaultPrototypeEngineRevision,
             storageBaseUrl:
                 storageBaseUrl ??
                 Platform.environment[storageBaseUrlEnvKey] ??
                 defaultStorageBaseUrl,
           );

  /// Environment variable used to override the base URL for artifact downloads.
  static const String storageBaseUrlEnvKey = 'FLUTTER_STORAGE_BASE_URL';

  /// Default base URL for Flutter artifact storage when [storageBaseUrlEnvKey] is unset.
  static const String defaultStorageBaseUrl = 'https://storage.googleapis.com';

  /// Placeholder engine revision used by the prototype when no explicit
  /// revision or artifact manifest is configured.
  // TODO(bkonyi): resolve the target engine revision and artifact checksums
  // from an extension artifact manifest rather than a static placeholder.
  static const String defaultPrototypeEngineRevision = '380c178f24dd8b8bf70c8b87bf1a2de891cf181f';

  /// Name of the default Linux x64 prototype artifact.
  static const String defaultArtifactName = 'linux-x64-custom-artifact';

  /// Placeholder SHA-256 digest (empty payload) used for hermetic prototype testing.
  static const String defaultArtifactSha256 =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  /// Default target platform identifier for the Linux x64 prototype artifact.
  static const String defaultTargetPlatform = 'linux-x64';

  /// Default artifacts provided by the Linux prototype extension.
  static final List<ArtifactDependency> defaultArtifacts = _buildDefaultArtifacts(
    engineRevision: defaultPrototypeEngineRevision,
    storageBaseUrl: defaultStorageBaseUrl,
  );

  static List<ArtifactDependency> _buildDefaultArtifacts({
    required String engineRevision,
    required String storageBaseUrl,
  }) {
    return <ArtifactDependency>[
      ArtifactDependency(
        name: defaultArtifactName,
        sha256: defaultArtifactSha256,
        url: Uri.parse(
          '$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/$defaultTargetPlatform/artifacts.zip',
        ),
        hostPlatform: HostPlatform.linux_x64,
        targetPlatform: defaultTargetPlatform,
      ),
    ];
  }

  final List<ArtifactDependency> _artifacts;

  @override
  Future<List<ArtifactDependency>> downloadArtifacts({
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  }) async {
    return _artifacts.where((ArtifactDependency artifact) {
      if (artifact.hostPlatform != null && artifact.hostPlatform != hostPlatform) {
        return false;
      }
      if (targetPlatforms != null && artifact.targetPlatform != null) {
        final String depTarget = artifact.targetPlatform!;
        final bool matched =
            targetPlatforms.contains(depTarget) ||
            targetPlatforms.any((String p) => depTarget.startsWith('$p-'));
        if (!matched) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
