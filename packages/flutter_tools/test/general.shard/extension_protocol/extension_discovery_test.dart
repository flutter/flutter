// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:dart_data_home/dart_data_home.dart';
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
import 'package:yaml/yaml.dart';

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

class _NotificationTestService extends ToolExtensionService {
  @override
  String get namespace => 'notify';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'emitCustom': (Map<String, Object?> params) {
        sendNotification('notify.customEvent', <String, Object?>{'payload': params['payload']});
        return 'emitted';
      },
    };
  }
}

void _notificationExtensionEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_NotificationTestService()]),
  );
}

class _ExitingService extends ToolExtensionService {
  @override
  String get namespace => 'exit';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'triggerExit': (Map<String, Object?> _) {
        Isolate.exit();
      },
    };
  }
}

void _exitingExtensionEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_ExitingService()]));
}

class _AsyncErrorService extends ToolExtensionService {
  @override
  String get namespace => 'error';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'triggerUnhandledError': (Map<String, Object?> _) {
        Timer.run(() {
          throw StateError('Simulated unhandled async error');
        });
        return Completer<Object?>().future;
      },
    };
  }
}

void _asyncErrorExtensionEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_AsyncErrorService()]));
}

MemoryFileSystem _hostStyleMemoryFs() => MemoryFileSystem.test(
  style: const LocalPlatform().isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
);

void _writeExtensionPackage(
  Directory extDir, {
  required String name,
  String? configYaml,
  String entrypointBody = 'void main(List<String> args, Object? message) {}',
}) {
  extDir.childFile('extension/flutter_tools/config.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      configYaml ??
          '''
name: $name
services:
  - diagnostics
''',
    );
  extDir.childFile('bin/$name.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(entrypointBody);
}

File _writePackageConfig(
  Directory rootDir, [
  Map<String, String> packageRoots = const <String, String>{},
]) {
  return rootDir.childFile('.dart_tool/package_config.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode(<String, Object?>{
        'configVersion': 2,
        'packages': <Map<String, Object?>>[
          for (final MapEntry(:String key, :String value) in packageRoots.entries)
            <String, Object?>{'name': key, 'rootUri': value, 'packageUri': 'lib/'},
        ],
      }),
    );
}

DiscoveredProjectExtension _discoveredExtension(
  FileSystem fs, {
  String name = 'my_ext',
  String rootPath = '/workspace/my_ext',
  String workspaceRootPath = '/workspace/app',
}) {
  final Directory dir = fs.directory(rootPath);
  return DiscoveredProjectExtension(
    name: name,
    rootUri: dir.uri,
    packageUri: dir.childDirectory('lib').uri,
    packageConfigUri: fs
        .file(fs.path.join(workspaceRootPath, '.dart_tool', 'package_config.json'))
        .uri,
    workspaceRootPath: workspaceRootPath,
    config: ExtensionPackageConfig(name: name, services: const <String>['diagnostics']),
  );
}

ExtensionKernelCompiler _createCompiler(
  FileSystem fs, {
  Map<String, String> environment = const <String, String>{'HOME': '/home/test'},
  String flutterRootPath = '/flutter',
  Logger? logger,
  String operatingSystem = 'linux',
  ProcessManager? processManager,
}) {
  return ExtensionKernelCompiler(
    artifacts: Artifacts.test(fileSystem: fs),
    fileSystem: fs,
    flutterRoot: fs.directory(flutterRootPath),
    logger: logger ?? BufferLogger.test(),
    platform: FakePlatform(operatingSystem: operatingSystem, environment: environment),
    processManager: processManager ?? FakeProcessManager.empty(),
  );
}

