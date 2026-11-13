// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/experimental/templates.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:flutter_tools_extension_linux_prototype/src/template.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../../src/common.dart';
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

final class _ConflictingPluginLinuxTemplateService extends TemplateService {
  @override
  Map<String, String> get pluginPlatformTemplates => const <String, String>{
    LinuxTemplateService.customLinuxPlatformName:
        'package:flutter_tools_extension_linux_prototype/templates/conflicting-plugin',
  };

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platformName,
    required Map<String, Object?> toolParameters,
  }) async {
    return <String, Object?>{...toolParameters, 'fromConflictingPluginExtension': true};
  }
}

void _conflictingPluginLinuxExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_ConflictingPluginLinuxTemplateService()],
    extensionName: 'conflicting_plugin_linux_extension',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _CombinedAppAndPluginLinuxTemplateService extends TemplateService {
  static const appTemplateUri =
      'package:flutter_tools_extension_linux_prototype/templates/combined-app';
  static const pluginTemplateUri =
      'package:flutter_tools_extension_linux_prototype/templates/combined-plugin';

  @override
  Map<String, String> get appPlatformTemplates => const <String, String>{
    LinuxTemplateService.customLinuxPlatformName: appTemplateUri,
  };

  @override
  Map<String, String> get pluginPlatformTemplates => const <String, String>{
    LinuxTemplateService.customLinuxPlatformName: pluginTemplateUri,
  };

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platformName,
    required Map<String, Object?> toolParameters,
  }) async {
    return <String, Object?>{...toolParameters, 'combinedExtension': true};
  }
}

void _combinedAppAndPluginLinuxExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_CombinedAppAndPluginLinuxTemplateService()],
    extensionName: 'combined_linux_extension',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _DomainErrorTemplateService extends TemplateService {
  static const customPlatformName = 'custom_os';

  @override
  Map<String, String> get appPlatformTemplates => const <String, String>{
    customPlatformName: LinuxTemplateService.customLinuxTemplateUri,
  };

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platformName,
    required Map<String, Object?> toolParameters,
  }) async {
    throw const ToolExtensionException('Template parameter generation failed.');
  }
}

void _domainErrorTemplateEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[_DomainErrorTemplateService()],
      extensionName: 'custom_template_ext',
      supportedPlatforms: const <String>{'linux'},
    ),
  );
}

