// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../doctor.dart';
import '../globals.dart';
import 'android_sdk.dart';
import 'android_studio.dart' as android_studio;

class AndroidWorkflow extends DoctorValidator implements Workflow {
  AndroidWorkflow() : super('Android toolchain - develop for Android devices');

  @override
  bool get appliesToHostPlatform => true;

  @override
  bool get canListDevices => getAdbPath(androidSdk) != null;

  @override
  bool get canLaunchDevices => androidSdk != null && androidSdk.validateSdkWellFormed().isEmpty;

  static const String _kJavaHomeEnvironmentVariable = 'JAVA_HOME';
  static const String _kJavaExecutable = 'java';
  static const String _kJdkDownload = 'https://www.oracle.com/technetwork/java/javase/downloads/';

  /// First try Java bundled with Android Studio, then sniff JAVA_HOME, then fallback to PATH.
  static String _findJavaBinary() {

    if (android_studio.javaPath != null)
      return fs.path.join(android_studio.javaPath, 'bin', 'java');

    final String javaHomeEnv = platform.environment[_kJavaHomeEnvironmentVariable];
    if (javaHomeEnv != null) {
      // Trust JAVA_HOME.
      return fs.path.join(javaHomeEnv, 'bin', 'java');
    }

    // MacOS specific logic to avoid popping up a dialog window.
    // See: http://stackoverflow.com/questions/14292698/how-do-i-check-if-the-java-jdk-is-installed-on-mac.
    if (platform.isMacOS) {
      try {
        final String javaHomeOutput = runCheckedSync(<String>['/usr/libexec/java_home'], hideStdout: true);
        if (javaHomeOutput != null) {
          final List<String> javaHomeOutputSplit = javaHomeOutput.split('\n');
          if ((javaHomeOutputSplit != null) && (javaHomeOutputSplit.isNotEmpty)) {
            final String javaHome = javaHomeOutputSplit[0].trim();
            return fs.path.join(javaHome, 'bin', 'java');
          }
        }
      } catch (_) { /* ignore */ }
    }

    // Fallback to PATH based lookup.
    return os.which(_kJavaExecutable)?.path;
  }

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
    messages.add(new ValidationMessage('Java version: $javaVersion'));
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
          'Install Android Studio from https://developer.android.com/studio/index.html.\n'
          'On first launch it will assist you in installing the Android SDK components.\n'
          '(or visit https://flutter.io/setup/#android-setup for detailed instructions).\n'
          'If Android SDK has been installed to a custom location, set \$$kAndroidHome to that location.'
        ));
      }

      return new ValidationResult(ValidationType.missing, messages);
    }

    messages.add(new ValidationMessage('Android SDK at ${androidSdk.directory}'));

    String sdkVersionText;
    if (androidSdk.latestVersion != null) {
      sdkVersionText = 'Android SDK ${androidSdk.latestVersion.buildToolsVersionName}';

      messages.add(new ValidationMessage(
        'Platform ${androidSdk.latestVersion.platformVersionName}, '
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
    final String javaBinary = _findJavaBinary();
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

    // Success.
    return new ValidationResult(ValidationType.installed, messages, statusInfo: sdkVersionText);
  }

  /// Run the Android SDK manager tool in order to accept SDK licenses.
  static Future<bool> runLicenseManager() async {
    if (androidSdk == null) {
      printStatus('Unable to locate Android SDK.');
      return false;
    }

    // If we can locate Java, then add it to the path used to run the Android SDK manager.
    final Map<String, String> sdkManagerEnv = <String, String>{};
    final String javaBinary = _findJavaBinary();
    if (javaBinary != null) {
      sdkManagerEnv['PATH'] =
          platform.environment['PATH'] + os.pathVarSeparator + fs.path.dirname(javaBinary);
    }

    final Process process = await Process.start(
      fs.path.join(androidSdk.directory, 'tools', 'bin', 'sdkmanager'),
      <String>['--licenses'],
      environment: sdkManagerEnv,
    );
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
    process.stdin.addStream(stdin);

    final int exitCode = await process.exitCode;
    return exitCode == 0;
  }
}
