// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/os.dart';
import '../base/process.dart';
import '../doctor.dart';
import 'mac.dart';

XCode get xcode => XCode.instance;

class IOSWorkflow extends DoctorValidator implements Workflow {
  IOSWorkflow() : super('iOS toolchain - develop for iOS devices');

  @override
  bool get appliesToHostPlatform => Platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and idevice_id to list real devices.
  @override
  bool get canListDevices => xcode.isInstalledAndMeetsVersionCheck;

  // We need xcode to launch simulator devices, and ideviceinstaller and ios-deploy
  // for real devices.
  @override
  bool get canLaunchDevices => xcode.isInstalledAndMeetsVersionCheck;

  bool get hasIDeviceId => exitsHappy(<String>['idevice_id', '-h']);

  @override
  Future<ValidationResult> validate() async {
    List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType xcodeStatus = ValidationType.missing;
    ValidationType brewStatus = ValidationType.missing;
    String xcodeVersionInfo;

    if (xcode.isInstalled) {
      xcodeStatus = ValidationType.installed;

      messages.add(new ValidationMessage('XCode at ${xcode.xcodeSelectPath}'));

      xcodeVersionInfo = xcode.xcodeVersionText;
      if (xcodeVersionInfo.contains(','))
        xcodeVersionInfo = xcodeVersionInfo.substring(0, xcodeVersionInfo.indexOf(','));
      messages.add(new ValidationMessage(xcode.xcodeVersionText));

      if (!xcode.isInstalledAndMeetsVersionCheck) {
        xcodeStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'Flutter requires a minimum XCode version of $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor.0.\n'
          'Download the latest version or update via the Mac App Store.'
        ));
      }

      if (!xcode.eulaSigned) {
        xcodeStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'XCode end user license agreement not signed; open XCode or run the command \'sudo xcodebuild -license\'.'
        ));
      }
    } else {
      xcodeStatus = ValidationType.missing;
      messages.add(new ValidationMessage.error(
        'XCode not installed; this is necessary for iOS development.\n'
        'Download at https://developer.apple.com/xcode/download/.'
      ));
    }

    // brew installed
    if (os.which('brew') != null) {
      brewStatus = ValidationType.installed;

      if (!exitsHappy(<String>['ideviceinstaller', '-h'])) {
        brewStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'ideviceinstaller not available; this is used to discover connected iOS devices.\n'
          'Install via \'brew install ideviceinstaller\'.'
        ));
      }

      if (!hasIDeviceId) {
        brewStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'ios-deploy not available; this is used to deploy to connected iOS devices.\n'
          'Install via \'brew install ios-deploy\'.'
        ));
      } else {
        // Check for compatibility between libimobiledevice and Xcode.
        // TODO(cbracken) remove this check once libimobiledevice > 1.2.0 is released.
        ProcessResult result = (await runAsync(<String>['idevice_id', '-l'])).processResult;
        if (result.exitCode == 0 && result.stdout.isNotEmpty && !exitsHappy(<String>['ideviceName'])) {
          brewStatus = ValidationType.partial;
          messages.add(new ValidationMessage.error(
            'libimobiledevice is incompatible with the installed XCode version. To update, run:\n'
            'brew uninstall libimobiledevice\n'
            'brew install --HEAD libimobiledevice'
          ));
        }
      }
    } else {
      brewStatus = ValidationType.missing;
      messages.add(new ValidationMessage.error(
        'Brew not installed; use this to install tools for iOS device development.\n'
        'Download brew at http://brew.sh/.'
      ));
    }

    return new ValidationResult(
      xcodeStatus == brewStatus ? xcodeStatus : ValidationType.partial,
      messages,
      statusInfo: xcodeVersionInfo
    );
  }
}
