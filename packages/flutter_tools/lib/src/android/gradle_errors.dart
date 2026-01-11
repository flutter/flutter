// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'gradle_utils.dart' as utils;

typedef GradleErrorTest = bool Function(String);

/// A Gradle error handled by the tool.
class GradleHandledError {
  const GradleHandledError({required this.test, required this.handler, this.eventLabel});

  /// The test function.
  ///
  /// Returns `true` if the current error message should be handled.
  final GradleErrorTest test;

  /// The handler function.
  final Future<GradleBuildStatus> Function({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
  })
  handler;

  /// The build event label is named gradle-[eventLabel].
  /// If not empty, the build event is logged along with
  /// additional metadata such as the attempt number.
  final String? eventLabel;
}

/// The status of the Gradle build.
enum GradleBuildStatus {
  /// The tool cannot recover from the failure and should exit.
  exit,

  /// The tool can retry the exact same build.
  retry,
}

/// Returns a simple test function that evaluates to `true` if at least one of
/// `errorMessages` is contained in the error message.
GradleErrorTest _lineMatcher(List<String> errorMessages) {
  return (String line) {
    return errorMessages.any((String errorMessage) => line.contains(errorMessage));
  };
}

/// The list of Gradle errors that the tool can handle.
///
/// The handlers are executed in the order in which they appear in the list.
///
/// Only the first error handler for which the
/// [GradleHandledError.test] function returns `true` is handled.
/// As a result, sort error handlers based on how strict
/// the [GradleHandledError.test] function is to eliminate false positives.
final gradleErrors = <GradleHandledError>[
  licenseNotAcceptedHandler,
  networkErrorHandler,
  permissionDeniedErrorHandler,
  flavorUndefinedHandler,
  r8DexingBugInAgp73Handler,
  minSdkVersionHandler,
  transformInputIssueHandler,
  lockFileDepMissingHandler,
  minCompileSdkVersionHandler,
  incompatibleJavaAndAgpVersionsHandler,
  outdatedGradleHandler,
  sslExceptionHandler,
  zipExceptionHandler,
  incompatibleJavaAndGradleVersionsHandler,
  remoteTerminatedHandshakeHandler,
  couldNotOpenCacheDirectoryHandler,
  incompatibleCompileSdk35AndAgpVersionHandler,
  usageOfV1EmbeddingReferencesHandler,
  jlinkErrorWithJava21AndSourceCompatibility,
  missingNdkSourcePropertiesFile,
  applyingKotlinAndroidPluginErrorHandler,
  useNewAgpDslErrorHandler,
  incompatibleKotlinVersionHandler, // This handler should always be last, as its key log output is sometimes in error messages with other root causes.
];

const _boxTitle = 'Flutter Fix';

// Permission defined error message.
@visibleForTesting
final permissionDeniedErrorHandler = GradleHandledError(
  test: _lineMatcher(const <String>['Permission denied']),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printBox(
          '${globals.logger.terminal.warningMark} Gradle does not have execution permission.\n'
          'You should change the ownership of the project directory to your user, '
          'or move the project to a directory with execute permissions.',
          title: _boxTitle,
        );
        return GradleBuildStatus.exit;
      },
  eventLabel: 'permission-denied',
);

/// Gradle crashes for several known reasons when downloading that are not
/// actionable by Flutter.
@visibleForTesting
final networkErrorHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    "> Could not get resource 'http",
    'java.io.FileNotFoundException',
    'java.io.FileNotFoundException: https://downloads.gradle.org',
    'java.io.IOException: Server returned HTTP response code: 502',
    'java.io.IOException: Unable to tunnel through proxy',
    'java.lang.RuntimeException: Timeout of',
    'java.net.ConnectException: Connection timed out',
    'java.net.SocketException: Connection reset',
    'java.util.zip.ZipException: error in opening zip file',
    'javax.net.ssl.SSLHandshakeException: Remote host closed connection during handshake',
  ]),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printError(
          '${globals.logger.terminal.warningMark} '
          'Gradle threw an error while downloading artifacts from the network.',
        );
        return GradleBuildStatus.retry;
      },
  eventLabel: 'network',
);

