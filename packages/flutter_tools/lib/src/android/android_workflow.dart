// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../doctor.dart';
import '../globals.dart';
import 'android_sdk.dart';

class AndroidWorkflow extends DoctorValidator implements Workflow {
  AndroidWorkflow() : super('Android toolchain - develop for Android devices');

  @override
  bool get appliesToHostPlatform => true;

  @override
  bool get canListDevices => getAdbPath(androidSdk) != null;

  @override
  bool get canLaunchDevices => androidSdk != null && androidSdk.validateSdkWellFormed().isEmpty;

  @override
  Future<ValidationResult> validate() async {
    List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType type = ValidationType.missing;
    String sdkVersionText;

    if (androidSdk == null) {
      if (platform.environment.containsKey(kAndroidHome)) {
        String androidHomeDir = platform.environment[kAndroidHome];
        messages.add(new ValidationMessage.error(
          '$kAndroidHome = $androidHomeDir\n'
          'but Android Studio / Android SDK not found at this location.'
        ));
      } else {
        messages.add(new ValidationMessage.error(
          'Android Studio / Android SDK not found. Download from https://developer.android.com/sdk/\n'
          '(or visit https://flutter.io/setup/#android-setup for detailed instructions).'
        ));
      }
    } else {
      type = ValidationType.partial;

      messages.add(new ValidationMessage('Android SDK at ${androidSdk.directory}'));

      if (androidSdk.latestVersion != null) {
        sdkVersionText = 'Android SDK ${androidSdk.latestVersion.buildToolsVersionName}';

        messages.add(new ValidationMessage(
          'Platform ${androidSdk.latestVersion.platformVersionName}, '
          'build-tools ${androidSdk.latestVersion.buildToolsVersionName}'
        ));
      }

      if (platform.environment.containsKey(kAndroidHome)) {
        String androidHomeDir = platform.environment[kAndroidHome];
        messages.add(new ValidationMessage('$kAndroidHome = $androidHomeDir'));
      }

      List<String> validationResult = androidSdk.validateSdkWellFormed();
      // Empty result means SDK is well formated.

      if (validationResult.isEmpty) {
        const String _kJdkDownload = 'https://www.oracle.com/technetwork/java/javase/downloads/';

        String javaVersion;

        try {
          printTrace('java -version');

          ProcessResult result = processManager.runSync(<String>['java', '-version']);
          if (result.exitCode == 0) {
            javaVersion = result.stderr;
            List<String> versionLines = javaVersion.split('\n');
            javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
          }
        } catch (error) {
        }

        if (javaVersion != null) {
          messages.add(new ValidationMessage(javaVersion));

          if (os.which('jarsigner') == null) {
            messages.add(new ValidationMessage.error(
              'The jarsigner utility was not found; this is used to build Android APKs. You may need to install\n'
              'or re-install the Java JDK: $_kJdkDownload.'
            ));
          } else {
            type = ValidationType.installed;
          }
        } else {
          messages.add(new ValidationMessage.error(
            'No Java Development Kit (JDK) found; you can download the JDK from $_kJdkDownload.'
          ));
        }
      } else {
        messages.addAll(validationResult.map((String message) {
          return new ValidationMessage.error(message);
        }));
        messages.add(new ValidationMessage('Try re-installing or updating your Android SDK.'));
      }
    }

    return new ValidationResult(type, messages, statusInfo: sdkVersionText);
  }
}
