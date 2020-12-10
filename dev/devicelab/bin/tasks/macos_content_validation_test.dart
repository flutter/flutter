// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      await runProjectTest((FlutterProject flutterProject) async {
        section('Build app with with --obfuscate');
        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'macos',
            '--release',
            '--obfuscate',
            '--split-debug-info=foo/',
          ]);
        });

        final String outputAppPath = path.join(
          flutterProject.rootPath,
          'build',
          'macos',
          'Build',
          'Products',
          'Release',
          '${flutterProject.name}.app',
        );
        final Directory outputAppFramework = Directory(path.join(
          outputAppPath,
          'Contents',
          'Frameworks',
          'App.framework',
        ));

        final File outputAppFrameworkBinary = File(path.join(
          outputAppFramework.path,
          'App',
        ));

        checkFileExists(outputAppFrameworkBinary.path);

        section('Validate obfuscation');

        // Verify that an identifier from the Dart project code is not present
        // in the compiled binary.
        await inDirectory(flutterProject.rootPath, () async {
          final String response = await eval(
            'grep',
            <String>[flutterProject.name, outputAppFrameworkBinary.path],
            canFail: true,
          );
          if (response.trim().contains('matches')) {
            throw TaskResult.failure('Found project name in obfuscated dart library');
          }
        });

        section('Validate release contents');

        final Link resourcesDirectory = Link(path.join(
          outputAppFramework.path,
          'Resources',
        ));

        if (!exists(resourcesDirectory)) {
          throw TaskResult.failure('App.framework Resources symlink missing');
        }

        checkFileNotExists(path.join(
          resourcesDirectory.path,
          'flutter_assets',
          'vm_snapshot_data',
        ));

        final File outputFlutterFrameworkBinary = File(path.join(
          flutterProject.rootPath,
          outputAppPath,
          'Contents',
          'Frameworks',
          'FlutterMacOS.framework',
          'FlutterMacOS',
        ));
        checkFileExists(outputFlutterFrameworkBinary.path);

        // Archiving should contain a bitcode blob, but not building in release.
        // This mimics Xcode behavior and present a developer from having to install a
        // 300+MB app.
        if (await containsBitcode(outputFlutterFrameworkBinary.path)) {
          throw TaskResult.failure('Bitcode present in FlutterMacOS.framework');
        }

        section('Clean build');

        await inDirectory(flutterProject.rootPath, () async {
          await flutter('clean');
        });

        section('Validate debug contents');

        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'macos',
            '--debug',
          ]);

          final String debugOutputAppPath = path.join(
            flutterProject.rootPath,
            'build',
            'macos',
            'Build',
            'Products',
            'Debug',
            '${flutterProject.name}.app',
          );

          final File debugOutputFlutterFrameworkBinary = File(path.join(
            debugOutputAppPath,
            'Contents',
            'Frameworks',
            'FlutterMacOS.framework',
            'FlutterMacOS',
          ));
          checkFileExists(debugOutputFlutterFrameworkBinary.path);

          // Debug should also not contain bitcode.
          if (await containsBitcode(debugOutputFlutterFrameworkBinary.path)) {
            throw TaskResult.failure('Bitcode present in Flutter.framework');
          }

          checkFileExists(path.join(
            debugOutputAppPath,
            'Contents',
            'Frameworks',
            'App.framework',
            'Resources',
            'flutter_assets',
            'vm_snapshot_data',
          ));
        });
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
