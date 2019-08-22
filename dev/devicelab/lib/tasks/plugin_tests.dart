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

/// Defines task that creates new Flutter project, adds a local and remote
/// plugin, and then builds the specified [buildTarget].
class PluginTest {
  PluginTest(this.buildTarget, this.options);

  final String buildTarget;
  final List<String> options;

  Future<TaskResult> call() async {
    final Directory tempDir =
        Directory.systemTemp.createTempSync('flutter_devicelab_plugin_test.');
    try {
      section('Create plugin');
      final _FlutterPlugin plugin =
          await _FlutterPlugin.create(tempDir, options);
      section('Test plugin');
      await plugin.test();
      section('Create Flutter app');
      final _FlutterApp app = await _FlutterApp.create(tempDir, options);
      try {
        if (buildTarget == 'ios')
          await prepareProvisioningCertificates(app.rootPath);
        section('Add plugins');
        await app.addPlugin('plugintest', pluginPath: '../plugintest');
        await app.addPlugin('path_provider');
        section('Build');
        await app.build(buildTarget);
      } finally {
        await plugin.delete();
        await app.delete();
      }
      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  }
}

abstract class _FlutterProject {
  _FlutterProject(this.parent, this.name);

  final Directory parent;
  final String name;

  String get rootPath => path.join(parent.path, name);

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

class _FlutterPlugin extends _FlutterProject {
  _FlutterPlugin(this.parent, this.name) : _FlutterProject(parent, name);

  static Future<_FlutterPlugin> create(
      Directory directory, List<String> options) async {
    await inDirectory(directory, () async {
      await flutter(
        'create',
        options: <String>[
          '--template=plugin',
          '--org',
          'io.flutter.devicelab',
          ...options,
          'plugintest'
        ],
      );
    });
    return _FlutterPlugin(directory, 'plugintest');
  }

  Future<void> test() async {
    await inDirectory(Directory(rootPath), () async {
      await flutter('test');
    });
  }
}

class _FlutterApp extends _FlutterProject {
  _FlutterApp(this.parent, this.name) : _FlutterProject(parent, name);

  static Future<_FlutterApp> create(
      Directory directory, List<String> options) async {
    await inDirectory(directory, () async {
      await flutter(
        'create',
        options: <String>[
          '--template=app',
          '--org',
          'io.flutter.devicelab',
          ...options,
          'plugintestapp'
        ],
      );
    });
    return _FlutterApp(directory, 'plugintestapp');
  }

  Future<void> addPlugin(String plugin, {String pluginPath}) async {
    final File pubspec = File(path.join(rootPath, 'pubspec.yaml'));
    String content = await pubspec.readAsString();
    String dependency =
        pluginPath != null ? '$plugin:\n    path: $pluginPath' : plugin;
    content = content.replaceFirst(
      '\ndependencies:\n',
      '\ndependencies:\n  $dependency\n',
    );
    await pubspec.writeAsString(content, flush: true);
  }

  Future<void> build(String target) async {
    await inDirectory(Directory(rootPath), () async {
      await flutter('build', options: <String>[target]);
    });
  }
}
