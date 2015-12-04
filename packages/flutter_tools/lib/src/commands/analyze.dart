// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../base/logging.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../runner/flutter_command.dart';

class AnalyzeCommand extends FlutterCommand {
  String get name => 'analyze';
  String get description => 'Runs a carefully configured dartanalyzer over the current project\'s dart code.';

  AnalyzeCommand() {
    argParser.addFlag('flutter-repo', help: 'Include all the examples and tests from the Flutter repository.', defaultsTo: false);
    argParser.addFlag('current-directory', help: 'Include all the Dart files in the current directory, if any.', defaultsTo: true);
    argParser.addFlag('current-package', help: 'Include the lib/main.dart file from the current directory, if any.', defaultsTo: true);
    argParser.addFlag('congratulate', help: 'Show output even when there are no errors, warnings, hints, or lints.', defaultsTo: true);
  }

  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    Set<String> pubSpecDirectories = new Set<String>();
    List<String> dartFiles = argResults.rest.toList();

    for (String file in dartFiles) {
      // TODO(ianh): figure out how dartanalyzer decides which .packages file to use when given a random file
      pubSpecDirectories.add(path.dirname(file));
    }

    if (argResults['flutter-repo']) {
      // .../examples/*/*.dart
      // .../examples/*/lib/main.dart
      Directory examples = new Directory(path.join(ArtifactStore.flutterRoot, 'examples'));
      for (FileSystemEntity entry in examples.listSync()) {
        if (entry is Directory) {
          bool foundOne = false;
          for (FileSystemEntity subentry in entry.listSync()) {
            if (subentry is File && subentry.path.endsWith('.dart')) {
              dartFiles.add(subentry.path);
              foundOne = true;
            } else if (subentry is Directory && path.basename(subentry.path) == 'lib') {
              String mainPath = path.join(subentry.path, 'main.dart');
              if (FileSystemEntity.isFileSync(mainPath)) {
                dartFiles.add(mainPath);
                foundOne = true;
              }
            }
          }
          if (foundOne)
            pubSpecDirectories.add(entry.path);
        }
      }

      bool foundTest = false;
      Directory flutterDir = new Directory(path.join(ArtifactStore.flutterRoot, 'packages/unit')); // See https://github.com/flutter/flutter/issues/50

      // .../packages/unit/test/*/*_test.dart
      Directory tests = new Directory(path.join(flutterDir.path, 'test'));
      for (FileSystemEntity entry in tests.listSync()) {
        if (entry is Directory) {
          for (FileSystemEntity subentry in entry.listSync()) {
            if (subentry is File && subentry.path.endsWith('_test.dart')) {
              dartFiles.add(subentry.path);
              foundTest = true;
            }
          }
        }
      }

      // .../packages/unit/benchmark/*/*_bench.dart
      Directory benchmarks = new Directory(path.join(flutterDir.path, 'benchmark'));
      for (FileSystemEntity entry in benchmarks.listSync()) {
        if (entry is Directory) {
          for (FileSystemEntity subentry in entry.listSync()) {
            if (subentry is File && subentry.path.endsWith('_bench.dart')) {
              dartFiles.add(subentry.path);
              foundTest = true;
            }
          }
        }
      }

      if (foundTest)
        pubSpecDirectories.add(flutterDir.path);

      // .../packages/*/bin/*.dart
      // .../packages/*/lib/main.dart
      Directory packages = new Directory(path.join(ArtifactStore.flutterRoot, 'packages'));
      for (FileSystemEntity entry in packages.listSync()) {
        if (entry is Directory) {
          bool foundOne = false;
          Directory binDirectory = new Directory(path.join(entry.path, 'bin'));
          if (binDirectory.existsSync()) {
            for (FileSystemEntity subentry in binDirectory.listSync()) {
              if (subentry is File && subentry.path.endsWith('.dart')) {
                dartFiles.add(subentry.path);
                foundOne = true;
              }
            }
          }
          String mainPath = path.join(entry.path, 'lib', 'main.dart');
          if (FileSystemEntity.isFileSync(mainPath)) {
            dartFiles.add(mainPath);
            foundOne = true;
          }
          if (foundOne)
            pubSpecDirectories.add(entry.path);
        }
      }
    }

    bool foundAnyInCurrentDirectory = false;

