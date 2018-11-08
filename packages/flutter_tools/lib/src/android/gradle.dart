// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

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
import '../flutter_manifest.dart';
import '../globals.dart';
import '../project.dart';
import 'android_sdk.dart';
import 'android_studio.dart';

const String gradleVersion = '4.10.2';
final RegExp _assembleTaskPattern = RegExp(r'assemble(\S+)');

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
final RegExp ndkMessageFilter = RegExp(r'^(?!NDK is missing a ".*" directory'
  r'|If you are not using NDK, unset the NDK variable from ANDROID_NDK_HOME or local.properties to remove this warning'
  r'|If you are using NDK, verify the ndk.dir is set to a valid NDK directory.  It is currently set to .*)');

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
      return fs.file((await _gradleProject()).apkDirectory.childFile('app.apk'));
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
  final FlutterProject flutterProject = await FlutterProject.current();
  final String gradle = await _ensureGradle(flutterProject);
  updateLocalProperties(project: flutterProject);
  final Status status = logger.startProgress('Resolving dependencies...', expectSlowOperation: true);
  GradleProject project;
  try {
    final RunResult propertiesRunResult = await runCheckedAsync(
      <String>[gradle, 'app:properties'],
      workingDirectory: flutterProject.android.hostAppGradleRoot.path,
      environment: _gradleEnv,
    );
    final RunResult tasksRunResult = await runCheckedAsync(
      <String>[gradle, 'app:tasks', '--all'],
      workingDirectory: flutterProject.android.hostAppGradleRoot.path,
      environment: _gradleEnv,
    );
    project = GradleProject.fromAppProperties(propertiesRunResult.stdout, tasksRunResult.stdout);
  } catch (exception) {
    if (getFlutterPluginVersion(flutterProject.android) == FlutterPluginVersion.managed) {
      status.cancel();
      // Handle known exceptions. This will exit if handled.
      handleKnownGradleExceptions(exception.toString());

      // Print a general Gradle error and exit.
      printError('* Error running Gradle:\n$exception\n');
      throwToolExit('Please review your Gradle project setup in the android/ folder.');
    }
    // Fall back to the default
    project = GradleProject(
      <String>['debug', 'profile', 'release'],
      <String>[], flutterProject.android.gradleAppOutV1Directory,
    );
  }
  status.stop();
  return project;
}

