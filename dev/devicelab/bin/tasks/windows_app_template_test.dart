import 'dart:io';
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';

const String _kIntegrationTestsRelativePath = '/dev/integration_tests';
const String _kTemplateRelativePath = '/packages/flutter_tools/templates/app_shared/windows.tmpl/runner';
const String _kWindowsRunnerSubPath = '/windows/runner';
const List<String> _kFilesToMatch = ['utils.h', 'utils.cpp'];
const int _kLicenseLines = 4;

Future<void> main() async {
  await task(() async {
    final String integrationTestsPath = '${flutterDirectory.path}$_kIntegrationTestsRelativePath';
    final String templatePath = '${flutterDirectory.path}$_kTemplateRelativePath';
    final Iterable<Directory>subDirs = (await Directory(integrationTestsPath).list().toList()).whereType<Directory>();
    bool match = true;
    for (final Directory testPath in subDirs) {
      final String runnerPath = '${testPath.path}$_kWindowsRunnerSubPath';
      final Directory runner = Directory(runnerPath);
      if (!runner.existsSync()) {
        continue;
      }
      for (final String fileName in _kFilesToMatch) {
        final String templateFilePath = '$templatePath/$fileName';
        final String templateFile = (await File(templateFilePath).readAsLines()).join('\n'); // Normalize line endings
        final String appFilePath = '$runnerPath/$fileName';
        final String appFile = (await File(appFilePath).readAsLines()).sublist(_kLicenseLines).join('\n'); // Skip license
        if (appFile != templateFile) {
          print('File $fileName mismatched for integration test $testPath');
          print('=====$templateFilePath======');
          print(appFile);
          print('=====$appFilePath======');
          print(templateFile);
          int i;
          for (i = 0; i < appFile.length; i++) {
            if (i >= templateFile.length || templateFile.codeUnitAt(i) != appFile.codeUnitAt(i)) {
              break;
            }
          }
          print('==========');
          print('Diff at character #$i');
          match = false;
        }
      }
    }
    if (!match) {
      return TaskResult.failure(null);
    }
    return TaskResult.success(null);
  });
}