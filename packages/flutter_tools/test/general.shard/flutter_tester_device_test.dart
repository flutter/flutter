// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:dds/dds.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/test/font_config_manager.dart';
import 'package:flutter_tools/src/test/flutter_tester_device.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  FakePlatform platform;
  FileSystem fileSystem;
  ProcessManager processManager;
  FlutterTesterTestDevice device;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    // Not Windows.
    platform = FakePlatform(
      operatingSystem: 'linux',
      environment: <String, String>{},
    );
    processManager = FakeProcessManager.any();
  });

  FlutterTesterTestDevice createDevice({
    List<String> dartEntrypointArgs = const <String>[],
    bool enableObservatory = false,
  }) =>
    TestFlutterTesterDevice(
      platform: platform,
      fileSystem: fileSystem,
      processManager: processManager,
      enableObservatory: enableObservatory,
      dartEntrypointArgs: dartEntrypointArgs,
    );

  group('The FLUTTER_TEST environment variable is passed to the test process', () {
    setUp(() {
      processManager = MockProcessManager();
      device = createDevice();

      fileSystem
          .file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"configVersion":2,"packages":[]}');
    });

    Future<Map<String, String>> captureEnvironment() async {
      final Future<StreamChannel<String>> deviceStarted = device.start(
          compiledEntrypointPath: 'example.dill',
      );

      when(processManager.start(
        any,
        environment: anyNamed('environment')),
      ).thenAnswer((_) {
        return Future<Process>.value(MockProcess());
      });
      await untilCalled(processManager.start(any, environment: anyNamed('environment')));
      final VerificationResult toVerify = verify(processManager.start(
        any,
        environment: captureAnyNamed('environment'),
      ));
      expect(toVerify.captured, hasLength(1));
      expect(toVerify.captured.first, isA<Map<String, String>>());
      await deviceStarted;
      return toVerify.captured.first as Map<String, String>;
    }

    testUsingContext('as true when not originally set', () async {
      final Map<String, String> capturedEnvironment = await captureEnvironment();
      expect(capturedEnvironment['FLUTTER_TEST'], 'true');
    });

    testUsingContext('as true when set to true', () async {
      platform.environment = <String, String>{'FLUTTER_TEST': 'true'};
      final Map<String, String> capturedEnvironment = await captureEnvironment();
      expect(capturedEnvironment['FLUTTER_TEST'], 'true');
    });

    testUsingContext('as false when set to false', () async {
      platform.environment = <String, String>{'FLUTTER_TEST': 'false'};
      final Map<String, String> capturedEnvironment = await captureEnvironment();
      expect(capturedEnvironment['FLUTTER_TEST'], 'false');
    });

    testUsingContext('unchanged when set', () async {
      platform.environment = <String, String>{'FLUTTER_TEST': 'neither true nor false'};
      final Map<String, String> capturedEnvironment = await captureEnvironment();
      expect(capturedEnvironment['FLUTTER_TEST'], 'neither true nor false');
    });

    testUsingContext('as null when set to null', () async {
      platform.environment = <String, String>{'FLUTTER_TEST': null};
      final Map<String, String> capturedEnvironment = await captureEnvironment();
      expect(capturedEnvironment['FLUTTER_TEST'], null);
    });
  });

  group('Dart Entrypoint Args', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            '/',
            '--disable-observatory',
            '--ipv6',
            '--enable-checked-mode',
            '--verify-entry-points',
            '--enable-software-rendering',
            '--skia-deterministic-rendering',
            '--enable-dart-profiling',
            '--non-interactive',
            '--use-test-fonts',
            '--packages=.dart_tool/package_config.json',
            '--foo',
            '--bar',
            'example.dill'
          ],
          stdout: 'success',
          stderr: 'failure',
          exitCode: 0,
        )
      ]);
      device = createDevice(dartEntrypointArgs: <String>['--foo', '--bar']);
    });

    testUsingContext('Can pass additional arguments to tester binary', () async {
      await device.start(compiledEntrypointPath: 'example.dill');

      expect((processManager as FakeProcessManager).hasRemainingExpectations, false);
    });
  });

  group('DDS', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            '/',
            '--observatory-port=0',
            '--ipv6',
            '--enable-checked-mode',
            '--verify-entry-points',
            '--enable-software-rendering',
            '--skia-deterministic-rendering',
            '--enable-dart-profiling',
            '--non-interactive',
            '--use-test-fonts',
            '--packages=.dart_tool/package_config.json',
            'example.dill'
          ],
          stdout: 'Observatory listening on http://localhost:1234',
          stderr: 'failure',
          exitCode: 0,
        )
      ]);
      device = createDevice(enableObservatory: true);
    });

    testUsingContext('skips setting observatory port and uses the input port for for DDS instead', () async {
      await device.start(compiledEntrypointPath: 'example.dill');
      await device.observatoryUri;

      final Uri uri = await (device as TestFlutterTesterDevice).ddsServiceUriFuture();
      expect(uri.port, 1234);
    });
  });
}

/// A Flutter Tester device.
///
/// Uses a mock HttpServer. We don't want to bind random ports in our CI hosts.
class TestFlutterTesterDevice extends FlutterTesterTestDevice {
  TestFlutterTesterDevice({
    @required Platform platform,
    @required FileSystem fileSystem,
    @required ProcessManager processManager,
    @required bool enableObservatory,
    @required List<String> dartEntrypointArgs,
  }) : super(
    id: 999,
    shellPath: '/',
    platform: platform,
    fileSystem: fileSystem,
    processManager: processManager,
    logger: MockLogger(),
    debuggingOptions: DebuggingOptions.enabled(
      const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        packagesPath: '.dart_tool/package_config.json',
      ),
      startPaused: false,
      disableDds: false,
      disableServiceAuthCodes: false,
      hostVmServicePort: 1234,
      nullAssertions: false,
      dartEntrypointArgs: dartEntrypointArgs,
    ),
    enableObservatory: enableObservatory,
    machine: false,
    host: InternetAddress.loopbackIPv6,
    buildTestAssets: false,
    flutterProject: null,
    icudtlPath: null,
    compileExpression: null,
    fontConfigManager: FontConfigManager(),
  );

  final Completer<Uri> _ddsServiceUriCompleter = Completer<Uri>();

  Future<Uri> ddsServiceUriFuture() => _ddsServiceUriCompleter.future;

  @override
  Future<DartDevelopmentService> startDds(Uri uri) async {
    _ddsServiceUriCompleter.complete(uri);
    final MockDartDevelopmentService mock = MockDartDevelopmentService();
    when(mock.uri).thenReturn(Uri.parse('http://localhost:${debuggingOptions.hostVmServicePort}'));
    return mock;
  }

  @override
  Future<HttpServer> bind(InternetAddress host, int port) async => MockHttpServer();

  @override
  Future<StreamChannel<String>> get remoteChannel async => StreamChannelController<String>().foreign;
}

class MockDartDevelopmentService extends Mock implements DartDevelopmentService {}

class MockHttpServer extends Mock implements HttpServer {}

class MockLogger extends Mock implements Logger {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {
  @override
  Future<int> get exitCode async => 0;

  @override
  Stream<List<int>> get stdout => const Stream<List<int>>.empty();

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();
}
