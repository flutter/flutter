// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_sdk.dart';
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
import 'android_sdk.dart';
import 'android_studio.dart';

const String gradleManifestPath = 'android/app/src/main/AndroidManifest.xml';
const String gradleAppOutV1 = 'android/app/build/outputs/apk/app-debug.apk';
const String gradleAppOutDirV1 = 'android/app/build/outputs/apk';
const String gradleVersion = '4.1';
final RegExp _assembleTaskPattern = new RegExp(r'assemble([^:]+): task ');

GradleProject _cachedGradleProject;
String _cachedGradleExecutable;

enum FlutterPluginVersion {
  none,
  v1,
  v2,
  managed,
}

// Investigation documented in #13975 suggests the filter should be a subset
// of the impact of -q, but users insist they see the error message sometimes
// anyway.  If we can prove it really is impossible, delete the filter.
final RegExp ndkMessageFilter = new RegExp(r'^(?!NDK is missing a ".*" directory'
  r'|If you are not using NDK, unset the NDK variable from ANDROID_NDK_HOME or local.properties to remove this warning'
  r'|If you are using NDK, verify the ndk.dir is set to a valid NDK directory.  It is currently set to .*)');


bool isProjectUsingGradle() {
  return fs.isFileSync('android/build.gradle');
}

FlutterPluginVersion get flutterPluginVersion {
  final File plugin = fs.file('android/buildSrc/src/main/groovy/FlutterPlugin.groovy');
  if (plugin.existsSync()) {
    final String packageLine = plugin.readAsLinesSync().skip(4).first;
    if (packageLine == 'package io.flutter.gradle') {
      return FlutterPluginVersion.v2;
    }
    return FlutterPluginVersion.v1;
  }
  final File appGradle = fs.file('android/app/build.gradle');
  if (appGradle.existsSync()) {
    for (String line in appGradle.readAsLinesSync()) {
      if (line.contains(new RegExp(r'apply from: .*/flutter.gradle'))) {
        return FlutterPluginVersion.managed;
      }
    }
  }
  return FlutterPluginVersion.none;
}

/// Returns the path to the apk file created by [buildGradleProject], relative
/// to current directory.
Future<String> getGradleAppOut() async {
  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend we're v1, and just go with it.
    case FlutterPluginVersion.v1:
      return gradleAppOutV1;
    case FlutterPluginVersion.managed:
      // Fall through. The managed plugin matches plugin v2 for now.
    case FlutterPluginVersion.v2:
      return fs.path.relative(fs.path.join((await _gradleProject()).apkDirectory, 'app.apk'));
  }
  return null;
}

Future<GradleProject> _gradleProject() async {
  _cachedGradleProject ??= await _readGradleProject();
  return _cachedGradleProject;
}

// Note: Dependencies are resolved and possibly downloaded as a side-effect
// of calculating the app properties using Gradle. This may take minutes.
Future<GradleProject> _readGradleProject() async {
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
    final GradleProject project = new GradleProject.fromAppProperties(properties);
    status.stop();
    return project;
  } catch (e) {
    if (flutterPluginVersion == FlutterPluginVersion.managed) {
      // Handle known exceptions. This will exit if handled.
      handleKnownGradleExceptions(e);

      // Print a general Gradle error and exit.
      printError('* Error running Gradle:\n$e\n');
      throwToolExit('Please review your Gradle project setup in the android/ folder.');
    }
  }
  // Fall back to the default
  return new GradleProject(<String>['debug', 'profile', 'release'], <String>[], gradleAppOutDirV1);
}

