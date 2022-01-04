// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'globals.dart' as globals;
import 'project.dart';
import 'cache.dart';

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

  static Future<String> getFileContents({required String revision, required String file, required String workingDirectory}) async {
    List<String> cmdArgs = ['show', '$revision:$file'];
    ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result);
    return result.stdout as String;
  }

  static Future<Directory> createTempDirectory(String name) async {
    ProcessResult result = await Process.run('mktemp', ['-d', '-t', name]);
    checkForErrors(result);
    return globals.fs.directory(result.stdout as String);
  }

  static Future<String> diffFiles(File one, File two) async {
    List<String> cmdArgs = ['diff', '--no-index', one.absolute.path, two.absolute.path];
    ProcessResult result = await Process.run('git', cmdArgs);
    checkForErrors(result, allowedExitCodes: <int>[1]); // diff exits with 1 if diffs are found.
    return result.stdout as String;
  }

  static Future<void> apply({required File diff, required String workingDirectory}) async {
    List<String> cmdArgs = ['apply', diff.absolute.path];
    ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: workingDirectory);
    checkForErrors(result);
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
