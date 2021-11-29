// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    section('Copy test Flutter App with watchOS Companion');

    final Directory tempDir = Directory.systemTemp
        .createTempSync('flutter_ios_app_with_extensions_test.');
    final Directory projectDir =
        Directory(path.join(tempDir.path, 'app_with_extensions'));
    try {
      mkdir(projectDir);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests',
            'ios_app_with_extensions')),
        projectDir,
      );

      section('Create release build');

      // This only builds the iOS app, not the companion watchOS app. The watchOS app
      // has been removed as a build dependency and is not embedded in the app to avoid
      // requiring the watchOS being available in CI.
      // Instead, validate the tool detects that there is a watch companion, and omits
      // the "-sdk iphoneos" option, which fails to build the watchOS app.
      // See https://github.com/flutter/flutter/pull/94190.
      await inDirectory(projectDir, () async {
        final String buildOutput = await evalFlutter(
          'build',
          options: <String>['ios', '--no-codesign', '--release', '--verbose'],
        );
        if (!buildOutput.contains('Watch companion app found')) {
          throw TaskResult.failure('Did not detect watch companion');
        }
        if (buildOutput.contains('-sdk iphoneos -destination')) {
          throw TaskResult.failure('-sdk must be omitted for app with watch companion');
        }
      });

      final String appBundle = Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      )).path;

      final String appFrameworkPath = path.join(
        appBundle,
        'Frameworks',
        'App.framework',
        'App',
      );
      final String flutterFrameworkPath = path.join(
        appBundle,
        'Frameworks',
        'Flutter.framework',
        'Flutter',
      );

      checkDirectoryExists(appBundle);
      await _checkFlutterFrameworkArchs(appFrameworkPath);
      await _checkFlutterFrameworkArchs(flutterFrameworkPath);

      section('Clean build');

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}

Future<void> _checkFlutterFrameworkArchs(String frameworkPath) async {
  checkFileExists(frameworkPath);

  final String archs = await fileType(frameworkPath);
  if (!archs.contains('arm64')) {
    throw TaskResult.failure('$frameworkPath arm64 architecture missing');
  }

  if (archs.contains('x86_64')) {
    throw TaskResult.failure('$frameworkPath x86_64 architecture unexpectedly present');
  }
}
