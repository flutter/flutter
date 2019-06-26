// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart';

import 'package:mockito/mockito.dart';
import 'package:test_core/backend.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('FlutterPlatform', () {
    testUsingContext('ensureConfiguration throws an error if an explicitObservatoryPort is specified and more than one test file', () async {
      final FlutterPlatform flutterPlatfrom = FlutterPlatform(shellPath: '/', explicitObservatoryPort: 1234);
      flutterPlatfrom.loadChannel('test1.dart', MockPlatform());
      expect(() => flutterPlatfrom.loadChannel('test2.dart', MockPlatform()), throwsA(isA<ToolExit>()));
    });

    testUsingContext('ensureConfiguration throws an error if a precompiled entrypoint is specified and more that one test file', () {
      final FlutterPlatform flutterPlatfrom = FlutterPlatform(shellPath: '/', precompiledDillPath: 'example.dill');
      flutterPlatfrom.loadChannel('test1.dart', MockPlatform());
      expect(() => flutterPlatfrom.loadChannel('test2.dart', MockPlatform()), throwsA(isA<ToolExit>()));
    });

    testUsingContext('installHook creates a FlutterPlatform', () {
      expect(() => installHook(
        shellPath: 'abc',
        enableObservatory: false,
        startPaused: true
      ), throwsA(isA<AssertionError>()));

      expect(() => installHook(
        shellPath: 'abc',
        enableObservatory: false,
        startPaused: false,
        observatoryPort: 123
      ), throwsA(isA<AssertionError>()));

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
        trackWidgetCreation: true,
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
      expect(flutterPlatform.trackWidgetCreation, equals(true));
      expect(flutterPlatform.updateGoldens, equals(true));
      expect(flutterPlatform.buildTestAssets, equals(true));
      expect(flutterPlatform.icudtlPath, equals('ghi'));
    });
  });
}

class MockPlatform extends Mock implements SuitePlatform {}
