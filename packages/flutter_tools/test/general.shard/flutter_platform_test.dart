// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    fileSystem.file('.packages').writeAsStringSync('\n');
  });

  group('FlutterPlatform', () {
    testUsingContext('ensureConfiguration throws an error if an '
      'explicitObservatoryPort is specified and more than one test file', () async {
      final FlutterPlatform flutterPlatform = FlutterPlatform(
        buildMode: BuildMode.debug,
        shellPath: '/',
        explicitObservatoryPort: 1234,
        extraFrontEndOptions: <String>[],
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
        buildMode: BuildMode.debug,
        shellPath: '/',
        precompiledDillPath: 'example.dill',
        extraFrontEndOptions: <String>[],
      );
      flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());

      expect(() => flutterPlatform.loadChannel('test2.dart', MockSuitePlatform()), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
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
        buildMode: BuildMode.debug,
        shellPath: 'abc',
        enableObservatory: false,
        startPaused: true,
        extraFrontEndOptions: <String>[],
      ), throwsAssertionError);

      expect(() => installHook(
        buildMode: BuildMode.debug,
        shellPath: 'abc',
        enableObservatory: false,
        startPaused: false,
        observatoryPort: 123,
        extraFrontEndOptions: <String>[],
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
        buildMode: BuildMode.debug,
        trackWidgetCreation: true,
        updateGoldens: true,
        buildTestAssets: true,
        observatoryPort: 200,
        serverType: InternetAddressType.IPv6,
        icudtlPath: 'ghi',
        extraFrontEndOptions: <String>[],
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
      expect(flutterPlatform.buildMode, equals(BuildMode.debug));
      expect(flutterPlatform.trackWidgetCreation, equals(true));
      expect(flutterPlatform.updateGoldens, equals(true));
      expect(flutterPlatform.buildTestAssets, equals(true));
      expect(flutterPlatform.icudtlPath, equals('ghi'));
    });
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
  TestFlutterPlatform() : super(
    buildMode: BuildMode.debug,
    shellPath: '/',
    precompiledDillPath: 'example.dill',
    host: InternetAddress.loopbackIPv6,
    port: 0,
    updateGoldens: false,
    startPaused: false,
    enableObservatory: false,
    buildTestAssets: false,
    extraFrontEndOptions: <String>[],
  );

  @override
  @protected
  Future<HttpServer> bind(InternetAddress host, int port) async => MockHttpServer();
}
