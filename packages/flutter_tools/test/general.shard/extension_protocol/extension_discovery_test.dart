// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:dart_data_home/dart_data_home.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_kernel_compiler.dart';
import 'package:flutter_tools/src/experimental/project_extension_finder.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

typedef _TestLockPackage = ({String? resolvedRef, String source, String version});

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

final class _DummyService extends ToolExtensionService {
  _DummyService(this.namespace, this.methodName);

  @override
  final String namespace;
  final String methodName;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{methodName: (Map<String, Object?> params) => 'ok'};
  }
}

final class _FailingInitService extends ToolExtensionService {
  @override
  String get namespace => 'failing';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    throw StateError('Simulated service initialize failure');
  }
}

final class _NotificationTestService extends ToolExtensionService {
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

final class _ExitingService extends ToolExtensionService {
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

final class _AsyncErrorService extends ToolExtensionService {
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

final class _ProtocolHardeningService extends ToolExtensionService {
  @override
  String get namespace => 'hardening';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'throwUserError': (Map<String, Object?> _) {
        throw const ToolExtensionException('Missing custom SDK at /opt/custom_sdk');
      },
      'callProcessExit': (Map<String, Object?> _) {
        io.exit(42);
      },
    };
  }
}

void _protocolHardeningEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_ProtocolHardeningService()]),
  );
}

final class _ExitInInitService extends ToolExtensionService {
  @override
  String get namespace => 'exit_init';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    io.exit(1);
  }
}

void _exitInInitEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_ExitInInitService()]));
}

final class _ShutdownTrackingService extends ToolExtensionService {
  _ShutdownTrackingService(this.namespace, {this.gateSendPort, this.throwOnShutdown = false});

  @override
  final String namespace;
  final SendPort? gateSendPort;
  final bool throwOnShutdown;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{'ping': (Map<String, Object?> _) => 'pong'};
  }

  @override
  Future<void> shutdown() async {
    if (gateSendPort case final SendPort gate) {
      final releasePort = ReceivePort();
      gate.send(releasePort.sendPort);
      await releasePort.first;
      releasePort.close();
    }
    sendNotification('lifecycle.shutdown', <String, Object?>{'service': namespace});
    if (throwOnShutdown) {
      throw StateError('Simulated shutdown failure in $namespace');
    }
  }
}

void _shutdownTrackingEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
      _ShutdownTrackingService('service_a', throwOnShutdown: true),
      _ShutdownTrackingService('service_b'),
    ]),
  );
}

MemoryFileSystem _hostStyleMemoryFs() => MemoryFileSystem.test(
  style: const LocalPlatform().isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
);

void _writeExtensionPackage(
  Directory extDir, {
  String entrypointBody = 'void main(List<String> args, Object? message) {}',
  String? name,
}) {
  extDir.childDirectory('extension').childDirectory('flutter_tools').childFile('extension.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(entrypointBody);
}

_TestLockPackage _inferLockPackage(FileSystem fs, String name, String rootPath) {
  final String basename = fs.path.basename(rootPath);
  final prefix = '$name-';
  final String version = basename.startsWith(prefix) && basename.length > prefix.length
      ? basename.substring(prefix.length)
      : '1.0.0';
  final String source;
  if (rootPath.contains('hosted')) {
    source = 'hosted';
  } else if (rootPath.contains('git')) {
    source = 'git';
  } else if (rootPath.contains('flutter')) {
    source = 'sdk';
  } else {
    source = 'path';
  }
  return (
    resolvedRef: source == 'git' ? 'deadbeef00000000' : null,
    source: source,
    version: version,
  );
}

File _writePackageConfig(
  Directory rootDir, [
  Map<String, String> packageRoots = const <String, String>{},
  Map<String, Object?> extraData = const <String, Object?>{},
  Map<String, _TestLockPackage>? lockPackages,
  bool writePubspecLock = true,
]) {
  final FileSystem fs = rootDir.fileSystem;
  final Directory dartToolDir = rootDir.childDirectory('.dart_tool')..createSync(recursive: true);
  final File packageConfigFile = dartToolDir.childFile('package_config.json');
  final Uri baseUri = packageConfigFile.absolute.uri;
  Uri resolveRootUri(String value) {
    if (fs.path.isAbsolute(value)) {
      return fs.directory(value).absolute.uri;
    }
    return baseUri.resolve(value.endsWith('/') ? value : '$value/');
  }

  final buffer = StringBuffer();
  PackageConfig.writeString(
    PackageConfig(<Package>[
      for (final MapEntry(:String key, :String value) in packageRoots.entries)
        Package(key, resolveRootUri(value), packageUriRoot: resolveRootUri(value).resolve('lib/')),
    ], extraData: extraData),
    buffer,
    baseUri,
  );
  packageConfigFile.writeAsStringSync(buffer.toString());

  final List<String> packageNames = packageRoots.keys.toList();
  dartToolDir
      .childFile('package_graph.json')
      .writeAsStringSync(
        jsonEncode(<String, Object?>{
          'configVersion': 1,
          'roots': <String>[if (packageNames.isNotEmpty) packageNames.first],
          'packages': <Map<String, Object?>>[
            for (var i = 0; i < packageNames.length; i++)
              <String, Object?>{
                'name': packageNames[i],
                'dependencies': <String>[
                  for (var j = i + 1; j < packageNames.length; j++) packageNames[j],
                ],
                'devDependencies': const <String>[],
              },
          ],
        }),
      );

  if (writePubspecLock) {
    final lockBuffer = StringBuffer('packages:\n');
    for (final MapEntry(:String key, :String value) in packageRoots.entries) {
      final _TestLockPackage lockInfo = lockPackages?[key] ?? _inferLockPackage(fs, key, value);
      lockBuffer
        ..writeln('  $key:')
        ..writeln('    dependency: transitive')
        ..write(
          lockInfo.resolvedRef != null
              ? '    description:\n      resolved-ref: "${lockInfo.resolvedRef}"\n'
              : '    description: $key\n',
        )
        ..writeln('    source: ${lockInfo.source}')
        ..writeln('    version: "${lockInfo.version}"');
    }
    rootDir.childFile('pubspec.lock').writeAsStringSync(lockBuffer.toString());
  }
  return packageConfigFile;
}

DiscoveredProjectExtension _discoveredExtension(
  FileSystem fs, {
  String name = 'my_ext',
  String? rootPath,
  String? workspaceRootPath,
}) {
  final String fsRoot = fs.currentDirectory.path;
  final Directory dir = fs.directory(rootPath ?? fs.path.join(fsRoot, 'workspace', 'my_ext'));
  final String resolvedWorkspaceRoot =
      workspaceRootPath ?? fs.path.join(fsRoot, 'workspace', 'app');
  return DiscoveredProjectExtension(
    entrypointUri: dir
        .childDirectory('extension')
        .childDirectory('flutter_tools')
        .childFile('extension.dart')
        .uri,
    name: name,
    packageConfigUri: fs
        .file(fs.path.join(resolvedWorkspaceRoot, '.dart_tool', 'package_config.json'))
        .uri,
    packageUri: dir.childDirectory('lib').uri,
    rootUri: dir.uri,
    workspaceRootUri: fs.directory(resolvedWorkspaceRoot).uri,
  );
}

ExtensionKernelCompiler _createCompiler(
  FileSystem fs, {
  Map<String, String> environment = const <String, String>{'HOME': '/home/test'},
  String? flutterRootPath,
  Logger? logger,
  String operatingSystem = 'linux',
  ProcessManager? processManager,
  String? sdkRevision = '6623b84628f37ca8c5c8e3d217f8d3b72d019f02',
  String? sdkVersion = '3.13.0-0.0.pre',
}) {
  final String resolvedFlutterRootPath =
      flutterRootPath ?? fs.path.join(fs.currentDirectory.path, 'flutter');
  final Directory dartSdkDir = fs
      .directory(resolvedFlutterRootPath)
      .childDirectory('bin')
      .childDirectory('cache')
      .childDirectory('dart-sdk');
  if (sdkRevision != null) {
    final File revisionFile = dartSdkDir.childFile('revision');
    if (!revisionFile.existsSync()) {
      revisionFile
        ..createSync(recursive: true)
        ..writeAsStringSync('$sdkRevision\n')
        ..setLastModifiedSync(DateTime.utc(2026));
    }
  }
  if (sdkVersion != null) {
    final File versionFile = dartSdkDir.childFile('version');
    if (!versionFile.existsSync()) {
      versionFile
        ..createSync(recursive: true)
        ..writeAsStringSync('$sdkVersion\n')
        ..setLastModifiedSync(DateTime.utc(2026));
    }
  }
  return ExtensionKernelCompiler(
    artifacts: Artifacts.test(fileSystem: fs),
    fileSystem: fs,
    flutterRoot: fs.directory(resolvedFlutterRootPath),
    logger: logger ?? BufferLogger.test(),
    platform: FakePlatform(operatingSystem: operatingSystem, environment: environment),
    processManager: processManager ?? FakeProcessManager.empty(),
  );
}

String _escapeDepfilePath(String path) => path.replaceAll(r'\', r'\\').replaceAll(' ', r'\ ');

FakeCommand _compileKernelCommand(
  FileSystem fs, {
  required String entrypointPath,
  required String outputDillPath,
  List<int> bytes = const <int>[1, 2, 3],
  String? depfileContent,
  Object? exception,
  int exitCode = 0,
  DateTime? modified,
  void Function()? onRunExtra,
  String? packageConfigPath,
  String stderr = '',
  bool writeDefaultDepfile = true,
}) {
  final String dartBinary = Artifacts.test(fileSystem: fs)
      .getArtifactPath(Artifact.engineDartBinary);
  final String resolvedPackageConfigPath =
      packageConfigPath ??
      fs.path.join(
        fs.currentDirectory.path,
        'workspace',
        'app',
        '.dart_tool',
        'package_config.json',
      );
  final tempDillPath = '$outputDillPath.tmp';
  final tempDepfilePath = '$outputDillPath.d.tmp';
  return FakeCommand(
    command: <String>[
      dartBinary,
      'compile',
      'kernel',
      '--packages=$resolvedPackageConfigPath',
      '--output=$tempDillPath',
      '--depfile=$tempDepfilePath',
      entrypointPath,
    ],
    exception: exception,
    exitCode: exitCode,
    stderr: stderr,
    onRun: (_) {
      final File dill = fs.file(tempDillPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
      if (modified != null) {
        dill.setLastModifiedSync(modified);
      }
      final String? resolvedDepfile =
          depfileContent ??
          (writeDefaultDepfile
              ? '${_escapeDepfilePath(tempDillPath)}: '
                    '${_escapeDepfilePath(resolvedPackageConfigPath)} '
                    '${_escapeDepfilePath(entrypointPath)}\n'
              : null);
      if (resolvedDepfile != null) {
        fs.file(tempDepfilePath)
          ..createSync(recursive: true)
          ..writeAsStringSync(resolvedDepfile);
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

      await expectLater(
        ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
          _DummyService('extension', 'shutdown'),
        ]),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Reserved RPC method registered: "extension.shutdown"'),
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
              'artifact',
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

    test('ToolExtensionException with domainErrorCode (-32001) translates to ToolExtensionException on sendRequest', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _protocolHardeningEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      await expectLater(
        connection.sendRequest('hardening.throwUserError'),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            'Missing custom SDK at /opt/custom_sdk',
          ),
        ),
      );
    });

    test('IOOverrides exit guard intercepts exit() inside extension RPC handler without killing host process', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _protocolHardeningEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      await expectLater(
        connection.sendRequest('hardening.callProcessExit'),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.message,
            'message',
            contains(
              'Unsupported operation: Tool extensions must not call exit(42); '
              'throw ToolExtensionException instead.',
            ),
          ),
        ),
      );
    });

    test('IOOverrides exit guard intercepts exit() during service initialize without killing host process', () async {
      final logger = BufferLogger.test();
      await expectLater(
        ExtensionConnection.spawn(_exitInInitEntryPoint, logger: logger),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains(
              'Tool extensions must not call exit(1); throw ToolExtensionException instead.',
            ),
          ),
        ),
      );
    });

    test('ExtensionConnection.dispose sends extension.shutdown and isolates per-service shutdown failures', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _shutdownTrackingEntryPoint,
        logger: logger,
      );

      final shutdownServices = <String>[];
      final StreamSubscription<Map<String, Object?>> subscription = connection
          .onNotification('lifecycle.shutdown')
          .listen((Map<String, Object?> event) {
            if (event['service'] case final String serviceName) {
              shutdownServices.add(serviceName);
            }
          });
      addTearDown(subscription.cancel);

      await connection.dispose();
      expect(shutdownServices, unorderedEquals(const <String>['service_a', 'service_b']));
      expect(logger.traceText, isNot(contains('did not complete cleanly')));
    });

    test(
      'concurrent ExtensionConnection.dispose calls await in-flight shutdown before resolving',
      () async {
        final logger = BufferLogger.test();
        final gatePort = ReceivePort();
        addTearDown(gatePort.close);
        final SendPort gateSendPort = gatePort.sendPort;

        void gatedShutdownEntryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _ShutdownTrackingService('gated_service', gateSendPort: gateSendPort),
            ]),
          );
        }

        final ExtensionConnection connection = await ExtensionConnection.spawn(
          gatedShutdownEntryPoint,
          logger: logger,
        );

        final shutdownServices = <String>[];
        final StreamSubscription<Map<String, Object?>> subscription = connection
            .onNotification('lifecycle.shutdown')
            .listen((Map<String, Object?> event) {
              if (event['service'] case final String serviceName) {
                shutdownServices.add(serviceName);
              }
            });
        addTearDown(subscription.cancel);

        final Future<void> firstDispose = connection.dispose();
        expect(connection.isDisposed, isTrue);

        final releaseSendPort = await gatePort.first as SendPort;
        var secondDisposeCompleted = false;
        final Future<void> secondDispose = connection.dispose().then((_) {
          secondDisposeCompleted = true;
        });

        await pumpEventQueue();
        expect(secondDisposeCompleted, isFalse);

        releaseSendPort.send(null);
        await Future.wait(<Future<void>>[firstDispose, secondDispose]);
        expect(secondDisposeCompleted, isTrue);
        expect(shutdownServices, const <String>['gated_service']);
      },
    );
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
        _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');

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
        final DiscoveredProjectExtension ext = afterPubGet.single;
        expect(ext.name, 'my_ext');
        expect(
          ext.entrypointUri,
          fs.file('/workspace/my_ext/extension/flutter_tools/extension.dart').uri,
        );
        expect(ext.rootUri, fs.directory('/workspace/my_ext').uri);
        expect(ext.packageUri, fs.directory('/workspace/my_ext/lib').uri);
        expect(ext.workspaceRootUri, fs.directory('/workspace/app').uri);
        expect(ext, _discoveredExtension(fs));
        expect(ext.hashCode, _discoveredExtension(fs).hashCode);
        expect(
          ext.toString(),
          allOf(
            contains('name: my_ext'),
            contains('rootUri: file:///workspace/my_ext/'),
            contains('packageUri: file:///workspace/my_ext/lib/'),
            contains(
              'entrypointUri: file:///workspace/my_ext/extension/flutter_tools/extension.dart',
            ),
            contains('packageConfigUri: file:///workspace/app/.dart_tool/package_config.json'),
            contains('workspaceRootUri: file:///workspace/app/'),
          ),
        );
      },
    );

    testWithoutContext('filters out transitive extensions without stating them and ignores packages without extension/flutter_tools/extension.dart', () async {
      var transitiveStatted = false;
      final fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (context.contains('transitive_ext/extension') && operation == FileSystemOp.exists) {
            transitiveStatted = true;
          }
        },
      );
      final logger = BufferLogger.test();
      final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
      projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dependencies:
  direct_ext: ^1.0.0
  regular_pkg: ^1.0.0
