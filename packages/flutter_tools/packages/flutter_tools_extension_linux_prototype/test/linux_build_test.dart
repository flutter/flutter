// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
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
      expect(target.description, 'A custom Linux build target from prototype extension.');
    });

    test('build succeeds for custom-linux-build and fails for unknown target', () async {
      final service = LinuxBuildService();

      final ExtensionBuildResult successResult = await service.build(
        buildMode: .debug,
        mainPath: 'lib/main.dart',
        projectRoot: Uri.parse('/project'),
        targetName: LinuxBuildService.customLinuxBuildTargetName,
      );
      expect(successResult.success, isTrue);
      expect(successResult.errorMessage, isNull);

      final ExtensionBuildResult failureResult = await service.build(
        buildMode: .debug,
        mainPath: 'lib/main.dart',
        projectRoot: Uri.parse('/project'),
        targetName: 'unknown-target',
      );
      expect(failureResult.success, isFalse);
      expect(failureResult.errorMessage, contains('Unknown build target: unknown-target'));
    });

    test('initialize registers getBuildTargets and build RPC handlers', () async {
      final service = LinuxBuildService();
      expect(service.namespace, BuildService.serviceNamespace);

      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      expect(handlers.keys, containsAll(<String>['getBuildTargets', 'build']));

      final Object? targetsResult = await handlers['getBuildTargets']!(const <String, Object?>{});
      final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(targetsResult);
      expect(targets, hasLength(1));
      expect(targets.first.name, LinuxBuildService.customLinuxBuildTargetName);

      final Object? buildResultObj = await handlers['build']!(<String, Object?>{
        BuildService.buildModeParam: 'debug',
        BuildService.mainPathParam: 'lib/main.dart',
        BuildService.projectRootParam: '/project',
        BuildService.targetNameParam: LinuxBuildService.customLinuxBuildTargetName,
      });
      expect(buildResultObj, isA<Map<String, Object?>>());
      final buildResult = ExtensionBuildResult.fromJson(buildResultObj! as Map<String, Object?>);
      expect(buildResult.success, isTrue);

      await service.shutdown();
    });

    test('build RPC handler throws on missing or invalid parameters', () async {
      final service = LinuxBuildService();
      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      final ExtensionRpcHandler buildHandler = handlers['build']!;

      await expectLater(
        () => buildHandler(const <String, Object?>{}),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.targetNameParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{BuildService.targetNameParam: 'custom-linux-build'}),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.projectRootParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.mainPathParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.buildModeParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: 'relative/path',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.projectRootParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'invalid_mode',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.buildModeParam}" parameter.'),
          ),
        ),
      );
    });
  });
}
