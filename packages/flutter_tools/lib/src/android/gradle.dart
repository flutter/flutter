// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
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
import '../plugins.dart';
import 'android_sdk.dart';
import 'android_studio.dart';

const String gradleManifestPath = 'android/app/src/main/AndroidManifest.xml';
const String gradleAppOutV1 = 'android/app/build/outputs/apk/app-debug.apk';
const String gradleAppOutDirV1 = 'android/app/build/outputs/apk';

String _cachedGradleAppOutDirV2;

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
  final File plugin = fs.file('android/buildSrc/src/main/groovy/FlutterPlugin.groovy');
  if (plugin.existsSync()) {
    final String packageLine = plugin.readAsLinesSync().skip(4).first;
    if (packageLine == "package io.flutter.gradle") {
      return FlutterPluginVersion.v2;
    }
    return FlutterPluginVersion.v1;
  }
  final File appGradle = fs.file('android/app/build.gradle');
  if (appGradle.existsSync()) {
    for (String line in appGradle.readAsLinesSync()) {
      if (line.contains(new RegExp(r"apply from: .*/flutter.gradle"))) {
        return FlutterPluginVersion.managed;
      }
    }
  }
  return FlutterPluginVersion.none;
}

String getGradleAppOut() {
  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend we're v1, and just go with it.
    case FlutterPluginVersion.v1:
      return gradleAppOutV1;
    case FlutterPluginVersion.managed:
      // Fall through. The managed plugin matches plugin v2 for now.
    case FlutterPluginVersion.v2:
      return '${getGradleAppOutDirV2()}/app.apk';
  }
  return null;
}

String getGradleAppOutDirV2() {
  _cachedGradleAppOutDirV2 ??= _calculateGradleAppOutDirV2();
  return _cachedGradleAppOutDirV2;
}

// Note: this call takes about a second to complete.
String _calculateGradleAppOutDirV2() {
  final String gradle = ensureGradle();
  updateLocalProperties();
  try {
    final String properties = runCheckedSync(
      <String>[gradle, 'app:properties'],
      workingDirectory: 'android',
      hideStdout: true,
      environment: _gradleEnv,
    );
    String buildDir = properties
        .split('\n')
        .firstWhere((String s) => s.startsWith('buildDir: '))
        .substring('buildDir: '.length)
        .trim();
    final String currentDirectory = fs.currentDirectory.path;
    if (buildDir.startsWith(currentDirectory)) {
      // Relativize path, snip current directory + separating '/'.
      buildDir = buildDir.substring(currentDirectory.length + 1);
    }
    return '$buildDir/outputs/apk';
  } catch (e) {
    printError('Error running gradle: $e');
  }
  // Fall back to the default
  return gradleAppOutDirV1;
}

String locateSystemGradle({ bool ensureExecutable: true }) {
  final String gradle = gradleExecutable;
  if (ensureExecutable && gradle != null) {
    final File file = fs.file(gradle);
    if (file.existsSync())
      os.makeExecutable(file);
  }
  return gradle;
}

String locateProjectGradlew({ bool ensureExecutable: true }) {
  final String path = fs.path.join(
      'android', platform.isWindows ? 'gradlew.bat' : 'gradlew'
  );

  if (fs.isFileSync(path)) {
    final File gradle = fs.file(path);
    if (ensureExecutable)
      os.makeExecutable(gradle);
    return gradle.absolute.path;
  } else {
    return null;
  }
}

String ensureGradle() {
  String gradle = locateProjectGradlew();
  if (gradle == null) {
    gradle = locateSystemGradle();
    if (gradle == null)
      throwToolExit('Unable to locate gradle. Please install Android Studio.');
  }
  printTrace('Using gradle from $gradle.');
  return gradle;
}

/// Create android/local.properties if needed, and update Flutter settings.
void updateLocalProperties({String projectPath, String buildMode}) {
  final File localProperties = (projectPath == null)
      ? fs.file(fs.path.join('android', 'local.properties'))
      : fs.file(fs.path.join(projectPath, 'android', 'local.properties'));
  bool changed = false;

  SettingsFile settings;
  if (localProperties.existsSync()) {
    settings = new SettingsFile.parseFromFile(localProperties);
  } else {
    settings = new SettingsFile();
    settings.values['sdk.dir'] = escapePath(androidSdk.directory);
    changed = true;
  }
  final String escapedRoot = escapePath(Cache.flutterRoot);
  if (changed || settings.values['flutter.sdk'] != escapedRoot) {
    settings.values['flutter.sdk'] = escapedRoot;
    changed = true;
  }
  if (buildMode != null && settings.values['flutter.buildMode'] != buildMode) {
    settings.values['flutter.buildMode']  = buildMode;
    changed = true;
  }

  if (changed)
    settings.writeContents(localProperties);
}

