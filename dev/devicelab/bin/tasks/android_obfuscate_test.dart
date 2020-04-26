// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      bool foundProjectName = false;
      await runProjectTest((FlutterProject flutterProject) async {
        section('APK content for task assembleRelease with --obfuscate');
        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'apk',
            '--target-platform=android-arm',
            '--obfuscate',
            '--split-debug-info=foo/',
          ]);
        });
        final String outputDirectory = path.join(
          flutterProject.rootPath,
          'build/app/outputs/apk/release/app-release.apk',
        );
        final Iterable<String> apkFiles = await getFilesInApk(outputDirectory);

        checkCollectionContains<String>(<String>[
          ...flutterAssets,
          ...baseApkFiles,
          'lib/armeabi-v7a/libapp.so',
        ], apkFiles);

        // Verify that an identifier from the Dart project code is not present
        // in the compiled binary.
        await inDirectory(flutterProject.rootPath, () async {
          await exec('unzip', <String>[outputDirectory]);
          final String response = await eval(
            'grep',
            <String>[flutterProject.name, 'lib/armeabi-v7a/libapp.so'],
            canFail: true,
          );
          if (response.trim().contains('matches')) {
            foundProjectName = true;
          }
        });
      });
      if (foundProjectName) {
        return TaskResult.failure('Found project name in obfuscated dart library');
      }
      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
