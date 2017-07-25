// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

void main() {
  task(() async {
    section('Setting up flutter project');
    final Directory tmp = await Directory.systemTemp.createTemp('gradle');
    final FlutterProject project = await FlutterProject.create(tmp, 'hello');

    section('gradlew assembleDebug');
    await project.runGradleTask('assembleDebug');

    section('gradlew assembleProfile');
    await project.runGradleTask('assembleProfile');

    section('gradlew assembleRelease');
    await project.runGradleTask('assembleRelease');

    section('gradlew assembleLocal (custom debug build)');
    await project.addCustomBuildType('local', initWith: 'debug');
    await project.runGradleTask('assembleLocal');

    section('gradlew assembleBeta (custom release build)');
    await project.addCustomBuildType('beta', initWith: 'release');
    await project.runGradleTask('assembleBeta');

    await project.parent.delete(recursive: true);
    return new TaskResult.success(null);
  });
}

class FlutterProject {
  FlutterProject(this.parent, this.name);

  Directory parent;
  String name;

  static Future<FlutterProject> create(Directory directory, String name) async {
    await inDirectory(directory, () async {
      await flutter('create', options: <String>[name]);
    });
    return new FlutterProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get androidPath => path.join(rootPath, 'android');

  Future<Null> addCustomBuildType(String name, {String initWith}) async {
    final File buildScript = new File(
      path.join(androidPath, 'app', 'build.gradle'),
    );
    buildScript.openWrite(mode: FileMode.APPEND).write('''

android {
    buildTypes {
        $name {
            initWith $initWith
        }
    }
}
    ''');
  }

  Future<Null> runGradleTask(String task) async {
    final ProcessResult result = await Process.run(
      './gradlew',
      <String>['-q', 'app:$task'],
      workingDirectory: androidPath,
    );
    if (result.exitCode != 0) {
      print('stdout:');
      print(result.stdout);
      print('stderr:');
      print(result.stderr);
    }
    assert(result.exitCode == 0);
  }
}
