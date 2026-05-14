// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:async';

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
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project_validator.dart';

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
  late AnsiTerminal terminal;
  late Logger logger;

  setUp(() {
    fileSystem = globals.localFileSystem;
    platform = const LocalPlatform();
    terminal = AnsiTerminal(platform: platform, stdio: Stdio());
    logger = BufferLogger(outputPreferences: OutputPreferences.test(), terminal: terminal);
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_analysis_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  void createSampleProject(Directory directory, {bool brokenCode = false}) {
    final File pubspecFile = directory.fileSystem.file(
      directory.fileSystem.path.join(directory.path, 'pubspec.yaml'),
    );
    pubspecFile.writeAsStringSync('''
  name: foo_project
  environment:
    sdk: ^3.7.0-0
  ''');

    final File dartFile = directory.fileSystem.file(
      directory.fileSystem.path.join(directory.path, 'lib', 'main.dart'),
    );
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
      final fileSystem = MemoryFileSystem.test();
      final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_analysis_test.',
      );
      createSampleProject(tempDir);

      final stdin = StreamController<List<int>>();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--suppress-analytics',
          ],
          stdin: IOSink(stdin.sink),
          stdout:
              'Content-Length: 36\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{}}'
              'Content-Length: 93\r\n\r\n'
              r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
              '"value":{"kind":"begin"}}}'
              'Content-Length: 91\r\n\r\n'
              r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
              '"value":{"kind":"end"}}}',
        ),
      ]);

      final server = AnalysisServer(
        'Artifact.engineDartSdkPath',
        <String>[tempDir.path],
        fileSystem: fileSystem,
        platform: FakePlatform(),
        processManager: processManager,
        logger: logger,
        terminal: terminal,
        suppressAnalytics: true,
      );

      var errorCount = 0;
      server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

      await server.start();
      await server.waitForAnalysis();

      expect(errorCount, 0);

      await server.dispose();
      expect(processManager, hasNoRemainingExpectations);
    });
  });

  testUsingContext('AnalysisServer errors', () async {
    final fileSystem = MemoryFileSystem.test();
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
      'flutter_analysis_test.',
    );
    createSampleProject(tempDir, brokenCode: true);

    final stdin = StreamController<List<int>>();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'Artifact.engineDartSdkPath/bin/dart',
          'language-server',
          '--dart-sdk',
          'Artifact.engineDartSdkPath',
          '--disable-server-feature-completion',
          '--disable-server-feature-search',
          '--suppress-analytics',
        ],
        stdin: IOSink(stdin.sink),
        stdout:
            'Content-Length: 36\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{}}'
            'Content-Length: 93\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"begin"}}}'
            'Content-Length: 249\r\n\r\n'
            '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{'
            '"uri":"file:///directoryA/foo","diagnostics":[{"range":{"start":{"line":99,'
            '"character":4},"end":{"line":99,"character":4}},"severity":2,"code":"500",'
            '"message":"It\'s an error."}]}}'
            'Content-Length: 91\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"end"}}}',
      ),
    ]);

    final server = AnalysisServer(
      'Artifact.engineDartSdkPath',
      <String>[tempDir.path],
      fileSystem: fileSystem,
      platform: FakePlatform(),
      processManager: processManager,
      logger: logger,
      terminal: terminal,
      suppressAnalytics: true,
    );

    var errorCount = 0;
    server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

    await server.start();
    await server.waitForAnalysis();

    expect(errorCount, greaterThan(0));

    await server.dispose();
    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('Returns no errors when source is error-free', () async {
    final fileSystem = MemoryFileSystem.test();
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
      'flutter_analysis_test.',
    );
    createSampleProject(tempDir);

    final stdin = StreamController<List<int>>();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'Artifact.engineDartSdkPath/bin/dart',
          'language-server',
          '--dart-sdk',
          'Artifact.engineDartSdkPath',
          '--disable-server-feature-completion',
          '--disable-server-feature-search',
          '--suppress-analytics',
        ],
        stdin: IOSink(stdin.sink),
        stdout:
            'Content-Length: 36\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{}}'
            'Content-Length: 93\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"begin"}}}'
            'Content-Length: 91\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"end"}}}',
      ),
    ]);

    final server = AnalysisServer(
      'Artifact.engineDartSdkPath',
      <String>[tempDir.path],
      fileSystem: fileSystem,
      platform: FakePlatform(),
      processManager: processManager,
      logger: logger,
      terminal: terminal,
      suppressAnalytics: true,
    );

    var errorCount = 0;
    server.onErrors.listen((FileAnalysisErrors errors) {
      errorCount += errors.errors.length;
    });
    await server.start();
    await server.waitForAnalysis();
    expect(errorCount, 0);
    await server.dispose();
    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('Can run AnalysisService without suppressing analytics', () async {
    final stdin = StreamController<List<int>>();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'Artifact.engineDartSdkPath/bin/dart',
          'language-server',
          '--dart-sdk',
          'Artifact.engineDartSdkPath',
          '--disable-server-feature-completion',
          '--disable-server-feature-search',
        ],
        stdin: IOSink(stdin.sink),
        stdout:
            'Content-Length: 53\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{"capabilities":{}}}\r\n',
      ),
    ]);

    final artifacts = Artifacts.test();
    final command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      fileSystem: MemoryFileSystem.test(),
      processManager: processManager,
      allProjectValidators: <ProjectValidator>[],
      suppressAnalytics: false,
    );

    final commandRunner = TestFlutterCommandRunner();
    commandRunner.addCommand(command);
    unawaited(commandRunner.run(<String>['analyze', '--watch']));
    await stdin.stream.first;

    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('Can run AnalysisService with customized cache location', () async {
    final stdin = StreamController<List<int>>();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'Artifact.engineDartSdkPath/bin/dart',
          'language-server',
          '--dart-sdk',
          'Artifact.engineDartSdkPath',
          '--disable-server-feature-completion',
          '--disable-server-feature-search',
          '--suppress-analytics',
        ],
        stdin: IOSink(stdin.sink),
        stdout:
            'Content-Length: 53\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{"capabilities":{}}}\r\n',
      ),
    ]);

    final artifacts = Artifacts.test();
    final command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      fileSystem: MemoryFileSystem.test(),
      processManager: processManager,
      allProjectValidators: <ProjectValidator>[],
      suppressAnalytics: true,
    );

    final commandRunner = TestFlutterCommandRunner();
    commandRunner.addCommand(command);
    unawaited(commandRunner.run(<String>['analyze', '--watch']));
    await stdin.stream.first;

    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('Can run AnalysisService with customized cache location --watch', () async {
    // Use Windows style on Windows host so Uri.toFilePath() parses it correctly with drive letters.
    final fileSystem = MemoryFileSystem.test(
      style: const LocalPlatform().isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
    );
    fileSystem.directory('directoryA').childFile('foo').createSync(recursive: true);

    final logger = BufferLogger.test();

    final fooUri = fileSystem.path.toUri(fileSystem.path.absolute('directoryA', 'foo')).toString();
    final diagnosticsJson =
        '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{'
        '"uri":"$fooUri","diagnostics":[{"range":{"start":{"line":99,'
        '"character":4},"end":{"line":99,"character":4}},"severity":2,"code":"500",'
        '"message":"It\'s an error."}]}}';

    final stdin = StreamController<List<int>>();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          fileSystem.path.join('Artifact.engineDartSdkPath', 'bin', 'dart'),
          'language-server',
          '--dart-sdk',
          'Artifact.engineDartSdkPath',
          '--disable-server-feature-completion',
          '--disable-server-feature-search',
          '--suppress-analytics',
        ],
        stdin: IOSink(stdin.sink),
        stdout:
            'Content-Length: 36\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{}}'
            'Content-Length: 93\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"begin"}}}'
            'Content-Length: ${diagnosticsJson.length}\r\n\r\n'
            '$diagnosticsJson'
            'Content-Length: 91\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"end"}}}',
      ),
    ]);

    final artifacts = Artifacts.test();
    final command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: logger,
      platform: FakePlatform(),
      fileSystem: fileSystem,
      processManager: processManager,
      allProjectValidators: <ProjectValidator>[],
      suppressAnalytics: true,
    );

    final commandRunner = TestFlutterCommandRunner();
    commandRunner.addCommand(command);
    unawaited(commandRunner.run(<String>['analyze', '--watch']));

    while (!logger.statusText.contains('analyzed 1 file')) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final String expectedPath = fileSystem.path.join('directoryA', 'foo');
    expect(logger.statusText, contains("warning • It's an error • $expectedPath:100:5 • 500"));
    expect(logger.statusText, contains('1 issue found. (1 new)'));
    expect(logger.errorText, isEmpty);
    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('AnalysisService --watch skips errors from non-files', () async {
    final logger = BufferLogger.test();
    final stdin = StreamController<List<int>>();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'Artifact.engineDartSdkPath/bin/dart',
          'language-server',
          '--dart-sdk',
          'Artifact.engineDartSdkPath',
          '--disable-server-feature-completion',
          '--disable-server-feature-search',
          '--suppress-analytics',
        ],
        stdin: IOSink(stdin.sink),
        stdout:
            'Content-Length: 36\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{}}'
            'Content-Length: 93\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"begin"}}}'
            'Content-Length: 249\r\n\r\n'
            '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{'
            '"uri":"file:///directoryA/bar","diagnostics":[{"range":{"start":{"line":99,'
            '"character":4},"end":{"line":99,"character":4}},"severity":2,"code":"500",'
            '"message":"It\'s an error."}]}}'
            'Content-Length: 91\r\n\r\n'
            r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
            '"value":{"kind":"end"}}}',
      ),
    ]);

    final artifacts = Artifacts.test();
    final command = AnalyzeCommand(
      terminal: Terminal.test(),
      artifacts: artifacts,
      logger: logger,
      platform: FakePlatform(),
      fileSystem: MemoryFileSystem.test(),
      processManager: processManager,
      allProjectValidators: <ProjectValidator>[],
      suppressAnalytics: true,
    );

    final commandRunner = TestFlutterCommandRunner();
    commandRunner.addCommand(command);
    unawaited(commandRunner.run(<String>['analyze', '--watch']));

    while (!logger.statusText.contains('analyzed 1 file')) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    expect(logger.statusText, contains('No issues found!'));
    expect(logger.errorText, isEmpty);
    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext(
    'AnalysisService --watch does not crash when the VM service is enabled',
    () async {
      // Pretend the VM service was enabled by sending SIGQUIT (CTRL + \) to ensure we don't try to
      // invoke json.decode(...) on the VM service message.
      //
      // Regression test for https://github.com/flutter/flutter/issues/58391.
      final logger = BufferLogger.test();
      final stdin = StreamController<List<int>>();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartSdkPath/bin/dart',
            'language-server',
            '--dart-sdk',
            'Artifact.engineDartSdkPath',
            '--disable-server-feature-completion',
            '--disable-server-feature-search',
            '--suppress-analytics',
          ],
          stdin: IOSink(stdin.sink),
          stdout:
              'The Dart VM service is listening on http://127.0.0.1:65155/ZkxDXuYz2Aw=/\n'
              'Content-Length: 36\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{}}'
              'Content-Length: 93\r\n\r\n'
              r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
              '"value":{"kind":"begin"}}}'
              'Content-Length: 249\r\n\r\n'
              '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{'
              '"uri":"file:///directoryA/bar","diagnostics":[{"range":{"start":{"line":99,'
              '"character":4},"end":{"line":99,"character":4}},"severity":2,"code":"500",'
              '"message":"It\'s an error."}]}}'
              'Content-Length: 91\r\n\r\n'
              r'{"jsonrpc":"2.0","method":"$/progress","params":{"token":"analyze",'
              '"value":{"kind":"end"}}}',
        ),
      ]);

      final artifacts = Artifacts.test();
      final command = AnalyzeCommand(
        terminal: Terminal.test(),
        artifacts: artifacts,
        logger: logger,
        platform: FakePlatform(),
        fileSystem: MemoryFileSystem.test(),
        processManager: processManager,
        allProjectValidators: <ProjectValidator>[],
        suppressAnalytics: true,
      );

      final commandRunner = TestFlutterCommandRunner();
      commandRunner.addCommand(command);
      unawaited(commandRunner.run(<String>['analyze', '--watch']));

      while (!logger.statusText.contains('analyzed 1 file')) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(logger.statusText, contains('No issues found!'));
      expect(logger.errorText, isEmpty);
      expect(processManager, hasNoRemainingExpectations);
    },
  );
}
