// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/process.dart';
import '../base/terminal.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'gradle_utils.dart';

typedef GradleErrorTest = bool Function(String);

/// A Gradle error handled by the tool.
class GradleHandledError {
  const GradleHandledError({
    this.test,
    this.handler,
    this.eventLabel,
  });

  /// The test function.
  /// Returns [true] if the current error message should be handled.
  final GradleErrorTest test;

  /// The handler function.
  final Future<GradleBuildStatus> Function({
    String line,
    FlutterProject project,
    bool usesAndroidX,
    bool shouldBuildPluginAsAar,
  }) handler;

  /// The [BuildEvent] label is named gradle-[eventLabel].
  /// If not empty, the build event is logged along with
  /// additional metadata such as the attempt number.
  final String eventLabel;
}

/// The status of the Gradle build.
enum GradleBuildStatus {
  /// The tool cannot recover from the failure and should exit.
  exit,
  /// The tool can retry the exact same build.
  retry,
  /// The tool can build the plugins as AAR and retry the build.
  retryWithAarPlugins,
}

/// Returns a simple test function that evaluates to [true] if
/// [errorMessage] is contained in the error message.
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
  androidXFailureHandler,
];

// Permission defined error message.
@visibleForTesting
final GradleHandledError permissionDeniedErrorHandler = GradleHandledError(
  test: _lineMatcher(const <String>[
    'Permission denied',
  ]),
  handler: ({
    String line,
    FlutterProject project,
    bool usesAndroidX,
    bool shouldBuildPluginAsAar,
  }) async {
    globals.printStatus('$warningMark Gradle does not have execution permission.', emphasis: true);
    globals.printStatus(
      'You should change the ownership of the project directory to your user, '
      'or move the project to a directory with execute permissions.',
      indent: 4
    );
    return GradleBuildStatus.exit;
  },
  eventLabel: 'permission-denied',
);

// Gradle crashes for several known reasons when downloading that are not
// actionable by flutter.
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
    'Gateway Time-out'
  ]),
  handler: ({
    String line,
    FlutterProject project,
    bool usesAndroidX,
    bool shouldBuildPluginAsAar,
  }) async {
    globals.printError(
      '$warningMark Gradle threw an error while downloading artifacts from the network. '
      'Retrying to download...'
    );
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
    String line,
    FlutterProject project,
    bool usesAndroidX,
    bool shouldBuildPluginAsAar,
  }) async {
    globals.printStatus('$warningMark The shrinker may have failed to optimize the Java bytecode.', emphasis: true);
    globals.printStatus('To disable the shrinker, pass the `--no-shrink` flag to this command.', indent: 4);
    globals.printStatus('To learn more, see: https://developer.android.com/studio/build/shrink-code', indent: 4);
    return GradleBuildStatus.exit;
  },
  eventLabel: 'r8',
);

// AndroidX failure.
//
// This regex is intentionally broad. AndroidX errors can manifest in multiple
// different ways and each one depends on the specific code config and
// filesystem paths of the project. Throwing the broadest net possible here to
// catch all known and likely cases.
//
// Example stack traces:
// https://github.com/flutter/flutter/issues/27226 "AAPT: error: resource android:attr/fontVariationSettings not found."
// https://github.com/flutter/flutter/issues/27106 "Android resource linking failed|Daemon: AAPT2|error: failed linking references"
// https://github.com/flutter/flutter/issues/27493 "error: cannot find symbol import androidx.annotation.NonNull;"
// https://github.com/flutter/flutter/issues/23995 "error: package android.support.annotation does not exist import android.support.annotation.NonNull;"
final RegExp _androidXFailureRegex = RegExp(r'(AAPT|androidx|android\.support)');

final RegExp androidXPluginWarningRegex = RegExp(r'\*{57}'
  r"|WARNING: This version of (\w+) will break your Android build if it or its dependencies aren't compatible with AndroidX."
  r'|See https://goo.gl/CP92wY for more information on the problem and how to fix it.'
  r'|This warning prints for all Android build failures. The real root cause of the error may be unrelated.');

