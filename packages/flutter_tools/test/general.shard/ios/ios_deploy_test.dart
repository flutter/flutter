// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main () {
  Artifacts artifacts;
  String iosDeployPath;
  FileSystem fileSystem;

  setUp(() {
    artifacts = Artifacts.test();
    iosDeployPath = artifacts.getArtifactPath(Artifact.iosDeploy, platform: TargetPlatform.ios);
    fileSystem = MemoryFileSystem.test();
  });

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
            iosDeployPath,
            '--id',
            '123',
            '--bundle',
            '/',
            '--app_deltas',
            'app-delta',
            '--debug',
            '--args',
            <String>[
              '--enable-dart-profiling',
            ].join(' '),
          ], environment: const <String, String>{
            'PATH': '/usr/bin:/usr/local/bin:/usr/bin',
            'DYLD_LIBRARY_PATH': '/path/to/libraries',
          },
          stdout: '(lldb)     run\nsuccess\nDid finish launching.',
        ),
      ]);
      final Directory appDeltaDirectory = fileSystem.directory('app-delta');
      final IOSDeploy iosDeploy = setUpIOSDeploy(processManager, artifacts: artifacts);
      final IOSDeployDebugger iosDeployDebugger = iosDeploy.prepareDebuggerForLaunch(
        deviceId: '123',
        bundlePath: '/',
        appDeltaDirectory: appDeltaDirectory,
        launchArguments: <String>['--enable-dart-profiling'],
        interfaceType: IOSDeviceInterface.network,
      );

      expect(await iosDeployDebugger.launchAndAttach(), isTrue);
      expect(await iosDeployDebugger.logLines.toList(), <String>['Did finish launching.']);
      expect(processManager, hasNoRemainingExpectations);
      expect(appDeltaDirectory, exists);
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
            stdout: '(lldb)     run\r\nsuccess\r\nsuccess\r\nLog on attach1\r\n\r\nLog on attach2\r\n\r\n\r\n\r\nPROCESS_STOPPED\r\nLog after process exit',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        final List<String> receivedLogLines = <String>[];
        final Stream<String> logLines = iosDeployDebugger.logLines
          ..listen(receivedLogLines.add);

        expect(await iosDeployDebugger.launchAndAttach(), isTrue);
        await logLines.toList();
        expect(receivedLogLines, <String>[
          'success', // ignore first "success" from lldb, but log subsequent ones from real logging.
          'Log on attach1',
          'Log on attach2',
          '',
          '',
          'Log after process exit',
        ]);
      });

      testWithoutContext('app exit', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout: '(lldb)     run\r\nsuccess\r\nLog on attach\r\nProcess 100 exited with status = 0\r\nLog after process exit',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        final List<String> receivedLogLines = <String>[];
        final Stream<String> logLines = iosDeployDebugger.logLines
          ..listen(receivedLogLines.add);

        expect(await iosDeployDebugger.launchAndAttach(), isTrue);
        await logLines.toList();
        expect(receivedLogLines, <String>[
          'Log on attach',
          'Log after process exit',
        ]);
      });

      testWithoutContext('app crash', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout:
                '(lldb)     run\r\nsuccess\r\nLog on attach\r\n(lldb) Process 6156 stopped\r\n* thread #1, stop reason = Assertion failed:',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        final List<String> receivedLogLines = <String>[];
        final Stream<String> logLines = iosDeployDebugger.logLines
          ..listen(receivedLogLines.add);

        expect(await iosDeployDebugger.launchAndAttach(), isTrue);
        await logLines.toList();
        expect(receivedLogLines, <String>[
          'Log on attach',
          '* thread #1, stop reason = Assertion failed:',
        ]);
      });

      testWithoutContext('attach failed', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            // A success after an error should never happen, but test that we're handling random "successes" anyway.
            stdout: '(lldb)     run\r\nerror: process launch failed\r\nsuccess\r\nLog on attach1',
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        final List<String> receivedLogLines = <String>[];
        final Stream<String> logLines = iosDeployDebugger.logLines
          ..listen(receivedLogLines.add);

        expect(await iosDeployDebugger.launchAndAttach(), isFalse);
        await logLines.toList();
        // Debugger lines are double spaced, separated by an extra \r\n. Skip the extra lines.
        // Still include empty lines other than the extra added newlines.
        expect(receivedLogLines, isEmpty);
      });

      testWithoutContext('no provisioning profile 1, stdout', () async {
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

      testWithoutContext('no provisioning profile 2, stderr', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stderr: 'Error 0xe8000067',
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

      testWithoutContext('unknown app launch error', () async {
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
        FakeCommand(command: <String>[
          iosDeployPath,
          '--id',
          deviceId,
          '--uninstall_only',
          '--bundle_id',
          bundleId,
        ])
      ]);
      final IOSDeploy iosDeploy = setUpIOSDeploy(processManager, artifacts: artifacts);
      final int exitCode = await iosDeploy.uninstallApp(
        deviceId: deviceId,
        bundleId: bundleId,
      );

      expect(exitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('returns non-zero exit code when ios-deploy does the same', () async {
      const String deviceId = '123';
      const String bundleId = 'com.example.app';
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          iosDeployPath,
          '--id',
          deviceId,
          '--uninstall_only',
          '--bundle_id',
          bundleId,
        ], exitCode: 1)
      ]);
      final IOSDeploy iosDeploy = setUpIOSDeploy(processManager, artifacts: artifacts);
      final int exitCode = await iosDeploy.uninstallApp(
        deviceId: deviceId,
        bundleId: bundleId,
      );

      expect(exitCode, 1);
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}

IOSDeploy setUpIOSDeploy(ProcessManager processManager, {
    Artifacts artifacts,
  }) {
  final FakePlatform macPlatform = FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{
      'PATH': '/usr/local/bin:/usr/bin'
    }
  );
  final Cache cache = Cache.test(
    platform: macPlatform,
    artifacts: <ArtifactSet>[
      FakeDyldEnvironmentArtifact(),
    ],
    processManager: FakeProcessManager.any(),
  );

  return IOSDeploy(
    logger: BufferLogger.test(),
    platform: macPlatform,
    processManager: processManager,
    artifacts: artifacts ?? Artifacts.test(),
    cache: cache,
  );
}
