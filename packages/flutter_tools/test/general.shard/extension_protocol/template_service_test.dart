// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/memory.dart';
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
  Set<String> supportedPlatforms(ExtensionTemplateType templateType) => switch (templateType) {
    .app => const <String>{LinuxTemplateService.customLinuxPlatformName},
    _ => const <String>{},
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
  Set<String> supportedPlatforms(ExtensionTemplateType templateType) => switch (templateType) {
    .plugin => const <String>{LinuxTemplateService.customLinuxPlatformName},
    _ => const <String>{},
  };

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platform,
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

final class _BuiltInCollisionTemplateService extends TemplateService {
  @override
  Set<String> supportedPlatforms(ExtensionTemplateType templateType) => switch (templateType) {
    .app => const <String>{'linux', 'valid_custom'},
    _ => const <String>{},
  };

  @override
  Future<ExtensionPlatformTemplate?> resolvePlatformTemplate({
    required String platform,
    required ExtensionTemplateType templateType,
    required Map<String, Object?> toolParameters,
  }) async => switch ((platform, templateType)) {
    ('valid_custom', .app) => ExtensionPlatformTemplate(
      templateUri: Uri.parse('package:builtin_collision_ext/templates/app'),
    ),
    _ => null,
  };
}

void _builtInCollisionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_BuiltInCollisionTemplateService()],
    extensionName: 'builtin_collision_ext',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _MultiVariantTemplateService extends TemplateService {
  static const platformName = 'custom_os';

  @override
  Set<String> supportedPlatforms(ExtensionTemplateType templateType) => const <String>{
    platformName,
  };

  @override
  Future<ExtensionPlatformTemplate?> resolvePlatformTemplate({
    required String platform,
    required ExtensionTemplateType templateType,
    required Map<String, Object?> toolParameters,
  }) async {
    if (platform != platformName) {
      return null;
    }
    final String variant = toolParameters['variant'] as String? ?? 'default';
    return ExtensionPlatformTemplate(
      templateUri: Uri.parse('package:multi_variant_ext/templates/${templateType.name}/$variant'),
    );
  }

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platform,
    required Map<String, Object?> toolParameters,
  }) async {
    return <String, Object?>{...toolParameters, 'combinedExtension': true};
  }
}

void _multiVariantExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_MultiVariantTemplateService()],
    extensionName: 'multi_variant_ext',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _FailingTemplateService extends TemplateService {
  static const domainErrorPlatform = 'domain_error_os';
  static const crashPlatform = 'crash_os';

  @override
  Set<String> supportedPlatforms(ExtensionTemplateType templateType) => switch (templateType) {
    .app => const <String>{domainErrorPlatform, crashPlatform},
    _ => const <String>{},
  };

  @override
  Future<ExtensionPlatformTemplate?> resolvePlatformTemplate({
    required String platform,
    required ExtensionTemplateType templateType,
    required Map<String, Object?> toolParameters,
  }) async {
    if (platform == domainErrorPlatform) {
      throw const ToolExtensionException('Template resolution failed.');
    }
    throw StateError('Unexpected crash during template resolution.');
  }

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platform,
    required Map<String, Object?> toolParameters,
  }) async {
    if (platform == domainErrorPlatform) {
      throw const ToolExtensionException('Template parameter generation failed.');
    }
    throw StateError('Unexpected crash during parameter generation.');
  }
}

