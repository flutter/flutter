// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';

/// Tests that we respect storage proxy URLs in gradle dependencies.
Future<void> main() async {
  await task(() async {
    section('Find Java');

    final String? javaHome = await findJavaHome();
    if (javaHome == null) {
      return TaskResult.failure('Could not find Java');
    }
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create project');
    await runProjectTest((FlutterProject flutterProject) async {
      await inDirectory(path.join(flutterProject.rootPath, 'android'), () async {
        section('Insert gradle testing script');
        final File build = File(path.join(
<<<<<<< HEAD
	    flutterProject.rootPath, 'android', 'app', 'build.gradle'));
=======
          flutterProject.rootPath, 'android', 'app', 'build.gradle',
        ));
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
        build.writeAsStringSync(
          '''
task printEngineMavenUrl() {
    doLast {
        println project.repositories.find { it.name == 'maven' }.url
    }
}
          ''',
          mode: FileMode.append,
          flush: true,
        );

        section('Checking default maven URL');
<<<<<<< HEAD
=======

>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
        String gradleOutput = await eval(
          gradlewExecutable,
          <String>['printEngineMavenUrl', '-q'],
        );
        const LineSplitter splitter = LineSplitter();
        List<String> outputLines = splitter.convert(gradleOutput);
        String mavenUrl = outputLines.last;
        print('Returned maven url: $mavenUrl');

<<<<<<< HEAD
        if (mavenUrl != 'https://storage.googleapis.com/download.flutter.io') {
          throw TaskResult.failure('Expected Android engine maven dependency URL to '
              'resolve to https://storage.googleapis.com/download.flutter.io. Got '
              '$mavenUrl instead');
=======
        String realm = File(
          path.join(flutterDirectory.path, 'bin', 'internal', 'engine.realm'),
        ).readAsStringSync().trim();
        if (realm.isNotEmpty) {
          realm = '$realm/';
        }

        if (mavenUrl != 'https://storage.googleapis.com/${realm}download.flutter.io') {
          throw TaskResult.failure(
            'Expected Android engine maven dependency URL to '
            'resolve to https://storage.googleapis.com/${realm}download.flutter.io. Got '
            '$mavenUrl instead',
          );
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
        }

        section('Checking overridden maven URL');
        gradleOutput = await eval(
<<<<<<< HEAD
	    gradlewExecutable,
	    <String>['printEngineMavenUrl','-q'],
	    environment: <String, String>{
              'FLUTTER_STORAGE_BASE_URL': 'https://my.special.proxy',
            }
	);
        outputLines = splitter.convert(gradleOutput);
        mavenUrl = outputLines.last;

        if (mavenUrl != 'https://my.special.proxy/download.flutter.io') {
          throw TaskResult.failure(
	      'Expected overridden Android engine maven '
              'dependency URL to resolve to proxy location '
              'https://my.special.proxy/download.flutter.io. Got '
              '$mavenUrl instead');
=======
          gradlewExecutable,
          <String>['printEngineMavenUrl','-q'],
          environment: <String, String>{
            'FLUTTER_STORAGE_BASE_URL': 'https://my.special.proxy',
          },
        );
        outputLines = splitter.convert(gradleOutput);
        mavenUrl = outputLines.last;

        if (mavenUrl != 'https://my.special.proxy/${realm}download.flutter.io') {
          throw TaskResult.failure(
            'Expected overridden Android engine maven '
            'dependency URL to resolve to proxy location '
            'https://my.special.proxy/${realm}download.flutter.io. Got '
            '$mavenUrl instead',
          );
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
        }
      });
    });
    return TaskResult.success(null);
  });
}
