// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';
import 'android_sdk.dart';
import 'android_studio.dart';

const String gradleManifestPath = 'android/app/src/main/AndroidManifest.xml';
const String gradleAppOutV1 = 'android/app/build/outputs/apk/app-debug.apk';
const String gradleAppOutV2 = 'android/app/build/outputs/apk/app.apk';
const String gradleAppOutDir = 'android/app/build/outputs/apk';

enum FlutterPluginVersion {
  none,
  v1,
  v2,
  managed,
}

bool isProjectUsingGradle() {
  return fs.isFileSync('android/build.gradle');
}

FlutterPluginVersion get flutterPluginVersion {
  File plugin = fs.file('android/buildSrc/src/main/groovy/FlutterPlugin.groovy');
  if (plugin.existsSync()) {
    String packageLine = plugin.readAsLinesSync().skip(4).first;
    if (packageLine == "package io.flutter.gradle") {
      return FlutterPluginVersion.v2;
    }
    return FlutterPluginVersion.v1;
  }
  File appGradle = fs.file('android/app/build.gradle');
  if (appGradle.existsSync()) {
    for (String line in appGradle.readAsLinesSync()) {
      if (line.contains(new RegExp(r"apply from: .*/flutter.gradle"))) {
        return FlutterPluginVersion.managed;
      }
    }
  }
  return FlutterPluginVersion.none;
}

String get gradleAppOut {
  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend we're v1, and just go with it.
    case FlutterPluginVersion.v1:
      return gradleAppOutV1;
    case FlutterPluginVersion.managed:
      // Fall through. The managed plugin matches plugin v2 for now.
    case FlutterPluginVersion.v2:
      return gradleAppOutV2;
  }
  return null;
}

String locateSystemGradle({ bool ensureExecutable: true }) {
  String gradle = gradleExecutable;
  if (ensureExecutable && gradle != null) {
    File file = fs.file(gradle);
    if (file.existsSync())
      os.makeExecutable(file);
  }
  return gradle;
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

Future<String> ensureGradle() async {
  String gradle = locateProjectGradlew();
  if (gradle == null) {
    gradle = locateSystemGradle();
    if (gradle == null) {
      throwToolExit('Unable to locate gradle. Please install Android Studio.');
    }
  }
  printTrace('Using gradle from $gradle.');
  return gradle;
}

Future<Null> buildGradleProject(BuildMode buildMode) async {
  // Create android/local.properties.
  File localProperties = fs.file('android/local.properties');
  if (!localProperties.existsSync()) {
    localProperties.writeAsStringSync(
        'sdk.dir=${_escapePath(androidSdk.directory)}\n'
        'flutter.sdk=${_escapePath(Cache.flutterRoot)}\n'
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

  String gradle = await ensureGradle();

  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend it's v1, and just go for it.
    case FlutterPluginVersion.v1:
      return buildGradleProjectV1(gradle);
    case FlutterPluginVersion.managed:
      // Fall through. Managed plugin builds the same way as plugin v2.
    case FlutterPluginVersion.v2:
      return buildGradleProjectV2(gradle, buildModeName);
  }
}

String _escapePath(String path) => platform.isWindows ? path.replaceAll('\\', '\\\\') : path;

Future<Null> buildGradleProjectV1(String gradle) async {
  // Run 'gradle build'.
  Status status = logger.startProgress('Running \'gradle build\'...', expectSlowOperation: true);
  int exitcode = await runCommandAndStreamOutput(
    <String>[fs.file(gradle).absolute.path, 'build'],
    workingDirectory: 'android',
    allowReentrantFlutter: true
  );
  status.stop();

  if (exitcode != 0)
    throwToolExit('Gradle build failed: $exitcode', exitCode: exitcode);

  File apkFile = fs.file(gradleAppOutV1);
  printStatus('Built $gradleAppOutV1 (${getSizeAsMB(apkFile.lengthSync())}).');
}

Future<Null> buildGradleProjectV2(String gradle, String buildModeName) async {
  String assembleTask = "assemble${toTitleCase(buildModeName)}";

  // Run 'gradle assemble<BuildMode>'.
  Status status = logger.startProgress('Running \'gradle $assembleTask\'...', expectSlowOperation: true);
  String gradlePath = fs.file(gradle).absolute.path;
  List<String> command = logger.isVerbose
      ? <String>[gradlePath, assembleTask]
      : <String>[gradlePath, '-q', assembleTask];
  int exitcode = await runCommandAndStreamOutput(
      command,
      workingDirectory: 'android',
      allowReentrantFlutter: true
  );
  status.stop();

  if (exitcode != 0)
    throwToolExit('Gradle build failed: $exitcode', exitCode: exitcode);

  String apkFilename = 'app-$buildModeName.apk';
  File apkFile = fs.file('$gradleAppOutDir/$apkFilename');
  // Copy the APK to app.apk, so `flutter run`, `flutter install`, etc. can find it.
  apkFile.copySync('$gradleAppOutDir/app.apk');
  printStatus('Built $apkFilename (${getSizeAsMB(apkFile.lengthSync())}).');
}
