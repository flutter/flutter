// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart';
import 'package:test_core/backend.dart'; // ignore: deprecated_member_use

import '../src/common.dart';
import '../src/context.dart';

void main() {
  late FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion":2,"packages":[]}');
  });

  group('FlutterPlatform', () {
    late SuitePlatform fakeSuitePlatform;
    setUp(() {
      fakeSuitePlatform = SuitePlatform(Runtime.vm);
    });

    testUsingContext('ensureConfiguration throws an error if an '
      'explicitVmServicePort is specified and more than one test file', () async {
      final FlutterPlatform flutterPlatform = FlutterPlatform(
        shellPath: '/',
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          hostVmServicePort: 1234,
        ),
        enableVmService: false,
      );
      flutterPlatform.loadChannel('test1.dart', fakeSuitePlatform);

      expect(() => flutterPlatform.loadChannel('test2.dart', fakeSuitePlatform), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('ensureConfiguration throws an error if a precompiled '
      'entrypoint is specified and more that one test file', () {
      final FlutterPlatform flutterPlatform = FlutterPlatform(
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        shellPath: '/',
        precompiledDillPath: 'example.dill',
        enableVmService: false,
      );
      flutterPlatform.loadChannel('test1.dart', fakeSuitePlatform);

      expect(() => flutterPlatform.loadChannel('test2.dart', fakeSuitePlatform), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('installHook creates a FlutterPlatform', () {
      expect(() => installHook(
        shellPath: 'abc',
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          startPaused: true,
        ),
      ), throwsAssertionError);

      expect(() => installHook(
        shellPath: 'abc',
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          startPaused: true,
          hostVmServicePort: 123,
        ),
      ), throwsAssertionError);

      FlutterPlatform? capturedPlatform;
      final Map<String, String> expectedPrecompiledDillFiles = <String, String>{'Key': 'Value'};
      final FlutterPlatform flutterPlatform = installHook(
        shellPath: 'abc',
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          startPaused: true,
          disableServiceAuthCodes: true,
          hostVmServicePort: 200,
        ),
        enableVmService: true,
        machine: true,
        precompiledDillPath: 'def',
        precompiledDillFiles: expectedPrecompiledDillFiles,
        updateGoldens: true,
        testAssetDirectory: '/build/test',
        serverType: InternetAddressType.IPv6,
        icudtlPath: 'ghi',
        platformPluginRegistration: (FlutterPlatform platform) {
          capturedPlatform = platform;
        },
        uriConverter: (String input) => '$input/test',
      );

      expect(identical(capturedPlatform, flutterPlatform), equals(true));
      expect(flutterPlatform.shellPath, equals('abc'));
      expect(flutterPlatform.debuggingOptions.buildInfo, equals(BuildInfo.debug));
      expect(flutterPlatform.debuggingOptions.startPaused, equals(true));
      expect(flutterPlatform.debuggingOptions.disableServiceAuthCodes, equals(true));
      expect(flutterPlatform.debuggingOptions.hostVmServicePort, equals(200));
      expect(flutterPlatform.enableVmService, equals(true));
      expect(flutterPlatform.machine, equals(true));
      expect(flutterPlatform.host, InternetAddress.loopbackIPv6);
      expect(flutterPlatform.precompiledDillPath, equals('def'));
      expect(flutterPlatform.precompiledDillFiles, expectedPrecompiledDillFiles);
      expect(flutterPlatform.updateGoldens, equals(true));
      expect(flutterPlatform.testAssetDirectory, '/build/test');
      expect(flutterPlatform.icudtlPath, equals('ghi'));
      expect(flutterPlatform.uriConverter?.call('hello'), 'hello/test');
    });
  });
}
