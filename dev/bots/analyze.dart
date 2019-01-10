// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';

import 'run_command.dart';

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
final String pub = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
final String pubCache = path.join(flutterRoot, '.pub-cache');

/// When you call this, you can pass additional arguments to pass custom
/// arguments to flutter analyze. For example, you might want to call this
/// script with the parameter --dart-sdk to use custom dart sdk.
///
/// For example:
/// bin/cache/dart-sdk/bin/dart dev/bots/analyze.dart --dart-sdk=/tmp/dart-sdk
Future<void> main(List<String> args) async {
  await _verifyNoTestPackageImports(flutterRoot);
  await _verifyGeneratedPluginRegistrants(flutterRoot);
  await _verifyNoBadImportsInFlutter(flutterRoot);
  await _verifyNoBadImportsInFlutterTools(flutterRoot);
  await _verifyInternationalizations();

  {
    // Analyze all the Dart code in the repo.
    final List<String> options = <String>['--flutter-repo'];
    options.addAll(args);
    await _runFlutterAnalyze(flutterRoot, options: options);
  }

  // Ensure that all package dependencies are in sync.
  await runCommand(flutter, <String>['update-packages', '--verify-only'],
    workingDirectory: flutterRoot,
  );

  // Analyze all the sample code in the repo
  await runCommand(dart,
    <String>[path.join(flutterRoot, 'dev', 'bots', 'analyze-sample-code.dart')],
    workingDirectory: flutterRoot,
  );

  // Try with the --watch analyzer, to make sure it returns success also.
  // The --benchmark argument exits after one run.
  {
    final List<String> options = <String>['--flutter-repo', '--watch', '--benchmark'];
    options.addAll(args);
    await _runFlutterAnalyze(flutterRoot, options: options);
  }

  await _checkForTrailingSpaces();

  // Try analysis against a big version of the gallery; generate into a temporary directory.
  final Directory outDir = Directory.systemTemp.createTempSync('flutter_mega_gallery.');

  try {
    await runCommand(dart,
      <String>[
        path.join(flutterRoot, 'dev', 'tools', 'mega_gallery.dart'),
        '--out',
        outDir.path,
      ],
      workingDirectory: flutterRoot,
    );
    {
      final List<String> options = <String>['--watch', '--benchmark'];
      options.addAll(args);
      await _runFlutterAnalyze(outDir.path, options: options);
    }
  } finally {
    outDir.deleteSync(recursive: true);
  }

  print('${bold}DONE: Analysis successful.$reset');
}

Future<void> _verifyInternationalizations() async {
  final EvalResult genResult = await _evalCommand(
    dart,
    <String>[
      path.join('dev', 'tools', 'gen_localizations.dart'),
    ],
    workingDirectory: flutterRoot,
  );

  final String localizationsFile = path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n', 'localizations.dart');
  final String expectedResult = await File(localizationsFile).readAsString();

  if (genResult.stdout.trim() != expectedResult.trim()) {
    stderr
      ..writeln('<<<<<<< $localizationsFile')
      ..writeln(expectedResult.trim())
      ..writeln('=======')
      ..writeln(genResult.stdout.trim())
      ..writeln('>>>>>>> gen_localizations')
      ..writeln('The contents of $localizationsFile are different from that produced by gen_localizations.')
      ..writeln()
      ..writeln('Did you forget to run gen_localizations.dart after updating a .arb file?');
    exit(1);
  }
  print('Contents of $localizationsFile matches output of gen_localizations.dart script.');
}

Future<String> _getCommitRange() async {
  // Using --fork-point is more conservative, and will result in the correct
  // fork point, but when running locally, it may return nothing. Git is
  // guaranteed to return a (reasonable, but maybe not optimal) result when not
  // using --fork-point, so we fall back to that if we can't get a definitive
  // fork point. See "git merge-base" documentation for more info.
  EvalResult result = await _evalCommand(
    'git',
    <String>['merge-base', '--fork-point', 'FETCH_HEAD', 'HEAD'],
    workingDirectory: flutterRoot,
    allowNonZeroExit: true,
  );
  if (result.exitCode != 0) {
    result = await _evalCommand(
      'git',
      <String>['merge-base', 'FETCH_HEAD', 'HEAD'],
      workingDirectory: flutterRoot,
    );
  }
  return result.stdout.trim();
}