/// Handles corrupted jar or other types of zip files.
///
/// If a terminal is attached, this handler prompts the user if they would like to
/// delete the $HOME/.gradle directory prior to retrying the build.
///
/// If this handler runs on a bot (e.g. a CI bot), the $HOME/.gradle is automatically deleted.
///
/// See also:
///  * https://github.com/flutter/flutter/issues/51195
///  * https://github.com/flutter/flutter/issues/89959
///  * https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home
@visibleForTesting
final zipExceptionHandler = GradleHandledError(
  test: _lineMatcher(const <String>['java.util.zip.ZipException: error in opening zip file']),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printError(
          '${globals.logger.terminal.warningMark} '
          'Your .gradle directory under the home directory might be corrupted.',
        );
        bool shouldDeleteUserGradle = await globals.botDetector.isRunningOnBot;
        if (!shouldDeleteUserGradle && globals.terminal.stdinHasTerminal) {
          try {
            final String selection = await globals.terminal.promptForCharInput(
              <String>['y', 'n'],
              logger: globals.logger,
              prompt: 'Do you want to delete the .gradle directory under the home directory?',
              defaultChoiceIndex: 0,
            );
            shouldDeleteUserGradle = selection == 'y';
          } on StateError catch (e) {
            globals.printError(e.message, indent: 0);
          }
        }
        if (shouldDeleteUserGradle) {
          final String? homeDir = globals.platform.environment['HOME'];
          if (homeDir == null) {
            globals.logger.printStatus(
              "Could not delete .gradle directory because there isn't a HOME env variable",
            );
            return GradleBuildStatus.retry;
          }
          final Directory userGradle = globals.fs.directory(
            globals.fs.path.join(homeDir, '.gradle'),
          );
          globals.logger.printStatus('Deleting ${userGradle.path}');
          try {
            ErrorHandlingFileSystem.deleteIfExists(userGradle, recursive: true);
          } on FileSystemException catch (err) {
            globals.printTrace('Failed to delete Gradle cache: $err');
          }
        }
        return GradleBuildStatus.retry;
      },
  eventLabel: 'zip-exception',
);

/// Handle Gradle error thrown when Gradle needs to download additional
/// Android SDK components (e.g. Platform Tools), and the license
/// for that component has not been accepted.
@visibleForTesting
final licenseNotAcceptedHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'You have not accepted the license agreements of the following SDK components',
  ]),
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    const licenseNotAcceptedMatcher =
        r'You have not accepted the license agreements of the following SDK components:\s*\[(.+)\]';

    final licenseFailure = RegExp(licenseNotAcceptedMatcher, multiLine: true);
    final Match? licenseMatch = licenseFailure.firstMatch(line);
    globals.printBox(
      '${globals.logger.terminal.warningMark} Unable to download needed Android SDK components, as the '
      'following licenses have not been accepted: '
      '${licenseMatch?.group(1)}\n\n'
      'To resolve this, please run the following command in a Terminal:\n'
      'flutter doctor --android-licenses',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'license-not-accepted',
);

final _undefinedTaskPattern = RegExp(r'Task .+ not found in root project.');

final _assembleTaskPattern = RegExp(r'assemble(\S+)');

/// Handler when a flavor is undefined.
@visibleForTesting
final flavorUndefinedHandler = GradleHandledError(
  test: (String line) {
    return _undefinedTaskPattern.hasMatch(line);
  },
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    final RunResult tasksRunResult = await globals.processUtils.run(
      <String>[globals.gradleUtils!.getExecutable(project), 'app:tasks', '--all', '--console=auto'],
      throwOnError: true,
      workingDirectory: project.android.hostAppGradleRoot.path,
      environment: globals.java?.environment,
    );
    // Extract build types and product flavors.
    final variants = <String>{};
    for (final String task in tasksRunResult.stdout.split('\n')) {
      final Match? match = _assembleTaskPattern.matchAsPrefix(task);
      if (match != null) {
        final String variant = match.group(1)!.toLowerCase();
        if (!variant.endsWith('test')) {
          variants.add(variant);
        }
      }
    }
    final productFlavors = <String>{};
    for (final variant1 in variants) {
      for (final variant2 in variants) {
        if (variant2.startsWith(variant1) && variant2 != variant1) {
          final String buildType = variant2.substring(variant1.length);
          if (variants.contains(buildType)) {
            productFlavors.add(variant1);
          }
        }
      }
    }
    final errorMessage =
        '${globals.logger.terminal.warningMark}  Gradle project does not define a task suitable for the requested build.';
    final File buildGradle = project.android.appGradleFile;
    if (productFlavors.isEmpty) {
      globals.printBox(
        '$errorMessage\n\n'
        'The ${buildGradle.absolute.path} file does not define '
        'any custom product flavors. '
        'You cannot use the --flavor option.',
        title: _boxTitle,
      );
    } else {
      globals.printBox(
        '$errorMessage\n\n'
        'The ${buildGradle.absolute.path} file defines product '
        'flavors: ${productFlavors.join(', ')}. '
        'You must specify a --flavor option to select one of them.',
        title: _boxTitle,
      );
    }
    return GradleBuildStatus.exit;
  },
  eventLabel: 'flavor-undefined',
);

