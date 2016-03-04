// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:den_api/den_api.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

bool isDartFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('.dart');
bool isDartTestFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('_test.dart');
bool isDartBenchmarkFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('_bench.dart');

bool _addPackage(String directoryPath, List<String> dartFiles, Set<String> pubSpecDirectories) {
  final int originalDartFilesCount = dartFiles.length;

  // .../directoryPath/*/bin/*.dart
  // .../directoryPath/*/lib/main.dart
  // .../directoryPath/*/test/*_test.dart
  // .../directoryPath/*/test/*/*_test.dart
  // .../directoryPath/*/benchmark/*/*_bench.dart

  Directory binDirectory = new Directory(path.join(directoryPath, 'bin'));
  if (binDirectory.existsSync()) {
    for (FileSystemEntity subentry in binDirectory.listSync()) {
      if (isDartFile(subentry))
        dartFiles.add(subentry.path);
    }
  }

  String mainPath = path.join(directoryPath, 'lib', 'main.dart');
  if (FileSystemEntity.isFileSync(mainPath))
    dartFiles.add(mainPath);

  Directory testDirectory = new Directory(path.join(directoryPath, 'test'));
  if (testDirectory.existsSync()) {
    for (FileSystemEntity entry in testDirectory.listSync()) {
      if (entry is Directory) {
        for (FileSystemEntity subentry in entry.listSync()) {
          if (isDartTestFile(subentry))
            dartFiles.add(subentry.path);
        }
      } else if (isDartTestFile(entry)) {
        dartFiles.add(entry.path);
      }
    }
  }

  Directory testDriverDirectory = new Directory(path.join(directoryPath, 'test_driver'));
  if (testDriverDirectory.existsSync()) {
    for (FileSystemEntity entry in testDriverDirectory.listSync()) {
      if (entry is Directory) {
        for (FileSystemEntity subentry in entry.listSync()) {
          if (isDartTestFile(subentry))
            dartFiles.add(subentry.path);
        }
      } else if (isDartTestFile(entry)) {
        dartFiles.add(entry.path);
      }
    }
  }

  Directory benchmarkDirectory = new Directory(path.join(directoryPath, 'benchmark'));
  if (benchmarkDirectory.existsSync()) {
    for (FileSystemEntity entry in benchmarkDirectory.listSync()) {
      if (entry is Directory) {
        for (FileSystemEntity subentry in entry.listSync()) {
          if (isDartBenchmarkFile(subentry))
            dartFiles.add(subentry.path);
        }
      } else if (isDartBenchmarkFile(entry)) {
        dartFiles.add(entry.path);
      }
    }
  }

  if (originalDartFilesCount != dartFiles.length) {
    pubSpecDirectories.add(directoryPath);
    return true;
  }
  return false;
}

/// Adds all packages in [subPath], assuming a flat directory structure, i.e.
/// each direct child of [subPath] is a plain Dart package.
void _addFlatPackageList(String subPath, List<String> dartFiles, Set<String> pubSpecDirectories) {
  Directory subdirectory = new Directory(path.join(ArtifactStore.flutterRoot, subPath));
  if (subdirectory.existsSync()) {
    for (FileSystemEntity entry in subdirectory.listSync()) {
      if (entry is Directory)
        _addPackage(entry.path, dartFiles, pubSpecDirectories);
    }
  }
}

class FileChanged { }

class AnalyzeCommand extends FlutterCommand {
  String get name => 'analyze';
  String get description => 'Analyze the project\'s Dart code.';

  AnalyzeCommand() {
    argParser.addFlag('flutter-repo', help: 'Include all the examples and tests from the Flutter repository.', defaultsTo: false);
    argParser.addFlag('current-directory', help: 'Include all the Dart files in the current directory, if any.', defaultsTo: true);
    argParser.addFlag('current-package', help: 'Include the lib/main.dart file from the current directory, if any.', defaultsTo: true);
    argParser.addFlag('preamble', help: 'Display the number of files that will be analyzed.', defaultsTo: true);
    argParser.addFlag('congratulate', help: 'Show output even when there are no errors, warnings, hints, or lints.', defaultsTo: true);
  }

  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    Stopwatch stopwatch = new Stopwatch()..start();
    Set<String> pubSpecDirectories = new HashSet<String>();
    List<String> dartFiles = argResults.rest.toList();

    bool foundAnyInCurrentDirectory = false;
    bool foundAnyInFlutterRepo = false;

    for (String file in dartFiles) {
      file = path.normalize(path.absolute(file));
      String root = path.rootPrefix(file);
      while (file != root) {
        file = path.dirname(file);
        if (FileSystemEntity.isFileSync(path.join(file, 'pubspec.yaml'))) {
          pubSpecDirectories.add(file);
          if (file == path.normalize(path.absolute(ArtifactStore.flutterRoot))) {
            foundAnyInFlutterRepo = true;
          } else if (file == path.normalize(path.absolute(path.current))) {
            foundAnyInCurrentDirectory = true;
          }
          break;
        }
      }
    }

