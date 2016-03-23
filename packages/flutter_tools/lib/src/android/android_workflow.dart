// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  ValidationResult validate() {
    List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType type = ValidationType.missing;
    String sdkVersionText;

    if (androidSdk == null) {
      messages.add(new ValidationMessage.error(
        'Android Studio / Android SDK not found. Download from https://developer.android.com/sdk/\n'
        '(or visit https://flutter.io/setup/#android-setup for detailed instructions).'
      ));
    } else {
      type = ValidationType.partial;

      messages.add(new ValidationMessage('Android SDK at ${androidSdk.directory}'));

      if (androidSdk.latestVersion != null) {
        sdkVersionText = 'Android SDK ${androidSdk.latestVersion.buildToolsVersionName}';

        messages.add(new ValidationMessage('Platform ${androidSdk.latestVersion.platformVersionName}'));
        messages.add(new ValidationMessage('Build-tools ${androidSdk.latestVersion.buildToolsVersionName}'));
      }

      List<String> validationResult = androidSdk.validateSdkWellFormed();

      if (validationResult.isEmpty) {
        type = ValidationType.installed;
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
