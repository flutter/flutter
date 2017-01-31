// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';
import 'android_sdk.dart';

const String gradleManifestPath = 'android/app/src/main/AndroidManifest.xml';
const String gradleAppOutV1 = 'android/app/build/outputs/apk/app-debug.apk';
const String gradleAppOutV2 = 'android/app/build/outputs/apk/app.apk';
const String gradleAppOutDir = 'android/app/build/outputs/apk';

enum FlutterPluginVersion {
  none,
  v1,
  v2,
}

bool isProjectUsingGradle() {
  return fs.isFileSync('android/build.gradle');
}

FlutterPluginVersion get flutterPluginVersion {
  File plugin = fs.file('android/buildSrc/src/main/groovy/FlutterPlugin.groovy');
  if (!plugin.existsSync()) {
    return FlutterPluginVersion.none;
  }
  String packageLine = plugin.readAsLinesSync().skip(4).first;
  if (packageLine == "package io.flutter.gradle") {
    return FlutterPluginVersion.v2;
  }
  return FlutterPluginVersion.v1;
}

String get gradleAppOut {
  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend we're v1, and just go with it.
    case FlutterPluginVersion.v1:
      return gradleAppOutV1;
    case FlutterPluginVersion.v2:
      return gradleAppOutV2;
  }
  return null;
}

String locateSystemGradle({ bool ensureExecutable: true }) {
  String gradle = _locateSystemGradle();
  if (ensureExecutable && gradle != null) {
    File file = fs.file(gradle);
    if (file.existsSync())
      os.makeExecutable(file);
  }
  return gradle;
}

String _locateSystemGradle() {
  // See if the user has explicitly configured gradle-dir.
  String gradleDir = config.getValue('gradle-dir');
  if (gradleDir != null) {
    if (fs.isFileSync(gradleDir))
      return gradleDir;
    return path.join(gradleDir, 'bin', 'gradle');
  }

  // Look relative to Android Studio.
  String studioPath = config.getValue('android-studio-dir');

  if (studioPath == null && os.isMacOS) {
    final String kDefaultMacPath = '/Applications/Android Studio.app';
    if (fs.isDirectorySync(kDefaultMacPath))
      studioPath = kDefaultMacPath;
  }

  if (studioPath != null) {
    // '/Applications/Android Studio.app/Contents/gradle/gradle-2.10/bin/gradle'
    if (os.isMacOS && !studioPath.endsWith('Contents'))
      studioPath = path.join(studioPath, 'Contents');

    Directory dir = fs.directory(path.join(studioPath, 'gradle'));
    if (dir.existsSync()) {
      // We find the first valid gradle directory.
      for (FileSystemEntity entity in dir.listSync()) {
        if (entity is Directory && path.basename(entity.path).startsWith('gradle-')) {
          String executable = path.join(entity.path, 'bin', 'gradle');
          if (fs.isFileSync(executable))
            return executable;
        }
      }
    }
  }

  // Use 'which'.
  File file = os.which('gradle');
  if (file != null)
    return file.path;

  // We couldn't locate gradle.
  return null;
}

String locateProjectGradlew({ bool ensureExecutable: true }) {
  final String path = 'android/gradlew';

  if (fs.isFileSync(path)) {
    if (ensureExecutable)
      os.makeExecutable(fs.file(path));
    return path;
  } else {
    return null;
  }
}

