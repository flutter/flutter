// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux implementation of [ArtifactService].
final class LinuxArtifactService extends ArtifactService {
  /// Default artifacts provided by the Linux prototype extension.
  static final defaultArtifacts = <ArtifactDependency>[
    ArtifactDependency(
      name: 'linux-x64-custom-artifact',
      sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      url: Uri.parse(
        'https://storage.googleapis.com/flutter_infra_release/flutter/380c178f24dd8b8bf70c8b87bf1a2de891cf181f/linux-x64/artifacts.zip',
      ),
      hostPlatform: HostPlatform.linux_x64,
      targetPlatform: 'linux-x64',
    ),
  ];

  @override
  Future<List<ArtifactDependency>> downloadArtifacts({
    required HostPlatform hostPlatform,
    String? targetPlatform,
  }) async {
    return defaultArtifacts.where((ArtifactDependency artifact) {
      if (artifact.hostPlatform != null && artifact.hostPlatform != hostPlatform) {
        return false;
      }
      if (targetPlatform != null &&
          artifact.targetPlatform != null &&
          artifact.targetPlatform != targetPlatform &&
          !artifact.targetPlatform!.startsWith('$targetPlatform-')) {
        return false;
      }
      return true;
    }).toList();
  }
}