final _minSdkVersionPattern = RegExp(
  r'uses-sdk:minSdkVersion ([0-9]+) cannot be smaller than version ([0-9]+) declared in library \[:(.+)\]',
);

/// Handler when a plugin requires a higher Android API level.
@visibleForTesting
final minSdkVersionHandler = GradleHandledError(
  test: (String line) {
    return _minSdkVersionPattern.hasMatch(line);
  },
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    final File gradleFile = project.android.appGradleFile;
    final Match? minSdkVersionMatch = _minSdkVersionPattern.firstMatch(line);
    assert(minSdkVersionMatch?.groupCount == 3);

    final String textInBold = globals.logger.terminal.bolden(
      'Fix this issue by adding the following to the file ${gradleFile.path}:\n'
      'android {\n'
      '  defaultConfig {\n'
      '    minSdkVersion ${minSdkVersionMatch?.group(2)}\n'
      '  }\n'
      '}\n',
    );
    globals.printBox(
      'The plugin ${minSdkVersionMatch?.group(3)} requires a higher Android SDK version.\n'
      '$textInBold\n'
      'Following this change, your app will not be available to users running Android SDKs below ${minSdkVersionMatch?.group(2)}.\n'
      'Consider searching for a version of this plugin that supports these lower versions of the Android SDK instead.\n'
      'For more information, see: https://flutter.dev/to/review-gradle-config',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'plugin-min-sdk',
);

/// Handler when https://issuetracker.google.com/issues/141126614 or
/// https://github.com/flutter/flutter/issues/58247 is triggered.
@visibleForTesting
final transformInputIssueHandler = GradleHandledError(
  test: (String line) {
    return line.contains('https://issuetracker.google.com/issues/158753935');
  },
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        final File gradleFile = project.android.appGradleFile;
        final String textInBold = globals.logger.terminal.bolden(
          'Fix this issue by adding the following to the file ${gradleFile.path}:\n'
          'android {\n'
          '  lintOptions {\n'
          '    checkReleaseBuilds false\n'
          '  }\n'
          '}',
        );
        globals.printBox(
          'This issue appears to be https://github.com/flutter/flutter/issues/58247.\n'
          '$textInBold',
          title: _boxTitle,
        );
        return GradleBuildStatus.exit;
      },
  eventLabel: 'transform-input-issue',
);

