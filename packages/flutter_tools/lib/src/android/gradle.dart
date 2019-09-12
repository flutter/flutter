// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../flutter_manifest.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import 'android_sdk.dart';
import 'android_studio.dart';

/// Gradle utils in the current [AppContext].
GradleUtils get gradleUtils => context.get<GradleUtils>();

/// Provides utilities to run a Gradle task,
/// such as finding the Gradle executable or constructing a Gradle project.
class GradleUtils {
  /// Empty constructor.
  GradleUtils();

  String _cachedExecutable;
  /// Gets the Gradle executable path.
  /// This is the `gradlew` or `gradlew.bat` script in the `android/` directory.
  Future<String> getExecutable(FlutterProject project) async {
    _cachedExecutable ??= await _initializeGradle(project);
    return _cachedExecutable;
  }

  GradleProject _cachedAppProject;
  /// Gets the [GradleProject] for the current [FlutterProject] if built as an app.
  Future<GradleProject> get appProject async {
    _cachedAppProject ??= await _readGradleProject(isLibrary: false);
    return _cachedAppProject;
  }

  GradleProject _cachedLibraryProject;
  /// Gets the [GradleProject] for the current [FlutterProject] if built as a library.
  Future<GradleProject> get libraryProject async {
    _cachedLibraryProject ??= await _readGradleProject(isLibrary: true);
    return _cachedLibraryProject;
  }
}

final RegExp _assembleTaskPattern = RegExp(r'assemble(\S+)');

enum FlutterPluginVersion {
  none,
  v1,
  v2,
  managed,
}

// Investigation documented in #13975 suggests the filter should be a subset
// of the impact of -q, but users insist they see the error message sometimes
// anyway.  If we can prove it really is impossible, delete the filter.
// This technically matches everything *except* the NDK message, since it's
// passed to a function that filters out all lines that don't match a filter.
final RegExp ndkMessageFilter = RegExp(r'^(?!NDK is missing a ".*" directory'
  r'|If you are not using NDK, unset the NDK variable from ANDROID_NDK_HOME or local.properties to remove this warning'
  r'|If you are using NDK, verify the ndk.dir is set to a valid NDK directory.  It is currently set to .*)');

// This regex is intentionally broad. AndroidX errors can manifest in multiple
// different ways and each one depends on the specific code config and
// filesystem paths of the project. Throwing the broadest net possible here to
// catch all known and likely cases.
//
// Example stack traces:
//
// https://github.com/flutter/flutter/issues/27226 "AAPT: error: resource android:attr/fontVariationSettings not found."
// https://github.com/flutter/flutter/issues/27106 "Android resource linking failed|Daemon: AAPT2|error: failed linking references"
// https://github.com/flutter/flutter/issues/27493 "error: cannot find symbol import androidx.annotation.NonNull;"
// https://github.com/flutter/flutter/issues/23995 "error: package android.support.annotation does not exist import android.support.annotation.NonNull;"
final RegExp androidXFailureRegex = RegExp(r'(AAPT|androidx|android\.support)');

final RegExp androidXPluginWarningRegex = RegExp(r'\*{57}'
  r"|WARNING: This version of (\w+) will break your Android build if it or its dependencies aren't compatible with AndroidX."
  r'|See https://goo.gl/CP92wY for more information on the problem and how to fix it.'
  r'|This warning prints for all Android build failures. The real root cause of the error may be unrelated.');

FlutterPluginVersion getFlutterPluginVersion(AndroidProject project) {
  final File plugin = project.hostAppGradleRoot.childFile(
      fs.path.join('buildSrc', 'src', 'main', 'groovy', 'FlutterPlugin.groovy'));
  if (plugin.existsSync()) {
    final String packageLine = plugin.readAsLinesSync().skip(4).first;
    if (packageLine == 'package io.flutter.gradle') {
      return FlutterPluginVersion.v2;
    }
    return FlutterPluginVersion.v1;
  }
  final File appGradle = project.hostAppGradleRoot.childFile(
      fs.path.join('app', 'build.gradle'));
  if (appGradle.existsSync()) {
    for (String line in appGradle.readAsLinesSync()) {
      if (line.contains(RegExp(r'apply from: .*/flutter.gradle'))) {
        return FlutterPluginVersion.managed;
      }
      if (line.contains("def flutterPluginVersion = 'managed'")) {
        return FlutterPluginVersion.managed;
      }
    }
  }
  return FlutterPluginVersion.none;
}

/// Returns the apk file created by [buildGradleProject]
Future<File> getGradleAppOut(AndroidProject androidProject) async {
  switch (getFlutterPluginVersion(androidProject)) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend we're v1, and just go with it.
    case FlutterPluginVersion.v1:
      return androidProject.gradleAppOutV1File;
    case FlutterPluginVersion.managed:
      // Fall through. The managed plugin matches plugin v2 for now.
    case FlutterPluginVersion.v2:
      final GradleProject gradleProject = await gradleUtils.appProject;
      return fs.file(gradleProject.apkDirectory.childFile('app.apk'));
  }
  return null;
}

