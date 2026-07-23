// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/local.dart' as local_fs;
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../base/version_range.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'android_sdk.dart';
import 'android_support_versions.dart';
export 'android_support_versions.dart';

// These are the versions used in the project templates.
//
// In general, Flutter aims to default to the latest stable version.
// However, this currently requires to migrate existing integration tests to the
// latest supported values.
//
// Please see the README before changing any of these values.

// When bumping, also update:
//  * Gradle warn version in packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
//  * Gradle test constants in packages/flutter_tools/gradle/src/test/kotlin/DependencyVersionCheckerTest.kt
// See https://gradle.org/releases
const templateDefaultGradleVersion = '9.3.1';

// When bumping, also update:
//  * AGP version constants in packages/flutter_tools/gradle/build.gradle.kts
//  * AGP warn version in packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
//  * AGP test constants in packages/flutter_tools/gradle/src/test/kotlin/DependencyVersionCheckerTest.kt
//  * AGP test constants in packages/flutter_tools/gradle/src/test/kotlin/FlutterPluginUtilsTest.kt
// See https://mvnrepository.com/artifact/com.android.tools.build/gradle
const templateAndroidGradlePluginVersion = '9.1.0';
const templateAndroidGradlePluginVersionForModule = '9.1.0';

// When bumping, also update:
//  * KGP version constants in packages/flutter_tools/gradle/build.gradle.kts
//  * KGP warn version in packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
//  * KGP jvm constant in packages/flutter_tools/gradle/src/test/kotlin/DependencyVersionCheckerTest.kt
// See https://kotlinlang.org/docs/releases.html#release-details
const templateKotlinGradlePluginVersion = '2.4.0';

// The Flutter Gradle Plugin is only applied to app projects, and modules that
// are built from source using (`include_flutter.groovy`). The remaining
// projects are: plugins, and modules compiled as AARs. In modules, the
// ephemeral directory `.android` is always regenerated after `flutter pub get`,
// so new versions are picked up after a Flutter upgrade.
//
// Please see the README before changing any of these values.
const compileSdkVersionInt = 36;
const compileSdkVersion = '$compileSdkVersionInt';
const targetSdkVersion = '36';
// When bumping, also update:
//  * ndkVersion constant in this file
//  * ndkVersion in FlutterExtension in packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt
const ndkVersion = '28.2.13676358';
final minBuildToolsVersion = Version(28, 0, 3);
final AndroidSupportVersions _supportVersions = _loadSupportVersions();
final int minSdkVersionInt = _supportVersions.minSdkVersion.warn;
final String minSdkVersion = '$minSdkVersionInt';

FileSystem get _fs {
  try {
    return globals.fs;
  } on Object catch (_) {
    return const local_fs.LocalFileSystem();
  }
}

AndroidSupportVersions _loadSupportVersions() {
  final FileSystem fs = _fs;
  final String jsonPath = fs.path.join(
    Cache.flutterRoot!,
    'packages',
    'flutter_tools',
    'gradle',
    'src',
    'main',
    'resources',
    'android_support_versions.json',
  );
  return AndroidSupportVersions.load(fs, jsonPath);
}

// Align with packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt.
final Version errorJavaMinVersionAndroid = Version.parse(_supportVersions.java.error)!;
final Version warnJavaMinVersionAndroid = Version.parse(_supportVersions.java.warn)!;

final String oneMajorVersionHigherJavaVersion = _supportVersions.oneMajorVersionHigherJavaVersion;

// Update this when new versions of Gradle come out including minor versions
// and should correspond to the maximum Gradle version we test in CI.
//
// Supported here means supported by the tooling for
// flutter analyze --suggestions and does not imply broader flutter support.
final String maxKnownAndSupportedGradleVersion = _supportVersions.maxKnownVersions.gradle;

// Update this with new KGP versions come out including minor versions.
//
// Supported here means supported by the tooling for
// flutter analyze --suggestions and does not imply broader flutter support.
final String maxKnownAndSupportedKgpVersion = _supportVersions.maxKnownVersions.kgp;

// Update this when new versions of AGP come out.
//
// Supported here means tooling is aware of this version's Java <-> AGP
// compatibility.
@visibleForTesting
final String maxKnownAndSupportedAgpVersion = _supportVersions.maxKnownVersions.agp;

// Update this when new versions of AGP with Kotlin support come out.
//
// Supported here means supported by the tooling for
// flutter analyze --suggestions and does not imply broader flutter support.
final String maxKnownAgpVersionWithFullKotlinSupport =
    _supportVersions.maxKnownVersions.agpWithKotlin;

// Update this when new versions of AGP come out.
final String maxKnownAgpVersion = _supportVersions.maxKnownVersions.agp;

// Supported here means tooling is aware of this versions
// Java <-> AGP compatibility and does not imply broader flutter support.
// For use in flutter see the code in:
// flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
@visibleForTesting
final String oldestConsideredAgpVersion = _supportVersions.oldestConsideredVersions.agp;

