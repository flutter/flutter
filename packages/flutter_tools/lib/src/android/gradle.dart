// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/logger.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';
import 'android_sdk.dart';

const String gradleManifestPath = 'android/app/src/main/AndroidManifest.xml';
const String gradleAppOut = 'android/app/build/outputs/apk/app-debug.apk';

bool isProjectUsingGradle() {
  return FileSystemEntity.isFileSync('android/build.gradle');
}

String locateSystemGradle({ bool ensureExecutable: true }) {
  // See if the user has explicitly configured gradle-dir.
  String gradleDir = config.getValue('gradle-dir');
  if (gradleDir != null) {
    if (FileSystemEntity.isFileSync(gradleDir))
      return _ensureExecutable(gradleDir, ensureExecutable);
    String executable = path.join(gradleDir, 'bin', 'gradle');
    return _ensureExecutable(executable, ensureExecutable);
  }

  // Look relative to Android Studio.
  String studioPath = config.getValue('android-studio-dir');

  if (studioPath == null && os.isMacOS) {
    final String kDefaultMacPath = '/Applications/Android Studio.app';
    if (FileSystemEntity.isDirectorySync(kDefaultMacPath))
      studioPath = kDefaultMacPath;
  }

  if (studioPath != null) {
    // '/Applications/Android Studio.app/Contents/gradle/gradle-2.10/bin/gradle'
    if (os.isMacOS && !studioPath.endsWith('Contents'))
      studioPath = path.join(studioPath, 'Contents');

    Directory dir = new Directory(path.join(studioPath, 'gradle'));
    if (dir.existsSync()) {
      // We find the first valid gradle directory.
      for (FileSystemEntity entity in dir.listSync()) {
        if (entity is Directory && path.basename(entity.path).startsWith('gradle-')) {
          String executable = path.join(entity.path, 'bin', 'gradle');
          if (FileSystemEntity.isFileSync(executable))
            return _ensureExecutable(executable, ensureExecutable);
        }
      }
    }
  }

  // Use 'which'.
  File file = os.which('gradle');
  if (file != null)
    return _ensureExecutable(file.path, ensureExecutable);

  // We couldn't locate gradle.
  return null;
}

String locateProjectGradlew({ bool ensureExecutable: true }) {
  final String path = 'android/gradlew';

  if (FileSystemEntity.isFileSync(path)) {
    if (ensureExecutable)
      os.makeExecutable(new File(path));
    return path;
  } else {
    return null;
  }
}

Future<int> buildGradleProject(BuildMode buildMode) async {
  // Create android/local.properties.
  File localProperties = new File('android/local.properties');
  if (!localProperties.existsSync()) {
    localProperties.writeAsStringSync(
      'sdk.dir=${androidSdk.directory}\n'
      'flutter.sdk=${Cache.flutterRoot}\n'
    );
  }

  // Update the local.settings file with the build mode.
  // TODO(devoncarew): It would be nicer if we could pass this information in via a cli flag.
  SettingsFile settings = new SettingsFile.parse(localProperties);
  settings.values['flutter.buildMode'] = getModeName(buildMode);
  settings.writeContents(localProperties);

  String gradlew = locateProjectGradlew();

  if (gradlew == null) {
    String gradle = locateSystemGradle();
    if (gradle == null) {
      printError(
        'Unable to locate gradle. Please configure the path to gradle using \'flutter config --gradle\'.'
      );
      return 1;
    } else {
      printTrace('Using gradle from $gradle.');
    }

    // Stamp the android/app/build.gradle file with the current android sdk and build tools version.
    File appGradleFile = new File('android/app/build.gradle');
    if (appGradleFile.existsSync()) {
      _GradleFile gradleFile = new _GradleFile.parse(appGradleFile);
      AndroidSdkVersion sdkVersion = androidSdk.latestVersion;
      gradleFile.replace('compileSdkVersion', "${sdkVersion.sdkLevel}");
      gradleFile.replace('buildToolsVersion', "'${sdkVersion.buildToolsVersionName}'");
      gradleFile.writeContents(appGradleFile);
    }

    // Run 'gradle wrapper'.
    Status status = logger.startProgress('Running \'gradle wrapper\'...');
    int exitcode = await runCommandAndStreamOutput(
      <String>[gradle, 'wrapper'],
      workingDirectory: 'android',
      allowReentrantFlutter: true
    );
    status.stop(showElapsedTime: true);
    if (exitcode != 0)
      return exitcode;

    gradlew = locateProjectGradlew();
    if (gradlew == null) {
      printError('Unable to build android/gradlew.');
      return 1;
    }
  }

  // Run 'gradlew build'.
  Status status = logger.startProgress('Running \'gradlew build\'...');
  int exitcode = await runCommandAndStreamOutput(
    <String>[new File('android/gradlew').absolute.path, 'build'],
    workingDirectory: 'android',
    allowReentrantFlutter: true
  );
  status.stop(showElapsedTime: true);

  if (exitcode == 0) {
    File apkFile = new File(gradleAppOut);
    printStatus('Built $gradleAppOut (${getSizeAsMB(apkFile.lengthSync())}).');
  }

  return exitcode;
}

class _GradleFile {
  _GradleFile.parse(File file) {
    contents = file.readAsStringSync();
  }

  String contents;

  void replace(String key, String newValue) {
    // Replace 'ws key ws value' with the new value.
    final RegExp regex = new RegExp('\\s+$key\\s+(\\S+)', multiLine: true);
    Match match = regex.firstMatch(contents);
    if (match != null) {
      String oldValue = match.group(1);
      int offset = match.end - oldValue.length;
      contents = contents.substring(0, offset) + newValue + contents.substring(match.end);
    }
  }

  void writeContents(File file) {
    file.writeAsStringSync(contents);
  }
}

String _ensureExecutable(String execPath, bool ensureExecutable) {
  if (ensureExecutable) {
    File file = new File(execPath);
    if (file.existsSync())
      os.makeExecutable(file);
  }

  return execPath;
}