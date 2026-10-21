// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_kernel_compiler.dart';
import 'package:flutter_tools/src/experimental/project_extension_finder.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void _dummyExtensionEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[]));
}

void _failingExtensionEntryPoint(SendPort sendPort) {
  // Throws during isolate initialization before handshake.
  throw StateError('Simulated isolate startup failure');
}

void _failingServiceInitEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_FailingInitService()]));
}

void _duplicateRpcEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
      _DummyService('test', 'ping'),
      _DummyService('test', 'ping'),
    ]),
  );
}

class _DummyService extends ToolExtensionService {
  _DummyService(this.namespace, this.methodName);

  @override
  final String namespace;
  final String methodName;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{methodName: (Map<String, Object?> params) => 'ok'};
  }
}

class _FailingInitService extends ToolExtensionService {
  @override
  String get namespace => 'failing';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    throw StateError('Simulated service initialize failure');
  }
}

void main() {
  group('ExtensionDiscovery & Connection Base', () {
    test('ExtensionConnection completes isolate handshake and retrieves capabilities', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );
      expect(connection.capabilities, isA<ToolExtensionCapabilities>());

      final discovery = ExtensionDiscovery(logger: logger);
      discovery.registerConnection(connection);
      expect(discovery.connections, hasLength(1));

      await discovery.dispose();
      expect(discovery.connections, isEmpty);
    });

    test('ExtensionConnection.spawn throws and cleans up on isolate startup failure', () async {
      final logger = BufferLogger.test();
      await expectLater(
        ExtensionConnection.spawn(_failingExtensionEntryPoint, logger: logger),
        throwsA(isA<StateError>()),
      );
    });

    test('ExtensionConnection.spawn throws when service initialize throws', () async {
      final logger = BufferLogger.test();
      await expectLater(
        ExtensionConnection.spawn(_failingServiceInitEntryPoint, logger: logger),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Simulated service initialize failure'),
          ),
        ),
      );
    });

    test('ExtensionConnection.spawn throws when service registers duplicate RPC method', () async {
      final logger = BufferLogger.test();
      await expectLater(
        ExtensionConnection.spawn(_duplicateRpcEntryPoint, logger: logger),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Duplicate RPC method registered: "test.ping"'),
          ),
        ),
      );
    });

    test('ExtensionDiscovery registers multiple connections and disposes them', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection1 = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );
      final ExtensionConnection connection2 = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );

      final discovery = ExtensionDiscovery(logger: logger);
      discovery.registerConnections(<ExtensionConnection>[connection1, connection2]);

      expect(discovery.connections, hasLength(2));
      await discovery.dispose();
      expect(discovery.connections, isEmpty);
    });

    test(
      'ToolExtensionCapabilities.fromJson eagerly deserializes lists and normalizes platforms',
      () {
        final capabilities = ToolExtensionCapabilities.fromJson(const <String, Object?>{
          'services': <Object?>['diagnostics', 'config'],
          'supportedPlatforms': <Object?>['Linux', 'MacOS'],
        });

        expect(capabilities.services, const <String>['diagnostics', 'config']);
        expect(capabilities.supportedPlatforms, const <String>{'linux', 'macos'});
        expect(capabilities.supportsHostPlatform('LINUX'), isTrue);
        expect(capabilities.supportsHostPlatform('windows'), isFalse);

        final defaultPlatformsCapabilities = ToolExtensionCapabilities.fromJson(
          const <String, Object?>{
            'services': <Object?>['diagnostics'],
          },
        );
        expect(defaultPlatformsCapabilities.supportedPlatforms, isEmpty);
      },
    );

    test('ToolExtensionCapabilities.fromJson throws FormatException on invalid field types', () {
      expect(
        () => ToolExtensionCapabilities.fromJson(const <String, Object?>{
          ToolExtensionCapabilities.extensionNameKey: 42,
        }),
        throwsFormatException,
      );
      expect(
        () => ToolExtensionCapabilities.fromJson(const <String, Object?>{
          ToolExtensionCapabilities.servicesKey: 'not-a-list',
        }),
        throwsFormatException,
      );
      expect(
        () => ToolExtensionCapabilities.fromJson(const <String, Object?>{
          ToolExtensionCapabilities.supportedPlatformsKey: <Object?>[123],
        }),
        throwsFormatException,
      );
    });

    test('ToolExtensionEntryPoint.run rejects duplicate RPC method registration', () async {
      final service1 = _DummyService('test', 'ping');
      final service2 = _DummyService('test', 'ping');

      final receivePort = ReceivePort();
      addTearDown(receivePort.close);
      final messages = <Object?>[];
      final StreamSubscription<Object?> subscription = receivePort.listen(messages.add);
      addTearDown(subscription.cancel);

      await expectLater(
        ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
          service1,
          service2,
        ]),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Duplicate RPC method registered: "test.ping"'),
          ),
        ),
      );
      await pumpEventQueue();
      expect(messages, isEmpty);

      await expectLater(
        ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
          _DummyService('extension', 'getCapabilities'),
        ]),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Reserved RPC method registered: "extension.getCapabilities"'),
          ),
        ),
      );
      await pumpEventQueue();
      expect(messages, isEmpty);
    });

    test('ToolExtensionEntryPoint.runMain validates SendPort message and runs', () async {
      await expectLater(
        ToolExtensionEntryPoint.runMain(
          const <String>[],
          'not-a-send-port',
          _dummyExtensionEntryPoint,
        ),
        throwsArgumentError,
      );

      SendPort? receivedPort;
      final receivePort = ReceivePort();
      addTearDown(receivePort.close);

      await ToolExtensionEntryPoint.runMain(const <String>[], receivePort.sendPort, (
        SendPort sendPort,
      ) {
        receivedPort = sendPort;
      });
      expect(receivedPort, equals(receivePort.sendPort));
    });

    test('ExtensionConnection.spawnUri spawns extension script and completes handshake', () async {
      final logger = BufferLogger.test();
      final Uri? libUri = await Isolate.resolvePackageUri(
        Uri.parse(
          'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart',
        ),
      );
      expect(libUri, isNotNull);
      final Uri entrypointUri = libUri!.resolve(
        '../bin/flutter_tools_extension_linux_prototype.dart',
      );
      final Uri? packageConfigUri = await Isolate.packageConfig;
      expect(packageConfigUri, isNotNull);

      final ExtensionConnection connection = await ExtensionConnection.spawnUri(
        entrypointUri,
        logger: logger,
        packageConfigUri: packageConfigUri!,
        extensionName: 'flutter_tools_extension_linux_prototype',
      );
      addTearDown(connection.dispose);

      expect(connection.extensionName, 'flutter_tools_extension_linux_prototype');
      expect(
        connection.capabilities.services,
        containsAll(const <String>['diagnostics', 'config', 'build', 'template']),
      );
    });
  });

  group('ProjectExtensionFinder', () {
    testWithoutContext(
      'returns empty list before package_config.json creation and succeeds after',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dev_dependencies:
  my_ext:
    path: ../my_ext
''');
        final Directory extDir = fs.directory('/workspace/my_ext')..createSync(recursive: true);
        extDir.childFile('extension/flutter_tools/config.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: my_ext
protocol_version: 1
supported_platforms:
  - linux
services:
  - build
build_targets:
  - custom-linux
''');
        extDir.childFile('bin/my_ext.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main(List<String> args, Object? message) {}');

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: logger);

        // Before pub get (.dart_tool/package_config.json does not exist yet).
        final List<DiscoveredProjectExtension> beforePubGet = await finder.findProjectExtensions(
          startDirectory: projectDir,
        );
        expect(beforePubGet, isEmpty);

        // Create .dart_tool/package_config.json (simulating pub get).
        projectDir.childFile('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'configVersion': 2,
              'packages': <Map<String, Object?>>[
                <String, Object?>{'name': 'app', 'rootUri': '../', 'packageUri': 'lib/'},
                <String, Object?>{
                  'name': 'my_ext',
                  'rootUri': '../../my_ext',
                  'packageUri': 'lib/',
                },
              ],
            }),
          );

        final List<DiscoveredProjectExtension> afterPubGet = await finder.findProjectExtensions(
          startDirectory: projectDir,
        );
        expect(afterPubGet, hasLength(1));
        expect(afterPubGet.single.name, 'my_ext');
        expect(afterPubGet.single.config.services, const <String>{'build'});
        expect(afterPubGet.single.config.buildTargets, const <String>{'custom-linux'});
      },
    );

    testWithoutContext(
      'filters out transitive extensions not listed in direct dependencies or dev_dependencies',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dependencies:
  direct_ext: ^1.0.0
''');

        for (final extName in <String>['direct_ext', 'transitive_ext']) {
          final Directory extDir = fs.directory('/workspace/$extName')..createSync(recursive: true);
          extDir.childFile('extension/flutter_tools/config.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: $extName
services:
  - diagnostics
''');
          extDir.childFile('bin/$extName.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('void main(List<String> args, Object? message) {}');
        }

        projectDir.childFile('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'configVersion': 2,
              'packages': <Map<String, Object?>>[
                <String, Object?>{'name': 'app', 'rootUri': '../', 'packageUri': 'lib/'},
                <String, Object?>{
                  'name': 'direct_ext',
                  'rootUri': '../../direct_ext',
                  'packageUri': 'lib/',
                },
                <String, Object?>{
                  'name': 'transitive_ext',
                  'rootUri': '../../transitive_ext',
                  'packageUri': 'lib/',
                },
              ],
            }),
          );

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: logger);
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: projectDir,
        );

        expect(discovered.map((DiscoveredProjectExtension e) => e.name), const <String>[
          'direct_ext',
        ]);
        expect(
          logger.traceText,
          contains('ignoring transitive extension package "transitive_ext"'),
        );
      },
    );

    testWithoutContext(
      'includes direct dependencies from Pub workspace root pubspec.yaml',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory workspaceRoot = fs.directory('/workspace')..createSync(recursive: true);
        workspaceRoot.childFile('pubspec.yaml').writeAsStringSync('''
name: my_workspace
workspace:
  - packages/app
dev_dependencies:
  workspace_ext:
    path: packages/workspace_ext
''');
        final Directory appDir = workspaceRoot.childDirectory('packages/app')
          ..createSync(recursive: true);
        appDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
resolution: workspace
''');
        final Directory extDir = workspaceRoot.childDirectory('packages/workspace_ext')
          ..createSync(recursive: true);
        extDir.childFile('extension/flutter_tools/config.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: workspace_ext
platforms:
  - custom_linux
services:
  - template
''');
        extDir.childFile('bin/workspace_ext.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main(List<String> args, Object? message) {}');

        workspaceRoot.childFile('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'configVersion': 2,
              'packages': <Map<String, Object?>>[
                <String, Object?>{
                  'name': 'app',
                  'rootUri': '../packages/app',
                  'packageUri': 'lib/',
                },
                <String, Object?>{
                  'name': 'workspace_ext',
                  'rootUri': '../packages/workspace_ext',
                  'packageUri': 'lib/',
                },
              ],
            }),
          );

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: logger);
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: appDir,
        );

        expect(discovered, hasLength(1));
        expect(discovered.single.name, 'workspace_ext');
        expect(discovered.single.config.platforms, const <String>{'custom_linux'});
      },
    );

    testWithoutContext(
      'discovers extensions via package:extension_discovery on LocalFileSystem',
      () async {
        final localFs = LocalFileSystem.test(signals: LocalSignals.instance);
        final Directory tempDir = localFs.systemTempDirectory.createTempSync('ext_finder_local.');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final logger = BufferLogger.test();
        final Directory projectDir = tempDir.childDirectory('app')..createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dependencies:
  local_ext:
    path: ../local_ext
''');
        final Directory extDir = tempDir.childDirectory('local_ext')..createSync(recursive: true);
        extDir.childFile('extension/flutter_tools/config.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: local_ext
services:
  - diagnostics
''');
        extDir.childFile('bin/local_ext.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main(List<String> args, Object? message) {}');

        projectDir.childFile('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'configVersion': 2,
              'packages': <Map<String, Object?>>[
                <String, Object?>{'name': 'app', 'rootUri': '../', 'packageUri': 'lib/'},
                <String, Object?>{
                  'name': 'local_ext',
                  'rootUri': '../../local_ext',
                  'packageUri': 'lib/',
                },
              ],
            }),
          );

        final finder = ProjectExtensionFinder(fileSystem: localFs, logger: logger);
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: projectDir,
        );

        expect(discovered, hasLength(1));
        expect(discovered.single.name, 'local_ext');
        expect(discovered.single.config.services, const <String>{'diagnostics'});
      },
    );
  });

  group('ExtensionKernelCompiler', () {
    testWithoutContext('compiles local extension to .dill and invalidates via depfile', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final artifacts = Artifacts.test(fileSystem: fs);
      final String dartBinary = artifacts.getArtifactPath(Artifact.engineDartBinary);

      final Directory sdkDir = fs.directory('/flutter/bin/cache/dart-sdk')
        ..createSync(recursive: true);
      final File sdkVersionFile = sdkDir.childFile('version')
        ..writeAsStringSync('3.13.0-0.0.pre\n');
      sdkVersionFile.setLastModifiedSync(DateTime.utc(2026));

      final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
      final File packageConfigFile = projectDir.childFile('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"configVersion":2,"packages":[]}');
      packageConfigFile.setLastModifiedSync(DateTime.utc(2026));

      final Directory extDir = fs.directory('/workspace/my_ext')..createSync(recursive: true);
      final File entrypointFile = extDir.childFile('bin/my_ext.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('import "package:my_ext/helper.dart"; void main() {}');
      entrypointFile.setLastModifiedSync(DateTime.utc(2026));
      final File helperFile = extDir.childFile('lib/helper.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('const int version = 1;');
      helperFile.setLastModifiedSync(DateTime.utc(2026));

      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      const expectedDepfilePath = '$expectedDillPath.d';
      const expectedTempDillPath = '$expectedDillPath.tmp';
      const expectedTempDepfilePath = '$expectedDepfilePath.tmp';

      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            dartBinary,
            'compile',
            'kernel',
            '--packages=${packageConfigFile.path}',
            '--output=$expectedTempDillPath',
            '--depfile=$expectedTempDepfilePath',
            entrypointFile.path,
          ],
          onRun: (_) {
            final File dill = fs.file(expectedTempDillPath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(<int>[1, 2, 3]);
            dill.setLastModifiedSync(DateTime.utc(2026, 1, 1, 1));
            fs.file(expectedTempDepfilePath)
              ..createSync(recursive: true)
              ..writeAsStringSync(
                '$expectedTempDillPath: ${entrypointFile.path} ${helperFile.path}\n',
              );
          },
        ),
        FakeCommand(
          command: <String>[
            dartBinary,
            'compile',
            'kernel',
            '--packages=${packageConfigFile.path}',
            '--output=$expectedTempDillPath',
            '--depfile=$expectedTempDepfilePath',
            entrypointFile.path,
          ],
          onRun: (_) {
            final File dill = fs.file(expectedTempDillPath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(<int>[4, 5, 6]);
            dill.setLastModifiedSync(DateTime.utc(2026, 1, 1, 3));
          },
        ),
      ]);

      final compiler = ExtensionKernelCompiler(
        artifacts: artifacts,
        fileSystem: fs,
        flutterRoot: fs.directory('/flutter'),
        logger: logger,
        platform: FakePlatform(environment: const <String, String>{'HOME': '/home/test'}),
        processManager: processManager,
      );

      final extension = DiscoveredProjectExtension(
        name: 'my_ext',
        rootUri: Uri.directory(extDir.path),
        packageUri: Uri.directory(extDir.childDirectory('lib').path),
        packageConfigUri: packageConfigFile.uri,
        workspaceRootPath: projectDir.path,
        config: ExtensionPackageConfig(name: 'my_ext'),
      );

      // 1. Initial compilation runs `dart compile kernel`.
      final Uri firstDillUri = await compiler.compile(extension);
      expect(firstDillUri, fs.file(expectedDillPath).uri);

      // 2. Second compilation hits the cache without invoking `dart compile kernel`.
      final Uri cachedDillUri = await compiler.compile(extension);
      expect(fs.file(cachedDillUri).readAsBytesSync(), const <int>[1, 2, 3]);

      // 3. Touching a transitive file listed in extension.dill.d invalidates the cache.
      helperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
      final Uri recompiledDillUri = await compiler.compile(extension);
      expect(fs.file(recompiledDillUri).readAsBytesSync(), const <int>[4, 5, 6]);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'caches immutable PUB_CACHE extension under DART_DATA_HOME/flutter_tool_extensions/cache',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final artifacts = Artifacts.test(fileSystem: fs);
        final String dartBinary = artifacts.getArtifactPath(Artifact.engineDartBinary);

        fs.file('/flutter/bin/cache/dart-sdk/version')
          ..createSync(recursive: true)
          ..writeAsStringSync('3.13.0\n');

        final File packageConfigFile = fs.file('/workspace/app/.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"configVersion":2,"packages":[]}');
        final Directory pubCacheExtDir = fs.directory(
          '/home/test/.pub-cache/hosted/pub.dev/hosted_ext-1.2.3',
        )..createSync(recursive: true);
        final File entrypointFile = pubCacheExtDir.childFile('bin/hosted_ext.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}');

        final extension = DiscoveredProjectExtension(
          name: 'hosted_ext',
          rootUri: Uri.directory(pubCacheExtDir.path),
          packageUri: Uri.directory(pubCacheExtDir.childDirectory('lib').path),
          packageConfigUri: packageConfigFile.uri,
          workspaceRootPath: '/workspace/app',
          config: ExtensionPackageConfig(name: 'hosted_ext'),
        );

        final processManager = FakeProcessManager.empty();
        final compiler = ExtensionKernelCompiler(
          artifacts: artifacts,
          fileSystem: fs,
          flutterRoot: fs.directory('/flutter'),
          logger: logger,
          platform: FakePlatform(
            environment: const <String, String>{
              'HOME': '/home/test',
              'PUB_CACHE': '/home/test/.pub-cache',
              'DART_DATA_HOME': '/custom_data',
            },
          ),
          processManager: processManager,
        );

        final File targetDill = compiler.resolveDillFile(extension);
        expect(
          targetDill.path,
          startsWith('/custom_data/flutter_tool_extensions/cache/hosted_ext-3.13.0-'),
        );

        var compileInvocations = 0;
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              dartBinary,
              'compile',
              'kernel',
              '--packages=${packageConfigFile.path}',
              '--output=${targetDill.path}.tmp',
              '--depfile=${targetDill.path}.d.tmp',
              entrypointFile.path,
            ],
            onRun: (_) {
              compileInvocations++;
              fs.file('${targetDill.path}.tmp')
                ..createSync(recursive: true)
                ..writeAsBytesSync(<int>[9, 9, 9]);
            },
          ),
        );

        final Uri dill1 = await compiler.compile(extension);
        expect(dill1, targetDill.uri);
        expect(fs.file('${targetDill.path}.lock').existsSync(), isTrue);
        expect(fs.file('${targetDill.path}.tmp').existsSync(), isFalse);
        final Uri dill2 = await compiler.compile(extension);
        expect(dill2, targetDill.uri);
        expect(compileInvocations, 1);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'cleans up temporary files and throws ExtensionCompileException on failure',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final artifacts = Artifacts.test(fileSystem: fs);
        final String dartBinary = artifacts.getArtifactPath(Artifact.engineDartBinary);

        final File packageConfigFile = fs.file('/workspace/app/.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"configVersion":2,"packages":[]}');
        final Directory extDir = fs.directory('/workspace/my_ext')..createSync(recursive: true);
        final File entrypointFile = extDir.childFile('bin/my_ext.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}');

        const expectedDillPath =
            '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
        const expectedDepfilePath = '$expectedDillPath.d';

        final processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: <String>[
              dartBinary,
              'compile',
              'kernel',
              '--packages=${packageConfigFile.path}',
              '--output=$expectedDillPath.tmp',
              '--depfile=$expectedDepfilePath.tmp',
              entrypointFile.path,
            ],
            exitCode: 254,
            stderr: 'Compilation error',
            onRun: (_) {
              fs.file('$expectedDillPath.tmp')
                ..createSync(recursive: true)
                ..writeAsBytesSync(<int>[0]);
              fs.file('$expectedDepfilePath.tmp')
                ..createSync(recursive: true)
                ..writeAsStringSync('partial');
            },
          ),
        ]);

        final compiler = ExtensionKernelCompiler(
          artifacts: artifacts,
          fileSystem: fs,
          flutterRoot: fs.directory('/flutter'),
          logger: logger,
          platform: FakePlatform(environment: const <String, String>{'HOME': '/home/test'}),
          processManager: processManager,
        );

        final extension = DiscoveredProjectExtension(
          name: 'my_ext',
          rootUri: Uri.directory(extDir.path),
          packageUri: Uri.directory(extDir.childDirectory('lib').path),
          packageConfigUri: packageConfigFile.uri,
          workspaceRootPath: '/workspace/app',
          config: ExtensionPackageConfig(name: 'my_ext'),
        );

        await expectLater(compiler.compile(extension), throwsA(isA<ExtensionCompileException>()));
        expect(fs.file(expectedDillPath).existsSync(), isFalse);
        expect(fs.file('$expectedDillPath.tmp').existsSync(), isFalse);
        expect(fs.file('$expectedDepfilePath.tmp').existsSync(), isFalse);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'parseDepfileDependencies handles escaped spaces, line continuations, and Windows paths',
      () {
        const depfileContent =
            r'C:\path\to\extension.dill.tmp: '
            'C:\\path\\ with\\ spaces\\main.dart \\\r\n'
            '  /workspace/lib/part\\ one.dart \\\n'
            '  /workspace/lib/part_two.dart\n';

        final List<String> parsed = ExtensionKernelCompiler.parseDepfileDependencies(
          depfileContent,
        );
        expect(parsed, const <String>[
          r'C:\path with spaces\main.dart',
          '/workspace/lib/part one.dart',
          '/workspace/lib/part_two.dart',
        ]);
      },
    );
  });
}