/// Runs `gradlew dependencies`, ensuring that dependencies are resolved and
/// potentially downloaded.
Future<void> checkGradleDependencies() async {
  final Status progress = logger.startProgress('Ensuring gradle dependencies are up to date...', timeout: timeoutConfiguration.slowOperation);
  final FlutterProject flutterProject = FlutterProject.current();
  final String gradlew = await gradleUtils.getExecutable(flutterProject);
  await processUtils.run(
    <String>[gradlew, 'dependencies'],
    throwOnError: true,
    workingDirectory: flutterProject.android.hostAppGradleRoot.path,
    environment: _gradleEnv,
  );
  androidSdk.reinitialize();
  progress.stop();
}

/// Tries to create `settings_aar.gradle` in an app project by removing the subprojects
/// from the existing `settings.gradle` file. This operation will fail if the existing
/// `settings.gradle` file has local edits.
void createSettingsAarGradle(Directory androidDirectory) {
  final File newSettingsFile = androidDirectory.childFile('settings_aar.gradle');
  if (newSettingsFile.existsSync()) {
    return;
  }
  final File currentSettingsFile = androidDirectory.childFile('settings.gradle');
  if (!currentSettingsFile.existsSync()) {
    return;
  }
  final String currentFileContent = currentSettingsFile.readAsStringSync();

  final String newSettingsRelativeFile = fs.path.relative(newSettingsFile.path);
  final Status status = logger.startProgress('✏️  Creating `$newSettingsRelativeFile`...',
      timeout: timeoutConfiguration.fastOperation);

  final String flutterRoot = fs.path.absolute(Cache.flutterRoot);
  final File deprecatedFile = fs.file(fs.path.join(flutterRoot, 'packages','flutter_tools',
      'gradle', 'deprecated_settings.gradle'));
  assert(deprecatedFile.existsSync());
  final String settingsAarContent = fs.file(fs.path.join(flutterRoot, 'packages','flutter_tools',
      'gradle', 'settings_aar.gradle.tmpl')).readAsStringSync();

  // Get the `settings.gradle` content variants that should be patched.
  final List<String> existingVariants = deprecatedFile.readAsStringSync().split(';EOF');
  existingVariants.add(settingsAarContent);

  bool exactMatch = false;
  for (String fileContentVariant in existingVariants) {
    if (currentFileContent.trim() == fileContentVariant.trim()) {
      exactMatch = true;
      break;
    }
  }
  if (!exactMatch) {
    status.cancel();
    printError('*******************************************************************************************');
    printError('Flutter tried to create the file `$newSettingsRelativeFile`, but failed.');
    // Print how to manually update the file.
    printError(fs.file(fs.path.join(flutterRoot, 'packages','flutter_tools',
        'gradle', 'manual_migration_settings.gradle.md')).readAsStringSync());
    printError('*******************************************************************************************');
    throwToolExit('Please create the file and run this command again.');
  }
  // Copy the new file.
  newSettingsFile.writeAsStringSync(settingsAarContent);
  status.stop();
  printStatus('✅ `$newSettingsRelativeFile` created successfully.');
}

// Note: Dependencies are resolved and possibly downloaded as a side-effect
// of calculating the app properties using Gradle. This may take minutes.
Future<GradleProject> _readGradleProject({bool isLibrary = false}) async {
  final FlutterProject flutterProject = FlutterProject.current();
  final String gradlew = await gradleUtils.getExecutable(flutterProject);

  updateLocalProperties(project: flutterProject);

  final FlutterManifest manifest = flutterProject.manifest;
  final Directory hostAppGradleRoot = flutterProject.android.hostAppGradleRoot;

  if (featureFlags.isPluginAsAarEnabled &&
      !manifest.isPlugin && !manifest.isModule) {
    createSettingsAarGradle(hostAppGradleRoot);
  }
  if (manifest.isPlugin) {
    assert(isLibrary);
    return GradleProject(
      <String>['debug', 'profile', 'release'],
      <String>[], // Plugins don't have flavors.
      flutterProject.directory.childDirectory('build').path,
    );
  }
  final Status status = logger.startProgress('Resolving dependencies...', timeout: timeoutConfiguration.slowOperation);
  GradleProject project;
  // Get the properties and tasks from Gradle, so we can determinate the `buildDir`,
  // flavors and build types defined in the project. If gradle fails, then check if the failure is due to t
  try {
    final RunResult propertiesRunResult = await processUtils.run(
      <String>[gradlew, isLibrary ? 'properties' : 'app:properties'],
      throwOnError: true,
      workingDirectory: hostAppGradleRoot.path,
      environment: _gradleEnv,
    );
    final RunResult tasksRunResult = await processUtils.run(
      <String>[gradlew, isLibrary ? 'tasks': 'app:tasks', '--all', '--console=auto'],
      throwOnError: true,
      workingDirectory: hostAppGradleRoot.path,
      environment: _gradleEnv,
    );
    project = GradleProject.fromAppProperties(propertiesRunResult.stdout, tasksRunResult.stdout);
  } catch (exception) {
    if (getFlutterPluginVersion(flutterProject.android) == FlutterPluginVersion.managed) {
      status.cancel();
      // Handle known exceptions.
      throwToolExitIfLicenseNotAccepted(exception);
      // Print a general Gradle error and exit.
      printError('* Error running Gradle:\n$exception\n');
      throwToolExit('Please review your Gradle project setup in the android/ folder.');
    }
    // Fall back to the default
    project = GradleProject(
      <String>['debug', 'profile', 'release'],
      <String>[],
      fs.path.join(flutterProject.android.hostAppGradleRoot.path, 'app', 'build')
    );
  }
  status.stop();
  return project;
}

