// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main () {
  late Artifacts artifacts;
  late String iosDeployPath;
  late FileSystem fileSystem;

  setUp(() {
    artifacts = Artifacts.test();
    iosDeployPath = artifacts.getHostArtifact(HostArtifact.iosDeploy).path;
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
            '--uninstall',
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
        interfaceType: IOSDeviceConnectionInterface.network,
        uninstallFirst: true,
      );

      expect(iosDeployDebugger.logLines, emits('Did finish launching.'));
      expect(await iosDeployDebugger.launchAndAttach(), isTrue);
      await iosDeployDebugger.logLines.drain();
      expect(processManager, hasNoRemainingExpectations);
      expect(appDeltaDirectory, exists);
    });
  });

  group('IOSDeployDebugger', () {
    group('launch', () {
      late BufferLogger logger;

      setUp(() {
        logger = BufferLogger.test();
      });

      testWithoutContext('debugger attached and stopped', () async {
        final StreamController<List<int>> stdin = StreamController<List<int>>();
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>['ios-deploy'],
            stdout: "(lldb)     run\r\nsuccess\r\nsuccess\r\nLog on attach1\r\n\r\nLog on attach2\r\n\r\n\r\n\r\nPROCESS_STOPPED\r\nLog after process stop\r\nthread backtrace all\r\n* thread #1, queue = 'com.apple.main-thread', stop reason = signal SIGSTOP",
            stdin: IOSink(stdin.sink),
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );
        final List<String> receivedLogLines = <String>[];
        final Stream<String> logLines = iosDeployDebugger.logLines
          ..listen(receivedLogLines.add);

        expect(iosDeployDebugger.logLines, emitsInOrder(<String>[
          'success', // ignore first "success" from lldb, but log subsequent ones from real logging.
          'Log on attach1',
          'Log on attach2',
          '',
          '',
          'Log after process stop',
        ]));
        expect(stdin.stream.transform<String>(const Utf8Decoder()), emitsInOrder(<String>[
          'thread backtrace all',
          '\n',
          'process detach',
        ]));
        expect(await iosDeployDebugger.launchAndAttach(), isTrue);
        await logLines.drain();

        expect(logger.traceText, contains('PROCESS_STOPPED'));
        expect(logger.traceText, contains('thread backtrace all'));
        expect(logger.traceText, contains('* thread #1'));
      });

      testWithoutContext('handle processing logging after process exit', () async {
        final StreamController<List<int>> stdin = StreamController<List<int>>();
        // Make sure we don't hit a race where logging processed after the process exits
        // causes listeners to receive logging on the closed logLines stream.
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>['ios-deploy'],
            stdout: 'stdout: "(lldb)     run\r\nsuccess\r\n',
            stdin: IOSink(stdin.sink),
            outputFollowsExit: true,
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );

        expect(iosDeployDebugger.logLines, emitsDone);
        expect(await iosDeployDebugger.launchAndAttach(), isFalse);
        await iosDeployDebugger.logLines.drain();
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
        expect(iosDeployDebugger.logLines, emitsInOrder(<String>[
          'Log on attach',
          'Log after process exit',
        ]));

        expect(await iosDeployDebugger.launchAndAttach(), isTrue);
        await iosDeployDebugger.logLines.drain();
      });

      testWithoutContext('app crash', () async {
        final StreamController<List<int>> stdin = StreamController<List<int>>();
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>['ios-deploy'],
            stdout:
                '(lldb)     run\r\nsuccess\r\nLog on attach\r\n(lldb) Process 6156 stopped\r\n* thread #1, stop reason = Assertion failed:\r\nthread backtrace all\r\n* thread #1, stop reason = Assertion failed:',
            stdin: IOSink(stdin.sink),
          ),
        ]);
        final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
          processManager: processManager,
          logger: logger,
        );

        expect(iosDeployDebugger.logLines, emitsInOrder(<String>[
          'Log on attach',
          '* thread #1, stop reason = Assertion failed:',
        ]));

        expect(stdin.stream.transform<String>(const Utf8Decoder()), emitsInOrder(<String>[
          'thread backtrace all',
          '\n',
          'process detach',
        ]));

        expect(await iosDeployDebugger.launchAndAttach(), isTrue);
        await iosDeployDebugger.logLines.drain();

        expect(logger.traceText, contains('Process 6156 stopped'));
        expect(logger.traceText, contains('thread backtrace all'));
        expect(logger.traceText, contains('* thread #1'));
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
        // Debugger lines are double spaced, separated by an extra \r\n. Skip the extra lines.
        // Still include empty lines other than the extra added newlines.
        expect(iosDeployDebugger.logLines, emitsDone);

        expect(await iosDeployDebugger.launchAndAttach(), isFalse);
        await iosDeployDebugger.logLines.drain();
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

      testWithoutContext('device locked code', () async {
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

      testWithoutContext('device locked message', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['ios-deploy'],
            stdout: '[  +95 ms] error: The operation couldn’t be completed. Unable to launch io.flutter.examples.gallery because the device was not, or could not be, unlocked.',
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
      expect(stdin.stream.transform<String>(const Utf8Decoder()), emits('process detach'));
      await iosDeployDebugger.launchAndAttach();
      iosDeployDebugger.detach();
    });

    testWithoutContext('stop with backtrace', () async {
      final StreamController<List<int>> stdin = StreamController<List<int>>();
      final Stream<String> stdinStream = stdin.stream.transform<String>(const Utf8Decoder());
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'ios-deploy',
          ],
          stdout:
          '(lldb)     run\nsuccess\nLog on attach\n(lldb) Process 6156 stopped\n* thread #1, stop reason = Assertion failed:\n(lldb) Process 6156 detached',
          stdin: IOSink(stdin.sink),
        ),
      ]);
      final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
        processManager: processManager,
      );
      await iosDeployDebugger.launchAndAttach();
      await iosDeployDebugger.stopAndDumpBacktrace();
      expect(await stdinStream.take(3).toList(), <String>[
        'thread backtrace all',
        '\n',
        'process detach',
      ]);
    });

    testWithoutContext('pause with backtrace', () async {
      final StreamController<List<int>> stdin = StreamController<List<int>>();
      final Stream<String> stdinStream = stdin.stream.transform<String>(const Utf8Decoder());
      const String stdout = '''
(lldb)     run
success
Log on attach
(lldb) Process 6156 stopped
* thread #1, stop reason = Assertion failed:
thread backtrace all
process continue
* thread #1, stop reason = signal SIGSTOP
  * frame #0: 0x0000000102eaee80 dyld`dyld3::MachOFile::read_uleb128(Diagnostics&, unsigned char const*&, unsigned char const*) + 36
    frame #1: 0x0000000102eabbd4 dyld`dyld3::MachOLoaded::trieWalk(Diagnostics&, unsigned char const*, unsigned char const*, char const*) + 332
    frame #2: 0x0000000102eaa078 dyld`DyldSharedCache::hasImagePath(char const*, unsigned int&) const + 144
    frame #3: 0x0000000102eaa13c dyld`DyldSharedCache::hasNonOverridablePath(char const*) const + 44
    frame #4: 0x0000000102ebc404 dyld`dyld3::closure::ClosureBuilder::findImage(char const*, dyld3::closure::ClosureBuilder::LoadedImageChain const&, dyld3::closure::ClosureBuilder::BuilderLoadedImage*&, dyld3::closure::ClosureBuilder::LinkageType, unsigned int, bool) +

    frame #5: 0x0000000102ebd974 dyld`invocation function for block in dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 136
    frame #6: 0x0000000102eae1b0 dyld`invocation function for block in dyld3::MachOFile::forEachDependentDylib(void (char const*, bool, bool, bool, unsigned int, unsigned int, bool&) block_pointer) const + 136
    frame #7: 0x0000000102eadc38 dyld`dyld3::MachOFile::forEachLoadCommand(Diagnostics&, void (load_command const*, bool&) block_pointer) const + 168
    frame #8: 0x0000000102eae108 dyld`dyld3::MachOFile::forEachDependentDylib(void (char const*, bool, bool, bool, unsigned int, unsigned int, bool&) block_pointer) const + 116
    frame #9: 0x0000000102ebd80c dyld`dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 164
    frame #10: 0x0000000102ebd8a8 dyld`dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 320
    frame #11: 0x0000000102ebd8a8 dyld`dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 320
    frame #12: 0x0000000102ebd8a8 dyld`dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 320
    frame #13: 0x0000000102ebd8a8 dyld`dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 320
    frame #14: 0x0000000102ebd8a8 dyld`dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 320
    frame #15: 0x0000000102ebd8a8 dyld`dyld3::closure::ClosureBuilder::recursiveLoadDependents(dyld3::closure::ClosureBuilder::LoadedImageChain&, bool) + 320
    frame #16: 0x0000000102ec7638 dyld`dyld3::closure::ClosureBuilder::makeLaunchClosure(dyld3::closure::LoadedFileInfo const&, bool) + 752
    frame #17: 0x0000000102e8fcf0 dyld`dyld::buildLaunchClosure(unsigned char const*, dyld3::closure::LoadedFileInfo const&, char const**) + 344
    frame #18: 0x0000000102e8e938 dyld`dyld::_main(macho_header const*, unsigned long, int, char const**, char const**, char const**, unsigned long*) + 2876
    frame #19: 0x0000000102e8922c dyld`dyldbootstrap::start(dyld3::MachOLoaded const*, int, char const**, dyld3::MachOLoaded const*, unsigned long*) + 432
    frame #20: 0x0000000102e89038 dyld`_dyld_start + 56
''';
      final BufferLogger logger = BufferLogger.test();
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'ios-deploy',
          ],
          stdout: stdout,
          stdin: IOSink(stdin.sink),
        ),
      ]);
      final IOSDeployDebugger iosDeployDebugger = IOSDeployDebugger.test(
        processManager: processManager,
        logger: logger,
      );
      await iosDeployDebugger.launchAndAttach();
      await iosDeployDebugger.pauseDumpBacktraceResume();
      // verify stacktrace was logged to trace
      expect(
        logger.traceText,
        contains(
          'frame #0: 0x0000000102eaee80 dyld`dyld3::MachOFile::read_uleb128(Diagnostics&, unsigned char const*&, unsigned char const*) + 36',
        ),
      );
      expect(await stdinStream.take(3).toList(), <String>[
        'thread backtrace all',
        '\n',
        'process detach',
      ]);
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
        ]),
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
        ], exitCode: 1),
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
    Artifacts? artifacts,
  }) {
  final FakePlatform macPlatform = FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{
      'PATH': '/usr/local/bin:/usr/bin',
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
