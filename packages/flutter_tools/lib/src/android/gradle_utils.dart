// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';

import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'android_sdk.dart';

// These are the versions used in the project templates.
//
// In general, Flutter aims to default to the latest version.
// However, this currently requires to migrate existing integration tests to the latest supported values.
//
// For more information about the latest version, check:
// https://developer.android.com/studio/releases/gradle-plugin#updating-gradle
// https://kotlinlang.org/docs/releases.html#release-details
const String templateDefaultGradleVersion = '7.5';
const String templateAndroidGradlePluginVersion = '7.3.0';
const String templateDefaultGradleVersionForModule = '7.3.0';
const String templateKotlinGradlePluginVersion = '1.7.10';

// These versions should match the values in flutter.gradle (FlutterExtension).
// The Flutter Gradle plugin is only applied to app projects, and modules that are built from source
// using (include_flutter.groovy).
// The remaining projects are: plugins, and modules compiled as AARs. In modules, the ephemeral directory
// `.android` is always regenerated after flutter pub get, so new versions are picked up after a
// Flutter upgrade.
const String compileSdkVersion = '31';
const String minSdkVersion = '16';
const String targetSdkVersion = '31';
const String ndkVersion = '23.1.7779620';

// Update this when new versions of Gradle come out.
const String _maxKnownAndSupportedGradleVersion = '8.0';
// Update this when new versions of AGP come out.
@visibleForTesting
const String maxKnownAgpVersion = '8.1';

// Expected content:
// "classpath 'com.android.tools.build:gradle:7.3.0'"
// Parentheticals are use to group which helps with version extraction.
// "...build:gradle:(...)" where group(1) should be the version string.
final RegExp _androidGradlePluginRegExp =
    RegExp(r'com\.android\.tools\.build:gradle:(\d+\.\d+\.\d+)');

// From https://docs.gradle.org/current/userguide/command_line_interface.html#command_line_interface
const String gradleVersionFlag = r'--version';

// Directory under android/ that gradle uses to store gradle information.
// Regularly used with [gradleWrapperDirectory] and
// [gradleWrapperPropertiesFilename].
// Different from the directory of gradle files stored in
// `_cache.getArtifactDirectory('gradle_wrapper')`
const String gradleDirectoryName = 'gradle';
const String gradleWrapperDirectoryName = 'wrapper';
const String gradleWrapperPropertiesFilename = 'gradle-wrapper.properties';

/// Provides utilities to run a Gradle task, such as finding the Gradle executable
/// or constructing a Gradle project.
class GradleUtils {
  GradleUtils({
    required Platform platform,
    required Logger logger,
    required Cache cache,
    required OperatingSystemUtils operatingSystemUtils,
  })  : _platform = platform,
       _logger = logger,
       _cache = cache,
       _operatingSystemUtils = operatingSystemUtils;

  final Cache _cache;
  final Platform _platform;
  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;

  /// Gets the Gradle executable path and prepares the Gradle project.
  /// This is the `gradlew` or `gradlew.bat` script in the `android/` directory.
  String getExecutable(FlutterProject project) {
    final Directory androidDir = project.android.hostAppGradleRoot;
    injectGradleWrapperIfNeeded(androidDir);

    final File gradle = androidDir.childFile(
      _platform.isWindows ? 'gradlew.bat' : 'gradlew',
    );
    if (gradle.existsSync()) {
      _logger.printTrace('Using gradle from ${gradle.absolute.path}.');
      // If the Gradle executable doesn't have execute permission,
      // then attempt to set it.
      _operatingSystemUtils.makeExecutable(gradle);
      return gradle.absolute.path;
    }
    throwToolExit(
       'Unable to locate gradlew script. Please check that ${gradle.path} '
       'exists or that ${gradle.dirname} can be read.');
  }

