// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'android_studio.dart';

/// The environment variables needed to run Gradle.
Map<String, String> get gradleEnvironment {
  final Map<String, String> environment = Map<String, String>.of(globals.platform.environment);
  if (javaPath != null) {
    // Use java bundled with Android Studio.
    environment['JAVA_HOME'] = javaPath;
  }
  // Don't log analytics for downstream Flutter commands.
  // e.g. `flutter build bundle`.
  environment['FLUTTER_SUPPRESS_ANALYTICS'] = 'true';
  return environment;
}

/// Gradle utils in the current [AppContext].
GradleUtils get gradleUtils => context.get<GradleUtils>();

/// Provides utilities to run a Gradle task,
/// such as finding the Gradle executable or constructing a Gradle project.
class GradleUtils {
  /// Gets the Gradle executable path and prepares the Gradle project.
  /// This is the `gradlew` or `gradlew.bat` script in the `android/` directory.
  String getExecutable(FlutterProject project) {
    final Directory androidDir = project.android.hostAppGradleRoot;
    // Update the project if needed.
    // TODO(egarciad): https://github.com/flutter/flutter/issues/40460
    gradleUtils.migrateToR8(androidDir);
    gradleUtils.injectGradleWrapperIfNeeded(androidDir);

    final File gradle = androidDir.childFile(
      globals.platform.isWindows ? 'gradlew.bat' : 'gradlew',
    );
    if (gradle.existsSync()) {
      globals.printTrace('Using gradle from ${gradle.absolute.path}.');
      // If the Gradle executable doesn't have execute permission,
      // then attempt to set it.
      _giveExecutePermissionIfNeeded(gradle);
      return gradle.absolute.path;
    }
    throwToolExit(
      'Unable to locate gradlew script. Please check that ${gradle.path} '
      'exists or that ${gradle.dirname} can be read.'
    );
    return null;
  }

  /// Migrates the Android's [directory] to R8.
  /// https://developer.android.com/studio/build/shrink-code
  @visibleForTesting
  void migrateToR8(Directory directory) {
    final File gradleProperties = directory.childFile('gradle.properties');
    if (!gradleProperties.existsSync()) {
      throwToolExit(
        'Expected file ${gradleProperties.path}. '
        'Please ensure that this file exists or that ${gradleProperties.dirname} can be read.'
      );
    }
    final String propertiesContent = gradleProperties.readAsStringSync();
    if (propertiesContent.contains('android.enableR8')) {
      globals.printTrace('gradle.properties already sets `android.enableR8`');
      return;
    }
    globals.printTrace('set `android.enableR8=true` in gradle.properties');
    try {
      if (propertiesContent.isNotEmpty && !propertiesContent.endsWith('\n')) {
        // Add a new line if the file doesn't end with a new line.
        gradleProperties.writeAsStringSync('\n', mode: FileMode.append);
      }
      gradleProperties.writeAsStringSync('android.enableR8=true\n', mode: FileMode.append);
    } on FileSystemException {
      throwToolExit(
        'The tool failed to add `android.enableR8=true` to ${gradleProperties.path}. '
        'Please update the file manually and try this command again.'
      );
    }
  }

