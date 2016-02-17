// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../base/process.dart';
import '../doctor.dart';
import '../globals.dart';

class IOSWorkflow extends Workflow {
  IOSWorkflow() : super('iOS');

  bool get appliesToHostPlatform => Platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and idevice_id to list real devices.
  bool get canListDevices => xcode.isInstalled;

  // We need xcode to launch simulator devices, and ideviceinstaller and ios-deploy
  // for real devices.
  bool get canLaunchDevices => xcode.isInstalled;

  ValidationResult validate() {
    Validator iosValidator = new Validator(
      '$name toolchain',
      description: 'develop for iOS devices'
    );

    Function _xcodeExists = () {
      return xcode.isInstalled ? ValidationType.installed : ValidationType.missing;
    };

    Function _brewExists = () {
      return exitsHappy(<String>['brew', '-v'])
        ? ValidationType.installed : ValidationType.missing;
    };

    Function _ideviceinstallerExists = () {
      return exitsHappy(<String>['ideviceinstaller', '-h'])
        ? ValidationType.installed : ValidationType.missing;
    };

    Function _iosdeployExists = () {
      return hasIdeviceId ? ValidationType.installed : ValidationType.missing;
    };

    iosValidator.addValidator(new Validator(
      'XCode',
      description: 'enable development for iOS devices',
      resolution: 'Download at https://developer.apple.com/xcode/download/',
      validatorFunction: _xcodeExists
    ));

    Validator brewValidator = new Validator(
      'brew',
      description: 'install additional development packages',
      resolution: 'Download at http://brew.sh/',
      validatorFunction: _brewExists
    );

    iosValidator.addValidator(brewValidator);

    brewValidator.addValidator(new Validator(
      'ideviceinstaller',
      description: 'discover connected iOS devices',
      resolution: "Install via 'brew install ideviceinstaller'",
      validatorFunction: _ideviceinstallerExists
    ));

    brewValidator.addValidator(new Validator(
      'ios-deploy',
      description: 'deploy to connected iOS devices',
      resolution: "Install via 'brew install ios-deploy'",
      validatorFunction: _iosdeployExists
    ));

    return iosValidator.validate();
  }

  void diagnose() => validate().print();

  bool get hasIdeviceId => exitsHappy(<String>['idevice_id', '-h']);

  /// Return whether the tooling to list and deploy to real iOS devices (not the
  /// simulator) is installed on the user's machine.
  bool get canWorkWithIOSDevices {
    return exitsHappy(<String>['ideviceinstaller', '-h']) && hasIdeviceId;
  }
}
