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
import '../reporting/reporting.dart';
import 'android_studio.dart';
import 'gradle_utils.dart';
import 'multidex.dart';

typedef GradleErrorTest = bool Function(String);

/// A Gradle error handled by the tool.
class GradleHandledError {
  const GradleHandledError({
    required this.test,
    required this.handler,
    this.eventLabel,
  });

  /// The test function.
  /// Returns [true] if the current error message should be handled.
  final GradleErrorTest test;

  /// The handler function.
  final Future<GradleBuildStatus> Function({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) handler;

  /// The [BuildEvent] label is named gradle-[eventLabel].
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
/// Only the first error handler for which the [test] function returns [true]
/// is handled. As a result, sort error handlers based on how strict the [test]
/// function is to eliminate false positives.
final List<GradleHandledError> gradleErrors = <GradleHandledError>[
  licenseNotAcceptedHandler,
  networkErrorHandler,
  permissionDeniedErrorHandler,
  flavorUndefinedHandler,
  r8FailureHandler,
  minSdkVersionHandler,
  transformInputIssueHandler,
  lockFileDepMissingHandler,
  multidexErrorHandler,
  incompatibleKotlinVersionHandler,
  minCompileSdkVersionHandler,
  jvm11RequiredHandler,
  outdatedGradleHandler,
  sslExceptionHandler,
  zipExceptionHandler,
];

const String _boxTitle = 'Flutter Fix';

// Multidex error message.
@visibleForTesting
final GradleHandledError multidexErrorHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'com.android.builder.dexing.DexArchiveMergerException: Error while merging dex archives:',
    'The number of method references in a .dex file cannot exceed 64K.',
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    globals.printStatus('${globals.logger.terminal.warningMark} App requires Multidex support', emphasis: true);
    if (multidexEnabled) {
      globals.printStatus(
        'Multidex support is required for your android app to build since the number of methods has exceeded 64k. '
        'See https://docs.flutter.dev/deployment/android#enabling-multidex-support for more information. '
        "You may pass the --no-multidex flag to skip Flutter's multidex support to use a manual solution.\n",
        indent: 4,
      );
      if (!androidManifestHasNameVariable(project.directory)) {
        globals.printStatus(
          r'Your `android/app/src/main/AndroidManifest.xml` does not contain `android:name="${applicationName}"` '
          'under the `application` element. This may be due to creating your project with an old version of Flutter. '
          'Add the `android:name="\${applicationName}"` attribute to your AndroidManifest.xml to enable Flutter\'s multidex support:\n',
          indent: 4,
        );
        globals.printStatus(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  ...
  <application
    ...
    android:name=''',
          indent: 8,
          newline: false,
          color: TerminalColor.grey,
        );
        globals.printStatus(r'"${applicationName}"', color: TerminalColor.green, newline: true);
        globals.printStatus(r'''
    ...>
''',
          indent: 8,
          color: TerminalColor.grey,
        );

        globals.printStatus(
          'You may also roll your own multidex support by following the guide at: https://developer.android.com/studio/build/multidex\n',
          indent: 4,
        );
        return GradleBuildStatus.exit;
      }
      if (!multiDexApplicationExists(project.directory)) {
        globals.printStatus(
          'Flutter tool can add multidex support. The following file will be added by flutter:\n',
          indent: 4,
        );
        globals.printStatus(
          'android/app/src/main/java/io/flutter/app/FlutterMultiDexApplication.java\n',
          indent: 8,
        );
        String selection = 'n';
        // Default to 'no' if no interactive terminal.
        try {
          selection = await globals.terminal.promptForCharInput(
            <String>['y', 'n'],
            logger: globals.logger,
            prompt: 'Do you want to continue with adding multidex support for Android?',
            defaultChoiceIndex: 0,
          );
        } on StateError catch(e) {
          globals.printError(
            e.message,
            indent: 0,
          );
        }
        if (selection == 'y') {
          ensureMultiDexApplicationExists(project.directory);
          globals.printStatus(
            'Multidex enabled. Retrying build.\n',
            indent: 0,
          );
          return GradleBuildStatus.retry;
        }
      }
    } else {
      globals.printBox(
        'Flutter multidex handling is disabled. If you wish to let the tool configure multidex, use the --multidex flag.',
        title: _boxTitle,
      );
    }
    return GradleBuildStatus.exit;
  },
  eventLabel: 'multidex-error',
);

// Permission defined error message.
@visibleForTesting
final GradleHandledError permissionDeniedErrorHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'Permission denied',
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
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
final GradleHandledError networkErrorHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'java.io.FileNotFoundException: https://downloads.gradle.org',
    'java.io.IOException: Unable to tunnel through proxy',
    'java.lang.RuntimeException: Timeout of',
    'java.util.zip.ZipException: error in opening zip file',
    'javax.net.ssl.SSLHandshakeException: Remote host closed connection during handshake',
    'java.net.SocketException: Connection reset',
    'java.io.FileNotFoundException',
    "> Could not get resource 'http",
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    globals.printError(
      '${globals.logger.terminal.warningMark} '
      'Gradle threw an error while downloading artifacts from the network.'
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
final GradleHandledError zipExceptionHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'java.util.zip.ZipException: error in opening zip file',
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    globals.printError(
      '${globals.logger.terminal.warningMark} '
      'Your .gradle directory under the home directory might be corrupted.'
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
      } on StateError catch(e) {
        globals.printError(
          e.message,
          indent: 0,
        );
      }
    }
    if (shouldDeleteUserGradle) {
      final String? homeDir = globals.platform.environment['HOME'];
      if (homeDir == null) {
        globals.logger.printStatus("Could not delete .gradle directory because there isn't a HOME env variable");
        return GradleBuildStatus.retry;
      }
      final Directory userGradle = globals.fs.directory(globals.fs.path.join(homeDir, '.gradle'));
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

// R8 failure.
@visibleForTesting
final GradleHandledError r8FailureHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'com.android.tools.r8',
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    globals.printBox(
      '${globals.logger.terminal.warningMark} The shrinker may have failed to optimize the Java bytecode.\n'
      'To disable the shrinker, pass the `--no-shrink` flag to this command.\n'
      'To learn more, see: https://developer.android.com/studio/build/shrink-code',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'r8',
);

/// Handle Gradle error thrown when Gradle needs to download additional
/// Android SDK components (e.g. Platform Tools), and the license
/// for that component has not been accepted.
@visibleForTesting
final GradleHandledError licenseNotAcceptedHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'You have not accepted the license agreements of the following SDK components',
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    const String licenseNotAcceptedMatcher =
      r'You have not accepted the license agreements of the following SDK components:\s*\[(.+)\]';

    final RegExp licenseFailure = RegExp(licenseNotAcceptedMatcher, multiLine: true);
    assert(licenseFailure != null);
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

final RegExp _undefinedTaskPattern = RegExp(r'Task .+ not found in root project.');

final RegExp _assembleTaskPattern = RegExp(r'assemble(\S+)');

/// Handler when a flavor is undefined.
@visibleForTesting
final GradleHandledError flavorUndefinedHandler = GradleHandledError(
  test: (String line) {
    return _undefinedTaskPattern.hasMatch(line);
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    final RunResult tasksRunResult = await globals.processUtils.run(
      <String>[
        globals.gradleUtils!.getExecutable(project),
        'app:tasks' ,
        '--all',
        '--console=auto',
      ],
      throwOnError: true,
      workingDirectory: project.android.hostAppGradleRoot.path,
      environment: <String, String>{
        if (javaPath != null)
          'JAVA_HOME': javaPath!,
      },
    );
    // Extract build types and product flavors.
    final Set<String> variants = <String>{};
    for (final String task in tasksRunResult.stdout.split('\n')) {
      final Match? match = _assembleTaskPattern.matchAsPrefix(task);
      if (match != null) {
        final String variant = match.group(1)!.toLowerCase();
        if (!variant.endsWith('test')) {
          variants.add(variant);
        }
      }
    }
    final Set<String> productFlavors = <String>{};
    for (final String variant1 in variants) {
      for (final String variant2 in variants) {
        if (variant2.startsWith(variant1) && variant2 != variant1) {
          final String buildType = variant2.substring(variant1.length);
          if (variants.contains(buildType)) {
            productFlavors.add(variant1);
          }
        }
      }
    }
    final String errorMessage = '${globals.logger.terminal.warningMark}  Gradle project does not define a task suitable for the requested build.';
    final File buildGradle = project.directory.childDirectory('android').childDirectory('app').childFile('build.gradle');
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


final RegExp _minSdkVersionPattern = RegExp(r'uses-sdk:minSdkVersion ([0-9]+) cannot be smaller than version ([0-9]+) declared in library \[\:(.+)\]');

/// Handler when a plugin requires a higher Android API level.
@visibleForTesting
final GradleHandledError minSdkVersionHandler = GradleHandledError(
  test: (String line) {
    return _minSdkVersionPattern.hasMatch(line);
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle');

    final Match? minSdkVersionMatch = _minSdkVersionPattern.firstMatch(line);
    assert(minSdkVersionMatch?.groupCount == 3);

    final String textInBold = globals.logger.terminal.bolden(
      'Fix this issue by adding the following to the file ${gradleFile.path}:\n'
      'android {\n'
      '  defaultConfig {\n'
      '    minSdkVersion ${minSdkVersionMatch?.group(2)}\n'
      '  }\n'
      '}\n'
    );
    globals.printBox(
      'The plugin ${minSdkVersionMatch?.group(3)} requires a higher Android SDK version.\n'
      '$textInBold\n'
      "Note that your app won't be available to users running Android SDKs below ${minSdkVersionMatch?.group(2)}.\n"
      'Alternatively, try to find a version of this plugin that supports these lower versions of the Android SDK.\n'
      'For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'plugin-min-sdk',
);

/// Handler when https://issuetracker.google.com/issues/141126614 or
/// https://github.com/flutter/flutter/issues/58247 is triggered.
@visibleForTesting
final GradleHandledError transformInputIssueHandler = GradleHandledError(
  test: (String line) {
    return line.contains('https://issuetracker.google.com/issues/158753935');
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle');
    final String textInBold = globals.logger.terminal.bolden(
      'Fix this issue by adding the following to the file ${gradleFile.path}:\n'
      'android {\n'
      '  lintOptions {\n'
      '    checkReleaseBuilds false\n'
      '  }\n'
      '}'
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
final GradleHandledError lockFileDepMissingHandler = GradleHandledError(
  test: (String line) {
    return line.contains('which is not part of the dependency lock state');
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childFile('build.gradle');
    final String textInBold = globals.logger.terminal.bolden(
      'To regenerate the lockfiles run: `./gradlew :generateLockfiles` in ${gradleFile.path}\n'
      'To remove dependency locking, remove the `dependencyLocking` from ${gradleFile.path}'
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

@visibleForTesting
final GradleHandledError incompatibleKotlinVersionHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'was compiled with an incompatible version of Kotlin',
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childFile('build.gradle');
    globals.printBox(
      '${globals.logger.terminal.warningMark} Your project requires a newer version of the Kotlin Gradle plugin.\n'
      'Find the latest version on https://kotlinlang.org/docs/releases.html#release-details, then update ${gradleFile.path}:\n'
      "ext.kotlin_version = '<latest-version>'",
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'incompatible-kotlin-version',
);

final RegExp _outdatedGradlePattern = RegExp(r'The current Gradle version (.+) is not compatible with the Kotlin Gradle plugin');

@visibleForTesting
final GradleHandledError outdatedGradleHandler = GradleHandledError(
  test: _outdatedGradlePattern.hasMatch,
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childFile('build.gradle');
    final File gradlePropertiesFile = project.directory
        .childDirectory('android')
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties');
    globals.printBox(
      '${globals.logger.terminal.warningMark} Your project needs to upgrade Gradle and the Android Gradle plugin.\n\n'
      'To fix this issue, replace the following content:\n'
      '${gradleFile.path}:\n'
      '    ${globals.terminal.color("- classpath 'com.android.tools.build:gradle:<current-version>'", TerminalColor.red)}\n'
      '    ${globals.terminal.color("+ classpath 'com.android.tools.build:gradle:$templateAndroidGradlePluginVersion'", TerminalColor.green)}\n'
      '${gradlePropertiesFile.path}:\n'
      '    ${globals.terminal.color('- https://services.gradle.org/distributions/gradle-<current-version>-all.zip', TerminalColor.red)}\n'
      '    ${globals.terminal.color('+ https://services.gradle.org/distributions/gradle-$templateDefaultGradleVersion-all.zip', TerminalColor.green)}',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'outdated-gradle-version',
);

final RegExp _minCompileSdkVersionPattern = RegExp(r'The minCompileSdk \(([0-9]+)\) specified in a');

@visibleForTesting
final GradleHandledError minCompileSdkVersionHandler = GradleHandledError(
  test: _minCompileSdkVersionPattern.hasMatch,
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    final Match? minCompileSdkVersionMatch = _minCompileSdkVersionPattern.firstMatch(line);
    assert(minCompileSdkVersionMatch?.groupCount == 1);

    final File gradleFile = project.directory
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle');
    globals.printBox(
      '${globals.logger.terminal.warningMark} Your project requires a higher compileSdkVersion.\n'
      'Fix this issue by bumping the compileSdkVersion in ${gradleFile.path}:\n'
      'android {\n'
      '  compileSdkVersion ${minCompileSdkVersionMatch?.group(1)}\n'
      '}',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'min-compile-sdk-version',
);

@visibleForTesting
final GradleHandledError jvm11RequiredHandler = GradleHandledError(
  test: (String line) {
    return line.contains('Android Gradle plugin requires Java 11 to run');
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    globals.printBox(
      '${globals.logger.terminal.warningMark} You need Java 11 or higher to build your app with this version of Gradle.\n\n'
      'To get Java 11, update to the latest version of Android Studio on https://developer.android.com/studio/install.\n\n'
      'To check the Java version used by Flutter, run `flutter doctor -v`.',
      title: _boxTitle,
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'java11-required',
);

/// Handles SSL exceptions: https://github.com/flutter/flutter/issues/104628
@visibleForTesting
final GradleHandledError sslExceptionHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'javax.net.ssl.SSLException: Tag mismatch!',
    'javax.crypto.AEADBadTagException: Tag mismatch!',
  ]),
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
    required bool multidexEnabled,
  }) async {
    globals.printError(
      '${globals.logger.terminal.warningMark} '
      'Gradle threw an error while downloading artifacts from the network.'
    );
    return GradleBuildStatus.retry;
  },
  eventLabel: 'ssl-exception-tag-mismatch',
);
