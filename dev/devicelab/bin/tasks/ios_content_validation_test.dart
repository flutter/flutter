// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      bool foundProjectName = false;
      bool bitcode = false;
      await runProjectTest((FlutterProject flutterProject) async {
        section('Build app with with --obfuscate');
        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'ios',
            '--release',
            '--obfuscate',
            '--split-debug-info=foo/',
          ]);
        });
        final String outputAppPath = path.join(
          flutterProject.rootPath,
          'build/ios/iphoneos/Runner.app',
        );
        final String outputAppFramework = path.join(
          flutterProject.rootPath,
          outputAppPath,
          'Frameworks/App.framework/App',
        );
        if (!File(outputAppFramework).existsSync()) {
          fail('Failed to produce expected output at $outputAppFramework');
        }

        section('Validate obfuscation');

        // Verify that an identifier from the Dart project code is not present
        // in the compiled binary.
        await inDirectory(flutterProject.rootPath, () async {
          final String response = await eval(
            'grep',
            <String>[flutterProject.name, outputAppFramework],
            canFail: true,
          );
          if (response.trim().contains('matches')) {
            foundProjectName = true;
          }
        });

        section('Validate bitcode');

        final String outputFlutterFramework = path.join(
          flutterProject.rootPath,
          outputAppPath,
          'Frameworks/Flutter.framework/Flutter',
        );

        if (!File(outputFlutterFramework).existsSync()) {
          fail('Failed to produce expected output at $outputFlutterFramework');
        }
        bitcode = await containsBitcode(outputFlutterFramework);
      });

      if (foundProjectName) {
        return TaskResult.failure('Found project name in obfuscated dart library');
      }
      // Archiving should contain a bitcode blob, but not building in release.
      // This mimics Xcode behavior and present a developer from having to install a
      // 300+MB app to test devices.
      if (bitcode) {
        return TaskResult.failure('Bitcode present in Flutter.framework');
      }

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
