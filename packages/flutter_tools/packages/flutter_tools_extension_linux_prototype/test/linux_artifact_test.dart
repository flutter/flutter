// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/artifact.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxArtifactService', () {
    test('returns default Linux x64 artifact when host and target match', () async {
      final service = LinuxArtifactService();
      final List<ArtifactDependency> deps = await service.downloadArtifacts(
        hostPlatform: HostPlatform.linux_x64,
        targetPlatform: 'linux-x64',
      );
      expect(deps, hasLength(1));
      expect(deps.first.name, 'linux-x64-custom-artifact');
      expect(deps.first.hostPlatform, HostPlatform.linux_x64);
      expect(deps.first.targetPlatform, 'linux-x64');
    });

    test('matches targetPlatform prefix such as linux', () async {
      final service = LinuxArtifactService();
      final List<ArtifactDependency> deps = await service.downloadArtifacts(
        hostPlatform: HostPlatform.linux_x64,
        targetPlatform: 'linux',
      );
      expect(deps, hasLength(1));
      expect(deps.first.name, 'linux-x64-custom-artifact');
    });

    test('filters out artifacts on non-matching hostPlatform or targetPlatform', () async {
      final service = LinuxArtifactService();
      expect(await service.downloadArtifacts(hostPlatform: HostPlatform.darwin_arm64), isEmpty);
      expect(
        await service.downloadArtifacts(
          hostPlatform: HostPlatform.linux_x64,
          targetPlatform: 'android-arm64',
        ),
        isEmpty,
      );
    });
  });
}