Future<void> _checkForTrailingSpaces() async {
  if (!Platform.isWindows) {
    final String commitRange = Platform.environment.containsKey('TEST_COMMIT_RANGE')
        ? Platform.environment['TEST_COMMIT_RANGE']
        : await _getCommitRange();
    final List<String> fileTypes = <String>[
      '*.dart', '*.cxx', '*.cpp', '*.cc', '*.c', '*.C', '*.h', '*.java', '*.mm', '*.m', '*.yml',
    ];
    final EvalResult changedFilesResult = await _evalCommand(
      'git', <String>['diff', '-U0', '--no-color', '--name-only', commitRange, '--'] + fileTypes,
      workingDirectory: flutterRoot,
    );
    if (changedFilesResult.stdout == null || changedFilesResult.stdout.trim().isEmpty) {
      print('No files found that need to be checked for trailing whitespace.');
      return;
    }
    // Only include files that actually exist, so that we don't try and grep for
    // nonexistent files, which can occur when files are deleted or moved.
    final List<String> changedFiles = changedFilesResult.stdout.split('\n').where((String filename) {
      return File(filename).existsSync();
    }).toList();
    if (changedFiles.isNotEmpty) {
      await runCommand('grep',
        <String>[
          '--line-number',
          '--extended-regexp',
          r'[[:blank:]]$',
        ] + changedFiles,
        workingDirectory: flutterRoot,
        failureMessage: '${red}Whitespace detected at the end of source code lines.$reset\nPlease remove:',
        expectNonZeroExit: true, // Just means a non-zero exit code is expected.
        expectedExitCode: 1, // Indicates that zero lines were found.
      );
    }
  }
}

class EvalResult {
  EvalResult({
    this.stdout,
    this.stderr,
    this.exitCode = 0,
  });

  final String stdout;
  final String stderr;
  final int exitCode;
}

Future<EvalResult> _evalCommand(String executable, List<String> arguments, {
  @required String workingDirectory,
  Map<String, String> environment,
  bool skip = false,
  bool allowNonZeroExit = false,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);
  if (skip) {
    printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return null;
  }
  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final DateTime start = DateTime.now();
  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  final Future<List<List<int>>> savedStdout = process.stdout.toList();
  final Future<List<List<int>>> savedStderr = process.stderr.toList();
  final int exitCode = await process.exitCode;
  final EvalResult result = EvalResult(
    stdout: utf8.decode((await savedStdout).expand<int>((List<int> ints) => ints).toList()),
    stderr: utf8.decode((await savedStderr).expand<int>((List<int> ints) => ints).toList()),
    exitCode: exitCode,
  );

  print('$clock ELAPSED TIME: $bold${elapsedTime(start)}$reset for $commandDescription in $relativeWorkingDir: ');

  if (exitCode != 0 && !allowNonZeroExit) {
    stderr.write(result.stderr);
    print(
      '$redLine\n'
      '${bold}ERROR:$red Last command exited with $exitCode.$reset\n'
      '${bold}Command:$red $commandDescription$reset\n'
      '${bold}Relative working directory:$red $relativeWorkingDir$reset\n'
      '$redLine'
    );
    exit(1);
  }

  return result;
}

Future<void> _runFlutterAnalyze(String workingDirectory, {
  List<String> options = const <String>[]
}) {
  return runCommand(flutter, <String>['analyze', '--dartdocs']..addAll(options),
    workingDirectory: workingDirectory,
  );
}

