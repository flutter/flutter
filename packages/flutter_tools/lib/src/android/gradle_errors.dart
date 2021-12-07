// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../globals_null_migrated.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'android_studio.dart';

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
  minSdkVersion,
  transformInputIssue,
  lockFileDepMissing,
];

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
  }) async {
    globals.printStatus('${globals.logger.terminal.warningMark} Gradle does not have execution permission.', emphasis: true);
    globals.printStatus(
      'You should change the ownership of the project directory to your user, '
      'or move the project to a directory with execute permissions.',
      indent: 4
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'permission-denied',
);

/// Gradle crashes for several known reasons when downloading that are not
/// actionable by Flutter.
///
/// The Gradle cache directory must be deleted, otherwise it may attempt to
/// re-use the bad zip file.
///
/// See also:
///  * https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home
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
  }) async {
    globals.printError(
      '${globals.logger.terminal.warningMark} Gradle threw an error while downloading artifacts from the network. '
      'Retrying to download...'
    );
    try {
      final String? homeDir = globals.platform.environment['HOME'];
      if (homeDir != null) {
        final Directory directory = globals.fs.directory(globals.fs.path.join(homeDir, '.gradle'));
        ErrorHandlingFileSystem.deleteIfExists(directory, recursive: true);
      }
    } on FileSystemException catch (err) {
      globals.printTrace('Failed to delete Gradle cache: $err');
    }
    return GradleBuildStatus.retry;
  },
  eventLabel: 'network',
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
  }) async {
    globals.printStatus('${globals.logger.terminal.warningMark} The shrinker may have failed to optimize the Java bytecode.', emphasis: true);
    globals.printStatus('To disable the shrinker, pass the `--no-shrink` flag to this command.', indent: 4);
    globals.printStatus('To learn more, see: https://developer.android.com/studio/build/shrink-code', indent: 4);
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
  }) async {
    const String licenseNotAcceptedMatcher =
      r'You have not accepted the license agreements of the following SDK components:\s*\[(.+)\]';

    final RegExp licenseFailure = RegExp(licenseNotAcceptedMatcher, multiLine: true);
    assert(licenseFailure != null);
    final Match? licenseMatch = licenseFailure.firstMatch(line);
    globals.printStatus(
      '${globals.logger.terminal.warningMark} Unable to download needed Android SDK components, as the '
      'following licenses have not been accepted:\n'
      '${licenseMatch?.group(1)}\n\n'
      'To resolve this, please run the following command in a Terminal:\n'
      'flutter doctor --android-licenses'
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
    globals.printStatus(
      '\n${globals.logger.terminal.warningMark}  Gradle project does not define a task suitable '
      'for the requested build.'
    );
    if (productFlavors.isEmpty) {
      globals.printStatus(
        'The android/app/build.gradle file does not define '
        'any custom product flavors. '
        'You cannot use the --flavor option.'
      );
    } else {
      globals.printStatus(
        'The android/app/build.gradle file defines product '
        'flavors: ${productFlavors.join(', ')} '
        'You must specify a --flavor option to select one of them.'
      );
    }
    return GradleBuildStatus.exit;
  },
  eventLabel: 'flavor-undefined',
);


final RegExp _minSdkVersionPattern = RegExp(r'uses-sdk:minSdkVersion ([0-9]+) cannot be smaller than version ([0-9]+) declared in library \[\:(.+)\]');

/// Handler when a plugin requires a higher Android API level.
@visibleForTesting
final GradleHandledError minSdkVersion = GradleHandledError(
  test: (String line) {
    return _minSdkVersionPattern.hasMatch(line);
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle');

    final Match? minSdkVersionMatch = _minSdkVersionPattern.firstMatch(line);
    assert(minSdkVersionMatch?.groupCount == 3);

    final String bold = globals.logger.terminal.bolden(
      'Fix this issue by adding the following to the file ${gradleFile.path}:\n'
      'android {\n'
      '  defaultConfig {\n'
      '    minSdkVersion ${minSdkVersionMatch?.group(2)}\n'
      '  }\n'
      '}\n'
    );
    globals.printStatus(
      '\n'
      'The plugin ${minSdkVersionMatch?.group(3)} requires a higher Android SDK version.\n'
      '$bold\n'
      "Note that your app won't be available to users running Android SDKs below ${minSdkVersionMatch?.group(2)}.\n"
      'Alternatively, try to find a version of this plugin that supports these lower versions of the Android SDK.'
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'plugin-min-sdk',
);

/// Handler when https://issuetracker.google.com/issues/141126614 or
/// https://github.com/flutter/flutter/issues/58247 is triggered.
@visibleForTesting
final GradleHandledError transformInputIssue = GradleHandledError(
  test: (String line) {
    return line.contains('https://issuetracker.google.com/issues/158753935');
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle');
    final String bold = globals.logger.terminal.bolden(
      'Fix this issue by adding the following to the file ${gradleFile.path}:\n'
      'android {\n'
      '  lintOptions {\n'
      '    checkReleaseBuilds false\n'
      '  }\n'
      '}'
    );
    globals.printStatus(
      '\n'
      'This issue appears to be https://github.com/flutter/flutter/issues/58247.\n'
      '$bold'
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'transform-input-issue',
);

/// Handler when a dependency is missing in the lockfile.
@visibleForTesting
final GradleHandledError lockFileDepMissing = GradleHandledError(
  test: (String line) {
    return line.contains('which is not part of the dependency lock state');
  },
  handler: ({
    required String line,
    required FlutterProject project,
    required bool usesAndroidX,
  }) async {
    final File gradleFile = project.directory
        .childDirectory('android')
        .childFile('build.gradle');
    final String bold = globals.logger.terminal.bolden(
      'To regenerate the lockfiles run: `./gradlew :generateLockfiles` in ${gradleFile.path}\n'
      'To remove dependency locking, remove the `dependencyLocking` from ${gradleFile.path}\n'
    );
    globals.printStatus(
      '\n'
      'You need to update the lockfile, or disable Gradle dependency locking.\n'
      '$bold'
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'lock-dep-issue',
);