/// Handle Gradle error thrown when Gradle needs to download additional
/// Android SDK components (e.g. Platform Tools), and the license
/// for that component has not been accepted.
void throwToolExitIfLicenseNotAccepted(Exception exception) {
  const String licenseNotAcceptedMatcher =
    r'You have not accepted the license agreements of the following SDK components:'
    r'\s*\[(.+)\]';
  final RegExp licenseFailure = RegExp(licenseNotAcceptedMatcher, multiLine: true);
  final Match licenseMatch = licenseFailure.firstMatch(exception.toString());
  if (licenseMatch != null) {
    final String missingLicenses = licenseMatch.group(1);
    final String errorMessage =
      '\n\n* Error running Gradle:\n'
      'Unable to download needed Android SDK components, as the following licenses have not been accepted:\n'
      '$missingLicenses\n\n'
      'To resolve this, please run the following command in a Terminal:\n'
      'flutter doctor --android-licenses';
    throwToolExit(errorMessage);
  }
}

String _locateGradlewExecutable(Directory directory) {
  final File gradle = directory.childFile(
    platform.isWindows ? 'gradlew.bat' : 'gradlew',
  );
  if (gradle.existsSync()) {
    return gradle.absolute.path;
  }
  return null;
}

// Note: Gradle may be bootstrapped and possibly downloaded as a side-effect
// of validating the Gradle executable. This may take several seconds.
Future<String> _initializeGradle(FlutterProject project) async {
  final Directory android = project.android.hostAppGradleRoot;
  final Status status = logger.startProgress('Initializing gradle...',
      timeout: timeoutConfiguration.slowOperation);

  injectGradleWrapperIfNeeded(android);

  final String gradle = _locateGradlewExecutable(android);
  if (gradle == null) {
    status.stop();
    throwToolExit('Unable to locate gradlew script');
  }
  printTrace('Using gradle from $gradle.');
  // Validates the Gradle executable by asking for its version.
  // Makes Gradle Wrapper download and install Gradle distribution, if needed.
  try {
    await processUtils.run(
      <String>[gradle, '-v'],
      throwOnError: true,
      environment: _gradleEnv,
    );
  } on ProcessException catch (e) {
    final String error = e.toString();
    if (error.contains('java.io.FileNotFoundException: https://downloads.gradle.org') ||
        error.contains('java.io.IOException: Unable to tunnel through proxy')) {
      throwToolExit('$gradle threw an error while trying to update itself.\n$e');
    }
    rethrow;
  } finally {
    status.stop();
  }
  return gradle;
}

/// Injects the Gradle wrapper files if any of these files don't exist in [directory].
void injectGradleWrapperIfNeeded(Directory directory) {
  copyDirectorySync(
    cache.getArtifactDirectory('gradle_wrapper'),
    directory,
    shouldCopyFile: (File sourceFile, File destinationFile) {
      // Don't override the existing files in the project.
      return !destinationFile.existsSync();
    },
    onFileCopied: (File sourceFile, File destinationFile) {
      final String modes = sourceFile.statSync().modeString();
      if (modes != null && modes.contains('x')) {
        os.makeExecutable(destinationFile);
      }
    },
  );
  // Add the `gradle-wrapper.properties` file if it doesn't exist.
  final File propertiesFile = directory.childFile(
      fs.path.join('gradle', 'wrapper', 'gradle-wrapper.properties'));
  if (!propertiesFile.existsSync()) {
    final String gradleVersion = getGradleVersionForAndroidPlugin(directory);
    propertiesFile.writeAsStringSync('''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-$gradleVersion-all.zip
''', flush: true,
    );
  }
}

/// Returns true if [targetVersion] is within the range [min] and [max] inclusive.
bool _isWithinVersionRange(String targetVersion, {String min, String max}) {
  final Version parsedTargetVersion = Version.parse(targetVersion);
  return parsedTargetVersion >= Version.parse(min) &&
      parsedTargetVersion <= Version.parse(max);
}

const String defaultGradleVersion = '4.10.2';

