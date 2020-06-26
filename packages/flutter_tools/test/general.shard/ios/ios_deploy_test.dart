// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/devices.dart';
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

  group('IOSDeploy.prepareDebuggerForLaunch', () {
    testWithoutContext('calls ios-deploy with correct arguments and returns when debugger attaches', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'script',
            '-t',
            '0',
            '/dev/null',
            'ios-deploy',
            '--id',
            '123',
            '--bundle',
            '/',
            '--debug',
            '--args',
            <String>[
              '--enable-dart-profiling',
            ].join(' '),
          ], environment: const <String, String>{
            'PATH': '/usr/bin:/usr/local/bin:/usr/bin',
            'DYLD_LIBRARY_PATH': '/path/to/libs',
          },
          stdout: '(lldb)     run\nsuccess\nDid finish launching.',
        ),
      ]);
      final IOSDeploy iosDeploy = setUpIOSDeploy(processManager);
      final IOSDeployDebugger iosDeployDebugger = iosDeploy.prepareDebuggerForLaunch(
        deviceId: '123',
        bundlePath: '/',
        launchArguments: <String>['--enable-dart-profiling'],
        interfaceType: IOSDeviceInterface.network,
      );

      expect(await iosDeployDebugger.launchAndAttach(), isTrue);
      expect(await iosDeployDebugger.logLines.toList(), <String>['Did finish launching.']);
      expect(processManager.hasRemainingExpectations, false);
    });
  });

  group('IOSDeployDebugger', () {
    group('launch', () {
      BufferLogger logger;

      setUp(() {
        logger = BufferLogger.test();
      });

      testWithoutContext('debugger attached', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout: '(lldb)     run\r\nsuccess\r\nLog on attach1\r\n\r\nLog on attach2\r\n\r\n\r\n\r\nPROCESS_STOPPED\r\nLog after process exit',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        final List<String> receivedLogLines = <String>[];
        final Stream<String> logLines = iosDeployDebugger.logLines
          ..listen(receivedLogLines.add);

        await iosDeployDebugger.launchAndAttach();
        await logLines.toList();
        // Debugger lines are double spaced, separated by an extra \r\n. Skip the extra lines.
        // Still include empty lines other than the extra added newlines.
        expect(receivedLogLines, <String>['Log on attach1', 'Log on attach2', '', '']);
      });

      testWithoutContext('no provisioning profile 1', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout: 'Error 0xe8008015',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );

        await iosDeployDebugger.launchAndAttach();
        expect(logger.errorText, contains('No Provisioning Profile was found'));
      });

      testWithoutContext('no provisioning profile 2', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout: 'Error 0xe8000067',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        await iosDeployDebugger.launchAndAttach();
        expect(logger.errorText, contains('No Provisioning Profile was found'));
      });

      testWithoutContext('device locked', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout: 'e80000e2',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        await iosDeployDebugger.launchAndAttach();
        expect(logger.errorText, contains('Your device is locked.'));
      });

      testWithoutContext('device locked', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout: 'Error 0xe8000022',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        await iosDeployDebugger.launchAndAttach();
        expect(logger.errorText, contains('Try launching from within Xcode'));
      });
    });

    testWithoutContext('detach', () async {
      final StreamController<List<int>> stdin = StreamController<List<int>>();
      final Stream<String> stdinStream = stdin.stream.transform<String>(const Utf8Decoder());
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'ios-deploy',
          ],
          stdout: '(lldb)     run\nsuccess',
          stdin: IOSink(stdin.sink),
        ),
      ]);
      final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
        processManager: processManager,
      );
      await iosDeployDebugger.launchAndAttach();
      iosDeployDebugger.detach();
      expect(await stdinStream.first, 'process detach');
    });
  });

  group('IOSDeploy.uninstallApp', () {
    testWithoutContext('calls ios-deploy with correct arguments and returns 0 on success', () async {
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

    testWithoutContext('returns non-zero exit code when ios-deploy does the same', () async {
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
