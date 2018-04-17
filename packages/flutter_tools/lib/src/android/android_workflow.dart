// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../base/common.dart';
import '../base/context.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../doctor.dart';
import '../globals.dart';
import 'android_sdk.dart';

AndroidWorkflow get androidWorkflow => context[AndroidWorkflow];

enum LicensesAccepted {
  none,
  some,
  all,
  unknown,
}

final RegExp licenseCounts = new RegExp(r'(\d+) of (\d+) SDK package licenses? not accepted.');
final RegExp licenseNotAccepted = new RegExp(r'licenses? not accepted', caseSensitive: false);
final RegExp licenseAccepted = new RegExp(r'All SDK package licenses accepted.');

class AndroidWorkflow extends DoctorValidator implements Workflow {
  AndroidWorkflow() : super('Android toolchain - develop for Android devices');

  @override
  bool get appliesToHostPlatform => true;

  @override
  bool get canListDevices => getAdbPath(androidSdk) != null;

  @override
  bool get canLaunchDevices => androidSdk != null && androidSdk.validateSdkWellFormed().isEmpty;

  static const String _kJdkDownload = 'https://www.oracle.com/technetwork/java/javase/downloads/';

  /// Returns false if we cannot determine the Java version or if the version
  /// is not compatible.
  bool _checkJavaVersion(String javaBinary, List<ValidationMessage> messages) {
    if (!processManager.canRun(javaBinary)) {
      messages.add(new ValidationMessage.error('Cannot execute $javaBinary to determine the version'));
      return false;
    }
    String javaVersion;
    try {
      printTrace('java -version');
      final ProcessResult result = processManager.runSync(<String>[javaBinary, '-version']);
      if (result.exitCode == 0) {
        final List<String> versionLines = result.stderr.split('\n');
        javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
      }
    } catch (_) { /* ignore */ }
    if (javaVersion == null) {
      // Could not determine the java version.
      messages.add(new ValidationMessage.error('Could not determine java version'));
      return false;
    }
    messages.add(new ValidationMessage('Java version $javaVersion'));
    // TODO(johnmccutchan): Validate version.
    return true;
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    if (androidSdk == null) {
      // No Android SDK found.
      if (platform.environment.containsKey(kAndroidHome)) {
        final String androidHomeDir = platform.environment[kAndroidHome];
        messages.add(new ValidationMessage.error(
          '$kAndroidHome = $androidHomeDir\n'
          'but Android SDK not found at this location.'
        ));
      } else {
        messages.add(new ValidationMessage.error(
          'Unable to locate Android SDK.\n'
          'Install Android Studio from: https://developer.android.com/studio/index.html\n'
          'On first launch it will assist you in installing the Android SDK components.\n'
          '(or visit https://flutter.io/setup/#android-setup for detailed instructions).\n'
          'If Android SDK has been installed to a custom location, set \$$kAndroidHome to that location.'
        ));
      }

      return new ValidationResult(ValidationType.missing, messages);
    }

    messages.add(new ValidationMessage('Android SDK at ${androidSdk.directory}'));

    messages.add(new ValidationMessage(androidSdk.ndkDirectory == null
          ? 'Android NDK location not configured (optional; useful for native profiling support)'
          : 'Android NDK at ${androidSdk.ndkDirectory}'));

    String sdkVersionText;
    if (androidSdk.latestVersion != null) {
      sdkVersionText = 'Android SDK ${androidSdk.latestVersion.buildToolsVersionName}';

      messages.add(new ValidationMessage(
        'Platform ${androidSdk.latestVersion.platformName}, '
        'build-tools ${androidSdk.latestVersion.buildToolsVersionName}'
      ));
    }

    if (platform.environment.containsKey(kAndroidHome)) {
      final String androidHomeDir = platform.environment[kAndroidHome];
      messages.add(new ValidationMessage('$kAndroidHome = $androidHomeDir'));
    }

    final List<String> validationResult = androidSdk.validateSdkWellFormed();

    if (validationResult.isNotEmpty) {
      // Android SDK is not functional.
      messages.addAll(validationResult.map((String message) {
        return new ValidationMessage.error(message);
      }));
      messages.add(new ValidationMessage(
          'Try re-installing or updating your Android SDK,\n'
          'visit https://flutter.io/setup/#android-setup for detailed instructions.'));
      return new ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Now check for the JDK.
    final String javaBinary = AndroidSdk.findJavaBinary();
    if (javaBinary == null) {
      messages.add(new ValidationMessage.error(
          'No Java Development Kit (JDK) found; You must have the environment '
          'variable JAVA_HOME set and the java binary in your PATH. '
          'You can download the JDK from $_kJdkDownload.'));
      return new ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }
    messages.add(new ValidationMessage('Java binary at: $javaBinary'));

    // Check JDK version.
    if (!_checkJavaVersion(javaBinary, messages)) {
      return new ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Check for licenses.
    switch (await licensesAccepted) {
      case LicensesAccepted.all:
        messages.add(new ValidationMessage('All Android licenses accepted.'));
        break;
      case LicensesAccepted.some:
        messages.add(new ValidationMessage.hint('Some Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses'));
        return new ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.none:
        messages.add(new ValidationMessage.error('Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses'));
        return new ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.unknown:
        messages.add(new ValidationMessage.error('Android license status unknown.'));
        return new ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Success.
    return new ValidationResult(ValidationType.installed, messages, statusInfo: sdkVersionText);
  }

  Future<LicensesAccepted> get licensesAccepted async {
    LicensesAccepted status = LicensesAccepted.unknown;

    void _onLine(String line) {
      if (licenseAccepted.hasMatch(line)) {
        status = LicensesAccepted.all;
      } else if (licenseCounts.hasMatch(line)) {
        final Match match = licenseCounts.firstMatch(line);
        if (match.group(1) != match.group(2)) {
          status = LicensesAccepted.some;
        } else {
          status = LicensesAccepted.none;
        }
      } else if (licenseNotAccepted.hasMatch(line)) {
        // In case the format changes, a more general match will keep doctor
        // mostly working.
        status = LicensesAccepted.none;
      }
    }

    _ensureCanRunSdkManager();

    final Process process = await runCommand(
      <String>[androidSdk.sdkManagerPath, '--licenses'],
      environment: androidSdk.sdkManagerEnv,
    );
    process.stdin.write('n\n');
    final Future<void> output = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(_onLine)
        .asFuture<void>(null);
    final Future<void> errors = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(_onLine)
        .asFuture<void>(null);
    try {
      await Future.wait<void>(<Future<void>>[output, errors]).timeout(const Duration(seconds: 30));
    } catch (TimeoutException) {
      printTrace('Intentionally killing ${androidSdk.sdkManagerPath}');
      processManager.killPid(process.pid);
    }
    return status;
  }

  /// Run the Android SDK manager tool in order to accept SDK licenses.
  static Future<bool> runLicenseManager() async {
    if (androidSdk == null) {
      printStatus('Unable to locate Android SDK.');
      return false;
    }

    _ensureCanRunSdkManager();

    final Version sdkManagerVersion = new Version.parse(androidSdk.sdkManagerVersion);
    if (sdkManagerVersion == null || sdkManagerVersion.major < 26)
      // SDK manager is found, but needs to be updated.
      throwToolExit(
        'A newer version of the Android SDK is required. To update, run:\n'
        '${androidSdk.sdkManagerPath} --update\n'
      );

    final Process process = await runCommand(
      <String>[androidSdk.sdkManagerPath, '--licenses'],
      environment: androidSdk.sdkManagerEnv,
    );

    process.stdin.addStream(stdin);
    await waitGroup<Null>(<Future<Null>>[
      stdout.addStream(process.stdout),
      stderr.addStream(process.stderr),
    ]);

    final int exitCode = await process.exitCode;
    return exitCode == 0;
  }

  static void _ensureCanRunSdkManager() {
    assert(androidSdk != null);
    final String sdkManagerPath = androidSdk.sdkManagerPath;
    if (!processManager.canRun(sdkManagerPath))
      throwToolExit(
        'Android sdkmanager tool not found ($sdkManagerPath).\n'
        'Try re-installing or updating your Android SDK,\n'
        'visit https://flutter.io/setup/#android-setup for detailed instructions.'
      );
  }
}
