// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core' as core_internals show print;
import 'dart:core' hide print;
import 'dart:io' as io_internals show exit;
import 'dart:io' hide exit;

import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';

import 'run_command.dart';

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
final String pub = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
final String pubCache = path.join(flutterRoot, '.pub-cache');

class ExitException implements Exception {
  ExitException(this.exitCode);

  final int exitCode;

  void apply() {
    io_internals.exit(exitCode);
  }
}

// We actually reimplement exit() so that it uses exceptions rather
// than truly immediately terminating the application, so that we can
// test the exit code in unit tests (see test/analyze_test.dart).
void exit(int exitCode) {
  throw ExitException(exitCode);
}

typedef PrintCallback = void Function(Object line);

// Allow print() to be overridden, for tests.
PrintCallback print = core_internals.print;

/// When you call this, you can pass additional arguments to pass custom
/// arguments to flutter analyze. For example, you might want to call this
/// script with the parameter --dart-sdk to use custom dart sdk.
///
/// For example:
/// bin/cache/dart-sdk/bin/dart dev/bots/analyze.dart --dart-sdk=/tmp/dart-sdk
Future<void> main(List<String> arguments) async {
  print('$clock STARTING ANALYSIS');
  try {
    await run(arguments);
  } on ExitException catch (error) {
    error.apply();
  }
  print('${bold}DONE: Analysis successful.$reset');
}

Future<void> run(List<String> arguments) async {
  bool assertsEnabled = false;
  assert(() { assertsEnabled = true; return true; }());
  if (!assertsEnabled) {
    print('The analyze.dart script must be run with --enable-asserts.');
    exit(1);
  }

  print('$clock Deprecations...');
  await verifyDeprecations(flutterRoot);

  print('$clock Licenses...');
  await verifyNoMissingLicense(flutterRoot);

  print('$clock Test imports...');
  await verifyNoTestImports(flutterRoot);

  print('$clock Test package imports...');
  await verifyNoTestPackageImports(flutterRoot);

  print('$clock Generated plugin registrants...');
  await verifyGeneratedPluginRegistrants(flutterRoot);

  print('$clock Bad imports (framework)...');
  await verifyNoBadImportsInFlutter(flutterRoot);

  print('$clock Bad imports (tools)...');
  await verifyNoBadImportsInFlutterTools(flutterRoot);

  print('$clock Internationalization...');
  await verifyInternationalizations();

  print('$clock Trailing spaces...');
  await verifyNoTrailingSpaces();

  // Ensure that all package dependencies are in sync.
  print('$clock Package dependencies...');
  await runCommand(flutter, <String>['update-packages', '--verify-only'],
    workingDirectory: flutterRoot,
  );

  // Analyze all the sample code in the repo
  print('$clock Sample code...');
  await runCommand(dart,
    <String>[path.join(flutterRoot, 'dev', 'bots', 'analyze-sample-code.dart')],
    workingDirectory: flutterRoot,
  );

  // Analyze all the Dart code in the repo.
  print('$clock Dart analysis...');
  await _runFlutterAnalyze(flutterRoot, options: <String>[
    '--flutter-repo',
    ...arguments,
  ]);

  // Try with the --watch analyzer, to make sure it returns success also.
  // The --benchmark argument exits after one run.
  print('$clock Dart analysis (with --watch)...');
  await _runFlutterAnalyze(flutterRoot, options: <String>[
    '--flutter-repo',
    '--watch',
    '--benchmark',
    ...arguments,
  ]);

  // Try analysis against a big version of the gallery; generate into a temporary directory.
  print('$clock Dart analysis (mega gallery)...');
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
    await _runFlutterAnalyze(outDir.path, options: <String>[
      '--watch',
      '--benchmark',
      ...arguments,
    ]);
  } finally {
    outDir.deleteSync(recursive: true);
  }
}


// TESTS

final RegExp _findDeprecationPattern = RegExp(r'@[Dd]eprecated');
final RegExp _deprecationPattern1 = RegExp(r'^( *)@Deprecated\($'); // ignore: flutter_deprecation_syntax (see analyze.dart)
final RegExp _deprecationPattern2 = RegExp(r"^ *'(.+) '$");
final RegExp _deprecationPattern3 = RegExp(r"^ *'This feature was deprecated after v([0-9]+)\.([0-9]+)\.([0-9]+)\.'$");
final RegExp _deprecationPattern4 = RegExp(r'^ *\)$');

