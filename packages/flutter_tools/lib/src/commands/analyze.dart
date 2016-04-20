// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_configuration.dart';
import '../dart/sdk.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

bool isDartFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('.dart');
bool isDartTestFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('_test.dart');
bool isDartBenchmarkFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('_bench.dart');

RegExp _testFileParser = new RegExp(r'^(.+)_test(\.dart)$');

void _addDriverTest(FileSystemEntity entry, List<String> dartFiles) {
  if (isDartTestFile(entry)) {
    final String testFileName = entry.path;
    dartFiles.add(testFileName);
    Match groups = _testFileParser.firstMatch(testFileName);
    assert(groups.groupCount == 2);
    final String hostFileName = '${groups[1]}${groups[2]}';
    File hostFile = new File(hostFileName);
    if (hostFile.existsSync()) {
      assert(isDartFile(hostFile));
      dartFiles.add(hostFileName);
    }
  }
}

void _addPackage(String directoryPath, List<String> dartFiles, Set<String> pubSpecDirectories) {
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
        for (FileSystemEntity subentry in entry.listSync())
          _addDriverTest(subentry, dartFiles);
      } else if (isDartTestFile(entry)) {
        _addDriverTest(entry, dartFiles);
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

  if (originalDartFilesCount != dartFiles.length)
    pubSpecDirectories.add(directoryPath);
}

class FileChanged { }

class AnalyzeCommand extends FlutterCommand {
  AnalyzeCommand() {
    argParser.addFlag('flutter-repo', help: 'Include all the examples and tests from the Flutter repository.', defaultsTo: false);
    argParser.addFlag('current-directory', help: 'Include all the Dart files in the current directory, if any.', defaultsTo: true);
    argParser.addFlag('current-package', help: 'Include the lib/main.dart file from the current directory, if any.', defaultsTo: true);
    argParser.addFlag('dartdocs', help: 'List every public member that is lacking documentation. (Only examines files in the Flutter repository.)', defaultsTo: false);
    argParser.addFlag('preamble', help: 'Display the number of files that will be analyzed.', defaultsTo: true);
    argParser.addFlag('congratulate', help: 'Show output even when there are no errors, warnings, hints, or lints.', defaultsTo: true);
    argParser.addFlag('watch', help: 'Run analysis continuously, watching the filesystem for changes.', negatable: false);
    argParser.addOption('dart-sdk', help: 'The path to the Dart SDK.', hide: true);

    usesPubOption();
  }

  @override
  String get name => 'analyze';

  @override
  String get description => 'Analyze the project\'s Dart code.';

  @override
  bool get shouldRunPub {
    // If they're not analyzing the current project.
    if (!argResults['current-package'])
      return false;

    // Or we're not in a project directory.
    if (!new File('pubspec.yaml').existsSync())
      return false;

    return super.shouldRunPub;
  }

  @override
  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() => argResults['watch'] ? _analyzeWatch() : _analyzeOnce();

  List<String> flutterRootComponents;
  bool isFlutterLibrary(String filename) {
    flutterRootComponents ??= path.normalize(path.absolute(ArtifactStore.flutterRoot)).split(path.separator);
    List<String> filenameComponents = path.normalize(path.absolute(filename)).split(path.separator);
    if (filenameComponents.length < flutterRootComponents.length + 4) // the 4: 'packages', package_name, 'lib', file_name
      return false;
    for (int index = 0; index < flutterRootComponents.length; index += 1) {
      if (flutterRootComponents[index] != filenameComponents[index])
        return false;
    }
    if (filenameComponents[flutterRootComponents.length] != 'packages')
      return false;
    if (filenameComponents[flutterRootComponents.length + 1] == 'flutter_tools')
      return false;
    if (filenameComponents[flutterRootComponents.length + 2] != 'lib')
      return false;
    return true;
  }

