// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

typedef Future<Null> ShardRunner();

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
final String pub = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
final String flutterTestArgs = Platform.environment['FLUTTER_TEST_ARGS'];
final bool hasColor = stdout.supportsAnsiEscapes;

final String bold = hasColor ? '\x1B[1m' : '';
final String red = hasColor ? '\x1B[31m' : '';
final String green = hasColor ? '\x1B[32m' : '';
final String yellow = hasColor ? '\x1B[33m' : '';
final String cyan = hasColor ? '\x1B[36m' : '';
final String reset = hasColor ? '\x1B[0m' : '';

const Map<String, ShardRunner> _kShards = const <String, ShardRunner>{
  'docs': _generateDocs,
  'analyze': _analyzeRepo,
  'tests': _runTests,
  'coverage': _runCoverage,
};

/// When you call this, you can set FLUTTER_TEST_ARGS to pass custom
/// arguments to flutter test. For example, you might want to call this
/// script using FLUTTER_TEST_ARGS=--local-engine=host_debug_unopt to
/// use your own build of the engine.
///
/// To run the analysis part, run it with SHARD=analyze
///
/// For example:
/// SHARD=analyze bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// FLUTTER_TEST_ARGS=--local-engine=host_debug_unopt bin/cache/dart-sdk/bin/dart dev/bots/test.dart
Future<Null> main() async {
  final String shard = Platform.environment['SHARD'] ?? 'tests';
  if (!_kShards.containsKey(shard))
    throw new ArgumentError('Invalid shard: $shard');
  await _kShards[shard]();
}

Future<Null> _generateDocs() async {
  print('${bold}DONE: test.dart does nothing in the docs shard.$reset');
}

Future<Null> _verifyInternationalizations() async {
  final EvalResult genResult = await _evalCommand(
    dart,
    <String>[
      path.join('dev', 'tools', 'gen_localizations.dart'),
      path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n'),
      'material'
    ],
    workingDirectory: flutterRoot,
  );

  final String localizationsFile = path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n', 'localizations.dart');

  final EvalResult sourceContents = await _evalCommand(
    'cat',
    <String>[localizationsFile],
    workingDirectory: flutterRoot,
  );

  if (genResult.stdout.trim() != sourceContents.stdout.trim()) {
    stderr
      ..writeln('<<<<<<< $localizationsFile')
      ..writeln(sourceContents.stdout.trim())
      ..writeln('=======')
      ..writeln(genResult.stdout.trim())
      ..writeln('>>>>>>> gen_localizations')
      ..writeln('The contents of $localizationsFile are different from that produced by gen_localizations.')
      ..writeln()
      ..writeln('Did you forget to run gen_localizations.dart after updating a .arb file?');
    exit(1);
  }
}

Future<Null> _analyzeRepo() async {
  await _verifyNoBadImports(flutterRoot);
  await _verifyInternationalizations();

  // Analyze all the Dart code in the repo.
  await _runFlutterAnalyze(flutterRoot,
    options: <String>['--flutter-repo'],
  );

  // Analyze all the sample code in the repo
  await _runCommand(dart, <String>[path.join(flutterRoot, 'dev', 'bots', 'analyze-sample-code.dart')],
    workingDirectory: flutterRoot,
  );

  // Try with the --watch analyzer, to make sure it returns success also.
  // The --benchmark argument exits after one run.
  await _runFlutterAnalyze(flutterRoot,
    options: <String>['--flutter-repo', '--watch', '--benchmark'],
  );

  // Try an analysis against a big version of the gallery.
  await _runCommand(dart, <String>[path.join(flutterRoot, 'dev', 'tools', 'mega_gallery.dart')],
    workingDirectory: flutterRoot,
  );
  await _runFlutterAnalyze(path.join(flutterRoot, 'dev', 'benchmarks', 'mega_gallery'),
    options: <String>['--watch', '--benchmark'],
  );

  print('${bold}DONE: Analysis successful.$reset');
}

Future<Null> _runTests() async {
  // Verify that the tests actually return failure on failure and success on success.
  final String automatedTests = path.join(flutterRoot, 'dev', 'automated_tests');
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'fail_test.dart'),
    expectFailure: true,
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'pass_test.dart'),
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'crash1_test.dart'),
    expectFailure: true,
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'crash2_test.dart'),
    expectFailure: true,
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'syntax_error_test.broken_dart'),
    expectFailure: true,
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'missing_import_test.broken_dart'),
    expectFailure: true,
    printOutput: false,
  );
  await _runCommand(flutter, <String>['drive', '--use-existing-app', '-t', path.join('test_driver', 'failure.dart')],
    workingDirectory: path.join(flutterRoot, 'packages', 'flutter_driver'),
    expectFailure: true,
    printOutput: false,
  );

  // Run tests.
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'));
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'));
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'));
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'));
  await _pubRunTest(path.join(flutterRoot, 'packages', 'flutter_tools'));

  await _runAllDartTests(path.join(flutterRoot, 'dev', 'devicelab'));
  await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'hello_world'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'layers'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'stocks'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'catalog'));

  print('${bold}DONE: All tests successful.$reset');
}

