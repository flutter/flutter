// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import '../base/common.dart';
import '../base/file_system.dart';
import '../cache.dart';
import '../dart/analysis.dart';
import '../globals.dart';
import 'analyze.dart';
import 'analyze_base.dart';

bool isDartFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('.dart');

typedef bool FileFilter(FileSystemEntity entity);

/// An aspect of the [AnalyzeCommand] to perform once time analysis.
class AnalyzeOnce extends AnalyzeBase {
  final List<Directory> repoPackages;

  AnalyzeOnce(ArgResults argResults, this.repoPackages) : super(argResults);

  @override
  Future<Null> analyze() async {
    Stopwatch stopwatch = new Stopwatch()..start();
    Set<Directory> pubSpecDirectories = new HashSet<Directory>();
    List<File> dartFiles = <File>[];

    for (String file in argResults.rest.toList()) {
      file = path.normalize(path.absolute(file));
      String root = path.rootPrefix(file);
      dartFiles.add(fs.file(file));
      while (file != root) {
        file = path.dirname(file);
        if (fs.isFileSync(path.join(file, 'pubspec.yaml'))) {
          pubSpecDirectories.add(fs.directory(file));
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
      Directory currentDirectory = fs.directory('.');
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
      Directory currentDirectory = fs.directory('.');
      _collectDartFiles(currentDirectory, dartFiles);
      pubSpecDirectories.add(currentDirectory);
    }

    if (flutterRepo) {
      for (Directory dir in repoPackages) {
        _collectDartFiles(dir, dartFiles);
        pubSpecDirectories.add(dir);
      }
    }

    // determine what all the various .packages files depend on
    PackageDependencyTracker dependencies = new PackageDependencyTracker();
    for (Directory directory in pubSpecDirectories) {
      String pubSpecYamlPath = path.join(directory.path, 'pubspec.yaml');
      File pubSpecYamlFile = fs.file(pubSpecYamlPath);
      if (pubSpecYamlFile.existsSync()) {
        // we are analyzing the actual canonical source for this package;
        // make sure we remember that, in case all the packages are actually
        // pointing elsewhere somehow.
        yaml.YamlMap pubSpecYaml = yaml.loadYaml(fs.file(pubSpecYamlPath).readAsStringSync());
        String packageName = pubSpecYaml['name'];
        String packagePath = path.normalize(path.absolute(path.join(directory.path, 'lib')));
        dependencies.addCanonicalCase(packageName, packagePath, pubSpecYamlPath);
      }
      String dotPackagesPath = path.join(directory.path, '.packages');
      File dotPackages = fs.file(dotPackagesPath);
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
                dependencies.add(packageName, path.normalize(path.absolute(directory.path, packagePath)), dotPackagesPath);
            }
        });
      }
    }

    // prepare a union of all the .packages files
    if (dependencies.hasConflicts) {
      StringBuffer message = new StringBuffer();
      message.writeln(dependencies.generateConflictReport());
      message.writeln('Make sure you have run "pub upgrade" in all the directories mentioned above.');
      if (dependencies.hasConflictsAffectingFlutterRepo) {
        message.writeln(
            'For packages in the flutter repository, try using '
            '"flutter update-packages --upgrade" to do all of them at once.');
      }
      message.write(
          'If this does not help, to track down the conflict you can use '
          '"pub deps --style=list" and "pub upgrade --verbosity=solver" in the affected directories.');
      throwToolExit(message.toString());
    }
    Map<String, String> packages = dependencies.asPackageMap();

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
      if (shouldIgnore)
        continue;
      printError(error.asString());
      errorCount += 1;
    }
    dumpErrors(errors.map<String>((AnalysisErrorDescription error) => error.asString()));

    stopwatch.stop();
    String elapsed = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(1);

    if (isBenchmarking)
      writeBenchmark(stopwatch, errorCount, membersMissingDocumentation);

    if (errorCount > 0) {
      // we consider any level of error to be an error exit (we don't report different levels)
      if (membersMissingDocumentation > 0 && flutterRepo)
        throwToolExit('[lint] $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation (ran in ${elapsed}s)');
      else
        throwToolExit('(Ran in ${elapsed}s)');
    }
    if (argResults['congratulate']) {
      if (membersMissingDocumentation > 0 && flutterRepo) {
        printStatus('No analyzer warnings! (ran in ${elapsed}s; $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation)');
      } else {
        printStatus('No analyzer warnings! (ran in ${elapsed}s)');
      }
    }
  }

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

  List<File> _collectDartFiles(Directory dir, List<File> collected) {
    // Bail out in case of a .dartignore.
    if (fs.isFileSync(path.join(dir.path, '.dartignore')))
      return collected;

    for (FileSystemEntity entity in dir.listSync(recursive: false, followLinks: false)) {
      if (isDartFile(entity))
        collected.add(entity);
      if (entity is Directory) {
        String name = path.basename(entity.path);
        if (!name.startsWith('.') && name != 'packages')
          _collectDartFiles(entity, collected);
      }
    }

    return collected;
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