  Future<int> _analyzeOnce() async {
    Stopwatch stopwatch = new Stopwatch()..start();
    Set<String> pubSpecDirectories = new HashSet<String>();
    List<String> dartFiles = argResults.rest.toList();

    for (String file in dartFiles) {
      file = path.normalize(path.absolute(file));
      String root = path.rootPrefix(file);
      while (file != root) {
        file = path.dirname(file);
        if (FileSystemEntity.isFileSync(path.join(file, 'pubspec.yaml'))) {
          pubSpecDirectories.add(file);
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
      if (foundOne)
        pubSpecDirectories.add('.');
    }

    if (argResults['current-package'])
      _addPackage('.', dartFiles, pubSpecDirectories);

    if (argResults['flutter-repo']) {
      //examples/*/ as package
      //examples/layers/*/ as files
      //dev/manual_tests/*/ as package
      //dev/manual_tests/*/ as files

      for (Directory dir in runner.getRepoPackages())
        _addPackage(dir.path, dartFiles, pubSpecDirectories);

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

    // determine what all the various .packages files depend on
    PackageDependencyTracker dependencies = new PackageDependencyTracker();
    for (Directory directory in pubSpecDirectories.map((String path) => new Directory(path))) {
      String pubSpecYamlPath = path.join(directory.path, 'pubspec.yaml');
      File pubSpecYamlFile = new File(pubSpecYamlPath);
      if (pubSpecYamlFile.existsSync()) {
        // we are analyzing the actual canonical source for this package;
        // make sure we remember that, in case all the packages are actually
        // pointing elsewhere somehow.
        yaml.YamlMap pubSpecYaml = yaml.loadYaml(new File(pubSpecYamlPath).readAsStringSync());
        String packageName = pubSpecYaml['name'];
        String packagePath = path.normalize(path.absolute(path.join(directory.path, 'lib')));
        dependencies.addCanonicalCase(packageName, packagePath, pubSpecYamlPath);
      }
      String dotPackagesPath = path.join(directory.path, '.packages');
      File dotPackages = new File(dotPackagesPath);
      if (dotPackages.existsSync()) {
        // this directory has opinions about what we should be using
        dotPackages
          .readAsStringSync()
          .split('\n')
          .where((String line) => !line.startsWith(new RegExp(r'^ *#')))
          .forEach((String line) {
            int colon = line.indexOf(':');
            if (colon > 0)
              dependencies.add(line.substring(0, colon), path.normalize(path.absolute(directory.path, path.fromUri(line.substring(colon+1)))), dotPackagesPath);
          });
      }
    }

    // prepare a union of all the .packages files
    if (dependencies.hasConflicts) {
      printError(dependencies.generateConflictReport());
      printError('Make sure you have run "pub upgrade" in all the directories mentioned above.');
      if (dependencies.hasConflictsAffectingFlutterRepo)
        printError('For packages in the flutter repository, try using "flutter update-packages --upgrade" to do all of them at once.');
      printError('If this does not help, to track down the conflict you can use "pub deps --style=list" and "pub upgrade --verbosity=solver" in the affected directories.');
      return 1;
    }
    Map<String, String> packages = dependencies.asPackageMap();

    // override the sky_engine and sky_services packages if the user is using a local build
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
    File optionsFile = new File(path.join(ArtifactStore.flutterRoot, 'packages', 'flutter_tools', 'flutter_analysis_options'));
    File packagesFile = new File(path.join(host.path, '.packages'))..writeAsStringSync(packagesBody.toString());

    List<String> cmd = <String>[
      sdkBinaryName('dartanalyzer', sdkLocation: argResults['dart-sdk']),
      // do not set '--warnings', since that will include the entire Dart SDK
      '--ignore-unrecognized-flags',
      '--enable_type_checks',
      '--package-warnings',
      '--fatal-warnings',
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
      new RegExp(r'[0-9]+ (error|warning|hint|lint).+found\.'),
      new RegExp(r'^$'),
    ];

    RegExp generalPattern = new RegExp(r'^\[(error|warning|hint|lint)\] (.+) \(([^(),]+), line ([0-9]+), col ([0-9]+)\)$');
    RegExp conflictingNamesPattern = new RegExp('^The imported libraries \'([^\']+)\' and \'([^\']+)\' cannot have the same name \'([^\']+)\'\$');
    RegExp missingFilePattern = new RegExp('^Target of URI does not exist: \'([^\')]+)\'\$');
    RegExp documentAllMembersPattern = new RegExp('^Document all public members\$');

    Set<String> changedFiles = new Set<String>(); // files about which we've complained that they changed

    _SourceCache cache = new _SourceCache(10);

    int membersMissingDocumentation = 0;
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
          try {
            File source = new File(filename);
            List<String> sourceLines = cache.getSourceFor(source);
            if (lineNumber > sourceLines.length)
              throw new FileChanged();
            String sourceLine = sourceLines[lineNumber-1];
            if (colNumber > sourceLine.length)
              throw new FileChanged();
            bool shouldIgnore = false;
            if (documentAllMembersPattern.firstMatch(errorMessage) != null) {
              // https://github.com/dart-lang/linter/issues/207
              // https://github.com/dart-lang/linter/issues/208
              if (isFlutterLibrary(filename)) {
                if (!argResults['dartdocs']) {
                  membersMissingDocumentation += 1;
                  shouldIgnore = true;
                }
              } else {
                shouldIgnore = true;
              }
            } else if (filename == mainFile.path) {
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
            } else if (sourceLines.first.startsWith('// DO NOT EDIT. This is code generated')) {
              // autogenerated code - TODO(ianh): Fix the intl package resource generator
              shouldIgnore = true;
            }
            if (shouldIgnore)
              continue;
          } on FileSystemException catch (exception) {
            if (changedFiles.add(filename))
              printError('[warning] Could not read file (${exception.message}${ exception.osError != null ? "; ${exception.osError}" : ""}) ($filename)');
          } on FileChanged {
            if (changedFiles.add(filename))
              printError('[warning] File shrank during analysis ($filename)');
          }
        }
        printError(errorLine);
        errorCount += 1;
      }
    }
    stopwatch.stop();
    String elapsed = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(1);

    host.deleteSync(recursive: true);

    if (exitCode < 0 || exitCode > 3) // analyzer exit codes: 0 = nothing, 1 = hints, 2 = warnings, 3 = errors
      return exitCode;

    if (errorCount > 0) {
      if (membersMissingDocumentation > 0 && argResults['flutter-repo'])
        printError('[lint] $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation');
      return 1; // we consider any level of error to be an error exit (we don't report different levels)
    }
    if (argResults['congratulate']) {
      if (membersMissingDocumentation > 0 && argResults['flutter-repo']) {
        printStatus('No analyzer warnings! (ran in ${elapsed}s; $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation)');
      } else {
        printStatus('No analyzer warnings! (ran in ${elapsed}s)');
      }
    }
    return 0;
  }

