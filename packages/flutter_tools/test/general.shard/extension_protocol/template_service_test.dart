// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/experimental/templates.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:flutter_tools_extension_linux_prototype/src/template.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

import '../../src/fakes.dart';

final class _DuplicateLinuxTemplateService extends TemplateService {
  @override
  Map<String, String> get appPlatformTemplates => const <String, String>{
    LinuxTemplateService.customLinuxPlatformName:
        'package:flutter_tools_extension_linux_prototype/templates/duplicate',
  };
}

void _duplicateLinuxExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_DuplicateLinuxTemplateService()],
    extensionName: 'duplicate_linux_extension',
    supportedPlatforms: const <String>{'linux'},
  );
}

void main() {
  setUpAll(() {
    Cache.flutterRoot = '/flutter';
  });

  group('ExtensionTemplateManager', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
    });

    test(
      'returns empty platform templates when tool extensions feature flag is disabled',
      () async {
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final templateManager = ExtensionTemplateManager(
          extensionManager: manager,
          fileSystem: fs,
          logger: logger,
          featureFlags: TestFeatureFlags(),
        );

        final Map<String, String> appTemplates = await templateManager.getAppPlatformTemplates();
        expect(appTemplates, isEmpty);
        expect(templateManager.cachedAppPlatformTemplates, isEmpty);

        final Map<String, String> pluginTemplates = await templateManager
            .getPluginPlatformTemplates();
        expect(pluginTemplates, isEmpty);
        expect(templateManager.cachedPluginPlatformTemplates, isEmpty);

        final defaultParams = <String, Object?>{'projectName': 'my_app'};
        final Map<String, Object?> generatedParams = await templateManager
            .generatePlatformTemplateParameters(
              platformName: LinuxTemplateService.customLinuxPlatformName,
              toolParameters: defaultParams,
            );
        expect(generatedParams, equals(defaultParams));

        await manager.dispose();
      },
    );

    test('queries platform templates over RPC and caches results', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        fileSystem: fs,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );

      final Map<String, String> appTemplates = await templateManager.getAppPlatformTemplates();
      expect(
        appTemplates,
        equals(<String, String>{
          LinuxTemplateService.customLinuxPlatformName: LinuxTemplateService.customLinuxTemplateUri,
        }),
      );
      expect(templateManager.cachedAppPlatformTemplates, equals(appTemplates));

      final Map<String, String> pluginTemplates = await templateManager
          .getPluginPlatformTemplates();
      expect(pluginTemplates, isEmpty);
      expect(templateManager.cachedPluginPlatformTemplates, isEmpty);

      // Subsequent calls return cached maps directly.
      final Map<String, String> cachedAppCall = await templateManager.getAppPlatformTemplates();
      expect(identical(cachedAppCall, appTemplates), isTrue);

      final Map<String, String> cachedPluginCall = await templateManager
          .getPluginPlatformTemplates();
      expect(identical(cachedPluginCall, pluginTemplates), isTrue);

      await manager.dispose();
    });

    test('generatePlatformTemplateParameters delegates over RPC and augments parameters', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        fileSystem: fs,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );

      final inputParams = <String, Object?>{
        'projectName': 'sample_linux_app',
        'org': 'com.example',
      };
      final Map<String, Object?> result = await templateManager.generatePlatformTemplateParameters(
        platformName: LinuxTemplateService.customLinuxPlatformName,
        toolParameters: inputParams,
      );

      expect(result['projectName'], 'sample_linux_app');
      expect(result['org'], 'com.example');
      expect(result['customLinux'], isTrue);

      // Returns toolParameters unchanged when platformName is unknown.
      final Map<String, Object?> unknownResult = await templateManager
          .generatePlatformTemplateParameters(
            platformName: 'unknown_platform',
            toolParameters: inputParams,
          );
      expect(unknownResult, equals(inputParams));

      await manager.dispose();
    });

    test('logs warning when duplicate platform template is encountered', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(
        entryPoints: <ExtensionEntryPoint>[
          linuxExtensionEntryPoint,
          _duplicateLinuxExtensionEntryPoint,
        ],
      );

      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        fileSystem: fs,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );

      final Map<String, String> appTemplates = await templateManager.getAppPlatformTemplates();
      expect(
        appTemplates,
        equals(<String, String>{
          LinuxTemplateService.customLinuxPlatformName: LinuxTemplateService.customLinuxTemplateUri,
        }),
      );
      expect(
        logger.warningText,
        contains(
          'Duplicate app platform template "custom_linux" provided by extension '
          '"duplicate_linux_extension" (already registered by extension '
          '"flutter_tools_extension_linux_prototype")',
        ),
      );

      await manager.dispose();
    });

    test('RPC parameter validation throws INVALID_PARAMS on invalid or missing params', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

      final ExtensionConnection connection = manager.connections.first;

      await expectLater(
        connection.sendRequest(
          TemplateService.generatePlatformTemplateParametersMethod,
          params: const <String, Object?>{},
        ),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            equals(error_code.INVALID_PARAMS),
          ),
        ),
      );

      await expectLater(
        connection.sendRequest(
          TemplateService.generatePlatformTemplateParametersMethod,
          params: const <String, Object?>{
            'platformName': 123,
            'toolParameters': <String, Object?>{},
          },
        ),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            equals(error_code.INVALID_PARAMS),
          ),
        ),
      );

      await manager.dispose();
    });

    test('resolveTemplateDirectory resolves package paths correctly', () {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        fileSystem: fs,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );

      final Directory toolsDir = templateManager.resolveTemplateDirectory(
        'package:flutter_tools/templates/app',
      );
      expect(
        toolsDir.path,
        fs.path.join('/flutter', 'packages', 'flutter_tools', 'lib', 'templates', 'app'),
      );

      final Directory protoDir = templateManager.resolveTemplateDirectory(
        'package:flutter_tools_extension_linux_prototype/templates/custom-linux-app',
      );
      expect(
        protoDir.path,
        fs.path.join(
          '/flutter',
          'packages',
          'flutter_tools',
          'packages',
          'flutter_tools_extension_linux_prototype',
          'lib',
          'templates',
          'custom-linux-app',
        ),
      );

      expect(
        () => templateManager.resolveTemplateDirectory('invalid_path/foo'),
        throwsArgumentError,
      );
    });
  });
}
