// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../doctor.dart';
import 'mac.dart';

Xcode get xcode => Xcode.instance;

class IOSWorkflow extends DoctorValidator implements Workflow {
  IOSWorkflow() : super('iOS toolchain - develop for iOS devices');

  @override
  bool get appliesToHostPlatform => platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and idevice_id to list real devices.
  @override
  bool get canListDevices => xcode.isInstalledAndMeetsVersionCheck;

  // We need xcode to launch simulator devices, and ideviceinstaller and ios-deploy
  // for real devices.
  @override
  bool get canLaunchDevices => xcode.isInstalledAndMeetsVersionCheck;

  bool get hasIDeviceId => exitsHappy(<String>['idevice_id', '-h']);

  bool get hasIosDeploy => exitsHappy(<String>['ios-deploy', '--version']);

  String get iosDeployMinimumVersion => '1.9.0';

  String get iosDeployVersionText => runSync(<String>['ios-deploy', '--version']).replaceAll('\n', '');

  bool get hasHomebrew => os.which('brew') != null;

  bool get hasPythonSixModule => exitsHappy(<String>['python', '-c', 'import six']);

  bool get hasCocoaPods => exitsHappy(<String>['pod', '--version']);

  String get cocoaPodsVersionText => runSync(<String>['pod', '--version']).trim();

  bool get _iosDeployIsInstalledAndMeetsVersionCheck {
    if (!hasIosDeploy)
      return false;
    try {
      final Version version = new Version.parse(iosDeployVersionText);
      return version >= new Version.parse(iosDeployMinimumVersion);
    } on FormatException catch (_) {
      return false;
    }
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType xcodeStatus = ValidationType.missing;
    ValidationType pythonStatus = ValidationType.missing;
    ValidationType brewStatus = ValidationType.missing;
    ValidationType podStatus = ValidationType.missing;
    String xcodeVersionInfo;

    if (xcode.isInstalled) {
      xcodeStatus = ValidationType.installed;

      messages.add(new ValidationMessage('Xcode at ${xcode.xcodeSelectPath}'));

      xcodeVersionInfo = xcode.xcodeVersionText;
      if (xcodeVersionInfo.contains(','))
        xcodeVersionInfo = xcodeVersionInfo.substring(0, xcodeVersionInfo.indexOf(','));
      messages.add(new ValidationMessage(xcode.xcodeVersionText));

      if (!xcode.isInstalledAndMeetsVersionCheck) {
        xcodeStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'Flutter requires a minimum Xcode version of $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor.0.\n'
          'Download the latest version or update via the Mac App Store.'
        ));
      }

      if (!xcode.eulaSigned) {
        xcodeStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'Xcode end user license agreement not signed; open Xcode or run the command \'sudo xcodebuild -license\'.'
        ));
      }
    } else {
      xcodeStatus = ValidationType.missing;
      if (xcode.xcodeSelectPath == null || xcode.xcodeSelectPath.isEmpty) {
        messages.add(new ValidationMessage.error(
            'Xcode not installed; this is necessary for iOS development.\n'
            'Download at https://developer.apple.com/xcode/download/.'
        ));
      } else {
        messages.add(new ValidationMessage.error(
            'Xcode installation is incomplete; a full installation is necessary for iOS development.\n'
            'Download at https://developer.apple.com/xcode/download/.'
            'Once installed, run \'sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer\'.'
        ));
      }
    }

    // Python dependencies installed
    if (hasPythonSixModule) {
      pythonStatus = ValidationType.installed;
    } else {
      pythonStatus = ValidationType.missing;
      messages.add(new ValidationMessage.error(
        'Python installation missing module "six".\n'
        'Install via \'pip install six\' or \'sudo easy_install six\'.'
      ));
    }

    // brew installed
    if (hasHomebrew) {
      brewStatus = ValidationType.installed;

      if (!exitsHappy(<String>['ideviceinstaller', '-h'])) {
        brewStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'ideviceinstaller not available; this is used to discover connected iOS devices.\n'
          'Install via \'brew install --HEAD ideviceinstaller\'.'
        ));
      }

      // Check ios-deploy is installed at meets version requirements.
      if (hasIosDeploy) {
        messages.add(new ValidationMessage('ios-deploy $iosDeployVersionText'));
      }
      if (!hasIDeviceId || !_iosDeployIsInstalledAndMeetsVersionCheck) {
        brewStatus = ValidationType.partial;
        if (hasIosDeploy) {
          messages.add(new ValidationMessage.error(
            'ios-deploy out of date ($iosDeployMinimumVersion is required): '
            'upgrade via \'brew upgrade ios-deploy\'.'
          ));
        } else {
          messages.add(new ValidationMessage.error(
            'ios-deploy not installed: install via \'brew install ios-deploy\'.'
          ));
        }
      } else {
        // Check for compatibility between libimobiledevice and Xcode.
        // TODO(cbracken) remove this check once libimobiledevice > 1.2.0 is released.
        final ProcessResult result = (await runAsync(<String>['idevice_id', '-l'])).processResult;
        if (result.exitCode == 0 && result.stdout.isNotEmpty && !exitsHappy(<String>['ideviceName'])) {
          brewStatus = ValidationType.partial;
          messages.add(new ValidationMessage.error(
            'libimobiledevice is incompatible with the installed Xcode version. To update, run:\n'
            'brew uninstall --ignore-dependencies libimobiledevice\n'
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

    if (hasCocoaPods) {
      podStatus = ValidationType.installed;
      messages.add(new ValidationMessage('CocoaPods version $cocoaPodsVersionText'));
    } else {
      podStatus = ValidationType.missing;
      messages.add(new ValidationMessage.error(
        'CocoaPods not installed; this is used for iOS development.\n'
        'Install by running: \'brew install cocoapods\''
      ));
    }

    return new ValidationResult(
      <ValidationType>[xcodeStatus, pythonStatus, brewStatus, podStatus].reduce(_mergeValidationTypes),
      messages,
      statusInfo: xcodeVersionInfo
    );
  }

  ValidationType _mergeValidationTypes(ValidationType t1, ValidationType t2) {
    return t1 == t2 ? t1 : ValidationType.partial;
  }
}
