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
AndroidValidator get androidValidator => context[AndroidValidator];
AndroidLicenseValidator get androidLicenseValidator => context[AndroidLicenseValidator];

enum LicensesAccepted {
  none,
  some,
  all,
  unknown,
}

final RegExp licenseCounts = RegExp(r'(\d+) of (\d+) SDK package licenses? not accepted.');
final RegExp licenseNotAccepted = RegExp(r'licenses? not accepted', caseSensitive: false);
final RegExp licenseAccepted = RegExp(r'All SDK package licenses accepted.');

class AndroidWorkflow implements Workflow {
  @override
  bool get appliesToHostPlatform => true;

  @override
  bool get canListDevices => getAdbPath(androidSdk) != null;

  @override
  bool get canLaunchDevices => androidSdk != null && androidSdk.validateSdkWellFormed().isEmpty;

  @override
  bool get canListEmulators => getEmulatorPath(androidSdk) != null && getAvdPath() != null;
}

class AndroidValidator extends DoctorValidator {
  AndroidValidator(): super('Android toolchain - develop for Android devices',);

  static const String _jdkDownload = 'https://www.oracle.com/technetwork/java/javase/downloads/';

  /// Returns false if we cannot determine the Java version or if the version
  /// is not compatible.
  Future<bool> _checkJavaVersion(String javaBinary, List<ValidationMessage> messages) async {
    if (!processManager.canRun(javaBinary)) {
      messages.add(ValidationMessage.error('Cannot execute $javaBinary to determine the version'));
      return false;
    }
    String javaVersion;
    try {
      printTrace('java -version');
      final ProcessResult result = await processManager.run(<String>[javaBinary, '-version']);
      if (result.exitCode == 0) {
        final List<String> versionLines = result.stderr.split('\n');
        javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
      }
    } catch (error) {
      printTrace(error.toString());
    }
    if (javaVersion == null) {
      // Could not determine the java version.
      messages.add(ValidationMessage.error('Could not determine java version'));
      return false;
    }
    messages.add(ValidationMessage('Java version $javaVersion'));
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
        messages.add(ValidationMessage.error(
          '$kAndroidHome = $androidHomeDir\n'
          'but Android SDK not found at this location.'
        ));
      } else {
        messages.add(ValidationMessage.error(
          'Unable to locate Android SDK.\n'
          'Install Android Studio from: https://developer.android.com/studio/index.html\n'
          'On first launch it will assist you in installing the Android SDK components.\n'
          '(or visit https://flutter.io/setup/#android-setup for detailed instructions).\n'
          'If Android SDK has been installed to a custom location, set \$$kAndroidHome to that location.\n'
          'You may also want to add it to your PATH environment variable.\n'
        ));
      }

      return ValidationResult(ValidationType.missing, messages);
    }

    messages.add(ValidationMessage('Android SDK at ${androidSdk.directory}'));

    messages.add(ValidationMessage(androidSdk.ndk == null
          ? 'Android NDK location not configured (optional; useful for native profiling support)'
          : 'Android NDK at ${androidSdk.ndk.directory}'));

    String sdkVersionText;
    if (androidSdk.latestVersion != null) {
      sdkVersionText = 'Android SDK ${androidSdk.latestVersion.buildToolsVersionName}';

      messages.add(ValidationMessage(
        'Platform ${androidSdk.latestVersion.platformName}, '
        'build-tools ${androidSdk.latestVersion.buildToolsVersionName}'
      ));
    }

    if (platform.environment.containsKey(kAndroidHome)) {
      final String androidHomeDir = platform.environment[kAndroidHome];
      messages.add(ValidationMessage('$kAndroidHome = $androidHomeDir'));
    }

    final List<String> validationResult = androidSdk.validateSdkWellFormed();

    if (validationResult.isNotEmpty) {
      // Android SDK is not functional.
      messages.addAll(validationResult.map<ValidationMessage>((String message) {
        return ValidationMessage.error(message);
      }));
      messages.add(ValidationMessage(
          'Try re-installing or updating your Android SDK,\n'
          'visit https://flutter.io/setup/#android-setup for detailed instructions.'));
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Now check for the JDK.
    final String javaBinary = AndroidSdk.findJavaBinary();
    if (javaBinary == null) {
      messages.add(ValidationMessage.error(
          'No Java Development Kit (JDK) found; You must have the environment '
          'variable JAVA_HOME set and the java binary in your PATH. '
          'You can download the JDK from $_jdkDownload.'));
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }
    messages.add(ValidationMessage('Java binary at: $javaBinary'));

    // Check JDK version.
    if (! await _checkJavaVersion(javaBinary, messages)) {
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Success.
    return ValidationResult(ValidationType.installed, messages, statusInfo: sdkVersionText);
  }
}

