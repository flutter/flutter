// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const Map<String, String> kDyLdLibEntry = <String, String>{
  'DYLD_LIBRARY_PATH': '/path/to/libs',
};

void main() {
  testWithoutContext('IOSDevice.installApp calls ios-deploy correctly', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleDir: fileSystem.currentDirectory,
    );
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'ios-deploy',
        '--id',
        '1234',
        '--bundle',
        '/',
        '--no-wifi',
      ], environment: <String, String>{
        'PATH': '/usr/bin:null',
        ...kDyLdLibEntry,
      })
    ]);
    final IOSDevice device = setUpIOSDevice(
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final bool wasInstalled = await device.installApp(iosApp);

    expect(wasInstalled, true);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('IOSDevice.uninstallApp calls ios-deploy correctly', () async {
    final IOSApp iosApp = PrebuiltIOSApp(projectBundleId: 'app');
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'ios-deploy',
        '--id',
        '1234',
        '--uninstall_only',
        '--bundle_id',
        'app',
      ], environment: <String, String>{
        'PATH': '/usr/bin:null',
        ...kDyLdLibEntry,
      })
    ]);
    final IOSDevice device = setUpIOSDevice(processManager: processManager);
    final bool wasUninstalled = await device.uninstallApp(iosApp);

    expect(wasUninstalled, true);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('IOSDevice.isAppInstalled catches ProcessException from ios-deploy', () async {
    final IOSApp iosApp = PrebuiltIOSApp(projectBundleId: 'app');
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(command: const <String>[
        'ios-deploy',
        '--id',
        '1234',
        '--exists',
        '--bundle_id',
        'app',
      ], environment: const <String, String>{
        'PATH': '/usr/bin:null',
        ...kDyLdLibEntry,
      }, onRun: () {
        throw const ProcessException('ios-deploy', <String>[]);
      })
    ]);
    final IOSDevice device = setUpIOSDevice(processManager: processManager);
    final bool isAppInstalled = await device.isAppInstalled(iosApp);

    expect(isAppInstalled, false);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('IOSDevice.installApp catches ProcessException from ios-deploy', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleDir: fileSystem.currentDirectory,
    );
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(command: const <String>[
        'ios-deploy',
        '--id',
        '1234',
        '--bundle',
        '/',
        '--no-wifi',
      ], environment: const <String, String>{
        'PATH': '/usr/bin:null',
        ...kDyLdLibEntry,
      }, onRun: () {
        throw const ProcessException('ios-deploy', <String>[]);
      })
    ]);
    final IOSDevice device = setUpIOSDevice(processManager: processManager);
    final bool wasAppInstalled = await device.installApp(iosApp);

    expect(wasAppInstalled, false);
  });

  testWithoutContext('IOSDevice.uninstallApp catches ProcessException from ios-deploy', () async {
    final IOSApp iosApp = PrebuiltIOSApp(projectBundleId: 'app');
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(command: const <String>[
        'ios-deploy',
        '--id',
        '1234',
        '--uninstall_only',
        '--bundle_id',
        'app',
      ], environment: const <String, String>{
        'PATH': '/usr/bin:null',
        ...kDyLdLibEntry,
      }, onRun: () {
        throw const ProcessException('ios-deploy', <String>[]);
      })
    ]);
    final IOSDevice device = setUpIOSDevice(processManager: processManager);
    final bool wasAppUninstalled = await device.uninstallApp(iosApp);

    expect(wasAppUninstalled, false);
  });
}

IOSDevice setUpIOSDevice({
  @required ProcessManager processManager,
  FileSystem fileSystem,
}) {
  final FakePlatform platform = FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{},
  );
  final MockArtifacts artifacts = MockArtifacts();
  final MockCache cache = MockCache();
  when(cache.dyLdLibEntry).thenReturn(kDyLdLibEntry.entries.first);
  when(artifacts.getArtifactPath(Artifact.iosDeploy, platform: anyNamed('platform')))
    .thenReturn('ios-deploy');
  return IOSDevice(
    '1234',
    name: 'iPhone 1',
    logger: BufferLogger.test(),
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    sdkVersion: '13.3',
    cpuArchitecture: DarwinArch.arm64,
    platform: platform,
    iosDeploy: IOSDeploy(
      logger: BufferLogger.test(),
      platform: platform,
      processManager: processManager,
      artifacts: artifacts,
      cache: cache,
    ),
    artifacts: artifacts,
  );
}

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
