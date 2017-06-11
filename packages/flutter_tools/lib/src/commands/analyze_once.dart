// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart' as yaml;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../dart/analysis.dart';
import '../globals.dart';
import 'analyze.dart';
import 'analyze_base.dart';

bool isDartFile(FileSystemEntity entry) => entry is File && entry.path.endsWith('.dart');

typedef bool FileFilter(FileSystemEntity entity);

/// An aspect of the [AnalyzeCommand] to perform once time analysis.
class AnalyzeOnce extends AnalyzeBase {
  AnalyzeOnce(ArgResults argResults, this.repoPackages, { this.workingDirectory }) : super(argResults);

  final List<Directory> repoPackages;

  /// The working directory for testing analysis using dartanalyzer
  final Directory workingDirectory;

  /// Packages whose source is defined in the vended SDK. 
  static const List<String> _vendedSdkPackages = const <String>['analyzer', 'front_end', 'kernel'];

  @override
  Future<Null> analyze() async {
    final Stopwatch stopwatch = new Stopwatch()..start();
    final Set<Directory> pubSpecDirectories = new HashSet<Directory>();
    final List<File> dartFiles = <File>[];
    for (String file in argResults.rest.toList()) {
      file = fs.path.normalize(fs.path.absolute(file));
      final String root = fs.path.rootPrefix(file);
      dartFiles.add(fs.file(file));
      while (file != root) {
        file = fs.path.dirname(file);
        if (fs.isFileSync(fs.path.join(file, 'pubspec.yaml'))) {
          pubSpecDirectories.add(fs.directory(file));
          break;
        }
      }
    }

    final bool currentPackage = argResults['current-package'] && (argResults.wasParsed('current-package') || dartFiles.isEmpty);
    final bool flutterRepo = argResults['flutter-repo'] || (workingDirectory == null && inRepo(argResults.rest));

    // Use dartanalyzer directly except when analyzing the Flutter repository.
    // Analyzing the repository requires a more complex report than dartanalyzer
    // currently supports (e.g. missing member dartdoc summary).
    // TODO(danrubel): enhance dartanalyzer to provide this type of summary
    if (!flutterRepo) {
      if (argResults['dartdocs'])
        throwToolExit('The --dartdocs option is currently only supported with --flutter-repo.');

      final List<String> arguments = <String>[];
      arguments.addAll(dartFiles.map((FileSystemEntity f) => f.path));

      if (arguments.isEmpty || currentPackage) {
        // workingDirectory is non-null only when testing flutter analyze
        final Directory currentDirectory = workingDirectory ?? fs.currentDirectory.absolute;
        final Directory projectDirectory = await projectDirectoryContaining(currentDirectory);
        if (projectDirectory != null) {
          arguments.add(projectDirectory.path);
        } else if (arguments.isEmpty) {
          arguments.add(currentDirectory.path);
        }
      }

      // If the files being analyzed are outside of the current directory hierarchy
      // then dartanalyzer does not yet know how to find the ".packages" file.
      // TODO(danrubel): fix dartanalyzer to find the .packages file
      final File packagesFile = await packagesFileFor(arguments);
      if (packagesFile != null) {
        arguments.insert(0, '--packages');
        arguments.insert(1, packagesFile.path);
      }

      final String dartanalyzer = fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dartanalyzer');
      arguments.insert(0, dartanalyzer);
      bool noErrors = false;
      final Set<String> issues = new Set<String>();
      int exitCode = await runCommandAndStreamOutput(
          arguments,
          workingDirectory: workingDirectory?.path,
          mapFunction: (String line) {
            // De-duplicate the dartanalyzer command output (https://github.com/dart-lang/sdk/issues/25697).
            if (line.startsWith('  ')) {
              if (!issues.add(line.trim()))
                return null;
            }

            // Workaround for the fact that dartanalyzer does not exit with a non-zero exit code
            // when errors are found.
            // TODO(danrubel): Fix dartanalyzer to return non-zero exit code
            if (line == 'No issues found!')
              noErrors = true;

            // Remove text about the issue count ('2 hints found.'); with the duplicates
            // above, the printed count would be incorrect.
            if (line.endsWith(' found.'))
              return null;

            return line;
          },
      );
      stopwatch.stop();
      if (issues.isNotEmpty)
        printStatus('${issues.length} ${pluralize('issue', issues.length)} found.');
      final String elapsed = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(1);
      // Workaround for the fact that dartanalyzer does not exit with a non-zero exit code
      // when errors are found.
      // TODO(danrubel): Fix dartanalyzer to return non-zero exit code
      if (exitCode == 0 && !noErrors)
        exitCode = 1;
      if (exitCode != 0)
        throwToolExit('(Ran in ${elapsed}s)', exitCode: exitCode);
      printStatus('Ran in ${elapsed}s');
      return;
    }

    for (Directory dir in repoPackages) {
      _collectDartFiles(dir, dartFiles);
      pubSpecDirectories.add(dir);
    }

    // determine what all the various .packages files depend on
    final PackageDependencyTracker dependencies = new PackageDependencyTracker();
    for (Directory directory in pubSpecDirectories) {
      final String pubSpecYamlPath = fs.path.join(directory.path, 'pubspec.yaml');
      final File pubSpecYamlFile = fs.file(pubSpecYamlPath);
      if (pubSpecYamlFile.existsSync()) {
        // we are analyzing the actual canonical source for this package;
        // make sure we remember that, in case all the packages are actually
        // pointing elsewhere somehow.
        final yaml.YamlMap pubSpecYaml = yaml.loadYaml(fs.file(pubSpecYamlPath).readAsStringSync());
        final String packageName = pubSpecYaml['name'];
        final String packagePath = fs.path.normalize(fs.path.absolute(fs.path.join(directory.path, 'lib')));
        dependencies.addCanonicalCase(packageName, packagePath, pubSpecYamlPath);
      }
      final String dotPackagesPath = fs.path.join(directory.path, '.packages');
      final File dotPackages = fs.file(dotPackagesPath);
      if (dotPackages.existsSync()) {
        // this directory has opinions about what we should be using
        dotPackages
          .readAsStringSync()
          .split('\n')
          .where((String line) => !line.startsWith(new RegExp(r'^ *#')))
          .forEach((String line) {
            final int colon = line.indexOf(':');
            if (colon > 0) {
              final String packageName = line.substring(0, colon);
              final String packagePath = fs.path.fromUri(line.substring(colon+1));
              // Ensure that we only add `analyzer` and dependent packages defined in the vended SDK (and referred to with a local 
              // fs.path. directive). Analyzer package versions reached via transitive dependencies (e.g., via `test`) are ignored 
              // since they would produce spurious conflicts.
              if (!_vendedSdkPackages.contains(packageName) || packagePath.startsWith('..'))
                dependencies.add(packageName, fs.path.normalize(fs.path.absolute(directory.path, packagePath)), dotPackagesPath);
            }
        });
      }
    }

    // prepare a union of all the .packages files
    if (dependencies.hasConflicts) {
      final StringBuffer message = new StringBuffer();
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
    final Map<String, String> packages = dependencies.asPackageMap();

    Cache.releaseLockEarly();

    if (argResults['preamble']) {
      if (dartFiles.length == 1) {
        logger.printStatus('Analyzing ${fs.path.relative(dartFiles.first.path)}...');
      } else {
        logger.printStatus('Analyzing ${dartFiles.length} files...');
      }
    }
    final DriverOptions options = new DriverOptions();
    options.dartSdkPath = argResults['dart-sdk'];
    options.packageMap = packages;
    options.analysisOptionsFile = fs.path.join(Cache.flutterRoot, '.analysis_options_repo');
    final AnalysisDriver analyzer = new AnalysisDriver(options);

    // TODO(pq): consider error handling
    final List<AnalysisErrorDescription> errors = analyzer.analyze(dartFiles);

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
    final String elapsed = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(1);

    if (isBenchmarking)
      writeBenchmark(stopwatch, errorCount, membersMissingDocumentation);

    if (errorCount > 0) {
      // we consider any level of error to be an error exit (we don't report different levels)
      if (membersMissingDocumentation > 0)
        throwToolExit('[lint] $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation (ran in ${elapsed}s)');
      else
        throwToolExit('(Ran in ${elapsed}s)');
    }
    if (argResults['congratulate']) {
      if (membersMissingDocumentation > 0) {
        printStatus('No analyzer warnings! (ran in ${elapsed}s; $membersMissingDocumentation public ${ membersMissingDocumentation == 1 ? "member lacks" : "members lack" } documentation)');
      } else {
        printStatus('No analyzer warnings! (ran in ${elapsed}s)');
      }
    }
  }

  /// Return a path to the ".packages" file for use by dartanalyzer when analyzing the specified files.
  /// Report an error if there are file paths that belong to different projects.
  Future<File> packagesFileFor(List<String> filePaths) async {
    String projectPath = await projectPathContaining(filePaths.first);
    if (projectPath != null) {
      if (projectPath.endsWith(fs.path.separator))
        projectPath = projectPath.substring(0, projectPath.length - 1);
      final String projectPrefix = projectPath + fs.path.separator;
      // Assert that all file paths are contained in the same project directory
      for (String filePath in filePaths) {
        if (!filePath.startsWith(projectPrefix) && filePath != projectPath)
          throwToolExit('Files in different projects cannot be analyzed at the same time.\n'
              '  Project: $projectPath\n  File outside project:  $filePath');
      }
    } else {
      // Assert that all file paths are not contained in any project
      for (String filePath in filePaths) {
        final String otherProjectPath = await projectPathContaining(filePath);
        if (otherProjectPath != null)
          throwToolExit('Files inside a project cannot be analyzed at the same time as files not in any project.\n'
              '  File inside a project: $filePath');
      }
    }

    if (projectPath == null)
      return null;
    final File packagesFile = fs.file(fs.path.join(projectPath, '.packages'));
    return await packagesFile.exists() ? packagesFile : null;
  }

  Future<String> projectPathContaining(String targetPath) async {
    final FileSystemEntity target = await fs.isDirectory(targetPath) ? fs.directory(targetPath) : fs.file(targetPath);
    final Directory projectDirectory = await projectDirectoryContaining(target);
    return projectDirectory?.path;
  }

  Future<Directory> projectDirectoryContaining(FileSystemEntity entity) async {
    Directory dir = entity is Directory ? entity : entity.parent;
    dir = dir.absolute;
    while (!await dir.childFile('pubspec.yaml').exists()) {
      final Directory parent = dir.parent;
      if (parent == null || parent.path == dir.path)
        return null;
      dir = parent;
    }
    return dir;
  }

  List<String> flutterRootComponents;
  bool isFlutterLibrary(String filename) {
    flutterRootComponents ??= fs.path.normalize(fs.path.absolute(Cache.flutterRoot)).split(fs.path.separator);
    final List<String> filenameComponents = fs.path.normalize(fs.path.absolute(filename)).split(fs.path.separator);
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
    if (fs.isFileSync(fs.path.join(dir.path, '.dartignore')))
      return collected;

    for (FileSystemEntity entity in dir.listSync(recursive: false, followLinks: false)) {
      if (isDartFile(entity))
        collected.add(entity);
      if (entity is Directory) {
        final String name = fs.path.basename(entity.path);
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
    assert(fs.path.isAbsolute(Cache.flutterRoot));
    for (List<String> targetSources in values.values) {
      for (String source in targetSources) {
        assert(fs.path.isAbsolute(source));
        if (fs.path.isWithin(Cache.flutterRoot, source))
          return true;
      }
    }
    return false;
  }
  void describeConflict(StringBuffer result) {
    assert(hasConflict);
    final List<String> targets = values.keys.toList();
    targets.sort((String a, String b) => values[b].length.compareTo(values[a].length));
    for (String target in targets) {
      final int count = values[target].length;
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
    final StringBuffer result = new StringBuffer();
    for (String package in packages.keys.where((String package) => packages[package].hasConflict)) {
      result.writeln('Package "$package" has conflicts:');
      packages[package].describeConflict(result);
    }
    return result.toString();
  }

  Map<String, String> asPackageMap() {
    final Map<String, String> result = <String, String>{};
    for (String package in packages.keys)
      result[package] = packages[package].target;
    return result;
  }
}