FakeCommand _compileKernelCommand(
  FileSystem fs, {
  required String entrypointPath,
  required String outputDillPath,
  List<int> bytes = const <int>[1, 2, 3],
  String? depfileContent,
  int exitCode = 0,
  DateTime? modified,
  void Function()? onRunExtra,
  String packageConfigPath = '/workspace/app/.dart_tool/package_config.json',
  String stderr = '',
}) {
  final String dartBinary = Artifacts.test(fileSystem: fs)
      .getArtifactPath(Artifact.engineDartBinary);
  final tempDillPath = '$outputDillPath.tmp';
  final tempDepfilePath = '$outputDillPath.d.tmp';
  return FakeCommand(
    command: <String>[
      dartBinary,
      'compile',
      'kernel',
      '--packages=$packageConfigPath',
      '--output=$tempDillPath',
      '--depfile=$tempDepfilePath',
      entrypointPath,
    ],
    exitCode: exitCode,
    stderr: stderr,
    onRun: (_) {
      final File dill = fs.file(tempDillPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
      if (modified != null) {
        dill.setLastModifiedSync(modified);
      }
      if (depfileContent != null) {
        fs.file(tempDepfilePath)
          ..createSync(recursive: true)
          ..writeAsStringSync(depfileContent);
      }
      onRunExtra?.call();
    },
  );
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

    test('ToolExtensionEntryPoint.run validates SendPort message', () async {
      await expectLater(
        ToolExtensionEntryPoint.run('not-a-send-port', <ToolExtensionService>[]),
        throwsArgumentError,
      );
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

      final fs = LocalFileSystem.test(signals: LocalSignals.instance);
      addTearDown(fs.dispose);
      final Uri configUri = libUri.resolve('../extension/flutter_tools/config.yaml');
      final rawYaml = loadYaml(fs.file(configUri).readAsStringSync()) as YamlMap;
      final expectedConfig = ExtensionPackageConfig.fromMap(
        rawYaml.cast<String, Object?>(),
        packageName: 'flutter_tools_extension_linux_prototype',
      );

      final ExtensionConnection connection = await ExtensionConnection.spawnUri(
        entrypointUri,
        expectedConfig: expectedConfig,
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

    test('ExtensionConnection.spawnUri throws StateError when expectedConfig does not match capabilities', () async {
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

      await expectLater(
        ExtensionConnection.spawnUri(
          entrypointUri,
          expectedConfig: ExtensionPackageConfig(
            name: 'flutter_tools_extension_linux_prototype',
            hostPlatforms: const <String>{'linux'},
            services: const <String>{'diagnostics'},
          ),
          logger: logger,
          packageConfigUri: packageConfigUri!,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains(
              'capabilities mismatch: extension/flutter_tools/config.yaml declares services',
            ),
          ),
        ),
      );

      await expectLater(
        ExtensionConnection.spawnUri(
          entrypointUri,
          expectedConfig: ExtensionPackageConfig(
            name: 'flutter_tools_extension_linux_prototype',
            hostPlatforms: const <String>{'macos'},
            services: const <String>{
              'diagnostics',
              'config',
              'template',
              'device',
              'build',
              'clean',
            },
          ),
          logger: logger,
          packageConfigUri: packageConfigUri,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains(
              'capabilities mismatch: extension/flutter_tools/config.yaml declares host_platforms',
            ),
          ),
        ),
      );
    });

    test('ToolExtensionService.sendNotification throws StateError before peer attachment', () {
      final service = _DummyService('test', 'ping');
      expect(
        () => service.sendNotification('test.event', const <String, Object?>{}),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('is not attached to an active peer'),
          ),
        ),
      );
    });

    test('sendNotification and onNotification deliver notifications round-trip', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _notificationExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      final receivedEvents = <Map<String, Object?>>[];
      final StreamSubscription<Map<String, Object?>> subscription = connection
          .onNotification('notify.customEvent')
          .listen(receivedEvents.add);
      addTearDown(subscription.cancel);

      final Object? response = await connection.sendRequest(
        'notify.emitCustom',
        params: const <String, Object?>{'payload': 'hello-host'},
      );
      expect(response, 'emitted');

      await pumpEventQueue();
      expect(receivedEvents, <Map<String, Object?>>[
        const <String, Object?>{'payload': 'hello-host'},
      ]);
    });

    test('onNotification supports multiple listeners on broadcast stream', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _notificationExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      final listener1Events = <Map<String, Object?>>[];
      final listener2Events = <Map<String, Object?>>[];

      final Stream<Map<String, Object?>> stream = connection.onNotification('notify.customEvent');
      final StreamSubscription<Map<String, Object?>> sub1 = stream.listen(listener1Events.add);
      final StreamSubscription<Map<String, Object?>> sub2 = stream.listen(listener2Events.add);
      addTearDown(sub1.cancel);
      addTearDown(sub2.cancel);

      await connection.sendRequest(
        'notify.emitCustom',
        params: const <String, Object?>{'payload': 'broadcast'},
      );

      await pumpEventQueue();
      expect(listener1Events, <Map<String, Object?>>[
        const <String, Object?>{'payload': 'broadcast'},
      ]);
      expect(listener2Events, <Map<String, Object?>>[
        const <String, Object?>{'payload': 'broadcast'},
      ]);
    });

    test('onNotification throws StateError after dispose', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );
      await connection.dispose();

      expect(
        () => connection.onNotification('notify.customEvent'),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('ExtensionConnection has been disposed.'),
          ),
        ),
      );
    });

    test(
      'sendRequest with timeout: null completes with StateError when isolate exits unexpectedly',
      () async {
        final logger = BufferLogger.test();
        final ExtensionConnection connection = await ExtensionConnection.spawn(
          _exitingExtensionEntryPoint,
          logger: logger,
        );
        addTearDown(connection.dispose);

        final Stream<Map<String, Object?>> notificationStream = connection.onNotification(
          'notify.customEvent',
        );
        final Future<void> streamDone = expectLater(notificationStream, emitsDone);

        await expectLater(
          connection.sendRequest('exit.triggerExit', timeout: null),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              contains('The client closed with pending request "exit.triggerExit"'),
            ),
          ),
        );
        await streamDone;
      },
    );

    test('sendRequest with timeout: null completes with StateError when isolate throws unhandled async error', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _asyncErrorExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      await expectLater(
        connection.sendRequest('error.triggerUnhandledError', timeout: null),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('The client closed with pending request "error.triggerUnhandledError"'),
          ),
        ),
      );
      expect(logger.errorText, contains('Simulated unhandled async error'));
    });
  });

  group('ProjectExtensionFinder', () {
    testWithoutContext(
      'returns empty list before package_config.json creation and succeeds after',
      () async {
        final fs = MemoryFileSystem.test();
        final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dev_dependencies:
  my_ext:
    path: ../my_ext
''');
        _writeExtensionPackage(
          fs.directory('/workspace/my_ext'),
          name: 'my_ext',
          configYaml: '''
name: my_ext
host_platforms:
  - linux
services:
  - build
build_targets:
  - custom-linux
''',
        );

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: BufferLogger.test());
        expect(await finder.findProjectExtensions(startDirectory: projectDir), isEmpty);

        _writePackageConfig(projectDir, const <String, String>{
          'app': '../',
          'my_ext': '../../my_ext',
        });

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
        final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dependencies:
  direct_ext: ^1.0.0
''');
        _writeExtensionPackage(fs.directory('/workspace/direct_ext'), name: 'direct_ext');
        _writeExtensionPackage(fs.directory('/workspace/transitive_ext'), name: 'transitive_ext');
        _writePackageConfig(projectDir, const <String, String>{
          'app': '../',
          'direct_ext': '../../direct_ext',
          'transitive_ext': '../../transitive_ext',
        });

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: BufferLogger.test());
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: projectDir,
        );
        expect(discovered.map((DiscoveredProjectExtension e) => e.name), const <String>[
          'direct_ext',
        ]);
      },
    );

    testWithoutContext('logs warning and skips extension when config.yaml has non-string keys or invalid field types', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
      projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dependencies:
  non_string_key_ext: ^1.0.0
  invalid_type_ext: ^1.0.0
  valid_ext: ^1.0.0
''');
      _writeExtensionPackage(
        fs.directory('/workspace/non_string_key_ext'),
        name: 'non_string_key_ext',
        configYaml: '''
name: non_string_key_ext
123: invalid_key
services:
  - diagnostics
''',
      );
      _writeExtensionPackage(
        fs.directory('/workspace/invalid_type_ext'),
        name: 'invalid_type_ext',
        configYaml: '''
name: invalid_type_ext
services: 42
''',
      );
      _writeExtensionPackage(fs.directory('/workspace/valid_ext'), name: 'valid_ext');
      _writePackageConfig(projectDir, const <String, String>{
        'app': '../',
        'non_string_key_ext': '../../non_string_key_ext',
        'invalid_type_ext': '../../invalid_type_ext',
        'valid_ext': '../../valid_ext',
      });

      final finder = ProjectExtensionFinder(fileSystem: fs, logger: logger);
      final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
        startDirectory: projectDir,
      );
      expect(discovered.map((DiscoveredProjectExtension e) => e.name), const <String>['valid_ext']);
      expect(
        logger.warningText,
        contains(
          'Skipping extension "non_string_key_ext": invalid extension/flutter_tools/config.yaml '
          '(config.yaml keys must be strings.).',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Skipping extension "invalid_type_ext": invalid extension/flutter_tools/config.yaml',
        ),
      );
    });

    testWithoutContext(
      'includes direct dependencies from Pub workspace root pubspec.yaml',
      () async {
        final fs = MemoryFileSystem.test();
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
        _writeExtensionPackage(
          workspaceRoot.childDirectory('packages/workspace_ext'),
          name: 'workspace_ext',
          configYaml: '''
name: workspace_ext
target_platforms:
  - custom_linux
services:
  - template
''',
        );
        _writePackageConfig(workspaceRoot, const <String, String>{
          'app': '../packages/app',
          'workspace_ext': '../packages/workspace_ext',
        });

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: BufferLogger.test());
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: appDir,
        );
        expect(discovered, hasLength(1));
        expect(discovered.single.name, 'workspace_ext');
        expect(discovered.single.config.targetPlatforms, const <String>{'custom_linux'});
      },
    );

    testWithoutContext(
      'discovers extensions via package:extension_discovery on LocalFileSystem',
      () async {
        final localFs = LocalFileSystem.test(signals: LocalSignals.instance);
        addTearDown(localFs.dispose);
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
        _writeExtensionPackage(tempDir.childDirectory('local_ext'), name: 'local_ext');
        _writeExtensionPackage(tempDir.childDirectory('transitive_ext'), name: 'transitive_ext');
        _writePackageConfig(projectDir, const <String, String>{
          'app': '../',
          'local_ext': '../../local_ext',
          'transitive_ext': '../../transitive_ext',
        });

        final finder = ProjectExtensionFinder(fileSystem: localFs, logger: logger);
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: projectDir,
        );
        expect(discovered, hasLength(1));
        expect(discovered.single.name, 'local_ext');
        expect(discovered.single.config.services, const <String>{'diagnostics'});
        expect(
          logger.traceText,
          contains('ignoring transitive extension package "transitive_ext"'),
        );
      },
    );
  });

  group('ExtensionKernelCompiler', () {
    testWithoutContext('compiles local extension to .dill and invalidates via depfile', () async {
      final fs = MemoryFileSystem.test();
      fs.file('/flutter/bin/cache/dart-sdk/version')
        ..createSync(recursive: true)
        ..writeAsStringSync('3.13.0-0.0.pre\n')
        ..setLastModifiedSync(DateTime.utc(2026));
      _writePackageConfig(fs.directory('/workspace/app')).setLastModifiedSync(DateTime.utc(2026));

      final Directory extDir = fs.directory('/workspace/my_ext');
      _writeExtensionPackage(extDir, name: 'my_ext');
      final File entrypointFile = extDir.childFile('bin/my_ext.dart')
        ..setLastModifiedSync(DateTime.utc(2026));
      final File helperFile = extDir.childFile('lib/helper.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('const int version = 1;')
        ..setLastModifiedSync(DateTime.utc(2026));

      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          modified: DateTime.utc(2026, 1, 1, 1),
          depfileContent: '$expectedDillPath.tmp: ${entrypointFile.path} ${helperFile.path}\n',
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[4, 5, 6],
          modified: DateTime.utc(2026, 1, 1, 3),
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[7, 8, 9],
          modified: DateTime.utc(2026, 1, 1, 5),
        ),
      ]);

      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);
      final DiscoveredProjectExtension extension = _discoveredExtension(fs);

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

      // 4. Truncating the .dill file to 0 bytes invalidates the cache even with a fresh timestamp.
      fs.file(expectedDillPath)
        ..writeAsBytesSync(const <int>[])
        ..setLastModifiedSync(DateTime.utc(2026, 1, 1, 4));
      final Uri emptyRecompiledDillUri = await compiler.compile(extension);
      expect(fs.file(emptyRecompiledDillUri).readAsBytesSync(), const <int>[7, 8, 9]);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('isPubCacheExtension resolves default pub-cache directory and does not misclassify local paths', () {
      final posixFs = MemoryFileSystem.test();
      final ExtensionKernelCompiler posixCompiler = _createCompiler(
        posixFs,
        environment: const <String, String>{'HOME': '/Users/user'},
      );

      expect(
        posixCompiler.isPubCacheExtension(
          _discoveredExtension(
            posixFs,
            rootPath: '/Users/user/.pub-cache/hosted/pub.dev/my_ext-1.0.0',
          ),
        ),
        isTrue,
      );
      for (final localPath in const <String>[
        '/Users/user/Projects/.pub-cache-test/my_ext',
        '/Users/user/Projects/Pub/Cache/my_ext',
        '/Users/user/Projects/.pub-cache/my_ext',
      ]) {
        expect(
          posixCompiler.isPubCacheExtension(_discoveredExtension(posixFs, rootPath: localPath)),
          isFalse,
        );
      }

      final windowsFs = MemoryFileSystem.test(style: FileSystemStyle.windows);
      final ExtensionKernelCompiler windowsCompiler = _createCompiler(
        windowsFs,
        operatingSystem: 'windows',
        flutterRootPath: r'C:\flutter',
        environment: const <String, String>{'LOCALAPPDATA': r'C:\Users\user\AppData\Local'},
      );
      expect(
        windowsCompiler.isPubCacheExtension(
          _discoveredExtension(
            windowsFs,
            rootPath: r'C:\Users\user\AppData\Local\Pub\Cache\hosted\pub.dev\my_ext-1.0.0',
            workspaceRootPath: r'C:\workspace\app',
          ),
        ),
        isTrue,
      );
      expect(
        windowsCompiler.isPubCacheExtension(
          _discoveredExtension(
            windowsFs,
            rootPath: r'C:\Users\user\Projects\Pub\Cache\my_ext',
            workspaceRootPath: r'C:\workspace\app',
          ),
        ),
        isFalse,
      );
    });

    testWithoutContext(
      'caches immutable PUB_CACHE extension under DART_DATA_HOME/flutter_tool_extensions/cache',
      () async {
        final MemoryFileSystem fs = _hostStyleMemoryFs();
        final String root = fs.currentDirectory.path;
        final String flutterRootPath = fs.path.join(root, 'flutter');
        final String workspaceAppPath = fs.path.join(root, 'workspace', 'app');
        final String homePath = fs.path.join(root, 'home', 'test');
        final String pubCachePath = fs.path.join(homePath, '.pub-cache');
        final String customDataPath = fs.path.join(root, 'custom_data');
        final String extRootPath = fs.path.join(
          pubCachePath,
          'hosted',
          'pub.dev',
          'hosted_ext-1.2.3',
        );

        fs.file(fs.path.join(flutterRootPath, 'bin', 'cache', 'dart-sdk', 'version'))
          ..createSync(recursive: true)
          ..writeAsStringSync('3.13.0\n');
        final File packageConfigFile = _writePackageConfig(fs.directory(workspaceAppPath));
        _writeExtensionPackage(fs.directory(extRootPath), name: 'hosted_ext');

        final DiscoveredProjectExtension extension = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRootPath,
          workspaceRootPath: workspaceAppPath,
        );
        final processManager = FakeProcessManager.empty();
        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          flutterRootPath: flutterRootPath,
          environment: <String, String>{
            'HOME': homePath,
            'PUB_CACHE': pubCachePath,
            'DART_DATA_HOME': customDataPath,
          },
          processManager: processManager,
        );

        final File targetDill = compiler.resolveDillFile(extension);
        expect(
          targetDill.path,
          startsWith(
            fs.path.join(customDataPath, 'flutter_tool_extensions', 'cache', 'hosted_ext-3.13.0-'),
          ),
        );

        var compileInvocations = 0;
        processManager.addCommand(
          _compileKernelCommand(
            fs,
            entrypointPath: fs.file(extension.entrypointUri).path,
            outputDillPath: targetDill.path,
            packageConfigPath: packageConfigFile.path,
            bytes: const <int>[9, 9, 9],
            onRunExtra: () => compileInvocations++,
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

    testWithoutContext('falls back to <flutterRoot>/bin/cache/flutter_tool_extensions/cache when OS data home environment variables are unset', () async {
      final fs = MemoryFileSystem.test();
      _writePackageConfig(fs.directory('/workspace/app'));

      DiscoveredProjectExtension extensionAt(String version) {
        final rootPath = '/pub/hosted/pub.dev/hosted_ext-$version';
        _writeExtensionPackage(fs.directory(rootPath), name: 'hosted_ext');
        return _discoveredExtension(fs, name: 'hosted_ext', rootPath: rootPath);
      }

      final DiscoveredProjectExtension v1 = extensionAt('1.0.0');
      final DiscoveredProjectExtension v2 = extensionAt('1.1.0');
      final processManager = FakeProcessManager.empty();
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        environment: const <String, String>{'PUB_CACHE': '/pub', 'DART_DATA_HOME': '   '},
        processManager: processManager,
      );

      final File v1Dill = compiler.resolveDillFile(v1);
      final File v2Dill = compiler.resolveDillFile(v2);
      expect(compiler.isPubCacheExtension(v1), isTrue);
      expect(
        v1Dill.path,
        startsWith('/flutter/bin/cache/flutter_tool_extensions/cache/hosted_ext-unknown-'),
      );
      expect(
        v2Dill.path,
        startsWith('/flutter/bin/cache/flutter_tool_extensions/cache/hosted_ext-unknown-'),
      );
      expect(v1Dill.path, isNot(v2Dill.path));

      processManager.addCommands(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: fs.file(v1.entrypointUri).path,
          outputDillPath: v1Dill.path,
          bytes: const <int>[1],
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: fs.file(v2.entrypointUri).path,
          outputDillPath: v2Dill.path,
          bytes: const <int>[2],
        ),
      ]);

      await compiler.compile(v1);
      final Uri upgradedDill = await compiler.compile(v2);
      expect(fs.file(upgradedDill).readAsBytesSync(), const <int>[2]);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'cleans up temporary files and throws ExtensionCompileException on failure',
      () async {
        final fs = MemoryFileSystem.test();
        _writePackageConfig(fs.directory('/workspace/app'));
        _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');

        const expectedDillPath =
            '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
        final processManager = FakeProcessManager.list(<FakeCommand>[
          _compileKernelCommand(
            fs,
            entrypointPath: '/workspace/my_ext/bin/my_ext.dart',
            outputDillPath: expectedDillPath,
            exitCode: 254,
            stderr: 'Compilation error',
            bytes: const <int>[0],
            depfileContent: 'partial',
          ),
        ]);

        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          processManager: processManager,
        );
        await expectLater(
          compiler.compile(_discoveredExtension(fs)),
          throwsA(isA<ExtensionCompileException>()),
        );
        expect(fs.file(expectedDillPath).existsSync(), isFalse);
        expect(fs.file('$expectedDillPath.tmp').existsSync(), isFalse);
        expect(fs.file('$expectedDillPath.d.tmp').existsSync(), isFalse);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'resolveDillFile resolves default getDartDataHome directory when DART_DATA_HOME is unset',
      () {
        final MemoryFileSystem fs = _hostStyleMemoryFs();
        final String root = fs.currentDirectory.path;
        final String pubCachePath = fs.path.join(root, 'pub');
        final String workspaceAppPath = fs.path.join(root, 'workspace', 'app');
        final String flutterRootPath = fs.path.join(root, 'flutter');
        final String extPath = fs.path.join(pubCachePath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
        final DiscoveredProjectExtension extension = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extPath,
          workspaceRootPath: workspaceAppPath,
        );

        final defaultEnvironment = <String, String>{
          'PUB_CACHE': pubCachePath,
          'HOME': fs.path.join(root, 'home', 'test'),
          'LOCALAPPDATA': fs.path.join(root, 'local_app_data'),
        };
        final String expectedDefaultDataHome = getDartDataHome(
          'flutter_tool_extensions',
          environment: defaultEnvironment,
        );
        final ExtensionKernelCompiler defaultCompiler = _createCompiler(
          fs,
          flutterRootPath: flutterRootPath,
          environment: defaultEnvironment,
        );
        expect(
          defaultCompiler.resolveDillFile(extension).path,
          startsWith(fs.path.join(expectedDefaultDataHome, 'cache', 'hosted_ext-')),
        );

        final xdgEnvironment = <String, String>{
          ...defaultEnvironment,
          'XDG_STATE_HOME': fs.path.join(root, 'custom_xdg_state'),
        };
        final String expectedXdgDataHome = getDartDataHome(
          'flutter_tool_extensions',
          environment: xdgEnvironment,
        );
        final ExtensionKernelCompiler xdgCompiler = _createCompiler(
          fs,
          flutterRootPath: flutterRootPath,
          environment: xdgEnvironment,
        );
        expect(
          xdgCompiler.resolveDillFile(extension).path,
          startsWith(fs.path.join(expectedXdgDataHome, 'cache', 'hosted_ext-')),
        );

        final ExtensionKernelCompiler emptyEnvCompiler = _createCompiler(
          fs,
          flutterRootPath: flutterRootPath,
          environment: const <String, String>{},
        );
        expect(emptyEnvCompiler.isPubCacheExtension(extension), isFalse);
        expect(
          emptyEnvCompiler.resolveDillFile(extension).path,
          fs.path.join(
            workspaceAppPath,
            '.dart_tool',
            'flutter_tools',
            'extensions',
            'hosted_ext',
            'extension.dill',
          ),
        );
      },
    );

    testWithoutContext('invalidates cached local kernel when depfile dependency with escaped spaces changes', () async {
      final fs = MemoryFileSystem.test();
      _writePackageConfig(fs.directory('/workspace/app')).setLastModifiedSync(DateTime.utc(2026));

      final Directory extDir = fs.directory('/workspace/my_ext');
      _writeExtensionPackage(extDir, name: 'my_ext');
      final File entrypointFile = extDir.childFile('bin/my_ext.dart')
        ..setLastModifiedSync(DateTime.utc(2026));
      final File spacedHelperFile = extDir.childFile('lib/part one.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('const int v = 1;')
        ..setLastModifiedSync(DateTime.utc(2026));

      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[1],
          modified: DateTime.utc(2026, 1, 1, 1),
          depfileContent:
              '$expectedDillPath.tmp: ${entrypointFile.path} /workspace/my_ext/lib/part\\ one.dart\n',
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[2],
          modified: DateTime.utc(2026, 1, 1, 3),
        ),
      ]);

      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);
      final DiscoveredProjectExtension extension = _discoveredExtension(fs);

      await compiler.compile(extension);
      await compiler.compile(extension);

      spacedHelperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
      final Uri recompiled = await compiler.compile(extension);
      expect(fs.file(recompiled).readAsBytesSync(), const <int>[2]);
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}
