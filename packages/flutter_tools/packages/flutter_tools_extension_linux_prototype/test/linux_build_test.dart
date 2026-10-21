// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:test/test.dart';

const int _invalidParamsErrorCode = -32602;

Matcher _throwsInvalidParams(String message) => throwsA(
  isA<Exception>()
      .having((Exception e) => e.toString(), 'code', contains('$_invalidParamsErrorCode'))
      .having((Exception e) => e.toString(), 'message', contains(message)),
);

void main() {
  group('LinuxBuildService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('linux_build_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final cmakeFile = File.fromUri(tempDir.uri.resolve('linux/CMakeLists.txt'))
        ..createSync(recursive: true);
      cmakeFile.writeAsStringSync('set(BINARY_NAME "test_app")\n');
    });

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
        projectRoot: tempDir.uri,
        targetName: LinuxBuildService.customLinuxBuildTargetName,
      );
      expect(successResult.success, isTrue);
      expect(successResult.errorMessage, isNull);
      expect(successResult.executableUri?.path, contains('bundle/test_app'));

      final ExtensionBuildResult failureResult = await service.build(
        buildMode: .debug,
        mainPath: 'lib/main.dart',
        projectRoot: tempDir.uri,
        targetName: 'unknown-target',
      );
      expect(failureResult.success, isFalse);
      expect(failureResult.errorMessage, contains('Unknown build target: unknown-target'));
    });

    test('build fails when linux/CMakeLists.txt is missing', () async {
      final Directory emptyDir = Directory.systemTemp.createTempSync('empty_project');
      addTearDown(() => emptyDir.deleteSync(recursive: true));
      final service = LinuxBuildService();
      final ExtensionBuildResult failureResult = await service.build(
        buildMode: .debug,
        mainPath: 'lib/main.dart',
        projectRoot: emptyDir.uri,
        targetName: LinuxBuildService.customLinuxBuildTargetName,
      );
      expect(failureResult.success, isFalse);
      expect(failureResult.errorMessage, 'Could not find BINARY_NAME in linux/CMakeLists.txt.');
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
        BuildService.projectRootParam: tempDir.uri.toString(),
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
        _throwsInvalidParams(
          'Missing required "${BuildService.targetNameParam}" (expected String).',
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{BuildService.targetNameParam: 'custom-linux-build'}),
        _throwsInvalidParams(
          'Missing required "${BuildService.projectRootParam}" (expected String).',
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
        }),
        _throwsInvalidParams('Missing required "${BuildService.mainPathParam}" (expected String).'),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
        }),
        _throwsInvalidParams(
          'Missing required "${BuildService.buildModeParam}" (expected String).',
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: 'relative/path',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
        }),
        _throwsInvalidParams('Missing or invalid "${BuildService.projectRootParam}" parameter.'),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'invalid_mode',
        }),
        _throwsInvalidParams('Missing or invalid "${BuildService.buildModeParam}" parameter.'),
      );
    });
  });
}