Future<Null> buildGradleProject(BuildMode buildMode, String target, String kernelPath) async {
  // Update the local.properties file with the build mode.
  // FlutterPlugin v1 reads local.properties to determine build mode. Plugin v2
  // uses the standard Android way to determine what to build, but we still
  // update local.properties, in case we want to use it in the future.
  final String buildModeName = getModeName(buildMode);
  updateLocalProperties(buildMode: buildModeName);

  injectPlugins();

  final String gradle = ensureGradle();

  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend it's v1, and just go for it.
    case FlutterPluginVersion.v1:
      return buildGradleProjectV1(gradle);
    case FlutterPluginVersion.managed:
      // Fall through. Managed plugin builds the same way as plugin v2.
    case FlutterPluginVersion.v2:
      return buildGradleProjectV2(gradle, buildModeName, target, kernelPath);
  }
}

Future<Null> buildGradleProjectV1(String gradle) async {
  // Run 'gradle build'.
  final Status status = logger.startProgress('Running \'gradle build\'...', expectSlowOperation: true);
  final int exitcode = await runCommandAndStreamOutput(
    <String>[fs.file(gradle).absolute.path, 'build'],
    workingDirectory: 'android',
    allowReentrantFlutter: true,
    environment: _gradleEnv,
  );
  status.stop();

  if (exitcode != 0)
    throwToolExit('Gradle build failed: $exitcode', exitCode: exitcode);

  final File apkFile = fs.file(gradleAppOutV1);
  printStatus('Built $gradleAppOutV1 (${getSizeAsMB(apkFile.lengthSync())}).');
}

Future<Null> buildGradleProjectV2(String gradle, String buildModeName, String target, String kernelPath) async {
  final String assembleTask = "assemble${toTitleCase(buildModeName)}";

  // Run 'gradle assemble<BuildMode>'.
  final Status status = logger.startProgress('Running \'gradle $assembleTask\'...', expectSlowOperation: true);
  final String gradlePath = fs.file(gradle).absolute.path;
  final List<String> command = <String>[gradlePath];
  if (!logger.isVerbose) {
    command.add('-q');
  }
  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts;
    printTrace('Using local engine: ${localEngineArtifacts.engineOutPath}');
    command.add('-PlocalEngineOut=${localEngineArtifacts.engineOutPath}');
  }
  if (target != null) {
    command.add('-Ptarget=$target');
  }
  if (kernelPath != null)
    command.add('-Pkernel=$kernelPath');
  command.add(assembleTask);
  final int exitcode = await runCommandAndStreamOutput(
      command,
      workingDirectory: 'android',
      allowReentrantFlutter: true,
      environment: _gradleEnv,
  );
  status.stop();

  if (exitcode != 0)
    throwToolExit('Gradle build failed: $exitcode', exitCode: exitcode);

  final String buildDirectory = getGradleAppOutDirV2();
  final String apkFilename = 'app-$buildModeName.apk';
  final File apkFile = fs.file('$buildDirectory/$apkFilename');
  // Copy the APK to app.apk, so `flutter run`, `flutter install`, etc. can find it.
  apkFile.copySync('$buildDirectory/app.apk');

  printTrace('calculateSha: $buildDirectory/app.apk');
  final File apkShaFile = fs.file('$buildDirectory/app.apk.sha1');
  apkShaFile.writeAsStringSync(calculateSha(apkFile));

  printStatus('Built ${apkFile.path} (${getSizeAsMB(apkFile.lengthSync())}).');
}

Map<String, String> get _gradleEnv {
  final Map<String, String> env = new Map<String, String>.from(platform.environment);
  if (javaPath != null) {
    // Use java bundled with Android Studio.
    env['JAVA_HOME'] = javaPath;
  }
  return env;
}