''');
      _writeExtensionPackage(fs.directory('/workspace/direct_ext'), name: 'direct_ext');
      _writeExtensionPackage(fs.directory('/workspace/transitive_ext'), name: 'transitive_ext');
      fs.directory('/workspace/regular_pkg/lib').createSync(recursive: true);
      _writePackageConfig(projectDir, const <String, String>{
        'app': '../',
        'direct_ext': '../../direct_ext',
        'regular_pkg': '../../regular_pkg',
        'transitive_ext': '../../transitive_ext',
      });

      final finder = ProjectExtensionFinder(fileSystem: fs, logger: logger);
      final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
        startDirectory: projectDir,
      );
      expect(discovered.map((DiscoveredProjectExtension e) => e.name), const <String>[
        'direct_ext',
      ]);
      expect(transitiveStatted, isFalse);
      expect(logger.warningText, isEmpty);
    });

    testWithoutContext('handles malformed or unreadable pubspec.yaml without throwing ToolExit under ErrorHandlingFileSystem', () async {
      var failRead = false;
      final delegateFs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (failRead && context.endsWith('pubspec.yaml') && operation == FileSystemOp.read) {
            throw const FileSystemException(
              'Permission denied',
              '/workspace/app/pubspec.yaml',
              OSError('Permission denied', 13),
            );
          }
        },
      );
      final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
      final logger = BufferLogger.test();
      final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
      projectDir.childFile('pubspec.yaml').writeAsStringSync('dependencies: [unclosed');
      _writePackageConfig(projectDir, const <String, String>{'app': '../'});

      final finder = ProjectExtensionFinder(fileSystem: fs, logger: logger);
      expect(await finder.findProjectExtensions(startDirectory: projectDir), isEmpty);
      expect(logger.traceText, contains('failed to parse "/workspace/app/pubspec.yaml"'));

      failRead = true;
      expect(await finder.findProjectExtensions(startDirectory: projectDir), isEmpty);
      expect(logger.traceText, contains('failed to read "/workspace/app/pubspec.yaml"'));
    });

    testWithoutContext(
      'unions direct dependencies from Pub workspace root and member pubspec.yaml',
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
        final Directory appDir = workspaceRoot.childDirectory('packages').childDirectory('app')
          ..createSync(recursive: true);
        appDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
resolution: workspace
dependencies:
  member_ext:
    path: ../member_ext
''');
        _writeExtensionPackage(
          workspaceRoot.childDirectory('packages').childDirectory('workspace_ext'),
          name: 'workspace_ext',
        );
        _writeExtensionPackage(
          workspaceRoot.childDirectory('packages').childDirectory('member_ext'),
          name: 'member_ext',
        );
        _writePackageConfig(workspaceRoot, const <String, String>{
          'app': '../packages/app',
          'member_ext': '../packages/member_ext',
          'workspace_ext': '../packages/workspace_ext',
        });

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: BufferLogger.test());
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: appDir,
        );
        expect(
          discovered.map((DiscoveredProjectExtension e) => e.name),
          unorderedEquals(const <String>['member_ext', 'workspace_ext']),
        );
        for (final ext in discovered) {
          expect(ext.workspaceRootUri, workspaceRoot.uri);
        }
      },
    );

    testWithoutContext('discovers extensions and enforces symlink containment under ErrorHandlingFileSystem on LocalFileSystem', () async {
      final localFs = LocalFileSystem.test(signals: LocalSignals.instance);
      addTearDown(localFs.dispose);
      final fs = ErrorHandlingFileSystem(delegate: localFs, platform: FakePlatform());
      final Directory tempDir = fs.systemTempDirectory.createTempSync('ext_finder_local.');
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
  valid_ext:
    path: ../valid_ext
  internal_symlink_ext:
    path: ../internal_symlink_ext
  escaped_file_ext:
    path: ../escaped_file_ext
  escaped_dir_ext:
    path: ../escaped_dir_ext
  broken_symlink_ext:
    path: ../broken_symlink_ext
''');

      // 1. Standard valid extension.
      _writeExtensionPackage(tempDir.childDirectory('valid_ext'), name: 'valid_ext');

      // 2. Symlink resolving inside <pkgRoot>.
      final Directory internalSymlinkExtDir = tempDir.childDirectory('internal_symlink_ext');
      final File internalTarget =
          internalSymlinkExtDir.childDirectory('src').childFile('real_entrypoint.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('void main(List<String> args, Object? message) {}');
      internalSymlinkExtDir
          .childDirectory('extension')
          .childDirectory('flutter_tools')
          .childLink('extension.dart')
          .createSync(internalTarget.path, recursive: true);

      // 3. File symlink resolving outside <pkgRoot>.
      final File outsideFile = tempDir.childDirectory('outside').childFile('escaped.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main(List<String> args, Object? message) {}');
      tempDir
          .childDirectory('escaped_file_ext')
          .childDirectory('extension')
          .childDirectory('flutter_tools')
          .childLink('extension.dart')
          .createSync(outsideFile.path, recursive: true);

      // 4. Directory symlink resolving outside <pkgRoot>.
      final Directory outsideExtDir =
          tempDir.childDirectory('outside_dir').childDirectory('flutter_tools')
            ..createSync(recursive: true);
      outsideExtDir
          .childFile('extension.dart')
          .writeAsStringSync('void main(List<String> args, Object? message) {}');
      tempDir
          .childDirectory('escaped_dir_ext')
          .childLink('extension')
          .createSync(outsideExtDir.parent.path, recursive: true);

      // 5. Broken symlink at extension/flutter_tools/extension.dart.
      tempDir
          .childDirectory('broken_symlink_ext')
          .childDirectory('extension')
          .childDirectory('flutter_tools')
          .childLink('extension.dart')
          .createSync(tempDir.childFile('nonexistent_target.dart').path, recursive: true);

      // 6. Transitive extension package.
      _writeExtensionPackage(tempDir.childDirectory('transitive_ext'), name: 'transitive_ext');

      _writePackageConfig(projectDir, const <String, String>{
        'app': '../',
        'valid_ext': '../../valid_ext',
        'internal_symlink_ext': '../../internal_symlink_ext',
        'escaped_file_ext': '../../escaped_file_ext',
        'escaped_dir_ext': '../../escaped_dir_ext',
        'broken_symlink_ext': '../../broken_symlink_ext',
        'transitive_ext': '../../transitive_ext',
      });

      final finder = ProjectExtensionFinder(fileSystem: fs, logger: logger);
      final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
        startDirectory: projectDir,
      );
      expect(
        discovered.map((DiscoveredProjectExtension e) => e.name),
        unorderedEquals(const <String>['valid_ext', 'internal_symlink_ext']),
      );
      expect(
        logger.warningText,
        contains(
          'Skipping extension "escaped_file_ext": entrypoint '
          '"${tempDir.childDirectory('escaped_file_ext').childDirectory('extension').childDirectory('flutter_tools').childFile('extension.dart').path}" '
          'resolves outside package root',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Skipping extension "escaped_dir_ext": entrypoint '
          '"${tempDir.childDirectory('escaped_dir_ext').childDirectory('extension').childDirectory('flutter_tools').childFile('extension.dart').path}" '
          'resolves outside package root',
        ),
      );
      expect(
        logger.warningText,
        contains('Skipping extension "broken_symlink_ext": broken symlink at'),
      );
    });
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
      final File entrypointFile =
          extDir
              .childDirectory('extension')
              .childDirectory('flutter_tools')
              .childFile('extension.dart')
            ..setLastModifiedSync(DateTime.utc(2026));
      final File helperFile = extDir.childDirectory('lib').childFile('helper.dart')
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

    testWithoutContext(
      'isSharedCacheExtension uses pubspec.lock sources and rejects in-workspace paths',
      () {
        final posixFs = MemoryFileSystem.test();
        const posixHostedExtRoot = '/Users/user/.pub-cache/hosted/pub.dev/my_ext-1.0.0';
        _writePackageConfig(posixFs.directory('/workspace/app'), const <String, String>{
          'app': '../',
          'my_ext': posixHostedExtRoot,
        });
        final ExtensionKernelCompiler posixCompiler = _createCompiler(
          posixFs,
          environment: const <String, String>{'HOME': '/Users/user'},
        );

        expect(
          posixCompiler.isSharedCacheExtension(
            _discoveredExtension(posixFs, rootPath: posixHostedExtRoot),
          ),
          isTrue,
        );
        // In-workspace root is rejected even if pubspec.lock claims hosted.
        expect(
          posixCompiler.isSharedCacheExtension(
            _discoveredExtension(posixFs, rootPath: '/workspace/app/packages/my_ext'),
          ),
          isFalse,
        );

        final windowsFs = MemoryFileSystem.test(style: FileSystemStyle.windows);
        const windowsHostedExtRoot =
            r'C:\Users\user\AppData\Local\Pub\Cache\hosted\pub.dev\my_ext-1.0.0';
        _writePackageConfig(windowsFs.directory(r'C:\workspace\app'), const <String, String>{
          'app': '../',
          'my_ext': windowsHostedExtRoot,
        });
        final ExtensionKernelCompiler windowsCompiler = _createCompiler(
          windowsFs,
          operatingSystem: 'windows',
          flutterRootPath: r'C:\flutter',
          environment: const <String, String>{'LOCALAPPDATA': r'C:\Users\user\AppData\Local'},
        );
        expect(
          windowsCompiler.isSharedCacheExtension(
            _discoveredExtension(
              windowsFs,
              rootPath: windowsHostedExtRoot,
              workspaceRootPath: r'C:\workspace\app',
            ),
          ),
          isTrue,
        );
        final DiscoveredProjectExtension windowsLocalExt = _discoveredExtension(
          windowsFs,
          rootPath: r'C:\Users\user\Projects\Pub\Cache\my_ext',
          workspaceRootPath: r'C:\workspace\app',
        );
        _writePackageConfig(windowsFs.directory(r'C:\workspace\app'));
        _writeExtensionPackage(
          windowsFs.directory(r'C:\Users\user\Projects\Pub\Cache\my_ext'),
          name: 'my_ext',
        );
        expect(windowsCompiler.isSharedCacheExtension(windowsLocalExt), isFalse);
        expect(windowsFs.file(windowsLocalExt.entrypointUri).existsSync(), isTrue);
        expect(windowsFs.file(windowsLocalExt.packageConfigUri).existsSync(), isTrue);
      },
    );

    testWithoutContext(
      'caches immutable hosted extension under DART_DATA_HOME/flutter_tool_extensions/cache',
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
        final File packageConfigFile = _writePackageConfig(
          fs.directory(workspaceAppPath),
          <String, String>{'app': '../', 'hosted_ext': extRootPath},
        )..setLastModifiedSync(DateTime.utc(2026));
        _writeExtensionPackage(fs.directory(extRootPath), name: 'hosted_ext');
        fs
            .file(fs.path.join(extRootPath, 'extension', 'flutter_tools', 'extension.dart'))
            .setLastModifiedSync(DateTime.utc(2026));

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
          environment: <String, String>{'HOME': homePath, 'DART_DATA_HOME': customDataPath},
          processManager: processManager,
        );

        final File targetDill = compiler.resolveDillFile(extension);
        expect(
          targetDill.path,
          startsWith(
            fs.path.join(customDataPath, 'flutter_tool_extensions', 'cache', 'hosted_ext-1.2.3-'),
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
            modified: DateTime.utc(2026, 1, 1, 1),
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

      DiscoveredProjectExtension extensionAt(String version, String workspaceRootPath) {
        final rootPath = '/pub/hosted/pub.dev/hosted_ext-$version';
        _writeExtensionPackage(fs.directory(rootPath), name: 'hosted_ext');
        fs
            .file('$rootPath/extension/flutter_tools/extension.dart')
            .setLastModifiedSync(DateTime.utc(2026));
        _writePackageConfig(fs.directory(workspaceRootPath), <String, String>{
          'app': '../',
          'hosted_ext': rootPath,
        }).setLastModifiedSync(DateTime.utc(2026));
        return _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: rootPath,
          workspaceRootPath: workspaceRootPath,
        );
      }

      final DiscoveredProjectExtension v1 = extensionAt('1.0.0', '/workspace/app_v1');
      final DiscoveredProjectExtension v2 = extensionAt('1.1.0', '/workspace/app_v2');
      final processManager = FakeProcessManager.empty();
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        environment: const <String, String>{'DART_DATA_HOME': '   '},
        processManager: processManager,
      );

      final File v1Dill = compiler.resolveDillFile(v1);
      final File v2Dill = compiler.resolveDillFile(v2);
      expect(compiler.isSharedCacheExtension(v1), isTrue);
      expect(
        v1Dill.path,
        startsWith('/flutter/bin/cache/flutter_tool_extensions/cache/hosted_ext-1.0.0-'),
      );
      expect(
        v2Dill.path,
        startsWith('/flutter/bin/cache/flutter_tool_extensions/cache/hosted_ext-1.1.0-'),
      );
      expect(v1Dill.path, isNot(v2Dill.path));

      processManager.addCommands(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: fs.file(v1.entrypointUri).path,
          outputDillPath: v1Dill.path,
          packageConfigPath: fs.file(v1.packageConfigUri).path,
          bytes: const <int>[1],
          modified: DateTime.utc(2026, 1, 1, 1),
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: fs.file(v2.entrypointUri).path,
          outputDillPath: v2Dill.path,
          packageConfigPath: fs.file(v2.packageConfigUri).path,
          bytes: const <int>[2],
          modified: DateTime.utc(2026, 1, 1, 1),
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
            entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
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
        _writePackageConfig(fs.directory(workspaceAppPath), <String, String>{
          'app': '../',
          'hosted_ext': extPath,
        });
        final DiscoveredProjectExtension extension = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extPath,
          workspaceRootPath: workspaceAppPath,
        );

        final defaultEnvironment = <String, String>{
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
          startsWith(fs.path.join(expectedDefaultDataHome, 'cache', 'hosted_ext-1.0.0-')),
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
          startsWith(fs.path.join(expectedXdgDataHome, 'cache', 'hosted_ext-1.0.0-')),
        );

        final ExtensionKernelCompiler emptyEnvCompiler = _createCompiler(
          fs,
          flutterRootPath: flutterRootPath,
          environment: const <String, String>{},
        );
        expect(emptyEnvCompiler.isSharedCacheExtension(extension), isTrue);
        expect(
          emptyEnvCompiler.resolveDillFile(extension).path,
          startsWith(
            fs.path.join(
              flutterRootPath,
              'bin',
              'cache',
              'flutter_tool_extensions',
              'cache',
              'hosted_ext-1.0.0-',
            ),
          ),
        );
      },
    );

    testWithoutContext('invalidates cached local kernel when depfile dependency with escaped spaces changes', () async {
      final fs = MemoryFileSystem.test();
      _writePackageConfig(fs.directory('/workspace/app')).setLastModifiedSync(DateTime.utc(2026));

      final Directory extDir = fs.directory('/workspace/my_ext');
      _writeExtensionPackage(extDir, name: 'my_ext');
      final File entrypointFile =
          extDir
              .childDirectory('extension')
              .childDirectory('flutter_tools')
              .childFile('extension.dart')
            ..setLastModifiedSync(DateTime.utc(2026));
      final File spacedHelperFile = extDir.childDirectory('lib').childFile('part one.dart')
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

    testWithoutContext(
      'shared cache key differs when projects resolve different transitive dependency versions',
      () {
        final MemoryFileSystem fs = _hostStyleMemoryFs();
        final String root = fs.currentDirectory.path;
        final String pubPath = fs.path.join(root, 'pub');
        final String dataHomePath = fs.path.join(root, 'data_home');
        final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
        final String helperV1 = fs.path.join(pubPath, 'hosted', 'pub.dev', 'helper-1.0.0');
        final String helperV2 = fs.path.join(pubPath, 'hosted', 'pub.dev', 'helper-2.0.0');

        _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
        final Directory appADir = fs.directory(fs.path.join(root, 'workspace', 'app_a'));
        final Directory appBDir = fs.directory(fs.path.join(root, 'workspace', 'app_b'));
        _writePackageConfig(appADir, <String, String>{
          'app_a': '../',
          'hosted_ext': extRoot,
          'helper': helperV1,
        });
        _writePackageConfig(appBDir, <String, String>{
          'app_b': '../',
          'hosted_ext': extRoot,
          'helper': helperV2,
        });

        final DiscoveredProjectExtension extA = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
          workspaceRootPath: appADir.path,
        );
        final DiscoveredProjectExtension extB = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
          workspaceRootPath: appBDir.path,
        );

        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          environment: <String, String>{'DART_DATA_HOME': dataHomePath},
        );

        expect(compiler.resolveDillFile(extA).path, isNot(compiler.resolveDillFile(extB).path));
      },
    );

    testWithoutContext('scopes shared cache closure via package_graph.json and ignores compiling project package_config.json mtime', () async {
      final MemoryFileSystem fs = _hostStyleMemoryFs();
      final String root = fs.currentDirectory.path;
      final String pubPath = fs.path.join(root, 'pub');
      final String dataHomePath = fs.path.join(root, 'data_home');
      final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
      final String helperV1 = fs.path.join(pubPath, 'hosted', 'pub.dev', 'helper-1.0.0');
      final String unrelatedV1 = fs.path.join(
        pubPath,
        'hosted',
        'pub.dev',
        'unrelated_app_pkg-1.0.0',
      );
      final String unrelatedV2 = fs.path.join(
        pubPath,
        'hosted',
        'pub.dev',
        'unrelated_app_pkg-2.0.0',
      );

      _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
      fs
          .file(fs.path.join(extRoot, 'extension', 'flutter_tools', 'extension.dart'))
          .setLastModifiedSync(DateTime.utc(2026));

      final Directory appADir = fs.directory(fs.path.join(root, 'workspace', 'app_a'));
      final Directory appBDir = fs.directory(fs.path.join(root, 'workspace', 'app_b'));
      final File configA = _writePackageConfig(appADir, <String, String>{
        'app_a': '../',
        'hosted_ext': extRoot,
        'helper': helperV1,
        'unrelated_app_pkg': unrelatedV1,
      })..setLastModifiedSync(DateTime.utc(2026));
      _writePackageConfig(appBDir, <String, String>{
        'app_b': '../',
        'hosted_ext': extRoot,
        'helper': helperV1,
        'unrelated_app_pkg': unrelatedV2,
      }).setLastModifiedSync(DateTime.utc(2026, 1, 1, 5));

      for (final dir in <Directory>[appADir, appBDir]) {
        dir
            .childDirectory('.dart_tool')
            .childFile('package_graph.json')
            .writeAsStringSync(
              jsonEncode(<String, Object?>{
                'configVersion': 1,
                'roots': const <String>['app_a'],
                'packages': <Map<String, Object?>>[
                  <String, Object?>{
                    'name': 'hosted_ext',
                    'dependencies': <String>['helper'],
                    'devDependencies': const <String>[],
                  },
                  <String, Object?>{
                    'name': 'helper',
                    'dependencies': <String>[],
                    'devDependencies': const <String>[],
                  },
                  <String, Object?>{
                    'name': 'unrelated_app_pkg',
                    'dependencies': <String>[],
                    'devDependencies': const <String>[],
                  },
                ],
              }),
            );
      }

      final DiscoveredProjectExtension extA = _discoveredExtension(
        fs,
        name: 'hosted_ext',
        rootPath: extRoot,
        workspaceRootPath: appADir.path,
      );
      final DiscoveredProjectExtension extB = _discoveredExtension(
        fs,
        name: 'hosted_ext',
        rootPath: extRoot,
        workspaceRootPath: appBDir.path,
      );

      final processManager = FakeProcessManager.empty();
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        environment: <String, String>{'DART_DATA_HOME': dataHomePath},
        processManager: processManager,
      );

      final File sharedDillA = compiler.resolveDillFile(extA);
      final File sharedDillB = compiler.resolveDillFile(extB);
      expect(sharedDillA.path, sharedDillB.path);

      processManager.addCommand(
        _compileKernelCommand(
          fs,
          entrypointPath: fs.file(extA.entrypointUri).path,
          outputDillPath: sharedDillA.path,
          packageConfigPath: configA.path,
          modified: DateTime.utc(2026, 1, 1, 1),
        ),
      );

      final Uri compiledFromA = await compiler.compile(extA);
      // Even if app_a's package_config.json is touched by pub get, app_b still reuses the shared .dill.
      configA.setLastModifiedSync(DateTime.utc(2026, 1, 1, 6));
      final Uri reusedFromB = await compiler.compile(extB);
      expect(compiledFromA, sharedDillA.uri);
      expect(reusedFromB, sharedDillA.uri);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'invalidates shared cache .dill when a depfile source input changes',
      () async {
        final MemoryFileSystem fs = _hostStyleMemoryFs();
        final String root = fs.currentDirectory.path;
        final String pubPath = fs.path.join(root, 'pub');
        final String dataHomePath = fs.path.join(root, 'data_home');
        final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
        _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
        final File entrypointFile = fs.file(
          fs.path.join(extRoot, 'extension', 'flutter_tools', 'extension.dart'),
        )..setLastModifiedSync(DateTime.utc(2026));
        final File helperFile = fs.file(fs.path.join(extRoot, 'lib', 'helper.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('const int v = 1;')
          ..setLastModifiedSync(DateTime.utc(2026));
        final Directory appDir = fs.directory(fs.path.join(root, 'workspace', 'app'));
        final File configFile = _writePackageConfig(appDir, <String, String>{
          'app': '../',
          'hosted_ext': extRoot,
        })..setLastModifiedSync(DateTime.utc(2026));

        final DiscoveredProjectExtension ext = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
          workspaceRootPath: appDir.path,
        );
        final processManager = FakeProcessManager.empty();
        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          environment: <String, String>{'DART_DATA_HOME': dataHomePath},
          processManager: processManager,
        );
        expect(compiler.isSharedCacheExtension(ext), isTrue);
        final File sharedDill = compiler.resolveDillFile(ext);

        processManager.addCommands(<FakeCommand>[
          _compileKernelCommand(
            fs,
            entrypointPath: entrypointFile.path,
            outputDillPath: sharedDill.path,
            packageConfigPath: configFile.path,
            modified: DateTime.utc(2026, 1, 1, 1),
            depfileContent:
                '${_escapeDepfilePath('${sharedDill.path}.tmp')}: '
                '${_escapeDepfilePath(configFile.path)} '
                '${_escapeDepfilePath(entrypointFile.path)} '
                '${_escapeDepfilePath(helperFile.path)}\n',
          ),
          _compileKernelCommand(
            fs,
            entrypointPath: entrypointFile.path,
            outputDillPath: sharedDill.path,
            packageConfigPath: configFile.path,
            bytes: const <int>[4, 5, 6],
            modified: DateTime.utc(2026, 1, 1, 3),
          ),
        ]);

        await compiler.compile(ext);
        await compiler.compile(ext);
        helperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
        final Uri recompiled = await compiler.compile(ext);
        expect(recompiled, sharedDill.uri);
        expect(fs.file(recompiled).readAsBytesSync(), const <int>[4, 5, 6]);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'extension with sdk dependency in pubspec.lock falls back to Tier 2 workspace-local cache',
      () {
        final MemoryFileSystem fs = _hostStyleMemoryFs();
        final String root = fs.currentDirectory.path;
        final String pubPath = fs.path.join(root, 'pub');
        final String dataHomePath = fs.path.join(root, 'data_home');
        final String flutterPath = fs.path.join(root, 'flutter');
        final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
        _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');

        final Directory appDir = fs.directory(fs.path.join(root, 'workspace', 'app'));
        _writePackageConfig(appDir, <String, String>{
          'app': '../',
          'hosted_ext': extRoot,
          'flutter_tools_extension': fs.path.join(
            flutterPath,
            'packages',
            'flutter_tools',
            'packages',
            'flutter_tools_extension',
          ),
        });

        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          flutterRootPath: flutterPath,
          environment: <String, String>{'DART_DATA_HOME': dataHomePath},
        );
        final DiscoveredProjectExtension ext = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
          workspaceRootPath: appDir.path,
        );

        expect(compiler.isSharedCacheExtension(ext), isFalse);
        expect(
          compiler.resolveDillFile(ext).path,
          fs.path.join(
            appDir.path,
            '.dart_tool',
            'flutter_tools',
            'extensions',
            'hosted_ext',
            'extension.dill',
          ),
        );
      },
    );

    testWithoutContext(
      'hosted extension with transitive path dependency uses workspace-local cache',
      () {
        final fs = MemoryFileSystem.test();
        const extRoot = '/pub/hosted/pub.dev/hosted_ext-1.0.0';
        _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
        _writePackageConfig(fs.directory('/workspace/app'), const <String, String>{
          'app': '../',
          'hosted_ext': extRoot,
          'local_override': '/workspace/local_override',
        });

        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          environment: const <String, String>{'DART_DATA_HOME': '/data_home'},
        );
        final DiscoveredProjectExtension extension = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
        );

        expect(compiler.isSharedCacheExtension(extension), isFalse);
        expect(
          compiler.resolveDillFile(extension).path,
          '/workspace/app/.dart_tool/flutter_tools/extensions/hosted_ext/extension.dill',
        );
      },
    );

    testWithoutContext(
      'hosted extension falls back to workspace-local cache when package_graph.json is missing',
      () {
        final fs = MemoryFileSystem.test();
        const extRoot = '/pub/hosted/pub.dev/hosted_ext-1.0.0';
        _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
        final Directory appDir = fs.directory('/workspace/app');
        _writePackageConfig(appDir, const <String, String>{'app': '../', 'hosted_ext': extRoot});
        appDir.childDirectory('.dart_tool').childFile('package_graph.json').deleteSync();

        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          environment: const <String, String>{'DART_DATA_HOME': '/data_home'},
        );
        final DiscoveredProjectExtension extension = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
        );

        expect(compiler.isSharedCacheExtension(extension), isFalse);
        expect(
          compiler.resolveDillFile(extension).path,
          '/workspace/app/.dart_tool/flutter_tools/extensions/hosted_ext/extension.dill',
        );
      },
    );

    testWithoutContext(
      'hosted extension falls back to workspace-local cache when package_graph.json is malformed',
      () {
        final fs = MemoryFileSystem.test();
        const extRoot = '/pub/hosted/pub.dev/hosted_ext-1.0.0';
        _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
        final Directory appDir = fs.directory('/workspace/app');
        _writePackageConfig(appDir, const <String, String>{'app': '../', 'hosted_ext': extRoot});
        appDir
            .childDirectory('.dart_tool')
            .childFile('package_graph.json')
            .writeAsStringSync('{malformed json');

        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          environment: const <String, String>{'DART_DATA_HOME': '/data_home'},
        );
        final DiscoveredProjectExtension extension = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
        );

        expect(compiler.isSharedCacheExtension(extension), isFalse);
        expect(
          compiler.resolveDillFile(extension).path,
          '/workspace/app/.dart_tool/flutter_tools/extensions/hosted_ext/extension.dill',
        );
      },
    );

    testWithoutContext(
      'throws ExtensionCompileException when bin/cache/dart-sdk/revision is missing',
      () async {
        final fs = MemoryFileSystem.test();
        _writePackageConfig(fs.directory('/workspace/app'));
        _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');
        final DiscoveredProjectExtension localExt = _discoveredExtension(fs);

        final ExtensionKernelCompiler compiler = _createCompiler(fs, sdkRevision: null);
        expect(
          () => compiler.resolveDillFile(localExt),
          throwsA(
            isA<ExtensionCompileException>().having(
              (ExtensionCompileException e) => e.message,
              'message',
              contains('no Dart SDK revision at "/flutter/bin/cache/dart-sdk/revision"'),
            ),
          ),
        );
        await expectLater(
          compiler.compile(localExt),
          throwsA(
            isA<ExtensionCompileException>().having(
              (ExtensionCompileException e) => e.message,
              'message',
              contains('no Dart SDK revision at "/flutter/bin/cache/dart-sdk/revision"'),
            ),
          ),
        );
      },
    );

    testWithoutContext('Dart SDK revision roll invalidates shared cache key', () {
      final MemoryFileSystem fs = _hostStyleMemoryFs();
      final String root = fs.currentDirectory.path;
      final String pubPath = fs.path.join(root, 'pub');
      final String dataHomePath = fs.path.join(root, 'data_home');
      final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
      _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
      _writePackageConfig(fs.directory(fs.path.join(root, 'workspace', 'app')), <String, String>{
        'app': '../',
        'hosted_ext': extRoot,
      });

      final DiscoveredProjectExtension pubCacheExt = _discoveredExtension(
        fs,
        name: 'hosted_ext',
        rootPath: extRoot,
      );
      final File revisionFile =
          fs.file(fs.path.join(root, 'flutter', 'bin', 'cache', 'dart-sdk', 'revision'))
            ..createSync(recursive: true)
            ..writeAsStringSync('abcdef0123456789\n');

      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        environment: <String, String>{'DART_DATA_HOME': dataHomePath},
        sdkRevision: null,
      );

      final File dillBeforeRoll = compiler.resolveDillFile(pubCacheExt);
      revisionFile.writeAsStringSync('9876543210fedcba\n');
      final File dillAfterRoll = compiler.resolveDillFile(pubCacheExt);
      expect(dillBeforeRoll.path, isNot(dillAfterRoll.path));
    });

    testWithoutContext('Dart SDK revision roll invalidates cached local kernel even when revision file mtime is older', () async {
      final fs = MemoryFileSystem.test();
      _writePackageConfig(fs.directory('/workspace/app')).setLastModifiedSync(DateTime.utc(2026));
      _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');
      fs
          .file('/workspace/my_ext/extension/flutter_tools/extension.dart')
          .setLastModifiedSync(DateTime.utc(2026));

      final DiscoveredProjectExtension localExt = _discoveredExtension(fs);
      final File revisionFile = fs.file('/flutter/bin/cache/dart-sdk/revision')
        ..createSync(recursive: true)
        ..writeAsStringSync('abcdef0123456789\n')
        ..setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));

      const localDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: localDillPath,
          bytes: const <int>[1],
          modified: DateTime.utc(2026, 1, 1, 5),
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: localDillPath,
          bytes: const <int>[2],
          modified: DateTime.utc(2026, 1, 1, 6),
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        processManager: processManager,
        sdkRevision: null,
      );

      await compiler.compile(localExt);
      // Second compile hits cache with matching revision stamp.
      expect(fs.file(await compiler.compile(localExt)).readAsBytesSync(), const <int>[1]);

      // Simulate unpacking a Dart SDK archive whose archived mtime is older than dillModified.
      revisionFile
        ..writeAsStringSync('9876543210fedcba\n')
        ..setLastModifiedSync(DateTime.utc(2026));
      final Uri recompiled = await compiler.compile(localExt);
      expect(fs.file(recompiled).readAsBytesSync(), const <int>[2]);
      final stampJson =
          jsonDecode(fs.file('$localDillPath.stamp').readAsStringSync()) as Map<String, Object?>;
      expect(stampJson['sdkRevision'], '9876543210fedcba');
      // Subsequent compile reuses the updated kernel.
      expect(fs.file(await compiler.compile(localExt)).readAsBytesSync(), const <int>[2]);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('preserves SemVer 2 build metadata (+) in sanitized .dill filename', () {
      final MemoryFileSystem fs = _hostStyleMemoryFs();
      final String root = fs.currentDirectory.path;
      final String pubPath = fs.path.join(root, 'pub');
      final String dataHomePath = fs.path.join(root, 'data_home');
      final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0+build.1');
      _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
      _writePackageConfig(fs.directory(fs.path.join(root, 'workspace', 'app')), <String, String>{
        'app': '../',
        'hosted_ext': extRoot,
      });

      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        environment: <String, String>{'DART_DATA_HOME': dataHomePath},
        sdkVersion: '3.13.0+build.1',
      );
      final DiscoveredProjectExtension pubCacheExt = _discoveredExtension(
        fs,
        name: 'hosted_ext',
        rootPath: extRoot,
      );

      expect(
        compiler.resolveDillFile(pubCacheExt).basename,
        startsWith('hosted_ext-1.0.0+build.1-'),
      );
    });

    testWithoutContext('wraps ProcessException in ExtensionCompileException', () async {
      final fs = MemoryFileSystem.test();
      _writePackageConfig(fs.directory('/workspace/app'));
      _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');
      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';

      final processExceptionManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          exception: const ProcessException('dart', <String>['compile', 'kernel'], 'spawn error'),
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        processManager: processExceptionManager,
      );

      await expectLater(
        compiler.compile(_discoveredExtension(fs)),
        throwsA(
          isA<ExtensionCompileException>().having(
            (ExtensionCompileException e) => e.message,
            'message',
            contains('spawn error'),
          ),
        ),
      );
      expect(processExceptionManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'wraps FileSystemException in ExtensionCompileException and cleans up temp files',
      () async {
        const expectedDillPath =
            '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
        var throwOnTempDillExists = false;
        final failingFs = MemoryFileSystem.test(
          opHandle: (String context, FileSystemOp operation) {
            if (throwOnTempDillExists &&
                context == '$expectedDillPath.tmp' &&
                operation == FileSystemOp.exists) {
              throwOnTempDillExists = false;
              throw const FileSystemException('filesystem failure');
            }
          },
        );
        _writePackageConfig(failingFs.directory('/workspace/app'));
        _writeExtensionPackage(failingFs.directory('/workspace/my_ext'), name: 'my_ext');
        final fsExceptionManager = FakeProcessManager.list(<FakeCommand>[
          _compileKernelCommand(
            failingFs,
            entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
            outputDillPath: expectedDillPath,
            onRunExtra: () {
              throwOnTempDillExists = true;
            },
          ),
        ]);
        final ExtensionKernelCompiler failingFsCompiler = _createCompiler(
          failingFs,
          processManager: fsExceptionManager,
        );

        await expectLater(
          failingFsCompiler.compile(_discoveredExtension(failingFs)),
          throwsA(
            isA<ExtensionCompileException>().having(
              (ExtensionCompileException e) => e.message,
              'message',
              contains('filesystem failure'),
            ),
          ),
        );
        expect(failingFs.file('$expectedDillPath.tmp').existsSync(), isFalse);
        expect(failingFs.file('$expectedDillPath.d.tmp').existsSync(), isFalse);
        expect(failingFs.file('$expectedDillPath.stamp.tmp').existsSync(), isFalse);
        expect(fsExceptionManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'deletes pre-existing stale depFile when dart compile kernel does not emit a tempDepFile',
      () async {
        final fs = MemoryFileSystem.test();
        _writePackageConfig(fs.directory('/workspace/app'));
        _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');

        const expectedDillPath =
            '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
        final File staleDepfile = fs.file('$expectedDillPath.d')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '$expectedDillPath.tmp: /workspace/my_ext/extension/flutter_tools/extension.dart\n',
          );

        final processManager = FakeProcessManager.list(<FakeCommand>[
          _compileKernelCommand(
            fs,
            entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
            outputDillPath: expectedDillPath,
            writeDefaultDepfile: false,
          ),
        ]);
        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          processManager: processManager,
        );

        await compiler.compile(_discoveredExtension(fs));
        expect(staleDepfile.existsSync(), isFalse);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'discovers, compiles, and reuses cached extension kernels on Windows paths',
      () async {
        final fs = MemoryFileSystem.test(style: FileSystemStyle.windows);
        const flutterRootPath = r'C:\flutter';
        const localAppDataPath = r'C:\Users\Developer Name\AppData\Local';
        const appRootPath = r'C:\Users\Developer Name\workspace\app';
        const localExtRootPath = r'C:\Users\Developer Name\workspace\local_ext';
        const hostedExtRootPath =
            r'C:\Users\Developer Name\AppData\Local\Pub\Cache\hosted\pub.dev\hosted_ext-1.2.3';

        final Directory appDir = fs.directory(appRootPath)..createSync(recursive: true);
        appDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dev_dependencies:
  local_ext:
    path: ../local_ext
  hosted_ext: ^1.2.3
''');
        _writeExtensionPackage(fs.directory(localExtRootPath), name: 'local_ext');
        _writeExtensionPackage(fs.directory(hostedExtRootPath), name: 'hosted_ext');
        final File localEntrypoint =
            fs
                .directory(localExtRootPath)
                .childDirectory('extension')
                .childDirectory('flutter_tools')
                .childFile('extension.dart')
              ..setLastModifiedSync(DateTime.utc(2026));
        final File localHelper =
            fs.directory(localExtRootPath).childDirectory('lib').childFile('helper.dart')
              ..createSync(recursive: true)
              ..writeAsStringSync('const int v = 1;')
              ..setLastModifiedSync(DateTime.utc(2026));
        fs
            .directory(hostedExtRootPath)
            .childDirectory('extension')
            .childDirectory('flutter_tools')
            .childFile('extension.dart')
            .setLastModifiedSync(DateTime.utc(2026));

        final File packageConfigFile = _writePackageConfig(appDir, const <String, String>{
          'app': '../',
          'local_ext': localExtRootPath,
          'hosted_ext': hostedExtRootPath,
        })..setLastModifiedSync(DateTime.utc(2026));

        final finder = ProjectExtensionFinder(fileSystem: fs, logger: BufferLogger.test());
        final List<DiscoveredProjectExtension> discovered = await finder.findProjectExtensions(
          startDirectory: appDir,
        );
        expect(discovered, hasLength(2));
        final DiscoveredProjectExtension localExt = discovered.firstWhere(
          (DiscoveredProjectExtension e) => e.name == 'local_ext',
        );
        final DiscoveredProjectExtension hostedExt = discovered.firstWhere(
          (DiscoveredProjectExtension e) => e.name == 'hosted_ext',
        );

        final processManager = FakeProcessManager.empty();
        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          operatingSystem: 'windows',
          flutterRootPath: flutterRootPath,
          environment: const <String, String>{'LOCALAPPDATA': localAppDataPath},
          processManager: processManager,
        );
        expect(compiler.isSharedCacheExtension(localExt), isFalse);
        expect(compiler.isSharedCacheExtension(hostedExt), isTrue);

        final File localDill = compiler.resolveDillFile(localExt);
        final File sharedDill = compiler.resolveDillFile(hostedExt);
        expect(
          localDill.path,
          r'C:\Users\Developer Name\workspace\app\.dart_tool\flutter_tools\extensions\local_ext\extension.dill',
        );

        processManager.addCommands(<FakeCommand>[
          _compileKernelCommand(
            fs,
            entrypointPath: localEntrypoint.path,
            outputDillPath: localDill.path,
            packageConfigPath: packageConfigFile.path,
            bytes: const <int>[1, 2],
            modified: DateTime.utc(2026, 1, 1, 1),
            depfileContent:
                '${_escapeDepfilePath('${localDill.path}.tmp')}: '
                '${_escapeDepfilePath(packageConfigFile.path)} '
                '${_escapeDepfilePath(localEntrypoint.path)} '
                '${_escapeDepfilePath(localHelper.path)}\n',
          ),
          _compileKernelCommand(
            fs,
            entrypointPath: localEntrypoint.path,
            outputDillPath: localDill.path,
            packageConfigPath: packageConfigFile.path,
            bytes: const <int>[5, 6],
            modified: DateTime.utc(2026, 1, 1, 3),
          ),
          _compileKernelCommand(
            fs,
            entrypointPath: fs.file(hostedExt.entrypointUri).path,
            outputDillPath: sharedDill.path,
            packageConfigPath: packageConfigFile.path,
            bytes: const <int>[3, 4],
            modified: DateTime.utc(2026, 1, 1, 1),
          ),
        ]);

        final Uri localCompiled = await compiler.compile(localExt);
        final Uri localCached = await compiler.compile(localExt);
        expect(localCompiled, localDill.uri);
        expect(localCached, localDill.uri);

        localHelper.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
        final Uri localRecompiled = await compiler.compile(localExt);
        expect(fs.file(localRecompiled).readAsBytesSync(), const <int>[5, 6]);

        final Uri sharedCompiled = await compiler.compile(hostedExt);
        packageConfigFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 5));
        final Uri sharedCached = await compiler.compile(hostedExt);
        expect(sharedCompiled, sharedDill.uri);
        expect(sharedCached, sharedDill.uri);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'resolveDillFile returns absolute File matching compile URI for relative DART_DATA_HOME',
      () async {
        final MemoryFileSystem fs = _hostStyleMemoryFs();
        final String root = fs.currentDirectory.path;
        final String pubPath = fs.path.join(root, 'pub');
        final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
        _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
        fs
            .file(fs.path.join(extRoot, 'extension', 'flutter_tools', 'extension.dart'))
            .setLastModifiedSync(DateTime.utc(2026));
        final Directory appDir = fs.directory(fs.path.join(root, 'workspace', 'app'));
        final File configFile = _writePackageConfig(appDir, <String, String>{
          'app': '../',
          'hosted_ext': extRoot,
        })..setLastModifiedSync(DateTime.utc(2026));

        final DiscoveredProjectExtension ext = _discoveredExtension(
          fs,
          name: 'hosted_ext',
          rootPath: extRoot,
          workspaceRootPath: appDir.path,
        );
        final processManager = FakeProcessManager.empty();
        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          environment: <String, String>{'DART_DATA_HOME': 'relative_data_home'},
          processManager: processManager,
        );

        final File resolvedDill = compiler.resolveDillFile(ext);
        expect(resolvedDill.isAbsolute, isTrue);

        processManager.addCommand(
          _compileKernelCommand(
            fs,
            entrypointPath: fs.file(ext.entrypointUri).path,
            outputDillPath: resolvedDill.path,
            packageConfigPath: configFile.path,
            modified: DateTime.utc(2026, 1, 1, 1),
          ),
        );

        final Uri compiledUri = await compiler.compile(ext);
        expect(compiledUri, resolvedDill.uri);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'validates pubspec.lock sources for Tier 1 eligibility and hashes git resolved-ref',
      () {
        final MemoryFileSystem delegateFs = _hostStyleMemoryFs();
        final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
        final String root = fs.currentDirectory.path;
        final String pubPath = fs.path.join(root, 'pub');
        final String dataHomePath = fs.path.join(root, 'data_home');
        final String flutterPath = fs.path.join(root, 'flutter');
        final String gitExtRoot = fs.path.join(pubPath, 'git', 'git_ext-abcdef');
        final String hostedDepRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'helper-1.0.0');
        final String sdkDepRoot = fs.path.join(
          flutterPath,
          'packages',
          'flutter_tools',
          'packages',
          'flutter_tools_extension',
        );
        _writeExtensionPackage(fs.directory(gitExtRoot), name: 'git_ext');

        final Directory appDir = fs.directory(fs.path.join(root, 'workspace', 'app'));
        final DiscoveredProjectExtension gitExt = _discoveredExtension(
          fs,
          name: 'git_ext',
          rootPath: gitExtRoot,
          workspaceRootPath: appDir.path,
        );
        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          flutterRootPath: flutterPath,
          environment: <String, String>{'DART_DATA_HOME': dataHomePath},
        );

        // 1. git source with hosted transitive dependency is eligible for Tier 1.
        _writePackageConfig(
          appDir,
          <String, String>{'app': '../', 'git_ext': gitExtRoot, 'helper': hostedDepRoot},
          const <String, Object?>{},
          const <String, _TestLockPackage>{
            'git_ext': (resolvedRef: 'commit111', source: 'git', version: '2.0.0'),
            'helper': (resolvedRef: null, source: 'hosted', version: '1.0.0'),
          },
        );
        expect(compiler.isSharedCacheExtension(gitExt), isTrue);
        final File gitDillCommit1 = compiler.resolveDillFile(gitExt);
        expect(gitDillCommit1.basename, startsWith('git_ext-2.0.0-'));

        // Changing git resolved-ref changes the Tier 1 <sdkAndDepsHash>.
        _writePackageConfig(
          appDir,
          <String, String>{'app': '../', 'git_ext': gitExtRoot, 'helper': hostedDepRoot},
          const <String, Object?>{},
          const <String, _TestLockPackage>{
            'git_ext': (resolvedRef: 'commit222', source: 'git', version: '2.0.0'),
            'helper': (resolvedRef: null, source: 'hosted', version: '1.0.0'),
          },
        );
        final File gitDillCommit2 = compiler.resolveDillFile(gitExt);
        expect(gitDillCommit2.path, isNot(gitDillCommit1.path));

        // 2. path or sdk source in pubspec.lock falls back to Tier 2.
        _writePackageConfig(
          appDir,
          <String, String>{'app': '../', 'git_ext': gitExtRoot, 'helper': hostedDepRoot},
          const <String, Object?>{},
          const <String, _TestLockPackage>{
            'git_ext': (resolvedRef: null, source: 'path', version: '2.0.0'),
            'helper': (resolvedRef: null, source: 'hosted', version: '1.0.0'),
          },
        );
        expect(compiler.isSharedCacheExtension(gitExt), isFalse);

        _writePackageConfig(
          appDir,
          <String, String>{
            'app': '../',
            'git_ext': gitExtRoot,
            'flutter_tools_extension': sdkDepRoot,
          },
          const <String, Object?>{},
          const <String, _TestLockPackage>{
            'git_ext': (resolvedRef: 'commit111', source: 'git', version: '2.0.0'),
            'flutter_tools_extension': (resolvedRef: null, source: 'sdk', version: '0.1.0'),
          },
        );
        expect(compiler.isSharedCacheExtension(gitExt), isFalse);

        // 3. Transitive path dependency override in pubspec.lock falls back to Tier 2.
        _writePackageConfig(
          appDir,
          <String, String>{'app': '../', 'git_ext': gitExtRoot, 'helper': hostedDepRoot},
          const <String, Object?>{},
          const <String, _TestLockPackage>{
            'git_ext': (resolvedRef: 'commit111', source: 'git', version: '2.0.0'),
            'helper': (resolvedRef: null, source: 'path', version: '1.0.0'),
          },
        );
        expect(compiler.isSharedCacheExtension(gitExt), isFalse);

        // 4. Malformed or missing pubspec.lock falls back safely to Tier 2.
        appDir.childFile('pubspec.lock').writeAsStringSync('packages: [unclosed');
        expect(compiler.isSharedCacheExtension(gitExt), isFalse);
        appDir.childFile('pubspec.lock').deleteSync();
        expect(compiler.isSharedCacheExtension(gitExt), isFalse);
      },
    );

    testWithoutContext('persists, round-trips, validates, and invalidates Tier 1 capabilities in .capabilities.json without race window', () async {
      var capabilitiesDeletedBeforeDillRename = false;
      String? targetDillPathToWatch;
      String? capabilitiesPathToWatch;
      late final MemoryFileSystem delegateFs;
      delegateFs = MemoryFileSystem.test(
        style: const LocalPlatform().isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
        opHandle: (String context, FileSystemOp operation) {
          if (targetDillPathToWatch case final String targetDillPath) {
            if (capabilitiesPathToWatch case final String capabilitiesPath
                when operation == FileSystemOp.delete && context == capabilitiesPath) {
              // At the moment capabilitiesFile is deleted, dillFile must still hold its old bytes [1, 2, 3].
              capabilitiesDeletedBeforeDillRename =
                  delegateFs.file(targetDillPath).readAsBytesSync().first == 1;
            }
          }
        },
      );
      final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
      final String root = fs.currentDirectory.path;
      final String pubPath = fs.path.join(root, 'pub');
      final String dataHomePath = fs.path.join(root, 'data_home');
      final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.2.3');
      _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
      final File entrypointFile = fs.file(
        fs.path.join(extRoot, 'extension', 'flutter_tools', 'extension.dart'),
      )..setLastModifiedSync(DateTime.utc(2026));
      final File helperFile = fs.file(fs.path.join(extRoot, 'lib', 'helper.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('const int v = 1;')
        ..setLastModifiedSync(DateTime.utc(2026));

      final Directory appDir = fs.directory(fs.path.join(root, 'workspace', 'app'));
      final File configFile = _writePackageConfig(appDir, <String, String>{
        'app': '../',
        'hosted_ext': extRoot,
      })..setLastModifiedSync(DateTime.utc(2026));

      final DiscoveredProjectExtension ext = _discoveredExtension(
        fs,
        name: 'hosted_ext',
        rootPath: extRoot,
        workspaceRootPath: appDir.path,
      );
      final processManager = FakeProcessManager.empty();
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        environment: <String, String>{'DART_DATA_HOME': dataHomePath},
        processManager: processManager,
      );

      final File sharedDill = compiler.resolveDillFile(ext);
      final File capabilitiesFile = fs.file(
        '${sharedDill.path.substring(0, sharedDill.path.length - '.dill'.length)}.capabilities.json',
      );

      // 1. Before compile, readCachedCapabilities returns null and writeCachedCapabilities is a no-op.
      expect(compiler.readCachedCapabilities(ext), isNull);
      await compiler.writeCachedCapabilities(
        ext,
        const ToolExtensionCapabilities(
          extensionName: 'hosted_ext',
          services: <String>['diagnostics', 'build'],
          supportedPlatforms: <String>{'linux', 'macos'},
        ),
      );
      expect(capabilitiesFile.existsSync(), isFalse);

      processManager.addCommands(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: sharedDill.path,
          packageConfigPath: configFile.path,
          modified: DateTime.utc(2026, 1, 1, 1),
          depfileContent:
              '${_escapeDepfilePath('${sharedDill.path}.tmp')}: '
              '${_escapeDepfilePath(entrypointFile.path)} '
              '${_escapeDepfilePath(helperFile.path)}\n',
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: sharedDill.path,
          packageConfigPath: configFile.path,
          bytes: const <int>[4, 5, 6],
          modified: DateTime.utc(2026, 1, 1, 3),
        ),
      ]);

      // 2. After compile but before handshake, readCachedCapabilities returns null.
      await compiler.compile(ext);
      expect(compiler.readCachedCapabilities(ext), isNull);

      // 3. writeCachedCapabilities persists <prefix>.capabilities.json and round-trips.
      const expectedCapabilities = ToolExtensionCapabilities(
        extensionName: 'hosted_ext',
        services: <String>['diagnostics', 'build'],
        supportedPlatforms: <String>{'linux', 'macos'},
      );
      await compiler.writeCachedCapabilities(ext, expectedCapabilities);
      expect(capabilitiesFile.existsSync(), isTrue);
      final ToolExtensionCapabilities? cached = compiler.readCachedCapabilities(ext);
      expect(cached, isNotNull);
      expect(cached!.extensionName, 'hosted_ext');
      expect(cached.services, const <String>['diagnostics', 'build']);
      expect(cached.supportedPlatforms, const <String>{'linux', 'macos'});

      // 4. Corrupt, non-map, or empty {} .capabilities.json returns null without throwing.
      for (final invalidContent in const <String>[
        '{corrupt json',
        '[1, 2, 3]',
        '{}',
        '{"services": 42}',
      ]) {
        capabilitiesFile.writeAsStringSync(invalidContent);
        expect(compiler.readCachedCapabilities(ext), isNull);
      }

      // Restore valid capabilities, then modify a depfile input and recompile:
      // recompilation must delete the stale .capabilities.json BEFORE renaming tempDillFile.
      await compiler.writeCachedCapabilities(ext, expectedCapabilities);
      expect(compiler.readCachedCapabilities(ext), isNotNull);

      targetDillPathToWatch = sharedDill.path;
      capabilitiesPathToWatch = capabilitiesFile.path;
      helperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
      expect(compiler.readCachedCapabilities(ext), isNull);
      await compiler.compile(ext);
      expect(capabilitiesDeletedBeforeDillRename, isTrue);
      expect(capabilitiesFile.existsSync(), isFalse);
      expect(compiler.readCachedCapabilities(ext), isNull);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('persists, round-trips, and enforces freshness ordering and race-free stamp update for Tier 2 capabilities', () async {
      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      var stampClearedBeforeDillRename = false;
      var watchRecompileRename = false;
      late final MemoryFileSystem delegateFs;
      delegateFs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (watchRecompileRename &&
              operation == FileSystemOp.write &&
              context == '$expectedDillPath.stamp.tmp') {
            // At the moment the new stamp is written, the old dillFile has already been deleted
            // and the new tempDillFile has not yet been renamed into place.
            stampClearedBeforeDillRename = !delegateFs.file(expectedDillPath).existsSync();
          }
        },
      );
      final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
      final Directory appDir = fs.directory('/workspace/app');
      final Directory extDir = fs.directory('/workspace/my_ext');
      _writeExtensionPackage(extDir, name: 'my_ext');
      final File entrypointFile =
          extDir
              .childDirectory('extension')
              .childDirectory('flutter_tools')
              .childFile('extension.dart')
            ..setLastModifiedSync(DateTime.utc(2026));
      final File helperFile = extDir.childDirectory('lib').childFile('helper.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('const int v = 1;')
        ..setLastModifiedSync(DateTime.utc(2026));

      final File packageConfigFile = _writePackageConfig(appDir, const <String, String>{
        'app': '../',
        'my_ext': '/workspace/my_ext',
        'local_dep': '/workspace/local_dep_v1',
      })..setLastModifiedSync(DateTime.utc(2026));

      final File stampFile = fs.file('$expectedDillPath.stamp');
      final DiscoveredProjectExtension ext = _discoveredExtension(fs);

      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          modified: DateTime.utc(2026, 1, 1, 2),
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[4, 5, 6],
          modified: DateTime.utc(2026, 1, 1, 4),
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);

      // 1. Before compile, readCachedCapabilities is null.
      expect(compiler.readCachedCapabilities(ext), isNull);

      // 2. Compile writes extension.dill.stamp without capabilities.
      await compiler.compile(ext);
      expect(stampFile.existsSync(), isTrue);
      expect(compiler.readCachedCapabilities(ext), isNull);

      // 3. writeCachedCapabilities persists capabilities into extension.dill.stamp.
      const expectedCapabilities = ToolExtensionCapabilities(
        extensionName: 'my_ext',
        services: <String>['diagnostics', 'device'],
        supportedPlatforms: <String>{'linux'},
      );
      await compiler.writeCachedCapabilities(ext, expectedCapabilities);
      final ToolExtensionCapabilities? cached = compiler.readCachedCapabilities(ext);
      expect(cached, isNotNull);
      expect(cached!.extensionName, 'my_ext');
      expect(cached.services, const <String>['diagnostics', 'device']);
      expect(cached.supportedPlatforms, const <String>{'linux'});

      // 4. Freshness check ordering BEFORE compile():
      // (a) Modifying a .dart source listed in extension.dill.d invalidates readCachedCapabilities immediately.
      helperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 3));
      expect(compiler.readCachedCapabilities(ext), isNull);
      helperFile.setLastModifiedSync(DateTime.utc(2026));
      expect(compiler.readCachedCapabilities(ext), isNotNull);

      // (b) Touching package_config.json invalidates readCachedCapabilities immediately.
      packageConfigFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 3));
      expect(compiler.readCachedCapabilities(ext), isNull);
      packageConfigFile.setLastModifiedSync(DateTime.utc(2026));
      expect(compiler.readCachedCapabilities(ext), isNotNull);

      // (c) Changing sdkRevision (even with an older mtime, e.g. fvm downgrade) invalidates readCachedCapabilities immediately.
      final File revisionFile = fs.file('/flutter/bin/cache/dart-sdk/revision');
      final String originalRevision = revisionFile.readAsStringSync();
      revisionFile
        ..writeAsStringSync('0000000000000000000000000000000000000000\n')
        ..setLastModifiedSync(DateTime.utc(2025));
      expect(compiler.readCachedCapabilities(ext), isNull);
      revisionFile
        ..writeAsStringSync(originalRevision)
        ..setLastModifiedSync(DateTime.utc(2026));
      expect(compiler.readCachedCapabilities(ext), isNotNull);

      // (d) Changing closureHash in package_config.json (even with identical mtime) invalidates readCachedCapabilities immediately
      // and triggers recompilation on compile(), updating extension.dill.stamp BEFORE renaming tempDillFile.
      watchRecompileRename = true;
      _writePackageConfig(appDir, const <String, String>{
        'app': '../',
        'my_ext': '/workspace/my_ext',
        'local_dep': '/workspace/local_dep_v2',
      }).setLastModifiedSync(DateTime.utc(2026));
      expect(compiler.readCachedCapabilities(ext), isNull);

      await compiler.compile(ext);
      expect(stampClearedBeforeDillRename, isTrue);
      expect(compiler.readCachedCapabilities(ext), isNull);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('falls back to Tier 2 workspace-local cache without ToolExit when DART_DATA_HOME is read-only under ErrorHandlingFileSystem', () async {
      final delegateFs = MemoryFileSystem.test(
        style: const LocalPlatform().isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
        opHandle: (String context, FileSystemOp operation) {
          if (context.contains('readonly_data_home') &&
              (operation == FileSystemOp.create || operation == FileSystemOp.open)) {
            throw FileSystemException(
              'Read-only file system',
              context,
              const OSError('Read-only file system', 30),
            );
          }
        },
      );
      final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
      final String root = fs.currentDirectory.path;
      final String pubPath = fs.path.join(root, 'pub');
      final String readOnlyDataHomePath = fs.path.join(root, 'readonly_data_home');
      final String extRoot = fs.path.join(pubPath, 'hosted', 'pub.dev', 'hosted_ext-1.0.0');
      _writeExtensionPackage(fs.directory(extRoot), name: 'hosted_ext');
      final File entrypointFile = fs.file(
        fs.path.join(extRoot, 'extension', 'flutter_tools', 'extension.dart'),
      )..setLastModifiedSync(DateTime.utc(2026));

      final Directory appDir = fs.directory(fs.path.join(root, 'workspace', 'app'));
      final File configFile = _writePackageConfig(appDir, <String, String>{
        'app': '../',
        'hosted_ext': extRoot,
      })..setLastModifiedSync(DateTime.utc(2026));

      final DiscoveredProjectExtension ext = _discoveredExtension(
        fs,
        name: 'hosted_ext',
        rootPath: extRoot,
        workspaceRootPath: appDir.path,
      );
      final String fallbackLocalDillPath = fs.path.join(
        appDir.path,
        '.dart_tool',
        'flutter_tools',
        'extensions',
        'hosted_ext',
        'extension.dill',
      );
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: fallbackLocalDillPath,
          packageConfigPath: configFile.path,
          bytes: const <int>[8, 8, 8],
          modified: DateTime.utc(2026, 1, 1, 2),
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        logger: logger,
        environment: <String, String>{'DART_DATA_HOME': readOnlyDataHomePath},
        processManager: processManager,
      );

      expect(compiler.isSharedCacheExtension(ext), isTrue);

      // 1. compile() catches the read-only shared cache failure and compiles to Tier 2 fallback.
      final Uri compiledUri = await compiler.compile(ext);
      expect(compiledUri, fs.file(fallbackLocalDillPath).uri);
      expect(logger.traceText, contains('shared cache unavailable'));

      // 2. Subsequent compile() hits the Tier 2 fallback cache without invoking dart compile kernel.
      final Uri cachedUri = await compiler.compile(ext);
      expect(cachedUri, fs.file(fallbackLocalDillPath).uri);

      // 3. writeCachedCapabilities and readCachedCapabilities operate on the Tier 2 fallback stamp.
      const expectedCapabilities = ToolExtensionCapabilities(
        extensionName: 'hosted_ext',
        services: <String>['diagnostics'],
        supportedPlatforms: <String>{'linux'},
      );
      await compiler.writeCachedCapabilities(ext, expectedCapabilities);
      final ToolExtensionCapabilities? readBack = compiler.readCachedCapabilities(ext);
      expect(readBack, isNotNull);
      expect(readBack!.extensionName, 'hosted_ext');
      expect(readBack.services, const <String>['diagnostics']);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('concurrent compile and writeCachedCapabilities preserve ErrorHandlingFileSystem ToolExit state', () async {
      final delegateFs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (context == '/nonexistent' && operation == FileSystemOp.open) {
            throw const FileSystemException(
              'No such file or directory',
              '/nonexistent',
              OSError('No such file or directory', 2),
            );
          }
        },
      );
      final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
      final Directory appDir = fs.directory('/workspace/app');
      _writeExtensionPackage(fs.directory('/workspace/ext_a'), name: 'ext_a');
      _writeExtensionPackage(fs.directory('/workspace/ext_b'), name: 'ext_b');
      final File configFile = _writePackageConfig(appDir, const <String, String>{
        'app': '../',
        'ext_a': '/workspace/ext_a',
        'ext_b': '/workspace/ext_b',
      })..setLastModifiedSync(DateTime.utc(2026));

      const dillAPath = '/workspace/app/.dart_tool/flutter_tools/extensions/ext_a/extension.dill';
      const dillBPath = '/workspace/app/.dart_tool/flutter_tools/extensions/ext_b/extension.dill';
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/ext_a/extension/flutter_tools/extension.dart',
          outputDillPath: dillAPath,
          packageConfigPath: configFile.path,
          modified: DateTime.utc(2026, 1, 1, 2),
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/ext_b/extension/flutter_tools/extension.dart',
          outputDillPath: dillBPath,
          packageConfigPath: configFile.path,
          modified: DateTime.utc(2026, 1, 1, 2),
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);
      final DiscoveredProjectExtension extA = _discoveredExtension(
        fs,
        name: 'ext_a',
        rootPath: '/workspace/ext_a',
      );
      final DiscoveredProjectExtension extB = _discoveredExtension(
        fs,
        name: 'ext_b',
        rootPath: '/workspace/ext_b',
      );

      await Future.wait(<Future<Uri>>[compiler.compile(extA), compiler.compile(extB)]);
      await Future.wait(<Future<void>>[
        compiler.writeCachedCapabilities(
          extA,
          const ToolExtensionCapabilities(services: <String>['diagnostics']),
        ),
        compiler.writeCachedCapabilities(
          extB,
          const ToolExtensionCapabilities(services: <String>['build']),
        ),
      ]);

      // Verify ErrorHandlingFileSystem._noExitOnFailure was not left stuck true.
      expect(() => fs.file('/nonexistent').openSync(), throwsToolExit());
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}