/// Handler when a dependency is missing in the lockfile.
@visibleForTesting
final lockFileDepMissingHandler = GradleHandledError(
  test: (String line) {
    return line.contains('which is not part of the dependency lock state');
  },
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    final File gradleFile = project.android.hostAppGradleFile;
    final generatedGradleCommand = globals.platform.isWindows ? r'.\gradlew.bat' : './gradlew';
    final String textInBold = globals.logger.terminal.bolden(
      'To regenerate the lockfiles run: `$generatedGradleCommand :generateLockfiles` in ${gradleFile.path}\n'
      'To remove dependency locking, remove the `dependencyLocking` from ${gradleFile.path}',
    );
    globals.printBox(
      'You need to update the lockfile, or disable Gradle dependency locking.\n'
      '$textInBold',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'lock-dep-issue',
);

// This handler is made visible in other files so that we can uniquely set it
// to be the lowest priority error.
final incompatibleKotlinVersionHandler = GradleHandledError(
  test: _lineMatcher(const <String>['was compiled with an incompatible version of Kotlin']),
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    final File gradleFile = project.android.hostAppGradleFile;
    final File settingsFile = project.directory
        .childDirectory('android')
        .childFile('settings.gradle');
    globals.printBox(
      '${globals.logger.terminal.warningMark} Your project requires a newer version of the Kotlin Gradle plugin.\n'
      'Find the latest version on https://kotlinlang.org/docs/releases.html#release-details, then update the \n'
      'version number of the plugin with id "org.jetbrains.kotlin.android" in the plugins block of \n'
      '${settingsFile.path}.\n\n'
      'Alternatively (if your project was created before Flutter 3.19), update \n'
      '${gradleFile.path}\n'
      "ext.kotlin_version = '<latest-version>'",
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'incompatible-kotlin-version',
);

final _outdatedGradlePattern = RegExp(
  r'The current Gradle version (.+) is not compatible with the Kotlin Gradle plugin',
);

@visibleForTesting
final outdatedGradleHandler = GradleHandledError(
  test: _outdatedGradlePattern.hasMatch,
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    final File gradleFile = project.android.hostAppGradleFile;
    final File gradlePropertiesFile = project.android.gradleWrapperPropertiesFile;
    globals.printBox(
      '${globals.logger.terminal.warningMark} Your project needs to upgrade Gradle and the Android Gradle plugin.\n\n'
      'To fix this issue, replace the following content:\n'
      '${gradleFile.path}:\n'
      '    ${globals.terminal.color("- classpath 'com.android.tools.build:gradle:<current-version>'", TerminalColor.red)}\n'
      '    ${globals.terminal.color("+ classpath 'com.android.tools.build:gradle:${utils.templateAndroidGradlePluginVersion}'", TerminalColor.green)}\n'
      '${gradlePropertiesFile.path}:\n'
      '    ${globals.terminal.color('- https://services.gradle.org/distributions/gradle-<current-version>-all.zip', TerminalColor.red)}\n'
      '    ${globals.terminal.color('+ https://services.gradle.org/distributions/gradle-${utils.templateDefaultGradleVersion}-all.zip', TerminalColor.green)}',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'outdated-gradle-version',
);

final _minCompileSdkVersionPattern = RegExp(r'The minCompileSdk \(([0-9]+)\) specified in a');

@visibleForTesting
final minCompileSdkVersionHandler = GradleHandledError(
  test: _minCompileSdkVersionPattern.hasMatch,
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        final Match? minCompileSdkVersionMatch = _minCompileSdkVersionPattern.firstMatch(line);
        assert(minCompileSdkVersionMatch?.groupCount == 1);

        final File gradleFile = project.android.appGradleFile;
        globals.printBox(
          '${globals.logger.terminal.warningMark} Your project requires a higher compileSdk version.\n'
          'Fix this issue by bumping the compileSdk version in ${gradleFile.path}:\n'
          'android {\n'
          '  compileSdk ${minCompileSdkVersionMatch?.group(1)}\n'
          '}',
          title: _boxTitle,
        );
        return GradleBuildStatus.exit;
      },
  eventLabel: 'min-compile-sdk-version',
);

final _agpJavaError = RegExp(r'Android Gradle plugin requires Java (\d+\.?\d*) to run');

// If an incompatible Java and Android Gradle Plugin error is caught,
// Android Gradle Plugin throws the required Java version to fix the error.
// Android Gradle Plugin handles the error here: http://shortn/_SgUWyRdywL.

// If we ever need to reference or check the thrown requirements,
// we can find the Java and Android Gradle Plugin compatibility here:
// 'https://developer.android.com/build/releases/past-releases'
@visibleForTesting
final incompatibleJavaAndAgpVersionsHandler = GradleHandledError(
  test: (String line) {
    return _agpJavaError.hasMatch(line);
  },
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    final String helpfulGradleError = line.trim().substring(2);

    globals.printBox(
      '${globals.logger.terminal.warningMark} $helpfulGradleError\n\n'
      'To fix this issue, try updating to the latest Android SDK and Android Studio on: ${AndroidProject.installAndroidStudioUrl}\n'
      'If that does not work, you can set the Java version used by Flutter by \n'
      'running `flutter config --jdk-dir=“</path/to/jdk>“`\n\n'
      'To check the Java version used by Flutter, run `flutter doctor --verbose`',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'incompatible-java-agp-version',
);

/// Handles SSL exceptions: https://github.com/flutter/flutter/issues/104628
@visibleForTesting
final sslExceptionHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'javax.net.ssl.SSLException: Tag mismatch!',
    'javax.crypto.AEADBadTagException: Tag mismatch!',
  ]),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printError(
          '${globals.logger.terminal.warningMark} '
          'Gradle threw an error while downloading artifacts from the network.',
        );
        return GradleBuildStatus.retry;
      },
  eventLabel: 'ssl-exception-tag-mismatch',
);