void main() {
  group('ExtensionTemplateManager', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
    });

    testWithoutContext(
      'returns empty platform templates when tool extensions feature flag is disabled',
      () async {
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        addTearDown(manager.dispose);
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final templateManager = ExtensionTemplateManager(
          extensionManager: manager,
          fileSystem: fs,
          logger: logger,
          featureFlags: TestFeatureFlags(),
          flutterRoot: '/flutter',
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
      },
    );

    testWithoutContext('queries platform templates over RPC and caches results', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        fileSystem: fs,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        flutterRoot: '/flutter',
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
    });

    testWithoutContext(
      'generatePlatformTemplateParameters delegates over RPC and augments parameters',
      () async {
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        addTearDown(manager.dispose);
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final templateManager = ExtensionTemplateManager(
          extensionManager: manager,
          fileSystem: fs,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          flutterRoot: '/flutter',
        );

        final inputParams = <String, Object?>{
          'projectName': 'sample_linux_app',
          'org': 'com.example',
        };
        final Map<String, Object?> result = await templateManager
            .generatePlatformTemplateParameters(
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
      },
    );

    testWithoutContext('logs warning when duplicate platform template is encountered', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      addTearDown(manager.dispose);
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
        flutterRoot: '/flutter',
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
    });

    testWithoutContext('logs warning and preserves owner when second extension registers plugin template for same platform', () async {
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);
      await manager.initialize(
        entryPoints: <ExtensionEntryPoint>[
          linuxExtensionEntryPoint,
          _conflictingPluginLinuxExtensionEntryPoint,
        ],
      );

      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        fileSystem: fs,
        flutterRoot: '/flutter',
        logger: logger,
      );

      // Query plugin templates first to verify ownership is deterministic regardless of call order.
      final Map<String, String> pluginTemplates = await templateManager
          .getPluginPlatformTemplates();
      expect(pluginTemplates, isEmpty);
      expect(
        logger.warningText,
        contains(
          'Conflicting plugin platform template "custom_linux" provided by extension '
          '"conflicting_plugin_linux_extension" (platform already registered by extension '
          '"flutter_tools_extension_linux_prototype")',
        ),
      );

      final Map<String, String> appTemplates = await templateManager.getAppPlatformTemplates();
      expect(
        appTemplates,
        equals(<String, String>{
          LinuxTemplateService.customLinuxPlatformName: LinuxTemplateService.customLinuxTemplateUri,
        }),
      );

      final Map<String, Object?> params = await templateManager.generatePlatformTemplateParameters(
        platformName: LinuxTemplateService.customLinuxPlatformName,
        toolParameters: const <String, Object?>{'projectName': 'my_app'},
      );
      expect(params['customLinux'], isTrue);
      expect(params.containsKey('fromConflictingPluginExtension'), isFalse);
    });

    testWithoutContext(
      'allows single extension to register both app and plugin templates for same platform',
      () async {
        final manager = ExtensionManager(
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
        );
        addTearDown(manager.dispose);
        await manager.initialize(
          entryPoints: <ExtensionEntryPoint>[_combinedAppAndPluginLinuxExtensionEntryPoint],
        );

        final templateManager = ExtensionTemplateManager(
          extensionManager: manager,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          fileSystem: fs,
          flutterRoot: '/flutter',
          logger: logger,
        );

        final Map<String, String> appTemplates = await templateManager.getAppPlatformTemplates();
        final Map<String, String> pluginTemplates = await templateManager
            .getPluginPlatformTemplates();

        expect(
          appTemplates,
          equals(<String, String>{
            LinuxTemplateService.customLinuxPlatformName:
                _CombinedAppAndPluginLinuxTemplateService.appTemplateUri,
          }),
        );
        expect(
          pluginTemplates,
          equals(<String, String>{
            LinuxTemplateService.customLinuxPlatformName:
                _CombinedAppAndPluginLinuxTemplateService.pluginTemplateUri,
          }),
        );
        expect(logger.warningText, isEmpty);

        final Map<String, Object?> params = await templateManager
            .generatePlatformTemplateParameters(
              platformName: LinuxTemplateService.customLinuxPlatformName,
              toolParameters: const <String, Object?>{'projectName': 'my_plugin'},
            );
        expect(params['combinedExtension'], isTrue);
      },
    );

    testWithoutContext(
      'RPC parameter validation throws INVALID_PARAMS on invalid or missing params',
      () async {
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        addTearDown(manager.dispose);
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
              TemplateService.platformNameParam: 123,
              TemplateService.toolParametersParam: <String, Object?>{},
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

        await expectLater(
          connection.sendRequest(
            TemplateService.generatePlatformTemplateParametersMethod,
            params: const <String, Object?>{
              TemplateService.platformNameParam: LinuxTemplateService.customLinuxPlatformName,
              TemplateService.toolParametersParam: 'invalid',
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
      },
    );

    testWithoutContext('resolveTemplateDirectory resolves package paths correctly', () {
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
        flutterRoot: '/flutter',
      );

      final Directory toolsDir = templateManager.resolveTemplateDirectory(
        'package:flutter_tools/templates/app',
      );
      expect(
        toolsDir.path,
        fs.path.join('/flutter', 'packages', 'flutter_tools', 'lib', 'templates', 'app'),
      );

      final Directory protoDir = templateManager.resolveTemplateDirectory(
        LinuxTemplateService.customLinuxTemplateUri,
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

    testWithoutContext('generatePlatformTemplateParameters throws ToolExit when extension throws ToolExtensionException', () async {
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_domainErrorTemplateEntryPoint]);

      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        fileSystem: fs,
        flutterRoot: '/flutter',
        logger: logger,
      );

      await expectLater(
        templateManager.generatePlatformTemplateParameters(
          platformName: _DomainErrorTemplateService.customPlatformName,
          toolParameters: const <String, Object?>{'projectName': 'my_app'},
        ),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            'Template parameter generation failed.',
          ),
        ),
      );
    });
  });
}