// Supported here means tooling is aware of this versions
// gradle compatibility and does not imply broader flutter support.
@visibleForTesting
final String oldestConsideredGradleVersion = _supportVersions.oldestConsideredVersions.gradle;

// Supported here means tooling is aware of this versions
// gradle/AGP compatibility and does not imply broader flutter support.
@visibleForTesting
final String oldestDocumentedKgpCompatabilityVersion =
    _supportVersions.oldestConsideredVersions.kgp;

// Oldest documented version of AGP that has a listed minimum
// compatible Java version.
final String oldestDocumentedJavaAgpCompatibilityVersion =
    _supportVersions.oldestConsideredVersions.javaAgp;

// Constant used in [_buildAndroidGradlePluginRegExp] and
// [_settingsAndroidGradlePluginRegExp] and [_kotlinGradlePluginRegExpFromId]
// to identify the version section.
const _versionGroupName = 'version';

// AGP can be defined in the dependencies block of [build.gradle] or [build.gradle.kts].
// Expected content (covers both classpath and compileOnly cases):
// Groovy DSL with single quotes - 'com.android.tools.build:gradle:{{agpVersion}}'
// Groovy DSL with double quotes - "com.android.tools.build:gradle:{{agpVersion}}"
// Kotlin DSL - ("com.android.tools.build.gradle:{{agpVersion}}")
// `(?<=^[^/]*)` is a positive look behind to ensure that the line is not commented out.
// `?<version>` is used to name the version group which helps with extraction.
// `\k<quote>` takes advanatage of the precviously declared `(?<quote>['"])` for reuse.
final _androidGradlePluginRegExpFromDependencies = RegExp(
  r"""\b(?:classpath|compileOnly)\b(?<=^[^/]*)\s*\(?(?<quote>['"])com\.android\.tools\.build:gradle:(?<version>\d+(?:.\d+){1,2}).*\k<quote>""",
  multiLine: true,
);

// AGP can be defined in the plugins block of [build.gradle],
// [build.gradle.kts], [settings.gradle], or [settings.gradle.kts].
// Expected content:
// Groovy DSL with single quotes - id 'com.android.application' version '{{agpVersion}}'
// Groovy DSL with double quotes - id "com.android.application" version "{{agpVersion}}"
// Kotlin DSL - id("com.android.application") version "{{agpVersion}}"
// `(?<=^[^/]*)` is a positive look behind to ensure that the line is not commented out.
// `?<version>` is used to name the version group which helps with extraction.
// `\k<quote>` takes advanatage of the precviously declared `(?<quote>['"])` for reuse.
final _androidGradlePluginRegExpFromId = RegExp(
  r"""\b(?:id)\b(?<=^[^/]*)\s*\(?(?<quote>['"])com\.android\.application\k<quote>\)?\s+version\s+\k<quote>(?<version>\d+(\.\d+){1,2})\)?""",
  multiLine: true,
);

// KGP is defined in several places this code only checks in plugins block
// of [settings.gradle] and [settings.gradle.kts].
// Expected content:
// Groovy DSL - id "org.jetbrains.kotlin.android" version "{{kgpVersion}}"
// Kotlin DSL - id("org.jetbrains.kotlin.android") version "{{kgpVersion}}"
// `(?<=^[^/]*)` is a positive look behind to ensure that the line is not commented out.
// `?<version>` is used to name the version group which helps with extraction.
// `\k<quote>` takes advanatage of the precviously declared `(?<quote>['"])` for reuse.
final _kotlinGradlePluginRegExpFromId = RegExp(
  r"""\b(?:id)\b(?<=^[^/]*)\s*\(?(?<quote>['"])org\.jetbrains\.kotlin\.android\k<quote>\)?\s+version\s+\k<quote>(?<version>\d+(\.\d+){1,2})\)?""",
  multiLine: true,
);

// Expected content format (with lines above and below).
// Version can have 2 or 3 numbers.
// 'distributionUrl=https\://services.gradle.org/distributions/gradle-7.4.2-all.zip'
// '^\s*' protects against commented out lines.
final distributionUrlRegex = RegExp(r'^\s*distributionUrl\s*=\s*.*\.zip', multiLine: true);

// Modified version of the gradle distribution url match designed to only match
// gradle.org urls so that we can guarantee any modifications to the url
// still points to a hosted zip.
final gradleOrgVersionMatch = RegExp(
  r'^\s*distributionUrl\s*=\s*https\\://services\.gradle\.org/distributions/gradle-([\d.]+)-(.*)\.zip',
  multiLine: true,
);

// This matches uncommented minSdkVersion lines in the module-level build.gradle
// file which have minSdkVersion 16, 17, 18, 19, 20, 21, 22, 23 set with space syntax,
// equals syntax and when using minSdk or minSdkVersion.
// Matches uncommented minSdkVersion lines using equals syntax (=)
final int _errorMinSdk = _supportVersions.minSdkVersion.error;
final int _rangeSize = _errorMinSdk < 16 ? 0 : _errorMinSdk - 16 + 1;
final String _tooOldMinSdkRegexPart = List<int>.generate(_rangeSize, (int i) => 16 + i).join('|');