  /// Injects the Gradle wrapper files if any of these files don't exist in [directory].
  void injectGradleWrapperIfNeeded(Directory directory) {
    copyDirectory(
      _cache.getArtifactDirectory('gradle_wrapper'),
      directory,
      shouldCopyFile: (File sourceFile, File destinationFile) {
        // Don't override the existing files in the project.
        return !destinationFile.existsSync();
      },
      onFileCopied: (File source, File dest) {
        _operatingSystemUtils.makeExecutable(dest);
      }
    );
    // Add the `gradle-wrapper.properties` file if it doesn't exist.
    final Directory propertiesDirectory = directory
        .childDirectory(gradleDirectoryName)
        .childDirectory(gradleWrapperDirectoryName);
    final File propertiesFile =
        propertiesDirectory.childFile(gradleWrapperPropertiesFilename);

    if (propertiesFile.existsSync()) {
      return;
    }
    propertiesDirectory.createSync(recursive: true);
    final String gradleVersion =
        getGradleVersionForAndroidPlugin(directory, _logger);
    final String propertyContents = '''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-$gradleVersion-all.zip
''';
    propertiesFile.writeAsStringSync(propertyContents);
  }
}

/// Returns the Gradle version that the current Android plugin depends on when found,
/// otherwise it returns a default version.
///
/// The Android plugin version is specified in the [build.gradle] file within
/// the project's Android directory.
String getGradleVersionForAndroidPlugin(Directory directory, Logger logger) {
  final File buildFile = directory.childFile('build.gradle');
  if (!buildFile.existsSync()) {
    logger.printTrace(
        "$buildFile doesn't exist, assuming Gradle version: $templateDefaultGradleVersion");
    return templateDefaultGradleVersion;
  }
  final String buildFileContent = buildFile.readAsStringSync();
  final Iterable<Match> pluginMatches = _androidGradlePluginRegExp.allMatches(buildFileContent);
  if (pluginMatches.isEmpty) {
    logger.printTrace("$buildFile doesn't provide an AGP version, assuming Gradle version: $templateDefaultGradleVersion");
    return templateDefaultGradleVersion;
  }
  final String? androidPluginVersion = pluginMatches.first.group(1);
  logger.printTrace('$buildFile provides AGP version: $androidPluginVersion');
  return getGradleVersionFor(androidPluginVersion ?? 'unknown');
}

/// Returns either the gradle-wrapper.properties value from the passed in
/// [directory] or if not present the version available in local path.
///
/// If gradle version is not found null is returned.
/// [directory] should be and android directory with an build.gradle file.
Future<String?> getGradleVersion(
    Directory directory, Logger logger, ProcessManager processManager) async {
  final File propertiesFile = directory
      .childDirectory(gradleDirectoryName)
      .childDirectory(gradleWrapperDirectoryName)
      .childFile(gradleWrapperPropertiesFilename);

  if (propertiesFile.existsSync()) {
    final String wrapperFileContent = propertiesFile.readAsStringSync();

    // Expected content format (with lines above and below).
    // Version can have 2 or 3 numbers.
    // 'distributionUrl=https\://services.gradle.org/distributions/gradle-7.4.2-all.zip'
    final RegExp distributionUrlRegex = RegExp(r'distributionUrl\s?=\s?.*\.zip');

    final RegExpMatch? distributionUrl =
        distributionUrlRegex.firstMatch(wrapperFileContent);
    if (distributionUrl != null) {
      // Expected content: 'gradle-7.4.2-all.zip'
      final String? gradleZip = distributionUrl.group(0);
      if (gradleZip != null) {
        final String gradleVersion = gradleZip.split('-')[1];
        return gradleVersion;
      } else {
        // Did not find gradle zip url. Likley this is a bug in our parsing.
        logger.printWarning(_formatParseWarning(wrapperFileContent));
      }
    } else {
      // If no distributionUrl log then treat as if there was no propertiesFile.
      logger.printTrace(
          '$propertiesFile does not provide an Gradle version falling back to system gradle.');
    }
  } else {
    // Could not find properties file.
    logger.printTrace(
        '$propertiesFile does not exist falling back to system gradle');
  }
  // System installed Gradle version.
  if (processManager.canRun('gradle')) {
    final String gradleVersionVerbose =
        (await processManager.run(<String>['gradle', gradleVersionFlag])).stdout
            as String;
    // Expected format:
/*

------------------------------------------------------------
Gradle 7.6
------------------------------------------------------------

Build time:   2022-11-25 13:35:10 UTC
Revision:     daece9dbc5b79370cc8e4fd6fe4b2cd400e150a8

Kotlin:       1.7.10
Groovy:       3.0.13
Ant:          Apache Ant(TM) version 1.10.11 compiled on July 10 2021
JVM:          17.0.6 (Homebrew 17.0.6+0)
OS:           Mac OS X 13.2.1 aarch64
    */
    // Observation shows that the version can have 2 or 3 numbers.
    // Inner parentheticals `(\.\d+)?` denote the optional third value.
    // Outter parentheticals `Gradle (...)` denote a grouping used to extract
    // the version number.
    final RegExp gradleVersionRegex = RegExp(r'Gradle (\d+\.\d+(\.\d+)?)');
    final RegExpMatch? version =
        gradleVersionRegex.firstMatch(gradleVersionVerbose);
    if (version == null) {
      // Most likley a bug in our parse implementation/regex.
      logger.printWarning(_formatParseWarning(gradleVersionVerbose));
      return null;
    }
    return version.group(1);
  } else {
    logger.printTrace('Could not run system gradle');
    return null;
  }
}