Future<String> ensureGradlew() async {
  String gradlew = locateProjectGradlew();

  if (gradlew == null) {
    String gradle = locateSystemGradle();
    if (gradle == null) {
      throwToolExit(
          'Unable to locate gradle. Please configure the path to gradle using \'flutter config --gradle-dir\'.'
      );
    } else {
      printTrace('Using gradle from $gradle.');
    }

    // Stamp the android/app/build.gradle file with the current android sdk and build tools version.
    File appGradleFile = fs.file('android/app/build.gradle');
    if (appGradleFile.existsSync()) {
      _GradleFile gradleFile = new _GradleFile.parse(appGradleFile);
      AndroidSdkVersion sdkVersion = androidSdk.latestVersion;
      gradleFile.replace('compileSdkVersion', "${sdkVersion.sdkLevel}");
      gradleFile.replace('buildToolsVersion', "'${sdkVersion.buildToolsVersionName}'");
      gradleFile.writeContents(appGradleFile);
    }

    // Run 'gradle wrapper'.
    List<String> command = logger.isVerbose
        ? <String>[gradle, 'wrapper']
        : <String>[gradle, '-q', 'wrapper'];
    try {
      Status status = logger.startProgress('Running \'gradle wrapper\'...');
      int exitcode = await runCommandAndStreamOutput(
          command,
          workingDirectory: 'android',
          allowReentrantFlutter: true
      );
      status.stop();
      if (exitcode != 0)
        throwToolExit('Gradle failed: $exitcode', exitCode: exitcode);
    } catch (error) {
      throwToolExit('$error');
    }

    gradlew = locateProjectGradlew();
    if (gradlew == null)
      throwToolExit('Unable to build android/gradlew.');
  }

  return gradlew;
}

Future<Null> buildGradleProject(BuildMode buildMode) async {
  // Create android/local.properties.
  File localProperties = fs.file('android/local.properties');
  if (!localProperties.existsSync()) {
    localProperties.writeAsStringSync(
        'sdk.dir=${androidSdk.directory}\n'
        'flutter.sdk=${Cache.flutterRoot}\n'
    );
  }
  // Update the local.properties file with the build mode.
  // FlutterPlugin v1 reads local.properties to determine build mode. Plugin v2
  // uses the standard Android way to determine what to build, but we still
  // update local.properties, in case we want to use it in the future.
  String buildModeName = getModeName(buildMode);
  SettingsFile settings = new SettingsFile.parseFromFile(localProperties);
  settings.values['flutter.buildMode'] = buildModeName;
  settings.writeContents(localProperties);

  String gradlew = await ensureGradlew();

  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend it's v1, and just go for it.
    case FlutterPluginVersion.v1:
      return buildGradleProjectV1(gradlew);
    case FlutterPluginVersion.v2:
      return buildGradleProjectV2(gradlew, buildModeName);
  }
}

Future<Null> buildGradleProjectV1(String gradlew) async {
  // Run 'gradlew build'.
  Status status = logger.startProgress('Running \'gradlew build\'...');
  int exitcode = await runCommandAndStreamOutput(
    <String>[fs.file(gradlew).absolute.path, 'build'],
    workingDirectory: 'android',
    allowReentrantFlutter: true
  );
  status.stop();

  if (exitcode != 0)
    throwToolExit('Gradlew failed: $exitcode', exitCode: exitcode);

  File apkFile = fs.file(gradleAppOutV1);
  printStatus('Built $gradleAppOutV1 (${getSizeAsMB(apkFile.lengthSync())}).');
}

Future<Null> buildGradleProjectV2(String gradlew, String buildModeName) async {
  String assembleTask = "assemble${toTitleCase(buildModeName)}";

  // Run 'gradlew assemble<BuildMode>'.
  Status status = logger.startProgress('Running \'gradlew $assembleTask\'...');
  String gradlewPath = fs.file(gradlew).absolute.path;
  List<String> command = logger.isVerbose
      ? <String>[gradlewPath, assembleTask]
      : <String>[gradlewPath, '-q', assembleTask];
  int exitcode = await runCommandAndStreamOutput(
      command,
      workingDirectory: 'android',
      allowReentrantFlutter: true
  );
  status.stop();

  if (exitcode != 0)
    throwToolExit('Gradlew failed: $exitcode', exitCode: exitcode);

  String apkFilename = 'app-$buildModeName.apk';
  File apkFile = fs.file('$gradleAppOutDir/$apkFilename');
  // Copy the APK to app.apk, so `flutter run`, `flutter install`, etc. can find it.
  apkFile.copySync('$gradleAppOutDir/app.apk');
  printStatus('Built $apkFilename (${getSizeAsMB(apkFile.lengthSync())}).');
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