// Matches uncommented minSdkVersion lines using equals syntax (=)
final tooOldMinSdkVersionEqualsMatch = RegExp(
  '(?<=^\\s*)minSdk(Version)?\\s*=\\s*($_tooOldMinSdkRegexPart)(?=\\s*(?://|\$))',
  multiLine: true,
);

// Matches uncommented minSdkVersion lines using space syntax (no =)
final tooOldMinSdkVersionSpaceMatch = RegExp(
  '(?<=^\\s*)minSdk(Version)?\\s+($_tooOldMinSdkRegexPart)(?=\\s*(?://|\$))',
  multiLine: true,
);

// From https://docs.gradle.org/current/userguide/command_line_interface.html#command_line_interface
// Flag to print the versions for gradle, kotlin dsl, groovy, etc.
const gradleVersionsFlag = r'--version';

// Directory under android/ that gradle uses to store gradle information.
// Regularly used with [gradleWrapperDirectory] and
// [gradleWrapperPropertiesFilename].
// Different from the directory of gradle files stored in
// `_cache.getArtifactDirectory('gradle_wrapper')`
const gradleDirectoryName = 'gradle';
const gradleWrapperDirectoryName = 'wrapper';
const gradleWrapperPropertiesFilename = 'gradle-wrapper.properties';

/// Provides utilities to run a Gradle task, such as finding the Gradle executable
/// or constructing a Gradle project.
class GradleUtils {
  GradleUtils({
    required Platform platform,
    required Logger logger,
    required Cache cache,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _platform = platform,
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

    final File gradle = androidDir.childFile(getGradlewFileName(_platform));

    if (gradle.existsSync()) {
      _logger.printTrace('Using gradle from ${gradle.absolute.path}.');
      // If the Gradle executable doesn't have execute permission,
      // then attempt to set it.
      _operatingSystemUtils.makeExecutable(gradle);
      return gradle.absolute.path;
    }
    throwToolExit(
      'Unable to locate gradlew script. Please check that ${gradle.path} '
      'exists or that ${gradle.dirname} can be read.',
    );
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
      },
    );
    // Add the `gradle-wrapper.properties` file if it doesn't exist.
    final Directory propertiesDirectory = directory
        .childDirectory(gradleDirectoryName)
        .childDirectory(gradleWrapperDirectoryName);
    final File propertiesFile = propertiesDirectory.childFile(gradleWrapperPropertiesFilename);

    if (propertiesFile.existsSync()) {
      return;
    }
    propertiesDirectory.createSync(recursive: true);
    final String gradleVersion = getGradleVersionForAndroidPlugin(directory, _logger);
    final propertyContents =
        '''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-$gradleVersion-all.zip
''';
    propertiesFile.writeAsStringSync(propertyContents);
  }

  /// Returns either the gradle-wrapper.properties value from the passed in
  /// [directory] or if not present the version available in local path.
  ///
  /// If gradle version is not found null is returned.
  /// [directory] should be an android directory with a build.gradle file.
  Future<String?> getGradleVersion(Directory directory, ProcessManager processManager) async {
    final File propertiesFile = getGradleWrapperFile(directory);

    if (propertiesFile.existsSync()) {
      final String wrapperFileContent = propertiesFile.readAsStringSync();

      final RegExpMatch? distributionUrl = distributionUrlRegex.firstMatch(wrapperFileContent);
      if (distributionUrl != null) {
        final String? gradleVersion = parseGradleVersionFromDistributionUrl(
          distributionUrl.group(0),
        );
        if (gradleVersion != null) {
          return gradleVersion;
        } else {
          // Did not find gradle zip url. Likely this is a bug in our parsing.
          _logger.printWarning(_formatParseWarning(wrapperFileContent, type: 'gradle'));
        }
      } else {
        // If no distributionUrl log then treat as if there was no propertiesFile.
        _logger.printTrace(
          '$propertiesFile does not provide a Gradle version falling back to system gradle.',
        );
      }
    } else {
      // Could not find properties file.
      _logger.printTrace('$propertiesFile does not exist falling back to system gradle');
    }
    // System installed Gradle version.
    // TODO(reidbaker): Modify this gradle execution to use gradlew.
    if (processManager.canRun('gradle')) {
      final gradleVersionsVerbose =
          (await processManager.run(<String>['gradle', gradleVersionsFlag])).stdout as String;
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
      // Outer parentheticals `Gradle (...)` denote a grouping used to extract
      // the version number.
      final gradleVersionRegex = RegExp(r'Gradle\s+(\d+\.\d+(?:\.\d+)?)');
      final RegExpMatch? version = gradleVersionRegex.firstMatch(gradleVersionsVerbose);
      if (version == null) {
        // Most likely a bug in our parse implementation/regex.
        _logger.printWarning(_formatParseWarning(gradleVersionsVerbose, type: 'gradle'));
        return null;
      }
      return version.group(1);
    } else {
      _logger.printTrace('Could not run system gradle');
      return null;
    }
  }
}

