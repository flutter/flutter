// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Platform _kNoColorTerminalPlatform = FakePlatform(stdoutSupportsAnsi: false);

void main() {
  String analyzerSeparator;
  FileSystem fileSystem;
  Platform platform;
  BufferLogger logger;
  AnsiTerminal terminal;
  ProcessManager processManager;
  Directory tempDir;
  String projectPath;
  File libMain;
  Artifacts artifacts;

  Future<void> runCommand({
    FlutterCommand command,
    List<String> arguments,
    List<String> statusTextContains,
    List<String> errorTextContains,
    bool toolExit = false,
    String exitMessageContains,
    int exitCode = 0,
  }) async {
    try {
      await createTestCommandRunner(command).run(arguments);
      expect(toolExit, isFalse, reason: 'Expected ToolExit exception');
    } on ToolExit catch (e) {
      if (!toolExit) {
        testLogger.clear();
        rethrow;
      }
      if (exitMessageContains != null) {
        expect(e.message, contains(exitMessageContains));
        // May not analyzer exception the `exitCode` is `null`.
        expect(e.exitCode ?? 0, exitCode);
      }
    }
    assertContains(logger.statusText, statusTextContains);
    assertContains(logger.errorText, errorTextContains);

    logger.clear();
  }

  void _createDotPackages(String projectPath, [bool nullSafe = false]) {
    final StringBuffer flutterRootUri = StringBuffer('file://');
    final String canonicalizedFlutterRootPath = fileSystem.path.canonicalize(Cache.flutterRoot);
    if (platform.isWindows) {
      flutterRootUri
          ..write('/')
          ..write(canonicalizedFlutterRootPath.replaceAll(r'\', '/'));
    } else {
      flutterRootUri.write(canonicalizedFlutterRootPath);
    }
    final String dotPackagesSrc = '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "flutter",
      "rootUri": "$flutterRootUri/packages/flutter",
      "packageUri": "lib/",
      "languageVersion": "2.10"
    },
    {
      "name": "sky_engine",
      "rootUri": "$flutterRootUri/bin/cache/pkg/sky_engine",
      "packageUri": "lib/",
      "languageVersion": "2.10"
    },
    {
      "name": "flutter_project",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "${nullSafe ? "2.10" : "2.7"}"
    }
  ]
}
''';

    fileSystem.file(fileSystem.path.join(projectPath, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(dotPackagesSrc);
  }

  setUpAll(() {
    Cache.disableLocking();
    processManager = const LocalProcessManager();
    platform = const LocalPlatform();
    terminal = AnsiTerminal(platform: platform, stdio: Stdio());
    fileSystem = LocalFileSystem.instance;
    logger = BufferLogger.test();
    analyzerSeparator = platform.isWindows ? '-' : '•';
    artifacts = CachedArtifacts(
      cache: globals.cache,
      fileSystem: fileSystem,
      platform: platform,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    Cache.flutterRoot = Cache.defaultFlutterRoot(
      fileSystem: fileSystem,
      platform: platform,
      userMessages: UserMessages(),
    );
  });

  setUp(() {
    tempDir = fileSystem.systemTempDirectory.createTempSync(
      'flutter_analyze_once_test_1.',
    ).absolute;
    projectPath = fileSystem.path.join(tempDir.path, 'flutter_project');
    fileSystem.file(fileSystem.path.join(projectPath, 'pubspec.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync(pubspecYamlSrc);
    _createDotPackages(projectPath);
    libMain = fileSystem.file(fileSystem.path.join(projectPath, 'lib', 'main.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(mainDartSrc);
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  // Analyze in the current directory - no arguments
  testUsingContext('working directory', () async {
    await runCommand(
      command: AnalyzeCommand(
        workingDirectory: fileSystem.directory(projectPath),
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
        terminal: terminal,
        artifacts: artifacts,
      ),
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>['No issues found!'],
    );
  });

  // Analyze a specific file outside the current directory
  testUsingContext('passing one file throws', () async {
    await runCommand(
      command: AnalyzeCommand(
        platform: platform,
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        terminal: terminal,
        artifacts: artifacts,
      ),
      arguments: <String>['analyze', '--no-pub', libMain.path],
      toolExit: true,
      exitMessageContains: 'is not a directory',
    );
  });

  // Analyze in the current directory - no arguments
  testUsingContext('working directory with errors', () async {
    // Break the code to produce the "Avoid empty else" hint
    // that is upgraded to a warning in package:flutter/analysis_options_user.yaml
    // to assert that we are using the default Flutter analysis options.
    // Also insert a statement that should not trigger a lint here
    // but will trigger a lint later on when an analysis_options.yaml is added.
    String source = await libMain.readAsString();
    source = source.replaceFirst(
      'return MaterialApp(',
      'if (debugPrintRebuildDirtyWidgets) {} else ; return MaterialApp(',
    );
    source = source.replaceFirst(
      'onPressed: _incrementCounter,',
      '// onPressed: _incrementCounter,',
    );
    source = source.replaceFirst(
        '_counter++;',
        '_counter++; throw "an error message";',
      );
    libMain.writeAsStringSync(source);

    // Analyze in the current directory - no arguments
    await runCommand(
      command: AnalyzeCommand(
        workingDirectory: fileSystem.directory(projectPath),
        platform: platform,
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        terminal: terminal,
        artifacts: artifacts,
      ),
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>[
        'Analyzing',
        'info $analyzerSeparator Avoid empty else statements',
        'info $analyzerSeparator Avoid empty statements',
        'info $analyzerSeparator The declaration \'_incrementCounter\' isn\'t',
        'warning $analyzerSeparator The parameter \'onPressed\' is required',
      ],
      exitMessageContains: '4 issues found.',
      toolExit: true,
      exitCode: 1,
    );
  });

  // Analyze in the current directory - no arguments
  testUsingContext('working directory with local options', () async {
    // Insert an analysis_options.yaml file in the project
    // which will trigger a lint for broken code that was inserted earlier
    final File optionsFile = fileSystem.file(fileSystem.path.join(projectPath, 'analysis_options.yaml'));
    try {
      optionsFile.writeAsStringSync('''
  include: package:flutter/analysis_options_user.yaml
  linter:
    rules:
      - only_throw_errors
  ''');
      String source = libMain.readAsStringSync();
      source = source.replaceFirst(
        'onPressed: _incrementCounter,',
        '// onPressed: _incrementCounter,',
      );
      source = source.replaceFirst(
        '_counter++;',
        '_counter++; throw "an error message";',
      );
      libMain.writeAsStringSync(source);

      // Analyze in the current directory - no arguments
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: fileSystem.directory(projectPath),
          platform: platform,
          fileSystem: fileSystem,
          logger: logger,
          processManager: processManager,
          terminal: terminal,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze', '--no-pub'],
        statusTextContains: <String>[
          'Analyzing',
          'info $analyzerSeparator The declaration \'_incrementCounter\' isn\'t',
          'info $analyzerSeparator Only throw instances of classes extending either Exception or Error',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
        ],
        exitMessageContains: '3 issues found.',
        toolExit: true,
        exitCode: 1,
      );
    } finally {
      ErrorHandlingFileSystem.deleteIfExists(optionsFile);
    }
  });

  testUsingContext('analyze once no duplicate issues', () async {
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_analyze_once_test_2.').absolute;
    _createDotPackages(tempDir.path);

    try {
      final File foo = fileSystem.file(fileSystem.path.join(tempDir.path, 'foo.dart'));
      foo.writeAsStringSync('''
import 'bar.dart';

void foo() => bar();
''');

      final File bar = fileSystem.file(fileSystem.path.join(tempDir.path, 'bar.dart'));
      bar.writeAsStringSync('''
import 'dart:async'; // unused

void bar() {
}
''');

      // Analyze in the current directory - no arguments
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: tempDir,
          platform: platform,
          fileSystem: fileSystem,
          logger: logger,
          processManager: processManager,
          terminal: terminal,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze', '--no-pub'],
        statusTextContains: <String>[
          'Analyzing',
        ],
        exitMessageContains: '1 issue found.',
        toolExit: true,
        exitCode: 1
      );
    } finally {
      tryToDelete(tempDir);
    }
  });

  testUsingContext('analyze once returns no issues when source is error-free', () async {
    const String contents = '''
StringBuffer bar = StringBuffer('baz');
''';
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_analyze_once_test_3.');
    _createDotPackages(tempDir.path);

    tempDir.childFile('main.dart').writeAsStringSync(contents);
    try {
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: fileSystem.directory(tempDir),
          platform: _kNoColorTerminalPlatform,
          fileSystem: fileSystem,
          logger: logger,
          processManager: processManager,
          terminal: terminal,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze', '--no-pub'],
        statusTextContains: <String>['No issues found!'],
      );
    } finally {
      tryToDelete(tempDir);
    }
  });

  testUsingContext('analyze once returns no issues for todo comments', () async {
    const String contents = '''
// TODO(foobar):
StringBuffer bar = StringBuffer('baz');
''';
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_analyze_once_test_4.');
    _createDotPackages(tempDir.path);

    tempDir.childFile('main.dart').writeAsStringSync(contents);
    try {
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: fileSystem.directory(tempDir),
          platform: _kNoColorTerminalPlatform,
          terminal: terminal,
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze', '--no-pub'],
        statusTextContains: <String>['No issues found!'],
      );
    } finally {
      tryToDelete(tempDir);
    }
  });

  testUsingContext('analyze once with default options has info issue finally exit code 1.', () async {
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_analyze_once_default_options_info_issue_exit_code_1.');
    _createDotPackages(tempDir.path);

    const String infoSourceCode = '''
int analyze() {}
''';

    tempDir.childFile('main.dart').writeAsStringSync(infoSourceCode);
    try {
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: fileSystem.directory(tempDir),
          platform: _kNoColorTerminalPlatform,
          terminal: terminal,
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze', '--no-pub'],
        statusTextContains: <String>[
          'info',
          'missing_return',
        ],
        exitMessageContains: '1 issue found.',
        toolExit: true,
        exitCode: 1,
      );
    } finally {
      tryToDelete(tempDir);
    }
  });

  testUsingContext('analyze once with no-fatal-infos has info issue finally exit code 0.', () async {
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_analyze_once_no_fatal_infos_info_issue_exit_code_0.');
    _createDotPackages(tempDir.path);

    const String infoSourceCode = '''
int analyze() {}
''';

    tempDir.childFile('main.dart').writeAsStringSync(infoSourceCode);
    try {
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: fileSystem.directory(tempDir),
          platform: _kNoColorTerminalPlatform,
          terminal: terminal,
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze', '--no-pub', '--no-fatal-infos'],
        statusTextContains: <String>[
          'info',
          'missing_return',
        ],
        exitMessageContains: '1 issue found.',
        toolExit: true,
        exitCode: 0,
      );
    } finally {
      tryToDelete(tempDir);
    }
  });

  testUsingContext('analyze once only fatal-warnings has info issue finally exit code 0.', () async {
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_analyze_once_only_fatal_warnings_info_issue_exit_code_0.');
    _createDotPackages(tempDir.path);

    const String infoSourceCode = '''
int analyze() {}
''';

    tempDir.childFile('main.dart').writeAsStringSync(infoSourceCode);
    try {
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: fileSystem.directory(tempDir),
          platform: _kNoColorTerminalPlatform,
          terminal: terminal,
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze', '--no-pub', '--fatal-warnings', '--no-fatal-infos'],
        statusTextContains: <String>[
          'info',
          'missing_return',
        ],
        exitMessageContains: '1 issue found.',
        toolExit: true,
        exitCode: 0,
      );
    } finally {
      tryToDelete(tempDir);
    }
  });

  testUsingContext('analyze once only fatal-infos has warning issue finally exit code 1.', () async {
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_analyze_once_only_fatal_infos_warning_issue_exit_code_1.');
    _createDotPackages(tempDir.path);

    const String warningSourceCode = '''
int analyze() {}
''';

    final File optionsFile = fileSystem.file(fileSystem.path.join(tempDir.path, 'analysis_options.yaml'));
    optionsFile.writeAsStringSync('''
analyzer:
  errors:
    missing_return: warning
  ''');

    tempDir.childFile('main.dart').writeAsStringSync(warningSourceCode);
    try {
      await runCommand(
        command: AnalyzeCommand(
          workingDirectory: fileSystem.directory(tempDir),
          platform: _kNoColorTerminalPlatform,
          terminal: terminal,
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          artifacts: artifacts,
        ),
        arguments: <String>['analyze','--no-pub', '--fatal-infos', '--no-fatal-warnings'],
        statusTextContains: <String>[
          'warning',
          'missing_return',
        ],
        exitMessageContains: '1 issue found.',
        toolExit: true,
        exitCode: 1,
      );
    } finally {
      tryToDelete(tempDir);
    }
  });
}

void assertContains(String text, List<String> patterns) {
  if (patterns != null) {
    for (final String pattern in patterns) {
      expect(text, contains(pattern));
    }
  }
}

const String mainDartSrc = r'''
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
''';

const String pubspecYamlSrc = r'''
name: flutter_project
environment:
  sdk: ">=2.1.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
''';
