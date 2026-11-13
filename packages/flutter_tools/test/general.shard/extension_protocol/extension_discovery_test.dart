// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/time.dart';
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

final class _AdvancingClock extends SystemClock {
  _AdvancingClock([DateTime? initial]) : _current = initial ?? DateTime.utc(2026, 1, 1, 1);

  DateTime _current;

  @override
  DateTime now() {
    final DateTime value = _current;
    _current = _current.add(const Duration(hours: 2));
    return value;
  }
}

final class _MutableClock extends SystemClock {
  _MutableClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

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

void _writeExtensionPackage(
  Directory extDir, {
  String entrypointBody = 'void main(List<String> args, Object? message) {}',
  String? name,
}) {
  extDir.childDirectory('extension').childDirectory('flutter_tools').childFile('extension.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(entrypointBody);
}

File _writePackageConfig(
  Directory rootDir, [
  Map<String, String> packageRoots = const <String, String>{},
  Map<String, Object?> extraData = const <String, Object?>{},
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
  SystemClock? clock,
  String? flutterRootPath,
  Logger? logger,
  ProcessManager? processManager,
  String? sdkRevision = '6623b84628f37ca8c5c8e3d217f8d3b72d019f02',
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
  return ExtensionKernelCompiler(
    artifacts: Artifacts.test(fileSystem: fs),
    clock: clock ?? _AdvancingClock(),
    fileSystem: fs,
    flutterRoot: fs.directory(resolvedFlutterRootPath),
    logger: logger ?? BufferLogger.test(),
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
    testWithoutContext('compiles extension to workspace-local .dill and invalidates via depfile or empty .dill', () async {
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

      // Hosted packages in PUB_CACHE also cache in the workspace-local .dart_tool directory.
      final DiscoveredProjectExtension hostedExtension = _discoveredExtension(
        fs,
        name: 'hosted_ext',
        rootPath: '/pub-cache/hosted/pub.dev/hosted_ext-1.2.3',
      );
      expect(
        compiler.resolveDillFile(hostedExtension).path,
        '/workspace/app/.dart_tool/flutter_tools/extensions/hosted_ext/extension.dill',
      );

      // 1. Initial compilation runs `dart compile kernel`.
      final (:String buildToken, dillUri: Uri firstDillUri) = await compiler.compile(extension);
      expect(buildToken, isNotEmpty);
      expect(firstDillUri, fs.file(expectedDillPath).uri);
      expect(fs.file('$expectedDillPath.lock').existsSync(), isTrue);
      expect(fs.file('$expectedDillPath.tmp').existsSync(), isFalse);

      // 2. Second compilation hits the cache without invoking `dart compile kernel`.
      final (buildToken: String cachedToken, dillUri: Uri cachedDillUri) = await compiler.compile(
        extension,
      );
      expect(cachedToken, buildToken);
      expect(fs.file(cachedDillUri).readAsBytesSync(), const <int>[1, 2, 3]);

      // 3. Touching a transitive file listed in extension.dill.d invalidates the cache.
      helperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
      final (buildToken: String recompiledToken, dillUri: Uri recompiledDillUri) = await compiler
          .compile(extension);
      expect(recompiledToken, isNot(buildToken));
      expect(fs.file(recompiledDillUri).readAsBytesSync(), const <int>[4, 5, 6]);

      // 4. Truncating the .dill file to 0 bytes invalidates the cache even with a fresh timestamp.
      fs.file(expectedDillPath)
        ..writeAsBytesSync(const <int>[])
        ..setLastModifiedSync(DateTime.utc(2026, 1, 1, 4));
      final CompiledExtensionKernel emptyRecompiled = await compiler.compile(extension);
      expect(fs.file(emptyRecompiled.dillUri).readAsBytesSync(), const <int>[7, 8, 9]);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('invalidates cached .dill and capabilities when an input file is modified mid-compile before extension.dill is written', () async {
      final fs = MemoryFileSystem.test();
      final File packageConfigFile = _writePackageConfig(fs.directory('/workspace/app'))
        ..setLastModifiedSync(DateTime.utc(2026));
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
      // Start compile mid-second at 01:00:00.500Z so `compiledAt` truncates to 01:00:00.000Z.
      final clock = _MutableClock(DateTime.utc(2026, 1, 1, 1, 0, 0, 500));
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[1, 1, 1],
          // Output .dill finishes writing at 01:00:05, AFTER the mid-compile edit.
          modified: DateTime.utc(2026, 1, 1, 1, 0, 5),
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
          onRunExtra: () {
            // Simulate a user saving `helper.dart` at 01:00:00.800Z on a filesystem
            // with 1-second mtime granularity, which truncates the stored mtime to
            // 01:00:00.000Z (equal to `compiledAt` and earlier than 01:00:00.500Z).
            helperFile
              ..writeAsStringSync('const int version = 2;')
              ..setLastModifiedSync(DateTime.utc(2026, 1, 1, 1));
          },
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[2, 2, 2],
          modified: DateTime.utc(2026, 1, 1, 1, 0, 12),
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
        ),
      ]);

      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        clock: clock,
        processManager: processManager,
      );
      final DiscoveredProjectExtension extension = _discoveredExtension(fs);

      // First compile completes, and `helper.dart` has mtime == `compiledAt` (01:00:00Z)
      // even though `extension.dill` has `lastModified = 01:00:05Z`.
      final CompiledExtensionKernel firstCompile = await compiler.compile(extension);
      expect(
        fs.file(expectedDillPath).lastModifiedSync().toUtc(),
        DateTime.utc(2026, 1, 1, 1, 0, 5),
      );
      expect(helperFile.lastModifiedSync().toUtc(), DateTime.utc(2026, 1, 1, 1));

      // Capabilities must not be persisted or served for an already-invalidated .dill.
      await compiler.writeCachedCapabilities(
        extension,
        const ToolExtensionCapabilities(services: <String>['diagnostics']),
        buildToken: firstCompile.buildToken,
      );
      expect(compiler.readCachedCapabilities(extension), isNull);

      // Next compile at 01:00:10.250Z (truncated to 01:00:10Z) recompiles and self-heals.
      clock.current = DateTime.utc(2026, 1, 1, 1, 0, 10, 250);
      final CompiledExtensionKernel recompiled = await compiler.compile(extension);
      expect(fs.file(recompiled.dillUri).readAsBytesSync(), const <int>[2, 2, 2]);

      // Third compile with no further edits reuses the cached .dill.
      clock.current = DateTime.utc(2026, 1, 1, 1, 0, 20);
      final CompiledExtensionKernel cached = await compiler.compile(extension);
      expect(fs.file(cached.dillUri).readAsBytesSync(), const <int>[2, 2, 2]);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('invalidates cached .dill when package_config.json content changes and ignores no-op mtime bumps', () async {
      final fs = MemoryFileSystem.test();
      final Directory appDir = fs.directory('/workspace/app');
      const extV1Root = '/pub-cache/hosted/pub.dev/my_ext-1.0.0';
      const gitDepCommit1 = '/pub-cache/git/helper-1111111111111111';
      const gitDepCommit2 = '/pub-cache/git/helper-2222222222222222';
      _writeExtensionPackage(fs.directory(extV1Root), name: 'my_ext');
      fs
          .file('$extV1Root/extension/flutter_tools/extension.dart')
          .setLastModifiedSync(DateTime.utc(2026));

      final File packageConfigFile = _writePackageConfig(appDir, const <String, String>{
        'app': '../',
        'my_ext': extV1Root,
        'helper': gitDepCommit1,
      })..setLastModifiedSync(DateTime.utc(2026));

      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      final DiscoveredProjectExtension ext = _discoveredExtension(fs, rootPath: extV1Root);
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: '$extV1Root/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          bytes: const <int>[1],
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: '$extV1Root/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          bytes: const <int>[2],
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);

      await compiler.compile(ext);
      // Bumping package_config.json mtime without changing its bytes (no-op `pub get`) reuses cache.
      packageConfigFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 5));
      expect(fs.file((await compiler.compile(ext)).dillUri).readAsBytesSync(), const <int>[1]);

      // Rewrite package_config.json with a new git commit root, preserving an older mtime
      // (simulating branch checkout or restored workspace state).
      _writePackageConfig(appDir, const <String, String>{
        'app': '../',
        'my_ext': extV1Root,
        'helper': gitDepCommit2,
      });
      packageConfigFile.setLastModifiedSync(DateTime.utc(2025));

      final CompiledExtensionKernel recompiled = await compiler.compile(ext);
      expect(fs.file(recompiled.dillUri).readAsBytesSync(), const <int>[2]);
      expect(fs.file((await compiler.compile(ext)).dillUri).readAsBytesSync(), const <int>[2]);
      expect(processManager, hasNoRemainingExpectations);
    });

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
          depfileContent:
              '$expectedDillPath.tmp: ${entrypointFile.path} /workspace/my_ext/lib/part\\ one.dart\n',
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[2],
        ),
      ]);

      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);
      final DiscoveredProjectExtension extension = _discoveredExtension(fs);

      await compiler.compile(extension);
      await compiler.compile(extension);

      spacedHelperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
      final CompiledExtensionKernel recompiled = await compiler.compile(extension);
      expect(fs.file(recompiled.dillUri).readAsBytesSync(), const <int>[2]);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'Dart SDK revision roll invalidates cached kernel even when revision file mtime is older',
      () async {
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
          ),
          _compileKernelCommand(
            fs,
            entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
            outputDillPath: localDillPath,
            bytes: const <int>[2],
          ),
        ]);
        final ExtensionKernelCompiler compiler = _createCompiler(
          fs,
          processManager: processManager,
          sdkRevision: null,
        );

        await compiler.compile(localExt);
        expect(fs.file((await compiler.compile(localExt)).dillUri).readAsBytesSync(), const <int>[
          1,
        ]);

        // Simulate unpacking a Dart SDK archive whose archived mtime is older than compiledAt.
        revisionFile
          ..writeAsStringSync('9876543210fedcba\n')
          ..setLastModifiedSync(DateTime.utc(2025));
        final CompiledExtensionKernel recompiledAfterRevisionRoll = await compiler.compile(
          localExt,
        );
        expect(fs.file(recompiledAfterRevisionRoll.dillUri).readAsBytesSync(), const <int>[2]);
        final stampJson =
            jsonDecode(fs.file('$localDillPath.stamp').readAsStringSync()) as Map<String, Object?>;
        expect(stampJson['sdkRevision'], '9876543210fedcba');
        expect(fs.file((await compiler.compile(localExt)).dillUri).readAsBytesSync(), const <int>[
          2,
        ]);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext('throws ExtensionCompileException when entrypoint, package_config.json, or bin/cache/dart-sdk/revision is missing', () async {
      final fs = MemoryFileSystem.test();
      final DiscoveredProjectExtension ext = _discoveredExtension(fs);
      final ExtensionKernelCompiler compilerMissingRevision = _createCompiler(
        fs,
        sdkRevision: null,
      );

      // 1. Missing entrypoint.
      await expectLater(
        compilerMissingRevision.compile(ext),
        throwsA(
          isA<ExtensionCompileException>().having(
            (ExtensionCompileException e) => e.message,
            'message',
            contains('entrypoint not found'),
          ),
        ),
      );

      // 2. Missing package_config.json.
      _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');
      await expectLater(
        compilerMissingRevision.compile(ext),
        throwsA(
          isA<ExtensionCompileException>().having(
            (ExtensionCompileException e) => e.message,
            'message',
            contains('without a resolved .dart_tool/package_config.json'),
          ),
        ),
      );

      // 3. Missing bin/cache/dart-sdk/revision.
      _writePackageConfig(fs.directory('/workspace/app'));
      await expectLater(
        compilerMissingRevision.compile(ext),
        throwsA(
          isA<ExtensionCompileException>().having(
            (ExtensionCompileException e) => e.message,
            'message',
            contains('no Dart SDK revision at "/flutter/bin/cache/dart-sdk/revision"'),
          ),
        ),
      );
    });

    testWithoutContext('cleans up temporary files and throws ExtensionCompileException without ToolExit even if temp cleanup hits EACCES', () async {
      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      var throwOnTempDillExists = false;
      var failTempCleanupDelete = false;
      final delegateFs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (throwOnTempDillExists &&
              context == '$expectedDillPath.tmp' &&
              operation == FileSystemOp.exists) {
            throwOnTempDillExists = false;
            throw const FileSystemException('filesystem failure');
          }
          if (failTempCleanupDelete &&
              context.endsWith('.tmp') &&
              operation == FileSystemOp.delete) {
            throw FileSystemException(
              'Permission denied',
              context,
              const OSError('Permission denied', 13),
            );
          }
        },
      );
      final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
      _writePackageConfig(fs.directory('/workspace/app'));
      _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');

      final processManager = FakeProcessManager.list(<FakeCommand>[
        // 1. Non-zero exit code.
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          exitCode: 254,
          stderr: 'Compilation error',
          bytes: const <int>[0],
          depfileContent: 'partial',
        ),
        // 2. Exit 0 with 0-byte output.
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          bytes: const <int>[],
        ),
        // 3. ProcessException.
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          exception: const ProcessException('dart', <String>['compile', 'kernel'], 'spawn error'),
        ),
        // 4. FileSystemException after producing temp artifacts.
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          onRunExtra: () {
            throwOnTempDillExists = true;
          },
        ),
        // 5. Non-zero exit where temp-file deletion throws EACCES under ErrorHandlingFileSystem:
        // must still surface ExtensionCompileException rather than ToolExit.
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/my_ext/extension/flutter_tools/extension.dart',
          outputDillPath: expectedDillPath,
          exitCode: 254,
          stderr: 'Syntax error before EACCES cleanup',
          bytes: const <int>[0],
          onRunExtra: () {
            failTempCleanupDelete = true;
          },
        ),
      ]);

      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);
      final DiscoveredProjectExtension ext = _discoveredExtension(fs);

      for (final expectedMessage in const <String>[
        'Compilation error',
        'did not produce a non-empty',
        'spawn error',
        'filesystem failure',
      ]) {
        await expectLater(
          compiler.compile(ext),
          throwsA(
            isA<ExtensionCompileException>().having(
              (ExtensionCompileException e) => e.message,
              'message',
              contains(expectedMessage),
            ),
          ),
        );
        expect(fs.file(expectedDillPath).existsSync(), isFalse);
        expect(fs.file('$expectedDillPath.tmp').existsSync(), isFalse);
        expect(fs.file('$expectedDillPath.d.tmp').existsSync(), isFalse);
        expect(fs.file('$expectedDillPath.stamp.tmp').existsSync(), isFalse);
      }

      await expectLater(
        compiler.compile(ext),
        throwsA(
          isA<ExtensionCompileException>().having(
            (ExtensionCompileException e) => e.message,
            'message',
            contains('Syntax error before EACCES cleanup'),
          ),
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'deletes pre-existing stale depFile when dart compile kernel does not emit a tempDepFile',
      () async {
        final fs = MemoryFileSystem.test();
        _writePackageConfig(fs.directory('/workspace/app')).setLastModifiedSync(DateTime.utc(2026));
        _writeExtensionPackage(fs.directory('/workspace/my_ext'), name: 'my_ext');
        fs
            .file('/workspace/my_ext/extension/flutter_tools/extension.dart')
            .setLastModifiedSync(DateTime.utc(2026));

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
        final File hostedEntrypoint =
            fs
                .directory(hostedExtRootPath)
                .childDirectory('extension')
                .childDirectory('flutter_tools')
                .childFile('extension.dart')
              ..setLastModifiedSync(DateTime.utc(2026));

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
          flutterRootPath: flutterRootPath,
          processManager: processManager,
        );

        final File localDill = compiler.resolveDillFile(localExt);
        final File hostedDill = compiler.resolveDillFile(hostedExt);
        expect(
          localDill.path,
          r'C:\Users\Developer Name\workspace\app\.dart_tool\flutter_tools\extensions\local_ext\extension.dill',
        );
        expect(
          hostedDill.path,
          r'C:\Users\Developer Name\workspace\app\.dart_tool\flutter_tools\extensions\hosted_ext\extension.dill',
        );

        processManager.addCommands(<FakeCommand>[
          _compileKernelCommand(
            fs,
            entrypointPath: localEntrypoint.path,
            outputDillPath: localDill.path,
            packageConfigPath: packageConfigFile.path,
            bytes: const <int>[1, 2],
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
          ),
          _compileKernelCommand(
            fs,
            entrypointPath: hostedEntrypoint.path,
            outputDillPath: hostedDill.path,
            packageConfigPath: packageConfigFile.path,
            bytes: const <int>[3, 4],
          ),
        ]);

        final CompiledExtensionKernel localCompiled = await compiler.compile(localExt);
        final CompiledExtensionKernel localCached = await compiler.compile(localExt);
        expect(localCompiled.dillUri, localDill.uri);
        expect(localCached.dillUri, localDill.uri);
        expect(localCached.buildToken, localCompiled.buildToken);

        localHelper.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
        final CompiledExtensionKernel localRecompiled = await compiler.compile(localExt);
        expect(fs.file(localRecompiled.dillUri).readAsBytesSync(), const <int>[5, 6]);

        final CompiledExtensionKernel hostedCompiled = await compiler.compile(hostedExt);
        final CompiledExtensionKernel hostedCached = await compiler.compile(hostedExt);
        expect(hostedCompiled.dillUri, hostedDill.uri);
        expect(hostedCached.dillUri, hostedDill.uri);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext('persists, round-trips, validates malformed stamps, and commits .d -> .dill -> .stamp in order', () async {
      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      var newDillPresentAndOldStampRejectedBeforeStampCommit = false;
      var watchRecompileCommitOrder = false;
      ExtensionKernelCompiler? concurrentReader;
      DiscoveredProjectExtension? watchedExtension;
      late final MemoryFileSystem delegateFs;
      delegateFs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (watchRecompileCommitOrder &&
              operation == FileSystemOp.write &&
              context == '$expectedDillPath.stamp.tmp') {
            watchRecompileCommitOrder = false;
            // At the moment the new stamp is being staged (before it is renamed onto `.stamp`),
            // `.d` and `.dill` ([4, 5, 6]) have already been committed into place, while the
            // previous stamp on disk is rejected by an unlocked reader because inputs changed.
            final File activeDill = delegateFs.file(expectedDillPath);
            final bool newDillCommitted =
                activeDill.existsSync() && activeDill.readAsBytesSync().first == 4;
            final oldStampRejected =
                concurrentReader!.readCachedCapabilities(watchedExtension!) == null;
            newDillPresentAndOldStampRejectedBeforeStampCommit =
                newDillCommitted && oldStampRejected;
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
      watchedExtension = ext;

      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[4, 5, 6],
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(fs, processManager: processManager);
      concurrentReader = _createCompiler(fs);

      // 1. Before compile, readCachedCapabilities is null and writeCachedCapabilities is a no-op.
      expect(compiler.readCachedCapabilities(ext), isNull);
      await compiler.writeCachedCapabilities(
        ext,
        const ToolExtensionCapabilities(services: <String>['diagnostics']),
        buildToken: 'nonexistent-token',
      );
      expect(stampFile.existsSync(), isFalse);

      // 2. Compile writes extension.dill.stamp with compiledAt and buildToken and without capabilities.
      final CompiledExtensionKernel firstBuild = await compiler.compile(ext);
      expect(stampFile.existsSync(), isTrue);
      final String validStampContent = stampFile.readAsStringSync();
      final initialStampJson = jsonDecode(validStampContent) as Map<String, Object?>;
      expect(initialStampJson['compiledAt'], '2026-01-01T01:00:00.000Z');
      expect(initialStampJson['buildToken'], firstBuild.buildToken);
      expect(compiler.readCachedCapabilities(ext), isNull);

      // 3. Malformed or incomplete stamp files safely return null from readCachedCapabilities.
      for (final invalidStamp in const <String>[
        '{corrupt json',
        '[1, 2, 3]',
        '{}',
        '{"buildToken": "tok", "compiledAt": "not-a-date", "packageConfigHash": "abc", "sdkRevision": "rev"}',
      ]) {
        stampFile.writeAsStringSync(invalidStamp);
        expect(compiler.readCachedCapabilities(ext), isNull);
      }
      stampFile.writeAsStringSync(validStampContent);

      // 4. writeCachedCapabilities persists capabilities into extension.dill.stamp while preserving compiledAt.
      const expectedCapabilities = ToolExtensionCapabilities(
        extensionName: 'my_ext',
        services: <String>['diagnostics', 'device'],
        supportedPlatforms: <String>{'linux'},
      );
      await compiler.writeCachedCapabilities(
        ext,
        expectedCapabilities,
        buildToken: firstBuild.buildToken,
      );
      final updatedStampJson = jsonDecode(stampFile.readAsStringSync()) as Map<String, Object?>;
      expect(updatedStampJson['compiledAt'], '2026-01-01T01:00:00.000Z');
      final ToolExtensionCapabilities? cached = compiler.readCachedCapabilities(ext);
      expect(cached, isNotNull);
      expect(cached!.extensionName, 'my_ext');
      expect(cached.services, const <String>['diagnostics', 'device']);
      expect(cached.supportedPlatforms, const <String>{'linux'});

      // 5. Freshness check ordering BEFORE compile():
      // (a) Modifying a .dart source listed in extension.dill.d invalidates readCachedCapabilities immediately.
      helperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
      expect(compiler.readCachedCapabilities(ext), isNull);
      helperFile.setLastModifiedSync(DateTime.utc(2026));
      expect(compiler.readCachedCapabilities(ext), isNotNull);

      // (b) Bumping package_config.json mtime without content changes preserves cached capabilities.
      packageConfigFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
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

      // (d) Changing package_config.json bytes (even with older mtime) invalidates readCachedCapabilities immediately
      // and commits `.d` -> `.dill` -> `.stamp` last on compile().
      watchRecompileCommitOrder = true;
      _writePackageConfig(appDir, const <String, String>{
        'app': '../',
        'my_ext': '/workspace/my_ext',
        'local_dep': '/workspace/local_dep_v2',
      }).setLastModifiedSync(DateTime.utc(2026));
      expect(compiler.readCachedCapabilities(ext), isNull);

      await compiler.compile(ext);
      expect(newDillPresentAndOldStampRejectedBeforeStampCommit, isTrue);
      expect(compiler.readCachedCapabilities(ext), isNull);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('writeCachedCapabilities rejects stale capabilities when another compiler instance recompiles concurrently', () async {
      final fs = MemoryFileSystem.test();
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
      })..setLastModifiedSync(DateTime.utc(2026));

      const expectedDillPath =
          '/workspace/app/.dart_tool/flutter_tools/extensions/my_ext/extension.dill';
      final DiscoveredProjectExtension ext = _discoveredExtension(fs);

      final processManagerA = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[1],
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
        ),
      ]);
      final processManagerB = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: entrypointFile.path,
          outputDillPath: expectedDillPath,
          bytes: const <int>[2],
          depfileContent:
              '$expectedDillPath.tmp: ${packageConfigFile.path} ${entrypointFile.path} ${helperFile.path}\n',
        ),
      ]);

      final ExtensionKernelCompiler compilerA = _createCompiler(
        fs,
        clock: _MutableClock(DateTime.utc(2026, 1, 1, 1)),
        processManager: processManagerA,
      );
      final ExtensionKernelCompiler compilerFastPath = _createCompiler(
        fs,
        clock: _MutableClock(DateTime.utc(2026, 1, 1, 1)),
      );
      final ExtensionKernelCompiler compilerB = _createCompiler(
        fs,
        clock: _MutableClock(DateTime.utc(2026, 1, 1, 3)),
        processManager: processManagerB,
      );

      // Process A compiles v1, and another reader hits the fast path for v1.
      final CompiledExtensionKernel buildA = await compilerA.compile(ext);
      final CompiledExtensionKernel buildFastPath = await compilerFastPath.compile(ext);
      expect(buildFastPath.buildToken, buildA.buildToken);

      // Before Process A or the fast-path reader finishes its handshake, the user edits
      // `helper.dart` and Process B recompiles v2 (writing a new buildToken).
      helperFile.setLastModifiedSync(DateTime.utc(2026, 1, 1, 2));
      final CompiledExtensionKernel buildB = await compilerB.compile(ext);
      expect(buildB.buildToken, isNot(buildA.buildToken));
      expect(fs.file(expectedDillPath).readAsBytesSync(), const <int>[2]);

      // Neither Process A nor the fast-path reader may overwrite v2's stamp with v1 capabilities.
      await compilerA.writeCachedCapabilities(
        ext,
        const ToolExtensionCapabilities(services: <String>['diagnostics']),
        buildToken: buildA.buildToken,
      );
      await compilerFastPath.writeCachedCapabilities(
        ext,
        const ToolExtensionCapabilities(services: <String>['config']),
        buildToken: buildFastPath.buildToken,
      );
      expect(compilerB.readCachedCapabilities(ext), isNull);

      // Process B's own capabilities write succeeds because its buildToken matches v2.
      await compilerB.writeCachedCapabilities(
        ext,
        const ToolExtensionCapabilities(services: <String>['diagnostics', 'build']),
        buildToken: buildB.buildToken,
      );
      expect(compilerB.readCachedCapabilities(ext)?.services, const <String>[
        'diagnostics',
        'build',
      ]);
      expect(processManagerA, hasNoRemainingExpectations);
      expect(processManagerB, hasNoRemainingExpectations);
    });

    testWithoutContext('writeCachedCapabilities logs trace on read-only stamp write and concurrent calls preserve ErrorHandlingFileSystem ToolExit state', () async {
      var failStampTempWrite = false;
      final delegateFs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (context == '/nonexistent' && operation == FileSystemOp.open) {
            throw const FileSystemException(
              'No such file or directory',
              '/nonexistent',
              OSError('No such file or directory', 2),
            );
          }
          if (failStampTempWrite &&
              context.endsWith('.stamp.tmp') &&
              operation == FileSystemOp.write) {
            throw FileSystemException(
              'Read-only file system',
              context,
              const OSError('Read-only file system', 30),
            );
          }
        },
      );
      final fs = ErrorHandlingFileSystem(delegate: delegateFs, platform: FakePlatform());
      final Directory appDir = fs.directory('/workspace/app');
      _writeExtensionPackage(fs.directory('/workspace/ext_a'), name: 'ext_a');
      _writeExtensionPackage(fs.directory('/workspace/ext_b'), name: 'ext_b');
      fs
          .file('/workspace/ext_a/extension/flutter_tools/extension.dart')
          .setLastModifiedSync(DateTime.utc(2026));
      fs
          .file('/workspace/ext_b/extension/flutter_tools/extension.dart')
          .setLastModifiedSync(DateTime.utc(2026));
      final File configFile = _writePackageConfig(appDir, const <String, String>{
        'app': '../',
        'ext_a': '/workspace/ext_a',
        'ext_b': '/workspace/ext_b',
      })..setLastModifiedSync(DateTime.utc(2026));

      const dillAPath = '/workspace/app/.dart_tool/flutter_tools/extensions/ext_a/extension.dill';
      const dillBPath = '/workspace/app/.dart_tool/flutter_tools/extensions/ext_b/extension.dill';
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/ext_a/extension/flutter_tools/extension.dart',
          outputDillPath: dillAPath,
          packageConfigPath: configFile.path,
        ),
        _compileKernelCommand(
          fs,
          entrypointPath: '/workspace/ext_b/extension/flutter_tools/extension.dart',
          outputDillPath: dillBPath,
          packageConfigPath: configFile.path,
        ),
      ]);
      final ExtensionKernelCompiler compiler = _createCompiler(
        fs,
        logger: logger,
        processManager: processManager,
      );
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

      final List<CompiledExtensionKernel> compiled = await Future.wait(
        <Future<CompiledExtensionKernel>>[compiler.compile(extA), compiler.compile(extB)],
      );
      await Future.wait(<Future<void>>[
        compiler.writeCachedCapabilities(
          extA,
          const ToolExtensionCapabilities(services: <String>['diagnostics']),
          buildToken: compiled[0].buildToken,
        ),
        compiler.writeCachedCapabilities(
          extB,
          const ToolExtensionCapabilities(services: <String>['build']),
          buildToken: compiled[1].buildToken,
        ),
      ]);

      // Read-only failure during capability persistence logs at trace level without throwing ToolExit.
      failStampTempWrite = true;
      await compiler.writeCachedCapabilities(
        extA,
        const ToolExtensionCapabilities(services: <String>['device']),
        buildToken: compiled[0].buildToken,
      );
      expect(logger.traceText, contains('failed to write capability cache for "ext_a"'));

      // Verify ErrorHandlingFileSystem._noExitOnFailure was not left stuck true.
      expect(() => fs.file('/nonexistent').openSync(), throwsToolExit());
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}