/// Returns the Gradle version that the current Android plugin depends on when found,
/// otherwise it returns a default version.
///
/// The Android plugin version is specified in the `build.gradle`,
/// `build.gradle.kts`, `settings.gradle`, or `settings.gradle.kts` file within
/// the project's Android directory.
String getGradleVersionForAndroidPlugin(Directory directory, Logger logger) {
  final String? androidPluginVersion = getAgpVersion(directory, logger);
  if (androidPluginVersion == null) {
    logger.printTrace(
      'AGP version cannot be determined, assuming Gradle version: $templateDefaultGradleVersion',
    );
    return templateDefaultGradleVersion;
  }
  return getGradleVersionFor(androidPluginVersion);
}

/// Returns the gradle file from the top level directory.
/// The returned file is not guaranteed to be present.
File getGradleWrapperFile(Directory directory) {
  return directory
      .childDirectory(gradleDirectoryName)
      .childDirectory(gradleWrapperDirectoryName)
      .childFile(gradleWrapperPropertiesFilename);
}

/// Parses the gradle wrapper distribution url to return a string containing
/// the version number.
///
/// Expected input is of the form '...gradle-7.4.2-all.zip', and the output
/// would be of the form '7.4.2'.
String? parseGradleVersionFromDistributionUrl(String? distributionUrl) {
  if (distributionUrl == null) {
    return null;
  }
  final List<String> zipParts = distributionUrl.split('-');
  if (zipParts.length < 2) {
    return null;
  }
  return zipParts[1];
}

/// Returns the Kotlin Gradle Plugin (KGP) version that the current project
/// depends on if found, `null` otherwise.
/// [androidDirectory] should be an android directory with a `build.gradle` file.
Future<String?> getKgpVersion(
  Directory androidDirectory,
  Logger logger,
  ProcessManager processManager,
) async {
  // Maintainers of the kotlin dsl and the kotlin gradle plugin are different.
  //
  // Android Docs refer to the kotlin gradle plugin with either the full name or KGP.
  // Kotlin docs refer to the kotlin gradle plugin as kotlin android plugin.
  //
  // gradle --version or ./gradlew --version will print the kotlin dsl version.
  // This version normally changes with the version of gradle.
  // https://github.com/gradle/gradle/blob/cefbee263181a924ac4efcaace6bda97a55bc0f7/platforms/core-runtime/gradle-cli/src/main/java/org/gradle/launcher/cli/DefaultCommandLineActionFactory.java#L260
  // This version is NOT the version of KGP that the project uses.
  //
  // Instead the kgpVersion task is a custom flutter task dynamically added that can
  // print the kgp version if gradle can run successfully.

  if (processManager.canRun('./gradlew', workingDirectory: androidDirectory.path)) {
    final ProcessResult command = await processManager.run(<String>[
      './gradlew',
      'kgpVersion',
      '-q',
    ], workingDirectory: androidDirectory.path);
    if (command.exitCode == 0) {
      final kgpVersionOutput = command.stdout as String;

      // See expected output defined in
      // flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterPluginUtils.kt addTaskForKGPVersion
      final kotlinVersionRegex = RegExp(r'KGP Version:\s+(\d+\.\d+(?:\.\d+)?)');
      final RegExpMatch? version = kotlinVersionRegex.firstMatch(kgpVersionOutput);
      if (version != null) {
        return version.group(1);
      }
      // Most likely a bug in our parse implementation/regex.
      logger.printWarning(_formatParseWarning(kgpVersionOutput, type: 'kotlin'));
    } else {
      logger.printTrace('Non zero exit code from gradle task kgpVersion.');
    }
  } else {
    logger.printTrace('Could not run gradle task kgpVersion.');
  }

  // Project valiation code is regularly run on projects that can not build.
  // Because of that this code also attempts to search through known template
  // locations for kotlin versions.

  logger.printTrace('Checking settings for kgp version.');
  File settingsFile = androidDirectory.childFile('settings.gradle');
  if (!settingsFile.existsSync()) {
    settingsFile = androidDirectory.childFile('settings.gradle.kts');
  }

  if (settingsFile.existsSync()) {
    final String settingsFileContent = settingsFile.readAsStringSync();
    final RegExpMatch? settingsMatch = _kotlinGradlePluginRegExpFromId.firstMatch(
      settingsFileContent,
    );

    if (settingsMatch != null) {
      final String? kgpVersion = settingsMatch.namedGroup(_versionGroupName);
      logger.printTrace('$settingsFile provides KGP version: $kgpVersion');
      return kgpVersion;
    }
  } else {
    logger.printTrace('No settings.gradle.kts');
  }

  return null;
}

