// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart';

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test_core/backend.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('FlutterPlatform', () {
    testUsingContext('ensureConfiguration throws an error if an explicitObservatoryPort is specified and more than one test file', () async {
      final FlutterPlatform flutterPlatform = FlutterPlatform(shellPath: '/', explicitObservatoryPort: 1234);
      flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());
      expect(() => flutterPlatform.loadChannel('test2.dart', MockSuitePlatform()), throwsA(isA<ToolExit>()));
    });

    testUsingContext('ensureConfiguration throws an error if a precompiled entrypoint is specified and more that one test file', () {
      final FlutterPlatform flutterPlatform = FlutterPlatform(shellPath: '/', precompiledDillPath: 'example.dill');
      flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());
      expect(() => flutterPlatform.loadChannel('test2.dart', MockSuitePlatform()), throwsA(isA<ToolExit>()));
    });

    group('The FLUTTER_TEST environment variable is passed to the test process', () {
      MockPlatform mockPlatform;
      MockProcessManager mockProcessManager;
      FlutterPlatform flutterPlatform;
      final Map<Type, Generator> contextOverrides = <Type, Generator>{
        Platform: () => mockPlatform,
        ProcessManager: () => mockProcessManager,
      };

      setUp(() {
        mockPlatform = MockPlatform();
        mockProcessManager = MockProcessManager();
        flutterPlatform = FlutterPlatform(
          shellPath: '/',
          precompiledDillPath: 'example.dill',
          host: InternetAddress.loopbackIPv6,
          port: 0,
          updateGoldens: false,
          startPaused: false,
          enableObservatory: false,
          buildTestAssets: false,
        );
      });

      Future<Map<String, String>> captureEnvironment() async {
        flutterPlatform.loadChannel('test1.dart', MockSuitePlatform());
        await untilCalled(mockProcessManager.start(any, environment: anyNamed('environment')));
        final VerificationResult toVerify = verify(mockProcessManager.start(any, environment: captureAnyNamed('environment')));
        expect(toVerify.captured, hasLength(1));
        expect(toVerify.captured.first, isInstanceOf<Map<String, String>>());
        return toVerify.captured.first;
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
  });
}

class MockSuitePlatform extends Mock implements SuitePlatform {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockPlatform extends Mock implements Platform {}