void handleKnownGradleExceptions(String exceptionString) {
  // Handle Gradle error thrown when Gradle needs to download additional
  // Android SDK components (e.g. Platform Tools), and the license
  // for that component has not been accepted.
  const String matcher =
    r'You have not accepted the license agreements of the following SDK components:'
    r'\s*\[(.+)\]';
  final RegExp licenseFailure = new RegExp(matcher, multiLine: true);
  final Match licenseMatch = licenseFailure.firstMatch(exceptionString);
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

String _locateProjectGradlew({ bool ensureExecutable: true }) {
  final String path = fs.path.join(
    'android',
    platform.isWindows ? 'gradlew.bat' : 'gradlew',
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
void updateLocalProperties({String projectPath, BuildInfo buildInfo}) {
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
  if (buildInfo != null && settings.values['flutter.buildMode'] != buildInfo.modeName) {
    settings.values['flutter.buildMode'] = buildInfo.modeName;
    changed = true;
  }

  if (changed)
    settings.writeContents(localProperties);
}

Future<Null> buildGradleProject(BuildInfo buildInfo, String target) async {
  // Update the local.properties file with the build mode.
  // FlutterPlugin v1 reads local.properties to determine build mode. Plugin v2
  // uses the standard Android way to determine what to build, but we still
  // update local.properties, in case we want to use it in the future.
  updateLocalProperties(buildInfo: buildInfo);

  final String gradle = await _ensureGradle();

  switch (flutterPluginVersion) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend it's v1, and just go for it.
    case FlutterPluginVersion.v1:
      return _buildGradleProjectV1(gradle);
    case FlutterPluginVersion.managed:
      // Fall through. Managed plugin builds the same way as plugin v2.
    case FlutterPluginVersion.v2:
      return _buildGradleProjectV2(gradle, buildInfo, target);
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

Future<Null> _buildGradleProjectV2(String gradle, BuildInfo buildInfo, String target) async {
  final GradleProject project = await _gradleProject();
  final String assembleTask = project.assembleTaskFor(buildInfo);
  if (assembleTask == null) {
    printError('');
    printError('The Gradle project does not define a task suitable for the requested build.');
    if (!project.buildTypes.contains(buildInfo.modeName)) {
      printError('Review the android/app/build.gradle file and ensure it defines a ${buildInfo.modeName} build type.');
    } else {
      if (project.productFlavors.isEmpty) {
        printError('The android/app/build.gradle file does not define any custom product flavors.');
        printError('You cannot use the --flavor option.');
      } else {
        printError('The android/app/build.gradle file defines product flavors: ${project.productFlavors.join(', ')}');
        printError('You must specify a --flavor option to select one of them.');
      }
      throwToolExit('Gradle build aborted.');
    }
  }
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
  if (buildInfo.previewDart2) {
    command.add('-Ppreview-dart-2=true');
    if (buildInfo.trackWidgetCreation)
      command.add('-Ptrack-widget-creation=true');
    if (buildInfo.extraFrontEndOptions != null)
      command.add('-Pextra-front-end-options=${buildInfo.extraFrontEndOptions}');
    if (buildInfo.extraGenSnapshotOptions != null)
      command.add('-Pextra-gen-snapshot-options=${buildInfo.extraGenSnapshotOptions}');
  }
  if (buildInfo.preferSharedLibrary && androidSdk.ndkCompiler != null) {
    command.add('-Pprefer-shared-library=true');
  }
  if (buildInfo.targetPlatform == TargetPlatform.android_arm64)
    command.add('-Ptarget-platform=android-arm64');

  command.add(assembleTask);
  final int exitCode = await runCommandAndStreamOutput(
      command,
      workingDirectory: 'android',
      allowReentrantFlutter: true,
      environment: _gradleEnv,
      filter: logger.isVerbose ? null : ndkMessageFilter,
  );
  status.stop();

  if (exitCode != 0)
    throwToolExit('Gradle build failed: $exitCode', exitCode: exitCode);

  final File apkFile = _findApkFile(project, buildInfo);
  if (apkFile == null)
    throwToolExit('Gradle build failed to produce an Android package.');
  // Copy the APK to app.apk, so `flutter run`, `flutter install`, etc. can find it.
  apkFile.copySync(fs.path.join(project.apkDirectory, 'app.apk'));

  printTrace('calculateSha: ${project.apkDirectory}/app.apk');
  final File apkShaFile = fs.file(fs.path.join(project.apkDirectory, 'app.apk.sha1'));
  apkShaFile.writeAsStringSync(calculateSha(apkFile));

  printStatus('Built ${fs.path.relative(apkFile.path)} (${getSizeAsMB(apkFile.lengthSync())}).');
}

File _findApkFile(GradleProject project, BuildInfo buildInfo) {
  final String apkFileName = project.apkFileFor(buildInfo);
  if (apkFileName == null)
    return null;
  File apkFile = fs.file(fs.path.join(project.apkDirectory, apkFileName));
  if (apkFile.existsSync())
    return apkFile;
  apkFile = fs.file(fs.path.join(project.apkDirectory, buildInfo.modeName, apkFileName));
  if (apkFile.existsSync())
    return apkFile;
  if (buildInfo.flavor != null) {
    // Android Studio Gradle plugin v3 adds flavor to path.
    apkFile = fs.file(fs.path.join(project.apkDirectory, buildInfo.flavor, buildInfo.modeName, apkFileName));
    if (apkFile.existsSync())
      return apkFile;
  }
  return null;
}

Map<String, String> get _gradleEnv {
  final Map<String, String> env = new Map<String, String>.from(platform.environment);
  if (javaPath != null) {
    // Use java bundled with Android Studio.
    env['JAVA_HOME'] = javaPath;
  }
  return env;
}

class GradleProject {
  GradleProject(this.buildTypes, this.productFlavors, this.apkDirectory);

  factory GradleProject.fromAppProperties(String properties) {
    // Extract build directory.
    final String buildDir = properties
        .split('\n')
        .firstWhere((String s) => s.startsWith('buildDir: '))
        .substring('buildDir: '.length)
        .trim();

    // Extract build types and product flavors.
    final Set<String> variants = new Set<String>();
    for (String s in properties.split('\n')) {
      final Match match = _assembleTaskPattern.matchAsPrefix(s);
      if (match != null) {
        final String variant = match.group(1).toLowerCase();
        if (!variant.endsWith('test'))
          variants.add(variant);
      }
    }
    final Set<String> buildTypes = new Set<String>();
    final Set<String> productFlavors = new Set<String>();
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
    return new GradleProject(
      buildTypes.toList(),
      productFlavors.toList(),
      fs.path.normalize(fs.path.join(buildDir, 'outputs', 'apk')),
    );
  }

  final List<String> buildTypes;
  final List<String> productFlavors;
  final String apkDirectory;

  String _buildTypeFor(BuildInfo buildInfo) {
    if (buildTypes.contains(buildInfo.modeName))
      return buildInfo.modeName;
    return null;
  }

  String _productFlavorFor(BuildInfo buildInfo) {
    if (buildInfo.flavor == null)
      return productFlavors.isEmpty ? '' : null;
    else if (productFlavors.contains(buildInfo.flavor.toLowerCase()))
      return buildInfo.flavor.toLowerCase();
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

  String apkFileFor(BuildInfo buildInfo) {
    final String buildType = _buildTypeFor(buildInfo);
    final String productFlavor = _productFlavorFor(buildInfo);
    if (buildType == null || productFlavor == null)
      return null;
    final String flavorString = productFlavor.isEmpty ? '' : '-' + productFlavor;
    return 'app$flavorString-$buildType.apk';
  }
}