Future<Null> _runCoverage() async {
  if (Platform.environment['TRAVIS'] == null ||
      Platform.environment['TRAVIS_PULL_REQUEST'] != 'false' ||
      Platform.environment['TRAVIS_OS_NAME'] != 'linux') {
    print('${bold}DONE: test.dart does not run coverage for Travis pull requests or not non-Linux environments');
    return;
  }

  final File coverageFile = new File(path.join(flutterRoot, 'packages', 'flutter', 'coverage', 'lcov.info'));
  if (!coverageFile.existsSync()) {
    print('${red}Coverage file not found.$reset');
    print('Expected to find: ${coverageFile.absolute}');
    print('This file is normally obtained by running `flutter update-packages`.');
    exit(1);
  }
  coverageFile.deleteSync();
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'),
    options: const <String>['--coverage'],
  );
  if (!coverageFile.existsSync()) {
    print('${red}Coverage file not found.$reset');
    print('Expected to find: ${coverageFile.absolute}');
    print('This file should have been generated by the `flutter test --coverage` script, but was not.');
    exit(1);
  }

  print('${bold}DONE: Coverage collection successful.$reset');
}

Future<Null> _pubRunTest(
  String workingDirectory, {
  String testPath,
}) {
  final List<String> args = <String>['run', 'test', '-j1', '-rexpanded'];
  if (testPath != null)
    args.add(testPath);
  return _runCommand(pub, args, workingDirectory: workingDirectory);
}

class EvalResult {
  EvalResult({
    this.stdout,
    this.stderr,
  });

  final String stdout;
  final String stderr;
}

Future<EvalResult> _evalCommand(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool skip: false,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);
  if (skip) {
    _printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return null;
  }
  _printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  final Future<List<List<int>>> savedStdout = process.stdout.toList();
  final Future<List<List<int>>> savedStderr = process.stderr.toList();
  final int exitCode = await process.exitCode;
  final EvalResult result = new EvalResult(
    stdout: UTF8.decode((await savedStdout).expand((List<int> ints) => ints).toList()),
    stderr: UTF8.decode((await savedStderr).expand((List<int> ints) => ints).toList()),
  );

  if (exitCode != 0) {
    stderr.write(result.stderr);
    print(
      '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset\n'
      '${bold}ERROR:$red Last command exited with $exitCode.$reset\n'
      '${bold}Command:$red $commandDescription$reset\n'
      '${bold}Relative working directory:$red $relativeWorkingDir$reset\n'
      '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset'
    );
    exit(1);
  }

  return result;
}

Future<Null> _runCommand(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectFailure: false,
  bool printOutput: true,
  bool skip: false,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);
  if (skip) {
    _printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return null;
  }
  _printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  Future<List<List<int>>> savedStdout, savedStderr;
  if (printOutput) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
  } else {
    savedStdout = process.stdout.toList();
    savedStderr = process.stderr.toList();
  }

  final int exitCode = await process.exitCode;
  if ((exitCode == 0) == expectFailure) {
    if (!printOutput) {
      print(UTF8.decode((await savedStdout).expand((List<int> ints) => ints).toList()));
      print(UTF8.decode((await savedStderr).expand((List<int> ints) => ints).toList()));
    }
    print(
      '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset\n'
      '${bold}ERROR:$red Last command exited with $exitCode (expected: ${expectFailure ? 'non-zero' : 'zero'}).$reset\n'
      '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset'
    );
    exit(1);
  }
}

Future<Null> _runFlutterTest(String workingDirectory, {
    String script,
    bool expectFailure: false,
    bool printOutput: true,
    List<String> options: const <String>[],
    bool skip: false,
}) {
  final List<String> args = <String>['test']..addAll(options);
  if (flutterTestArgs != null && flutterTestArgs.isNotEmpty)
    args.add(flutterTestArgs);
  if (script != null)
    args.add(script);
  return _runCommand(flutter, args,
    workingDirectory: workingDirectory,
    expectFailure: expectFailure,
    printOutput: printOutput,
    skip: skip || Platform.isWindows, // TODO(goderbauer): run on Windows when sky_shell is available
  );
}

Future<Null> _runAllDartTests(String workingDirectory, {
  Map<String, String> environment,
}) {
  final List<String> args = <String>['--checked', path.join('test', 'all.dart')];
  return _runCommand(dart, args,
    workingDirectory: workingDirectory,
    environment: environment,
  );
}

