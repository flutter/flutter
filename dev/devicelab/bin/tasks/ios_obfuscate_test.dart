// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      bool foundProjectName = false;
      await runProjectTest((FlutterProject flutterProject) async {
        section('iOS Framework content with --obfuscate');
        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'ios',
            '--release',
            '--obfuscate',
            '--split-debug-info=foo/',
          ]);
        });
        final String outputFramework = path.join(
          flutterProject.rootPath,
          'build/ios/iphoneos/Runner.app/Frameworks/App.framework/App',
        );
        if (!File(outputFramework).existsSync()) {
          fail('Failed to produce expected output at $outputFramework');
        }

        // Verify that an identifier from the Dart project code is not present
        // in the compiled binary.
        await inDirectory(flutterProject.rootPath, () async {
          final String response = await eval(
            'grep',
            <String>[flutterProject.name, outputFramework],
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
