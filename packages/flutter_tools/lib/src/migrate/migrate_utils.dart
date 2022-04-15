// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';

/// The default name of the migrate working directory used to stage proposed changes.
const String kDefaultMigrateWorkingDirectoryName = 'migrate_working_dir';

/// Utility class that contains static methods that wrap git and other shell commands.
class MigrateUtils {
  MigrateUtils();

  /// Calls `git diff` on two files and returns the diff as a DiffResult.
  static Future<DiffResult> diffFiles(File one, File two, Logger logger) async {
    if (one.existsSync() && !two.existsSync()) {
      return DiffResult.deletion();
    }
    if (!one.existsSync() && two.existsSync()) {
      return DiffResult.addition();
    }
    final List<String> cmdArgs = <String>['diff', '--no-index', one.absolute.path, two.absolute.path];
    final ProcessResult result = await Process.run('git', cmdArgs);

    // diff exits with 1 if diffs are found.
    checkForErrors(result, logger, allowedExitCodes: <int>[1], commandDescription: 'git ${cmdArgs.join(' ')}');
    return DiffResult(result);
  }

  // Clones a copy of the flutter repo into the destination directory. Returns false if unsucessful.
  static Future<bool> cloneFlutter(String revision, String destination, String flutterDirectory, Logger logger) async {
    // Use https url instead of ssh to avoid need to setup ssh on git.
    List<String> cmdArgs = <String>['clone', '--single-branch', '--filter=blob:none', '--shallow-exclude=v1.0.0', 'https://github.com/flutter/flutter.git', destination];
    ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result, logger, commandDescription: 'git ${cmdArgs.join(' ')}');

    cmdArgs.clear();
    cmdArgs = <String>['reset', '--hard', revision];
    result = await Process.run('git', cmdArgs, workingDirectory: destination);
    if (!checkForErrors(result, logger, commandDescription: 'git ${cmdArgs.join(' ')}', exit: false)) {
      return false;
    }
    return true;
  }

  /// Calls `flutter create` as a re-entrant command.
  static Future<String> createFromTemplates(String flutterBinPath, {
    required String name,
    bool legacyNameParameter = false,
    required String androidLanguage,
    required String iosLanguage,
    required String outputDirectory,
    String? createVersion,
    List<String> platforms = const <String>[],
    required Logger logger,
    required FileSystem fileSystem,
  }) async {
    final List<String> cmdArgs = <String>['create'];
    if (!legacyNameParameter) {
      cmdArgs.add('--project-name=$name');
    }
    cmdArgs.add('--android-language=$androidLanguage');
    cmdArgs.add('--ios-language=$iosLanguage');
    if (platforms.isNotEmpty) {
      String platformsArg = '--platforms=';
      for (int i = 0; i < platforms.length; i++) {
        if (i > 0) {
          platformsArg += ',';
        }
        platformsArg += platforms[i];
      }
      cmdArgs.add(platformsArg);
    }
    cmdArgs.add('--no-pub');
    if (legacyNameParameter) {
      cmdArgs.add(name);
    } else {
      cmdArgs.add(outputDirectory);
    }
    final ProcessResult result = await Process.run('$flutterBinPath/flutter', cmdArgs, workingDirectory: outputDirectory);
    final String error = result.stderr as String;

    // Catch errors due to parameters not existing.

    // Old versions of the tool does not include the platforms option.
    if (error.contains('Could not find an option named "platforms".')) {
      return createFromTemplates(
        flutterBinPath,
        name: name,
        legacyNameParameter: legacyNameParameter,
        androidLanguage: androidLanguage,
        iosLanguage: iosLanguage,
        outputDirectory: outputDirectory,
        logger: logger,
        fileSystem: fileSystem,
      );
    }
    // Old versions of the tool does not include the project-name option.
    if ((result.stderr as String).contains('Could not find an option named "project-name".')) {
      return createFromTemplates(
        name: name,
        legacyNameParameter: true,
        flutterBinPath,
        androidLanguage: androidLanguage,
        iosLanguage: iosLanguage,
        outputDirectory: outputDirectory,
        platforms: platforms,
        logger: logger,
        fileSystem: fileSystem,
      );
    }
    if (error.contains('Multiple output directories specified.')) {
      if (error.contains('Try moving --platforms')) {
        return createFromTemplates(
          flutterBinPath,
          name: name,
          legacyNameParameter: legacyNameParameter,
          androidLanguage: androidLanguage,
          iosLanguage: iosLanguage,
          outputDirectory: outputDirectory,
          logger: logger,
          fileSystem: fileSystem,
        );
      }
    }
    checkForErrors(result, logger, commandDescription: '${flutterBinPath}flutter ${cmdArgs.join(' ')}', silent: true);

    if (legacyNameParameter) {
      return fileSystem.path.join(outputDirectory, name);
    }
    return outputDirectory;
  }

  /// Runs the git 3-way merge on three files and returns the results as a MergeResult.
  ///
  /// Passing the same path for base and current will perform a two-way fast forward merge.
  static Future<MergeResult> gitMergeFile({
    required String base,
    required String current,
    required String target,
    required String localPath,
    required Logger logger
  }) async {
    final List<String> cmdArgs = <String>['merge-file', '-p', current, base, target];
    final ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result, logger, allowedExitCodes: <int>[-1], commandDescription: 'git ${cmdArgs.join(' ')}');
    return MergeResult(result, localPath);
  }

  /// Calls `git init` on the workingDirectory.
  static Future<void> gitInit(String workingDirectory, Logger logger) async {
    final List<String> cmdArgs = <String>['init'];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, logger, allowedExitCodes: <int>[0], commandDescription: 'git ${cmdArgs.join(' ')}');
  }

  /// Returns true if the workingDirectory git repo has any uncommited changes.
  static Future<bool> hasUncommitedChanges(String workingDirectory, Logger logger) async {
    final List<String> cmdArgs = <String>['diff', '--quiet', 'HEAD', '--', '.', "':(exclude)$kDefaultMigrateWorkingDirectoryName'"];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, logger, allowedExitCodes: <int>[-1], commandDescription: 'git ${cmdArgs.join(' ')}');
    if (result.exitCode == 0) {
      return false;
    }
    return true;
  }

  /// Returns true if the workingDirectory is a git repo.
  static Future<bool> isGitRepo(String workingDirectory, Logger logger) async {
    final List<String> cmdArgs = <String>['rev-parse', '--is-inside-work-tree'];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, logger, allowedExitCodes: <int>[-1], commandDescription: 'git ${cmdArgs.join(' ')}');
    if (result.exitCode == 0) {
      return true;
    }
    return false;
  }

  /// Returns true if the file at `filePath` is covered by the `.gitignore`
  static Future<bool> isGitIgnored(String filePath, String workingDirectory, Logger logger) async {
    final List<String> cmdArgs = <String>['check-ignore', filePath];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, logger, allowedExitCodes: <int>[0, 1, 128], commandDescription: 'git ${cmdArgs.join(' ')}');
    return result.exitCode == 0;
  }

  /// Runs `flutter pub upgrate --major-revisions`.
  static Future<void> flutterPubUpgrade(String workingDirectory, Logger logger) async {
    final List<String> cmdArgs = <String>['pub', 'upgrade', '--major-versions'];
    final ProcessResult result = await Process.run('flutter', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, logger, allowedExitCodes: <int>[0], commandDescription: 'flutter ${cmdArgs.join(' ')}');
  }

  /// Runs `./gradlew tasks` in the android directory of a flutter project.
  static Future<void> gradlewTasks(String workingDirectory, Logger logger) async {
    final String baseCommand = Platform.isWindows ? 'gradlew.bat' : './gradlew';
    final List<String> cmdArgs = <String>['tasks'];
    final ProcessResult result = await Process.run(baseCommand, cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, logger, allowedExitCodes: <int>[0], commandDescription: '$baseCommand ${cmdArgs.join(' ')}');
  }

  /// Verifies that the ProcessResult does not contain an error.
  ///
  /// If an error is detected, the error can be optionally logged or exit the tool.
  static bool checkForErrors(
    ProcessResult result,
    Logger logger, {
    List<int> allowedExitCodes = const <int>[],
    String? commandDescription,
    bool exit = true,
    bool silent = false
  }) {
    // -1 in allowed exit codes means all exit codes are valid.
    if ((result.exitCode != 0 && !allowedExitCodes.contains(result.exitCode)) && !allowedExitCodes.contains(-1)) {
      if (!silent) {
        logger.printError('Command encountered an error with exit code ${result.exitCode}.');
        if (commandDescription != null) {
          logger.printError('Command:');
          logger.printError(commandDescription, indent: 2);
        }
        logger.printError('Stdout:');
        logger.printStatus(result.stdout as String, indent: 2);
        logger.printError('Stderr:');
        logger.printError(result.stderr as String, indent: 2);
      }
      if (exit) {
        throwToolExit('Command failed with exit code ${result.exitCode}', exitCode: result.exitCode);
      }
      return false;
    }
    return true;
  }

  /// Returns true if the file does not contain any git conflit markers.
  static bool conflictsResolved(String contents) {
    if (contents.contains('>>>>>>>') || contents.contains('=======') || contents.contains('<<<<<<<')) {
      return false;
    }
    return true;
  }
}

