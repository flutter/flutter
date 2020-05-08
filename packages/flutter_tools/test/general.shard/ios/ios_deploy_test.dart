// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main () {
  testWithoutContext('IOSDeploy.iosDeployEnv returns path with /usr/bin first', () {
    final IOSDeploy iosDeploy = setUpIOSDeploy(FakeProcessManager.any());
    final Map<String, String> environment = iosDeploy.iosDeployEnv;

    expect(environment['PATH'], startsWith('/usr/bin'));
  });

  testWithoutContext('IOSDeploy.uninstallApp calls ios-deploy with correct arguments and returns 0 on success', () async {
    const String deviceId = '123';
    const String bundleId = 'com.example.app';
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'ios-deploy',
        '--id',
        deviceId,
        '--uninstall_only',
        '--bundle_id',
        bundleId,
      ])
    ]);
    final IOSDeploy iosDeploy = setUpIOSDeploy(processManager);
    final int exitCode = await iosDeploy.uninstallApp(
      deviceId: deviceId,
      bundleId: bundleId,
    );

    expect(exitCode, 0);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('IOSDeploy.uninstallApp returns non-zero exit code when ios-deploy does the same', () async {
    const String deviceId = '123';
    const String bundleId = 'com.example.app';
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'ios-deploy',
        '--id',
        deviceId,
        '--uninstall_only',
        '--bundle_id',
        bundleId,
      ], exitCode: 1)
    ]);
    final IOSDeploy iosDeploy = setUpIOSDeploy(processManager);
    final int exitCode = await iosDeploy.uninstallApp(
      deviceId: deviceId,
      bundleId: bundleId,
    );

    expect(exitCode, 1);
    expect(processManager.hasRemainingExpectations, false);
  });
}

IOSDeploy setUpIOSDeploy(ProcessManager processManager) {
  const MapEntry<String, String> kDyLdLibEntry = MapEntry<String, String>(
    'DYLD_LIBRARY_PATH', '/path/to/libs',
  );
  final FakePlatform macPlatform = FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{
      'PATH': '/usr/local/bin:/usr/bin'
    }
  );
  final MockArtifacts artifacts = MockArtifacts();
  final MockCache cache = MockCache();

  when(cache.dyLdLibEntry).thenReturn(kDyLdLibEntry);
  when(artifacts.getArtifactPath(Artifact.iosDeploy, platform: anyNamed('platform')))
    .thenReturn('ios-deploy');
  return IOSDeploy(
    logger: BufferLogger.test(),
    platform: macPlatform,
    processManager: processManager,
    artifacts: artifacts,
    cache: cache,
  );
}

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
