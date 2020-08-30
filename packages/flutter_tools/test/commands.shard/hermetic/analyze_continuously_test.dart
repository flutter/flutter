// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  AnalysisServer server;
  Directory tempDir;
  FileSystem fileSystem;
  Platform platform;
  ProcessManager processManager;
  AnsiTerminal terminal;
  Logger logger;

  setUp(() {
    fileSystem = LocalFileSystem.instance;
    platform = const LocalPlatform();
    processManager = const LocalProcessManager();
    terminal = AnsiTerminal(platform: platform, stdio: Stdio());
    logger = BufferLogger(outputPreferences: OutputPreferences.test(), terminal: terminal);
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_analysis_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
    return server?.dispose();
  });


  void _createSampleProject(Directory directory, { bool brokenCode = false }) {
    final File pubspecFile = fileSystem.file(fileSystem.path.join(directory.path, 'pubspec.yaml'));
    pubspecFile.writeAsStringSync('''
  name: foo_project
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
      _createSampleProject(tempDir);

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
        generateSyntheticPackage: false,
      );

      server = AnalysisServer(
        globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        <String>[tempDir.path],
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        logger: logger,
        terminal: terminal,
        experiments: <String>[],
      );

      int errorCount = 0;
      final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
      server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

      await server.start();
      await onDone;

      expect(errorCount, 0);
    });
  });

  testUsingContext('AnalysisServer errors', () async {
    _createSampleProject(tempDir, brokenCode: true);

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      platform: const LocalPlatform(),
      usage: globals.flutterUsage,
      botDetector: globals.botDetector,
      toolStampFile: globals.fs.file('test'),
    );
    await pub.get(
      context: PubContext.flutterTests,
      directory: tempDir.path,
      generateSyntheticPackage: false,
    );

      server = AnalysisServer(
        globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        <String>[tempDir.path],
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        logger: logger,
        terminal: terminal,
        experiments: <String>[],
      );

    int errorCount = 0;
    final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
    server.onErrors.listen((FileAnalysisErrors errors) {
      errorCount += errors.errors.length;
    });

    await server.start();
    await onDone;

    expect(errorCount, greaterThan(0));
  });

  testUsingContext('Returns no errors when source is error-free', () async {
    const String contents = "StringBuffer bar = StringBuffer('baz');";
    tempDir.childFile('main.dart').writeAsStringSync(contents);
    server = AnalysisServer(
      globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
      <String>[tempDir.path],
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      logger: logger,
      terminal: terminal,
      experiments: <String>[],
    );

    int errorCount = 0;
    final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
    server.onErrors.listen((FileAnalysisErrors errors) {
      errorCount += errors.errors.length;
    });
    await server.start();
    await onDone;
    expect(errorCount, 0);
  });

  testWithoutContext('Can forward null-safety experiments to the AnalysisServer', () async {
    final Completer<void> completer = Completer<void>();
    final StreamController<List<int>> stdin = StreamController<List<int>>();
    const String fakeSdkPath = 'dart-sdk';
    final FakeCommand fakeCommand = FakeCommand(
      command: const <String>[
        'dart-sdk/bin/dart',
        '--disable-dart-dev',
        'dart-sdk/bin/snapshots/analysis_server.dart.snapshot',
        '--enable-experiment',
        'non-nullable',
        '--disable-server-feature-completion',
        '--disable-server-feature-search',
        '--sdk',
        'dart-sdk',
      ],
      completer: completer,
      stdin: IOSink(stdin.sink),
    );

    server = AnalysisServer(fakeSdkPath, <String>[''],
      fileSystem: MemoryFileSystem.test(),
      platform: FakePlatform(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        fakeCommand,
      ]),
      logger: BufferLogger.test(),
      terminal: Terminal.test(),
      experiments: <String>[
        'non-nullable'
      ],
    );

    await server.start();
  });

  testUsingContext('Can run AnalysisService with customized cache location', () async {
    final Completer<void> completer = Completer<void>();
    final StreamController<List<int>> stdin = StreamController<List<int>>();
    final FakeProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        FakeCommand(
          command: const <String>[
            'custom-dart-sdk/bin/dart',
            '--disable-dart-dev',
            'custom-dart-sdk/bin/snapshots/analysis_server.dart.snapshot',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--sdk',
            'custom-dart-sdk',
          ],
          completer: completer,
          stdin: IOSink(stdin.sink),
        ),
      ]);

    final Artifacts artifacts = MockArtifacts();
    when(artifacts.getArtifactPath(Artifact.engineDartSdkPath))
      .thenReturn('custom-dart-sdk');

    final AnalyzeCommand command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      fileSystem: MemoryFileSystem.test(),
      processManager: processManager,
    );

    final TestFlutterCommandRunner commandRunner = TestFlutterCommandRunner();
    commandRunner.addCommand(command);
    unawaited(commandRunner.run(<String>['analyze', '--watch']));
    await stdin.stream.first;

    expect(processManager.hasRemainingExpectations, false);
  });

  testUsingContext('Can run AnalysisService with customized cache location --watch', () async {
    final Completer<void> completer = Completer<void>();
    final StreamController<List<int>> stdin = StreamController<List<int>>();
    final FakeProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        FakeCommand(
          command: const <String>[
            'custom-dart-sdk/bin/dart',
            '--disable-dart-dev',
            'custom-dart-sdk/bin/snapshots/analysis_server.dart.snapshot',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--sdk',
            'custom-dart-sdk',
          ],
          completer: completer,
          stdin: IOSink(stdin.sink),
        ),
      ]);

    final Artifacts artifacts = MockArtifacts();
    when(artifacts.getArtifactPath(Artifact.engineDartSdkPath))
      .thenReturn('custom-dart-sdk');

    final AnalyzeCommand command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      fileSystem: MemoryFileSystem.test(),
      processManager: processManager,
    );

    final TestFlutterCommandRunner commandRunner = TestFlutterCommandRunner();
    commandRunner.addCommand(command);
    unawaited(commandRunner.run(<String>['analyze', '--watch']));
    await stdin.stream.first;

    expect(processManager.hasRemainingExpectations, false);
  });
}

class MockArtifacts extends Mock implements Artifacts {}