Future<void> _verifyNoTestPackageImports(String workingDirectory) async {
  // TODO(ianh): Remove this whole test once https://github.com/dart-lang/matcher/issues/98 is fixed.
  final List<String> shims = <String>[];
  final List<String> errors = Directory(workingDirectory)
    .listSync(recursive: true)
    .where((FileSystemEntity entity) {
      return entity is File && entity.path.endsWith('.dart');
    })
    .map<String>((FileSystemEntity entity) {
      final File file = entity;
      final String name = Uri.file(path.relative(file.path,
          from: workingDirectory)).toFilePath(windows: false);
      if (name.startsWith('bin/cache') ||
          name == 'dev/bots/test.dart' ||
          name.startsWith('.pub-cache'))
        return null;
      final String data = file.readAsStringSync();
      if (data.contains("import 'package:test/test.dart'")) {
        if (data.contains("// Defines a 'package:test' shim.")) {
          shims.add('  $name');
          if (!data.contains('https://github.com/dart-lang/matcher/issues/98'))
            return '  $name: Shims must link to the isInstanceOf issue.';
          if (data.contains("import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;") &&
              data.contains("export 'package:test/test.dart' hide TypeMatcher, isInstanceOf;"))
            return null;
          return '  $name: Shim seems to be missing the expected import/export lines.';
        }
        final int count = 'package:test'.allMatches(data).length;
        if (path.split(file.path).contains('test_driver') ||
            name.startsWith('dev/missing_dependency_tests/') ||
            name.startsWith('dev/automated_tests/') ||
            name.startsWith('dev/snippets/') ||
            name.startsWith('packages/flutter/test/engine/') ||
            name.startsWith('examples/layers/test/smoketests/raw/') ||
            name.startsWith('examples/layers/test/smoketests/rendering/') ||
            name.startsWith('examples/flutter_gallery/test/calculator')) {
          // We only exempt driver tests, some of our special trivial tests.
          // Driver tests aren't typically expected to use TypeMatcher and company.
          // The trivial tests don't typically do anything at all and it would be
          // a pain to have to give them a shim.
          if (!data.contains("import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;"))
            return '  $name: test does not hide TypeMatcher and isInstanceOf from package:test; consider using a shim instead.';
          assert(count > 0);
          if (count == 1)
            return null;
          return '  $name: uses \'package:test\' $count times.';
        }
        if (name.startsWith('packages/flutter_test/')) {
          // flutter_test has deep ties to package:test
          return null;
        }
        if (data.contains("import 'package:test/test.dart' as test_package;") ||
            data.contains("import 'package:test/test.dart' as test_package show ")) {
          if (count == 1)
            return null;
        }
        return '  $name: uses \'package:test\' directly';
      }
      return null;
    })
    .where((String line) => line != null)
    .toList()
    ..sort();

  // Fail if any errors
  if (errors.isNotEmpty) {
    print('$redLine');
    final String s1 = errors.length == 1 ? 's' : '';
    final String s2 = errors.length == 1 ? '' : 's';
    print('${bold}The following file$s2 use$s1 \'package:test\' incorrectly:$reset');
    print(errors.join('\n'));
    print('Rather than depending on \'package:test\' directly, use one of the shims:');
    print(shims.join('\n'));
    print('This insulates us from breaking changes in \'package:test\'.');
    print('$redLine\n');
    exit(1);
  }
}

