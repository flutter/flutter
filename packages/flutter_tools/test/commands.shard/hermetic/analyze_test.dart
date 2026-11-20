// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/commands/analyze_base.dart';
import 'package:flutter_tools/src/project_validator.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' hide FakeProcess;
import '../../src/test_flutter_command_runner.dart';
import 'analysis_server_mock.dart';

const _kFlutterRoot = '/data/flutter';
const SIGABRT = -6;

void main() {
  testWithoutContext('analyze generate correct errors message', () async {
    expect(
      AnalyzeBase.generateErrorsMessage(issueCount: 0, seconds: '0.1'),
      'No issues found! (ran in 0.1s)',
    );

    expect(
      AnalyzeBase.generateErrorsMessage(issueCount: 3, issueDiff: 2, files: 1, seconds: '0.1'),
      '3 issues found. (2 new) • analyzed 1 file (ran in 0.1s)',
    );
  });

  group('analyze command', () {
    late FileSystem fileSystem;
    late Platform platform;
    late BufferLogger logger;
    late FakeProcessManager processManager;
    late FakeToolContext toolContext;
    late AnalyzeCommand command;
    late CommandRunner<void> runner;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      platform = FakePlatform();
      logger = BufferLogger.test();
      processManager = FakeProcessManager.empty();
      // Setup repo roots
      const homePath = '/home/user/flutter';
      toolContext = FakeToolContext(
        artifacts: Artifacts.test(),
        cache: FakeCache(fileSystem: fileSystem, flutterRoot: homePath),
        fs: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );
      command = AnalyzeCommand(
        allProjectValidators: <ProjectValidator>[],
        suppressAnalytics: true,
        toolContext: toolContext,
      );
      runner = createTestCommandRunner(command);

      for (final dir in <String>['dev', 'examples', 'packages']) {
        fileSystem.directory(homePath).childDirectory(dir).createSync(recursive: true);
      }
    });

    testWithoutContext('SIGABRT throws Exception', () async {
      const stderr = 'Something bad happened!';
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          // artifact paths are from Artifacts.test() and stable
          command: <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            '--suppress-analytics',
          ],
          exitCode: SIGABRT,
          stderr: stderr,
        ),
      ]);
      await expectLater(
        runner.run(<String>['analyze']),
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
            'description',
            contains('analysis server exited with code $SIGABRT and output:\n[stderr] $stderr'),
          ),
        ),
      );
    });

    testWithoutContext('Analysis server premature exit with 255 throws ToolExit', () async {
      const stderr = 'Fatal error in analyzer';
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            '--suppress-analytics',
          ],
          exitCode: 255,
          stderr: stderr,
        ),
      ]);
      await expectLater(
        runner.run(<String>['analyze']),
        throwsA(
          isA<ToolExit>()
              .having(
                (ToolExit e) => e.message,
                'message',
                contains('analysis server exited with code 255 and output:\n[stderr] $stderr'),
              )
              .having((ToolExit e) => e.exitCode, 'exitCode', equals(255)),
        ),
      );
    });

    testWithoutContext('--flutter-repo analyzes everything in the flutterRoot', () async {
      final process = MockLspServerProcess();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          // artifact paths are from Artifacts.test() and stable
          command: const <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            '--suppress-analytics',
          ],
          process: process,
        ),
      ]);
      await runner.run(<String>['analyze', '--flutter-repo']);

      final Map<String, Object?> request = await process.initializeRequest;
      final params = request['params']! as Map<String, Object?>;
      expect(
        params['workspaceFolders'] as List<Object?>?,
        contains(
          equals(<String, Object?>{
            'name': '/home/user/flutter',
            'uri': 'file:///home/user/flutter/',
          }),
        ),
      );
    });

    testWithoutContext('only the latest diagnostics published for a file are reported', () async {
      final process = MockLspServerProcess();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            '--suppress-analytics',
          ],
          process: process,
        ),
      ]);
      final Uri targetUri = Uri.parse('file:///directoryA/foo');
      await process.runSimulatedAnalysis(diagnosticsFor: targetUri);
      await process.runSimulatedAnalysis(diagnosticsFor: targetUri, diagnosticsCount: 2);

      await expectLater(
        runner.run(<String>['analyze']),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            startsWith('2 issues found.'),
          ),
        ),
      );
    });

    testWithoutContext('--no-plugins passes --no-plugins to language-server', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            '--no-plugins',
            '--suppress-analytics',
          ],
          exitCode: 255,
          stderr: 'error',
        ),
      ]);
      await expectLater(runner.run(<String>['analyze', '--no-plugins']), throwsA(isA<ToolExit>()));
    });

    testWithoutContext('--benchmark passes --no-plugins to language-server by default', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            '--no-plugins',
            '--suppress-analytics',
          ],
          exitCode: 255,
          stderr: 'error',
        ),
      ]);
      await expectLater(runner.run(<String>['analyze', '--benchmark']), throwsA(isA<ToolExit>()));
    });

    testWithoutContext('--benchmark with --plugins enables plugins', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            '--plugins',
            '--suppress-analytics',
          ],
          exitCode: 255,
          stderr: 'error',
        ),
      ]);
      await expectLater(
        runner.run(<String>['analyze', '--benchmark', '--plugins']),
        throwsA(isA<ToolExit>()),
      );
    });

    Future<void> expectServerArgs(
      List<String> analyzeArgs,
      List<String> expectedServerFlags, {
      bool isRunningOnBot = false,
    }) async {
      final botProcessManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--no-with-fine-dependencies',
            ...expectedServerFlags,
            '--suppress-analytics',
          ],
          exitCode: 255,
          stderr: 'error',
        ),
      ]);
      final localCommand = AnalyzeCommand(
        allProjectValidators: <ProjectValidator>[],
        suppressAnalytics: true,
        toolContext: FakeToolContext(
          artifacts: Artifacts.test(),
          botDetector: FakeBotDetector(isRunningOnBot),
          cache: FakeCache(fileSystem: fileSystem, flutterRoot: '/home/user/flutter'),
          fs: fileSystem,
          logger: logger,
          platform: platform,
          processManager: botProcessManager,
        ),
      );
      final CommandRunner<void> localRunner = createTestCommandRunner(localCommand);
      await expectLater(
        localRunner.run(<String>['analyze', ...analyzeArgs]),
        throwsA(isA<ToolExit>()),
      );
      expect(botProcessManager, hasNoRemainingExpectations);
    }

    testWithoutContext('--plugins passes --plugins to language-server', () async {
      await expectServerArgs(<String>['--plugins'], <String>['--plugins']);
    });

    testWithoutContext('plugin trust flags pass expected flags to language-server', () async {
      await expectServerArgs(<String>['--trust-plugins'], <String>['--trust-plugins']);
      await expectServerArgs(
        <String>['--always-trust-plugins'],
        <String>['--always-trust-plugins'],
      );
      await expectServerArgs(<String>['--never-trust-plugins'], <String>['--never-trust-plugins']);
    });

    testWithoutContext('plugin trust flags are mutually exclusive', () async {
      for (final args in const <List<String>>[
        <String>['--trust-plugins', '--always-trust-plugins'],
        <String>['--trust-plugins', '--never-trust-plugins'],
        <String>['--always-trust-plugins', '--never-trust-plugins'],
        <String>['--trust-plugins', '--always-trust-plugins', '--never-trust-plugins'],
      ]) {
        await expectLater(
          runner.run(<String>['analyze', ...args]),
          throwsToolExit(
            message:
                'Cannot specify more than one of "--trust-plugins", '
                '"--always-trust-plugins", and "--never-trust-plugins".',
          ),
        );
      }
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('plugin trust flags are not negatable', () async {
      for (final flag in const <String>[
        '--no-trust-plugins',
        '--no-always-trust-plugins',
        '--no-never-trust-plugins',
      ]) {
        await expectLater(runner.run(<String>['analyze', flag]), throwsA(isA<UsageException>()));
      }
    });

    testWithoutContext('enables plugins by default when running on a bot', () async {
      await expectServerArgs(const <String>[], <String>['--plugins'], isRunningOnBot: true);
      await expectServerArgs(
        <String>['--no-plugins'],
        <String>['--no-plugins'],
        isRunningOnBot: true,
      );
      await expectServerArgs(
        <String>['--benchmark'],
        <String>['--no-plugins'],
        isRunningOnBot: true,
      );
      await expectServerArgs(
        <String>['--never-trust-plugins'],
        <String>['--never-trust-plugins'],
        isRunningOnBot: true,
      );
      await expectServerArgs(
        <String>['--trust-plugins'],
        <String>['--plugins', '--trust-plugins'],
        isRunningOnBot: true,
      );
      await expectServerArgs(
        <String>['--always-trust-plugins'],
        <String>['--plugins', '--always-trust-plugins'],
        isRunningOnBot: true,
      );
    });
  });

  testWithoutContext('analyze inRepo', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory(_kFlutterRoot).createSync(recursive: true);
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
      'flutter_analysis_test.',
    );

    // Absolute paths
    expect(inRepo(<String>[tempDir.path], fileSystem, _kFlutterRoot), isFalse);
    expect(
      inRepo(<String>[fileSystem.path.join(tempDir.path, 'foo')], fileSystem, _kFlutterRoot),
      isFalse,
    );
    expect(inRepo(<String>[_kFlutterRoot], fileSystem, _kFlutterRoot), isTrue);
    expect(
      inRepo(<String>[fileSystem.path.join(_kFlutterRoot, 'foo')], fileSystem, _kFlutterRoot),
      isTrue,
    );

    // Relative paths
    fileSystem.currentDirectory = _kFlutterRoot;
    expect(inRepo(<String>['.'], fileSystem, _kFlutterRoot), isTrue);
    expect(inRepo(<String>['foo'], fileSystem, _kFlutterRoot), isTrue);
    fileSystem.currentDirectory = tempDir.path;
    expect(inRepo(<String>['.'], fileSystem, _kFlutterRoot), isFalse);
    expect(inRepo(<String>['foo'], fileSystem, _kFlutterRoot), isFalse);

    // Ensure no exceptions
    inRepo(null, fileSystem, _kFlutterRoot);
    inRepo(<String>[], fileSystem, _kFlutterRoot);
  });
}

bool inRepo(List<String>? fileList, FileSystem fileSystem, String flutterRoot) {
  if (fileList == null || fileList.isEmpty) {
    fileList = <String>[fileSystem.path.current];
  }
  final String root = fileSystem.path.normalize(fileSystem.path.absolute(flutterRoot));
  final String prefix = root + fileSystem.path.separator;
  for (String file in fileList) {
    file = fileSystem.path.normalize(fileSystem.path.absolute(file));
    if (file == root || file.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}
