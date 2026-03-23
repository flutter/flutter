// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/commands/analyze_base.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/project_validator.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

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
    late Terminal terminal;
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
      terminal = Terminal.test();
      command = AnalyzeCommand(
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
        terminal: terminal,
        allProjectValidators: <ProjectValidator>[],
        suppressAnalytics: true,
      );
      runner = createTestCommandRunner(command);

      // Setup repo roots
      const homePath = '/home/user/flutter';
      Cache.flutterRoot = homePath;
      for (final dir in <String>['dev', 'examples', 'packages']) {
        fileSystem.directory(homePath).childDirectory(dir).createSync(recursive: true);
      }
    });

    String buildResponse({required String message}) {
      return 'Content-Length: ${message.length}\r\n\r\n$message';
    }

    final headerRegExp = RegExp(r'Content-Length:\s(\d+)(\r\n|\n){2}', caseSensitive: false);
    String stripLspHeader({required String message}) {
      final Match? match = headerRegExp.firstMatch(message);
      if (match == null) {
        throw StateError('Unexpected message format: $message');
      }
      final int messageLength = int.parse(match.group(1)!);
      return message.replaceFirst(headerRegExp, '').substring(0, messageLength);
    }

    testUsingContext(
      'SIGABRT throws Exception',
      () async {
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
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      '--flutter-repo analyzes everything in the flutterRoot',
      () async {
        final streamController = StreamController<List<int>>();
        final sink = IOSink(streamController.sink);
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
              '--suppress-analytics',
            ],
            stdin: sink,
            //completer: completer,
            stdout: buildResponse(message: '{"id":1, "result":{}}'),
          ),
        ]);
        try {
          await runner.run(<String>['analyze', '--flutter-repo']);
        } on Object {}
        final String rawRequest = stripLspHeader(
          message: await streamController.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .join('\n'),
        );

        final initializeCommand = jsonDecode(rawRequest) as Map<String, Object?>;
        expect(initializeCommand['method'], 'initialize');
        final params = initializeCommand['params']! as Map<String, Object?>;
        expect(params['workspaceFolders'], <String?>[
          fileSystem.directory(Cache.flutterRoot).uri.toString(),
        ]);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );
  });

  testWithoutContext('analyze inRepo', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory(_kFlutterRoot).createSync(recursive: true);
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
      'flutter_analysis_test.',
    );
    Cache.flutterRoot = _kFlutterRoot;

    // Absolute paths
    expect(inRepo(<String>[tempDir.path], fileSystem), isFalse);
    expect(inRepo(<String>[fileSystem.path.join(tempDir.path, 'foo')], fileSystem), isFalse);
    expect(inRepo(<String>[Cache.flutterRoot!], fileSystem), isTrue);
    expect(inRepo(<String>[fileSystem.path.join(Cache.flutterRoot!, 'foo')], fileSystem), isTrue);

    // Relative paths
    fileSystem.currentDirectory = Cache.flutterRoot;
    expect(inRepo(<String>['.'], fileSystem), isTrue);
    expect(inRepo(<String>['foo'], fileSystem), isTrue);
    fileSystem.currentDirectory = tempDir.path;
    expect(inRepo(<String>['.'], fileSystem), isFalse);
    expect(inRepo(<String>['foo'], fileSystem), isFalse);

    // Ensure no exceptions
    inRepo(null, fileSystem);
    inRepo(<String>[], fileSystem);
  });

  testWithoutContext('AnalysisError from json write correct', () {
    const file = '/Users/.../lib/test.dart';
    final json = <String, dynamic>{
      'severity': 3,
      'range': <String, dynamic>{
        'start': <String, dynamic>{'line': 14, 'character': 3},
      },
      'file': file,
      'message': 'Prefer final for variable declarations if they are not reassigned.',
      'code': 'var foo = 123;',
      'hasFix': false,
    };
    expect(
      WrittenError.fromLsp(json, file).toString(),
      '[info] Prefer final for variable declarations if they are not reassigned (/Users/.../lib/test.dart:15:4)',
    );
  });
}

bool inRepo(List<String>? fileList, FileSystem fileSystem) {
  if (fileList == null || fileList.isEmpty) {
    fileList = <String>[fileSystem.path.current];
  }
  final String root = fileSystem.path.normalize(fileSystem.path.absolute(Cache.flutterRoot!));
  final String prefix = root + fileSystem.path.separator;
  for (String file in fileList) {
    file = fileSystem.path.normalize(fileSystem.path.absolute(file));
    if (file == root || file.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}