/// Tracks the output of a git diff command or any special cases such as addition of a new
/// file or deletion of an existing file.
class DiffResult {
  DiffResult(ProcessResult result) :
    diff = result.stdout as String,
    isDeletion = false,
    isAddition = false,
    isIgnored = false,
    exitCode = result.exitCode;

  /// Creates a DiffResult that represents a newly added file.
  DiffResult.addition() :
    diff = '',
    isDeletion = false,
    isAddition = true,
    isIgnored = false,
    exitCode = 0;

  /// Creates a DiffResult that represents a deleted file.
  DiffResult.deletion() :
    diff = '',
    isDeletion = true,
    isAddition = false,
    isIgnored = false,
    exitCode = 0;

  /// Creates a DiffResult that represents an ignored file.
  DiffResult.ignored() :
    diff = '',
    isDeletion = false,
    isAddition = false,
    isIgnored = true,
    exitCode = 0;

  /// The diff string output by git.
  final String diff;

  final bool isDeletion;
  final bool isAddition;
  final bool isIgnored;

  /// The exitcode of the command. This is zero when no diffs are found.
  final int exitCode;
}

/// Data class to hold the results of a merge.
class MergeResult {
  /// Initializes a MergeResult based off of a ProcessResult.
  MergeResult(ProcessResult result, this.localPath) :
    mergedString = result.stdout as String,
    hasConflict = result.exitCode != 0,
    exitCode = result.exitCode;

  /// Manually initializes a MergeResult with explicit values.
  MergeResult.explicit({
    this.mergedString,
    this.mergedBytes,
    required this.hasConflict,
    required this.exitCode,
    required this.localPath,
  }) : assert(mergedString == null && mergedBytes != null || mergedString != null && mergedBytes == null);

  /// The final merged string.
  String? mergedString;

  /// If the file was a binary file, then this field is non-null while mergedString is null.
  Uint8List? mergedBytes;

  /// True when there is a merge conflict.
  bool hasConflict;

  /// The exitcode of the merge command.
  int exitCode;

  /// The local path relative to the project root of the file.
  String localPath;
}
