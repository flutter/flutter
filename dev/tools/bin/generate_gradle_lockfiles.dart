// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This script generates `android/build.gradle` for each directory specify in the stdin.
// Then it generate the lockfiles for each Gradle project.
// To regenerate these files, run `find . -type d -name 'android' | dart dev/tools/bin/generate_gradle_lockfiles.dart`

import 'dart:io';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) {
  print(
    "Usage: find . -type d -name 'android' | dart dev/tools/bin/generate_gradle_lockfiles.dart\n"
    'If you would rather enter the files manually, just run `dart dev/tools/bin/generate_gradle_lockfiles.dart`,\n'
    "enter the absolute paths to the app's android directory, then press CTRL-D.\n"
  );

  const FileSystem fileSystem = LocalFileSystem();
  final List<String> androidDirectories = getFilesFromStdin();

  for (final String androidDirectoryPath in androidDirectories) {
    final Directory androidDirectory = fileSystem.directory(path.normalize(androidDirectoryPath));

    if (!androidDirectory.existsSync()) {
      throw '$androidDirectory does not exist';
    }

    final File rootBuildGradle = androidDirectory.childFile('build.gradle');
    if (!rootBuildGradle.existsSync()) {
      print('${rootBuildGradle.path} does not exist - skipping');
      continue;
    }

    final File settingsGradle = androidDirectory.childFile('settings.gradle');
    if (!settingsGradle.existsSync()) {
      print('${settingsGradle.path} does not exist - skipping');
      continue;
    }

    if (settingsGradle.readAsStringSync().contains('include_flutter.groovy')) {
      print('${settingsGradle.path} add to app - skipping');
      continue;
    }

    if (!androidDirectory.childDirectory('app').existsSync()) {
      print('${rootBuildGradle.path} is not an app - skipping');
      continue;
    }

    if (!androidDirectory.parent.childFile('pubspec.yaml').existsSync()) {
      print('${rootBuildGradle.path} no pubspec.yaml in parent directory - skipping');
      continue;
    }

    if (androidDirectory.parent.childFile('pubspec.yaml').readAsStringSync().contains('deferred-components')) {
      print('${rootBuildGradle.path} uses deferred components - skipping');
      continue;
    }

    if (!androidDirectory.parent
        .childDirectory('lib')
        .childFile('main.dart')
        .existsSync()) {
      print('${rootBuildGradle.path} no main.dart under lib - skipping');
      continue;
    }

    print('Processing ${androidDirectory.path}');

    try {
      androidDirectory.childFile('buildscript-gradle.lockfile').deleteSync();
    } on FileSystemException {
      // noop
    }

    rootBuildGradle.writeAsStringSync(rootGradleFileContent);
    settingsGradle.writeAsStringSync(settingGradleFile);

    final String appDirectory = androidDirectory.parent.absolute.path;

    // Fetch pub dependencies.
    exec('flutter', <String>['pub', 'get'], workingDirectory: appDirectory);

    // Verify that the Gradlew wrapper exists.
    final File gradleWrapper = androidDirectory.childFile('gradlew');
    // Generate Gradle wrapper if it doesn't exist.
    if (!gradleWrapper.existsSync()) {
      Process.runSync(
        'flutter',
        <String>['build', 'apk', '--config-only'],
        workingDirectory: appDirectory,
      );
    }

    // Generate lock files.
    exec(
      gradleWrapper.absolute.path,
      <String>[':generateLockfiles'],
      workingDirectory: androidDirectory.absolute.path,
    );

    print('Processed');
  }
}

List<String> getFilesFromStdin() {
  final List<String> files = <String>[];
  while (true) {
    final String? file = stdin.readLineSync();
    if (file == null) {
      break;
    }
    files.add(file);
  }
  return files;
}

void exec(
  String cmd,
  List<String> args, {
  String? workingDirectory,
}) {
  final ProcessResult result = Process.runSync(cmd, args, workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw ProcessException(
        cmd, args, '${result.stdout}${result.stderr}', result.exitCode);
  }
}

const String rootGradleFileContent = r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto generated.
// To update all the build.gradle files in the Flutter repo,
// See dev/tools/bin/generate_gradle_lockfiles.dart.

buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }

    configurations.classpath {
        resolutionStrategy.activateDependencyLocking()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'

subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
    dependencyLocking {
        ignoredDependencies.add('io.flutter:*')
        lockFile = file("${rootProject.projectDir}/project-${project.name}.lockfile")
        if (!project.hasProperty('local-engine-repo')) {
          lockAllConfigurations()
        }
    }
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
''';

const String settingGradleFile = r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto generated.
// To update all the settings.gradle files in the Flutter repo,
// See dev/tools/bin/generate_gradle_lockfiles.dart.

include ':app'

def localPropertiesFile = new File(rootProject.projectDir, "local.properties")
def properties = new Properties()

assert localPropertiesFile.exists()
localPropertiesFile.withReader("UTF-8") { reader -> properties.load(reader) }

def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"
''';