/// Returns the Gradle version that is required by the given Android Gradle plugin version
/// by picking the largest compatible version from
/// https://developer.android.com/studio/releases/gradle-plugin#updating-gradle
String getGradleVersionFor(String androidPluginVersion) {
  if (_isWithinVersionRange(androidPluginVersion, min: '1.0.0', max: '1.1.3')) {
    return '2.3';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '1.2.0', max: '1.3.1')) {
    return '2.9';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '1.5.0', max: '1.5.0')) {
    return '2.2.1';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '2.0.0', max: '2.1.2')) {
    return '2.13';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '2.1.3', max: '2.2.3')) {
    return '2.14.1';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '2.3.0', max: '2.9.9')) {
    return '3.3';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '3.0.0', max: '3.0.9')) {
    return '4.1';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '3.1.0', max: '3.1.9')) {
    return '4.4';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '3.2.0', max: '3.2.1')) {
    return '4.6';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '3.3.0', max: '3.3.2')) {
    return '4.10.2';
  }
  if (_isWithinVersionRange(androidPluginVersion, min: '3.4.0', max: '3.5.0')) {
    return '5.1.1';
  }
  throwToolExit('Unsuported Android Plugin version: $androidPluginVersion.');
  return '';
}

final RegExp _androidPluginRegExp = RegExp('com\.android\.tools\.build\:gradle\:(\\d+\.\\d+\.\\d+\)');

/// Returns the Gradle version that the current Android plugin depends on when found,
/// otherwise it returns a default version.
///
/// The Android plugin version is specified in the [build.gradle] file within
/// the project's Android directory.
String getGradleVersionForAndroidPlugin(Directory directory) {
  final File buildFile = directory.childFile('build.gradle');
  if (!buildFile.existsSync()) {
    return defaultGradleVersion;
  }
  final String buildFileContent = buildFile.readAsStringSync();
  final Iterable<Match> pluginMatches = _androidPluginRegExp.allMatches(buildFileContent);

  if (pluginMatches.isEmpty) {
    return defaultGradleVersion;
  }
  final String androidPluginVersion = pluginMatches.first.group(1);
  return getGradleVersionFor(androidPluginVersion);
}

/// Overwrite local.properties in the specified Flutter project's Android
/// sub-project, if needed.
///
/// If [requireAndroidSdk] is true (the default) and no Android SDK is found,
/// this will fail with a [ToolExit].
void updateLocalProperties({
  @required FlutterProject project,
  BuildInfo buildInfo,
  bool requireAndroidSdk = true,
}) {
  if (requireAndroidSdk) {
    _exitIfNoAndroidSdk();
  }

  final File localProperties = project.android.localPropertiesFile;
  bool changed = false;

  SettingsFile settings;
  if (localProperties.existsSync()) {
    settings = SettingsFile.parseFromFile(localProperties);
  } else {
    settings = SettingsFile();
    changed = true;
  }

  void changeIfNecessary(String key, String value) {
    if (settings.values[key] != value) {
      if (value == null) {
        settings.values.remove(key);
      } else {
        settings.values[key] = value;
      }
      changed = true;
    }
  }

  final FlutterManifest manifest = project.manifest;

  if (androidSdk != null)
    changeIfNecessary('sdk.dir', escapePath(androidSdk.directory));

  changeIfNecessary('flutter.sdk', escapePath(Cache.flutterRoot));

  if (buildInfo != null) {
    changeIfNecessary('flutter.buildMode', buildInfo.modeName);
    final String buildName = validatedBuildNameForPlatform(TargetPlatform.android_arm, buildInfo.buildName ?? manifest.buildName);
    changeIfNecessary('flutter.versionName', buildName);
    final String buildNumber = validatedBuildNumberForPlatform(TargetPlatform.android_arm, buildInfo.buildNumber ?? manifest.buildNumber);
    changeIfNecessary('flutter.versionCode', buildNumber?.toString());
  }

  if (changed)
    settings.writeContents(localProperties);
}

/// Writes standard Android local properties to the specified [properties] file.
///
/// Writes the path to the Android SDK, if known.
void writeLocalProperties(File properties) {
  final SettingsFile settings = SettingsFile();
  if (androidSdk != null) {
    settings.values['sdk.dir'] = escapePath(androidSdk.directory);
  }
  settings.writeContents(properties);
}

/// Throws a ToolExit, if the path to the Android SDK is not known.
void _exitIfNoAndroidSdk() {
  if (androidSdk == null) {
    throwToolExit('Unable to locate Android SDK. Please run `flutter doctor` for more details.');
  }
}

Future<void> buildGradleProject({
  @required FlutterProject project,
  @required AndroidBuildInfo androidBuildInfo,
  @required String target,
  @required bool isBuildingBundle,
}) async {
  // Update the local.properties file with the build mode, version name and code.
  // FlutterPlugin v1 reads local.properties to determine build mode. Plugin v2
  // uses the standard Android way to determine what to build, but we still
  // update local.properties, in case we want to use it in the future.
  // Version name and number are provided by the pubspec.yaml file
  // and can be overwritten with flutter build command.
  // The default Gradle script reads the version name and number
  // from the local.properties file.
  updateLocalProperties(project: project, buildInfo: androidBuildInfo.buildInfo);

  switch (getFlutterPluginVersion(project.android)) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend it's v1, and just go for it.
    case FlutterPluginVersion.v1:
      return _buildGradleProjectV1(project);
    case FlutterPluginVersion.managed:
      // Fall through. Managed plugin builds the same way as plugin v2.
    case FlutterPluginVersion.v2:
      return _buildGradleProjectV2(project, androidBuildInfo, target, isBuildingBundle);
  }
}

