// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/context.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/user_messages.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../convert.dart';
import '../doctor.dart';
import '../globals.dart';
import 'android_sdk.dart';

const int kAndroidSdkMinVersion = 28;
final Version kAndroidSdkBuildToolsMinVersion = Version(28, 0, 3);

AndroidWorkflow get androidWorkflow => context.get<AndroidWorkflow>();
AndroidValidator get androidValidator => context.get<AndroidValidator>();
AndroidLicenseValidator get androidLicenseValidator => context.get<AndroidLicenseValidator>();

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
  bool get canListEmulators => getEmulatorPath(androidSdk) != null;
}

class AndroidValidator extends DoctorValidator {
  AndroidValidator() : super('Android toolchain - develop for Android devices',);

  @override
  String get slowWarning => '${_task ?? 'This'} is taking a long time...';
  String _task;

  /// Returns false if we cannot determine the Java version or if the version
  /// is not compatible.
  Future<bool> _checkJavaVersion(String javaBinary, List<ValidationMessage> messages) async {
    _task = 'Checking Java status';
    try {
      if (!processManager.canRun(javaBinary)) {
        messages.add(ValidationMessage.error(userMessages.androidCantRunJavaBinary(javaBinary)));
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
        messages.add(ValidationMessage.error(userMessages.androidUnknownJavaVersion));
        return false;
      }
      messages.add(ValidationMessage(userMessages.androidJavaVersion(javaVersion)));
      // TODO(johnmccutchan): Validate version.
      return true;
    } finally {
      _task = null;
    }
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    if (androidSdk == null) {
      // No Android SDK found.
      if (platform.environment.containsKey(kAndroidHome)) {
        final String androidHomeDir = platform.environment[kAndroidHome];
        messages.add(ValidationMessage.error(userMessages.androidBadSdkDir(kAndroidHome, androidHomeDir)));
      } else {
        messages.add(ValidationMessage.error(userMessages.androidMissingSdkInstructions(kAndroidHome)));
      }
      return ValidationResult(ValidationType.missing, messages);
    }

    if (androidSdk.licensesAvailable && !androidSdk.platformToolsAvailable) {
      messages.add(ValidationMessage.hint(userMessages.androidSdkLicenseOnly(kAndroidHome)));
      return ValidationResult(ValidationType.partial, messages);
    }

    messages.add(ValidationMessage(userMessages.androidSdkLocation(androidSdk.directory)));

    messages.add(ValidationMessage(androidSdk.ndk == null
          ? userMessages.androidMissingNdk
          : userMessages.androidNdkLocation(androidSdk.ndk.directory)));

    String sdkVersionText;
    if (androidSdk.latestVersion != null) {
      if (androidSdk.latestVersion.sdkLevel < 28 || androidSdk.latestVersion.buildToolsVersion < kAndroidSdkBuildToolsMinVersion) {
        messages.add(ValidationMessage.error(
          userMessages.androidSdkBuildToolsOutdated(androidSdk.sdkManagerPath, kAndroidSdkMinVersion, kAndroidSdkBuildToolsMinVersion.toString())),
        );
        return ValidationResult(ValidationType.missing, messages);
      }
      sdkVersionText = userMessages.androidStatusInfo(androidSdk.latestVersion.buildToolsVersionName);

      messages.add(ValidationMessage(userMessages.androidSdkPlatformToolsVersion(
        androidSdk.latestVersion.platformName,
        androidSdk.latestVersion.buildToolsVersionName)));
    } else {
      messages.add(ValidationMessage.error(userMessages.androidMissingSdkInstructions(kAndroidHome)));
    }

    if (platform.environment.containsKey(kAndroidHome)) {
      final String androidHomeDir = platform.environment[kAndroidHome];
      messages.add(ValidationMessage('$kAndroidHome = $androidHomeDir'));
    }
    if (platform.environment.containsKey(kAndroidSdkRoot)) {
      final String androidSdkRoot = platform.environment[kAndroidSdkRoot];
      messages.add(ValidationMessage('$kAndroidSdkRoot = $androidSdkRoot'));
    }

    final List<String> validationResult = androidSdk.validateSdkWellFormed();

    if (validationResult.isNotEmpty) {
      // Android SDK is not functional.
      messages.addAll(validationResult.map<ValidationMessage>((String message) {
        return ValidationMessage.error(message);
      }));
      messages.add(ValidationMessage(userMessages.androidSdkInstallHelp));
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Now check for the JDK.
    final String javaBinary = AndroidSdk.findJavaBinary();
    if (javaBinary == null) {
      messages.add(ValidationMessage.error(userMessages.androidMissingJdk));
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }
    messages.add(ValidationMessage(userMessages.androidJdkLocation(javaBinary)));

    // Check JDK version.
    if (! await _checkJavaVersion(javaBinary, messages)) {
      return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
    }

    // Success.
    return ValidationResult(ValidationType.installed, messages, statusInfo: sdkVersionText);
  }
}

class AndroidLicenseValidator extends DoctorValidator {
  AndroidLicenseValidator() : super('Android license subvalidator',);

