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
const String gradleVersion = '3.3';

String _cachedGradleAppOutDirV2;
String _cachedGradleExecutable;

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

Future<String> getGradleAppOut() async {
  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend we're v1, and just go with it.
    case FlutterPluginVersion.v1:
      return gradleAppOutV1;
    case FlutterPluginVersion.managed:
      // Fall through. The managed plugin matches plugin v2 for now.
    case FlutterPluginVersion.v2:
      return '${await _getGradleAppOutDirV2()}/app.apk';
  }
  return null;
}

Future<String> _getGradleAppOutDirV2() async {
  _cachedGradleAppOutDirV2 ??= await _calculateGradleAppOutDirV2();
  return _cachedGradleAppOutDirV2;
}

// Note: Dependencies are resolved and possibly downloaded as a side-effect
// of calculating the app properties using Gradle. This may take minutes.
Future<String> _calculateGradleAppOutDirV2() async {
  final String gradle = await _ensureGradle();
  updateLocalProperties();
  try {
    final Status status = logger.startProgress('Resolving dependencies...', expectSlowOperation: true);
    final RunResult runResult = await runCheckedAsync(
      <String>[gradle, 'app:properties'],
      workingDirectory: 'android',
      environment: _gradleEnv,
    );
    final String properties = runResult.stdout.trim();
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
    status.stop();
    return '$buildDir/outputs/apk';
  } catch (e) {
    printError('Error running gradle: $e');
  }
  // Fall back to the default
  return gradleAppOutDirV1;
}

String _locateProjectGradlew({ bool ensureExecutable: true }) {
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

Future<String> _ensureGradle() async {
  _cachedGradleExecutable ??= await _initializeGradle();
  return _cachedGradleExecutable;
}

// Note: Gradle may be bootstrapped and possibly downloaded as a side-effect
// of validating the Gradle executable. This may take several seconds.
Future<String> _initializeGradle() async {
  final Status status = logger.startProgress('Initializing gradle...', expectSlowOperation: true);
  String gradle = _locateProjectGradlew();
  if (gradle == null) {
    _injectGradleWrapper();
    gradle = _locateProjectGradlew();
  }
  if (gradle == null)
    throwToolExit('Unable to locate gradlew script');
  printTrace('Using gradle from $gradle.');
  // Validates the Gradle executable by asking for its version.
  // Makes Gradle Wrapper download and install Gradle distribution, if needed.
  await runCheckedAsync(<String>[gradle, '-v'], environment: _gradleEnv);
  status.stop();
  return gradle;
}

void _injectGradleWrapper() {
  copyDirectorySync(cache.getArtifactDirectory('gradle_wrapper'), fs.directory('android'));
  final String propertiesPath = fs.path.join('android', 'gradle', 'wrapper', 'gradle-wrapper.properties');
  if (!fs.file(propertiesPath).existsSync()) {
    fs.file(propertiesPath).writeAsStringSync('''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-$gradleVersion-all.zip
''', flush: true,
    );
  }
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

Future<Null> buildGradleProject(BuildMode buildMode, String target, bool previewDart2) async {
  // Update the local.properties file with the build mode.
  // FlutterPlugin v1 reads local.properties to determine build mode. Plugin v2
  // uses the standard Android way to determine what to build, but we still
  // update local.properties, in case we want to use it in the future.
  final String buildModeName = getModeName(buildMode);
  updateLocalProperties(buildMode: buildModeName);

  injectPlugins();

  final String gradle = await _ensureGradle();

  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend it's v1, and just go for it.
    case FlutterPluginVersion.v1:
      return _buildGradleProjectV1(gradle);
    case FlutterPluginVersion.managed:
      // Fall through. Managed plugin builds the same way as plugin v2.
    case FlutterPluginVersion.v2:
      return _buildGradleProjectV2(gradle, buildModeName, target, previewDart2);
  }
}

Future<Null> _buildGradleProjectV1(String gradle) async {
  // Run 'gradlew build'.
  final Status status = logger.startProgress('Running \'gradlew build\'...', expectSlowOperation: true);
  final int exitCode = await runCommandAndStreamOutput(
    <String>[fs.file(gradle).absolute.path, 'build'],
    workingDirectory: 'android',
    allowReentrantFlutter: true,
    environment: _gradleEnv,
  );
  status.stop();

  if (exitCode != 0)
    throwToolExit('Gradle build failed: $exitCode', exitCode: exitCode);

  final File apkFile = fs.file(gradleAppOutV1);
  printStatus('Built $gradleAppOutV1 (${getSizeAsMB(apkFile.lengthSync())}).');
}

File findApkFile(String buildDirectory, String buildModeName) {
  final String apkFilename = 'app-$buildModeName.apk';
  File apkFile = fs.file('$buildDirectory/$apkFilename');
  if (apkFile.existsSync())
    return apkFile;
  apkFile = fs.file('$buildDirectory/$buildModeName/$apkFilename');
  if (apkFile.existsSync())
    return apkFile;
  return null;
}

Future<Null> _buildGradleProjectV2(String gradle, String buildModeName, String target, bool previewDart2) async {
  final String assembleTask = "assemble${toTitleCase(buildModeName)}";

  // Run 'gradlew assemble<BuildMode>'.
  final Status status = logger.startProgress('Running \'gradlew $assembleTask\'...', expectSlowOperation: true);
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
  if (previewDart2)
    command.add('-Ppreview-dart-2=true');
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

  final String buildDirectory = await _getGradleAppOutDirV2();
  final File apkFile = findApkFile(buildDirectory, buildModeName);
  if (apkFile == null)
    throwToolExit('Gradle build failed to produce an Android package.');
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