/// Some deprecation notices are special, for example they're used to annotate members that
/// will never go away and were never allowed but which we are trying to show messages for.
/// (One example would be a library that intentionally conflicts with a member in another
/// library to indicate that it is incompatible with that other library. Another would be
/// the regexp just above...)
const String _ignoreDeprecation = ' // ignore: flutter_deprecation_syntax (see analyze.dart)';

/// Some deprecation notices are grand-fathered in for now. They must have an issue listed.
final RegExp _grandfatheredDeprecation = RegExp(r' // ignore: flutter_deprecation_syntax, https://github.com/flutter/flutter/issues/[0-9]+$');

Future<void> verifyDeprecations(String workingDirectory) async {
  final List<String> errors = <String>[];
  for (File file in _allFiles(workingDirectory, 'dart')) {
    int lineNumber = 0;
    final List<String> lines = file.readAsLinesSync();
    final List<int> linesWithDeprecations = <int>[];
    for (String line in lines) {
      if (line.contains(_findDeprecationPattern) &&
          !line.endsWith(_ignoreDeprecation) &&
          !line.contains(_grandfatheredDeprecation)) {
        linesWithDeprecations.add(lineNumber);
      }
      lineNumber += 1;
    }
    for (int lineNumber in linesWithDeprecations) {
      try {
        final Match match1 = _deprecationPattern1.firstMatch(lines[lineNumber]);
        if (match1 == null)
          throw 'Deprecation notice does not match required pattern.';
        final String indent = match1[1];
        lineNumber += 1;
        if (lineNumber >= lines.length)
          throw 'Incomplete deprecation notice.';
        Match match3;
        String message;
        do {
          final Match match2 = _deprecationPattern2.firstMatch(lines[lineNumber]);
          if (match2 == null)
            throw 'Deprecation notice does not match required pattern.';
          if (!lines[lineNumber].startsWith("$indent  '"))
            throw 'Unexpected deprecation notice indent.';
          if (message == null) {
            final String firstChar = String.fromCharCode(match2[1].runes.first);
            if (firstChar.toUpperCase() != firstChar)
              throw 'Deprecation notice should be a grammatically correct sentence and start with a capital letter; see style guide.';
          }
          message = match2[1];
          lineNumber += 1;
          if (lineNumber >= lines.length)
            throw 'Incomplete deprecation notice.';
          match3 = _deprecationPattern3.firstMatch(lines[lineNumber]);
        } while (match3 == null);
        if (!message.endsWith('.') && !message.endsWith('!') && !message.endsWith('?'))
          throw 'Deprecation notice should be a grammatically correct sentence and end with a period.';
        if (!lines[lineNumber].startsWith("$indent  '"))
          throw 'Unexpected deprecation notice indent.';
        lineNumber += 1;
        if (lineNumber >= lines.length)
          throw 'Incomplete deprecation notice.';
        if (!lines[lineNumber].contains(_deprecationPattern4))
          throw 'End of deprecation notice does not match required pattern.';
        if (!lines[lineNumber].startsWith('$indent)'))
          throw 'Unexpected deprecation notice indent.';
      } catch (error) {
        errors.add('${file.path}:${lineNumber + 1}: $error');
      }
    }
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    print('$redLine');
    print(errors.join('\n'));
    print('${bold}See: https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes$reset\n');
    print('$redLine\n');
    exit(1);
  }
}

String _generateLicense(String prefix) {
  assert(prefix != null);
  return '${prefix}Copyright 2014 The Flutter Authors. All rights reserved.\n'
         '${prefix}Use of this source code is governed by a BSD-style license that can be\n'
         '${prefix}found in the LICENSE file.';
}