    if (argResults['current-directory']) {
      // ./*.dart
      Directory currentDirectory = new Directory('.');
      bool foundOne = false;
      for (FileSystemEntity entry in currentDirectory.listSync()) {
        if (entry is File && entry.path.endsWith('.dart')) {
          dartFiles.add(entry.path);
          foundOne = true;
        }
      }
      if (foundOne) {
        pubSpecDirectories.add('.');
        foundAnyInCurrentDirectory = true;
      }
    }

    if (argResults['current-package']) {
      // ./lib/main.dart
      String mainPath = 'lib/main.dart';
      if (FileSystemEntity.isFileSync(mainPath)) {
        dartFiles.add(mainPath);
        pubSpecDirectories.add('.');
        foundAnyInCurrentDirectory = true;
      }
    }

    // prepare a Dart file that references all the above Dart files
    StringBuffer mainBody = new StringBuffer();
    for (int index = 0; index < dartFiles.length; index += 1)
      mainBody.writeln('import \'${path.normalize(path.absolute(dartFiles[index]))}\' as file$index;');
    mainBody.writeln('void main() { }');

    // prepare a union of all the .packages files
    Map<String, String> packages = <String, String>{};
    bool hadInconsistentRequirements = false;
    for (Directory directory in pubSpecDirectories.map((path) => new Directory(path))) {
      File dotPackages = new File(path.join(directory.path, '.packages'));
      if (dotPackages.existsSync()) {
        Map<String, String> dependencies = <String, String>{};
        dotPackages
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.startsWith(new RegExp(r'^ *#')))
          .forEach((line) {
            int colon = line.indexOf(':');
            if (colon > 0)
              dependencies[line.substring(0, colon)] = path.normalize(path.absolute(directory.path, path.fromUri(line.substring(colon+1))));
          });
        for (String package in dependencies.keys) {
          if (packages.containsKey(package)) {
            if (packages[package] != dependencies[package]) {
              logging.warning('Inconsistent requirements for $package; using ${packages[package]} (and not ${dependencies[package]}).');
              hadInconsistentRequirements = true;
            }
          } else {
            packages[package] = dependencies[package];
          }
        }
      }
    }
    if (hadInconsistentRequirements) {
      if (argResults['flutter-repo'])
        logging.warning('You may need to run "dart ${path.normalize(path.relative(path.join(ArtifactStore.flutterRoot, 'dev/update_packages.dart')))} --upgrade".');
      if (foundAnyInCurrentDirectory)
        logging.warning('You may need to run "pub upgrade".');
    }

    String buildDir = buildConfigurations.firstWhere((BuildConfiguration config) => config.testable, orElse: () => null)?.buildDir;
    if (buildDir != null) {
      packages['sky_engine'] = path.join(buildDir, 'gen/dart-pkg/sky_engine/lib');
      packages['sky_services'] = path.join(buildDir, 'gen/dart-pkg/sky_services/lib');
    }

    StringBuffer packagesBody = new StringBuffer();
    for (String package in packages.keys)
      packagesBody.writeln('$package:${path.toUri(packages[package])}');

    // save the Dart file and the .packages file to disk
    Directory host = Directory.systemTemp.createTempSync('flutter-analyze-');
    File mainFile = new File(path.join(host.path, 'main.dart'))..writeAsStringSync(mainBody.toString());
    File packagesFile = new File(path.join(host.path, '.packages'))..writeAsStringSync(packagesBody.toString());

    List<String> cmd = <String>[
      sdkBinaryName('dartanalyzer'),
      // do not set '--warnings', since that will include the entire Dart SDK
      '--ignore-unrecognized-flags',
      '--supermixin',
      '--enable-strict-call-checks',
      '--enable_type_checks',
      '--strong',
      '--package-warnings',
      '--fatal-warnings',
      '--strong-hints',
      '--fatal-hints',
      '--lints',
      '--packages', packagesFile.path,
      mainFile.path
    ];

    logging.info(cmd.join(' '));
    Process process = await Process.start(
      cmd[0],
      cmd.sublist(1),
      workingDirectory: host.path
    );
    int errorCount = 0;
    StringBuffer output = new StringBuffer();
    process.stdout.transform(UTF8.decoder).listen((String data) {
      output.write(data);
    });
    process.stderr.transform(UTF8.decoder).listen((String data) {
      // dartanalyzer doesn't seem to ever output anything on stderr
      errorCount += 1;
      print(data);
    });

    int exitCode = await process.exitCode;

    host.deleteSync(recursive: true);

    List<Pattern> patternsToSkip = <Pattern>[
      'Analyzing [${mainFile.path}]...',
      new RegExp('^\\[hint\\] Unused import \\(${mainFile.path},'),
      new RegExp(r'^\[.+\] .+ \(.+/\.pub-cache/.+'),
      new RegExp(r'^\[error\] Invalid override\. The type of [^ ]+ \(.+\) is not a subtype of [^ ]+ \(.+\)\.'), // we allow type narrowing
      new RegExp(r'^\[warning\] .+ will need runtime check to cast to type .+'), // https://github.com/dart-lang/sdk/issues/24542
      new RegExp(r'^\[error\] Type check failed: .*\(dynamic\) is not of type'), // allow unchecked casts from dynamic
      new RegExp('^\\[error\\] Target of URI does not exist: \'dart:ui_internals\''), // https://github.com/flutter/flutter/issues/83
      new RegExp(r'\[lint\] Prefer using lowerCamelCase for constant names.'), // sometimes we have no choice (e.g. when matching other platforms)
      new RegExp(r'\[lint\] Avoid defining a one-member abstract class when a simple function will do.'), // too many false-positives; code review should catch real instances
      new RegExp(r'[0-9]+ (error|warning|hint|lint).+found\.'),
      new RegExp(r'^$'),
    ];

    RegExp generalPattern = new RegExp(r'^\[(error|warning|hint|lint)\] (.+) \(([^(),]+), line ([0-9]+), col ([0-9]+)\)$');
    RegExp allowedIdentifiersPattern = new RegExp(r'_?([A-Z]|_+)\b');
    RegExp constructorTearOffsPattern = new RegExp('.+#.+// analyzer doesn\'t like constructor tear-offs');
    RegExp ignorePattern = new RegExp(r'// analyzer says "([^"]+)"');

    List<String> errorLines = output.toString().split('\n');
    for (String errorLine in errorLines) {
      if (patternsToSkip.every((Pattern pattern) => pattern.allMatches(errorLine).isEmpty)) {
        Match groups = generalPattern.firstMatch(errorLine);
        if (groups != null) {
          String level = groups[1];
          String filename = groups[3];
          String errorMessage = groups[2];
          int lineNumber = int.parse(groups[4]);
          int colNumber = int.parse(groups[5]);
          File source = new File(filename);
          List<String> sourceLines = source.readAsLinesSync();
          String sourceLine = (lineNumber < sourceLines.length) ? sourceLines[lineNumber-1] : '';
          bool shouldIgnore = false;
          if (filename.endsWith('.mojom.dart')) {
            // autogenerated code - TODO(ianh): Fix the Dart mojom compiler
            shouldIgnore = true;
          } else if ((sourceLines[0] == '/**') && (' * DO NOT EDIT. This is code generated'.matchAsPrefix(sourceLines[1]) != null)) {
            // autogenerated code - TODO(ianh): Fix the intl package resource generator
            shouldIgnore = true;
          } else if (level == 'lint' && errorMessage == 'Name non-constant identifiers using lowerCamelCase.') {
            if (allowedIdentifiersPattern.matchAsPrefix(sourceLine, colNumber-1) != null)
              shouldIgnore = true;
          } else if (constructorTearOffsPattern.allMatches(sourceLine).isNotEmpty) {
            shouldIgnore = true;
          } else {
            Iterable<Match> ignoreGroups = ignorePattern.allMatches(sourceLine);
            for (Match ignoreGroup in ignoreGroups) {
              if (errorMessage.contains(ignoreGroup[1])) {
                shouldIgnore = true;
                break;
              }
            }
          }
          if (shouldIgnore)
            continue;
        }
        print(errorLine);
        errorCount += 1;
      }
    }

    if (exitCode < 0 || exitCode > 3) // 0 = nothing, 1 = hints, 2 = warnings, 3 = errors
      return exitCode;

    if (errorCount > 0)
      return 1;
    if (argResults['congratulate'])
      print('No analyzer warnings!');
    return 0;
  }
}
