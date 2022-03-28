// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../commands/migrate.dart';
import '../globals.dart' as globals;

// TODO(garyq): support windows.

/// Utility class that contains static methods that wrap git and other shell commands.
class MigrateUtils {
  MigrateUtils();

  /// Creates a temporary directory.
  ///
  /// This directory should be deleted after use.
  static Future<Directory> createTempDirectory(String name) async {
    final ProcessResult result = await Process.run('mktemp', <String>['-d', '-t', name]);
    checkForErrors(result);
    final Directory dir = globals.fs.directory((result.stdout as String).trim());
    dir.createSync(recursive: true);
    return dir;
  }

  /// Calls `git diff` on two files and returns the diff as a DiffResult.
  static Future<DiffResult> diffFiles(File one, File two, {String? outputPath}) async {
    if (one.existsSync() && !two.existsSync()) {
      return DiffResult.deletion();
    }
    if (!one.existsSync() && two.existsSync()) {
      return DiffResult.addition();
    }
    String gitCmd = '';
    if (outputPath != null) {
      final String parentDirPath = outputPath.substring(0, outputPath.lastIndexOf('/'));
      gitCmd += 'mkdir -p "$parentDirPath" && touch "$outputPath"; ';
    }
    gitCmd += 'git diff --no-index "${one.absolute.path}" "${two.absolute.path}"';
    if (outputPath != null) {
      gitCmd += ' > "$outputPath"';
    }
    final List<String> cmdArgs = <String>['-c', gitCmd];
    final ProcessResult result = await Process.run('bash', cmdArgs);

    // diff exits with 1 if diffs are found.
    checkForErrors(result, allowedExitCodes: <int>[1], commandDescription: 'git ${cmdArgs.join(' ')}');
    return DiffResult(result, outputPath);
  }

  // Clones a copy of the flutter repo into the destination directory. Returns false if unsucessful.
  static Future<bool> cloneFlutter(String revision, String destination) async {
    // Use https url instead of ssh to avoid need to setup ssh on git.
    List<String> cmdArgs = <String>['clone', 'https://github.com/flutter/flutter.git', destination];
    ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result, commandDescription: 'git ${cmdArgs.join(' ')}', silent: true);

