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
    return new TaskResult.success(null);
  };
}

/// Defines task that creates new Flutter project, adds a plugin, and then
/// builds the specified [buildTarget].
class PluginTest {
  final String buildTarget;
  final List<String> options;

  PluginTest(this.buildTarget, this.options);

  Future<TaskResult> call() async {
    section('Create Flutter project');
    final Directory tmp = await Directory.systemTemp.createTemp('plugin');
    final FlutterProject project = await FlutterProject.create(tmp, options);
    if (buildTarget == 'ios') {
      await prepareProvisioningCertificates(project.rootPath);
    }
    try {
      section('Add plugin');
      await project.addPlugin('path_provider');

      section('Build');
      await project.build(buildTarget);

      return new TaskResult.success(null);
    } catch (e) {
      return new TaskResult.failure(e.toString());
    } finally {
      await project.delete();
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
        options: <String>['--org', 'io.flutter.devicelab']..addAll(options)..add('plugintest')
      );
    });
    return new FlutterProject(directory, 'plugintest');
  }

  String get rootPath => path.join(parent.path, name);

  Future<Null> addPlugin(String plugin) async {
    final File pubspec = new File(path.join(rootPath, 'pubspec.yaml'));
    String content = await pubspec.readAsString();
    content = content.replaceFirst(
      '\ndependencies:\n',
      '\ndependencies:\n  $plugin:\n',
    );
    await pubspec.writeAsString(content, flush: true);
  }

  Future<Null> build(String target) async {
    await inDirectory(new Directory(rootPath), () async {
      await flutter('build', options: <String>[target]);
    });
  }

  Future<Null> delete() async {
    await parent.delete(recursive: true);
  }
}
