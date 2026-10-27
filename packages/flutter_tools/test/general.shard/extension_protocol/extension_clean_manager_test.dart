// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/experimental/extension_clean_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide HostPlatform;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/test.dart';

import '../../src/fakes.dart';

final class _FakeCleanService extends CleanService {
  _FakeCleanService(this.onClean);

  final Future<void> Function(CleanEnvironment environment) onClean;

  @override
  Future<void> clean(CleanEnvironment environment) => onClean(environment);
}

void main() {
  group('ExtensionCleanManager', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
    });

    test('does nothing when tool extensions feature flag is disabled', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_FakeCleanService((CleanEnvironment _) async {})],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[entryPoint],
      );
      addTearDown(manager.dispose);

      final cleanManager = ExtensionCleanManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        logger: logger,
      );

      final Directory projectDir = fs.directory('/project')..createSync(recursive: true);
      projectDir.childFile('pubspec.yaml').writeAsStringSync('name: test_app\n');
      final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir, logger);

      await cleanManager.cleanProject(project, buildDirectory: projectDir.childDirectory('build'));
      expect(manager.isInitialized, isFalse);
    });

    test('skips connections that do not advertise the clean capability', () async {
      void noCleanEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          const <ToolExtensionService>[],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[noCleanEntryPoint],
      );
      addTearDown(manager.dispose);

      final cleanManager = ExtensionCleanManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        logger: logger,
      );

      final Directory projectDir = fs.directory('/project')..createSync(recursive: true);
      projectDir.childFile('pubspec.yaml').writeAsStringSync('name: test_app\n');
      final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir, logger);

      await cleanManager.cleanProject(project, buildDirectory: projectDir.childDirectory('build'));
      expect(manager.isInitialized, isTrue);
      expect(logger.errorText, isEmpty);
    });

    test('invokes clean RPC on active extensions with buildDirectory and projectRoot', () async {
      final verifyPort = ReceivePort();
      addTearDown(verifyPort.close);
      final SendPort verifySendPort = verifyPort.sendPort;

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeCleanService((CleanEnvironment env) async {
              verifySendPort.send(env.toMap());
            }),
          ],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[entryPoint],
      );
      addTearDown(manager.dispose);

      final cleanManager = ExtensionCleanManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        logger: logger,
      );

      final Directory projectDir = fs.directory('/my_project')..createSync(recursive: true);
      projectDir.childFile('pubspec.yaml').writeAsStringSync('name: test_app\n');
      final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir, logger);
      final Directory customBuildDir = projectDir.childDirectory('custom_build');

      await cleanManager.cleanProject(project, buildDirectory: customBuildDir);

      final Object? rawReceived = await verifyPort.first;
      final receivedEnv = CleanEnvironment.fromJson(rawReceived! as Map<String, Object?>);
      expect(receivedEnv.projectRoot, project.directory.absolute.uri);
      expect(receivedEnv.buildDir, customBuildDir.absolute.uri);
    });

    test(
      'logs error when extension clean RPC throws without failing caller or sibling extensions',
      () async {
        final verifyPort = ReceivePort();
        addTearDown(verifyPort.close);
        final SendPort verifySendPort = verifyPort.sendPort;

        void failingEntryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _FakeCleanService((CleanEnvironment _) async {
                throw StateError('Simulated extension clean failure');
              }),
            ],
            extensionName: 'failing_clean_extension',
            supportedPlatforms: const <String>{'linux'},
          );
        }

        void succeedingEntryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _FakeCleanService((CleanEnvironment env) async {
                verifySendPort.send(env.toMap());
              }),
            ],
            extensionName: 'succeeding_clean_extension',
            supportedPlatforms: const <String>{'linux'},
          );
        }

        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          entryPoints: <ExtensionEntryPoint>[failingEntryPoint, succeedingEntryPoint],
        );
        addTearDown(manager.dispose);

        final cleanManager = ExtensionCleanManager(
          extensionManager: manager,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          logger: logger,
        );

        final Directory projectDir = fs.directory('/my_project')..createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: test_app\n');
        final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir, logger);
        final Directory buildDir = projectDir.childDirectory('build');

        await cleanManager.cleanProject(project, buildDirectory: buildDir);
        expect(
          logger.errorText,
          contains('Failed to clean extension artifacts for "failing_clean_extension"'),
        );

        final Object? rawReceived = await verifyPort.first;
        final receivedEnv = CleanEnvironment.fromJson(rawReceived! as Map<String, Object?>);
        expect(receivedEnv.projectRoot, project.directory.absolute.uri);
        expect(receivedEnv.buildDir, buildDir.absolute.uri);
      },
    );
  });
}