Future<void> buildGradleAar({
  @required FlutterProject project,
  @required AndroidBuildInfo androidBuildInfo,
  @required String target,
  @required String outputDir,
}) async {
  final FlutterManifest manifest = project.manifest;

  GradleProject gradleProject;
  if (manifest.isModule) {
    gradleProject = await gradleUtils.appProject;
  } else if (manifest.isPlugin) {
    gradleProject = await gradleUtils.libraryProject;
  } else {
    throwToolExit('AARs can only be built for plugin or module projects.');
  }

  if (outputDir != null && outputDir.isNotEmpty) {
    gradleProject.buildDirectory = outputDir;
  }

  final String aarTask = gradleProject.aarTaskFor(androidBuildInfo.buildInfo);
  if (aarTask == null) {
    printUndefinedTask(gradleProject, androidBuildInfo.buildInfo);
    throwToolExit('Gradle build aborted.');
  }
  final Status status = logger.startProgress(
    'Running Gradle task \'$aarTask\'...',
    timeout: timeoutConfiguration.slowOperation,
    multilineOutput: true,
  );

  final String gradlew = await gradleUtils.getExecutable(project);
  final String flutterRoot = fs.path.absolute(Cache.flutterRoot);
  final String initScript = fs.path.join(flutterRoot, 'packages','flutter_tools', 'gradle', 'aar_init_script.gradle');
  final List<String> command = <String>[
    gradlew,
    '-I=$initScript',
    '-Pflutter-root=$flutterRoot',
    '-Poutput-dir=${gradleProject.buildDirectory}',
    '-Pis-plugin=${manifest.isPlugin}',
    '-Dbuild-plugins-as-aars=true',
  ];

  if (target != null && target.isNotEmpty) {
    command.add('-Ptarget=$target');
  }

  if (androidBuildInfo.targetArchs.isNotEmpty) {
    final String targetPlatforms = androidBuildInfo.targetArchs
        .map(getPlatformNameForAndroidArch).join(',');
    command.add('-Ptarget-platform=$targetPlatforms');
  }
  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts;
    printTrace('Using local engine: ${localEngineArtifacts.engineOutPath}');
    command.add('-PlocalEngineOut=${localEngineArtifacts.engineOutPath}');
  }

  command.add(aarTask);

  final Stopwatch sw = Stopwatch()..start();
  int exitCode = 1;

  try {
    exitCode = await processUtils.stream(
      command,
      workingDirectory: project.android.hostAppGradleRoot.path,
      allowReentrantFlutter: true,
      environment: _gradleEnv,
      mapFunction: (String line) {
        // Always print the full line in verbose mode.
        if (logger.isVerbose) {
          return line;
        }
        return null;
      },
    );
  } finally {
    status.stop();
  }
  flutterUsage.sendTiming('build', 'gradle-aar', Duration(milliseconds: sw.elapsedMilliseconds));

  if (exitCode != 0) {
    throwToolExit('Gradle task $aarTask failed with exit code $exitCode', exitCode: exitCode);
  }

  final Directory repoDirectory = gradleProject.repoDirectory;
  if (!repoDirectory.existsSync()) {
    throwToolExit('Gradle task $aarTask failed to produce $repoDirectory', exitCode: exitCode);
  }
  printStatus('Built ${fs.path.relative(repoDirectory.path)}.', color: TerminalColor.green);
}

Future<void> _buildGradleProjectV1(FlutterProject project) async {
  final String gradlew = await gradleUtils.getExecutable(project);
  // Run 'gradlew build'.
  final Status status = logger.startProgress(
    'Running \'gradlew build\'...',
    timeout: timeoutConfiguration.slowOperation,
    multilineOutput: true,
  );
  final Stopwatch sw = Stopwatch()..start();
  final int exitCode = await processUtils.stream(
    <String>[fs.file(gradlew).absolute.path, 'build'],
    workingDirectory: project.android.hostAppGradleRoot.path,
    allowReentrantFlutter: true,
    environment: _gradleEnv,
  );
  status.stop();
  flutterUsage.sendTiming('build', 'gradle-v1', Duration(milliseconds: sw.elapsedMilliseconds));

  if (exitCode != 0)
    throwToolExit('Gradle build failed: $exitCode', exitCode: exitCode);

  printStatus('Built ${fs.path.relative(project.android.gradleAppOutV1File.path)}.');
}

String _hex(List<int> bytes) {
  final StringBuffer result = StringBuffer();
  for (int part in bytes)
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  return result.toString();
}

