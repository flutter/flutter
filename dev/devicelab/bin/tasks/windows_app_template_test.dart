// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart';

const int _kLicenseLines = 4;
const List<String> _kFilesToMatch = <String>[
  'main.cpp.tmpl',
  'utils.cpp',
  'utils.h',
  'win32_window.cpp',
  'win32_window.h',
];
const String _kIntegrationTestsRelativePath = '/dev/integration_tests';
const String _kTemplateRelativePath = '/packages/flutter_tools/templates/app_shared/windows.tmpl/runner';
const String _kWindowsRunnerSubPath = '/windows/runner';
const String _kProjectNameKey = '{{projectName}}';

Future<void> main() async {
  await task(() async {
    final String integrationTestsPath = '${flutterDirectory.path}$_kIntegrationTestsRelativePath';
    final String templatePath = '${flutterDirectory.path}$_kTemplateRelativePath';
    final Iterable<Directory>subDirs = (await Directory(integrationTestsPath).list().toList()).whereType<Directory>();
    bool fileContentsMatch = true;
    for (final Directory testPath in subDirs) {
      final String projectName = basename(testPath.path);
      final String runnerPath = '${testPath.path}$_kWindowsRunnerSubPath';
      final Directory runner = Directory(runnerPath);
      if (!runner.existsSync()) {
        continue;
      }
      for (final String fileName in _kFilesToMatch) {
        final String templateFilePath = '$templatePath/$fileName';
        String templateFile = await _fileContents(templateFilePath);
        String appFilePath = '$runnerPath/$fileName';
        if (fileName.endsWith('.tmpl')) {
          appFilePath = appFilePath.substring(0, appFilePath.length - 4); // Remove '.tmpl' from app file path
          templateFile = templateFile.replaceAll(_kProjectNameKey, projectName); // Substitute template project name
        }
        final String appFile = await _fileContents(appFilePath, linesToSkip: _kLicenseLines);
        if (appFile != templateFile) {
          fileContentsMatch = false;
          print('File $fileName mismatched for integration test $testPath');
          print('=====$appFilePath======');
          print(appFile);
          print('=====$templateFilePath======');
          print(templateFile);
          int indexOfDifference;
          for (indexOfDifference = 0; indexOfDifference < appFile.length; indexOfDifference++) {
            if (indexOfDifference >= templateFile.length || templateFile.codeUnitAt(indexOfDifference) != appFile.codeUnitAt(indexOfDifference)) {
              break;
            }
          }
          print('==========');
          print('Diff at character #$indexOfDifference');
        }
      }
    }
    if (!fileContentsMatch) {
      return TaskResult.failure(null);
    }
    return TaskResult.success(null);
  });
}

Future<String> _fileContents(String path, {int linesToSkip: 0}) async {
  return (await File(path).readAsLines()).sublist(linesToSkip).join('\n');
}
