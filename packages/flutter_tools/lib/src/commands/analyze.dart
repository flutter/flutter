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
import '../base/utils.dart';
import '../build_configuration.dart';
import '../dart/sdk.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

// TODO(devoncarew): Possible improvements to flutter analyze --watch:
// - Auto-detect new issues introduced by changes and highlight then in the output.
// - Use ANSI codes to improve the display when the terminal supports it (screen
//   clearing, cursor position manipulation, bold and faint codes, ...)

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
    argParser.addFlag('current-directory', help: 'Include all the Dart files in the current directory, if any.', defaultsTo: true);
    argParser.addFlag('current-package', help: 'Include the lib/main.dart file from the current directory, if any.', defaultsTo: true);
    argParser.addFlag('preamble', help: 'Display the number of files that will be analyzed.', defaultsTo: true);
    argParser.addFlag('congratulate', help: 'Show output even when there are no errors, warnings, hints, or lints.', defaultsTo: true);
    argParser.addFlag('watch', help: 'Run analysis continuously, watching the filesystem for changes.', negatable: false);
  }

  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    return argResults['watch'] ? _analyzeWatch() : _analyzeOnce();
  }

  Future<int> _analyzeOnce() async {
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

    if (ArtifactStore.isFlutterRepo) {
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
    File optionsFile = new File(path.join(ArtifactStore.flutterRoot, 'packages', 'flutter_tools', '.analysis_options'));

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

  Future<int> _analyzeWatch() async {
    List<String> directories;

    if (ArtifactStore.isFlutterRepo) {
      directories = <String>[];
      directories.addAll(_gatherProjectPaths(path.absolute('examples')));
      directories.addAll(_gatherProjectPaths(path.absolute('packages')));
      printStatus('Analyzing Flutter repository (${directories.length} projects).');
      for (String projectPath in directories)
        printTrace('  ${path.relative(projectPath)}');
      printStatus('');
    } else {
      directories = <String>[Directory.current.path];
    }

    AnalysisServer server = new AnalysisServer(dartSdkPath, directories);
    server.onAnalyzing.listen(_handleAnalysisStatus);
    server.onErrors.listen(_handleAnalysisErrors);

    await server.start();

    int exitCode = await server.onExit;
    printStatus('Analysis server exited with code $exitCode.');
    return 0;
  }

  bool firstAnalysis = true;
  Set<String> analyzedPaths = new Set<String>();
  Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
  Stopwatch analysisTimer;
  int lastErrorCount = 0;

  void _handleAnalysisStatus(bool isAnalyzing) {
    if (isAnalyzing) {
      if (firstAnalysis) {
        printStatus('Analyzing ${path.basename(Directory.current.path)}...');
      } else {
        printStatus('');
      }

      analyzedPaths.clear();
      analysisTimer = new Stopwatch()..start();
    } else {
      analysisTimer.stop();

      // Sort and print errors.
      List<AnalysisError> errors = <AnalysisError>[];
      for (List<AnalysisError> fileErrors in analysisErrors.values)
        errors.addAll(fileErrors);

      errors.sort();

      for (AnalysisError error in errors)
        printStatus(error.toString());

      // Print an analysis summary.
      String errorsMessage;

      int issueCount = errors.length;
      int issueDiff = issueCount - lastErrorCount;
      lastErrorCount = issueCount;

      // TODO(devoncarew): If there were no issues found, and no change in the
      // issue count, do we want to print anything?
      if (firstAnalysis)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found';
      else if (issueDiff > 0)
        errorsMessage = '$issueDiff new ${pluralize('issue', issueDiff)}, $issueCount total';
      else if (issueDiff < 0)
        errorsMessage = '${-issueDiff} ${pluralize('issue', -issueDiff)} fixed, $issueCount remaining';
      else if (issueCount != 0)
        errorsMessage = 'no new issues, $issueCount total';
      else
        errorsMessage = 'no issues found';

      String files = '${analyzedPaths.length} ${pluralize('file', analyzedPaths.length)}';
      String seconds = (analysisTimer.elapsedMilliseconds / 1000.0).toStringAsFixed(2);
      printStatus('$errorsMessage • analyzed $files, $seconds seconds');

      firstAnalysis = false;
    }
  }

  void _handleAnalysisErrors(FileAnalysisErrors fileErrors) {
    fileErrors.errors.removeWhere(_filterError);

    analyzedPaths.add(fileErrors.file);
    analysisErrors[fileErrors.file] = fileErrors.errors;
  }

  bool _filterError(AnalysisError error) {
    // TODO(devoncarew): Also filter the regex items from `analyzeOnce()`.

    if (error.type == 'TODO')
      return true;

    return false;
  }

  List<String> _gatherProjectPaths(String rootPath) {
    if (FileSystemEntity.isFileSync(path.join(rootPath, 'pubspec.yaml')))
      return <String>[rootPath];

    return new Directory(rootPath)
      .listSync(followLinks: false)
      .expand((FileSystemEntity entity) {
        return entity is Directory ? _gatherProjectPaths(entity.path) : <String>[];
      });
  }
}

class AnalysisServer {
  AnalysisServer(this.sdk, this.directories);

  final String sdk;
  final List<String> directories;

  Process _process;
  StreamController<bool> _analyzingController = new StreamController<bool>.broadcast();
  StreamController<FileAnalysisErrors> _errorsController = new StreamController<FileAnalysisErrors>.broadcast();

  int _id = 0;

  Future start() async {
    String snapshot = path.join(sdk, 'bin/snapshots/analysis_server.dart.snapshot');
    List<String> args = <String>[snapshot, '--sdk', sdk];

    printTrace('dart ${args.join(' ')}');
    _process = await Process.start('dart', args);
    _process.exitCode.whenComplete(() => _process = null);

    Stream<String> errorStream = _process.stderr.transform(UTF8.decoder).transform(const LineSplitter());
    errorStream.listen((String error) => printError(error));

    Stream<String> inStream = _process.stdout.transform(UTF8.decoder).transform(const LineSplitter());
    inStream.listen(_handleServerResponse);

    // Available options (many of these are obsolete):
    //   enableAsync, enableDeferredLoading, enableEnums, enableNullAwareOperators,
    //   enableSuperMixins, generateDart2jsHints, generateHints, generateLints
    _sendCommand('analysis.updateOptions', <String, dynamic>{
      'options': <String, dynamic>{
        'enableSuperMixins': true
      }
    });

    _sendCommand('server.setSubscriptions', <String, dynamic>{
      'subscriptions': <String>['STATUS']
    });

    _sendCommand('analysis.setAnalysisRoots', <String, dynamic>{
      'included': directories,
      'excluded': <String>[]
    });
  }

  Stream<bool> get onAnalyzing => _analyzingController.stream;
  Stream<FileAnalysisErrors> get onErrors => _errorsController.stream;

  Future<int> get onExit => _process.exitCode;

  void _sendCommand(String method, Map<String, dynamic> params) {
    String message = JSON.encode(<String, dynamic> {
      'id': (++_id).toString(),
      'method': method,
      'params': params
    });
    _process.stdin.writeln(message);
    printTrace('==> $message');
  }

  void _handleServerResponse(String line) {
    printTrace('<== $line');

    dynamic response = JSON.decode(line);

    if (response is Map) {
      if (response['event'] != null) {
        String event = response['event'];
        dynamic params = response['params'];

        if (params is Map) {
          if (event == 'server.status')
            _handleStatus(response['params']);
          else if (event == 'analysis.errors')
            _handleAnalysisIssues(response['params']);
          else if (event == 'server.error')
            _handleServerError(response['params']);
        }
      } else if (response['error'] != null) {
        printError('Error from the analysis server: ${response['error']['message']}');
      }
    }
  }

  void _handleStatus(Map<String, dynamic> statusInfo) {
    // {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
    if (statusInfo['analysis'] != null) {
      bool isAnalyzing = statusInfo['analysis']['isAnalyzing'];
      _analyzingController.add(isAnalyzing);
    }
  }

  void _handleServerError(Map<String, dynamic> errorInfo) {
    printError('Error from the analysis server: ${errorInfo['message']}');
  }

  void _handleAnalysisIssues(Map<String, dynamic> issueInfo) {
    // {"event":"analysis.errors","params":{"file":"/Users/.../lib/main.dart","errors":[]}}
    String file = issueInfo['file'];
    List<AnalysisError> errors = issueInfo['errors'].map((Map<String, dynamic> json) => new AnalysisError(json)).toList();
    _errorsController.add(new FileAnalysisErrors(file, errors));
  }

  Future dispose() async => _process?.kill();
}

class FileAnalysisErrors {
  FileAnalysisErrors(this.file, this.errors);

  final String file;
  final List<AnalysisError> errors;
}

class AnalysisError implements Comparable<AnalysisError> {
  AnalysisError(this.json);

  static final Map<String, int> _severityMap = <String, int> {
    'ERROR': 3,
    'WARNING': 2,
    'INFO': 1
  };

  // "severity":"INFO","type":"TODO","location":{
  //   "file":"/Users/.../lib/test.dart","offset":362,"length":72,"startLine":15,"startColumn":4
  // },"message":"...","hasFix":false}
  Map<String, dynamic> json;

  String get severity => json['severity'];
  int get severityLevel => _severityMap[severity] ?? 0;
  String get type => json['type'];
  String get message => json['message'];

  String get file => json['location']['file'];
  int get startLine => json['location']['startLine'];
  int get startColumn => json['location']['startColumn'];
  int get offset => json['location']['offset'];

  int compareTo(AnalysisError other) {
    // Sort in order of file path, error location, severity, and message.
    if (file != other.file)
      return file.compareTo(other.file);

    if (offset != other.offset)
      return offset - other.offset;

    int diff = other.severityLevel - severityLevel;
    if (diff != 0)
      return diff;

    return message.compareTo(other.message);
  }

  String toString() {
    String relativePath = path.relative(file);
    return '${severity.toLowerCase()} • $message • $relativePath:$startLine:$startColumn';
  }
}