/// If an incompatible Java and Gradle versions error is caught, we expect an
/// error specifying that the Java major class file version, one of
/// https://javaalmanac.io/bytecode/versions/, is unsupported by Gradle.
final _unsupportedClassFileMajorVersionPattern = RegExp(
  r'Unsupported class file major version\s+\d+',
);

@visibleForTesting
final incompatibleJavaAndGradleVersionsHandler = GradleHandledError(
  test: (String line) {
    return _unsupportedClassFileMajorVersionPattern.hasMatch(line);
  },
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        final File gradlePropertiesFile = project.android.gradleWrapperPropertiesFile;
        // TODO(reidbaker): Replace URL with constant defined in
        // https://github.com/flutter/flutter/pull/123916.
        globals.printBox(
          "${globals.logger.terminal.warningMark} Your project's Gradle version "
          'is incompatible with the Java version that Flutter is using for Gradle.\n\n'
          'To fix this issue, first, check the Java version used by Flutter by '
          'running `flutter doctor --verbose`.\n\n'
          'Then, update the Gradle version specified in ${gradlePropertiesFile.path} '
          'to be compatible with that Java version. '
          'See the link below for more information on compatible Java/Gradle versions:\n'
          'https://docs.gradle.org/current/userguide/compatibility.html#java\n\n',
          title: _boxTitle,
        );
        return GradleBuildStatus.exit;
      },
  eventLabel: 'incompatible-java-gradle-version',
);

@visibleForTesting
final remoteTerminatedHandshakeHandler = GradleHandledError(
  test: (String line) => line.contains('Remote host terminated the handshake'),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printError(
          '${globals.logger.terminal.warningMark} '
          'Gradle threw an error while downloading artifacts from the network.',
        );

        return GradleBuildStatus.retry;
      },
  eventLabel: 'remote-terminated-handshake',
);

@visibleForTesting
final couldNotOpenCacheDirectoryHandler = GradleHandledError(
  test: (String line) => line.contains('> Could not open cache directory '),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printError(
          '${globals.logger.terminal.warningMark} '
          'Gradle threw an error while resolving dependencies.',
        );

        return GradleBuildStatus.retry;
      },
  eventLabel: 'could-not-open-cache-directory',
);

String _getAgpLocation(FlutterProject project) {
  return '''
 The version of AGP that your project uses is likely defined in:
${project.android.settingsGradleFile.path},
in the 'plugins' closure (by the number following "com.android.application").
 Alternatively, if your project was created with an older version of the templates, it is likely
in the buildscript.dependencies closure of the top-level build.gradle:
${project.android.hostAppGradleFile.path},
as the number following "com.android.tools.build:gradle:".''';
}

@visibleForTesting
final incompatibleCompileSdk35AndAgpVersionHandler = GradleHandledError(
  test: (String line) =>
      line.contains('RES_TABLE_TYPE_TYPE entry offsets overlap actual entry data'),
  handler: ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
    globals.printBox(
      '${globals.logger.terminal.warningMark} Using compileSdk 35 requires Android Gradle Plugin (AGP) 8.1.0 or higher.'
      ' \n Please upgrade to a newer AGP version.${_getAgpLocation(project)}\n\n Finally, if you have a'
      ' strong reason to avoid upgrading AGP, you can temporarily lower the compileSdk version in the following file:\n${project.android.appGradleFile.path}',
      title: _boxTitle,
    );

    return GradleBuildStatus.exit;
  },
  eventLabel: 'incompatible-compile-sdk-and-agp',
);

@visibleForTesting
final r8DexingBugInAgp73Handler = GradleHandledError(
  test: (String line) =>
      line.contains('com.android.tools.r8.internal') &&
      line.contains(': Unused argument with users'),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printBox('''
${globals.logger.terminal.warningMark} Version 7.3 of the Android Gradle Plugin (AGP) uses a version of R8 that contains a bug which causes this error (see more info at https://issuetracker.google.com/issues/242308990).
To fix this error, update to a newer version of AGP (at least 7.4.0).

${_getAgpLocation(project)}''', title: _boxTitle);

        return GradleBuildStatus.exit;
      },
  eventLabel: 'r8-dexing-bug-in-AGP-7.3',
);

