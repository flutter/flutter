// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project_validator.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  late Directory tempDir;
  late FileSystem fileSystem;
  late Platform platform;
  late ProcessManager processManager;
  late AnsiTerminal terminal;
  late Logger logger;

  setUp(() {
    fileSystem = globals.localFileSystem;
    platform = const LocalPlatform();
    processManager = const LocalProcessManager();
    terminal = AnsiTerminal(platform: platform, stdio: Stdio());
    logger = BufferLogger(outputPreferences: OutputPreferences.test(), terminal: terminal);
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_analysis_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });


  void createSampleProject(Directory directory, { bool brokenCode = false }) {
    final File pubspecFile = fileSystem.file(fileSystem.path.join(directory.path, 'pubspec.yaml'));
    pubspecFile.writeAsStringSync('''
  name: foo_project
  environment:
    sdk: '>=2.10.0 <3.0.0'
  ''');

    final File dartFile = fileSystem.file(fileSystem.path.join(directory.path, 'lib', 'main.dart'));
    dartFile.parent.createSync();
    dartFile.writeAsStringSync('''
  void main() {
    print('hello world');
    ${brokenCode ? 'prints("hello world");' : ''}
  }
  ''');
  }

  group('analyze --watch', () {
    testUsingContext('AnalysisServer success', () async {
      createSampleProject(tempDir);

      final Pub pub = Pub(
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        platform: const LocalPlatform(),
        botDetector: globals.botDetector,
        usage: globals.flutterUsage,
      );
      await pub.get(
        context: PubContext.flutterTests,
        directory: tempDir.path,
      );

      final AnalysisServer server = AnalysisServer(
        globals.artifacts!.getHostArtifact(HostArtifact.engineDartSdkPath).path,
        <String>[tempDir.path],
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        logger: logger,
        terminal: terminal,
      );

      int errorCount = 0;
      final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
      server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

      await server.start();
      await onDone;

      expect(errorCount, 0);

      await server.dispose();
    });
  });

  testUsingContext('AnalysisServer errors', () async {
    createSampleProject(tempDir, brokenCode: true);

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      platform: const LocalPlatform(),
      usage: globals.flutterUsage,
      botDetector: globals.botDetector,
    );
    await pub.get(
      context: PubContext.flutterTests,
      directory: tempDir.path,
    );

    final AnalysisServer server = AnalysisServer(
      globals.artifacts!.getHostArtifact(HostArtifact.engineDartSdkPath).path,
      <String>[tempDir.path],
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      logger: logger,
      terminal: terminal,
    );

    int errorCount = 0;
    final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
    server.onErrors.listen((FileAnalysisErrors errors) {
      errorCount += errors.errors.length;
    });

    await server.start();
    await onDone;

    expect(errorCount, greaterThan(0));

    await server.dispose();
  });

  testUsingContext('Returns no errors when source is error-free', () async {
    const String contents = "StringBuffer bar = StringBuffer('baz');";
    tempDir.childFile('main.dart').writeAsStringSync(contents);
    final AnalysisServer server = AnalysisServer(
      globals.artifacts!.getHostArtifact(HostArtifact.engineDartSdkPath).path,
      <String>[tempDir.path],
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      logger: logger,
      terminal: terminal,
    );

    int errorCount = 0;
    final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
    server.onErrors.listen((FileAnalysisErrors errors) {
      errorCount += errors.errors.length;
    });
    await server.start();
    await onDone;
    expect(errorCount, 0);
    await server.dispose();
  });

  testUsingContext('Can run AnalysisService with customized cache location', () async {
    final StreamController<List<int>> stdin = StreamController<List<int>>();
    final FakeProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        FakeCommand(
          command: const <String>[
            'HostArtifact.engineDartSdkPath/bin/dart',
            '--disable-dart-dev',
            'HostArtifact.engineDartSdkPath/bin/snapshots/analysis_server.dart.snapshot',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--sdk',
            'HostArtifact.engineDartSdkPath',
          ],
          stdin: IOSink(stdin.sink),
        ),
      ]);

    final Artifacts artifacts = Artifacts.test();
    final AnalyzeCommand command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      fileSystem: MemoryFileSystem.test(),
      processManager: processManager,
      allProjectValidators: <ProjectValidator>[],
    );

    final TestFlutterCommandRunner commandRunner = TestFlutterCommandRunner();
    commandRunner.addCommand(command);
    unawaited(commandRunner.run(<String>['analyze', '--watch']));
    await stdin.stream.first;

    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('Can run AnalysisService with customized cache location --watch', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory('directoryA').childFile('foo').createSync(recursive: true);

    final BufferLogger logger = BufferLogger.test();

    final Completer<void> completer = Completer<void>();
    final StreamController<List<int>> stdin = StreamController<List<int>>();
    final FakeProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        FakeCommand(
          command: const <String>[
            'HostArtifact.engineDartSdkPath/bin/dart',
            '--disable-dart-dev',
            'HostArtifact.engineDartSdkPath/bin/snapshots/analysis_server.dart.snapshot',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--sdk',
            'HostArtifact.engineDartSdkPath',
          ],
          stdin: IOSink(stdin.sink),
          stdout: '''
{"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
{"event":"analysis.errors","params":{"file":"/directoryA/foo","errors":[{"type":"TestError","message":"It's an error.","severity":"warning","code":"500","location":{"file":"/directoryA/foo","startLine": 100,"startColumn":5,"offset":0}}]}}
{"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}
'''
        ),
      ]);

    final Artifacts artifacts = Artifacts.test();
    final AnalyzeCommand command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: logger,
      platform: FakePlatform(),
      fileSystem: fileSystem,
      processManager: processManager,
      allProjectValidators: <ProjectValidator>[],
    );

    await FakeAsync().run((FakeAsync time) async {
      final TestFlutterCommandRunner commandRunner = TestFlutterCommandRunner();
      commandRunner.addCommand(command);
      unawaited(commandRunner.run(<String>['analyze', '--watch']));

      while (!logger.statusText.contains('analyzed 1 file')) {
        time.flushMicrotasks();
      }
      completer.complete();
      return completer.future;
    });
    expect(logger.statusText, contains("warning • It's an error • directoryA/foo:100:5 • 500"));
    expect(logger.statusText, contains('1 issue found. (1 new)'));
    expect(logger.errorText, isEmpty);
    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('AnalysisService --watch skips errors from non-files', () async {
    final BufferLogger logger = BufferLogger.test();
    final Completer<void> completer = Completer<void>();
    final StreamController<List<int>> stdin = StreamController<List<int>>();
    final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[
          FakeCommand(
              command: const <String>[
                'HostArtifact.engineDartSdkPath/bin/dart',
                '--disable-dart-dev',
                'HostArtifact.engineDartSdkPath/bin/snapshots/analysis_server.dart.snapshot',
                '--disable-server-feature-completion',
                '--disable-server-feature-search',
                '--sdk',
                'HostArtifact.engineDartSdkPath',
              ],
              stdin: IOSink(stdin.sink),
              stdout: '''
{"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
{"event":"analysis.errors","params":{"file":"/directoryA/bar","errors":[{"type":"TestError","message":"It's an error.","severity":"warning","code":"500","location":{"file":"/directoryA/bar","startLine":100,"startColumn":5,"offset":0}}]}}
{"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}
'''
          ),
        ]);

    final Artifacts artifacts = Artifacts.test();
    final AnalyzeCommand command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: logger,
      platform: FakePlatform(),
      fileSystem: MemoryFileSystem.test(),
      processManager: processManager,
      allProjectValidators: <ProjectValidator>[],
    );

    await FakeAsync().run((FakeAsync time) async {
      final TestFlutterCommandRunner commandRunner = TestFlutterCommandRunner();
      commandRunner.addCommand(command);
      unawaited(commandRunner.run(<String>['analyze', '--watch']));

      while (!logger.statusText.contains('analyzed 1 file')) {
        time.flushMicrotasks();
      }
      completer.complete();
      return completer.future;
    });

    expect(logger.statusText, contains('No issues found!'));
    expect(logger.errorText, isEmpty);
    expect(processManager, hasNoRemainingExpectations);
  });
}
