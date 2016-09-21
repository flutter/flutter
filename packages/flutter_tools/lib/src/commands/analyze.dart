// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import '../base/logger.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../dart/analysis.dart';
import '../dart/sdk.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

bool isDartFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('.dart');

typedef bool FileFilter(FileSystemEntity entity);

class AnalyzeCommand extends FlutterCommand {
  AnalyzeCommand({bool verboseHelp: false}) {
    argParser.addFlag('flutter-repo', help: 'Include all the examples and tests from the Flutter repository.', defaultsTo: false);
    argParser.addFlag('current-directory', help: 'Include all the Dart files in the current directory, if any.', defaultsTo: true);
    argParser.addFlag('current-package', help: 'Include the lib/main.dart file from the current directory, if any.', defaultsTo: true);
    argParser.addFlag('dartdocs', help: 'List every public member that is lacking documentation (only examines files in the Flutter repository).', defaultsTo: false);
    argParser.addFlag('preamble', help: 'Display the number of files that will be analyzed.', defaultsTo: true);
    argParser.addFlag('congratulate', help: 'Show output even when there are no errors, warnings, hints, or lints.', defaultsTo: true);
    argParser.addFlag('watch', help: 'Run analysis continuously, watching the filesystem for changes.', negatable: false);
    argParser.addOption('write', valueHelp: 'file', help: 'Also output the results to a file. This is useful with --watch if you want a file to always contain the latest results.');
    argParser.addOption('dart-sdk', valueHelp: 'path-to-sdk', help: 'The path to the Dart SDK.', hide: !verboseHelp);

    // Hidden option to enable a benchmarking mode.
    argParser.addFlag('benchmark', negatable: false, hide: !verboseHelp);

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
  Future<int> runCommand() => argResults['watch'] ? _analyzeWatch() : _analyzeOnce();

  List<String> flutterRootComponents;
  bool isFlutterLibrary(String filename) {
    flutterRootComponents ??= path.normalize(path.absolute(Cache.flutterRoot)).split(path.separator);
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

  /// Return `true` if [fileList] contains a path that resides inside the Flutter repository.
  /// If [fileList] is empty, then return `true` if the current directory resides inside the Flutter repository.
  bool inRepo(List<String> fileList) {
    if (fileList == null || fileList.isEmpty)
      fileList = <String>[path.current];
    String root = path.normalize(path.absolute(Cache.flutterRoot));
    String prefix = root + Platform.pathSeparator;
    for (String file in fileList) {
      file = path.normalize(path.absolute(file));
      if (file == root || file.startsWith(prefix))
        return true;
    }
    return false;
  }

  bool get _isBenchmarking => argResults['benchmark'];

  Future<int> _analyzeOnce() async {
    Stopwatch stopwatch = new Stopwatch()..start();
    Set<Directory> pubSpecDirectories = new HashSet<Directory>();
    List<File> dartFiles = <File>[];

    for (String file in argResults.rest.toList()) {
      file = path.normalize(path.absolute(file));
      String root = path.rootPrefix(file);
      dartFiles.add(new File(file));
      while (file != root) {
        file = path.dirname(file);
        if (FileSystemEntity.isFileSync(path.join(file, 'pubspec.yaml'))) {
          pubSpecDirectories.add(new Directory(file));
          break;
        }
      }
    }

    bool currentDirectory = argResults['current-directory'] && (argResults.wasParsed('current-directory') || dartFiles.isEmpty);
    bool currentPackage = argResults['current-package'] && (argResults.wasParsed('current-package') || dartFiles.isEmpty);
    bool flutterRepo = argResults['flutter-repo'] || inRepo(argResults.rest);

    //TODO (pq): revisit package and directory defaults

    if (currentDirectory  && !flutterRepo) {
      // ./*.dart
      Directory currentDirectory = new Directory('.');
      bool foundOne = false;
      for (FileSystemEntity entry in currentDirectory.listSync()) {
        if (isDartFile(entry)) {
          dartFiles.add(entry);
          foundOne = true;
        }
      }
      if (foundOne)
        pubSpecDirectories.add(currentDirectory);
    }

    if (currentPackage && !flutterRepo) {
      // **/.*dart
      Directory currentDirectory = new Directory('.');
      _collectDartFiles(currentDirectory, dartFiles);
      pubSpecDirectories.add(currentDirectory);
    }

    // TODO(ianh): Fix the intl package resource generator
    // TODO(pq): extract this regexp from the exclude in options
    RegExp stockExampleFiles = new RegExp('examples/stocks/lib/i18n/.*\.dart\$');

    if (flutterRepo) {
      for (Directory dir in runner.getRepoPackages()) {
        _collectDartFiles(dir, dartFiles,
            exclude: (FileSystemEntity entity) => stockExampleFiles.hasMatch(entity.path));
        pubSpecDirectories.add(dir);
      }
    }

    // determine what all the various .packages files depend on
    PackageDependencyTracker dependencies = new PackageDependencyTracker();
    for (Directory directory in pubSpecDirectories) {
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
            if (colon > 0) {
              String packageName = line.substring(0, colon);
              String packagePath = path.fromUri(line.substring(colon+1));
              // Ensure that we only add the `analyzer` package defined in the vended SDK (and referred to with a local path directive).
              // Analyzer package versions reached via transitive dependencies (e.g., via `test`) are ignored since they would produce
              // spurious conflicts.
              if (packageName != 'analyzer' || packagePath.startsWith('..'))
                dependencies.add(packageName, path.normalize(path.absolute(directory.path, path.fromUri(packagePath))), dotPackagesPath);
            }
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
    if (tools.engineBuildPath != null) {
      packages['sky_engine'] = path.join(tools.engineBuildPath, 'gen/dart-pkg/sky_engine/lib');
      packages['sky_services'] = path.join(tools.engineBuildPath, 'gen/dart-pkg/sky_services/lib');
    }

    Cache.releaseLockEarly();

    if (argResults['preamble']) {
      if (dartFiles.length == 1) {
        logger.printStatus('Analyzing ${path.relative(dartFiles.first.path)}...');
      } else {
        logger.printStatus('Analyzing ${dartFiles.length} files...');
      }
    }
    DriverOptions options = new DriverOptions();
    options.dartSdkPath = argResults['dart-sdk'];
    options.packageMap = packages;
    options.analysisOptionsFile = flutterRepo
      ? path.join(Cache.flutterRoot, '.analysis_options_repo')
      : path.join(Cache.flutterRoot, '.analysis_options_user');
    AnalysisDriver analyzer = new AnalysisDriver(options);

    // TODO(pq): consider error handling
    List<AnalysisErrorDescription> errors = analyzer.analyze(dartFiles);

    int errorCount = 0;
    int membersMissingDocumentation = 0;
    for (AnalysisErrorDescription error in errors) {
      bool shouldIgnore = false;
      if (error.errorCode.name == 'public_member_api_docs') {
        // https://github.com/dart-lang/linter/issues/207
        // https://github.com/dart-lang/linter/issues/208
        if (isFlutterLibrary(error.source.fullName)) {
          if (!argResults['dartdocs']) {
            membersMissingDocumentation += 1;
            shouldIgnore = true;
          }
        } else {
          shouldIgnore = true;
        }
      }
      // TODO(ianh): Fix the Dart mojom compiler
      if (error.source.fullName.endsWith('.mojom.dart'))
        shouldIgnore = true;
      if (shouldIgnore)
        continue;
      printError(error.asString());
      errorCount += 1;
    }
    _dumpErrors(errors.map/*<String>*/((AnalysisErrorDescription error) => error.asString()));

    stopwatch.stop();
    String elapsed = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(1);

    if (_isBenchmarking)
      _writeBenchmark(stopwatch, errorCount, membersMissingDocumentation);

    if (errorCount > 0) {
      if (membersMissingDocumentation > 0 && flutterRepo)
        printError('[lint] $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation (ran in ${elapsed}s)');
      else
        print('(Ran in ${elapsed}s)');
      return 1; // we consider any level of error to be an error exit (we don't report different levels)
    }
    if (argResults['congratulate']) {
      if (membersMissingDocumentation > 0 && flutterRepo) {
        printStatus('No analyzer warnings! (ran in ${elapsed}s; $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation)');
      } else {
        printStatus('No analyzer warnings! (ran in ${elapsed}s)');
      }
    }
    return 0;
  }

  void _dumpErrors(Iterable<String> errors) {
    if (argResults['write'] != null) {
      try {
        final RandomAccessFile resultsFile = new File(argResults['write']).openSync(mode: FileMode.WRITE);
        try {
          resultsFile.lockSync();
          resultsFile.writeStringSync(errors.join('\n'));
        } finally {
          resultsFile.close();
        }
      } catch (e) {
        printError('Failed to save output to "${argResults['write']}": $e');
      }
    }
  }

  List<File> _collectDartFiles(Directory dir, List<File> collected, {FileFilter exclude}) {
    // Bail out in case of a .dartignore.
    if (FileSystemEntity.isFileSync(path.join(path.dirname(dir.path), '.dartignore')))
      return collected;

    for (FileSystemEntity entity in dir.listSync(recursive: false, followLinks: false)) {
      if (isDartFile(entity) && (exclude == null || !exclude(entity)))
        collected.add(entity);
      if (entity is Directory) {
        String name = path.basename(entity.path);
        if (!name.startsWith('.') && name != 'packages')
          _collectDartFiles(entity, collected, exclude: exclude);
      }
    }

    return collected;
  }


  String analysisTarget;
  bool firstAnalysis = true;
  Set<String> analyzedPaths = new Set<String>();
  Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
  Stopwatch analysisTimer;
  int lastErrorCount = 0;
  Status analysisStatus;

  Future<int> _analyzeWatch() async {
    List<String> directories;

    if (argResults['flutter-repo']) {
      directories = runner.getRepoAnalysisEntryPoints().map((Directory dir) => dir.path).toList();
      analysisTarget = 'Flutter repository';
      printTrace('Analyzing Flutter repository:');
      for (String projectPath in directories)
        printTrace('  ${path.relative(projectPath)}');
    } else {
      directories = <String>[Directory.current.path];
      analysisTarget = Directory.current.path;
    }

    AnalysisServer server = new AnalysisServer(dartSdkPath, directories);
    server.onAnalyzing.listen((bool isAnalyzing) => _handleAnalysisStatus(server, isAnalyzing));
    server.onErrors.listen(_handleAnalysisErrors);

    Cache.releaseLockEarly();

    await server.start();
    final int exitCode = await server.onExit;

    printStatus('Analysis server exited with code $exitCode.');
    return 0;
  }

  void _handleAnalysisStatus(AnalysisServer server, bool isAnalyzing) {
    if (isAnalyzing) {
      analysisStatus?.cancel();
      if (!firstAnalysis)
        printStatus('\n');
      analysisStatus = logger.startProgress('Analyzing $analysisTarget...');
      analyzedPaths.clear();
      analysisTimer = new Stopwatch()..start();
    } else {
      analysisStatus?.stop(showElapsedTime: true);
      analysisTimer.stop();

      logger.printStatus(terminal.clearScreen(), newline: false);

      // Remove errors for deleted files, sort, and print errors.
      final List<AnalysisError> errors = <AnalysisError>[];
      for (String path in analysisErrors.keys.toList()) {
        if (FileSystemEntity.isFileSync(path)) {
          errors.addAll(analysisErrors[path]);
        } else {
          analysisErrors.remove(path);
        }
      }

      errors.sort();

      for (AnalysisError error in errors) {
        printStatus(error.toString());
        if (error.code != null)
          printTrace('error code: ${error.code}');
      }

      _dumpErrors(errors.map/*<String>*/((AnalysisError error) => error.toLegacyString()));

      // Print an analysis summary.
      String errorsMessage;

      int issueCount = errors.length;
      int issueDiff = issueCount - lastErrorCount;
      lastErrorCount = issueCount;

      if (firstAnalysis)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found';
      else if (issueDiff > 0)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found ($issueDiff new)';
      else if (issueDiff < 0)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found (${-issueDiff} fixed)';
      else if (issueCount != 0)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found';
      else
        errorsMessage = 'no issues found';

      String files = '${analyzedPaths.length} ${pluralize('file', analyzedPaths.length)}';
      String seconds = (analysisTimer.elapsedMilliseconds / 1000.0).toStringAsFixed(2);
      printStatus('$errorsMessage • analyzed $files, $seconds seconds');

      if (firstAnalysis && _isBenchmarking) {
        _writeBenchmark(analysisTimer, issueCount, -1); // TODO(ianh): track members missing dartdocs instead of saying -1
        server.dispose().then((_) => exit(issueCount > 0 ? 1 : 0));
      }

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

  void _writeBenchmark(Stopwatch stopwatch, int errorCount, int membersMissingDocumentation) {
    final String benchmarkOut = 'analysis_benchmark.json';
    Map<String, dynamic> data = <String, dynamic>{
      'time': (stopwatch.elapsedMilliseconds / 1000.0),
      'issues': errorCount,
      'missingDartDocs': membersMissingDocumentation
    };
    new File(benchmarkOut).writeAsStringSync(toPrettyJson(data));
    printStatus('Analysis benchmark written to $benchmarkOut ($data).');
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
    assert(path.isAbsolute(Cache.flutterRoot));
    for (List<String> targetSources in values.values) {
      for (String source in targetSources) {
        assert(path.isAbsolute(source));
        if (path.isWithin(Cache.flutterRoot, source))
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
        // Fields are 'code', 'message', and 'stackTrace'.
        Map<String, dynamic> error = response['error'];
        printError('Error response from the server: ${error['code']} ${error['message']}');
        if (error['stackTrace'] != null)
          printError(error['stackTrace']);
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

  void _handleServerError(Map<String, dynamic> error) {
    // Fields are 'isFatal', 'message', and 'stackTrace'.
    printError('Error from the analysis server: ${error['message']}');
    if (error['stackTrace'] != null)
      printError(error['stackTrace']);
  }

  void _handleAnalysisIssues(Map<String, dynamic> issueInfo) {
    // {"event":"analysis.errors","params":{"file":"/Users/.../lib/main.dart","errors":[]}}
    String file = issueInfo['file'];
    List<AnalysisError> errors = issueInfo['errors'].map((Map<String, dynamic> json) => new AnalysisError(json)).toList();
    _errorsController.add(new FileAnalysisErrors(file, errors));
  }

  Future<bool> dispose() async {
    await _analyzingController.close();
    await _errorsController.close();
    return _process?.kill();
  }
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
    return '${severity.toLowerCase().padLeft(7)} • $message • $relativePath:$startLine:$startColumn';
  }

  String toLegacyString() {
    return '[${severity.toLowerCase()}] $message ($file:$startLine:$startColumn)';
  }
}
