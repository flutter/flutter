// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:args/args.dart';

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
    dependencies.checkForConflictingDependencies(pubSpecDirectories, dependencies);
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
