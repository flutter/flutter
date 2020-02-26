// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Process;

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockLogger extends Mock implements Logger {}
class MockPlatform extends Mock implements Platform {}
class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}

void main () {
  group('IOSDeploy()', () {
    Artifacts mockArtifacts;
    Cache mockCache;
    IOSDeploy iosDeploy;
    Logger mockLogger;
    Platform mockPlatform;
    ProcessManager mockProcessManager;
    const String iosDeployPath = '/path/to/ios-deploy';
    const String deviceId = '123';
    const String bundleId = 'com.example.app';

    setUp(() {
      mockArtifacts = MockArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.iosDeploy, platform: TargetPlatform.ios))
        .thenReturn(iosDeployPath);
      mockCache = MockCache();
      const MapEntry<String, String> mapEntry = MapEntry<String, String>('DYLD_LIBRARY_PATH', '/path/to/libs');
      when(mockCache.dyLdLibEntry).thenReturn(mapEntry);
      mockLogger = MockLogger();
      mockPlatform = MockPlatform();
      when(mockPlatform.environment).thenReturn(<String, String>{
        'PATH': '/usr/local/bin:/usr/bin',
      });
      mockProcessManager = MockProcessManager();
      iosDeploy = IOSDeploy(
        artifacts: mockArtifacts,
        cache: mockCache,
        logger: mockLogger,
        platform: mockPlatform,
        processManager: mockProcessManager,
      );
    });

    testWithoutContext('iosDeployEnv returns path with /usr/bin first', () {
      final Map<String, String> env = iosDeploy.iosDeployEnv;
      expect(env['PATH'].startsWith('/usr/bin'), true);
    });

    testWithoutContext('uninstallApp() calls ios-deploy with correct arguments and returns 0 on success', () async {
      final List<String> args = <String>[
        iosDeployPath,
        '--id',
        deviceId,
        '--uninstall_only',
        '--bundle_id',
        bundleId,
      ];
      when(mockProcessManager.start(
        args,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(createMockProcess(exitCode: 0)));
      final int exitCode = await iosDeploy.uninstallApp(
        deviceId: deviceId,
        bundleId: bundleId,
      );

      verify(mockProcessManager.start(
        args,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      ));
      expect(exitCode, 0);
    });

    testWithoutContext('uninstallApp() returns non-zero exit code when ios-deploy does the same', () async {
      final List<String> args = <String>[
        iosDeployPath,
        '--id',
        deviceId,
        '--uninstall_only',
        '--bundle_id',
        bundleId,
      ];
      when(mockProcessManager.start(
        args,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(createMockProcess(exitCode: 1)));
      final int exitCode = await iosDeploy.uninstallApp(
        deviceId: deviceId,
        bundleId: bundleId,
      );

      verify(mockProcessManager.start(
        args,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      ));
      expect(exitCode, 1);
    });
  });
}
