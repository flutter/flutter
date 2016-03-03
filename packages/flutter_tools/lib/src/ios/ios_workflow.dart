// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../base/process.dart';
import '../doctor.dart';
import 'mac.dart';

class IOSWorkflow extends Workflow {
  String get label => 'iOS toolchain';

  bool get appliesToHostPlatform => Platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and idevice_id to list real devices.
  bool get canListDevices => XCode.instance.isInstalledAndMeetsVersionCheck;

  // We need xcode to launch simulator devices, and ideviceinstaller and ios-deploy
  // for real devices.
  bool get canLaunchDevices => XCode.instance.isInstalledAndMeetsVersionCheck;

  ValidationResult validate() {
    Validator iosValidator = new Validator(
      label,
      description: 'develop for iOS devices'
    );

    ValidationType xcodeExists() {
      return XCode.instance.isInstalled ? ValidationType.installed : ValidationType.missing;
    };

    ValidationType xcodeVersionSatisfactory() {
      return XCode.instance.isInstalledAndMeetsVersionCheck ? ValidationType.installed : ValidationType.missing;
    };

    ValidationType xcodeEulaSigned() {
      return XCode.instance.eulaSigned ? ValidationType.installed : ValidationType.missing;
    };

    ValidationType brewExists() {
      return exitsHappy(<String>['brew', '-v'])
        ? ValidationType.installed : ValidationType.missing;
    };

    ValidationType ideviceinstallerExists() {
      return exitsHappy(<String>['ideviceinstaller', '-h'])
        ? ValidationType.installed : ValidationType.missing;
    };

    ValidationType iosdeployExists() {
      return hasIdeviceId ? ValidationType.installed : ValidationType.missing;
    };

    Validator xcodeValidator = new Validator(
      'XCode',
      description: 'enable development for iOS devices',
      resolution: 'Download at https://developer.apple.com/xcode/download/',
      validatorFunction: xcodeExists
    );

    iosValidator.addValidator(xcodeValidator);

    xcodeValidator.addValidator(new Validator(
      'version',
      description: 'Xcode minimum version of $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor.0',
      resolution: 'Download the latest version or update via the Mac App Store',
      validatorFunction: xcodeVersionSatisfactory
    ));

    xcodeValidator.addValidator(new Validator(
      'EULA',
      description: 'XCode end user license agreement',
      resolution: "Open XCode or run the command 'sudo xcodebuild -license'",
      validatorFunction: xcodeEulaSigned
    ));

    Validator brewValidator = new Validator(
      'brew',
      description: 'install additional development packages',
      resolution: 'Download at http://brew.sh/',
      validatorFunction: brewExists
    );

    iosValidator.addValidator(brewValidator);

    brewValidator.addValidator(new Validator(
      'ideviceinstaller',
      description: 'discover connected iOS devices',
      resolution: "Install via 'brew install ideviceinstaller'",
      validatorFunction: ideviceinstallerExists
    ));

    brewValidator.addValidator(new Validator(
      'ios-deploy',
      description: 'deploy to connected iOS devices',
      resolution: "Install via 'brew install ios-deploy'",
      validatorFunction: iosdeployExists
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