    cmdArgs.clear();
    cmdArgs = <String>['reset', '--hard', revision];
    result = await Process.run('git', cmdArgs, workingDirectory: destination);
    if (!checkForErrors(result, commandDescription: 'git ${cmdArgs.join(' ')}', exit: false, silent: true)) {
      return false;
    }
    return true;
  }

  /// Calls `flutter create` as a re-entrant command.
  static Future<String> createFromTemplates(String flutterBinPath, {
    required String name,
    required String androidLanguage,
    required String iosLanguage,
    required String outputDirectory,
    String? createVersion,
    List<String> platforms = const <String>[],
  }) async {
    final List<String> cmdArgs = <String>['create', '--no-pub', '--project-name', name];
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
    cmdArgs.add(outputDirectory);
    final ProcessResult result = await Process.run('./flutter', cmdArgs, workingDirectory: flutterBinPath);
    // Old versions of the tool does not include the platforms option. In this case, we will just
    // just call the general create command.
    if ((result.stderr as String).contains('Could not find an option named "platforms".')) {
      return createFromTemplates(
        flutterBinPath,
        name: name,
        androidLanguage: androidLanguage,
        iosLanguage: iosLanguage,
        outputDirectory: outputDirectory,
      );
    }
    checkForErrors(result, commandDescription: '${flutterBinPath}flutter ${cmdArgs.join(' ')}');
    return result.stdout as String;
  }

  /// Runs the git 3-way merge on three files and returns the results as a MergeResult.
  ///
  /// Passing the same path for base and current will perform a two-way fast forward merge.
  static Future<MergeResult> gitMergeFile({
    required String base,
    required String current,
    required String target,
    required String localPath
  }) async {
    final List<String> cmdArgs = <String>['merge-file', '-p', current, base, target];
    final ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result, allowedExitCodes: <int>[-1], commandDescription: 'git ${cmdArgs.join(' ')}');
    return MergeResult(result, localPath);
  }

  /// Calls `git init` on the workingDirectory.
  static Future<void> gitInit(String workingDirectory) async {
    final List<String> cmdArgs = <String>['init'];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, allowedExitCodes: <int>[0], commandDescription: 'git ${cmdArgs.join(' ')}');
  }

  /// Returns true if the workingDirectory git repo has any uncommited changes.
  static Future<bool> hasUncommitedChanges(String workingDirectory) async {
    final List<String> cmdArgs = <String>['diff', '--quiet', 'HEAD', '--', '.', "':(exclude)$kDefaultMigrateWorkingDirectoryName'"];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, allowedExitCodes: <int>[-1], commandDescription: 'git ${cmdArgs.join(' ')}');
    if (result.exitCode == 0) {
      return false;
    }
    return true;
  }

  /// Returns true if the workingDirectory is a git repo.
  static Future<bool> isGitRepo(String workingDirectory) async {
    final List<String> cmdArgs = <String>['rev-parse', '--is-inside-work-tree'];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, allowedExitCodes: <int>[-1], commandDescription: 'git ${cmdArgs.join(' ')}');
    if (result.exitCode == 0) {
      return true;
    }
    return false;
  }

  /// Returns true if the file at `filePath` is covered by the `.gitignore`
  static Future<bool> isGitIgnored(String filePath, String workingDirectory) async {
    final List<String> cmdArgs = <String>['check-ignore', filePath];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, allowedExitCodes: <int>[0, 1, 128], commandDescription: 'git ${cmdArgs.join(' ')}');
    return result.exitCode == 0;
  }

  /// Deletes the files or directories at the provided paths.
  static void deleteTempDirectories({List<String> paths = const <String>[], List<Directory> directories = const <Directory>[]}) {
    for (final Directory d in directories) {
      d.deleteSync(recursive: true);
    }
    for (final String p in paths) {
      globals.fs.directory(p).deleteSync(recursive: true);
    }
  }

  static bool checkForErrors(ProcessResult result, {List<int> allowedExitCodes = const <int>[], String? commandDescription, bool exit = true, bool silent = false}) {
    // -1 in allowed exit codes means all exit codes are valid.
    if ((result.exitCode != 0 && !allowedExitCodes.contains(result.exitCode)) && !allowedExitCodes.contains(-1)) {
      if (!silent) {
        globals.printError('Command encountered an error with exit code ${result.exitCode}.');
        if (commandDescription != null) {
          globals.printError('Command:');
          globals.printError(commandDescription, indent: 2);
        }
        globals.printError('Stdout:');
        globals.printStatus(result.stdout as String, indent: 2);
        globals.printError('Stderr:');
        globals.printError(result.stderr as String, indent: 2);
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

  /// Prints a command to logger with appropriate formatting.
  static void printCommandText(String command, Logger logger) {
    logger.printStatus(
      '\n\$ $command\n',
      color: TerminalColor.grey,
      indent: 4,
      newline: false,
    );
  }
}

/// Tracks the output of a git diff command or any special cases such as addition of a new
/// file or deletion of an existing file.
class DiffResult {
  DiffResult(ProcessResult result, this.outputPath) :
    diff = result.stdout as String,
    isDeletion = false,
    isAddition = false,
    isIgnored = false,
    exitCode = result.exitCode;

  DiffResult.addition() :
    diff = '',
    isDeletion = false,
    isAddition = true,
    isIgnored = false,
    outputPath = null,
    exitCode = 0;

  DiffResult.deletion() :
    diff = '',
    isDeletion = true, 
    isAddition = false,
    isIgnored = false,
    outputPath = null,
    exitCode = 0;

  DiffResult.ignored() :
    diff = '',
    isDeletion = false, 
    isAddition = false,
    isIgnored = true,
    outputPath = null,
    exitCode = 0;

  final String diff;
  final bool isDeletion;
  final bool isAddition;
  final bool isIgnored;
  final String? outputPath;
  final int exitCode;
}

/// Data class to hold the 
class MergeResult {
  MergeResult(ProcessResult result, this.localPath) :
    mergedString = result.stdout as String,
    hasConflict = result.exitCode != 0,
    exitCode = result.exitCode;

  MergeResult.explicit({
    this.mergedString,
    this.mergedBytes,
    required this.hasConflict,
    required this.exitCode,
    required this.localPath,
  }) : assert(mergedString == null && mergedBytes != null || mergedString != null && mergedBytes == null);

  String? mergedString;
  Uint8List? mergedBytes;
  bool hasConflict;
  int exitCode;
  String localPath;
}