class AndroidLicenseValidator extends DoctorValidator {
  AndroidLicenseValidator(): super('Android license subvalidator',);

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    // Match pre-existing early termination behavior
    if (androidSdk == null || androidSdk.latestVersion == null ||
        androidSdk.validateSdkWellFormed().isNotEmpty ||
        ! await _checkJavaVersionNoOutput()) {
      return ValidationResult(ValidationType.missing, messages);
    }

    final String sdkVersionText = 'Android SDK ${androidSdk.latestVersion.buildToolsVersionName}';

    // Check for licenses.
    switch (await licensesAccepted) {
      case LicensesAccepted.all:
        messages.add(ValidationMessage('All Android licenses accepted.'));
        break;
      case LicensesAccepted.some:
        messages.add(ValidationMessage.hint('Some Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses'));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.none:
        messages.add(ValidationMessage.error('Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses'));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.unknown:
        messages.add(ValidationMessage.error('Android license status unknown.'));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }
    return ValidationResult(ValidationType.installed, messages, statusInfo: sdkVersionText);
  }

  Future<bool> _checkJavaVersionNoOutput() async {
    final String javaBinary = AndroidSdk.findJavaBinary();
    if (javaBinary == null) {
      return false;
    }
    if (!processManager.canRun(javaBinary)) {
      return false;
    }
    String javaVersion;
    try {
      final ProcessResult result = await processManager.run(<String>[javaBinary, '-version']);
      if (result.exitCode == 0) {
        final List<String> versionLines = result.stderr.split('\n');
        javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
      }
    } catch (error) {
      printTrace(error.toString());
    }
    if (javaVersion == null) {
      // Could not determine the java version.
      return false;
    }
    return true;
  }

  Future<LicensesAccepted> get licensesAccepted async {
    LicensesAccepted status;

    void _onLine(String line) {
      if (status == null && licenseAccepted.hasMatch(line)) {
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
      .transform<String>(const Utf8Decoder(allowMalformed: true))
      .transform<String>(const LineSplitter())
      .listen(_onLine)
      .asFuture<void>(null);
    final Future<void> errors = process.stderr
      .transform<String>(const Utf8Decoder(allowMalformed: true))
      .transform<String>(const LineSplitter())
      .listen(_onLine)
      .asFuture<void>(null);
    try {
      await Future.wait<void>(<Future<void>>[output, errors]).timeout(const Duration(seconds: 30));
    } catch (TimeoutException) {
      printTrace('Intentionally killing ${androidSdk.sdkManagerPath}');
      processManager.killPid(process.pid);
    }
    return status ?? LicensesAccepted.unknown;
  }

  /// Run the Android SDK manager tool in order to accept SDK licenses.
  static Future<bool> runLicenseManager() async {
    if (androidSdk == null) {
      printStatus('Unable to locate Android SDK.');
      return false;
    }

    _ensureCanRunSdkManager();

    final Version sdkManagerVersion = Version.parse(androidSdk.sdkManagerVersion);
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

    // The real stdin will never finish streaming. Pipe until the child process
    // finishes.
    process.stdin.addStream(stdin); // ignore: unawaited_futures
    // Wait for stdout and stderr to be fully processed, because process.exitCode
    // may complete first.
    await waitGroup<void>(<Future<void>>[
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