  /// Injects the Gradle wrapper files if any of these files don't exist in [directory].
  void injectGradleWrapperIfNeeded(Directory directory) {
    globals.fsUtils.copyDirectorySync(
      globals.cache.getArtifactDirectory('gradle_wrapper'),
      directory,
      shouldCopyFile: (File sourceFile, File destinationFile) {
        // Don't override the existing files in the project.
        return !destinationFile.existsSync();
      },
      onFileCopied: (File sourceFile, File destinationFile) {
        if (_hasAnyExecutableFlagSet(sourceFile)) {
          _giveExecutePermissionIfNeeded(destinationFile);
        }
      },
    );
    // Add the `gradle-wrapper.properties` file if it doesn't exist.
    final File propertiesFile = directory.childFile(
        globals.fs.path.join('gradle', 'wrapper', 'gradle-wrapper.properties'));
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
}
const String _defaultGradleVersion = '5.6.2';

final RegExp _androidPluginRegExp = RegExp(r'com\.android\.tools\.build:gradle:\(\d+\.\d+\.\d+\)');

/// Returns the Gradle version that the current Android plugin depends on when found,
/// otherwise it returns a default version.
///
/// The Android plugin version is specified in the [build.gradle] file within
/// the project's Android directory.
String getGradleVersionForAndroidPlugin(Directory directory) {
  final File buildFile = directory.childFile('build.gradle');
  if (!buildFile.existsSync()) {
    return _defaultGradleVersion;
  }
  final String buildFileContent = buildFile.readAsStringSync();
  final Iterable<Match> pluginMatches = _androidPluginRegExp.allMatches(buildFileContent);
  if (pluginMatches.isEmpty) {
    return _defaultGradleVersion;
  }
  final String androidPluginVersion = pluginMatches.first.group(1);
  return getGradleVersionFor(androidPluginVersion);
}

const int _kExecPermissionMask = 0x49; // a+x

/// Returns [true] if [executable] has all executable flag set.
bool _hasAllExecutableFlagSet(File executable) {
  final FileStat stat = executable.statSync();
  assert(stat.type != FileSystemEntityType.notFound);
  globals.printTrace('${executable.path} mode: ${stat.mode} ${stat.modeString()}.');
  return stat.mode & _kExecPermissionMask == _kExecPermissionMask;
}

/// Returns [true] if [executable] has any executable flag set.
bool _hasAnyExecutableFlagSet(File executable) {
  final FileStat stat = executable.statSync();
  assert(stat.type != FileSystemEntityType.notFound);
  globals.printTrace('${executable.path} mode: ${stat.mode} ${stat.modeString()}.');
  return stat.mode & _kExecPermissionMask != 0;
}

/// Gives execute permission to [executable] if it doesn't have it already.
void _giveExecutePermissionIfNeeded(File executable) {
  if (!_hasAllExecutableFlagSet(executable)) {
    globals.printTrace('Trying to give execute permission to ${executable.path}.');
    globals.os.makeExecutable(executable);
  }
}

/// Returns true if [targetVersion] is within the range [min] and [max] inclusive.
bool _isWithinVersionRange(
  String targetVersion, {
  @required String min,
  @required String max,
}) {
  assert(min != null);
  assert(max != null);
  final Version parsedTargetVersion = Version.parse(targetVersion);
  return parsedTargetVersion >= Version.parse(min) &&
         parsedTargetVersion <= Version.parse(max);
}

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
    return '5.6.2';
  }
  throwToolExit('Unsupported Android Plugin version: $androidPluginVersion.');
  return '';
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
  if (requireAndroidSdk && globals.androidSdk == null) {
    exitWithNoSdkMessage();
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
    if (settings.values[key] == value) {
      return;
    }
    if (value == null) {
      settings.values.remove(key);
    } else {
      settings.values[key] = value;
    }
    changed = true;
  }

  if (globals.androidSdk != null) {
    changeIfNecessary('sdk.dir', globals.fsUtils.escapePath(globals.androidSdk.directory));
  }

  changeIfNecessary('flutter.sdk', globals.fsUtils.escapePath(Cache.flutterRoot));
  if (buildInfo != null) {
    changeIfNecessary('flutter.buildMode', buildInfo.modeName);
    final String buildName = validatedBuildNameForPlatform(
      TargetPlatform.android_arm,
      buildInfo.buildName ?? project.manifest.buildName,
      globals.logger,
    );
    changeIfNecessary('flutter.versionName', buildName);
    final String buildNumber = validatedBuildNumberForPlatform(
      TargetPlatform.android_arm,
      buildInfo.buildNumber ?? project.manifest.buildNumber,
      globals.logger,
    );
    changeIfNecessary('flutter.versionCode', buildNumber?.toString());
  }

  if (changed) {
    settings.writeContents(localProperties);
  }
}

/// Writes standard Android local properties to the specified [properties] file.
///
/// Writes the path to the Android SDK, if known.
void writeLocalProperties(File properties) {
  final SettingsFile settings = SettingsFile();
  if (globals.androidSdk != null) {
    settings.values['sdk.dir'] = globals.fsUtils.escapePath(globals.androidSdk.directory);
  }
  settings.writeContents(properties);
}

void exitWithNoSdkMessage() {
  BuildEvent('unsupported-project', eventError: 'android-sdk-not-found', flutterUsage: globals.flutterUsage).send();
  throwToolExit(
    '$warningMark No Android SDK found. '
    'Try setting the ANDROID_SDK_ROOT environment variable.'
  );
}
