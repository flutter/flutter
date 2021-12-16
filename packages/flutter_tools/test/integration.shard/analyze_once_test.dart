// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import '../src/common.dart';
import 'test_utils.dart';

final String analyzerSeparator = platform.isWindows ? '-' : '•';

void main() {
  late Directory tempDir;
  late String projectPath;
  late File libMain;

  Future<void> runCommand({
    List<String> arguments = const <String>[],
    List<String> statusTextContains = const <String>[],
    List<String> errorTextContains = const <String>[],
    String exitMessageContains = '',
    int exitCode = 0,
  }) async {
    final ProcessResult result = await processManager.run(<String>[
      fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter'),
      '--no-color',
      ...arguments,
    ], workingDirectory: projectPath);
    printOnFailure('Output of flutter ${arguments.join(" ")}');
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());
    expect(result.exitCode, exitCode, reason: 'Expected to exit with non-zero exit code.');
    assertContains(result.stdout.toString(), statusTextContains);
    assertContains(result.stdout.toString(), errorTextContains);
    expect(result.stderr, contains(exitMessageContains));
  }

  void _createDotPackages(String projectPath, [bool nullSafe = false]) {
    final StringBuffer flutterRootUri = StringBuffer('file://');
    final String canonicalizedFlutterRootPath = fileSystem.path.canonicalize(getFlutterRoot());
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
      "languageVersion": "${nullSafe ? "2.12" : "2.7"}"
    }
  ]
}
''';

    fileSystem.file(fileSystem.path.join(projectPath, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(dotPackagesSrc);
  }

  setUp(() {
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_analyze_once_test_1.').absolute;
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
  testWithoutContext('working directory', () async {
    await runCommand(
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>['No issues found!'],
    );
  });

  // testWithoutContext a specific file outside the current directory
  testWithoutContext('passing one file throws', () async {
    await runCommand(
      arguments: <String>['analyze', '--no-pub', libMain.path],
      exitMessageContains: 'is not a directory',
      exitCode: 1,
    );
  });

  // Analyze in the current directory - no arguments
  testWithoutContext('working directory with errors', () async {
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
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>[
        'Analyzing',
        'info $analyzerSeparator Avoid empty else statements',
        'info $analyzerSeparator Avoid empty statements',
        "info $analyzerSeparator The declaration '_incrementCounter' isn't",
        "warning $analyzerSeparator The parameter 'onPressed' is required",
      ],
      exitMessageContains: '4 issues found.',
      exitCode: 1,
    );
  });

  // Analyze in the current directory - no arguments
  testWithoutContext('working directory with local options', () async {
    // Insert an analysis_options.yaml file in the project
    // which will trigger a lint for broken code that was inserted earlier
    final File optionsFile = fileSystem.file(fileSystem.path.join(projectPath, 'analysis_options.yaml'));
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
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>[
        'Analyzing',
        "info $analyzerSeparator The declaration '_incrementCounter' isn't",
        'info $analyzerSeparator Only throw instances of classes extending either Exception or Error',
        "warning $analyzerSeparator The parameter 'onPressed' is required",
      ],
      exitMessageContains: '3 issues found.',
      exitCode: 1,
    );
  });

  testWithoutContext('analyze once no duplicate issues', () async {
    final File foo = fileSystem.file(fileSystem.path.join(projectPath, 'foo.dart'));
    foo.writeAsStringSync('''
import 'bar.dart';

void foo() => bar();
''');

    final File bar = fileSystem.file(fileSystem.path.join(projectPath, 'bar.dart'));
    bar.writeAsStringSync('''
import 'dart:async'; // unused

void bar() {
}
''');

    // Analyze in the current directory - no arguments
    await runCommand(
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>[
        'Analyzing',
      ],
      exitMessageContains: '1 issue found.',
      exitCode: 1
    );
  });

  testWithoutContext('analyze once returns no issues when source is error-free', () async {
    const String contents = '''
StringBuffer bar = StringBuffer('baz');
''';

    fileSystem.directory(projectPath).childFile('main.dart').writeAsStringSync(contents);
    await runCommand(
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>['No issues found!'],
    );
  });

  testWithoutContext('analyze once returns no issues for todo comments', () async {
    const String contents = '''
// TODO(foobar):
StringBuffer bar = StringBuffer('baz');
''';

    fileSystem.directory(projectPath).childFile('main.dart').writeAsStringSync(contents);
    await runCommand(
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>['No issues found!'],
    );
  });

  testWithoutContext('analyze once with default options has info issue finally exit code 1.', () async {
    const String infoSourceCode = '''
int analyze() {}
''';

    fileSystem.directory(projectPath).childFile('main.dart').writeAsStringSync(infoSourceCode);
    await runCommand(
      arguments: <String>['analyze', '--no-pub'],
      statusTextContains: <String>[
        'info',
        'missing_return',
      ],
      exitMessageContains: '1 issue found.',
      exitCode: 1,
    );
  });

  testWithoutContext('analyze once with no-fatal-infos has info issue finally exit code 0.', () async {
    const String infoSourceCode = '''
int analyze() {}
''';

    fileSystem.directory(projectPath).childFile('main.dart').writeAsStringSync(infoSourceCode);
    await runCommand(
      arguments: <String>['analyze', '--no-pub', '--no-fatal-infos'],
      statusTextContains: <String>[
        'info',
        'missing_return',
      ],
      exitMessageContains: '1 issue found.',
    );
  });

  testWithoutContext('analyze once only fatal-warnings has info issue finally exit code 0.', () async {
    const String infoSourceCode = '''
int analyze() {}
''';

    fileSystem.directory(projectPath).childFile('main.dart').writeAsStringSync(infoSourceCode);
    await runCommand(
      arguments: <String>['analyze', '--no-pub', '--fatal-warnings', '--no-fatal-infos'],
      statusTextContains: <String>[
        'info',
        'missing_return',
      ],
      exitMessageContains: '1 issue found.',
    );
  });

  testWithoutContext('analyze once only fatal-infos has warning issue finally exit code 1.', () async {
    const String warningSourceCode = '''
int analyze() {}
''';

    final File optionsFile = fileSystem.file(fileSystem.path.join(projectPath, 'analysis_options.yaml'));
    optionsFile.writeAsStringSync('''
analyzer:
  errors:
    missing_return: warning
  ''');

    fileSystem.directory(projectPath).childFile('main.dart').writeAsStringSync(warningSourceCode);
    await runCommand(
      arguments: <String>['analyze','--no-pub', '--fatal-infos', '--no-fatal-warnings'],
      statusTextContains: <String>[
        'warning',
        'missing_return',
      ],
      exitMessageContains: '1 issue found.',
      exitCode: 1,
    );
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