Future<void> verifyNoMissingLicense(String workingDirectory) async {
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'dart', _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'java', _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'h', _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'm', _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'swift', _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'gradle', _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'gn', _generateLicense('# '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'sh', '#!/usr/bin/env bash\n' + _generateLicense('# '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'bat', '@ECHO off\n' + _generateLicense('REM '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'ps1', _generateLicense('# '));
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'html', '<!DOCTYPE HTML>\n<!-- ${_generateLicense('')} -->', trailingBlank: false);
  await _verifyNoMissingLicenseForExtension(workingDirectory, 'xml', '<!-- ${_generateLicense('')} -->');
}

Future<void> _verifyNoMissingLicenseForExtension(String workingDirectory, String extension, String license, { bool trailingBlank = true }) async {
  assert(!license.endsWith('\n'));
  final String licensePattern = license + '\n' + (trailingBlank ? '\n' : '');
  final List<String> errors = <String>[];
  for (File file in _allFiles(workingDirectory, extension)) {
    final String contents = file.readAsStringSync().replaceAll('\r\n', '\n');
    if (contents.isEmpty)
      continue; // let's not go down the /bin/true rabbit hole
    if (!contents.startsWith(licensePattern))
      errors.add(file.path);
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    print('$redLine');
    final String s = errors.length == 1 ? ' does' : 's do';
    print('${bold}The following ${errors.length} file$s not have the right license header:$reset\n');
    print(errors.join('\n'));
    print('$redLine\n');
    print('The expected license header is:');
    print('$license');
    if (trailingBlank)
      print('...followed by a blank line.');
    exit(1);
  }
}

final RegExp _testImportPattern = RegExp(r'''import (['"])([^'"]+_test\.dart)\1''');
const Set<String> _exemptTestImports = <String>{
  'package:flutter_test/flutter_test.dart',
  'hit_test.dart',
  'package:test_api/src/backend/live_test.dart',
};

Future<void> verifyNoTestImports(String workingDirectory) async {
  final List<String> errors = <String>[];
  assert("// foo\nimport 'binding_test.dart' as binding;\n'".contains(_testImportPattern));
  for (FileSystemEntity entity in Directory(path.join(workingDirectory, 'packages'))
    .listSync(recursive: true)
    .where((FileSystemEntity entity) => entity is File && path.extension(entity.path) == '.dart')) {
    final File file = entity;
    for (String line in file.readAsLinesSync()) {
      final Match match = _testImportPattern.firstMatch(line);
      if (match != null && !_exemptTestImports.contains(match.group(2)))
        errors.add(file.path);
    }
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    print('$redLine');
    final String s = errors.length == 1 ? '' : 's';
    print('${bold}The following file$s import a test directly. Test utilities should be in their own file.$reset\n');
    print(errors.join('\n'));
    print('$redLine\n');
    exit(1);
  }
}

Future<void> verifyNoTestPackageImports(String workingDirectory) async {
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

Future<void> verifyGeneratedPluginRegistrants(String flutterRoot) async {
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

  final Set<String> outOfDate = <String>{};

  for (String package in packageToRegistrants.keys) {
    final Map<File, String> fileToContent = <File, String>{};
    for (File f in packageToRegistrants[package]) {
      fileToContent[f] = f.readAsStringSync();
    }
    await runCommand(flutter, <String>['inject-plugins'],
      workingDirectory: package,
      outputMode: OutputMode.discard,
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

Future<void> verifyNoBadImportsInFlutter(String workingDirectory) async {
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
  if (!_listEquals<String>(packages, directories)) {
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
    dependencyMap[directory] = _findFlutterDependencies(path.join(srcPath, directory), errors, checkForMeta: directory != 'foundation');
  }
  assert(dependencyMap['material'].contains('widgets') &&
         dependencyMap['widgets'].contains('rendering') &&
         dependencyMap['rendering'].contains('painting')); // to make sure we're convinced _findFlutterDependencies is finding some
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

Future<void> verifyNoBadImportsInFlutterTools(String workingDirectory) async {
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

Future<void> verifyInternationalizations() async {
  final EvalResult materialGenResult = await _evalCommand(
    dart,
    <String>[
      path.join('dev', 'tools', 'localization', 'gen_localizations.dart'),
      '--material',
    ],
    workingDirectory: flutterRoot,
  );
  final EvalResult cupertinoGenResult = await _evalCommand(
    dart,
    <String>[
      path.join('dev', 'tools', 'localization', 'gen_localizations.dart'),
      '--cupertino',
    ],
    workingDirectory: flutterRoot,
  );

  final String materialLocalizationsFile = path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n', 'generated_material_localizations.dart');
  final String cupertinoLocalizationsFile = path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n', 'generated_cupertino_localizations.dart');
  final String expectedMaterialResult = await File(materialLocalizationsFile).readAsString();
  final String expectedCupertinoResult = await File(cupertinoLocalizationsFile).readAsString();

  if (materialGenResult.stdout.trim() != expectedMaterialResult.trim()) {
    stderr
      ..writeln('<<<<<<< $materialLocalizationsFile')
      ..writeln(expectedMaterialResult.trim())
      ..writeln('=======')
      ..writeln(materialGenResult.stdout.trim())
      ..writeln('>>>>>>> gen_localizations')
      ..writeln('The contents of $materialLocalizationsFile are different from that produced by gen_localizations.')
      ..writeln()
      ..writeln('Did you forget to run gen_localizations.dart after updating a .arb file?');
    exit(1);
  }
  if (cupertinoGenResult.stdout.trim() != expectedCupertinoResult.trim()) {
    stderr
      ..writeln('<<<<<<< $cupertinoLocalizationsFile')
      ..writeln(expectedCupertinoResult.trim())
      ..writeln('=======')
      ..writeln(cupertinoGenResult.stdout.trim())
      ..writeln('>>>>>>> gen_localizations')
      ..writeln('The contents of $cupertinoLocalizationsFile are different from that produced by gen_localizations.')
      ..writeln()
      ..writeln('Did you forget to run gen_localizations.dart after updating a .arb file?');
    exit(1);
  }
}

Future<void> verifyNoTrailingSpaces() async {
  if (!Platform.isWindows) {
    final String commitRange = Platform.environment.containsKey('TEST_COMMIT_RANGE')
        ? Platform.environment['TEST_COMMIT_RANGE']
        : await _getCommitRange();
    final List<String> fileTypes = <String>[
      '*.dart', '*.cxx', '*.cpp', '*.cc', '*.c', '*.C', '*.h', '*.java', '*.mm', '*.m', '*.yml',
    ];
    final EvalResult changedFilesResult = await _evalCommand(
      'git', <String>['diff', '-U0', '--no-color', '--name-only', commitRange, '--', ...fileTypes],
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
          ...changedFiles,
        ],
        workingDirectory: flutterRoot,
        failureMessage: '${red}Detected trailing whitespace in the file[s] listed above.$reset\nPlease remove them from the offending line[s].',
        expectNonZeroExit: true, // Just means a non-zero exit code is expected.
        expectedExitCode: 1, // Indicates that zero lines were found.
      );
    }
  }
}


// UTILITY FUNCTIONS

bool _listEquals<T>(List<T> a, List<T> b) {
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

Iterable<File> _allFiles(String workingDirectory, String extension) sync* {
  final Set<FileSystemEntity> pending = <FileSystemEntity>{ Directory(workingDirectory) };
  while (pending.isNotEmpty) {
    final FileSystemEntity entity = pending.first;
    pending.remove(entity);
    if (path.extension(entity.path) == '.tmpl')
      continue;
    if (entity is File) {
      if (_isGeneratedPluginRegistrant(entity))
        continue;
      if (path.basename(entity.path) == 'flutter_export_environment.sh')
        continue;
      if (path.basename(entity.path) == 'gradlew.bat')
        continue;
      if (path.extension(entity.path) == '.$extension')
        yield entity;
    } else if (entity is Directory) {
      if (File(path.join(entity.path, '.dartignore')).existsSync())
        continue;
      if (path.basename(entity.path) == '.git')
        continue;
      if (path.basename(entity.path) == '.dart_tool')
        continue;
      if (path.basename(entity.path) == 'build')
        continue;
      pending.addAll(entity.listSync());
    }
  }
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

  final Stopwatch time = Stopwatch()..start();
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

  print('$clock ELAPSED TIME: $bold${prettyPrintDuration(time.elapsed)}$reset for $commandDescription in $relativeWorkingDir');

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
  List<String> options = const <String>[],
}) {
  return runCommand(
    flutter,
    <String>['analyze', '--dartdocs', ...options],
    workingDirectory: workingDirectory,
  );
}

final RegExp _importPattern = RegExp(r'''^\s*import (['"])package:flutter/([^.]+)\.dart\1''');
final RegExp _importMetaPattern = RegExp(r'''^\s*import (['"])package:meta/meta\.dart\1''');

Set<String> _findFlutterDependencies(String srcPath, List<String> errors, { bool checkForMeta = false }) {
  return Directory(srcPath).listSync(recursive: true).where((FileSystemEntity entity) {
    return entity is File && path.extension(entity.path) == '.dart';
  }).map<Set<String>>((FileSystemEntity entity) {
    final Set<String> result = <String>{};
    final File file = entity;
    for (String line in file.readAsLinesSync()) {
      Match match = _importPattern.firstMatch(line);
      if (match != null)
        result.add(match.group(2));
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
    value ??= <String>{};
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
      <T>{
        if (seen == null) start else ...seen,
        key,
      },
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
