// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxBuildService', () {
    test('getBuildTargets returns prototype custom-linux-build target', () async {
      final service = LinuxBuildService();
      final List<ExtensionBuildTarget> targets = await service.getBuildTargets();

      expect(targets, hasLength(1));
      final ExtensionBuildTarget target = targets.first;
      expect(target.name, LinuxBuildService.customLinuxBuildTargetName);
      expect(target.targetPlatform, LinuxBuildService.linuxX64TargetPlatform);
      expect(target.description, 'A custom Linux build target from prototype extension.');
    });

    test('build succeeds for custom-linux-build and fails for unknown target', () async {
      final service = LinuxBuildService();

      final ExtensionBuildResult successResult = await service.build(
        buildMode: 'debug',
        mainPath: 'lib/main.dart',
        projectRoot: '/project',
        targetName: LinuxBuildService.customLinuxBuildTargetName,
      );
      expect(successResult.success, isTrue);
      expect(successResult.errorMessage, isNull);

      final ExtensionBuildResult failureResult = await service.build(
        buildMode: 'debug',
        mainPath: 'lib/main.dart',
        projectRoot: '/project',
        targetName: 'unknown-target',
      );
      expect(failureResult.success, isFalse);
      expect(failureResult.errorMessage, contains('Unknown build target: unknown-target'));
    });
  });
}
