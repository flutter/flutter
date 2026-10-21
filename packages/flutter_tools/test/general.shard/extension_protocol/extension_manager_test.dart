// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_kernel_compiler.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/experimental/project_extension_finder.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void _dummyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[]);
}

void _linuxOnlyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[],
    supportedPlatforms: const <String>{'linux'},
  );
}

class _FakeExtensionKernelCompiler extends Fake implements ExtensionKernelCompiler {
  _FakeExtensionKernelCompiler(this._onCompile);

  final Future<Uri> Function(DiscoveredProjectExtension extension) _onCompile;

  @override
  Future<Uri> compile(DiscoveredProjectExtension extension) => _onCompile(extension);
}

class _FakeExtensionConnection extends Fake implements ExtensionConnection {
  _FakeExtensionConnection({required this.capabilities, String? extensionName})
    : extensionName = extensionName ?? ExtensionConnection.defaultExtensionName;

  @override
  final ToolExtensionCapabilities capabilities;

  @override
  final String extensionName;

  bool _disposed = false;

  @override
  bool get isDisposed => _disposed;

  @override
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = const Duration(seconds: 5),
  }) async => null;

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}

void main() {
  group('ExtensionManager Integration', () {
    testWithoutContext('ExtensionManager loads extension compatible with hostPlatform', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_dummyExtensionEntryPoint]);

      expect(manager.connections, hasLength(1));
      await manager.dispose();
      expect(manager.connections, isEmpty);
    });

    testWithoutContext(
      'ExtensionManager filters out extension incompatible with hostPlatform',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.darwin_arm64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[_linuxOnlyExtensionEntryPoint]);

        expect(manager.connections, isEmpty);
        await manager.dispose();
      },
    );

    testWithoutContext(
      'ensureInitialized(requiredServices: ...) only compiles and spawns matching extensions',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
        fs.currentDirectory = projectDir;

        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dev_dependencies:
  diag_ext:
    path: ../diag_ext
  build_ext:
    path: ../build_ext
''');

        final Directory diagExtDir = fs.directory('/workspace/diag_ext')
          ..createSync(recursive: true);
        diagExtDir.childFile('extension/flutter_tools/config.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: diag_ext
supported_platforms:
  - linux
services:
  - diagnostics
''');
        diagExtDir.childFile('bin/diag_ext.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}');

        final Directory buildExtDir = fs.directory('/workspace/build_ext')
          ..createSync(recursive: true);
        buildExtDir.childFile('extension/flutter_tools/config.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: build_ext
supported_platforms:
  - linux
services:
  - build
build_targets:
  - custom-linux
''');
        buildExtDir.childFile('bin/build_ext.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}');

        projectDir.childFile('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'configVersion': 2,
              'packages': <Map<String, Object?>>[
                <String, Object?>{'name': 'app', 'rootUri': '../', 'packageUri': 'lib/'},
                <String, Object?>{
                  'name': 'diag_ext',
                  'rootUri': '../../diag_ext',
                  'packageUri': 'lib/',
                },
                <String, Object?>{
                  'name': 'build_ext',
                  'rootUri': '../../build_ext',
                  'packageUri': 'lib/',
                },
              ],
            }),
          );

        final compiledExtensions = <String>[];
        final spawnedExtensions = <String>[];

        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          extensionFinder: ProjectExtensionFinder(fileSystem: fs, logger: logger),
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          kernelCompiler: _FakeExtensionKernelCompiler((DiscoveredProjectExtension ext) async {
            compiledExtensions.add(ext.name);
            return Uri.file('/cache/${ext.name}.dill');
          }),
          uriSpawner:
              (
                Uri entrypointUri, {
                required Logger logger,
                required Uri packageConfigUri,
                String? extensionName,
              }) async {
                spawnedExtensions.add(extensionName ?? entrypointUri.toString());
                return _FakeExtensionConnection(
                  capabilities: ToolExtensionCapabilities(
                    services: <String>[if (extensionName == 'diag_ext') 'diagnostics' else 'build'],
                    supportedPlatforms: const <String>{'linux'},
                  ),
                  extensionName: extensionName,
                );
              },
        );

        // 1. Static discovery does not compile or spawn any extension.
        final List<DiscoveredProjectExtension> discovered = await manager.discoverExtensions();
        expect(discovered, hasLength(2));
        expect(compiledExtensions, isEmpty);
        expect(spawnedExtensions, isEmpty);

        // 2. Requesting 'diagnostics' only compiles and spawns 'diag_ext'.
        await manager.ensureInitialized(requiredServices: const <String>{'diagnostics'});
        expect(compiledExtensions, const <String>['diag_ext']);
        expect(spawnedExtensions, const <String>['diag_ext']);
        expect(manager.diagnosticsExtensions, hasLength(1));

        // 3. Requesting 'build' subsequently compiles and spawns 'build_ext' without respawning 'diag_ext'.
        await manager.ensureInitialized(requiredServices: const <String>{'build'});
        expect(compiledExtensions, const <String>['diag_ext', 'build_ext']);
        expect(spawnedExtensions, const <String>['diag_ext', 'build_ext']);
        expect(manager.connections, hasLength(2));

        await manager.dispose();
      },
    );

    testWithoutContext(
      'ensureInitialized skips spawning when tool extensions are disabled',
      () async {
        final logger = BufferLogger.test();
        var spawned = false;

        final disabledManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(),
          entryPoints: <ExtensionEntryPoint>[
            (SendPort sendPort) {
              spawned = true;
              _dummyExtensionEntryPoint(sendPort);
            },
          ],
        );

        await disabledManager.ensureInitialized();
        expect(spawned, isFalse);
        expect(disabledManager.connections, isEmpty);
        await disabledManager.dispose();
      },
    );

    testWithoutContext(
      'disable throws AssertionError when called after initialization has started',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.ensureInitialized();
        expect(() => manager.disable(), throwsA(isA<AssertionError>()));
        await manager.dispose();
      },
    );
  });
}