Future<Null> _runFlutterAnalyze(String workingDirectory, {
  List<String> options: const <String>[]
}) {
  return _runCommand(flutter, <String>['analyze']..addAll(options),
    workingDirectory: workingDirectory,
  );
}

Future<Null> _verifyNoBadImports(String workingDirectory) async {
  final List<String> errors = <String>[];
  final String libPath = path.join(workingDirectory, 'packages', 'flutter', 'lib');
  final String srcPath = path.join(workingDirectory, 'packages', 'flutter', 'lib', 'src');
  // Verify there's one libPath/*.dart for each srcPath/*/.
  final List<String> packages = new Directory(libPath).listSync()
    .where((FileSystemEntity entity) => entity is File && path.extension(entity.path) == '.dart')
    .map<String>((FileSystemEntity entity) => path.basenameWithoutExtension(entity.path))
    .toList()..sort();
  final List<String> directories = new Directory(srcPath).listSync()
    .where((FileSystemEntity entity) => entity is Directory)
    .map<String>((FileSystemEntity entity) => path.basename(entity.path))
    .toList()..sort();
  if (!_matches(packages, directories)) {
    errors.add(
      'flutter/lib/*.dart does not match flutter/lib/src/*/:\n'
      'These are the exported packages:\n' +
      packages.map((String path) => '  lib/$path.dart').join('\n') +
      'These are the directories:\n' +
      directories.map((String path) => '  lib/src/$path/').join('\n')
    );
  }
  // Verify that the imports are well-ordered.
  final Map<String, Set<String>> dependencyMap = new Map<String, Set<String>>.fromIterable(
    directories,
    key: (String directory) => directory,
    value: (String directory) => _findDependencies(path.join(srcPath, directory), errors, checkForMeta: directory != 'foundation'),
  );
  for (String package in dependencyMap.keys) {
    if (dependencyMap[package].contains(package)) {
      errors.add(
        'One of the files in the $yellow$package$reset package imports that package recursively.'
      );
    }
  }
  for (String package in dependencyMap.keys) {
    final List<String> loop = _deepSearch(dependencyMap, package);
    if (loop != null) {
      errors.add(
        '${yellow}Dependency loop:$reset ' +
        loop.join(' depends on ')
      );
    }
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    print('$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset');
    if (errors.length == 1) {
      print('${bold}An error was detected when looking at import dependencies within the Flutter package:$reset\n');
    } else {
      print('${bold}Multiple errors were detected when looking at import dependencies within the Flutter package:$reset\n');
    }
    print(errors.join('\n\n'));
    print('$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset\n');
    exit(1);
  }
}

bool _matches<T>(List<T> a, List<T> b) {
  assert(a != null);
  assert(b != null);
  if (a.length != b.length)
    return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index])
      return false;
  }
  return true;
}

final RegExp _importPattern = new RegExp(r"import 'package:flutter/([^.]+)\.dart'");
final RegExp _importMetaPattern = new RegExp(r"import 'package:meta/meta.dart'");

Set<String> _findDependencies(String srcPath, List<String> errors, { bool checkForMeta: false }) {
  return new Directory(srcPath).listSync().where((FileSystemEntity entity) {
    return entity is File && path.extension(entity.path) == '.dart';
  }).map<Set<String>>((FileSystemEntity entity) {
    final Set<String> result = new Set<String>();
    final File file = entity;
    for (String line in file.readAsLinesSync()) {
      Match match = _importPattern.firstMatch(line);
      if (match != null)
        result.add(match.group(1));
      if (checkForMeta) {
        match = _importMetaPattern.firstMatch(line);
        if (match != null) {
          errors.add(
            '${file.path}\nThis package imports the ${yellow}meta$reset package.\n'
            'You should instead import the "foundation.dart" library.'
          );
        }
      }
    }
    return result;
  }).reduce((Set<String> value, Set<String> element) {
    value ??= new Set<String>();
    value.addAll(element);
    return value;
  });
}

List<T> _deepSearch<T>(Map<T, Set<T>> map, T start, [ Set<T> seen ]) {
  for (T key in map[start]) {
    if (key == start)
      continue; // we catch these separately
    if (seen != null && seen.contains(key))
      return <T>[start, key];
    final List<T> result = _deepSearch(
      map,
      key,
      (seen == null ? new Set<T>.from(<T>[start]) : new Set<T>.from(seen))..add(key),
    );
    if (result != null) {
      result.insert(0, start);
      // Only report the shortest chains.
      // For example a->b->a, rather than c->a->b->a.
      // Since we visit every node, we know the shortest chains are those
      // that start and end on the loop.
      if (result.first == result.last)
        return result;
    }
  }
  return null;
}

void _printProgress(String action, String workingDir, String command) {
  const String arrow = '⏩';
  print('$arrow $action: cd $cyan$workingDir$reset; $yellow$command$reset');
}
