// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:flutter_tools_extension_linux_prototype/src/clean.dart';
import 'package:flutter_tools_extension_linux_prototype/src/config.dart';
import 'package:flutter_tools_extension_linux_prototype/src/device.dart';
import 'package:flutter_tools_extension_linux_prototype/src/diagnostics.dart';
import 'package:flutter_tools_extension_linux_prototype/src/template.dart';
import 'package:test/test.dart';

Uri _resolvePrototypePackageRoot() {
  final Uri? libraryUri = Isolate.resolvePackageUriSync(
    Uri.parse(
      'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart',
    ),
  );
  if (libraryUri == null) {
    throw StateError('Failed to resolve package:flutter_tools_extension_linux_prototype URI.');
  }
  return libraryUri.resolve('../');
}

void main() {
  const methodNotFoundErrorCode = -32601;

  group('Linux Prototype ExtensionTestHarness', () {
    test(
      'spawn exercises typed protocol clients and build graceful-skip path over JSON-RPC 2.0',
      () async {
        final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
          linuxExtensionEntryPoint,
        );
        addTearDown(harness.dispose);

        expect(harness.capabilities.extensionName, 'flutter_tools_extension_linux_prototype');
        expect(
          harness.capabilities.protocolVersion,
          ToolExtensionCapabilities.currentProtocolVersion,
        );
        expect(harness.capabilities.supportedPlatforms, <String>{'linux'});
        expect(
          harness.capabilities.services,
          unorderedEquals(<String>[
            'diagnostics',
            'config',
            'template',
            'device',
            'build',
            'clean',
          ]),
        );

        expect(await harness.diagnosticsClient.getTitle(), 'Linux Custom Extension Prototype');
        final List<ValidationResult> diagnostics = await harness.diagnosticsClient.runDiagnostics();
        expect(diagnostics, hasLength(1));
        expect(diagnostics.first.type, ValidationType.success);
        expect(diagnostics.first.statusInfo, 'Linux Prototype Extension OK');

        expect(await harness.configClient.getTitle(), 'Linux Custom Extension Prototype');
        final List<FeatureFlag> flags = await harness.configClient.getFeatureFlags();
        expect(flags, hasLength(1));
        expect(flags.first.name, LinuxConfigurationExtension.kEnableLinuxCustomPrototype);
        final List<ConfigOption> configs = await harness.configClient.getConfigurations();
        expect(configs, hasLength(1));
        expect(configs.first.name, LinuxConfigurationExtension.kLinuxGtkVersion);

        expect(await harness.templateClient.getAppTemplates(), isEmpty);
        expect(await harness.templateClient.getPluginTemplates(), isEmpty);
        final List<ExtensionProjectTemplate> templates = await harness.templateClient
            .getProjectTemplates();
        expect(templates, hasLength(1));
        expect(templates.first.name, 'custom-linux-app');
        final Map<String, Object?> params = await harness.templateClient.generateTemplateParameters(
          'custom-linux-app',
          const <String, Object?>{'projectName': 'demo_app'},
        );
        expect(params, const <String, Object?>{'projectName': 'demo_app'});

        final List<TargetDevice> devices = await harness.deviceClient.getDevices();
        expect(devices, hasLength(1));
        expect(devices.first.id, LinuxDeviceService.customLinuxDeviceId);

        final List<ExtensionBuildTarget> buildTargets = await harness.buildClient.getBuildTargets();
        expect(buildTargets, hasLength(1));
        expect(buildTargets.first.name, LinuxBuildService.customLinuxBuildTargetName);

        final ExtensionBuildResult buildResult = await harness.buildClient.build(
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          projectRoot: Uri.parse('file:///nonexistent_project_root/'),
          targetName: LinuxBuildService.customLinuxBuildTargetName,
        );
        expect(buildResult.success, isTrue);

        await expectLater(
          harness.sendRawRequest('unknown.method'),
          throwsA(
            isA<RpcException>().having((RpcException e) => e.code, 'code', methodNotFoundErrorCode),
          ),
        );
      },
    );

    test(
      'deviceClient and cleanClient work with injected hermetic ExtensionDependencies',
      () async {
        final ExtensionDependencies dependencies = createTestDependencies();
        final ExtensionDirectory projectDir = dependencies.fileSystem.directory(
          Uri.parse('file:///hermetic_app/'),
        )..createSync(recursive: true);
        final ExtensionDirectory buildDir = projectDir.childDirectory('build')
          ..createSync(recursive: true);
        final ExtensionDirectory linuxBuildDir = buildDir.childDirectory('linux')
          ..createSync(recursive: true);
        linuxBuildDir.childFile('libapp.so').writeAsStringSync('elf');
        final ExtensionDirectory linuxEphemeralDir =
            projectDir.childDirectory('linux').childDirectory('flutter').childDirectory('ephemeral')
              ..createSync(recursive: true);
        linuxEphemeralDir.childFile('generated.cmake').writeAsStringSync('cmake');

        final ExtensionTestHarness harness = await ExtensionTestHarness.spawn((SendPort sendPort) {
          return ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              LinuxExtensionDiagnostics(),
              LinuxConfigurationExtension(),
              LinuxTemplateService(),
              LinuxDeviceService(dependencies: dependencies),
              LinuxBuildService(),
              LinuxCleanService(dependencies: dependencies),
            ],
            extensionName: 'flutter_tools_extension_linux_prototype',
            supportedPlatforms: const <String>{'linux'},
          );
        });
        addTearDown(harness.dispose);

        final project = ExtensionFlutterProject(
          appName: 'hermetic_app',
          buildDirectory: buildDir.uri,
          directory: projectDir.uri,
        );
        expect(
          await harness.deviceClient.isSupportedForProject(
            deviceId: LinuxDeviceService.customLinuxDeviceId,
            project: project,
          ),
          isTrue,
        );
        expect(
          await harness.deviceClient.isSupportedForProject(
            deviceId: LinuxDeviceService.customLinuxDeviceId,
            project: ExtensionFlutterProject(
              appName: 'unsupported_app',
              buildDirectory: buildDir.uri,
              directory: Uri.parse('file:///missing_project/'),
            ),
          ),
          isFalse,
        );

        final buildAsProject = ExtensionFlutterProject(
          appName: 'hermetic_build_probe',
          buildDirectory: buildDir.uri,
          directory: buildDir.uri,
        );
        expect(
          await harness.deviceClient.isSupportedForProject(
            deviceId: LinuxDeviceService.customLinuxDeviceId,
            project: buildAsProject,
          ),
          isTrue,
        );

        await harness.cleanClient.clean(
          CleanEnvironment(buildDir: buildDir.uri, projectRoot: projectDir.uri),
        );
        expect(
          await harness.deviceClient.isSupportedForProject(
            deviceId: LinuxDeviceService.customLinuxDeviceId,
            project: buildAsProject,
          ),
          isFalse,
        );
      },
    );

    test('spawnUri spawns bin/flutter_tools_extension_linux_prototype.dart', () async {
      final Uri packageRoot = _resolvePrototypePackageRoot();
      final Uri entrypointUri = packageRoot.resolve(
        'bin/flutter_tools_extension_linux_prototype.dart',
      );

      final ExtensionTestHarness harness = await ExtensionTestHarness.spawnUri(entrypointUri);
      addTearDown(harness.dispose);

      expect(harness.capabilities.extensionName, 'flutter_tools_extension_linux_prototype');
      final List<TargetDevice> devices = await harness.deviceClient.getDevices();
      expect(devices, hasLength(1));
      expect(devices.first.id, LinuxDeviceService.customLinuxDeviceId);
    });

    test('verifyExtensionPackage validates config.yaml against runtime extension', () async {
      final Uri packageRoot = _resolvePrototypePackageRoot();

      await verifyExtensionPackage(packageRoot: packageRoot, entryPoint: linuxExtensionEntryPoint);

      await verifyExtensionPackage(packageRoot: packageRoot);
    });
  });
}
