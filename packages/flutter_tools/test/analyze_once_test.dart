// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  Directory tempDir, originalDir;
  File libMain;

  setUpAll(() {
    Cache.disableLocking();
    originalDir = fs.currentDirectory.absolute;
    tempDir = fs.systemTempDirectory.createTempSync('analyze_once_test_').absolute;
    libMain = fs.file(fs.path.join(tempDir.path, 'lib', 'main.dart'));
  });

  tearDownAll(() {
    fs.currentDirectory = originalDir;
    tempDir?.deleteSync(recursive: true);
  });

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
    } on ToolExit catch (_) {
      if (!toolExit) {
        testLogger.clear();
        rethrow;
      }
    }
    assertContains(testLogger.statusText, statusTextContains);
    assertContains(testLogger.errorText, errorTextContains);
    testLogger.clear();
  }

  // Create a project to be analyzed
  testUsingContext('flutter create', () async {
    await runCommand(
      command: new CreateCommand(),
      arguments: <String>['create', tempDir.path],
      statusTextContains: <String>[
        'All done!',
        'Your main program file is lib/main.dart',
      ],
    );
    expect(libMain.existsSync(), isTrue);
  });

  // Analyze in the current directory - no arguments
  testUsingContext('flutter analyze working directory', () async {
    fs.currentDirectory = tempDir;
    await runCommand(
      command: new AnalyzeCommand(),
      arguments: <String>['analyze'],
      statusTextContains: <String>['No issues found!'],
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => new TestLocalFileSystem(tempDir),
  });

  // Analyze a specific file outside the current directory
  testUsingContext('flutter analyze one file', () async {
    fs.currentDirectory = originalDir;
    await runCommand(
      command: new AnalyzeCommand(),
      arguments: <String>['analyze', libMain.path],
      statusTextContains: <String>['No issues found!'],
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => new TestLocalFileSystem(originalDir),
  });

  // Analyze in the current directory - no arguments
  testUsingContext('flutter analyze working directory with errors', () async {

    // Break the code to produce the "The parameter 'child' is required" hint
    // that is upgraded to a warning in package:flutter/analysis_options_user.yaml
    // to assert that we are using the default Flutter analysis options.
    // Also insert a statement that should not trigger a lint here
    // but will trigger a lint later on when an analysis_options.yaml is added.
    String source = await libMain.readAsString();
    source = source.replaceFirst(
      'child: new Icon(Icons.add),',
      '// child: new Icon(Icons.add),',
    );
    source = source.replaceFirst(
      '_counter++;',
      '_counter++; throw "an error message";',
    );
    await libMain.writeAsString(source);

    /// Analyze in the current directory - no arguments
    fs.currentDirectory = tempDir;
    await runCommand(
      command: new AnalyzeCommand(),
      arguments: <String>['analyze'],
      statusTextContains: <String>[
        'Analyzing',
        '[warning] The parameter \'child\' is required',
        '1 warning found.',
      ],
      // TODO(danrubel) fix dartanalyzer to have non-zero exit code
      toolExit: false,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => new TestLocalFileSystem(tempDir),
  });

  // Analyze a specific file outside the current directory
  testUsingContext('flutter analyze one file with errors', () async {
    fs.currentDirectory = originalDir;
    await runCommand(
      command: new AnalyzeCommand(),
      arguments: <String>['analyze', libMain.path],
      statusTextContains: <String>[
        'Analyzing',
        '[warning] The parameter \'child\' is required',
        '1 warning found.',
      ],
      // TODO(danrubel) fix dartanalyzer to have non-zero exit code
      toolExit: false,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => new TestLocalFileSystem(originalDir),
  });

  // Analyze in the current directory - no arguments
  testUsingContext('flutter analyze working directory with local options', () async {

    // Insert an analysis_options.yaml file in the project
    // which will trigger a lint for broken code that was inserted earlier
    final File optionsFile = fs.file(fs.path.join(tempDir.path, 'analysis_options.yaml'));
    await optionsFile.writeAsString('''
include: package:flutter/analysis_options_user.yaml
linter:
  rules:
    - only_throw_errors
''');

    /// Analyze in the current directory - no arguments
    fs.currentDirectory = tempDir;
    await runCommand(
      command: new AnalyzeCommand(),
      arguments: <String>['analyze'],
      statusTextContains: <String>[
        'Analyzing',
        '[warning] The parameter \'child\' is required',
        '[lint] Only throw instances of classes extending either Exception or Error',
        '1 warning and 1 lint found.',
      ],
      // TODO(danrubel) fix dartanalyzer to have non-zero exit code
      toolExit: false,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => new TestLocalFileSystem(tempDir),
  });

  // Analyze a specific file outside the current directory
  testUsingContext('flutter analyze one file with local options', () async {

    /// Analyze a specific file outside the current directory
    fs.currentDirectory = originalDir;
    await runCommand(
      command: new AnalyzeCommand(),
      arguments: <String>['analyze', libMain.path],
      statusTextContains: <String>[
        'Analyzing',
        '[warning] The parameter \'child\' is required',
        '[lint] Only throw instances of classes extending either Exception or Error',
        '1 warning and 1 lint found.',
      ],
      // TODO(danrubel) fix dartanalyzer to have non-zero exit code
      toolExit: false,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => new TestLocalFileSystem(originalDir),
  });
}

class TestLocalFileSystem extends LocalFileSystem {
  final Directory wd;

  TestLocalFileSystem(this.wd);

  @override
  p.Context get path => new p.Context(current: wd.path);
}