// Handler for when an outdated plugin is still using v1 embedding references that
// were possibly removed in more recent plugin versions.
@visibleForTesting
final usageOfV1EmbeddingReferencesHandler = GradleHandledError(
  test: (String line) =>
      line.contains('io.flutter.plugin.common.PluginRegistry.Registrar registrar'),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printBox(
          '''
${globals.logger.terminal.warningMark} Consult the error logs above to identify any broken plugins, specifically those containing "error: cannot find symbol..."
This issue is likely caused by v1 embedding removal and the plugin's continued usage of removed references to the v1 embedding.
To fix this error, please upgrade your current package's dependencies to latest versions by running `flutter pub upgrade`.
If that does not work, please file an issue for the problematic plugin(s) here: https://github.com/flutter/flutter/issues''',
          title: _boxTitle,
        );

        return GradleBuildStatus.exit;
      },
  eventLabel: 'usage-of-v1-embedding-references',
);

@visibleForTesting
final jlinkErrorWithJava21AndSourceCompatibility = GradleHandledError(
  test: (String line) => line.contains('> Error while executing process') && line.contains('jlink'),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        globals.printBox('''
${globals.logger.terminal.warningMark} This is likely due to a known bug in Android Gradle Plugin (AGP) versions less than 8.2.1, when
  1. setting a value for SourceCompatibility and
  2. using Java 21 or above.
To fix this error, please upgrade your AGP version to at least 8.2.1.${_getAgpLocation(project)}

For more information, see:
https://issuetracker.google.com/issues/294137077
https://github.com/flutter/flutter/issues/156304''', title: _boxTitle);

        return GradleBuildStatus.exit;
      },
  eventLabel: 'java21-and-source-compatibility',
);

final _missingNdkSourcePropertiesRegexp = RegExp(
  r'NDK at ((?:/|[a-zA-Z]:\\).+?) did not have a source\.properties file',
  multiLine: true,
);

@visibleForTesting
final missingNdkSourcePropertiesFile = GradleHandledError(
  test: (String line) => _missingNdkSourcePropertiesRegexp.hasMatch(line),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        final String path = _missingNdkSourcePropertiesRegexp.firstMatch(line)!.group(1)!;
        globals.printBox('''
    ${globals.logger.terminal.warningMark} This is likely due to a malformed download of the NDK.
    This can be fixed by deleting the local NDK copy at: $path
    and allowing the Android Gradle Plugin to automatically re-download it.
    ''', title: _boxTitle);
        return GradleBuildStatus.exit;
      },
  eventLabel: 'ndk-missing-source-properties-file',
);

/// Handler when applying the kotlin-android plugin results in a build failure. This failure occurs when
/// using AGP 9+ because built-in Kotlin has become the default behavior.
@visibleForTesting
final applyingKotlinAndroidPluginErrorHandler = GradleHandledError(
  test: (String line) {
    return line.contains(
      "The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0",
    );
  },
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        final File appGradleFile = project.android.appGradleFile;
        globals.printBox(
          '''
${globals.logger.terminal.warningMark} Starting AGP 9+, the default has become built-in Kotlin. This results in a build failure when applying the kotlin-android plugin at ${appGradleFile.path}.
\nTo resolve this, migrate to built-in Kotlin. For instructions on how to migrate, see: https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9''',
          title: _boxTitle,
        );

        return GradleBuildStatus.exit;
      },
  eventLabel: 'applying-kotlin-android-plugin-error',
);

/// Handler when using the new AGP DSL interfaces. Starting AGP 9+, only the new
/// DSL interfaces are used. This results in a failure because we still depend
/// on old DSL types.
@visibleForTesting
final useNewAgpDslErrorHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    "> Failed to apply plugin 'dev.flutter.flutter-gradle-plugin'",
    '> java.lang.NullPointerException (no error message)',
  ]),
  handler:
      ({required String line, required FlutterProject project, required bool usesAndroidX}) async {
        final File appGradleFile = project.android.appGradleFile;
        globals.printBox(
          '''
${globals.logger.terminal.warningMark} Starting AGP 9+, only the new DSL interface will be read. This results in a build failure when applying the Flutter Gradle plugin at ${appGradleFile.path}.
\nTo resolve this update flutter or opt out of `android.newDsl`. For instructions on how to opt out, see: https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9
\nIf you are not upgrading to AGP 9+, run `flutter analyze --suggestions` to check for incompatible dependencies.''',
          title: _boxTitle,
        );

        return GradleBuildStatus.exit;
      },
  eventLabel: 'use-new-agp-dsl-error',
);
