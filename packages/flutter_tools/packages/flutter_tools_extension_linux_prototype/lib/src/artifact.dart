// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux implementation of [ArtifactService].
final class LinuxArtifactService extends ArtifactService {
  LinuxArtifactService({this._artifacts = const <ArtifactDependency>[]});

  final List<ArtifactDependency> _artifacts;

  @override
  Future<List<ArtifactDependency>> downloadArtifacts({
    required String engineVersion,
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  }) async {
    return <ArtifactDependency>[
      for (final ArtifactDependency artifact in _artifacts)
        if (artifact.matchesPlatforms(
          currentHostPlatform: hostPlatform,
          targetPlatforms: targetPlatforms,
        ))
          artifact,
    ];
  }
}