/// Returns the Android Gradle Plugin (AGP) version that the current project
/// depends on when found, null otherwise.
///
/// The Android plugin version is specified in the `build.gradle`,
/// `build.gradle.kts`, `settings.gradle, or `settings.gradle.kts`
/// files within the project's Android directory ([androidDirectory]).
String? getAgpVersion(Directory androidDirectory, Logger logger) {
  File buildFile = androidDirectory.childFile('build.gradle');
  if (!buildFile.existsSync()) {
    buildFile = androidDirectory.childFile('build.gradle.kts');
  }
  if (!buildFile.existsSync()) {
    logger.printTrace('Cannot find build.gradle/build.gradle.kts in $androidDirectory');
    return null;
  }
  final String buildFileContent = buildFile.readAsStringSync();
  final RegExpMatch? buildMatchClasspath = _androidGradlePluginRegExpFromDependencies.firstMatch(
    buildFileContent,
  );
  if (buildMatchClasspath != null) {
    final String? androidPluginVersion = buildMatchClasspath.namedGroup(_versionGroupName);
    logger.printTrace('$buildFile provides AGP version from classpath: $androidPluginVersion');
    return androidPluginVersion;
  }
  final RegExpMatch? buildMatchId = _androidGradlePluginRegExpFromId.firstMatch(buildFileContent);
  if (buildMatchId != null) {
    final String? androidPluginVersion = buildMatchId.namedGroup(_versionGroupName);
    logger.printTrace('$buildFile provides AGP version from plugin id: $androidPluginVersion');
    return androidPluginVersion;
  }

  logger.printTrace("$buildFile doesn't provide an AGP version. Checking settings.");
  File settingsFile = androidDirectory.childFile('settings.gradle');
  if (!settingsFile.existsSync()) {
    settingsFile = androidDirectory.childFile('settings.gradle.kts');
  }
  if (!settingsFile.existsSync()) {
    logger.printTrace('Cannot find settings.gradle/settings.gradle.kts in $androidDirectory');
    return null;
  }
  final String settingsFileContent = settingsFile.readAsStringSync();
  final RegExpMatch? settingsMatch = _androidGradlePluginRegExpFromId.firstMatch(
    settingsFileContent,
  );

  if (settingsMatch != null) {
    final String? androidPluginVersion = settingsMatch.namedGroup(_versionGroupName);
    logger.printTrace('$settingsFile provides AGP version: $androidPluginVersion');
    return androidPluginVersion;
  }
  logger.printTrace("$settingsFile doesn't provide an AGP version.");
  return null;
}

String _formatParseWarning(String content, {required String type}) {
  return 'Could not parse $type version from: \n'
      '$content \n'
      'If there is a version please look for an existing bug '
      'https://github.com/flutter/flutter/issues/'
      ' and if one does not exist file a new issue.';
}

// Validate that KGP and Gradle are compatible with each other.
//
// Returns true if versions are compatible.
// Null or empty Gradle or KGP version returns false.
// If compatibility cannot be evaluated returns false.
// If versions are newer than the max known version a warning is logged and true
// returned.
//
// Source of truth found here:
// https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin
bool validateGradleAndKGP(Logger logger, {required String? kgpV, required String? gradleV}) {
  if (gradleV == null || kgpV == null || gradleV.isEmpty || kgpV.isEmpty) {
    logger.printTrace('Gradle or KGP version unknown ($gradleV, $kgpV).');
    return false;
  }

  if (isWithinVersionRange(gradleV, min: '0.0', max: oldestConsideredGradleVersion)) {
    logger.printTrace(
      'Gradle version $gradleV older than oldest considered $oldestConsideredGradleVersion',
    );
    return false;
  }

  if (isWithinVersionRange(
    kgpV,
    min: maxKnownAndSupportedKgpVersion,
    max: '100.100',
    inclusiveMin: false,
  )) {
    logger.printTrace(
      'Newer than known KGP version ($kgpV), gradle ($gradleV).'
      '\n Treating as valid configuration.',
    );
    return true;
  }

  // https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin
  // Documentation is non continuous, past versions are known to the
  // publishers of KGP. When covering version ranges beyond what is documented
  // add a comment with the documented value.
  // Continuous KGP version handling is preferred in case an emergency patch to a
  // past release is shipped this code will assume the version range that is closest.

  for (final KgpGradleCompat data in _supportVersions.kgpGradleCompat) {
    if (isWithinVersionRange(
      kgpV,
      min: data.kgpMin,
      max: data.kgpMax,
      inclusiveMax: data.inclusiveMaxKgp,
    )) {
      return isWithinVersionRange(
        gradleV,
        min: data.gradleMin,
        max: data.gradleMax,
        inclusiveMax: data.inclusiveMaxGradle,
      );
    }
  }

  logger.printTrace('Unknown KGP-Gradle compatibility, KGP: $kgpV, Gradle: $gradleV');
  return false;
}