Future<void> _verifyNoBadImportsInFlutter(String workingDirectory) async {
  final List<String> errors = <String>[];
  final String libPath = path.join(workingDirectory, 'packages', 'flutter', 'lib');
  final String srcPath = path.join(workingDirectory, 'packages', 'flutter', 'lib', 'src');
  // Verify there's one libPath/*.dart for each srcPath/*/.
  final List<String> packages = Directory(libPath).listSync()
    .where((FileSystemEntity entity) => entity is File && path.extension(entity.path) == '.dart')
    .map<String>((FileSystemEntity entity) => path.basenameWithoutExtension(entity.path))
    .toList()..sort();
  final List<String> directories = Directory(srcPath).listSync()
    .whereType<Directory>()
    .map<String>((Directory entity) => path.basename(entity.path))
    .toList()..sort();
  if (!_matches<String>(packages, directories)) {
    errors.add(
      'flutter/lib/*.dart does not match flutter/lib/src/*/:\n'
      'These are the exported packages:\n' +
      packages.map<String>((String path) => '  lib/$path.dart').join('\n') +
      'These are the directories:\n' +
      directories.map<String>((String path) => '  lib/src/$path/').join('\n')
    );
  }
  // Verify that the imports are well-ordered.
  final Map<String, Set<String>> dependencyMap = <String, Set<String>>{};
  for (String directory in directories) {
    dependencyMap[directory] = _findDependencies(path.join(srcPath, directory), errors, checkForMeta: directory != 'foundation');
  }
  for (String package in dependencyMap.keys) {
    if (dependencyMap[package].contains(package)) {
      errors.add(
        'One of the files in the $yellow$package$reset package imports that package recursively.'
      );
    }
  }
  for (String package in dependencyMap.keys) {
    final List<String> loop = _deepSearch<String>(dependencyMap, package);
    if (loop != null) {
      errors.add(
        '${yellow}Dependency loop:$reset ' +
        loop.join(' depends on ')
      );
    }
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    print('$redLine');
    if (errors.length == 1) {
      print('${bold}An error was detected when looking at import dependencies within the Flutter package:$reset\n');
    } else {
      print('${bold}Multiple errors were detected when looking at import dependencies within the Flutter package:$reset\n');
    }
    print(errors.join('\n\n'));
    print('$redLine\n');
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

final RegExp _importPattern = RegExp(r"import 'package:flutter/([^.]+)\.dart'");
final RegExp _importMetaPattern = RegExp(r"import 'package:meta/meta.dart'");

Set<String> _findDependencies(String srcPath, List<String> errors, { bool checkForMeta = false }) {
  return Directory(srcPath).listSync(recursive: true).where((FileSystemEntity entity) {
    return entity is File && path.extension(entity.path) == '.dart';
  }).map<Set<String>>((FileSystemEntity entity) {
    final Set<String> result = Set<String>();
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
    value ??= Set<String>();
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
    final List<T> result = _deepSearch<T>(
      map,
      key,
      (seen == null ? Set<T>.from(<T>[start]) : Set<T>.from(seen))..add(key),
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

Future<void> _verifyNoBadImportsInFlutterTools(String workingDirectory) async {
  final List<String> errors = <String>[];
  for (FileSystemEntity entity in Directory(path.join(workingDirectory, 'packages', 'flutter_tools', 'lib'))
    .listSync(recursive: true)
    .where((FileSystemEntity entity) => entity is File && path.extension(entity.path) == '.dart')) {
    final File file = entity;
    if (file.readAsStringSync().contains('package:flutter_tools/')) {
      errors.add('$yellow${file.path}$reset imports flutter_tools.');
    }
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    print('$redLine');
    if (errors.length == 1) {
      print('${bold}An error was detected when looking at import dependencies within the flutter_tools package:$reset\n');
    } else {
      print('${bold}Multiple errors were detected when looking at import dependencies within the flutter_tools package:$reset\n');
    }
    print(errors.join('\n\n'));
    print('$redLine\n');
    exit(1);
  }
}

Future<void> _verifyGeneratedPluginRegistrants(String flutterRoot) async {
  final Directory flutterRootDir = Directory(flutterRoot);

  final Map<String, List<File>> packageToRegistrants = <String, List<File>>{};

  for (FileSystemEntity entity in flutterRootDir.listSync(recursive: true)) {
    if (entity is! File)
      continue;
    if (_isGeneratedPluginRegistrant(entity)) {
      final String package = _getPackageFor(entity, flutterRootDir);
      final List<File> registrants = packageToRegistrants.putIfAbsent(package, () => <File>[]);
      registrants.add(entity);
    }
  }

  final Set<String> outOfDate = Set<String>();

  for (String package in packageToRegistrants.keys) {
    final Map<File, String> fileToContent = <File, String>{};
    for (File f in packageToRegistrants[package]) {
      fileToContent[f] = f.readAsStringSync();
    }
    await runCommand(flutter, <String>['inject-plugins'],
      workingDirectory: package,
      printOutput: false,
    );
    for (File registrant in fileToContent.keys) {
      if (registrant.readAsStringSync() != fileToContent[registrant]) {
        outOfDate.add(registrant.path);
      }
    }
  }

  if (outOfDate.isNotEmpty) {
    print('$redLine');
    print('${bold}The following GeneratedPluginRegistrants are out of date:$reset');
    for (String registrant in outOfDate) {
      print(' - $registrant');
    }
    print('\nRun "flutter inject-plugins" in the package that\'s out of date.');
    print('$redLine');
    exit(1);
  }
}

String _getPackageFor(File entity, Directory flutterRootDir) {
  for (Directory dir = entity.parent; dir != flutterRootDir; dir = dir.parent) {
    if (File(path.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir.path;
    }
  }
  throw ArgumentError('$entity is not within a dart package.');
}

bool _isGeneratedPluginRegistrant(File file) {
  final String filename = path.basename(file.path);
  return !file.path.contains('.pub-cache')
      && (filename == 'GeneratedPluginRegistrant.java' ||
          filename == 'GeneratedPluginRegistrant.h' ||
          filename == 'GeneratedPluginRegistrant.m');
}