void handleKnownGradleExceptions(String exceptionString) {
  // Handle Gradle error thrown when Gradle needs to download additional
  // Android SDK components (e.g. Platform Tools), and the license
  // for that component has not been accepted.
  const String matcher =
    r'You have not accepted the license agreements of the following SDK components:'
    r'\s*\[(.+)\]';
  final RegExp licenseFailure = RegExp(matcher, multiLine: true);
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

String _locateGradlewExecutable(Directory directory) {
  final File gradle = directory.childFile(
    platform.isWindows ? 'gradlew.bat' : 'gradlew',
  );

  if (gradle.existsSync()) {
    os.makeExecutable(gradle);
    return gradle.absolute.path;
  } else {
    return null;
  }
}

Future<String> _ensureGradle(FlutterProject project) async {
  _cachedGradleExecutable ??= await _initializeGradle(project);
  return _cachedGradleExecutable;
}

// Note: Gradle may be bootstrapped and possibly downloaded as a side-effect
// of validating the Gradle executable. This may take several seconds.
Future<String> _initializeGradle(FlutterProject project) async {
  final Directory android = project.android.hostAppGradleRoot;
  final Status status = logger.startProgress('Initializing gradle...', expectSlowOperation: true);
  String gradle = _locateGradlewExecutable(android);
  if (gradle == null) {
    injectGradleWrapper(android);
    gradle = _locateGradlewExecutable(android);
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

/// Injects the Gradle wrapper into the specified directory.
void injectGradleWrapper(Directory directory) {
  copyDirectorySync(cache.getArtifactDirectory('gradle_wrapper'), directory);
  _locateGradlewExecutable(directory);
  final File propertiesFile = directory.childFile(fs.path.join('gradle', 'wrapper', 'gradle-wrapper.properties'));
  if (!propertiesFile.existsSync()) {
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
      settings.values[key] = value;
      changed = true;
    }
  }

  final FlutterManifest manifest = project.manifest;

  if (androidSdk != null)
    changeIfNecessary('sdk.dir', escapePath(androidSdk.directory));
  changeIfNecessary('flutter.sdk', escapePath(Cache.flutterRoot));
  if (buildInfo != null)
    changeIfNecessary('flutter.buildMode', buildInfo.modeName);
  final String buildName = buildInfo?.buildName ?? manifest.buildName;
  if (buildName != null)
    changeIfNecessary('flutter.versionName', buildName);
  final int buildNumber = buildInfo?.buildNumber ?? manifest.buildNumber;
  if (buildNumber != null)
    changeIfNecessary('flutter.versionCode', '$buildNumber');

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
  @required BuildInfo buildInfo,
  @required String target,
}) async {
  // Update the local.properties file with the build mode, version name and code.
  // FlutterPlugin v1 reads local.properties to determine build mode. Plugin v2
  // uses the standard Android way to determine what to build, but we still
  // update local.properties, in case we want to use it in the future.
  // Version name and number are provided by the pubspec.yaml file
  // and can be overwritten with flutter build command.
  // The default Gradle script reads the version name and number
  // from the local.properties file.
  updateLocalProperties(project: project, buildInfo: buildInfo);

  final String gradle = await _ensureGradle(project);

  switch (getFlutterPluginVersion(project.android)) {
    case FlutterPluginVersion.none:
      // Fall through. Pretend it's v1, and just go for it.
    case FlutterPluginVersion.v1:
      return _buildGradleProjectV1(project, gradle);
    case FlutterPluginVersion.managed:
      // Fall through. Managed plugin builds the same way as plugin v2.
    case FlutterPluginVersion.v2:
      return _buildGradleProjectV2(project, gradle, buildInfo, target);
  }
}

Future<void> _buildGradleProjectV1(FlutterProject project, String gradle) async {
  // Run 'gradlew build'.
  final Status status = logger.startProgress(
    "Running 'gradlew build'...",
    expectSlowOperation: true,
    multilineOutput: true,
  );
  final int exitCode = await runCommandAndStreamOutput(
    <String>[fs.file(gradle).absolute.path, 'build'],
    workingDirectory: project.android.hostAppGradleRoot.path,
    allowReentrantFlutter: true,
    environment: _gradleEnv,
  );
  status.stop();

  if (exitCode != 0)
    throwToolExit('Gradle build failed: $exitCode', exitCode: exitCode);

  printStatus('Built ${fs.path.relative(project.android.gradleAppOutV1File.path)}.');
}

Future<void> _buildGradleProjectV2(
    FlutterProject flutterProject,
    String gradle,
    BuildInfo buildInfo,
    String target) async {
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
  final Status status = logger.startProgress(
    "Gradle task '$assembleTask'...",
    expectSlowOperation: true,
    multilineOutput: true,
  );
  final String gradlePath = fs.file(gradle).absolute.path;
  final List<String> command = <String>[gradlePath];
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
  if (buildInfo.compilationTraceFilePath != null)
    command.add('-Pprecompile=${buildInfo.compilationTraceFilePath}');
  if (buildInfo.buildHotUpdate)
    command.add('-Photupdate=true');
  if (buildInfo.extraFrontEndOptions != null)
    command.add('-Pextra-front-end-options=${buildInfo.extraFrontEndOptions}');
  if (buildInfo.extraGenSnapshotOptions != null)
    command.add('-Pextra-gen-snapshot-options=${buildInfo.extraGenSnapshotOptions}');
  if (buildInfo.fileSystemRoots != null && buildInfo.fileSystemRoots.isNotEmpty)
    command.add('-Pfilesystem-roots=${buildInfo.fileSystemRoots.join('|')}');
  if (buildInfo.fileSystemScheme != null)
    command.add('-Pfilesystem-scheme=${buildInfo.fileSystemScheme}');
  if (buildInfo.buildSharedLibrary && androidSdk.ndk != null) {
    command.add('-Pbuild-shared-library=true');
  }
  if (buildInfo.targetPlatform != null)
    command.add('-Ptarget-platform=${getNameForTargetPlatform(buildInfo.targetPlatform)}');

  command.add(assembleTask);
  final int exitCode = await runCommandAndStreamOutput(
    command,
    workingDirectory: flutterProject.android.hostAppGradleRoot.path,
    allowReentrantFlutter: true,
    environment: _gradleEnv,
    filter: logger.isVerbose ? null : ndkMessageFilter,
  );
  status.stop();

  if (exitCode != 0)
    throwToolExit('Gradle task $assembleTask failed with exit code $exitCode', exitCode: exitCode);

  final File apkFile = _findApkFile(project, buildInfo);
  if (apkFile == null)
    throwToolExit('Gradle build failed to produce an Android package.');
  // Copy the APK to app.apk, so `flutter run`, `flutter install`, etc. can find it.
  apkFile.copySync(project.apkDirectory.childFile('app.apk').path);

  printTrace('calculateSha: ${project.apkDirectory}/app.apk');
  final File apkShaFile = project.apkDirectory.childFile('app.apk.sha1');
  apkShaFile.writeAsStringSync(calculateSha(apkFile));

  String appSize;
  if (buildInfo.mode == BuildMode.debug) {
    appSize = '';
  } else {
    appSize = ' (${getSizeAsMB(apkFile.lengthSync())})';
  }
  printStatus('Built ${fs.path.relative(apkFile.path)}$appSize.');
}

File _findApkFile(GradleProject project, BuildInfo buildInfo) {
  final String apkFileName = project.apkFileFor(buildInfo);
  if (apkFileName == null)
    return null;
  File apkFile = fs.file(fs.path.join(project.apkDirectory.path, apkFileName));
  if (apkFile.existsSync())
    return apkFile;
  final String modeName = camelCase(buildInfo.modeName);
  apkFile = fs.file(fs.path.join(project.apkDirectory.path, modeName, apkFileName));
  if (apkFile.existsSync())
    return apkFile;
  if (buildInfo.flavor != null) {
    // Android Studio Gradle plugin v3 adds flavor to path.
    apkFile = fs.file(fs.path.join(project.apkDirectory.path, buildInfo.flavor, modeName, apkFileName));
    if (apkFile.existsSync())
      return apkFile;
  }
  return null;
}

Map<String, String> get _gradleEnv {
  final Map<String, String> env = Map<String, String>.from(platform.environment);
  if (javaPath != null) {
    // Use java bundled with Android Studio.
    env['JAVA_HOME'] = javaPath;
  }
  return env;
}

class GradleProject {
  GradleProject(this.buildTypes, this.productFlavors, this.apkDirectory);

  factory GradleProject.fromAppProperties(String properties, String tasks) {
    // Extract build directory.
    final String buildDir = properties
        .split('\n')
        .firstWhere((String s) => s.startsWith('buildDir: '))
        .substring('buildDir: '.length)
        .trim();

    // Extract build types and product flavors.
    final Set<String> variants = Set<String>();
    for (String s in tasks.split('\n')) {
      final Match match = _assembleTaskPattern.matchAsPrefix(s);
      if (match != null) {
        final String variant = match.group(1).toLowerCase();
        if (!variant.endsWith('test'))
          variants.add(variant);
      }
    }
    final Set<String> buildTypes = Set<String>();
    final Set<String> productFlavors = Set<String>();
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
      fs.directory(fs.path.join(buildDir, 'outputs', 'apk')),
    );
  }

  final List<String> buildTypes;
  final List<String> productFlavors;
  final Directory apkDirectory;

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

  String apkFileFor(BuildInfo buildInfo) {
    final String buildType = _buildTypeFor(buildInfo);
    final String productFlavor = _productFlavorFor(buildInfo);
    if (buildType == null || productFlavor == null)
      return null;
    final String flavorString = productFlavor.isEmpty ? '' : '-' + productFlavor;
    return 'app$flavorString-$buildType.apk';
  }
}