// Validate that KGP and AGP are compatible with each other.
//
// Returns true if versions are compatible.
// Null or empty KGP or AGP version returns false.
// If compatibility cannot be evaluated returns false.
// If versions are newer than the max known version a warning is logged and true
// returned.
//
// Source of truth found here:
// https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin
bool validateAgpAndKgp(Logger logger, {required String? kgpV, required String? agpV}) {
  if (agpV == null || kgpV == null || agpV.isEmpty || kgpV.isEmpty) {
    logger.printTrace('KGP or AGP version unknown ($kgpV, $agpV).');
    return false;
  }

  if (isWithinVersionRange(agpV, min: '0.0', max: oldestConsideredAgpVersion)) {
    logger.printTrace(
      'AGP version ($agpV) older than oldest supported $oldestConsideredAgpVersion.',
    );
  }

  if (isWithinVersionRange(
        kgpV,
        min: maxKnownAndSupportedKgpVersion,
        max: '100.100',
        inclusiveMin: false,
      ) ||
      isWithinVersionRange(
        agpV,
        min: maxKnownAgpVersionWithFullKotlinSupport,
        max: '100.100',
        inclusiveMin: false,
      )) {
    logger.printTrace(
      'Newer than known KGP version ($kgpV), AGP ($agpV).'
      '\n Treating as valid configuration.',
    );
    return true;
  }

  // https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin
  // Documentation is non continuous, past versions are known to the
  // publishers of KGP. When covering version ranges beyond what is documented
  // add a comment with the documented value.
  // Continuous KGP version handling is preferred in case an emergency patch to a
  // past release is shipped this code will assume the version range that is closest.

  for (final AgpKgpCompat data in _supportVersions.agpKgpCompat) {
    if (isWithinVersionRange(
      kgpV,
      min: data.kgpMin,
      max: data.kgpMax,
      inclusiveMax: data.inclusiveMaxKgp,
    )) {
      return isWithinVersionRange(
        agpV,
        min: data.agpMin,
        max: data.agpMax,
        inclusiveMax: data.inclusiveMaxAgp,
      );
    }
  }

  logger.printTrace('Unknown KGP-AGP compatibility, KGP: $kgpV, AGP: $agpV');
  return false;
}

/// Returns the compatible Gradle version range for a given Kotlin Gradle Plugin (KGP) version.
String? getCompatibleGradleRangeForKgp(String kgpV) {
  for (final KgpGradleCompat data in _supportVersions.kgpGradleCompat) {
    if (isWithinVersionRange(
      kgpV,
      min: data.kgpMin,
      max: data.kgpMax,
      inclusiveMax: data.inclusiveMaxKgp,
    )) {
      final minPart = '>= ${data.gradleMin}';
      final op = data.inclusiveMaxGradle ? '<=' : '<';
      return '$minPart and $op ${data.gradleMax}';
    }
  }
  return null;
}

/// Returns the compatible Kotlin Gradle Plugin (KGP) version range for a given Gradle version.
String? getCompatibleKgpRangeForGradle(String gradleV) {
  KgpGradleCompat? highestMatch;
  KgpGradleCompat? lowestMatch;
  for (final KgpGradleCompat data in _supportVersions.kgpGradleCompat) {
    final bool compatible = isWithinVersionRange(
      gradleV,
      min: data.gradleMin,
      max: data.gradleMax,
      inclusiveMax: data.inclusiveMaxGradle,
    );
    if (compatible) {
      highestMatch ??= data;
      lowestMatch = data;
    }
  }
  if (highestMatch == null || lowestMatch == null) {
    return null;
  }
  final minPart = '>= ${lowestMatch.kgpMin}';
  final op = highestMatch.inclusiveMaxKgp ? '<=' : '<';
  return '$minPart and $op ${highestMatch.kgpMax}';
}

/// Returns the compatible Android Gradle Plugin (AGP) version range for a given Kotlin Gradle Plugin (KGP) version.
String? getCompatibleAgpRangeForKgp(String kgpV) {
  for (final AgpKgpCompat data in _supportVersions.agpKgpCompat) {
    if (isWithinVersionRange(
      kgpV,
      min: data.kgpMin,
      max: data.kgpMax,
      inclusiveMax: data.inclusiveMaxKgp,
    )) {
      final minPart = '>= ${data.agpMin}';
      final op = data.inclusiveMaxAgp ? '<=' : '<';
      return '$minPart and $op ${data.agpMax}';
    }
  }
  return null;
}

/// Returns the compatible Kotlin Gradle Plugin (KGP) version range for a given Android Gradle Plugin (AGP) version.
String? getCompatibleKgpRangeForAgp(String agpV) {
  AgpKgpCompat? highestMatch;
  AgpKgpCompat? lowestMatch;
  for (final AgpKgpCompat data in _supportVersions.agpKgpCompat) {
    final bool compatible = isWithinVersionRange(
      agpV,
      min: data.agpMin,
      max: data.agpMax,
      inclusiveMax: data.inclusiveMaxAgp,
    );
    if (compatible) {
      highestMatch ??= data;
      lowestMatch = data;
    }
  }
  if (highestMatch == null || lowestMatch == null) {
    return null;
  }
  final minPart = '>= ${lowestMatch.kgpMin}';
  final op = highestMatch.inclusiveMaxKgp ? '<=' : '<';
  return '$minPart and $op ${highestMatch.kgpMax}';
}

