// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/common.dart';
import '../base/file_system.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../cache.dart';

class MigrateUtils {

  MigrateUtils();

  static Future<Directory> createTempDirectory(String name) async {
    ProcessResult result = await Process.run('mktemp', ['-d', '-t', name]);
    checkForErrors(result);
    return globals.fs.directory((result.stdout as String).trim());
  }

  static Future<DiffResult> diffFiles(File one, File two, {String? outputPath}) async {
    if (one.existsSync() && !two.existsSync()) {
      return DiffResult.deletion();
    }
    if (!one.existsSync() && two.existsSync()) {
      return DiffResult.addition();
    }
    String gitCmd = '';
    if (outputPath != null) {
      String parentDirPath = outputPath.substring(0, outputPath.lastIndexOf('/'));
      gitCmd += 'mkdir -p "$parentDirPath" && touch "$outputPath"; ';
    }
    gitCmd += 'git diff --no-index "${one.absolute.path}" "${two.absolute.path}"';
    if (outputPath != null) {
      gitCmd += ' > "$outputPath"';
    }
    List<String> cmdArgs = ['-c', '$gitCmd'];
    final ProcessResult result = await Process.run('bash', cmdArgs);

    checkForErrors(result, allowedExitCodes: <int>[1]); // diff exits with 1 if diffs are found.
    return DiffResult(result, outputPath);
  }

  static Future<void> gitApply({required File diff, required String workingDirectory}) async {
    List<String> cmdArgs = ['apply', diff.absolute.path];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result);
  }

  static Future<void> cloneFlutter(String revision, String destination) async {
    // Use https url instead of ssh to avoid need to setup ssh on git.
    List<String> cmdArgs = ['clone', 'https://github.com/flutter/flutter.git', destination];
    print('Cloning old revision flutter');
    ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result);
    print('Done Cloning old revision flutter to $destination');

    cmdArgs.clear();
    cmdArgs = <String>['reset', '--hard', revision];
    result = await Process.run('git', cmdArgs, workingDirectory: destination);
    checkForErrors(result);
  }

  static Future<String> createFromTemplates(String flutterBinPath, {
    required String name,
    required String androidLanguage,
    required String iosLanguage,
    String? outputDirectory,
    List<String> platforms = const <String>[],
  }) async {
     List<String> cmdArgs = ['create', '--project-name', name];
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
    if (outputDirectory != null) {
      cmdArgs.add(outputDirectory);
    }
    print('CREATING');
    final ProcessResult result = await Process.run('./flutter', cmdArgs, workingDirectory: flutterBinPath);
    checkForErrors(result);
    print('CREATING DONE: $outputDirectory');
    return result.stdout;
  }

  static Future<MergeResult> gitMergeFile({required String ancestor, required String current, required String other}) async {
    print('  git Merging');
    List<String> cmdArgs = ['merge-file', '-p', current, ancestor, other];
    final ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result, allowedExitCodes: <int>[-1]);
    return MergeResult(result);
  }

  static Future<String> getGitHash(String projectPath, [String tag = 'HEAD']) async {
    List<String> cmdArgs = ['rev-parse', tag];
    ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: projectPath);
    checkForErrors(result);
    return result.stdout;
  }

 static Future<void> gitInit(String workingDirectory) async {
    List<String> cmdArgs = ['init'];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, allowedExitCodes: <int>[0]);
 }

  static Future<bool> isGitIgnored(String filePath, String workingDirectory) async {
    List<String> cmdArgs = ['check-ignore', filePath];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result, allowedExitCodes: <int>[0, 1, 128]);
    return result.exitCode == 0;
  }

  static void deleteTempDirectories({List<String> paths = const <String>[], List<Directory> directories = const <Directory>[]}) {
    for (Directory d in directories) {
      d.deleteSync(recursive: true);
    }
    for (String p in paths) {
      globals.fs.directory(p).deleteSync(recursive: true);
    }
  }

  static checkForErrors(ProcessResult result, {List<int> allowedExitCodes = const <int>[]}) {
    // -1 in allowed exit codes means all exit codes are valid.
    if ((result.exitCode != 0 && !allowedExitCodes.contains(result.exitCode)) && !allowedExitCodes.contains(-1)) {
      globals.printError('Git command encountered an error. Stdout:');
      globals.printStatus(result.stdout as String);
      globals.printError('Stderr:');
      globals.printError(result.stderr as String);
      throwToolExit('Git command failed with exit code ${result.exitCode}', exitCode: result.exitCode);
    }
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
  MergeResult(ProcessResult result) :
    mergedContents = result.stdout as String,
    hasConflict = result.exitCode != 0,
    exitCode = result.exitCode;

  MergeResult.explicit({
    required this.mergedContents,
    required this.hasConflict,
    required this.exitCode
  });

  String mergedContents;
  bool hasConflict;
  int exitCode;
}