  Future<int> _analyzeWatch() async {
    List<String> directories;

    if (argResults['flutter-repo']) {
      directories = runner.getRepoPackages().map((Directory dir) => dir.path).toList();
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

      for (AnalysisError error in errors) {
        printStatus(error.toString());
        if (error.code != null)
          printTrace('error code: ${error.code}');
      }

      // Print an analysis summary.
      String errorsMessage;

      int issueCount = errors.length;
      int issueDiff = issueCount - lastErrorCount;
      lastErrorCount = issueCount;

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
      printStatus('$errorsMessage ${logger.separator} analyzed $files, $seconds seconds');

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
}

class PackageDependency {
  // This is a map from dependency targets (lib directories) to a list
  // of places that ask for that target (.packages or pubspec.yaml files)
  Map<String, List<String>> values = <String, List<String>>{};
  String canonicalSource;
  void addCanonicalCase(String packagePath, String pubSpecYamlPath) {
    assert(canonicalSource == null);
    add(packagePath, pubSpecYamlPath);
    canonicalSource = pubSpecYamlPath;
  }
  void add(String packagePath, String sourcePath) {
    values.putIfAbsent(packagePath, () => <String>[]).add(sourcePath);
  }
  bool get hasConflict => values.length > 1;
  bool get hasConflictAffectingFlutterRepo {
    assert(path.isAbsolute(ArtifactStore.flutterRoot));
    for (List<String> targetSources in values.values) {
      for (String source in targetSources) {
        assert(path.isAbsolute(source));
        if (path.isWithin(ArtifactStore.flutterRoot, source))
          return true;
      }
    }
    return false;
  }
  void describeConflict(StringBuffer result) {
    assert(hasConflict);
    List<String> targets = values.keys.toList();
    targets.sort((String a, String b) => values[b].length.compareTo(values[a].length));
    for (String target in targets) {
      int count = values[target].length;
      result.writeln('  $count ${count == 1 ? 'source wants' : 'sources want'} "$target":');
      bool canonical = false;
      for (String source in values[target]) {
        result.writeln('    $source');
        if (source == canonicalSource)
          canonical = true;
      }
      if (canonical) {
        result.writeln('    (This is the actual package definition, so it is considered the canonical "right answer".)');
      }
    }
  }
  String get target => values.keys.single;
}

class PackageDependencyTracker {
  // This is a map from package names to objects that track the paths
  // involved (sources and targets).
  Map<String, PackageDependency> packages = <String, PackageDependency>{};

  PackageDependency getPackageDependency(String packageName) {
    return packages.putIfAbsent(packageName, () => new PackageDependency());
  }

  void addCanonicalCase(String packageName, String packagePath, String pubSpecYamlPath) {
    getPackageDependency(packageName).addCanonicalCase(packagePath, pubSpecYamlPath);
  }

  void add(String packageName, String packagePath, String dotPackagesPath) {
    getPackageDependency(packageName).add(packagePath, dotPackagesPath);
  }

  bool get hasConflicts {
    return packages.values.any((PackageDependency dependency) => dependency.hasConflict);
  }

  bool get hasConflictsAffectingFlutterRepo {
    return packages.values.any((PackageDependency dependency) => dependency.hasConflictAffectingFlutterRepo);
  }

  String generateConflictReport() {
    assert(hasConflicts);
    StringBuffer result = new StringBuffer();
    for (String package in packages.keys.where((String package) => packages[package].hasConflict)) {
      result.writeln('Package "$package" has conflicts:');
      packages[package].describeConflict(result);
    }
    return result.toString();
  }

  Map<String, String> asPackageMap() {
    Map<String, String> result = <String, String>{};
    for (String package in packages.keys)
      result[package] = packages[package].target;
    return result;
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

  Future<Null> start() async {
    String snapshot = path.join(sdk, 'bin/snapshots/analysis_server.dart.snapshot');
    List<String> args = <String>[snapshot, '--sdk', sdk];

    printTrace('dart ${args.join(' ')}');
    _process = await Process.start(path.join(dartSdkPath, 'bin', 'dart'), args);
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

    if (response is Map<dynamic, dynamic>) {
      if (response['event'] != null) {
        String event = response['event'];
        dynamic params = response['params'];

        if (params is Map<dynamic, dynamic>) {
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

  Future<bool> dispose() async => _process?.kill();
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
  String get code => json['code'];

  String get file => json['location']['file'];
  int get startLine => json['location']['startLine'];
  int get startColumn => json['location']['startColumn'];
  int get offset => json['location']['offset'];

  @override
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

  @override
  String toString() {
    String relativePath = path.relative(file);
    String sep = logger.separator;
    return '${severity.toLowerCase().padLeft(7)} $sep $message $sep $relativePath:$startLine:$startColumn';
  }
}

class _SourceCache {
  _SourceCache(this.cacheSize);

  final int cacheSize;
  final Map<String, List<String>> _lines = new LinkedHashMap<String, List<String>>();

  List<String> getSourceFor(File file) {
    if (!_lines.containsKey(file.path)) {
      if (_lines.length >= cacheSize)
        _lines.remove(_lines.keys.first);
      _lines[file.path] = file.readAsLinesSync();
    }

    return _lines[file.path];
  }
}