    if (argResults['current-directory']) {
      // ./*.dart
      Directory currentDirectory = new Directory('.');
      bool foundOne = false;
      for (FileSystemEntity entry in currentDirectory.listSync()) {
        if (isDartFile(entry)) {
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
      if (_addPackage('.', dartFiles, pubSpecDirectories))
        foundAnyInCurrentDirectory = true;
    }

    if (argResults['flutter-repo']) {

      //examples/*/ as package
      //examples/layers/*/ as files
      //dev/manual_tests/*/ as package
      //dev/manual_tests/*/ as files

      _addFlatPackageList('packages', dartFiles, pubSpecDirectories);
      _addFlatPackageList('examples', dartFiles, pubSpecDirectories);

      Directory subdirectory;

      subdirectory = new Directory(path.join(ArtifactStore.flutterRoot, 'examples', 'layers'));
      if (subdirectory.existsSync()) {
        bool foundOne = false;
        for (FileSystemEntity entry in subdirectory.listSync()) {
          if (entry is Directory) {
            for (FileSystemEntity subentry in entry.listSync()) {
              if (isDartFile(subentry)) {
                dartFiles.add(subentry.path);
                foundOne = true;
              }
            }
          }
        }
        if (foundOne)
          pubSpecDirectories.add(subdirectory.path);
      }

      subdirectory = new Directory(path.join(ArtifactStore.flutterRoot, 'dev', 'manual_tests'));
      if (subdirectory.existsSync()) {
        bool foundOne = false;
        for (FileSystemEntity entry in subdirectory.listSync()) {
          if (entry is Directory) {
            _addPackage(entry.path, dartFiles, pubSpecDirectories);
          } else if (isDartFile(entry)) {
            dartFiles.add(entry.path);
            foundOne = true;
          }
        }
        if (foundOne)
          pubSpecDirectories.add(subdirectory.path);
      }

    }

    dartFiles = dartFiles.map((String directory) => path.normalize(path.absolute(directory))).toSet().toList();
    dartFiles.sort();

    // prepare a Dart file that references all the above Dart files
    StringBuffer mainBody = new StringBuffer();
    for (int index = 0; index < dartFiles.length; index += 1)
      mainBody.writeln('import \'${dartFiles[index]}\' as file$index;');
    mainBody.writeln('void main() { }');

    // prepare a union of all the .packages files
    Map<String, String> packages = <String, String>{};
    bool hadInconsistentRequirements = false;
    for (Directory directory in pubSpecDirectories.map((path) => new Directory(path))) {
      String pubSpecYamlPath = path.join(directory.path, 'pubspec.yaml');
      File pubSpecYamlFile = new File(pubSpecYamlPath);
      if (pubSpecYamlFile.existsSync()) {
        Pubspec pubSpecYaml = await Pubspec.load(pubSpecYamlPath);
        String packageName = pubSpecYaml.name;
        String packagePath = path.normalize(path.absolute(path.join(directory.path, 'lib')));
        if (packages.containsKey(packageName) && packages[packageName] != packagePath) {
          printError('Inconsistent requirements for $packageName; using $packagePath (and not ${packages[packageName]}).');
          hadInconsistentRequirements = true;
        }
        packages[packageName] = packagePath;
      }
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
              printError('Inconsistent requirements for $package; using ${packages[package]} (and not ${dependencies[package]}).');
              hadInconsistentRequirements = true;
            }
          } else {
            packages[package] = dependencies[package];
          }
        }
      }
    }
    if (hadInconsistentRequirements) {
      if (foundAnyInFlutterRepo)
        printError('You may need to run "flutter update-packages --upgrade".');
      if (foundAnyInCurrentDirectory)
        printError('You may need to run "pub upgrade".');
    }

    String buildDir = buildConfigurations.firstWhere((BuildConfiguration config) => config.testable, orElse: () => null)?.buildDir;
    if (buildDir != null) {
      packages['sky_engine'] = path.join(buildDir, 'gen/dart-pkg/sky_engine/lib');
      packages['sky_services'] = path.join(buildDir, 'gen/dart-pkg/sky_services/lib');
    }

    StringBuffer packagesBody = new StringBuffer();
    for (String package in packages.keys)
      packagesBody.writeln('$package:${path.toUri(packages[package])}');

    /// specify analysis options
    /// note that until there is a default "all-in" lint rule-set we need
    /// to opt-in to all desired lints (https://github.com/dart-lang/sdk/issues/25843)
    String optionsBody = '''
analyzer:
  errors:
    # we allow overriding fields (if they use super, ideally...)
    strong_mode_invalid_field_override: ignore
    # we allow type narrowing
    strong_mode_invalid_method_override: ignore
    todo: ignore
linter:
  rules:
    - camel_case_types
    # sometimes we have no choice (e.g. when matching other platforms)
    # - constant_identifier_names
    - empty_constructor_bodies
    # disabled until regexp fix is pulled in (https://github.com/flutter/flutter/pull/1996)
    # - library_names
    - library_prefixes
    - non_constant_identifier_names
    # too many false-positives; code review should catch real instances
    # - one_member_abstracts
    - slash_for_doc_comments
    - super_goes_last
    - type_init_formals
    - unnecessary_brace_in_string_interp
''';

    // save the Dart file and the .packages file to disk
    Directory host = Directory.systemTemp.createTempSync('flutter-analyze-');
    File mainFile = new File(path.join(host.path, 'main.dart'))..writeAsStringSync(mainBody.toString());
    File optionsFile = new File(path.join(host.path, '_analysis.options'))..writeAsStringSync(optionsBody.toString());
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
      // defines lints
      '--options', optionsFile.path,
      '--packages', packagesFile.path,
      mainFile.path
    ];

    if (argResults['preamble']) {
      if (dartFiles.length == 1) {
        printStatus('Analyzing ${dartFiles.first}...');
      } else {
        printStatus('Analyzing ${dartFiles.length} entry points...');
      }
      for (String file in dartFiles)
        printTrace(file);
    }

    printTrace(cmd.join(' '));
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
      printError(data);
    });

    int exitCode = await process.exitCode;

    List<Pattern> patternsToSkip = <Pattern>[
      'Analyzing [${mainFile.path}]...',
      new RegExp('^\\[(hint|error)\\] Unused import \\(${mainFile.path},'),
      new RegExp(r'^\[.+\] .+ \(.+/\.pub-cache/.+'),
      new RegExp('^\\[error\\] The argument type \'List<T>\' cannot be assigned to the parameter type \'List<.+>\''), // until we have generic methods, there's not much choice if you want to use map()
      new RegExp(r'^\[error\] Type check failed: .*\(dynamic\) is not of type'), // allow unchecked casts from dynamic
      new RegExp('\\[warning\\] Missing concrete implementation of \'RenderObject\\.applyPaintTransform\''), // https://github.com/dart-lang/sdk/issues/25232
      new RegExp(r'[0-9]+ (error|warning|hint|lint).+found\.'),
      new RegExp(r'^$'),
    ];

    RegExp generalPattern = new RegExp(r'^\[(error|warning|hint|lint)\] (.+) \(([^(),]+), line ([0-9]+), col ([0-9]+)\)$');
    RegExp allowedIdentifiersPattern = new RegExp(r'_?([A-Z]|_+)\b');
    RegExp constructorTearOffsPattern = new RegExp('.+#.+// analyzer doesn\'t like constructor tear-offs');
    RegExp ignorePattern = new RegExp(r'// analyzer says "([^"]+)"');
    RegExp conflictingNamesPattern = new RegExp('^The imported libraries \'([^\']+)\' and \'([^\']+)\' cannot have the same name \'([^\']+)\'\$');
    RegExp missingFilePattern = new RegExp('^Target of URI does not exist: \'([^\')]+)\'\$');

    Set<String> changedFiles = new Set<String>(); // files about which we've complained that they changed

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
          String sourceLine;
          try {
            if (lineNumber > sourceLines.length)
              throw new FileChanged();
            sourceLine = sourceLines[lineNumber-1];
            if (colNumber > sourceLine.length)
              throw new FileChanged();
          } on FileChanged {
            if (changedFiles.add(filename))
              printError('[warning] File shrank during analysis ($filename)');
            sourceLine = '';
            lineNumber = 1;
            colNumber = 1;
          }
          bool shouldIgnore = false;
          if (filename == mainFile.path) {
            Match libs = conflictingNamesPattern.firstMatch(errorMessage);
            Match missing = missingFilePattern.firstMatch(errorMessage);
            if (libs != null) {
              errorLine = '[$level] $errorMessage (${dartFiles[lineNumber-1]})'; // strip the reference to the generated main.dart
            } else if (missing != null) {
              errorLine = '[$level] File does not exist (${missing[1]})';
            } else {
              errorLine += ' (Please file a bug on the "flutter analyze" command saying that you saw this message.)';
            }
          } else if (filename.endsWith('.mojom.dart')) {
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
        printError(errorLine);
        errorCount += 1;
      }
    }
    stopwatch.stop();
    String elapsed = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(1);

    host.deleteSync(recursive: true);

    if (exitCode < 0 || exitCode > 3) // 0 = nothing, 1 = hints, 2 = warnings, 3 = errors
      return exitCode;

    if (errorCount > 0)
      return 1; // Doesn't this mean 'hints' per the above comment?
    if (argResults['congratulate'])
      printStatus('No analyzer warnings! (ran in ${elapsed}s)');
    return 0;
  }
}
