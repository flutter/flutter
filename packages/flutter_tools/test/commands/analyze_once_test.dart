// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../src/common.dart';
import '../src/context.dart';

/// Test case timeout for tests involving project analysis.
const Timeout allowForSlowAnalyzeTests = Timeout.factor(5.0);

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

void main() {
  final String analyzerSeparator = platform.isWindows ? '-' : '•';

  group('analyze once', () {
    Directory tempDir;
    String projectPath;
    File libMain;

    setUpAll(() {
      Cache.disableLocking();
      tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_1.').absolute;
      projectPath = fs.path.join(tempDir.path, 'flutter_project');
      libMain = fs.file(fs.path.join(projectPath, 'lib', 'main.dart'));
    });

    tearDownAll(() {
      tryToDelete(tempDir);
    });

    // Create a project to be analyzed
    testUsingContext('flutter create', () async {
      await runCommand(
        command: CreateCommand(),
        arguments: <String>['--no-wrap', 'create', projectPath],
        statusTextContains: <String>[
          'All done!',
          'Your application code is in ${fs.path.normalize(fs.path.join(fs.path.relative(projectPath), 'lib', 'main.dart'))}',
        ],
      );
      expect(libMain.existsSync(), isTrue);
    }, timeout: allowForRemotePubInvocation);

    // Analyze in the current directory - no arguments
    testUsingContext('working directory', () async {
      await runCommand(
        command: AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>['No issues found!'],
      );
    }, timeout: allowForSlowAnalyzeTests);

    // Analyze a specific file outside the current directory
    testUsingContext('passing one file throws', () async {
      await runCommand(
        command: AnalyzeCommand(),
        arguments: <String>['analyze', libMain.path],
        toolExit: true,
        exitMessageContains: 'is not a directory',
      );
    });

    // Analyze in the current directory - no arguments
    testUsingContext('working directory with errors', () async {
      // Break the code to produce the "The parameter 'onPressed' is required" hint
      // that is upgraded to a warning in package:flutter/analysis_options_user.yaml
      // to assert that we are using the default Flutter analysis options.
      // Also insert a statement that should not trigger a lint here
      // but will trigger a lint later on when an analysis_options.yaml is added.
      String source = await libMain.readAsString();
      source = source.replaceFirst(
        'onPressed: _incrementCounter,',
        '// onPressed: _incrementCounter,',
      );
      source = source.replaceFirst(
        '_counter++;',
        '_counter++; throw "an error message";',
      );
      await libMain.writeAsString(source);

      // Analyze in the current directory - no arguments
      await runCommand(
        command: AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'info $analyzerSeparator The method \'_incrementCounter\' isn\'t used',
        ],
        exitMessageContains: '2 issues found.',
        toolExit: true,
      );
    }, timeout: allowForSlowAnalyzeTests, overrides: noColorTerminalOverride);

    // Analyze in the current directory - no arguments
    testUsingContext('working directory with local options', () async {
      // Insert an analysis_options.yaml file in the project
      // which will trigger a lint for broken code that was inserted earlier
      final File optionsFile = fs.file(fs.path.join(projectPath, 'analysis_options.yaml'));
      await optionsFile.writeAsString('''
  include: package:flutter/analysis_options_user.yaml
  linter:
    rules:
      - only_throw_errors
  ''');

      // Analyze in the current directory - no arguments
      await runCommand(
        command: AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'info $analyzerSeparator The method \'_incrementCounter\' isn\'t used',
          'info $analyzerSeparator Only throw instances of classes extending either Exception or Error',
        ],
        exitMessageContains: '3 issues found.',
        toolExit: true,
      );
    }, timeout: allowForSlowAnalyzeTests, overrides: noColorTerminalOverride);

    testUsingContext('no duplicate issues', () async {
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_2.').absolute;

      try {
        final File foo = fs.file(fs.path.join(tempDir.path, 'foo.dart'));
        foo.writeAsStringSync('''
import 'bar.dart';

void foo() => bar();
''');

        final File bar = fs.file(fs.path.join(tempDir.path, 'bar.dart'));
        bar.writeAsStringSync('''
import 'dart:async'; // unused

void bar() {
}
''');

        // Analyze in the current directory - no arguments
        await runCommand(
          command: AnalyzeCommand(workingDirectory: tempDir),
          arguments: <String>['analyze'],
          statusTextContains: <String>[
            'Analyzing',
          ],
          exitMessageContains: '1 issue found.',
          toolExit: true,
        );
      } finally {
        tryToDelete(tempDir);
      }
    }, overrides: noColorTerminalOverride);

    testUsingContext('returns no issues when source is error-free', () async {
      const String contents = '''
StringBuffer bar = StringBuffer('baz');
''';
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_3.');
      tempDir.childFile('main.dart').writeAsStringSync(contents);
      try {
        await runCommand(
          command: AnalyzeCommand(workingDirectory: fs.directory(tempDir)),
          arguments: <String>['analyze'],
          statusTextContains: <String>['No issues found!'],
        );
      } finally {
        tryToDelete(tempDir);
      }
    }, overrides: noColorTerminalOverride);

    testUsingContext('returns no issues for todo comments', () async {
      const String contents = '''
// TODO(foobar):
StringBuffer bar = StringBuffer('baz');
''';
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_4.');
      tempDir.childFile('main.dart').writeAsStringSync(contents);
      try {
        await runCommand(
          command: AnalyzeCommand(workingDirectory: fs.directory(tempDir)),
          arguments: <String>['analyze'],
          statusTextContains: <String>['No issues found!'],
        );
      } finally {
        tryToDelete(tempDir);
      }
    }, overrides: noColorTerminalOverride);
  });
}

void assertContains(String text, List<String> patterns) {
  if (patterns == null) {
    expect(text, isEmpty);
  } else {
    for (String pattern in patterns) {
      expect(text, contains(pattern));
    }
  }
}

Future<void> runCommand({
  FlutterCommand command,
  List<String> arguments,
  List<String> statusTextContains,
  List<String> errorTextContains,
  bool toolExit = false,
  String exitMessageContains,
}) async {
  try {
    arguments.insert(0, '--flutter-root=${Cache.flutterRoot}');
    await createTestCommandRunner(command).run(arguments);
    expect(toolExit, isFalse, reason: 'Expected ToolExit exception');
  } on ToolExit catch (e) {
    if (!toolExit) {
      testLogger.clear();
      rethrow;
    }
    if (exitMessageContains != null) {
      expect(e.message, contains(exitMessageContains));
    }
  }
  assertContains(testLogger.statusText, statusTextContains);
  assertContains(testLogger.errorText, errorTextContains);

  testLogger.clear();
}