// Validate that Gradle version and AGP are compatible with each other.
//
// Returns true if versions are compatible.
// Null Gradle version or AGP version returns false.
// If compatibility cannot be evaluated returns false.
// If versions are newer than the max known version a warning is logged and true
// returned.
//
// Source of truth found here:
// https://developer.android.com/studio/releases/gradle-plugin#updating-gradle
// AGP has a minimum version of gradle required but no max starting at
// AGP version 2.3.0+.
bool validateGradleAndAgp(Logger logger, {required String? gradleV, required String? agpV}) {
  if (gradleV == null || agpV == null) {
    logger.printTrace('Gradle version or AGP version unknown ($gradleV, $agpV).');
    return false;
  }

  // First check if versions are too old.
  if (isWithinVersionRange(
    agpV,
    min: '0.0',
    max: oldestConsideredAgpVersion,
    inclusiveMax: false,
  )) {
    logger.printTrace('AGP Version: $agpV is too old.');
    return false;
  }
  if (isWithinVersionRange(
    gradleV,
    min: '0.0',
    max: oldestConsideredGradleVersion,
    inclusiveMax: false,
  )) {
    logger.printTrace('Gradle Version: $gradleV is too old.');
    return false;
  }

  // Check if versions are newer than the max known versions.
  if (isWithinVersionRange(agpV, min: maxKnownAndSupportedAgpVersion, max: '100.100')) {
    // Assume versions we do not know about are valid but log.
    final bool validGradle = isWithinVersionRange(
      gradleV,
      min: maxKnownAndSupportedGradleVersion,
      max: '100.00',
    );
    logger.printTrace(
      'Newer than known AGP version ($agpV), gradle ($gradleV).'
      '\n Treating as valid configuration.',
    );
    return validGradle;
  }

  for (final GradleAgpCompat data in _supportVersions.gradleAgpCompat) {
    if (isWithinVersionRange(
      agpV,
      min: data.agpMin,
      max: data.agpMax,
      inclusiveMax: data.inclusiveMaxAgp,
    )) {
      return isWithinVersionRange(
        gradleV,
        min: data.gradleMin,
        max: maxKnownAndSupportedGradleVersion,
      );
    }
  }

  logger.printTrace('Unknown Gradle-AGP compatibility, Gradle: $gradleV, AGP: $agpV');
  return false;
}

/// Validate that the [javaVersion] and [gradleVersion] are compatible with
/// each other.
///
/// Source of truth:
/// https://docs.gradle.org/current/userguide/compatibility.html#java
bool validateJavaAndGradle(
  Logger logger, {
  required String? javaVersion,
  required String? gradleVersion,
}) {
  // https://docs.gradle.org/current/userguide/compatibility.html#java
  const oldestConsideredJavaVersion = '1.8';
  const oldestDocumentedJavaGradleCompatibility = '2.0';

  // Begin Java <-> Gradle validation.

  if (javaVersion == null || gradleVersion == null) {
    logger.printTrace('Java version or Gradle version unknown ($javaVersion, $gradleVersion).');
    return false;
  }

  // First check if versions are too old.
  if (isWithinVersionRange(
    javaVersion,
    min: '1.1',
    max: oldestConsideredJavaVersion,
    inclusiveMax: false,
  )) {
    logger.printTrace('Java Version: $javaVersion is too old.');
    return false;
  }
  if (isWithinVersionRange(
    gradleVersion,
    min: '0.0',
    max: oldestDocumentedJavaGradleCompatibility,
    inclusiveMax: false,
  )) {
    logger.printTrace('Gradle Version: $gradleVersion is too old.');
    return false;
  }

  // Check if versions are newer than the max supported versions.
  if (isWithinVersionRange(javaVersion, min: oneMajorVersionHigherJavaVersion, max: '100.100')) {
    // Assume versions Java versions newer than [maxSupportedJavaVersion]
    // required a higher gradle version.
    final bool validGradle = isWithinVersionRange(
      gradleVersion,
      min: maxKnownAndSupportedGradleVersion,
      max: '100.00',
    );
    logger.printWarning(
      'Newer than known valid Java version ($javaVersion), gradle ($gradleVersion).'
      '\n Treating as valid configuration.',
    );
    return validGradle;
  }

  // Begin known Java <-> Gradle evaluation.
  for (final JavaGradleCompat data in _supportVersions.javaGradleCompat) {
    if (isWithinVersionRange(
      javaVersion,
      min: data.javaMin,
      max: data.javaMax,
      inclusiveMax: false,
    )) {
      // Null max value should be treated as unbounded on the max side.
      return isWithinVersionRange(
        gradleVersion,
        min: data.gradleMin,
        max: data.gradleMax ?? '100.100',
      );
    }
  }

  logger.printTrace(
    'Unknown Java-Gradle compatibility, Java: $javaVersion, Gradle: $gradleVersion',
  );
  return false;
}

/// Returns compatibility information for the valid range of Gradle versions for
/// the specified Java version.
///
/// Returns null when the tooling has not documented the compatible Gradle
/// versions for the Java version (either the version is too old or too new). If
/// this seems like a mistake, the caller may need to update the
/// android_support_versions.json detailing Java/Gradle compatibility.
JavaGradleCompat? getValidGradleVersionRangeForJavaVersion(Logger logger, {required String javaV}) {
  for (final JavaGradleCompat data in _supportVersions.javaGradleCompat) {
    if (isWithinVersionRange(javaV, min: data.javaMin, max: data.javaMax, inclusiveMax: false)) {
      return data;
    }
  }

  logger.printTrace('Unable to determine valid Gradle version range for Java version $javaV.');
  return null;
}

