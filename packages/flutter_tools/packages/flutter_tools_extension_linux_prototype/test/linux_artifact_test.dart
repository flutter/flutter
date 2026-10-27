// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/artifact.dart';
import 'package:test/test.dart';

void main() {
  const testArtifactName = 'linux-x64-custom-artifact';
  const testEngineVersion = '0123456789abcdef0123456789abcdef01234567';
  const testSha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
  const testTargetPlatform = 'linux-x64';

  final testArtifacts = <ArtifactDependency>[
    ArtifactDependency(
      name: testArtifactName,
      sha256: testSha256,
      url: Uri.parse('https://example.com/linux-x64/artifacts.zip'),
      hostPlatform: HostPlatform.linux_x64,
      targetPlatform: testTargetPlatform,
    ),
  ];

  group('LinuxArtifactService', () {
    test('defaults to empty artifact list when none are configured', () async {
      final service = LinuxArtifactService();
      expect(
        await service.downloadArtifacts(
          engineVersion: testEngineVersion,
          hostPlatform: HostPlatform.linux_x64,
        ),
        isEmpty,
      );
    });

    test('returns configured Linux x64 artifact when host and target match', () async {
      final service = LinuxArtifactService(artifacts: testArtifacts);
      final List<ArtifactDependency> deps = await service.downloadArtifacts(
        engineVersion: testEngineVersion,
        hostPlatform: HostPlatform.linux_x64,
        targetPlatforms: const <String>{testTargetPlatform},
      );
      expect(deps, hasLength(1));
      expect(deps.first.name, testArtifactName);
      expect(deps.first.hostPlatform, HostPlatform.linux_x64);
      expect(deps.first.targetPlatform, testTargetPlatform);
    });

    test('matches targetPlatforms prefix such as linux or multiple targetPlatforms', () async {
      final service = LinuxArtifactService(artifacts: testArtifacts);
      final List<ArtifactDependency> deps = await service.downloadArtifacts(
        engineVersion: testEngineVersion,
        hostPlatform: HostPlatform.linux_x64,
        targetPlatforms: const <String>{'android', 'linux'},
      );
      expect(deps, hasLength(1));
      expect(deps.first.name, testArtifactName);
    });

    test('filters out artifacts on non-matching hostPlatform or targetPlatforms', () async {
      final service = LinuxArtifactService(artifacts: testArtifacts);
      expect(
        await service.downloadArtifacts(
          engineVersion: testEngineVersion,
          hostPlatform: HostPlatform.darwin_arm64,
        ),
        isEmpty,
      );
      expect(
        await service.downloadArtifacts(
          engineVersion: testEngineVersion,
          hostPlatform: HostPlatform.linux_x64,
          targetPlatforms: const <String>{'android-arm64'},
        ),
        isEmpty,
      );
    });
  });
}
