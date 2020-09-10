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
      await runProjectTest((FlutterProject flutterProject) async {
        section('Build app with with --obfuscate');
        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'ios',
            '--release',
            '--obfuscate',
            '--split-debug-info=foo/',
            '--no-codesign',
          ]);
        });
        final String buildPath = path.join(
          flutterProject.rootPath,
          'build',
          'ios',
          'iphoneos',
        );
        final String outputAppPath = path.join(
          buildPath,
          'Runner.app',
        );
        final Directory outputAppFramework = Directory(path.join(
          outputAppPath,
          'Frameworks',
          'App.framework',
        ));

        final File outputAppFrameworkBinary = File(path.join(
          outputAppFramework.path,
          'App',
        ));

        if (!outputAppFrameworkBinary.existsSync()) {
          fail('Failed to produce expected output at ${outputAppFrameworkBinary.path}');
        }

        if (await dartObservatoryBonjourServiceFound(outputAppPath)) {
          throw TaskResult.failure('Release bundle has unexpected NSBonjourServices');
        }
        if (await localNetworkUsageFound(outputAppPath)) {
          throw TaskResult.failure('Release bundle has unexpected NSLocalNetworkUsageDescription');
        }

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

        final Directory outputFlutterFramework = Directory(path.join(
          flutterProject.rootPath,
          outputAppPath,
          'Frameworks',
          'Flutter.framework',
        ));
        final File outputFlutterFrameworkBinary = File(path.join(
          outputFlutterFramework.path,
          'Flutter',
        ));

        if (!outputFlutterFrameworkBinary.existsSync()) {
          fail('Failed to produce expected output at ${outputFlutterFrameworkBinary.path}');
        }

        // Archiving should contain a bitcode blob, but not building in release.
        // This mimics Xcode behavior and present a developer from having to install a
        // 300+MB app to test devices.
        if (await containsBitcode(outputFlutterFrameworkBinary.path)) {
          throw TaskResult.failure('Bitcode present in Flutter.framework');
        }

        section('Xcode backend script');

        outputFlutterFramework.deleteSync(recursive: true);
        outputAppFramework.deleteSync(recursive: true);
        if (outputFlutterFramework.existsSync() || outputAppFramework.existsSync()) {
          fail('Failed to delete embedded frameworks');
        }

        final String xcodeBackendPath = path.join(
          flutterDirectory.path,
          'packages',
          'flutter_tools',
          'bin',
          'xcode_backend.sh'
        );

        // Simulate a common Xcode build setting misconfiguration
        // where FLUTTER_APPLICATION_PATH is missing
        final int result = await exec(
          xcodeBackendPath,
          <String>['embed_and_thin'],
          environment: <String, String>{
            'SOURCE_ROOT': flutterProject.iosPath,
            'TARGET_BUILD_DIR': buildPath,
            'FRAMEWORKS_FOLDER_PATH': 'Runner.app/Frameworks',
            'VERBOSE_SCRIPT_LOGGING': '1',
            'FLUTTER_BUILD_MODE': 'release',
            'ACTION': 'install', // Skip bitcode stripping since we just checked that above.
          },
        );

        if (result != 0) {
          fail('xcode_backend embed_and_thin failed');
        }

        if (!outputFlutterFrameworkBinary.existsSync()) {
          fail('Failed to re-embed ${outputFlutterFrameworkBinary.path}');
        }

        if (!outputAppFrameworkBinary.existsSync()) {
          fail('Failed to re-embed ${outputAppFrameworkBinary.path}');
        }

        section('Clean build');

        await inDirectory(flutterProject.rootPath, () async {
          await flutter('clean');
        });

        section('Validate debug contents');

        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'ios',
            '--debug',
            '--no-codesign',
          ]);
        });

        // Debug should also not contain bitcode.
        if (await containsBitcode(outputFlutterFrameworkBinary.path)) {
          throw TaskResult.failure('Bitcode present in Flutter.framework');
        }

        if (!await dartObservatoryBonjourServiceFound(outputAppPath)) {
          throw TaskResult.failure('Debug bundle is missing NSBonjourServices');
        }
        if (!await localNetworkUsageFound(outputAppPath)) {
          throw TaskResult.failure('Debug bundle is missing NSLocalNetworkUsageDescription');
        }
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
