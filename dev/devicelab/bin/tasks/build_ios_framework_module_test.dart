// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that iOS .frameworks can be built on module projects.
Future<void> main() async {
  await task(() async {

    section('Create module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--template', 'module', 'hello'],
        );
      });

      section('Add plugins');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = pubspec.readAsStringSync();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  device_info: 0.4.1\n  package_info: 0.4.0+9\n',
      );
      pubspec.writeAsStringSync(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      // This builds all build modes' frameworks by default
      section('Build frameworks');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios-framework'],
        );
      });

      final String outputPath = path.join(
        projectDir.path,
        'build',
        'ios',
        'framework',
      );

      section('Check debug build has Dart snapshot as asset');

      checkFileExists(path.join(
        outputPath,
        'Debug',
        'App.framework',
        'flutter_assets',
        'vm_snapshot_data',
      ));

      section('Check debug build has no Dart AOT');

      // There's still an App.framework with a dylib, but it's empty.
      checkFileExists(path.join(
        outputPath,
        'Debug',
        'App.framework',
        'App',
      ));

      final String aotSymbols = await dylibSymbols(path.join(
        outputPath,
        'Debug',
        'App.framework',
        'App',
      ));

      if (aotSymbols.contains('architecture') ||
          aotSymbols.contains('_kDartVmSnapshot')) {
        throw TaskResult.failure('Debug App.framework contains AOT');
      }

      section('Check profile, release builds has Dart AOT dylib');

      for (String mode in <String>['Profile', 'Release']) {
        checkFileExists(path.join(
          outputPath,
          mode,
          'App.framework',
          'App',
        ));

        final String aotSymbols = await dylibSymbols(path.join(
          outputPath,
          mode,
          'App.framework',
          'App',
        ));

        if (!aotSymbols.contains('armv7')) {
          throw TaskResult.failure('$mode App.framework armv7 architecture missing');
        }

        if (!aotSymbols.contains('arm64')) {
          throw TaskResult.failure('$mode App.framework arm64 architecture missing');
        }

        if (!aotSymbols.contains('_kDartVmSnapshot')) {
          throw TaskResult.failure('$mode App.framework missing Dart AOT');
        }

        checkFileNotExists(path.join(
          outputPath,
          mode,
          'App.framework',
          'flutter_assets',
          'vm_snapshot_data',
        ));
      }

      section("Check all modes' engine dylib");

      for (String mode in <String>['Debug', 'Profile', 'Release']) {
        checkFileExists(path.join(
          outputPath,
          mode,
          'Flutter.framework',
          'Flutter',
        ));
      }

      section("Check all modes' engine header");

      for (String mode in <String>['Debug', 'Profile', 'Release']) {
        checkFileContains(
          <String>['#include "FlutterEngine.h"'],
          path.join(outputPath, mode, 'Flutter.framework', 'Headers', 'Flutter.h'),
        );
      }

      section("Check all modes' have plugin dylib");

      for (String mode in <String>['Debug', 'Profile', 'Release']) {
        checkFileExists(path.join(
          outputPath,
          mode,
          'device_info.framework',
          'device_info',
        ));
      }

      section("Check all modes' have generated plugin registrant");

      for (String mode in <String>['Debug', 'Profile', 'Release']) {
        checkFileExists(path.join(
          outputPath,
          mode,
          'FlutterPluginRegistrant.framework',
          'Headers',
          'GeneratedPluginRegistrant.h',
        ));
      }

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