  @override
  String get slowWarning => 'Checking Android licenses is taking an unexpectedly long time...';

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    // Match pre-existing early termination behavior
    if (androidSdk == null || androidSdk.latestVersion == null ||
        androidSdk.validateSdkWellFormed().isNotEmpty ||
        ! await _checkJavaVersionNoOutput()) {
      return ValidationResult(ValidationType.missing, messages);
    }

    final String sdkVersionText = userMessages.androidStatusInfo(androidSdk.latestVersion.buildToolsVersionName);

    // Check for licenses.
    switch (await licensesAccepted) {
      case LicensesAccepted.all:
        messages.add(ValidationMessage(userMessages.androidLicensesAll));
        break;
      case LicensesAccepted.some:
        messages.add(ValidationMessage.hint(userMessages.androidLicensesSome));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.none:
        messages.add(ValidationMessage.error(userMessages.androidLicensesNone));
        return ValidationResult(ValidationType.partial, messages, statusInfo: sdkVersionText);
      case LicensesAccepted.unknown:
        messages.add(ValidationMessage.error(userMessages.androidLicensesUnknown));
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

    void _handleLine(String line) {
      if (licenseCounts.hasMatch(line)) {
        final Match match = licenseCounts.firstMatch(line);
        if (match.group(1) != match.group(2)) {
          status = LicensesAccepted.some;
        } else {
          status = LicensesAccepted.none;
        }
      } else if (licenseNotAccepted.hasMatch(line)) {
        // The licenseNotAccepted pattern is trying to match the same line as
        // licenseCounts, but is more general. In case the format changes, a
        // more general match may keep doctor mostly working.
        status = LicensesAccepted.none;
      } else if (licenseAccepted.hasMatch(line)) {
        status ??= LicensesAccepted.all;
      }
    }

    if (!_canRunSdkManager()) {
      return LicensesAccepted.unknown;
    }

    try {
      final Process process = await processUtils.start(
        <String>[androidSdk.sdkManagerPath, '--licenses'],
        environment: androidSdk.sdkManagerEnv,
      );
      process.stdin.write('n\n');
      // We expect logcat streams to occasionally contain invalid utf-8,
      // see: https://github.com/flutter/flutter/pull/8864.
      final Future<void> output = process.stdout
        .transform<String>(const Utf8Decoder(reportErrors: false))
        .transform<String>(const LineSplitter())
        .listen(_handleLine)
        .asFuture<void>(null);
      final Future<void> errors = process.stderr
        .transform<String>(const Utf8Decoder(reportErrors: false))
        .transform<String>(const LineSplitter())
        .listen(_handleLine)
        .asFuture<void>(null);
      await Future.wait<void>(<Future<void>>[output, errors]);
      return status ?? LicensesAccepted.unknown;
    } on ProcessException catch (e) {
      printTrace('Failed to run Android sdk manager: $e');
      return LicensesAccepted.unknown;
    }
  }

  /// Run the Android SDK manager tool in order to accept SDK licenses.
  static Future<bool> runLicenseManager() async {
    if (androidSdk == null) {
      printStatus(userMessages.androidSdkShort);
      return false;
    }

    if (!_canRunSdkManager()) {
      throwToolExit(userMessages.androidMissingSdkManager(androidSdk.sdkManagerPath));
    }

    final Version sdkManagerVersion = Version.parse(androidSdk.sdkManagerVersion);
    if (sdkManagerVersion == null || sdkManagerVersion.major < 26) {
      // SDK manager is found, but needs to be updated.
      throwToolExit(userMessages.androidSdkManagerOutdated(androidSdk.sdkManagerPath));
    }

    try {
      final Process process = await processUtils.start(
        <String>[androidSdk.sdkManagerPath, '--licenses'],
        environment: androidSdk.sdkManagerEnv,
      );

      // The real stdin will never finish streaming. Pipe until the child process
      // finishes.
      unawaited(process.stdin.addStream(stdin));
      // Wait for stdout and stderr to be fully processed, because process.exitCode
      // may complete first.
      await waitGroup<void>(<Future<void>>[
        stdout.addStream(process.stdout),
        stderr.addStream(process.stderr),
      ]);

      final int exitCode = await process.exitCode;
      return exitCode == 0;
    } on ProcessException catch (e) {
      throwToolExit(userMessages.androidCannotRunSdkManager(
          androidSdk.sdkManagerPath, e.toString()));
      return false;
    }
  }

  static bool _canRunSdkManager() {
    assert(androidSdk != null);
    final String sdkManagerPath = androidSdk.sdkManagerPath;
    return processManager.canRun(sdkManagerPath);
  }
}