String _calculateSha(File file) {
  final Stopwatch sw = Stopwatch()..start();
  final List<int> bytes = file.readAsBytesSync();
  printTrace('calculateSha: reading file took ${sw.elapsedMilliseconds}us');
  flutterUsage.sendTiming('build', 'apk-sha-read', Duration(milliseconds: sw.elapsedMilliseconds));
  sw.reset();
  final String sha = _hex(sha1.convert(bytes).bytes);
  printTrace('calculateSha: computing sha took ${sw.elapsedMilliseconds}us');
  flutterUsage.sendTiming('build', 'apk-sha-calc', Duration(milliseconds: sw.elapsedMilliseconds));
  return sha;
}

void printUndefinedTask(GradleProject project, BuildInfo buildInfo) {
  printError('');
  printError('The Gradle project does not define a task suitable for the requested build.');
  if (!project.buildTypes.contains(buildInfo.modeName)) {
    printError('Review the android/app/build.gradle file and ensure it defines a ${buildInfo.modeName} build type.');
    return;
  }
  if (project.productFlavors.isEmpty) {
    printError('The android/app/build.gradle file does not define any custom product flavors.');
    printError('You cannot use the --flavor option.');
  } else {
    printError('The android/app/build.gradle file defines product flavors: ${project.productFlavors.join(', ')}');
    printError('You must specify a --flavor option to select one of them.');
  }
}

