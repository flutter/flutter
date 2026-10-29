// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/experimental/templates.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/test.dart';

import '../../src/fakes.dart';

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

    test('returns empty templates when tool extensions feature flag is disabled', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(),
      );
      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        fileSystem: fs,
        logger: logger,
        featureFlags: TestFeatureFlags(),
      );

      final List<ProjectTemplate> templates = await templateManager.getProjectTemplates();
      expect(templates, isEmpty);
      expect(templateManager.cachedTemplates, isEmpty);
      expect(templateManager.projectTemplates, isEmpty);

      final defaultParams = <String, Object?>{'projectName': 'my_app'};
      final Map<String, Object?> generatedParams = await templateManager.generateTemplateParameters(
        'custom-linux-app',
        defaultParams,
      );
      expect(generatedParams, equals(defaultParams));

      await manager.dispose();
    });

    test('queries project templates over RPC and caches results', () async {
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

      final List<ProjectTemplate> templates = await templateManager.getProjectTemplates();
      expect(templates, hasLength(1));
      final ProjectTemplate template = templates.first;
      expect(template.name, 'custom-linux-app');
      expect(template.hidden, isFalse);
      expect(template.templateDependencies, <String>{'app'});
      expect(template.templateSources, contains('pubspec.yaml.tmpl'));
      expect(templateManager.cachedTemplates, equals(templates));
      expect(templateManager.projectTemplates, equals(templates.toSet()));

      // Subsequent call returns cached list directly.
      final List<ProjectTemplate> cachedCall = await templateManager.getProjectTemplates();
      expect(identical(cachedCall, templates), isTrue);

      await manager.dispose();
    });

    test('generateTemplateParameters delegates over RPC', () async {
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
      final Map<String, Object?> result = await templateManager.generateTemplateParameters(
        'custom-linux-app',
        inputParams,
      );

      expect(result['projectName'], 'sample_linux_app');
      expect(result['org'], 'com.example');

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
