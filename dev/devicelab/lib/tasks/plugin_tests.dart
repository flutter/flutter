// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/utils.dart';

/// Combines several TaskFunctions with trivial success value into one.
TaskFunction combine(List<TaskFunction> tasks) {
  return () async {
    for (TaskFunction task in tasks) {
      final TaskResult result = await task();
      if (result.failed) {
        return result;
      }
    }
    return TaskResult.success(null);
  };
}

/// Defines task that creates new Flutter project, adds a plugin, and then
/// builds the specified [buildTarget].
class PluginTest {
  PluginTest(this.buildTarget, this.options);

  final String buildTarget;
  final List<String> options;

  Future<TaskResult> call() async {
    section('Create Flutter project');
    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_devicelab_plugin_test.');
    try {
      final FlutterProject project = await FlutterProject.create(tempDir, options);
      try {
        if (buildTarget == 'ios')
          await prepareProvisioningCertificates(project.rootPath);
        section('Add plugin');
        await project.addPlugin('path_provider');
        section('Build');
        await project.build(buildTarget);
      } finally {
        await project.delete();
      }
      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  }
}

class FlutterProject {
  FlutterProject(this.parent, this.name);

  final Directory parent;
  final String name;

  static Future<FlutterProject> create(Directory directory, List<String> options) async {
    await inDirectory(directory, () async {
      await flutter(
        'create',
        options: <String>['--template=app', '--org', 'io.flutter.devicelab']..addAll(options)..add('plugintest')
      );
    });
    return FlutterProject(directory, 'plugintest');
  }

  String get rootPath => path.join(parent.path, name);

  Future<void> addPlugin(String plugin) async {
    final File pubspec = File(path.join(rootPath, 'pubspec.yaml'));
    String content = await pubspec.readAsString();
    content = content.replaceFirst(
      '\ndependencies:\n',
      '\ndependencies:\n  $plugin:\n',
    );
    await pubspec.writeAsString(content, flush: true);
  }

  Future<void> build(String target) async {
    await inDirectory(Directory(rootPath), () async {
      await flutter('build', options: <String>[target]);
    });
  }

  Future<void> delete() async {
    if (Platform.isWindows) {
      // A running Gradle daemon might prevent us from deleting the project
      // folder on Windows.
      await exec(
        path.absolute(path.join(rootPath, 'android', 'gradlew.bat')),
        <String>['--stop'],
        canFail: true,
      );
      // TODO(ianh): Investigating if flakiness is timing dependent.
      await Future<void>.delayed(const Duration(seconds: 10));
    }
    rmTree(parent);
  }
}