@visibleForTesting
final GradleHandledError androidXFailureHandler = GradleHandledError(
  test: (String line) {
    return !androidXPluginWarningRegex.hasMatch(line) &&
           _androidXFailureRegex.hasMatch(line);
  },
  handler: ({
    String line,
    FlutterProject project,
    bool usesAndroidX,
    bool shouldBuildPluginAsAar,
  }) async {
    final bool hasPlugins = project.flutterPluginsFile.existsSync();
    if (!hasPlugins) {
      // If the app doesn't use any plugin, then it's unclear where
      // the incompatibility is coming from.
      BuildEvent(
        'gradle-android-x-failure',
        eventError: 'app-not-using-plugins',
        flutterUsage: globals.flutterUsage,
      ).send();
    }
    if (hasPlugins && !usesAndroidX) {
      // If the app isn't using AndroidX, then the app is likely using
      // a plugin already migrated to AndroidX.
      globals.printStatus(
        'AndroidX incompatibilities may have caused this build to fail. '
        'Please migrate your app to AndroidX. See https://goo.gl/CP92wY .'
      );
      BuildEvent(
        'gradle-android-x-failure',
        eventError: 'app-not-using-androidx',
        flutterUsage: globals.flutterUsage,
      ).send();
    }
    if (hasPlugins && usesAndroidX && shouldBuildPluginAsAar) {
      // This is a dependency conflict instead of an AndroidX failure since
      // by this point the app is using AndroidX, the plugins are built as
      // AARs, Jetifier translated Support libraries for AndroidX equivalents.
      BuildEvent(
        'gradle-android-x-failure',
        eventError: 'using-jetifier',
        flutterUsage: globals.flutterUsage,
      ).send();
    }
    if (hasPlugins && usesAndroidX && !shouldBuildPluginAsAar) {
      globals.printStatus(
        'The built failed likely due to AndroidX incompatibilities in a plugin. '
        'The tool is about to try using Jetfier to solve the incompatibility.'
      );
      BuildEvent(
        'gradle-android-x-failure',
        eventError: 'not-using-jetifier',
        flutterUsage: globals.flutterUsage,
      ).send();
      return GradleBuildStatus.retryWithAarPlugins;
    }
    return GradleBuildStatus.exit;
  },
  eventLabel: 'android-x',
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
    String line,
    FlutterProject project,
    bool usesAndroidX,
    bool shouldBuildPluginAsAar,
  }) async {
    const String licenseNotAcceptedMatcher =
      r'You have not accepted the license agreements of the following SDK components:\s*\[(.+)\]';

    final RegExp licenseFailure = RegExp(licenseNotAcceptedMatcher, multiLine: true);
    assert(licenseFailure != null);
    final Match licenseMatch = licenseFailure.firstMatch(line);
    globals.printStatus(
      '$warningMark Unable to download needed Android SDK components, as the '
      'following licenses have not been accepted:\n'
      '${licenseMatch.group(1)}\n\n'
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
    String line,
    FlutterProject project,
    bool usesAndroidX,
    bool shouldBuildPluginAsAar,
  }) async {
    final RunResult tasksRunResult = await processUtils.run(
      <String>[
        gradleUtils.getExecutable(project),
        'app:tasks' ,
        '--all',
        '--console=auto',
      ],
      throwOnError: true,
      workingDirectory: project.android.hostAppGradleRoot.path,
      environment: gradleEnvironment,
    );
    // Extract build types and product flavors.
    final Set<String> variants = <String>{};
    for (final String task in tasksRunResult.stdout.split('\n')) {
      final Match match = _assembleTaskPattern.matchAsPrefix(task);
      if (match != null) {
        final String variant = match.group(1).toLowerCase();
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
      '\n$warningMark  Gradle project does not define a task suitable '
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
