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
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {

  final String analyzerSeparator = platform.isWindows ? '-' : '•';

  group('analyze once', () {
    Directory tempDir;
    String projectPath;
    File libMain;

    setUpAll(() {
      Cache.disableLocking();
      tempDir = fs.systemTempDirectory.createTempSync('analyze_once_test_').absolute;
      projectPath = fs.path.join(tempDir.path, 'flutter_project');
      libMain = fs.file(fs.path.join(projectPath, 'lib', 'main.dart'));
    });

    tearDownAll(() {
      tempDir?.deleteSync(recursive: true);
    });

    // Create a project to be analyzed
    testUsingContext('flutter create', () async {
      await runCommand(
        command: new CreateCommand(),
        arguments: <String>['create', projectPath],
        statusTextContains: <String>[
          'All done!',
          'Your main program file is lib/main.dart',
        ],
      );
      expect(libMain.existsSync(), isTrue);
    }, timeout: allowForRemotePubInvocation);

    // Analyze in the current directory - no arguments
    testUsingContext('flutter analyze working directory', () async {
      await runCommand(
        command: new AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>['No issues found!'],
      );
    });

    // Analyze a specific file outside the current directory
    testUsingContext('flutter analyze one file', () async {
      await runCommand(
        command: new AnalyzeCommand(),
        arguments: <String>['analyze', libMain.path],
        statusTextContains: <String>['No issues found!'],
      );
    });

    // Analyze in the current directory - no arguments
    testUsingContext('flutter analyze working directory with errors', () async {

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
        command: new AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'hint $analyzerSeparator The method \'_incrementCounter\' isn\'t used',
          '2 issues found.',
        ],
        toolExit: true,
      );
    });

    // Analyze a specific file outside the current directory
    testUsingContext('flutter analyze one file with errors', () async {
      await runCommand(
        command: new AnalyzeCommand(),
        arguments: <String>['analyze', libMain.path],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'hint $analyzerSeparator The method \'_incrementCounter\' isn\'t used',
          '2 issues found.',
        ],
        toolExit: true,
      );
    });

    // Analyze in the current directory - no arguments
    testUsingContext('flutter analyze working directory with local options', () async {

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
        command: new AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'hint $analyzerSeparator The method \'_incrementCounter\' isn\'t used',
          'lint $analyzerSeparator Only throw instances of classes extending either Exception or Error',
          '3 issues found.',
        ],
        toolExit: true,
      );
    });

    testUsingContext('flutter analyze no duplicate issues', () async {
      final Directory tempDir = fs.systemTempDirectory.createTempSync('analyze_once_test_').absolute;

      try {
        final File foo = fs.file(fs.path.join(tempDir.path, 'foo.dart'));
        foo.writeAsStringSync('''
import 'bar.dart';

foo() => bar();
''');

        final File bar = fs.file(fs.path.join(tempDir.path, 'bar.dart'));
        bar.writeAsStringSync('''
import 'dart:async'; // unused

void bar() {
}
''');

        // Analyze in the current directory - no arguments
        await runCommand(
          command: new AnalyzeCommand(workingDirectory: tempDir),
          arguments: <String>['analyze'],
          statusTextContains: <String>[
            'Analyzing',
            '1 issue found.',
          ],
          toolExit: true,
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // Analyze a specific file outside the current directory
    testUsingContext('flutter analyze one file with local options', () async {
      await runCommand(
        command: new AnalyzeCommand(),
        arguments: <String>['analyze', libMain.path],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'hint $analyzerSeparator The method \'_incrementCounter\' isn\'t used',
          'lint $analyzerSeparator Only throw instances of classes extending either Exception or Error',
          '3 issues found.',
        ],
        toolExit: true,
      );
    });

    testUsingContext('--preview-dart-2', () async {
      const String contents = '''
StringBuffer bar = StringBuffer('baz');
''';

      final Directory tempDir = fs.systemTempDirectory.createTempSync();
      tempDir.childFile('main.dart').writeAsStringSync(contents);

      try {
        await runCommand(
          command: new AnalyzeCommand(workingDirectory: fs.directory(tempDir)),
          arguments: <String>['analyze', '--preview-dart-2'],
          statusTextContains: <String>['No issues found!'],
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    testUsingContext('no --preview-dart-2 shows errors', () async {
      const String contents = '''
StringBuffer bar = StringBuffer('baz');
''';

      final Directory tempDir = fs.systemTempDirectory.createTempSync();
      tempDir.childFile('main.dart').writeAsStringSync(contents);

      try {
        await runCommand(
          command: new AnalyzeCommand(workingDirectory: fs.directory(tempDir)),
          arguments: <String>['analyze'],
          statusTextContains: <String>['1 issue found.'],
          toolExit: true,
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
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

Future<Null> runCommand({
  FlutterCommand command,
  List<String> arguments,
  List<String> statusTextContains,
  List<String> errorTextContains,
  bool toolExit: false,
}) async {
  try {
    arguments.insert(0, '--flutter-root=${Cache.flutterRoot}');
    await createTestCommandRunner(command).run(arguments);
    expect(toolExit, isFalse, reason: 'Expected ToolExit exception');
  } on ToolExit {
    if (!toolExit) {
      testLogger.clear();
      rethrow;
    }
  }
  assertContains(testLogger.statusText, statusTextContains);
  assertContains(testLogger.errorText, errorTextContains);
  testLogger.clear();
}