Future<void> _buildGradleProjectV2(
  FlutterProject flutterProject,
  AndroidBuildInfo androidBuildInfo,
  String target,
  bool isBuildingBundle,
) async {
  final String gradlew = await gradleUtils.getExecutable(flutterProject);
  final GradleProject project = await gradleUtils.appProject;
  final BuildInfo buildInfo = androidBuildInfo.buildInfo;

  String assembleTask;

  if (isBuildingBundle) {
    assembleTask = project.bundleTaskFor(buildInfo);
  } else {
    assembleTask = project.assembleTaskFor(buildInfo);
  }
  if (assembleTask == null) {
    printUndefinedTask(project, buildInfo);
    throwToolExit('Gradle build aborted.');
  }
  final Status status = logger.startProgress(
    'Running Gradle task \'$assembleTask\'...',
    timeout: timeoutConfiguration.slowOperation,
    multilineOutput: true,
  );
  final List<String> command = <String>[gradlew];
  if (logger.isVerbose) {
    command.add('-Pverbose=true');
  } else {
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
  assert(buildInfo.trackWidgetCreation != null);
  command.add('-Ptrack-widget-creation=${buildInfo.trackWidgetCreation}');
  if (buildInfo.extraFrontEndOptions != null)
    command.add('-Pextra-front-end-options=${buildInfo.extraFrontEndOptions}');
  if (buildInfo.extraGenSnapshotOptions != null)
    command.add('-Pextra-gen-snapshot-options=${buildInfo.extraGenSnapshotOptions}');
  if (buildInfo.fileSystemRoots != null && buildInfo.fileSystemRoots.isNotEmpty)
    command.add('-Pfilesystem-roots=${buildInfo.fileSystemRoots.join('|')}');
  if (buildInfo.fileSystemScheme != null)
    command.add('-Pfilesystem-scheme=${buildInfo.fileSystemScheme}');
  if (androidBuildInfo.splitPerAbi)
    command.add('-Psplit-per-abi=true');
  if (androidBuildInfo.proguard)
    command.add('-Pproguard=true');
  if (androidBuildInfo.targetArchs.isNotEmpty) {
    final String targetPlatforms = androidBuildInfo.targetArchs
        .map(getPlatformNameForAndroidArch).join(',');
    command.add('-Ptarget-platform=$targetPlatforms');
  }
  if (featureFlags.isPluginAsAarEnabled) {
     // Pass a system flag instead of a project flag, so this flag can be
     // read from include_flutter.groovy.
    command.add('-Dbuild-plugins-as-aars=true');
    if (!flutterProject.manifest.isModule) {
      command.add('--settings-file=settings_aar.gradle');
    }
  }
  command.add(assembleTask);
  bool potentialAndroidXFailure = false;
  bool potentialProguardFailure = false;
  final Stopwatch sw = Stopwatch()..start();
  int exitCode = 1;
  try {
    exitCode = await processUtils.stream(
      command,
      workingDirectory: flutterProject.android.hostAppGradleRoot.path,
      allowReentrantFlutter: true,
      environment: _gradleEnv,
      // TODO(mklim): if AndroidX warnings are no longer required, this
      // mapFunction and all its associated variabled can be replaced with just
      // `filter: ndkMessagefilter`.
      mapFunction: (String line) {
        final bool isAndroidXPluginWarning = androidXPluginWarningRegex.hasMatch(line);
        if (!isAndroidXPluginWarning && androidXFailureRegex.hasMatch(line)) {
          potentialAndroidXFailure = true;
        }
        // Proguard errors include this url.
        if (!potentialProguardFailure && androidBuildInfo.proguard &&
            line.contains('http://proguard.sourceforge.net')) {
          potentialProguardFailure = true;
        }
        // Always print the full line in verbose mode.
        if (logger.isVerbose) {
          return line;
        } else if (isAndroidXPluginWarning || !ndkMessageFilter.hasMatch(line)) {
          return null;
        }
        return line;
      },
    );
  } finally {
    status.stop();
  }

  if (exitCode != 0) {
    if (potentialProguardFailure) {
      final String exclamationMark = terminal.color('[!]', TerminalColor.red);
      printStatus('$exclamationMark Proguard may have failed to optimize the Java bytecode.', emphasis: true);
      printStatus('To disable proguard, pass the `--no-proguard` flag to this command.', indent: 4);
      printStatus('To learn more about Proguard, see: https://flutter.dev/docs/deployment/android#enabling-proguard', indent: 4);
      BuildEvent('proguard-failure').send();
    } else if (potentialAndroidXFailure) {
      printStatus('AndroidX incompatibilities may have caused this build to fail. See https://goo.gl/CP92wY.');
      BuildEvent('android-x-failure').send();
    }
    throwToolExit('Gradle task $assembleTask failed with exit code $exitCode', exitCode: exitCode);
  }
  flutterUsage.sendTiming('build', 'gradle-v2', Duration(milliseconds: sw.elapsedMilliseconds));

  if (!isBuildingBundle) {
    final Iterable<File> apkFiles = findApkFiles(project, androidBuildInfo);
    if (apkFiles.isEmpty)
      throwToolExit('Gradle build failed to produce an Android package.');
    // Copy the first APK to app.apk, so `flutter run`, `flutter install`, etc. can find it.
    // TODO(blasten): Handle multiple APKs.
    apkFiles.first.copySync(project.apkDirectory.childFile('app.apk').path);

    printTrace('calculateSha: ${project.apkDirectory}/app.apk');
    final File apkShaFile = project.apkDirectory.childFile('app.apk.sha1');
    apkShaFile.writeAsStringSync(_calculateSha(apkFiles.first));

    for (File apkFile in apkFiles) {
      String appSize;
      if (buildInfo.mode == BuildMode.debug) {
        appSize = '';
      } else {
        appSize = ' (${getSizeAsMB(apkFile.lengthSync())})';
      }
      printStatus('Built ${fs.path.relative(apkFile.path)}$appSize.',
          color: TerminalColor.green);
    }
  } else {
    final File bundleFile = findBundleFile(project, buildInfo);
    if (bundleFile == null)
      throwToolExit('Gradle build failed to produce an Android bundle package.');

    String appSize;
    if (buildInfo.mode == BuildMode.debug) {
      appSize = '';
    } else {
      appSize = ' (${getSizeAsMB(bundleFile.lengthSync())})';
    }
    printStatus('Built ${fs.path.relative(bundleFile.path)}$appSize.',
        color: TerminalColor.green);
  }
}

@visibleForTesting
Iterable<File> findApkFiles(GradleProject project, AndroidBuildInfo androidBuildInfo) {
  final Iterable<String> apkFileNames = project.apkFilesFor(androidBuildInfo);
  if (apkFileNames.isEmpty)
    return const <File>[];

  return apkFileNames.expand<File>((String apkFileName) {
    File apkFile = project.apkDirectory.childFile(apkFileName);
    if (apkFile.existsSync())
      return <File>[apkFile];
    final BuildInfo buildInfo = androidBuildInfo.buildInfo;
    final String modeName = camelCase(buildInfo.modeName);
    apkFile = project.apkDirectory
        .childDirectory(modeName)
        .childFile(apkFileName);
    if (apkFile.existsSync())
      return <File>[apkFile];
    if (buildInfo.flavor != null) {
      // Android Studio Gradle plugin v3 adds flavor to path.
      apkFile = project.apkDirectory
          .childDirectory(buildInfo.flavor)
          .childDirectory(modeName)
          .childFile(apkFileName);
      if (apkFile.existsSync())
        return <File>[apkFile];
    }
    return const <File>[];
  });
}

@visibleForTesting
File findBundleFile(GradleProject project, BuildInfo buildInfo) {
  final List<File> fileCandidates = <File>[
    project.bundleDirectory
      .childDirectory(camelCase(buildInfo.modeName))
      .childFile('app.aab'),
    project.bundleDirectory
      .childDirectory(camelCase(buildInfo.modeName))
      .childFile('app-${buildInfo.modeName}.aab'),
  ];

  if (buildInfo.flavor != null) {
    // The Android Gradle plugin 3.0.0 adds the flavor name to the path.
    // For example: In release mode, if the flavor name is `foo_bar`, then
    // the directory name is `foo_barRelease`.
    fileCandidates.add(
      project.bundleDirectory
        .childDirectory('${buildInfo.flavor}${camelCase('_' + buildInfo.modeName)}')
        .childFile('app.aab'));

    // The Android Gradle plugin 3.5.0 adds the flavor name to file name.
    // For example: In release mode, if the flavor name is `foo_bar`, then
    // the file name name is `app-foo_bar-release.aab`.
    fileCandidates.add(
      project.bundleDirectory
        .childDirectory('${buildInfo.flavor}${camelCase('_' + buildInfo.modeName)}')
        .childFile('app-${buildInfo.flavor}-${buildInfo.modeName}.aab'));
  }
  for (final File bundleFile in fileCandidates) {
    if (bundleFile.existsSync()) {
      return bundleFile;
    }
  }
  return null;
}

Map<String, String> get _gradleEnv {
  final Map<String, String> env = Map<String, String>.from(platform.environment);
  if (javaPath != null) {
    // Use java bundled with Android Studio.
    env['JAVA_HOME'] = javaPath;
  }
  // Don't log analytics for downstream Flutter commands.
  // e.g. `flutter build bundle`.
  env['FLUTTER_SUPPRESS_ANALYTICS'] = 'true';
  return env;
}

class GradleProject {
  GradleProject(
    this.buildTypes,
    this.productFlavors,
    this.buildDirectory,
  );

  factory GradleProject.fromAppProperties(String properties, String tasks) {
    // Extract build directory.
    final String buildDirectory = properties
        .split('\n')
        .firstWhere((String s) => s.startsWith('buildDir: '))
        .substring('buildDir: '.length)
        .trim();

    // Extract build types and product flavors.
    final Set<String> variants = <String>{};
    for (String s in tasks.split('\n')) {
      final Match match = _assembleTaskPattern.matchAsPrefix(s);
      if (match != null) {
        final String variant = match.group(1).toLowerCase();
        if (!variant.endsWith('test'))
          variants.add(variant);
      }
    }
    final Set<String> buildTypes = <String>{};
    final Set<String> productFlavors = <String>{};
    for (final String variant1 in variants) {
      for (final String variant2 in variants) {
        if (variant2.startsWith(variant1) && variant2 != variant1) {
          final String buildType = variant2.substring(variant1.length);
          if (variants.contains(buildType)) {
            buildTypes.add(buildType);
            productFlavors.add(variant1);
          }
        }
      }
    }
    if (productFlavors.isEmpty)
      buildTypes.addAll(variants);
    return GradleProject(
        buildTypes.toList(),
        productFlavors.toList(),
        buildDirectory,
      );
  }

  /// The build types such as [release] or [debug].
  final List<String> buildTypes;

  /// The product flavors defined in build.gradle.
  final List<String> productFlavors;

  /// The build directory. This is typically <project>build/.
  String buildDirectory;

  /// The directory where the APK artifact is generated.
  Directory get apkDirectory {
    return fs.directory(fs.path.join(buildDirectory, 'outputs', 'apk'));
  }

  /// The directory where the app bundle artifact is generated.
  Directory get bundleDirectory {
    return fs.directory(fs.path.join(buildDirectory, 'outputs', 'bundle'));
  }

  /// The directory where the repo is generated.
  /// Only applicable to AARs.
  Directory get repoDirectory {
    return fs.directory(fs.path.join(buildDirectory, 'outputs', 'repo'));
  }

  String _buildTypeFor(BuildInfo buildInfo) {
    final String modeName = camelCase(buildInfo.modeName);
    if (buildTypes.contains(modeName.toLowerCase()))
      return modeName;
    return null;
  }

  String _productFlavorFor(BuildInfo buildInfo) {
    if (buildInfo.flavor == null)
      return productFlavors.isEmpty ? '' : null;
    else if (productFlavors.contains(buildInfo.flavor))
      return buildInfo.flavor;
    else
      return null;
  }

  String assembleTaskFor(BuildInfo buildInfo) {
    final String buildType = _buildTypeFor(buildInfo);
    final String productFlavor = _productFlavorFor(buildInfo);
    if (buildType == null || productFlavor == null)
      return null;
    return 'assemble${toTitleCase(productFlavor)}${toTitleCase(buildType)}';
  }

  Iterable<String> apkFilesFor(AndroidBuildInfo androidBuildInfo) {
    final String buildType = _buildTypeFor(androidBuildInfo.buildInfo);
    final String productFlavor = _productFlavorFor(androidBuildInfo.buildInfo);
    if (buildType == null || productFlavor == null)
      return const <String>[];

    final String flavorString = productFlavor.isEmpty ? '' : '-' + productFlavor;
    if (androidBuildInfo.splitPerAbi) {
      return androidBuildInfo.targetArchs.map<String>((AndroidArch arch) {
        final String abi = getNameForAndroidArch(arch);
        return 'app$flavorString-$abi-$buildType.apk';
      });
    }
    return <String>['app$flavorString-$buildType.apk'];
  }

  String bundleTaskFor(BuildInfo buildInfo) {
    final String buildType = _buildTypeFor(buildInfo);
    final String productFlavor = _productFlavorFor(buildInfo);
    if (buildType == null || productFlavor == null)
      return null;
    return 'bundle${toTitleCase(productFlavor)}${toTitleCase(buildType)}';
  }

  String aarTaskFor(BuildInfo buildInfo) {
    final String buildType = _buildTypeFor(buildInfo);
    final String productFlavor = _productFlavorFor(buildInfo);
    if (buildType == null || productFlavor == null)
      return null;
    return 'assembleAar${toTitleCase(productFlavor)}${toTitleCase(buildType)}';
  }
}