/// Returns the Android Gradle Plugin (AGP) version that the current project
/// depends on when found, null otherwise.
///
/// The Android plugin version is specified in the [build.gradle] file within
/// the project's Android directory ([androidDirectory]).
String? getAgpVersion(Directory androidDirectory, Logger logger) {
  final File buildFile = androidDirectory.childFile('build.gradle');
  if (!buildFile.existsSync()) {
    logger.printTrace('Can not find build.gradle in $androidDirectory');
    return null;
  }
  final String buildFileContent = buildFile.readAsStringSync();
  final Iterable<Match> pluginMatches =
      _androidGradlePluginRegExp.allMatches(buildFileContent);
  if (pluginMatches.isEmpty) {
    logger.printTrace("$buildFile doesn't provide an AGP version");
    return null;
  }
  final String? androidPluginVersion = pluginMatches.first.group(1);
  logger.printTrace('$buildFile provides AGP version: $androidPluginVersion');
  return androidPluginVersion;
}

String _formatParseWarning(String content) {
  return 'Could not parse gradle version from: \n'
      '$content \n'
      'If there is a version please look for an existing bug '
      'https://github.com/flutter/flutter/issues/'
      ' and if one does not exist file a new issue.';
}

// Validate that Gradle version and AGP are compatible with each other.
//
// Returns true if versions are compatible.
// Null Gradle version or AGP version returns false.
// If compatability can not be evaulated returns false.
// If versions are newer than the max known version a warning is logged and true
// returned.
//
// Source of truth found here:
// https://developer.android.com/studio/releases/gradle-plugin#updating-gradle
// AGP has a minimim version of gradle required but no max starting at
// AGP version 2.3.0+.
bool validateGradleAndAgp(Logger logger,
    {required String? gradleV, required String? agpV}) {

  // TODO(reidbaker): are these the correct values we want to support?
  const String oldestSupportedAgpVersion = '3.3.0';
  const String oldestSupportedGradleVersion = '4.10.1';

  if (gradleV == null || agpV == null) {
    logger
        .printTrace('Gradle version or AGP version unknown ($gradleV, $agpV).');
    return false;
  }

  // First check if versions are too old.
  if (isWithinVersionRange(agpV,
      min: '0.0', max: oldestSupportedAgpVersion, inclusiveMax: false)) {
    logger.printTrace('AGP Version: $agpV is too old.');
    return false;
  }
  if (isWithinVersionRange(gradleV,
      min: '0.0', max: oldestSupportedGradleVersion, inclusiveMax: false)) {
    logger.printTrace('Gradle Version: $gradleV is too old.');
    return false;
  }

  // Check highest supported version before checking unknown versions.
  if (isWithinVersionRange(agpV, min: '8.0', max: maxKnownAgpVersion)) {
    return isWithinVersionRange(gradleV,
        min: '8.0', max: _maxKnownAndSupportedGradleVersion);
  }
  // Check if versions are newer than the max known versions.
  if (isWithinVersionRange(agpV,
      min: _maxKnownAndSupportedGradleVersion, max: '100.100')) {
    // Assume versions we do not know about are valid but log.
    final bool validGradle =
        isWithinVersionRange(gradleV, min: '8.0', max: '100.00');
    logger.printTrace('Newer than known AGP version ($agpV), gradle ($gradleV).'
        '\n Treating as valid configuration.');
    return validGradle;
  }

  // Begin Known Gradle <-> AGP validation.
  // Max agp here is a made up version to contain all 7.4 changes.
  if (isWithinVersionRange(agpV, min: '7.4', max: '7.5')) {
    return isWithinVersionRange(gradleV,
        min: '7.5', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(agpV,
      min: '7.3', max: '7.4', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.4', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(agpV,
      min: '7.2', max: '7.3', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.3.3', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(agpV,
      min: '7.1', max: '7.2', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.2', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(agpV,
      min: '7.0', max: '7.1', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.0', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(agpV,
      min: '4.2.0', max: '7.0', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '6.7.1', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(agpV,
      min: '4.1.0', max: '4.2.0', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '6.5', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(agpV,
      min: '4.0.0', max: '4.1.0', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '6.1.1', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(
    agpV,
    min: '3.6.0',
    max: '3.6.4',
  )) {
    return isWithinVersionRange(gradleV,
        min: '5.6.4', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(
    agpV,
    min: '3.5.0',
    max: '3.5.4',
  )) {
    return isWithinVersionRange(gradleV,
        min: '5.4.1', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(
    agpV,
    min: '3.4.0',
    max: '3.4.3',
  )) {
    return isWithinVersionRange(gradleV,
        min: '5.1.1', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(
    agpV,
    min: '3.3.0',
    max: '3.3.3',
  )) {
    return isWithinVersionRange(gradleV,
        min: '4.10.1', max: _maxKnownAndSupportedGradleVersion);
  }

  logger.printTrace('Unknown Gradle-Agp compatability, $gradleV, $agpV');
  return false;
}

// Validate that the [javaVersion] and Gradle version are compatible with
// each other.
//
// Source of truth:
// https://docs.gradle.org/current/userguide/compatibility.html#java
bool validateJavaGradle(Logger logger,
    {required String? javaV, required String? gradleV}) {
  // Update these when new versions of Java or Gradle come out.
  // Supported means Java <-> Gradle support.
  const String maxSupportedJavaVersion = '19';

  // https://docs.gradle.org/current/userguide/compatibility.html#java
  const String oldestSupportedJavaVersion = '1.8';
  const String oldestDocumentedJavaGradleCompatability = '2.0';

  // Begin Java <-> Gradle validation.

  if (javaV == null || gradleV == null) {
    logger.printTrace(
        'Java version or Gradle version unknown ($javaV, $gradleV).');
    return false;
  }

  // First check if versions are too old.
  if (isWithinVersionRange(javaV,
      min: '1.1', max: oldestSupportedJavaVersion, inclusiveMax: false)) {
    logger.printTrace('Java Version: $javaV is too old.');
    return false;
  }
  if (isWithinVersionRange(gradleV,
      min: '0.0', max: oldestDocumentedJavaGradleCompatability, inclusiveMax: false)) {
    logger.printTrace('Gradle Version: $gradleV is too old.');
    return false;
  }

  // Check if versions are newer than the max supported versions.
  if (isWithinVersionRange(javaV, min: maxSupportedJavaVersion, max: '100.100', inclusiveMin: false)) {
    // Assume versions Java versions newer than [maxSupportedJavaVersion]
    // required a higher gradle version.
    final bool validGradle =
        isWithinVersionRange(gradleV, min: _maxKnownAndSupportedGradleVersion, max: '100.00');
    logger.printWarning('Newer than known valid Java version ($javaV), gradle ($gradleV).'
        '\n Treating as valid configuration.');
    return validGradle;
  }

  // Begin known Java <-> Gradle evaluation.
  if (isWithinVersionRange(javaV, min: '19', max: '20', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.6', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '18', max: '19', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.5', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '17', max: '18', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.3', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '16', max: '17', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '7.0', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '15', max: '16', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '6.7', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '14', max: '15', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '6.3', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '13', max: '14', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '6.0', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '12', max: '13', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '5.4', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '11', max: '12', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '5.0', max: _maxKnownAndSupportedGradleVersion);
  }
  // 1.11 is a made up java version to cover everything in 1.10.*
  if (isWithinVersionRange(javaV, min: '1.10', max: '1.11', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '4.7', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '1.9', max: '1.10', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '4.3', max: _maxKnownAndSupportedGradleVersion);
  }
  if (isWithinVersionRange(javaV, min: '1.8', max: '1.9', inclusiveMax: false)) {
    return isWithinVersionRange(gradleV,
        min: '2.0', max: _maxKnownAndSupportedGradleVersion);
  }

  logger.printTrace('Unknown Java-Gradle compatability $javaV, $gradleV');
  return false;
}



/// Returns the Gradle version that is required by the given Android Gradle plugin version
/// by picking the largest compatible version from
/// https://developer.android.com/studio/releases/gradle-plugin#updating-gradle
String getGradleVersionFor(String androidPluginVersion) {
  if (isWithinVersionRange(androidPluginVersion, min: '1.0.0', max: '1.1.3')) {
    return '2.3';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '1.2.0', max: '1.3.1')) {
    return '2.9';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '1.5.0', max: '1.5.0')) {
    return '2.2.1';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '2.0.0', max: '2.1.2')) {
    return '2.13';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '2.1.3', max: '2.2.3')) {
    return '2.14.1';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '2.3.0', max: '2.9.9')) {
    return '3.3';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '3.0.0', max: '3.0.9')) {
    return '4.1';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '3.1.0', max: '3.1.9')) {
    return '4.4';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '3.2.0', max: '3.2.1')) {
    return '4.6';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '3.3.0', max: '3.3.2')) {
    return '4.10.2';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '3.4.0', max: '3.5.0')) {
    return '5.6.2';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '4.0.0', max: '4.1.0')) {
    return '6.7';
  }
  // 7.5 is a made up value to include everything through 7.4.*
  if (isWithinVersionRange(androidPluginVersion, min: '7.0', max: '7.5')) {
    return '7.5';
  }
  if (isWithinVersionRange(androidPluginVersion, min: '7.5', max: maxKnownAgpVersion)) {
    return '8.0';
  }
  // Assume if AGP is newer than this code know about return the highest gradle
  // version we know about.
  if (isWithinVersionRange(androidPluginVersion, min: maxKnownAgpVersion, max: '100.100')) {
    return _maxKnownAndSupportedGradleVersion;
  }
  // TODO(reidbaker): should this be a regular thow so that @christopherfujino
  // can see these in crash logging.
  throwToolExit('Unsupported Android Plugin version: $androidPluginVersion.');
}

