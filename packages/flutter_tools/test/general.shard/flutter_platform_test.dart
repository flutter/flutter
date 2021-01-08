// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test_core/backend.dart'; // ignore: deprecated_member_use

import '../src/common.dart';
import '../src/context.dart';

void main() {
  FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem
      .file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion":2,"packages":[]}');
  });

  group('FlutterPlatform', () {
    testUsingContext('ensureConfiguration throws an error if an '
      'explicitObservatoryPort is specified and more than one test file', () async {
      final FlutterPlatform flutterPlatform = FlutterPlatform(
        buildInfo: BuildInfo.debug,
        shellPath: '/',
        explicitObservatoryPort: 1234,
      );
      flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());

      expect(() => flutterPlatform.loadChannel('test2.dart', MockSuitePlatform()), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('ensureConfiguration throws an error if a precompiled '
      'entrypoint is specified and more that one test file', () {
      final FlutterPlatform flutterPlatform = FlutterPlatform(
        buildInfo: BuildInfo.debug,
        shellPath: '/',
        precompiledDillPath: 'example.dill',
      );
      flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());

      expect(() => flutterPlatform.loadChannel('test2.dart', MockSuitePlatform()), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    group('Observatory and DDS setup', () {
      Platform fakePlatform;
      ProcessManager mockProcessManager;
      FlutterPlatform flutterPlatform;
      final Map<Type, Generator> contextOverrides = <Type, Generator>{
        Platform: () => fakePlatform,
        ProcessManager: () => mockProcessManager,
        FileSystem: () => fileSystem,
      };

      setUp(() {
        fakePlatform = FakePlatform(operatingSystem: 'linux', environment: <String, String>{});
        mockProcessManager = FakeProcessManager.list(<FakeCommand>[
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
            stdout: 'success',
            stderr: 'failure',
            exitCode: 0,
          )
        ]);
        flutterPlatform = TestObservatoryFlutterPlatform();
      });

      testUsingContext('skips setting observatory port and uses the input port for for DDS instead', () async {
        flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());
        final TestObservatoryFlutterPlatform testPlatform = flutterPlatform as TestObservatoryFlutterPlatform;
        await testPlatform.ddsServiceUriFuture().then((Uri uri) => expect(uri.port, 1234));
      }, overrides: contextOverrides);
    });

    group('The FLUTTER_TEST environment variable is passed to the test process', () {
      MockPlatform mockPlatform;
      MockProcessManager mockProcessManager;
      FlutterPlatform flutterPlatform;
      final Map<Type, Generator> contextOverrides = <Type, Generator>{
        Platform: () => mockPlatform,
        ProcessManager: () => mockProcessManager,
        FileSystem: () => fileSystem,
      };

      setUp(() {
        mockPlatform = MockPlatform();
        when(mockPlatform.isWindows).thenReturn(false);
        mockProcessManager = MockProcessManager();
        flutterPlatform = TestFlutterPlatform();
      });

      Future<Map<String, String>> captureEnvironment() async {
        flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());
        when(mockProcessManager.start(
          any,
          environment: anyNamed('environment')),
        ).thenAnswer((_) {
          return Future<Process>.value(MockProcess());
        });
        await untilCalled(mockProcessManager.start(any, environment: anyNamed('environment')));
        final VerificationResult toVerify = verify(mockProcessManager.start(
          any,
          environment: captureAnyNamed('environment'),
        ));
        expect(toVerify.captured, hasLength(1));
        expect(toVerify.captured.first, isA<Map<String, String>>());
        return toVerify.captured.first as Map<String, String>;
      }

      testUsingContext('as true when not originally set', () async {
        when(mockPlatform.environment).thenReturn(<String, String>{});
        final Map<String, String> capturedEnvironment = await captureEnvironment();
        expect(capturedEnvironment['FLUTTER_TEST'], 'true');
      }, overrides: contextOverrides);

      testUsingContext('as true when set to true', () async {
        when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_TEST': 'true'});
        final Map<String, String> capturedEnvironment = await captureEnvironment();
        expect(capturedEnvironment['FLUTTER_TEST'], 'true');
      }, overrides: contextOverrides);

      testUsingContext('as false when set to false', () async {
        when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_TEST': 'false'});
        final Map<String, String> capturedEnvironment = await captureEnvironment();
        expect(capturedEnvironment['FLUTTER_TEST'], 'false');
      }, overrides: contextOverrides);

      testUsingContext('unchanged when set', () async {
        when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_TEST': 'neither true nor false'});
        final Map<String, String> capturedEnvironment = await captureEnvironment();
        expect(capturedEnvironment['FLUTTER_TEST'], 'neither true nor false');
      }, overrides: contextOverrides);

      testUsingContext('as null when set to null', () async {
        when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_TEST': null});
        final Map<String, String> capturedEnvironment = await captureEnvironment();
        expect(capturedEnvironment['FLUTTER_TEST'], null);
      }, overrides: contextOverrides);
    });

    testUsingContext('installHook creates a FlutterPlatform', () {
      expect(() => installHook(
        buildInfo: BuildInfo.debug,
        shellPath: 'abc',
        enableObservatory: false,
        startPaused: true,
      ), throwsAssertionError);

      expect(() => installHook(
        buildInfo: BuildInfo.debug,
        shellPath: 'abc',
        enableObservatory: false,
        startPaused: false,
        observatoryPort: 123,
      ), throwsAssertionError);

      FlutterPlatform capturedPlatform;
      final Map<String, String> expectedPrecompiledDillFiles = <String, String>{'Key': 'Value'};
      final FlutterPlatform flutterPlatform = installHook(
        shellPath: 'abc',
        enableObservatory: true,
        machine: true,
        startPaused: true,
        disableServiceAuthCodes: true,
        port: 100,
        precompiledDillPath: 'def',
        precompiledDillFiles: expectedPrecompiledDillFiles,
        buildInfo: BuildInfo.debug,
        updateGoldens: true,
        buildTestAssets: true,
        observatoryPort: 200,
        serverType: InternetAddressType.IPv6,
        icudtlPath: 'ghi',
        platformPluginRegistration: (FlutterPlatform platform) {
          capturedPlatform = platform;
        });

      expect(identical(capturedPlatform, flutterPlatform), equals(true));
      expect(flutterPlatform.shellPath, equals('abc'));
      expect(flutterPlatform.enableObservatory, equals(true));
      expect(flutterPlatform.machine, equals(true));
      expect(flutterPlatform.startPaused, equals(true));
      expect(flutterPlatform.disableServiceAuthCodes, equals(true));
      expect(flutterPlatform.port, equals(100));
      expect(flutterPlatform.host, InternetAddress.loopbackIPv6);
      expect(flutterPlatform.explicitObservatoryPort, equals(200));
      expect(flutterPlatform.precompiledDillPath, equals('def'));
      expect(flutterPlatform.precompiledDillFiles, expectedPrecompiledDillFiles);
      expect(flutterPlatform.buildInfo, equals(BuildInfo.debug));
      expect(flutterPlatform.updateGoldens, equals(true));
      expect(flutterPlatform.buildTestAssets, equals(true));
      expect(flutterPlatform.icudtlPath, equals('ghi'));
    });
  });

  FakeProcessManager fakeProcessManager;

  testUsingContext('Can pass additional arguments to tester binary', () async {
    final TestFlutterPlatform platform = TestFlutterPlatform(<String>['--foo', '--bar']);
    platform.loadChannel('test1.dart', MockSuitePlatform());
    await null;

    expect(fakeProcessManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () {
      return fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
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
    }
  });
}

class MockSuitePlatform extends Mock implements SuitePlatform {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}

class MockPlatform extends Mock implements Platform {}

class MockHttpServer extends Mock implements HttpServer {}

// A FlutterPlatform with enough fields set to load and start a test.
//
// Uses a mock HttpServer. We don't want to bind random ports in our CI hosts.
class TestFlutterPlatform extends FlutterPlatform {
  TestFlutterPlatform([List<String> additionalArguments]) : super(
    buildInfo: const BuildInfo(BuildMode.debug, '', treeShakeIcons: false, packagesPath: '.dart_tool/package_config.json'),
    shellPath: '/',
    precompiledDillPath: 'example.dill',
    host: InternetAddress.loopbackIPv6,
    port: 0,
    updateGoldens: false,
    startPaused: false,
    enableObservatory: false,
    buildTestAssets: false,
    disableDds: true,
    additionalArguments: additionalArguments,
  );

  @override
  @protected
  Future<HttpServer> bind(InternetAddress host, int port) async => MockHttpServer();
}

// A FlutterPlatform that enables observatory.
//
// Uses a mock HttpServer. We don't want to bind random ports in our CI hosts.
class TestObservatoryFlutterPlatform extends FlutterPlatform {
  TestObservatoryFlutterPlatform() : super(
    buildInfo: const BuildInfo(BuildMode.debug, '', treeShakeIcons: false, packagesPath: '.dart_tool/package_config.json'),
    shellPath: '/',
    precompiledDillPath: 'example.dill',
    host: InternetAddress.loopbackIPv6,
    port: 0,
    updateGoldens: false,
    startPaused: false,
    enableObservatory: true,
    explicitObservatoryPort: 1234,
    buildTestAssets: false,
    disableServiceAuthCodes: false,
    disableDds: false,
    additionalArguments: null,
  );

  final Completer<Uri> _ddsServiceUriCompleter = Completer<Uri>();

  Future<Uri> ddsServiceUriFuture() {
    return _ddsServiceUriCompleter.future;
  }

  @override
  @protected
  Future<HttpServer> bind(InternetAddress host, int port) async => MockHttpServer();

  @override
  Uri getDdsServiceUri() {
    final Uri result = super.getDdsServiceUri();
    _ddsServiceUriCompleter.complete(result);
    return result;
  }
}
