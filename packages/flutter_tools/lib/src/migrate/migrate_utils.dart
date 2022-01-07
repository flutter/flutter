// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../cache.dart';

// git show 1980492997e27108451090ac53732c8c4caa1f39:packages/flutter_tools/templates/template_manifest.json
// git ls-tree --name-only -r 1980492997e27108451090ac53732c8c4caa1f39 packages/flutter_tools
// git ls-tree --name-only -r 1980492997e27108451090ac53732c8c4caa1f39 packages/flutter_tools

class MigrateUtils {

  MigrateUtils();

  static Future<List<String>> getFileNamesInDirectory({required String revision, required String searchPath, required String workingDirectory, bool recursive = true}) async {
    List<String> cmdArgs = ['ls-tree', '--name-only'];
    if (recursive) {
      cmdArgs.add('-r');
    }
    cmdArgs.add('$revision:$searchPath');
    ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result);
    List<String> files = <String>[];
    for (String filePath in result.stdout.split('\n')) {
      if (filePath != '') {
        files.add('$searchPath/$filePath');
      }
    }
    return files;
  }

  // If outputPath is included, the return string will be empty.
  static Future<String> getFileContents({required String revision, required String file, required String workingDirectory, String? outputPath}) async {
    // TODO(garyq): Make this work on non-unix hosts.
    String gitCmd = 'cd "$workingDirectory" && ';
    if (outputPath != null) {
      String parentDirPath = outputPath.substring(0, outputPath.lastIndexOf('/'));
      gitCmd += 'mkdir -p "$parentDirPath" && touch "$outputPath"; ';
    }
    gitCmd += 'git show "$revision:$file"';
    if (outputPath != null) {
      gitCmd += ' > "$outputPath"';
    }
    List<String> cmdArgs = ['-c', '$gitCmd'];
    ProcessResult result = await Process.run('bash', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result);
    return result.stdout as String;
  }

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
    ProcessResult result = await Process.run('bash', cmdArgs);

    // List<String> cmdArgs = ['diff', '--no-index', one.absolute.path, two.absolute.path];
    // ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result, allowedExitCodes: <int>[1]); // diff exits with 1 if diffs are found.
    return DiffResult(result, outputPath);
  }

  static Future<void> apply({required File diff, required String workingDirectory}) async {
    List<String> cmdArgs = ['apply', diff.absolute.path];
    ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
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

  static Future<String> createFromTemplates(String flutterBinPath, String name, {String? outputDirectory}) async {
     List<String> cmdArgs = ['create', '--project-name', name];
    if (outputDirectory != null) {
      cmdArgs.add(outputDirectory);
    }
    print('CREATING');
    ProcessResult result = await Process.run('./flutter', cmdArgs, workingDirectory: flutterBinPath);
    checkForErrors(result);
    print('CREATING DONE: $outputDirectory');
    return result.stdout;
  }

  static void deleteTempDirectories({List<String> paths = const <String>[], List<Directory> directories = const <Directory>[]}) {
    print('Deleting temp directories');
    for (Directory d in directories) {
      d.deleteSync(recursive: true);
    }
    for (String p in paths) {
      globals.fs.directory(p).deleteSync(recursive: true);
    }
  }

  static checkForErrors(ProcessResult result, {List<int> allowedExitCodes = const <int>[]}) {
    if (result.exitCode != 0 && !allowedExitCodes.contains(result.exitCode)) {
      globals.printError('Git command encountered an error. Stdout:');
      globals.printStatus(result.stdout as String);
      globals.printError('Stderr:');
      globals.printError(result.stderr as String);
      throwToolExit('Git command failed with exit code ${result.exitCode}', exitCode: result.exitCode);
    }
  } 

}

class DiffResult {
  DiffResult(ProcessResult result, this.outputPath) :
    diff = result.stdout as String,
    isDeletion = false,
    isAddition = false,
    exitCode = result.exitCode;

  DiffResult.addition() :
    diff = '',
    isDeletion = false,
    isAddition = true,
    outputPath = null,
    exitCode = 0;

  DiffResult.deletion() :
    diff = '',
    isDeletion = true, 
    isAddition = false,
    outputPath = null,
    exitCode = 0;

  String diff;
  bool isDeletion;
  bool isAddition;
  String? outputPath;
  int exitCode;
}
