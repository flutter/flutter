// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:flutter_tools_extension_linux_prototype/src/config.dart';
import 'package:flutter_tools_extension_linux_prototype/src/device.dart';
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
    test('spawn exercises typed protocol clients and build validation over JSON-RPC 2.0', () async {
      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
        linuxExtensionEntryPoint,
      );
      addTearDown(harness.dispose);

      expect(harness.capabilities.extensionName, 'flutter_tools_extension_linux_prototype');
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
          'artifact',
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

      final List<ExtensionAssembleTarget> assembleTargets = await harness.buildClient
          .getAssembleTargets();
      expect(assembleTargets, hasLength(1));
      expect(assembleTargets.first.name, 'custom-linux-assemble-only-debug');

      final Uri projectRoot = Uri.parse('file:///nonexistent_project_root/');
      final ExtensionBuildResult buildResult = await harness.buildClient.build(
        buildMode: .debug,
        flutterRoot: Uri.parse('file:///flutter_sdk/'),
        mainPath: 'lib/main.dart',
        outputDir: projectRoot.resolve('build/'),
        projectRoot: projectRoot,
        targetName: LinuxBuildService.customLinuxBuildTargetName,
      );
      expect(buildResult.success, isFalse);
      expect(buildResult.errorMessage, contains('Missing linux/CMakeLists.txt'));

      final List<ArtifactDependency> artifacts = await harness.artifactClient.listRequiredArtifacts(
        engineVersion: 'abcdef123456',
        hostPlatform: HostPlatform.linux_x64,
      );
      expect(artifacts, isEmpty);

      await expectLater(
        harness.sendRawRequest('unknown.method'),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', methodNotFoundErrorCode),
        ),
      );
    });

    test(
      'deviceClient and cleanClient operate over JSON-RPC on a temporary project directory',
      () async {
        final Directory tempDir = Directory.systemTemp.createTempSync('linux_harness_test.');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final buildDir = Directory('${tempDir.path}/build')..createSync(recursive: true);
        final linuxBuildDir = Directory('${buildDir.path}/linux')..createSync(recursive: true);
        File('${linuxBuildDir.path}/libapp.so').writeAsStringSync('elf');
        final linuxEphemeralDir = Directory('${tempDir.path}/linux/flutter/ephemeral')
          ..createSync(recursive: true);
        File('${linuxEphemeralDir.path}/generated.cmake').writeAsStringSync('cmake');

        final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
          linuxExtensionEntryPoint,
        );
        addTearDown(harness.dispose);

        final project = ExtensionFlutterProject(
          appName: 'temp_app',
          buildDirectory: buildDir.uri,
          directory: tempDir.uri,
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

        await harness.cleanClient.clean(
          CleanEnvironment(buildDir: buildDir.uri, projectRoot: tempDir.uri),
        );
        expect(linuxBuildDir.existsSync(), isFalse);
        expect(linuxEphemeralDir.existsSync(), isFalse);
        expect(buildDir.existsSync(), isTrue);
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

    test(
      'verifyExtensionPackage validates prototype entrypoint and runtime capabilities',
      () async {
        final Uri packageRoot = _resolvePrototypePackageRoot();
        final expectedConfig = ExtensionPackageConfig(
          name: 'flutter_tools_extension_linux_prototype',
          entrypoint: 'bin/flutter_tools_extension_linux_prototype.dart',
          hostPlatforms: const <String>{'linux'},
          services: const <String>{
            'diagnostics',
            'config',
            'template',
            'device',
            'build',
            'clean',
            'artifact',
          },
          buildTargets: const <String>{LinuxBuildService.customLinuxBuildTargetName},
          templates: const <String>{'custom-linux-app'},
          targetPlatforms: const <String>{'custom_linux'},
        );

        await verifyExtensionPackage(
          packageRoot: packageRoot,
          entryPoint: linuxExtensionEntryPoint,
          expectedConfig: expectedConfig,
        );

        await verifyExtensionPackage(packageRoot: packageRoot, expectedConfig: expectedConfig);
      },
    );
  });
}