/// Validate that the specified Java and Android Gradle Plugin (AGP) versions are
/// compatible with each other.
///
/// Returns true when the specified Java and AGP versions are
/// definitely compatible; True if AGP is newer than known, otherwise, false. In addition,
/// this will return false when either a null Java or AGP version is provided.
///
/// Source of truth are the AGP release notes:
/// https://developer.android.com/build/releases/gradle-plugin
bool validateJavaAndAgp(Logger logger, {required String? javaV, required String? agpV}) {
  if (javaV == null || agpV == null) {
    logger.printTrace('Java version or AGP version unknown ($javaV, $agpV).');
    return false;
  }

  // Check if AGP version is too old to perform validation.
  if (isWithinVersionRange(
    agpV,
    min: '1.0',
    max: oldestDocumentedJavaAgpCompatibilityVersion,
    inclusiveMax: false,
  )) {
    logger.printTrace('AGP Version: $agpV is too old to determine Java compatibility.');
    return false;
  }

  if (isWithinVersionRange(
    agpV,
    min: maxKnownAndSupportedAgpVersion,
    max: '100.100',
    inclusiveMin: false,
  )) {
    logger.printTrace('AGP Version: $agpV is too new to determine Java compatibility.');
    return true;
  }

  // Begin known Java <-> AGP evaluation.
  for (final JavaAgpCompat data in _supportVersions.javaAgpCompat) {
    if (isWithinVersionRange(agpV, min: data.agpMin, max: data.agpMax)) {
      return isWithinVersionRange(javaV, min: data.javaMin, max: '100.100');
    }
  }

  logger.printTrace('Unknown Java-AGP compatibility $javaV, $agpV');
  return false;
}

/// Returns compatibility information concerning the minimum AGP
/// version for the specified Java version.
JavaAgpCompat? getMinimumAgpVersionForJavaVersion(Logger logger, {required String javaV}) {
  for (final JavaAgpCompat data in _supportVersions.javaAgpCompat) {
    if (isWithinVersionRange(javaV, min: data.javaMin, max: '100.100')) {
      return data;
    }
  }

  logger.printTrace('Unable to determine minimum AGP version for specified Java version.');
  return null;
}

/// Returns valid Java range for specified Gradle and AGP versions.
///
/// Assumes that gradleV and agpV are compatible versions.
VersionRange getJavaVersionFor({required String gradleV, required String agpV}) {
  // Find minimum Java version based on AGP compatibility.
  String? minJavaVersion;
  for (final JavaAgpCompat data in _supportVersions.javaAgpCompat) {
    if (isWithinVersionRange(agpV, min: data.agpMin, max: data.agpMax)) {
      minJavaVersion = data.javaMin;
    }
  }

  // Find maximum Java version based on Gradle compatibility.
  String? maxJavaVersion;
  for (final JavaGradleCompat data in _supportVersions.javaGradleCompat.reversed) {
    if (isWithinVersionRange(
      gradleV,
      min: data.gradleMin,
      max: maxKnownAndSupportedGradleVersion,
    )) {
      maxJavaVersion = data.javaMax;
    }
  }

  return VersionRange(minJavaVersion, maxJavaVersion);
}

/// Returns the Gradle version that is required by the given Android Gradle plugin version
/// by picking the largest compatible version from
/// https://developer.android.com/studio/releases/gradle-plugin#updating-gradle
String getGradleVersionFor(String agpV) {
  for (final GradleVersionForAgp data in _supportVersions.gradleVersionForAgp) {
    if (isWithinVersionRange(agpV, min: data.agpMin, max: data.agpMax)) {
      return data.minRequiredGradle;
    }
  }
  if (isWithinVersionRange(agpV, min: maxKnownAgpVersion, max: '100.100')) {
    return maxKnownAndSupportedGradleVersion;
  }
  throwToolExit('Unsupported Android Plugin version: $agpV.');
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
  var changed = false;

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
  final settings = SettingsFile();
  final AndroidSdk? androidSdk = globals.androidSdk;
  if (androidSdk != null) {
    settings.values['sdk.dir'] = globals.fsUtils.escapePath(androidSdk.directory.path);
  }
  settings.writeContents(properties);
}

void exitWithNoSdkMessage() {
  globals.analytics.send(
    Event.flutterBuildInfo(
      label: 'unsupported-project',
      buildType: 'gradle',
      error: 'android-sdk-not-found',
    ),
  );
  throwToolExit(
    '${globals.logger.terminal.warningMark} No Android SDK found. '
    'Try setting the ANDROID_HOME environment variable.',
  );
}

// Returns gradlew file name based on the platform.
String getGradlewFileName(Platform platform) {
  if (platform.isWindows) {
    return 'gradlew.bat';
  } else {
    return 'gradlew';
  }
}