void _failingTemplateEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[_FailingTemplateService()],
      extensionName: 'failing_template_ext',
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

    Future<(ExtensionManager, ExtensionTemplateManager)> createManagers({
      required List<ExtensionEntryPoint> entryPoints,
    }) async {
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: entryPoints);
      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        fileSystem: fs,
        flutterRoot: '/flutter',
        logger: logger,
      );
      return (manager, templateManager);
    }

    test(
      'returns empty results without initializing extensions when feature flag is disabled',
      () async {
        final manager = ExtensionManager(
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
        );
        addTearDown(manager.dispose);
        final templateManager = ExtensionTemplateManager(
          extensionManager: manager,
          featureFlags: TestFeatureFlags(),
          fileSystem: fs,
          flutterRoot: '/flutter',
          logger: logger,
        );

        for (final ExtensionTemplateType type in ExtensionTemplateType.values) {
          expect(await templateManager.getSupportedPlatforms(type), isEmpty);
          expect(templateManager.cachedPlatforms(type), isEmpty);
        }

        expect(
          await templateManager.resolvePlatformTemplate(
            platform: LinuxTemplateService.customLinuxPlatformName,
            templateType: .app,
            toolParameters: const <String, Object?>{},
          ),
          isNull,
        );

        const defaultParams = <String, Object?>{'projectName': 'my_app'};
        expect(
          await templateManager.generatePlatformTemplateParameters(
            platform: LinuxTemplateService.customLinuxPlatformName,
            toolParameters: defaultParams,
          ),
          equals(defaultParams),
        );
        expect(manager.isInitialized, isFalse);
      },
    );

    test(
      'queries supported platforms, caches results, and resolves platform templates over RPC',
      () async {
        final (_, ExtensionTemplateManager templateManager) = await createManagers(
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
        );

        final Set<String> appPlatforms = await templateManager.getSupportedPlatforms(.app);
        expect(appPlatforms, equals(const <String>{LinuxTemplateService.customLinuxPlatformName}));
        expect(templateManager.cachedPlatforms(.app), same(appPlatforms));
        expect(await templateManager.getSupportedPlatforms(.plugin), isEmpty);
        expect(await templateManager.getSupportedPlatforms(.ffiPlugin), isEmpty);

        final ExtensionPlatformTemplate? resolved = await templateManager.resolvePlatformTemplate(
          platform: LinuxTemplateService.customLinuxPlatformName,
          templateType: .app,
          toolParameters: const <String, Object?>{'projectName': 'my_app'},
        );
        expect(
          resolved,
          equals(
            ExtensionPlatformTemplate(templateUri: LinuxTemplateService.customLinuxTemplateUri),
          ),
        );

        expect(
          await templateManager.resolvePlatformTemplate(
            platform: LinuxTemplateService.customLinuxPlatformName,
            templateType: .plugin,
            toolParameters: const <String, Object?>{},
          ),
          isNull,
        );
        expect(
          await templateManager.resolvePlatformTemplate(
            platform: 'unknown_platform',
            templateType: .app,
            toolParameters: const <String, Object?>{},
          ),
          isNull,
        );
      },
    );

    test('generatePlatformTemplateParameters delegates over RPC and augments parameters', () async {
      final (_, ExtensionTemplateManager templateManager) = await createManagers(
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
      );

      const inputParams = <String, Object?>{
        'projectName': 'sample_linux_app',
        'org': 'com.example',
      };
      final Map<String, Object?> result = await templateManager.generatePlatformTemplateParameters(
        platform: LinuxTemplateService.customLinuxPlatformName,
        toolParameters: inputParams,
      );

      expect(result['projectName'], 'sample_linux_app');
      expect(result['org'], 'com.example');
      expect(result['customLinux'], isTrue);

      expect(
        await templateManager.generatePlatformTemplateParameters(
          platform: 'unknown_platform',
          toolParameters: inputParams,
        ),
        equals(inputParams),
      );
    });

    test('rejects built-in platform collisions with a warning', () async {
      final (_, ExtensionTemplateManager templateManager) = await createManagers(
        entryPoints: <ExtensionEntryPoint>[_builtInCollisionEntryPoint],
      );

      final Set<String> appPlatforms = await templateManager.getSupportedPlatforms(.app);
      expect(appPlatforms, equals(const <String>{'valid_custom'}));
      expect(
        logger.warningText,
        contains(
          'Extension "builtin_collision_ext" attempted to register app platform template '
          '"linux", which conflicts with a built-in Flutter platform.',
        ),
      );
      expect(
        await templateManager.resolvePlatformTemplate(
          platform: 'linux',
          templateType: .app,
          toolParameters: const <String, Object?>{},
        ),
        isNull,
      );
    });

    test('logs warning when duplicate platform template is encountered', () async {
      final (_, ExtensionTemplateManager templateManager) = await createManagers(
        entryPoints: <ExtensionEntryPoint>[
          linuxExtensionEntryPoint,
          _duplicateLinuxExtensionEntryPoint,
        ],
      );

      final Set<String> appPlatforms = await templateManager.getSupportedPlatforms(.app);
      expect(appPlatforms, equals(const <String>{LinuxTemplateService.customLinuxPlatformName}));
      expect(
        logger.warningText,
        contains(
          'Duplicate app platform template "custom_linux" provided by extension '
          '"duplicate_linux_extension" (already registered by extension '
          '"flutter_tools_extension_linux_prototype")',
        ),
      );
    });

    test('logs warning and preserves owner when second extension registers plugin template for same platform', () async {
      final (_, ExtensionTemplateManager templateManager) = await createManagers(
        entryPoints: <ExtensionEntryPoint>[
          linuxExtensionEntryPoint,
          _conflictingPluginLinuxExtensionEntryPoint,
        ],
      );

      expect(await templateManager.getSupportedPlatforms(.plugin), isEmpty);
      expect(
        logger.warningText,
        contains(
          'Conflicting plugin platform template "custom_linux" provided by extension '
          '"conflicting_plugin_linux_extension" (platform already registered by extension '
          '"flutter_tools_extension_linux_prototype")',
        ),
      );

      expect(
        await templateManager.getSupportedPlatforms(.app),
        equals(const <String>{LinuxTemplateService.customLinuxPlatformName}),
      );

      final Map<String, Object?> params = await templateManager.generatePlatformTemplateParameters(
        platform: LinuxTemplateService.customLinuxPlatformName,
        toolParameters: const <String, Object?>{'projectName': 'my_app'},
      );
      expect(params['customLinux'], isTrue);
      expect(params.containsKey('fromConflictingPluginExtension'), isFalse);
    });

    test(
      'allows single extension to resolve multi-variant templates across template types',
      () async {
        final (_, ExtensionTemplateManager templateManager) = await createManagers(
          entryPoints: <ExtensionEntryPoint>[_multiVariantExtensionEntryPoint],
        );

        for (final ExtensionTemplateType type in ExtensionTemplateType.values) {
          expect(
            await templateManager.getSupportedPlatforms(type),
            equals(const <String>{_MultiVariantTemplateService.platformName}),
          );
        }
        expect(logger.warningText, isEmpty);

        final ExtensionPlatformTemplate? serviceApp = await templateManager.resolvePlatformTemplate(
          platform: _MultiVariantTemplateService.platformName,
          templateType: .app,
          toolParameters: const <String, Object?>{'variant': 'service'},
        );
        expect(
          serviceApp?.templateUri,
          Uri.parse('package:multi_variant_ext/templates/app/service'),
        );

        final ExtensionPlatformTemplate? cppPlugin = await templateManager.resolvePlatformTemplate(
          platform: _MultiVariantTemplateService.platformName,
          templateType: .plugin,
          toolParameters: const <String, Object?>{'variant': 'cpp'},
        );
        expect(cppPlugin?.templateUri, Uri.parse('package:multi_variant_ext/templates/plugin/cpp'));

        final Map<String, Object?> params = await templateManager
            .generatePlatformTemplateParameters(
              platform: _MultiVariantTemplateService.platformName,
              toolParameters: const <String, Object?>{'projectName': 'my_plugin'},
            );
        expect(params['combinedExtension'], isTrue);
      },
    );

    test('RPC parameter validation throws INVALID_PARAMS on invalid or missing params', () async {
      final (ExtensionManager manager, _) = await createManagers(
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
      );
      final ExtensionConnection connection = manager.connections.first;

      final invalidCases = <(String, Map<String, Object?>)>[
        (TemplateService.resolvePlatformTemplateMethod, const <String, Object?>{}),
        (
          TemplateService.resolvePlatformTemplateMethod,
          const <String, Object?>{
            TemplateService.platformParam: 123,
            TemplateService.templateTypeParam: 'app',
            TemplateService.toolParametersParam: <String, Object?>{},
          },
        ),
        (
          TemplateService.resolvePlatformTemplateMethod,
          const <String, Object?>{
            TemplateService.platformParam: 'custom_linux',
            TemplateService.templateTypeParam: 'unknown_type',
            TemplateService.toolParametersParam: <String, Object?>{},
          },
        ),
        (
          TemplateService.resolvePlatformTemplateMethod,
          const <String, Object?>{
            TemplateService.platformParam: 'custom_linux',
            TemplateService.templateTypeParam: 'app',
            TemplateService.toolParametersParam: 'invalid',
          },
        ),
        (TemplateService.generatePlatformTemplateParametersMethod, const <String, Object?>{}),
        (
          TemplateService.generatePlatformTemplateParametersMethod,
          const <String, Object?>{
            TemplateService.platformParam: 123,
            TemplateService.toolParametersParam: <String, Object?>{},
          },
        ),
        (
          TemplateService.generatePlatformTemplateParametersMethod,
          const <String, Object?>{
            TemplateService.platformParam: 'custom_linux',
            TemplateService.toolParametersParam: 'invalid',
          },
        ),
      ];

      for (final (method, params) in invalidCases) {
        await expectLater(
          connection.sendRequest(method, params: params),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              equals(error_code.INVALID_PARAMS),
            ),
          ),
        );
      }
    });

    test('resolveTemplateDirectory resolves package URIs correctly', () {
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        fileSystem: fs,
        flutterRoot: '/flutter',
        logger: logger,
      );

      final Directory toolsDir = templateManager.resolveTemplateDirectory(
        ExtensionPlatformTemplate(templateUri: Uri.parse('package:flutter_tools/templates/app')),
      );
      expect(
        toolsDir.path,
        fs.path.join('/flutter', 'packages', 'flutter_tools', 'lib', 'templates', 'app'),
      );

      final Directory protoDir = templateManager.resolveTemplateDirectory(
        ExtensionPlatformTemplate(templateUri: LinuxTemplateService.customLinuxTemplateUri),
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
        () => templateManager.resolveTemplateDirectory(
          ExtensionPlatformTemplate(templateUri: Uri.parse('package:unknown_pkg/templates')),
        ),
        throwsArgumentError,
      );
    });

    test('surfaces resolvePlatformTemplate errors as ToolExit and falls back on unexpected parameter errors', () async {
      final (_, ExtensionTemplateManager templateManager) = await createManagers(
        entryPoints: <ExtensionEntryPoint>[_failingTemplateEntryPoint],
      );

      await expectLater(
        templateManager.resolvePlatformTemplate(
          platform: _FailingTemplateService.domainErrorPlatform,
          templateType: .app,
          toolParameters: const <String, Object?>{},
        ),
        throwsToolExit(message: 'Template resolution failed.'),
      );

      await expectLater(
        templateManager.resolvePlatformTemplate(
          platform: _FailingTemplateService.crashPlatform,
          templateType: .app,
          toolParameters: const <String, Object?>{},
        ),
        throwsToolExit(),
      );

      await expectLater(
        templateManager.generatePlatformTemplateParameters(
          platform: _FailingTemplateService.domainErrorPlatform,
          toolParameters: const <String, Object?>{'projectName': 'my_app'},
        ),
        throwsToolExit(message: 'Template parameter generation failed.'),
      );

      const inputParams = <String, Object?>{'projectName': 'my_app'};
      expect(
        await templateManager.generatePlatformTemplateParameters(
          platform: _FailingTemplateService.crashPlatform,
          toolParameters: inputParams,
        ),
        equals(inputParams),
      );
      expect(
        logger.traceText,
        contains(
          'Failed to generate platform template parameters from extension "failing_template_ext"',
        ),
      );
    });
  });
}