/// Overwrite local.properties in the specified Flutter project's Android
/// sub-project, if needed.
///
/// If [requireAndroidSdk] is true (the default) and no Android SDK is found,
/// this will fail with a [ToolExit].
void updateLocalProperties({
  required FlutterProject project,
  BuildInfo? buildInfo,
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

  void changeIfNecessary(String key, String? value) {
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

  final AndroidSdk? androidSdk = globals.androidSdk;
  if (androidSdk != null) {
    changeIfNecessary('sdk.dir', globals.fsUtils.escapePath(androidSdk.directory.path));
  }

  changeIfNecessary('flutter.sdk', globals.fsUtils.escapePath(Cache.flutterRoot!));
  if (buildInfo != null) {
    changeIfNecessary('flutter.buildMode', buildInfo.modeName);
    final String? buildName = validatedBuildNameForPlatform(
      TargetPlatform.android_arm,
      buildInfo.buildName ?? project.manifest.buildName,
      globals.logger,
    );
    changeIfNecessary('flutter.versionName', buildName);
    final String? buildNumber = validatedBuildNumberForPlatform(
      TargetPlatform.android_arm,
      buildInfo.buildNumber ?? project.manifest.buildNumber,
      globals.logger,
    );
    changeIfNecessary('flutter.versionCode', buildNumber);
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
  final AndroidSdk? androidSdk = globals.androidSdk;
  if (androidSdk != null) {
    settings.values['sdk.dir'] = globals.fsUtils.escapePath(androidSdk.directory.path);
  }
  settings.writeContents(properties);
}

void exitWithNoSdkMessage() {
  BuildEvent('unsupported-project',
          type: 'gradle',
          eventError: 'android-sdk-not-found',
          flutterUsage: globals.flutterUsage)
      .send();
  throwToolExit('${globals.logger.terminal.warningMark} No Android SDK found. '
      'Try setting the ANDROID_SDK_ROOT environment variable.');
}
