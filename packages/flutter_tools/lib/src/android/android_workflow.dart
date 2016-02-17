// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/globals.dart';
import '../doctor.dart';
import 'android_sdk.dart';

class AndroidWorkflow extends Workflow {
  AndroidWorkflow() : super('Android');

  bool get appliesToHostPlatform => true;

  bool get canListDevices => getAdbPath(androidSdk) != null;

  bool get canLaunchDevices => androidSdk != null && androidSdk.validateSdkWellFormed(complain: false);

  void diagnose() {
    Validator androidValidator = new Validator('Develop for Android devices');

    Function _sdkExists = () {
      return androidSdk == null ? ValidationType.missing : ValidationType.installed;
    };

    androidValidator.addValidator(new Validator(
      'Android SDK',
      description: 'enable development for Android devices',
      resolution: 'Download at https://developer.android.com/sdk/',
      validatorFunction: _sdkExists
    ));

    androidValidator.validate().print();
  }
}
